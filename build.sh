#!/bin/sh
# Build the jsDelivr XML proxy entry point and the .svg.gz mirrors.
#
# index.xml is generated from index.svgz with index.xsl. It is an uncompressed
# SVG document, so jsDelivr serves it as application/xml and browsers render
# the SVG root directly. No client-side XSLT is required.
#
# Usage: ./build.sh [--build|--check|--list|--help]
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$ROOT"

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

Build the jsDelivr XML proxy entry point and the .svg.gz mirrors.

Options:
  --build   Generate index.xml from index.svgz and rebuild all .svg.gz mirrors
            (default)
  --check   Verify index.xml is current and every .svg.gz matches its .svgz
  --list    Print the generated paths
  -h, --help
            Show this help
EOF
}

build_index() {
	new_workdir
	gzip -dc -- index.svgz > "$WORK/index.svg"
	xsltproc --nonet index.xsl "$WORK/index.svg" > "$WORK/index.xml"
	if [ -f index.xml ] && cmp -s -- "$WORK/index.xml" index.xml; then
		echo "up to date index.xml"
	else
		mv -- "$WORK/index.xml" index.xml
		echo "built index.xml"
	fi
	drop_workdir
}

check_index() {
	new_workdir
	gzip -dc -- index.svgz > "$WORK/index.svg"
	xsltproc --nonet index.xsl "$WORK/index.svg" > "$WORK/index.xml"
	if [ -f index.xml ] && cmp -s -- "$WORK/index.xml" index.xml; then
		echo "ok index.xml"
		drop_workdir
		return 0
	fi
	echo "stale index.xml" >&2
	drop_workdir
	return 1
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
	echo "index.xml"
	find . -type f -name '*.svgz' -printf '%P\n' | sort | sed 's/\.svgz$/.svg.gz/'
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
		check_index || fail=1
		check_mirrors || fail=1
		if [ "$fail" -ne 0 ]; then
			echo "build.sh: build is stale" >&2
			exit 1
		fi
		;;
	build)
		build_index
		build_mirrors
		echo "build.sh: build complete"
		;;
esac
