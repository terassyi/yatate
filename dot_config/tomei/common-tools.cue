package tomei

import "tomei.terassyi.net/presets/aqua"

// Override the builtin "aqua" installer to enable the minimumReleaseAge
// supply-chain gate: refuse to install any aqua-fetched tool whose upstream
// release is younger than 1 week, giving the community time to flag a
// compromised release. Applies to every aqua-installed tool (cliTools,
// k8sTools, crane, pwru, ffmpeg, ...). The override MUST keep type: "download".
aquaInstaller: {
	apiVersion: "tomei.terassyi.net/v1beta1"
	kind:       "Installer"
	metadata: name: "aqua"
	spec: {
		type:              "download"
		minimumReleaseAge: "168h"
	}
}

cliTools: aqua.#AquaToolSet & {
	metadata: name: "cli-tools"
	spec: tools: {
		rg: {package: "BurntSushi/ripgrep", version: "15.1.0"}
		fd: {package: "sharkdp/fd", version: "v10.4.2"}
		jq: {package: "jqlang/jq", version: "1.8.1"}
		bat: {package: "sharkdp/bat", version: "v0.26.1"}
		delta: {package: "dandavison/delta", version: "0.19.2"}
		zellij: {package: "zellij-org/zellij", version: "v0.44.3"}
		just: {package: "casey/just", version: "1.51.0"}
		gh: {package: "cli/cli", version: "v2.93.0"}
		zoxide: {package: "ajeetdsouza/zoxide", version: "v0.9.9"}
		gitui: {package: "gitui-org/gitui", version: "v0.28.1"}
		sk: {package: "skim-rs/skim", version: "v4.7.0"}
		starship: {package: "starship/starship", version: "v1.25.1"}
		hugo: {package: "gohugoio/hugo", version: "v0.162.1"}
		"golangci-lint": {package: "golangci/golangci-lint", version: "v2.12.2"}
		task: {package: "go-task/task", version: "v3.51.1"}
		age: {package: "FiloSottile/age", version: "v1.3.1"}
		cloudflared: {package: "cloudflare/cloudflared", version: "2026.5.2"}
		// tree-sitter CLI for nvim-treesitter's `main` branch (generates and
		// compiles parsers; needed wherever neovim runs). The aqua registry asset
		// is a bare `.gz` single binary stored without an exec bit; tomei extracts
		// bare gz (#272), sets the exec bit (#273), and (v0.2.2) places it under
		// the registry files[].src name (#281), so the plain aqua path works.
		"tree-sitter": {package: "tree-sitter/tree-sitter", version: "v0.26.9"}
		// herdr: agent-aware terminal multiplexer (tmux/zellij-like panes + AI
		// coding-agent state in a sidebar). Binary name matches the key.
		herdr: {package: "ogulcancelik/herdr", version: "v0.7.1"}
	}
}

// aqua CLI itself, for standalone use outside tomei (tomei's builtin "aqua"
// installer only consumes the registry and does not provide the binary).
// aqua is not registered in its own registry, so install via explicit
// GitHub release download with checksum verification.
aquaCli: {
	apiVersion: "tomei.terassyi.net/v1beta1"
	kind:       "Tool"
	metadata: name: "aqua"
	spec: {
		installerRef: "download"
		version:      "2.60.1"
		source: {
			url: "https://github.com/aquaproj/aqua/releases/download/v\(spec.version)/aqua_\(_os)_\(_arch).tar.gz"
			checksum: url: "https://github.com/aquaproj/aqua/releases/download/v\(spec.version)/aqua_\(spec.version)_checksums.txt"
		}
	}
}

claudeCode: {
	apiVersion: "tomei.terassyi.net/v1beta1"
	kind:       "Tool"
	metadata: name: "claude"
	spec: {
		version: "latest"
		commands: {
			install: ["curl -fsSL https://claude.ai/install.sh | bash"]
			update: ["claude update"]
			check: ["claude --version"]
			remove: ["rm -f ~/.local/bin/claude"]
		}
	}
}

