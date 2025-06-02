#!/bin/bash

#
# extract_commits.sh
#
# Given a GitHub repository URL, clones the repo using gh CLI and saves commit
# messages into commits/repository/ as files named by commit hash (no file
# extensions).
#

if ! command -v gh &> /dev/null; then
    echo "gh CLI not found. Please install GitHub CLI first."
    exit 1
fi

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 github.com/owner/repo"
    exit 1
fi

INPUT_URL="$1"
REPO_PATH=$(echo "$INPUT_URL" | sed -E 's|https?://||' | sed 's|github\.com/||')
OWNER_REPO="$REPO_PATH"
REPO_NAME=$(basename "$REPO_PATH")
OUTPUT_DIR="$(pwd)/commits/$REPO_NAME"
mkdir -p "$OUTPUT_DIR"

TMP_DIR=$(mktemp -d)
cd "$TMP_DIR" || exit 1

gh repo clone "$OWNER_REPO" repo_clone
cd repo_clone || exit 1

git log --pretty=format:"%H" | while read -r HASH; do
    COMMIT_MSG=$(git log -n 1 --pretty=format:"%B" "$HASH")
    echo "$COMMIT_MSG" > "$OUTPUT_DIR/$HASH"
done

cd "$OLDPWD" || exit 1
rm -rf "$TMP_DIR"
