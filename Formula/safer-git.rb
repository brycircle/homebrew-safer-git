class SaferGit < Formula
  desc "Git with hooks permanently disabled at compile time"
  homepage "https://git-scm.com"
  url "https://mirrors.edge.kernel.org/pub/software/scm/git/git-2.55.0.tar.xz"
  sha256 "457fdb04dc8728e007d4688695e6912e6f680727920f2a40bf11eacc17505357"

  depends_on "gettext"
  depends_on "openssl@3"
  depends_on "curl"
  depends_on "pcre2"

  def install
    system "patch", "-p1", "-i", "#{__dir__}/../patches/disable-hooks.patch"

    ENV["USE_LIBPCRE2"] = "YesPlease"
    ENV["NO_PERL"] = "1"
    ENV["NO_PYTHON"] = "1"
    ENV["NO_TCLTK"] = "1"
    ENV["NO_GETTEXT"] = "1"

    openssl = Formula["openssl@3"]
    ENV["OPENSSLDIR"] = openssl.opt_prefix

    args = %W[
      prefix=#{prefix}
      CFLAGS=-O2
      CC=#{ENV.cc}
    ]

    system "make", *args
    system "make", "install", *args
  end

  test do
    system bin/"git", "--version"

    system bin/"git", "init", testpath
    system bin/"git", "config", "user.email", "test@example.com"
    system bin/"git", "config", "user.name", "Test"

    (testpath/".git/hooks/pre-commit").write("#!/bin/sh\nexit 1\n")
    chmod 0755, testpath/".git/hooks/pre-commit"

    (testpath/"file.txt").write("hello")
    system bin/"git", "add", "file.txt"
    system bin/"git", "commit", "-m", "test commit"
  end
end
