# GFX.WebView

GFX.WebView displays embedded HTML, CSS and JavaScript inside a system WebView
attached to a `GFX.Window`. It uses the operating-system browser engine and
does not distribute Chromium or another browser runtime.

```text
silex install GFX.WebView
```

```sx
use GFX.Application
use GFX.WebView

func main() {
    let site = WebView.Site.html(
        "<!doctype html><html><body><h1>Silex</h1></body></html>"
    )
    Application()
        ..add_plugin(WebView.Plugin(site))
        ..run()
}
```

The package owns its portable WebView API, application plugin, platform
adapters, examples, tests and target-selected system boundary. It depends only
on public GFX capabilities and contributes its plugin and resource views to
`GFX.Plugins` and `GFX.Resources`.

`Tests/Consumer` is an anonymous application fixture with its own manifest. It
verifies those declarations from outside the package with no privileged access.

See [Docs/README.md](Docs/README.md) for assets, messaging, lifecycle and
platform availability.
