FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo
# Standard CI marker (GitHub Actions sets this too). On linux the tomei apply
# script always runs with `--system`; sudo is passwordless here (NOPASSWD below),
# so the apt SystemPackageSets (base/build/bpf/...) install non-interactively and
# the test exercises the real SystemPackage flow. (On darwin, CI still skips
# `--system` to avoid heavy Homebrew installs on the macOS runner.)
ENV CI=true

# jq is required by dot_config/zed/modify_settings.json.tmpl during `chezmoi
# apply`, i.e. before tomei runs — so it must be a base-image package, not a
# tomei SystemPackage. (Runtime jq also comes from the aqua cliTools set.)
# Keep /var/lib/apt/lists (do not clean): tomei's apt SystemPackage backend runs
# `apt-get install` without a preceding `apt-get update`, so the `base`/other
# SystemPackageSets need the package lists to remain present.
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential ca-certificates curl file git jq sudo unzip xz-utils

RUN useradd -m -s /bin/bash testuser \
    && echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# chezmoi
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin -t v2.70.0

USER testuser
WORKDIR /home/testuser
ENV PATH="/home/testuser/.local/bin:${PATH}"

CMD ["bash"]
