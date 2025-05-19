#!/bin/bash -v

mkdir -p data
cd data

wget -nc http://data.statmt.org/wmt17/translation-task/training-parallel-nc-v12.tgz

# extract data
tar -xf training-parallel-nc-v12.tgz

# create corpus files
cat training/news-commentary-v12.de-en.de > corpus.uk
cat training/news-commentary-v12.de-en.en > corpus.en

# clean
rm -r europarl-* commoncrawl.* training/ *.tgz

cd ..



# # get En-Uk training data for WMT17
# wget -nc -O training.tgz "https://drive.usercontent.google.com/download?id=1pS5pM0H8n4383saEuf-3yQtOquu5Uawj&export=download&confirm=t"

# # extract data
# tar -xf training.tgz

# # create corpus files
# cat training/corpus.uk-en.uk > corpus.uk
# cat training/corpus.uk-en.en > corpus.en

# cd ..
