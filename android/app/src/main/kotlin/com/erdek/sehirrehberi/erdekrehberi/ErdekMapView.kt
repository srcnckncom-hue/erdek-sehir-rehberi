package com.erdek.sehirrehberi.erdekrehberi

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.drawable.BitmapDrawable
import android.view.View
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import org.osmdroid.config.Configuration
import org.osmdroid.tileprovider.tilesource.TileSourceFactory
import org.osmdroid.util.BoundingBox
import org.osmdroid.util.GeoPoint
import org.osmdroid.views.CustomZoomButtonsController
import org.osmdroid.views.MapView
import org.osmdroid.views.overlay.CopyrightOverlay
import org.osmdroid.views.overlay.Marker
import org.osmdroid.views.overlay.Polyline
import org.osmdroid.views.overlay.mylocation.GpsMyLocationProvider
import org.osmdroid.views.overlay.mylocation.MyLocationNewOverlay

class ErdekMapFactory(private val messenger: BinaryMessenger) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView =
        ErdekMapView(context, viewId, args as? Map<*, *>, messenger)
}

/**
 * iOS'taki MapKit görünümünün Android karşılığı (OpenStreetMap, anahtar gerektirmez).
 * Parametreler aynı: centerLat/centerLng, pins [{id, kind, title, subtitle, lat, lng}],
 * path [[lat, lng]], fit. Kanal 'erdek/map_<id>': setPins ← , select →.
 */
class ErdekMapView(context: Context, viewId: Int, params: Map<*, *>?, messenger: BinaryMessenger) : PlatformView {
    private val map: MapView
    private val channel = MethodChannel(messenger, "erdek/map_$viewId")
    private val markers = mutableListOf<Marker>()
    private var line: Polyline? = null
    private val density = context.resources.displayMetrics.density

    init {
        Configuration.getInstance().apply {
            load(context, context.getSharedPreferences("osmdroid", Context.MODE_PRIVATE))
            userAgentValue = context.packageName
        }
        map = MapView(context).apply {
            setTileSource(TileSourceFactory.MAPNIK)
            setMultiTouchControls(true)
            zoomController.setVisibility(CustomZoomButtonsController.Visibility.NEVER)
            isTilesScaledToDpi = true
            minZoomLevel = 5.0
            maxZoomLevel = 19.0
        }
        val lat = (params?.get("centerLat") as? Number)?.toDouble() ?: 40.3955
        val lng = (params?.get("centerLng") as? Number)?.toDouble() ?: 27.7930
        map.controller.setZoom(13.0)
        map.controller.setCenter(GeoPoint(lat, lng))
        map.overlays.add(CopyrightOverlay(context))

        val hasLocation = context.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
            context.checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
        if (hasLocation) {
            map.overlays.add(MyLocationNewOverlay(GpsMyLocationProvider(context), map).apply { enableMyLocation() })
        }

        (params?.get("path") as? List<*>)?.let { raw ->
            val pts = raw.mapNotNull { p ->
                val pair = (p as? List<*>)?.mapNotNull { (it as? Number)?.toDouble() }
                if (pair != null && pair.size == 2) GeoPoint(pair[0], pair[1]) else null
            }
            if (pts.size > 1) {
                val polyline = Polyline(map).apply {
                    setPoints(pts)
                    outlinePaint.color = Color.argb(230, 38, 143, 196)
                    outlinePaint.strokeWidth = 4 * density
                    outlinePaint.strokeCap = Paint.Cap.ROUND
                }
                line = polyline
                map.overlays.add(polyline)
            }
        }
        setPins(params?.get("pins") as? List<*> ?: emptyList<Any>())
        if (params?.get("fit") == true) map.addOnFirstLayoutListener { _, _, _, _, _ -> fitAll() }

        channel.setMethodCallHandler { call, result ->
            if (call.method == "setPins") {
                setPins(call.arguments as? List<*> ?: emptyList<Any>())
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun getView(): View = map

    override fun dispose() {
        channel.setMethodCallHandler(null)
        map.onDetach()
    }

    private fun fitAll() {
        val points = markers.map { it.position } + (line?.actualPoints ?: emptyList())
        if (points.isEmpty()) return
        if (points.size == 1) {
            map.controller.setZoom(15.0)
            map.controller.setCenter(points[0])
            return
        }
        val box = BoundingBox.fromGeoPointsSafe(points)
        map.zoomToBoundingBox(box.increaseByScale(1.25f), false, (32 * density).toInt())
    }

    private fun setPins(items: List<*>) {
        markers.forEach { map.overlays.remove(it) }
        markers.clear()
        for (raw in items) {
            val item = raw as? Map<*, *> ?: continue
            val id = item["id"] as? String ?: continue
            val lat = (item["lat"] as? Number)?.toDouble() ?: continue
            val lng = (item["lng"] as? Number)?.toDouble() ?: continue
            val kind = item["kind"] as? String ?: "place"
            val marker = Marker(map).apply {
                position = GeoPoint(lat, lng)
                title = item["title"] as? String
                snippet = item["subtitle"] as? String
                setAnchor(Marker.ANCHOR_CENTER, Marker.ANCHOR_CENTER)
                setIcon(pinIcon(kind, if (kind == "stop") id.substringAfterLast(':') else null))
                setOnMarkerClickListener { m, _ ->
                    if (kind == "stop") {
                        if (m.isInfoWindowShown) m.closeInfoWindow() else m.showInfoWindow()
                    } else {
                        channel.invokeMethod("select", id)
                    }
                    true
                }
            }
            markers.add(marker)
            map.overlays.add(marker)
        }
        map.invalidate()
    }

    /** Renkli yuvarlak iğne; rota duraklarında numara yazılı. */
    private fun pinIcon(kind: String, label: String?): BitmapDrawable {
        val color = when (kind) {
            "stop" -> Color.rgb(33, 140, 89)
            "pharmacy" -> Color.rgb(199, 28, 23)
            "business" -> Color.rgb(237, 105, 28)
            "taxi" -> Color.rgb(245, 179, 0)
            "atm" -> Color.rgb(33, 140, 89)
            "parking" -> Color.rgb(41, 97, 217)
            "wc" -> Color.rgb(26, 153, 166)
            "charging" -> Color.rgb(115, 77, 204)
            "fuel" -> Color.rgb(204, 51, 64)
            else -> Color.rgb(38, 143, 196)
        }
        val size = ((if (label != null) 26 else 22) * density).toInt()
        val bmp = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val c = Canvas(bmp)
        val r = size / 2f
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        paint.color = Color.WHITE
        c.drawCircle(r, r, r, paint)
        paint.color = color
        c.drawCircle(r, r, r - 2.5f * density, paint)
        if (label != null) {
            paint.color = Color.WHITE
            paint.textSize = 12 * density
            paint.isFakeBoldText = true
            paint.textAlign = Paint.Align.CENTER
            c.drawText(label, r, r - (paint.descent() + paint.ascent()) / 2, paint)
        } else {
            paint.color = Color.WHITE
            c.drawCircle(r, r, r * 0.3f, paint)
        }
        return BitmapDrawable(map.resources, bmp)
    }
}
