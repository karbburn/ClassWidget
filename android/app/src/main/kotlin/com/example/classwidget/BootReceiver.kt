package com.example.classwidget

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d("ClassWidget", "Boot completed. Rescheduling widget alarms.")
            val triggerIntent = Intent(context, ClassWidgetProvider::class.java).apply {
                action = "com.example.classwidget.ACTION_BOOT"
                addFlags(Intent.FLAG_RECEIVER_FOREGROUND)
            }
            context.sendBroadcast(triggerIntent)
        }
    }
}
