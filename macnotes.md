Mac Notes

if you want a minimal tex environment on a mac, you can install basictex from the terminal with 

```bash
brew install  basictex
```

It then needs to be configured with the following packages

```bash

sudo tlmgr update --self
sudo tlmgr install todonotes
sudo tlmgr install multirow
sudo tlmgr install wasysym
sudo tlmgr install wasy
sudo tlmgr install tabulary
sudo tlmgr install nth
sudo tlmgr install courier
sudo tlmgr install makecell
sudo tlmgr install appendix
sudo tlmgr install titlesec
sudo tlmgr install placeins
sudo tlmgr install adjustbox
sudo tlmgr install ltablex
sudo tlmgr install seqsplit
sudo tlmgr install soul
sudo tlmgr install supertabular
sudo tlmgr install enumitem
sudo tlmgr install sidecap
sudo tlmgr install xifthen
sudo tlmgr install ifmtarg
sudo tlmgr install relsize

```

also to use a particular mirror

```shell
sudo tlmgr option repository https://mirror.ox.ac.uk/sites/ctan.org/systems/texlive/tlnet
```