FROM quay.io/jupyter/r-notebook:hub-4.1.4

USER root
WORKDIR /root

# Install R-Studio and some common R module dependencies
RUN curl --silent -L --fail https://download2.rstudio.org/server/jammy/amd64/rstudio-server-2024.04.2-764-amd64.deb > /root/rstudio.deb && \
    apt update && \
    apt install -y libgdal-dev libgeos-dev libproj-dev && \
    apt install -y /root/rstudio.deb && \
    apt clean && \
    rm -rf /var/lib/apt/lists/* \
           /root/rstudio.deb

# RStudio needs to run as the notebook user
RUN chown -R ${NB_USER}:rstudio-server /var/lib/rstudio-server && \
    chmod -R g=u /var/lib/rstudio-server

ENV PATH=$PATH:/usr/lib/rstudio-server/bin

USER ${NB_USER}
WORKDIR $HOME

# Replace all favicons with Nectar logo and install our theme extension
COPY favicon.ico /tmp
RUN cp /tmp/favicon.ico /opt/conda/share/jupyterhub/static/favicon.ico || true && \
    cp /tmp/favicon.ico /opt/conda/lib/python3.11/site-packages/jupyter_server/static/favicon.ico || true && \
    cp /tmp/favicon.ico /opt/conda/lib/python3.11/site-packages/jupyter_server/static/favicons/favicon.ico || true && \
    cp /tmp/favicon.ico /opt/conda/lib/python3.11/site-packages/nbclassic/static/base/images/favicon.ico || true && \
    cp /tmp/favicon.ico /opt/conda/lib/python3.11/site-packages/nbclassic/static/favicon.ico || true && \
    cp /tmp/favicon.ico /opt/conda/lib/python3.11/site-packages/notebook/static/favicon.ico || true

# Install Nectar JupyterLab theme at latest commit
RUN pip install git+https://github.com/NeCTAR-RC/nectar-jupyterlab-theme.git@227cd43f4cba9651d04ce0f973faa7d41c09aeb9

# Extra R packages - installed in chunks or mamba locks up
RUN mamba install -v -y r-ggplot2 r-dplyr r-tidyr r-janitor r-here r-arrow && \
    mamba install -v -y r-mgcv r-lme4 r-caret r-randomForest r-lattice && \
    mamba install -v -y r-tidyverse r-tidymodels r-lubridate r-zoo && \
    mamba install -v -y r-data.table r-devtools r-XML r-jsonlite r-knitr && \
    mamba install -v -y r-rmarkdown r-gbm r-dismo r-terra && \
    mamba clean --all -f -y && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

RUN pip install jupyter-rsession-proxy
