
MRuby::Build.new do |conf|

  if RUBY_PLATFORM =~ /darwin/
    conf.toolchain :clang
  else
    conf.toolchain :gcc
  end

  conf.gembox "default"

end
