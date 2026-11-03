package com.example.we_decor_enquiries

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createEnquiryUpdatesChannel()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WHATSAPP_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "shareImageToChat" -> {
                        val bytes = call.argument<ByteArray>("png")
                        val phone = call.argument<String>("phone")
                        val text = call.argument<String>("text") ?: ""
                        if (bytes == null || phone.isNullOrBlank()) {
                            result.success(false)
                        } else {
                            result.success(shareImageToChat(bytes, phone, text))
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Opens [phone]'s WhatsApp chat with the wish card attached and [text] as its
     * caption. Uses WhatsApp's `jid` extra (widely used, not an official API): when a
     * WhatsApp build ignores it, WhatsApp shows its own contact picker instead.
     * Prefers WhatsApp Business (the business number), then WhatsApp.
     * Returns false when neither app is installed, so Dart can fall back.
     */
    private fun shareImageToChat(png: ByteArray, phone: String, text: String): Boolean {
        val target = WHATSAPP_PACKAGES.firstOrNull { isInstalled(it) } ?: return false
        return try {
            val dir = File(cacheDir, "wishes").apply { mkdirs() }
            val file = File(dir, "we-decor-wish.png")
            file.writeBytes(png)
            val uri = FileProvider.getUriForFile(this, "$packageName.wishprovider", file)
            val digits = phone.filter { it.isDigit() }
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "image/png"
                setPackage(target)
                putExtra(Intent.EXTRA_STREAM, uri)
                putExtra(Intent.EXTRA_TEXT, text)
                putExtra("jid", "$digits@s.whatsapp.net")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun isInstalled(pkg: String): Boolean = try {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.getPackageInfo(pkg, PackageManager.PackageInfoFlags.of(0))
        } else {
            @Suppress("DEPRECATION")
            packageManager.getPackageInfo(pkg, 0)
        }
        true
    } catch (e: PackageManager.NameNotFoundException) {
        false
    }

    // Channel used by Cloud Functions pushes (android.notification.channelId)
    // and as the FCM default channel in AndroidManifest.xml.
    private fun createEnquiryUpdatesChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "enquiry_updates",
                "Enquiry updates",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "New enquiries, assignments and status changes"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    companion object {
        private const val WHATSAPP_CHANNEL = "wedecor/whatsapp"
        private val WHATSAPP_PACKAGES = listOf("com.whatsapp.w4b", "com.whatsapp")
    }
}
