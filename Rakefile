# Library dependency versions — update these when new releases are available
mruby_version     = '3.1.0'
sdl_version       = '2.26.1'
sdl_image_version = '2.6.2'
sdl_mixer_version = '2.6.2'
sdl_ttf_version   = '2.20.1'

# Shared variables
tmp_dir = nil

# Helpers ######################################################################

# Extend `String` to include some fancy colors
class String
  def ruby2d_colorize(c); "\e[#{c}m#{self}\e[0m" end
  def bold;    ruby2d_colorize('1')    end
  def info;    ruby2d_colorize('1;34') end
  def warn;    ruby2d_colorize('1;33') end
  def success; ruby2d_colorize('1;32') end
  def error;   ruby2d_colorize('1;31') end
end

# Detect the platform
case RUBY_PLATFORM
when /darwin/
  RUBY2D_PLATFORM = :macos
when /linux/
  RUBY2D_PLATFORM = :linux
when /mingw/
  RUBY2D_PLATFORM = :windows
end

# Format printing of task
def print_task(task)
  print "==> ".info, task.bold, "\n"
end

# Run system command
def run_cmd(cmd)
  puts "==> #{cmd}".bold
  system cmd
end

# Tasks ########################################################################

task :default => [:list]

desc 'List commands'
task :list do
  puts `rake -T`
end


desc "Update all assets"
task :update => [
  :update_mingw_packages,
  :set_tmp_dir,
  :download_extract_libs,
  :assemble_includes,
  :assemble_macos_libs,
  :assemble_windows_libs
] do
  puts "\n😎 All assets updated for this platform!\n".success
end


desc 'Set the temporary working directory'
task :set_tmp_dir do

  print_task 'Set `tmp/` directory'

  # Create tmp directory
  FileUtils.mkdir_p 'tmp'

  # Change to tmp dir, save location
  Dir.chdir 'tmp'
  tmp_dir = Dir.pwd

end


desc "Download and extract libraries"
task :download_extract_libs => :set_tmp_dir do

  # Clean out tmp dir if already exists, directories only (to avoid re-downloading .zips)
  FileUtils.rm_rf Dir.glob("#{tmp_dir}/*/")

  # Library URLs
  mruby_url = "https://github.com/mruby/mruby/archive/refs/tags/#{mruby_version}.zip"
  sdl_url = "https://github.com/libsdl-org/SDL/archive/refs/tags/release-#{sdl_version}.zip"
  sdl_image_url = "https://github.com/libsdl-org/SDL_image/archive/refs/tags/release-#{sdl_image_version}.zip"
  sdl_mixer_url = "https://github.com/libsdl-org/SDL_mixer/archive/refs/tags/release-#{sdl_mixer_version}.zip"
  sdl_ttf_url = "https://github.com/libsdl-org/SDL_ttf/archive/refs/tags/release-#{sdl_ttf_version}.zip"
  angle_url = "https://github.com/google/angle/archive/refs/heads/main.zip"

  # Download libs

  def download(lib_name, url, filename)
    if File.exist? filename
      print_task "#{lib_name} already downloaded..."
    else
      print_task "Downloading #{lib_name}..."
      run_cmd "curl -L #{url} -o #{filename}"
    end
  end

  download 'mruby', mruby_url, "mruby-#{mruby_version}.zip"
  download 'SDL', sdl_url, "SDL-#{sdl_version}.zip"
  download 'SDL_image', sdl_image_url, "SDL_image-#{sdl_image_version}.zip"
  download 'SDL_mixer', sdl_mixer_url, "SDL_mixer-#{sdl_mixer_version}.zip"
  download 'SDL_ttf', sdl_ttf_url, "SDL_ttf-#{sdl_ttf_version}.zip"
  download 'angle', angle_url, "angle-main.zip"

  # Extract and rename directories

  if RUBY2D_PLATFORM == :windows && !system('unzip')
    run_cmd 'pacman -S --noconfirm unzip'
  end

  def extract(filename, extracted_filename, rename_to)
    print_task "Extracting #{filename}..."
    run_cmd "unzip -q #{filename}"
    File.rename extracted_filename, rename_to
  end

  extract "mruby-#{mruby_version}.zip", "mruby-#{mruby_version}", 'mruby'
  extract "SDL-#{sdl_version}.zip", "SDL-release-#{sdl_version}", 'SDL'
  extract "SDL_image-#{sdl_image_version}.zip", "SDL_image-release-#{sdl_image_version}", 'SDL_image'
  extract "SDL_mixer-#{sdl_mixer_version}.zip", "SDL_mixer-release-#{sdl_mixer_version}", 'SDL_mixer'
  extract "SDL_ttf-#{sdl_ttf_version}.zip", "SDL_ttf-release-#{sdl_ttf_version}", 'SDL_ttf'
  extract "angle-main.zip", "angle-main", 'angle'

