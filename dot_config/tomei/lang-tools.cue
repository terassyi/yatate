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
			// gopls v0.24.0
			gopls: {package: "golang.org/x/tools/gopls", sha: "1f9922d1dcc5836d5c5bcb552c8fed230f885372"}
			// golang.org/x/tools v0.52.0
			goimports: {package: "golang.org/x/tools/cmd/goimports", sha: "16517d951552611e7bd358c48ee1051fd0e57b0c"}
			// cue v0.17.1
			cue: {package: "cuelang.org/go/cmd/cue", sha: "fc6c0b2ecd3666da92f7053d13fcfbf009b7d7a3"}
			// protobuf v1.36.12
			"protoc-gen-go": {package: "google.golang.org/protobuf/cmd/protoc-gen-go", sha: "cdd4c5f7406e82462949c7a65defa9f3029c162d"}
			// protoc-gen-go-grpc v1.6.2
			"protoc-gen-go-grpc": {package: "google.golang.org/grpc/cmd/protoc-gen-go-grpc", sha: "1c63fa5f5492fb6cb4cabf9847999ce469505f49"}
			// delve v1.27.2
			dlv: {package: "github.com/go-delve/delve/cmd/dlv", sha: "d116177dd925e085ba5dd340f8c644f4a1501a3b"}
			// gobgp v4.10.0
			gobgp: {package: "github.com/osrg/gobgp/v4/cmd/gobgp", sha: "da824d99912e02124b53741245ee4186c381adcc"}
			// cfssl v1.7.1
			cfssl: {package: "github.com/cloudflare/cfssl/cmd/cfssl", sha: "ab47f0d984778865b3f5b5adf6ba336a15b96c31"}
			cfssljson: {package: "github.com/cloudflare/cfssl/cmd/cfssljson", sha: "ab47f0d984778865b3f5b5adf6ba336a15b96c31"}
			// yq v4.54.1 — installed via go rather than aqua because yq's
			// checksums-bsd asset is an rhash multi-algorithm file whose first
			// line is a CRC32 entry; aqua parses it via file_format: regexp +
			// algorithm: sha512, which tomei does not implement (its detector
			// only inspects the first line and reports "unknown checksum file
			// format"). go install verifies the module via GOSUMDB instead.
			yq: {package: "github.com/mikefarah/yq/v4", sha: "504fc38780cc46be8444ea1b72fb55919fc0bfb0"}
		}
	}
}

cargoBinstall:     rust.#CargoBinstall
binstallInstaller: rust.#BinstallInstaller

rustTools: rust.#BinstallToolSet & {
	metadata: name: "rust-tools"
	spec: tools: {
		stylua: {package: "stylua", version: "2.6.0"}
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
	_rustup: "~/.cargo/bin/rustup"

	apiVersion: "tomei.terassyi.net/v1beta1"
	kind:       "Tool"
	metadata: {
		name:        "rust-nightly"
		description: "Rust nightly toolchain with rust-src (aya-ebpf build-std)"
	}
	spec: {
		version: "nightly"
		dependsOn: ["rust"]
		commands: {
			install: ["\(_rustup) toolchain install nightly --profile minimal --component rust-src --no-self-update"]
			update: ["\(_rustup) update nightly --no-self-update"]
			// Verify the rust-src component (the reason this toolchain exists);
			// listing it implies the nightly toolchain is present too.
			check: ["\(_rustup) component list --toolchain nightly --installed 2>/dev/null | grep -q '^rust-src'"]
			remove: ["\(_rustup) toolchain uninstall nightly"]
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
		protoc: {package: "protocolbuffers/protobuf/protoc", version: "v36.2"}
		grpcurl: {package: "fullstorydev/grpcurl", version: "v1.9.4"}
	}
}
