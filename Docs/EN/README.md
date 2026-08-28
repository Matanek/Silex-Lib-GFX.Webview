# Display an HTML interface with GFX.WebView

`GFX.WebView` displays HTML, CSS, and JavaScript in the WebView supplied by the
operating system. It embeds neither Chromium nor another browser runtime in
GFX.

[Lire cette documentation en français.](../FR/README.md)

## Install the package

```text
silex install GFX.WebView
```

GFX.WebView requires Silex 0.40.0 or newer.

## Open an embedded site

The plugin owns the view throughout the application lifecycle:

```sx
use GFX.Application
use GFX.WebView

func main() {
    var site = WebView.Site.html(embed_text("Web/index.html"))
    site.add(WebView.Asset.css(embed_text("Web/app.css"), path:"/app.css"))
    site.add(WebView.Asset.javascript(embed_text("Web/app.js"), path:"/app.js"))

    Application()
        ..add_plugin(WebView.Plugin(site, WebView.Settings(context_menu:true)))
        ..run()
}
```

Paths passed to `embed_text` are relative to the `.sx` file and known at
compile time. The plugin installs Window and Input itself, creates the view
during `Schedule.startup`, flushes messages after updates, and destroys the
view at shutdown. Closing the window stops the application by default.

A direct program can construct `WebView.View(window, site)` and own its window,
event loop, and lifecycle.

## Embed assets

Logical paths begin with `/` and identify resources in the site. `Asset.html`,
`Asset.css`, and `Asset.javascript` associate text with a path and media type.
The general initializer accepts other formats:

```sx
let manifest = WebView.Asset(
    content:embed_text("Web/manifest.json"),
    path:"/manifest.json",
    media_type:WebView.MediaType.json,
)
```

Binary resources use `embed_bytes`:

```sx
site.add(WebView.Asset(
    content:embed_bytes("Web/icon.png"),
    path:"/icon.png",
    media_type:WebView.MediaType.png,
))
```

`MediaType` names formats independently of their extension;
`MediaType.custom(...)` covers a type absent from the enum. Document references
are replaced by self-contained data URLs. Each adapter assembles one document
before loading it; the source directory is not distributed beside the
executable.

## Exchange messages

The `window.silex` bridge is installed at document start, before HTML scripts.
JavaScript can therefore subscribe and send immediately:

```js
window.silex.send("action", "save")
window.silex.on("status", payload => {
    document.querySelector("#status").textContent = payload
})
```

Silex receives messages and queues its responses:

```sx
for message in view.receive() {
    if message.name == "action" {
        view.send("status", "Saved " + message.payload)
    }
}
view.flush()
```

`flush` makes no platform call when the queue is empty and otherwise sends the
whole queue in one JavaScript evaluation. In the other direction, JavaScript
groups calls made during one microtask. Order is preserved both ways.

Names and payloads are strings; an application can encode JSON in them.
Dispatch remains asynchronous and does not participate in rendering frames.

## Manage the view and appearance

`View` has no public per-frame `update()` operation. WebKit or WebView2 owns
layout, JavaScript, painting, and invalidation; `status`, `receive`, and `flush`
only perform platform housekeeping.

The window and WebView are transparent by default. `Settings.background` and
`set_background(Color)` replace the native background; an opaque CSS
background still takes precedence. The system context menu is disabled by
default and enabled with `WebView.Settings(context_menu:true)`.

Create, use, and destroy the window and view on the main thread. `View` retains
its `GFX.Window`, fills its content, and follows resizing.

An optional target can be inspected before creation:

```sx
let web_view = WebView.availability()
if !web_view.is_available() {
    if let reason = web_view.reason() { print(reason) }
    return
}
```

## Know the platforms

- `macos-arm64` uses Cocoa and WebKit through Objective-C Interop.
- `linux-x64` uses GTK 3, WebKitGTK 4.1, and X11. XWayland follows this path;
  native Wayland attachment is not implemented yet.
- `windows-x64` and `windows-arm64` use the installed Microsoft Edge WebView2
  runtime and architecture-specific static loader. Windows ARM64 remains a
  recognized experimental target in the Silex matrix.

The browser engine remains supplied by the selected system. macOS and Linux
bind their facilities directly through Interop; Windows does the same for
Win32 and COM and adds only the official WebView2 loader.

The complete [EmbeddedWebView](https://github.com/Matanek/Silex-Examples/tree/main/Sources/EmbeddedWebView)
and [WebViewBridge](https://github.com/Matanek/Silex-Examples/blob/main/Sources/WebViewBridge.sx)
applications belong to Silex-Examples. The messaging benchmark belongs to
[Silex-Benchmarks](https://github.com/Matanek/Silex-Benchmarks/tree/main/Sources/WebViewBridgeRoundTrips).
