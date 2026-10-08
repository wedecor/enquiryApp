import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(localPropertiesFile.inputStream())
}

fun localReleaseProp(name: String): String? {
    return localProperties.getProperty(name) ?: (project.findProperty(name) as String?)
}

android {
    namespace = "com.example.we_decor_enquiries"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // NOTE: applicationId/namespace are still the Flutter template "com.example..." id.
        // Do NOT change it casually: a new id is a different app on Android, so existing
        // users could not update in place (they would have to uninstall + reinstall and
        // re-register for push). Change only as a planned migration.
        applicationId = "com.example.we_decor_enquiries"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val storeFilePath = localReleaseProp("RELEASE_STORE_FILE")
            if (storeFilePath != null) {
                storeFile = file(storeFilePath)
                storePassword = localReleaseProp("RELEASE_STORE_PASSWORD")
                keyAlias = localReleaseProp("RELEASE_KEY_ALIAS")
                keyPassword = localReleaseProp("RELEASE_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        debug {
            isMinifyEnabled = false
            isDebuggable = true
        }
        release {
            // Release builds MUST be signed with the release keystore. Falling back to the
            // debug key produces an APK that cannot be installed over the existing app
            // (signature mismatch), so fail loudly instead. Only enforced when a release
            // task is actually requested, so debug builds keep working without the keystore.
            val releaseTaskRequested = gradle.startParameter.taskNames.any {
                it.contains("Release", ignoreCase = true)
            }
            val missingReleaseProps = listOf(
                "RELEASE_STORE_FILE",
                "RELEASE_STORE_PASSWORD",
                "RELEASE_KEY_ALIAS",
                "RELEASE_KEY_PASSWORD",
            ).filter { localReleaseProp(it).isNullOrBlank() }
            if (releaseTaskRequested) {
                if (missingReleaseProps.isNotEmpty()) {
                    throw GradleException(
                        "Release signing is not configured. Missing: " +
                            missingReleaseProps.joinToString(", ") +
                            ". Add them to android/local.properties (or pass -P<name>=...). " +
                            "Refusing to sign a release build with the debug key."
                    )
                }
                val keystoreFile = file(localReleaseProp("RELEASE_STORE_FILE")!!)
                if (!keystoreFile.exists()) {
                    throw GradleException(
                        "Release keystore not found at ${keystoreFile.absolutePath} (RELEASE_STORE_FILE)."
                    )
                }
            }
            signingConfig = signingConfigs.getByName("release")

            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
