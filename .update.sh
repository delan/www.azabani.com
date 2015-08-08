#!/bin/sh

git pull &&
jekyll build &&
cd _site &&
ln -s patch bug
