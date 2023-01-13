---
title: "Docker 컨테이너 환경에서 소스 빌드하기"
category: Docker
toc: true
toc_label: "이 페이지 목차"
---

Docker 컨테이너 환경에서 소스 빌드 환경을 구축하였고, 간단히 기록을 남긴다.

<br>
참고로 본 글에서는 Dockerfile을 이용한 빌드 환경 구축에 집중하기 위하여, 의도적으로 Docker compose를 이용하지는 않았다. (Docker compose를 이용하면 Docker start, run 등의 명령을 아주 간단하게 실행시킬 수 있다)

## 동기
회사에서 Linux를 설치해서 가끔 사용하던 데스크탑을 우분투 20.04로 새로 설치하였다. 그런데 회사 프로젝트 소스를 빌드하려고, 필요한 모든 패키지를 설치한 후에 빌드를 해 보았더니, 빌드시 여러 open source 들에서 우분투 18.04에서는 발생하지 않았던 컴파일 에러들이 발생하였다.  
구글링을 해 보니, 대부분 host gcc 버전 관련해서 문제가 있는 것 같았다. (실제로 buildroot에 포함된 문제가 발생한 패키지들의 버전을 확인해 보니 오래된 버전들이었고, 테스트로 몇몇 패키지들을 최신 버전으로 업데이트했더니, 해당 빌드 에러가 발생하지 않았다)

<br>
그런데 이것 때문에 host gcc 버전을 바꾸거나 (물론 update-alternative 방법으로 바꿀 수는 있지만 원하는 방향이 아님) open source 들의 버전을 변경하거나 새로 설치한 우분투 20.04를 뒤집기는 싫어서, 간단히 <mark style='background-color: #ffdce0'>Docker</mark>를 이용해서 빌드 환경을 구성하기로 하였다.

## Dockerfile 구성
아래 내용과 같이 `Dockerfile`을 구성하였다. 각각 주석을 달았으므로 쉽게 이해할 수 있을 것이다.  
간단히 종합해 보면, 먼저 우분투 18.04를 base로 하고, 사용하는 cross-toolchain이 32bit base인 관계로 32bit를 지원하게 만들고, 소스 빌드에 필요한 패키지를 설치한다. 이후 shell을 dash에서 bash로 변경해 준다. 그 다음에 빌드 아규먼트로 받은 유저 정보로 유저를 생성하고, 유저 권한으로 shell을 실행시킨다.
> 물론 유저 권한을 사용하는 대신에 root 권한으로도 빌드할 수 있으나, 이 경우에는 빌드 결과로 생성되는 파일들도 root 권한을 갖게 되어, 호스트에서 삭제 등을 할 수 없게 되는 불편함이 있다.

```Dockerfile
# Use Ubuntu 18.04 as base image
FROM ubuntu:18.04

# Support 32bit because of 32bit cross-toolchain
RUN dpkg --add-architecture i386
RUN apt-get update
RUN apt-get install -y apt-utils libc6:i386 libstdc++6:i386 zlib1g:i386

# Install needed package for source build
RUN apt-get install -y net-tools iputils-ping libssl-dev vim make g++ patch wget cpio python unzip rsync bc git subversion autoconf gettext m4 gperf
RUN ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime && (echo "6"; echo "69") | apt-get install -y tcl

# Change dash to bash
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Create container user with host user's information
ARG user uid gid
RUN groupadd -g ${gid} ${user} && useradd -m -u ${uid} -g ${gid} ${user}

# Run with user privilege
USER ${user}
WORKDIR /home/${user}
```

## Docker 이미지 생성
Dockerfile을 만들었으므로, 이제 Dockerfile이 있는 경로에서 아래와 같이 실행하면 **build_image** 이름의 Docker 이미지가 생성된다. (호스트에서의 유저의 user 이름, user id, group id 정보를 그대로 빌드 아규먼트로 넘김)
```shell
$ docker build --tag build_image --build-arg user=$USER --build-arg uid=$(id -u) --build-arg gid=$(id -g) .
```

실행이 끝나면 아래와 같이 확인해 볼 수 있다.
```shell
$ docker images build_image
REPOSITORY    TAG       IMAGE ID       CREATED         SIZE
build_image   latest    0d04150164f9   14 seconds ago  493MB
```

