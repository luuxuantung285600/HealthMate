import com.android.build.api.dsl.ApplicationExtension
import java.io.File
import java.util.Properties
import java.util.Base64

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseKeys = Properties()
val releaseKeysFile = rootProject.file("key.properties")
if (releaseKeysFile.exists()) {
    releaseKeysFile.inputStream().use { releaseKeys.load(it) }
}
val signingReady = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
    .all { !releaseKeys.getProperty(it).isNullOrBlank() }

// Inspect the resolved graph, including aliases such as `assemble`, so a release
// cannot evade the guard by omitting "release" from the command line.
gradle.taskGraph.whenReady {
    if (allTasks.any { it.name.contains("release", ignoreCase = true) }) {
        if (!signingReady) {
            throw GradleException("HealthMate release signing is not configured. Supply private android/key.properties; see docs/release-readiness.md. Debug builds remain available.")
        }
        val keyPath = File(releaseKeys.getProperty("storeFile"))
        if (!keyPath.isAbsolute || !keyPath.isFile ||
            keyPath.name.equals("debug.keystore", ignoreCase = true) ||
            releaseKeys.getProperty("keyAlias").equals("androiddebugkey", ignoreCase = true)) {
            throw GradleException("HealthMate release requires an existing absolute private keystore path and a non-debug signing identity.")
        }
        val rawDefines = providers.gradleProperty("dart-defines").orNull.orEmpty()
        val seen = mutableSetOf<String>()
        val releaseDefines = mutableMapOf<String, String>()
        val allowedHealthMateDefines = setOf(
            "HEALTHMATE_ENABLE_ADMIN_CONTROLS", "HEALTHMATE_ENABLE_PREMIUM_DEMO",
            "HEALTHMATE_ENABLE_CHATBOT", "HEALTHMATE_ENABLE_FOOD_SCANNER",
            "HEALTHMATE_CHAT_API_URL", "HEALTHMATE_GOOGLE_SERVER_CLIENT_ID",
        )
        rawDefines.split(',').filter { it.isNotEmpty() }.forEach { encoded ->
            val entry = try {
                String(Base64.getDecoder().decode(encoded), Charsets.UTF_8)
            } catch (_: IllegalArgumentException) {
                throw GradleException("Malformed release dart-defines; values are not logged.")
            }
            val key = entry.substringBefore('=')
            val value = entry.substringAfter('=', "")
            if (!entry.contains('=') || !seen.add(key)) {
                throw GradleException("Malformed or duplicate release dart-define; values are not logged.")
            }
            val normalizedKey = key.uppercase()
            if (normalizedKey.contains("DEBUG") || normalizedKey.contains("EMULATOR")) {
                throw GradleException("Debug/emulator dart-defines are forbidden in HealthMate release builds; values are not logged.")
            }
            if (key.startsWith("HEALTHMATE_") && key !in allowedHealthMateDefines) {
                throw GradleException("Unknown HealthMate release dart-define; values are not logged.")
            }
            releaseDefines[key] = value
            if (key == "HEALTHMATE_ENABLE_PREMIUM_DEMO" && value != "false") {
                throw GradleException("Premium demo must be disabled in release builds.")
            }
        }
        val requiredDefines = mapOf(
            "HEALTHMATE_ENABLE_ADMIN_CONTROLS" to "true",
            "HEALTHMATE_ENABLE_PREMIUM_DEMO" to "false",
            "HEALTHMATE_ENABLE_CHATBOT" to "false",
            "HEALTHMATE_CHAT_API_URL" to "",
        )
        if (requiredDefines.any { (key, value) -> releaseDefines[key] != value } ||
            releaseDefines["HEALTHMATE_ENABLE_FOOD_SCANNER"] !in setOf("true", "false")) {
            throw GradleException("Explicit approved release configuration required. AI gateway remains unverified; use config/release-candidate.json.")
        }
    }
}

extensions.configure<ApplicationExtension> {
    namespace = "com.example.healthmate"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.healthmate"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (signingReady) {
            create("release") {
                keyAlias = releaseKeys.getProperty("keyAlias")
                keyPassword = releaseKeys.getProperty("keyPassword")
                storeFile = file(releaseKeys.getProperty("storeFile"))
                storePassword = releaseKeys.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (signingReady) signingConfigs.getByName("release") else null
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
