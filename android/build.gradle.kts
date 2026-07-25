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
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    val configureAndroidSDK = Action<Project> {
        extensions.findByName("android")?.let { androidExtension ->
            try {
                val setCompileSdkMethod = androidExtension.javaClass.getMethod("setCompileSdk", java.lang.Integer::class.java)
                setCompileSdkMethod.invoke(androidExtension, 36)
            } catch (e: NoSuchMethodException) {
                val compileSdkVersionMethod = androidExtension.javaClass.getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
                compileSdkVersionMethod.invoke(androidExtension, 36)
            }
        }
    }

    if (state.executed) {
        configureAndroidSDK.execute(this)
    } else {
        afterEvaluate {
            configureAndroidSDK.execute(this)
        }
    }
}