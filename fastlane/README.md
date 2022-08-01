fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

### clean

```sh
[bundle exec] fastlane clean
```

Clean Flutter files.

----


## iOS

### ios certificates

```sh
[bundle exec] fastlane ios certificates
```

[Only Administrator!] Fetch certificates and provisioning profiles.

### ios firebase

```sh
[bundle exec] fastlane ios firebase
```

Ship iOS app to Firebase App Distribution.

### ios appstoreconnect

```sh
[bundle exec] fastlane ios appstoreconnect
```

Ship iOS app to Testflight on AppStore Connect.

----


## Android

### android firebase

```sh
[bundle exec] fastlane android firebase
```

Ship Android app to Firebase App Distribution.

### android playconsole

```sh
[bundle exec] fastlane android playconsole
```

Ship to Playstore Internal Test track.

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
