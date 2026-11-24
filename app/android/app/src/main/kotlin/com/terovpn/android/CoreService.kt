package com.terovpn.android

import com.arman.firefoxvpn.Tun2Socks
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.VpnService
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.widget.Toast
import java.io.File
import java.util.Locale
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger

/**
 * The Go core (core/mobile, built into libs/core.jar by gomobile) runs in
 * this process. While the UI is open it runs with the proxy off, so the
 * settings and the accounts work. Turned on (the app's button, the Quick
 * Settings tile), this service keeps the core running in the foreground.
 * In VPN mode it is also the phone's VPN: it hands the core the VPN's TUN
 * device, so every app's TCP traffic goes through the proxy; the app
 * itself is left out of the VPN, so the core's own connections go straight
 * out.
 */
class CoreService : VpnService() {
    private val main = Handler(Looper.getMainLooper())

    /** The country the notification shows; "" for "Connecting…", NO_NETWORK for none. */
    private var shownCountry: String? = null

    /** The local proxy the notification names (proxy mode); "" for none. */
    private var shownProxy = ""

    /** The speed the notification shows (the user's choice); "" for none. */
    private var shownSpeed = ""

    /** Android reported that no network is connected (no Wi-Fi, no mobile data). */
    @Volatile
    private var offline = false

    /** onDestroy ran: a network callback still in flight must not post again. */
    @Volatile
    private var destroyed = false

    /** Generation captured when this service instance was started. */
    private var startedGen = 0

    /**
     * Keeps the notification on the country the traffic leaves from, and
     * the routing region's apps among the bypassed ones (checkSuggested).
     * All Go/JNI and Tun2Socks queries run on [worker] so the Android main
     * UI thread is never blocked (eliminating ANRs and frozen frames).
     */
    private val watchCountry = object : Runnable {
        override fun run() {
            if (destroyed || !on) return
            val gen = serviceGen.get()
            worker.execute {
                if (destroyed || !on || serviceGen.get() != gen) return@execute
                val isRunning = try { mobile.Mobile.running() } catch (_: Throwable) { false }
                if (!isRunning) {
                    Log.e(TAG, "the core stopped; turning the VPN off")
                    turnOff(this@CoreService)
                    return@execute
                }
                val coreOn = try { mobile.Mobile.isOn() } catch (_: Throwable) { false }
                if (!coreOn) {
                    Log.w(TAG, "the connect was given up; turning the VPN off")
                    turnOff(this@CoreService)
                    return@execute
                }
                val useVpn = usesVpn(this@CoreService)
                if (useVpn && Tun2Socks.ended()) {
                    Log.e(TAG, "the VPN's tunnel ended; turning the VPN off")
                    turnOff(this@CoreService)
                    return@execute
                }
                val pending = try { mobile.Mobile.connectPending() } catch (_: Throwable) { true }
                val code = when {
                    pending -> ""
                    offline -> NO_NETWORK
                    else -> try { mobile.Mobile.exitCountry() } catch (_: Throwable) { "" }
                }
                val proxy = if (useVpn) "" else try { mobile.Mobile.proxyAddress() } catch (_: Throwable) { "" }
                val wantSpeed = showSpeed(this@CoreService)
                val speed = if (wantSpeed && !offline) {
                    try { speedText(mobile.Mobile.speed()) } catch (_: Throwable) { "" }
                } else ""
                val excludeMode = useVpn && appMode(this@CoreService) == MODE_EXCLUDE

                main.post {
                    if (destroyed || !on || serviceGen.get() != gen) return@post
                    connected = on && code.length == 2
                    ConnectWidget.updateAll(this@CoreService)
                    if (code != shownCountry || proxy != shownProxy || speed != shownSpeed) {
                        shownCountry = code
                        shownProxy = proxy
                        shownSpeed = speed
                        try {
                            getSystemService(NotificationManager::class.java)
                                .notify(NOTIFICATION_ID, notification(code))
                        } catch (_: Throwable) {}
                    }
                    if (excludeMode) {
                        checkSuggested()
                    }
                    main.removeCallbacks(this)
                    main.postDelayed(this, if (wantSpeed) SPEED_POLL_MS else COUNTRY_POLL_MS)
                }
            }
        }
    }

    private var networkCallback: ConnectivityManager.NetworkCallback? = null