// Google Antigravity CLI (binary: agy), installed via the official curl
// script into ~/.local/bin. It self-updates in the background, so there is
// no update command. Replaces the former @google/gemini-cli (pnpm) tool.
antigravityCli: {
	apiVersion: "tomei.terassyi.net/v1beta1"
	kind:       "Tool"
	metadata: {
		name:        "agy"
		description: "Google Antigravity CLI"
	}
	spec: {
		version: "latest"
		commands: {
			install: ["curl -fsSL https://antigravity.google/cli/install.sh | bash"]
			check: ["command -v agy"]
			remove: ["rm -f ~/.local/bin/agy"]
		}
	}
}

k8sTools: aqua.#AquaToolSet & {
	metadata: name: "k8s-tools"
	spec: tools: {
		kubectl: {package: "kubernetes/kubernetes/kubectl", version: "v1.36.1"}
		helm: {package: "helm/helm", version: "v4.2.0"}
		kind: {package: "kubernetes-sigs/kind", version: "v0.31.0"}
		kustomize: {package: "kubernetes-sigs/kustomize", version: "v5.8.1"}
		stern: {package: "stern/stern", version: "v1.34.0"}
		cosign: {package: "sigstore/cosign", version: "v3.0.6"}
		cilium: {package: "cilium/cilium-cli", version: "v0.19.4"}
		hubble: {package: "cilium/hubble", version: "v1.19.3"}
	}
}

// krew: kubectl plugin manager installed via aqua with binaryName override
krew: {
	apiVersion: "tomei.terassyi.net/v1beta1"
	kind:       "Tool"
	metadata: name: "krew"
	spec: {
		installerRef: "aqua"
		version:      "v0.5.0"
		package: {
			owner: "kubernetes-sigs"
			repo:  "krew"
		}
		binaryName: "kubectl-krew"
	}
}

// krew delegation Installer — declares binDir for PATH inclusion
krewInstaller: {
	apiVersion: "tomei.terassyi.net/v1beta1"
	kind:       "Installer"
	metadata: name: "krew"
	spec: {
		type:    "delegation"
		toolRef: "krew"
		dependsOn: ["kubectl"]
		binDir: "~/.krew/bin"
		commands: {
			install: ["kubectl krew install {{.Package}}"]
			check: ["kubectl krew list 2>/dev/null | grep -q ^{{.Name}}$"]
			remove: ["kubectl krew uninstall {{.Name}}"]
		}
	}
}

// mft krew custom index — required for installing mft plugin
mftIndex: {
	apiVersion: "tomei.terassyi.net/v1beta1"
	kind:       "InstallerRepository"
	metadata: name: "mft"
	spec: {
		installerRef: "krew"
		source: {
			type: "delegation"
			url:  "https://github.com/chez-shanpu/kubectl-mft.git"
			commands: {
				install: ["kubectl krew index add mft https://github.com/chez-shanpu/kubectl-mft.git"]
				check: ["kubectl krew index list 2>/dev/null | grep -q ^mft"]
				remove: ["kubectl krew index remove mft"]
			}
		}
	}
}

// kubectl-mft: manage Kubernetes manifests as OCI artifacts (via krew)
kubectlMft: {
	apiVersion: "tomei.terassyi.net/v1beta1"
	kind:       "Tool"
	metadata: {
		name:        "mft"
		description: "Manage Kubernetes manifests as OCI artifacts"
	}
	spec: {
		installerRef:  "krew"
		repositoryRef: "mft"
		version:       "v0.5.0"
		package: name: "mft/mft"
	}
}

// crane: container registry CLI (aqua package includes crane and gcrane)
crane: {
	apiVersion: "tomei.terassyi.net/v1beta1"
	kind:       "Tool"
	metadata: name: "crane"
	spec: {
		installerRef: "aqua"
		version:      "v0.21.6"
		package:      "google/go-containerregistry"
		binaryName:   "crane"
	}
}

