# Copyright 2024 Whippet Sort
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

cmake_minimum_required(VERSION 3.20.0)

# https://gitlab.kitware.com/cmake/community/wikis/FAQ#how-do-i-use-a-different-compiler must be set before project
set(CMAKE_CXX_COMPILER clang++)
set(CMAKE_C_COMPILER clang)

project(WhippetSort LANGUAGES CXX)

# ----------------------------------------------------------------------
# CMake modules
include(CTest) # adds BUILD_TESTING option, include after project() but before add_subdirectory()
set(CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake)
include(utils)

# ----------------------------------------------------------------------
# Cached options
option(FLAVIUS_ENABLE_CCACHE "Enable ccache for compilation" ON)

# ----------------------------------------------------------------------
# Setup global compile options
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_CXX_STANDARD 17) # to be consistent with velox
set(CMAKE_CXX_STANDARD_REQUIRED TRUE)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Known warnings that are benign can be disabled.
set(DISABLED_WARNINGS "-Wno-nullability-completeness -Wno-deprecated-declarations")

# mode
set(CMAKE_CXX_FLAGS_DEBUG "-g -fsanitize=address -Wall") # -Werror
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "-O3 -g")
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -Wall -march=native -DNDEBUG")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${DISABLED_WARNINGS}")

# ----------------------------------------------------------------------
# Use ccache
if(FLAVIUS_ENABLE_CCACHE
   AND NOT CMAKE_C_COMPILER_LAUNCHER
   AND NOT CMAKE_CXX_COMPILER_LAUNCHER
)
  find_program(CCACHE_FOUND ccache)
  if(CCACHE_FOUND)
    message(STATUS "Using ccache: ${CCACHE_FOUND}")
    set(CMAKE_C_COMPILER_LAUNCHER ${CCACHE_FOUND})
    set(CMAKE_CXX_COMPILER_LAUNCHER ${CCACHE_FOUND})
    # keep comments as they might matter to the compiler
    set(ENV{CCACHE_COMMENTS} "1")
  endif()
endif()

# ----------------------------------------------------------------------
# dependencies

list(APPEND CMAKE_PREFIX_PATH ${PROJECT_SOURCE_DIR}/third_party/install/arrow)
message(STATUS ${CMAKE_PREFIX_PATH})
# arrow
find_package(Arrow CONFIG REQUIRED)
# parquet
find_package(Parquet CONFIG REQUIRED)

# folly and its deps, used by velox
set(Boost_USE_STATIC_RUNTIME ON)
list(APPEND CMAKE_PREFIX_PATH ${PROJECT_SOURCE_DIR}/third_party/install/boost)
list(APPEND CMAKE_PREFIX_PATH ${PROJECT_SOURCE_DIR}/third_party/install/libevent)
list(APPEND CMAKE_PREFIX_PATH ${PROJECT_SOURCE_DIR}/third_party/install/fmt)
find_package(Fmt CONFIG REQUIRED)
list(APPEND CMAKE_PREFIX_PATH ${PROJECT_SOURCE_DIR}/third_party/install/glog)
find_package(glog CONFIG REQUIRED)
list(APPEND CMAKE_PREFIX_PATH ${PROJECT_SOURCE_DIR}/third_party/install/folly)
find_package(folly CONFIG REQUIRED)

include_directories(SYSTEM ${PROJECT_SOURCE_DIR}/third_party/install/boost/include)
link_directories(${PROJECT_SOURCE_DIR}/third_party/install/boost/lib)

# ----------------------------------------------------------------------
# Setup velox
set(VELOX_ROOT ${PROJECT_SOURCE_DIR}/velox)
message(STATUS "Setting VELOX_ROOT = ${VELOX_ROOT}")
execute_process(
  COMMAND bash -c
          "( source ${VELOX_ROOT}/scripts/setup-helper-functions.sh && echo -n $(get_cxx_flags $ENV{CPU_TARGET}))"
  OUTPUT_VARIABLE SCRIPT_CXX_FLAGS
  RESULT_VARIABLE COMMAND_STATUS
)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${SCRIPT_CXX_FLAGS}")
# minimal build for the need to test sorting
set(VELOX_CODEGEN_SUPPORT OFF)
set(VELOX_ENABLE_EXAMPLES OFF)
set(VELOX_ENABLE_HDFS OFF)
set(VELOX_ENABLE_SPARK_FUNCTIONS OFF)
set(VELOX_ENABLE_S3 OFF)
set(VELOX_ENABLE_PARQUET ON)
set(VELOX_ENABLE_DUCKDB ON)
set(VELOX_ENABLE_HIVE_CONNECTOR ON)
set(VELOX_ENABLE_TPCH_CONNECTOR ON)
# for velox bundled deps
include_directories(SYSTEM ${CMAKE_BINARY_DIR}/_deps/gflags-build/include)
include_directories(${VELOX_ROOT})
add_subdirectory(${VELOX_ROOT})
# supress compiler warnings for velox libraries
get_all_targets(_velox_targets ${VELOX_ROOT})
foreach(_target IN LISTS _velox_targets)
  if(${_target} MATCHES "^velox_")
    message(DEBUG "subpress compiler warning for ${_target}")
    target_compile_options(${_target} PRIVATE "-w")
  endif()
endforeach()


# ----------------------------------------------------------------------
# sources
include_directories(${PROJECT_SOURCE_DIR}/src)
add_subdirectory(src)
