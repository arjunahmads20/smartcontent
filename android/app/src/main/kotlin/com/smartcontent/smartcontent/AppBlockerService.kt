package com.smartcontent.smartcontent

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.widget.Toast

class AppBlockerService : AccessibilityService() {
    companion object {
        var blockedApps: List<String> = emptyList()
        private const val TAG = "AppBlockerService"
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString() ?: return

            Log.d(TAG, "Window changed to package: $packageName")
            
            // Check if it's a blocked app and it's not our own app
            if (blockedApps.contains(packageName) && packageName != applicationContext.packageName) {
                Log.d(TAG, "Blocked app detected: $packageName. Redirecting to SmartContent.")
                
                // Show a toast message
                Toast.makeText(applicationContext, "This app is blocked by SmartContent", Toast.LENGTH_SHORT).show()
                
                // Launch our app to the foreground
                val intent = Intent(this, MainActivity::class.java).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                }
                startActivity(intent)
            }
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "AppBlockerService interrupted")
    }
}
