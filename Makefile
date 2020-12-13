SHELL = /bin/bash
CUR_DIR := $(shell pwd)
OUTPUT_DIR := $(CUR_DIR)/output

UBOOT_NM := u-boot-2018.03-armada-18.12
UBOOT := u-boot-marvell-$(UBOOT_NM)
UBOOT_URL := https://github.com/MarvellEmbeddedProcessors/u-boot-marvell/archive/refs/heads/$(UBOOT_NM).tar.gz
UBOOT_CFG := catdrive.config
DTB := armada-3720-catdrive
BL33 := $(UBOOT)/u-boot.bin

DDR_NM := mv_ddr-armada-18.12
DDR := mv-ddr-marvell-$(DDR_NM)
DDR_URL := https://github.com/MarvellEmbeddedProcessors/mv-ddr-marvell/archive/refs/heads/$(DDR_NM).tar.gz

A3700_NM := A3700_utils-armada-18.12-fixed
A3700 := A3700-utils-marvell-$(A3700_NM)
A3700_URL := https://github.com/MarvellEmbeddedProcessors/A3700-utils-marvell/archive/refs/heads/$(A3700_NM).tar.gz

ATF_NM := atf-v1.5-armada-18.12
ATF := atf-marvell-$(ATF_NM)
ATF_URL := https://github.com/MarvellEmbeddedProcessors/atf-marvell/archive/refs/heads/$(ATF_NM).tar.gz

TC_ARM := gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabi
TC_AARCH64 := gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu
TC_ARM_URL := https://releases.linaro.org/components/toolchain/binaries/latest-7/arm-linux-gnueabi/$(TC_ARM).tar.xz
TC_AARCH64_URL := https://releases.linaro.org/components/toolchain/binaries/latest-7/aarch64-linux-gnu/$(TC_AARCH64).tar.xz

DEFCONFIG := $(CUR_DIR)/$(UBOOT)/configs/catdrive_defconfig
MAKE_ARCH := export PATH=$$PATH:$(CUR_DIR)/$(TC_ARM)/bin:$(CUR_DIR)/$(TC_AARCH64)/bin; make CROSS_COMPILE=aarch64-linux-gnu- CROSS_CM3=arm-linux-gnueabi-

dl_toolchain:
ifeq (,$(wildcard $(CUR_DIR)/$(TC_ARM).tar.xz))
	curl -O -L $(TC_ARM_URL)
	tar xf $(TC_ARM).tar.xz
else ifeq (,$(wildcard $(CUR_DIR)/$(TC_ARM)))
	tar xf $(TC_ARM).tar.xz
endif
ifeq (,$(wildcard $(CUR_DIR)/$(TC_AARCH64).tar.xz))
	curl -O -L $(TC_AARCH64_URL)
	tar xf $(TC_AARCH64).tar.xz
else ifeq (,$(wildcard $(CUR_DIR)/$(TC_AARCH64)))
	tar xf $(TC_AARCH64).tar.xz
endif

dl_uboot:
ifeq (,$(wildcard $(CUR_DIR)/$(UBOOT_NM).tar.gz))
	curl -O -L $(UBOOT_URL)
	tar xf $(UBOOT_NM).tar.gz
else ifeq (,$(wildcard $(CUR_DIR)/$(UBOOT)))
	tar xf $(UBOOT_NM).tar.gz
endif

dl_ddr:
ifeq (,$(wildcard $(CUR_DIR)/$(DDR_NM).tar.gz))
	curl -O -L $(DDR_URL)
	tar xf $(DDR_NM).tar.gz
else ifeq (,$(wildcard $(CUR_DIR)/$(DDR)))
	tar xf $(DDR_NM).tar.gz
endif

dl_atf:
ifeq (,$(wildcard $(CUR_DIR)/$(ATF_NM).tar.gz))
	curl -O -L $(ATF_URL)
	tar xf $(ATF_NM).tar.gz
else ifeq (,$(wildcard $(CUR_DIR)/$(ATF)))
	tar xf $(ATF_NM).tar.gz
endif

dl_A3700:
ifeq (,$(wildcard $(CUR_DIR)/$(A3700_NM).tar.gz))
	curl -O -L $(A3700_URL)
	tar xf $(A3700_NM).tar.gz
else ifeq (,$(wildcard $(CUR_DIR)/$(A3700)))
	tar xf $(A3700_NM).tar.gz
endif

all: atf
	mkdir -p $(OUTPUT_DIR)
	cp -f $(ATF)/build/a3700/release/uart-images.tgz $(OUTPUT_DIR)
	cp -f $(ATF)/build/a3700/release/flash-image.bin $(OUTPUT_DIR)

patch: dl_A3700 dl_atf dl_ddr dl_uboot dl_toolchain
ifeq (,$(wildcard $(DEFCONFIG)))
	find $(CUR_DIR)/patches -type f -print | sort | xargs -n 1 patch -d $(UBOOT) -p1 -i
endif

uboot: patch
	$(MAKE_ARCH) -C $(UBOOT) catdrive_defconfig
	$(MAKE_ARCH) -C $(UBOOT) DEVICE_TREE=$(DTB)

atf: uboot
	$(MAKE_ARCH) -C $(ATF) \
		MV_DDR_PATH=$(CUR_DIR)/$(DDR) \
		WTP=$(CUR_DIR)/$(A3700) \
		BL33=$(CUR_DIR)/$(BL33) \
		CLOCKSPRESET=CPU_1000_DDR_800 DDR_TOPOLOGY=0 \
		BOOTDEV=SPINOR PARTNUM=0 PLAT=a3700 DEBUG=0 \
		USE_COHERENT_MEM=0 LOG_LEVEL=20 SECURE=0 \
		all fip

clean:
ifneq (,$(wildcard $(DEFCONFIG)))
	find $(CUR_DIR)/patches -type f -print | sort -r | xargs -n 1 patch -d $(UBOOT) -p1 -R -i
endif
	$(MAKE_ARCH) -C $(UBOOT) clean
	$(MAKE_ARCH) -C $(ATF) distclean
	rm -rf $(OUTPUT_DIR)

# vim:ft=make
