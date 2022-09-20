#!/usr/bin/env bash
for CPU in $(seq 0 $(($(nproc) - 1))); do
    echo $1 > /sys/devices/system/cpu/cpu"$CPU"/cpufreq/scaling_governor
    cat /sys/devices/system/cpu/cpu"$CPU"/cpufreq/scaling_governor
done
