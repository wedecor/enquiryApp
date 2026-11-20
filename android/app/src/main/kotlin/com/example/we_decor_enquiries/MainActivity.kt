package com.example.we_decor_enquiries

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ClipData
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
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
     * Card + caption to [phone]'s chat.
     *
     * WhatsApp only honors the unofficial `jid` on [ACTION_SEND] when that
     * number already has a local chat thread. Unknown numbers silently fall
     * back to the contact picker — which is why some customers work and others
     * ask "whom to send?".
     *
     * Fix: open Click-to-Chat first (`api.whatsapp.com/send?phone=…`) so WhatsApp
     * creates/opens the thread, then [ACTION_SEND] image+caption with `jid`.
     * Package is chosen in Flutter (glass sheet).
     */
    private fun shareImageToChat(png: ByteArray, phone: String, text: String, pkg: String): Boolean {
        return try {
            val digits = repairWhatsAppDigits(phone.filter { it.isDigit() })
            if (digits.length !in 11..15) return false

            val dir = File(cacheDir, "wishes").apply { mkdirs() }
            val file = File(dir, "we-decor-${System.currentTimeMillis()}.png")
            file.writeBytes(png)
            val uri = FileProvider.getUriForFile(this, "$packageName.wishprovider", file)
            grantUriPermission(pkg, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)

            // Step A — create/open the chat for any number (saved or not).
            val chatUrl = Uri.parse("https://api.whatsapp.com/send?phone=$digits")
            startActivity(
                Intent(Intent.ACTION_VIEW, chatUrl).apply {
                    setPackage(pkg)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                },
            )

            // Step B — attach card + caption now that the jid can resolve.
            Handler(Looper.getMainLooper()).postDelayed({
                try {
                    startActivity(sendIntent(pkg, uri, text, digits))
                } catch (_: Exception) {
                    // Chat already open; staff can still type / attach manually.
                }
            }, CHAT_WARMUP_MS)

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
        /** Time for WhatsApp to open/create the chat before image share. */
        private const val CHAT_WARMUP_MS = 1100L
        private val WHATSAPP_PACKAGES = listOf("com.whatsapp", "com.whatsapp.w4b")

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
