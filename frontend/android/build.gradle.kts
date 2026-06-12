allprojects {
    repositories {
        google()
        mavenCentral()
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

    project.evaluationDependsOn(":app")

    configurations.all {

        // ✅ 1. Force correct TensorFlow Lite version
        resolutionStrategy {
            eachDependency {
                if (requested.group == "org.tensorflow") {
                    if (requested.name.startsWith("tensorflow-lite")) {
                        useVersion("2.12.0")
                    }
                }
            }
        }

        // ✅ 2. Remove conflicting modules (THIS IS CORRECT PLACE)
        exclude(group = "org.tensorflow", module = "tensorflow-lite-api")
        exclude(group = "org.tensorflow", module = "tensorflow-lite-gpu")
    }
}