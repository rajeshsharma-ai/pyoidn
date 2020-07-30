FROM ubuntu:18.04 AS build
WORKDIR /home

# This Dockerfile's base image has a non-root user with sudo access. Use the "remoteUser"
# property in devcontainer.json to use it. On Linux, the container user's GID/UIDs
# will be updated to match your local UID/GID (when using the dockerFile property).
# See https://aka.ms/vscode-remote/containers/non-root-user for details.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Configure apt and install packages
RUN apt-get update \
    #
    # Install C++ tools
    && apt-get -y install build-essential cmake python \
    #
    # [Optional] Update UID/GID if needed
    && if [ "$USER_GID" != "1000" ] || [ "$USER_UID" != "1000" ]; then \
        groupmod --gid $USER_GID $USERNAME \
        && usermod --uid $USER_UID --gid $USER_GID $USERNAME \
        && chown -R $USER_UID:$USER_GID /home/$USERNAME; \
    fi \
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=dialog

# COMMON BUILD TOOLS
ENV DEBIAN_FRONTEND=noninteractive
# hadolint ignore=DL3009
RUN apt-get update && apt-get install -y -q --no-install-recommends build-essential autoconf make git wget pciutils cpio libtool lsb-release ca-certificates pkg-config bison flex libcurl4-gnutls-dev zlib1g-dev cppcheck valgrind

# Build ISPC
ARG ISPC_VER=1.13.0
ARG ISPC_REPO=https://github.com/ispc/ispc/releases/download/v1.13.0/ispc-v1.13.0-linux.tar.gz
#ARG ISPC_REPO=https://downloads.sourceforge.net/project/ispcmirror/v${ISPC_VER}/ispc-v${ISPC_VER}-linux.tar.gz
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN wget -O - ${ISPC_REPO} | tar xz
ENV ISPC_EXECUTABLE=/home/ispc-v${ISPC_VER}-linux/ispc


# Build cmake, automake, NASM, YASM
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y -q --no-install-recommends cmake automake yasm nasm && \
    apt-get clean       && \
    rm -rf /var/lib/apt/lists/*

# Build TBB
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y -q --no-install-recommends libtbb-dev && \
    apt-get clean       && \
    rm -rf /var/lib/apt/lists/*

# python-dev, pybind11, numpy
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y -q --no-install-recommends python-dev python-pybind11 python-numpy   && \
apt-get clean   && \
rm -rf /var/lib/apt/lists/*

# tiff, zlib, png, jpeg, boost
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y -q --no-install-recommends libtiff-dev zlib1g-dev libpng-dev libjpeg-dev libboost-python-dev libboost-filesystem-dev libboost-thread-dev  && \
apt-get clean   && \
rm -rf /var/lib/apt/lists/*

# gitLFS
#RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y -q --no-install-recommends git-lfs  && \
#apt-get clean   && \
#rm -rf /var/lib/apt/lists/*

# OpenEXR, OpenImageIO
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y -q --no-install-recommends libopenexr-dev openexr libopenimageio-dev   && \
apt-get clean   && \
rm -rf /var/lib/apt/lists/*

# upgrade pip
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y -q --no-install-recommends python3-pip   && \
apt-get clean   && \
rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --upgrade pip

# install numpy and imageio
RUN pip install numpy && \
    pip install imageio

# OpenImageDenosiser
ARG Oidn_REPO=https://github.com/OpenImageDenoise/oidn.git
RUN git lfs install; \
    git clone --recursive ${Oidn_REPO}; \
    mkdir oidn/build; \
    cd oidn/build; \
    cmake -DISPC_EXECUTABLE:STRING=/home/ispc-v${ISPC_VER}-linux/ispc ..; \
    make -j 4; \
    make install

#RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y -q --no-install-recommends libglfw3-dev libgl1-mesa-dri libxrandr-dev  libxinerama-dev libxcursor-dev  && \
#apt-get clean  && \
#rm -rf /var/lib/apt/lists/*

#RUN apt-get update && apt-get install -y -q --no-install-recommends libglfw3-dev libgl1-mesa-dri libxrandr-dev  libxinerama-dev libxcursor-dev libmpich-dev mpich openssh-server openssh-client        && \
#    apt-get clean      && \
#    rm -rf /var/lib/apt/lists/*


SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN mkdir -p /var/run/sshd; \
    sed -i 's/^#Port/Port/g' /etc/ssh/sshd_config; \
    sed -i 's/^Port 22/Port 2222/g' /etc/ssh/sshd_config; \
    sed -i 's/^#PermitRootLogin/PermitRootLogin/g' /etc/ssh/sshd_config; \
    sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config; \
    sed -i 's/#   Port 22/Port 2222/g' /etc/ssh/ssh_config; \
    echo 'root:ospray' |chpasswd; \
    /usr/sbin/sshd-keygen; \
    sed -i 's/#   StrictHostKeyChecking ask/   StrictHostKeyChecking no/g' /etc/ssh/ssh_config; \
    /usr/bin/ssh-keygen -q -t rsa -N '' -f /root/.ssh/id_rsa; \
    cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys

FROM build
LABEL Description="This is the image for development on Ubuntu 18.04 LTS"
LABEL Vendor="xarmalarma"
WORKDIR /home
