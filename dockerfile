FROM debian:bookworm-backports as android-sdk

# Setup Android SDK
# https://doc.qt.io/qt-6/android-getting-started.html
ENV NDK_VERSION 23.2.8568313
RUN apt --quiet update --yes &&\
    apt --quiet install --yes wget unzip android-sdk &&\
    rm -rf /var/lib/apt/lists/* &&\
    wget -nc -O /tmp/commandlinetools.zip https://dl.google.com/android/repository/commandlinetools-linux-8092744_latest.zip &&\
    unzip -o /tmp/commandlinetools.zip -d /usr/lib/android-sdk &&\
    rm /tmp/commandlinetools.zip &&\
    (yes | /usr/lib/android-sdk/cmdline-tools/bin/sdkmanager --sdk_root=/usr/lib/android-sdk --licenses || true) &&\
    /usr/lib/android-sdk/cmdline-tools/bin/sdkmanager --sdk_root=/usr/lib/android-sdk --install "platform-tools" "platforms;android-26" "build-tools;31.0.0" "ndk;$NDK_VERSION" &&\
    rm -rf /usr/lib/android-sdk/build-tools/debian

ENV ANDROID_HOME /usr/lib/android-sdk/
ENV ANDROID_NDK_HOME /usr/lib/android-sdk/ndk/$NDK_VERSION/

FROM android-sdk as dev-build
RUN apt --quiet update --yes &&\
    apt --quiet install --yes git &&\
    rm -rf /var/lib/apt/lists/*
WORKDIR /build
RUN git clone https://github.com/project-chip/connectedhomeip.git &&\
    cd connectedhomeip &&\
    source scripts/bootstrap.sh
ENV TARGET_CPU arm64
RUN cd connectedhomeip &&\
    ./scripts/examples/android_app_ide.sh

FROM android-sdk
COPY --from=dev-build /build/connectedhomeip /connectedhomeip
