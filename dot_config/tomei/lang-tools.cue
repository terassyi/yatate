package tomei

import (
	"tomei.terassyi.net/schema"
	"tomei.terassyi.net/presets/aqua"
	"tomei.terassyi.net/presets/node"
	"tomei.terassyi.net/presets/rust"
)

// go tools pinned to git commit SHAs (runtimeRef: "go" verifies the SHA via
// GOSUMDB). The #GoToolSet preset mandates a non-empty version, which is
// mutually exclusive with sha, so this uses the raw schema.#ToolSet. SHAs are
// the commits the listed release tags point to (resolved via the Go module
// proxy). Bump by re-resolving `go list`/`go mod download -json @<tag>`.
goTools: schema.#ToolSet & {
	apiVersion: "tomei.terassyi.net/v1beta1"
	kind:       "ToolSet"
	metadata: name: "go-tools"
	spec: {
		runtimeRef: "go"
		tools: {
			// gopls v0.22.0
			gopls: {package: "golang.org/x/tools/gopls", sha: "235f6b391a9df7be9bfce1c34bc29404412be72c"}
			// golang.org/x/tools v0.45.0
			goimports: {package: "golang.org/x/tools/cmd/goimports", sha: "2aabba0e4be44cc8f254ced118a7156d04bbc9f3"}
			// cue v0.16.1
			cue: {package: "cuelang.org/go/cmd/cue", sha: "6d609d768f1686f9a3a2a20197cacdbb70e5c79d"}
			// protobuf v1.36.11
			"protoc-gen-go": {package: "google.golang.org/protobuf/cmd/protoc-gen-go", sha: "96a179180f0ad6bba9b1e7b6e38d0affb0168e9a"}
			// protoc-gen-go-grpc v1.6.2
			"protoc-gen-go-grpc": {package: "google.golang.org/grpc/cmd/protoc-gen-go-grpc", sha: "1c63fa5f5492fb6cb4cabf9847999ce469505f49"}
			// delve v1.26.3
			dlv: {package: "github.com/go-delve/delve/cmd/dlv", sha: "b17676cac1c1b8588ebdc906ea890e8f075cd948"}
			// gobgp v4.6.0
			gobgp: {package: "github.com/osrg/gobgp/v4/cmd/gobgp", sha: "51511000d5b566e9c6d20c7b90e6d9cd23140c51"}
			// cfssl v1.6.5
			cfssl: {package: "github.com/cloudflare/cfssl/cmd/cfssl", sha: "96259aa29c9cc9b2f4e04bad7d4bc152e5405dda"}
			cfssljson: {package: "github.com/cloudflare/cfssl/cmd/cfssljson", sha: "96259aa29c9cc9b2f4e04bad7d4bc152e5405dda"}
		}
	}
}

cargoBinstall:     rust.#CargoBinstall
binstallInstaller: rust.#BinstallInstaller

rustTools: rust.#BinstallToolSet & {
	metadata: name: "rust-tools"
	spec: tools: {
		stylua: {package: "stylua", version: "2.5.2"}
		eza: {package: "eza"}
		btm: {package: "bottom"}
		tokei: {package: "tokei"}
		"license-generator": {package: "license-generator"}
		"cargo-expand": {package: "cargo-expand"}
		"cargo-generate": {package: "cargo-generate"}
		jj: {package: "jj-cli"}
		// eBPF (rust + aya): bpf-linker links eBPF bytecode (binstall = prebuilt,
		// so no system LLVM build needed); bindgen-cli is used by aya-tool to
		// generate Rust bindings for kernel structures (needs libclang at runtime,
		// provided by the bpf-dev SystemPackageSet).
		"bpf-linker": {package: "bpf-linker"}
		"bindgen-cli": {package: "bindgen-cli"}
	}
}

// Rust nightly toolchain + rust-src, required to build aya-ebpf programs
// (`cargo +nightly build -Z build-std=core` for the bpfel-unknown-none target).
// Installed via rustup (provided by the `rust` runtime); dependsOn orders this
// after that runtime. The default toolchain stays stable (see runtimes.cue).
rustNightly: {
	apiVersion: "tomei.terassyi.net/v1beta1"
	kind:       "Tool"
	metadata: {
		name:        "rust-nightly"
		description: "Rust nightly toolchain with rust-src (aya-ebpf build-std)"
	}
	spec: {
		version:   "nightly"
		dependsOn: ["rust"]
		commands: {
			install: ["~/.cargo/bin/rustup toolchain install nightly --profile minimal --component rust-src --no-self-update"]
			update: ["~/.cargo/bin/rustup update nightly"]
			check: ["~/.cargo/bin/rustup toolchain list | grep -q '^nightly'"]
			remove: ["~/.cargo/bin/rustup toolchain uninstall nightly"]
		}
	}
}

rustupComponentInstaller: rust.#RustupComponentInstaller

rustupComponents: rust.#RustupComponentToolSet & {
	metadata: name: "rustup-components"
	spec: tools: {
		"rust-analyzer": {}
		"rust-src": {}
	}
}

nodeTools: node.#PnpmToolSet & {
	metadata: name: "node-tools"
	spec: tools: {
		gws: {package: "@googleworkspace/cli", version: "0.22.5"}
	}
}

protoTools: aqua.#AquaToolSet & {
	metadata: name: "proto-tools"
	spec: tools: {
		protoc: {package: "protocolbuffers/protobuf/protoc", version: "v35.0"}
		grpcurl: {package: "fullstorydev/grpcurl", version: "v1.9.3"}
	}
}
