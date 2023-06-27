# add executables with project library
macro(add_simple_excutable dirname name)
  add_executable(${dirname}_${name}
                 ${CMAKE_CURRENT_SOURCE_DIR}/${dirname}/${name}.cpp)
  target_link_libraries(${dirname}_${name} ${PROJECT_NAME})
  install(TARGETS ${dirname}_${name} DESTINATION ${CMAKE_INSTALL_PREFIX}/bin/${PROJECT_NAME})
endmacro()

macro(add_simple_excutables dirname)
  file(GLOB files "${CMAKE_CURRENT_SOURCE_DIR}/${dirname}/*.cpp")
  foreach(file ${files})
    get_filename_component(name ${file} NAME_WE)
    add_simple_excutable(${dirname} ${name})
  endforeach()
endmacro()

macro(add_simple_apps)
  add_simple_excutables("apps")
endmacro()

macro(add_simple_examples)
  add_simple_excutables("examples")
endmacro()

# add tests with project library
macro(add_simple_test dirname name)
  add_executable(${dirname}_${name}
                 ${CMAKE_CURRENT_SOURCE_DIR}/test/${dirname}/${name}.cpp)
  target_link_libraries(${dirname}_${name} ${PROJECT_NAME} gtest_main)
  add_test(NAME ${dirname}_${name} COMMAND ${dirname}_${name})
  install(TARGETS ${dirname}_${name} DESTINATION ${CMAKE_INSTALL_PREFIX}/bin/${PROJECT_NAME})
endmacro()

macro(add_tests_in_dir dirname)
  file(GLOB files "${CMAKE_CURRENT_SOURCE_DIR}/test/${dirname}/*.cpp")
  foreach(file ${files})
    get_filename_component(name ${file} NAME_WE)
    add_simple_test(${dirname} ${name})
  endforeach()
endmacro()

