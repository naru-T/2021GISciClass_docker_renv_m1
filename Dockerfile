ARG DEBIAN_FRONTEND=noninteractive

FROM edgyr/internal-ubuntu-builder:latest AS builder

FROM ubuntu:bionic

COPY --from=builder /usr/local/lib/rstudio-server /usr/local/lib/rstudio-server
COPY --from=builder /usr/local/bin/pandoc /usr/local/bin/pandoc
COPY --from=builder /usr/local/lib/R /usr/local/lib/R
COPY --from=builder /usr/local/bin/R* /usr/local/bin/
COPY --from=builder /usr/local/lib/libRmath.so /usr/local/lib/libRmath.so
COPY --from=builder /usr/local/lib/libRmath.a /usr/local/lib/libRmath.a
COPY --from=builder /usr/local/include /usr/local/include

ENV S6_VERSION=${S6_VERSION:-v1.21.7.0}
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2
ENV PATH=/usr/local/lib/rstudio-server/bin:$PATH

ENV DEBIAN_FRONTEND=noninteractive

COPY userconf.sh /etc/cont-init.d/userconf
COPY disable_auth_rserver.conf /etc/rstudio/disable_auth_rserver.conf
COPY pam-helper.sh /usr/local/lib/rstudio-server/bin/pam-helper

RUN apt-get update \
  && apt-get install -qqy --no-install-recommends \
    binutils \ 
    cmake \
    curl \
    default-jdk \
    file \
    fonts-roboto \
    fonts-texgyre \
    g++ \
    gdal-bin \
    gfortran \
    ghostscript \
    git \
    grass \
    gsfonts \
    hugo \
    lbzip2 \
    less \
    libapparmor1 \
    libbz2-*\
    libbz2-dev \
    libclang-dev \
    libcurl4 \
    libcurl4-openssl-dev \
    libedit2 \
    libfftw3-dev \
    libfribidi-dev \
    libgc1c2 \
    libgdal-dev \
    libgeos-dev \
    libgl1-mesa-dev \
    libglpk-dev \
    libglu1-mesa-dev \
    libgmp3-dev \
    libgsl0-dev \
    libharfbuzz-dev \
    libhdf4-alt-dev \
    libhdf5-dev \
    libhunspell-dev \
    libicu-dev \
    libjq-dev \
    liblzma-dev \
    libmagick++-dev \
    libnetcdf-dev \
    libobjc4 \
    libopenmpi-dev \
    libpangocairo-* \
    libpcre2-dev \
    libpng16* \
    libpq-dev \
    libpq5 \
    libproj-dev \
    libprotobuf-dev \
    libreadline-dev \
    libreadline7 \
    libsqlite3-dev \
    libssl-dev \
    libssl-dev \
    libudunits2-dev \
    libxml2-dev \
    libxslt1-dev \
    libzmq3-dev \
    lsb-release \
    netcdf-bin \
    postgis \
    procps \
    protobuf-compiler \
    psmisc \
    python-setuptools \
    qgis \ 
    qgis-plugin-grass \
    qpdf \
    saga \
    software-properties-common \
    sqlite3 \
    sudo \
    texinfo \
    texlive-fonts-extra \
    texlive-fonts-recommended \
    tk-dev \
    unixodbc-dev \
    wget


RUN mkdir -p /etc/R \
     && mkdir -p /etc/rstudio \
     && mkdir -p /usr/local/lib/R/etc \
     && echo '\n\
       \n# Configure httr to perform out-of-band authentication if HTTR_LOCALHOST \
       \n# is not set since a redirect to localhost may not work depending upon \
       \n# where this Docker container is running. \
       \nif(is.na(Sys.getenv("HTTR_LOCALHOST", unset=NA))) { \
       \n  options(httr_oob_default = TRUE) \
       \n}' >> /usr/local/lib/R/etc/Rprofile.site \
     && echo "PATH=${PATH}" >> /usr/local/lib/R/etc/Renviron \
     && useradd rstudio \
     && echo "rstudio:rstudio" | chpasswd \
   	 && mkdir /home/rstudio \
   	 && chown rstudio:rstudio /home/rstudio \
   	 && addgroup rstudio staff \
     &&  echo 'rsession-which-r=/usr/local/bin/R' >> /etc/rstudio/rserver.conf \
     && echo 'lock-type=advisory' >> /etc/rstudio/file-locks \
     && cd .. \
     && rm -rf src \
     && echo "options(repos = c(CRAN='https://cran.rstudio.com'), download.file.method = 'libcurl')" \
       >> /usr/local/lib/R/etc/Rprofile.site \
     && mkdir -p /home/rstudio/.rstudio/monitored/user-settings \
     && echo 'alwaysSaveHistory="0" \
             \nloadRData="0" \
             \nsaveAction="0"' \
             > /home/rstudio/.rstudio/monitored/user-settings/user-settings \
     && chown -R rstudio:rstudio /home/rstudio/.rstudio \
     && mkdir -p /var/run/rstudio-server \
     && mkdir -p /var/lock/rstudio-server \
     && mkdir -p /var/log/rstudio-server \
     && mkdir -p /var/lib/rstudio-server 