    private fun watchNetwork() {
        if (networkCallback != null) return
        val callback = object : ConnectivityManager.NetworkCallback() {
            private var current: Network? = null
            private var lost = false

            override fun onAvailable(network: Network) {
                val caps = getSystemService(ConnectivityManager::class.java).getNetworkCapabilities(network)
                if (caps?.hasTransport(NetworkCapabilities.TRANSPORT_VPN) == true) return
                val changed = (current != null && current != network) || (current == null && lost) || reportedDown
                current = network
                lost = false
                setUnderlyingNetworks(arrayOf(network))
                if (changed) {
                    mobile.Mobile.networkChanged(true)
                    reportedDown = false
                }
                if (offline) {
                    offline = false
                    refreshNotification()
                }
            }

            override fun onLost(network: Network) {
                if (network != current) return
                current = null
                lost = true
                setUnderlyingNetworks(null)
                mobile.Mobile.networkChanged(false)
                reportedDown = true
                offline = true
                refreshNotification()
            }
        }
        try {
            val connectivity = getSystemService(ConnectivityManager::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val request = NetworkRequest.Builder()
                    .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
                    .addCapability(NetworkCapabilities.NET_CAPABILITY_NOT_VPN)
                    .build()
                connectivity.registerBestMatchingNetworkCallback(request, callback, main)
            } else {
                connectivity.registerDefaultNetworkCallback(callback)
            }
            networkCallback = callback
            if (!hasNetwork(connectivity)) {
                mobile.Mobile.networkChanged(false)
                reportedDown = true
                offline = true
                refreshNotification()
            }
        } catch (e: Exception) {
            Log.w(TAG, "watching the network failed", e)
        }
    }

