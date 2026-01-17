plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

android {
    namespace = "com.example.smartsensor"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.smartsensor"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val keystoreProperties = Properties()
    val keystorePropertiesFile = rootProject.file("key.properties")
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

// Fix for Flutter not finding APK with AGP 8.9.1
// Copy APK to Flutter's expected location after build
tasks.whenTaskAdded {
    if (name == "assembleDebug" || name == "assembleRelease" || name == "assembleProfile") {
        val buildType = name.removePrefix("assemble").lowercase()
        doLast {
            val sourceDir = file("build/outputs/apk/$buildType")
            val targetDir = file("${rootProject.projectDir}/../build/app/outputs/flutter-apk")
            if (sourceDir.exists()) {
                targetDir.mkdirs()
                sourceDir.listFiles()?.filter { it.extension == "apk" }?.forEach { apk ->
                    val targetName = if (buildType == "debug") "app-debug.apk" 
                                    else if (buildType == "release") "app-release.apk" 
                                    else "app-$buildType.apk"
                    apk.copyTo(file("${targetDir}/$targetName"), overwrite = true)
                    println("✅ Copied APK to: ${targetDir}/$targetName")
                }
            }
        }
    }
}
