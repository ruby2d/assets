require 'yaml'
require_relative 'target'

# Load pinned dependency versions from deps.yaml — updated by `rake update`
DEPS = YAML.load_file(File.join(__dir__, 'deps.yaml'))

SDL_NAMES = %w[SDL SDL_image SDL_mixer SDL_ttf]

# Key directories (resolved from host OS/arch/toolchain, or env overrides)
HOST_OS      = AssetsTarget.host_os       # e.g. "macos", "windows"
SOURCES_DIR  = AssetsTarget.sources_dir   # assets/sources
PLATFORM_DIR = AssetsTarget.platform_dir  # assets/platform/{os}-{arch}[-{toolchain}]
INCLUDE_DIR  = AssetsTarget.include_dir   # assets/platform/include (shared headers)
BUILD_DIR    = AssetsTarget.build_dir     # assets/build/{target_id}
WASM_BUILD_DIR = AssetsTarget.wasm_build_dir
WASM_LIB_DIR = File.join(AssetsTarget.wasm_platform_dir, 'lib')  # assets/platform/wasm/lib


# Helpers ######################################################################

# Extend `String` to include some fancy colors
class String
  def ruby2d_colorize(c); "\e[#{c}m#{self}\e[0m" end
  def bold;      ruby2d_colorize('1')               end
  def dim;       ruby2d_colorize('2')               end
  def info;      ruby2d_colorize('1;34')            end
  def warning;   ruby2d_colorize('1;33')            end
  def success;   ruby2d_colorize('1;32')            end
  def error;     ruby2d_colorize('1;31')            end
  def ruby2d_red; ruby2d_colorize('38;2;246;60;56') end
end

# Platform-specific linker flags
PLATFORM_LIBS = case HOST_OS
when 'macos'
  %w[
    AVFoundation AudioToolbox Carbon Cocoa CoreAudio CoreHaptics
    CoreMedia ForceFeedback GameController IOKit Metal QuartzCore
    UniformTypeIdentifiers
  ].map { |fw| "-framework #{fw}" }.join(' ')
when 'windows'
  '-lhid -lsetupapi -lole32 -loleaut32 -luuid -lgdi32 -luser32 -lwinmm -lusp10 -limm32 -lversion -lrpcrt4'
when 'linux'
  # SDL loads most features dynamically at runtime (dlopen), so we only need
  # libc-adjacent libs here; -ldl/-lpthread are no-ops on glibc >= 2.34
  '-lm -ldl -lpthread'
end

LIBS = "-lSDL3 -lSDL3_image -lSDL3_mixer -lSDL3_ttf #{PLATFORM_LIBS}"

# A task banner: ruby-red diamond + bold title. The leading "\n" owns the blank
# before it; whatever follows (a run_cmd echo, the next banner, or a message
# with its own leading "\n") supplies the gap after. In the rare case a banner
# is followed directly by self-printed prose, add a `puts` at that call site.
def print_task(task)
  print "\n", "  #{'◆'.ruby2d_red} #{task.bold}", "\n"
end

# Run system command
def run_cmd(cmd)
  puts "  #{"$ #{cmd}".dim}\n\n"
  system(cmd) || exit(1)
rescue Interrupt
  # Ctrl-C — the user stopped the running command (e.g. the `launch` web
  # server). Exit quietly with the conventional SIGINT status (130) instead of
  # dumping a backtrace.
  exit(130)
end

# Print a produced-file line: dim "wrote" + the path, indented under a banner
def wrote(path)
  puts "    #{'wrote'.dim} #{path}"
end

# Check if a command is available on PATH (cached)
$cmd_cache = {}
def cmd_available?(cmd)
  $cmd_cache.fetch(cmd) do
    result =
      if HOST_OS == 'windows'
        system("where #{cmd} >NUL 2>&1")
      else
        system("command -v #{cmd} >/dev/null 2>&1")
      end
    $cmd_cache[cmd] = result
  end
end

