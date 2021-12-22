## Dockerfile for latexml-plugin-cortex, using the latest LaTeXML
##
## The Docker Image starts the harness on all available CPUs for the container
## accepting the address and port of the CorTeX job dispatcher
##
## build via:
##
## docker build --tag latexml-plugin-cortex:1.5 .
##
## run example via:
##
##
## 1. threadripper 1950x
## docker run --cpus="24.0" --memory="48g" --shm-size="32g" --hostname=$(hostname) latexml-plugin-cortex:1.2 latexml_harness 131.188.48.209
##
## 2. monster config style:
## docker run --cpus="72.0" --memory="96g" --shm-size="64g" --hostname=$(hostname) latexml-plugin-cortex:1.2 latexml_harness 131.188.48.209

FROM ubuntu:21.10
ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# LaTeX stuff first, because it's enormous and doesn't change much
RUN set -ex && apt-get update -qq && apt-get install -qy \
  texlive \
  texlive-fonts-extra \
  texlive-lang-all \
  texlive-latex-extra \
  texlive-science

# latexml dependencies
RUN set -ex && apt-get update -qq && apt-get install -qy \
  build-essential \
  cpanminus \
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
  make \
  perl-doc

# Install LaTeXML's master branch via cpanminus
RUN export HARNESS_OPTIONS=j$(grep -c ^processor /proc/cpuinfo):c
RUN mkdir -p /opt/latexml
WORKDIR /opt/latexml
ENV LATEXML_COMMIT=5d792128cb5b756a69dd3d18f42941a9ec1123bb
RUN cpanm --notest --verbose --skip-installed https://github.com/brucemiller/LaTeXML/tarball/$LATEXML_COMMIT

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

# Install LaTeXML-Plugin-Cortex's master branch via cpanminus
RUN mkdir -p /opt/latexml_plugin_cortex
WORKDIR /opt/latexml_plugin_cortex
ENV CORTEX_WORKER_COMMIT=09748987dc87f02ac09cf408267c108146ac7dc5
RUN cpanm --verbose --skip-installed https://github.com/dginev/LaTeXML-Plugin-Cortex/tarball/$CORTEX_WORKER_COMMIT
