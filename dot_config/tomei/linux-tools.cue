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
