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

# folly
FOLLY_DOWNLOAD="https://github.com/facebook/folly/archive/refs/tags/v2022.11.14.00.tar.gz"
FOLLY_NAME=folly-v2022.11.14.00.tar.gz
FOLLY_SOURCE=folly-v2022.11.14.00
FOLLY_SHA256="b249436cb61b6dfd5288093565438d8da642b07ae021191a4042b221bc1bdc0e"

# arrow
ARROW_VERSION=apache-arrow-15.0.0

check_if_source_exist() {
  if [ -z $1 ]; then
    echo "dir should specified to check if exist." && return 1
  fi
  if [ ! -d $1 ]; then
    echo "$1 does not exist." && return 1
  fi
  return 0
}

download_folly() {
  mkdir -p ${third_party_dir}/tmp_dir
  if wget --no-check-certificate $FOLLY_DOWNLOAD -O ${third_party_dir}/${FOLLY_NAME}; then
    echo "downloaded ${third_party_dir}/${FOLLY_NAME}"
  else
    echo "Failed to downloaded ${third_party_dir}/${FOLLY_NAME}"
    exit 1
  fi
  tar xzf ${third_party_dir}/${FOLLY_NAME} -C ${third_party_dir}/tmp_dir &&
    mv ${third_party_dir}/tmp_dir/* ${third_party_dir}/${FOLLY_SOURCE} || exit
  echo extracted to ${third_party_dir}/${FOLLY_SOURCE}
}

build_folly_deps() {
  pushd ${third_party_dir}/${FOLLY_SOURCE}
  ./build/fbcode_builder/getdeps.py --allow-system-packages build --install-prefix=${install_dir}/folly mvfst
  popd
}

build_folly() {
  check_if_source_exist ${third_party_dir}/${FOLLY_SOURCE} || download_folly
  build_folly_deps
  mkdir -p build
  pushd ${third_party_dir}/${FOLLY_SOURCE}/build
  source ${root_dir}/velox/scripts/setup-helper-functions.sh
  compiler_flags=\"$(get_cxx_flags "unknown")\"
  bash -c "cmake $COMMON_CMAKE_FLAGS \
      -DCMAKE_INSTALL_PREFIX=${install_dir}/folly -DCMAKE_PREFIX_PATH=${install_dir} \
      -DGFLAGS_USE_TARGET_NAMESPACE=TRUE \
      -DBoost_USE_STATIC_RUNTIME=ON \
      -DBOOST_LINK_STATIC=ON \
      -DBUILD_TESTS=OFF \
      -DGFLAGS_NOTHREADS=OFF \
      -DFOLLY_HAVE_INT128_T=ON \
      -DCXX_STD="c++20" \
      -DCMAKE_CXX_FLAGS=${compiler_flags} \
      .."
  make -j ${PARALLEL} install
  popd
}

download_arrow() {
  mkdir -p $third_party_dir
  pushd $third_party_dir
  if [ -e arrow ]; then git clone https://github.com/apache/arrow.git; fi
  cd arrow
  git checkout ${ARROW_VERSION}
  popd
}

build_arrow() {
  download_arrow
  pushd $third_party_dir/arrow/cpp

  mkdir -p build && cd build

  cmake -G${CMAKE_GENERATOR} ${COMMON_CMAKE_FLAGS} \
    -DCMAKE_INSTALL_PREFIX=${install_dir}/arrow -DCMAKE_PREFIX_PATH=${install_dir} \
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
}

$@
