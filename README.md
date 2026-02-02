# RMStylusButton

RMStylusButton is a small stand-alone program that runs on the reMarkable 2.  It detects stylus button presses to switch to the eraser tool and trigger undo and redo actions.

It should work with any EMR (Wacom-compatible) stylus.  It has been tested with the [Lamy ALstar EMR stylus](https://www.lamy.com/en/digital-writing/classic-meets-smartness/#alstaremr), and similar tools have reported success with:
 * Kindle Scribe Pen
 * Samsung S6 S Pen
 * Wacom One Pen CP91300B2Z
 * iFlytec T1 4096

## Fork

This project is a fork of - [RMStylusButton](https://github.com/rschroll/RMStylusButton) which hasn't been updated in a while. 
The two main changes are:
- Use docker to build the binary on any machine (as I was building for mac and don't trust binaries created by others).
- Add support for the latest reMarkable OS (with the help of antigravity https://antigravity.google/ as I am not a Linux expert)

Tested on the latest reMarkable OS (3.25.0.142)

## Build

> [!WARNING]
> It is not safe to just use binaries you found in the internet, so the guide was changed to allow anyone to build it by themselves, if any part is not clear, please raise an issue

To build RMStylusButton, follow these steps:

### 1. Download the source code
### 2. Complete the pre-install steps
- reMarkable 2
- SSH access to your reMarkable device. 
This [reMarkable guide page](https://remarkable.guide/guide/access/ssh.html) can get you started.
- Docker installed https://www.docker.com
- reMarkable toolchain downloaded (you should use the version that is compatible with your reMarkable device). However, if you are using the latest reMarkable OS, you can just use the latest. Just make sure to download the one with the `rm2` codename
### 3. Place SDK in toolchains folder
```bash
# Create toolchains directory
mkdir -p toolchains

# Move downloaded SDK there
mv ~/Downloads/remarkable-production-image-*.sh toolchains/
```
### 4. Build the docker image (this allows you to build the linux binary on any machine)
```bash
chmod +x docker-build.sh
./docker-build.sh build-image
```

The script will automatically detect the SDK in the `toolchains/` folder.

<details>
  <summary>Output example</summary>
  
  <img width="1440" height="832" alt="image" src="https://github.com/user-attachments/assets/17f2d460-5baf-4939-99db-b3e9ab1edf77" />
  
</details>

### 5. Compile the project

```bash
./docker-build.sh compile
```

This creates:
- `RMStylusButton/RMStylusButton` - The compiled binary
- `RMStylusButton.tar.gz` - Tarball ready for deployment

<details>
  <summary>Output example</summary>
  
  <img width="1439" height="518" alt="image" src="https://github.com/user-attachments/assets/f316b743-3719-431e-bbff-a094e1299b85" />
  
</details>

## Deployment to reMarkable

### Manual deployment (recommended)

```bash
# Copy tarball to device
scp RMStylusButton.tar.gz root@<your address>:~/

# SSH into device
ssh root@<your address>

# Extract and install
tar xzf RMStylusButton.tar.gz
cd RMStylusButton

# To test it out, run
./RMStylusButton
# Use `Ctrl-C` to stop the program.

# Install with toggle mode (button toggles between pen/eraser)
./manage.sh install --toggle

# Or install with press mode (button acts as eraser while pressed)
./manage.sh install
```


<details>
  <summary>Output example</summary>
  
  <img width="787" height="125" alt="image" src="https://github.com/user-attachments/assets/7c9f8e90-8ec3-4ec1-8fc9-3741b5155913" />
  
</details>

### Check installation

```bash
# On reMarkable device
systemctl status RMStylusButton.service
```

## Available Commands

```bash
./docker-build.sh build-image  # Build Docker image with SDK
./docker-build.sh compile      # Compile the project
./docker-build.sh all          # Build image and compile in one step
./docker-build.sh clean        # Clean build artifacts
./docker-build.sh shell        # Open interactive shell in container
```

## Troubleshooting

### Docker not running
```bash
# Make sure Docker Desktop is running
docker info
```

### SDK not found
```bash
# Verify SDK is in toolchains folder
ls -la toolchains/
# Should show .sh file
```

### Binary architecture verification
```bash
# Verify the binary is ARM
file RMStylusButton/RMStylusButton
# Should show: ELF 64-bit LSB executable, ARM aarch64
```

### SSH connection to reMarkable
```bash
# Connect via USB
ssh root@10.11.99.1

# Password is in: Settings > Help > Copyrights and licenses
```

### Uninstall from reMarkable
```bash
ssh root@10.11.99.1
cd RMStylusButton
./manage.sh uninstall
```

## Notes

- The SDK must be in the `toolchains/` folder before building the Docker image
- The Docker image includes the full cross-compilation toolchain
- The compiled binary is ARM architecture for reMarkable devices
- You only need to rebuild the Docker image if you change SDK versions
- Use `./docker-build.sh compile` for subsequent builds after image is created


### reMarkable upgrades

When you install an updated version of the reMarkable software, it will erase the changes that cause RMStylusButton to start automatically.  The files downloaded above should still be present, so just SSH in and again run
```
./RMStylusButton/manage.sh install
```

### Uninstalling

If you don't want RMStylusButton active anymore, SSH into your device and run
```
./RMStylusButton/manage.sh uninstall
```
If you desire, you can also delete the downloaded files:
```
rm -r RMStylusButton
```

## Usage

Press and hold the button on your stylus to erase.  Release the button to switch back to whatever pen you had selected.

Double-click the button to undo the most recent action.  Triple-click the button to redo that action.

### Configuration

RMStylusButton can be configured by options passed to the binary or to the `manage.sh install` command.  Valid options are

<table><tr>
<td><code>--toggle</code></td>
<td>Single presses of the button toggle between erase mode and pen mode.</td>
</tr></table>

### How it works

Stylus events appear in `/dev/input/event1` on the reMarkable 2.  RMStylusButton watches this event stream for button presses.  When it sees events indicating that erasing should happen, it injects events corresponding to the eraser button.

Undo and redo actions are triggered by creating a uinput keyboard device and injecting `Ctrl-Z` and `Ctrl-Y` events.

## Alternatives

Other tools provide similar capabilities to RMStylusButton, but with different features and mechanisms.  Here are the ones I know about.

- [RemarkableLamyEraser](https://github.com/isaacwisdom/RemarkableLamyEraser) was the starting point for this project.  This project [has been paused](https://github.com/isaacwisdom/RemarkableLamyEraser/issues/70) by the developer.
- [slotThe's fork](https://github.com/slotThe/RemarkableLamyEraser) continues the work towards version 2 of RemarkableLamyEraser.  This features a configuration system to allow many different events to be triggered by a wide variety of button click patterns.  These events are triggered by simulating touch events on the relevant UI elements on the tablet screen.  This makes it sensitive to whether the device is in left-handed mode or landscape mode.  It is also vulnerable to changes to the UI in new versions of the reMarkable software.
- [remarkable-stylus](https://github.com/ddvk/remarkable-stylus) provides similar capabilites for users of the [remarkable-hacks](https://github.com/ddvk/remarkable-hacks) modified UI.

## Copyright

Copyright 2023-2024 Robert Schroll
<br/>
Copyright 2021-2023 Isaac Wisdom

RMStylusButton is released under the GPLv3.  See LICENSE for details.
