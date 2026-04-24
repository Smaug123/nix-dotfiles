{
  pkgs,
  config,
  ...
}: {
  nixpkgs.config.allowUnfree = true;
  imports = [
    ../hardware/capybara.nix
  ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.bluetooth.enable = true;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.useOSProber = true;

  boot.kernelParams = [
    "video=DP-1:2560x1440@144"
    "video=HDMI-A-1:1920x1080@144"
  ];

  boot.extraModulePackages = [config.boot.kernelPackages.rtl8821au];

  networking = {
    hostName = "capybara";
    networkmanager.enable = true;
  };

  time.timeZone = "Europe/London";

  programs.sway.enable = true;
  programs.zsh.enable = true;

  # TODO: work out secrets management for password, then set mutableUsers to false
  users.mutableUsers = true;
  users.users.patrick = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkManager"];
  };

  services.syncthing = {
    enable = true;
    user = "patrick";
    dataDir = "/home/patrick/syncthing";
  };

  environment.systemPackages = [
    pkgs.git
    pkgs.vim
    pkgs.wget
    pkgs.tmux
    pkgs.home-manager
    pkgs.firefox
  ];

  environment.loginShellInit = ''
    [[ "$(tty)" == /dev/tty1 ]] && sway --unsupported-gpu
  '';

  services.openssh.enable = true;

  system.stateVersion = "23.11";
  nix.settings.experimental-features = ["nix-command" "flakes" "ca-derivations"];

  nix.gc.automatic = true;
  nix.extraOptions = ''
    auto-optimise-store = true
    max-jobs = auto
    keep-outputs = true
    keep-derivations = true
  '';

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
  };

  # --- Observability: local full LGTM stack on 127.0.0.1 -------------------
  # admin_password and secret_key are placeholders. Swap for file-provider
  # once the secrets-management TODO above is resolved.

  services.loki = {
    enable = true;
    configuration = {
      auth_enabled = false;
      server = {
        http_listen_address = "127.0.0.1";
        http_listen_port = 3100;
      };
      common = {
        path_prefix = "/var/lib/loki";
        replication_factor = 1;
        ring.kvstore.store = "inmemory";
        storage.filesystem = {
          chunks_directory = "/var/lib/loki/chunks";
          rules_directory = "/var/lib/loki/rules";
        };
      };
      schema_config.configs = [
        {
          from = "2024-01-01";
          store = "tsdb";
          object_store = "filesystem";
          schema = "v13";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }
      ];
      analytics.reporting_enabled = false;
    };
  };

  services.tempo = {
    enable = true;
    settings = {
      server = {
        http_listen_address = "127.0.0.1";
        http_listen_port = 3200;
      };
      distributor.receivers.otlp.protocols = {
        grpc.endpoint = "127.0.0.1:4317";
        http.endpoint = "127.0.0.1:4318";
      };
      ingester.trace_idle_period = "10s";
      storage.trace = {
        backend = "local";
        local.path = "/var/lib/tempo/traces";
        wal.path = "/var/lib/tempo/wal";
      };
      usage_report.reporting_enabled = false;
    };
  };

  services.mimir = {
    enable = true;
    configuration = {
      target = "all";
      multitenancy_enabled = false;
      server = {
        http_listen_address = "127.0.0.1";
        http_listen_port = 9009;
        grpc_listen_port = 9095;
      };
      common = {
        storage = {
          backend = "filesystem";
          filesystem.dir = "/var/lib/mimir/data";
        };
      };
      blocks_storage = {
        filesystem.dir = "/var/lib/mimir/blocks";
        bucket_store.sync_dir = "/var/lib/mimir/tsdb-sync";
        tsdb.dir = "/var/lib/mimir/tsdb";
      };
      ruler_storage = {
        backend = "filesystem";
        filesystem.dir = "/var/lib/mimir/ruler";
      };
      compactor.data_dir = "/var/lib/mimir/compactor";
      ingester.ring = {
        replication_factor = 1;
        instance_addr = "127.0.0.1";
        kvstore.store = "inmemory";
      };
      distributor.ring = {
        instance_addr = "127.0.0.1";
        kvstore.store = "inmemory";
      };
      store_gateway.sharding_ring = {
        replication_factor = 1;
        instance_addr = "127.0.0.1";
        kvstore.store = "inmemory";
      };
      ruler.ring = {
        instance_addr = "127.0.0.1";
        kvstore.store = "inmemory";
      };
      usage_stats.enabled = false;
    };
  };

  services.prometheus.exporters.node = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9100;
  };

  services.alloy = {
    enable = true;
    extraFlags = ["--server.http.listen-addr=127.0.0.1:12345"];
  };

  environment.etc."alloy/config.alloy".text = ''
    // --- metrics: scrape local services, remote_write to Mimir -----------
    prometheus.remote_write "mimir" {
      endpoint {
        url = "http://127.0.0.1:9009/api/v1/push"
      }
    }

    prometheus.scrape "self" {
      targets = [
        {"__address__" = "127.0.0.1:3000",  "job" = "grafana"},
        {"__address__" = "127.0.0.1:3100",  "job" = "loki"},
        {"__address__" = "127.0.0.1:3200",  "job" = "tempo"},
        {"__address__" = "127.0.0.1:9009",  "job" = "mimir"},
        {"__address__" = "127.0.0.1:12345", "job" = "alloy"},
        {"__address__" = "127.0.0.1:9100",  "job" = "node"},
      ]
      forward_to      = [prometheus.remote_write.mimir.receiver]
      scrape_interval = "15s"
    }

    // --- logs: tail systemd-journal, forward to Loki ---------------------
    loki.write "loki" {
      endpoint {
        url = "http://127.0.0.1:3100/loki/api/v1/push"
      }
    }

    loki.relabel "journal" {
      forward_to = []
      rule {
        source_labels = ["__journal__systemd_unit"]
        target_label  = "unit"
      }
      rule {
        source_labels = ["__journal__hostname"]
        target_label  = "nodename"
      }
    }

    loki.source.journal "journal" {
      max_age       = "12h"
      labels        = {"job" = "systemd-journal", "host" = "capybara"}
      relabel_rules = loki.relabel.journal.rules
      forward_to    = [loki.write.loki.receiver]
    }
  '';

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3000;
      };
      security = {
        admin_user = "admin";
        admin_password = "admin";
        secret_key = "nixos-lgtm-placeholder-replace-me";
      };
      analytics.reporting_enabled = false;
      "auth.anonymous".enabled = false;
    };
    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Loki";
          type = "loki";
          access = "proxy";
          url = "http://127.0.0.1:3100";
          isDefault = true;
        }
        {
          name = "Mimir";
          type = "prometheus";
          access = "proxy";
          url = "http://127.0.0.1:9009/prometheus";
        }
        {
          name = "Tempo";
          type = "tempo";
          access = "proxy";
          url = "http://127.0.0.1:3200";
        }
      ];
    };
  };
}
