# case-law-semantic-shift
Creates both states and contextual word embeddings for several legal corpora using Word2Vec and fine-tuned BERT models in order to map the semantic shift between language of case law and everyday English.

## Semantic Shift Analysis
This repository contains a Jupyter notebook for analyzing **semantic shifts** in language between contexts. The main focus is on tracking how word meanings may differ between their legal context and everyday context. It also contains a folder with all the necessary files for a lightweight semantic search function (except large Word2Vec models).

## Notebook
- [`semantic_shift_v0.ipynb`](semantic_shift_v0.ipynb): Core analysis of semantic shifts using linguistic data.

### Corpora
This notebook analyses three corpora:
- Case Law of England and Wales: https://caselaw.nationalarchives.gov.uk
- British National Corpus: http://www.natcorp.ox.ac.uk
- UK Legislation: https://www.legislation.gov.uk

# app-folder
This folder contains all code and assets related to running the semantic suggestions web app. It uses the semantic_sggestions_w2v function described in the Jupyter Notebook to guide user queries to alternative search terms.

## Semantic Search prototype
This prototype can be considered as a legal 'did you mean' function. It suggests legal alternatives to words by finding the intersection of nearest neighbours of a term between the BNC and the FCL corpus.

### Features

- Loads and preprocesses three corpora
- Compares semantic similarity across corpora
- Prototype for semantic search engine
- Visualizes word shift magnitude

### Building and running the application locally
You first need access to the Word2Vec models in order for the prototype to run. These can be accessed upon request as they are too large to be shared on GitHub. You will need to download the .bin and .npy files for each model (1 model per corpus) and ensure that these are saved in your /models folder as described in semantic_app.py

Build the docker container with
`docker build . -t semantic-search-app`
Then run it with
`docker run -p 8000:80 semantic-search-app`

You can then access the application at 0.0.0.0:8000/search

### Note About models/
The models/ directory is intentionally excluded from version control due to GitHub's file size limits (100 MB max per file). It should contain:

bnc_sg_w10_f5_300_v3.bin.syn1neg.npy
bnc_sg_w10_f5_300_v3.bin.wv.vectors.npy
fcl_sg_w10_f5_300_v4.bin.syn1neg.npy
fcl_sg_w10_f5_300_v4.bin.wv.vectors.npy

These files are required to run the app. They can either be created using the train_word2vec_models function in the Notebook or they can be shared by the author for download.
