# mac2phabricator

![mac2phabricator running on macOS](missing)

A simple Mac application designed to make uploading images and screenshots to your [phabricator.com](https://phabricator.com) quick and effortless.

## Installation

Build it yourself

## Usage

The application will listen for new screenshots taken by the [built in screenshot functionality of macOS](https://support.apple.com/kb/ht5775), so you can use the following shortcuts to capture your screen:

- Press <kbd>CMD ⌘</kbd> + <kbd>SHIFT ⇧</kbd> + <kbd>3</kbd> to take a full-screen screenshot

- Press <kbd>CMD ⌘</kbd> + <kbd>SHIFT ⇧</kbd> + <kbd>4</kbd> to take a rectangular selection of the screen

- Press <kbd>CMD ⌘</kbd> + <kbd>SHIFT ⇧</kbd> + <kbd>4</kbd> + <kbd>SPACE</kbd> to capture a specific window or menu

In addition, images can be uploaded manually by either:

- Dragging and dropping images on the status bar icon  (macOS 10.10+)
- Clicking the "Upload Images…" option in the status bar menu

As soon as an image is uploaded, the link is copied to your clipboard and a notification is sent:
![mac2phabricator upload notification](missing)

## Application Preferences

### General

| Preference Name | Description 
| --------------- | ----------- | 
| Launch at Login | Allows mac2phabricator to start as soon as you log in - this can also be changed from the `Login Items` tab of the `Users & Groups` pane of `System Preferences`. | 
| Clear Clipboard | Clears the clipboard when an upload is taking place. |
| Copy Link to Clipboard | Copies the direct link to the uploaded image, if the upload completes successfully. |

### Screenshots

| Preference Name | Description |
| --------------- | ----------- |
| Delete After Upload | Causes the original screenshot file to be moved to trash after attempting to upload. |
| Disable Detection | Any new screenshots taken are ignored by the application and not uploaded. |
| Request Confirmation Before Upload | Screenshots are not uploaded automatically. Instead, an alert is displayed, showing the image and image name, allowing you to either proceed or cancel. |
| Downscale from Retina | Retina screenshots are resized (reducing resolution) before upload. [More Info.](https://cloudup.com/blog/the-retina-screenshot-problem) |

## System Preferences

Some aspects of the system screenshot functionality can be customized through `defaults`, including the following options:

| Key | Value | Result |
| --- | ----- | ------ |
| location | Any path, e.g. `/Users/[username]/Pictures` | Screenshots will be saved to the specified location, if it is valid. Otherwise, the default location (typically `~/Desktop`) will be used. |
| type | `png`, `jpg`, `gif`, `tiff` etc | The screenshot will be saved in the specified format. |
| name | Any string, e.g. `My Screenshot` | The screenshot file will be prefixed with the specified name, e.g. `My Screenshot 2016-07-10 at 17.42.17`. |

You can modify the defaults easily from `Terminal.app`:

`defaults write com.apple.screencapture <key> <value>`

`defaults delete com.apple.screencapture <key>`

### Examples

Save screenshots using the `JPG` format:

`defaults write com.apple.screencapture type jpg`

Revert the screenshot save location back to the system default:

`defaults delete com.apple.screencapture location`

### Further Information

More about `defaults` can be found from `defaults --help` and `man defaults`.

For any changes to take effect, you must restart `SystemUIServer`, which can be done through `Activity Monitor.app` or by running a command such as `killall SystemUIServer`.

When changing the screenshot location, it is also necessary to restart mac2phabricator.

## Support

If you encounter any problems or have an idea for a new feature, don't hesitate to [file an issue](missing) - but please be as descriptive as possible! 

On the same note, pull requests to fix bugs, add features or simply to improve the codebase are greatly appreciated.

## Development

- Written in Swift 3
- [CocoaPods](https://cocoapods.org) for dependency management

## Legal

mac2phabricator is based on [mac2imgur](https://github.com/mileswd/mac2imgur)

This application is released under a GPLv3 license. See [LICENSE](https://github.com/thorbenprimke/mac2phabricator/blob/master/LICENSE) for more information.
