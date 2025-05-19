#!/bin/bash -v

mkdir -p data
cd data

# get En-Uk training data for WMT17
wget -nc -O training.tgz "https://drive.usercontent.google.com/download?id=1pS5pM0H8n4383saEuf-3yQtOquu5Uawj&export=download&confirm=t"

# extract data
tar -xf training.tgz

# create corpus files
cat training/corpus.uk-en.uk > corpus.de
cat training/corpus.uk-en.en > corpus.en

cd ..
