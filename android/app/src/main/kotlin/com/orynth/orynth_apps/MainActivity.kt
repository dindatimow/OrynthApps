package com.orynth.orynth_apps

import android.content.pm.ApplicationInfo
import android.os.Build
import android.os.Bundle
import android.os.Debug
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "orynth_apps/security"

    private val isDebuggableBuild: Boolean
        get() = (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Blokir screenshot, screen recording & thumbnail di recent apps (hanya build release).
        if (!isDebuggableBuild) {
            window.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE
            )
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "check") {
                    result.success(
                        mapOf(
                            "rooted" to isRooted(),
                            "debugger" to (Debug.isDebuggerConnected() || Debug.waitingForDebugger())
                        )
                    )
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun isRooted(): Boolean {
        if (Build.TAGS?.contains("test-keys") == true) return true
        val paths = arrayOf(
            "/system/app/Superuser.apk", "/sbin/su", "/system/bin/su", "/system/xbin/su",
            "/data/local/xbin/su", "/data/local/bin/su", "/system/sd/xbin/su",
            "/system/bin/failsafe/su", "/data/local/su", "/su/bin/su",
            "/system/xbin/daemonsu", "/magisk"
        )
        return paths.any { File(it).exists() }
    }
}
