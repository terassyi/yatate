@if(darwin)

package tomei

import "tomei.terassyi.net/presets/brew"

homebrew: brew.#Homebrew

brewInstaller: brew.#BrewInstaller

brewTools: brew.#FormulaSet & {
	metadata: name: "brew-formulae"
	spec: tools: {
		fish: {package: "fish"}
		neovim: {package: "neovim"}
		"google-cloud-sdk": {package: "google-cloud-sdk"}
	}
}
