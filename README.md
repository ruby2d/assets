# Assets for the Ruby 2D gem

## Contents

- [`include/`](include) — C include headers for dependencies
- [`ios/`](ios) and [`tvos/`](tvos)
  - Xcode projects for iOS and tvOS, derived from the [Simple 2D dependencies](https://github.com/simple2d/deps/tree/master/xcode)
  - iOS and tvOS frameworks from [`mruby-frameworks`](https://github.com/ruby2d/mruby-frameworks)
- [`linux/`](linux) — Simple 2D source and includes for Linux
- [`macos/`](macos) — Static library dependencies for macOS
- [`mingw/`](mingw) — Static and dynamic library dependencies for Windows / MinGW
- [`app.icns`](app.icns) — The [Ruby 2D logo](https://github.com/ruby2d/logo) icon

## Updating

1. Update the Simple 2D version in the [Rakefile](Rakefile)
2. Run `rake`

To update the Xcode projects:
- Copy over Xcode iOS and tvOS projects from `xcode/ios` and `xcode/tvos` in [simple2d/deps](https://github.com/simple2d/deps)
- Add frameworks to the Xcode projects (Target -> Build Phases -> Link Binary with Libraries) and the "Header Search Paths"
- Rename Bundle Identifiers from "Simple2D.MyApp" to "Ruby2D.MyApp"
