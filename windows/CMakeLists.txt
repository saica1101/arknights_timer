# Project-level configuration.
cmake_minimum_required(VERSION 3.14)
project(arknights_timer LANGUAGES CXX)

# The name of the executable created for the application. Change this to change
# the on-disk name of your application.
set(BINARY_NAME "ArknightsTimer")

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(VERSION 3.14...3.25)

# Define build configuration option.
get_property(IS_MULTICONFIG GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(IS_MULTICONFIG)
  set(CMAKE_CONFIGURATION_TYPES "Debug;Profile;Release"
    CACHE STRING "" FORCE)
else()
  if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE "Debug" CACHE
      STRING "Flutter build mode" FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
      "Debug" "Profile" "Release")
  endif()
endif()
# Define settings for the Profile build mode.
set(CMAKE_EXE_LINKER_FLAGS_PROFILE "${CMAKE_EXE_LINKER_FLAGS_RELEASE}")
set(CMAKE_SHARED_LINKER_FLAGS_PROFILE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE}")
set(CMAKE_C_FLAGS_PROFILE "${CMAKE_C_FLAGS_RELEASE}")
set(CMAKE_CXX_FLAGS_PROFILE "${CMAKE_CXX_FLAGS_RELEASE}")

# Use Unicode for all projects.
add_definitions(-DUNICODE -D_UNICODE)

# Compilation settings that should be applied to most targets.
#
# Be cautious about adding new options here, as plugins use this function by
# default. In most cases, you should add new options to specific targets instead
# of modifying this function.
function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_17)
  target_compile_options(${TARGET} PRIVATE /W4 /WX /wd"4100")
  target_compile_options(${TARGET} PRIVATE /EHsc)
  target_compile_definitions(${TARGET} PRIVATE "_HAS_EXCEPTIONS=0")
  target_compile_definitions(${TARGET} PRIVATE "$<$<CONFIG:Debug>:_DEBUG>")
endfunction()

# Flutter library and tool build rules.
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})

# Application build; see runner/CMakeLists.txt.
add_subdirectory("runner")

# --- Workaround for ATL headers on Windows ---
# Some plugins (e.g., flutter_local_notifications_windows) include <atlbase.h>.
# Ensure the ATL/MFC headers are on the include path for all subdirectories.
# This relies on Visual Studio setting VCToolsInstallDir during generation.
if(DEFINED ENV{VCToolsInstallDir})
  include_directories("$ENV{VCToolsInstallDir}/atlmfc/include")
  # Optionally add ATL lib path (not strictly required for header-only usage)
  if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    link_directories("$ENV{VCToolsInstallDir}/atlmfc/lib/x64")
  else()
    link_directories("$ENV{VCToolsInstallDir}/atlmfc/lib/x86")
  endif()
endif()


# Generated plugin build rules, which manage building the plugins and adding
# them to the application.
include(flutter/generated_plugins.cmake)

# Ensure ATL is enabled for plugins that require <atlbase.h> (e.g., flutter_local_notifications_windows)
if(TARGET flutter_local_notifications_windows)
  # Enable ATL so Visual Studio injects $(VC_AtlmfcIncludePath) and libraries
  set_target_properties(flutter_local_notifications_windows PROPERTIES VS_GLOBAL_UseOfAtl "Dynamic")
  # Fallback: try to locate ATL include dir under VS 2022 Community default path
  if(MSVC AND NOT DEFINED ENV{VCToolsInstallDir})
    set(_VS2022_MSVC_ROOT "C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Tools/MSVC")
    if(EXISTS "${_VS2022_MSVC_ROOT}")
      file(GLOB _MSVC_VER_DIRS LIST_DIRECTORIES true "${_VS2022_MSVC_ROOT}/*")
      # Pick the last (sorted) directory that contains atlmfc/include/atlbase.h
      list(SORT _MSVC_VER_DIRS)
      list(REVERSE _MSVC_VER_DIRS)
      foreach(_d IN LISTS _MSVC_VER_DIRS)
        if(EXISTS "${_d}/atlmfc/include/atlbase.h")
          set(_ATLMFC_INCLUDE_DIR "${_d}/atlmfc/include")
          if(CMAKE_SIZEOF_VOID_P EQUAL 8)
            set(_ATLMFC_LIB_DIR "${_d}/atlmfc/lib/x64")
          else()
            set(_ATLMFC_LIB_DIR "${_d}/atlmfc/lib/x86")
          endif()
          break()
        endif()
      endforeach()
      if(DEFINED _ATLMFC_INCLUDE_DIR)
        target_include_directories(flutter_local_notifications_windows PRIVATE "${_ATLMFC_INCLUDE_DIR}")
        if(EXISTS "${_ATLMFC_LIB_DIR}")
          # Add library search path for this target and link atls.lib explicitly.
          if(COMMAND target_link_directories)
            target_link_directories(flutter_local_notifications_windows PRIVATE "${_ATLMFC_LIB_DIR}")
          endif()
          if(EXISTS "${_ATLMFC_LIB_DIR}/atls.lib")
            target_link_libraries(flutter_local_notifications_windows PRIVATE "${_ATLMFC_LIB_DIR}/atls.lib")
          else()
            # Fallback to library name if absolute path not found
            target_link_libraries(flutter_local_notifications_windows PRIVATE atls)
          endif()
        endif()
      endif()
    endif()
  endif()
endif()


# === Installation ===
# Support files are copied into place next to the executable, so that it can
# run in place. This is done instead of making a separate bundle (as on Linux)
# so that building and running from within Visual Studio will work.
set(BUILD_BUNDLE_DIR "$<TARGET_FILE_DIR:${BINARY_NAME}>")
# Make the "install" step default, as it's required to run.
set(CMAKE_VS_INCLUDE_INSTALL_TO_DEFAULT_BUILD 1)
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "..." FORCE)
endif()

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}")

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_ICU_DATA_FILE}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  COMPONENT Runtime)

if(PLUGIN_BUNDLED_LIBRARIES)
  install(FILES "${PLUGIN_BUNDLED_LIBRARIES}"
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endif()

# Copy the native assets provided by the build.dart from all packages.
set(NATIVE_ASSETS_DIR "${PROJECT_BUILD_DIR}native_assets/windows/")
install(DIRECTORY "${NATIVE_ASSETS_DIR}"
   DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
   COMPONENT Runtime)

# Fully re-copy the assets directory on each build to avoid having stale files
# from a previous install.
set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
install(CODE "
  file(REMOVE_RECURSE \"${INSTALL_BUNDLE_DATA_DIR}/${FLUTTER_ASSET_DIR_NAME}\")
  " COMPONENT Runtime)
install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
  DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)

# Install the AOT library on non-Debug builds only.
install(FILES "${AOT_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  CONFIGURATIONS Profile;Release
  COMPONENT Runtime)
