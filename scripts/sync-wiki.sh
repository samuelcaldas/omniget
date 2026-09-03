#!/usr/bin/env bash
# ==============================================================================
# OmniGet - GitHub Wiki Synchronization Utility
# Synchronizes the contents of wiki/ to the GitHub Wiki Git Repository.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WIKI_DIR="${REPO_ROOT}/wiki"
WIKI_REMOTE="git@github.com:samuelcaldas/omniget.wiki.git"
TEMP_DIR="$(mktemp -d /tmp/omniget-wiki-sync.XXXXXX)"

cleanup() {
    rm -rf "${TEMP_DIR}"
}
trap cleanup EXIT

echo "=============================================================================="
echo "  OmniGet GitHub Wiki Synchronizer"
echo "=============================================================================="

if [ ! -d "${WIKI_DIR}" ]; then
    echo "[ERROR] Wiki directory ${WIKI_DIR} not found!"
    exit 1
fi

echo "[INFO] Cloning or initializing wiki repository: ${WIKI_REMOTE}..."
if git clone "${WIKI_REMOTE}" "${TEMP_DIR}" 2>/dev/null; then
    echo "[INFO] Cloned existing wiki repository."
else
    echo "[INFO] Wiki repository not yet initialized. Initializing new repository..."
    (cd "${TEMP_DIR}" && git init -b master && git remote add origin "${WIKI_REMOTE}")
fi

echo "[INFO] Synchronizing markdown files from ${WIKI_DIR}..."
cp -r "${WIKI_DIR}"/* "${TEMP_DIR}/"

(
    cd "${TEMP_DIR}"
    git add -A
    if git diff --staged --quiet; then
        echo "[SUCCESS] GitHub Wiki is already up to date. No changes to commit."
    else
        git commit -m "docs(wiki): synchronize omniget documentation and guides"
        echo "[INFO] Pushing wiki documentation to GitHub..."
        git push origin master || git push origin main
        echo "[SUCCESS] Successfully synchronized OmniGet Wiki!"
    fi
)
