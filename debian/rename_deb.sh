#!/bin/bash
set -e

cd debian/packages

for f in OpenNote_*.deb; do
  if [ -f "$f" ]; then
    # 提取版本号：OpenNote_1.1.0_amd64.deb -> 1.1.0
    version=$(echo "$f" | sed -n 's/OpenNote_\([0-9.]*\.[0-9]*\.[0-9]*\)_amd64\.deb/\1/p')
    if [ -n "$version" ]; then
      new_name="OpenNote-v${version}-linux_amd64.deb"
      echo "Renaming: $f -> $new_name"
      mv "$f" "$new_name"
    else
      echo "Skipping: $f (no version match)"
    fi
  fi
done

echo "Deb files renamed successfully"
