package com.example.classwidget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject

class ClassWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            // Feature #7: Widget Size Support
            val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
            val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)

            val layoutId = when {
                minHeight < 100 -> R.layout.widget_layout_small
                minWidth > 250 -> R.layout.widget_layout_large
                else -> R.layout.widget_layout
            }

            val views = RemoteViews(context.packageName, layoutId)
            
            // Feature #11: Tap to Open App
            val activityIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            val pendingIntent = PendingIntent.getActivity(
                context, 0, activityIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)

            // Setup List Adapter
            val adapterIntent = Intent(context, ListRemoteViewsService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            }
            views.setRemoteAdapter(R.id.widget_list, adapterIntent)
            views.setPendingIntentTemplate(R.id.widget_list, pendingIntent)
            views.setEmptyView(R.id.widget_list, R.id.empty_view)

            // Feature #15/18: Info Header & Countdown
            val jsonString = widgetData.getString("today_schedule", "{}") ?: "{}"
            try {
                val root = JSONObject(jsonString)
                val dayName = root.optString("dayName", "Today")
                views.setTextViewText(R.id.widget_title, dayName)

                if (root.has("nextTitle")) {
                    val nextText = "Next: ${root.getString("nextTitle")} in ${root.getInt("minutesUntilNext")}m"
                    views.setTextViewText(R.id.next_class_info, nextText)
                    views.setViewVisibility(R.id.next_class_info, View.VISIBLE)
                } else {
                    views.setViewVisibility(R.id.next_class_info, View.GONE)
                }
            } catch (e: Exception) {
                views.setTextViewText(R.id.widget_title, "ClassWidget")
            }
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.widget_list)
        }
    }
}
