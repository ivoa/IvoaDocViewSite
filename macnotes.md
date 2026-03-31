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
```

also to use a particular mirror

```shell
sudo tlmgr option repository https://mirror.ox.ac.uk/sites/ctan.org/systems/texlive/tlnet
```