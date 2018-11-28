# Makefile - kdb Integration with systemd Nofication Mechanism
# Copyright (c) 2018 Jaskirat Rajasansir

CC = g++
PROG = libkdbsystemd.so

ifeq (${KSL_SRC},)
  CPP_SRC = $(CURDIR)/src
else
  CPP_SRC = ${KSL_SRC}
endif

ifeq (${KSL_OUT},)
  CPP_OUT_ROOT = $(CURDIR)/build
else
  CPP_OUT_ROOT = ${KSL_OUT}
endif

CPP_OUT_32 = $(CPP_OUT_ROOT)/lib
CPP_OUT_64 = $(CPP_OUT_ROOT)/lib64

CPP_FLAGS = -v -std=c++11 -shared -fPIC -DKXVER=3 -I. -lsystemd


all: build_init build_lib_64 build_lib_32

build_init:
	mkdir -pv $(CPP_OUT_32) $(CPP_OUT_64)

build_lib_64:
	$(CC) $(CPP_FLAGS) $(CPP_SRC)/*.cpp -o $(CPP_OUT_64)/$(PROG)

build_lib_32:
	$(CC) $(CPP_FLAGS) -m32 $(CPP_SRC)/*.cpp -o $(CPP_OUT_32)/$(PROG)

clean:
	rm -rfv $(CPP_OUT_ROOT)


# vim: noexpandtab
