package com.example.we_decor_enquiries

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ClipData
import android.content.ContentProviderOperation
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.ContactsContract
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private var pendingContactsPermissionResult: MethodChannel.Result? = null

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
                    "hasContactsPermission" -> {
                        result.success(hasContactsPermission())
                    }
                    "requestContactsPermission" -> {
                        requestContactsPermission(result)
                    }
                    "isInContacts" -> {
                        val phone = call.argument<String>("phone")
                        if (phone.isNullOrBlank() || !hasContactsPermission()) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        result.success(isInContacts(phone))
                    }
                    "saveContact" -> {
                        val name = call.argument<String>("name") ?: ""
                        val phone = call.argument<String>("phone")
                        if (phone.isNullOrBlank() || !hasContactsPermission()) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        result.success(saveContact(name, phone))
                    }
                    "openChat" -> {
                        val phone = call.argument<String>("phone")
                        val text = call.argument<String>("text") ?: ""
                        val pkg = call.argument<String>("package")
                        if (phone.isNullOrBlank() || pkg.isNullOrBlank() ||
                            !WHATSAPP_PACKAGES.contains(pkg) || !isInstalled(pkg)
                        ) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        result.success(openChat(phone, text, pkg))
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
     * Opens [phone]'s chat via Click-to-Chat with [text] typed in.
     *
     * Click-to-Chat works for any number (saved or not, chatted before or not),
     * so this never shows WhatsApp's "send to…" picker. It creates the chat
     * thread once the message is sent, which is what lets a later
     * [shareImageToChat] (with `jid`) land in that chat.
     */
    private fun openChat(phone: String, text: String, pkg: String): Boolean {
        return try {
            val digits = repairWhatsAppDigits(phone)
            if (digits.length !in 11..15) return false
            val builder = Uri.parse("https://api.whatsapp.com/send").buildUpon()
                .appendQueryParameter("phone", digits)
            if (text.isNotBlank()) builder.appendQueryParameter("text", text)
            // Launched from our foreground activity (the user's tap): no NEW_TASK.
            startActivity(Intent(Intent.ACTION_VIEW, builder.build()).apply { setPackage(pkg) })
            true
        } catch (e: Exception) {
            Log.w(TAG, "openChat failed", e)
            false
        }
    }

    /**
     * Card (+ optional caption) to [phone]'s chat in ONE intent.
     *
     * Must be called while our activity is in the foreground. The previous
     * version opened Click-to-Chat and then fired this intent 1.1 s later from
     * a delayed callback; by then our app was in the background and Android 10+
     * background-activity-start restrictions silently dropped the launch, so
     * the chat opened but the card never attached.
     *
     * WhatsApp honours the unofficial `jid` extra only when the chat thread
     * already exists on this device; Dart decides when that is the case.
     */
    private fun shareImageToChat(png: ByteArray, phone: String, text: String, pkg: String): Boolean {
        return try {
            val digits = repairWhatsAppDigits(phone)
            if (digits.length !in 11..15) return false

            val dir = File(cacheDir, "wishes").apply { mkdirs() }
            pruneOldCards(dir)
            val file = File(dir, "we-decor-${System.currentTimeMillis()}.png")
            file.writeBytes(png)
            val uri = FileProvider.getUriForFile(this, "$packageName.wishprovider", file)
            grantUriPermission(pkg, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
            startActivity(sendIntent(pkg, uri, text, digits))
            true
        } catch (e: Exception) {
            Log.w(TAG, "shareImageToChat failed", e)
            false
        }
    }

    /**
     * ACTION_SEND for one WhatsApp package. Sets [ClipData] as well as EXTRA_STREAM —
     * without ClipData, Android 7+ often hands WhatsApp an unreadable URI so the
     * image silently drops. No NEW_TASK: started from our foreground activity, like
     * any normal share, so WhatsApp's share screen opens on top of us.
     */
    private fun sendIntent(pkg: String, uri: Uri, text: String, digits: String): Intent {
        return Intent(Intent.ACTION_SEND).apply {
            type = "image/png"
            setPackage(pkg)
            putExtra(Intent.EXTRA_STREAM, uri)
            if (text.isNotBlank()) putExtra(Intent.EXTRA_TEXT, text)
            putExtra("jid", "$digits@s.whatsapp.net")
            clipData = ClipData.newUri(contentResolver, "we-decor-card", uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
    }

    /** Cards older than a day are no longer needed by WhatsApp. */
    private fun pruneOldCards(dir: File) {
        val cutoff = System.currentTimeMillis() - CARD_MAX_AGE_MS
        dir.listFiles()?.forEach { f ->
            if (f.isFile && f.lastModified() < cutoff) f.delete()
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

    private fun hasContactsPermission(): Boolean {
        val read = ContextCompat.checkSelfPermission(this, Manifest.permission.READ_CONTACTS)
        val write = ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_CONTACTS)
        return read == PackageManager.PERMISSION_GRANTED && write == PackageManager.PERMISSION_GRANTED
    }

    /**
     * True if [phone] matches any row via [ContactsContract.PhoneLookup].
     * Tries `+` + international digits, then the 10-digit national form.
     */
    private fun isInContacts(phone: String): Boolean {
        val digits = repairWhatsAppDigits(phone)
        if (digits.length !in 11..15) return false
        if (lookupPhone("+$digits")) return true
        // Also try bare national (last 10) — many Indian contacts are stored that way.
        if (digits.length >= 10) {
            val national = digits.takeLast(10)
            if (lookupPhone(national)) return true
        }
        return false
    }

    private fun lookupPhone(query: String): Boolean {
        return try {
            val uri = Uri.withAppendedPath(
                ContactsContract.PhoneLookup.CONTENT_FILTER_URI,
                Uri.encode(query),
            )
            contentResolver.query(
                uri,
                arrayOf(ContactsContract.PhoneLookup._ID),
                null,
                null,
                null,
            )?.use { cursor -> cursor.moveToFirst() } ?: false
        } catch (e: Exception) {
            Log.w(TAG, "lookupPhone failed for query length=${query.length}", e)
            false
        }
    }

    /**
     * Inserts a device-only contact (null account — not synced to Google).
     * Never updates or deletes existing contacts.
     */
    private fun saveContact(name: String, phone: String): Boolean {
        return try {
            val digits = repairWhatsAppDigits(phone)
            if (digits.length !in 11..15) return false
            val display = name.trim().ifEmpty { "+$digits" }
            val ops = ArrayList<ContentProviderOperation>()
            ops.add(
                ContentProviderOperation.newInsert(ContactsContract.RawContacts.CONTENT_URI)
                    .withValue(ContactsContract.RawContacts.ACCOUNT_TYPE, null)
                    .withValue(ContactsContract.RawContacts.ACCOUNT_NAME, null)
                    .build(),
            )
            ops.add(
                ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                    .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                    .withValue(
                        ContactsContract.Data.MIMETYPE,
                        ContactsContract.CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE,
                    )
                    .withValue(
                        ContactsContract.CommonDataKinds.StructuredName.DISPLAY_NAME,
                        display,
                    )
                    .build(),
            )
            ops.add(
                ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                    .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                    .withValue(
                        ContactsContract.Data.MIMETYPE,
                        ContactsContract.CommonDataKinds.Phone.CONTENT_ITEM_TYPE,
                    )
                    .withValue(ContactsContract.CommonDataKinds.Phone.NUMBER, "+$digits")
                    .withValue(
                        ContactsContract.CommonDataKinds.Phone.TYPE,
                        ContactsContract.CommonDataKinds.Phone.TYPE_MOBILE,
                    )
                    .build(),
            )
            contentResolver.applyBatch(ContactsContract.AUTHORITY, ops)
            true
        } catch (e: Exception) {
            Log.w(TAG, "saveContact failed", e)
            false
        }
    }

    private fun requestContactsPermission(result: MethodChannel.Result) {
        if (hasContactsPermission()) {
            result.success(true)
            return
        }
        if (pendingContactsPermissionResult != null) {
            result.success(false)
            return
        }
        pendingContactsPermissionResult = result
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.READ_CONTACTS, Manifest.permission.WRITE_CONTACTS),
            REQ_CONTACTS_PERMISSION,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        if (requestCode != REQ_CONTACTS_PERMISSION) {
            super.onRequestPermissionsResult(requestCode, permissions, grantResults)
            return
        }
        val ok = grantResults.isNotEmpty() &&
            grantResults.all { it == PackageManager.PERMISSION_GRANTED }
        pendingContactsPermissionResult?.success(ok)
        pendingContactsPermissionResult = null
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
        private const val TAG = "WeDecorWhatsApp"
        private const val CARD_MAX_AGE_MS = 24L * 60 * 60 * 1000
        private const val REQ_CONTACTS_PERMISSION = 9911
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
