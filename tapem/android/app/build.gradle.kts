import java.util.Properties
import java.util.Base64

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

fun firstNonBlank(vararg values: String?): String? =
    values.firstOrNull { !it.isNullOrBlank() }?.trim()

val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) {
        file.inputStream().use(::load)
    }
}

val releaseStoreFile = firstNonBlank(
    providers.gradleProperty("ANDROID_KEYSTORE_PATH").orNull,
    System.getenv("ANDROID_KEYSTORE_PATH"),
    keystoreProperties.getProperty("storeFile"),
)
val releaseKeystoreBase64 = firstNonBlank(
    providers.gradleProperty("ANDROID_KEYSTORE_BASE64").orNull,
    System.getenv("ANDROID_KEYSTORE_BASE64"),
)
val releaseStorePassword = firstNonBlank(
    providers.gradleProperty("ANDROID_KEYSTORE_PASSWORD").orNull,
    System.getenv("ANDROID_KEYSTORE_PASSWORD"),
    keystoreProperties.getProperty("storePassword"),
)
val releaseKeyAlias = firstNonBlank(
    providers.gradleProperty("ANDROID_KEY_ALIAS").orNull,
    System.getenv("ANDROID_KEY_ALIAS"),
    keystoreProperties.getProperty("keyAlias"),
)
val releaseKeyPassword = firstNonBlank(
    providers.gradleProperty("ANDROID_KEY_PASSWORD").orNull,
    System.getenv("ANDROID_KEY_PASSWORD"),
    keystoreProperties.getProperty("keyPassword"),
)

val hasReleaseSigning = listOf(
    releaseStorePassword,
    releaseKeyAlias,
    releaseKeyPassword,
).all { !it.isNullOrBlank() }

val resolvedReleaseStoreFile = when {
    !releaseKeystoreBase64.isNullOrBlank() -> {
        val out = layout.buildDirectory.file("secrets/release-upload-keystore.bin").get().asFile
        out.parentFile.mkdirs()
        out.writeBytes(Base64.getDecoder().decode(releaseKeystoreBase64))
        out
    }
    !releaseStoreFile.isNullOrBlank() -> rootProject.file(releaseStoreFile)
    else -> null
}

val hasReleaseStoreFile = resolvedReleaseStoreFile != null
val hasCompleteReleaseSigning = hasReleaseSigning && hasReleaseStoreFile

android {
    namespace = "com.tapem.tapem"
    compileSdk = flutter.compileSdkVersion
    // Keep this pinned to satisfy plugin requirements consistently in CI/local.
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.tapem.tapem"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasCompleteReleaseSigning) {
            create("release") {
                storeFile = requireNotNull(resolvedReleaseStoreFile)
                storePassword = requireNotNull(releaseStorePassword)
                keyAlias = requireNotNull(releaseKeyAlias)
                keyPassword = requireNotNull(releaseKeyPassword)
            }
        }
    }

    buildTypes {
        release {
            if (hasCompleteReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

val verifyReleaseSigning by tasks.registering {
    group = "verification"
    description = "Validates that release signing is fully configured."
    doLast {
        if (!hasCompleteReleaseSigning) {
            throw GradleException(
                """
                Missing Android release signing configuration.

                Provide either:
                - android/key.properties with: storeFile, storePassword, keyAlias, keyPassword
                - or environment / Gradle properties:
                  ANDROID_KEYSTORE_PATH, ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS, ANDROID_KEY_PASSWORD
                - or CI base64 keystore:
                  ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS, ANDROID_KEY_PASSWORD

                See android/README_SIGNING.md for the full setup.
                """.trimIndent(),
            )
        }

        val keystoreFile = requireNotNull(resolvedReleaseStoreFile)
        if (!keystoreFile.exists()) {
            throw GradleException("Configured keystore file does not exist: ${keystoreFile.absolutePath}")
        }
    }
}

tasks.matching { task ->
    task.name in setOf("assembleRelease", "bundleRelease", "packageRelease")
}.configureEach {
    dependsOn(verifyReleaseSigning)
}

tasks.matching { it.name == "preReleaseBuild" }.configureEach {
    dependsOn(verifyReleaseSigning)
}

flutter {
    source = "../.."
}
