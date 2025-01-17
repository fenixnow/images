FROM golang:1.20 as go

EXPOSE 5900

COPY tmp/devtools /devtools

RUN \
    apt-get update && \
    apt-get install -y upx-ucl libx11-dev && \
    cd /devtools && \
    GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" && \
    upx /devtools/devtools

FROM ubuntu:20.04

ARG APPIUM_VERSION="2.0.0-beta.66"

RUN \
    apt update && \
    apt install -y apt-transport-https ca-certificates tzdata locales curl gnupg && \
    	curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
	apt install -y --no-install-recommends \
	    curl \
	    iproute2 \
	    openjdk-11-jdk \
	    unzip \
	    xvfb \
	    wget \
	    nodejs \
	    libpulse0 \
		libxcomposite1 \
		libxcursor1 \
		libxi6 \
		libasound2 \
        fluxbox \
        x11vnc \
        feh \
        wmctrl \
	    libglib2.0-0 && \
    apt-get clean && \
    rm -Rf /tmp/* && rm -Rf /var/lib/apt/lists/*

RUN npm install -g npm@latest && npm install -g appium@$APPIUM_VERSION
RUN appium driver install uiautomator2

# COPY android.conf /etc/ld.so.conf.d/
COPY fluxbox/aerokube /usr/share/fluxbox/styles/
COPY fluxbox/init /root/.fluxbox/
COPY fluxbox/aerokube.png /usr/share/images/fluxbox/
COPY --from=go /devtools/devtools /usr/bin/

# Android SDK
ENV ANDROID_HOME /opt/android-sdk
ENV ANDROID_SDK_ROOT $ANDROID_HOME
ENV PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/tools/bin
ENV PATH ${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/emulator:$PATH
ENV LD_LIBRARY_PATH ${ANDROID_HOME}/emulator/lib64:${ANDROID_HOME}/emulator/lib64/gles_swiftshader:${ANDROID_HOME}/emulator/lib64/qt/lib:${ANDROID_HOME}/emulator/lib64/vulkan:${LD_LIBRARY_PATH}
ENV VK_ICD_FILENAMES ${ANDROID_HOME}/emulator/lib64/vulkan/vk_swiftshader_icd.json:${VK_ICD_FILENAMES}

ARG ANDROID_DEVICE="Nexus 4"
ARG ANDROID_SKIN="nexus_4"
ARG REPLACE_IMG="y"
ARG AVD_NAME="android11.0-1"
ARG BUILD_TOOLS="build-tools;34.0.0-rc4"
ARG PLATFORM="android-30"
ARG EMULATOR_IMAGE="system-images;android-30;default;x86"
ARG EMULATOR_IMAGE_TYPE="default"
ARG ANDROID_ABI="x86"
ARG SDCARD_SIZE="64"
ARG USERDATA_SIZE="64"

RUN SDK_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip" && \
	mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
	mkdir ${ANDROID_SDK_ROOT}/platforms && \
	wget -O cmdline-tools.zip -t 5 "${SDK_TOOLS_URL}" && \
	unzip -q cmdline-tools.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools && \
	mv "${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools" "${ANDROID_SDK_ROOT}/cmdline-tools/tools" && \
	rm cmdline-tools.zip
	
RUN echo y | sdkmanager --licenses
RUN echo y | sdkmanager "emulator"
RUN echo y | sdkmanager "cmdline-tools;latest" "platform-tools"
RUN echo y | sdkmanager "$BUILD_TOOLS"
RUN echo y | sdkmanager "platforms;$PLATFORM"
RUN echo y | sdkmanager "$EMULATOR_IMAGE"

COPY skins/ $ANDROID_HOME/skins/

RUN mksdcard "$SDCARD_SIZE"M sdcard.img
RUN \	
	echo "no" | ( \
		avdmanager create avd -n "$AVD_NAME" -k "$EMULATOR_IMAGE" --abi "$ANDROID_ABI" --device "$ANDROID_DEVICE" --skin "$ANDROID_SKIN" --sdcard /sdcard.img \
		# ([ -n "$ANDROID_DEVICE" ] && avdmanager create avd -n "$AVD_NAME" -k "$EMULATOR_IMAGE" --abi "$ANDROID_ABI" --device "$ANDROID_DEVICE" --skin "$ANDROID_SKIN" --sdcard /sdcard.img ) || \
	    # avdmanager create avd -n "$AVD_NAME" -k "$EMULATOR_IMAGE" --abi "$ANDROID_ABI" --sdcard /sdcard.img \
	) && \ 
	ldconfig && \
	( \
	    resize2fs /root/.android/avd/$AVD_NAME.avd/userdata.img "$USERDATA_SIZE"M || \
	    ${ANDROID_SDK_ROOT}/emulator/qemu-img resize -f raw /root/.android/avd/$AVD_NAME.avd/userdata.img "$USERDATA_SIZE"M \
    ) && \
	([ -z "$REPLACE_IMG" ] || mv /root/.android/avd/$AVD_NAME.avd/userdata.img /root/.android/avd/$AVD_NAME.avd/userdata-qemu.img ) && \
	rm ${ANDROID_SDK_ROOT}/system-images/$PLATFORM/$EMULATOR_IMAGE_TYPE/"$ANDROID_ABI"/userdata.img

# modify config.ini
RUN \
	sed -i 's/hw.mainKeys=yes/hw.mainKeys=no/g' /root/.android/avd/$AVD_NAME.avd/config.ini	&& \
	sed -i 's/hw.keyboard=no/hw.keyboard=yes/g' /root/.android/avd/$AVD_NAME.avd/config.ini
	# echo 'skin.dynamic=yes' >> /root/.android/avd/$AVD_NAME.avd/config.ini && \
	# echo 'skin.name=nexus_4' >> /root/.android/avd/$AVD_NAME.avd/config.ini && \
	# echo 'skin.path=/opt/android-sdk/skins/nexus_4' >> /root/.android/avd/$AVD_NAME.avd/config.ini

COPY ["Emulator.conf", "/root/.config/Android Open Source Project/Emulator.conf"]
COPY emulator-snapshot.sh tmp/chromedriver* *.apk /usr/bin/

# Entrypoint
COPY tmp/entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
