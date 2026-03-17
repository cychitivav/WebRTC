# sudo apt-get update && sudo apt-get install -y libasound2-dev libpulse-dev
# sudo apt-get install -y libxcomposite-dev libxfixes-dev libxdamage-dev libxrandr-dev libxtst-dev
cmake_minimum_required(VERSION 3.28)
project(webrtc)

set(CPACK_GENERATOR "DEB")
set(CPACK_PACKAGE_NAME "webrtc")
set(CPACK_PACKAGE_VERSION "21.0.0")
set(CPACK_PACKAGE_CONTACT "You <your.email@example.com>")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Custom build of WebRTC")
set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "amd64")
set(CPACK_DEBIAN_PACKAGE_SECTION "libdevel")
set(CPACK_DEBIAN_PACKAGE_DEPENDS
  "libc6, libstdc++6, libjpeg-dev, libxcomposite-dev, libxfixes-dev, libxdamage-dev, libxrandr-dev, libxtst-dev"
)

include(CPack)

message(STATUS "Configuring WebRTC build system")
message(${CMAKE_CURRENT_SOURCE_DIR})

execute_process(
  COMMAND "${CMAKE_CURRENT_SOURCE_DIR}/build/webrtc-checkout/src/build/util/lastchange.py" "LASTCHANGE"
  WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/build/webrtc-checkout/src/build/util/"
)

execute_process(
  COMMAND ${CMAKE_COMMAND} -E env "PATH=${CMAKE_CURRENT_SOURCE_DIR}/build/depot_tools:$ENV{PATH}"
  "gn" gen "${CMAKE_CURRENT_BINARY_DIR}/ninja"
  "--args=is_debug=false rtc_include_tests=false rtc_build_examples=false is_clang=false is_desktop_linux=true use_system_libjpeg=true treat_warnings_as_errors=false fatal_linker_warnings=false use_gio=false use_rtti=true rtc_enable_protobuf=false use_sysroot=false use_custom_libcxx=false rtc_build_json=true symbol_level=0 target_os=\"linux\" target_cpu=\"x64\" rtc_include_internal_audio_device=false rtc_include_pulse_audio=false"
  WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/build/webrtc-checkout/src"
  RESULT_VARIABLE prepare_webrtc_build_result
)
if(NOT ${prepare_webrtc_build_result} EQUAL 0)
  message(FATAL_ERROR "cannot prepare WebRTC build system: ${prepare_webrtc_build_result}")
endif()

add_custom_target(webrtc ALL
  COMMAND ${CMAKE_COMMAND} -E env "PATH=${CMAKE_CURRENT_SOURCE_DIR}/build/depot_tools:$ENV{PATH}"
  "ninja" -C "${CMAKE_CURRENT_BINARY_DIR}/ninja"
  webrtc
  builtin_video_decoder_factory
  builtin_video_encoder_factory
  rtc_internal_video_codecs
  rtc_simulcast_encoder_adapter
  WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/build/webrtc-checkout/src"
)

# Write the ar MRI script at CMake configure time (avoids shell escaping in Makefile)
set(WEBRTC_MRI_SCRIPT "${CMAKE_CURRENT_BINARY_DIR}/combine_webrtc.mri")
file(WRITE ${WEBRTC_MRI_SCRIPT}
  "CREATE ${CMAKE_CURRENT_BINARY_DIR}/ninja/obj/libwebrtc_full.a\n"
  "ADDLIB ${CMAKE_CURRENT_BINARY_DIR}/ninja/obj/libwebrtc.a\n"
  "ADDLIB ${CMAKE_CURRENT_BINARY_DIR}/ninja/obj/api/video_codecs/libbuiltin_video_encoder_factory.a\n"
  "ADDLIB ${CMAKE_CURRENT_BINARY_DIR}/ninja/obj/api/video_codecs/libbuiltin_video_decoder_factory.a\n"
  "ADDLIB ${CMAKE_CURRENT_BINARY_DIR}/ninja/obj/api/video_codecs/librtc_software_fallback_wrappers.a\n"
  "ADDLIB ${CMAKE_CURRENT_BINARY_DIR}/ninja/obj/media/librtc_internal_video_codecs.a\n"
  "ADDLIB ${CMAKE_CURRENT_BINARY_DIR}/ninja/obj/media/librtc_simulcast_encoder_adapter.a\n"
  "SAVE\n"
  "END\n"
)

# add_custom_target(webrtc_merged ALL
#   DEPENDS webrtc
#   COMMAND ar -M < ${WEBRTC_MRI_SCRIPT}
#   COMMENT "Merging WebRTC libraries into single archive"
# )
add_custom_target(webrtc_merged ALL
  DEPENDS webrtc
  COMMAND ar -M < ${WEBRTC_MRI_SCRIPT}
  COMMAND ar d "${CMAKE_CURRENT_BINARY_DIR}/ninja/obj/libwebrtc_full.a" fake_video_codec_factory.o
  COMMENT "Merging and cleaning WebRTC libraries"
)

# Install the built library
install(
  FILES "${CMAKE_CURRENT_BINARY_DIR}/ninja/obj/libwebrtc_full.a"
  DESTINATION "lib"
  RENAME "libwebrtc.a"
)

install(
  DIRECTORY "build/webrtc-checkout/src/"
  DESTINATION "include/webrtc"
  FILES_MATCHING PATTERN "*.h" PATTERN "*.inc"
)

set(WEBRTC_CONFIG_PATH "${CMAKE_CURRENT_BINARY_DIR}/webrtcConfig.cmake")
file(WRITE ${WEBRTC_CONFIG_PATH}
  "cmake_minimum_required(VERSION 3.5)\n"
  "\n"
  "find_package(JPEG REQUIRED)\n"
  "\n"
  "if(NOT TARGET webrtc::webrtc)\n"
  "  add_library(webrtc::webrtc INTERFACE IMPORTED GLOBAL)\n"
  "\n"
  "  set(_webrtc_includes\n"
  "    \"/usr/include/webrtc/third_party/abseil-cpp;/usr/include/webrtc/third_party/libyuv/include;/usr/include/webrtc/third_party;/usr/include/webrtc\"\n"
  "  )\n"
  "\n"
  "  set_target_properties(webrtc::webrtc PROPERTIES\n"
  "    INTERFACE_COMPILE_DEFINITIONS \"WEBRTC_POSIX;WEBRTC_LINUX;NDEBUG\"\n"
  "    INTERFACE_INCLUDE_DIRECTORIES \"\${_webrtc_includes}\"\n"
  "    INTERFACE_SYSTEM_INCLUDE_DIRECTORIES \"\${_webrtc_includes}\"\n"
  "    INTERFACE_LINK_LIBRARIES \"-Wl,--whole-archive;/usr/lib/libwebrtc.a;-Wl,--no-whole-archive;JPEG::JPEG;X11;Xext;Xcomposite;Xfixes;Xdamage;Xrandr;Xtst\"\n"
  "  )\n"
  "endif()\n"
  "\n"
  "set(webrtc_FOUND TRUE)\n"
)

install(
  FILES ${WEBRTC_CONFIG_PATH}
  DESTINATION "lib/cmake/webrtc"
)
