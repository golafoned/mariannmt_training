#!/bin/bash -v

mkdir -p data
cd data

# get En-Uk training data for WMT17
wget -nc -O training.tgz "https://drive.usercontent.google.com/download?id=1penNB2h9XFrv0BKwCrZoBq-KUtFxqfpl&export=download&confirm=t"

# extract data
tar -xf training.tgz

# create corpus files
cat training/corpus.uk-en.uk > corpus.uk
cat training/corpus.uk-en.en > corpus.en

cd ..
