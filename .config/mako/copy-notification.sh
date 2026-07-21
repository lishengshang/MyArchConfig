#!/bin/sh
exec >> /tmp/mako-copy.log 2>&1
set -x

nid="${1:-$id}"

# 如果 mako 没传 id，就取当前最新一条可见通知
if [ -z "$nid" ]; then
    nid=$(makoctl list -j | jq -r '.[0].id // empty')
fi

[ -z "$nid" ] && { echo "no id and no visible notifications"; exit 1; }

makoctl list -j | jq -r --arg id "$nid" '
  .[] | select(.id == ($id | tonumber)) | .body
' | wl-copy
