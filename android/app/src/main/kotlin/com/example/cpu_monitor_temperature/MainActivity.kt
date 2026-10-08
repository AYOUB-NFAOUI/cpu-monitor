package com.cpu.monitor.temperature

import android.content.Context
import android.hardware.display.DisplayManager
import android.os.Build
import android.util.DisplayMetrics
import android.view.Display
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Date
import java.util.Locale
import java.util.TimeZone

class MainActivity : FlutterActivity() {

    private val channelName = "cpu_monitor/device"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getDisplayInfo" -> {
                        try {
                            result.success(collectInfo())
                        } catch (e: Exception) {
                            result.error("UNAVAILABLE", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    @Suppress("DEPRECATION")
    private fun collectInfo(): Map<String, Any?> {
        val displayManager = getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
        val display = displayManager.getDisplay(Display.DEFAULT_DISPLAY)

        val metrics = DisplayMetrics()
        display.getRealMetrics(metrics)

        // Fréquences d'écran supportées (ex. 120, 96, 60, 48)
        val rates: List<Int> = if (Build.VERSION.SDK_INT >= 23) {
            display.supportedModes
                .map { Math.round(it.refreshRate) }
                .distinct()
                .sortedDescending()
        } else {
            listOf(Math.round(display.refreshRate))
        }

        // Types HDR supportés : 1 Dolby Vision, 2 HDR10, 3 HLG, 4 HDR10+
        val hdrTypes: IntArray = when {
            Build.VERSION.SDK_INT >= 34 -> display.mode.supportedHdrTypes
            Build.VERSION.SDK_INT >= 26 ->
                display.hdrCapabilities?.supportedHdrTypes ?: IntArray(0)
            else -> IntArray(0)
        }
        val hdrNames: List<String> = hdrTypes.sorted().mapNotNull {
            when (it) {
                1 -> "Dolby Vision"
                2 -> "HDR10"
                3 -> "HLG"
                4 -> "HDR10+"
                else -> null
            }
        }

        val tz = TimeZone.getDefault()
        val inDst = tz.inDaylightTime(Date())
        val tzName = tz.getDisplayName(inDst, TimeZone.LONG, Locale.ENGLISH)
        val offsetMinutes = tz.getOffset(System.currentTimeMillis()) / 60000

        return mapOf(
            "widthPx" to metrics.widthPixels,
            "heightPx" to metrics.heightPixels,
            "xdpi" to metrics.xdpi.toDouble(),
            "ydpi" to metrics.ydpi.toDouble(),
            "densityDpi" to metrics.densityDpi,
            "refreshRates" to rates,
            "hdr" to hdrNames,
            "jvm" to (System.getProperty("java.vm.version") ?: ""),
            "tzId" to tz.id,
            "tzName" to tzName,
            "tzOffsetMinutes" to offsetMinutes
        )
    }
}
