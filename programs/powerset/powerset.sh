#!/bin/sh
for CPU in $(seq 0 $(($(nproc) - 1))); do
    printf $1 > /sys/devices/system/cpu/cpu"$CPU"/cpufreq/scaling_governor
    cat /sys/devices/system/cpu/cpu"$CPU"/cpufreq/scaling_governor
done
