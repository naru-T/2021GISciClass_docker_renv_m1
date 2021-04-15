ARG DEBIAN_FRONTEND=noninteractive

FROM  amoselb/rstudio-m1:latest

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    binutils libproj-dev gdal-bin grass qgis qgis-plugin-grass saga libgit2-dev

RUN R CMD javareconf \
  && Rscript -e "install.packages(c('remotes','renv','tinytex','s2','PKI','bookdown','rticles','rmdshower','rJava'))" \
  && Rscript -e "remotes::install_github('paleolimbot/qgisprocess')"


COPY renv.lock renv.lock
RUN R -e 'renv::consent(provided = TRUE); renv::restore()'



