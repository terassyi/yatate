@if(darwin && arm64)

package tomei

import "tomei.terassyi.net/presets/brew"

homebrew: brew.#Homebrew

// tomei v0.2.1 prepends a delegation installer's own binDir to the command PATH
// (terassyi/tomei#269), so the preset's bare "brew" now resolves via binDir
// (/opt/homebrew/bin). No absolute-path override needed anymore.
brewInstaller: brew.#BrewInstaller

brewTools: brew.#FormulaSet & {
	metadata: name: "brew-formulae"
	spec: tools: {
		fish: {package: "fish"}
		neovim: {package: "neovim"}
		"google-cloud-sdk": {package: "google-cloud-sdk"}
		ffmpeg: {package: "ffmpeg"}
	}
}
