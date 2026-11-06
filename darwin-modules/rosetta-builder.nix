# A Nix remote builder for aarch64-linux (native) and x86_64-linux (via Rosetta), running in
# Apple's `container` (https://github.com/apple/container), which must be installed separately.
#
# nix-darwin's `nix.linux-builder` can't be used with Determinate Nix (it asserts `nix.enable`), and
# its QEMU VM can't use Rosetta. Determinate's own native Linux builder shares this machine's
# case-insensitive store, which breaks some Linux builds (see below).
#
# The agent generates SSH keys in `stateDir` on first start. The root-run Nix daemon reads the
# client key and known_hosts from there too.
#
# After `darwin-rebuild switch` changes the Nix settings below, restart the Nix daemon:
#   sudo launchctl kickstart -k system/systems.determinate.nix-daemon
{pkgs, ...}: let
  name = "rosetta-builder";
  port = 31122;
  cpus = 8;
  memory = "16G";
  # No spaces: ssh_config's UserKnownHostsFile takes a space-separated list.
  stateDir = "/Users/patrick/.local/state/rosetta-builder";
  # Only the host key and authorized_keys are mounted into the container, not the client key.
  containerDir = "${stateDir}/container";
  clientKey = "${stateDir}/client_ed25519";
  knownHosts = "${stateDir}/known_hosts";

  containerCli = "/usr/local/bin/container";
  # `nixos/nix:latest` as of 2026-10-22.
  image = "docker.io/nixos/nix@sha256:f159a58f390677f41e8e900a74b6e2f9c7f27b364122ae6acf7a652ce6c551c0";

  linuxPkgs = import pkgs.path {system = "aarch64-linux";};
  # These are realised inside the container (from cache.nixos.org), not on this machine, so we
  # discard the string context to stop nix-darwin from trying to fetch them here.
  linuxPath = drv: builtins.unsafeDiscardStringContext "${drv}";
  utilLinux = linuxPath linuxPkgs.util-linux.bin;
  openssh = linuxPath linuxPkgs.openssh;

  entrypoint = pkgs.writeTextDir "entrypoint.sh" ''
    #!/bin/sh
    set -eu

    PATH=/root/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH

    cat > /etc/nix/nix.conf <<'CONF'
    build-users-group = nixbld
    trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
    experimental-features = nix-command flakes ca-derivations
    extra-platforms = x86_64-linux
    sandbox = true
    sandbox-fallback = false
    max-jobs = auto
    trusted-users = root
    CONF

    nix-store --realise ${utilLinux} ${openssh} > /dev/null

    # The runtime overmounts parts of /proc and /sys. While those are present, the kernel refuses
    # a fresh procfs mount inside a user namespace, which Nix's sandbox needs.
    cut -d' ' -f5 /proc/self/mountinfo | grep -E '^/(proc/.|sys/firmware)' | sort -r | while read -r m; do
      ${utilLinux}/bin/umount "$m" || ${utilLinux}/bin/umount -l "$m"
    done

    # `container --rosetta` registers Rosetta without the P (preserve-argv0) flag, so the kernel
    # replaces argv[0] with the interpreted binary's path. nixpkgs wrappers rely on argv[0] (e.g. a
    # python3.withPackages env finds its site-packages through it), so re-register with POCF.
    mkdir -p /mnt/rosetta /binfmt_misc
    ${utilLinux}/bin/mount -t virtiofs rosetta /mnt/rosetta
    ${utilLinux}/bin/mount -t binfmt_misc binfmt_misc /binfmt_misc
    if [ -e /binfmt_misc/x86_64 ]; then echo -1 > /binfmt_misc/x86_64; fi
    printf '%s' ':x86_64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x3e\x00:\xff\xff\xff\xff\xff\xfe\xfe\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/mnt/rosetta/rosetta:POCF' > /binfmt_misc/register

    mkdir -p /etc/ssh /root/.ssh /var/empty /run
    install -m 600 /config/ssh_host_ed25519_key /etc/ssh/ssh_host_ed25519_key
    install -m 600 /config/authorized_keys /root/.ssh/authorized_keys
    # The image's root account is locked ("!"), which sshd rejects even for key auth; "*" means
    # "no password" without being locked.
    { echo 'root:*:1::::::'; grep -v '^root:' /etc/shadow; } > /etc/shadow.new
    mv /etc/shadow.new /etc/shadow
    grep -q '^sshd:' /etc/passwd || echo 'sshd:x:74:74:sshd:/var/empty:/bin/false' >> /etc/passwd
    grep -q '^sshd:' /etc/group || echo 'sshd:x:74:' >> /etc/group

    cat > /etc/ssh/sshd_config <<CONF
    Port 22
    HostKey /etc/ssh/ssh_host_ed25519_key
    PermitRootLogin prohibit-password
    PasswordAuthentication no
    KbdInteractiveAuthentication no
    AuthorizedKeysFile /root/.ssh/authorized_keys
    SetEnv PATH=$PATH:/bin:/usr/bin
    CONF

    exec ${openssh}/bin/sshd -D -e -f /etc/ssh/sshd_config
  '';

  createArgs = [
    "--name"
    name
    "--arch"
    "arm64"
    "--rosetta"
    # For unmounting the /proc overmounts and registering binfmt_misc.
    "--cap-add"
    "ALL"
    "--cpus"
    (toString cpus)
    "--memory"
    memory
    "--publish"
    "127.0.0.1:${toString port}:22"
    "--volume"
    "${containerDir}:/config"
    "--volume"
    "${entrypoint}:/entrypoint"
    image
    "sh"
    "/entrypoint/entrypoint.sh"
  ];
  # The container (and its Nix store) persists across restarts. It is recreated only when its
  # configuration changes, detected through this label.
  configHash = builtins.hashString "sha256" (builtins.toJSON createArgs);

  start = pkgs.writeShellScript "${name}-start" ''
    set -eu
    mkdir -p ${pkgs.lib.escapeShellArg containerDir}
    chmod 700 ${pkgs.lib.escapeShellArg stateDir}
    if [ ! -e ${pkgs.lib.escapeShellArg clientKey} ]; then
      ${pkgs.openssh}/bin/ssh-keygen -q -t ed25519 -N "" -C ${name}-client -f ${pkgs.lib.escapeShellArg clientKey}
    fi
    if [ ! -e ${pkgs.lib.escapeShellArg "${containerDir}/ssh_host_ed25519_key"} ]; then
      ${pkgs.openssh}/bin/ssh-keygen -q -t ed25519 -N "" -C ${name}-host -f ${pkgs.lib.escapeShellArg "${containerDir}/ssh_host_ed25519_key"}
    fi
    cp ${pkgs.lib.escapeShellArg "${clientKey}.pub"} ${pkgs.lib.escapeShellArg "${containerDir}/authorized_keys"}
    echo "${name} $(cut -d' ' -f1,2 ${pkgs.lib.escapeShellArg "${containerDir}/ssh_host_ed25519_key.pub"})" > ${pkgs.lib.escapeShellArg knownHosts}

    ${containerCli} system start --disable-kernel-install

    if info=$(${containerCli} inspect ${name} 2>/dev/null); then
      if [ "$(echo "$info" | ${pkgs.jq}/bin/jq -r '.[0].status.state')" = running ]; then
        # `start --attach` refuses a running container, and launchd needs a foreground process.
        ${containerCli} stop ${name}
      fi
      if [ "$(echo "$info" | ${pkgs.jq}/bin/jq -r '.[0].configuration.labels."nix-config" // ""')" != ${configHash} ]; then
        ${containerCli} delete ${name}
      fi
    fi
    if ! ${containerCli} inspect ${name} > /dev/null 2>&1; then
      ${containerCli} create --label nix-config=${configHash} ${pkgs.lib.escapeShellArgs createArgs}
    fi
    exec ${containerCli} start --attach ${name}
  '';
