FROM quay.io/jupyter/r-notebook:hub-5.4.6

USER root

RUN curl --silent -L --fail https://download2.rstudio.org/server/jammy/amd64/rstudio-server-2026.05.0-218-amd64.deb > /tmp/rstudio.deb && \
    apt-get update && \
    apt-get install -y /tmp/rstudio.deb nodejs libudunits2-dev && \
    rm /tmp/rstudio.deb && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Setting ld library path to ensure R is using the conda provided SSL libs
RUN chown -R ${NB_USER}:rstudio-server /var/lib/rstudio-server && \
    chmod -R g=u /var/lib/rstudio-server && \
    echo "rsession-ld-library-path=/opt/conda/lib:/usr/lib/x86_64-linux-gnu" >> /etc/rstudio/rserver.conf && \
    echo "www-port=8888" >> /etc/rstudio/rserver.conf

ENV PATH=$PATH:/usr/lib/rstudio-server/bin

# Switch to User for App-level installs
USER ${NB_USER}
WORKDIR $HOME

# Install common R Packages
RUN mamba install -v -y \
    r-ggplot2 r-dplyr r-tidyr r-janitor r-here r-arrow \
    r-mgcv r-lme4 r-caret r-randomForest r-lattice \
    r-tidyverse r-tidymodels r-lubridate r-zoo \
    r-data.table r-devtools r-XML r-jsonlite r-knitr \
    r-rmarkdown r-gbm r-dismo r-terra r-sf r-gt && \
    mamba clean --all -f -y

# Switch back to Root for final cleanup and scoped fixes
USER root

# Surgical Fix for R & Final Permissions
# Configures both the system LD_LIBRARY_PATH and the persistent local user library location
RUN echo "LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:\${LD_LIBRARY_PATH}" >> /opt/conda/lib/R/etc/Renviron.site && \
    echo "R_LIBS_USER=\${R_LIBS_USER:-'~/R/%p-library/%v'}" >> /opt/conda/lib/R/etc/Renviron.site && \
    echo 'local({ lib <- Sys.getenv("R_LIBS_USER"); if (nchar(lib) > 0) { dir.create(lib, recursive = TRUE, showWarnings = FALSE); .libPaths(c(lib, .libPaths())) } })' >> /opt/conda/lib/R/etc/Rprofile.site && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# Install Proxy
USER ${NB_USER}
RUN pip install --no-cache-dir jupyter-rsession-proxy
