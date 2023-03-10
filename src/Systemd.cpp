// kdb Integration with systemd Nofication Mechanism
// Copyright (c) 2018 Jaskirat Rajasansir

#include "kx-c-lib/c/c/k.h"

#include <string>
#include <iostream>

#include <unistd.h>

#include <systemd/sd-daemon.h>


// Definitions of strings that are sent to systemd are defined at
//      https://www.freedesktop.org/software/systemd/man/sd_notify.html


namespace kdbsystemd {

// systemd string to signal process is ready
const std::string isReady = std::string("READY=1");

// systemd string to signal process is stopping
const std::string isStopping = std::string("STOPPING=1");

// systemd string to signal process is heartbeating
const std::string isWatchdog = std::string("WATCHDOG=1");

// systemd string prefix to publish information to systemd
const std::string isStatusPrefix = std::string("STATUS=");

// systemd string prefix to publish the main PID
const std::string mainPidPrefix = std::string("MAINPID=");

// systemd string prefix to publish timeout extension
const std::string extendTimeoutPrefix = std::string("EXTEND_TIMEOUT_USEC=");

// Multiplier to convert between milliseconds and nanoseconds
const uint64_t msToNano = 1000000;


// Notifies that the current process is ready
//  @see sd_pid_notify
//  @see getpid
//  @see isReady
void notifyReady() {
    sd_pid_notify(getpid(), 0, isReady.c_str());
}

// Notifies that the current process is stopping
void notifyStopping() {
    sd_pid_notify(getpid(), 0, isStopping.c_str());
}

// Queries the interval that systemd is expecting heartbeat messages (watchdog's) to be sent from the process
//  @return The interval in milliseconds
//  @see sd_watchdog_enabled
int notifyGetIntervalMs() {
    uint64_t sdInterval;

    int sdRes = sd_watchdog_enabled(0, &sdInterval);

    if(sdRes == 0)
        return 0;

    return sdInterval / 1000;
}

// Sends a heartbeat to systemd
void notifyWatchdog() {
    sd_pid_notify(getpid(), 0, isWatchdog.c_str());
}

// Sends a generic status string to systemd as an update of its internal state
//  @param status A status
//  @see isStatusPrefix
//  @see sd_pid_notify
//  @see getpid
void notifyStatus(std::string status) {
    std::string statusPrefix = std::string(isStatusPrefix);
    sd_pid_notify(getpid(), 0, statusPrefix.append(status).c_str());
}

// Sends the specified PID of the service to systemd in case the service manager did not fork off the process itself
void sendMainPid(int pid) {
    std::string mainPidStr = std::string(mainPidPrefix);
    sd_pid_notify(getpid(), 0, mainPidStr.append(std::to_string(pid)).c_str());
}

// Allows the kdb process to extend the amount of time taken to transition the process (e.g. during process start, before ready to check TP log file)
//  @param extendTimeUs The time extension required in microseconds
void extendTimeout(int extendTimeUs) {
    std::string timeoutStr = std::string(extendTimeoutPrefix);
    sd_pid_notify(getpid(), 0, timeoutStr.append(std::to_string(extendTimeUs)).c_str());
}

}   // namespace kdbsystemd


extern "C" K sendReady(K nullArg) {
    kdbsystemd::notifyReady();
    return kb(1);
}

extern "C" K sendStopping(K nullArg) {
    kdbsystemd::notifyStopping();
    return kb(1);
}

extern "C" K getInterval(K nullArg) {
    int interval = kdbsystemd::notifyGetIntervalMs();
    return ktj(-KN, interval * kdbsystemd::msToNano);
}

extern "C" K sendWatchdog(K nullArg) {
    if(kdbsystemd::notifyGetIntervalMs() == 0)
        return krr((char*) "[lib-kdbsystemd] systemd watchdog is not enabled. No heartbeating required");

    kdbsystemd::notifyWatchdog();
    return kb(1);
}

extern "C" K sendStatus(K status) {
    std::string statusStr;

    if(status->t == -KS)
        statusStr = std::string(status->s);
    else if(status->t == KC)
        statusStr = std::string((const char*) kC(status), status->n);
    else
        return krr((char*) "[lib-kdbsystemd] Incorrect type for status. Must be symbol or string");

    if(statusStr.empty())
        return krr((char*) "[lib-kdbsystemd] No status specified");

    kdbsystemd::notifyStatus(statusStr);
    return kb(1);
}

extern "C" K sendMainPid(K intOrNullArg) {
    int pid = getpid();

    if(intOrNullArg->t != -KI)
        pid = intOrNullArg->i;

    kdbsystemd::sendMainPid(pid);
    return kb(1);
}

extern "C" K extendTimeout(K timespan) {
    int timeoutUs;

    if(timespan->t == -KN)
        timeoutUs = timespan->j / 1000;
    else
        return krr((char*) "[lib-kdbsystemd] Incorrect type for start timeout extension. Must be timespan");

    if(timeoutUs <= 0)
        return krr((char*) "[lib-kdbsystemd] Incorrect value for start timeout extension. Must be greater than 0 us");

    kdbsystemd::extendTimeout(timeoutUs);
    return kb(1);
}
