IOS_SIM_ID := 372BBDEF-052C-4B4B-A646-2EFB4EEB080D  # iPhone 16 Plus (iOS 18.6)
ENV_FILE   := .env.json

# App Store Connect API credentials — set these after creating the key in
# App Store Connect → Users and Access → Integrations → App Store Connect API.
# The matching AuthKey_<ASC_KEY_ID>.p8 file must live at:
#   ~/.appstoreconnect/private_keys/AuthKey_$(ASC_KEY_ID).p8
ASC_KEY_ID    ?= YX8L3MY7S7
ASC_ISSUER_ID ?= b8e1987b-405d-4f2f-ac95-1cf246d6f457

BUNDLE_ID     := com.tapem.tapem
IPA_PATH      := build/ios/ipa/tapem.ipa
APK_PATH      := build/app/outputs/flutter-apk/app-release.apk

.PHONY: ios-emu apk testflight

ios-emu:
	@echo "→ Killing any running Flutter instances..."
	@pkill -f "flutter run" 2>/dev/null || true
	@sleep 1
	@echo "→ Booting simulator $(IOS_SIM_ID)..."
	@xcrun simctl boot $(IOS_SIM_ID) 2>/dev/null || true
	@open -a Simulator
	@echo "→ Building and launching on iOS simulator..."
	flutter run -d $(IOS_SIM_ID) --dart-define-from-file=$(ENV_FILE)

## ── Android ──────────────────────────────────────────────────────────────────
## Build a release APK ready for Firebase App Distribution.
## Output: $(APK_PATH)
apk:
	@echo "→ Building release APK..."
	flutter build apk --release --dart-define-from-file=$(ENV_FILE)
	@echo ""
	@echo "✓ APK built: $(APK_PATH)"
	@echo "  Upload this file to Firebase App Distribution."

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
