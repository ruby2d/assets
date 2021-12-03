# Library dependency versions — update these when new releases are available
mruby_version     = '3.0.0'
sdl_version       = '2.0.16'
sdl_image_version = '2.0.5'
sdl_mixer_version = '2.0.4'
sdl_ttf_version   = '2.0.15'
glew_version      = '2.1.0'

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


desc "Update all assets"
task :update => [
  :set_up_tmp_dir,
  :download_extract_libs,
  :assemble_includes,
  :assemble_mingw_libs,
  :assemble_macos_libs
] do
  puts "\n😎 All assets updated!\n".success
end


desc 'Create and set the temporary working directory'
task :set_up_tmp_dir do
  print_task 'Creating and setting `tmp/` directory'

  # Create dir and enter
  FileUtils.mkdir_p 'tmp'
  Dir.chdir 'tmp'

  # Save the dir location
  tmp_dir = Dir.pwd

  # Delete only folders from the
  FileUtils.rm_rf Dir.glob('tmp/*/')
end


desc "Download and extract libraries"
task :download_extract_libs => :set_up_tmp_dir do

  # Library URLs
  mruby_release = "https://github.com/mruby/mruby/archive/refs/tags/#{mruby_version}.zip"

  sdl_src = "https://www.libsdl.org/release/SDL2-#{sdl_version}.tar.gz"
  sdl_mingw = "https://www.libsdl.org/release/SDL2-devel-#{sdl_version}-mingw.tar.gz"

  sdl_image_src = "https://www.libsdl.org/projects/SDL_image/release/SDL2_image-#{sdl_image_version}.tar.gz"
  sdl_image_mingw = "https://www.libsdl.org/projects/SDL_image/release/SDL2_image-devel-#{sdl_image_version}-mingw.tar.gz"

  sdl_mixer_src = "https://www.libsdl.org/projects/SDL_mixer/release/SDL2_mixer-#{sdl_mixer_version}.tar.gz"
  sdl_mixer_mingw = "https://www.libsdl.org/projects/SDL_mixer/release/SDL2_mixer-devel-#{sdl_mixer_version}-mingw.tar.gz"

  sdl_ttf_src = "https://www.libsdl.org/projects/SDL_ttf/release/SDL2_ttf-#{sdl_ttf_version}.tar.gz"
  sdl_ttf_mingw = "https://www.libsdl.org/projects/SDL_ttf/release/SDL2_ttf-devel-#{sdl_ttf_version}-mingw.tar.gz"

  glew_src = "https://github.com/nigels-com/glew/archive/glew-#{glew_version}.zip"
  glew_release = "https://github.com/nigels-com/glew/releases/download/glew-#{glew_version}/glew-#{glew_version}-win32.zip"

  # Download libs

  def download(lib_name, url, filename)
    if File.exist? filename
      print_task "#{lib_name} already downloaded..."
    else
      print_task "Downloading #{lib_name}..."
      run_cmd "curl -L #{url} -o #{filename}"
    end
  end

  download 'mruby release', mruby_release, "mruby-#{mruby_version}.zip"

  download 'SDL2 source', sdl_src, "SDL2-#{sdl_version}.tar.gz"
  download 'SDL2 MinGW', sdl_mingw, "SDL2-mingw-#{sdl_version}.tar.gz"

  download 'SDL2_image source', sdl_image_src, "SDL2_image-#{sdl_image_version}.tar.gz"
  download 'SDL2_image MinGW', sdl_image_mingw, "SDL2_image-mingw-#{sdl_image_version}.tar.gz"

  download 'SDL2_mixer source', sdl_mixer_src, "SDL2_mixer-#{sdl_mixer_version}.tar.gz"
  download 'SDL2_mixer MinGW', sdl_mixer_mingw, "SDL2_mixer-mingw-#{sdl_mixer_version}.tar.gz"

  download 'SDL2_ttf source', sdl_ttf_src, "SDL2_ttf-#{sdl_ttf_version}.tar.gz"
  download 'SDL2_ttf MinGW', sdl_ttf_mingw, "SDL2_ttf-mingw-#{sdl_ttf_version}.tar.gz"

  download 'GLEW source', glew_src, "glew-#{glew_version}.zip"
  download 'GLEW release', glew_release, "glew-release-#{glew_version}.zip"

  # Extract and rename directories

  def extract(filename, extracted_filename, rename_to)
    if File.exists? rename_to
      print_task "#{filename} already extracted..."
    else
      print_task "Extracting #{filename}..."

      if filename.include? '.tar.gz'
        run_cmd "tar -xzf #{filename}"
      else
        run_cmd "unzip -q #{filename}"
      end

      File.rename extracted_filename, rename_to
    end
  end

  extract "mruby-#{mruby_version}.zip", "mruby-#{mruby_version}", 'mruby'

  extract "SDL2-#{sdl_version}.tar.gz", "SDL2-#{sdl_version}", 'SDL'
  extract "SDL2-mingw-#{sdl_version}.tar.gz", "SDL2-#{sdl_version}", 'SDL-mingw'

  extract "SDL2_image-#{sdl_image_version}.tar.gz", "SDL2_image-#{sdl_image_version}", 'SDL_image'
  extract "SDL2_image-mingw-#{sdl_image_version}.tar.gz", "SDL2_image-#{sdl_image_version}", 'SDL_image-mingw'

  extract "SDL2_mixer-#{sdl_mixer_version}.tar.gz", "SDL2_mixer-#{sdl_mixer_version}", 'SDL_mixer'
  extract "SDL2_mixer-mingw-#{sdl_mixer_version}.tar.gz", "SDL2_mixer-#{sdl_mixer_version}", 'SDL_mixer-mingw'

  extract "SDL2_ttf-#{sdl_ttf_version}.tar.gz", "SDL2_ttf-#{sdl_ttf_version}", 'SDL_ttf'
  extract "SDL2_ttf-mingw-#{sdl_ttf_version}.tar.gz", "SDL2_ttf-#{sdl_ttf_version}", 'SDL_ttf-mingw'

  extract "glew-#{glew_version}.zip", "glew-glew-#{glew_version}", 'glew'
  extract "glew-release-#{glew_version}.zip", "glew-#{glew_version}", 'glew-release'

