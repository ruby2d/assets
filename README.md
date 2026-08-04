# Assets for the Ruby 2D gem

## Contents

- [`platform/`](platform) — Platform-specific headers and pre-built static libraries
  - [`include/`](platform/include) — C headers for SDL3 and mruby, shared across all targets
  - `macos-arm64/`, `windows-x86_64-mingw-ucrt/`, etc. — Compiled static libraries and binaries, organized by `{os}-{arch}/` (or `{os}-{arch}-{toolchain}/` on Windows)
  - [`wasm/`](platform/wasm) — Static libraries for the WASM (Emscripten) target (`lib/` only — no host binaries)
- [`sources/`](sources) — Dependency source repos (cloned by `rake`, gitignored)
- [`build/`](build) — CMake build artifacts, organized by target ID (e.g. `macos-arm64`)
- [`build_support/`](build_support) — CMake and mruby build configuration files
- [`resources/`](resources) — Static assets bundled with the gem
  - [`fonts/`](resources/fonts), [`icons/`](resources/icons), [`spritesheets/`](resources/spritesheets), and [`web/`](resources/web) (the HTML template for the web build)
- [`test_media/`](test_media) — Media files (images, sounds, etc.) for tests
- [`target.rb`](target.rb) — Host OS/arch/toolchain detection and path resolution (used by the Rakefile and build configs)
- [`deps.yaml`](deps.yaml) — Pinned dependency versions, updated by `rake update`

## Prerequisites

- [CMake](https://cmake.org) — required to build SDL3 libraries
- [Ruby](https://www.ruby-lang.org) and [Rake](https://ruby.github.io/rake/) — required to run build tasks
- [Emscripten](https://emscripten.org) — required for WASM builds only

**On Windows**, we recommend installing Ruby using the [RubyInstaller for Windows](https://rubyinstaller.org) and downloading the Ruby+Devkit versions. This has been tested with version 4.0.5-1 (arm and x64). `git` and `cmake` aren't installed by default — the build tasks check for them up front and offer to install them for you via MSYS2's `pacman`. To install them yourself instead, run `pacman -S` with the packages for your architecture:
- For x86_64 systems, `git mingw-w64-ucrt-x86_64-cmake`
- For ARM64 systems, `git mingw-w64-clang-aarch64-cmake`

## Building

Clone this repo, then run:

```sh
rake
```

With no arguments, `rake` cleans the current target and builds everything from source. It prints what it will do and prompts before continuing, then:

1. Clones any missing SDL3 and mruby sources at the pinned version tags in [`deps.yaml`](deps.yaml) — existing sources are left as-is, and it does not run `update`
2. Builds everything with CMake / mruby's build system
3. Copies headers to `platform/include/` and static libraries to `platform/{os}-{arch}[-{toolchain}]/lib/`

If [Emscripten](https://emscripten.org) is available on your `PATH`, the WASM libraries are built too (see [`rake wasm`](#individual-tasks)); otherwise that step is skipped with a notice. Run `rake wasm` directly to build them explicitly.

To build without the confirmation prompt, run `rake build` directly. Unlike `rake`, it re-clones any source whose pinned tag in [`deps.yaml`](deps.yaml) has changed.

### Individual tasks

```sh
rake sdl          # Download and build SDL libraries
rake mruby        # Download and build mruby
rake wasm         # Download and build all WASM libraries (SDL + mruby)
```

To remove the current target's build artifacts (plus WASM):

```sh
rake clean
```

To start completely fresh — remove **every** target's build artifacts, the WASM libraries, and all downloaded sources (re-cloned on the next build):

```sh
rake clean:all
```

### Testing SDL

```sh
rake sdl:test     # Compile and run sdl_test.c against the built libraries
```

Note: `sdl:test` opens a window and plays audio, so it needs a graphical/audio environment — it won't run headless (e.g. in CI).

## Updating dependencies

All dependency versions are pinned by tag in [`deps.yaml`](deps.yaml). To check for and apply updates:

```sh
rake update
```

This will check each dependency's remote for newer release tags, show what's available, and ask for confirmation before updating. Pinned tags in `deps.yaml` are updated automatically.

After updating, run `rake build` to rebuild with the updated sources.

## License

The contents of this repo are released under the [MIT License](LICENSE.md), unless otherwise specified. Third-party files retain their original licenses, including:

- [`platform/include/SDL3*`](platform/include) and the built `libSDL3*` libraries — [SDL3](https://www.libsdl.org), [zlib license](https://www.libsdl.org/license.php)
- [`platform/include/mruby*`](platform/include) and the built `libmruby` libraries — [mruby](https://mruby.org), [MIT License](https://github.com/mruby/mruby/blob/master/LICENSE)
- [`platform/wasm/lib/`](platform/wasm/lib) — also includes libraries bundled by SDL_image, SDL_mixer, and SDL_ttf (FreeType, HarfBuzz, libpng, zlib, Ogg/Vorbis, FLAC, PlutoVG/PlutoSVG), each under its own license
- [`resources/fonts/`](resources/fonts) — [Outfit](resources/fonts/outfit/OFL.txt) and [Roboto Mono](resources/fonts/roboto_mono/OFL.txt), [SIL Open Font License 1.1](https://openfontlicense.org)
- [`resources/spritesheets/`](resources/spritesheets) — Kenney's New Platformer Pack, [CC0](resources/spritesheets/License.txt)

See the license file included alongside each of the above, or the upstream project, for full terms.
