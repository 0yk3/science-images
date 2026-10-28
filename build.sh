#!/bin/sh
# Generated from build.xml by build.xsl. Do not edit by hand.
# Usage: ./build.sh [--build|--check|--list|--help]
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$ROOT"

usage() {
	cat <<'EOF'
Usage: ./build.sh [--build|--check|--list]

Rebuild the .svg.gz mirrors from their .svgz sources.

Options:
  --build   Copy each .svgz to .svg.gz (default)
  --check   Verify each .svg.gz exists, is valid gzip, and matches its source
  --list    Print the target paths
  -h, --help
            Show this help
EOF
}

MODE=build
case ${1:-} in
	''|--build) MODE=build ;;
	--check) MODE=check ;;
	--list) MODE=list ;;
	-h|--help) usage; exit 0 ;;
	*)
		echo "build.sh: unknown option: $1" >&2
		echo "Try --help." >&2
		exit 2
		;;
esac

build_one() {
	src=$1
	dest=$2
	if [ ! -f "$src" ]; then
		echo "error: missing source: $src" >&2
		return 1
	fi
	if [ -f "$dest" ] && cmp -s -- "$src" "$dest" && gzip -t -- "$dest" 2>/dev/null; then
		echo "up to date $dest"
		return 0
	fi
	dir=$(dirname -- "$dest")
	[ -d "$dir" ] || mkdir -p -- "$dir"
	tmp="$dest.tmp.$$"
	trap 'rm -f -- "$tmp"' 0 1 2 3 15
	cp -- "$src" "$tmp"
	gzip -t -- "$tmp"
	mv -- "$tmp" "$dest"
	trap - 0 1 2 3 15
	echo "built $dest"
}

check_one() {
	src=$1
	dest=$2
	if [ ! -f "$dest" ]; then
		echo "missing $dest" >&2
		return 1
	fi
	if ! cmp -s -- "$src" "$dest"; then
		echo "stale $dest" >&2
		return 1
	fi
	if ! gzip -t -- "$dest" 2>/dev/null; then
		echo "invalid gzip $dest" >&2
		return 1
	fi
	echo "ok $dest"
}

fail=0
while IFS='|' read -r src dest; do
	[ -n "$src" ] || continue
	case $MODE in
		list) printf '%s\n' "$dest" ;;
		check) check_one "$src" "$dest" || fail=1 ;;
		build) build_one "$src" "$dest" ;;
	esac
done <<'ARTIFACTS'
index.svgz|index.svg.gz
en_US/index.svgz|en_US/index.svg.gz
en_US/catalog/index.svgz|en_US/catalog/index.svg.gz
en_US/catalog/package/index.svgz|en_US/catalog/package/index.svg.gz
en_US/catalog/pagination/index.svgz|en_US/catalog/pagination/index.svg.gz
en_US/games/index.svgz|en_US/games/index.svg.gz
en_US/settings/appearance/index.svgz|en_US/settings/appearance/index.svg.gz
en_US/settings/credits/index.svgz|en_US/settings/credits/index.svg.gz
en_US/settings/misc/index.svgz|en_US/settings/misc/index.svg.gz
en_US/settings/pr/index.svgz|en_US/settings/pr/index.svg.gz
en_US/settings/tab/index.svgz|en_US/settings/tab/index.svg.gz
jp/index.svgz|jp/index.svg.gz
jp/catalog/index.svgz|jp/catalog/index.svg.gz
jp/catalog/package/index.svgz|jp/catalog/package/index.svg.gz
jp/catalog/pagination/index.svgz|jp/catalog/pagination/index.svg.gz
jp/games/index.svgz|jp/games/index.svg.gz
jp/settings/appearance/index.svgz|jp/settings/appearance/index.svg.gz
jp/settings/credits/index.svgz|jp/settings/credits/index.svg.gz
jp/settings/misc/index.svgz|jp/settings/misc/index.svg.gz
jp/settings/pr/index.svgz|jp/settings/pr/index.svg.gz
jp/settings/tab/index.svgz|jp/settings/tab/index.svg.gz
ARTIFACTS

if [ "$MODE" = check ] && [ "$fail" -ne 0 ]; then
	echo "build.sh: one or more targets are missing or stale" >&2
	exit 1
fi

if [ "$MODE" = build ]; then
	echo "build.sh: all targets are up to date"
fi
