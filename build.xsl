<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text" encoding="UTF-8" omit-xml-declaration="yes"/>
  <xsl:strip-space elements="*"/>

  <!--
    Generates the standalone build.sh script from build.xml.
    XSLT 1.0; works with xsltproc, Saxon, or any conforming processor.
  -->
  <xsl:template match="/">
    <xsl:text><![CDATA[#!/bin/sh
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
]]></xsl:text>
    <xsl:for-each select="/build/artifacts/artifact">
      <xsl:value-of select="@source"/>
      <xsl:text>|</xsl:text>
      <xsl:value-of select="@target"/>
      <xsl:text>&#10;</xsl:text>
    </xsl:for-each>
    <xsl:text><![CDATA[ARTIFACTS

if [ "$MODE" = check ] && [ "$fail" -ne 0 ]; then
	echo "build.sh: one or more targets are missing or stale" >&2
	exit 1
fi

if [ "$MODE" = build ]; then
	echo "build.sh: all targets are up to date"
fi
]]></xsl:text>
  </xsl:template>
</xsl:stylesheet>
