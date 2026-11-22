package com.example.we_decor_enquiries

import android.Manifest
import android.accounts.AccountManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ClipData
import android.content.ContentProviderOperation
import android.content.ContentUris
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
     * Must be called while our activity is in the foreground. Delayed launches
     * after Click-to-Chat are blocked by Android 10+ background-activity rules.
     *
     * WhatsApp's unofficial `jid` extra works best when the number is in the
     * device address book and/or a chat already exists; Dart saves the contact
     * before calling this when needed.
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

    private data class ContactAccount(val name: String?, val type: String?)

    /**
     * Accounts to try when inserting. Google first (shows in Google Contacts),
     * then common OEM "Phone" buckets, then null (device-only).
     * Never updates or deletes existing contacts.
     */
    private fun contactAccountCandidates(): List<ContactAccount> {
        val out = ArrayList<ContactAccount>()
        try {
            val am = AccountManager.get(this)
            for (type in listOf("com.google", "com.google.android.gm.exchange")) {
                for (acc in am.getAccountsByType(type)) {
                    out.add(ContactAccount(acc.name, acc.type))
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "AccountManager lookup failed", e)
        }
        // OEM local buckets — visible under Phone/Device in many Contacts apps.
        out.add(ContactAccount("Phone", "com.android.localphone"))
        out.add(ContactAccount("Phone", "vnd.sec.contact.phone"))
        out.add(ContactAccount("Phone", "com.android.contacts.default"))
        out.add(ContactAccount("Phone", "com.xiaomi"))
        out.add(ContactAccount(null, null))
        return out.distinctBy { "${it.type}|${it.name}" }
    }

    /**
     * Inserts a contact that PhoneLookup can see. Tries Google / OEM / device
     * accounts until the number is findable. Never updates existing rows.
     */
    private fun saveContact(name: String, phone: String): Boolean {
        val digits = repairWhatsAppDigits(phone)
        if (digits.length !in 11..15) return false
        if (isInContacts(digits)) return true
        val display = name.trim().ifEmpty { "+$digits" }
        for (account in contactAccountCandidates()) {
            if (insertContact(display, digits, account) && isInContacts(digits)) {
                Log.i(TAG, "saveContact ok accountType=${account.type}")
                return true
            }
        }
        Log.w(TAG, "saveContact: wrote but PhoneLookup still misses digits len=${digits.length}")
        return false
    }

    private fun insertContact(display: String, digits: String, account: ContactAccount): Boolean {
        return try {
            val ops = ArrayList<ContentProviderOperation>()
            ops.add(
                ContentProviderOperation.newInsert(ContactsContract.RawContacts.CONTENT_URI)
                    .withValue(ContactsContract.RawContacts.ACCOUNT_TYPE, account.type)
                    .withValue(ContactsContract.RawContacts.ACCOUNT_NAME, account.name)
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
                    .withValue(
                        ContactsContract.CommonDataKinds.StructuredName.GIVEN_NAME,
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
            // National form helps PhoneLookup / dialer on Indian devices.
            if (digits.length >= 10) {
                ops.add(
                    ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                        .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                        .withValue(
                            ContactsContract.Data.MIMETYPE,
                            ContactsContract.CommonDataKinds.Phone.CONTENT_ITEM_TYPE,
                        )
                        .withValue(
                            ContactsContract.CommonDataKinds.Phone.NUMBER,
                            digits.takeLast(10),
                        )
                        .withValue(
                            ContactsContract.CommonDataKinds.Phone.TYPE,
                            ContactsContract.CommonDataKinds.Phone.TYPE_MOBILE,
                        )
                        .build(),
                )
            }
            ops.add(
                ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                    .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                    .withValue(
                        ContactsContract.Data.MIMETYPE,
                        ContactsContract.CommonDataKinds.Organization.CONTENT_ITEM_TYPE,
                    )
                    .withValue(ContactsContract.CommonDataKinds.Organization.COMPANY, "We Decor")
                    .build(),
            )
            val results = contentResolver.applyBatch(ContactsContract.AUTHORITY, ops)
            val uri = results.getOrNull(0)?.uri ?: return false
            ContentUris.parseId(uri) > 0
        } catch (e: Exception) {
            Log.w(TAG, "insertContact failed accountType=${account.type}", e)
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
