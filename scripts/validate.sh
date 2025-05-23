#!/bin/bash

cat $1 \
    | sed 's/\@\@ //g' \
    | ../tools/moses-scripts/scripts/recaser/detruecase.perl 2>/dev/null \
    | ../tools/moses-scripts/scripts/tokenizer/detokenizer.perl -l uk 2>/dev/null \
    | ../tools/moses-scripts/scripts/generic/multi-bleu-detok.perl data/valid.uk \
    | sed -r 's/BLEU = ([0-9.]+),.*/\1/'
