FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV UV_PYTHON_INSTALL_DIR=/opt/uv-python

# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
      bash \
      bash-completion \
      bcftools \
      bedtools \
      ca-certificates \
      curl \
      file \
      git \
      gnupg \
      htop \
      jq \
      less \
      man-db \
      manpages \
      nano \
      perl \
      samtools \
      sudo \
      tmux \
      tree \
      util-linux \
      vim-tiny \
      wget \
  && rm -rf /var/lib/apt/lists/* /etc/motd /etc/update-motd.d/* \
  && (userdel -r ubuntu 2>/dev/null || true) \
  && useradd -m -u 1000 -s /bin/bash student \
  && rm -rf /home/student \
  && echo 'student ALL=(root) NOPASSWD: /usr/bin/apt-get *' > /etc/sudoers.d/student-apt \
  && chmod 0440 /etc/sudoers.d/student-apt

# uv (Astral) + seqkit binaries. Combined into one RUN to keep layers minimal.
RUN set -eux; \
    arch=$(uname -m); \
    case "$arch" in \
      x86_64) uv_arch=x86_64; seqkit_arch=amd64 ;; \
      aarch64) uv_arch=aarch64; seqkit_arch=arm64 ;; \
      *) echo "unsupported arch: $arch"; exit 1 ;; \
    esac; \
    curl -LsSf "https://github.com/astral-sh/uv/releases/latest/download/uv-${uv_arch}-unknown-linux-gnu.tar.gz" -o /tmp/uv.tgz; \
    tar xzf /tmp/uv.tgz -C /tmp; \
    mv "/tmp/uv-${uv_arch}-unknown-linux-gnu/uv"  /usr/local/bin/; \
    mv "/tmp/uv-${uv_arch}-unknown-linux-gnu/uvx" /usr/local/bin/; \
    rm -rf "/tmp/uv.tgz" "/tmp/uv-${uv_arch}-unknown-linux-gnu"; \
    uv python install 3.13; \
    chmod -R a+rX "${UV_PYTHON_INSTALL_DIR}"; \
    ln -s "$(uv python find 3.13)" /usr/local/bin/python3; \
    ln -s /usr/local/bin/python3 /usr/local/bin/python; \
    curl -LsSf "https://github.com/shenwei356/seqkit/releases/latest/download/seqkit_linux_${seqkit_arch}.tar.gz" -o /tmp/seqkit.tgz; \
    tar xzf /tmp/seqkit.tgz -C /tmp; \
    mv /tmp/seqkit /usr/local/bin/; \
    rm /tmp/seqkit.tgz

COPY skel/ /etc/skel/
COPY entrypoint.sh /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint && chmod -R a+rX /etc/skel

USER student
WORKDIR /home/student
ENV TERM=xterm-256color HOME=/home/student USER=student LOGNAME=student SHELL=/bin/bash

ENTRYPOINT ["/usr/local/bin/entrypoint"]
