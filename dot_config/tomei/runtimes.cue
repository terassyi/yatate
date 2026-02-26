package tomei

import (
	gopreset "tomei.terassyi.net/presets/go"
	"tomei.terassyi.net/presets/rust"
	"tomei.terassyi.net/presets/node"
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
