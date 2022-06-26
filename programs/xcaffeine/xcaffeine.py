#!/bin/python3

# external modules

from os import setuid, system
from pwd import getpwnam
from subprocess import Popen, PIPE, STDOUT
from time import sleep

# depends on X11, libpulse (compatible w/Pipewire&PulseAudio)

# START USER CHANGEABLE VARIABLES
# list of pactl search terms
pactl_search = ['jellyfinmediaplayer', 'rpcs3']
# frequency to check for activity (in seconds)
timeout = 290
# FINISH USER CHANGEABLE VARIABLES

# ensure running as correct user
setuid(1000)

while True:
    sleep(timeout)
    for search_term in pactl_search:
        command = f"pactl list | grep {search_term[:-1]}"
        output = Popen(command, shell=True, stdin=PIPE, stdout=PIPE, stderr=STDOUT, close_fds=True)
        block = output.communicate()[0].strip()  # blocks the program from proceeding until stdout is given
        if block.decode('utf-8').__contains__(search_term):
            print(f"Whitelisted content ({search_term}) is active, keeping screen alive...")
            system('xset s off -dpms')
            sleep(5)
            system('xset s on +dpms')
