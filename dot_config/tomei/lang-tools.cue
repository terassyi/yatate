package tomei

import (
	"tomei.terassyi.net/presets/aqua"
	gopreset "tomei.terassyi.net/presets/go"
	"tomei.terassyi.net/presets/rust"
)

goTools: gopreset.#GoToolSet & {
	metadata: name: "go-tools"
	spec: tools: {
		gopls:                {package: "golang.org/x/tools/gopls", version: "latest"}
		"protoc-gen-go":      {package: "google.golang.org/protobuf/cmd/protoc-gen-go", version: "latest"}
		"protoc-gen-go-grpc": {package: "google.golang.org/grpc/cmd/protoc-gen-go-grpc", version: "latest"}
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

protoTools: aqua.#AquaToolSet & {
	metadata: name: "proto-tools"
	spec: tools: {
		protoc:  {package: "protocolbuffers/protobuf/protoc", version: "v34.0"}
		grpcurl: {package: "fullstorydev/grpcurl", version: "v1.9.3"}
	}
}
