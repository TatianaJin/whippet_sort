#!/bin/bash

root_dir=$(dirname $(realpath $0))
third_party_dir=${root_dir}/third_party
install_dir=${third_party_dir}/install

export CC=clang
export CXX=clang++

PARALLEL=12 # make parallelism
CMAKE_GENERATOR=Ninja
COMMON_CMAKE_FLAGS="-DCMAKE_BUILD_TYPE=Release \
                    -DCMAKE_C_COMPILER=$CC \
                    -DCMAKE_CXX_COMPILER=$CXX \
                    -DBUILD_SHARED_LIBS=OFF \
                    -DCMAKE_CXX_STANDARD=20 \
                    -DCMAKE_POSITION_INDEPENDENT_CODE=ON"

# boost
BOOST_DOWNLOAD="https://boostorg.jfrog.io/artifactory/main/release/1.78.0/source/boost_1_78_0.tar.gz"
BOOST_SOURCE=boost_1_78_0
BOOST_NAME=boost_1_78_0.tar.gz
BOOST_SHA256="94ced8b72956591c4775ae2207a9763d3600b30d9d7446562c552f0a14a63be7"
boost_install_dir=${install_dir}/boost

# double-conversion
DOUBLE_CONVERSION_DOWNLOAD="https://github.com/google/double-conversion/archive/refs/tags/v3.1.6.tar.gz"
DOUBLE_CONVERSION_SOURCE=double-conversion-3.1.6
DOUBLE_CONVERSION_NAME=double_conversion_3.1.6.tar.gz
DOUBLE_CONVERSION_SHA256="8a79e87d02ce1333c9d6c5e47f452596442a343d8c3e9b234e8a62fce1b1d49c"
double_conversion_install_dir=${install_dir}/double_conversion

# libevent
LIBEVENT_DOWNLOAD="https://github.com/libevent/libevent/releases/download/release-2.1.12-stable/libevent-2.1.12-stable.tar.gz"
LIBEVENT_SOURCE="libevent-2.1.12"
LIBEVENT_NAME="libevent-2.1.12.tar.gz"
LIBEVENT_SHA256="92e6de1be9ec176428fd2367677e61ceffc2ee1cb119035037a27d346b0403bb"
libevent_install_dir=${install_dir}/libevent

# fmt
FMTLIB_DOWNLOAD="https://github.com/fmtlib/fmt/archive/refs/tags/8.0.1.tar.gz"
FMTLIB_NAME="fmt-8.0.1.tar.gz"
FMTLIB_SOURCE="fmt-8.0.1"
FMTLIB_SHA256="b06ca3130158c625848f3fb7418f235155a4d389b2abc3a6245fb01cb0eb1e01"
fmt_install_dir=${install_dir}/fmt

# glog
GLOG_DOWNLOAD="https://github.com/google/glog/archive/v0.6.0.tar.gz"
GLOG_NAME="glog-0.6.0.tar.gz"
GLOG_SOURCE="glog-0.6.0"
GLOG_SHA256="8a83bf982f37bb70825df71a9709fa90ea9f4447fb3c099e1d720a439d88bad6"
glog_install_dir=${install_dir}/glog

# folly: deps on boost, double-conversion, libevent, fmt, glog
FOLLY_DOWNLOAD="https://github.com/facebook/folly/archive/refs/tags/v2022.11.14.00.tar.gz"
FOLLY_NAME=folly-v2022.11.14.00.tar.gz
FOLLY_SOURCE=folly-v2022.11.14.00
FOLLY_SHA256="b249436cb61b6dfd5288093565438d8da642b07ae021191a4042b221bc1bdc0e"
folly_install_dir=${install_dir}/folly

# arrow
ARROW_VERSION=release-15.0.0-rc0
arrow_install_dir=${install_dir}/arrow

check_if_source_exist() {
  if [ -z $1 ]; then
    echo "dir should specified to check if exist." && return 1
  fi
  if [ ! -d $1 ]; then
    echo "$1 does not exist." && return 1
  fi
  return 0
}

