#!/usr/bin/env bash
# Create the repo on GitHub and push (requires: gh auth login, or GITHUB_TOKEN / GH_TOKEN)
set -euo pipefail
cd "$(dirname "$0")"

REPO_NAME="${1:-treasure-hunt-rhty2026}"

if ! command -v gh >/dev/null 2>&1; then
  echo "Install GitHub CLI: https://cli.github.com/ (or add ~/.local/bin to PATH)" >&2
  exit 1
fi

if ! gh auth status &>/dev/null; then
  if [[ -n "${GITHUB_TOKEN:-}" || -n "${GH_TOKEN:-}" ]]; then
    echo "${GITHUB_TOKEN:-$GH_TOKEN}" | gh auth login --with-token
  else
    echo "Not logged in to GitHub. Run once:" >&2
    echo "  gh auth login" >&2
    echo "Or set GITHUB_TOKEN (repo scope) and run this script again." >&2
    exit 1
  fi
fi

if git remote get-url origin &>/dev/null; then
  echo "Remote 'origin' already exists. Pushing..." >&2
  git push -u origin main
  exit 0
fi

gh repo create "$REPO_NAME" --public --source=. --remote=origin --push
