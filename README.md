# artcraft-launcher-bin

AUR packaging of the prebuilt [ArtCraft Launcher](https://github.com/storytold/craft-launcher)
release tarballs for `x86_64` and `aarch64`, published as
[`artcraft-launcher-bin`](https://aur.archlinux.org/packages/artcraft-launcher-bin).

## How it is maintained

- `update` runs daily: when upstream publishes a newer stable release it sets `pkgver`, resets
  `pkgrel`, takes the checksums from the release's `SHA256SUMS.txt`, builds the package and opens
  a PR whose description compares `depends`/`optdepends` with upstream's own Arch package. When
  both match it merges the PR and publishes to the AUR in the same run; otherwise the PR waits
  for a manual merge.
- `ci` builds every push and PR in an Arch container with `makepkg` and `namcap` and checks that
  `.SRCINFO` matches the PKGBUILD; on `main` it then publishes PKGBUILD and `.SRCINFO` to the AUR
  through `publish` and the `aur` environment.
- `automerge` merges Dependabot PRs once `ci` has passed on them.

## Local use

```sh
ci/check.sh                   # build, namcap, verify .SRCINFO (needs podman)
ci/check.sh --write-srcinfo   # regenerate .SRCINFO after editing PKGBUILD
ci/update.sh 0.11.0 notes.md  # move to another upstream release (needs gh)
```

The packaging files are released under the 0BSD license; ArtCraft Launcher itself is
`MIT OR Apache-2.0`.
