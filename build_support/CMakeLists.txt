cmake_minimum_required(VERSION 3.16)

# Default to an optimized (Release, -O3) build. SDL, SDL_image, SDL_mixer and
# SDL_ttf are pulled in via add_subdirectory below, so SDL's own "default to
# RelWithDebInfo" logic does not apply (it only triggers when SDL is the
# top-level project). Without this they would compile at -O0 — a large penalty
# for the WASM build, where every render call goes through that code.
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()

project(ruby2d_deps)

# Disable shared libraries (static builds only)
set(BUILD_SHARED_LIBS OFF CACHE INTERNAL "")

# PIC needed when static libs are later linked into
# ruby2d.so (shared object), especially on ELF platforms.
if(UNIX AND NOT APPLE)
  set(CMAKE_POSITION_INDEPENDENT_CODE ON)
endif()

# SDL sources live in ../sources relative to this CMakeLists.txt, unless the
# caller passes -DRUBY2D_SOURCES_DIR — `ruby2d setup` builds into a per-user
# cache outside the gem and points cmake at that cache's sources.
if(NOT RUBY2D_SOURCES_DIR)
  set(RUBY2D_SOURCES_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../sources")
endif()

# SDL
add_subdirectory("${RUBY2D_SOURCES_DIR}/SDL" SDL EXCLUDE_FROM_ALL)

# SDL_image
set(SDLIMAGE_VENDORED ON)
set(SDLIMAGE_AVIF OFF)
set(SDLIMAGE_BMP ON)
set(SDLIMAGE_GIF ON)
set(SDLIMAGE_JPG ON)
set(SDLIMAGE_LBM OFF)
set(SDLIMAGE_PCX OFF)
set(SDLIMAGE_PNG ON)
set(SDLIMAGE_PNM OFF)
set(SDLIMAGE_QOI OFF)
set(SDLIMAGE_SVG ON)
set(SDLIMAGE_TGA OFF)
set(SDLIMAGE_TIF OFF)
set(SDLIMAGE_WEBP OFF)
set(SDLIMAGE_XCF OFF)
set(SDLIMAGE_XPM OFF)
set(SDLIMAGE_XV OFF)
add_subdirectory("${RUBY2D_SOURCES_DIR}/SDL_image" SDL_image EXCLUDE_FROM_ALL)

# SDL_mixer
set(SDLMIXER_VENDORED ON)
set(SDLMIXER_FLAC ON)
set(SDLMIXER_GME OFF)
set(SDLMIXER_MOD OFF)
set(SDLMIXER_MP3 ON)
# Prefer dr_mp3 over libmpg123 on platforms where mpg123 doesn't build cleanly:
#   - MinGW/Windows ARM64: libmpg123 POSIX cpu-probe code
#   - Emscripten: mpg123 requires ASM
#   - Linux ARM64: mpg123 doesn't currently build
if(MINGW OR EMSCRIPTEN OR
   (CMAKE_SYSTEM_NAME STREQUAL "Linux" AND CMAKE_SYSTEM_PROCESSOR STREQUAL "aarch64"))
  set(SDLMIXER_MP3_DRMP3 ON  CACHE BOOL "" FORCE)
  set(SDLMIXER_MP3_MPG123 OFF CACHE BOOL "" FORCE)
endif()
set(SDLMIXER_MIDI OFF)
set(SDLMIXER_MIDI_NATIVE OFF)
set(SDLMIXER_OPUS OFF)
set(SDLMIXER_WAVE ON)
set(SDLMIXER_WAVPACK OFF)
add_subdirectory("${RUBY2D_SOURCES_DIR}/SDL_mixer" SDL_mixer EXCLUDE_FROM_ALL)

# SDL_ttf
set(SDLTTF_VENDORED ON)
add_subdirectory("${RUBY2D_SOURCES_DIR}/SDL_ttf" SDL_ttf EXCLUDE_FROM_ALL)

# Vendored harfbuzz promotes the -Wunused group to errors via pragmas in
# hb.hh. Clang 21+ (shipped with recent Emscripten) added -Wunused-template
# to that group, which fires on harfbuzz 8.x headers and breaks the build.
# Upstream harfbuzz 11.x fixed this; until SDL_ttf vendors a newer harfbuzz,
# disable the pragma-based error promotion (compiler defaults still apply).
if(TARGET harfbuzz)
  target_compile_definitions(harfbuzz PRIVATE HB_NO_PRAGMA_GCC_DIAGNOSTIC_ERROR)
endif()

# Build all static libraries as part of the default target
add_custom_target(deps ALL DEPENDS
  SDL3::SDL3
  SDL3_image::SDL3_image
  SDL3_mixer::SDL3_mixer
  SDL3_ttf::SDL3_ttf
)
