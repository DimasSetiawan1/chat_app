subprojects {
    project.evaluationDependsOn(":app")
}
subprojects {
    // fix for verifyReleaseResources
    // ============
    plugins.withId("com.android.application") {
        extensions.configure(com.android.build.api.dsl.ApplicationExtension::class.java) {
           // compileSdk = 34;
            if (namespace.isNullOrBlank()) {
                namespace = project.group.toString()
            }
        }
    }
    plugins.withId("com.android.library") {
        extensions.configure(com.android.build.api.dsl.LibraryExtension::class.java) {
            compileSdk = 34
            if (namespace.isNullOrBlank()) {
                namespace = project.group.toString()
            }
        }
    }
    // ============
    project.buildDir = file("${rootProject.buildDir}/${project.name}")
    project.evaluationDependsOn(":app")
}

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
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}