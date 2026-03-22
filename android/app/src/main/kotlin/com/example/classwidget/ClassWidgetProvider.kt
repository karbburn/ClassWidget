package com.example.classwidget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.widget.RemoteViews
import android.widget.Toast
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class ClassWidgetProvider : AppWidgetProvider() {
 
    companion object {
        const val ACTION_COMPLETE_TASK = "com.example.classwidget.ACTION_COMPLETE_TASK"
        const val ACTION_OPEN_APP = "com.example.classwidget.ACTION_OPEN_APP"
        const val EXTRA_TASK_ID = "extra_task_id"
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_COMPLETE_TASK -> {
                val taskId = intent.getIntExtra(EXTRA_TASK_ID, -1)
                if (taskId != -1) {
                    updateTaskCompletion(context, taskId)
                }
            }
            ACTION_OPEN_APP -> {
                val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                if (launchIntent != null) {
                    launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    context.startActivity(launchIntent)
                }
            }
            "android.intent.action.DATE_CHANGED",
            "android.intent.action.TIME_SET",
            "android.intent.action.TIMEZONE_CHANGED",
            "android.intent.action.TIME_CHANGED" -> {
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val thisWidget = android.content.ComponentName(context, ClassWidgetProvider::class.java)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
                
                // Trigger Flutter background sync for fresh data
                try {
                    HomeWidgetBackgroundIntent.getBroadcast(
                        context,
                        Uri.parse("homeWidget://update")
                    ).send()
                } catch (e: Exception) {
                    e.printStackTrace()
                }
                
                // Also force the list view to re-read data (it will filter by new system date)
                appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetIds, R.id.widget_list_view)
                onUpdate(context, appWidgetManager, appWidgetIds)
            }
        }
        super.onReceive(context, intent)
    }

    private fun updateTaskCompletion(context: Context, taskId: Int) {
        try {
            val dbPath = context.getDatabasePath("class_widget_v2.db").absolutePath
            val db = android.database.sqlite.SQLiteDatabase.openDatabase(dbPath, null, android.database.sqlite.SQLiteDatabase.OPEN_READWRITE)
            db.execSQL("UPDATE events SET completed = 1 WHERE id = ?", arrayOf(taskId))
            db.close()

            // Update JSON Cache in SharedPreferences so the list UI updates immediately
            val widgetData = HomeWidgetPlugin.getData(context)
            val jsonString = widgetData.getString("schedule_data", null)
            if (jsonString != null) {
                val jsonObject = JSONObject(jsonString)
                val events = jsonObject.optJSONArray("events")
                if (events != null) {
                    val newEvents = JSONArray()
                    for (i in 0 until events.length()) {
                        val event = events.getJSONObject(i)
                        if (event.optInt("id") != taskId) {
                            newEvents.put(event)
                        }
                    }
                    jsonObject.put("events", newEvents)
                    
                    val editor = widgetData.edit()
                    editor.putString("schedule_data", jsonObject.toString())
                    editor.apply()
                }
            }

            Toast.makeText(context, "Task marked as completed!", Toast.LENGTH_SHORT).show()

            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = android.content.ComponentName(context, ClassWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            
            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetIds, R.id.widget_list_view)
            onUpdate(context, appWidgetManager, appWidgetIds)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }


    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
            updateAppWidget(context, appWidgetManager, appWidgetId, options)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        updateAppWidget(context, appWidgetManager, appWidgetId, newOptions)
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        options: Bundle
    ) {
        val widgetData = HomeWidgetPlugin.getData(context)
        val jsonString = widgetData.getString("schedule_data", "{}")
        
        // Always derive "today" from system clock
        val todayStr = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
        val currentDayName = SimpleDateFormat("EEEE", Locale.getDefault()).format(Date())
        val currentTime = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date())

        // Filter events for today
        var todayEvents = JSONArray()
        var showProfessorNames = true

        try {
            val jsonObject = JSONObject(jsonString)
            showProfessorNames = jsonObject.optBoolean("showProfessorNames", true)
            val allEvents = jsonObject.optJSONArray("events") ?: JSONArray()
            
            for (i in 0 until allEvents.length()) {
                val event = allEvents.getJSONObject(i)
                val eventDate = event.optString("date", "")
                if (eventDate == todayStr) {
                    // For classes, always include. For tasks, only incomplete.
                    val type = event.optString("type", "class")
                    val completed = event.optBoolean("completed", false)
                    if (type == "class" || !completed) {
                        todayEvents.put(event)
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        val isEmpty = todayEvents.length() == 0

        // Find next upcoming class using system time
        var nextTitle = ""
        var minutesUntilNext = -1
        try {
            val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
            val nowParsed = timeFormat.parse(currentTime)
            
            for (i in 0 until todayEvents.length()) {
                val event = todayEvents.getJSONObject(i)
                val startTime = event.optString("startTime", "")
                if (startTime.isNotEmpty() && startTime > currentTime) {
                    val nextParsed = timeFormat.parse(startTime)
                    if (nowParsed != null && nextParsed != null) {
                        minutesUntilNext = ((nextParsed.time - nowParsed.time) / 60000).toInt()
                        nextTitle = event.optString("title", "")
                    }
                    break
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // Determine layout based on dimensions
        val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
        val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)

        val layoutId = when {
            minWidth < 150 || minHeight < 110 -> R.layout.widget_layout_small
            minWidth > 250 && minHeight > 250 -> R.layout.widget_layout_large
            else -> R.layout.widget_layout
        }

        val views = RemoteViews(context.packageName, layoutId)
        
        views.setTextViewText(R.id.widget_title, "ClassWidget · $currentDayName")

        if (isEmpty) {
            views.setViewVisibility(R.id.empty_view, android.view.View.VISIBLE)
            views.setViewVisibility(R.id.widget_list_view, android.view.View.GONE)
            views.setViewVisibility(R.id.next_class_container, android.view.View.GONE)
        } else {
            views.setViewVisibility(R.id.empty_view, android.view.View.GONE)
            views.setViewVisibility(R.id.widget_list_view, android.view.View.VISIBLE)
            
            // Handle Next Class countdown
            if (minutesUntilNext >= 0) {
                views.setViewVisibility(R.id.next_class_container, android.view.View.VISIBLE)
                val timeStr = if (minutesUntilNext > 60) {
                    "${minutesUntilNext / 60}h ${minutesUntilNext % 60}m"
                } else {
                    "${minutesUntilNext}m"
                }
                views.setTextViewText(R.id.next_class_text, "Next: $nextTitle in $timeStr")
            } else {
                views.setViewVisibility(R.id.next_class_container, android.view.View.GONE)
            }

            // Set up ListView
            val intent = Intent(context, ListRemoteViewsService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
            }
            views.setRemoteAdapter(R.id.widget_list_view, intent)
            views.setEmptyView(R.id.widget_list_view, R.id.empty_view)

            val baseIntent = Intent(context, ClassWidgetProvider::class.java)
            val basePendingIntent = PendingIntent.getBroadcast(
                context, 0, baseIntent, 
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            )
            views.setPendingIntentTemplate(R.id.widget_list_view, basePendingIntent)
        }

        // Tap to open app
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
