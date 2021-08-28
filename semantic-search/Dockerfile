
FROM python:3.8
COPY sem-covid/ /opt
COPY requirements-semantic-search.txt /opt
COPY .env /opt


WORKDIR /opt
RUN pip install --upgrade pip
RUN pip install -r requirements-semantic-search.txt
ENV PYTHONPATH "$PYTHONPATH:$(pwd)/sem_covid"
CMD streamlit run sem_covid/entrypoints/notebooks/legal_radar/entrypoints/streamlit_app/app.py
