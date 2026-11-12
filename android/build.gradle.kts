allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
        // Додаємо jcenter як застарілий репозиторій, оскільки старі плагіни Bluetooth його шукають
        maven { url = uri("https://jcenter.bintray.com") }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val androidExtension = project.extensions.getByName("android") as com.android.build.api.dsl.CommonExtension
            val currentNamespace = androidExtension.namespace
            if (currentNamespace == null || currentNamespace.isEmpty() || currentNamespace.startsWith(".")) {
                val groupStr = project.group.toString()
                androidExtension.namespace = if (groupStr.isNotEmpty() && !groupStr.startsWith(".")) {
                    "$groupStr.${project.name.replace("-", "_")}"
                } else {
                    "com.example.${project.name.replace("-", "_")}"
                }
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
