#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ANDROID_DIR="${ROOT_DIR}/android"
KEYSTORE_DIR="${ANDROID_DIR}/keystore"
KEYSTORE_PATH="${KEYSTORE_DIR}/tapem-upload-keystore.p12"
SECRETS_PATH="${ANDROID_DIR}/.signing_credentials.txt"
KEY_ALIAS="${KEY_ALIAS:-tapem_upload}"
KEY_DNAME="${KEY_DNAME:-CN=Tapem Upload, OU=Engineering, O=Tapem, L=Berlin, ST=Berlin, C=DE}"
PRINT_SECRETS="${PRINT_SECRETS:-false}"

if ! command -v keytool >/dev/null 2>&1; then
  echo "ERROR: keytool not found. Install a JDK first."
  exit 1
fi

mkdir -p "${KEYSTORE_DIR}"

if [[ -f "${KEYSTORE_PATH}" ]]; then
  echo "ERROR: Keystore already exists at ${KEYSTORE_PATH}"
  echo "Refusing to overwrite. Remove it manually if you want to recreate it."
  exit 1
fi

if command -v openssl >/dev/null 2>&1; then
  STORE_PASSWORD="$(openssl rand -base64 48 | tr -d '=+/' | cut -c1-32)"
else
  # Fallback if openssl is unavailable.
  STORE_PASSWORD="ChangeMeStorePassword_$(date +%s)"
fi
KEY_PASSWORD="${STORE_PASSWORD}"

keytool -genkeypair \
  -v \
  -storetype PKCS12 \
  -keyalg RSA \
  -keysize 4096 \
  -validity 10000 \
  -alias "${KEY_ALIAS}" \
  -keystore "${KEYSTORE_PATH}" \
  -storepass "${STORE_PASSWORD}" \
  -keypass "${KEY_PASSWORD}" \
  -dname "${KEY_DNAME}"

cat > "${ANDROID_DIR}/key.properties" <<EOF
storeFile=keystore/tapem-upload-keystore.p12
storePassword=${STORE_PASSWORD}
keyAlias=${KEY_ALIAS}
keyPassword=${KEY_PASSWORD}
EOF

chmod 600 "${ANDROID_DIR}/key.properties"
cat > "${SECRETS_PATH}" <<EOF
storePassword=${STORE_PASSWORD}
keyAlias=${KEY_ALIAS}
keyPassword=${KEY_PASSWORD}
EOF
chmod 600 "${SECRETS_PATH}"

echo ""
echo "Created upload keystore:"
echo "  ${KEYSTORE_PATH}"
echo "Created local signing config:"
echo "  ${ANDROID_DIR}/key.properties"
echo "Stored signing credentials:"
echo "  ${SECRETS_PATH}"
echo ""
echo "IMPORTANT: Move credentials from ${SECRETS_PATH} to your password manager."
echo "Note: PKCS12 uses the same password for store and key."
if [[ "${PRINT_SECRETS}" == "true" ]]; then
  echo "storePassword=${STORE_PASSWORD}"
  echo "keyAlias=${KEY_ALIAS}"
  echo "keyPassword=${KEY_PASSWORD}"
fi
