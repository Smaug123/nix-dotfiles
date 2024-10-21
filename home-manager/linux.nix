{
  nixpkgs,
  username,
  dotnet,
  ...
}: {
  home.packages = [nixpkgs.wl-clipboard nixpkgs.jetbrains.rider];
  nixpkgs.config.firefox = {
    speechSynthesisSupport = true;
  };

  # Sadly not implemented on Darwin
  programs.firefox = {
    enable = true;
    profiles = {
      patrick = {
        isDefault = true;
        name = "patrick";
        search = {default = "Google";};
        settings = {
          # see https://github.com/TLATER/dotfiles/blob/b39af91fbd13d338559a05d69f56c5a97f8c905d/home-config/config/graphical-applications/firefox.nix
          # see https://www.ghacks.net/2015/08/18/a-comprehensive-list-of-firefox-privacy-and-security-settings/
          "browser.search.isUS" = false;
          "browser.search.region" = "GB";
          "gfx.webrender.all" = true; # enable GPU acceleration
          "media.ffmpeg.vaapi.enabled" = true;
          "widget.dmabuf.force-enabled" = true;
          "privacy.webrtc.legacyGlobalIndicator" = false;
          "app.shield.optoutstudies.enabled" = false;
          "app.update.enabled" = false;
          "app.update.auto" = false;
          "app.update.silent" = false;
          "app.update.service.enabled" = false;
          "app.update.staging.enabled" = false;
          "browser.discovery.enabled" = false;
          "browser.laterrun.enabled" = false;
          "browser.shell.checkDefaultBrowser" = false;
          "browser.rights.3.shown" = true;
          "browser.search.update" = false;
          "extensions.update.enabled" = false;
          "extensions.update.autoUpdateDefault" = false;
          "extensions.getAddons.cache.enabled" = false;
          "dom.ipc.plugins.reportCrashURL" = false;
          "extensions.webservice.discoverURL" = "http://127.0.0.1";
          "toolkit.telemetry.unified" = false;
          "toolkit.telemetry.unifiedIsOptIn" = true;
          "toolkit.telemetry.enabled" = false;
          "toolkit.telemetry.server" = "";
          "toolkit.telemetry.archive.enabled" = false;
          "lightweightThemes.update.enabled" = false;
          "startup.homepage_welcome_url" = "";
          "startup.homepage_welcome_url.additional" = "";
          "startup.homepage_override_url" = "";
          "datareporting.healthreport.uploadEnabled" = false;
          "datareporting.healthreport.documentServerURI" = "";
          "datareporting.healthreport.service.enabled" = false;
          "datareporting.healthreport.about.reportUrl" = "data:text/plain,";
          "toolkit.telemetry.cachedClientID" = "";
          "browser.selfsupport.url" = "";
          "browser.selfsupport.enabled" = false;
          "experiments.enabled" = false;
          "experiments.supported" = false;
          "experiments.activeExperiment" = false;
          "experiments.manifest.uri" = "";
          "network.allow-experiments" = false;
          "breakpad.reportURL" = "";
          "browser.tabs.crashReporting.sendReport" = false;
          "browser.newtab.preload" = false;
          "browser.newtabpage.directory.ping" = "data:text/plain,";
          "browser.newtabpage.directory.source" = "data:text/plain,";
          "browser.newtabpage.enabled" = false;
          "browser.newtabpage.enhanced" = false;
          "browser.newtabpage.introShown" = true;
          "browser.aboutHomeSnippets.updateUrl" = "https://127.0.0.1";
          "extensions.pocket.enabled" = false;
          "extensions.pocket.api" = "";
          "extensions.pocket.site" = "";
          "extensions.pocket.oAuthConsumerKey" = "";
          "social.whitelist" = "";
          "social.toast-notifications.enabled" = false;
          "social.shareDirectory" = "";
          "social.remote-install.enabled" = false;
          "social.directories" = "";
          "social.share.activationPanelEnabled" = false;
          "social.enabled" = false;
          "dom.flyweb.enabled" = false;
          "services.sync.enabled" = false;
        };
      };
    };
  };

  wayland.windowManager.sway = {
    enable = true;
    config = {
      focus = {followMouse = false;};
      modifier = "Mod4";
      terminal = "alacritty";
      window = {border = 5;};
      bars = [
      {
          command = "${nixpkgs.waybar}/bin/waybar";
      }
      ];
    };
    extraConfig = ''
      output Unknown-1 scale 2
    '';
  };

  services.gpg-agent = {
    enable = nixpkgs.stdenv.isLinux;
    pinentryPackage = nixpkgs.pinentry-qt;
  };

  services.swayidle = {enable = true;};
  services.cbatticon = {
    lowLevelPercent = 20;
    iconType = "standard";
    enable = true;
  };
}
