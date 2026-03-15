cmake_minimum_required(VERSION 3.28)
project(webrtc)

set(CPACK_GENERATOR "DEB")
set(CPACK_PACKAGE_NAME "webrtc-dev")
set(CPACK_PACKAGE_VERSION "1.0.0")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Custom build of WebRTC")
set(CPACK_DEBIAN_PACKAGE_DEPENDS "")
set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "amd64")

include(CPack)

message(STATUS "Building WebRTC")
execute_process(
  COMMAND ${CMAKE_COMMAND} -E env BRANCH=main "${CMAKE_CURRENT_SOURCE_DIR}/build.sh"
  WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
  RESULT_VARIABLE result
)
if(NOT ${result} EQUAL 0)
  message(FATAL_ERROR "Error building WebRTC: ${result}")
endif()

message(STATUS "Configuring WebRTC build system")
message(${CMAKE_CURRENT_SOURCE_DIR})
execute_process(
  COMMAND "${CMAKE_CURRENT_SOURCE_DIR}/build/webrtc/src/build/util/lastchange.py" "LASTCHANGE"
  WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/build/webrtc/src/build/util/"
)
execute_process(
  COMMAND "build/prepare_webrtc_build" "${CMAKE_CURRENT_BINARY_DIR}/ninja"
  WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
  RESULT_VARIABLE prepare_webrtc_build_result
)
if(NOT ${prepare_webrtc_build_result} EQUAL 0)
  message(FATAL_ERROR "cannot prepare WebRTC build system")
endif()

add_custom_target(webrtc ALL
  COMMAND "build/depot_tools/ninja" -C "${CMAKE_CURRENT_BINARY_DIR}/ninja" webrtc stunserver turnserver
  COMMAND "build/update_cmake_config" "${CMAKE_CURRENT_SOURCE_DIR}/build/webrtc/src" "${CMAKE_CURRENT_BINARY_DIR}/ninja" "${CMAKE_CURRENT_BINARY_DIR}/output" "${CMAKE_INSTALL_PREFIX}"
  WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
)

install(FILES "package.xml" DESTINATION "share/webrtc")
install(
  FILES
  "${CMAKE_CURRENT_BINARY_DIR}/output/webrtcConfig.cmake"
  DESTINATION "share/webrtc/cmake"
)



install(
  DIRECTORY "build/webrtc/src/"
  DESTINATION "include/webrtc"
  FILES_MATCHING PATTERN "*.h"
)
install(
  DIRECTORY "build/webrtc/src/third_party/jsoncpp/generated/"
  DESTINATION "include/webrtc/3rdparty/json"
  FILES_MATCHING PATTERN "*.h"
)
install(
  DIRECTORY "build/webrtc/src/third_party/libyuv/include/"
  DESTINATION "include/webrtc/3rdparty"
  FILES_MATCHING PATTERN "*.h"
)
install(
  DIRECTORY "build/webrtc/src/third_party/abseil-cpp/"
  DESTINATION "include/webrtc"
  FILES_MATCHING PATTERN "*.h"
)
install(SCRIPT "${CMAKE_CURRENT_BINARY_DIR}/output/make_install.cmake")

