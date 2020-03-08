# SuccessionRestore
Modern alternative to Cydia Eraser, a tool that allows users to restore their jailbroken device(s) back to stock iOS without a firmware update or the use of SHSH2 blobs.

Unlike Cydia Eraser, Succession uses rootfilesystem DMGs that can be dumped to perform a restore, making Succession more reliable and easier to update, while always maintaining support for modern iOS devices/firnwares.

Special thanks to [comex](https://github.com/comex) for generously providing attach, a component that allows DMGs to be attached for use on older devices.

### How it works
Succession is both an IPSW downloader/extractor and DMG mounter, allowing the ability to perform a restore on your device by:
- Downloading an IPSW from Apple's servers for your device/iOS version
- Extracting the largest DMG file from the downloaded IPSW
- Mounting the extracted DMG file on your filesystem (at `/var/MobileSoftwareUpdate/mnt1`)
- Using [rsync](https://rsync.samba.org/) to replace any modified file with a clean versions from the mounted DMG file while deleting additional files

Once this occurs, `mobile_obliterator` (aka "Erase all Content and Settings") is called to complete the restore. **This is NOT dangerous, as files have been correctly replaced with cleaner versions and your device is unjailbroken at this point.**

### Device Support
- All devices running iOS 10.0 or newer are fully supported
- Devices running iOS 8.0-9.3.5 are supported **(exclduing the iPad Pro 12.9", iPad Pro 9.7", and iPhone 6s+)** through the usage of decryption keys provided by [theiphonewiki](https://www.theiphonewiki.com/). Succession will be able to support the currently excluded devices as soon as decryption keys are posted there, and this will not require an update to Succesion to include support.

### Installation
If you'd like to go back to stock iOS, you can obtain Succession from:
- [My Cydia Repository](https://samgisaninja.github.io/)
- [Dynastic](https://repo.dynastic.co) (default repository on all  jailbreaks and package managers, iOS 11 or higher)
- [BigBoss](https://apt.thebigboss.org/repofiles) (default respository for Cydia only)

You can also find pre-compiled versions of Succession via [Github Releases](https://github.com/Samgisaninja/SuccessionRestore/releases) if you pefer to install packages manually.

## Compiling
*I really don't anticipate anyone ever attempting to compile this project... but here it goes* ¯\\\_(ツ)_/¯

In order to compile Succession, you'll need a fairly recent version of macOS with `fakeroot`, `ldid`, and `dpkg` installed. If you do not have these dependencies, you can easily installed them by using [Homebrew](https://brew.sh):
```
$ brew install fakeroot
$ brew install ldid
$ brew install dpkg
```

As of Succession 1.4.12, you will need a fairly recent version of theos set up, you can follow their install tutorial [here](https://github.com/theos/theos/wiki/Installation-macOS)

Once you have these dependencies, clone Succession using [Git](https://git-scm.com/downloads):
```
$ git clone https://github.com/Samgisaninja/SuccessionRestore.git
```
Compiling is fairly simple afterwards, thanks to the `compile` and `install` scripts provided in the root directory of the project. You can use them to compile and install Succession directly onto your device.

***Note**: The `install` script will only work if you have OpenSSH installed on your iOS device.*

## License
This project is licensed under the GNU General Public License v3.0, with accordance to [rsync](https://rsync.samba.org/) and [Zebra](https://github.com/wstyres/Zebra). If you'd like to support the project or my development, you can donate [here](https://paypal.me/SamGardner4). **Donations are not a requirement, but highly appreciated!**

Special thanks to [PsychoTea](https://twitter.com/iBSparkes), [Pwn20wnd](https://twitter.com/Pwn20wnd), [Cryptiiic](https://github.com/Cryptiiiic), and [Nobbele](https://github.com/nobbele) for their respective contributions to this project.
