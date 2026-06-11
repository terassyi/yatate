@if(darwin && arm64)

package tomei

import "tomei.terassyi.net/presets/brew"

homebrew: brew.#Homebrew

// Override brew.#BrewInstaller to use the absolute brew path. tomei does not
// add the installer's binDir to the exec PATH, so a bare "brew" fails with exit
// 127 (confirmed on tomei v0.2.0). #Homebrew itself stays the privileged preset
// since v0.2.0 runs privileged tools as the user (no root rejection).
// TODO: fold the absolute path into the brew preset (terassyi/tomei#269).
brewInstaller: {
	apiVersion: "tomei.terassyi.net/v1beta1"
	kind:       "Installer"
	metadata: {
		name:        "brew"
		description: "Install packages via Homebrew"
	}
	spec: {
		type:    "delegation"
		toolRef: "homebrew"
		commands: {
			install: ["/opt/homebrew/bin/brew install {{.Package}}"]
			remove: ["/opt/homebrew/bin/brew uninstall {{.Package}}"]
			check: ["/opt/homebrew/bin/brew list --formula {{.Package}} >/dev/null 2>&1"]
		}
		binDir: "/opt/homebrew/bin"
	}
}

brewTools: brew.#FormulaSet & {
	metadata: name: "brew-formulae"
	spec: tools: {
		fish: {package: "fish"}
		neovim: {package: "neovim"}
		"google-cloud-sdk": {package: "google-cloud-sdk"}
		ffmpeg: {package: "ffmpeg"}
	}
}
