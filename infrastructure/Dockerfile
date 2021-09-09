FROM nginx:alpine as build

RUN apk add --update \
  wget

ARG HUGO_VERSION="0.82.0"
RUN wget "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz" && \
  tar xzf hugo_${HUGO_VERSION}_Linux-64bit.tar.gz && \
  rm -r hugo_${HUGO_VERSION}_Linux-64bit.tar.gz && \
  mv hugo /usr/bin

RUN mkdir -p /root/app
COPY ./blog /root/app
WORKDIR /root/app

RUN hugo -d public --gc --minify --cleanDestinationDir

FROM scratch as static
COPY --from=build /root/app/public /