# Firebase Phone Auth Android Setup Guide

This guide outlines the steps to resolve and prevent the following error in **Kutub FM**:
`This app is not authorized to use Firebase Authentication. Please verify that the correct package name, SHA-1, and SHA-256 are configured in the Firebase Console. [ Invalid app info in play_integrity_token ]`

---

## 1. Firebase Console Configuration

### A. Enable Phone Authentication
1. Open the [Firebase Console](https://console.firebase.google.com/).
2. Select your project: **kutubfm-1ef89**.
3. In the left sidebar, navigate to **Build > Authentication** and select the **Sign-in method** tab.
4. Under **Native providers**, click on **Phone**, toggle the **Enable** switch, and click **Save**.

### B. Configure SMS Region Policy
1. Inside **Authentication**, select the **Settings** tab.
2. Expand the **SMS region policy** section.
3. Ensure that **Egypt (+20)** (and any other target regions) is allowed.

### C. Add Test Phone Numbers (for local development)
1. Go back to **Authentication > Sign-in method** and expand the **Phone** provider.
2. Scroll to the **Phone numbers for testing (optional)** section and click **Add test phone number**.
3. Add a test phone number and a corresponding verification code (e.g. Phone: `+201000000000`, Code: `123456`).
4. Click **Add**.

---

## 2. SHA Fingerprint Configuration

Firebase Phone Auth on Android uses App Attest or Play Integrity (falling back to SafetyNet/reCAPTCHA) to verify requests. To allow your application to authenticate via phone numbers:

### A. Retrieve SHA Fingerprints
Run the following command from the root of your project:
```bash
cd android && ./gradlew signingReport
```

For your local machine, the **Debug** fingerprints are:
* **Debug SHA-1**: `1D:A2:81:9D:F8:AD:B8:2D:76:EB:1D:D6:EF:14:44:C1:7E:A8:A9:CE`
* **Debug SHA-256**: `38:EC:C0:BB:61:CD:80:EC:83:07:BD:7B:18:2A:62:68:C3:EF:A1:70:36:1A:2A:4D:A1:67:CD:DC:CB:87:40:36`

### B. Add Fingerprints to Firebase Console
1. In the Firebase Console, click the gear icon next to **Project Overview** in the left sidebar and select **Project settings**.
2. Under the **General** tab, scroll down to the **Your apps** section and select your Android application (`com.example.kutub_fm`).
3. Click **Add fingerprint**.
4. Add the **SHA-1** fingerprint and click **Save**.
5. Click **Add fingerprint** again, add the **SHA-256** fingerprint, and click **Save**.

> [!IMPORTANT]
> **Release SHA Keys**: When building your application for production (release mode) or uploading it to the Google Play Store, you must also add your release signing key's SHA-1 and SHA-256 fingerprints to the same section in the Firebase Console. If you use Google Play App Signing, copy the SHA-1 and SHA-256 keys directly from the **Play Console** under **Setup > App integrity**.

---

## 3. Update Client Configuration

Once the SHA keys are added in the Firebase Console:

### Option A: Re-configure using FlutterFire CLI (Recommended)
From the project root directory, run:
```bash
flutterfire configure
```
Select your Firebase project (**kutubfm-1ef89**), select `android` (and any other relevant platforms), and allow the CLI to update your configuration files.

### Option B: Manual Update
1. Download the updated `google-services.json` from the Firebase Console (under **Project settings > General > Your apps**).
2. Replace the existing file in the project at `android/app/google-services.json`.

---

## 4. App Identification Details

For reference, the app configuration details checked and verified in this project:
* **Package Name / Application ID**: `com.example.kutub_fm` (verified in [build.gradle.kts](file:///Users/omarragab/Projects/kutub_fm/android/app/build.gradle.kts))
* **Namespace**: `com.example.kutub_fm` (verified in [build.gradle.kts](file:///Users/omarragab/Projects/kutub_fm/android/app/build.gradle.kts))
* **google-services.json package_name**: `com.example.kutub_fm` (verified in [google-services.json](file:///Users/omarragab/Projects/kutub_fm/android/app/google-services.json))
