import org.gradle.api.tasks.compile.JavaCompile

allprojects {
    ext {
        set("appCompatVersion", "1.4.2")
        set("playServicesLocationVersion", "21.3.0")
    }
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://www.jitpack.io")
        }
        // [required] flutter_background_geolocation
        maven {
            url = uri("${project(":flutter_background_geolocation").projectDir}/libs")
        }
        // [required] background_fetch
        maven {
            url = uri("${project(":background_fetch").projectDir}/libs")
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // Configure Java compilation to suppress obsolete warnings
    afterEvaluate {
        tasks.withType<JavaCompile> {
            options.compilerArgs.addAll(listOf("-Xlint:-options"))
        }

        // Fix for packages that don't have namespace configured
        if (project.hasProperty("android")) {
            project.extensions.configure<com.android.build.gradle.BaseExtension>("android") {
                if (namespace == null) {
                    namespace = "com.example.${project.name.replace("-", "_")}"
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
