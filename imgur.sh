#!/usr/bin/env sh
#
# Simple script used for downloading http://imgur.com albums
#   jaagr <c@rlberg.se>

msg() {
  echo "\033[1;32m ** \033[0m$*"
}

main() {
  url="$1"
  target_dir="${2:-images/}"

  test -z "$url" && {
    echo "Usage: $0 URL [target_dir]"; exit
  }

  tmp=$(mktemp -u)

  msg "Fetching album URL $url"
  gridurl=$(curl -s "$url" | sed -nr 's/.*href="(.*\/layout\/grid)".*/http:\1/p')

  msg "Scanning image URLs"
  curl -s "$gridurl" | egrep -o '"hash":"[^"]+"' | sed -nr 's/"hash":"([^"]+)"/http:\/\/i.imgur.com\/\1.jpg/p' > "$tmp"

  sort -u -o "$tmp" "$tmp"
  count=$(wc -l < "$tmp")
  step=$(( count / 20 ))

  ! [ -d "$target_dir" ] && mkdir -p "$target_dir"

  msg "Downloading $count images to \"$target_dir\""

  for i in $(seq 1 20); do
    addrA=$(( ( i - 1 ) * step ))
    addrB=$(( step - 1 ))

    [ "$i" -eq 20 ] && addrB=$(( addrB + $(( count % 20 ))))
    [ "$addrA" -eq 0 ] && addrA=1

    sed -n "${addrA},+${addrB}p" "$tmp" | while read -r line; do
      msg "Downloading => $line"
      wget -q --directory-prefix="$target_dir" "$line"
    done &
  done

  wait

  msg "Done!"

  rm "$tmp"
}

main "$@"
