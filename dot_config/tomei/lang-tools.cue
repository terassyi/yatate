package tomei

import (
	gopreset "tomei.terassyi.net/presets/go"
	"tomei.terassyi.net/presets/rust"
)

goTools: gopreset.#GoToolSet & {
	metadata: name: "go-tools"
	spec: tools: {
		gopls: {package: "golang.org/x/tools/gopls", version: "v0.21.1"}
	}
}

cargoBinstall: rust.#CargoBinstall
binstallInstaller: rust.#BinstallInstaller

rustTools: rust.#BinstallToolSet & {
	metadata: name: "rust-tools"
	spec: tools: {
		stylua: {package: "stylua", version: "2.3.1"}
		eza:    {package: "eza"}
		btm:    {package: "bottom"}
		tokei:  {package: "tokei"}
	}
}
