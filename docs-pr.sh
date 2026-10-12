#!/bin/bash
# Opens a pull request in ioBroker.docs that points the Raspberry Pi download
# (engine-2/front-end/src/config/installation.json) to the new image.
# Older open PRs of this kind are closed as superseded.
#
# Env: GH_TOKEN     token with write access to ioBroker.docs (contents + pull requests)
#      IMAGE_URL    new public URL, e.g. https://iobroker.live/images/ioBroker-image-RPi_5_2026_10_12.zip
#      IMAGE_NAME   e.g. ioBroker-image-RPi_5_2026_10_12
#      BASE_IMAGE, NODE_VERSION, CONTROLLER_VERSION, SHA256, RUN_URL (optional, for the PR text)
#      DOCS_REPO    default ioBroker/ioBroker.docs
#      DRY_RUN=1    only show the change, no push and no PR
set -euo pipefail

DOCS_REPO=${DOCS_REPO:-ioBroker/ioBroker.docs}
FILE=engine-2/front-end/src/config/installation.json
: "${IMAGE_URL:?IMAGE_URL not set}"
: "${IMAGE_NAME:?IMAGE_NAME not set}"
DRY_RUN=${DRY_RUN:-0}
[ "$DRY_RUN" = 1 ] || : "${GH_TOKEN:?GH_TOKEN not set}"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

if [ -n "${GH_TOKEN:-}" ]; then
  CLONE_URL="https://x-access-token:${GH_TOKEN}@github.com/${DOCS_REPO}.git"
else
  CLONE_URL="https://github.com/${DOCS_REPO}.git"
fi

# Only the one directory is needed, the docs repository itself is large
git clone --quiet --depth 1 --filter=blob:none --sparse "$CLONE_URL" "$WORK/docs"
cd "$WORK/docs"
git sparse-checkout set "$(dirname "$FILE")"
BASE_BRANCH=$(git rev-parse --abbrev-ref HEAD)

OLD_URL=$(grep -oE 'https://iobroker\.live/images/ioBroker-image-RPi_5_[0-9_]+\.zip' "$FILE" | head -1 || true)
if [ -z "$OLD_URL" ]; then
  echo "No Raspberry Pi image link found in $FILE, nothing to do"
  exit 1
fi
if [ "$OLD_URL" = "$IMAGE_URL" ]; then
  echo "Docs already point to $IMAGE_URL"
  exit 0
fi

sed -i "s#${OLD_URL//./\\.}#${IMAGE_URL}#" "$FILE"
git --no-pager diff

if [ "$DRY_RUN" = 1 ]; then
  echo "DRY_RUN: no push, no pull request"
  exit 0
fi

BRANCH="raspi-image/$IMAGE_NAME"
git checkout --quiet -b "$BRANCH"
git -c user.name="github-actions[bot]" -c user.email="41898282+github-actions[bot]@users.noreply.github.com" \
  commit --quiet -am "Raspberry Pi image: $IMAGE_NAME"
git push --quiet --force origin "$BRANCH"

BODY=$(cat <<EOF
New ioBroker image for Raspberry Pi 5, built automatically by [ioBroker/raspi-image](https://github.com/ioBroker/raspi-image).

**Please test the image on a real Raspberry Pi 5 before merging.**

| | |
|---|---|
| Download | $IMAGE_URL |
| Previous | $OLD_URL |
| Base | \`${BASE_IMAGE:-?}\` |
| Node.js | \`${NODE_VERSION:-?}\` |
| js-controller | \`${CONTROLLER_VERSION:-?}\` |
| SHA256 | \`${SHA256:-?}\` |
| Build | ${RUN_URL:-?} |

Test checklist:
- [ ] Image boots on Raspberry Pi 5
- [ ] SSH login as \`iob\` works
- [ ] Admin reachable on http://iobroker.local:8081
- [ ] Welcome and wireless-settings adapters present
EOF
)

if gh pr view "$BRANCH" --repo "$DOCS_REPO" --json state -q .state 2>/dev/null | grep -q OPEN; then
  echo "PR for $BRANCH already open, branch updated"
  NEW_PR=$(gh pr view "$BRANCH" --repo "$DOCS_REPO" --json number -q .number)
else
  PR_URL=$(gh pr create --repo "$DOCS_REPO" --base "$BASE_BRANCH" --head "$BRANCH" \
    --title "Update Raspberry Pi image to $IMAGE_NAME" --body "$BODY")
  echo "Created $PR_URL"
  NEW_PR=${PR_URL##*/}
fi

# Close older image PRs, the new one replaces them
gh pr list --repo "$DOCS_REPO" --state open --json number,headRefName \
  -q '.[] | select(.headRefName | startswith("raspi-image/")) | .number' |
while read -r n; do
  [ "$n" = "$NEW_PR" ] && continue
  gh pr close "$n" --repo "$DOCS_REPO" --delete-branch \
    --comment "Superseded by #$NEW_PR" || true
done

[ -n "${GITHUB_STEP_SUMMARY:-}" ] && echo "Docs PR: https://github.com/$DOCS_REPO/pull/$NEW_PR" >> "$GITHUB_STEP_SUMMARY"
exit 0
