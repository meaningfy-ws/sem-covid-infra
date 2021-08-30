
FROM python:3.8
COPY sem-covid/ /opt
COPY requirements-topic-modeling.txt /opt
COPY .env /opt


WORKDIR /opt
RUN pip install --upgrade pip
RUN pip install -r requirements-topic-modeling.txt
ENV PYTHONPATH "$PYTHONPATH:$(pwd)/sem_covid"
CMD streamlit run sem_covid/entrypoints/streamlit_visualizers/topic_modeling.py
