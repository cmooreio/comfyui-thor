#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKERFILE="${SCRIPT_DIR}/Dockerfile"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

COMFYUI_REF="$(awk -F= '/^ARG COMFYUI_REF=/{print $2}' "${DOCKERFILE}")"
COMFYUI_MANAGER_REF="$(awk -F= '/^ARG COMFYUI_MANAGER_REF=/{print $2}' "${DOCKERFILE}")"
BASE_TORCH_CONSTRAINTS="${SCRIPT_DIR}/torch-base-constraints.txt"
NO_EMIT_ARGS=(
  --no-emit-package torch
  --no-emit-package torchvision
  --no-emit-package torchaudio
)

if [[ -z "${COMFYUI_REF}" || -z "${COMFYUI_MANAGER_REF}" ]]; then
  echo "Failed to extract COMFYUI_REF or COMFYUI_MANAGER_REF from Dockerfile" >&2
  exit 1
fi

curl -fsSL \
  "https://raw.githubusercontent.com/Comfy-Org/ComfyUI/${COMFYUI_REF}/requirements.txt" \
  | grep -vE '^torch(vision|audio)?([<>=!~].*)?$' \
  > "${TMP_DIR}/comfyui.in"

curl -fsSL \
  "https://raw.githubusercontent.com/Comfy-Org/ComfyUI-Manager/${COMFYUI_MANAGER_REF}/requirements.txt" \
  > "${TMP_DIR}/manager.in"

cat "${TMP_DIR}/comfyui.in" "${TMP_DIR}/manager.in" > "${TMP_DIR}/runtime.in"

uv pip compile \
  --generate-hashes \
  --python-version 3.12 \
  --python-platform aarch64-unknown-linux-gnu \
  --custom-compile-command "./generate-lockfiles.sh" \
  "${NO_EMIT_ARGS[@]}" \
  -c "${BASE_TORCH_CONSTRAINTS}" \
  "${TMP_DIR}/runtime.in" \
  -o "${SCRIPT_DIR}/requirements-runtime.lock.txt"

uv pip compile \
  --generate-hashes \
  --python-version 3.12 \
  --python-platform aarch64-unknown-linux-gnu \
  --custom-compile-command "./generate-lockfiles.sh" \
  "${NO_EMIT_ARGS[@]}" \
  -c "${SCRIPT_DIR}/requirements-runtime.lock.txt" \
  -c "${BASE_TORCH_CONSTRAINTS}" \
  "${SCRIPT_DIR}/extra-requirements.txt" \
  -o "${SCRIPT_DIR}/requirements-extra.lock.txt"
