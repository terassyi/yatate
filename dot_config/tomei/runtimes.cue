package tomei

import (
	gopreset "tomei.terassyi.net/presets/go"
	"tomei.terassyi.net/presets/rust"
	"tomei.terassyi.net/presets/node"
	"tomei.terassyi.net/presets/python"
)

goRuntime: gopreset.#GoRuntime & {
	platform: {os: _os, arch: _arch}
	spec: version: "1.27.3"
}

rustRuntime: rust.#RustRuntime & {
	spec: version: "stable"
}

// pnpm is held on the 10.x line: pnpm 11+ moved pnpm/pnpx/node and global
// bins under $PNPM_HOME/bin/, but node.#PnpmRuntime (tomei cuemodule v0.2.1,
// same on upstream main) hardcodes $PNPM_HOME/pnpm for install/check/binDir,
// so `tomei apply` fails with "pnpm: not found" on 11+. Bump once the preset
// supports the bin/ layout.
pnpmRuntime: node.#PnpmRuntime & {
	spec: version: "10.34.7"
}

uvRuntime: python.#UvRuntime & {
	spec: version: "0.13.1"
}

_zigOSMap: {darwin: "macos", linux: "linux"}
_zigArchMap: {amd64: "x86_64", arm64: "aarch64"}

zigRuntime: {
	let _zigOS = _zigOSMap[_os]
	let _zigArch = _zigArchMap[_arch]

	apiVersion: "tomei.terassyi.net/v1beta1"
	kind:       "Runtime"
	metadata: name: "zig"
	platform: {os: _os, arch: _arch}
	spec: {
		type:    "download"
		version: "0.17.0"
		source: {
			// Zig 0.15+ renamed tarballs to arch-first (zig-<arch>-<os>-<ver>.tar.xz).
			url: "https://ziglang.org/download/{{.Version}}/zig-\(_zigArch)-\(_zigOS)-{{.Version}}.tar.xz"
		}
		binaries: ["zig"]
		binDir: "~/.local/share/tomei/runtimes/zig/{{.Version}}"
	}
}

luaRuntime: {
	apiVersion: "tomei.terassyi.net/v1beta1"
	kind:       "Runtime"
	metadata: name: "lua"
	spec: {
		type:    "delegation"
		version: "5.5.1"
		bootstrap: {
			install:
				"""
					set -e
					LUA_PREFIX="${HOME}/.local/share/tomei/runtimes/lua/{{.Version}}"
					TMPDIR="$(mktemp -d)"
					curl -fsSL -o "${TMPDIR}/lua-{{.Version}}.tar.gz" "https://www.lua.org/ftp/lua-{{.Version}}.tar.gz"
					tar zxf "${TMPDIR}/lua-{{.Version}}.tar.gz" -C "${TMPDIR}"
					make -C "${TMPDIR}/lua-{{.Version}}" all INSTALL_TOP="${LUA_PREFIX}"
					make -C "${TMPDIR}/lua-{{.Version}}" install INSTALL_TOP="${LUA_PREFIX}"
					rm -rf "${TMPDIR}"
					"""
			check:  "$HOME/.local/share/tomei/runtimes/lua/\(spec.version)/bin/lua -v"
			remove: "rm -rf $HOME/.local/share/tomei/runtimes/lua/\(spec.version)"
		}
		binaries: ["lua", "luac"]
		binDir:      "~/.local/share/tomei/runtimes/lua/\(spec.version)/bin"
		toolBinPath: "~/.local/share/tomei/runtimes/lua/\(spec.version)/bin"
		env: {
			LUA_HOME: "~/.local/share/tomei/runtimes/lua/\(spec.version)"
		}
	}
}
