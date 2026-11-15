package com.example.we_decor_enquiries

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ClipData
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
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
     *
     * When both personal WhatsApp and WhatsApp Business are installed, shows the
     * system chooser so staff can pick which app to use. With only one installed,
     * opens that app directly.
     *
     * Returns false when neither app is installed, so Dart can fall back.
     *
     * Callers must confirm delivery before logging — [startActivity] success only
     * means an app opened, not that the right chat received the message.
     */
    private fun shareImageToChat(png: ByteArray, phone: String, text: String): Boolean {
        val installed = WHATSAPP_PACKAGES.filter { isInstalled(it) }
        if (installed.isEmpty()) return false
        return try {
            val dir = File(cacheDir, "wishes").apply { mkdirs() }
            val file = File(dir, "we-decor-${System.currentTimeMillis()}.png")
            file.writeBytes(png)
            val uri = FileProvider.getUriForFile(this, "$packageName.wishprovider", file)
            // Full international digits (e.g. 9198…), never a bare 10-digit local number —
            // WhatsApp's jid ignores the chat when the country code is missing.
            val digits = phone.filter { it.isDigit() }
            if (digits.length < 10) return false

            // Grant every installed WhatsApp — the chooser may open either one.
            for (pkg in installed) {
                grantUriPermission(pkg, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }

            val intents = installed.map { pkg -> sendIntent(pkg, uri, text, digits) }
            if (intents.size == 1) {
                startActivity(intents[0])
            } else {
                // Primary + EXTRA_INITIAL_INTENTS → chooser lists only WA / W4B.
                val chooser = Intent.createChooser(intents[0], "Send with").apply {
                    putExtra(Intent.EXTRA_INITIAL_INTENTS, intents.drop(1).toTypedArray())
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                startActivity(chooser)
            }
            true
        } catch (e: Exception) {
            false
        }
    }

    /**
     * ACTION_SEND for one WhatsApp package. Sets [ClipData] as well as EXTRA_STREAM —
     * without ClipData, Android 7+ often hands WhatsApp an unreadable URI so the
     * image silently drops and only the caption (or an empty composer) appears.
     */
    private fun sendIntent(pkg: String, uri: Uri, text: String, digits: String): Intent {
        return Intent(Intent.ACTION_SEND).apply {
            type = "image/png"
            setPackage(pkg)
            putExtra(Intent.EXTRA_STREAM, uri)
            putExtra(Intent.EXTRA_TEXT, text)
            putExtra("jid", "$digits@s.whatsapp.net")
            clipData = ClipData.newUri(contentResolver, "we-decor-card", uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
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
        private val WHATSAPP_PACKAGES = listOf("com.whatsapp", "com.whatsapp.w4b")
    }
}
