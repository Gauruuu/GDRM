package com.hlp.gdrm_ecosystem

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.gdrm.ecosystem/security"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Screenshot / screen-recording prevention for DRM-protected content.
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }

    private fun isUsbDebuggingEnabled(): Boolean {
        return try {
            Settings.Global.getInt(contentResolver, Settings.Global.ADB_ENABLED, 0) == 1
        } catch (e: Exception) {
            try {
                @Suppress("DEPRECATION")
                Settings.Secure.getInt(contentResolver, Settings.Secure.ADB_ENABLED, 0) == 1
            } catch (_: Exception) {
                false
            }
        }
    }

    private fun openDeveloperSettings() {
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(intent)
        } catch (e: Exception) {
            try {
                val intent = Intent(Settings.ACTION_SETTINGS)
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                startActivity(intent)
            } catch (_: Exception) {}
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setSecureWindow" -> {
                        window.setFlags(
                            WindowManager.LayoutParams.FLAG_SECURE,
                            WindowManager.LayoutParams.FLAG_SECURE
                        )
                        result.success(null)
                    }

                    "isUsbDebuggingEnabled" -> {
                        result.success(isUsbDebuggingEnabled())
                    }

                    "openDeveloperSettings" -> {
                        openDeveloperSettings()
                        result.success(null)
                    }

                    "readContentUri" -> {
                        val uriString = call.argument<String>("uri")
                        if (uriString == null) {
                            result.error("NO_URI", "No URI was provided", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val uri = Uri.parse(uriString)
                            val bytes = contentResolver.openInputStream(uri)?.use { it.readBytes() }
                            if (bytes != null) {
                                result.success(bytes)
                            } else {
                                result.error("READ_FAILED", "ContentResolver returned no stream for this URI", null)
                            }
                        } catch (e: Exception) {
                            result.error("READ_ERROR", e.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }
}