plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.sespimma.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.sespimma.app"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    // --- TAMBAHKAN SCRIPT INI UNTUK CUSTOM NAMA APK (KOTLIN DSL) ---
    applicationVariants.all {
        if (buildType.name == "release") {
            outputs.all {
                // Di Kotlin DSL, kita perlu melakukan casting ke BaseVariantOutputImpl
                val outputImpl = this as com.android.build.gradle.internal.api.BaseVariantOutputImpl
                outputImpl.outputFileName = "sespimma-v1.5(14)-alpha.apk"
            }
        }
    }
    // ---------------------------------------------------------------
}

flutter {
    source = "../.."
}