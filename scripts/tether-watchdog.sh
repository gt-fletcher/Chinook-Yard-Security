#!/bin/sh

# Safe tether watchdog
# Verifies adb availability, Pixel tether state, and link reachability.
#/root/tether-watchdog.sh

LOGTAG="tether-watchdog"
FAIL_THRESHOLD=3
fail_count=0

log() {
    logger -t $LOGTAG "$1"
}

while true; do
    # Check adb device presence first
    device=$(adb devices | awk 'NR>1 && $2=="device" {print $1}')
    if [ -z "$device" ]; then
        log "Pixel not detected via adb. Attempting recovery..."
        sleep 5
        continue
    fi

    # Check reachability of internet
    if ping -c1 -W3 8.8.8.8 >/dev/null 2>&1; then
        fail_count=0
    else
        fail_count=$((fail_count+1))
        log "No internet detected (fail_count=${fail_count})"

        if [ "$fail_count" -ge "$FAIL_THRESHOLD" ]; then
            log "Attempting USB tether reset via adb"

            adb shell svc usb setFunctions none
            sleep 2
            adb shell svc usb setFunctions rndis,adb

            fail_count=0
            sleep 10
        fi
    fi

    sleep 15
done
