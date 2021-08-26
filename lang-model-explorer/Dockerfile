
FROM python:3.8
COPY sem-covid/ /opt
COPY requirements-lang-model.txt /opt
COPY .env /opt


WORKDIR /opt
RUN pip install --upgrade pip
RUN pip install -r requirements-lang-model.txt
ENV PYTHONPATH "$PYTHONPATH:$(pwd)/sem_covid"
CMD streamlit run sem_covid/entrypoints/streamlit_visualizers/word_similarity.py
