package tomei

import (
	"tomei.terassyi.net/presets/aqua"
	gopreset "tomei.terassyi.net/presets/go"
	"tomei.terassyi.net/presets/node"
	"tomei.terassyi.net/presets/rust"
)

goTools: gopreset.#GoToolSet & {
	metadata: name: "go-tools"
	spec: tools: {
		gopls: {package: "golang.org/x/tools/gopls", version: "latest"}
		goimports: {package: "golang.org/x/tools/cmd/goimports", version: "latest"}
		cue: {package: "cuelang.org/go/cmd/cue", version: "latest"}
		"protoc-gen-go": {package: "google.golang.org/protobuf/cmd/protoc-gen-go", version: "latest"}
		"protoc-gen-go-grpc": {package: "google.golang.org/grpc/cmd/protoc-gen-go-grpc", version: "latest"}
		dlv: {package: "github.com/go-delve/delve/cmd/dlv", version: "latest"}
		gobgp: {package: "github.com/osrg/gobgp/v4/cmd/gobgp", version: "latest"}
		cfssl: {package: "github.com/cloudflare/cfssl/cmd/cfssl", version: "latest"}
		cfssljson: {package: "github.com/cloudflare/cfssl/cmd/cfssljson", version: "latest"}
	}
}

cargoBinstall:     rust.#CargoBinstall
binstallInstaller: rust.#BinstallInstaller

rustTools: rust.#BinstallToolSet & {
	metadata: name: "rust-tools"
	spec: tools: {
		stylua: {package: "stylua", version: "2.3.1"}
		eza: {package: "eza"}
		btm: {package: "bottom"}
		tokei: {package: "tokei"}
		"license-generator": {package: "license-generator"}
		"cargo-expand": {package: "cargo-expand"}
		"cargo-generate": {package: "cargo-generate"}
		jj: {package: "jj-cli"}
	}
}

nodeTools: node.#PnpmToolSet & {
	metadata: name: "node-tools"
	spec: tools: {
		gemini: {package: "@google/gemini-cli", version: "0.32.1"}
	}
}

protoTools: aqua.#AquaToolSet & {
	metadata: name: "proto-tools"
	spec: tools: {
		protoc: {package: "protocolbuffers/protobuf/protoc", version: "v34.0"}
		grpcurl: {package: "fullstorydev/grpcurl", version: "v1.9.3"}
	}
}
