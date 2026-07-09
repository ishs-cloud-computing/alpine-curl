# syntax=docker/dockerfile:1
FROM alpine:3.23 AS build

RUN apk add --no-cache clang lld compiler-rt musl-dev cmake samurai && \
    LLVM_VER=$(clang --version | grep -oiE 'version [0-9]+' | grep -oE '[0-9]+' | head -1) && \
    apk add --no-cache "llvm${LLVM_VER}"

WORKDIR /src
COPY curl ./curl

RUN LLVM_VER=$(clang --version | grep -oiE 'version [0-9]+' | grep -oE '[0-9]+' | head -1) && \
    export PATH="/usr/lib/llvm${LLVM_VER}/bin:${PATH}" && \
    cmake -G Ninja -S curl -B build \
      -DCMAKE_BUILD_TYPE=MinSizeRel \
      -DCMAKE_C_COMPILER=clang \
      -DCMAKE_AR="$(command -v llvm-ar)" \
      -DCMAKE_RANLIB="$(command -v llvm-ranlib)" \
      -DCMAKE_NM="$(command -v llvm-nm)" \
      -DCMAKE_C_FLAGS="-Oz -ffunction-sections -fdata-sections" \
      -DCMAKE_EXE_LINKER_FLAGS="-static -fuse-ld=lld -rtlib=compiler-rt -unwindlib=none -Wl,--gc-sections" \
      -DBUILD_SHARED_LIBS=OFF -DBUILD_STATIC_CURL=ON -DBUILD_CURL_EXE=ON \
      -DCURL_ENABLE_SSL=OFF \
      -DCURL_ZLIB=OFF -DCURL_BROTLI=OFF -DCURL_ZSTD=OFF \
      -DUSE_NGHTTP2=OFF -DUSE_NGTCP2=OFF \
      -DCURL_USE_LIBPSL=OFF -DUSE_LIBIDN2=OFF \
      -DCURL_USE_LIBSSH2=OFF -DCURL_USE_LIBSSH=OFF \
      -DCURL_DISABLE_LDAP=ON -DCURL_DISABLE_LDAPS=ON \
      -DCURL_DISABLE_RTSP=ON -DCURL_DISABLE_DICT=ON \
      -DCURL_DISABLE_TELNET=ON -DCURL_DISABLE_TFTP=ON \
      -DCURL_DISABLE_FTP=ON -DCURL_DISABLE_FILE=ON \
      -DCURL_DISABLE_POP3=ON -DCURL_DISABLE_IMAP=ON \
      -DCURL_DISABLE_SMTP=ON -DCURL_DISABLE_SMB=ON \
      -DCURL_DISABLE_GOPHER=ON -DCURL_DISABLE_MQTT=ON && \
    cmake --build build && \
    llvm-strip build/src/curl && cp build/src/curl /curl

FROM alpine:3.23
LABEL org.opencontainers.image.source="https://github.com/ishs-cloud-computing/alpine-curl"
LABEL org.opencontainers.image.licenses="BSD-3-Clause"
COPY --from=build /curl /usr/bin/curl