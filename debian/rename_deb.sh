#!/bin/bash
set -e

cd debian/packages

for f in open-note_*.deb; do
  if [ -f "$f" ]; then
    version=$(echo "$f" | sed -n 's/open-note_\([0-9.]*\.[0-9]*\)_amd64/OpenNote-v\1-linux_x86_64/')
    if [ -n "$version" ]; then
      new_name="OpenNote-${version}.deb"
      echo "Renaming: $f -> $new_name"
      mv "$f" "$new_name"
    else
      echo "Skipping: $f (no version match)"
    fi
  fi
done

echo "Deb files renamed successfully"
