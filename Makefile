SHELL = /bin/bash
CUR_DIR := $(shell pwd)
STAGE_DIR := $(CUR_DIR)/stage
OUTPUT_DIR := $(CUR_DIR)/output

TC := gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu
TCURL := https://releases.linaro.org/components/toolchain/binaries/latest-7/aarch64-linux-gnu
KTAGS := linux-4.14.76-armada-18.12
KURL := https://github.com/MarvellEmbeddedProcessors/linux-marvell/archive/refs/heads

KDIR := linux-marvell-$(KTAGS)
KCFG := catdrive_defconfig
KVER = $(shell make -s kernel_version)

MAKE_ARCH := export PATH=$$PATH:$(CUR_DIR)/$(TC)/bin; make -C $(KDIR) CROSS_COMPILE=aarch64-linux-gnu- ARCH=arm64
J=$(shell grep ^processor /proc/cpuinfo | wc -l)

all: kernel modules
	mkdir -p $(OUTPUT_DIR)
	cp -f $(KDIR)/defconfig $(OUTPUT_DIR)/$(KCFG)
	cp -f $(KDIR)/arch/arm64/boot/Image $(OUTPUT_DIR)
	cp -f $(KDIR)/arch/arm64/boot/dts/marvell/armada-3720-catdrive.dtb $(OUTPUT_DIR)
	tar --owner=root --group=root -cJf $(OUTPUT_DIR)/modules.tar.xz -C $(STAGE_DIR) lib

dl_toolchain:
ifeq (,$(wildcard $(CUR_DIR)/$(TC).tar.xz))
	curl -O -L $(TCURL)/$(TC).tar.xz
	tar xf $(TC).tar.xz
else ifeq (,$(wildcard $(CUR_DIR)/$(TC)))
	tar xf $(TC).tar.xz
endif

dl_kernel:
ifeq (,$(wildcard $(CUR_DIR)/$(KTAGS).tar.gz))
	curl -O -L $(KURL)/$(KTAGS).tar.gz
	tar xf $(KTAGS).tar.gz
	rm -rf $(KDIR)/.git
else ifeq (,$(wildcard $(CUR_DIR)/$(KDIR)))
	tar xf $(KTAGS).tar.gz
	rm -rf $(KDIR)/.git
endif

patch: dl_kernel dl_toolchain
	find $(CUR_DIR)/patches -type f -print | sort | xargs -n 1 patch -d $(KDIR) -p1 -i

kernel-config:
	cp -f $(KCFG) $(KDIR)/arch/arm64/configs/

kernel_version: kernel-config
	$(MAKE_ARCH) kernelrelease

kernel: kernel-config
	$(MAKE_ARCH) $(KCFG)
	$(MAKE_ARCH) -j$(J) Image dtbs
	$(MAKE_ARCH) savedefconfig

modules: kernel-config
	rm -rf $(STAGE_DIR)
	$(MAKE_ARCH) -j$(J) modules
	$(MAKE_ARCH) INSTALL_MOD_STRIP=1 INSTALL_MOD_PATH=$(STAGE_DIR) modules_install
	rm -f $(STAGE_DIR)/lib/modules/$(KVER)/build $(STAGE_DIR)/lib/modules/$(KVER)/source

kernel_clean:
	$(MAKE_ARCH) clean
	find $(CUR_DIR)/patches -type f -print | sort -r | xargs -n 1 patch -d $(KDIR) -p1 -R -i

clean: kernel_clean
	rm -rf $(STAGE_DIR)
	rm -rf $(OUTPUT_DIR)/*
