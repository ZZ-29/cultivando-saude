plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "br.com.cultivandosaude.cultivando_saude"

    // compileSdk = 37 (e não o padrão 36 do Flutter 3.47).
    // O flutter_local_notifications 23 e o androidx.core 1.19 exigem compilar
    // contra as APIs 37; com 36 o build morre no checkDebugAarMetadata.
    compileSdk = 37

    // NDK fixado na versão REALMENTE instalada nesta máquina.
    // O Flutter 3.47 força o provisionamento do NDK 28.2.13676358 em todo app
    // (FlutterPlugin.forceNdkDownload), mas a "Android CLI" nova não sabe
    // instalar NDK — o build morria com "sdkmanager did not install NDK".
    ndkVersion = "30.0.16248370"

    compileOptions {
        // Obrigatório para o flutter_local_notifications (java.time + desugaring).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // Chave de release própria, criada para este app.
    // O arquivo vive FORA do repositório (android-build/ está no .gitignore);
    // se não existir (ex.: na CI), o release cai para a chave de debug.
    val keystore = rootProject.file("../android-build/cultivando.jks")
    signingConfigs {
        if (keystore.exists()) {
            create("release") {
                storeFile = keystore
                storePassword = System.getenv("CULTIVANDO_SENHA") ?: "cultivando2026"
                keyAlias = "cultivando"
                keyPassword = System.getenv("CULTIVANDO_SENHA") ?: "cultivando2026"
                // Assinar nos três esquemas: sem a v1 (JAR), alguns aparelhos
                // e instaladores recusam o APK como "instalador inválido".
                enableV1Signing = true
                enableV2Signing = true
                enableV3Signing = true
            }
        }
    }

    defaultConfig {
        applicationId = "br.com.cultivandosaude.cultivando_saude"

        // Android 7.0 (API 24). Não dá para descer: o
        // flutter_local_notifications 23 declara minSdk 24 no manifest dele,
        // e o Flutter 3.47 também exige 24.
        minSdk = 24

        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = if (keystore.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
