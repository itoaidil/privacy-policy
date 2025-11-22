plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

android {
    namespace = "com.example.travel_booking_app"
    compileSdk = flutter.compileSdkVersion
    // ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    // Disable NDK to avoid download issues
    buildFeatures {
        buildConfig = true
    }
    
    packagingOptions {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.travel_booking_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Explicitly set ndk to avoid auto-download
        ndk {
            abiFilters.clear()
        }
    }

    // Release signing configuration
    // Store credentials in ~/.gradle/gradle.properties or project gradle.properties:
    //   MYAPP_UPLOAD_STORE_FILE=/path/to/upload-keystore.jks
    //   MYAPP_UPLOAD_KEY_ALIAS=upload
    //   MYAPP_UPLOAD_STORE_PASSWORD=your-store-password
    //   MYAPP_UPLOAD_KEY_PASSWORD=your-key-password
    signingConfigs {
        create("release") {
            val keystorePropertiesFile = rootProject.file("key.properties")
            if (keystorePropertiesFile.exists()) {
                val keystoreProperties = Properties()
                keystoreProperties.load(FileInputStream(keystorePropertiesFile))
                
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            } else {
                // Fallback to Gradle properties
                storeFile = file(System.getProperty("MYAPP_UPLOAD_STORE_FILE") ?: 
                    System.getenv("MYAPP_UPLOAD_STORE_FILE") ?: "")
                storePassword = System.getProperty("MYAPP_UPLOAD_STORE_PASSWORD") ?: 
                    System.getenv("MYAPP_UPLOAD_STORE_PASSWORD")
                keyAlias = System.getProperty("MYAPP_UPLOAD_KEY_ALIAS") ?: 
                    System.getenv("MYAPP_UPLOAD_KEY_ALIAS")
                keyPassword = System.getProperty("MYAPP_UPLOAD_KEY_PASSWORD") ?: 
                    System.getenv("MYAPP_UPLOAD_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // Disable minification for now to simplify build
            isMinifyEnabled = false
            isShrinkResources = false
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
