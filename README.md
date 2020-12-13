# bootloader armada 3720

U-boot/ATF for armada-3720-catdrive

#### toolchain

    gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu
    gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabi

#### u-boot-marvell

    https://github.com/MarvellEmbeddedProcessors/u-boot-marvell
    branch u-boot-2018.03-armada-18.12


#### mv-ddr-marvell

    https://github.com/MarvellEmbeddedProcessors/mv-ddr-marvell
    branch mv_ddr-armada-18.12

#### atf-marvell

    https://github.com/MarvellEmbeddedProcessors/atf-marvell
    branch atf-v1.5-armada-18.12

#### A3700-utils-marvell

    https://github.com/MarvellEmbeddedProcessors/A3700-utils-marvell
    branch A3700_utils-armada-18.12-fixed

#### build uboot

    make patch
    make all

Porting the patch from <https://github.com/hanwckf/bl-armada-3720>
