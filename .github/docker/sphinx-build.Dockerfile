FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1

# Base tooling + full document build dependencies used by this repo.
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    make \
    python3 \
    python3-pip \
    python3-venv \
    openjdk-17-jre-headless \
    texlive-latex-base \
    texlive-latex-recommended \
    texlive-latex-extra \
    texlive-fonts-recommended \
    librsvg2-bin \
    latexmk \
    inkscape \
    pdftk \
    xsltproc \
    cm-super \
    pdf2svg \
    pandoc \
    plantuml \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Pre-install Python deps used by Sphinx build.
COPY requirements.txt /tmp/requirements.txt
RUN python3 -m pip install --upgrade pip \
    && python3 -m pip install -r /tmp/requirements.txt \
    && rm -f /tmp/requirements.txt

CMD ["bash"]
