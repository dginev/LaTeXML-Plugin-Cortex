## Dockerfile for latexml-plugin-cortex, using the latest LaTeXML
##
## The Docker Image starts the harness on all available CPUs for the container
## accepting the address and port of the CorTeX job dispatcher
##
## build via:
##
## export HOSTNAME=$(hostname); export HOSTTIME=$(date -Iminute);
## docker build --build-arg HOSTNAME=$HOSTNAME --build-arg HOSTTIME=$HOSTTIME --tag latexml-plugin-cortex:2.1 .
##
## run example via:
##
##
## 1. threadripper 1950x
## docker run --cpus="24.0" --memory="48g" --shm-size="32g" --hostname=$(hostname) latexml-plugin-cortex:2.1 latexml_harness 131.188.48.209
##
## 2. monster config style:
## docker run --cpus="72.0" --memory="96g" --shm-size="64g" --hostname=$(hostname) latexml-plugin-cortex:2.1 latexml_harness 131.188.48.209

FROM ubuntu:22.04
ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
ARG HOSTNAME
ENV DOCKER_HOST=$HOSTNAME

# LaTeX stuff first, because it's enormous and doesn't change much
RUN set -ex && apt-get update -qq && apt-get install -qy \
  texlive \
  texlive-fonts-extra \
  texlive-lang-all \
  texlive-latex-extra \
  texlive-bibtex-extra \
  texlive-science \
  texlive-pictures \
  texlive-pstricks \
  texlive-publishers

# latexml dependencies
RUN set -ex && apt-get update -qq && apt-get install -qy \
  build-essential \
  git \
  imagemagick \
  libarchive-zip-perl \
  libdb-dev \
  libfile-which-perl \
  libimage-magick-perl \
  libimage-size-perl \
  libio-string-perl \
  libjson-xs-perl \
  libparse-recdescent-perl \
  libtext-unidecode-perl \
  liburi-perl \
  libuuid-tiny-perl \
  libwww-perl \
  libxml-libxml-perl \
  libxml-libxslt-perl \
  libxml2 libxml2-dev \
  libxslt1-dev \
  libxslt1.1 \
  liblocal-lib-perl \
  make \
  perl-doc \
  cpanminus

# make sure perl paths are OK
RUN eval $(perl -I$HOME/perl5/lib -Mlocal::lib)
RUN echo 'eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib)"' >> ~/.bashrc

# Collect the extended arxmliv-bindings files
ENV ARXMLIV_BINDINGS_COMMIT=5df05d473b925009216da5ac2fc6727b7d59fbc1
ENV ARXMLIV_BINDINGS_BASE=/opt/arxmliv-bindings
ENV ARXMLIV_BINDINGS_PATH=$ARXMLIV_BINDINGS_BASE/bindings
ENV ARXMLIV_SUPPORTED_ORIGINALS_PATH=$ARXMLIV_BINDINGS_BASE/supported_originals
RUN rm -rf $ARXMLIV_BINDINGS_BASE ; mkdir -p $ARXMLIV_BINDINGS_BASE
RUN git clone https://github.com/dginev/arxmliv-bindings $ARXMLIV_BINDINGS_BASE
WORKDIR $ARXMLIV_BINDINGS_BASE
RUN git reset --hard $ARXMLIV_BINDINGS_COMMIT

# Install LaTeXML, at a fixed commit, via cpanminus
RUN export HARNESS_OPTIONS=j$(grep -c ^processor /proc/cpuinfo):c
RUN mkdir -p /opt/latexml
WORKDIR /opt/latexml
ENV LATEXML_COMMIT=e52efffcdf13218e7772b822c67e1ba0d8bb3fb5
RUN cpanm --notest --verbose https://github.com/brucemiller/LaTeXML/tarball/$LATEXML_COMMIT

# cortex worker dependencies
RUN set -ex && apt-get update -qq && apt-get install -qy \
  libarchive-zip-perl \
  libcapture-tiny-perl \
  libdevel-checklib-perl \
  libio-all-perl \
  libproc-processtable-perl \
  libtask-weaken-perl \
  libtest-fatal-perl \
  libtest-requires-perl \
  libtest-sharedfork-perl \
  libtest-tcp-perl \
  libtest-weaken-perl \
  libunix-processors-perl \
  libzmq3-dev

# Enable imagemagick policy permissions for work with arXiv PDF/EPS files
RUN perl -pi.bak -e 's/rights="none" pattern="([XE]?PS\d?|PDF)"/rights="read|write" pattern="$1"/g' /etc/ImageMagick-6/policy.xml
# Extend imagemagick resource allowance to be able to create with high-quality images
RUN perl -pi.bak -e 's/policy domain="resource" name="width" value="(\w+)"/policy domain="resource" name="width" value="126KP"/' /etc/ImageMagick-6/policy.xml
RUN perl -pi.bak -e 's/policy domain="resource" name="height" value="(\w+)"/policy domain="resource" name="height" value="126KP"/' /etc/ImageMagick-6/policy.xml
RUN perl -pi.bak -e 's/policy domain="resource" name="area" value="(\w+)"/policy domain="resource" name="area" value="2GiB"/' /etc/ImageMagick-6/policy.xml
RUN perl -pi.bak -e 's/policy domain="resource" name="disk" value="(\w+)"/policy domain="resource" name="disk" value="8GiB"/' /etc/ImageMagick-6/policy.xml
RUN perl -pi.bak -e 's/policy domain="resource" name="memory" value="(\w+)"/policy domain="resource" name="memory" value="2GiB"/' /etc/ImageMagick-6/policy.xml
RUN perl -pi.bak -e 's/policy domain="resource" name="map" value="(\w+)"/policy domain="resource" name="map" value="2GiB"/' /etc/ImageMagick-6/policy.xml

# Install LaTeXML-Plugin-Cortex, at a fixed commit, via cpanminus
ARG HOSTTIME
ENV DOCKER_BUILD_TIME=$HOSTTIME
ENV WORKING_DIR=/opt/latexml_plugin_cortex
RUN if [ -d "$WORKING_DIR" ]; then rm -Rf $WORKING_DIR; fi
RUN mkdir -p $WORKING_DIR
WORKDIR $WORKING_DIR
ENV CORTEX_WORKER_COMMIT=54d1fca48620fe8e820bdc06daf01d5967b1aa75
RUN cpanm --verbose https://github.com/dginev/LaTeXML-Plugin-Cortex/tarball/$CORTEX_WORKER_COMMIT

RUN echo "Build started at $DOCKER_BUILD_TIME, ended at $(date -Iminute)"