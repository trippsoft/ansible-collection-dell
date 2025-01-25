#! /bin/bash

set -e

MOLECULE_BOX="w2022_cis" molecule test -s win_dell_driver_pack
MOLECULE_BOX="w2019_cis" molecule test -s win_dell_driver_pack
MOLECULE_BOX="w2025_base" molecule test -s win_dell_driver_pack
