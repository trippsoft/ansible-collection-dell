# Changelog

All notable changes to this project will be documented in this file.

## [1.1.3] - 2025-06-10

### Collection

- Changed repository URL to use GitHub Organization.

## [1.1.2] - 2025-02-13

### Module Plugin - win_dell_driver_pack

- Reverted changing documentation from .py file to .yml file because ansible-lint does not parse it correctly yet.

## [1.1.1] - 2025-02-09

### Module Plugin - win_dell_driver_pack

- Made several code quality and style changes to the module that were recommended by the Ansible sanity tests.

## [1.1.0] - 2025-01-25

### Collection

- *mdt_drivers* role added.

### Module Plugin - win_dell_driver_pack

- Removed steps to download and extract catalog CAB file. This was done to simplify the module.
- Removed steps to extract the CAB and EXE file. This was done to simplify the module.
- Changed output file for EXE packs to not change the extension to .zip.

## [1.0.0] - 2025-01-22

### Collection

- Initial release.
- *win_dell_driver_pack* module plugin added.
