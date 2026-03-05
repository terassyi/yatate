package tomei

import "tomei.terassyi.net/presets/aqua"

cliTools: aqua.#AquaToolSet & {
	metadata: name: "cli-tools"
	spec: tools: {
		rg:     {package: "BurntSushi/ripgrep", version: "15.1.0"}
		fd:     {package: "sharkdp/fd", version: "v10.3.0"}
		jq:     {package: "jqlang/jq", version: "1.8.1"}
		bat:    {package: "sharkdp/bat", version: "v0.26.1"}
		delta:  {package: "dandavison/delta", version: "0.18.2"}
		zellij: {package: "zellij-org/zellij", version: "v0.43.1"}
		just:   {package: "casey/just", version: "1.46.0"}
		yq:     {package: "mikefarah/yq", version: "v4.52.4"}
		gh:     {package: "cli/cli", version: "v2.87.3"}
		zoxide: {package: "ajeetdsouza/zoxide", version: "v0.9.9"}
		gitui:    {package: "gitui-org/gitui", version: "v0.28.0"}
		sk:       {package: "skim-rs/skim", version: "v3.6.1"}
		starship: {package: "starship/starship", version: "v1.24.2"}
		hugo:          {package: "gohugoio/hugo", version: "v0.157.0"}
		"golangci-lint": {package: "golangci/golangci-lint", version: "v2.10.1"}
		task:            {package: "go-task/task", version: "v3.48.0"}
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
			update:  ["claude update"]
			check:   ["claude --version"]
			remove:  ["rm -f ~/.local/bin/claude"]
		}
	}
}

k8sTools: aqua.#AquaToolSet & {
	metadata: name: "k8s-tools"
	spec: tools: {
		kubectl:   {package: "kubernetes/kubernetes/kubectl", version: "v1.35.2"}
		helm:      {package: "helm/helm", version: "v4.1.1"}
		kind:      {package: "kubernetes-sigs/kind", version: "v0.31.0"}
		kustomize: {package: "kubernetes-sigs/kustomize", version: "v5.8.1"}
		stern:     {package: "stern/stern", version: "v1.33.1"}
	}
}
