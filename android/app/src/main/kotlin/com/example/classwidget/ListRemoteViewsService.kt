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
        val jsonString = widgetData.getString(AppConstants.KEY_SCHEDULE_DATA, "{}")
        
        // Dynamically determine "today" from system clock
        val todayStr = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
        
        todayEvents = JSONArray()
        try {
            val jsonObject = JSONObject(jsonString)
            showProfessorNames = jsonObject.optBoolean(AppConstants.KEY_SHOW_PROFESSOR_NAMES, true)
            val allEvents = jsonObject.optJSONArray(AppConstants.KEY_EVENTS) ?: JSONArray()
            
            for (i in 0 until allEvents.length()) {
                val event = allEvents.getJSONObject(i)
                val eventDate = event.optString(AppConstants.KEY_DATE, "")
                if (eventDate == todayStr) {
                    val type = event.optString(AppConstants.KEY_TYPE, "class")
                    val completed = event.optBoolean(AppConstants.KEY_COMPLETED, false)
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
            val id = event.optInt(AppConstants.KEY_ID, -1)
            val title = event.optString(AppConstants.KEY_TITLE, "Unknown")
            val startTime = event.optString(AppConstants.KEY_START_TIME, "")
            val endTime = event.optString(AppConstants.KEY_END_TIME, "")
            val professor = event.optString(AppConstants.KEY_PROFESSOR, "")
            val type = event.optString(AppConstants.KEY_TYPE, "class")

            // Dynamically compute isCurrent using system time
            val currentTime = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date())
            val isCurrent = if (type == "class" && startTime.isNotEmpty() && endTime.isNotEmpty()) {
                try {
                    val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
                    val currentParsed = timeFormat.parse(currentTime)
                    val startParsed = timeFormat.parse(startTime)
                    val endParsed = timeFormat.parse(endTime)
                    currentParsed != null && startParsed != null && endParsed != null &&
                        !currentParsed.before(startParsed) && !currentParsed.after(endParsed)
                } catch (e: Exception) {
                    false
                }
            } else {
                false
            }

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
