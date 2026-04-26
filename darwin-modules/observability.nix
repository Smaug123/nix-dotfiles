{
  lib,
  pkgs,
  ...
}: let
  home = "/Users/patrick";
  stateDir = "${home}/Library/Application Support";

  lokiDir = "${stateDir}/Loki";
  tempoDir = "${stateDir}/Tempo";
  mimirDir = "${stateDir}/Mimir";
  alloyDir = "${stateDir}/Alloy";
  grafanaDir = "${stateDir}/Grafana";
  grafanaSecretsDir = "${grafanaDir}/secrets";
  grafanaDatasourcePath = "${grafanaDir}/provisioning/datasources/lgtm.yaml";
  grafanaAdminPasswordFile = "${grafanaSecretsDir}/admin-password";
  grafanaSecretKeyFile = "${grafanaSecretsDir}/secret-key";

  yaml = (pkgs.formats.yaml {}).generate;

  lokiConfig = yaml "loki.yaml" {
    auth_enabled = false;
    server = {
      http_listen_address = "127.0.0.1";
      http_listen_port = 3100;
      grpc_listen_address = "127.0.0.1";
      grpc_listen_port = 9096;
    };
    frontend = {
      address = "127.0.0.1";
      port = 9096;
    };
    common = {
      path_prefix = lokiDir;
      replication_factor = 1;
      ring = {
        kvstore.store = "inmemory";
        instance_addr = "127.0.0.1";
        instance_port = 9096;
        instance_id = "localhost";
      };
      storage.filesystem = {
        chunks_directory = "${lokiDir}/chunks";
        rules_directory = "${lokiDir}/rules";
      };
    };
    # The APFS Data volume is large enough that 90% full can still leave tens of GiB free.
    ingester.wal.disk_full_threshold = 0.99;
    limits_config.volume_enabled = true;
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

  tempoConfig = yaml "tempo.yaml" {
    server = {
      http_listen_address = "127.0.0.1";
      http_listen_port = 3200;
      grpc_listen_address = "127.0.0.1";
      grpc_listen_port = 9097;
    };
    distributor.receivers.otlp.protocols = {
      grpc.endpoint = "127.0.0.1:14317";
      http.endpoint = "127.0.0.1:14318";
    };
    ingester.trace_idle_period = "10s";
    storage.trace = {
      backend = "local";
      local.path = "${tempoDir}/traces";
      wal.path = "${tempoDir}/wal";
    };
    usage_report.reporting_enabled = false;
  };

  mimirConfig = yaml "mimir.yaml" {
    target = "all";
    multitenancy_enabled = false;
    activity_tracker.filepath = "${mimirDir}/metrics-activity.log";
    server = {
      http_listen_address = "127.0.0.1";
      http_listen_port = 9009;
      grpc_listen_address = "127.0.0.1";
      grpc_listen_port = 9098;
    };
    common = {
      storage = {
        backend = "filesystem";
        filesystem.dir = "${mimirDir}/data";
      };
    };
    blocks_storage = {
      filesystem.dir = "${mimirDir}/blocks";
      bucket_store.sync_dir = "${mimirDir}/tsdb-sync";
      tsdb.dir = "${mimirDir}/tsdb";
    };
    ruler_storage = {
      backend = "filesystem";
      filesystem.dir = "${mimirDir}/ruler";
    };
    compactor.data_dir = "${mimirDir}/compactor";
    ingester = {
      ring = {
        replication_factor = 1;
        instance_addr = "127.0.0.1";
        kvstore.store = "inmemory";
      };
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

  alloyConfig = pkgs.writeText "config.alloy" ''
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
      ]
      forward_to      = [prometheus.remote_write.mimir.receiver]
      scrape_interval = "15s"
    }

    // --- logs: tail /tmp launchd logs, forward to Loki -------------------
    loki.write "loki" {
      endpoint {
        url = "http://127.0.0.1:3100/loki/api/v1/push"
      }
    }

    local.file_match "tmp_logs" {
      path_targets = [
        {"__path__" = "/tmp/mbsync.*.log",   "job" = "launchd", "host" = "patrick", "source" = "mbsync"},
        {"__path__" = "/tmp/radicale.*.log", "job" = "launchd", "host" = "patrick", "source" = "radicale"},
      ]
    }

    loki.source.file "tmp" {
      targets    = local.file_match.tmp_logs.targets
      forward_to = [loki.write.loki.receiver]
    }

    // --- otlp: receive app telemetry, send traces to Tempo and logs to Loki
    otelcol.exporter.otlp "tempo" {
      client {
        endpoint = "127.0.0.1:14317"

        tls {
          insecure             = true
          insecure_skip_verify = true
        }
      }
    }

    otelcol.exporter.loki "otlp" {
      forward_to = [loki.write.loki.receiver]
    }

    otelcol.processor.attributes "otlp_logs" {
      action {
        key    = "loki.resource.labels"
        action = "insert"
        value  = "service.name, service.namespace"
      }

      output {
        logs = [otelcol.processor.batch.otlp.input]
      }
    }

    otelcol.processor.batch "otlp" {
      output {
        logs   = [otelcol.exporter.loki.otlp.input]
        traces = [otelcol.exporter.otlp.tempo.input]
      }
    }

    otelcol.receiver.otlp "default" {
      grpc {
        endpoint = "127.0.0.1:4317"
      }

      http {
        endpoint = "127.0.0.1:4318"
      }

      output {
        logs   = [otelcol.processor.attributes.otlp_logs.input]
        traces = [otelcol.processor.batch.otlp.input]
      }
    }
  '';

  grafanaIni = pkgs.writeText "grafana.ini" ''
    [server]
    http_addr = 127.0.0.1
    http_port = 3000

    [paths]
    data         = ${grafanaDir}/data
    logs         = ${grafanaDir}/logs
    plugins      = ${grafanaDir}/plugins
    provisioning = ${grafanaDir}/provisioning

    [security]
    admin_user     = admin
    admin_password = $__file{${grafanaAdminPasswordFile}}
    secret_key     = $__file{${grafanaSecretKeyFile}}

    [analytics]
    reporting_enabled = false

    [auth.anonymous]
    enabled = false
  '';

  datasourcesYaml = pkgs.writeText "lgtm-datasources.yaml" ''
    apiVersion: 1
    datasources:
      - name: Loki
        type: loki
        access: proxy
        url: http://127.0.0.1:3100
        isDefault: true
        jsonData:
          httpHeaderName1: X-Scope-OrgID
        secureJsonData:
          httpHeaderValue1: fake
      - name: Mimir
        type: prometheus
        access: proxy
        url: http://127.0.0.1:9009/prometheus
      - name: Tempo
        type: tempo
        access: proxy
        url: http://127.0.0.1:3200
  '';

  bootstrap = inner: ''
    ${pkgs.bash}/bin/bash -c "set -e ; \
      mkdir -p '${lokiDir}/chunks' '${lokiDir}/rules' ; \
      mkdir -p '${tempoDir}/traces' '${tempoDir}/wal' ; \
      mkdir -p '${mimirDir}/data' '${mimirDir}/blocks' '${mimirDir}/tsdb-sync' \
               '${mimirDir}/tsdb' '${mimirDir}/ruler' '${mimirDir}/compactor' ; \
      mkdir -p '${alloyDir}' ; \
      mkdir -p '${grafanaDir}/data' '${grafanaDir}/logs' '${grafanaDir}/plugins' \
               '${grafanaDir}/provisioning/datasources' '${grafanaDir}/provisioning/dashboards' \
               '${grafanaSecretsDir}' ; \
      chmod 700 '${grafanaSecretsDir}' ; \
      if [ ! -e '${grafanaAdminPasswordFile}' ] ; then \
        ${pkgs.openssl}/bin/openssl rand -hex 32 | ${pkgs.coreutils}/bin/tr -d '\n' > '${grafanaAdminPasswordFile}' ; \
      fi ; \
      if [ ! -e '${grafanaSecretKeyFile}' ] ; then \
        ${pkgs.openssl}/bin/openssl rand -hex 32 | ${pkgs.coreutils}/bin/tr -d '\n' > '${grafanaSecretKeyFile}' ; \
      fi ; \
      chmod 400 '${grafanaAdminPasswordFile}' '${grafanaSecretKeyFile}' ; \
      rm -f '${grafanaDatasourcePath}' ; \
      cp '${datasourcesYaml}' '${grafanaDatasourcePath}' ; \
      chmod 644 '${grafanaDatasourcePath}' ; \
      exec ${inner}"
  '';

  agent = name: cmd: {
    command = bootstrap "${cmd} > /tmp/${name}.log 2>&1";
    serviceConfig = {
      KeepAlive = true;
      RunAtLoad = true;
    };
  };
in {
  launchd.user.agents = {
    loki = agent "loki" "${pkgs.grafana-loki}/bin/loki -config.file=${lokiConfig}";

    tempo = agent "tempo" "${pkgs.tempo}/bin/tempo --config.file=${tempoConfig}";

    mimir = agent "mimir" "${pkgs.mimir}/bin/mimir --config.file=${mimirConfig}";

    alloy = agent "alloy" "${pkgs.grafana-alloy}/bin/alloy run ${alloyConfig} --server.http.listen-addr=127.0.0.1:12345 --storage.path=${lib.escapeShellArg alloyDir}";

    grafana = agent "grafana" "${pkgs.grafana}/bin/grafana server -homepath ${pkgs.grafana}/share/grafana -config ${grafanaIni}";
  };
}
