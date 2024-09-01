#!/usr/bin/env zsh
# usage: path/to/copy-original-photo.sh IMG_1234.jpg path/to/output/dir
set -euo pipefail -o bsdecho
filename=${1##*/}
output_dir=$2
output_path=$output_dir/_/$filename
small_path=$output_dir/_small/$filename
exif_path=$output_dir/_exif/$filename.json

mkdir -p -- "$output_dir/_" "$output_dir/_small" "$output_dir/_exif"
if [ -e "$output_path" ] && [ -e "$small_path" ] && [ -e "$exif_path" ]; then
  >&2 echo "$output_path"
  exit
fi

for raw_dir in \
  /mnt/ocean/private/delan/photos/pixel8/rawtherapee-2024-05-25 \
  /mnt/ocean/private/delan/photos/pixel8/darktable_exported \
  /mnt/ocean/private/delan/photos/pixel8 \
  /mnt/ocean/private/delan/photos/1000d/darktable_exported \
  /mnt/ocean/private/delan/photos/d3200/darktable_exported \
  /mnt/ocean/private/delan/photos/darktable/*/darktable_exported \
; do
  input_path=$raw_dir/$filename
  if [ "$output_path" -ef "$input_path" ]; then
    >&2 echo "fatal: attempting to modify original: $output_path"
    exit 1
  fi
  if [ "$small_path" -ef "$input_path" ]; then
    >&2 echo "fatal: attempting to modify original: $small_path"
    exit 1
  fi
  if [ "$exif_path" -ef "$input_path" ]; then
    >&2 echo "fatal: attempting to modify original: $exif_path"
    exit 1
  fi
  > /dev/null cat "$input_path" || continue
  # Copy first, to avoid exiftool file I/O errors on sshfs
  cp -- "$input_path" "$output_path" || continue
  # Strip geotag data
  exiftool -overwrite_original -geotag= "$output_path" || continue
  # Scale the stripped version, but use the imagemagick jpeg encoder
  # because the ffmpeg mjpeg encoder has fixed low-quality output
  ffmpeg -i "$output_path" -filter:v thumbnail,scale=w=900:h=900:force_original_aspect_ratio=decrease -frames:v 1 "$small_path.png"
  convert "$small_path.png" "$small_path"
  rm "$small_path.png"
  # Extract metadata from the stripped version
  exiftool -j "$output_path" > "$exif_path" || continue
  >&2 echo "$output_path"
  exit
done
exit 1
