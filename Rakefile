# The Simple 2D version to use
S2D_VERISON = '1.2.0'

# Extend `String` to include some fancy colors
class String
  def ruby2d_colorize(c); "\e[#{c}m#{self}\e[0m" end
  def bold;  ruby2d_colorize('1')    end
  def info;  ruby2d_colorize('1;34') end
  def warn;  ruby2d_colorize('1;33') end
  def error; ruby2d_colorize('1;31') end
end

def print_task(task)
  print "\n", "==> ".info, task.bold, "\n"
end

def run_cmd(cmd)
  puts "\n==> #{cmd}\n".bold
  system cmd
end

task default: 'update'

desc 'Update assets'
task :update do

  print_task 'Clean out directories'
  FileUtils.rm_rf Dir.glob('include/*')
  FileUtils.rm_rf Dir.glob('linux/*')
  FileUtils.rm_rf Dir.glob('macos/*')
  FileUtils.rm_rf Dir.glob('mingw/*')
  FileUtils.rm_rf 'ios/MRuby.framework'
  FileUtils.rm_rf 'tvos/MRuby.framework'
  FileUtils.mkdir_p 'tmp'
  FileUtils.rm_rf Dir.glob('tmp/*')

  print_task 'Download dependencies'
  run_cmd "git clone --branch v#{S2D_VERISON} --recursive --depth 1 https://github.com/simple2d/simple2d tmp/simple2d"

  def download_simple2d_release(release)
    release = "simple2d-#{release}-#{S2D_VERISON}"
    run_cmd "curl -L -o tmp/#{release}.zip https://github.com/simple2d/simple2d/releases/download/v#{S2D_VERISON}/#{release}.zip"
    run_cmd "unzip -q tmp/#{release}.zip -d tmp/#{release}"
  end

  download_simple2d_release 'apple'
  download_simple2d_release 'windows-mingw'
  download_simple2d_release 'windows-vc'

  run_cmd 'git clone --depth 1 https://github.com/ruby2d/mruby-frameworks tmp/ruby2d-mruby-frameworks'

  print_task 'Copy files from `simple2d` repo'
  FileUtils.cp 'tmp/simple2d/include/simple2d.h', 'include'
  FileUtils.cp_r Dir.glob('tmp/simple2d/deps/headers/*'), 'include'

  print_task 'Copy files for macOS'
  FileUtils.mkdir_p 'macos/lib'
  FileUtils.cp_r Dir.glob('tmp/simple2d/deps/macos/lib/*'), 'macos/lib'
  S2D_APPLE_RELEASE="simple2d-apple-#{S2D_VERISON}"
  FileUtils.cp "tmp/#{S2D_APPLE_RELEASE}/#{S2D_APPLE_RELEASE}/macOS/libsimple2d.a", 'macos/lib'

  print_task 'Copy files for tvOS and macOS'
  FileUtils.cp_r 'tmp/ruby2d-mruby-frameworks/ios/MRuby.framework', 'ios'
  FileUtils.cp_r 'tmp/ruby2d-mruby-frameworks/tvos/MRuby.framework', 'tvos'

  print_task 'Copy files for Linux'
  FileUtils.mkdir_p 'linux/simple2d/bin'
  FileUtils.mkdir_p 'linux/simple2d/include'
  FileUtils.mkdir_p 'linux/simple2d/src'
  FileUtils.cp 'tmp/simple2d/bin/simple2d.sh', 'linux/simple2d/bin'
  FileUtils.cp 'tmp/simple2d/include/simple2d.h', 'linux/simple2d/include'
  FileUtils.cp_r Dir.glob('tmp/simple2d/src/*'), 'linux/simple2d/src'
  FileUtils.cp 'tmp/simple2d/Makefile', 'linux/simple2d'

  print_task 'Copy files for MinGW'
  FileUtils.mkdir_p 'mingw/bin'
  FileUtils.mkdir_p 'mingw/lib'
  FileUtils.cp_r Dir.glob('tmp/simple2d/deps/mingw/bin/*'), 'mingw/bin'
  FileUtils.cp_r Dir.glob('tmp/simple2d/deps/mingw/lib/*'), 'mingw/lib'
  S2D_MINGW_RELEASE="simple2d-windows-mingw-#{S2D_VERISON}"
  FileUtils.cp "tmp/#{S2D_MINGW_RELEASE}/lib/libsimple2d.a", 'mingw/lib'

  print_task "Done! 😎\n"

end
