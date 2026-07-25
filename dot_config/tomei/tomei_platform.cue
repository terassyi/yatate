package tomei

// Platform values resolved by tomei apply.
// For cue eval: cue eval -t os=linux -t arch=amd64
_os:       string        @tag(os)
_arch:     string        @tag(arch)
_headless: bool | *false @tag(headless,type=bool)

// Spellings upstream release assets use instead of the tag values above.
// Index with _arch / _os (e.g. _unameArchMap[_arch]).
//
// uname: `uname -m` words, which are also the Rust/LLVM target arch words —
// used by zig, firecracker, the bytecodealliance tools, and many others.
_unameArchMap: {amd64: "x86_64", arm64: "aarch64"}

// macos: projects that spell darwin as "macos" (zig, bytecodealliance, ...).
_macosOSMap: {darwin: "macos", linux: "linux"}
