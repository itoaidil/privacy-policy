allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Revert custom build directory override to default to avoid Flutter invalid depfile issues.
// The previous redirection to "../../build" caused unusual relative paths for Flutter's kernel snapshot.
// Using standard Gradle build dirs helps stabilize incremental compilation and depfile generation.

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
