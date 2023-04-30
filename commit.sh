#!/bin/sh
git add -f config-files programs chrootInstall.sh install.sh LICENSE README.md commit.sh .gitignore
git commit -m "$1"
git push
