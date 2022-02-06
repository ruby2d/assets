# Library dependency versions — update these when new releases are available
mruby_version     = '3.0.0'
sdl_version       = '2.0.20'
sdl_image_version = '2.0.5'
sdl_mixer_version = '2.0.4'
sdl_ttf_version   = '2.0.15'

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
  :set_tmp_dir,
  :download_extract_libs,
  :assemble_includes,
  :assemble_macos_libs,
  :assemble_mingw_libs
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

  # Clean out tmp dir if already exists
  FileUtils.rm_rf Dir.glob("#{tmp_dir}/*")

  # Library URLs
  mruby_url = "https://github.com/mruby/mruby/archive/refs/tags/#{mruby_version}.zip"
  sdl_url = "https://github.com/libsdl-org/SDL/archive/refs/tags/release-#{sdl_version}.zip"
  sdl_image_url = "https://github.com/libsdl-org/SDL_image/archive/refs/tags/release-#{sdl_image_version}.zip"
  sdl_mixer_url = "https://github.com/libsdl-org/SDL_mixer/archive/refs/tags/release-#{sdl_mixer_version}.zip"
  sdl_ttf_url = "https://github.com/libsdl-org/SDL_ttf/archive/refs/tags/release-#{sdl_ttf_version}.zip"

  # Download libs

  def download(lib_name, url, filename)
    print_task "Downloading #{lib_name}..."
    run_cmd "curl -L #{url} -o #{filename}"
  end

  download 'mruby', mruby_url, "mruby-#{mruby_version}.zip"
  download 'SDL', sdl_url, "SDL-#{sdl_version}.zip"
  download 'SDL_image', sdl_image_url, "SDL_image-#{sdl_image_version}.zip"
  download 'SDL_mixer', sdl_mixer_url, "SDL_mixer-#{sdl_mixer_version}.zip"
  download 'SDL_ttf', sdl_ttf_url, "SDL_ttf-#{sdl_ttf_version}.zip"

  # Extract and rename directories

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

end


desc "Assemble C includes"
task :assemble_includes => :download_extract_libs do

  print_task "Assembling includes..."

  # Set and clean include directory
  include_dir = "#{tmp_dir}/../include"
  FileUtils.rm_rf Dir.glob("#{include_dir}/*")

  # mruby
  FileUtils.cp_r 'mruby/include/.', "#{include_dir}"

  # SDL
  FileUtils.mkdir_p "#{include_dir}/SDL2"
  FileUtils.cp Dir.glob('SDL/include/*.h'), "#{include_dir}/SDL2"
  FileUtils.cp 'SDL_image/SDL_image.h', "#{include_dir}/SDL2"
  FileUtils.cp 'SDL_mixer/SDL_mixer.h', "#{include_dir}/SDL2"
  FileUtils.cp 'SDL_ttf/SDL_ttf.h', "#{include_dir}/SDL2"

  # GLEW
  FileUtils.cp '../mingw/glew/glew.h', include_dir

end


desc "Uninstall all SDL2-related libs using Homebrew"
task :uninstall_sdl_homebrew do
  run_cmd 'brew uninstall --force '\
    'libmodplug mpg123 '\
    'sdl2_ttf sdl2_mixer sdl2_image sdl2'
end


desc "Build and assemble macOS libs"
task :assemble_macos_libs => [:set_tmp_dir, :uninstall_sdl_homebrew] do

  unless RUBY2D_PLATFORM == :macos
    puts "Not macOS, skipping task...".warn
    next
  end

  print_task "Building and assembling macOS libs..."

  # Install custom `mpg123` and `libmodplug` to get static libraries and linking
  homebrew_dir = "#{tmp_dir}/../homebrew"
  run_cmd "brew install --formula #{homebrew_dir}/mpg123.rb"
  run_cmd "brew install --formula #{homebrew_dir}/libmodplug.rb"
  run_cmd "export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1 && brew install --formula #{homebrew_dir}/sdl2_ttf.rb"

  # Install SDL libs
  run_cmd "brew install sdl2 sdl2_image sdl2_mixer"

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
    print_task "Only #{arch} is present, skipping universal macOS lib creation...\n"\
               "Run on a #{other_arch} Mac to create universal libs"
  end

end


desc "Build and assemble Windows (MinGW) libs"
task :assemble_mingw_libs => :set_tmp_dir do

  unless RUBY2D_PLATFORM == :windows
    puts "Not Windows (MinGW), skipping task...".warn
    next
  end

end


# Helper tasks

desc "Remove Xcode user data"
task :remove_xcode_user_data do
  print_task "Removing Xcode user data..."
  run_cmd "find ./xcode -name \"xcuserdata\" -type d -exec rm -r \"{}\" \\;"
end
