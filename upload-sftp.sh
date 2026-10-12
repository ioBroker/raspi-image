#!/bin/bash
# Uploads the image (and its .sha256) to the iobroker.live SFTP server, so it is
# reachable as https://iobroker.live/images/<file>.
#
# Works with both kinds of SFTP accounts:
#  - main account, SFTP root = web root      => file goes to /images
#  - account restricted to the images folder => its SFTP root "/" IS /images
# Without SFTP_REMOTE_DIR the script uses /images if it exists, otherwise "/".
# The final URL check catches a wrong folder in either case.
#
# Usage: ./upload-sftp.sh out/ioBroker-image-RPi_5_YYYY_MM_DD.zip
# Env:   SFTP_HOST, SFTP_PORT (default 22), SFTP_USERNAME, SFTP_PASSWORD
#        SFTP_REMOTE_DIR (optional, forces the remote folder)
#        PUBLIC_DIR_URL (default https://iobroker.live/images)
set -euo pipefail

FILE=${1:?local file missing}
REMOTE_DIR=${SFTP_REMOTE_DIR:-}
PORT=${SFTP_PORT:-22}
PUBLIC_DIR_URL=${PUBLIC_DIR_URL:-https://iobroker.live/images}
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
"
if [ -n "$REMOTE_DIR" ]; then
  CMDS+="cd $REMOTE_DIR
"
else
  CMDS+="cd /images || cd /
"
fi
CMDS+="pwd
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

echo ">>> Uploading ${FILES[*]} to sftp://$SFTP_HOST:$PORT ${REMOTE_DIR:-(auto: /images or /)}"
export LFTP_PASSWORD="$SFTP_PASSWORD"
lftp --env-password -p "$PORT" -u "$SFTP_USERNAME" "sftp://$SFTP_HOST" <<<"$CMDS"

URL="${PUBLIC_DIR_URL%/}/$NAME"
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
