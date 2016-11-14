#!/bin/bash

# make string names
datestr=$(date +"%d%m%y%H%M%S")
packstr=./results/packup-${datestr}

# make folder
mkdir ${packstr}

# move files
mv ./results/*.mat ${packstr}
mv ./results/*.fig ${packstr}
mv ./results/*.txt ${packstr}

# get summary file
cd ./results/
str=${1}
cat > summary.txt << EOF
${str}
EOF

# zip files
zip packup-${datestr}.zip packup-${datestr}/* summary.txt
cd ../

# rm folder
rm -r ${packstr}
rm ./results/summary.txt
