# Changelog

All notable changes to this project will be documented in this file.

## [1.1.1] - 2025-02-09

### win_dell_driver_pack Module Plugin

- Made several code quality and style changes to the module that were recommended by the Ansible sanity tests.

## [1.1.0] - 2025-01-25

### Collection

- *mdt_drivers* role added.

### win_dell_driver_pack Module Plugin

- Removed steps to download and extract catalog CAB file. This was done to simplify the module.
- Removed steps to extract the CAB and EXE file. This was done to simplify the module.
- Changed output file for EXE packs to not change the extension to .zip.

## [1.0.0] - 2025-01-22

### Collection

- Initial release.
- *win_dell_driver_pack* module plugin added.
