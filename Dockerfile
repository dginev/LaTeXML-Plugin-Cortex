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

# Collect the extended ar5iv-bindings files
ENV AR5IV_BINDINGS_COMMIT=5ec2cf22a3c69bc865448f5b8a98dc8c36f099e4
ENV AR5IV_BINDINGS_BASE=/opt/ar5iv-bindings
ENV AR5IV_BINDINGS_PATH=$AR5IV_BINDINGS_BASE/bindings
ENV AR5IV_SUPPORTED_ORIGINALS_PATH=$AR5IV_BINDINGS_BASE/supported_originals
RUN rm -rf $AR5IV_BINDINGS_BASE ; mkdir -p $AR5IV_BINDINGS_BASE
RUN git clone https://github.com/dginev/ar5iv-bindings $AR5IV_BINDINGS_BASE
WORKDIR $AR5IV_BINDINGS_BASE
RUN git reset --hard $AR5IV_BINDINGS_COMMIT

# Install LaTeXML, at a fixed commit, via cpanminus
RUN export HARNESS_OPTIONS=j$(grep -c ^processor /proc/cpuinfo):c
RUN mkdir -p /opt/latexml
WORKDIR /opt/latexml
ENV LATEXML_COMMIT=169d04c9743c5deac5309bef496029f172dd0afe
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
ENV CORTEX_WORKER_COMMIT=5a4da8ce0e66459b9d4de6731c431bafb33c38c6
RUN cpanm --verbose https://github.com/dginev/LaTeXML-Plugin-Cortex/tarball/$CORTEX_WORKER_COMMIT

RUN echo "Build started at $DOCKER_BUILD_TIME, ended at $(date -Iminute)"