set (Package "ProtobufPmtdMsgs")
set (package_name "protobuf_pmtd_msgs")

find_package(PkgConfig)
pkg_check_modules(PC_${Package} QUIET ${package_name})

find_path(${Package}_INCLUDE_DIR
    NAMES ${package_name}/${package_name}_export.h
    PATHS /opt/pmtd/include /usr/local/include
    PATH_SUFFIXES ${package_name}
    )
find_library(${Package}_LIBRARY
    NAMES ${package_name}
    PATHS /opt/pmtd/lib /usr/local/lib/
    )

set(${Package}_VERSION ${PC_${Package}_VERSION})
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(${Package}
    FOUND_VAR ${Package}_FOUND
    REQUIRED_VARS
    ${Package}_LIBRARY
    ${Package}_INCLUDE_DIR
    VERSION_VAR ${Package}_VERSION
    )

if (${Package}_FOUND)
    set(${Package}_LIBRARIES ${${Package}_LIBRARY})
    set(${Package}_INCLUDE_DIRS ${${Package}_INCLUDE_DIR}/${package_name})
    set(${Package}_DEFINITIONS ${PC_${Package}_CFLAGS_OTHER})
    message(STATUS "Found ${Package} 
      version: ${${Package}_VERSION}
      include: ${${Package}_INCLUDE_DIRS}
      library: ${${Package}_LIBRARIES}")
    mark_as_advanced(
        ${Package}_INCLUDE_DIR
        ${Package}_LIBRARY
    )
endif ()