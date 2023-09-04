# pmtd cmake
cmake utils for pmtd repositories, extends from [project-zetton](https://github.com/project-zetton)'s cmake utils.

## template

### usage

```shell
cmake -D CMAKE_INSTALL_PREFIX=/opt/pmtd \
    -D BUILD_WITH_TESTS=ON \
    -D INSTALL_PROTO=ON \ # for install *.proto files
    -D INSTALL_CONFIG=ON \ # for install config/*
    -D ARCHITECTURE_ARM=ON \ # for build arm64 deb
    ..
```

### CmakeLists

```cmake
cmake_minimum_required(VERSION 3.5)

project(pmtd_color_cloud 
  VERSION 1.1
  LANGUAGES CXX)

# version settings
SET(PROJECT_VERSION_MAJOR 1)
SET(PROJECT_VERSION_MINOR 0)
SET(PROJECT_VERSION_PATCH 1)

# =============#
# Dependencies #
# =============#

# ----------------------#
# Third-party libraries #
# ----------------------#

# useful macros
include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/pmtd_cmake/util.cmake)

# setting pmtd libs path 
set(CMAKE_MODULE_PATH 
  "${CMAKE_SOURCE_DIR}/cmake/pmtd_cmake/modules;${CMAKE_MODULE_PATH}")
set(ENV{PKG_CONFIG_PATH}
  /opt/pmtd/lib/pkgconfig:$ENV{PKG_CONFIG_PATH})

find_package(Protobuf REQUIRED)
find_package(eCAL REQUIRED)
find_package(OpenCV 4 REQUIRED) 
find_package(PCL REQUIRED) 
find_package(Eigen3)
find_package(GTest REQUIRED) 
find_package(absl REQUIRED)
find_package(YamlCpp REQUIRED) 

# pmtd libs
find_package(ProtobufSensorMsgs REQUIRED)
find_package(ProtobufPmtdMsgs REQUIRED)
find_package(Camodocal REQUIRED)
find_package(PmtdDriverEcal REQUIRED)
find_package(PmtdMsgSync REQUIRED)

# =========# 
# Settings #
# =========#

# shared libraries
if(NOT DEFINED BUILD_SHARED_LIBS)
  message(STATUS "${PROJECT_NAME}: Building dynamically-linked binaries")
  option(BUILD_SHARED_LIBS "Build dynamically-linked binaries" ON)
  set(BUILD_SHARED_LIBS ON)
endif()

# build type
if(NOT CMAKE_CONFIGURATION_TYPES AND NOT CMAKE_BUILD_TYPE)
  message(STATUS "${PROJECT_NAME}: Defaulting build type to RelWithDebInfo")
  set(CMAKE_BUILD_TYPE RelWithDebInfo)
endif()

# global compilations
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED TRUE) 
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
add_definitions(-O2)

# ##############################################################################
# Build #
# ##############################################################################

# ==============#
# Build targets #
# ==============#

include(GenerateExportHeader)
include(CMakePackageConfigHelpers)
include(GNUInstallDirs)

# ---------------#
# Library target #
# ---------------#

# find all source files
file(GLOB_RECURSE src_files ${PROJECT_SOURCE_DIR}/src/*.cpp
     ${PROJECT_SOURCE_DIR}/src/*/*.cpp)

# install path setting
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "/opt/pmtd")
endif()

# common library and install settings
pmtd_deb_library(
  NAME
  ${PROJECT_NAME}
  SRCS
  ${src_files}

  INCLUDES
  ${GTEST_INCLUDE_DIRS}
  ${OpenCV_INCLUDE_DIRS}
  ${PCL_INCLUDE_DIRS}
  ${EIGEN3_INCLUDE_DIR}
  ${YamlCpp_INCLUDE_DIR}
  ${ProtobufSensorMsgs_INCLUDE_DIR}
  ${ProtobufPmtdMsgs_INCLUDE_DIR}
  ${Camodocal_INCLUDE_DIR}
  ${PmtdDriverEcal_INCLUDE_DIR}
  ${PmtdMsgSync_INCLUDE_DIR}

  DEPS
  ${GTEST_BOTH_LIBRARIES}
  pthread
  eCAL::core
  protobuf::libprotobuf
  ${OpenCV_LIBS}
  ${PCL_LIBRARIES}
  ${YamlCpp_LIBRARY}
  absl::flags
  absl::flags_parse
  ${ProtobufSensorMsgs_LIBRARY}
  ${ProtobufPmtdMsgs_LIBRARY}
  ${Camodocal_LIBRARY}
  ${PmtdDriverEcal_LIBRARY}
  ${PmtdMsgSync_LIBRARY}
  )

# apps and examples
add_simple_apps()
add_simple_examples()

# tests
option(BUILD_WITH_TESTS "Build project with tests" ON)
if (BUILD_WITH_TESTS)
  message(STATUS "Build with tests")
  add_tests_in_dir(common)
endif (BUILD_WITH_TESTS) 

# install config DIRECTORY or not
option(INSTALL_CONFIG "Install the package config to ${CONFIG_DIR}" ON)
pmtd_library_settings()

# make deb pkg settings
option(ARCHITECTURE_ARM "CPACK_DEBIAN_PACKAGE_ARCHITECTURE default false(amd) " OFF)
set(description "message package for pmtd_driver_ecal")
if (${ARCHITECTURE_ARM})
  pmtd_deb_settings("arm64" ${description})
else(${ARCHITECTURE_ARM})
  pmtd_deb_settings("amd64" ${description})
endif (${ARCHITECTURE_ARM})
```

