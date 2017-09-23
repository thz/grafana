FROM golang:1.8 as golang
FROM node as buildstage
# fetch golang from previous stage
COPY --from=golang /usr/local/go /usr/local/go
ENV GOPATH /go
ENV PATH /go/bin:/usr/local/go/bin:$PATH

# stage code
RUN mkdir -p /go/src/github.com/grafana/grafana
COPY . /go/src/github.com/grafana/grafana

# build
WORKDIR /go/src/github.com/grafana/grafana
RUN go run build.go setup
RUN go run build.go build
RUN go run build.go build-cli

# build assets
RUN npm install -g yarn --silent
RUN yarn install --pure-lockfile ||  true
RUN npm install -g grunt-cli
RUN grunt

# runtime
FROM bitnami/minideb:jessie as runstage

RUN mkdir -p /usr/share/grafana/

COPY --from=buildstage \
	/go/src/github.com/grafana/grafana/bin/grafana-server \
	/go/src/github.com/grafana/grafana/bin/grafana-cli \
	/usr/sbin/
COPY --from=buildstage \
	/go/src/github.com/grafana/grafana/conf /usr/share/grafana/conf

COPY --from=buildstage \
	/go/src/github.com/grafana/grafana/public_gen /usr/share/grafana/public

EXPOSE 3000
ENTRYPOINT /usr/sbin/grafana-server --homepath /usr/share/grafana
