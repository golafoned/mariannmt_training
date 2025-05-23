#!/bin/bash -v

MARIAN=../../build

# if we are in WSL, we need to add '.exe' to the tool names
if [ -e "/bin/wslpath" ]
then
    EXT=.exe
fi

MARIAN_TRAIN=$MARIAN/marian$EXT
MARIAN_DECODER=$MARIAN/marian-decoder$EXT
MARIAN_VOCAB=$MARIAN/marian-vocab$EXT
MARIAN_SCORER=$MARIAN/marian-scorer$EXT

# set chosen gpus
GPUS=0
if [ $# -ne 0 ]
then
    GPUS=$@
fi
echo Using GPUs: $GPUS

if [ ! -e $MARIAN_TRAIN ]
then
    echo "marian is not installed in $MARIAN, you need to compile the toolkit first"
    exit 1
fi

if [ ! -e ../tools/moses-scripts ] || [ ! -e ../tools/subword-nmt ] || [ ! -e ../tools/sacreBLEU ]
then
    echo "missing tools in ../tools, you need to download them first"
    exit 1
fi

if [ ! -e "data/corpus.en" ]
then
    ./scripts/download-files.sh
fi

mkdir -p model

# preprocess data
if [ ! -e "data/corpus.bpe.en" ]
then
    LC_ALL=C.UTF-8 python3 -m sacrebleu -t wmt22 -l en-uk --echo src > data/valid.en
    LC_ALL=C.UTF-8 python3 -m sacrebleu -t wmt22 -l en-uk --echo ref > data/valid.uk


    LC_ALL=C.UTF-8 python3 -m sacrebleu -t wmt22 -l en-uk --echo src > data/test2022.en
    LC_ALL=C.UTF-8 python3 -m sacrebleu -t wmt23 -l en-uk --echo src > data/test2023.en
    LC_ALL=C.UTF-8 python3 -m sacrebleu -t wmt24 -l en-uk --echo src > data/test2024.en


    ./scripts/preprocess-data.sh
fi

# create common vocabulary
if [ ! -e "model/vocab.enuk.yml" ]
then
    cat data/corpus.bpe.en data/corpus.bpe.uk | $MARIAN_VOCAB --max-size 36000 > model/vocab.enuk.yml
fi

# train model
if [ ! -e "model/model.npz" ]
then
    $MARIAN_TRAIN \
        --model model/model.npz --type transformer \
        --train-sets data/corpus.bpe.en data/corpus.bpe.uk \
        --max-length 100 \
        --vocabs model/vocab.enuk.yml model/vocab.enuk.yml \
        --mini-batch-fit -w 20000 --maxi-batch 1000 \
        --early-stopping 10 --cost-type=ce-mean-words \
        --valid-freq 5000 --save-freq 5000 --disp-freq 500 \
        --valid-metrics ce-mean-words perplexity translation \
        --valid-sets data/valid.bpe.en data/valid.bpe.uk \
        --valid-script-path "bash ./scripts/validate.sh" \
        --valid-translation-output data/valid.bpe.en.output --quiet-translation \
        --valid-mini-batch 64 \
        --beam-size 6 --normalize 0.6 \
        --log model/train.log --valid-log model/valid.log \
        --enc-depth 6 --dec-depth 6 \
        --transformer-heads 8 \
        --transformer-postprocess-emb d \
        --transformer-postprocess dan \
        --transformer-dropout 0.1 --label-smoothing 0.1 \
        --learn-rate 0.0003 --lr-warmup 16000 --lr-decay-inv-sqrt 16000 --lr-report \
        --optimizer-params 0.9 0.98 1e-09 --clip-norm 5 \
        --tied-embeddings-all \
        --devices $GPUS --sync-sgd --seed 1111 \
        --exponential-smoothing
fi

# find best model on dev set
ITER=`cat model/valid.log | grep translation | sort -rg -k12,12 -t' ' | cut -f8 -d' ' | head -n1`

# translate test sets
for prefix in test2022 test2023 test2024
do
    cat data/$prefix.bpe.en \
        | $MARIAN_DECODER -c model/model.npz.decoder.yml -m model/model.iter$ITER.npz -d $GPUS -b 12 -n -w 6000 \
        | sed 's/\@\@ //g' \
        | ../tools/moses-scripts/scripts/recaser/detruecase.perl \
        | ../tools/moses-scripts/scripts/tokenizer/detokenizer.perl -l de \
        > data/$prefix.uk.output
done

# calculate bleu scores on test sets
LLC_ALL=C.UTF-8 python3 -m sacrebleu -t wmt22 -l en-uk < data/test2022.uk.output
LC_ALL=C.UTF-8 python3 -m sacrebleu -t wmt23 -l en-uk < data/test2023.uk.output
LC_ALL=C.UTF-8 python3 -m sacrebleu -t wmt24 -l en-uk < data/test2024.uk.output
