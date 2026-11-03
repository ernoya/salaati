#!/usr/bin/env python3
"""Rewrite the Flutter Android build files for a given compatibility profile.

Usage: patch_android.py <profile 1|2|3> <app_dir>

Profiles escalate the Android toolchain so that CI can recover automatically
when a plugin requires a newer compileSdk / AGP / Kotlin than the project was
created with.
"""
import os
import re
import sys
import textwrap

PROFILES = {
    # Flutter 3.29.x — closest to the project's Dart 3.5 target, and the first
    # generation that exposes `flutter.compileSdkVersion` to plugin projects
    # (required by geolocator_android 4.6.2).
    "1": dict(compile_sdk="35", min_sdk="23", target_sdk="35",
              agp="8.7.3", gradle="8.12", kotlin="2.1.0", desugar="2.1.4"),
    # Flutter 3.32.x — newer Dart, compileSdk 36.
    "2": dict(compile_sdk="36", min_sdk="24", target_sdk="36",
              agp="8.7.3", gradle="8.12", kotlin="2.1.0", desugar="2.1.4"),
    # Latest stable — toolchain one notch newer.
    "3": dict(compile_sdk="36", min_sdk="24", target_sdk="36",
              agp="8.9.1", gradle="8.13", kotlin="2.1.0", desugar="2.1.4"),
}

BUILD_GRADLE = """\
plugins {{
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}}

android {{
    namespace = "com.salati.app"
    compileSdk = {compile_sdk}
    ndkVersion = flutter.ndkVersion

    compileOptions {{
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }}

    kotlinOptions {{
        jvmTarget = JavaVersion.VERSION_11
    }}

    defaultConfig {{
        applicationId = "com.salati.app"
        minSdk = {min_sdk}
        targetSdk = {target_sdk}
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }}

    buildTypes {{
        release {{
            // Debug keys: installable by sideloading, but not publishable.
            signingConfig = signingConfigs.debug
            minifyEnabled = false
            shrinkResources = false
        }}
    }}
}}

flutter {{
    source = "../.."
}}

dependencies {{
    coreLibraryDesugaring "com.android.tools:desugar_jdk_libs:{desugar}"
    implementation "androidx.multidex:multidex:2.0.1"
}}
"""

GRADLE_WRAPPER = """\
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\\://services.gradle.org/distributions/gradle-{gradle}-all.zip
"""


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__)
        return 2
    profile, app_dir = sys.argv[1], sys.argv[2]
    cfg = PROFILES[profile]
    android = os.path.join(app_dir, "android")

    with open(os.path.join(android, "app", "build.gradle"), "w") as fh:
        fh.write(BUILD_GRADLE.format(**cfg))

    with open(os.path.join(android, "gradle", "wrapper", "gradle-wrapper.properties"), "w") as fh:
        fh.write(GRADLE_WRAPPER.format(**cfg))

    settings_path = os.path.join(android, "settings.gradle")
    with open(settings_path) as fh:
        settings = fh.read()
    settings = re.sub(r'id "com\.android\.application" version "[^"]+"',
                      'id "com.android.application" version "%s"' % cfg["agp"], settings)
    settings = re.sub(r'id "org\.jetbrains\.kotlin\.android" version "[^"]+"',
                      'id "org.jetbrains.kotlin.android" version "%s"' % cfg["kotlin"], settings)
    with open(settings_path, "w") as fh:
        fh.write(settings)

    gradle_props = os.path.join(android, "gradle.properties")
    with open(gradle_props) as fh:
        props = fh.read()
    props = re.sub(r"org\.gradle\.jvmargs=.*", "org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=2G", props)
    if "android.enableJetifier" not in props:
        props += "\nandroid.enableJetifier=true\n"
    with open(gradle_props, "w") as fh:
        fh.write(props if props.endswith("\n") else props + "\n")

    print(textwrap.dedent(f"""\
        applied profile {profile}:
          compileSdk={cfg['compile_sdk']} minSdk={cfg['min_sdk']} targetSdk={cfg['target_sdk']}
          AGP={cfg['agp']} Gradle={cfg['gradle']} Kotlin={cfg['kotlin']}
          desugar_jdk_libs={cfg['desugar']}"""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