end


desc "Assemble C includes"
task :assemble_includes => :download_extract_libs do

  print_task "Assembling includes..."

  # Set and clean include directory, _except_ `GL/` which contains `glew.h` generated on Windows
  include_dir = "#{tmp_dir}/../include"
  FileUtils.mkdir_p include_dir
  FileUtils.rm_rf(Dir.glob("#{include_dir}/*") - Dir.glob("#{include_dir}/GL"))

  # mruby
  FileUtils.cp_r 'mruby/include/.', "#{include_dir}"

  # SDL
  FileUtils.mkdir_p "#{include_dir}/SDL2"
  FileUtils.cp Dir.glob('SDL/include/*.h'), "#{include_dir}/SDL2"
  FileUtils.cp 'SDL_image/SDL_image.h', "#{include_dir}/SDL2"
  FileUtils.cp 'SDL_mixer/include/SDL_mixer.h', "#{include_dir}/SDL2"
  FileUtils.cp 'SDL_ttf/SDL_ttf.h', "#{include_dir}/SDL2"

  # ANGLE
  FileUtils.cp_r 'angle/include/GLES2', include_dir
  FileUtils.cp_r 'angle/include/GLES3', include_dir
  FileUtils.cp_r 'angle/include/KHR', include_dir
  Dir.glob("#{include_dir}/**/.*").each { |f| File.delete(f) }
end


desc "Build mruby"
task :build_mruby => :download_extract_libs do

  print_task "Building mruby..."
  build_config = "#{tmp_dir}/../mruby/build_config.rb"

  Dir.chdir("#{tmp_dir}/mruby") do
    ENV['MRUBY_CONFIG'] = build_config
    run_cmd 'rake'
  end

  FileUtils.rm "#{build_config}.lock"

end


desc "Build mruby for WebAssembly"
task :build_mruby_wasm => :download_extract_libs do

  print_task "Building mruby..."
  build_config = "#{tmp_dir}/../mruby/build_config_wasm.rb"

  Dir.chdir("#{tmp_dir}/mruby") do
    ENV['MRUBY_CONFIG'] = build_config
    run_cmd 'rake'
  end

  wasm_dir = "#{tmp_dir}/../wasm"
  FileUtils.rm ["#{build_config}.lock", "#{wasm_dir}/libmruby.a"]
  FileUtils.cp "#{tmp_dir}/mruby/build/emscripten/lib/libmruby.a", wasm_dir
end


