<!-- BEGIN_ANSIBLE_DOCS -->

# Ansible Role: trippsc2.dell.mdt_drivers
Version: 1.1.1

This role manages Dell MDT drivers.

## Requirements

| Platform | Versions |
| -------- | -------- |
| Windows | <ul><li>2019</li><li>2022</li></ul> |

## Dependencies
| Role |
| ---- |
| trippsc2.windows.install_psgallery |

| Collection |
| ---------- |
| ansible.windows |
| community.windows |
| trippsc2.mdt |
| trippsc2.windows |

## Role Arguments
|Option|Description|Type|Required|Choices|Default|
|---|---|---|---|---|---|
| dell_mdt_catalog_download_url | <p>The URL from which to download the Dell MDT driver catalog CAB file.</p> | str | no |  | https://downloads.dell.com/catalog/DriverPackCatalog.cab |
| dell_mdt_temp_directory_path | <p>The path to the temporary directory in which to store the Dell MDT driver catalog files.</p><p>If not provided, the *ansible.windows.win_tempfile* module is used to create a temporary directory.</p> | path | no |  |  |
| dell_mdt_installation_path | <p>The path to the MDT installation directory.</p><p>If not provided, the default installation path is used.</p> | path | no |  |  |
| dell_mdt_share_path | <p>The path to the MDT deployment share.</p> | path | yes |  |  |
| dell_mdt_winpe_driver_packs | <p>The list of Dell WinPE driver packs to download and manage.</p> | list of dicts of 'dell_mdt_winpe_driver_packs' options | yes |  |  |
| dell_mdt_operating_systems | <p>The list of Dell operating systems for which we will maintain drivers.</p> | list of dicts of 'dell_mdt_operating_systems' options | yes |  |  |
| dell_mdt_models | <p>The list of Dell models for which we will maintain drivers.</p> | list of dicts of 'dell_mdt_models' options | yes |  |  |
| dell_mdt_max_retries | <p>The maximum number of times to retry a download.</p> | int | no |  | 3 |
| dell_mdt_update_mdt_boot_image | <p>Whether to update the MDT boot image.</p><p>This will only occur when new WinPE drivers are added.</p> | bool | no |  | True |
| dell_mdt_replace_wds_boot_image | <p>Whether to replace the WDS boot image.</p><p>If *dell_mdt_update_mdt_boot_image* is set to `false`, this will be ignored.</p><p>This will only occur when new WinPE drivers are added and a new MDT boot image is created.</p> | bool | no |  | False |
| dell_mdt_wds_boot_image_name | <p>The name of the WDS boot image.</p><p>This is required if *dell_mdt_replace_wds_boot_image* is set to `true`.</p> | str | no |  |  |
| dell_mdt_wds_boot_image_description | <p>The description of the WDS boot image.</p><p>If not provided, no description will be provided to the module.</p> | str | no |  |  |
| dell_mdt_wds_boot_image_display_order | <p>The display order of the WDS boot image.</p><p>If not provided, no display order will be provided to the module.</p> | int | no |  |  |

### Options for dell_mdt_winpe_driver_packs
|Option|Description|Type|Required|Choices|Default|
|---|---|---|---|---|---|
| os | <p>The version of WinPE for which to download a driver pack.</p> | str | yes | <ul><li>winpe_11</li><li>winpe_10</li></ul> |  |
| mdt_path | <p>The path of the driver directory to which to import the driver pack.</p><p>This path is relative to the `Out-of-Box Drivers` directory.</p> | str | yes |  |  |

### Options for dell_mdt_operating_systems
|Option|Description|Type|Required|Choices|Default|
|---|---|---|---|---|---|
| os | <p>The version of Windows for which to maintain drivers.</p> | str | yes | <ul><li>win_11</li><li>win_10</li></ul> |  |
| base_mdt_path | <p>The base path of the driver directory to which to import driver packs.</p><p>This path is relative to the `Out-of-Box Drivers` directory.</p> | str | yes |  |  |

### Options for dell_mdt_models
|Option|Description|Type|Required|Choices|Default|
|---|---|---|---|---|---|
| catalog_name | <p>The name of the model in the Dell driver catalog.</p> | str | yes |  |  |
| mdt_name | <p>The name of the model in the MDT driver directory.</p><p>If you are using WMI filters to select driver, this must accurately match the model name in WMI.</p> | str | yes |  |  |


## License
MIT

## Author and Project Information
Jim Tarpley
<!-- END_ANSIBLE_DOCS -->
