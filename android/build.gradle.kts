allprojects {
    repositories {
        google()
        mavenCentral()
    }
    // Force JavaCompile to 17 globally (may be ignored by some plugins)
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = "17"
        targetCompatibility = "17"
    }

    // Conditional Kotlin target
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        kotlinOptions {
            if (project.name == "audio_streamer" || 
                project.name == "sentry_flutter" || 
                project.name == "wifi_scan") {
                jvmTarget = "1.8"
            } else {
                jvmTarget = "17"
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
