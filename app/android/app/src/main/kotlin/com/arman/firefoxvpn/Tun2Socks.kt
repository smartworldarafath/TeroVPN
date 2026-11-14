package com.arman.firefoxvpn

import android.os.ParcelFileDescriptor

/**
 * hev-socks5-tunnel (app/android), the C library that takes the VPN's packets
 * apart and opens a SOCKS5 connection to the core for each TCP connection and
 * UDP flow, on a thread of its own.
 */
object Tun2Socks {
    private external fun TProxyStartService(configPath: String, fd: Int): Boolean
    private external fun TProxyStopService(): Boolean
    private external fun TProxyIsRunning(): Boolean

    @Suppress("unused")
    private external fun TProxyGetStats(): LongArray

    private var device: ParcelFileDescriptor? = null

    @Synchronized
    fun start(configPath: String, tun: ParcelFileDescriptor): Boolean {
        try {
            stop()
            System.loadLibrary("hev-socks5-tunnel")
            device = tun
            if (TProxyStartService(configPath, tun.fd)) return true
        } catch (e: Throwable) {
            device = null
            tun.close()
            throw e
        }
        stop()
        return false
    }

    @Synchronized
    fun stop() {
        val tun = device ?: return
        device = null
        TProxyStopService()
        tun.close()
    }

    @Synchronized
    fun ended(): Boolean = device != null && !TProxyIsRunning()
}
