require(ENV['RUBY2D_TARGET_RB'] || File.expand_path('../../target', __dir__))

MRuby::CrossBuild.new('emscripten') do |conf|
  conf.build_dir = File.join(AssetsTarget.wasm_build_dir, 'mruby')
  conf.mrbcfile  = File.join(AssetsTarget.build_dir, 'mruby', 'bin', 'mrbc')
  toolchain :clang
  # The same library gems as the native build, minus every bin tool — commands
  # cross-compiled to wasm are dead weight, and mrbcfile above already points
  # at the native mrbc. Keep this list in sync with build_config.rb.
  conf.gembox 'stdlib'
  conf.gembox 'stdlib-ext'
  conf.gembox 'stdlib-io'
  conf.gembox 'math'
  conf.gembox 'metaprog'
  conf.gem core: 'mruby-strftime'
  conf.gem core: 'mruby-encoding'
  conf.gem core: 'mruby-exit'
  conf.cc.command = 'emcc'
  conf.cc.flags << '-O3'
  # No boxing: mrb_value is a plain struct with the Float stored inline — no
  # heap allocation per Float. wasm is 32-bit, where the default word boxing
  # heap-allocates every Float, making float-heavy loops (game math) several
  # times slower. mruby's own docs point to MRB_NO_BOXING as the 32-bit
  # escape hatch (NaN boxing trips the 5-word GC cell assert on 32-bit).
  # Anything compiled against these headers (the ruby2d web/try builds) must
  # define this too — the boxing mode is ABI.
  conf.cc.defines << 'MRB_NO_BOXING'
  conf.linker.command = 'emcc'
  conf.archiver.command = 'emar'
end