RUN git config --system credential.helper 'cache --timeout=3600' \
     && git config --system push.default simple \
     && wget -P /tmp/ https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/s6-overlay-aarch64.tar.gz \
     && tar xzf /tmp/s6-overlay-aarch64.tar.gz -C / \
     && mkdir -p /etc/services.d/rstudio \
     && echo '#!/usr/bin/with-contenv bash \
     		  \n for line in $( cat /etc/environment ) ; do export $line ; done \
             \n exec /usr/local/lib/rstudio-server/bin/rserver --server-daemonize 0' \
             > /etc/services.d/rstudio/run \
     && echo '#!/bin/bash \
             \n /usr/local/lib/rstudio-server/bin/rstudio-server stop' \
             > /etc/services.d/rstudio/finish \
     && cp /usr/local/lib/rstudio-server/extras/init.d/debian/rstudio-server /etc/init.d/ \
     && update-rc.d rstudio-server defaults \
     && ln -f -s /usr/local/lib/rstudio-server/bin/rstudio-server /usr/sbin/rstudio-server \
     && useradd -r rstudio-server

COPY --from=builder /usr/local/src/packages packages
RUN apt-get install -qqy --no-install-recommends libc-ares2 \
  && dpkg -i ./packages/libnghttp2-14_1.36.0-bionic0_arm64.deb \
  && dpkg -i ./packages/libuv1_1.24.1-bionic0_arm64.deb \
  && dpkg -i ./packages/libnode64_10.15.2~dfsg-bionic0_arm64.deb \
  && dpkg -i ./packages/libuv1-dev_1.24.1-bionic0_arm64.deb \
  && dpkg -i ./packages/libnode-dev_10.15.2~dfsg-bionic0_arm64.deb \
  && rm -rf ./packages

RUN echo 'rstudio ALL=(ALL:ALL) ALL' >> /etc/sudoers

RUN wget https://github.com/conda-forge/miniforge/releases/download/4.9.2-5/Mambaforge-Linux-aarch64.sh \
  && sh ./Mambaforge-Linux-aarch64.sh -b -p /usr/local/mambaforge \
  && rm ./Mambaforge-Linux-aarch64.sh

ENV PATH=/usr/local/mambaforge/bin/:$PATH

RUN R CMD javareconf \
  && Rscript -e "install.packages(c('remotes','renv','rmarkdown', 'shiny', 'rJava', 'reticulate', 'PKI','bookdown','rticles','rmdshower','tinytex'))"


RUN Rscript -e "remotes::install_github('paleolimbot/qgisprocess')"

COPY renv.lock renv.lock
RUN R -e 'renv::consent(provided = TRUE); renv::restore()'



#https://hub.docker.com/r/rocker/verse/dockerfile
# Version-stable CTAN repo from the tlnet archive at texlive.info, used in the
# TinyTeX installation: chosen as the frozen snapshot of the TeXLive release
# shipped for the base Debian image of a given rocker/r-ver tag.
# Debian buster => TeXLive 2018, frozen release snapshot 2019/02/27
ARG CTAN_REPO=${CTAN_REPO:-https://www.texlive.info/tlnet-archive/2019/02/27/tlnet}
ENV CTAN_REPO=${CTAN_REPO}

ENV PATH=$PATH:/opt/TinyTeX/bin/x86_64-linux/

## Add LaTeX, rticles and bookdown support
RUN wget "https://travis-bin.yihui.name/texlive-local.deb" \
  && dpkg -i texlive-local.deb \
  && rm texlive-local.deb \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    curl \
    default-jdk \
    fonts-roboto \
    ghostscript \
    less \
    libbz2-dev \
    libicu-dev \
    liblzma-dev \
    libhunspell-dev \
    libjpeg-dev \
    libmagick++-dev \
    libopenmpi-dev \
    librdf0-dev \
    libtiff-dev \
    libv8-dev \
    libzmq3-dev \
    qpdf \
    ssh \
    texinfo \
    vim \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/ \
  ## Admin-based install of TinyTeX:
  && wget -qO- \
    "https://github.com/yihui/tinytex/raw/master/tools/install-unx.sh" | \
    sh -s - --admin --no-path \
  && mv ~/.TinyTeX /opt/TinyTeX \
  && if /opt/TinyTeX/bin/*/tex -v | grep -q 'TeX Live 2018'; then \
      ## Patch the Perl modules in the frozen TeX Live 2018 snapshot with the newer
      ## version available for the installer in tlnet/tlpkg/TeXLive, to include the
      ## fix described in https://github.com/yihui/tinytex/issues/77#issuecomment-466584510
      ## as discussed in https://www.preining.info/blog/2019/09/tex-services-at-texlive-info/#comments
      wget -P /tmp/ ${CTAN_REPO}/install-tl-unx.tar.gz \
      && tar -xzf /tmp/install-tl-unx.tar.gz -C /tmp/ \
      && cp -Tr /tmp/install-tl-*/tlpkg/TeXLive /opt/TinyTeX/tlpkg/TeXLive \
      && rm -r /tmp/install-tl-*; \
    fi \
  && /opt/TinyTeX/bin/*/tlmgr path add \
  && tlmgr install ae inconsolata listings metafont mfware parskip pdfcrop tex \
  && tlmgr path add \
  && Rscript -e "tinytex::r_texmf()" \
  && chown -R root:staff /opt/TinyTeX \
  && chmod -R g+w /opt/TinyTeX \
  && chmod -R g+wx /opt/TinyTeX/bin \
  && echo "PATH=${PATH}" >> /usr/local/lib/R/etc/Renviron 
   
#

RUN tlmgr update --self


EXPOSE 8787
CMD ["/init"]



