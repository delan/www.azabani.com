#!/bin/sh

git pull &&
jekyll build &&
ln -s _site/patch _site/bug
