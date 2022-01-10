---
title: "Docker image 크기 줄이기"
category: Docker
toc: true
toc_label: "이 페이지 목차"
---

배포하는 Docker 이미지의 크기를 줄여보았다.

## Docker 이미지 크기
Docker 이미지 크기는 base 이미지와 이것에 내가 추가하는 패키지, app 등의 크기를 더한 값이 된다. 또한 빌드시 Docker 이미지의 layer가 많아져도 오버헤드가 있으니 layer 개수도 적을수록 크기가 줄어든다.  
내가 배포하는 이미지는 `ubuntu:18.04`를 base 이미지로 하여 내가 짠 Go 웹 서버 프로그램을 add 시키고 이것을 실행하는 것이었는데, 아래와 같이 `ubuntu:18.04` 이미지 크기를 보니 약 64MB였다.
```bash
$ docker images ubuntu:18.04
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
ubuntu              18.04               8e4ce0a6ce69        3 weeks ago         64.2MB
```

여기에 내가 짠 프로그램 크기를 더한 값 정도가 최종 이미지의 크기였다.  
내가 짠 app의 크기는 upx로 압축하여 약 5MB였으므로 (배보다 배꼽이 심하게 큰 상태), 최종 배포 이미지의 크기는 약 70MB가 되어 너무 크다고 생각하여 크기를 줄여보기로 하였다.🤔

## Scratch 이미지 이용
Base 이미지를 scratch 이미지로 시작하면 내 마음대로(실제로 필요한 것들만으로) 구성할 수 있으므로, 크기를 가장 줄일 수 있는 궁극의 방법일 것이다.  
예를 들어 내가 짠 app를 upx로 압축하기 전에 ldd 툴로 사용하는 shared library를 확인하여 이것들을 구성하는 것이다.  
또는 프로그램을 shared libary를 사용하지 않는 static으로 빌드할 수도 있다. 이를 위하여 C 언어에서는 `--static` 옵션을 붙이면 되고, Go 언어에서는 아래와 같이 빌드시 `CGO_ENABLED=0`를 추가하고 `-a` 옵션을 붙여서, 빌드시 모든 의존 패키지를 cgo를 사용하지 않고 재빌드하도록 하면 된다.
```bash
$ CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -ldflags '-s'
```

그런데 이 방법은 shell을 띄울 수 없고 (물론 shell을 수동으로 추가하면 가능하겠지만), 테스트 부담이 많고, Dockerfile을 소스 저장소에 올리기에도 깔끔하지 않아서 제외시켰다.

## Alpine 이미지 이용
Alpine 이미지는 glibc 대신에 크기가 작은 muslc를 사용하고, shell과 tool도 크기가 작은 busybox로 대체한 이미지로, 크기는 약 5MB 정도이다.  
이 이미지를 이용할 수 있으면 좋겠지만, 불행히도 Go로 빌드한 app를 ldd 툴로 확인해보면 glibc를 사용하므로, 이것을 그대로 이용할 수는 없다.😢  

## Alpine glibc 이미지 이용
혹시나 alpine 이미지에 glibc를 추가한 이미지는 없는지 아래와 같이 찾아 보았더니, 역시나 나온다.
```bash
$ docker search alpine-glibc
```

대체로 이미지 구성은 alpine 이미지를 base로 하여, glibc 패키지를 설치하는 방식인 것 같았다.  
일단 아래와 같이 가장 많이 star를 받은 frolvlad/alpine-glibc 이미지를 받아서 크기를 확인해 보았다.
```bash
$ docker pull frolvlad/alpine-glibc
$ docker images frolvlad/alpine-glibc
REPOSITORY              TAG                 IMAGE ID            CREATED             SIZE
frolvlad/alpine-glibc   latest              f4da87f0a9f4        3 weeks ago         17.6MB
```

즉, 크기가 18MB가 안 되었다. 이 이미지를 base로 내 이미지를 빌드시켰더니, 최종 이미지 크기가 base 이미지가 작아진 크기만큼 줄어들었고, app도 정상적으로 실행되었다.  
이 정도에서 만족할까 하다가 좀 더 작은 이미지가 있는지 확인해 보니, 아래와 같이 `crownpeak/alpine-glibc` 이미지가 좀 더 작았다.
```bash
$ docker pull crownpeak/alpine-glibc
$ docker images crownpeak/alpine-glibc
REPOSITORY               TAG                 IMAGE ID            CREATED             SIZE
crownpeak/alpine-glibc   latest              144cc4c44885        2 years ago         11.5MB
```

다시 이것을 base 이미지로 하여 내 이미지를 빌드했더니 크기도 상응하게 줄었고, app도 정상적으로 동작하였다. 물론 alpine base이므로 shell도 잘 실행이 되었다. 몇 시간의 삽질 끝에 배포 이미지 크기가 엄청나게 줄어서 만족한다.😛
