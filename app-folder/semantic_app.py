from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
import spacy
import numpy as np
from gensim.models import Word2Vec

# App + templates setup
app = FastAPI()
templates = Jinja2Templates(directory="templates")

# Load NLP models
nlp = spacy.load("en_core_web_sm")
best_bnc_model = Word2Vec.load("/models/bnc_sg_w10_f5_300_v3.bin")
best_fcl_model = Word2Vec.load("/models/fcl_sg_w10_f5_300_v4.bin")

# === Helper functions ===

def extract_keyword_w2v(sentence, model):
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

def suggest_search_terms_w2v(word, fcl_model, bnc_model, k=5, threshold=0.5):
    if word not in fcl_model.wv:
        return f"'{word}' not found in the legal corpus. Try another term."

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
            if score > bnc_similarity or bnc_similarity < 0.4:
                filtered_neighbors.append((neighbor, score))
        else:
            filtered_neighbors.append((neighbor, score))

    filtered_neighbors.sort(key=lambda x: x[1], reverse=True)
    top_neighbors = filtered_neighbors[:k]

    if not top_neighbors:
        return f"No distinctive legal terms found for '{word}'. Try another term."

    result_terms = [f"{term} ({score:.2f})" for term, score in top_neighbors]
    return f"Suggested legal search terms for '{word}': {', '.join(result_terms)}"

@app.get("/search", response_class=HTMLResponse)
def semantic_suggestions_w2v(request: Request, user_input: str = ""):
    keyword = None
    result = None

    if user_input:
        keyword = extract_keyword_w2v(user_input, best_fcl_model)
        if not keyword:
            result = "Couldn't extract a meaningful keyword. Try rephrasing."
        else:
            result = suggest_search_terms_w2v(keyword, best_fcl_model, best_bnc_model)

    return templates.TemplateResponse("search.html", {
        "request": request,
        "user_input": user_input,
        "result": result,
        "keyword": keyword
    })

