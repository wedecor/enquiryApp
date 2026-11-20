package com.example.we_decor_enquiries

import android.app.AlertDialog
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
                    "shareImageToChat" -> {
                        val bytes = call.argument<ByteArray>("png")
                        val phone = call.argument<String>("phone")
                        val text = call.argument<String>("text") ?: ""
                        if (bytes == null || phone.isNullOrBlank()) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        // Package pick may show a dialog — reply after the two-step share starts.
                        pickWhatsAppPackage { pkg ->
                            if (pkg == null) {
                                result.success(false)
                            } else {
                                result.success(shareImageToChat(bytes, phone, text, pkg))
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Two-step share that does **not** rely on WhatsApp's unofficial `jid` extra
     * (many builds ignore it and show a contact picker even when the number is known).
     *
     * 1. [ACTION_VIEW] `api.whatsapp.com/send?phone=…&text=…` with [setPackage] —
     *    same phone-in-URL targeting as the normal WhatsApp button.
     * 2. Shortly after, [ACTION_SEND] the card image to the **same** package
     *    (ClipData + FileProvider). Chat selection already happened in step 1.
     *
     * When both personal WhatsApp and Business are installed, staff pick which app.
     * Returns false when neither is installed or step 1 cannot start (Dart falls back).
     */
    private fun shareImageToChat(png: ByteArray, phone: String, text: String, pkg: String): Boolean {
        return try {
            val digits = phone.filter { it.isDigit() }
            if (digits.length < 10) return false

            val dir = File(cacheDir, "wishes").apply { mkdirs() }
            val file = File(dir, "we-decor-${System.currentTimeMillis()}.png")
            file.writeBytes(png)
            val uri = FileProvider.getUriForFile(this, "$packageName.wishprovider", file)
            grantUriPermission(pkg, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)

            // Step A — open the correct chat with the caption (phone in the URL).
            val sendUrl = Uri.parse(
                "https://api.whatsapp.com/send?phone=$digits&text=${Uri.encode(text)}",
            )
            val viewIntent = Intent(Intent.ACTION_VIEW, sendUrl).apply {
                setPackage(pkg)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(viewIntent)

            // Step B — attach the card to the same app after the chat has a moment to open.
            // No `jid` extra: that is what triggered "whom to send" on many devices.
            Handler(Looper.getMainLooper()).postDelayed({
                try {
                    startActivity(imageSendIntent(pkg, uri))
                } catch (_: Exception) {
                    // Chat + caption already opened; Dart still prompts Mark as sent.
                }
            }, IMAGE_SHARE_DELAY_MS)

            true
        } catch (e: Exception) {
            false
        }
    }

    /** Image-only ACTION_SEND for [pkg]. Caption already went out in step A. */
    private fun imageSendIntent(pkg: String, uri: Uri): Intent {
        return Intent(Intent.ACTION_SEND).apply {
            type = "image/png"
            setPackage(pkg)
            putExtra(Intent.EXTRA_STREAM, uri)
            clipData = ClipData.newUri(contentResolver, "we-decor-card", uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
    }

    /**
     * One installed app → use it. Both → dialog (WhatsApp / WhatsApp Business),
     * remembering the last choice as the default selected item.
     */
    private fun pickWhatsAppPackage(onPicked: (String?) -> Unit) {
        val installed = WHATSAPP_PACKAGES.filter { isInstalled(it) }
        when {
            installed.isEmpty() -> onPicked(null)
            installed.size == 1 -> onPicked(installed[0])
            else -> runOnUiThread {
                if (isFinishing || isDestroyed) {
                    onPicked(null)
                    return@runOnUiThread
                }
                val prefs = getSharedPreferences(PREFS_WHATSAPP, MODE_PRIVATE)
                val last = prefs.getString(PREF_LAST_PKG, null)
                val labels = installed.map { pkgLabel(it) }.toTypedArray()
                val checked = installed.indexOf(last).coerceAtLeast(0)
                AlertDialog.Builder(this)
                    .setTitle("Send with")
                    .setSingleChoiceItems(labels, checked, null)
                    .setPositiveButton("Continue") { dialog, _ ->
                        val list = (dialog as AlertDialog).listView
                        val idx = list.checkedItemPosition.coerceIn(0, installed.lastIndex)
                        val pkg = installed[idx]
                        prefs.edit().putString(PREF_LAST_PKG, pkg).apply()
                        onPicked(pkg)
                    }
                    .setNegativeButton("Cancel") { _, _ -> onPicked(null) }
                    .setOnCancelListener { onPicked(null) }
                    .show()
            }
        }
    }

    private fun pkgLabel(pkg: String): String = when (pkg) {
        "com.whatsapp.w4b" -> "WhatsApp Business"
        else -> "WhatsApp"
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
        private const val PREFS_WHATSAPP = "whatsapp_share"
        private const val PREF_LAST_PKG = "last_pkg"
        private const val IMAGE_SHARE_DELAY_MS = 900L
        private val WHATSAPP_PACKAGES = listOf("com.whatsapp", "com.whatsapp.w4b")
    }
}
