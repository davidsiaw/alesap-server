#!/bin/sh
# Rotates the production master key and re-encrypts the production credentials with a
# fresh secret_key_base (the only entry). Run from the app, e.g. inside `heighliner login`:
#
#   sh bin/rotate-prod-key.sh
#
# Afterwards: put the printed key into the ALESAP_MASTER_KEY GitHub secret (and Portainer's
# stack variable), commit config/credentials/production.yml.enc, deploy. The old key is kept as
# config/credentials/production-before-rotation.key (ignored by git and docker) until you
# delete it; the old .yml.enc is in git.
set -eu

cd "$(dirname "$0")/.."
dir=config/credentials
key=$dir/production.key
enc=$dir/production.yml.enc
backup=$dir/production-before-rotation.key

if [ -e "$backup" ]; then
  echo "$backup already exists: a rotation was already done. Delete it first to rotate again." >&2
  exit 1
fi

if [ -e "$key" ]; then
  mv "$key" "$backup"
  echo "old key moved to $backup"
fi
rm -f "$enc"

secret=$(bin/rails secret)
editor=$(mktemp)
trap 'rm -f "$editor"' EXIT
printf '#!/bin/sh\nprintf "secret_key_base: %%s\\n" "%s" > "$1"\n' "$secret" > "$editor"
chmod +x "$editor"

EDITOR="$editor" bin/rails credentials:edit --environment production > /dev/null

# Check it decrypts, without printing the secret.
if ! bin/rails credentials:show --environment production | grep -q '^secret_key_base: .\{64,\}$'; then
  echo "new credentials don't decrypt as expected; old key is in $backup" >&2
  exit 1
fi

cat <<EOF

Rotated. New production master key:

  $(cat "$key")

Next:
  1. Set it as the ALESAP_MASTER_KEY GitHub secret (and in Portainer if you deploy from there).
  2. Commit $enc (the key itself stays out of git and images).
  3. Deploy. Existing admin sessions are logged out.
  4. Once it works: delete $backup, and the leaked image tag/digest on Docker Hub.
EOF
