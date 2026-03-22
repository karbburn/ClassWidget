package com.example.classwidget

import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class ListRemoteViewsService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return ListRemoteViewsFactory(this.applicationContext)
    }
}

class ListRemoteViewsFactory(private val context: Context) : RemoteViewsService.RemoteViewsFactory {
    
    private var todayEvents: JSONArray = JSONArray()
    private var showProfessorNames: Boolean = true

    override fun onCreate() {}

    override fun onDataSetChanged() {
        val widgetData = HomeWidgetPlugin.getData(context)
        val jsonString = widgetData.getString("schedule_data", "{}")
        
        // Dynamically determine "today" from system clock
        val todayStr = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
        
        todayEvents = JSONArray()
        try {
            val jsonObject = JSONObject(jsonString)
            showProfessorNames = jsonObject.optBoolean("showProfessorNames", true)
            val allEvents = jsonObject.optJSONArray("events") ?: JSONArray()
            
            for (i in 0 until allEvents.length()) {
                val event = allEvents.getJSONObject(i)
                val eventDate = event.optString("date", "")
                if (eventDate == todayStr) {
                    val type = event.optString("type", "class")
                    val completed = event.optBoolean("completed", false)
                    if (type == "class" || !completed) {
                        todayEvents.put(event)
                    }
                }
            }
        } catch (e: Exception) {
            todayEvents = JSONArray()
        }
    }

    override fun onDestroy() {}

    override fun getCount(): Int = todayEvents.length()

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_item)
        
        try {
            val event = todayEvents.getJSONObject(position)
            val id = event.optInt("id", -1)
            val title = event.optString("title", "Unknown")
            val startTime = event.optString("startTime", "")
            val endTime = event.optString("endTime", "")
            val professor = event.optString("professor", "")
            val type = event.optString("type", "class")

            // Dynamically compute isCurrent using system time
            val currentTime = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date())
            val isCurrent = type == "class" && startTime.isNotEmpty() && endTime.isNotEmpty() &&
                            currentTime >= startTime && currentTime <= endTime

            val timeDisplay = if (startTime.isEmpty()) "All Day" else "$startTime - $endTime"

            views.setTextViewText(R.id.item_title, title)
            
            val subtitle = if (type == "task") {
                if (professor.isNotEmpty() && professor != "null") "Due: $timeDisplay • $professor" else "Due: $timeDisplay"
            } else {
                if (showProfessorNames && professor.isNotEmpty() && professor != "null") "$timeDisplay • $professor" else timeDisplay
            }
            views.setTextViewText(R.id.item_subtitle, subtitle)

            if (isCurrent) {
                views.setViewVisibility(R.id.current_indicator, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.current_indicator, View.GONE)
            }

            // Task Specific Logic
            if (type == "task") {
                views.setViewVisibility(R.id.task_checkbox_container, View.VISIBLE)
                
                val completeFillIn = Intent().apply {
                    action = ClassWidgetProvider.ACTION_COMPLETE_TASK
                    putExtra(ClassWidgetProvider.EXTRA_TASK_ID, id)
                }
                views.setOnClickFillInIntent(R.id.task_checkbox_container, completeFillIn)
            } else {
                views.setViewVisibility(R.id.task_checkbox_container, View.GONE)
            }

            // Intent to open app for the main info section
            val openFillIn = Intent().apply {
                action = ClassWidgetProvider.ACTION_OPEN_APP
            }
            views.setOnClickFillInIntent(R.id.info_container, openFillIn)
            
        } catch (e: Exception) {
            e.printStackTrace()
        }

        return views
    }

    override fun getLoadingView(): RemoteViews? = null
    override fun getViewTypeCount(): Int = 1
    override fun getItemId(position: Int): Long = position.toLong()
    override fun hasStableIds(): Boolean = true
}