    @Suppress("DEPRECATION")
    private fun hasNetwork(connectivity: ConnectivityManager): Boolean =
        connectivity.allNetworks.any { network ->
            val caps = connectivity.getNetworkCapabilities(network)
            caps != null &&
                caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) &&
                !caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN)
        }

    private fun refreshNotification() {
        if (destroyed) return
        main.removeCallbacks(watchCountry)
        main.post(watchCountry)
    }

    private fun stopWatchingNetwork() {
        val callback = networkCallback ?: return
        networkCallback = null
        try {
            getSystemService(ConnectivityManager::class.java).unregisterNetworkCallback(callback)
        } catch (e: Exception) {
            // Not registered.
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            turnOffAsync(this)
            return START_NOT_STICKY
        }
        if (intent?.action == ACTION_RECONNECT) {
            val gen = serviceGen.get()
            worker.execute {
                if (destroyed || !on || serviceGen.get() != gen) return@execute
                if (usesVpn(this)) {
                    if (!startTunnel()) turnOff(this)
                } else {
                    stopTunnel()
                }
            }
            return START_STICKY
        }
        startInForeground()
        val gen = serviceGen.get()
        startedGen = gen
        on = true
        offline = reportedDown
        worker.execute {
            if (destroyed || !on || serviceGen.get() != gen) return@execute
            startCore(this, on = true)
            if (!mobile.Mobile.isOn()) {
                mobile.Mobile.setOn(true)
                mobile.Mobile.connect()
            }
            if (usesVpn(this) && !startTunnel()) {
                turnOff(this)
                return@execute
            }
            main.post {
                if (destroyed || !on || serviceGen.get() != gen) return@post
                QuickTile.refresh(this)
                ConnectWidget.updateAll(this)
                main.removeCallbacks(watchCountry)
                main.post(watchCountry)
                watchNetwork()
            }
        }
        return START_STICKY
    }

    override fun onRevoke() {
        turnOffAsync(this)
    }

    override fun onDestroy() {
        destroyed = true
        main.removeCallbacks(watchCountry)
        try {
            getSystemService(NotificationManager::class.java).cancel(NOTIFICATION_ID)
        } catch (_: Throwable) {}
        stopWatchingNetwork()
        val staleDestroy = on && serviceGen.get() != startedGen
        if (!staleDestroy) {
            on = false
            connected = false
            worker.execute { stopTunnel() }
        }
        QuickTile.refresh(this)
        ConnectWidget.updateAll(this)
        super.onDestroy()
    }

    private fun startTunnel(): Boolean {
        if (prepare(this) != null) {
            Log.w(TAG, "the VPN has no permission")
            return false
        }
        return try {
            val mtu = mobile.Mobile.tunMTU().takeIf { it > 0 } ?: MTU
            val config = mobile.Mobile.tunConfig(mtu)
            val builder = Builder()
                .setSession(getString(R.string.app_name))
                .setMtu(mtu)
                .addAddress("172.19.0.1", 30)
                .addRoute("0.0.0.0", 0)
                .addDnsServer("172.19.0.2")
                .addAddress("fdfe:dcba:9876::1", 126)
                .addRoute("::", 0)
            applyApps(builder)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) builder.setMetered(false)
            val tun = builder.establish() ?: return false
            if (!Tun2Socks.start(config, tun)) {
                Log.e(TAG, "the VPN's tunnel did not start")
                return false
            }
            tunnelUpAt = System.currentTimeMillis()
            true
        } catch (e: Throwable) {
            Log.e(TAG, "the VPN did not start", e)
            main.post {
                Toast.makeText(this, e.message ?: e.toString(), Toast.LENGTH_LONG).show()
            }
            false
        }
    }

    private fun applyApps(builder: Builder) {
        fun each(packages: Set<String>, add: (String) -> Unit) {
            for (pkg in packages) {
                try {
                    add(pkg)
                } catch (e: PackageManager.NameNotFoundException) {
                    // Uninstalled since.
                }
            }
        }
        if (appMode(this) == MODE_INCLUDE) {
            var added = 0
            each(appSet(this, ONLY) - packageName) {
                builder.addAllowedApplication(it)
                added++
            }
            if (added > 0) return
        }
        builder.addDisallowedApplication(packageName)
        each(appSet(this, BYPASS) - packageName) { builder.addDisallowedApplication(it) }
    }

    @Volatile
    private var tunnelUpAt = 0L

    private val suggesting = AtomicBoolean(false)

    private fun checkSuggested() {
        val first = !hasAppChoice(this)
        if (!first && (!suggestDue(this) || System.currentTimeMillis() - tunnelUpAt < SUGGEST_SETTLE_MS)) return
        if (!suggesting.compareAndSet(false, true)) return
        worker.execute {
            try {
                if (suggest(this) && first) {
                    main.post { if (on && !startTunnel()) turnOff(this) }
                }
            } finally {
                suggesting.set(false)
            }
        }
    }

    private fun startInForeground() {
        val manager = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.deleteNotificationChannel(OLD_CHANNEL)
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL, getString(R.string.notification_channel), NotificationManager.IMPORTANCE_LOW)
                    .apply { setShowBadge(false) },
            )
        }
        shownCountry = ""
        shownProxy = ""
        shownSpeed = ""
        val notification = notification("")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun notification(code: String): Notification {
        val state = when {
            code == NO_NETWORK -> getString(R.string.notification_no_network)
            code.length == 2 -> "${flag(code)}  ${Locale.Builder().setRegion(code).build().displayCountry}"
            else -> getString(R.string.notification_connecting)
        }
        val first = if (shownSpeed.isEmpty()) state else "$state  ·  $shownSpeed"
        val text = if (shownProxy.isEmpty()) first else "$first\n${getString(R.string.notification_proxy, shownProxy)}"
        val open = PendingIntent.getActivity(
            this, 0, Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE,
        )
        val stop = PendingIntent.getService(
            this, 1, Intent(this, CoreService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        return builder
            .setSmallIcon(R.drawable.ic_stat_logo)
            .setContentTitle(getString(R.string.app_name))
            .setContentText(text)
            .setStyle(Notification.BigTextStyle().bigText(text))
            .setContentIntent(open)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .addAction(Notification.Action.Builder(null, getString(R.string.notification_stop), stop).build())
            .build()
    }

    companion object {
        const val ACTION_STOP = "com.terovpn.android.STOP"
        private const val ACTION_RECONNECT = "com.terovpn.android.RECONNECT"
        private const val PREFS = "vpn"
        private const val MODE = "app_mode"
        const val MODE_EXCLUDE = "exclude"
        const val MODE_INCLUDE = "include"

        private const val CONNECTION = "connection_mode"
        const val MODE_VPN = "vpn"
        const val MODE_PROXY = "proxy"

        private const val NO_NETWORK = "-"
        private const val SHOW_SPEED = "show_speed"

        fun showSpeed(context: Context) = prefs(context).getBoolean(SHOW_SPEED, false)

        fun setShowSpeed(context: Context, on: Boolean) {
            prefs(context).edit().putBoolean(SHOW_SPEED, on).apply()
        }

        fun speedText(downUp: String): String {
            val parts = downUp.split(",")
            val down = parts.getOrNull(0)?.toLongOrNull() ?: 0
            val up = parts.getOrNull(1)?.toLongOrNull() ?: 0
            return "↓ ${rate(down)}  ↑ ${rate(up)}"
        }

        private fun rate(bytes: Long): String = when {
            bytes >= 1024 * 1024 -> String.format(Locale.US, "%.1f MB/s", bytes / 1048576.0)
            bytes >= 1024 -> "${bytes / 1024} KB/s"
            else -> "$bytes B/s"
        }

        fun connectionMode(context: Context): String =
            prefs(context).getString(CONNECTION, MODE_VPN) ?: MODE_VPN

        fun usesVpn(context: Context) = connectionMode(context) != MODE_PROXY

        fun setConnectionMode(context: Context, mode: String) {
            prefs(context).edit().putString(CONNECTION, if (mode == MODE_PROXY) MODE_PROXY else MODE_VPN).apply()
            reconnect(context)
        }

        const val BYPASS = "bypass_apps"
        const val ONLY = "only_apps"
        const val DECLINED = "declined_apps"

        private const val SUGGESTED_AT = "suggested_at"
        private const val SUGGEST_EVERY_MS = 3L * 24 * 60 * 60 * 1000
        private const val SUGGEST_SETTLE_MS = 2L * 60 * 1000

        private val worker = Executors.newSingleThreadExecutor()

        fun hasAppChoice(context: Context) = prefs(context).contains(BYPASS)

        fun suggestDue(context: Context) =
            System.currentTimeMillis() - prefs(context).getLong(SUGGESTED_AT, 0) >= SUGGEST_EVERY_MS

        private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

        fun appMode(context: Context): String = prefs(context).getString(MODE, MODE_EXCLUDE) ?: MODE_EXCLUDE

        fun appSet(context: Context, key: String): Set<String> = prefs(context).getStringSet(key, emptySet()) ?: emptySet()

        fun setAppRouting(context: Context, mode: String, sets: Map<String, Set<String>>) {
            val edit = prefs(context).edit().putString(MODE, mode)
            for ((key, packages) in sets) edit.putStringSet(key, packages)
            edit.apply()
        }

        fun suggest(context: Context, force: Boolean = false): Boolean {
            val p = prefs(context)
            val now = System.currentTimeMillis()
            if (!force && now - p.getLong(SUGGESTED_AT, 0) < SUGGEST_EVERY_MS) return false
            val region = regionAppList().toSet()
            if (region.isEmpty()) return false
            val installed = installedPackages(context)
            val before = appSet(context, BYPASS)
            var declined = appSet(context, DECLINED)
            if (!p.contains(SUGGESTED_AT) && p.contains(BYPASS)) {
                declined = declined + (region intersect installed) - before
            }
            val after = before - (region - installed) + ((region intersect installed) - declined)
            p.edit()
                .putStringSet(BYPASS, after)
                .putStringSet(DECLINED, declined)
                .putLong(SUGGESTED_AT, now)
                .apply()
            return after != before
        }

        private fun installedPackages(context: Context): Set<String> {
            @Suppress("DEPRECATION")
            return context.packageManager.getInstalledApplications(0).map { it.packageName }.toSet()
        }

        fun regionAppList(): List<String> =
            if (mobile.Mobile.running()) mobile.Mobile.directApps().lines().filter { it.isNotBlank() } else emptyList()

        fun reconnect(context: Context) {
            if (!on) return
            context.startService(Intent(context, CoreService::class.java).setAction(ACTION_RECONNECT))
        }

        private const val CHANNEL = "status"
        private const val OLD_CHANNEL = "core"
        private const val NOTIFICATION_ID = 1
        private const val TAG = "CoreService"

        private const val COUNTRY_POLL_MS = 3000L
        private const val SPEED_POLL_MS = 2000L

        fun flag(code: String): String =
            code.uppercase().filter { it in 'A'..'Z' }
                .map { String(Character.toChars(0x1F1E6 + (it - 'A'))) }
                .joinToString("")

        private const val MTU = 1500

        @Volatile
        private var reportedDown = false

        @Volatile
        var on = false
            private set

        @Volatile
        var connected = false
            private set

        private val serviceGen = AtomicInteger(0)

        fun runOnCoreExecutor(task: () -> Unit) {
            worker.execute(task)
        }

        fun dataDir(context: Context): File = File(context.filesDir, "core")

        fun turnOn(context: Context) {
            val appCtx = context.applicationContext
            serviceGen.incrementAndGet()
            on = true
            connected = false
            val intent = Intent(appCtx, CoreService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                appCtx.startForegroundService(intent)
            } else {
                appCtx.startService(intent)
            }
            startCore(appCtx, on = true)
            mobile.Mobile.setOn(true)
            mobile.Mobile.connect()
            QuickTile.refresh(appCtx)
            ConnectWidget.updateAll(appCtx)
        }

        fun turnOnAsync(context: Context, onComplete: (Exception?) -> Unit) {
            val appCtx = context.applicationContext
            val gen = serviceGen.incrementAndGet()
            on = true
            connected = false
            val intent = Intent(appCtx, CoreService::class.java)
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    appCtx.startForegroundService(intent)
                } else {
                    appCtx.startService(intent)
                }
            } catch (e: Exception) {
                on = false
                onComplete(e)
                return
            }
            worker.execute {
                try {
                    if (serviceGen.get() != gen) {
                        onComplete(null)
                        return@execute
                    }
                    startCore(appCtx, on = true)
                    mobile.Mobile.setOn(true)
                    mobile.Mobile.connect()
                    QuickTile.refresh(appCtx)
                    ConnectWidget.updateAll(appCtx)
                    onComplete(null)
                } catch (e: Exception) {
                    onComplete(e)
                }
            }
        }

        private fun stopTunnel() {
            Tun2Socks.stop()
            if (mobile.Mobile.running()) mobile.Mobile.stopTun()
        }

        fun turnOff(context: Context) {
            val appCtx = context.applicationContext
            serviceGen.incrementAndGet()
            on = false
            connected = false
            stopTunnel()
            if (mobile.Mobile.running()) {
                mobile.Mobile.setOn(false)
            }
            appCtx.stopService(Intent(appCtx, CoreService::class.java))
            QuickTile.refresh(appCtx)
            ConnectWidget.updateAll(appCtx)
        }

        fun turnOffAsync(context: Context, onComplete: (() -> Unit)? = null) {
            val appCtx = context.applicationContext
            val gen = serviceGen.incrementAndGet()
            on = false
            connected = false
            worker.execute {
                try {
                    if (serviceGen.get() == gen) {
                        stopTunnel()
                        if (mobile.Mobile.running()) {
                            mobile.Mobile.setOn(false)
                        }
                    }
                } finally {
                    appCtx.stopService(Intent(appCtx, CoreService::class.java))
                    QuickTile.refresh(appCtx)
                    ConnectWidget.updateAll(appCtx)
                    onComplete?.invoke()
                }
            }
        }

        @Synchronized
        fun startCore(context: Context, on: Boolean) {
            if (mobile.Mobile.running()) return
            if ((context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0) {
                importFromComputer(context)
            } else {
                File(context.getExternalFilesDir(null), "import").takeIf { it.exists() }?.deleteRecursively()
            }
            try {
                mobile.Mobile.start(dataDir(context).absolutePath, on)
            } catch (e: Exception) {
                Log.e(TAG, "the core did not start", e)
            }
        }

        private fun importFromComputer(context: Context) {
            val source = File(context.getExternalFilesDir(null), "import")
            if (!source.isDirectory) return
            val target = dataDir(context).apply { mkdirs() }
            try {
                for (name in listOf("config.json", "state.json", "selection.json")) {
                    val file = File(source, name)
                    if (file.isFile) file.copyTo(File(target, name), overwrite = true)
                }
                File(source, "accounts").takeIf { it.isDirectory }
                    ?.copyRecursively(File(target, "accounts"), overwrite = true)
                Log.i(TAG, "imported the data copied from the computer")
            } catch (e: Exception) {
                Log.e(TAG, "the import failed", e)
            } finally {
                source.deleteRecursively()
            }
        }

        @Synchronized
        fun stopCore() {
            Tun2Socks.stop()
            if (mobile.Mobile.running()) mobile.Mobile.stop()
        }
    }
}