in {
  launchd.user.agents.${name} = {
    command = "${start} > /tmp/${name}.log 2>&1";
    serviceConfig = {
      KeepAlive = true;
      RunAtLoad = true;
    };
  };

  # Nix passes no host key of its own (the `-` in `builders`), so ssh uses this known_hosts.
  environment.etc."ssh/ssh_config.d/200-${name}.conf".text = ''
    Host ${name}
      User root
      Hostname 127.0.0.1
      Port ${toString port}
      HostKeyAlias ${name}
      IdentityFile "${clientKey}"
      UserKnownHostsFile "${knownHosts}"
      StrictHostKeyChecking yes
  '';

  # Determinate's own native Linux builder builds against the host's case-insensitive store, which
  # breaks e.g. ncurses' terminfo (`l/` vs `L/`) and hence the NixOS initrd. Nix would still use it
  # for `preferLocalBuild` derivations, so turn it off. (It sets `external-builders` after including
  # nix.custom.conf, so we can't override it there.)
  environment.etc."determinate/config.json".text = builtins.toJSON {
    builder.state = "disabled";
  };

  # Determinate Nix owns /etc/nix/nix.conf and includes this file.
  environment.etc."nix/nix.custom.conf" = {
    text = ''
      extra-experimental-features = nix-command flakes ca-derivations
      builders = ssh-ng://${name} aarch64-linux,x86_64-linux - ${toString cpus} 1 big-parallel,benchmark - -
      builders-use-substitutes = true
    '';
    # The file as the Determinate installer wrote it.
    knownSha256Hashes = ["2e24c043dd5f54a2181b8100fff9724daea583161825180e15f439a1bd304f56"];
  };
}
