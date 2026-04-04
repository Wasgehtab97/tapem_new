# Android Release Signing (Play Store)

This project is configured for secure release signing with:

- local file-based secrets (`android/key.properties`)
- CI-friendly environment variables
- hard fail for `bundleRelease`/`assembleRelease` if signing is missing

## 1) Generate an upload keystore (one-time)

Use a dedicated upload key for Google Play App Signing.

Preferred (project helper):

```bash
./scripts/android/create_upload_keystore.sh
```

This creates:

- `android/keystore/tapem-upload-keystore.p12`
- `android/key.properties` (gitignored)
- `android/.signing_credentials.txt` (gitignored; move to password manager)

Manual alternative:

```bash
keytool -genkeypair \
  -v \
  -storetype PKCS12 \
  -keyalg RSA \
  -keysize 4096 \
  -validity 10000 \
  -alias tapem_upload \
  -keystore ~/secure/tapem-upload-keystore.p12
```

Store this file in a secure location (not in git).

## 2) Local setup

Copy the template:

```bash
cp android/key.properties.example android/key.properties
```

Set real values in `android/key.properties`:

- `storeFile`
- `storePassword`
- `keyAlias`
- `keyPassword`

`android/.gitignore` already excludes `key.properties` and keystore files.

## 3) CI setup (recommended)

Set these CI secrets (instead of `key.properties`):

- `ANDROID_KEYSTORE_PATH`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

These values take precedence over `key.properties`.

Alternative for CI without filesystem secret mount:

- `ANDROID_KEYSTORE_BASE64` (base64-encoded keystore, e.g. `.p12`)
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

When `ANDROID_KEYSTORE_BASE64` is set, the build writes a temporary keystore to
`android/build/secrets/release-upload-keystore.bin`.

## 4) Validate configuration

```bash
cd android
./gradlew verifyReleaseSigning
```

## 5) Build Play artifact

Use an Android App Bundle for Play Store:

```bash
flutter build appbundle --release --dart-define-from-file=.env.json
```

Output:

`build/app/outputs/bundle/release/app-release.aab`

## 6) Export upload certificate fingerprints (for Play Console)

```bash
./scripts/android/print_upload_cert_fingerprints.sh
```

Use the SHA-1 / SHA-256 values when Play Console asks for your upload key cert.

## 7) Export upload certificate as PEM (for Play Console)

```bash
./scripts/android/export_upload_certificate_pem.sh
```

Output:

`android/keystore/upload_certificate.pem`

## 8) CI secret helper (base64 mode)

```bash
./scripts/android/encode_keystore_base64.sh
```

Copy the output into the `ANDROID_KEYSTORE_BASE64` GitHub secret.

## Operational best practices

- Back up the upload key offline (encrypted vault + controlled access).
- Keep at least 2 owners with documented recovery procedure.
- Rotate CI credentials periodically.
- Never commit keystore files or signing passwords.
