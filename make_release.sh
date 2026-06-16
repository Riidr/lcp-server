#!/usr/bin/env bash
set -e
set -o pipefail

# Verify the production LCP patch has been applied before building.
# Run lcp-patcher-v2/install.sh first if any of these are missing.
for f in pkg/lic/user_key_prod.go pkg/lic/userkey.h pkg/lic/libuserkey.a; do
  if [ ! -f "$f" ]; then
    echo "ERROR: production patch file '$f' not found."
    echo "Run: ../lcp-patcher-v2/install.sh . linux-x64"
    exit 1
  fi
done
echo "Production patch files present — proceeding with PLCP build."

version_filename=VERSION

old_version=$(< $version_filename)
new_version=$(($old_version + 1))
new_tag=eu.gcr.io/pubfront/lcp-server:$new_version

docker build --platform linux/amd64 -t $new_tag .
docker push $new_tag

echo $new_version > $version_filename
echo "Built and pushed $new_tag"
