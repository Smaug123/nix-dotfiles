{lib, ...}: {
  # Tell PlugInKit to ignore Safari's WidgetKit extension. chronod launches it at login even with
  # no Safari widget placed, and the system then suspends it while it holds an FSEvents stream.
  # Nothing ever drains that stream, so fseventsd's queue for it grows until fseventsd spends a
  # full core on every file event. Undo with
  # `pluginkit -e default -i com.apple.Safari.SafariWidgetExtension`.
  home.activation.ignoreSafariWidgetExtension = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run /usr/bin/pluginkit -e ignore -i com.apple.Safari.SafariWidgetExtension
  '';
}
