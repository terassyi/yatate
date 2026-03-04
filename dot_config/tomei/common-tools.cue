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
		hugo:     {package: "gohugoio/hugo", version: "v0.157.0"}
	}
}
