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
                    "listInstalledPackages" -> {
                        result.success(WHATSAPP_PACKAGES.filter { isInstalled(it) })
                    }
                    "shareImageToChat" -> {
                        val bytes = call.argument<ByteArray>("png")
                        val phone = call.argument<String>("phone")
                        val text = call.argument<String>("text") ?: ""
                        val pkg = call.argument<String>("package")
                        if (bytes == null || phone.isNullOrBlank() || pkg.isNullOrBlank()) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        if (!WHATSAPP_PACKAGES.contains(pkg) || !isInstalled(pkg)) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        result.success(shareImageToChat(bytes, phone, text, pkg))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Opens [phone]'s WhatsApp chat with the card attached and [text] as caption.
     *
     * Single [ACTION_SEND] with ClipData + FileProvider + WhatsApp's unofficial
     * `jid` extra. Package is chosen in Flutter (glass sheet) so the native UI
     * stays out of the way.
     *
     * Returns false when share cannot start (Dart falls back).
     */
    private fun shareImageToChat(png: ByteArray, phone: String, text: String, pkg: String): Boolean {
        return try {
            val digits = repairWhatsAppDigits(phone.filter { it.isDigit() })
            // Plausible E.164 length without '+'; bare 10-digit jids open the picker.
            if (digits.length !in 11..15) return false

            val dir = File(cacheDir, "wishes").apply { mkdirs() }
            val file = File(dir, "we-decor-${System.currentTimeMillis()}.png")
            file.writeBytes(png)
            val uri = FileProvider.getUriForFile(this, "$packageName.wishprovider", file)
            grantUriPermission(pkg, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)

            startActivity(sendIntent(pkg, uri, text, digits))
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

        /** Mirror of Dart [ContactLauncher] India trunk-zero + bare-10 repair. */
        fun repairWhatsAppDigits(raw: String): String {
            var digits = raw.filter { it.isDigit() }
            if (digits.length == 13 && digits.startsWith("910")) {
                digits = "91" + digits.substring(3)
            }
            if (digits.length == 10) {
                digits = "91$digits"
            }
            return digits
        }
    }
}
