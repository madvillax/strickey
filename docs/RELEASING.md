# Release strickey

The repository is `madvillax/strickey`. Release builds include a universal app for Apple Silicon and Intel, supporting macOS 14 or later. The project uses a shell installer and DMG for distribution.

## Build and verify

```sh
./scripts/test.sh
./scripts/release.sh 0.2.1
./scripts/verify-release.sh dist/Strickey-0.2.1-universal.dmg
```

The release script creates:

- `dist/Strickey.app`, with recordings and their license inside the app bundle.
- `dist/Strickey-0.2.1-universal.dmg`, with an Applications shortcut and install instructions.
- `dist/Strickey-0.2.1-universal.dmg.sha256`.
- `dist/release-notes.md`.

The DMG and checksum are ignored build artifacts. Upload those exact files to GitHub Releases. A rebuilt DMG has a different checksum.

The shell installer downloads the latest published release, checks its SHA-256 and DMG structure, and installs to `~/Applications/Strickey.app` by default. Run `scripts/install.sh 0.2.1` to choose a specific version, or pass a writable destination directory as its second argument. It opens the installed app so the user can enable Input Monitoring.

## Developer ID signing and notarization

The default build uses an ad-hoc signature. It is useful locally but is not notarized; Gatekeeper can block downloaded copies. The script does not disable quarantine or bypass Gatekeeper.

For public distribution, obtain a **Developer ID Application** certificate through an Apple Developer account and install it in the keychain. Use full Xcode for `notarytool` and `stapler`. Store a notarization credentials profile interactively:

```sh
xcrun notarytool store-credentials strickey-notary
```

Then build with the identity shown by `security find-identity -v -p codesigning`:

```sh
STRICKEY_SIGNING_IDENTITY='Developer ID Application: YOUR NAME (TEAMID)' \
STRICKEY_NOTARY_PROFILE='strickey-notary' \
./scripts/release.sh 0.2.1
```

The script signs the app with hardened runtime and a timestamp, notarizes and staples the app, creates and signs the DMG, notarizes and staples the DMG, and verifies the result. Failure stops the release. No credentials belong in this repository.

Before shipping, assess the final signed DMG/app with Gatekeeper on a clean Mac and test Input Monitoring and login items there. Intel is cross-compiled and included; live Intel execution requires an Intel Mac or an appropriate test environment.

Apple references: [Developer ID](https://developer.apple.com/developer-id/) and [notarization](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution).

## Publish the first GitHub release

The current app version is `0.2.1`. There are no prior tags or releases, so `v0.2.1` can be the first published version. The release workflow also builds version `0.2.1` by default.

1. Build and verify the release locally with the commands above. For a notarized public build, configure Developer ID and notarization first.
2. Commit any intended source changes and push the branch that will carry the release. The generated DMG remains under ignored `dist/` and does not need to be committed.
3. Create and push the version tag:

   ```sh
   git tag v0.2.1
   git push origin v0.2.1
   ```

4. Create a draft release and attach the DMG and checksum:

   ```sh
   gh release create v0.2.1 \
     dist/Strickey-0.2.1-universal.dmg \
     dist/Strickey-0.2.1-universal.dmg.sha256 \
     --repo madvillax/strickey \
     --title 'strickey 0.2.1' \
     --notes-file dist/release-notes.md \
     --verify-tag \
     --draft
   ```

5. Review the draft on GitHub, then publish it with `gh release edit v0.2.1 --repo madvillax/strickey --draft=false`, or use the Publish release button.

The GitHub Actions **Build release artifacts** workflow can build the DMG, checksum, and notes for a manually selected version. Download its artifact before creating the tag and release. CI builds are ad-hoc signed and not notarized. Neither workflow publishes a release automatically.
