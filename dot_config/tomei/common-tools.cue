package tomei

import "tomei.terassyi.net/presets/aqua"

cliTools: aqua.#AquaToolSet & {
	metadata: name: "cli-tools"
	spec: tools: {
		rg: {package: "BurntSushi/ripgrep", version: "15.1.0"}
		fd: {package: "sharkdp/fd", version: "v10.3.0"}
		jq: {package: "jqlang/jq", version: "1.8.1"}
		bat: {package: "sharkdp/bat", version: "v0.26.1"}
		delta: {package: "dandavison/delta", version: "0.18.2"}
		zellij: {package: "zellij-org/zellij", version: "v0.43.1"}
		just: {package: "casey/just", version: "1.46.0"}
		yq: {package: "mikefarah/yq", version: "v4.52.4"}
		gh: {package: "cli/cli", version: "v2.87.3"}
		zoxide: {package: "ajeetdsouza/zoxide", version: "v0.9.9"}
		gitui: {package: "gitui-org/gitui", version: "v0.28.0"}
		sk: {package: "skim-rs/skim", version: "v3.6.1"}
		starship: {package: "starship/starship", version: "v1.24.2"}
		hugo: {package: "gohugoio/hugo", version: "v0.157.0"}
		"golangci-lint": {package: "golangci/golangci-lint", version: "v2.10.1"}
		task: {package: "go-task/task", version: "v3.48.0"}
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

k8sTools: aqua.#AquaToolSet & {
	metadata: name: "k8s-tools"
	spec: tools: {
		kubectl: {package: "kubernetes/kubernetes/kubectl", version: "v1.35.2"}
		helm: {package: "helm/helm", version: "v4.1.1"}
		kind: {package: "kubernetes-sigs/kind", version: "v0.31.0"}
		kustomize: {package: "kubernetes-sigs/kustomize", version: "v5.8.1"}
		stern: {package: "stern/stern", version: "v1.33.1"}
		cosign: {package: "sigstore/cosign", version: "v3.0.5"}
		cilium: {package: "cilium/cilium-cli", version: "v0.19.2"}
		hubble: {package: "cilium/hubble", version: "v1.18.6"}
	}
}

// krew: kubectl plugin manager installed via aqua with binaryName override
krew: {
	apiVersion: "tomei.terassyi.net/v1beta1"
	kind:       "Tool"
	metadata: name: "krew"
	spec: {
		installerRef: "aqua"
		version:      "v0.4.4"
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
		version:      "v0.21.2"
		package:      "google/go-containerregistry"
		binaryName:   "crane"
	}
}

// pwru: eBPF packet tracer (linux only)
pwru: {
	apiVersion: "tomei.terassyi.net/v1beta1"
	kind:       "Tool"
	metadata: name: "pwru"
	spec: {
		installerRef: "aqua"
		version:      "v1.0.11"
		enabled:      _os == "linux"
		source: {
			url:         "https://github.com/cilium/pwru/releases/download/v1.0.11/pwru-linux-\(_arch).tar.gz"
			archiveType: "tar.gz"
		}
	}
}
