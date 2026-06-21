## Dockerfile for latexml-plugin-cortex, using the latest LaTeXML
##
## The Docker Image starts the harness on all available CPUs for the container
## accepting the address and port of the CorTeX job dispatcher
##
## build via:
##
## export HOSTNAME=$(hostname); export HOSTTIME=$(date -Iminute);
## docker build --build-arg HOSTNAME=$HOSTNAME --build-arg HOSTTIME=$HOSTTIME --tag latexml-plugin-cortex:3.0 .
##
## run example via (default dispatcher is 104.207.132.13, i.e. corpora.latexml.rs):
##
##
## Scratch (TMPDIR) is disk-backed at /opt/cortex-scratch — bind-mount a host dir on a SEPARATE
## physical disk from the OS (`-v /opt/cortex-scratch:/opt/cortex-scratch`). Do NOT stage on a
## ramdisk: /dev/shm exhaustion under a large fleet truncates inputs → empty results (CorTeX D-18).
##
## 1. threadripper 1950x
## docker run --cpus="24.0" --memory="48g" -v /opt/cortex-scratch:/opt/cortex-scratch --hostname=$(hostname) latexml-plugin-cortex:3.0 latexml_harness 104.207.132.13
##
## 2. monster config style:
## docker run --cpus="72.0" --memory="96g" -v /opt/cortex-scratch:/opt/cortex-scratch --hostname=$(hostname) latexml-plugin-cortex:3.0 latexml_harness 104.207.132.13
##
## 3. local testing on the dispatcher host (loopback, skips the Docker bridge/NAT overhead):
## docker run --network host -v /opt/cortex-scratch:/opt/cortex-scratch --hostname=$(hostname) latexml-plugin-cortex:3.0 latexml_harness 127.0.0.1

FROM ubuntu:24.04
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
  libxml2-dev \
  libxslt1-dev \
  liblocal-lib-perl \
  make \
  perl-doc \
  cpanminus

# make sure perl paths are OK
RUN eval $(perl -I$HOME/perl5/lib -Mlocal::lib)
RUN echo 'eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib)"' >> ~/.bashrc

# Collect the extended ar5iv-bindings files
ENV AR5IV_BINDINGS_COMMIT=4ea082baa008d6b759c0405a9c99753b75c5c906
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
ENV LATEXML_COMMIT=8ed66961963e54fc9c04f8c1e90eb3a4da885956
RUN cpanm --notest --verbose --build-args formats https://github.com/arXiv/LaTeXML/tarball/$LATEXML_COMMIT

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
  libcrypt-dev \
  libzmq3-dev

# Enable imagemagick policy permissions for work with arXiv PDF/EPS files
RUN perl -pi.bak -e 's/rights="none" pattern="([XE]?PS\d?|PDF)"/rights="read|write" pattern="$1"/g' /etc/ImageMagick-6/policy.xml
# Extend imagemagick resource allowance to be able to create with high-quality images
RUN perl -pi.bak -e 's/policy domain="resource" name="width" value="(\w+)"/policy domain="resource" name="width" value="256KP"/' /etc/ImageMagick-6/policy.xml
RUN perl -pi.bak -e 's/policy domain="resource" name="height" value="(\w+)"/policy domain="resource" name="height" value="256KP"/' /etc/ImageMagick-6/policy.xml
RUN perl -pi.bak -e 's/policy domain="resource" name="area" value="(\w+)"/policy domain="resource" name="area" value="4GiB"/' /etc/ImageMagick-6/policy.xml
RUN perl -pi.bak -e 's/policy domain="resource" name="disk" value="(\w+)"/policy domain="resource" name="disk" value="6GiB"/' /etc/ImageMagick-6/policy.xml
RUN perl -pi.bak -e 's/policy domain="resource" name="memory" value="(\w+)"/policy domain="resource" name="memory" value="4GiB"/' /etc/ImageMagick-6/policy.xml
RUN perl -pi.bak -e 's/policy domain="resource" name="map" value="(\w+)"/policy domain="resource" name="map" value="4GiB"/' /etc/ImageMagick-6/policy.xml

# Install LaTeXML-Plugin-Cortex, at a fixed commit, via cpanminus
ARG HOSTTIME
ENV DOCKER_BUILD_TIME=$HOSTTIME
ENV WORKING_DIR=/opt/latexml_plugin_cortex
RUN if [ -d "$WORKING_DIR" ]; then rm -Rf $WORKING_DIR; fi
RUN mkdir -p $WORKING_DIR
WORKDIR $WORKING_DIR
ENV CORTEX_WORKER_COMMIT=c621d439a8dd47b7a96d46c49a4c9426a16d23cf
RUN cpanm --verbose https://github.com/dginev/LaTeXML-Plugin-Cortex/tarball/$CORTEX_WORKER_COMMIT

# Allow a `CORTEX_WORKERS` env override of the harness fleet size — latexml_harness has no flag for
# it today (it derives `max_online − reservation`), so pin it here when a run needs a specific count,
# e.g. to match the latexml-oxide cortex-worker for a controlled comparison. Unset → unchanged default.
RUN sed -i '/1 free when 2-4 available/a $Cache->{processor_multiplier} = $ENV{CORTEX_WORKERS} if $ENV{CORTEX_WORKERS};' /usr/local/bin/latexml_harness

# Stage scratch on a disk-backed dir on a SEPARATE physical disk from the OS, NOT the RAM disk:
# under a large fleet the shared /dev/shm fills and the worker truncates inputs → empty 0-byte
# results (CorTeX KNOWN_ISSUES D-18). The pinned worker hardcodes TMPDIR=/dev/shm, so patch the
# installed copy (mirrors the CORTEX_WORKERS override above); bind-mount the host dir at run time
# with `-v /opt/cortex-scratch:/opt/cortex-scratch`.
RUN mkdir -p /opt/cortex-scratch \
 && sed -i 's|/dev/shm|/opt/cortex-scratch|g' /usr/local/bin/latexml_worker
ENV TMPDIR=/opt/cortex-scratch
ENV MAGICK_TMPDIR=/opt/cortex-scratch

RUN echo "Build started at $DOCKER_BUILD_TIME, ended at $(date -Iminute)"
