import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release imzası: android/key.properties varsa kullanılır; yoksa debug
// imzasına düşülür ki keystore olmadan da `flutter run --release` çalışsın.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "dev.halilibrahim.cunehat"
    compileSdk = 36
    ndkVersion = "27.0.12077973"


    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "dev.halilibrahim.cunehat"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        // Geliştirme derlemesi AYRI bir uygulama olarak kurulur
        // (`dev.halilibrahim.cunehat.dev`).
        //
        // Neden: Play'deki sürüm Play'in kendi imzasıyla imzalıdır; yerelde
        // üretilen APK — upload anahtarıyla imzalansa bile — onun ÜZERİNE
        // kurulamaz (INSTALL_FAILED_UPDATE_INCOMPATIBLE). Tek çare uygulamayı
        // kaldırmak olurdu, bu da gerçek veriyi silerdi. Ayrı paket adıyla
        // ikisi yan yana durur: Play sürümü ve verisi hiç ellenmez.
        //
        // SÜRÜM (release) derlemesi DEĞİŞMEZ: AAB hâlâ
        // `dev.halilibrahim.cunehat`. Google ile giriş (Drive yedekleme) dev
        // pakette çalışmaz — OAuth istemcisi paket adı + SHA-1'e bağlı
        // (bkz. drive-oauth-package-mismatch); yerel yedek/geri yükleme çalışır.
        debug {
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
        }
        // `--profile` de aynı ayrı pakete gider: debug JIT olduğu için 85
        // satırlık ekstre listesi cihazda yanıltıcı biçimde yavaş görünür,
        // profile derlemesi AOT'tur. (`maybeCreate`: "profile" tipini Flutter
        // eklentisi kuruyor, sıraya bağlı kalmayalım.)
        maybeCreate("profile").apply {
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
        }
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
