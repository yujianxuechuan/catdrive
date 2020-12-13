### build catdrive kernel

linux 4.14 bsp kernel for marvell armada-3720-catdrive

#### toolchain

    gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu

#### linux-marvell

    https://github.com/MarvellEmbeddedProcessors/linux-marvell
    branch linux-4.14.76-armada-18.12

#### build

    make patch
    make all

Porting the patch from <https://github.com/hanwckf/linux-marvell>
