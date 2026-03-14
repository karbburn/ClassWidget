package com.example.classwidget

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray
import org.json.JSONObject

class ListRemoteViewsService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return ListRemoteViewsFactory(this.applicationContext)
    }
}

class ListRemoteViewsFactory(private val context: Context) : RemoteViewsService.RemoteViewsFactory {
    private var eventList: List<JSONObject> = listOf()

    override fun onCreate() {}

    override fun onDataSetChanged() {
        val prefs = context.getSharedPreferences("HomeWidgetPrefs", Context.MODE_PRIVATE)
        val jsonString = prefs.getString("today_schedule", "{}") ?: "{}"
        
        try {
            val root = JSONObject(jsonString)
            val jsonArray = root.optJSONArray("events") ?: JSONArray()
            
            val newList = mutableListOf<JSONObject>()
            for (i in 0 until jsonArray.length()) {
                newList.add(jsonArray.getJSONObject(i))
            }
            eventList = newList
        } catch (e: Exception) {
            eventList = listOf()
        }
    }

    override fun onDestroy() {}

    override fun getCount(): Int = eventList.size

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_item)
        val event = eventList[position]
        
        val title = event.optString("title", "No Title")
        val isCurrent = event.optBoolean("isCurrent", false)
        
        // Feature #17: Current Class Highlight
        val displayTitle = if (isCurrent) "▶ $title" else title
        views.setTextViewText(R.id.item_title, displayTitle)
        views.setTextViewText(R.id.item_time, event.optString("time", ""))
        
        if (isCurrent) {
            views.setTextColor(R.id.item_title, Color.parseColor("#4CAF50")) // Green for current
        } else {
            views.setTextColor(R.id.item_title, Color.WHITE)
        }
        
        // Feature #11: Tap Action (Fill in the intent)
        val fillInIntent = Intent()
        views.setOnClickFillInIntent(R.id.widget_item_container, fillInIntent)
        
        return views
    }

    override fun getLoadingView(): RemoteViews? = null
    override fun getViewTypeCount(): Int = 1
    override fun getItemId(position: Int): Long = position.toLong()
    override fun hasStableIds(): Boolean = true
}
