plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin") // ✅ Flutter plugin must be after Android/Kotlin plugins
}

android {
    namespace = "com.example.greyappnew"
    compileSdk = 35  // ✅ Updated SDK version

    defaultConfig {
        applicationId = "com.example.greyappnew"
        minSdk = 21
        targetSdk = 35  // ✅ Ensure it's 35, not 34
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug") // ✅ Fix signing config
        }
    }

    buildFeatures {
        viewBinding = true
    }

    compileOptions {
        isCoreLibraryDesugaringEnabled = true  // ✅ Enable core library desugaring
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"  // ✅ Match Java 17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") // Updated to required version

}
