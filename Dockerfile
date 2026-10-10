FROM ubuntu:26.04@sha256:f144425ff09be612d6d9ad965196e9cdc23dae1f42110a8a11a3e9a8198759f7 AS build-base

ARG TARGETARCH
ARG HUGO_VERSION=0.167.0
ARG HUGO_SHA256_AMD64=2d012c4490248195e2db07e89ce7f76af8bead93233e930bdf3733c53acd3b23
ARG HUGO_SHA256_ARM64=df8ef5dbd365822d12e4de3e682d6c37ab3b09cc09e344058d3fd182c4190e16
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
  && apt-get install --yes --no-install-recommends ca-certificates curl emacs-nox git \
    && curl --fail --location --silent --show-error \
      "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-${TARGETARCH}.deb" \
      --output /tmp/hugo.deb \
    && case "${TARGETARCH}" in \
      amd64) expected_sha256="${HUGO_SHA256_AMD64}" ;; \
      arm64) expected_sha256="${HUGO_SHA256_ARM64}" ;; \
      *) echo "Unsupported target architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && printf '%s  %s\n' "${expected_sha256}" /tmp/hugo.deb | sha256sum --check --strict \
    && apt-get install --yes /tmp/hugo.deb \
    && rm -f /tmp/hugo.deb \
    && rm -rf /var/lib/apt/lists/*

RUN git init /opt/ox-hugo \
    && git -C /opt/ox-hugo remote add origin https://github.com/kaushalmodi/ox-hugo.git \
    && git -C /opt/ox-hugo fetch --depth 1 origin b7dc44dc28911b9d8e3055a18deac16c3b560b03 \
    && git -C /opt/ox-hugo checkout --detach FETCH_HEAD

RUN git init /opt/tomelr \
  && git -C /opt/tomelr remote add origin https://github.com/kaushalmodi/tomelr.git \
  && git -C /opt/tomelr fetch --depth 1 origin 670e0a08f625175fd80137cf69e799619bf8a381 \
  && git -C /opt/tomelr checkout --detach FETCH_HEAD

RUN groupadd --system site \
    && useradd --system --gid site --create-home site \
    && install --directory --owner=site --group=site /site

USER site:site
ENV HOME=/home/site OX_HUGO_LOAD_PATH=/opt/ox-hugo:/opt/tomelr HUGO_CACHEDIR=/tmp/hugo_cache
WORKDIR /site
COPY --chown=site:site . .
RUN emacs --batch --load scripts/export-org.el

FROM build-base AS site-build
RUN hugo --minify

FROM build-base AS preview
EXPOSE 1313
CMD ["sh", "-c", "emacs --batch --load scripts/export-org.el && hugo server --bind 0.0.0.0 --noBuildLock --renderToMemory --cacheDir /tmp/hugo_cache"]