#!/bin/sh
# SPDX-License-Identifier: 0BSD
# Moves PKGBUILD and .SRCINFO to upstream release VERSION, with checksums from its SHA256SUMS.txt,
# and writes to NOTES a comparison of our dependencies with those of upstream's own Arch package.
# Prints `match` when both dependency lists equal upstream's, `differ` otherwise.
# Usage: ci/update.sh VERSION NOTES   (needs gh; build output goes to stderr)
set -eu

[ $# -eq 2 ] || { echo "usage: $0 VERSION NOTES" >&2; exit 2; }
version=$1
notes=$2
upstream=storytold/craft-launcher
root=$(cd "$(dirname "$0")/.." && pwd)
dl=$(mktemp -d)
trap 'rm -rf "$dl"' EXIT

gh release download "v$version" -R "$upstream" -D "$dl" \
    -p SHA256SUMS.txt -p "artcraft-launcher-$version-linux-x86_64.pkg.tar.zst"
(cd "$dl" && sha256sum -c --ignore-missing --quiet SHA256SUMS.txt)

sum() { awk -v f="artcraft-launcher-$version-linux-$1.tar.gz" '$2 == f { print $1 }' "$dl/SHA256SUMS.txt"; }
sha_x86_64=$(sum x86_64)
sha_aarch64=$(sum aarch64)
[ -n "$sha_x86_64" ] && [ -n "$sha_aarch64" ] || { echo "release v$version lacks a Linux tarball" >&2; exit 1; }

sed -i \
    -e "s/^pkgver=.*/pkgver=$version/" \
    -e "s/^pkgrel=.*/pkgrel=1/" \
    -e "s/^sha256sums_x86_64=.*/sha256sums_x86_64=('$sha_x86_64')/" \
    -e "s/^sha256sums_aarch64=.*/sha256sums_aarch64=('$sha_aarch64')/" \
    "$root/PKGBUILD"
"$root/ci/check.sh" --write-srcinfo >&2

tar --zstd -xOf "$dl/artcraft-launcher-$version-linux-x86_64.pkg.tar.zst" .PKGINFO >"$dl/PKGINFO"
deps() { sed -n "s/^[[:space:]]*$2 = //p" "$1" | sort; }
deps "$dl/PKGINFO" depend >"$dl/upstream-depends"
deps "$root/.SRCINFO" depends >"$dl/our-depends"
deps "$dl/PKGINFO" optdepend >"$dl/upstream-optdepends"
deps "$root/.SRCINFO" optdepends >"$dl/our-optdepends"
result=match
{
    echo "Upstream release: https://github.com/$upstream/releases/tag/v$version"
    echo
    for kind in depends optdepends; do
        if diff -q "$dl/our-$kind" "$dl/upstream-$kind" >/dev/null; then
            echo "- \`$kind\` match upstream's Arch package."
        else
            result=differ
            echo "- \`$kind\` differ from upstream's Arch package (\`-\` ours, \`+\` upstream):"
            echo
            echo '```diff'
            diff -u "$dl/our-$kind" "$dl/upstream-$kind" | tail -n +4 || true
            echo '```'
        fi
    done
} >"$notes"
echo "$result"
