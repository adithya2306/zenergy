# SPDX-License-Identifier: GPL-2.0
#
# Makefile for AMD Energy driver
#
# Copyright (C) 2021 Advanced Micro Devices, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2

# If KDIR is not specified, assume the development source link
# is in the modules directory for the running kernel
KDIR ?= /lib/modules/$(shell uname -r)/build
obj-m := zenergy.o

# Use LLVM toolchain if the target kernel was built with clang
ifeq ($(shell grep -s 'CONFIG_CC_IS_CLANG=y' $(KDIR)/.config),CONFIG_CC_IS_CLANG=y)
LLVM ?= 1
endif

DKMS_NAME := zenergy
DKMS_VERSION := 0.1.0
DKMS_ROOT := /usr/src/$(DKMS_NAME)-$(DKMS_VERSION)

default:
	export CONFIG_SENSOR_zenergy=m;	\
	$(MAKE) -C $(KDIR) M=$$PWD modules $(if $(LLVM),LLVM=$(LLVM))

modules: default

modules_install:
	$(MAKE) -C $(KDIR) M=$$PWD modules_install

dkms_install:
	mkdir -p $(DKMS_ROOT)
	cp Makefile dkms.conf zenergy.c $(DKMS_ROOT)/
	sed -i "s/@VERSION@/$(DKMS_VERSION)/" $(DKMS_ROOT)/dkms.conf
	dkms add $(DKMS_NAME)/$(DKMS_VERSION)
	dkms build $(DKMS_NAME)/$(DKMS_VERSION)
	dkms install $(DKMS_NAME)/$(DKMS_VERSION)

dkms_uninstall:
	dkms uninstall $(DKMS_NAME)/$(DKMS_VERSION) || true
	dkms remove $(DKMS_NAME)/$(DKMS_VERSION) --all || true
	rm -rf $(DKMS_ROOT)

clean:
	$(MAKE) -C $(KDIR) M=$$PWD clean

help:
	@echo "\nThe following make targets are supported:\n"
	@echo "default\t\tBuild the driver module (or if no make target is supplied)"
	@echo "modules\t\tSame as default"
	@echo "modules_install\tBuild and install the driver module"
	@echo "dkms_install\tInstall the driver via DKMS"
	@echo "dkms_uninstall\tUninstall and remove the driver from DKMS"
	@echo "clean"
	@echo

.PHONY: default modules modules_install dkms_install dkms_uninstall clean help