desc "Build and assemble macOS libs"
task :assemble_macos_libs => [:set_tmp_dir, :build_mruby] do

  unless RUBY2D_PLATFORM == :macos
    puts "Not macOS, skipping task...".warn
    next
  end

  print_task "Building and assembling macOS libs..."

  # Graphite — Download and build static library
  #   This SDL_ttf / HarfBuzz dependency has a bug in CMakeLists.txt which
  #   breaks static builds. This script here clones the library, removes the
  #   line causing the issue (see https://github.com/silnrsi/graphite/pull/54),
  #   and compiles with CMake. Hopefully this PR gets merged and a new version
  #   cut so we can get this library from Homebrew (like the others) and skip
  #   this workaround.
  run_cmd "brew install cmake"
  FileUtils.rm_rf "#{tmp_dir}/graphite"
  run_cmd "git clone https://github.com/silnrsi/graphite.git"
  Dir.chdir "#{tmp_dir}/graphite"
  run_cmd "git checkout 2f45277584beae312f1f4eea2b8706c44a4ae8d2"
  run_cmd "sed -i '' 128d src/CMakeLists.txt"  # delete infected line 128

  graphite_build_dir = "#{tmp_dir}/graphite/build"
  FileUtils.mkdir_p graphite_build_dir
  Dir.chdir graphite_build_dir
  run_cmd "cmake .. -DBUILD_SHARED_LIBS=OFF"
  run_cmd "make"

  Dir.chdir tmp_dir
  ### End Graphite static build

  # libavif — Download and build static library
  #   The Homebrew formula doesn't currently create static libs, so have do do
  #   this instead.
  FileUtils.rm_rf "#{tmp_dir}/libavif"
  run_cmd "git clone https://github.com/AOMediaCodec/libavif.git"
  Dir.chdir "#{tmp_dir}/libavif"
  run_cmd "git checkout tags/v0.11.1"

  libavif_build_dir = "#{tmp_dir}/libavif/build"
  FileUtils.mkdir_p libavif_build_dir
  Dir.chdir libavif_build_dir
  run_cmd "cmake .. -DBUILD_SHARED_LIBS=OFF"
  run_cmd "make"

  Dir.chdir tmp_dir
  ### End libavif static build

  # Highway — Download and build static library
  #   The Homebrew formula doesn't currently create static libs, so have do do
  #   this instead.
  run_cmd "git clone https://github.com/google/highway.git"
  Dir.chdir "#{tmp_dir}/highway"
  run_cmd "git checkout tags/v1.0.2"

  highway_build_dir = "#{tmp_dir}/highway/build_dir"
  FileUtils.mkdir_p highway_build_dir
  Dir.chdir highway_build_dir
  run_cmd "cmake .. -DBUILD_SHARED_LIBS=OFF -DHWY_ENABLE_CONTRIB=OFF -DHWY_ENABLE_TESTS=OFF -DHWY_ENABLE_EXAMPLES=OFF"
  run_cmd "make"

  Dir.chdir tmp_dir
  ### End Highway static build

  # Install SDL libs
  run_cmd "brew install sdl2 sdl2_image sdl2_mixer sdl2_ttf"

  # Save the machine architecture
  arch = `uname -m`.strip

  # Clean out files for current architecture
  macos_dir = "#{tmp_dir}/../macos"
  bin_dir = "#{macos_dir}/#{arch}/bin"
  lib_dir = "#{macos_dir}/#{arch}/lib"
  FileUtils.rm_rf Dir.glob("#{macos_dir}/#{arch}/*")
  FileUtils.mkdir_p bin_dir
  FileUtils.mkdir_p lib_dir

  # Set Homebrew paths
  brew_cellar = `brew --cellar`.strip

  # Copy over SDL libraries from Homebrew
  FileUtils.cp [
    # SDL
    Dir.glob("#{brew_cellar}/sdl2/*/lib/libSDL2.a")[0],

    # SDL_image
    Dir.glob("#{brew_cellar}/sdl2_image/*/lib/libSDL2_image.a")[0],
    Dir.glob("#{brew_cellar}/jpeg-turbo/*/lib/libjpeg.a")[0],
    Dir.glob("#{brew_cellar}/jpeg-xl/*/lib/libjxl.a")[0],
    Dir.glob("#{brew_cellar}/brotli/*/lib/libbrotlicommon-static.a")[0],
    Dir.glob("#{brew_cellar}/brotli/*/lib/libbrotlidec-static.a")[0],
    Dir.glob("#{brew_cellar}/libpng/*/lib/libpng.a")[0],
    Dir.glob("#{brew_cellar}/libtiff/*/lib/libtiff.a")[0],
    Dir.glob("#{brew_cellar}/zstd/*/lib/libzstd.a")[0],
    Dir.glob("#{brew_cellar}/webp/*/lib/libwebp.a")[0],
    Dir.glob("#{tmp_dir}/libavif/build/libavif.a")[0],
    Dir.glob("#{tmp_dir}/highway/build_dir/libhwy.a")[0],

    # SDL_mixer
    Dir.glob("#{brew_cellar}/sdl2_mixer/*/lib/libSDL2_mixer.a")[0],
    Dir.glob("#{brew_cellar}/mpg123/*/lib/libmpg123.a")[0],
    Dir.glob("#{brew_cellar}/libogg/*/lib/libogg.a")[0],
    Dir.glob("#{brew_cellar}/flac/*/lib/libFLAC.a")[0],
    Dir.glob("#{brew_cellar}/libvorbis/*/lib/libvorbis.a")[0],
    Dir.glob("#{brew_cellar}/libvorbis/*/lib/libvorbisfile.a")[0],
    Dir.glob("#{brew_cellar}/libmodplug/*/lib/libmodplug.a")[0],

    # SDL_ttf
    Dir.glob("#{brew_cellar}/sdl2_ttf/*/lib/libSDL2_ttf.a")[0],
    Dir.glob("#{brew_cellar}/freetype/*/lib/libfreetype.a")[0],
    Dir.glob("#{brew_cellar}/harfbuzz/*/lib/libharfbuzz.a")[0],
    Dir.glob("#{tmp_dir}/graphite/build/src/libgraphite2.a")[0]
  ], lib_dir

  # mruby
  mruby_build_dir = "#{tmp_dir}/mruby/build/host"
  FileUtils.cp "#{mruby_build_dir}/bin/mrbc", bin_dir
  FileUtils.cp "#{mruby_build_dir}/lib/libmruby.a", lib_dir

  # Make universal libraries by combining x86_64 and arm64 versions into one file
  def make_universal(file_path, this_arch, other_arch)
    other_arch_file = file_path.sub(this_arch, other_arch)  # create file path for other architecture...
    universal_file = file_path.sub(this_arch, 'universal')  # ...and universal architecture
    run_cmd "lipo #{file_path} #{other_arch_file} -create -output #{universal_file}"
    run_cmd "lipo -info #{universal_file}"
  end

  # Pick the other machine architecture (e.g. if on x86_64, will pick arm64)
  other_arch = arch == 'x86_64' ? 'arm64' : 'x86_64'
  FileUtils.mkdir_p "#{macos_dir}/#{other_arch}/lib"

  # If the other architecture lib directory has files in it, create universal versions
  if !Dir.empty? "#{macos_dir}/#{other_arch}/lib"
    print_task "Creating universal macOS libs..."
    # If libraries from the other architecture is present, merge them to create a universal file
    FileUtils.rm_rf Dir.glob("#{macos_dir}/universal/*")
    FileUtils.mkdir_p "#{macos_dir}/universal/lib"
    Dir.glob("#{macos_dir}/#{arch}/lib/*").each do |lib|
      make_universal(lib, arch, other_arch)
    end

    FileUtils.mkdir_p "#{macos_dir}/universal/bin"
    make_universal("#{bin_dir}/mrbc", arch, other_arch)
  else
    print_task "Only #{arch} is present, skipping universal macOS lib creation...\n"\
               "Run on a #{other_arch} Mac to create universal libs"
  end

  # Make files world readable on macOS, if needed
  ['../windows/mingw-w64-ucrt-x86_64/bin',
   '../windows/mingw-w64-ucrt-x86_64/lib',
   '../windows/mingw-w64-x86_64/bin',
   '../windows/mingw-w64-x86_64/lib'].each do |dir|
    run_cmd("chmod -R +r #{dir}")
  end