## Docker 컨테이너 생성
이제 **build_image** 이름의 Docker 이미지가 생성되었으므로, 아래 예와 같이 **build_container** 이름의 Docker 컨테이너를 생성할 수 있다.
```shell
$ docker run --name build_container -it -v /home/$USER/:/home/$USER/ -v /opt/nfs/$USER/:/opt/nfs/$USER/ --net=host build_image
```
> 위 예에서는 사용자 디렉토리 전체를 컨테이너에서 동일 경로로 공유하였고, 호스트 유저의 NFS 디렉터리를 추가로 공유하였다.  
> 또, 호스트의 `/etc/hosts` 파일을 그대로 사용하기 위해서 `--net=host` 아규먼트를 주어서 호스트 네트워크를 사용하게 했다. (또는 이 방법 대신에 `--add-host` 아규먼트를 이용하여 원하는 alias와 IP를 추가해도 됨)

결과로 Docker 컨테이너가 생성된 후에 자동으로 실행되고, 컨테이너의 shell 프롬프트가 표시된다.  
여기에서 `id` 명령으로 유저 정보를 확인해 보면, 호스트에서의 유저 정보와 동일하게 유저가 생성되었음을 확인할 수 있다.  
심지어 유저 이름까지 똑같으므로 내가 호스트 시스템에 있는지, 컨테이너 내에 있는지조차 헷갈릴 수 있다. 😵  
이제 컨테이너에서 해당 프로젝트 디렉토리로 이동하여 빌드를 하면 된다.

> Docker의 강력함으로 인해, 간혹 컨테이너에서 실행 중인지조차 인지하지 못할 때가 있다. 이런 경우에 혼돈을 막으려면 아래 예와 같이 Docker 이미지를 생성할 때, `user` 세팅값으로 컨테이너 상의 유저 이름을 다른 이름으로 (아래 예에서는 **container** 사용) 세팅할 수 있다.
> ```shell
> $ docker build --tag build_image --build-arg user=container --build-arg uid=$(id -u) --build-arg gid=$(id -g) .
> ```
> 물론 표시되는 이름만 다르고 실제 uid, gid는 동일하므로, 컨테이너 밖에서는 원래 사용자로 올바르게 보인다.

## Docker 컨테이너 종료
컨테이너에서 빌드 작업이 완료되었으면 아래와 같이 `exit` 명령을 실행하면 컨테이너가 종료된다.
```shell
$ exit
```

빌드된 결과 파일들을 확인해 보면, 기대대로 호스트에서의 내 uid, gid와 동일한 유저로 생성되므로, Docker를 사용하지 않았을 때와 동일하게 본인 유저 권한으로 빌드되었음을 알 수 있다. 😋

<br>

참고로 이때 Docker 컨테이너 상태를 확인해 보면, 아래 예와 같이 나온다. (즉, 컨테이너가 중단된 상태)
```shell
$ docker ps -a
CONTAINER ID   IMAGE         COMMAND   CREATED             STATUS                     PORTS     NAMES
e96029e37ddb   build_image   "bash"    About an hour ago   Exited (0) 4 seconds ago             build_container
```

## Docker 컨테이너 재실행
소스가 수정되어 다시 빌드를 하려면 아래와 같이 컨테이너를 재실행한다.
```shell
$ docker restart build_container
```

이때 Docker 컨테이너 상태를 확인해 보면, 아래 예와 같이 나온다. (즉, 실행 중인 상태)
```shell
$ docker ps
CONTAINER ID   IMAGE         COMMAND   CREATED             STATUS         PORTS     NAMES
e96029e37ddb   build_image   "bash"    About an hour ago   Up 5 seconds             build_container
```

그런데 빌드를 하기 위해서는 커맨드 프롬프트를 얻어야 하므로, 이후 아래와 같이 컨테이너에 attach 시키면 컨테이너의 프롬프트를 얻을 수 있다.
```shell
$ docker attach build_container
```

이제 컨테이너의 커맨드 프롬프트를 얻었으므로, 다시 빌드를 수행할 수 있다. 빌드를 마쳤으면 다시 `exit` 명령으로 컨테이너를 빠져 나올 수 있다.

## Docker 컨테이너 삭제
Docker 컨테이너가 더 이상 필요하지 않으면, 아래와 같이 삭제할 수 있다.
```shell
$ docker rm build_container
```

## Docker 이미지 삭제
Docker 이미지도 더 이상 필요하지 않으면, 아래와 같이 삭제할 수 있다.
```shell
$ docker rmi build_image
```

## 결론
Docker 덕분에 빠르고 간단하게 개발 환경을 구성할 수 있었다. 물론 Docker를 사용한 덕분에 성능상의 하락도 거의 없다. 역시 Docker는 너무 좋다. 😍
