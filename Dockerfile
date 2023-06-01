# 编译
FROM --platform=$TARGETPLATFORM rust:1.68-alpine3.17 as builder

WORKDIR /usr/src

RUN USER=root cargo new dm-ticket

RUN  sed -i "s/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g" /etc/apk/repositories;

RUN apk add musl-dev openssl openssl-dev pkgconfig upx git

COPY Cargo.toml Cargo.lock /usr/src/dm-ticket/

COPY .cargo /usr/src/dm-ticket/.cargo

WORKDIR /usr/src/dm-ticket

RUN mkdir src/bin && cat src/main.rs > src/bin/login.rs && cat src/main.rs > src/bin/ticket.rs

RUN cargo build --release --verbose

COPY src /usr/src/dm-ticket/src/

RUN RUST_BACKTRACE=1 cargo build --release --verbose --bin dm-ticket && upx /usr/src/dm-ticket/target/release/dm-ticket


RUN RUST_BACKTRACE=1 cargo build --release --verbose --bin dm-login && upx /usr/src/dm-ticket/target/release/dm-login


FROM --platform=$TARGETPLATFORM alpine:3.17 as runtime

ENV TZ=Asia/Shanghai

RUN sed -i "s/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g" /etc/apk/repositories \
    && apk update  \
    && apk add --no-cache vim tzdata bind-tools curl \
    && echo "${TZ}" > /etc/timezone \
    && ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
    && rm -rf /var/cache/apk/*

WORKDIR /src/

COPY --from=builder /usr/src/dm-ticket/target/release/dm-ticket /usr/bin/dm-ticket

COPY --from=builder /usr/src/dm-ticket/target/release/dm-login /usr/bin/dm-login

COPY scripts/start.sh /usr/bin/start

CMD ["/usr/bin/start"]