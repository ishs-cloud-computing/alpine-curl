# alpine-curl

2026 전국 기능경기대회 클라우드컴퓨팅 과제용 최소 정적 curl 베이스 이미지입니다. Alpine 위에 HTTP 전용 정적 curl 하나만 올린 이미지로, 대회에서는 해당 이미지 위에 book 바이너리를 `COPY`해서 최종 애플리케이션 이미지를 만듭니다.

```
ghcr.io/ishs-cloud-computing/alpine-curl:3.23
```

## 설계 의도

이 이미지는 대회 과제의 세 가지 제약을 동시에 만족시키기 위해 만들어졌습니다.

- ECR 이미지 크기 8MB 이하: 불필요한 요소를 모두 제거하고 `curl`을 정적 링크 + `strip` + `-Oz`로 빌드해 부피를 최소화했습니다. 크기 기준은 ECR `imageSizeInBytes` (압축된 레이어 합)dlau, `docker/podman images`가 보여주는 비압축 크기와는 다릅니다.
- curl 포함: 채점이 컨테이너 안에서 `curl`로 IMDS(`http://169.254.169.254`)접근 차단을 확인합니다. 대상이 HTTP이므로 TLS는 포함하지 않습니다. `apk add curl`이 함께 차지하는 openssl / nghttp2 / brotli / zstd 등의 의존성 트리를 제거해 크기를 크게 줄였습니다.
- ECR basic scan 지원: `scratch` / `distroless` 이미지는 basic scan이 지원하지 않아 `UnsupportedImage`가 납니다. 스캔이 정상 동작하려면 지원되는 OS가 필요하므로 Alpine 베이스를 유지합니다.

## 툴체인

빌드는 LLVM 계열로만 구성했습니다.

| 역할 | 도구 | 라이선스 |
| --- | --- | --- |
| 컴파일 | clang | Apache-2.0 WITH LLVM-exception |
| 링크 | lld | Apache-2.0 WITH LLVM-exception |
| 런타임 | compiler-rt (`-rtlib=compiler-rt -unwindlib=none`) | Apache-2.0 WITH LLVM-exception |
| 아카이브/strip | llvm-ar / llvm-ranlib / llvm-strip | Apache-2.0 WITH LLVM-exception |
| 빌드 시스템 | CMake + samurai (ninja) | BSD-3-Clause / MIT |

gcc, libgcc, binutils, autotools는 사용하지 않습니다. curl 소스는
vendor/curl git submodule로 특정 릴리스 태그에 고정됩니다.

## 요구사항

- podman (또는 docker)
- git

빌드에 필요한 clang / lld / compiler-rt / cmake / samurai 등은 모두 컨테이너 안에서
apk로 설치되므로 호스트에는 별도 설치가 필요 없습니다.

## 빌드

submodule을 포함해 클론합니다.

```bash
git clone --recurse-submodules https://github.com/ishs-cloud-computing/alpine-curl.git
cd alpine-curl
```

이미 클론한 경우 submodule만 초기화합니다.

```bash
git submodule update --init --recursive
```

이미지를 빌드합니다.

```bash
podman build --platform linux/amd64 -t alpine-curl:3.23 .

# 또는 Docker 사용

docker build --platform linux/amd64 -t alpine-curl:3.23 -f Containerfile .
```

> 노드 아키텍처가 arm64면 --platform linux/arm64로 맞추세요.

## License

This project is licensed under [BSD-3-Claude License](LICENSE).