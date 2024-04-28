{
  pkgs,
  mbsync,
  secretsPath,
  ...
}: let
  deobfuscate = str: let
    lib = pkgs.lib;
    base64Table =
      builtins.listToAttrs
      (lib.imap0 (i: c: lib.nameValuePair c i)
        (lib.stringToCharacters "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"));

    # Generated using python3:
    # print(''.join([ chr(n) for n in range(1, 256) ]), file=open('ascii', 'w'))
    ascii = builtins.readFile ./mail/ascii;

    # List of base-64 numbers
    numbers64 = map (c: base64Table.${c}) (lib.lists.reverseList (lib.stringToCharacters str));

    # List of base-256 numbers
    numbers256 = lib.concatLists (lib.genList (
      i: let
        v =
          lib.foldl'
          (acc: el: acc * 64 + el)
          0
          (lib.sublist (i * 4) 4 numbers64);
      in [
        (lib.mod (v / 256 / 256) 256)
        (lib.mod (v / 256) 256)
        (lib.mod v 256)
      ]
    ) (lib.length numbers64 / 4));
  in
    # Converts base-256 numbers to ascii
    lib.concatMapStrings (
      n:
      # Can't represent the null byte in Nix..
      let
        result = lib.substring (n - 1) 1 ascii;
      in
        if result == " "
        then ""
        else result
    )
    numbers256;
in {
  accounts.email.accounts."Gmail" = let
    address = (deobfuscate "AFTN0cWdh12c") + "gmail.com";
  in {
    notmuch.enable = true;
    neomutt = {
      enable = true;
    };
    address = address;
    flavor = "gmail.com";
    mbsync = {
      enable = true;
      create = "maildir";
      extraConfig.account = {
        AuthMechs = "XOAUTH2";
      };
    };
    userName = address;
    # This is accompanied by a developer application at Google:
    # https://console.cloud.google.com/apis/credentials
    # Create an OAuth 2.0 Client ID with type `Desktop`.
    # The Google application needs the https://mail.google.com scope; mine has
    # an authorized domain `google.com` but I don't know if that's required.
    # Enter the client ID and client secret into a two-line text file
    # named gmail-client-app.txt immediately next to the intended destination
    # secret file (the arg to mutt-oauth2.py in the invocation):
    # so here it would be /path/to/gmail-client-app.txt .
    # Run `./mail/mutt-oauth2.py /path/to/secret --authorize --verbose` once manually,
    # and that will populate /path/to/secret.
    # I've left it unencrypted here; the original uses GPG to store it encrypted at rest.
    passwordCommand = ''${pkgs.python3}/bin/python ${./mail/mutt-oauth2.py} ${secretsPath}/gmail.txt'';
    realName = "Patrick Stevens";
  };

  accounts.email.accounts."BTInternet" = let
    address = (deobfuscate "z5WZ2VGdz5yajlmc0FGc") + "@btinternet.com";
  in {
    notmuch.enable = true;
    neomutt = {
      enable = true;
    };
    address = address;
    imap = {
      host = "mail.btinternet.com";
      port = 993;
      tls = {
        enable = true;
        useStartTls = false;
      };
    };
    mbsync = {
      enable = true;
      create = "maildir";
    };
    realName = "Patrick Stevens";
    passwordCommand = "${pkgs.coreutils}/bin/cat ${secretsPath}/btinternet.txt";
    smtp = {
      host = "mail.btinternet.com";
      port = 465;
      tls = {
        enable = true;
        useStartTls = false;
      };
    };
    userName = address;
    primary = true;
  };

  accounts.email.accounts."Proton" = let
    address = deobfuscate "gAya15ybj5ycuVmdlR3crNWayRXYwB0ajlmc0FGc";
  in {
    notmuch.enable = true;
    neomutt = {
      enable = true;
    };
    address = address;
    # I use the ProtonMail bridge, which sits at localhost.
    imap = {
      host = "127.0.0.1";
      port = 1143; # 8125; if using hydroxide
      tls = {
        enable = false;
        useStartTls = true;
      };
    };
    mbsync = {
      enable = true;
      create = "maildir";
      extraConfig.account = {
        # Because ProtonMail Bridge is localhost, we don't
        # care that we can only auth to it in plain text.
        AuthMechs = "LOGIN";
      };
    };
    realName = "Patrick Stevens";
    passwordCommand =
      # I store the ProtonMail Bridge password here.
      # Extracting it from a keychain would be better.
      "${pkgs.coreutils}/bin/cat ${secretsPath}/proton.txt";
    smtp = {
      host = "127.0.0.1";
      port = 1025; # 8126; if using hydroxide
      tls = {enable = false;};
    };
    userName = address;
  };

  programs.mbsync = {
    enable = true;
    extraConfig = ''
      CopyArrivalDate yes
    '';
    package = mbsync;
  };
  programs.neomutt = {
    enable = true;
    extraConfig = ''
      set use_threads=threads sort=last-date sort_aux=date
    '';
    sidebar.enable = true;
    vimKeys = true;
  };

  programs.notmuch.enable = true;

  home.file.".mailcap".source = ./mail/mailcap;

  home.packages = [
    pkgs.notmuch
    pkgs.lynx
  ];
}
