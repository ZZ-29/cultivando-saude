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
    // A plataforma android-37 já está instalada (o `flutter doctor` a mostra).
    // O AGP 9.1 avisa que "foi testado até 36" — é aviso, não erro.
    compileSdk = 37

    // NDK fixado na versão REALMENTE instalada nesta máquina.
    // O Flutter 3.47 força o provisionamento do NDK 28.2.13676358 em todo app
    // (FlutterPlugin.forceNdkDownload), mas a "Android CLI" nova não sabe
    // instalar NDK — o build morria com "sdkmanager did not install NDK".
    // Instalamos o NDK 30.0.16248370 pelo SDK Manager e o declaramos aqui:
    // agora o Flutter encontra a versão instalada e não tenta baixar nada.
    // Este app não tem código C/C++, então a versão do NDK não afeta o binário.
    ndkVersion = "30.0.16248370"

    compileOptions {
        // Obrigatório para o flutter_local_notifications.
        // O plugin usa java.time (zonedSchedule) e o desugaring leva essa API
        // para aparelhos Android antigos. Sem esta linha o build falha.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "br.com.cultivandosaude.cultivando_saude"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // O desugaring gera mais métodos do que o limite antigo de 64k do DEX.
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // Assinado com a chave de debug por enquanto.
            signingConfig = signingConfigs.getByName("debug")
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
    // Versão usada pelo próprio exemplo oficial do plugin.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
