#!/bin/bash

# make string names
datestr=$(date +"%d%H")
packstr=./fit-${1}-${datestr}

# make folder
mkdir ${packstr}

# move files
mv ./*.mat ${packstr}
mv ./*.fig ${packstr}
mv ./*.txt ${packstr}
