# moe.TV
Watch bangumi on Apple devices

# App
TestFlight: [https://testflight.apple.com/join/3v0FALsY](https://testflight.apple.com/join/3v0FALsY)

## Features
- Sync with iCloud (No need to log in multiple times)
- Support multiple platforms (iOS/macOS/tvOS)
- Sync progress with bgm.tv
- Picture in Picture
- Save playing progress automatically
- Cache video files locally (offline mode)
- Yes, SwiftUI

## Support platform
- iOS 16.0 and later
- macOS (Native & Catalyst) 13.0 and later
- tvOS 16.0 and later

## Support Service
- [Albireo](https://github.com/lordfriend/Albireo) or the new [Mira project](https://github.com/irohalab/mira-docker)

## URL Schemes
- moetv://detail?id=\<Bangumi ID\>

## How to build
1. ```git clone``` this project.
2. Create a file name ```DONOTUPLOAD.swift``` under moe.TV folder.
3. [Create a new app at bgm.tv](https://bgm.tv/dev/app).
4. Edit the file ```DONOTUPLOAD.swift``` with:
```
let bgmAppID = "<Your AppID from bgm.tv>"
let bgmAppSecret = "<Your AppSecret from bgm.tv>"
let testURL = "<Your Albreo server URL, optional>"
```
5. Open Xcode, build & run.
