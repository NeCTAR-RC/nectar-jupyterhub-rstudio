FROM jupyter/r-notebook:hub-3.0.0

# Replace all favicons with Nectar logo and install our theme extension
COPY favicon.ico /tmp
RUN cp /tmp/favicon.ico /opt/conda/share/jupyterhub/static/favicon.ico || true && \
    cp /tmp/favicon.ico /opt/conda/lib/python3.10/site-packages/jupyter_server/static/favicon.ico || true && \
    cp /tmp/favicon.ico /opt/conda/lib/python3.10/site-packages/jupyter_server/static/favicons/favicon.ico || true && \
    cp /tmp/favicon.ico /opt/conda/lib/python3.10/site-packages/nbclassic/static/base/images/favicon.ico || true && \
    cp /tmp/favicon.ico /opt/conda/lib/python3.10/site-packages/nbclassic/static/favicon.ico || true && \
    cp /tmp/favicon.ico /opt/conda/lib/python3.10/site-packages/notebook/static/base/images/favicon.ico || true && \
    cp /tmp/favicon.ico /opt/conda/lib/python3.10/site-packages/notebook/static/favicon.ico || true && \
    pip install git+https://github.com/NeCTAR-RC/nectar-jupyterlab-theme.git


RUN python3 -m pip install jupyter-rsession-proxy jupyter-server-proxy && \
    jupyter labextension install @jupyterlab/server-proxy

USER root
# Specify RStudio version
ENV RSTUDIO_VERSION "2022.12.0-353"

# Install OS dependencies of RStudio
RUN apt update && \
    apt install -y libgsl0-dev zlib1g-dev libxml2-dev cmake

RUN curl --silent -L --fail https://s3.amazonaws.com/rstudio-ide-build/server/jammy/amd64/rstudio-server-${RSTUDIO_VERSION}-amd64.deb > /tmp/rstudio.deb && \
    apt install -y /tmp/rstudio.deb && \
    rm /tmp/rstudio.deb && \
    apt clean && rm -rf /var/lib/apt/lists/* 

# RStudio needs to run as the notebook user
RUN chown -R ${NB_USER}:rstudio-server /var/lib/rstudio-server && \
    chmod -R g=u /var/lib/rstudio-server

ENV PATH=$PATH:/usr/lib/rstudio-server/bin

#ENV PASSWORD admin
#ENV USER ${NB_USER}

USER ${NB_USER}

#CMD ["/usr/lib/rstudio-server/bin/rserver", "--server-user","${USER}","--server-daemonize", "0", "--auth-none", "1", "--www-frame-origin", "same", "--www-verify-user-agent", "0"]
#CMD /usr/lib/rstudio-server/bin/rserver --server-user ${USER} --server-daemonize 0 --auth-none 1 --www-frame-origin same --www-verify-user-agent 0
