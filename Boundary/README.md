# Windows WebView2 loader archives

The Windows archives are built from OpenWebView2Loader commit
`fb3a1687029b986b235dc64d98b395d0cd581494` with Zig 0.16.0. The local patch
uses compiler atomics for the loader's internal reference count. The companion
C source supplies the two atomic entry points used by the Silex COM bridge.

From an OpenWebView2Loader checkout at that commit:

```sh
cp /path/to/GFX.WebView/Boundary/Source/EventToken.h Include/EventToken.h
git apply /path/to/GFX.WebView/Boundary/OpenWebView2Loader.patch
zig c++ -target x86_64-windows-gnu -O2 -fno-exceptions -fno-rtti -c Source/WebView2Loader.cpp -IInclude -ISource -o OpenWebView2Loader-x64.o
zig cc -target x86_64-windows-gnu -O2 -c /path/to/GFX.WebView/Boundary/Source/OpenWebView2LoaderAtomics.c -o OpenWebView2LoaderAtomics-x64.o
zig ar rcs WebView2LoaderStatic-x64.lib OpenWebView2Loader-x64.o OpenWebView2LoaderAtomics-x64.o
zig c++ -target aarch64-windows-gnu -O2 -fno-exceptions -fno-rtti -c Source/WebView2Loader.cpp -IInclude -ISource -o OpenWebView2Loader-arm64.o
zig cc -target aarch64-windows-gnu -O2 -c /path/to/GFX.WebView/Boundary/Source/OpenWebView2LoaderAtomics.c -o OpenWebView2LoaderAtomics-arm64.o
zig ar rcs WebView2LoaderStatic-arm64.lib OpenWebView2Loader-arm64.o OpenWebView2LoaderAtomics-arm64.o
```
