FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl file git sudo unzip xz-utils \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash testuser \
    && echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# chezmoi
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin

USER testuser
WORKDIR /home/testuser
ENV PATH="/home/testuser/.local/bin:${PATH}"

CMD ["bash"]
