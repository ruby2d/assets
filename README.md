# Assets for the Ruby 2D gem

## Contents

- [`include/`](include) — C include headers for dependencies
- [`macos/`](macos) — macOS libraries
- [`mruby/`](mruby) — mruby build config files
- [`test_media/`](test_media) — Media files (images, sounds, etc.) for tests
- [`wasm/`](wasm) — [WebAssembly](https://webassembly.org) libraries and resources
- [`windows/`](windows) — [MinGW](https://en.wikipedia.org/wiki/MinGW) and MSYS2 (Windows) libraries
- [`xcode/`](xcode) — Xcode projects for iOS and tvOS
  - iOS and tvOS frameworks from [`mruby-frameworks`](https://github.com/ruby2d/mruby-frameworks)
- [`app.icns`](app.icns) — The [Ruby 2D logo](https://github.com/ruby2d/logo) icon

## Updating

### Prerequisites

On macOS, if you have existing Homebrew packages compiled or bottled from a previous OS version or Xcode SDK, rebuild / reinstall using the following:

```sh
brew list | xargs brew reinstall
```

On Windows with MinGW, if the terminal exits when running `rake update`, just run again (it's running the MSYS2 core system upgrade and needs to restart to finish, that's all).

### To update and rebuild all dependencies:

1. Update library versions in the [`Rakefile`](Rakefile)
2. Clone this repo and run `rake update` on the following platforms:
  - Windows 10 or higher (Ruby should be installed using [these instructions](https://www.ruby2d.com/learn/windows))
  - macOS 12 or higher — Intel / x86_64
  - macOS 12 or higher — Apple silicon / arm64
3. Commit or save changes to this repo after running on each platform. This is especially important for macOS, where univeral libraries are created (e.g. new x86_64 libs should be present to merge with arm64 to create universal versions)
