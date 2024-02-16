# Changelog

## 1.5.1

- Reverts to a previous version of the c-sdk tunnel due to issues with DNS.

## 1.5

- Temporary measures to ensure DNS resolution does not fail.

## 1.4

- Nomenclature alignment.

## 1.3.5

- Fixes issues with enrollment.
- Updates a few methods and functions in startup.

## 1.3.4

- Addresses a problem with decoding a new identity (JWT).
- Updates the Ziti-Edge-Tunnel (v0.22.16) utilizing ZITI C SDK (v0.35.8).

## 1.3.3

- Fixes a few things that got messed up due to how git was being handled.

## 1.3.2

- Updates to the display system.

## 1.3.1

- Fixes errors presented in previous update.

## 1.3.0

- Major update to newest OpenZiti tunnel (C-SDK).

## 1.2.3

- Bug fixes and enhancements to the look and feel of the ingress system.

## 1.2.2

- Fixes exposure of the ingress to only allow authorized users from the HA interface.

## 1.2.1

- Multiple bug fixes.
- Enhanced the status page.

## 1.2.0

- Major update now includes ingress capabilities to reflect status page.
- Multiple bug fixes.

## 1.1.4

- Addresses an issue in build that prevents the image from launching correctly.
- Updates README to reflect how you would remove enrolled identities.

## 1.1.3

- Minor bug fixes.

## 1.1.2

- Updates the Ziti-Edge-Tunnel (v0.21.0) utilizing ZITI C SDK (v0.31.5).

## 1.1.1

- Fixes an error in signing with CAS.
- Adds a graceful release of the original DNS upstream of the system upon shutdown.
- Some minor bug fixes.

## 1.1.0

- Major update to utilize CAS notary.

## 1.0.4

- Now utilizing a prebuilt container via DockerHub for speed to install.
- Minor bug fixes.

## 1.0.3

- New building options.
- Bug fixes.

## 1.0.2

- Cleanup of some license information.
- Change the checking cycle to reduce logging.

## 1.0.1

- Fixed a bug in the enrollment method.

## 1.0.0

- Initial release.
