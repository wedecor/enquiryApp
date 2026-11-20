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
                        // Package pick may show a dialog — reply after share starts.
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
     * Opens [phone]'s WhatsApp chat with the card attached and [text] as caption.
     *
     * Uses a single [ACTION_SEND] with ClipData + FileProvider + WhatsApp's
     * unofficial `jid` extra. A prior two-step (text URL, then delayed image)
     * opened the chat reliably but WhatsApp does not attach a follow-up
     * [ACTION_SEND] to that open chat without `jid`, so staff only saw text.
     *
     * When both personal WhatsApp and Business are installed, staff pick which
     * app. Returns false when neither is installed or share cannot start
     * (Dart falls back to phone-URL + share sheet).
     */
    private fun shareImageToChat(png: ByteArray, phone: String, text: String, pkg: String): Boolean {
        return try {
            // Full international digits (e.g. 9198…), never a bare 10-digit local
            // number — WhatsApp's jid ignores the chat when the country code is missing.
            val digits = phone.filter { it.isDigit() }
            if (digits.length < 10) return false

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
        private val WHATSAPP_PACKAGES = listOf("com.whatsapp", "com.whatsapp.w4b")
    }
}
