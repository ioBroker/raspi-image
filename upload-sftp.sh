#!/bin/bash
# Uploads the image (and its .sha256) to the iobroker.live SFTP server.
# The SFTP root is the web root of https://iobroker.live, so
#   /images/<file>  =>  https://iobroker.live/images/<file>
#
# Usage: ./upload-sftp.sh out/ioBroker-image-RPi_5_YYYY_MM_DD.zip [remote dir]
# Env:   SFTP_HOST, SFTP_PORT (default 22), SFTP_USERNAME, SFTP_PASSWORD
#        PUBLIC_BASE_URL (default https://iobroker.live)
set -euo pipefail

FILE=${1:?local file missing}
REMOTE_DIR=${2:-/images}
PORT=${SFTP_PORT:-22}
PUBLIC_BASE_URL=${PUBLIC_BASE_URL:-https://iobroker.live}
: "${SFTP_HOST:?SFTP_HOST not set}"
: "${SFTP_USERNAME:?SFTP_USERNAME not set}"
: "${SFTP_PASSWORD:?SFTP_PASSWORD not set}"

NAME=$(basename "$FILE")
FILES=("$FILE")
[ -f "$FILE.sha256" ] && FILES+=("$FILE.sha256")

CMDS="set cmd:fail-exit yes
set sftp:auto-confirm yes
set net:max-retries 3
set net:timeout 60
set net:reconnect-interval-base 10
mkdir -p -f $REMOTE_DIR
cd $REMOTE_DIR
"
for f in "${FILES[@]}"; do
  n=$(basename "$f")
  # upload under a temporary name, then swap: nobody downloads a half written file
  CMDS+="put $f -o $n.part
rm -f $n
mv $n.part $n
"
done
CMDS+="cls -l $NAME
bye"

echo ">>> Uploading ${FILES[*]} to sftp://$SFTP_HOST:$PORT$REMOTE_DIR"
export LFTP_PASSWORD="$SFTP_PASSWORD"
lftp --env-password -p "$PORT" -u "$SFTP_USERNAME" "sftp://$SFTP_HOST" <<<"$CMDS"

URL="$PUBLIC_BASE_URL${REMOTE_DIR%/}/$NAME"
echo ">>> Public URL: $URL"

# Check that the web server delivers the complete file
if [ "${SKIP_URL_CHECK:-0}" != "1" ]; then
  LOCAL_SIZE=$(stat -c %s "$FILE")
  REMOTE_SIZE=$(curl -fsSIL "$URL" | tr -d '\r' | awk 'tolower($1)=="content-length:" {v=$2} END {print v}')
  if [ "$LOCAL_SIZE" != "$REMOTE_SIZE" ]; then
    echo "Size mismatch: local $LOCAL_SIZE, $URL delivers '$REMOTE_SIZE'"
    exit 1
  fi
  echo ">>> Verified: $URL ($REMOTE_SIZE bytes)"
fi

[ -n "${GITHUB_OUTPUT:-}" ] && echo "url=$URL" >> "$GITHUB_OUTPUT"
exit 0
