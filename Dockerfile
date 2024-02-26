FROM docker.io/library/ubuntu:jammy

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update

##### apt-utils #####
RUN apt-get install -y apt-utils

##### os libs #####
RUN apt-get install -y software-properties-common linux-tools-common linux-tools-generic

##### common tools #####
RUN apt-get install -y net-tools build-essential wget pkg-config unzip pip

##### dev tools #####
RUN apt-get install -y vim git cmake ninja-build libtool ccache

### clang
RUN wget https://github.com/llvm/llvm-project/releases/download/llvmorg-17.0.6/clang+llvm-17.0.6-x86_64-linux-gnu-ubuntu-22.04.tar.xz
RUN tar -xf clang+llvm-17.0.6-x86_64-linux-gnu-ubuntu-22.04.tar.xz
RUN mv clang+llvm-17.0.6-x86_64-linux-gnu-ubuntu-22.04 /opt/clang+llvm
RUN update-alternatives --install /usr/bin/clang clang /opt/clang+llvm/bin/clang 101
RUN update-alternatives --install /usr/bin/clang++ clang++ /opt/clang+llvm/bin/clang++ 101
RUN update-alternatives --install /usr/bin/clang-tidy clang-tidy /opt/clang+llvm/bin/clang-tidy 101
RUN update-alternatives --install /usr/bin/clang-format clang-format /opt/clang+llvm/bin/clang-format 101

### cmakelang
RUN pip install cmakelang

### common libs
RUN apt-get install -y zlib1g-dev libssl-dev librange-v3-dev libcurl4-gnutls-dev

### velox deps
RUN apt-get install -y libsnappy-dev liblz4-dev liblzo2-dev libzstd-dev libre2-dev bison flex libfl-dev

##### third-party tools & baselines

### arrow 
RUN pip install pyarrow

### duckdb
RUN pip install duckdb

### benchmark related libs. 
RUN pip install matplotlib