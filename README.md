# Windows Wing

WWing (Short for Windows Wing) is a highly user-experience focused top-bar theme for rainmeter.

It follows the concept of *One Action* for any operation.

It is designed to **replace** the taskbar, and allow a dock to be used as your task bar.

In regards to this skin, it means that any of it's features are usable with that single action. For example, to view any of the skin's overlays, mouse over the icon.

## Features

### Weather
**Your location is gathered automatically and weather is parsed from it** - I know right? No more country code lookup and variable hacking.

### Spotify
![Spotify](https://i.imgur.com/cKkubKN.jpg)

In the spotify overlay, the track progress is displayed in the green bar at the top, the album in grey text and image, the title in bold white text, and the artist in green text.

On mousing over the media controls, the Spotify logo will become the play/pause logo with the corresponding action.

To open the full Spotify window, **Right Click** the play pause icon.

### Steam
![Steam](https://i.imgur.com/guFW1eC.jpg)

The steam overlay appears on mousing over the steam icon. The overlay will *only* show your steam friends that are online and **in-game**.

**Left Click** to open the steam app.
**Right Click** to open the steam friends location.

In the default configuration, it pulls your steam username from the autologin key in the steam registry:

    HKEY_CURRENT_USER\Software\Valve\Steam\AutoLoginUser

This is used with the url fragment in the variable **vPreSteamNameUrl**

The whole url (vPreSteamNameUrl + steam username) will be appended with the fragment "/friends".

If your steam friends page does not match this format (most do) you will need to manually update the variable yourself. 

### Volume Meter

![Volume Meter](https://i.imgur.com/kY1VMFV.jpg)
There is a right/left VU meter at the top of the icon.

Mouse over to see the current volume.

**Mouse Wheel Up to increase volume.**
**Mouse Wheel Down to decrease volume.**

### CPU Meter

![CPU Meter](https://i.imgur.com/0MqZInl.jpg)
The CPU meter overlays the start button, with a simple radial meter.

### Main Bar
![Main Bar](https://i.imgur.com/UK2CMZb.jpg)

The main bar will fill to fully opaque black whenever there is at least one maximized window open, or the start menu is detected as open.

## Requirements

 - You need autohotkey 2.0 installed, as all the scripts this skin uses utilize it. I may consider compiling to exe files if there is demand for this.
 - You need some kind of dock with systray support. I recommend  [Winstep Nexus](http://www.winstep.net/nexus.asp) as it supports multiple docks and a customizable systray
 - **This theme will hide your taskbar while it is running** so make sure you have your dock running first. If you get stuck, **ctrl-shift-esc** and kill rainmeter.
 - You need to install the spotify.dll plugin for rainmeter by Raptor -> https://forum.rainmeter.net/viewtopic.php?t=17077
 - **You need to have your taskbar at the top of the screen before running the skin**

### System Tray
- I recommend having your systray set at the top right of your screen. 
- The systray icons need to be 48 pixels high. 
- The icons need a border of Top: 0px, Right: 10px, Bottom: 20px, Left: 10px. 
- If you are using winstep nexus you will need 1px vertical icon spacing, at -1px offset (for a total of 0px vert spacing for the icons).
- The notification mode icon uses a 48px x 2px sizing along the top.

![Systray](https://i.imgur.com/3yPPH2Q.png)

This weird sizing is required for having notification icons sitting hard up against the monitor border. 

## Notes and Issues

 - I had to include an exe file (AccountPicConverter.exe) to get your windows user pic. 
The source code is here: https://github.com/Efreeto/AccountPicConverter - I didn't make it, just found it
 - The downloads icon will light up while any downloads are running. Click it to open your downloads folder.
 - If there are any issues, do a full refresh all. The top bar blackout feature sometimes gets out of sync. Im working on this.

