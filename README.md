# moe.TV
An [Albireo](https://github.com/lordfriend/Albireo) & [Sonarr](https://sonarr.tv/) client which can watch bangumis / videos on your tvOS devices.

## How to use (for Albireo)

Just input your server domain and login in using your authentication info.

## How to use (for Sonarr)

1. Setup your Sonarr and WebDAV service on your server, you can install [WebDAVNav Server](https://apps.apple.com/us/app/webdavnav-server/id747482894?mt=12) if you are using macOS as your service Server.

2. Set the download path within Sonarr as your WebDAV shared folder. Such as /Macintosh HD/Users/your_user_name/Downloads/sonarr/. The sub-folders should be the series name. 

- Note: Authentication on both Sonarr and WebDAV only support HTTP basic authentication which is browser popup. And both Sonarr and WebDAV basic authentication enable or disable at the same time, i,e you can't enable Sonarr basic authentication and disable WebDAV authentication. And Digest authentication in WebDAV is not support, don't check that box in WebDAVNav Server's Authentication page.

3. Login moe.TV client with your Sonarr service info.

For example:

- Service Type: Sonarr

- Connection Type: HTTP

- Host:192.18.1.2:8989

- WebDAV port:8990

- API key:<On Sonarr server, open [/settings/general](http://127.0.0.1:8989/settings/general)>

4. Hit "Save&Login in", and enjoy your anime night.

## How to Build

1. Clone this project or download sorcecode and upzip it. And open moe.TV folder.

2. Open Terminal, cd to moe.TV folder's path, and run 'pod install'. Notice that TVVLCKit framwork will take about 970MB space and the package download speed is relatively slow.

3. Open moe.TV.xcworkspace, Choose your Team for code-signing.

4. Build and run.

## Preview

![sc1](https://pbs.twimg.com/media/EE-t6cfU8AAhj_3?format=jpg&name=large)

![sc2](https://pbs.twimg.com/media/ESsXkq6U0AAR2I9?format=jpg&name=large)

![sc3](https://pbs.twimg.com/media/EFTwM65U0AAeLSp?format=jpg&name=large)

## Long term issue

- WebDAV is require for video files transfer in Sonarr mode. Sonarr service does not include WebDAV or script for run services. 3rd part program is required.

