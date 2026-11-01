package com.terovpn.android

import android.Manifest
import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Intent
import android.content.pm.ActivityInfo
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.net.Uri
import android.net.VpnService
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

/**
 * The Flutter UI. Channel "app/android": dataDir, startCore (with the proxy
 * off), setOn, isRunning, openUrl. The UI talks to the core itself through
 * its HTTP API on loopback.
 */
class MainActivity : FlutterActivity() {
    /** Waits for the user's answer to the VPN permission. */
    private var pendingOn: Result? = null
    /** Waits for the user's answer to the Camera permission. */
    private var pendingCamera: Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        holdPhoneUpright(resources.configuration)
        setupCutoutAndEdgeToEdge()
        super.onCreate(savedInstanceState)
    }

    /**
     * Fixes screen cropping at camera cutout and ensures edge-to-edge drawing.
     * Prevents artificial top padding so toast notifications align with real camera cutouts.
     */
    private fun setupCutoutAndEdgeToEdge() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                val params = window.attributes
                params.layoutInDisplayCutoutMode =
                    android.view.WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
                window.attributes = params
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                window.isStatusBarContrastEnforced = false
                window.isNavigationBarContrastEnforced = false
            }
            window.statusBarColor = android.graphics.Color.TRANSPARENT
            window.navigationBarColor = android.graphics.Color.TRANSPARENT
            androidx.core.view.WindowCompat.setDecorFitsSystemWindows(window, false)
        } catch (_: Throwable) {
        }
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        holdPhoneUpright(newConfig)
    }

    override fun onPostResume() {
        super.onPostResume()
        enableHighRefreshRate()
    }

    /**
     * Enables 120Hz / highest available display refresh rate on supported Android devices.
     * Safely executes post-resume with zero risk of crashing on emulators or legacy devices.
     */
    private fun enableHighRefreshRate() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val display = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    display
                } else {
                    @Suppress("DEPRECATION")
                    windowManager.defaultDisplay
                }
                val modes = display?.supportedModes
                if (!modes.isNullOrEmpty()) {
                    var bestMode = modes[0]
                    for (mode in modes) {
                        if (mode.refreshRate > bestMode.refreshRate) {
                            bestMode = mode
                        }
                    }
                    if (bestMode.refreshRate > 60f) {
                        val params = window.attributes
                        params.preferredDisplayModeId = bestMode.modeId
                        window.attributes = params
                    }
                }
            }
        } catch (_: Throwable) {
            // Graceful fallback
        }
    }

    /**
     * A phone stays upright (its layout is made for it); a tablet, whose
     * shorter side is 600 dp or more, turns freely. Asked again when the
     * screen changes, so a foldable follows its folding.
     */
    private fun holdPhoneUpright(config: Configuration) {
        val wanted = if (config.smallestScreenWidthDp < 600) {
            ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
        } else {
            ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
        }
        if (requestedOrientation != wanted) requestedOrientation = wanted
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app/android").setMethodCallHandler { call, result ->
            when (call.method) {
                "dataDir" -> result.success(CoreService.dataDir(this).absolutePath)
                "startCore" -> {
                    CoreService.startCore(this, on = false)
                    result.success(null)
                }
                "setOn" -> {
                    if (call.argument<Boolean>("on") != true) {
                        CoreService.turnOff(this)
                        result.success(null)
                    } else {
                        askForNotifications()
                        // The first time, Android asks the user to allow the
                        // VPN; proxy mode needs no VPN.
                        val consent = if (CoreService.usesVpn(this)) VpnService.prepare(this) else null
                        if (consent == null) {
                            turnOn(result)
                        } else {
                            pendingOn?.error("vpn_denied", "superseded", null)
                            pendingOn = result
                            startActivityForResult(consent, VPN_REQUEST)
                        }
                    }
                }
                "isRunning" -> result.success(mobile.Mobile.running())
                "isOn" -> result.success(CoreService.on)
                "isConnected" -> result.success(CoreService.connected)
                "installApk" -> {
                    val filePath = call.argument<String>("filePath") ?: ""
                    val file = java.io.File(filePath)
                    if (!file.exists()) {
                        result.error("not_found", "APK file does not exist", null)
                    } else {
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                if (!packageManager.canRequestPackageInstalls()) {
                                    val manageIntent = Intent(android.provider.Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                                        data = Uri.parse("package:$packageName")
                                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                                    }
                                    startActivity(manageIntent)
                                }
                            }
                            val uri = androidx.core.content.FileProvider.getUriForFile(
                                this,
                                "$packageName.fileprovider",
                                file
                            )
                            val intent = android.content.Intent(android.content.Intent.ACTION_VIEW).apply {
                                setDataAndType(uri, "application/vnd.android.package-archive")
                                flags = android.content.Intent.FLAG_ACTIVITY_NEW_TASK or android.content.Intent.FLAG_GRANT_READ_URI_PERMISSION
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("install_error", e.message, null)
                        }
                    }
                }
                "askNotifications" -> {
                    askForNotifications()
                    result.success(null)
                }
                "checkCamera" -> {
                    val granted = checkSelfPermission(Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
                    result.success(granted)
                }
                "requestCamera" -> {
                    if (checkSelfPermission(Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
                        result.success(true)
                    } else {
                        pendingCamera?.error("camera_denied", "superseded", null)
                        pendingCamera = result
                        requestPermissions(arrayOf(Manifest.permission.CAMERA), CAMERA_REQUEST)
                    }
                }
                "setAppIcon" -> {
                    val mode = call.argument<String>("mode") ?: "default"
                    setDynamicAppIcon(mode)
                    result.success(true)
                }
                "connectionMode" -> result.success(CoreService.connectionMode(this))
                "showSpeed" -> result.success(CoreService.showSpeed(this))
                "setShowSpeed" -> {
                    CoreService.setShowSpeed(this, call.argument<Boolean>("on") == true)
                    result.success(null)
                }
                "setConnectionMode" -> {
                    val mode = call.argument<String>("mode") ?: CoreService.MODE_VPN
                    // A running proxy switched to the VPN needs the permission
                    // first; the app turns it off and on again to ask.
                    if (CoreService.on && mode == CoreService.MODE_VPN && VpnService.prepare(this) != null) {
                        result.error("vpn_denied", "the VPN is not allowed yet", null)
                    } else {
                        CoreService.setConnectionMode(this, mode)
                        result.success(null)
                    }
                }
                "installedApps" -> inBackground(result) { installedApps() }
                "appIcon" -> {
                    val pkg = call.argument<String>("package") ?: ""
                    inBackground(result) { appIcon(pkg) }
                }
                "appRouting" -> inBackground(result) {
                    if (CoreService.appMode(this) == CoreService.MODE_EXCLUDE &&
                        CoreService.suggest(this, force = true)
                    ) {
                        CoreService.reconnect(this)
                    }
                    mapOf(
                        "mode" to CoreService.appMode(this),
                        "bypass" to CoreService.appSet(this, CoreService.BYPASS).toList(),
                        "only" to CoreService.appSet(this, CoreService.ONLY).toList(),
                        "declined" to CoreService.appSet(this, CoreService.DECLINED).toList(),
                        "region" to CoreService.regionAppList(),
                    )
                }
                "setAppRouting" -> {
                    fun set(key: String) = (call.argument<List<String>>(key) ?: emptyList()).toSet()
                    CoreService.setAppRouting(
                        this,
                        call.argument<String>("mode") ?: CoreService.MODE_EXCLUDE,
                        mapOf(
                            CoreService.BYPASS to set("bypass"),
                            CoreService.ONLY to set("only"),
                            CoreService.DECLINED to set("declined"),
                        ),
                    )
                    if (call.argument<Boolean>("apply") == true) CoreService.reconnect(this)
                    result.success(null)
                }
                "showNotification" -> {
                    val title = call.argument<String>("title") ?: "TeroVPN Update"
                    val message = call.argument<String>("message") ?: ""
                    val isReady = call.argument<Boolean>("isUpdateReady") ?: false
                    val apkPath = call.argument<String>("apkPath")
                    showSystemNotification(title, message, isReady, apkPath)
                    result.success(true)
                }
                "getCutoutInfo" -> {
                    val info = mutableMapOf<String, Any>()
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                        val cutout = window.decorView.rootWindowInsets?.displayCutout
                        if (cutout != null) {
                            val rects = cutout.boundingRects
                            if (rects.isNotEmpty()) {
                                val r = rects[0]
                                info["hasCutout"] = true
                                info["left"] = r.left
                                info["top"] = r.top
                                info["right"] = r.right
                                info["bottom"] = r.bottom
                                info["centerX"] = r.exactCenterX().toDouble()
                                info["centerY"] = r.exactCenterY().toDouble()
                            }
                        }
                    }
                    result.success(info)
                }
                "abi" -> result.success(Build.SUPPORTED_ABIS.firstOrNull() ?: "")
                "openUrl" -> {
                    val url = call.argument<String>("url") ?: ""
                    try {
                        startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
                        result.success(true)
                    } catch (e: ActivityNotFoundException) {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun setDynamicAppIcon(mode: String) {
        try {
            val pm = packageManager
            val defaultAlias = ComponentName(this, "com.terovpn.android.MainActivityDefault")
            val lightAlias = ComponentName(this, "com.terovpn.android.MainActivityLight")
            val darkAlias = ComponentName(this, "com.terovpn.android.MainActivityDark")

            val targetAlias = when (mode.lowercase()) {
                "light" -> lightAlias
                "dark" -> darkAlias
                else -> defaultAlias
            }

            val aliases = listOf(defaultAlias, lightAlias, darkAlias)
            for (alias in aliases) {
                val state = if (alias == targetAlias) {
                    PackageManager.COMPONENT_ENABLED_STATE_ENABLED
                } else {
                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED
                }
                pm.setComponentEnabledSetting(alias, state, PackageManager.DONT_KILL_APP)
            }
        } catch (_: Throwable) {
        }
    }

    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    /** Runs [work] off the UI thread and answers with its value. */
    private fun inBackground(result: Result, work: () -> Any?) {
        worker.execute {
            val value = try {
                work()
            } catch (e: Exception) {
                null
            }
            main.post { result.success(value) }
        }
    }

    /**
     * The installed apps but this one: package, name, and whether it has a
     * launcher icon.
     */
    private fun installedApps(): List<Map<String, Any>> {
        val pm = packageManager
        val launcher = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val withIcon = pm.queryIntentActivities(launcher, 0)
            .map { it.activityInfo.packageName }
            .toSet()
        @Suppress("DEPRECATION")
        return pm.getInstalledApplications(0)
            .filter { it.packageName != packageName && (it.flags and ApplicationInfo.FLAG_HAS_CODE) != 0 }
            .map {
                mapOf(
                    "package" to it.packageName,
                    "label" to it.loadLabel(pm).toString(),
                    "launcher" to (it.packageName in withIcon),
                )
            }
    }

    /** An app's icon as a small PNG. */
    private fun appIcon(pkg: String): ByteArray {
        val drawable = packageManager.getApplicationIcon(pkg)
        val size = 96
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        drawable.setBounds(0, 0, size, size)
        drawable.draw(Canvas(bitmap))
        return ByteArrayOutputStream().also { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }.toByteArray()
    }

    private fun turnOn(result: Result) {
        try {
            CoreService.turnOn(this)
            result.success(null)
        } catch (e: Exception) {
            result.error("start_failed", e.message, null)
        }
    }

    @Deprecated("The VPN permission is asked with startActivityForResult.")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != VPN_REQUEST) return
        val result = pendingOn ?: return
        pendingOn = null
        if (resultCode == RESULT_OK) turnOn(result) else result.error("vpn_denied", "the VPN was not allowed", null)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == CAMERA_REQUEST) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingCamera?.success(granted)
            pendingCamera = null
        }
    }

    override fun onDestroy() {
        if (isFinishing && !CoreService.on) CoreService.stopCore()
        super.onDestroy()
    }

    companion object {
        private const val VPN_REQUEST = 7
        private const val CAMERA_REQUEST = 8
        private const val UPDATE_CHANNEL_ID = "terovpn_updates"
        private const val UPDATE_NOTIFICATION_ID = 1002
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = android.app.NotificationChannel(
                UPDATE_CHANNEL_ID,
                "TeroVPN Updates",
                android.app.NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications for new TeroVPN releases and auto-updates"
                enableLights(true)
                lightColor = android.graphics.Color.parseColor("#6B42FF")
                enableVibration(true)
            }
            val manager = getSystemService(android.app.NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    private fun showSystemNotification(title: String, message: String, isUpdateReady: Boolean, apkPath: String?) {
        try {
            createNotificationChannel()
            val notifyManager = androidx.core.app.NotificationManagerCompat.from(this)

            val intent = if (isUpdateReady && !apkPath.isNullOrEmpty()) {
                val file = java.io.File(apkPath)
                if (file.exists()) {
                    val uri = androidx.core.content.FileProvider.getUriForFile(
                        this,
                        "$packageName.fileprovider",
                        file
                    )
                    Intent(Intent.ACTION_VIEW).apply {
                        setDataAndType(uri, "application/vnd.android.package-archive")
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
                    }
                } else {
                    Intent(this, MainActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    }
                }
            } else {
                Intent(this, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
            }

            val pendingIntent = android.app.PendingIntent.getActivity(
                this,
                0,
                intent,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) android.app.PendingIntent.FLAG_IMMUTABLE else 0)
            )

            val builder = androidx.core.app.NotificationCompat.Builder(this, UPDATE_CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_stat_logo)
                .setContentTitle(title)
                .setContentText(message)
                .setStyle(androidx.core.app.NotificationCompat.BigTextStyle().bigText(message))
                .setPriority(androidx.core.app.NotificationCompat.PRIORITY_HIGH)
                .setContentIntent(pendingIntent)
                .setAutoCancel(true)

            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
                checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
            ) {
                notifyManager.notify(UPDATE_NOTIFICATION_ID, builder.build())
            }
        } catch (_: Throwable) {
        }
    }

    private fun askForNotifications() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1)
        }
    }
}