# 根据配置生成so库及相关cmake配置文件
function(zetton_cc_library)
  cmake_parse_arguments(
    ZETTON_CC_LIB "" "NAME" "HDRS;SRCS;COPTS;DEFINES;LINKOPTS;INCLUDES;DEPS"
    ${ARGN})

  set(_NAME "${ZETTON_CC_LIB_NAME}")
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
           ${ZETTON_CC_LIB_INCLUDES})

  target_link_libraries(
    ${_NAME}
    PUBLIC ${ZETTON_CC_LIB_DEPS}
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

  install(DIRECTORY output_cxx/ DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}")

  install(FILES "${CMAKE_CURRENT_BINARY_DIR}/${_NAME}_export.h"
          DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${_NAME}")

  install(
    FILES
      "${PROJECT_BINARY_DIR}/${CMAKE_FILES_DIRECTORY}/${_NAME}Config.cmake"
      "${PROJECT_BINARY_DIR}/${CMAKE_FILES_DIRECTORY}/${_NAME}ConfigVersion.cmake"
      # "${CMAKE_CURRENT_SOURCE_DIR}/package.xml"
    DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/${_NAME}")

  install(
    TARGETS ${_NAME}
    EXPORT EXPORT_${_NAME}
    ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")

  install(
    EXPORT EXPORT_${_NAME}
    DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/${_NAME}"
    NAMESPACE ${PROJECT_NAME}::
    FILE ${_NAME}Targets.cmake)

  # ===============#
  # Export targets #
  # ===============#

  export(
    EXPORT EXPORT_${_NAME}
    NAMESPACE ${PROJECT_NAME}::
    FILE "${PROJECT_BINARY_DIR}/${_NAME}Targets.cmake")

endfunction()

# 根据输入的安装路径与配置生成so库及相关cmake配置文件
function(pmtd_deb_library)
  cmake_parse_arguments(
    ZETTON_CC_LIB "" "NAME" "HDRS;SRCS;COPTS;DEFINES;LINKOPTS;INCLUDES;DEPS"
    ${ARGN})

  set(_NAME "${ZETTON_CC_LIB_NAME}")

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
           ${ZETTON_CC_LIB_INCLUDES})

  target_link_libraries(
    ${_NAME}
    PUBLIC ${ZETTON_CC_LIB_DEPS}
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

  # set(CMAKE_INSTALL_PREFIX ${ZETTON_CC_LIB_INSTALL_PATH})

  install(DIRECTORY output_cxx/ DESTINATION "${CMAKE_INSTALL_PREFIX}/include")

  install(FILES "${CMAKE_CURRENT_BINARY_DIR}/${_NAME}_export.h"
          DESTINATION "${CMAKE_INSTALL_PREFIX}/include/${_NAME}")

  install(
    FILES
      "${PROJECT_BINARY_DIR}/${CMAKE_FILES_DIRECTORY}/${_NAME}Config.cmake"
      "${PROJECT_BINARY_DIR}/${CMAKE_FILES_DIRECTORY}/${_NAME}ConfigVersion.cmake"
    DESTINATION "${CMAKE_INSTALL_PREFIX}/share/${_NAME}")

  install(
    TARGETS ${_NAME}
    EXPORT EXPORT_${_NAME}
    ARCHIVE DESTINATION "${CMAKE_INSTALL_PREFIX}/lib"
    LIBRARY DESTINATION "${CMAKE_INSTALL_PREFIX}/lib"
    RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}/lib")

  install(
    EXPORT EXPORT_${_NAME}
    DESTINATION "${CMAKE_INSTALL_PREFIX}/share/${_NAME}"
    NAMESPACE ${PROJECT_NAME}::
    FILE ${_NAME}Targets.cmake)

  # ===============#
  # Export targets #
  # ===============#

  export(
    EXPORT EXPORT_${_NAME}
    NAMESPACE ${PROJECT_NAME}::
    FILE "${PROJECT_BINARY_DIR}/${_NAME}Targets.cmake")

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

  message(STATUS "${PROJECT_NAME} install path: ${CMAKE_INSTALL_PREFIX}")
  message(STATUS "${PROJECT_NAME} pkgconfig install path: ${PKGCONFIG_DIR}")

  set(CONFIG_DIR ${CMAKE_INSTALL_PREFIX}/config/${PROJECT_NAME})
  if (INSTALL_CONFIG)
    message(STATUS "${PROJECT_NAME} setting config install path: ${CONFIG_DIR}")
  endif (INSTALL_CONFIG)   

  # pkgconfig
  include(CMakePackageConfigHelpers)
  configure_file(
    "${PROJECT_SOURCE_DIR}/cmake/${PROJECT_NAME}.pc.in"
    "${pkgconfig}"
    @ONLY)

  # pkgconfig
  write_basic_package_version_file(
    ${version_config}
    VERSION ${CAMODOCAL_VERSION}
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
# endfunction()
endmacro()

function(join result_var)
  set(result "")
  foreach (arg ${ARGN})
    set(result "${result}${arg}")
  endforeach ()
  set(${result_var} "${result}" PARENT_SCOPE)
endfunction()

# Sets a cache variable with a docstring joined from multiple arguments:
#   set(<variable> <value>... CACHE <type> <docstring>...)
# This allows splitting a long docstring for readability.
function(set_verbose)
  # cmake_parse_arguments is broken in CMake 3.4 (cannot parse CACHE) so use
  # list instead.
  list(GET ARGN 0 var)
  list(REMOVE_AT ARGN 0)
  list(GET ARGN 0 val)
  list(REMOVE_AT ARGN 0)
  list(REMOVE_AT ARGN 0)
  list(GET ARGN 0 type)
  list(REMOVE_AT ARGN 0)
  join(doc ${ARGN})
  set(${var} ${val} CACHE ${type} ${doc})
endfunction()


function(join result_var)
  set(result "")
  foreach (arg ${ARGN})
    set(result "${result}${arg}")
  endforeach ()
  set(${result_var} "${result}" PARENT_SCOPE)
endfunction()

# Sets a cache variable with a docstring joined from multiple arguments:
#   set(<variable> <value>... CACHE <type> <docstring>...)
# This allows splitting a long docstring for readability.
function(set_verbose)
  # cmake_parse_arguments is broken in CMake 3.4 (cannot parse CACHE) so use
  # list instead.
  list(GET ARGN 0 var)
  list(REMOVE_AT ARGN 0)
  list(GET ARGN 0 val)
  list(REMOVE_AT ARGN 0)
  list(REMOVE_AT ARGN 0)
  list(GET ARGN 0 type)
  list(REMOVE_AT ARGN 0)
  join(doc ${ARGN})
  set(${var} ${val} CACHE ${type} ${doc})
endfunction()
