# Gravity Flip — One-Click APK Builder

This package is prepared so you can build the Android APK online without installing Unity or Godot.

## Easiest method: GitHub Actions

1. Create/sign in to a GitHub account.
2. Create a new **private or public repository**.
3. Upload the **contents of this folder** into the repository (not the outer ZIP folder itself).
4. Open the repository's **Actions** tab.
5. Select **Build Gravity Flip APK**.
6. Click **Run workflow**.
7. Wait for the build to finish.
8. Open the completed workflow run and download the artifact named **GravityFlip-Android-APK**.
9. Extract the downloaded artifact and install `GravityFlip.apk` on your Android phone.

The workflow uses Godot 4.3 and a GitHub Actions build runner. Godot supports command-line/headless Android exports, which is why this can be done entirely in the cloud.

## Important

- This first build is a **debug APK** for easy testing.
- For Google Play publishing, a **release-signed AAB/APK** should be created with your own keystore. Do not put keystore passwords or private signing keys into the repository.
- The Android package ID is `com.totcom.gravityflip`.
- The game includes the Info credit: **DESIGNED BY Totcom Technologies**.

## If GitHub asks for permissions

GitHub Actions may need to be enabled for the repository. The workflow itself does not require you to install Godot, Android Studio, Java, or the Android SDK locally.
