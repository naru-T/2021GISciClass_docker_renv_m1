ARG DEBIAN_FRONTEND=noninteractive

FROM  amoselb/rstudio-m1:latest

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    binutils libproj-dev gdal-bin grass qgis qgis-plugin-grass saga libgit2-dev

RUN R CMD javareconf \
  && Rscript -e "install.packages(c('remotes','renv','tinytex'))" \
  && Rscript -e "remotes::install_github('paleolimbot/qgisprocess')"

RUN Rscript -e "remotes::install_github('paleolimbot/qgisprocess')"

RUN R CMD javareconf \
  && Rscript -e "install.packages('versions')" 

RUN R CMD javareconf \
  && Rscript -e "versions::install.versions('s2', '1.0.3')" 

COPY renv.lock renv.lock
RUN R -e 'renv::consent(provided = TRUE); renv::restore()'


RUN R CMD javareconf \
  && Rscript -e "install.packages(c('PKI','bookdown','rticles','rmdshower','rJava'))"



