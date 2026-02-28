FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    dvisvgm \
    fontconfig \
    fonts-firacode \
    fonts-stix \
    inotify-tools \
    texlive-fonts-extra \
    texlive-fonts-recommended \
    texlive-lang-french \
    texlive-latex-extra \
    texlive-luatex \
    texlive-plain-generic \
    texlive-science \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

CMD ["bash"]
