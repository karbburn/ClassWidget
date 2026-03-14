package com.example.classwidget

import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONObject

class ListRemoteViewsService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return ListRemoteViewsFactory(this.applicationContext)
    }
}

class ListRemoteViewsFactory(private val context: Context) : RemoteViewsService.RemoteViewsFactory {
    
    private var eventsList: JSONArray = JSONArray()
    private var showProfessorNames: Boolean = true

    override fun onCreate() {}

    override fun onDataSetChanged() {
        val widgetData = HomeWidgetPlugin.getData(context)
        val jsonString = widgetData.getString("today_schedule", "{}")
        
        try {
            val jsonObject = JSONObject(jsonString)
            eventsList = jsonObject.optJSONArray("events") ?: JSONArray()
            showProfessorNames = jsonObject.optBoolean("showProfessorNames", true)
        } catch (e: Exception) {
            eventsList = JSONArray()
        }
    }

    override fun onDestroy() {}

    override fun getCount(): Int = eventsList.length()

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_item)
        
        try {
            val event = eventsList.getJSONObject(position)
            val id = event.optInt("id", -1)
            val title = event.optString("title", "Unknown")
            val time = event.optString("time", "")
            val professor = event.optString("professor", "")
            val isCurrent = event.optBoolean("isCurrent", false)
            val type = event.optString("type", "class")

            views.setTextViewText(R.id.item_title, title)
            
            val subtitle = if (type == "task") {
                if (professor.isNotEmpty() && professor != "null") "Due: $time • $professor" else "Due: $time"
            } else {
                if (showProfessorNames && professor.isNotEmpty() && professor != "null") "$time • $professor" else time
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
                
                // Intent to complete task
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
