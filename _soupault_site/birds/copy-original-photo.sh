#!/usr/bin/env zsh
# usage: path/to/copy-original-photo.sh IMG_1234.jpg path/to/output/dir
set -euo pipefail -o bsdecho
filename=${1##*/}
output_dir=$2
output_path=$output_dir/$filename
json_path=$output_path.json

if [ -e "$output_path" ] && [ -e "$json_path" ]; then
  >&2 echo "$output_path"
  exit
fi

for raw_dir in \
  /mnt/ocean/private/delan/photos/pixel8/rawtherapee-2024-05-25 \
  /mnt/ocean/private/delan/photos/pixel8/darktable_exported \
  /mnt/ocean/private/delan/photos/1000d/darktable_exported \
; do
  input_path=$raw_dir/$filename
  if [ "$input_path" -ef "$output_path" ]; then
    >&2 echo "fatal: attempting to modify original"
    exit 1
  fi
  > /dev/null cat "$input_path" || continue
  # Copy first, to avoid exiftool file I/O errors on sshfs
  cp -- "$input_path" "$output_path" || continue
  exiftool -overwrite_original -geotag= "$output_path" || continue
  exiftool -j "$output_path" > "$output_path.json" || continue
  >&2 echo "$output_path"
  break
done
