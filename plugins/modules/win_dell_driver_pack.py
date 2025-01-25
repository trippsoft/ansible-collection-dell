#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

DOCUMENTATION = r"""
module: win_dell_driver_pack
version_added: 1.0.0
author:
  - Jim Tarpley
short_description: Downloads a Dell driver pack and extracts it on Windows systems
description:
  - Downloads a Dell driver pack for the specified OS and model from the Dell support site and extracts it to a specified directory.
attributes:
  check_mode:
    support: none
    details:
      - Does not support check mode
options:
  catalog_path:
    type: path
    required: true
    description:
      - The path to the Dell catalog XML file.
  download_path:
    type: path
    required: true
    description:
      - The path to which to download the driver pack.
      - If O(create_version_subdirectory=true), the driver pack will be extracted to a subdirectory named for the version.
  os:
    type: str
    required: true
    choices:
      - winpe_11
      - winpe_10
      - win_11
      - win_10
    description:
      - The OS for which to download the driver pack.
  model:
    type: str
    required: false
    description:
      - The model for which to download the driver pack.
      - When O(os=winpe_11) or O(os=winpe_10), this is ignored.
      - When O(os=win_11) or O(os=win_10), this is required.
  create_version_subdirectory:
    type: bool
    required: false
    default: true
    description:
      - If V(true), the driver pack will be extracted to a subdirectory named for the version.
  disambiguation_method:
    type: str
    required: false
    default: newest
    choices:
      - newest
      - oldest
    description:
      - The method to use to disambiguate driver packs for similarly named models.
"""

EXAMPLES = r"""
- name: Download WinPE 10 Driver Pack
  trippsc2.dell.win_dell_driver_pack:
    catalog_path: C:\\temp\\DriverPackCatalog.xml
    download_path: C:\\temp\\winpe10
    os: winpe_10
    create_version_subdirectory: true
    expand_cabs: false

- name: Download WinPE 11 Driver Pack
  trippsc2.dell.win_dell_driver_pack:
    catalog_path: C:\\temp\\DriverPackCatalog.xml
    download_path: C:\\temp\\winpe11
    os: winpe_11
    create_version_subdirectory: true
    expand_cabs: false

- name: Download Win 10 Driver Packs
  loop:
    - OptiPlex 7020 Micro
    - Latitude 5550
    - XPS 13 9380
  trippsc2.dell.win_dell_driver_pack:
    catalog_path: C:\\temp\\DriverPackCatalog.xml
    download_path: "C:\\temp\\win10\\{{ item }}"
    os: win_10
    model: "{{ item }}"
    create_version_subdirectory: true
    expand_cabs: false

- name: Download Win 11 Driver Packs
  loop:
    - OptiPlex 7020 Micro
    - Latitude 5550
    - XPS 13 9380
  trippsc2.dell.win_dell_driver_pack:
    catalog_temp_path: C:\\temp
    download_path: "C:\\temp\\win11\\{{ item }}"
    os: win_11
    model: "{{ item }}"
    create_version_subdirectory: true
    expand_cabs: false
"""

RETURN = r"""
catalog_version:
  type: str
  returned:
    - success
  description:
    - The version of the catalog file.
driver_pack_version:
  type: str
  returned:
    - success
  description:
    - The version of the driver pack.
driver_pack_path:
  type: path
  returned:
    - success
  description:
    - The path to which the driver pack was downloaded.
driver_format:
  type: str
  returned:
    - success
  choices:
    - exe
    - cab
  description:
    - The format of the driver pack.
"""