download() {
  download_uri=$1
  tar_file_name=$2
  target_folder_name=$3
  mkdir -p ${third_party_dir}/tmp_dir
  if wget --no-check-certificate $download_uri -O ${third_party_dir}/${tar_file_name}; then
    echo "downloaded ${third_party_dir}/${tar_file_name}"
  else
    echo "Failed to downloaded ${third_party_dir}/${tar_file_name}"
    exit 1
  fi
  tar xzf ${third_party_dir}/${tar_file_name} -C ${third_party_dir}/tmp_dir &&
    mv ${third_party_dir}/tmp_dir/* ${third_party_dir}/${target_folder_name} || exit
  echo extracted to ${third_party_dir}/${target_folder_name}
}

download_boost() {
  download $BOOST_DOWNLOAD $BOOST_NAME $BOOST_SOURCE
}

build_boost() {
  check_if_source_exist ${third_party_dir}/${BOOST_SOURCE} || download_boost
  pushd ${third_party_dir}/${BOOST_SOURCE}
  ./bootstrap.sh --prefix=${boost_install_dir} --with-toolset=clang
  ./b2 link=static runtime-link=static -j $PARALLEL \
    --without-mpi --without-graph --without-graph_parallel \
    --without-python cxxflags="-std=c++11 -g -fPIC \
    -I${install_dir} -L${install_dir}" install
  popd
}

download_double_conversion() {
  download $DOUBLE_CONVERSION_DOWNLOAD $DOUBLE_CONVERSION_NAME $DOUBLE_CONVERSION_SOURCE
}

build_double_conversion() {
  check_if_source_exist ${third_party_dir}/${DOUBLE_CONVERSION_SOURCE} || download_double_conversion
  pushd ${third_party_dir}/${DOUBLE_CONVERSION_SOURCE}
  mkdir -p __build && cd __build
  bash -c "cmake $COMMON_CMAKE_FLAGS -DCMAKE_INSTALL_PREFIX=${double_conversion_install_dir} .."
  make --jobs=${PARALLEL} install
}

download_libevent() {
  download $LIBEVENT_DOWNLOAD $LIBEVENT_NAME $LIBEVENT_SOURCE
}

build_libevent() {
  check_if_source_exist ${third_party_dir}/${LIBEVENT_SOURCE} || download_libevent
  pushd ${third_party_dir}/${LIBEVENT_SOURCE}
  mkdir -p __build && cd __build
  pwd
  bash -c "cmake $COMMON_CMAKE_FLAGS \
        -DCMAKE_INSTALL_PREFIX=${libevent_install_dir} \
        -DEVENT__DISABLE_TESTS=ON  \
        -DEVENT__DISABLE_BENCHMARK=ON \
        -DEVENT__DISABLE_SAMPLES=ON  \
        -DEVENT__DISABLE_REGRESS=ON  \
        -DEVENT__LIBRARY_TYPE=STATIC \
        .."
  make --jobs=${PARALLEL} install
  popd
}

download_fmt() {
  download $FMTLIB_DOWNLOAD $FMTLIB_NAME $FMTLIB_SOURCE
}

build_fmt() {
  check_if_source_exist ${third_party_dir}/${FMTLIB_SOURCE} || download_fmt
  pushd ${third_party_dir}/${FMTLIB_SOURCE}
  mkdir -p __build && cd __build
  bash -c "cmake $COMMON_CMAKE_FLAGS -DCMAKE_INSTALL_PREFIX=${fmt_install_dir} -DFMT_TEST=OFF .."
  make --jobs=${PARALLEL} install
  popd
}

download_glog() {
  download $GLOG_DOWNLOAD $GLOG_NAME $GLOG_SOURCE
}

build_glog() {
  check_if_source_exist ${third_party_dir}/${GLOG_SOURCE} || download_glog
  pushd ${third_party_dir}/${GLOG_SOURCE}
  mkdir -p __build && cd __build
  bash -c "cmake $COMMON_CMAKE_FLAGS -DCMAKE_INSTALL_PREFIX=${glog_install_dir} \
        -DBUILD_STATIC_LIBS=OFF -DBUILD_SHARED_LIBS=ON \
        .."
  make --jobs=${PARALLEL} install
}

download_folly() {
  download $FOLLY_DOWNLOAD $FOLLY_NAME $FOLLY_SOURCE
}

build_folly_deps() {
  ### This built-in deps script does not work well, manually install the deps
  # pushd ${third_party_dir}/${FOLLY_SOURCE}
  # ./build/fbcode_builder/getdeps.py --allow-system-packages build --install-prefix=${folly_install_dir} mvfst
  # popd
  FOLLY_DEPS="boost double_conversion libevent fmt glog"
  for dep in ${FOLLY_DEPS[*]}; do
    dep_install_dir=$dep"_install_dir"
    if [ ! -d ${!dep_install_dir} ]; then
      echo "[===== Building ${dep} for folly deps =====]"
      build_$dep || return 1
    fi
  done
  return 0
}

build_folly() {
  check_if_source_exist ${third_party_dir}/${FOLLY_SOURCE} || download_folly
  build_folly_deps && echo "-------------- Built all deps --------------" || (echo "Error building folly deps" && exit 1)
  mkdir -p ${third_party_dir}/${FOLLY_SOURCE}/__build
  pushd ${third_party_dir}/${FOLLY_SOURCE}/__build
  source ${root_dir}/velox/scripts/setup-helper-functions.sh
  compiler_flags=\"$(get_cxx_flags "unknown")\"
  bash -c "cmake $COMMON_CMAKE_FLAGS \
      -DCMAKE_INSTALL_PREFIX=${folly_install_dir} \
      -DCMAKE_PREFIX_PATH=${boost_install_dir} -DCMAKE_PREFIX_PATH=${double_conversion_install_dir} -DCMAKE_PREFIX_PATH=${libevent_install_dir} \
      -DCMAKE_PREFIX_PATH=${fmt_install_dir} -DCMAKE_PREFIX_PATH=${glog_install_dir} \
      -DGFLAGS_USE_TARGET_NAMESPACE=TRUE \
      -DBoost_USE_STATIC_RUNTIME=ON \
      -DBOOST_LINK_STATIC=ON \
      -DBUILD_TESTS=OFF \
      -DGFLAGS_NOTHREADS=OFF \
      -DFOLLY_HAVE_INT128_T=ON \
      -DCXX_STD="c++20" \
      -DCMAKE_CXX_FLAGS=${compiler_flags} \
      .."
  make --jobs=${PARALLEL} install
  popd
}

download_arrow() {
  mkdir -p $third_party_dir
  pushd $third_party_dir
  if [ ! -e arrow ]; then git clone https://github.com/apache/arrow.git; fi
  cd arrow
  git checkout ${ARROW_VERSION}
  popd
}

build_arrow() {
  download_arrow
  pushd $third_party_dir/arrow/cpp

  mkdir -p build && cd build

  cmake -G${CMAKE_GENERATOR} ${COMMON_CMAKE_FLAGS} \
    -DCMAKE_INSTALL_PREFIX=${arrow_install_dir} -DCMAKE_PREFIX_PATH=${install_dir} \
    -DBUILD_WARNING_LEVEL=PRODUCTION \
    -DARROW_USE_CCACHE=ON \
    -DARROW_ALTIVEC=OFF \
    -DARROW_DEPENDENCY_USE_SHARED=OFF -DARROW_BOOST_USE_SHARED=OFF -DARROW_BUILD_SHARED=OFF \
    -DARROW_BUILD_STATIC=ON -DARROW_COMPUTE=ON -DARROW_IPC=ON -DARROW_JEMALLOC=OFF \
    -DARROW_SIMD_LEVEL=NONE -DARROW_RUNTIME_SIMD_LEVEL=NONE \
    -DARROW_WITH_BROTLI=OFF \
    -DARROW_WITH_LZ4=ON -Dlz4_SOURCE=BUNDLED -DARROW_WITH_SNAPPY=ON -DSnappy_SOURCE=BUNDLED -DARROW_WITH_ZLIB=ON -DZLIB_SOURCE=BUNDLED \
    -DARROW_WITH_ZSTD=ON -Dzstd_SOURCE=BUNDLED -DThrift_SOURCE=BUNDLED \
    -DARROW_WITH_RE2=OFF \
    -DARROW_WITH_PROTOBUF=OFF -DARROW_WITH_RAPIDJSON=OFF \
    -DARROW_WITH_UTF8PROC=OFF -DARROW_BUILD_BENCHMARKS=OFF -DARROW_BUILD_EXAMPLES=OFF \
    -DARROW_BUILD_INTEGRATION=OFF \
    -DARROW_CSV=ON -DARROW_JSON=OFF -DARROW_PARQUET=ON \
    -DARROW_FILESYSTEM=ON \
    -DARROW_GCS=OFF -DARROW_S3=OFF -DARROW_HDFS=ON \
    -DARROW_BUILD_UTILITIES=ON -DARROW_BUILD_TESTS=OFF -DARROW_ENABLE_TIMING_TESTS=OFF \
    -DARROW_FUZZING=OFF \
    -DARROW_OPENSSL_USE_SHARED=ON \
    ..
  cmake --build . --config Release -- -j $PARALLEL
  cmake --install .
  popd
}

all() {
  build_arrow
  build_folly
}

$@
