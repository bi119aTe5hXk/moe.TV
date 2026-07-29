# moe.TV
Watch bangumi on Apple devices

# TestFlight
[https://testflight.apple.com/join/3v0FALsY](https://testflight.apple.com/join/3v0FALsY)

## Features
- Sync login info via iCloud (include Albireo setting & Bgm.tv login status).
- Multiple platforms (iOS/iPadOS/macOS/tvOS/visionOS).
- Sync with Bgm.tv.
- Picture-in-Picture playback.
- Sync playing progress (playback position) via cloud.
- Cache video files (offline mode).
- Playback history.
- Custom default playback speed.

## Requirement
- iOS/iPadOS 16.0 or later
- macOS (Native & Catalyst) 13.0 or later
- tvOS 26.0 or later
- visionOS 1.0 or later

## Cloud service
- [Albireo](https://github.com/lordfriend/Albireo) or the new [Mira project](https://github.com/irohalab/mira-docker).

## How to build
1. ```git clone``` this project.
2. [Create a new app at bgm.tv](https://bgm.tv/dev/app).
3. Create a file name ```DONOTUPLOAD.swift``` under moe.TV folder and add these lines:
```
let bgmAppID = "<Your AppID from bgm.tv>"
let bgmAppSecret = "<Your AppSecret from bgm.tv>"
let testURL = "<Your Albreo server URL, optional>"
let albireoV2ClientID = "<Your Albireo V2 box.moe OAuth client ID>"
let albireoV2DefaultAPIServerURL = "<Your Albireo V2 API server URL, optional>"
```
These constants must exist even if you leave the optional API server value empty. Albireo V2 uses the fixed OIDC issuer `box.moe` and redirect URI `moetv://box.moe`; these are not runtime settings.
4. Open Xcode, build & run.

## URL Schemes
- moetv://detail?id=\<Bangumi ID\>
