---
title: "Docker 대체용 Podman 소개"
category: Docker
toc: true
toc_label: "이 페이지 목차"
---

Docker를 대체할 수 있는 Podman을 사용해 보자.

## Podman 특징
[Podman](https://podman.io/)은 2017년에 [Docker](https://www.docker.com/)가 엔터프라이즈 버전을 상용화하면서, Red Hat이 다른 컨테이너 오픈소스 기술인 Podman을 사용하여 Red Hat의 엔터프라이즈 제품들을 출시하였고, 2019년 3월에 릴리즈 한 RHEL 8에 Podman이 추가되었다.  
Docker와 Podman 둘 다 `OCI(Open Container Initiative)` 표준을 따르므로 Docker로 개발한 이미지를 Podman에서 그대로 사용 가능하다.

<br>
가장 큰 차이점은 Docker는 Docker daemon을 이용하지만, Podman은 daemon 없이 컨테이너를 실행하고, 따라서 루트 권한이 없는 사용자도 실행할 수 있다는 것이다. (libpod 라이브러리 사용)  
즉, Podman은 daemon 없이 커맨드로 컨테이너 레지스트리로부터 이미지를 받아와 Podman 호스트의 로컬 이미지 저장소에 이미지를 저장하고, 해당 이미지를 이용하여 컨테이너를 실행한다. 이때 Podman 라이브러리를 통해서 바로 컨테이너를 실행하기 때문에 컨테이너 간에 서로 영향을 주지 않으며, 커맨드 명령어로 컨테이너를 제어하거나 이미지를 관리할 때도 서로 영향을 주지 않는다.

## Podman 장점
Docker는 docker daemon에 모든 권한이 집중되다 보니 아무나 docker client로 docker daemon을 제어하지 못하도록 root 사용자만 docker client를 사용할 수 있도록 했다.  
이에 반해 Podman은 fork/exec 방식을 사용하여 개별 컨테이너를 실행시킬 수 있으므로 특별히 root 권한으로 실행해야 하는 작업이 아니라면 일반 사용자로도 실행할 수 있다.  
즉, Docker는 root 권한을 가진 사용자만 수행 가능하고 일반 사용자는 수행할 수가 없는데 반해, Podman은 일반 사용자도 수행 가능하고, 이에 따라 사용자 별로 각각의 컨테이너 환경을 구성할 수 있다는 것이 큰 장점이다.

## 설치
자세한 내용은 [Podman 설치](https://podman.io/getting-started/installation) 페이지를 참고한다.
1. Ubuntu 20.10 이상에서는 공식 저장소에서 지원하므로 아래와 같이 설치할 수 있다.
   ```shell
   $ sudo apt install podman
   ```
1. Ubuntu 20.04 이하에서는 아래 예와 같이 설치할 수 있다. (아래 예에서는 20.04인 경우)
   ```shell
   $ echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_20.04/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
   $ curl -L "https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_20.04/Release.key" | sudo apt-key add -
   $ sudo apt update
   $ sudo apt upgrade
   $ sudo apt install podman
   ```
1. CentOS 8에서는 기본 제공되므로 아래와 같이 설치할 수 있다.
   ```shell
   $ sudo yum install podman
   ```
1. CentOS 7인 경우에는 아래와 같이 kubic project 저장소를 등록해서 설치할 수 있다.
   ```shell
   $ sudo curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/CentOS_7/devel:kubic:libcontainers:stable.repo
   $ sudo yum install podman
   ```
1. 버전 확인
   ```shell
   $ podman version
   ```
1. 정보 확인
   ```shell
   $ podman info
   ```

## 간단 테스트
대략적인 사용법은 docker와 상당히 유사하므로 본 블로그에는 생략한다.  
아래 테스트와 같이 Docker와 사용법이 동일하므로 쉽게 적응되었다.
1. 아래와 같이 Ubuntu 18.04 이미지를 다운로드 한다.
   ```shell
   $ podman pull ubuntu:18.04
   ```
1. 아래와 같이 전체 Podman 이미지를 확인할 수 있다.
   ```shell
   $ podman images
   ```
1. 아래와 같이 ubuntu:18.04 이미지로 ubuntu_container 이름의 컨테이너를 생성한다.
   ```shell
   $ podman run -it --name ubuntu_container ubuntu:18.04
   ```
1. 아래와 같이 전체 컨테이너 정보를 출력해 볼 수 있다.
   ```shell
   $ podman ps -a
   ```
1. 아래와 같이 컨테이너를 재실행시킬 수 있다.
   ```shell
   $ podman restart ubuntu_container
   ```
   이제 아래와 같이 active 컨테이너를 확인해 보면, ubuntu_container 컨테이너가 up 상태로 나옴을 확인할 수 있다.
   ```shell
   $ podman ps
   ```
1. 다시 아래와 같이 실행 중인 ubuntu_container 컨테이너에 attach 할 수 있다.
   ```shell
   $ podman attach ubuntu_container
   ```
1. 아래와 같이 ubuntu_container 컨테이너를 삭제할 수 있다.
   ```shell
   $ podman rm ubuntu_container
   ```
1. 아래와 같이 ubuntu:18.04 이미지를 삭제할 수 있다.
   ```shell
   $ podman rmi ubuntu:18.04
   ```

## 기타 팁
- 컨테이너를 privileged 모드로 실행하고 싶으면 아래와 같이 run 시 `--privileged` 옵션을 추가하면 된다.
  ```shell
  $ podman run -it --privileged
  ```
- Host 볼륨 (예: /home/userid/) 마운트시 root 권한으로 마운트되어 write가 안 되는 문제는, 컨테이너 생성시 아래 예와 같이 `--userns=keep-id --user=$(id -ur):$(id -gr)` 옵션을 추가하면 된다. (이 방법을 알아내기 위해서 고생 좀 했음 😓)
  ```shell
  $ podman run --name my_container -it -v /home/$USER:/home/$USER --userns=keep-id --user=$(id -ur):$(id -gr)
  ```
- 아래와 같이 컨테이너의 현재 상태를 파일로 압축할 수 있다.
  ```shell
  $ podman container checkpoint <container_id> -e <파일.tar.gz>
  ```
- 아래와 같이 파일로부터 컨테이너를 복원할 수 있다.
  ```shell
  $ podman container restore -i <파일.tar.gz>
  ```

## Podman으로 빌드 환경 구성 예
1. 아래와 같이 `Dockerfile`을 작성하였다. (Docker 이미지 생성시에 사용한 내용과 동일함)
   ```Dockerfile
   # Use Ubuntu 18.04 as base image
   FROM ubuntu:18.04
   
   # Environment
   ENV DEBIAN_FRONTEND=noninteractive LC_ALL=ko_KR.utf8 LANG=ko_KR.utf8 LANGUAGE=ko_KR.UTF-8 LC_CTYPE=ko_KR.UTF-8
   
   # Update
   RUN apt-get update && apt-get install -y apt-utils
   
   # Install and set locale
   RUN LC_ALL=C apt-get install -y language-pack-ko
   RUN locale-gen ko_KR.UTF-8 && update-locale && dpkg-reconfigure locales
   
   # Support 32bit because of 32bit cross-toolchain
   RUN dpkg --add-architecture i386 && apt-get update && apt-get install -y libc6:i386 libstdc++6:i386 zlib1g:i386
   
   # Set time zone
   RUN ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime && (echo "6"; echo "69")
   
   # Install packages
   RUN apt-get install -y tcl dialog net-tools iputils-ping lsb-release libssl-dev build-essential vim make g++ patch wget cpio python python3 unzip rsync bc git subversion autoconf gettext m4 flex bison gperf gengetopt gawk ninja-build libtool curl pkg-config intltool libglib2.0-dev-bin protobuf-compiler libboost-all-dev libcap-dev
   
   # Install recent cmake
   RUN wget -q https://github.com/Kitware/CMake/releases/download/v3.22.1/cmake-3.22.1-linux-x86_64.sh && sh cmake-3.22.1-linux-x86_64.sh --skip-license --prefix=/usr && rm cmake-3.22.1-linux-x86_64.sh
   
   # Set default shell to bash
   RUN rm /bin/sh && ln -s /bin/bash /bin/sh
   
   # Create container user with host user's information
   ARG user
   ARG uid
   ARG gid
   RUN groupadd -g ${gid} ${user} && useradd -u ${uid} -g ${gid} ${user}
   
   # Run with user privilege
   USER ${user}
   WORKDIR /home/${user}
   ```
1. 아래와 같이 이미지를 빌드한다. (이미지 이름은 **build_image**로 함)
   ```shell
   $ podman build --tag build_image --build-arg user=$USER --build-arg uid=$(id -u) --build-arg gid=$(id -g) .
   ```
1. 아래와 같이 컨테이너를 생성한다. (컨테이너 이름은 **build_container**로 함, 빌드시에 사용되는 시스템 디렉토리와 사용자 home 디렉토리를 볼륨으로 마운트함)
   ```shell
   $ podman run --name build_container -it \
       -v /opt/crosstools/:/opt/crosstools/ \
       -v /opt/nfs/$USER/:/opt/nfs/$USER/ \
       -v /tftpboot/$USER/:/tftpboot/$USER/ \
       -v /home/$USER/:/home/$USER/ --userns=keep-id --user=$(id -ur):$(id -gr) \
       --net=host build_image
   ```
   컨테이너가 생성된 후, 자동으로 시작된다. 컨테이너를 종료하려면 `exit` 명령을 실행하거나 Ctrl+D를 누르면 된다.
1. 컨테이너 재시작 및 터미널 접속은 아래와 같이 하면 된다.
   ```shell
   $ podman restart build_container
   $ podman attach build_container
   ```

>위에서 보듯이 Podman CLI 명령은 Docker와 상당히 유사하다. (위의 예에서 유일한 차이점은 사용자 home 디렉토리를 볼륨으로 마운트시에 디폴트로 root 권한으로 설정된다는 것이었는데, 이것은 위의 예에서 보듯이 `--userns=keep-id --user=$(id -ur):$(id -gr)` 옵션을 추가로 주어서 해결할 수 있었다)

## 사용 후기
Docker는 root나 docker 권한이 있어야지만 실행할 수 있어서 불편한 점이 많았다. 예를 들어 특정 사용자들에게 docker 그룹 권한을 주면 다른 사람이 만든 이미지나 컨테이너도 멈추거나 삭제할 수 있게 되는 불편함이 있었다.  
이에 반해 Podman은 사용자 권한으로도 모든 것을 할 수 있고, 각 사용자 별로 분리가 되므로 (다른 사람의 컨테이너를 조작 못함) 사용성이 아주 좋았다.  
아직 Podman은 Docker에 비해 기능이나 툴, 안정성 등이 부족한 점이 있긴 하지만 이런 점들도 점점 나아지고 있어서 점차 Docker를 대체할 수 있을 것 같다.
