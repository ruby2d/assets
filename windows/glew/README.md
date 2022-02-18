# GLEW for MinGW

This directory contains GLEW binaries for MinGW, since the project does not have them.

To update these binaries:
1. Install "MSYS2 MinGW 64-bit" on Windows, open its corresponding command prompt
2. Install dependencies, like `pacman -S git python`
3. Download latest [GLEW source release](https://github.com/nigels-com/glew/releases)
4. Enter directory and run `make extensions && make`
5. From the GLEW `lib/` directory, copy `libglew32.a` to this directory
