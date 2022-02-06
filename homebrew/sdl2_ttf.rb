# WARNING: Version 2.0.18 causes text to look scrambed, make sure to test new releases!
#
# Original formula:
#   https://github.com/Homebrew/homebrew-core/blob/master/Formula/sdl2_ttf.rb
#
# Changes:
#   - Added `revision 99` so Homebrew doesn't upgrade the formula
#   - Removed bottles
#   - Removed `depends_on "harfbuzz"`
#   - Restored `def install` to https://github.com/Homebrew/homebrew-core/blob/9f0a427ea6b9d9d12401966ad5c46b686d3e5879/Formula/sdl2_ttf.rb

class Sdl2Ttf < Formula
  desc "Library for using TrueType fonts in SDL applications"
  homepage "https://github.com/libsdl-org/SDL_ttf"
  url "https://www.libsdl.org/projects/SDL_ttf/release/SDL2_ttf-2.0.15.tar.gz"
  sha256 "a9eceb1ad88c1f1545cd7bd28e7cbc0b2c14191d40238f531a15b01b1b22cd33"
  license "Zlib"
  revision 99

  depends_on "pkg-config" => :build
  depends_on "freetype"
  depends_on "sdl2"

  def install
    inreplace "SDL2_ttf.pc.in", "@prefix@", HOMEBREW_PREFIX
    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include <SDL2/SDL_ttf.h>

      int main()
      {
          int success = TTF_Init();
          TTF_Quit();
          return success;
      }
    EOS
    system ENV.cc, "test.c", "-I#{Formula["sdl2"].opt_include}/SDL2", "-L#{lib}", "-lSDL2_ttf", "-o", "test"
    system "./test"
  end
end
