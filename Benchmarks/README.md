# GFX.WebView benchmarks

`WebViewBridge.sx` exercises 1,000 round trips through the public batched
message bridge. It intentionally carries no machine-dependent timing
threshold; use an external profiler or command timer when measuring it.
