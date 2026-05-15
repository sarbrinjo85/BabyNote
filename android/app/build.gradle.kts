import java.util.Properties
import java.io.FileInputStream
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// android/key.properties 로드 — release 서명용 (gitignore 됨).
// 파일이 없으면 빈 Properties → release 가 debug 서명으로 fallback (개발 편의).
val keystoreProperties = Properties().apply {
    val keystorePropertiesFile = rootProject.file("key.properties")
    if (keystorePropertiesFile.exists()) {
        load(FileInputStream(keystorePropertiesFile))
    }
}

android {
    namespace = "com.kjfamily.babynote"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications가 Java 8+ API 사용 → desugar 필요
        isCoreLibraryDesugaringEnabled = true
    }

    // Kotlin 2.x 새 DSL — 이전의 kotlinOptions { jvmTarget = "17" } 는 deprecated
    // (Kotlin Gradle Plugin 2.2+ 에선 컴파일 에러).
    kotlin {
        compilerOptions {
            jvmTarget = JvmTarget.JVM_17
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.kjfamily.babynote"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ── 서명 설정 ─────────────────────────────────────────────────────
    // release 서명: key.properties (gitignore 됨) 에서 비밀번호/keystore 경로 로드.
    // 파일 없으면 release 서명 설정도 생성 안 됨 → release 빌드가 debug 서명 사용.
    signingConfigs {
        if (!keystoreProperties.isEmpty) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String?
            }
        }
    }

    buildTypes {
        release {
            // key.properties 가 있으면 release 서명, 없으면 debug fallback (개발 편의).
            signingConfig = if (!keystoreProperties.isEmpty) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // 첫 출시는 코드 축소/난독화 OFF — 안정화 후 활성화 검토.
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // flutter_local_notifications가 요구하는 desugar 라이브러리
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
