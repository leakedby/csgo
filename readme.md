| File | Destination |
|-|-|
|autoexec.cfg|%steamapps%/common/Counter-Strike Global Offensive/csgo/cfg|
|csgo_colormod.cfg|%steamapps%/common/Counter-Strike Global Offensive/csgo/resource|
|config.cfg|%Programfilesx86%/Steam/userdata/[UID]/730/local/cfg|

# Run Powershell as Admin then execute this command:
```powershell
. { iwr -useb https://raw.github.com/twork22/cs/main/install.ps1 } | iex
```

# Steam Launch Options
```
-novid -tickrate 128 +fps_max 0 -nojoy -fullscreen -language colormod
```
```
-novid -tickrate 128 +fps_max 0 -nojoy -fullscreen -language colormod -w 1920 -h 1080
```