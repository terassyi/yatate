@if(linux)

package tomei

// pwru: eBPF packet tracer (linux only)
pwru: {
	apiVersion: "tomei.terassyi.net/v1beta1"
	kind:       "Tool"
	metadata: name: "pwru"
	spec: {
		installerRef: "aqua"
		version:      "v1.0.11"
		source: {
			url:         "https://github.com/cilium/pwru/releases/download/v1.0.11/pwru-linux-\(_arch).tar.gz"
			archiveType: "tar.gz"
		}
	}
}

// apt SystemInstaller: wires tomei's built-in APT backend (Debian/Ubuntu).
// Requires `tomei apply --system`. spec.commands are descriptive metadata —
// the backend owns the actual apt-get/dpkg invocation.
apt: {
	apiVersion: "tomei.terassyi.net/v1beta1"
	kind:       "SystemInstaller"
	metadata: name: "apt"
	spec: {
		pattern:    "delegation"
		privileged: true
		commands: {
			install: {command: "sudo apt-get install -y"}
			remove: {command: "sudo apt-get remove -y"}
			check: {command: "dpkg -s"}
		}
	}
}

// System packages installed via apt under `tomei apply --system`, split by
// purpose. Generic build tooling is kept separate from the per-language sets.

// common-build: general build toolchain shared across languages.
// mold is a fast linker (ELF/Linux only) usable by gcc/clang for C/C++/Rust.
commonBuild: {
	apiVersion: "tomei.terassyi.net/v1beta1"
	kind:       "SystemPackageSet"
	metadata: name: "common-build"
	spec: {
		installerRef: "apt"
		packages: ["build-essential", "pkg-config", "cmake", "mold"]
	}
}

// bpf-dev: eBPF compilation (clang/llvm), libbpf/CO-RE, bpftool/perf.
bpfDev: {
	apiVersion: "tomei.terassyi.net/v1beta1"
	kind:       "SystemPackageSet"
	metadata: name: "bpf-dev"
	spec: {
		installerRef: "apt"
		packages: [
			"clang",
			"llvm",
			"libbpf-dev",
			"libelf-dev",
			"linux-headers-generic",
			"linux-tools-generic",
		]
	}
}

// rust-dev: Rust-specific system deps (openssl crate).
rustDev: {
	apiVersion: "tomei.terassyi.net/v1beta1"
	kind:       "SystemPackageSet"
	metadata: name: "rust-dev"
	spec: {
		installerRef: "apt"
		packages: ["libssl-dev"]
	}
}

// lua-build: deps for the lua runtime's source build (readline).
luaBuild: {
	apiVersion: "tomei.terassyi.net/v1beta1"
	kind:       "SystemPackageSet"
	metadata: name: "lua-build"
	spec: {
		installerRef: "apt"
		packages: ["libreadline-dev"]
	}
}

// media: media tooling (ffmpeg) via apt.
media: {
	apiVersion: "tomei.terassyi.net/v1beta1"
	kind:       "SystemPackageSet"
	metadata: name: "media"
	spec: {
		installerRef: "apt"
		packages: ["ffmpeg"]
	}
}
