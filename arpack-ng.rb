require 'formula'

class ArpackNg < Formula
  homepage 'http://forge.scilab.org/index.php/p/arpack-ng'
  url 'http://forge.scilab.org/index.php/p/arpack-ng/downloads/get/arpack-ng_3.1.0.tar.gz'
  md5 '942a866c306ab6986f3f4fe59ac4b13e'

  def install
    ENV.fortran

    # Include MPIF77, as the arpack-ng build process ignores "F77" for MPI
    ENV['MPIF77'] = ENV['F77']

    configure_args = ["--disable-dependency-tracking", "--prefix=#{prefix}", "--enable-shared"]
    configure_args << "--with-blas=-framework Accelerate"
    configure_args << "--with-lapack=-framework Accelerate"

    system "./configure", *configure_args

    system "make install"
  end
end
