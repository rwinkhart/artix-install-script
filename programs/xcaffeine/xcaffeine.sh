#!/usr/bin/env bash

# depends on X11, libpulse (compatible w/Pipewire&PulseAudio)

# START USER CHANGEABLE VARIABLES
# list of pactl search terms
pactl_search=('jellyfinmediaplayer' 'rpcs3')
# frequency to check for activity (in seconds)
timeout=290
# FINISH USER CHANGEABLE VARIABLES

while [ True ]; do
    sleep $timeout
    for term in ${pactl_search[@]}; do
        search_result=$(pactl list | grep $term)
        if [ ! -z "$search_result" ]; then
            echo "Whitelisted content ($term) is active, keeping screen alive..."
            xset s off -dpms
            sleep 5
            xset s on +dpms
        fi
    done
done
