// [파일 위치: android/app/build.gradle.kts]
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // ✅ [수정 완료] 네이버 콘솔에 등록한 이름과 똑같이 언더바(_) 사용
    namespace = "com.sm_general.sales_note"
    compileSdk = flutter.compileSdkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // ✅ [수정 완료] 앱의 진짜 신분증 이름을 언더바(_)로 일치시킴
        applicationId = "com.sm_general.sales_note"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // 나머지 설정들 (buildTypes 등)은 기존 기능 100% 유지
}

flutter {
    source = "../.."
}