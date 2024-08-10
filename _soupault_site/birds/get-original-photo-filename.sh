#!/usr/bin/env zsh
# usage: path/to/get-original-photo-filename.sh <cohost attachment id> path/to/output/dir
set -euo pipefail -o bsdecho
id=$1
output_dir=$2
cd -- "$output_dir"

if ! [ -e "$id" ]; then
    curl -IO "https://cohost.org/rc/attachment-redirect/$id"
fi

location_header_value=$(rg --pcre2 -o '(?<=^location: ).*' "$id")
printf \%s\\n "${location_header_value##*/}"
