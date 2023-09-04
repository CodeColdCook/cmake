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

  install(DIRECTORY include/ DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}")

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
