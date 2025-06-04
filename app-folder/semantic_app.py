import streamlit as st
import re
import spacy
import numpy as np
import os
import pandas as pd
from gensim.models import Word2Vec

# === Helper functions ===

@st.cache_resource
def load_models():
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    MODEL_DIR = os.path.join(BASE_DIR, "models")

    bnc_model = Word2Vec.load(os.path.join(MODEL_DIR, "bnc_sg_w10_f5_300_v3.bin"))
    fcl_model = Word2Vec.load(os.path.join(MODEL_DIR, "fcl_sg_w10_f5_300_v4.bin"))

    return bnc_model, fcl_model

def extract_keyword_w2v(sentence, model):
    nlp = spacy.load("en_core_web_sm")
    doc = nlp(sentence)
    content_words = [token.lemma_.lower() for token in doc if token.pos_ in ['NOUN', 'VERB', 'ADJ']]
    valid_words = [word for word in content_words if word in model.wv]

    if not valid_words:
        return None

    sims = []
    for word in valid_words:
        other_words = [w for w in valid_words if w != word]
        avg_sim = np.mean([model.wv.similarity(word, other) for other in other_words]) if other_words else 0
        sims.append(avg_sim)

    best_word = valid_words[np.argmax(sims)]
    return best_word

def suggest_search_terms_w2v(word, fcl_model, bnc_model, k=10, threshold=0.5):
    if word not in fcl_model.wv:
        return []

    fcl_neighbors = fcl_model.wv.most_similar(word, topn=k*5)
    filtered_neighbors = []

    for neighbor, score in fcl_neighbors:
        if score < threshold:
            continue
        if not neighbor.isalpha() or len(neighbor) < 3 or len(neighbor) > 20:
            continue
        if neighbor.startswith(word) or word.startswith(neighbor):
            if abs(len(neighbor) - len(word)) <= 2:
                continue
        if neighbor in bnc_model.wv:
            bnc_similarity = bnc_model.wv.similarity(word, neighbor)
            shift = score - bnc_similarity
            if score > bnc_similarity or bnc_similarity < 0.4:
                filtered_neighbors.append((neighbor, score, bnc_similarity, shift))
        else:
            bnc_similarity = 0.0
            shift = score
            filtered_neighbors.append((neighbor, score, bnc_similarity, shift))

    filtered_neighbors.sort(key=lambda x: x[1], reverse=True)
    top_neighbors = filtered_neighbors[:k]

    return [
        (
            term,
            score,        # FCL cosine similarity
            bnc_sim,      # BNC cosine similarity
            shift,        # Shift
            f"https://caselaw.nationalarchives.gov.uk/search?per_page=10&order=-date&query={term}"
        )
        for term, score, bnc_sim, shift in top_neighbors
    ]

def get_suggestions(user_input: str = "", k: int = 10):
    best_bnc_model, best_fcl_model = load_models()

    keyword = extract_keyword_w2v(user_input, best_fcl_model)

    if not keyword:
        results = []
    else:
        results = suggest_search_terms_w2v(keyword, best_fcl_model, best_bnc_model, k=k)

    return {
        "user_input": user_input,
        "results": results,
        "keyword": keyword
    }

# === Streamlit app ===

st.set_page_config(page_title="Legal Synonym Tool", layout="wide")

if "results" not in st.session_state:
    st.session_state["results"] = None

st.markdown("""
Lost for Words: A Legal Synonym Tool
==================

### This prototype is an experimental semantic search tool for The National Archives' [Find Case Law](https://caselaw.nationalarchives.gov.uk/) repository.

""")

col1, col2 = st.columns(2)

with col1:
    with st.container(border=True):
        user_input = st.text_input("Enter your search query", autocomplete="off")

        if st.button("Search", disabled=(not user_input)):
            with st.spinner(text="Generating suggestions..."):
                result = get_suggestions(user_input)

                st.session_state["results"] = result["results"]
                st.session_state["user_input"] = result["user_input"]
                st.session_state["keyword"] = result["keyword"]
                st.rerun()

    if st.session_state["results"] is not None:
        with st.container(border=True):
            col3, col4 = st.columns(2)

            with col3:
                st.caption("You searched for:")
                st.text(st.session_state["user_input"])
            with col4:
                st.caption("Detected keyword:")
                st.text(st.session_state["keyword"])

            results = st.session_state["results"]

            if results:
                st.caption("Results")

                for term, score, bnc_sim, shift, url in results:
                    if shift > 0.3:
                        color = "red"
                    elif shift < -0.3:
                        color = "green"
                    else:
                        color = "black"

                    st.markdown(
                        f'<a href="{url}" target="_blank" style="color:{color}">{term}</a> '
                        f'(FCL: {score:.2f}, BNC: {bnc_sim:.2f}, Shift: {shift:+.2f})',
                        unsafe_allow_html=True
                    )

                st.caption("Semantic Shift Visualisation")

                df = pd.DataFrame([
                    {"Term": term, "Semantic Shift": shift}
                    for term, score, bnc_sim, shift, url in results
                ])

                st.bar_chart(df.set_index("Term"))
            else:
                st.warning("No distinctive legal terms found. Try another query.")

with col2:
    with st.expander(label="About this tool", expanded=True):
        st.markdown("""
        This prototype uses custom-trained Word2Vec models to extract a single keyword from your input sentence. It then suggests related legal search terms based on their semantic similarity in the Find Case Law corpus.

        Clicking on a suggested term takes you to the [Find Case Law](https://caselaw.nationalarchives.gov.uk/) search interface with that term pre-filled.
        """)
    with st.expander(label="Scores", expanded=True):
        st.markdown("""
        *   The FCL (Find Case Law) score shows how strongly each term is associated with your query in the legal corpus. 
        *   The BNC (British National Corpus) score shows its association in general English. 
        *   The Shift score (FCL - BNC) highlights how distinctive or specialised the term is in legal language — higher shift suggests more domain-specific usage.
        *   Results marked in red have a particularly high shift in meaning in the legal corpus, these terms are most likely to have distinct legal meaning. 
        """)
    with st.expander(label="Limitations", expanded=True):
        st.markdown("""
        *   This is an alpha-stage tool and is not comprehensive or authoritative.
        *   Search suggestions are generated from relatively small legal corpora and may include unexpected or irrelevant terms.
        *   The keyword extraction and similarity matching may not always align with legal search intent.
        *   Only one keyword is selected per query; complex legal questions may require multiple concepts.

        This tool is intended for research and prototyping purposes only.
        """)

    with st.expander(label="Credits", expanded=True):
        st.markdown("""
            This is an alpha version developed by **Caitlin Wilson** as part of a collaborative PhD project between **King's College London** and **The National Archives**, funded by the [**London Arts and Humanities Partnership**](https://www.lahp.ac.uk/).

            Supervisors: Dr Barbara McGillivray and Dr Niccolo Ridi. 
            
            With generous support from the Find Case Law team at The National Archives.
        """)
