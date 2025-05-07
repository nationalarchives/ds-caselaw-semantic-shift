# case-law-semantic-shift
Creates both states and contextual word embeddings for several legal corpora using Word2Vec and fine-tuned BERT models in order to map the semantic shift between language of case law and everyday English.

# Semantic Shift Analysis
This repository contains a Jupyter notebook for analyzing **semantic shifts** in language between contexts. The main focus is on tracking how word meanings may differ between their legal context and everyday context.

# Notebook
- [`semantic_shift_v2.ipynb`](semantic_shift_v2.ipynb): Core analysis of semantic shifts using linguistic data.

# Corpora
This notebook analyses three corpora:
- Case Law of England and Wales: https://caselaw.nationalarchives.gov.uk
- British National Corpus: http://www.natcorp.ox.ac.uk
- UK Legislation: https://www.legislation.gov.uk

# Semantic Search prototype
This prototype can be considered as a legal 'did you mean' function. It suggests legal alternatives to words by finding the intersection of nearest neighbours of a term between the BNC and the FCL corpus.

# Features

- Loads and preprocesses three corpora
- Compares semantic similarity across corpora
- Prototype for semantic search engine
- Visualizes word shift magnitude
