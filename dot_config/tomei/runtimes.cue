package tomei

import (
	gopreset "tomei.terassyi.net/presets/go"
	"tomei.terassyi.net/presets/rust"
	"tomei.terassyi.net/presets/node"
	"tomei.terassyi.net/presets/python"
)

goRuntime: gopreset.#GoRuntime & {
	platform: {os: _os, arch: _arch}
	spec: version: "1.26.0"
}

rustRuntime: rust.#RustRuntime & {
	spec: version: "stable"
}

pnpmRuntime: node.#PnpmRuntime & {
	spec: version: "10.29.3"
}

uvRuntime: python.#UvRuntime & {
	spec: version: "0.10.6"
}

luaRuntime: {
	apiVersion: "tomei.terassyi.net/v1beta1"
	kind:       "Runtime"
	metadata: name: "lua"
	spec: {
		type:    "delegation"
		version: "5.5.0"
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
