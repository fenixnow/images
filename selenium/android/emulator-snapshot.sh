#!/bin/bash
MAX_ATTEMPTS=5
adb root
adb kill-server
sleep 60
adb start-server
adb devices | grep emulator | cut -f1 | while read id; do
    apks=(/usr/bin/*.apk)
    for apk in "${apks[@]}"; do
        if [ -r "$apk" ]; then
            for i in `seq 1 ${MAX_ATTEMPTS}`; do
                echo "Installing $apk (attempt #$i of $MAX_ATTEMPTS)"
                adb -s "$id" install -r "$apk" && break || sleep 60 && echo "Retrying to install $apk"
                adb shell am start -n ru.vkusvill/ru.vkusvill.ui.screens.splash.SplashActivity && break || sleep 30
                adb shell am force-stop ru.vkusvill
            done
        fi
    done
    adb -s "$id" emu kill -2 || true
done
rm -f /tmp/.X99-lock || true
