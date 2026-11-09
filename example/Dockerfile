FROM nvidia/cuda:11.7.0-base-ubuntu20.04
ARG DEBIAN_FRONTEND=nointeractive
ENV LANG C.UTF-8
RUN apt-get update && apt-get install -y git
RUN apt-get install -y software-properties-common
RUN apt-get update
RUN apt-get install -y gcc-8 g++-8
ENV CXX=/usr/bin/g++-8
ENV CC=/usr/bin/gcc-8

# ==================================================================
# create working directories
# ------------------------------------------------------------------
ENV WORKSPACE=/raisim_ws
RUN mkdir -p $WORKSPACE

# ==================================================================
# tools
# ------------------------------------------------------------------
RUN apt-get install -y cmake python3.9-dev python3-pip libpython3.9-dev libeigen3-dev vim

# ==================================================================
# raisimLib
# ------------------------------------------------------------------
RUN cd $WORKSPACE && git clone https://github.com/raisimTech/raisimLib.git

# ===================================================================
# docker-speicific
# ------------------------------------------------------------------
RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get install -y --no-install-recommends \
        libxau6 libxau6:i386 \
        libxdmcp6 libxdmcp6:i386 \
        libxcb1 libxcb1:i386 \
        libxext6 libxext6:i386 \
        libx11-6 libx11-6:i386 && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 6006
