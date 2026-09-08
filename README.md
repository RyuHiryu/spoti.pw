<p align="center">
  <img src="docs/icon.png" width="96" alt="">
</p>

<h1 align="center">spoti.pw</h1>

<p align="center">Spotify, in glass.</p>

<p align="center">
  <img src="https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white" alt="iOS">
  <img src="https://img.shields.io/badge/Spotify-1ED760?style=for-the-badge&logo=spotify&logoColor=white" alt="Spotify">
  <img src="https://img.shields.io/badge/Objective--C-3A95E3?style=for-the-badge&logo=apple&logoColor=white" alt="Objective-C">
  <img src="https://img.shields.io/badge/GitHub_Actions-2671E5?style=for-the-badge&logo=githubactions&logoColor=white" alt="GitHub Actions">
  <img src="https://img.shields.io/badge/License-GPL_v3-blue?style=for-the-badge" alt="GPL-3.0">
</p>

<p align="center">
  <a href="https://spoti.pw">spoti.pw</a> ·
  <a href="#get-it">Get it</a> ·
  <a href="#build-it-yourself">Build it yourself</a> ·
  <a href="docs/tweaks.md">Hack on it</a>
</p>

<p align="center">
  <img src="docs/screenshots/now-playing.webp" width="19%" alt="Full screen player">
  <img src="docs/screenshots/queue.webp" width="19%" alt="Queue as a bottom sheet">
  <img src="docs/screenshots/home.webp" width="19%" alt="Home in AMOLED black">
  <img src="docs/screenshots/navbar.webp" width="19%" alt="Navbar editor">
  <img src="docs/screenshots/settings.webp" width="19%" alt="Mod Settings">
</p>

A Theos tweak that rebuilds the Spotify iOS app in Liquid Glass. One dylib, injected into a
decrypted Spotify IPA and signed with your own certificate, so it runs on a stock iPhone with no
jailbreak. Every piece sits behind its own switch in Settings → Mod Settings.

- Spotify's own Liquid Glass, every flag of it on at once
- Glass now playing bar, player header, search field and lyrics card
- Pure black AMOLED, and a Home gradient
- A tab bar you reorder, hide and add any `spotify:` link to
- Queue as a bottom sheet, swipe a row to play next
- Like and dislike back on the lock screen widget, animated artwork on it
- Speed control and trim silence for music, not only podcasts
- Picture in picture, in the app and out of it
- No ad on app open, no upsells, no tooltips, no DJ badge
- Telemetry blocked, with a count of what it stopped
- Hide anything: Home shortcuts, playlist header, player buttons and the cards under them
- Unreleased features Spotify built and never shipped
- Every remote-config flag Spotify ships, searchable, Auto / Off / On

Purely cosmetic. It does not unlock Premium.

## Get it

No IPA is distributed in this repo. [spoti.pw](https://spoti.pw) carries the current build, and
it is also a source for SideStore, AltStore and Feather: add `https://spoti.pw` and later builds
arrive on their own. Mod Settings → Updates checks the same place.

The app installs as `com.spotify.client2`, next to the real Spotify rather than over it.

## Build it yourself

You bring a decrypted Spotify IPA of your own. Either way the result is an unsigned
`Spotify-<version>-glass.ipa` to sign with SideStore, Feather or any certificate signer.

### On GitHub, no Mac needed

Fork this repo, enable Actions in the fork, and run the **Build IPA from your own Spotify IPA**
workflow. It asks for a direct link to your decrypted `.ipa` (filebin.net, Dropbox, a host of
your own), builds the tweak, injects it, and hands the IPA back as a workflow artifact, or on
filebin.net if you pick that. The link is masked in the run's log and the result lives only in
your fork.

### On a Mac

Theos in `~/theos` with an iPhoneOS SDK in `~/theos/sdks`, plus:

    brew install make ldid dpkg zsign ideviceinstaller libimobiledevice
    uv tool install "cyan @ git+https://github.com/asdfzxcvbn/pyzule-rw"

Put the decrypted `.ipa` in `ipa/`, then:

    make release    # out/Spotify-<version>-glass.ipa, ready to sign
    make install    # the same, signed with your certificate and pushed to the iPhone over USB

`make install` reads `SIGN_P12`, `SIGN_PROFILE` and `SIGN_P12_PASSWORD` from `.signing.env`; copy
`.signing.env.example` and fill it in. `BUNDLE_ID=` overrides the bundle id.

The first build spends about a minute reading Spotify's remote-config flags out of your IPA into
`tweak/src/SGFlagList.m`, so the flag list always matches the Spotify you built from. Later builds
reuse it; `make flags` regenerates it.

## Mod Settings

Settings → Mod Settings is one page per area: UI Tweaks, Home & Library, Playlist, Now Playing,
Lock screen widget, Playback, Ads & nags, Unreleased and Experimental, then Privacy, Navbar and
All flags. A switch on a page forces one of Spotify's flags; off leaves Spotify's own value, and
All flags is where a flag goes back to Auto. Navbar applies straight away, everything else after
Spotify restarts.

## Hack on it

[docs/tweaks.md](docs/tweaks.md): the layout of the tweak, the other make targets, how the view
trees are recorded off the phone, and how to add a tweak of your own.

## Credits

[cyan](https://github.com/asdfzxcvbn/pyzule-rw) does the injection, [Theos](https://theos.dev)
builds the tweak, and [FLEX](https://github.com/FLEXTool/FLEX), as hopeless's AutoFLEX build in
`vendor/`, is the in-app inspector the view trees are read through.

GPL-3.0. Not affiliated with Spotify.
