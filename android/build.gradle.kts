allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// AGP 9, eklenti modüllerinin compileSdk'sını da AAR üstverisine karşı
// denetliyor. flutter_native_splash 2.4.4 hâlâ android-31 ile derleniyor
// (2.4.6 düzeltiyor ama excel'in archive ^3 kısıtı yükseltmeyi engelliyor);
// eklentinin kendi build.gradle'ı compileSdk'yı yazdıktan SONRA ezilir.
// Bu blok evaluationDependsOn'dan ÖNCE kalmalı: afterEvaluate, değerlendirilmiş
// projeye kaydedilemez.
subprojects {
    if (name == "flutter_native_splash") {
        afterEvaluate {
            extensions.configure<com.android.build.gradle.LibraryExtension> {
                compileSdk = 36
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
