# Locate target.rb via RUBY2D_TARGET_RB when this config has been staged outside
# its source tree (see assets/Rakefile mruby:build, which stages it into the
# build dir so mruby's scratch/lock files stay out of a read-only gem). Falls
# back to the in-tree relative path for a normal, in-place build.
require(ENV['RUBY2D_TARGET_RB'] || File.expand_path('../../target', __dir__))

MRuby::Build.new do |conf|
  conf.build_dir = File.join(AssetsTarget.build_dir, 'mruby')
  # Use clang on macOS and Windows ARM64 (mingw-w64-clang-aarch64); gcc elsewhere
  if RUBY_PLATFORM =~ /darwin/ ||
     (AssetsTarget.host_os == 'windows' && AssetsTarget.host_arch == 'arm64')
    conf.toolchain :clang
  else
    conf.toolchain :gcc
  end
  # Same runtime gems as the "default" gembox, but only the mrbc command —
  # ruby2d ships libmruby.a + mrbc and nothing else. Skipping the other bin
  # gems avoids building mruby-bin-mirb, whose bundled strndup fallback
  # (#ifdef _WIN32) clashes with the strndup already declared by the MSYS2
  # UCRT/clangarm64 C library, and speeds up the build.
  conf.gembox 'stdlib'
  conf.gembox 'stdlib-ext'
  conf.gembox 'stdlib-io'
  conf.gembox 'math'
  conf.gembox 'metaprog'
  # Plus core gems outside those gemboxes, for CRuby parity: Time#strftime,
  # String#encoding/#force_encoding, and Kernel#exit. mruby-sleep stays out
  # on purpose — it would block the frame loop (and on web, the whole tab).
  # Keep this list in sync with build_config_wasm.rb.
  conf.gem core: 'mruby-strftime'
  conf.gem core: 'mruby-encoding'
  conf.gem core: 'mruby-exit'
  conf.gem core: 'mruby-bin-mrbc'
end
