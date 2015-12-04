# LaTeXML-Plugin-Cortex
A CorTeX worker for LaTeXML

By default connects to the KWARC dispatcher, generating e.g. the [arXMLiv corpus](http://cortex.mathweb.org/corpus/arXMLiv/tex_to_html)

# Installation under Debian

Strategy: fetch the dependencies via the package managers, then install the bleeding versions from git.

```bash
sudo apt-get install latexml libzmq3-dev &&
cpanm git@github.com:brucemiller/LaTeXML.git &&
cpanm git@github.com:dginev/LaTeXML-Plugin-Cortex.git
```

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