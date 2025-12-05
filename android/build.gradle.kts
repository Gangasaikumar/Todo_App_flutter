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

    afterEvaluate {
        val android = extensions.findByName("android")
        if (android != null) {
            try {
                val namespaceMethod = android.javaClass.getMethod("getNamespace")
                val namespace = namespaceMethod.invoke(android)
                if (namespace == null) {
                    val setNamespaceMethod = android.javaClass.getMethod("setNamespace", String::class.java)
                    setNamespaceMethod.invoke(android, group.toString())
                }
            } catch (e: Exception) {
                // Ignore
            }

            try {
                val compileOptionsMethod = android.javaClass.getMethod("getCompileOptions")
                val compileOptions = compileOptionsMethod.invoke(android)

                val setSourceCompatibility = compileOptions.javaClass.getMethod("setSourceCompatibility", JavaVersion::class.java)
                setSourceCompatibility.invoke(compileOptions, JavaVersion.VERSION_17)

                val setTargetCompatibility = compileOptions.javaClass.getMethod("setTargetCompatibility", JavaVersion::class.java)
                setTargetCompatibility.invoke(compileOptions, JavaVersion.VERSION_17)
            } catch (e: Exception) {
                // Ignore
            }
            
            try {
                val setCompileSdkVersionMethod = android.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                setCompileSdkVersionMethod.invoke(android, 36)
            } catch (e: Exception) {
                // Ignore
            }
        }
    }
    tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile::class).configureEach {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
