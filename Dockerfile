# Build frontend dist.
FROM node:18.12.1-alpine3.16 AS frontend
WORKDIR /app

COPY ./app/ .

RUN yarn
RUN yarn build

# Build backend exec file.
FROM golang:1.19.3-alpine3.16 AS backend
WORKDIR /app

RUN apk update
RUN apk --no-cache add gcc musl-dev

COPY . .
COPY --from=frontend /app/dist ./server/dist

RUN go build -o memos ./bin/server/main.go

# Make workspace with above generated files.
FROM alpine:3.16 AS monolithic
# 使用 HTTPS 协议访问容器云调用证书安装
RUN apk add ca-certificates

WORKDIR /app

COPY --from=backend /app/memos /app/

# Directory to store the data, which can be referenced as the mounting point.
RUN mkdir -p /var/opt/memos

ENTRYPOINT ["./memos", "--mode", "prod", "--port", "5230"]
