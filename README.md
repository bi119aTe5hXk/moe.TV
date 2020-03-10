# moe.TV
An [Albireo](https://github.com/lordfriend/Albireo) & [Sonarr](https://sonarr.tv/) client which can watch bangumis / videos on your tvOS devices.

## How-to (Sonarr)

1. Setup your Sonarr and WebDAV service on your server, you can install [WebDAVNav Server](https://apps.apple.com/us/app/webdavnav-server/id747482894?mt=12) if you are using macOS as your service Server.

2. Set the download path within Sonarr as your WebDAV shared folder. Such as /Macintosh HD/Users/your_user_name/Downloads/sonarr/. The sub-folders should be the series name.

3. Login moe.TV client with your Sonarr service info.

For example:

- Service Type: Sonarr

- Connection Type: HTTP

- Host:192.18.1.2:8989

- WebDAV port:8990

- API key:<On Sonarr server, open [/settings/general](http://127.0.0.1:8989/settings/general)>

4. Hit "Save&Login in", and enjoy your anime night.


## Preview

![sc1](https://pbs.twimg.com/media/EE-t6cfU8AAhj_3?format=jpg&name=large)

![sc2](https://pbs.twimg.com/media/ESsXkq6U0AAR2I9?format=jpg&name=large)

![sc3](https://pbs.twimg.com/media/EFTwM65U0AAeLSp?format=jpg&name=large)

## Long term issue

- unsupport video file such as .mkv, .h264 can not be played. And tvOS is not support URL scheme yet, so jump to VLC player also not working. Hope next update will support this 🙏. (temp workaround: download supported format such as .mp4, .m4v)