# Guard that aborts if a required command is missing
def require_cmd!(cmd, error_msg = nil)
  return true if cmd_available?(cmd)

  abort("#{'Error:'.error} #{error_msg || "#{cmd} is not installed or not found in PATH"}")
end

# Whether an Emscripten toolchain is available for WASM builds
def emscripten_available?
  cmd_available?('emcc') && cmd_available?('emcmake')
end

# Windows build tools (git + cmake) come from MSYS2, which is bundled with the
# RubyInstaller Devkit but doesn't install these by default. The cmake package
# name differs by architecture; git is the same on both.
WINDOWS_PACMAN_PACKAGES = {
  'x86_64' => %w[git mingw-w64-ucrt-x86_64-cmake],
  'arm64'  => %w[git mingw-w64-clang-aarch64-cmake],
}.freeze

# On Windows, check for git and cmake up front and offer to install them via
# pacman rather than failing partway through a build. No-op on other platforms
# (the per-task `require_cmd!` guards still apply there).
def check_windows_build_tools!
  return unless HOST_OS == 'windows'

  missing = %w[git cmake].reject { |c| cmd_available?(c) }
  return if missing.empty?

  packages = WINDOWS_PACMAN_PACKAGES[AssetsTarget.host_arch]
  pkg_list = packages&.join(' ')

  puts "\n#{'Missing build tools:'.warning} #{missing.join(', ')}"
  puts "These come from MSYS2, bundled with the RubyInstaller Devkit."

  # RubyInstaller exposes MSYS2's pacman via `ridk exec`; fall back to a bare
  # `pacman` if it's already on PATH (e.g. running inside an MSYS2 shell).
  runner =
    if    cmd_available?('ridk')   then 'ridk exec pacman'
    elsif cmd_available?('pacman') then 'pacman'
    end

  # Can't drive pacman (no ridk/pacman) or unknown arch — print instructions and stop.
  if runner.nil? || pkg_list.nil?
    puts "\nInstall them manually, then re-run:"
    puts "  #{"pacman -S #{pkg_list || 'git <cmake-package>'}".dim}"
    abort "#{'Error:'.error} git and cmake are required to build."
  end

  puts "Install with: #{"pacman -S #{pkg_list}".dim}"
  print "\nInstall them now? [y/N] "
  answer = $stdin.gets&.strip
  unless answer&.downcase == 'y'
    abort "#{'Error:'.error} git and cmake are required to build. Install the packages above and re-run."
  end

  install_cmd = "#{runner} -S --needed --noconfirm #{pkg_list}"
  print_task "Installing build tools"
  puts "  #{"$ #{install_cmd}".dim}\n\n"
  install_ok = system(install_cmd)

  # Freshly installed tools land in an MSYS2 bin already on PATH, so clear the
  # (negative) cache and re-check rather than trusting the earlier result.
  $cmd_cache.clear
  still_missing = %w[git cmake].reject { |c| cmd_available?(c) }

  unless install_ok && still_missing.empty?
    detail = still_missing.empty? ? '' : " (#{still_missing.join(', ')} still not on PATH)"
    abort "#{'Error:'.error} Couldn't install build tools automatically#{detail}.\n" \
          "  Run #{"pacman -S #{pkg_list}".dim} in an MSYS2 shell, then re-run.\n" \
          "  You may need to open a new terminal so the tools are picked up on PATH."
  end

  puts "\n#{'Build tools ready!'.success}"
end

# Clone a repo at a specific tag (shallow), re-cloning if the tag has changed.
# When $skip_source_updates is set, existing sources are left as-is (only
# missing sources are cloned) — used by the default `rake` task.
def clone_at_tag(name, url, tag, dir, recurse_submodules: false)
  if Dir.exist?(dir)
    return if $skip_source_updates
    current_tag = `git -C #{dir} describe --tags --exact-match 2>/dev/null`.strip
    return if current_tag == tag
    print_task "Re-cloning #{name} (#{current_tag.empty? ? '?' : current_tag} -> #{tag})"
    FileUtils.rm_rf dir
  else
    print_task "Cloning #{name} at #{tag}"
  end
  FileUtils.mkdir_p(File.dirname(dir))
  cmds = ["git clone --branch #{tag} --depth 1 #{url} #{dir}"]
  if recurse_submodules
    cmds << "git -C #{dir} submodule update --init --recursive --depth 1"
  end
  cmds.each { |cmd| run_cmd cmd }
end


# Tasks ########################################################################

task default: :all

# Preflight tool check (Windows: offer to install git/cmake via pacman). Listed
# as a prerequisite of the build tasks below so it runs before any download or
# build step. Rake invokes it at most once per run; no-op on non-Windows hosts.
task :preflight do
  check_windows_build_tools!
end

desc 'List commands'
task :list do
  puts `rake -T`
end

desc "Clean and build everything from source (prompts before running)"
task :all do
  puts
  puts "Clean and build everything from source".bold
  puts
  puts "This will:".bold
  puts "  • Clean build artifacts for this target (#{AssetsTarget.target_id}) and WASM"
  puts "  • Build SDL libraries (SDL, SDL_image, SDL_mixer, SDL_ttf)"
  puts "  • Build mruby"
  puts "  • Build WASM libraries (only if Emscripten is available)"
  puts
  puts "This will NOT:".warning
  puts "  • Run `update` — pinned dependencies may be out of date"
  puts "    (run `rake update` to check for and apply newer versions)"
  puts "  • Update existing sources — missing sources will be cloned at"
  puts "    their pinned versions, but existing sources are left untouched"
  puts "  • Clean other targets or start fresh — to wipe EVERY target's"
  puts "    artifacts and all sources, run `rake clean:all` first"
  puts
  puts "This can take several minutes."

  print "\nContinue? [y/N] "
  answer = $stdin.gets&.strip
  unless answer&.downcase == 'y'
    puts "Cancelled."
    next
  end

  # Ensure build tools are present before doing any work (Windows: offer to
  # install git/cmake). Runs before `clean` so nothing happens if tools are
  # missing and the user declines to install.
  Rake::Task[:preflight].invoke

  # Leave existing sources untouched; only clone what's missing
  $skip_source_updates = true

  Rake::Task[:clean].invoke
  Rake::Task[:build].invoke
end

desc "Build all libraries (SDL + mruby, plus WASM if Emscripten is available)"
task build: [:preflight, :sdl, :mruby] do
  # Build WASM too, but only if Emscripten is available — otherwise skip with a notice
  if emscripten_available?
    Rake::Task[:wasm].invoke
  else
    puts "\n#{'Warning:'.warning} Skipping WASM build — Emscripten not found (run `rake wasm` after sourcing emsdk_env.sh)"
  end

  puts "\n#{'All done!'.success}"

  # Native platform artifacts
  libs = Dir.glob(File.join(PLATFORM_DIR, 'lib', '*.a')).map { |f| File.basename(f) }.sort
  bins = Dir.glob(File.join(PLATFORM_DIR, 'bin', '*')).map { |f| File.basename(f) }.sort

  unless libs.empty? && bins.empty?
    puts "\n  #{"Native (#{AssetsTarget.target_id})".bold}"
    libs.each { |f| puts "    lib/#{f}" }
    bins.each { |f| puts "    bin/#{f}" }
  end

  # WASM artifacts — list the main libs, summarize vendored
  wasm_main = %w[libSDL3.a libSDL3_image.a libSDL3_mixer.a libSDL3_ttf.a libmruby.a]
                .select { |f| File.exist?(File.join(WASM_LIB_DIR, f)) }
  wasm_vendored = Dir.glob(File.join(WASM_LIB_DIR, '*.a')).count - wasm_main.count

  unless wasm_main.empty?
    puts "\n  #{"WASM (platform/wasm/lib/)".bold}"
    wasm_main.each { |f| puts "    #{f}" }
    puts "    + #{wasm_vendored} vendored" if wasm_vendored > 0
  end

  puts ""
end

desc "Clean all build artifacts"
task clean: [:'sdl:clean', :'mruby:clean', :'wasm:clean']

namespace :clean do
  desc "Deep clean — remove EVERY target's build artifacts, WASM libs, and downloaded sources"
  task :all do
    print_task "Removing all build artifacts (every target + WASM)"
    FileUtils.rm_rf 'build'      # build/{target_id} for every target, plus build/wasm
    FileUtils.rm_rf 'platform'   # compiled libs/bins/headers for every target, plus platform/wasm

    print_task "Removing downloaded sources"
    FileUtils.rm_rf SOURCES_DIR  # re-downloaded on the next build (or `rake sdl:download` / `rake update`)
  end
end


# Update #######################################################################

desc "Check for newer tags and update sources + deps.yaml"
task :update do
  print_task "Checking for updates"
  require_cmd! 'git'

  updates = {}
  errors = {}
  threads = DEPS.map do |name, info|
    Thread.new do
      out = `git ls-remote --tags #{info['url']}`
      # $? is per-thread; check it immediately so a fetch failure isn't
      # mistaken for "no newer tags" (which would falsely read as up to date)
      unless $?.success?
        errors[name] = "could not reach #{info['url']}"
        next
      end

      tags = out.lines
                .map { |l| l.split("\t").last.strip.sub('refs/tags/', '') }
                .reject { |t| t.end_with?('^{}') }

      latest = if SDL_NAMES.include?(name)
        # Only consider release-X.Y.Z tags (exclude prerelease-*)
        tags.select { |t| t.match?(/\Arelease-\d+\.\d+\.\d+\z/) }
            .max_by { |t| t.sub('release-', '').split('.').map(&:to_i) }
      else
        # Only consider clean version tags (e.g. 4.0.0), skip rc/alpha/beta
        tags.select { |t| t.match?(/\A\d+\.\d+\.\d+\z/) }
            .max_by { |t| t.split('.').map(&:to_i) }
      end

      updates[name] = latest if latest && latest != info['tag']
    end
  end
  threads.each(&:join)

  unless errors.empty?
    puts "\nCould not check some dependencies:".warning
    errors.each { |name, msg| puts "  #{name}: #{msg}" }
  end

  if updates.empty?
    puts "\nAll dependencies are up to date!".success if errors.empty?
    next
  end

  puts "\nUpdates available:".bold
  updates.each do |name, new_tag|
    puts "  #{name}: #{DEPS[name]['tag']} -> #{new_tag}"
  end

  print "\nApply updates? [y/N] "
  answer = $stdin.gets&.strip
  unless answer&.downcase == 'y'
    puts "Cancelled."
    next
  end

  # Update local clones
  updates.each do |name, new_tag|
    clone_at_tag(name, DEPS[name]['url'], new_tag,
      File.join(SOURCES_DIR, name), recurse_submodules: name != 'mruby')
  end

  # Update pinned tags in deps.yaml
  deps_path = File.join(__dir__, 'deps.yaml')
  deps = YAML.load_file(deps_path)
  updates.each { |name, new_tag| deps[name]['tag'] = new_tag }
  File.write(deps_path, YAML.dump(deps))

  puts "\nPinned tags updated in deps.yaml!".success
  puts "Run `rake build` to rebuild with the updated sources.".bold
end


# SDL ##########################################################################

desc "Download and build SDL libraries"
task sdl: [:preflight, :'sdl:download', :'sdl:build']

namespace :sdl do

  desc "Download SDL sources at pinned versions"
  task :download do
    require_cmd! 'git'

    threads = SDL_NAMES.map do |name|
      Thread.new do
        clone_at_tag(name, DEPS[name]['url'], DEPS[name]['tag'],
          File.join(SOURCES_DIR, name), recurse_submodules: true)
      end
    end
    threads.each(&:join)
  end

  desc "Build SDL libraries and copy headers/libs"
  task build: [:download, :clean] do
    require_cmd! 'cmake'

    SDL_NAMES.each do |lib|
      unless Dir.exist?(File.join(SOURCES_DIR, lib))
        puts "#{'Error:'.error} Missing #{lib}. Run `rake sdl:download` to download sources."
        exit 1
      end
    end

    print_task "Building SDL libraries"
    run_cmd "cmake -S build_support -B #{BUILD_DIR} -DRUBY2D_SOURCES_DIR=#{SOURCES_DIR}"
    run_cmd "cmake --build #{BUILD_DIR} --parallel"

    lib_dir = File.join(PLATFORM_DIR, 'lib')
    FileUtils.mkdir_p INCLUDE_DIR
    FileUtils.mkdir_p lib_dir

    # Copy headers and static libraries
    SDL_NAMES.each do |lib|
      sdl3_name = lib.sub('SDL', 'SDL3')
      FileUtils.cp_r File.join(SOURCES_DIR, lib, 'include', sdl3_name), INCLUDE_DIR
      FileUtils.cp File.join(BUILD_DIR, lib, "lib#{sdl3_name}.a"), lib_dir
    end
  end

  desc "Test SDL libraries"
  task :test do
    print_task "Testing SDL libraries"
    sdl_test_bin = File.join(BUILD_DIR, 'sdl_test')
    FileUtils.rm_f sdl_test_bin
    run_cmd "cc -I#{INCLUDE_DIR} build_support/sdl_test.c -L#{File.join(PLATFORM_DIR, 'lib')} #{LIBS} -o #{sdl_test_bin}"
    run_cmd sdl_test_bin
  end

  desc "Clean SDL build artifacts"
  task :clean do
    print_task "Cleaning SDL"
    FileUtils.rm_rf BUILD_DIR
    FileUtils.rm_rf Dir.glob(File.join(INCLUDE_DIR, 'SDL3*'))
    SDL_NAMES.each do |lib|
      FileUtils.rm_f File.join(PLATFORM_DIR, 'lib', "lib#{lib.sub('SDL', 'SDL3')}.a")
    end
  end
end


# mruby ########################################################################

desc "Download and build mruby"
task mruby: [:preflight, :'mruby:download', :'mruby:build']

namespace :mruby do

  desc "Download mruby source at pinned version"
  task :download do
    require_cmd! 'git'
    clone_at_tag('mruby', DEPS['mruby']['url'], DEPS['mruby']['tag'],
      File.join(SOURCES_DIR, 'mruby'))
  end

  desc "Build mruby and copy artifacts"
  task build: [:download, :clean] do
    print_task "Building mruby"

    mruby_src  = File.join(SOURCES_DIR, 'mruby')
    build_config = File.expand_path('build_support/mruby/build_config.rb', __dir__)

    # Stage the build config into the (writable) build dir and point mruby at the
    # copy, so mruby's `<config>.lock` and other scratch land there rather than
    # beside the shipped config — which sits in a possibly read-only gem when
    # invoked via `ruby2d setup`. The staged copy locates target.rb via
    # RUBY2D_TARGET_RB (see build_support/mruby/build_config.rb).
    staged_config = File.join(BUILD_DIR, 'mruby_build_config.rb')
    FileUtils.mkdir_p BUILD_DIR
    FileUtils.cp build_config, staged_config
    ENV['RUBY2D_TARGET_RB'] = File.expand_path('target.rb', __dir__)

    Dir.chdir(mruby_src) do
      ENV['MRUBY_CONFIG'] = staged_config
      run_cmd 'rake'
    end

    FileUtils.rm_f "#{staged_config}.lock"

    # Copy headers
    print_task "Copying mruby headers"
    mruby_build_dir = File.join(BUILD_DIR, 'mruby')
    presym_dir = File.join(INCLUDE_DIR, 'mruby', 'presym')
    FileUtils.mkdir_p INCLUDE_DIR
    FileUtils.cp_r File.join(mruby_src, 'include', 'mruby'), INCLUDE_DIR
    FileUtils.cp File.join(mruby_src, 'include', 'mruby.h'), INCLUDE_DIR
    FileUtils.cp File.join(mruby_src, 'include', 'mrbconf.h'), INCLUDE_DIR
    # Add pre-allocated symbol IDs from build
    FileUtils.mkdir_p presym_dir
    FileUtils.cp File.join(mruby_build_dir, 'include', 'mruby', 'presym', 'id.h'), presym_dir
    FileUtils.cp File.join(mruby_build_dir, 'include', 'mruby', 'presym', 'table.h'), presym_dir

    # Copy static library and compiler
    print_task "Copying mruby binaries"
    lib_dir = File.join(PLATFORM_DIR, 'lib')
    bin_dir = File.join(PLATFORM_DIR, 'bin')
    FileUtils.mkdir_p lib_dir
    FileUtils.mkdir_p bin_dir
    FileUtils.cp File.join(mruby_build_dir, 'lib', 'libmruby.a'), lib_dir
    mrbc_fname = HOST_OS == 'windows' ? 'mrbc.exe' : 'mrbc'
    FileUtils.cp File.join(mruby_build_dir, 'bin', mrbc_fname), bin_dir
  end

  desc "Clean mruby build artifacts"
  task :clean do
    print_task "Cleaning mruby"
    FileUtils.rm_rf File.join(BUILD_DIR, 'mruby')
    FileUtils.rm_rf Dir.glob(File.join(INCLUDE_DIR, 'mruby*'))
    FileUtils.rm_f File.join(INCLUDE_DIR, 'mrbconf.h')
    FileUtils.rm_f File.join(PLATFORM_DIR, 'lib', 'libmruby.a')
    FileUtils.rm_f File.join(PLATFORM_DIR, 'bin', 'mrbc')
    FileUtils.rm_f File.join(PLATFORM_DIR, 'bin', 'mrbc.exe')
  end
end


# WASM ##########################################################################

desc "Download and build all WASM libraries (SDL + mruby)"
task wasm: [:preflight, :'wasm:clean', :'wasm:sdl', :'wasm:mruby']

namespace :wasm do

  desc "Download and build SDL libraries for WASM"
  task sdl: [:'sdl:download', :'wasm:sdl:build']

  namespace :sdl do

    desc "Build SDL libraries for WASM and copy to platform/wasm/lib/"
    task :build do
      require_cmd! 'cmake'
      require_cmd! 'emcmake', 'Emscripten not found. Install the Emscripten SDK and source emsdk_env.sh'

      SDL_NAMES.each do |lib|
        unless Dir.exist?(File.join(SOURCES_DIR, lib))
          puts "#{'Error:'.error} Missing #{lib}. Run `rake sdl:download` to download sources."
          exit 1
        end
      end

      print_task "Building SDL libraries for WASM"
      run_cmd "emcmake cmake -S build_support -B #{WASM_BUILD_DIR} -DRUBY2D_SOURCES_DIR=#{SOURCES_DIR}"
      run_cmd "cmake --build #{WASM_BUILD_DIR} --parallel"

      FileUtils.mkdir_p WASM_LIB_DIR

      print_task "Copying WASM SDL libraries"
      SDL_NAMES.each do |lib|
        fname = "lib#{lib.sub('SDL', 'SDL3')}.a"
        FileUtils.cp File.join(WASM_BUILD_DIR, lib, fname), WASM_LIB_DIR
        wrote fname
      end

      # Copy vendored dependency libraries
      print_task "Copying WASM vendored libraries"
      vendored_libs = Dir.glob(File.join(WASM_BUILD_DIR, '*/external/**/*.a'))
      vendored_libs.each do |lib|
        dest = File.join(WASM_LIB_DIR, File.basename(lib))
        FileUtils.cp lib, dest
        wrote File.basename(lib)
      end
    end
  end

  desc "Download and build mruby for WASM"
  # Note: no :'mruby:build' prereq here. Written inside `namespace :wasm`, that
  # name resolves to wasm:mruby:build (Rake looks in the current scope first),
  # so it never triggered the native build it appears to. The cross build needs
  # a native mrbc; wasm:mruby:build guards for it and tells you to run `rake`.
  task mruby: [:'wasm:mruby:build']

  namespace :mruby do
    desc "Build mruby for WASM and copy to platform/wasm/lib/"
    task :build do
      require_cmd! 'emcc', 'Emscripten not found. Install the Emscripten SDK and source emsdk_env.sh'

      mruby_src = File.join(SOURCES_DIR, 'mruby')
      unless Dir.exist?(mruby_src)
        puts "#{'Error:'.error} Missing mruby source. Run `rake mruby:download` to download."
        exit 1
      end

      # The cross build compiles Ruby with a *native* mrbc — build_config_wasm.rb
      # points mrbcfile at this path. Bail early with guidance if the native
      # build hasn't produced it yet (keep this in sync with that mrbcfile).
      host_mrbc = File.join(BUILD_DIR, 'mruby', 'bin', 'mrbc')
      unless File.exist?(host_mrbc)
        puts "#{'Error:'.error} Native mruby compiler not found (#{host_mrbc})."
        puts "       Run `rake mruby:build` first (or just `rake` for a full build)."
        exit 1
      end

      print_task "Building mruby for WASM"

      build_config = File.expand_path('build_support/mruby/build_config_wasm.rb', __dir__)

      Dir.chdir(mruby_src) do
        ENV['MRUBY_CONFIG'] = build_config
        run_cmd 'rake'
      end

      FileUtils.rm_f "#{build_config}.lock"

      FileUtils.mkdir_p WASM_LIB_DIR

      print_task "Copying WASM mruby library"
      FileUtils.cp File.join(WASM_BUILD_DIR, 'mruby', 'lib', 'libmruby.a'), WASM_LIB_DIR
      wrote 'libmruby.a'
    end
  end

  desc "Clean WASM build artifacts"
  task :clean do
    print_task "Cleaning WASM"
    FileUtils.rm_rf WASM_BUILD_DIR
    FileUtils.rm_rf Dir.glob(File.join(WASM_LIB_DIR, '*.a'))
  end

end
