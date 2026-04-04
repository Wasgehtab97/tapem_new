#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
KEY_PROPERTIES="${ROOT_DIR}/android/key.properties"
OUT_PATH="${ROOT_DIR}/android/keystore/upload_certificate.pem"

if ! command -v keytool >/dev/null 2>&1; then
  echo "ERROR: keytool not found. Install a JDK first."
  exit 1
fi

if [[ ! -f "${KEY_PROPERTIES}" ]]; then
  echo "ERROR: ${KEY_PROPERTIES} not found."
  echo "Run scripts/android/create_upload_keystore.sh first or create key.properties manually."
  exit 1
fi

get_prop() {
  local key="$1"
  grep -E "^${key}=" "${KEY_PROPERTIES}" | head -n1 | cut -d'=' -f2-
}

STORE_FILE="$(get_prop storeFile)"
STORE_PASSWORD="$(get_prop storePassword)"
KEY_ALIAS="$(get_prop keyAlias)"

if [[ -z "${STORE_FILE}" || -z "${STORE_PASSWORD}" || -z "${KEY_ALIAS}" ]]; then
  echo "ERROR: key.properties is missing required values."
  exit 1
fi

if [[ "${STORE_FILE}" = /* ]]; then
  KEYSTORE_PATH="${STORE_FILE}"
else
  KEYSTORE_PATH="${ROOT_DIR}/android/${STORE_FILE}"
fi

if [[ ! -f "${KEYSTORE_PATH}" ]]; then
  echo "ERROR: Keystore not found at ${KEYSTORE_PATH}"
  exit 1
fi

mkdir -p "$(dirname "${OUT_PATH}")"

keytool -exportcert -rfc \
  -keystore "${KEYSTORE_PATH}" \
  -storepass "${STORE_PASSWORD}" \
  -alias "${KEY_ALIAS}" \
  -file "${OUT_PATH}"

echo "Exported upload certificate:"
echo "  ${OUT_PATH}"
