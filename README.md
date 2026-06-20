# LaTeXML-Plugin-Cortex
A CorTeX worker for LaTeXML

By default connects to the [corpora.latexml.rs](https://corpora.latexml.rs/) dispatcher (`104.207.132.13`), generating e.g. the arXMLiv corpus.

Intended for use with the latest `master` branch of LaTeXML.

# Run with Docker (recommended)

The simplest way to contribute compute is via the bundled `Dockerfile`. It pins compatible LaTeXML and ar5iv-bindings commits, installs every prerequisite, and starts the harness on all available CPUs — no host Perl setup required.

## Build

```bash
export HOSTNAME=$(hostname); export HOSTTIME=$(date -Iminute);
docker build --build-arg HOSTNAME=$HOSTNAME --build-arg HOSTTIME=$HOSTTIME --tag latexml-plugin-cortex:3.0 .
```

## Run

The harness takes the dispatcher address as its first argument, defaulting to `104.207.132.13` (`corpora.latexml.rs`). Size `--cpus`, `--memory` and `--shm-size` to the host:

```bash
# threadripper 1950x style
docker run --cpus="24.0" --memory="48g" --shm-size="32g" --hostname=$(hostname) \
  latexml-plugin-cortex:3.0 latexml_harness 104.207.132.13

# larger machine
docker run --cpus="72.0" --memory="96g" --shm-size="64g" --hostname=$(hostname) \
  latexml-plugin-cortex:3.0 latexml_harness 104.207.132.13
```

## Local testing (worker on the dispatcher host)

When the worker and the dispatcher run on the same machine, use host networking and the loopback interface to skip the Docker bridge and the public-network round-trip entirely:

```bash
docker run --network host --shm-size="32g" --hostname=$(hostname) \
  latexml-plugin-cortex:3.0 latexml_harness 127.0.0.1
```

With `--network host` the container shares the host's network stack, so `127.0.0.1` reaches a dispatcher bound on the host's loopback with no NAT overhead — the minimal-latency setup for local testing.

# Manual installation under Debian

As an alternative to Docker, fetch the dependencies via the package managers, then install the bleeding versions from git.

```bash
sudo apt-get install cpanminus libzmq3-dev libcrypt-dev &&
sudo apt-get build-dep latexml &&
cpanm git@github.com:brucemiller/LaTeXML.git &&
cpanm git@github.com:dginev/LaTeXML-Plugin-Cortex.git
```

**Note:** `libcrypt-dev` is required on recent distributions (e.g. Ubuntu 24.04+, where `crypt` was split out of glibc into libxcrypt). Without it, `cpanm` builds of XS modules fail because Perl links every XS module with `-lcrypt`. The most confusing symptom is `ZMQ::LibZMQ3` aborting with `Can't link/include C library 'zmq.h', 'zmq'` — this is misleading, as `libzmq` is fine; the real error a line above is `cannot find -lcrypt`. The same missing package also breaks `Unix::Processors` with `fatal error: crypt.h: No such file or directory`. If `libcrypt-dev` is unavailable, try `libxcrypt-dev` instead.

## Update workflow for worker machines
Adding a helper library to manage the local cpanm installs via `cpanm local::lib`, it becomes possible to use this `~/.bashrc` eval+aliases for a simple update+deploy of the harness:

```
eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib)"

alias latexmlup="killall -9 perl; killall -9 latexml_worker;\
                 cd $HOME/LaTeXML; git pull --rebase; cpanm --uninstall -f LaTeXML; cpanm .;\
                 cd $HOME/LaTeXML-Plugin-Cortex; git pull --rebase; cpanm .;\
                 nohup latexml_harness 104.207.132.13 2>&1 > cortex.log &"
                 
alias latexmlupraw="killall -9 perl; killall -9 latexml_worker;\
                 cd $HOME/LaTeXML; git pull --rebase; cpanm --uninstall -f LaTeXML; cpanm .;\
                 cd $HOME/LaTeXML-Plugin-Cortex; git pull --rebase; cpanm .;\
                 nohup latexml_harness 104.207.132.13 51695 51696 raw_tex_to_html 2>&1 > cortex.log &"

```

# Runtime Reliability

It is recommended to setup all client machines that are accessing the main server via the open internet to have at least two separate DNS servers setup, as well as to have **only an IPv4 interface** enabled, with IPv6 explicitly enabled. It is a current limitation of the central CorTeX server that no robust IPv6 interface is exposed.

# Contribute to the arXMLiv build system

All you need to do to contribute is do the installation and then run:
```bash
latexml_harness
```

That's it! Feel free to start it as a background job on worker machines, e.g. via:
```bash
nohup latexml_harness 2>&1 > cortex.log &
```

Thanks for contributing!
