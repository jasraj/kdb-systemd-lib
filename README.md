# Shared Library for systemd Notification Interface

This repository provides a shared library that can be used to communicate with `systemd` to notify it of the lifecycle of a kdb process or application.

For more information on the `systemd` notification mechanism, see [the systemd documentation](https://www.freedesktop.org/software/systemd/man/sd_notify.html).

The related kdb library that uses this shared object can be found here - [https://github.com/jasraj/kdb-systemd](https://github.com/jasraj/kdb-systemd).

## Compiling

### Pre-requisites

To compile this project, you must ensure the following packages are available on your build server (along with the standard build tools):

* libsystemd-dev

If you want to build the shared object for 32-bit kdb as well as 64-bit kdb processes, ensure the following packages are available:

* libsystemd-dev:i386
* gcc-multilib
* g++-multilib

If you are using Ubuntu, you'll need to explicitly enable 32-bit library installation:

```
> dpkg --add-architecture i386
> apt-get update
```

### Compilation

To compile, use `make`:

```
# Compile the 32 and 64-bit versions of the shared library
make all

# Only compile the 64-bit version
make build_init build_lib_64
```

The build output folder can be customised by specifying a target folder in the environment variable `KSL_OUT`.
