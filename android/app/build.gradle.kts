plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.navtest"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // Enable BuildConfig generation so flavor fields are accessible in Kotlin
    buildFeatures {
        buildConfig = true
    }

    defaultConfig {
        // Overridden per flavor below
        minSdk = 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ---------------------------------------------------------------------------
    // Flavor dimensions
    // ---------------------------------------------------------------------------
    flavorDimensions += "environment"

    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationId = "com.example.navtest.dev"
            resValue("string", "app_name", "NavTest Dev")
            // Routing server — can be changed per environment
            buildConfigField("String", "ROUTING_BASE_URL", "\"https://router.project-osrm.org\"")
            buildConfigField("String", "FLAVOR_NAME", "\"dev\"")
        }
        create("prod") {
            dimension = "environment"
            applicationId = "com.example.navtest"
            resValue("string", "app_name", "NavTest")
            buildConfigField("String", "ROUTING_BASE_URL", "\"https://router.project-osrm.org\"")
            buildConfigField("String", "FLAVOR_NAME", "\"prod\"")
        }
    }

    buildTypes {
        release {
            // Use debug signing for now; replace with a real keystore before shipping
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // FusedLocationProviderClient — required for native location implementation
    implementation("com.google.android.gms:play-services-location:21.3.0")
}
