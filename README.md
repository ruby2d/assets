# Assets for the Ruby 2D gem

## Contents

- [`include/`](include) — C include headers for dependencies
- [`ios/`](ios) and [`tvos/`](tvos)
  - Xcode projects for iOS and tvOS, derived from the [Simple 2D dependencies](https://github.com/simple2d/deps/tree/master/xcode)
  - iOS and tvOS frameworks from [`mruby-frameworks`](https://github.com/ruby2d/mruby-frameworks)
- [`macos/`](macos) — Static library dependencies for macOS
- [`mingw/`](mingw) — Static and dynamic library dependencies for Windows / MinGW
- [`app.icns`](app.icns) — The [Ruby 2D logo](https://github.com/ruby2d/logo) icon

## Updating

- From [simple2d/deps](https://github.com/simple2d/deps):
  - Copy over SDL and GLEW headers to `include/`
  - Copy over `macos/lib`, `mingw/lib`, and `mingw/bin`
  - Copy over Xcode iOS and tvOS projects from `xcode/ios` and `xcode/tvos`
  - Copy iOS and tvOS [MRuby frameworks](https://github.com/ruby2d/mruby-frameworks) to their respective project directories, add them to the Xcode projects (Target -> Build Phases -> Link Binary with Libraries) and the "Header Search Paths"; Rename Bundle Identifiers from "Simple2D.MyApp" to "Ruby2D.MyApp"
- From your local [Simple 2D](https://github.com/simple2d) project
  - Copy `simple2d.h` to `include/`
  - Copy the `libsimple2d.a` builds to their respective `macos/lib` and `mingw/lib` directories
