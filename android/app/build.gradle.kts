import java.io.FileInputStream
import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

fun releaseSetting(environmentName: String, propertyName: String): String? {
    return System.getenv(environmentName)?.takeIf { it.isNotBlank() }
        ?: keystoreProperties.getProperty(propertyName)?.takeIf { it.isNotBlank() }
}

val releaseStorePath = releaseSetting("ANDROID_KEYSTORE_PATH", "storeFile")
val releaseStorePassword = releaseSetting("ANDROID_KEYSTORE_PASSWORD", "storePassword")
val releaseKeyAlias = releaseSetting("ANDROID_KEY_ALIAS", "keyAlias")
val releaseKeyPassword = releaseSetting("ANDROID_KEY_PASSWORD", "keyPassword")
val hasReleaseSigning = listOf(
    releaseStorePath,
    releaseStorePassword,
    releaseKeyAlias,
    releaseKeyPassword,
).all { !it.isNullOrBlank() }

val requireReleaseSigning =
    System.getenv("DADAFINANZA_REQUIRE_RELEASE_SIGNING") == "1"

if (requireReleaseSigning && !hasReleaseSigning) {
    throw GradleException(
        "Production release signing is required but the Android signing credentials are missing.",
    )
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.dadafinanza.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.dadafinanza.app"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(releaseStorePath!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            // Local/internal release builds may still use the debug key when no
            // production credentials are present. The Play Store workflow sets
            // DADAFINANZA_REQUIRE_RELEASE_SIGNING=1, so it can never silently
            // produce a debug-signed bundle.
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
