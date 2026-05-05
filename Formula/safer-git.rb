class SaferGit < Formula
  desc "Git with hooks permanently disabled at compile time"
  homepage "https://git-scm.com"
  url "https://mirrors.edge.kernel.org/pub/software/scm/git/git-2.54.0.tar.xz"
  sha256 "f689162364c10de79ef89aa8dbf48731eb057e34edbbd20aca510ce0154681a3"

  depends_on "gettext"
  depends_on "openssl@3"
  depends_on "curl"
  depends_on "pcre2"

  patch :p1 do
    <<~'PATCH'
      --- a/hook.c
      +++ b/hook.c
      @@ -562,6 +562,10 @@ int run_hooks_opt(struct repository *r, const char *hook_name,
       	if (options->invoked_hook)
       		*options->invoked_hook = 0;

      +	/* safer-git: all hooks permanently disabled at build time */
      +	run_hooks_opt_clear(options);
      +	return 0;
      +
       	cb_data.hook_command_list = list_hooks(r, hook_name, options);
       	if (!cb_data.hook_command_list->nr) {
    PATCH
  end

  def install
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
