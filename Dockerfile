FROM lukemathwalker/cargo-chef:latest-rust-1.59.0 AS chef
WORKDIR app

FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

FROM chef AS builder
COPY --from=planner /app/recipe.json recipe.json
# Build dependencies - this is the caching Docker layer!
RUN cargo chef cook --release --recipe-path recipe.json
# Build application
COPY . .
RUN cargo build --release --bin raffle_mongo_api

# We do not need the Rust toolchain to run the binary!
FROM debian:bullseye-slim AS runtime
RUN apt-get update
RUN apt-get install openssl -y
RUN apt-get install curl -y

#RUN apt-get install libssl-dev -y
#RUN apt-get install libnss3-tools -y
#RUN apt-get install build-essential procps curl file git -y
#RUN useradd -ms /bin/bash -g root -G sudo user
#USER user
#RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
#$RUN su - user -c 'brew install mkcert'
WORKDIR app
COPY conf /app/conf
RUN mkdir -p /app/cert
#RUN cd /app/cert && openssl genpkey -out key.pem -algorithm RSA -pkeyopt rsa_keygen_bits:2048
#RUN cd /app/cert && openssl pkey -in key.pem -pubout -out cert.pem
RUN cd /app/cert && openssl req -newkey rsa:2048 -new -nodes -x509 -days 3650 -keyout key.pem -out cert.pem -subj "/C=GE/ST=London/L=London/O=Global Security/OU=IT Department/CN=example.com"

COPY --from=builder /app/target/release/raffle_mongo_api /app
RUN ls -la /app
#EXPOSE 8080
#CMD ["/app/raffle_mongo_api"]
ENTRYPOINT ["/app/raffle_mongo_api"]