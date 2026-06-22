FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
      bash \
      bash-completion \
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
      tmux \
      tree \
      util-linux \
      vim-tiny \
      wget \
  && rm -rf /var/lib/apt/lists/* /etc/motd /etc/update-motd.d/* \
  && (userdel -r ubuntu 2>/dev/null || true) \
  && useradd -m -u 1000 -s /bin/bash student \
  && rm -rf /home/student

COPY skel/ /etc/skel/
COPY entrypoint.sh /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint && chmod -R a+rX /etc/skel

USER student
WORKDIR /home/student
ENV TERM=xterm-256color HOME=/home/student USER=student LOGNAME=student SHELL=/bin/bash

ENTRYPOINT ["/usr/local/bin/entrypoint"]
