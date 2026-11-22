package com.erdek.sehirrehberi.erdekrehberi

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONObject
import java.time.OffsetDateTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter

/**
 * Ana ekran widget'ları (iOS ErdekWidget karşılığı). Veri uygulamadan gelir
 * (HomeWidgetSync, 'erdek/widget' kanalı) ve günlerce yetecek kadar ileriyi kapsar;
 * widget her vakit/sefer değişiminde kendini yeniler.
 */
object WidgetStore {
    private const val PREFS = "erdek_widget"
    private const val KEY = "widget_data"
    private val zone: ZoneId = ZoneId.of("Europe/Istanbul")
    private val hhmm: DateTimeFormatter = DateTimeFormatter.ofPattern("HH:mm")

    fun save(context: Context, json: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(KEY, json).apply()
    }

    private fun load(context: Context): JSONObject? = try {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, null)?.let { JSONObject(it) }
    } catch (e: Exception) {
        null
    }

    fun refreshAll(context: Context) {
        for (cls in listOf(PrayerWidget::class.java, PharmacyWidget::class.java, TripWidget::class.java)) {
            val ids = AppWidgetManager.getInstance(context).getAppWidgetIds(ComponentName(context, cls))
            if (ids.isEmpty()) continue
            context.sendBroadcast(Intent(context, cls).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            })
        }
    }

    private fun parse(s: String): OffsetDateTime? = try {
        OffsetDateTime.parse(s)
    } catch (e: Exception) {
        null
    }

    fun time(t: OffsetDateTime): String = t.atZoneSameInstant(zone).format(hhmm)

    data class Prayer(val name: String, val at: OffsetDateTime)
    data class Trip(val mode: String, val route: String, val at: OffsetDateTime)
    data class Duty(val names: List<String>, val to: OffsetDateTime)

    fun prayers(context: Context): List<Prayer> {
        val arr = load(context)?.optJSONArray("prayers") ?: return emptyList()
        return (0 until arr.length()).mapNotNull { i ->
            val o = arr.optJSONObject(i) ?: return@mapNotNull null
            parse(o.optString("at"))?.let { Prayer(o.optString("name"), it) }
        }.sortedBy { it.at }
    }

    fun trips(context: Context): List<Trip> {
        val arr = load(context)?.optJSONArray("departures") ?: return emptyList()
        return (0 until arr.length()).mapNotNull { i ->
            val o = arr.optJSONObject(i) ?: return@mapNotNull null
            parse(o.optString("at"))?.let { Trip(o.optString("mode"), o.optString("route"), it) }
        }.sortedBy { it.at }
    }

    fun dutyNow(context: Context, now: OffsetDateTime): Duty? {
        val arr = load(context)?.optJSONArray("duties") ?: return null
        for (i in 0 until arr.length()) {
            val o = arr.optJSONObject(i) ?: continue
            val from = parse(o.optString("from")) ?: continue
            val to = parse(o.optString("to")) ?: continue
            if (!now.isBefore(from) && now.isBefore(to)) {
                val names = o.optJSONArray("names") ?: continue
                return Duty((0 until names.length()).map { names.optString(it) }, to)
            }
        }
        return null
    }

    /** Uygulamayı açan dokunma. */
    fun openApp(context: Context): PendingIntent = PendingIntent.getActivity(
        context, 0,
        Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    /** [at] anında widget'ı yenile (izin gerektirmeyen, yaklaşık alarm). */
    fun scheduleRefresh(context: Context, cls: Class<*>, at: OffsetDateTime?) {
        if (at == null) return
        val ids = AppWidgetManager.getInstance(context).getAppWidgetIds(ComponentName(context, cls))
        val intent = Intent(context, cls).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
        }
        val pi = PendingIntent.getBroadcast(context, cls.name.hashCode(), intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.set(AlarmManager.RTC, at.toInstant().toEpochMilli() + 30_000, pi)
    }
}

private fun now(): OffsetDateTime = OffsetDateTime.now()

class PrayerWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val n = now()
        val list = WidgetStore.prayers(context)
        val nextIndex = list.indexOfFirst { it.at.isAfter(n) }
        val views = RemoteViews(context.packageName, R.layout.widget_card)
        views.setTextViewText(R.id.widget_title, "Sıradaki vakit")
        if (nextIndex < 0) {
            views.setTextViewText(R.id.widget_main, "—")
            views.setTextViewText(R.id.widget_sub, "Uygulamayı açın")
        } else {
            val next = list[nextIndex]
            views.setTextViewText(R.id.widget_main, "${next.name} ${WidgetStore.time(next.at)}")
            val after = list.getOrNull(nextIndex + 1)
            views.setTextViewText(R.id.widget_sub, if (after != null) "Sonra: ${after.name} ${WidgetStore.time(after.at)}" else "")
        }
        views.setOnClickPendingIntent(R.id.widget_root, WidgetStore.openApp(context))
        ids.forEach { manager.updateAppWidget(it, views) }
        WidgetStore.scheduleRefresh(context, PrayerWidget::class.java, list.getOrNull(nextIndex)?.at)
    }
}

class PharmacyWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val duty = WidgetStore.dutyNow(context, now())
        val views = RemoteViews(context.packageName, R.layout.widget_card)
        views.setTextViewText(R.id.widget_title, "Nöbetçi eczane")
        views.setTextViewText(R.id.widget_main, duty?.names?.firstOrNull() ?: "—")
        views.setTextViewText(
            R.id.widget_sub,
            when {
                duty == null -> "Uygulamayı açın"
                duty.names.size > 1 -> duty.names.drop(1).joinToString(", ")
                else -> "Yarın 08:30'a kadar"
            },
        )
        views.setOnClickPendingIntent(R.id.widget_root, WidgetStore.openApp(context))
        ids.forEach { manager.updateAppWidget(it, views) }
        WidgetStore.scheduleRefresh(context, PharmacyWidget::class.java, duty?.to)
    }
}

class TripWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val n = now()
        val next = WidgetStore.trips(context).firstOrNull { it.at.isAfter(n) }
        val views = RemoteViews(context.packageName, R.layout.widget_card)
        views.setTextViewText(R.id.widget_title, if (next?.mode == "bus") "Sıradaki otobüs" else "Sıradaki sefer")
        if (next == null) {
            views.setTextViewText(R.id.widget_main, "—")
            views.setTextViewText(R.id.widget_sub, "Uygulamayı açın")
        } else {
            views.setTextViewText(R.id.widget_main, WidgetStore.time(next.at))
            views.setTextViewText(R.id.widget_sub, next.route)
        }
        views.setOnClickPendingIntent(R.id.widget_root, WidgetStore.openApp(context))
        ids.forEach { manager.updateAppWidget(it, views) }
        WidgetStore.scheduleRefresh(context, TripWidget::class.java, next?.at)
    }
}
