# vorssaint-stumm

A small Mac tool that mutes the speakers when the volume reaches zero.

## Why it exists

I use Vorssaint with "Use finer volume steps" switched on. With that option, volume zero is not mute: the MacBook speakers keep playing at −63.5 dB. In a quiet room you can still hear it.

macOS on its own mutes at zero. This tool brings that behaviour back.

## What it does

It watches the default output device through CoreAudio. There is no polling. It only wakes up when the volume, the mute state or the default device changes.

- When the volume reaches zero, it mutes the device.
- When the volume goes back up, it unmutes, but only if it was the one that muted. If you muted by hand, it leaves that alone.
- When you switch to another output, such as headphones or a display, it follows.
- Some devices have no main mute switch, only one per channel. It handles both.

The whole thing is one Swift file, `main.swift`, with no dependencies beyond what ships with macOS.

## Install

You need the Xcode command line tools, because the build uses `swiftc`.

```
./build.sh
```

This compiles the tool, installs a LaunchAgent for your user and starts it. From then on it starts at login. It needs no admin rights.

The LaunchAgent points at the folder you built in, so keep the folder where it is, or run `./build.sh` again after moving it.

## Remove

```
./uninstall.sh
```

This stops the tool and deletes the LaunchAgent. Nothing else was installed.

## Log

The tool writes to `log.txt` in its folder: one line when it starts, and one each time it mutes or unmutes.

## Notes

"Stumm" is German for "mute".

I wrote this for my own MacBook and run it on macOS 27. I have not tested other versions.

This project is not affiliated with Vorssaint.

## License

MIT. See [LICENSE](LICENSE).
