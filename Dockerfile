#
# Dockerfile for an image with the currently checked out version of zipline installed. To build:
#
#    docker build -t alpacamarkets/alpaca-zipline .
#
# To run the container:
#
#    docker run -v /path/to/your/notebooks:/projects -v ~/.zipline:/root/.zipline -p 8888:8888/tcp --name zipline -it quantopian/zipline
#
# To access Jupyter when running docker locally (you may need to add NAT rules):
#
#    https://127.0.0.1:8888
#
# You can also run an algo using the docker exec command.  For example:
#
#    docker exec -it zipline zipline run -f /projects/my_algo.py --start 2015-1-1 --end 2016-1-1 /projects/result.pickle
#
FROM python:3.5

#
# set up environment
#
ENV TINI_VERSION v0.10.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

ENV PROJECT_DIR=/projects \
    NOTEBOOK_PORT=8888 \
    SSL_CERT_PEM=/root/.jupyter/jupyter.pem \
    SSL_CERT_KEY=/root/.jupyter/jupyter.key \
    PW_HASH="u'sha1:31cb67870a35:1a2321318481f00b0efdf3d1f71af523d3ffc505'" \
    CONFIG_PATH=/root/.jupyter/jupyter_notebook_config.py

#
# install TA-Lib and other prerequisites
#

RUN mkdir ${PROJECT_DIR} \
    && apt-get -y update \
    && apt-get -y install libfreetype6-dev libpng-dev libopenblas-dev liblapack-dev gfortran \
    && curl -L https://downloads.sourceforge.net/project/ta-lib/ta-lib/0.4.0/ta-lib-0.4.0-src.tar.gz | tar xvz

#
# build and install zipline from source.  install TA-Lib after to ensure
# numpy is available.
#

WORKDIR /ta-lib

RUN pip install 'numpy>=1.11.1,<2.0.0' \
  && pip install 'scipy>=0.17.1,<1.0.0' \
  && pip install 'pandas>=0.18.1,<1.0.0' \
  && ./configure --prefix=/usr \
  && make \
  && make install \
  && pip install TA-Lib \
  && pip install matplotlib \
  && pip install jupyter

RUN pip install git+https://github.com/alpacahq/zipline@98e860b55c9fc4a8a825fe6c0f558b0fb2866bf8
RUN pip install alpaca-trade-api==0.10.0

EXPOSE ${NOTEBOOK_PORT}

ADD ./extension.py /root/.zipline/extension.py

#
# start the jupyter server
#

WORKDIR ${PROJECT_DIR}
ADD ./start-jupyter.sh /
CMD /start-jupyter.sh
