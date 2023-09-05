function(pmtd_find_pkg Package package_name)
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
endfunction()

function(pmtd_pkg_modules)
  cmake_parse_arguments(
    PMTD_PKG_MODULE "" "NAME" "PACKAGE_NAMES;package_names"
    ${ARGN})

  set(_NAME "${PMTD_PKG_MODULE_NAME}")

  list(LENGTH PMTD_PKG_MODULE_PACKAGE_NAMES len_PKG)
  list(LENGTH PMTD_PKG_MODULE_package_names len_pkg_name)

  if(NOT len_PKG EQUAL len_pkg_name)
      message(FATAL_ERROR "PMTD packages have different lengths")
      message(STATUS "PACKAGE_NAMES length: ${len_PKG}")
      message(STATUS "package_names length: ${len_pkg_name}")
  endif()

  foreach(index RANGE ${len_PKG})
    if(NOT ${index} EQUAL ${len_PKG})
      list(GET PMTD_PKG_MODULE_PACKAGE_NAMES ${index} Package)
      list(GET PMTD_PKG_MODULE_package_names ${index} package_name)
      pmtd_find_pkg(${Package} ${package_name})
    endif()
     
  endforeach()

endfunction()

# 根据输入的安装路径与配置生成so库及相关cmake配置文件
function(pmtd_deb_library)
  cmake_parse_arguments(
    ZETTON_CC_LIB "" "NAME" "HDRS;SRCS;COPTS;DEFINES;LINKOPTS;INCLUDES;DEPS;PMTD_PACKAGE_NAMES;pmtd_package_names"
    ${ARGN})

  set(_NAME "${ZETTON_CC_LIB_NAME}")

  include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/pmtd_cmake/util_zetton.cmake)
  # ==============#
  # Find pmtd packages #
  # ==============#
  find_package(PkgConfig)

  list(LENGTH ZETTON_CC_LIB_PMTD_PACKAGE_NAMES len_PKG)
  list(LENGTH ZETTON_CC_LIB_pmtd_package_names len_pkg_name)

  if(NOT len_PKG EQUAL len_pkg_name)
      message(FATAL_ERROR "PMTD packages have different lengths")
      message(STATUS "PMTD_PACKAGE_NAMES length: ${len_PKG}")
      message(STATUS "pmtd_package_names length: ${len_pkg_name}")
  endif()


  set(PMTD_INCLUDES)
  set(PMTD_DEPS)
  foreach(index RANGE ${len_PKG})
    if(NOT ${index} EQUAL ${len_PKG})
      list(GET ZETTON_CC_LIB_PMTD_PACKAGE_NAMES ${index} Package)
      list(GET ZETTON_CC_LIB_pmtd_package_names ${index} package_name)
      pmtd_find_pkg(${Package} ${package_name})
      list(APPEND PMTD_INCLUDES "${${Package}_INCLUDE_DIR}")
      list(APPEND PMTD_DEPS "${${Package}_LIBRARY}")
    endif()
     
  endforeach()

  # ==============#
  # Build targets #
  # ==============#

  # common library
  add_library(${_NAME} ${ZETTON_CC_LIB_SRCS} ${ZETTON_CC_LIB_HDRS})
  add_library(${PROJECT_NAME}::${_NAME} ALIAS ${_NAME})

  # generate a header with export macros, which is written to the
  # CMAKE_CURRENT_BINARY_DIR location.
  generate_export_header(${_NAME})

  target_include_directories(
    ${_NAME}
    PUBLIC "$<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>"
           "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>"
           "$<INSTALL_INTERFACE:$<INSTALL_PREFIX>/include>"
           ${ZETTON_CC_LIB_INCLUDES}
           ${PMTD_INCLUDES})

  target_link_libraries(
    ${_NAME}
    PUBLIC ${ZETTON_CC_LIB_DEPS}
    PUBLIC ${PMTD_DEPS}
    PRIVATE ${ZETTON_CC_LIB_LINKOPTS})

  # compiling options
  target_compile_options(${_NAME} PRIVATE ${ZETTON_CC_LIB_COPTS})
  if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    target_compile_options(${_NAME} PRIVATE -Wall -Wextra -Wpedantic
                                            -Wno-unused-parameter)
  elseif(CMAKE_CXX_COMPILER_ID MATCHES "MSVC")
    target_compile_options(${_NAME} PRIVATE /W4)
  endif()
  if(MSVC)
    # Force include the export header when using Microsoft Visual C++ compiler.
    target_compile_options(
      ${_NAME} PUBLIC "/FI${CMAKE_CURRENT_BINARY_DIR}/${_NAME}_export.h")
  endif()

  # compiling definitions
  target_compile_definitions(${_NAME} PUBLIC ${ZETTON_CC_LIB_DEFINES})
  if(NOT BUILD_SHARED_LIBS)
    target_compile_definitions(${_NAME} PUBLIC "ZETTON_COMMON_STATIC_DEFINE")
  endif()

  # compiling features
  target_compile_features(${_NAME} PRIVATE cxx_std_14)

  # =============================#
  # CMake package configurations #
  # =============================#

  include(CMakePackageConfigHelpers)

  # Create the ${_NAME}Config.cmake file, which is used by other packages to
  # find this package and its dependencies.
  configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/Config.cmake.in"
    "${PROJECT_BINARY_DIR}/${CMAKE_FILES_DIRECTORY}/${_NAME}Config.cmake" @ONLY)

  # Create the ${_NAME}ConfigVersion.cmake.
  write_basic_package_version_file(
    "${PROJECT_BINARY_DIR}/${CMAKE_FILES_DIRECTORY}/${_NAME}ConfigVersion.cmake"
    COMPATIBILITY AnyNewerVersion)

  # ==============#
  # Install files #
  # ==============#

  include(GNUInstallDirs)
