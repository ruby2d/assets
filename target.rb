require 'rbconfig'

module AssetsTarget
  module_function

  # Normalize OS into folder names
  def host_os
    host = RbConfig::CONFIG['host_os'].downcase

    return 'windows' if host.include?('mswin') || host.include?('mingw') || host.include?('cygwin')
    return 'macos'   if host.include?('darwin')
    return 'linux'   if host.include?('linux')
    return 'bsd'     if host.match?(/freebsd|openbsd|netbsd|dragonfly/)

    raise "Unsupported host OS: #{host.inspect}"
  end

  # Normalize CPU arch into folder names
  def host_arch
    cpu = RbConfig::CONFIG['host_cpu'].downcase

    case cpu
    when 'x86_64', 'amd64', 'x64'
      'x86_64'
    when 'aarch64', 'arm64'
      'arm64'
    else
      if host_os != 'windows'
        uname = `uname -m 2>/dev/null`.strip.downcase
        return 'arm64'  if ['arm64', 'aarch64'].include?(uname)
        return 'x86_64' if ['x86_64', 'amd64'].include?(uname)
      end

      raise "Unsupported host CPU: #{cpu.inspect}"
    end
  end

  # Toolchain is deterministic from host OS:
  # - windows => mingw-ucrt (MSYS2 UCRT)
  # - macos   => nil
  # - linux   => nil (expand as needed)
  # - bsd     => nil
  def host_toolchain
    case host_os
    when 'windows' then 'mingw-ucrt'
    when 'macos'   then nil
    when 'linux'   then nil
    when 'bsd'     then nil
    end
  end

  # Allow overrides via env vars:
  #   RUBY2D_ASSETS_OS=windows RUBY2D_ASSETS_ARCH=arm64 RUBY2D_ASSETS_TOOLCHAIN=mingw-ucrt
  def resolved_target
    os        = ENV['RUBY2D_ASSETS_OS']   || host_os
    arch      = ENV['RUBY2D_ASSETS_ARCH'] || host_arch
    toolchain = ENV.key?('RUBY2D_ASSETS_TOOLCHAIN') ? ENV['RUBY2D_ASSETS_TOOLCHAIN'] : host_toolchain

    [os, arch, toolchain]
  end

  # Canonical target ID string, e.g. "macos-arm64" or "windows-x86_64-mingw-ucrt"
  def target_id
    os, arch, toolchain = resolved_target
    toolchain && !toolchain.empty? ? "#{os}-#{arch}-#{toolchain}" : "#{os}-#{arch}"
  end

  # Where library builds read and write. Defaults to this gem's own `assets/`
  # dir — both the dev repo and the bundled gem build in place there. Setting
  # RUBY2D_ASSETS_ROOT redirects it; `ruby2d setup` points it at `cache_root`
  # so a `gem install`ed user can build libs without touching the (possibly
  # read-only) gem dir.
  def default_root
    override = ENV['RUBY2D_ASSETS_ROOT']
    override && !override.empty? ? override : __dir__
  end

  # Per-user cache root for libraries built by `ruby2d setup`, outside the gem.
  # Honors RUBY2D_ASSETS_ROOT (so `setup` and the build agree), else a
  # platform-native cache location. Reported to the user by `setup`.
  def cache_root
    override = ENV['RUBY2D_ASSETS_ROOT']
    return override if override && !override.empty?

    case host_os
    when 'windows'
      base = ENV['LOCALAPPDATA']
      base = File.join(Dir.home, 'AppData', 'Local') if base.nil? || base.empty?
      File.join(base, 'ruby2d')
    when 'macos'
      File.join(Dir.home, 'Library', 'Caches', 'ruby2d')
    else # linux, bsd
      base = ENV['XDG_CACHE_HOME']
      base = File.join(Dir.home, '.cache') if base.nil? || base.empty?
      File.join(base, 'ruby2d')
    end
  end

  # platform/{target_id} — where compiled libs and binaries live
  def platform_dir(root: default_root)
    File.join(root, 'platform', target_id)
  end

  # platform/include — SDL3 + mruby headers, shared across targets (not per-id)
  def include_dir(root: default_root)
    File.join(root, 'platform', 'include')
  end

  # platform/wasm — pre-built WASM (Emscripten) libraries. WASM is a single
  # cross-compile target with no host binaries, so it gets a flat `wasm` dir
  # (mirroring build/wasm) rather than an {os}-{arch} id, and only a lib/ under
  # it. Headers are shared via include_dir, same as the native targets.
  def wasm_platform_dir(root: default_root)
    File.join(root, 'platform', 'wasm')
  end

  # build/{target_id} — intermediate cmake build artifacts
  def build_dir(root: default_root)
    File.join(root, 'build', target_id)
  end

  # build/wasm — intermediate build artifacts for the WASM target
  def wasm_build_dir(root: default_root)
    File.join(root, 'build', 'wasm')
  end

  # sources/ — where dependency source repos are cloned
  def sources_dir(root: default_root)
    File.join(root, 'sources')
  end
end
