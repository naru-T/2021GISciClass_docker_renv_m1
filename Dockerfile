ARG DEBIAN_FRONTEND=noninteractive

FROM  amoselb/rstudio-m1:latest

RUN apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests --allow-unauthenticated -y \
    libpng-dev \
    binutils \
    libproj-dev \
    gdal-bin \
    libgit2-dev \
    qgis-plugin-grass \
    saga \
    grass

#RUN env QT_QPA_PLATFORM='offscreen' qgis_process
#RUN echo "[PythonPlugins]\nprocessing=true" >> root/.local/share/QGIS/QGIS3/profiles/default/QGIS/QGIS3.ini

RUN R CMD javareconf \
  && Rscript -e "install.packages(c('remotes','renv','tinytex','s2','PKI','bookdown','rticles','rmdshower','rJava', 'RQGIS'))" \
  && Rscript -e "remotes::install_github('paleolimbot/qgisprocess')"


COPY renv.lock renv.lock
RUN R -e 'renv::consent(provided = TRUE); renv::restore()'
