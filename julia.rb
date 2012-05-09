require 'formula'

class Julia < Formula
  homepage 'http://julialang.org'
  head 'https://github.com/JuliaLang/julia.git'

  depends_on "readline"
  depends_on "pcre"
  depends_on "gmp"
  depends_on "llvm"
  depends_on "glpk"
  depends_on "homebrew/science/suite-sparse"
  depends_on "homebrew/science/arpack-ng"
  depends_on "lighttpd"
  depends_on "fftw"
  depends_on "tbb"
  depends_on "metis"

  def install
    ENV.fortran

    # Julia ignores CPPFLAGS and only uses CFLAGS, so we must store CPPFLAGS into CFLAGS
    ENV.append_to_cflags ENV['CPPFLAGS']

    # Hack to allow julia to get the git version on demand
    ENV['GIT_DIR'] = cached_download/'.git'

    # This from @ijt's formula, with possible exclusion if @sharpie makes standard for ENV.fortran builds
    libgfortran = `$FC --print-file-name libgfortran.a`.chomp
    ENV.append "LDFLAGS", "-L#{File.dirname libgfortran}"

    # symlink external dylibs into julia's usr/lib directory, so that it can load them at runtime
    mkdir_p "usr/lib"
    ['', 'f', 'l', '_threads', 'f_threads', 'l_threads'].each do |ext|
      ln_s "#{Formula.factory('fftw').lib}/libfftw3#{ext}.dylib", "usr/lib/"
    end

    ln_s "#{Formula.factory('homebrew/science/arpack-ng').lib}/libarpack.dylib", "usr/lib/"

    build_opts = ["PREFIX=#{prefix}"]

    # Make sure Julia uses clang if the environment supports it
    build_opts << "USECLANG=1" if ENV.compiler == :clang

    # Kudos to @ijt for these lines of code
    ['READLINE', 'GLPK', 'GMP', 'LLVM', 'PCRE', 'LIGHTTPD', 'FFTW', 'LAPACK', 'BLAS', 'SUITESPARSE', 'ARPACK'].each do |dep|
      build_opts << "USE_SYSTEM_#{dep}=1"
    end

    # call make with the build options
    system "make", *build_opts

    # Install!
    system "make", *(build_opts + ["install"])

    # Final install step, symlink julia binary and webserver into bin:
    bin.install_symlink "#{share}/julia/julia"
    bin.install_symlink "#{share}/julia/launch-julia-webserver"

    # symlink lighttpd binary into usr/sbin, so that launch-julia-webserver works properly
    mkdir_p "usr/sbin"
    ln_s "#{Formula.factor('lighttpd').bin}/lighttpd", "usr/sbin/"

    # and for boatloads of fun, we'll make the test data, and allow it to be run from `brew test julia`
    system "make", "-C", "test/unicode/"
    cp_r "test", "#{share}/julia/"
  end

  def test
    # Run julia-provided test suite, copied over in install step
    chdir "#{share}/julia/test"
    system "julia", "runtests.jl", "all"
  end
end