end


# This is a separate task so it can be run before others. On a new RubyInstaller
# installation, the shell may need to be restarted after package updates, so
# this gets it out of the way first thing.
desc "Update MinGW packages"
task :update_mingw_packages do
  if RUBY2D_PLATFORM == :windows
    run_cmd "pacman -Syu --noconfirm"
  end
end


desc "Build and assemble Windows libs"
task :assemble_windows_libs => [:set_tmp_dir, :build_mruby] do

  unless RUBY2D_PLATFORM == :windows
    puts "Not Windows (MinGW), skipping task...".warn
    next
  end

  # Install SDL2 libraries

  if `ruby -v` =~ /ucrt/
    arch = 'mingw-w64-ucrt-x86_64'
    ucrt = true
  else
    arch = 'mingw-w64-x86_64'
    ucrt = false
  end

  run_cmd "pacman -S --noconfirm #{arch}-SDL2 #{arch}-SDL2_image #{arch}-SDL2_mixer #{arch}-SDL2_ttf #{arch}-glew"

  # Clean out files for current architecture
  windows_dir = "#{tmp_dir}/../windows"
  bin_dir = "#{windows_dir}/#{arch}/bin"
  lib_dir = "#{windows_dir}/#{arch}/lib"
  FileUtils.rm_rf Dir.glob("#{windows_dir}/#{arch}/*")
  FileUtils.mkdir_p bin_dir
  FileUtils.mkdir_p lib_dir

  # Location where pacman installs MinGW libraries
  # !!! Use UCRT for Ruby 3.1+ !!!
  if ucrt
    pacman_dir = "C:/Ruby31-x64/msys64/ucrt64"
  else
    pacman_dir = "C:/Ruby30-x64/msys64/mingw64"
  end

  pacman_include_dir = "#{pacman_dir}/include"
  pacman_lib_dir = "#{pacman_dir}/lib"

  # Copy over SDL libraries
  FileUtils.cp [

    # SDL
    "#{pacman_lib_dir}/libSDL2.a",

    # SDL_image
    "#{pacman_lib_dir}/libSDL2_image.a",
    "#{pacman_lib_dir}/libjpeg.a",
    "#{pacman_lib_dir}/libpng.a",
    "#{pacman_lib_dir}/libtiff.a",
    "#{pacman_lib_dir}/libwebp.a",
    "#{pacman_lib_dir}/libjxl.a",
    "#{pacman_lib_dir}/libhwy.a",
    "#{pacman_lib_dir}/libjbig.a",
    "#{pacman_lib_dir}/libdeflate.a",
    "#{pacman_lib_dir}/liblzma.a",
    "#{pacman_lib_dir}/libzstd.a",
    "#{pacman_lib_dir}/libLerc.a",

    # SDL_mixer
    "#{pacman_lib_dir}/libSDL2_mixer.a",
    "#{pacman_lib_dir}/libmpg123.a",
    "#{pacman_lib_dir}/libFLAC.a",
    "#{pacman_lib_dir}/libvorbis.a",
    "#{pacman_lib_dir}/libvorbisfile.a",
    "#{pacman_lib_dir}/libogg.a",
    "#{pacman_lib_dir}/libmodplug.a",
    "#{pacman_lib_dir}/libopus.a",
    "#{pacman_lib_dir}/libopusfile.a",
    "#{pacman_lib_dir}/libsndfile.a",

    # SDL_ttf
    "#{pacman_lib_dir}/libSDL2_ttf.a",
    "#{pacman_lib_dir}/libfreetype.a",
    "#{pacman_lib_dir}/libharfbuzz.a",
    "#{pacman_lib_dir}/libgraphite2.a",
    "#{pacman_lib_dir}/libbz2.a",
    "#{pacman_lib_dir}/libbrotlicommon.a",
    "#{pacman_lib_dir}/libbrotlidec.a",

    # Other dependencies
    "#{pacman_lib_dir}/libz.a",
    "#{pacman_lib_dir}/libstdc++.a",
    "#{pacman_lib_dir}/libssp.a",
    "#{pacman_lib_dir}/libglew32.a"

  ], lib_dir

  # glew header
  assets_include_dir = "#{tmp_dir}/../include"
  FileUtils.rm_f "#{assets_include_dir}/GL/glew.h"
  FileUtils.mkdir_p "#{assets_include_dir}/GL"
  FileUtils.cp "#{pacman_include_dir}/GL/glew.h", "#{assets_include_dir}/GL"

  # mruby
  mruby_build_dir = "#{tmp_dir}/mruby/build/host"
  FileUtils.cp "#{mruby_build_dir}/bin/mrbc.exe", bin_dir
  FileUtils.cp "#{mruby_build_dir}/lib/libmruby.a", lib_dir
end


# Helper tasks

desc "Remove Xcode user data"
task :remove_xcode_user_data do
  print_task "Removing Xcode user data..."
  run_cmd "find ./xcode -name \"xcuserdata\" -type d -exec rm -r \"{}\" \\;"
end
