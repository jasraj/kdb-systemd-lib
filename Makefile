# Makefile - kdb Integration with systemd Nofication Mechanism
# Copyright (c) 2018 Jaskirat Rajasansir

CC = gcc
PROG = libkdbsystemd.so

CPP_SRC = $(CURDIR)/src

CPP_OUT_ROOT = $(CURDIR)/build
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
