#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 12 ]]; then
    echo "usage: $0 <silex> <target> <STD> <JSON> <GFX> <GFX.Assets> <GFX.Audio> <GFX.Font> <GFX.Canvas> <Image> <GFX.WebView> <temporary-directory>" >&2
    exit 2
fi

silex="$1"
target="$2"
std_dir="$(cd -- "$3" && pwd)"
json_dir="$(cd -- "$4" && pwd)"
gfx_dir="$(cd -- "$5" && pwd)"
assets_dir="$(cd -- "$6" && pwd)"
audio_dir="$(cd -- "$7" && pwd)"
font_dir="$(cd -- "$8" && pwd)"
canvas_dir="$(cd -- "$9" && pwd)"
image_dir="$(cd -- "${10}" && pwd)"
webview_dir="$(cd -- "${11}" && pwd)"
temporary_dir="${12}"
integrated_consumer="$webview_dir/Tests/Portability"

mkdir -p "$temporary_dir"
# GFX.Font's public consumer intentionally verifies a relative workspace path.
# Recreate only its scratch parent when the CI checkouts are laid out flat.
mkdir -p "$(pwd)/Packages/GFX.Font/Tests/Consumer/Tests"

link_into() {
    local workspace="$1"
    shift
    for package_dir in "$@"; do
        "$silex" link "$package_dir" --workspace "$workspace" --target "$target"
    done
    "$silex" packages resolve "$workspace"
}

run_consumer() {
    local consumer="$1"
    local output
    output="$(SDL_AUDIODRIVER=dummy "$silex" test "$consumer/Tests" --nocache)"
    printf '%s\n' "$output"
    grep -Eq '[1-9][0-9]* passed; 0 failed in [1-9][0-9]* files' <<< "$output"
}

if [[ "$target" == windows-arm64 ]]; then
    # The native ARM64 runner uses the recorded Windows X64 linker through
    # Windows emulation; the other runners already expose their native Zig.
    "$silex" setup
fi

link_into "$integrated_consumer" \
    "$std_dir" "$json_dir" "$gfx_dir" "$assets_dir" "$audio_dir" \
    "$font_dir" "$canvas_dir" "$image_dir" "$webview_dir"

link_into "$audio_dir/Tests/Consumer" "$std_dir" "$gfx_dir" "$audio_dir"
link_into "$font_dir/Tests/Consumer" "$std_dir" "$gfx_dir" "$font_dir"
link_into "$canvas_dir/Tests/Consumer" \
    "$std_dir" "$json_dir" "$gfx_dir" "$assets_dir" "$font_dir" "$canvas_dir"
link_into "$image_dir/Tests/Consumer" "$std_dir" "$gfx_dir" "$image_dir"
link_into "$webview_dir/Tests/Consumer" \
    "$std_dir" "$json_dir" "$gfx_dir" "$webview_dir"

run_consumer "$integrated_consumer"
run_consumer "$audio_dir/Tests/Consumer"
run_consumer "$font_dir/Tests/Consumer"
run_consumer "$canvas_dir/Tests/Consumer"
run_consumer "$image_dir/Tests/Consumer"
run_consumer "$webview_dir/Tests/Consumer"

link_into "$webview_dir" "$std_dir" "$json_dir" "$gfx_dir"
if [[ "$target" == linux-* ]]; then
    webview_output="$(xvfb-run -a env GDK_BACKEND=x11 SDL_VIDEO_DRIVER=x11 \
        NO_AT_BRIDGE=1 LIBGL_ALWAYS_SOFTWARE=1 \
        WEBKIT_DISABLE_COMPOSITING_MODE=1 WEBKIT_DISABLE_DMABUF_RENDERER=1 \
        "$silex" test "$webview_dir/Tests" --nocache)"
else
    webview_output="$("$silex" test "$webview_dir/Tests" --nocache)"
fi
printf '%s\n' "$webview_output"
grep -Fxq '5 passed; 0 failed in 4 files' <<< "$webview_output"

if [[ "$target" == macos-arm64 ]]; then
    link_into "$audio_dir" "$std_dir" "$gfx_dir"
    link_into "$font_dir" "$std_dir" "$gfx_dir"
    link_into "$canvas_dir" \
        "$std_dir" "$json_dir" "$gfx_dir" "$assets_dir" "$font_dir"
    link_into "$image_dir" "$std_dir" "$gfx_dir"
    for package_tests in \
        "$audio_dir/Tests" \
        "$font_dir/Tests" \
        "$canvas_dir/Tests" \
        "$image_dir/Tests"; do
        output="$(SDL_AUDIODRIVER=dummy "$silex" test "$package_tests" --nocache)"
        printf '%s\n' "$output"
        grep -Eq '[1-9][0-9]* passed; 0 failed in [1-9][0-9]* files' <<< "$output"
    done
fi

echo "PASS $target official desktop package suite"
