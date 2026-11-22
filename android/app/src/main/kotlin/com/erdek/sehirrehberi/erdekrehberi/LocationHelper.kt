package com.erdek.sehirrehberi.erdekrehberi

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodChannel

/**
 * Tek seferlik konum ('erdek/location' → current). Konum yalnızca telefonda kullanılır.
 * Hata kodları Dart tarafıyla aynı: "denied" (izin yok), "unavailable".
 */
class LocationHelper(private val activity: Activity) {
    companion object {
        const val REQUEST_CODE = 4107
        private const val TIMEOUT_MS = 15_000L
        private const val FRESH_MS = 2 * 60 * 1000L
    }

    private var pending: MethodChannel.Result? = null
    private val main = Handler(Looper.getMainLooper())

    private fun granted(): Boolean =
        activity.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
            activity.checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED

    fun current(result: MethodChannel.Result) {
        if (granted()) {
            fetch(result)
            return
        }
        pending?.error("unavailable", "Yeni istek geldi", null)
        pending = result
        activity.requestPermissions(
            arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION),
            REQUEST_CODE,
        )
    }

    fun onPermissionResult(grantResults: IntArray) {
        val result = pending ?: return
        pending = null
        if (grantResults.any { it == PackageManager.PERMISSION_GRANTED }) fetch(result) else result.error("denied", "Konum izni yok", null)
    }

    @Suppress("MissingPermission")
    private fun fetch(result: MethodChannel.Result) {
        val lm = activity.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val providers = listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER)
            .filter { runCatching { lm.isProviderEnabled(it) }.getOrDefault(false) }
        if (providers.isEmpty()) {
            result.error("unavailable", "Konum servisleri kapalı", null)
            return
        }
        val last = providers.mapNotNull { runCatching { lm.getLastKnownLocation(it) }.getOrNull() }
            .maxByOrNull { it.time }
        if (last != null && System.currentTimeMillis() - last.time < FRESH_MS) {
            reply(result, last)
            return
        }

        var done = false
        val listeners = mutableListOf<LocationListener>()
        fun finish(loc: Location?) {
            if (done) return
            done = true
            listeners.forEach { runCatching { lm.removeUpdates(it) } }
            val best = loc ?: last
            if (best != null) reply(result, best) else result.error("unavailable", "Konum alınamadı", null)
        }
        for (provider in providers) {
            val listener = object : LocationListener {
                override fun onLocationChanged(location: Location) = finish(location)
                @Deprecated("Deprecated in Java")
                override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
                override fun onProviderEnabled(provider: String) {}
                override fun onProviderDisabled(provider: String) {}
            }
            listeners.add(listener)
            runCatching { lm.requestLocationUpdates(provider, 0L, 0f, listener, Looper.getMainLooper()) }
        }
        main.postDelayed({ finish(null) }, TIMEOUT_MS)
    }

    private fun reply(result: MethodChannel.Result, loc: Location) {
        result.success(mapOf("lat" to loc.latitude, "lng" to loc.longitude))
    }
}
