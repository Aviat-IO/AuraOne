import org.gradle.api.tasks.compile.JavaCompile

allprojects {
    ext {
        set("appCompatVersion", "1.4.2")             // or higher / as desired
        set("playServicesLocationVersion", "21.3.0") // or higher / as desired
    }
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://transistorsoft.jfrog.io/artifactory/maven")
        }
        // [required] flutter_background_geolocation
        maven(url = "${project(":flutter_background_geolocation").projectDir}/libs")
        maven(url = "https://developer.huawei.com/repo/")
        // [required] background_fetch
        maven(url = "${project(":background_fetch").projectDir}/libs")
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
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
