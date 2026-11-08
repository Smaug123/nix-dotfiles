# NixOS asserts that every user's primary `group` is declared, but silently ignores an
# `extraGroups` entry naming an undeclared group. So a typo such as "networkManager" for
# "networkmanager" evaluates, builds and deploys without complaint, and the user just
# isn't in the group. Make every such reference an evaluation-time assertion failure.
{
  config,
  lib,
  ...
}: let
  enabledUsers = lib.filterAttrs (_: u: u.enable) config.users.users;
  references = lib.concatLists (lib.mapAttrsToList (user: u: map (group: {inherit user group;}) u.extraGroups) enabledUsers);
in {
  assertions =
    map (r: {
      assertion = config.users.groups ? ${r.group};
      message = "users.users.${r.user}.extraGroups refers to group ‘${r.group}’, but users.groups.${r.group} is not declared.";
    })
    references;
}
