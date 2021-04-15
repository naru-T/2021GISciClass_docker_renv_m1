このレポジトリはdockerhubに連携するために使用しています。  

`Dockerfile`にはgeocomputation wirh Rで用いているパッケージを`renv`を用いて復元しています。 
`renv.lock`は、geocomputation wirh RのRstudio cloudにて`R version 4.0.3`で制作しました。 
Rstudio serverを通じてgeocomputation with Rの環境を再現できる他、Rmarkdownによる日本語でのpdf作成にも対応するようにしています。  

## 使い方
`docker-compose up -d --b`にてdocker imageを構築すると時間がかかる（> 1 hr.）ので、dockerhub上の  
https://hub.docker.com/r/rsnaru/2021gisciclass  
を通じて環境構築するのがよい。

## reference
- [geocomputation with R](https://geocompr.robinlovelace.net/)
- [binder](https://mybinder.org/v2/gh/robinlovelace/geocompr/master?urlpath=rstudio)
- [Rstudio cloud](https://rstudio.cloud/project/1642300)　
