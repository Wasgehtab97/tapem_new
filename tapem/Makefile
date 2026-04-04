IOS_SIM_ID     := 372BBDEF-052C-4B4B-A646-2EFB4EEB080D  # iPhone 16 Plus (iOS 18.6)
IOS_DEVICE_ID  := 00008130-0010745E1A09001C              # Daniels iPhone (wireless)
ENV_FILE       := .env.json

# App Store Connect API credentials — set these after creating the key in
# App Store Connect → Users and Access → Integrations → App Store Connect API.
# The matching AuthKey_<ASC_KEY_ID>.p8 file must live at:
#   ~/.appstoreconnect/private_keys/AuthKey_$(ASC_KEY_ID).p8
ASC_KEY_ID    ?= YX8L3MY7S7
ASC_ISSUER_ID ?= b8e1987b-405d-4f2f-ac95-1cf246d6f457

BUNDLE_ID     := com.tapem.tapem
IPA_PATH      := build/ios/ipa/tapem.ipa
APK_PATH      := build/app/outputs/flutter-apk/app-release.apk
AAB_PATH      := build/app/outputs/bundle/release/app-release.aab

## Run all Flutter tests.
test:
	flutter test test/

.PHONY: test ios-emu ios-iphone apk aab testflight deploy-functions signing-init signing-check signing-fingerprints signing-base64 signing-cert supabase-usage-check

## ── Edge Functions ───────────────────────────────────────────────────────────
## Deploy all Supabase Edge Functions.
## verify_jwt = false is set in supabase/config.toml — no extra flags needed.
deploy-functions:
	@echo "→ Deploying Edge Functions..."
	supabase functions deploy sync-workout
	supabase functions deploy finish-session
	supabase functions deploy process-xp-event
	supabase functions deploy dsr-export-account-data
	supabase functions deploy dsr-delete-account
	@echo "✓ All functions deployed."

## Run Supabase usage proxy alert check locally.
## Requires env vars:
##   SUPABASE_PROJECT_REF
##   SUPABASE_ACCESS_TOKEN (PAT with analytics read scope)
supabase-usage-check:
	./scripts/monitor/supabase_usage_alert.sh

ios-emu:
	@echo "→ Killing any running Flutter instances..."
	@pkill -f "flutter run" 2>/dev/null || true
	@sleep 1
	@echo "→ Booting simulator $(IOS_SIM_ID)..."
	@xcrun simctl boot $(IOS_SIM_ID) 2>/dev/null || true
	@open -a Simulator
	@echo "→ Building and launching on iOS simulator..."
	flutter run -d $(IOS_SIM_ID) --dart-define-from-file=$(ENV_FILE) --dart-define=BUILD_DATE=$$(date +'%d.%m.%Y')

ios-iphone:
	@echo "→ Killing any running Flutter instances..."
	@pkill -f "flutter run" 2>/dev/null || true
	@sleep 1
	@echo "→ Building release build for iOS..."
	flutter build ios --release --dart-define-from-file=$(ENV_FILE) --dart-define=BUILD_DATE=$$(date +'%d.%m.%Y')
	@echo "→ Installing on Daniels iPhone..."
	xcrun devicectl device install app --device $(IOS_DEVICE_ID) build/ios/iphoneos/Runner.app
	@echo "✓ App installiert — auf dem iPhone öffnen."

## ── Android ──────────────────────────────────────────────────────────────────
## Build a release APK ready for Firebase App Distribution.
## Output: $(APK_PATH)
apk:
	@echo "→ Building release APK..."
	flutter build apk --release --dart-define-from-file=$(ENV_FILE) --dart-define=BUILD_DATE=$$(date +'%d.%m.%Y')
	@echo ""
	@echo "✓ APK built: $(APK_PATH)"
	@echo "  Upload this file to Firebase App Distribution."

## Build a signed Android App Bundle for Google Play.
## Requires release signing config (see android/README_SIGNING.md).
## Output: $(AAB_PATH)
aab:
	@echo "→ Building release AAB (Google Play)..."
	flutter build appbundle --release --dart-define-from-file=$(ENV_FILE) --dart-define=BUILD_DATE=$$(date +'%d.%m.%Y')
	@echo ""
	@echo "✓ AAB built: $(AAB_PATH)"
	@echo "  Upload this file to Google Play Console."

## Create upload keystore + local key.properties (one-time, gitignored).
signing-init:
	./scripts/android/create_upload_keystore.sh

## Validate release signing configuration.
signing-check:
	cd android && ./gradlew verifyReleaseSigning --console=plain

## Print upload certificate fingerprints (SHA1/SHA256) for Play Console.
signing-fingerprints:
	./scripts/android/print_upload_cert_fingerprints.sh

## Print base64 keystore string for ANDROID_KEYSTORE_BASE64 secret.
signing-base64:
	./scripts/android/encode_keystore_base64.sh

## Export upload certificate PEM for Play Console.
signing-cert:
	./scripts/android/export_upload_certificate_pem.sh

## ── iOS / TestFlight ─────────────────────────────────────────────────────────
## Build a release IPA and upload it directly to TestFlight.
## Prerequisites:
##   1. ASC_KEY_ID and ASC_ISSUER_ID set above (or exported in shell).
##   2. ~/.appstoreconnect/private_keys/AuthKey_$(ASC_KEY_ID).p8 exists.
##   3. Xcode signed in with your Apple Developer account (automatic signing).
testflight:
	@if [ "$(ASC_KEY_ID)" = "CHANGE_ME" ] || [ "$(ASC_ISSUER_ID)" = "CHANGE_ME" ]; then \
		echo "ERROR: Set ASC_KEY_ID and ASC_ISSUER_ID at the top of the Makefile first."; \
		exit 1; \
	fi
	@CURRENT=$$(grep '^version:' pubspec.yaml | sed 's/.*+//'); \
	 NEW=$$((CURRENT + 1)); \
	 sed -i '' "s/^version: \(.*\)+$${CURRENT}$$/version: \1+$${NEW}/" pubspec.yaml; \
	 echo "→ Build number: $${CURRENT} → $${NEW}"
	@echo "→ Building release IPA..."
	flutter build ipa --release \
		--dart-define-from-file=$(ENV_FILE) \
		--dart-define=BUILD_DATE=$$(date +'%d.%m.%Y') \
		--export-options-plist=ios/ExportOptions.plist
	@echo "→ Uploading to TestFlight (bundle: $(BUNDLE_ID))..."
	@xcrun altool --upload-app \
		--type ios \
		--file "$(IPA_PATH)" \
		--apiKey "$(ASC_KEY_ID)" \
		--apiIssuer "$(ASC_ISSUER_ID)" \
		2>&1 | tee /tmp/altool_output.txt; \
	if grep -q "ERROR" /tmp/altool_output.txt; then \
		echo ""; \
		echo "✗ Upload failed — see errors above."; \
		exit 1; \
	fi
	@echo ""
	@echo "✓ Upload complete — builds appear in TestFlight within ~5 min."
