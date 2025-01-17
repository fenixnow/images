#!/bin/bash
CHROMEDRIVER_PORT=9515
BOOTSTRAP_PORT=4725
EMULATOR=emulator-5554
APPIUM_ARGS=${APPIUM_ARGS:-""}
EMULATOR_ARGS=${EMULATOR_ARGS:-""}
PORT=${PORT:-"4444"}
DISPLAY_NUM=99
export DISPLAY=":$DISPLAY_NUM"
SCREEN_RESOLUTION=${SCREEN_RESOLUTION:-"1920x1080x24"}
SKIN=${SKIN:-"nexus_4"}
STOP=""
VERBOSE=${VERBOSE:-""}
ENABLE_VNC="true"

if [ -z "$VERBOSE" ]; then
    if [ -z "$APPIUM_ARGS" ]; then
        APPIUM_ARGS="--log-level error"
    fi
else
    EMULATOR_ARGS="$EMULATOR_ARGS -verbose"
fi


clean() {
  STOP="yes"
  if [ -n "$APPIUM_PID" ]; then
    kill -TERM "$APPIUM_PID"
  fi
  if [ -n "$EMULATOR_PID" ]; then
    kill -TERM "$EMULATOR_PID"
  fi
  if [ -n "$X11VNC_PID" ]; then
    kill -TERM "$X11VNC_PID"
  fi
  if [ -n "$DEVTOOLS_PID" ]; then
    kill -TERM "$DEVTOOLS_PID"
  fi
  if [ -n "$XVFB_PID" ]; then
    kill -TERM "$XVFB_PID"
  fi
}

trap clean SIGINT SIGTERM

/usr/bin/xvfb-run -e /dev/stdout -l -n "$DISPLAY_NUM" -s "-ac -screen 0 $SCREEN_RESOLUTION -noreset -listen tcp" /usr/bin/fluxbox -display "$DISPLAY" -log /tmp/fluxbox.log 2>/dev/null &
XVFB_PID=$!

retcode=1
until [ $retcode -eq 0 ] || [ -n "$STOP" ]; do
  DISPLAY="$DISPLAY" wmctrl -m >/dev/null 2>&1
  retcode=$?
  if [ $retcode -ne 0 ]; then
    echo Waiting X server...
    sleep 0.1
  fi
done
if [ -n "$STOP" ]; then exit 0; fi

if [ "$ENABLE_VNC" != "true" ] && [ "$ENABLE_VIDEO" != "true" ]; then
    EMULATOR_ARGS="$EMULATOR_ARGS -no-window"
fi
# ANDROID_AVD_HOME=/root/.android/avd DISPLAY="$DISPLAY" emulator ${EMULATOR_ARGS} -change-language ru -timezone Europe/Moscow -verbose -writable-system -no-boot-anim -no-audio -no-snapshot-save -ranchu -avd @AVD_NAME@ -sdcard /sdcard.img -gpu swiftshader_indirect &
ANDROID_AVD_HOME=/root/.android/avd 
DISPLAY="$DISPLAY" 
emulator ${EMULATOR_ARGS} -verbose -avd @AVD_NAME@ -writable-system -gpu swiftshader_indirect -timezone Europe/Moscow -accel on &

EMULATOR_PID=$!

if [ "$ENABLE_VNC" == "true" ]; then
    x11vnc -display "$DISPLAY" -passwd selenoid -shared -forever -loop500 -rfbport 5900 -rfbportv6 5900 -logfile /tmp/x11vnc.log &
    X11VNC_PID=$!
fi

while [ "$(adb shell getprop sys.boot_completed | tr -d '\r')" != "1" ] && [ -z "$STOP" ] ; do sleep 1; done
if [ -n "$STOP" ]; then exit 0; fi

DEFAULT_CAPABILITIES='"platformName": "Android", "appium:automationName": "uiautomator2"'
if [ -n "@CHROME_MOBILE@" ]; then
    while ip addr | grep inet | grep -q tentative > /dev/null; do sleep 0.1; done
    DEFAULT_CAPABILITIES=$DEFAULT_CAPABILITIES', "chromedriverPort": '$CHROMEDRIVER_PORT
    /usr/bin/devtools --android &
    DEVTOOLS_PID=$!
fi

if [ -x "/usr/bin/chromedriver" ]; then
    DEFAULT_CAPABILITIES=$DEFAULT_CAPABILITIES',"chromedriverExecutable": "/usr/bin/chromedriver"'
fi

appium -p "$PORT" -cp "$BOOTSTRAP_PORT" --log-timestamp --log-no-colors ${APPIUM_ARGS} --default-capabilities "{$DEFAULT_CAPABILITIES}" &
APPIUM_PID=$!

wait
