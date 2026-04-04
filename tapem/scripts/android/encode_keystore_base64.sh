#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
KEY_PROPERTIES="${ROOT_DIR}/android/key.properties"

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
if [[ -z "${STORE_FILE}" ]]; then
  echo "ERROR: key.properties missing storeFile."
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

if [[ "$(uname -s)" == "Darwin" ]]; then
  base64 -i "${KEYSTORE_PATH}" | tr -d '\n'
else
  base64 -w 0 "${KEYSTORE_PATH}"
fi

echo ""