end


desc "Assemble C includes"
task :assemble_includes => :download_extract_libs do

  print_task "Assembling includes..."

  # Set and clean include directory
  include_dir = "#{tmp_dir}/../include"
  FileUtils.rm_rf Dir.glob('include/*')

  # mruby
  FileUtils.cp_r 'mruby/include/.', "#{include_dir}"

  # SDL
  FileUtils.mkdir_p "#{include_dir}/SDL2"
  FileUtils.cp Dir.glob('SDL/include/*.h'), "#{include_dir}/SDL2"
  FileUtils.cp 'SDL_image/SDL_image.h', "#{include_dir}/SDL2"
  FileUtils.cp 'SDL_mixer/SDL_mixer.h', "#{include_dir}/SDL2"
  FileUtils.cp 'SDL_ttf/SDL_ttf.h', "#{include_dir}/SDL2"

  # GLEW
  FileUtils.cp 'glew-release/include/GL/glew.h', include_dir

end


desc "Assemble MinGW libs"
task :assemble_mingw_libs => :download_extract_libs do

  print_task "Assembling MinGW libs..."

  mingw_dir = "#{tmp_dir}/../mingw"
  mingw_bin_dir = "#{mingw_dir}/bin"
  mingw_lib_dir = "#{mingw_dir}/lib"

  FileUtils.mkdir_p [mingw_bin_dir, mingw_lib_dir]
  FileUtils.rm_rf Dir.glob("#{mingw_bin_dir}/*")
  FileUtils.rm_rf Dir.glob("#{mingw_lib_dir}/*")

  ['SDL-mingw', 'SDL_image-mingw', 'SDL_mixer-mingw', 'SDL_ttf-mingw'].each do |lib|
    FileUtils.cp Dir.glob("#{lib}/x86_64-w64-mingw32/bin/*.dll"), mingw_bin_dir
    FileUtils.cp Dir.glob("#{lib}/x86_64-w64-mingw32/lib/*.a"), mingw_lib_dir
  end

  FileUtils.cp "#{mingw_dir}/glew/glew32.dll", mingw_bin_dir
  FileUtils.cp ["#{mingw_dir}/glew/libglew32.a", "#{mingw_dir}/glew/libglew32.dll.a"], mingw_lib_dir

end


