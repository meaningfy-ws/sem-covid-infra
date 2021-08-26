#FROM samdobson/streamlit
#COPY . /usr/src/app
#WORKDIR /usr/src/app
#RUN pip install streamlit pandas networkx numpy d3graph

FROM python:3.8
COPY sem-covid/ /opt
COPY requirements-lang-model.txt /opt
COPY .env /opt


WORKDIR /opt
RUN pip install --upgrade pip
RUN pip install -r requirements-lang-model.txt
ENV PYTHONPATH "$PYTHONPATH:$(pwd)/sem_covid"
CMD streamlit run sem_covid/entrypoints/streamlit_visualizers/word_similarity.py



























#WORKDIR /opt/lang-model-explorer
##RUN pip install --upgrade pip
##
##RUN pip install streamlit pandas networkx numpy d3graph
#COPY . .
#
#WORKDIR /streamlit/sem-covid/sem_covid/entrypoints/streamlit_visualizers
#RUN pip install --upgrade pip
#
#RUN pip install streamlit pandas networkx numpy d3graph python-dotenv
##WORKDIR /streamlit/sem-covid
##RUN echo "/streamlit/sem-covid"
##RUN pwd
##RUN ls -l
##
##WORKDIR /sem-covid/sem-covid
##RUN echo "/sem-covid/sem-covid"
##RUN pwd
##RUN ls -l
#
##RUN cd sem_covid/sem_covid/entrypoints/streamlit_visualizers && streamlit run word_similarity.py
#
#CMD streamlit run word_similarity.py