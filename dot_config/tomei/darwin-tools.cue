package tomei

import "tomei.terassyi.net/presets/aqua"

darwinDockerTools: aqua.#AquaToolSet & {
	metadata: name: "darwin-docker-tools"
	spec: tools: {
		docker: {package: "docker/cli/docker", version: "v29.2.1"}
	}
}

darwinGcloud: {
	apiVersion: "tomei.terassyi.net/v1beta1"
	kind:       "Tool"
	metadata: name: "gcloud"
	spec: {
		version: "559.0.0"
		commands: {
			install: [
				"bash", "-c",
				"""
				set -e
				GCLOUD_PREFIX="${HOME}/.local/share/tomei/tools/gcloud/\(spec.version)"
				TMPDIR="$(mktemp -d)"
				ARCH="$(uname -m)"
				case "${ARCH}" in
				  x86_64) ARCH="x86_64" ;;
				  arm64|aarch64) ARCH="arm" ;;
				esac
				curl -fsSL -o "${TMPDIR}/google-cloud-cli.tar.gz" "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-\(spec.version)-darwin-${ARCH}.tar.gz"
				mkdir -p "${GCLOUD_PREFIX}"
				tar zxf "${TMPDIR}/google-cloud-cli.tar.gz" -C "${GCLOUD_PREFIX}" --strip-components=1
				rm -rf "${TMPDIR}"
				""",
			]
			check: ["bash", "-c", "$HOME/.local/share/tomei/tools/gcloud/\(spec.version)/bin/gcloud version"]
			remove: ["rm", "-rf", "$HOME/.local/share/tomei/tools/gcloud/\(spec.version)"]
		}
	}
}
