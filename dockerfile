
# Setup Android SDK
# https://doc.qt.io/qt-6/android-getting-started.html

FROM debian:bullseye-backports as android-sdk

RUN apt-get --quiet update &&\
    apt-get --quiet install -y openjdk-11-jdk &&\
    rm -rf /var/lib/apt/lists/*
ENV JAVA_HOME /usr/lib/jvm/java-11-openjdk-amd64

ENV NDK_VERSION 23.2.8568313
RUN apt-get --quiet update &&\
    apt-get --quiet install -y wget unzip &&\
    rm -rf /var/lib/apt/lists/* &&\
    wget -nc -O /tmp/commandlinetools.zip https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip &&\
    unzip -o /tmp/commandlinetools.zip -d /usr/lib/android-sdk &&\
    rm /tmp/commandlinetools.zip &&\
    (yes | /usr/lib/android-sdk/cmdline-tools/bin/sdkmanager --sdk_root=/usr/lib/android-sdk --licenses || true) &&\
    /usr/lib/android-sdk/cmdline-tools/bin/sdkmanager --sdk_root=/usr/lib/android-sdk --install "platform-tools" "platforms;android-26" "build-tools;31.0.0" "ndk;$NDK_VERSION" &&\
    rm -rf /usr/lib/android-sdk/build-tools/debian
ENV ANDROID_HOME /usr/lib/android-sdk/
ENV ANDROID_NDK_HOME /usr/lib/android-sdk/ndk/$NDK_VERSION/


FROM android-sdk
SHELL ["bash", "-c"]
RUN apt-get --quiet update &&\
    apt-get --quiet install -y git &&\
    rm -rf /var/lib/apt/lists/*
RUN cd / && git clone --depth=1 https://github.com/project-chip/connectedhomeip.git
RUN apt-get --quiet update &&\
    apt-get --quiet install -y python3-full python3-pip libgirepository-1.0-1 pkgconf libglib2.0-dev &&\
    rm -rf /var/lib/apt/lists/*
RUN cd /connectedhomeip &&\
    git rm -r third_party/openthread/ot-* third_party/ti_simplelink_sdk third_party/mt793x_sdk &&\
    sed -i 's/git submodule update$/git submodule update --depth 1/g' scripts/bootstrap.sh &&\
    sed -i 's/git submodule update --init$/git submodule update --init --depth 1/g' scripts/bootstrap.sh &&\
    source scripts/bootstrap.sh
RUN apt-get --quiet update &&\
    apt-get --quiet install -y curl &&\
    rm -rf /var/lib/apt/lists/*
RUN cd /connectedhomeip &&\
    ./third_party/java_deps/set_up_java_deps.sh
ENV TARGET_CPU arm64
RUN cd /connectedhomeip &&\
    ./scripts/examples/android_app_ide.sh

RUN apt-get --quiet update &&\
    apt-get --quiet install -y cmake ninja-build &&\
    rm -rf /var/lib/apt/lists/*
WORKDIR /src
