cmake_minimum_required(VERSION 3.28)
project(webrtc)

set(CPACK_GENERATOR "DEB")
set(CPACK_PACKAGE_NAME "webrtc")
set(CPACK_PACKAGE_VERSION "1.0.0")
set(CPACK_PACKAGE_CONTACT "You <your.email@example.com>")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Custom build of WebRTC")
set(CPACK_DEBIAN_PACKAGE_DEPENDS "libabsl-dev")
set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "amd64")

include(CPack)

message(STATUS "Configuring WebRTC build system")
message(${CMAKE_CURRENT_SOURCE_DIR})
execute_process(
  COMMAND "${CMAKE_CURRENT_SOURCE_DIR}/build/webrtc-checkout/src/build/util/lastchange.py" "LASTCHANGE"
  WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/build/webrtc-checkout/src/build/util/"
)
execute_process(
  COMMAND ${CMAKE_COMMAND} -E env "PATH=${CMAKE_CURRENT_SOURCE_DIR}/build/depot_tools:$ENV{PATH}" "gn" gen "${CMAKE_CURRENT_BINARY_DIR}/ninja" "--args=is_debug=false rtc_include_tests=false rtc_build_examples=false"
  WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/build/webrtc-checkout/src"
  RESULT_VARIABLE prepare_webrtc_build_result
)
if(NOT ${prepare_webrtc_build_result} EQUAL 0)
  message(FATAL_ERROR "cannot prepare WebRTC build system: ${prepare_webrtc_build_result}")
endif()

add_custom_target(webrtc ALL
  COMMAND ${CMAKE_COMMAND} -E env "PATH=${CMAKE_CURRENT_SOURCE_DIR}/build/depot_tools:$ENV{PATH}" "ninja" -C "${CMAKE_CURRENT_BINARY_DIR}/ninja" webrtc
  WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/build/webrtc-checkout/src"
)

# Install the built library
install(
  FILES "${CMAKE_CURRENT_BINARY_DIR}/ninja/obj/libwebrtc.a"
  DESTINATION "lib"
)

# Install headers
install(
  DIRECTORY "build/webrtc-checkout/src/"
  DESTINATION "include/webrtc"
  FILES_MATCHING PATTERN "*.h"
)
install(
  DIRECTORY "build/webrtc-checkout/src/third_party/jsoncpp/generated/"
  DESTINATION "include/webrtc/3rdparty/json"
  FILES_MATCHING PATTERN "*.h"
)
install(
  DIRECTORY "build/webrtc-checkout/src/third_party/libyuv/include/"
  DESTINATION "include/webrtc"
  FILES_MATCHING PATTERN "*.h"
)
install(
  DIRECTORY "build/webrtc-checkout/src/third_party/abseil-cpp/"
  DESTINATION "include/webrtc"
  FILES_MATCHING PATTERN "*.h"
)


# Create generic config script for find_package(webrtc)
set(WEBRTC_CONFIG_PATH "${CMAKE_CURRENT_BINARY_DIR}/webrtcConfig.cmake")
file(WRITE ${WEBRTC_CONFIG_PATH}
  "set(webrtc_INCLUDE_DIRS \"/usr/include/webrtc\")\n"
  "set(webrtc_LIBRARIES \"/usr/lib/libwebrtc.a\")\n"
  "set(webrtc_DEFINITIONS \"-DWEBRTC_POSIX\")\n"
  "set(webrtc_FOUND TRUE)\n"
)
install(
  FILES ${WEBRTC_CONFIG_PATH}
  DESTINATION "lib/cmake/webrtc"
)
