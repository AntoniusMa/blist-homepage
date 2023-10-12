FROM docker.io/library/golang:1.21.3-bookworm
COPY . .
RUN apt-get update -y
RUN apt-get install wget git npm -y
RUN npm i -g postcss-cli
RUN npm i
RUN wget https://github.com/gohugoio/hugo/releases/download/v0.115.4/hugo_extended_0.115.4_Linux-64bit.tar.gz && \
    tar -xvzf hugo_extended_0.115.4_Linux-64bit.tar.gz  && \
    chmod +x hugo && \
    mv hugo /usr/local/bin/hugo && \
    rm hugo_extended_0.115.4_Linux-64bit.tar.gz
RUN hugo
VOLUME [ "/public" ]