endfunction()

# 设置deb安装包的CMAKE配置，并制定deb包以及安装后的名称规则
# ARCHITECTURE 架构格式输入amd64 arm64
macro(pmtd_deb_settings architecture description)
  #说明要生成的是deb包
  SET(CPACK_GENERATOR "DEB")

  ##############设置debian/control文件中的内容###############
  #设置版本信息
  SET(CPACK_PACKAGE_VERSION_MAJOR "${PROJECT_VERSION_MAJOR}")
  SET(CPACK_PACKAGE_VERSION_MINOR "${PROJECT_VERSION_MINOR}")
  SET(CPACK_PACKAGE_VERSION_PATCH "${PROJECT_VERSION_PATCH}")

  #设置安装包的包名，打好的包将会是packagename-version-linux.deb，如果不设置，默认是工程名
  set(CPACK_PACKAGE_NAME "${PROJECT_NAME}_${architecture}")

  #设置程序名，就是程序安装后的名字
  set(CPACK_DEBIAN_PACKAGE_NAME "${PROJECT_NAME}")

  #设置架构
  set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "${architecture}")

  #设置依赖
  set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)
  # SET(CPACK_DEBIAN_PACKAGE_DEPENDS "libprotobuf")

  #设置description
  SET(CPACK_PACKAGE_DESCRIPTION ${description})

  #设置联系方式
  SET(CPACK_PACKAGE_CONTACT "${PROJECT_NAME}")

  #设置维护人
  set(CPACK_DEBIAN_PACKAGE_MAINTAINER "BDCA")

  include(CPack)

endmacro()

# 主要配置仓库安装地址，版本信息，pkgconfig
macro(pmtd_library_settings)
  set(PKGCONFIG_DIR ${CMAKE_INSTALL_PREFIX}/lib/pkgconfig)
  set(pkgconfig ${PROJECT_BINARY_DIR}/${PROJECT_NAME}.pc)
  set(version_config ${PROJECT_BINARY_DIR}/${PROJECT_NAME}-config-version.cmake)
  set(CONFIG_DIR ${CMAKE_INSTALL_PREFIX}/config/${PROJECT_NAME})
  set(PROTO_DIR "${CMAKE_INSTALL_PREFIX}/proto")

  message(STATUS "${PROJECT_NAME} install path: ${CMAKE_INSTALL_PREFIX}")
  message(STATUS "${PROJECT_NAME} pkgconfig install path: ${PKGCONFIG_DIR}")

  if (INSTALL_CONFIG)
    message(STATUS "${PROJECT_NAME} setting config install path: ${CONFIG_DIR}")
  endif (INSTALL_CONFIG)   
  if(INSTALL_PROTO)
    message(STATUS "${PROJECT_NAME} proto file install path: ${PROTO_DIR}")
  endif(INSTALL_PROTO)

  # pkgconfig
  include(CMakePackageConfigHelpers)
  configure_file(
    "${PROJECT_SOURCE_DIR}/cmake/${PROJECT_NAME}.pc.in"
    "${pkgconfig}"
    @ONLY)

  # pkgconfig
  write_basic_package_version_file(
    ${version_config}
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY AnyNewerVersion)
  configure_file(
      ${PROJECT_SOURCE_DIR}/cmake/version.h.in
      ${PROJECT_SOURCE_DIR}/include/${PROJECT_NAME}/version.h
      @ONLY
  )
  
  # pmtd install
  install(FILES "${pkgconfig}" DESTINATION "${PKGCONFIG_DIR}")
  # install config 
  if (INSTALL_CONFIG)
    install(DIRECTORY config/ DESTINATION "${CONFIG_DIR}")
  endif (INSTALL_CONFIG)

  # 配置protobuf的安装路径
  install(DIRECTORY include/ DESTINATION "${CMAKE_INSTALL_PREFIX}/include")
  if(INSTALL_PROTO)
    install(DIRECTORY proto/${PROJECT_NAME} DESTINATION ${PROTO_DIR})
  endif(INSTALL_PROTO)

  install(FILES "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}_export.h"
          DESTINATION "${CMAKE_INSTALL_PREFIX}/include/${PROJECT_NAME}")

  install(
    FILES
      "${PROJECT_BINARY_DIR}/${CMAKE_FILES_DIRECTORY}/${PROJECT_NAME}Config.cmake"
      "${PROJECT_BINARY_DIR}/${CMAKE_FILES_DIRECTORY}/${PROJECT_NAME}ConfigVersion.cmake"
    DESTINATION "${CMAKE_INSTALL_PREFIX}/share/${PROJECT_NAME}")

  install(
    TARGETS ${PROJECT_NAME}
    EXPORT EXPORT_${PROJECT_NAME}
    ARCHIVE DESTINATION "${CMAKE_INSTALL_PREFIX}/lib"
    LIBRARY DESTINATION "${CMAKE_INSTALL_PREFIX}/lib"
    RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}/lib")

  install(
    EXPORT EXPORT_${PROJECT_NAME}
    DESTINATION "${CMAKE_INSTALL_PREFIX}/share/${PROJECT_NAME}"
    NAMESPACE ${PROJECT_NAME}::
    FILE ${PROJECT_NAME}Targets.cmake)

  # ===============#
  # Export targets #
  # ===============#

  export(
    EXPORT EXPORT_${PROJECT_NAME}
    NAMESPACE ${PROJECT_NAME}::
    FILE "${PROJECT_BINARY_DIR}/${PROJECT_NAME}Targets.cmake")
# endfunction()
endmacro()
