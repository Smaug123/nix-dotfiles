{pkgs, ...}: {
  home.packages = [
    pkgs.claude-code
  ];

  home.file.".claude/settings.json".source = ./claude-code/settings-raw.json;
}

