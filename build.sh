#!/bin/sh
# Build the static SVG/XML proxy tree and the .svg.gz mirrors.
#
# Every .svgz route gets matching .xml, .svg, .xhtml, and .xsl files generated
# with xml-build.xsl. The generated files are uncompressed SVG documents, so
# hosts serve them as renderable document types:
#
#   .xml   application/xml        jsDelivr, statically.io
#   .svg   image/svg+xml          jsDelivr, statically.io
#   .xhtml application/xhtml+xml  jsDelivr
#   .xsl   application/xml        jsDelivr (alternate extension, not a stylesheet)
#
# Internal navigation links are rewritten to the matching extension, so each
# variant stays inside its own route tree. Set FORMATS to limit the formats,
# for example: FORMATS="svg xml" ./build.sh
#
# Usage: ./build.sh [--build|--check|--list|--help]
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$ROOT"

FORMATS=${FORMATS:-xml svg xhtml xsl}

WORK=
cleanup() {
	if [ -n "$WORK" ]; then
		rm -rf -- "$WORK"
	fi
}
trap cleanup 0 1 2 3 15

new_workdir() {
	WORK=$(mktemp -d "${TMPDIR:-/tmp}/nebula-build.XXXXXX")
}

drop_workdir() {
	rm -rf -- "$WORK"
	WORK=
}

usage() {
	cat <<'EOF'
Usage: ./build.sh [--build|--check|--list]

Build the static SVG/XML proxy tree and the .svg.gz mirrors.

Options:
  --build   Generate every configured route format and rebuild all .svg.gz
            mirrors (default)
  --check   Verify every configured route and mirror is current
  --list    Print the generated paths
  -h, --help
            Show this help

Formats: xml svg xhtml xsl
Override with FORMATS, for example: FORMATS="svg xml" ./build.sh
EOF
}

build_routes() {
	new_workdir
	find . -type f -name '*.svgz' | sort > "$WORK/sources.txt"
	while IFS= read -r src; do
		gzip -dc -- "$src" > "$WORK/source.svg"
		for fmt in $FORMATS; do
			dest=${src%.svgz}.$fmt
			xsltproc --nonet --stringparam target "$fmt" xml-build.xsl "$WORK/source.svg" > "$WORK/output.$fmt"
			if [ -f "$dest" ] && cmp -s -- "$WORK/output.$fmt" "$dest"; then
				echo "up to date $dest"
			else
				mv -- "$WORK/output.$fmt" "$dest"
				echo "built $dest"
			fi
		done
	done < "$WORK/sources.txt"
	drop_workdir
}

check_routes() {
	new_workdir
	find . -type f -name '*.svgz' | sort > "$WORK/sources.txt"
	route_fail=0
	while IFS= read -r src; do
		gzip -dc -- "$src" > "$WORK/source.svg"
		for fmt in $FORMATS; do
			dest=${src%.svgz}.$fmt
			if [ ! -f "$dest" ]; then
				echo "missing $dest" >&2
				route_fail=1
				continue
			fi
			xsltproc --nonet --stringparam target "$fmt" xml-build.xsl "$WORK/source.svg" > "$WORK/output.$fmt"
			if ! cmp -s -- "$WORK/output.$fmt" "$dest"; then
				echo "stale $dest" >&2
				route_fail=1
				continue
			fi
			echo "ok $dest"
		done
	done < "$WORK/sources.txt"
	drop_workdir
	[ "$route_fail" -eq 0 ]
}

build_mirrors() {
	find . -type f -name '*.svgz' | sort | while IFS= read -r src; do
		dest=${src%.svgz}.svg.gz
		if [ -f "$dest" ] && cmp -s -- "$src" "$dest" && gzip -t -- "$dest" 2>/dev/null; then
			echo "up to date $dest"
			continue
		fi
		cp -- "$src" "$dest"
		gzip -t -- "$dest"
		echo "built $dest"
	done
}

check_mirrors() {
	new_workdir
	find . -type f -name '*.svgz' | sort > "$WORK/mirrors.txt"
	mirror_fail=0
	while IFS= read -r src; do
		dest=${src%.svgz}.svg.gz
		if [ ! -f "$dest" ]; then
			echo "missing $dest" >&2
			mirror_fail=1
			continue
		fi
		if ! cmp -s -- "$src" "$dest"; then
			echo "stale $dest" >&2
			mirror_fail=1
			continue
		fi
		if ! gzip -t -- "$dest" 2>/dev/null; then
			echo "invalid gzip $dest" >&2
			mirror_fail=1
			continue
		fi
		echo "ok $dest"
	done < "$WORK/mirrors.txt"
	drop_workdir
	[ "$mirror_fail" -eq 0 ]
}

list_outputs() {
	{
		for fmt in $FORMATS; do
			find . -type f -name '*.svgz' -printf '%P\n' | sort | sed "s/\.svgz$/.$fmt/"
		done
		find . -type f -name '*.svgz' -printf '%P\n' | sort | sed 's/\.svgz$/.svg.gz/'
	} | sort
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

case $MODE in
	list)
		list_outputs
		;;
	check)
		fail=0
		check_routes || fail=1
		check_mirrors || fail=1
		if [ "$fail" -ne 0 ]; then
			echo "build.sh: build is stale" >&2
			exit 1
		fi
		;;
	build)
		build_routes
		build_mirrors
		echo "build.sh: build complete"
		;;
esac
