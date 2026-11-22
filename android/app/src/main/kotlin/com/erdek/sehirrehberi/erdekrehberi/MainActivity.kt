package com.erdek.sehirrehberi.erdekrehberi

import android.content.Intent
import android.os.Build
import android.provider.CalendarContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar
import java.util.TimeZone

/**
 * iOS AppDelegate'teki yerel kanalların Android karşılıkları:
 *  - erdek/system   : paylaş, sürüm, takvime ekle, değerlendir (Android'de sessiz)
 *  - erdek/location : tek seferlik konum (LocationHelper)
 *  - erdek/widget   : ana ekran widget verisi (WidgetStore)
 *  - erdek/map      : harita görünümü (ErdekMapFactory, OpenStreetMap)
 */
class MainActivity : FlutterActivity() {
    private lateinit var location: LocationHelper

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        location = LocationHelper(this)

        MethodChannel(messenger, "erdek/system").setMethodCallHandler { call, result ->
            when (call.method) {
                "share" -> {
                    val text = call.argument<String>("text") ?: ""
                    val send = Intent(Intent.ACTION_SEND).apply {
                        type = "text/plain"
                        putExtra(Intent.EXTRA_TEXT, text)
                    }
                    startActivity(Intent.createChooser(send, null))
                    result.success(null)
                }
                "requestReview" -> result.success(null)
                "appVersion" -> {
                    val info = if (Build.VERSION.SDK_INT >= 33) {
                        packageManager.getPackageInfo(packageName, android.content.pm.PackageManager.PackageInfoFlags.of(0))
                    } else {
                        @Suppress("DEPRECATION")
                        packageManager.getPackageInfo(packageName, 0)
                    }
                    result.success(info.versionName)
                }
                "addToCalendar" -> result.success(addToCalendar(call.arguments as? Map<*, *>))
                else -> result.notImplemented()
            }
        }

        MethodChannel(messenger, "erdek/location").setMethodCallHandler { call, result ->
            if (call.method == "current") location.current(result) else result.notImplemented()
        }

        MethodChannel(messenger, "erdek/widget").setMethodCallHandler { call, result ->
            if (call.method == "update") {
                WidgetStore.save(this, call.arguments as? String ?: "")
                WidgetStore.refreshAll(this)
                result.success(null)
            } else {
                result.notImplemented()
            }
        }

        flutterEngine.platformViewsController.registry
            .registerViewFactory("erdek/map", ErdekMapFactory(messenger))
    }

    /** Takvim uygulamasının "Etkinlik ekle" ekranını hazır bilgilerle açar (izin gerekmez). */
    private fun addToCalendar(args: Map<*, *>?): String {
        if (args == null) return "unavailable"
        fun millis(key: String): Long? {
            val p = (args[key] as? List<*>)?.mapNotNull { (it as? Number)?.toInt() } ?: return null
            if (p.size < 5) return null
            val c = Calendar.getInstance(TimeZone.getTimeZone("Europe/Istanbul"))
            c.clear()
            c.set(p[0], p[1] - 1, p[2], p[3], p[4])
            return c.timeInMillis
        }
        val start = millis("start") ?: return "unavailable"
        val end = millis("end") ?: start
        val notes = listOfNotNull(args["notes"] as? String, args["url"] as? String).joinToString("\n\n")
        val intent = Intent(Intent.ACTION_INSERT).apply {
            data = CalendarContract.Events.CONTENT_URI
            putExtra(CalendarContract.Events.TITLE, args["title"] as? String ?: "")
            putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, start)
            putExtra(CalendarContract.EXTRA_EVENT_END_TIME, end)
            putExtra(CalendarContract.EXTRA_EVENT_ALL_DAY, args["allDay"] as? Boolean ?: false)
            (args["location"] as? String)?.let { putExtra(CalendarContract.Events.EVENT_LOCATION, it) }
            if (notes.isNotEmpty()) putExtra(CalendarContract.Events.DESCRIPTION, notes)
        }
        return try {
            startActivity(intent)
            "saved"
        } catch (e: Exception) {
            "unavailable"
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == LocationHelper.REQUEST_CODE) location.onPermissionResult(grantResults)
    }
}
