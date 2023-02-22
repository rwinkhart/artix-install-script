#!/usr/bin/env bash
qdbus org.freedesktop.ScreenSaver /ScreenSaver Lock
doas /usr/local/bin/plasmablank-root.sh
