#!/bin/sh

# set KONQUAKE_ID and KONQUAKE_STATUS
[ -f /tmp/konquakerc ] && . /tmp/konquakerc || { KONQUAKE_ID=1; KONQUAKE_STATUS=1; }

# if KONQUAKE_ID is associated with konsole
if [ "$(ps -p $KONQUAKE_ID -o comm=)" = 'konsole' ]; then
    # toggle konsole window
    if [ $KONQUAKE_STATUS -eq 0 ]; then
        # set custom window title (to match window rule)
        dbus-send --type=method_call --dest=org.kde.konsole-$KONQUAKE_ID /konsole/MainWindow_1 org.qtproject.Qt.QWidget.setWindowTitle string:konquake\ session
        # show konsole window
        dbus-send --type=method_call --dest=org.kde.konsole-$KONQUAKE_ID /konsole/MainWindow_1 org.qtproject.Qt.QWidget.show
        KONQUAKE_STATUS=1
    else
        # hide konsole window
        dbus-send --type=method_call --dest=org.kde.konsole-$KONQUAKE_ID /konsole/MainWindow_1 org.qtproject.Qt.QWidget.hide
        KONQUAKE_STATUS=0
    fi
else
    konsole -e zsh -c "printf $'\033]30;'konquake\ session$'\007' && exec zsh" &
    # update KONQUAKE_ID for newest konsole instance
    KONQUAKE_ID=$!
    sleep .2
    # hide konsole window
    dbus-send --type=method_call --dest=org.kde.konsole-$KONQUAKE_ID /konsole/MainWindow_1 org.qtproject.Qt.QWidget.hide
    # show konsole window
    dbus-send --type=method_call --dest=org.kde.konsole-$KONQUAKE_ID /konsole/MainWindow_1 org.qtproject.Qt.QWidget.show
fi

# update /tmp/konquakerc with status information
printf "export KONQUAKE_ID=$KONQUAKE_ID\nexport KONQUAKE_STATUS=$KONQUAKE_STATUS" > /tmp/konquakerc