desc "Build and assemble macOS libs"
task :assemble_macos_libs => [:download_extract_libs, :uninstall_sdl_homebrew] do

  unless RUBY2D_PLATFORM == :macos
    puts "Not macOS, skipping task...\n".warn
    next
  end

  print_task "Building and assembling macOS libs..."

  # Install custom `mpg123` and `libmodplug` to get static libraries and linking
  homebrew_dir = "#{tmp_dir}/../homebrew"
  run_cmd "brew install --formula #{homebrew_dir}/mpg123.rb"
  run_cmd "brew install --formula #{homebrew_dir}/libmodplug.rb"

  # Install SDL libs
  run_cmd "brew install sdl2 sdl2_image sdl2_mixer sdl2_ttf"

  # Set Homebrew paths
  brew_cellar = `brew --cellar`.strip
  brew_sdl_dir = Dir.glob("#{brew_cellar}/sdl2/#{sdl_version}*")[0]
  brew_sdl_image_dir = Dir.glob("#{brew_cellar}/sdl2_image/#{sdl_image_version}*")[0]
  brew_sdl_mixer_dir = Dir.glob("#{brew_cellar}/sdl2_mixer/#{sdl_mixer_version}*")[0]
  brew_sdl_ttf_dir = Dir.glob("#{brew_cellar}/sdl2_ttf/#{sdl_ttf_version}*")[0]

  # Save the machine architecture
  arch = `uname -m`.strip

  # Clean out lib files for current architecture
  macos_dir = "#{tmp_dir}/../macos"
  FileUtils.mkdir_p "#{macos_dir}/#{arch}"
  FileUtils.rm_rf Dir.glob("#{macos_dir}/#{arch}/*")

  # Copy over SDL libraries from Homebrew
  FileUtils.cp [
    # SDL
    "#{brew_sdl_dir}/lib/libSDL2.a",

    # SDL_image
    "#{brew_sdl_image_dir}/lib/libSDL2_image.a",
    Dir.glob("#{brew_cellar}/jpeg/*/lib/libjpeg.a")[0],
    Dir.glob("#{brew_cellar}/libpng/*/lib/libpng16.a")[0],
    Dir.glob("#{brew_cellar}/libtiff/*/lib/libtiff.a")[0],
    Dir.glob("#{brew_cellar}/webp/*/lib/libwebp.a")[0],

    # SDL_mixer
    "#{brew_sdl_mixer_dir}/lib/libSDL2_mixer.a",
    Dir.glob("#{brew_cellar}/mpg123/*/lib/libmpg123.a")[0],
    Dir.glob("#{brew_cellar}/libogg/*/lib/libogg.a")[0],
    Dir.glob("#{brew_cellar}/flac/*/lib/libFLAC.a")[0],
    Dir.glob("#{brew_cellar}/libvorbis/*/lib/libvorbis.a")[0],
    Dir.glob("#{brew_cellar}/libvorbis/*/lib/libvorbisfile.a")[0],
    Dir.glob("#{brew_cellar}/libmodplug/*/lib/libmodplug.a")[0],

    # SDL_ttf
    "#{brew_sdl_ttf_dir}/lib/libSDL2_ttf.a",
    Dir.glob("#{brew_cellar}/freetype/*/lib/libfreetype.a")[0]
  ], "#{macos_dir}/#{arch}"

  # Make universal libraries by combining x86_64 and arm64 versions into one file
  def make_universal_libs(this_arch, other_arch, macos_dir)
    Dir.glob("#{macos_dir}/#{this_arch}/*").each do |lib|
      other_arch_lib = lib.sub(this_arch, other_arch)
      universal_lib = lib.sub(this_arch, 'universal')
      run_cmd "lipo #{lib} #{other_arch_lib} -create -output #{universal_lib}"
      run_cmd "lipo -info #{universal_lib}"
    end
  end

  # Pick the other machine architecture (e.g. if on x86_64, will pick arm64)
  other_arch = arch == 'x86_64' ? 'arm64' : 'x86_64'
  FileUtils.mkdir_p "#{macos_dir}/#{other_arch}"

  # If the other architecture lib directory has files in it, create universal versions
  if !Dir.empty? "#{macos_dir}/#{other_arch}"
    print_task "Creating universal macOS libs..."
    # If libraries from the other architecture is present, merge them to create a universal file
    FileUtils.mkdir_p "#{macos_dir}/universal"
    FileUtils.rm_rf Dir.glob("#{macos_dir}/universal/*")
    make_universal_libs(arch, other_arch, macos_dir)
  else
    print_task "Only #{arch} is present, skipping universal macOS lib creation..."
  end

end



desc "Build mruby"
task :build_mruby_wasm => :download_extract_libs do

  print_task "Building mruby for WebAssembly..."

  mruby_src_dir = "#{tmp_dir}/mruby"
  wasm_dir = "#{tmp_dir}/../wasm"

  Dir.chdir(mruby_src_dir) do
    ENV['MRUBY_CONFIG'] = "#{wasm_dir}/build_config.rb"
    run_cmd 'rake'

    FileUtils.cp 'build/emscripten/lib/libmruby.a', "#{wasm_dir}"
  end

end



desc "Uninstall all SDL2-related libs using Homebrew"
task :uninstall_sdl_homebrew do
  run_cmd 'brew uninstall --force '\
    'freetype '\
    'libogg flac libvorbis libmodplug mpg123 '\
    'jpeg libpng libtiff giflib webp '\
    'sdl2_ttf sdl2_mixer sdl2_image sdl2'
end


desc "Remove Xcode user data"
task :remove_xcode_user_data do
  print_task "Removing Xcode user data..."
  run_cmd "find ./xcode -name \"xcuserdata\" -type d -exec rm -r \"{}\" \\;"
end
