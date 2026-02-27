package tomei

import "tomei.terassyi.net/presets/aqua"

darwinTools: aqua.#AquaToolSet & {
	metadata: name: "darwin-tools"
	spec: tools: {
		gcloud: {package: "twistedpair/google-cloud-sdk", version: "558.0.0"}
		docker: {package: "docker/cli", version: "v29.2.1"}
	}
}
