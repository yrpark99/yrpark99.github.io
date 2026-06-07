---
title: "Docker rootless 모드"
category: [Docker]
toc: true
toc_label: "이 페이지 목차"
---

Docker rootless 모드를 간략히 소개한다.

## Docker 최신 버전으로 설치하기
Ubuntu에서 docker가 설치되지 않았거나 최신 버전으로 설치하려면 [Install Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/) 페이지를 참고하여 아래와 같이 설치한다.
1. 기존 버전이 설치되어 있으면 아래와 같이 기존 Docker 패키지를 제거한다.
   ```sh
   $ sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc | cut -f1)
   ```
1. 이후 아래와 같이 APT 저장소를 설정한다.
   ```sh
   $ sudo apt update
   $ sudo apt install ca-certificates curl
   $ sudo install -m 0755 -d /etc/apt/keyrings
   $ sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
   $ sudo chmod a+r /etc/apt/keyrings/docker.asc

   $ sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
   > Types: deb
   > URIs: https://download.docker.com/linux/ubuntu
   > Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
   > Components: stable
   > Architectures: $(dpkg --print-architecture)
   > Signed-By: /etc/apt/keyrings/docker.asc
   > EOF

   $ sudo apt update
   ```
1. 이제 아래와 같이 설치할 수 있다.
   ```sh
   $ sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
   ```
1. Docker가 실행 중이 아니면 아래와 같이 start 시킨다.
   ```sh
   $ sudo systemctl start docker
   ```
   이제 아래와 같이 확인시 docker가 "active (running)" 상태로 표시된다.
   ```sh
   $ sudo systemctl status docker
   ```

## Docker rootlful mode의 위험성
Docker는 기본적으로 root 권한을 사용하는데 (docker 그룹), 이에 따른 여러 보안 이슈가 있다.  
예를 들어 docker 그룹에 속한 모든 사용자들은 다른 사용자가 만든 docker 이미지와 컨테이너를 볼 수도 있고, 원하면 중지/삭제시킬 수도 있다.  
또, 아래와 같이 `--privileged` 아규먼트를 주어서 컨테이너를 생성하면, host 시스템 전체를 root 권한으로 실행시킬 수 있게 된다.
```sh
$ docker run -v /:/mnt --rm -it --privileged alpine chroot /mnt sh
```
예를 들어 아래와 같이 /home/ 디렉토리에 root 권한으로 디렉토리를 생성할 수도 있다.
```rust
sh-4.4# mkdir /home/iamroot
sh-4.4# exit
```
이제 host 환경에서 확인해 보면, 실제로 root 권한으로 /home/iamroot/ 디렉토리가 생성된 것을 확인할 수 있다. (즉, root 권한으로 시스템의 모든 파일/디렉토리에 대한 액세스가 가능함)  
또한 원하면 간단히 프로그램을 짜서 root shell을 획득할 수도 있다.  
<br>

이런 Docker의 보안 문제점 때문에 경쟁사에서 [Podman](https://podman.io/)을 출시했었는데, Docker에서도 20.10 버전부터 정식으로 rootless 모드를 지원한다.

## Docker rootless mode
Docker rootless mode에 대해서는 dockerdocs의 [Rootless mode](https://docs.docker.com/engine/security/rootless/) 페이지를 참고한다.  
Docker rootless mode는 일반 사용자 권한으로 Docker 데몬과 컨테이너를 실행하여 데몬과 컨테이너 런타임의 잠재적인 취약성을 완화할 수 있다. 실제로 rootless mode는 Docker 데몬과 컨테이너를 user namespace에서 실행시키므로 사용자별(user-scoped) docker이다.  
<br>

Docker rootless mode를 설치하기 위한 사전 조건으로 **newuidmap**, **newgidmap** 툴이 필요하므로, 만약 아직 설치되지 않은 상태이며 아래와 같이 설치한다.
```sh
$ sudo apt install uidmap
```

참고로 만약에 더이상 rootful 모드를 사용하지 않으려면 아래와 같이 disable 시킬 수 있다. (옵션 사항)
```sh
$ sudo systemctl disable --now docker.service docker.socket
$ sudo rm /var/run/docker.sock
```
<br>

이제 아래와 같이 설치할 수 있다.
1. **/usr/bin/dockerd-rootless-setuptool.sh** 파일이 있는지 확인한다. (단, docker-ce 특정 버전 이상부터 있음)  
   있으면 아래와 같이 dockerd-rootless-setuptool.sh 스크립트를 실행시키면 설치된다.
   ```sh
   $ dockerd-rootless-setuptool.sh install
   ```
   없는 경우에는 과거 버전의 Docker가 설치된 경우인데, 이때는 위 방법 대신에 아래와 같이 설치할 수 있다.
   ```sh
   $ sudo systemctl disable docker
   $ sudo systemctl disable docker.socket
   $ sudo systemctl stop docker
   $ sudo systemctl stop docker.socket
   $ export FORCE_ROOTLESS_INSTALL=1
   $ curl -fsSL https://get.docker.com/rootless | sh
   ```
1. 설치가 끝나면 마지막 부분에 아래와 같이 context가 "**rootless**"로 변경되었다는 로그를 확인할 수 있다.
   ```sh
   [INFO] Installed docker.service successfully.
   [INFO] To control docker.service, run: `systemctl --user (start|stop|restart) docker.service`
   [INFO] To run docker.service on system startup, run: `sudo loginctl enable-linger {USER}`

   [INFO] Creating CLI context "rootless"
   Successfully created context "rootless"
   [INFO] Using CLI context "rootless"
   Current context is now "rootless"

   [INFO] Make sure the following environment variable(s) are set (or add them to ~/.bashrc):
   export PATH=/usr/bin:$PATH

   [INFO] Some applications may require the following environment variable too:
   export DOCKER_HOST=unix:///run/user/{UID}/docker.sock
   ```
1. 아래와 같이 "docker info" 명령시 Context 값에 "default" 대신에 "**rootless**"가 출력되면 docker 클라이언트가 rootless 데몬에 성공적으로 연결된 것이다.
   ```sh
   $ docker info
   ```
   또, 아래와 같이 context 정보만 확인하면 아래와 같이 "default"가 아닌 "**rootless**"가 선택되었고, docker.sock 경로도 rootful 모드시 사용되는 "/var/run/docker.sock"가 아닌 "/run/user/{UID}/docker.sock" 경로로 설정된 것을 확인할 수 있다.
   ```sh
   $ docker context ls
   NAME         DESCRIPTION                               DOCKER ENDPOINT                     ERROR
   default      Current DOCKER_HOST based configuration   unix:///var/run/docker.sock
   rootless *   Rootless mode                             unix:///run/user/{UID}/docker.sock
   ```

이제부터는 docker는 (docker 그룹에 속하지 않은) 일반 사용자 권한으로도 정상적으로 실행되는 것을 확인할 수 있다.  
<br>

다른 사용자들도 사용자마다 본인이 직접 아래와 같이 설치하여 rootless 모드를 활성화시켜야 한다.
> 주의: 만약에 root 사용자가 `"sudo su - {USER}"` 명령으로 사용자 계정으로 로그인하여 대신 설치해 주려는 경우에는, 로그인 후에 아래와 같이 XDG_RUNTIME_DIR 환경 변수를 설정한 이후에 설치를 진행해야 한다.
> ```sh
> $ export XDG_RUNTIME_DIR=/run/user/$UID
> ```

아래와 같이 스크립트를 실행한다.
```sh
$ dockerd-rootless-setuptool.sh install
```
또는
```sh
$ curl -fsSL https://get.docker.com/rootless | sh
```
이후 확인하면, 아래와 같이 성공적으로 rootless 모드로 전환된 것을 확인할 수 있다.
```sh
$ docker context ls
NAME         DESCRIPTION                               DOCKER ENDPOINT                     ERROR
default      Current DOCKER_HOST based configuration   unix:///var/run/docker.sock
rootless *   Rootless mode                             unix:///run/user/{UID}/docker.sock
```
만약에 docker 명령 실행시 docker.sock 파일을 찾을 수 없다고 나오면 이 소켓 파일의 설정된 경로가 `"systemctl --user status docker"` 명령의 결과와 다르기 때문이다. 이 경우에는 (`"sudo su"` 명령으로 로그인한 경우에는 위에서 언급한 바와 같이 `XDG_RUNTIME_DIR` 환경 변수를 설정한 후에) 아래와 같이 rootless context를 삭제한 후에 다시 설치하면 된다.
```sh
$ docker context rm rootless -f
$ dockerd-rootless-setuptool.sh install
```
결과로 **/run/user/{UID}/docker.sock** 소켓 파일이 생성되고, 이제부터 정상적으로 docker 명령이 실행된다.

## Docker rootless 모드 테스트
Rootless 모드에서 테스트로 다시 아래와 같이 실행해 보자.
```sh
$ docker run -v /:/mnt --rm -it --privileged alpine chroot /mnt sh
```

위에서와 마찬가지로 /home/ 디렉토리에 디렉토리를 생성해 보면, 이번에는 아래와 같이 실패함을 확인할 수 있다.
```java
# mkdir /home/iamroot
mkdir: cannot create directory '/home/iamroot': Permission denied
```
물론 본인의 home 경로에 있는 디렉토리나 파일들은 정상적으로 액세스된다.  
<br>

사용자들은 각자 rootless 모드로 Docker 이미지와 컨테이너를 생성할 수 있고, 다른 사용자의 Docker 이미지와 컨테이너를 볼 수는 없다. 또한 위의 테스트에서 본 것 처럼 `--privileged` 아규먼트를 주어도 실제로 host의 root 권한으로 실행되지는 않으므로, 보안적으로도 안전함을 확인할 수 있다.

## Docker 모드 전환하기
보안이 중요한 멀티유저 서버인 경우에는 rootless Docker를 사용하고, rootful과 rootless가 둘 다 필요한 경우에는 둘 다 설치한 후에 필요에 따라 docker context로 전환할 수 있다.  
즉, Docker rootful과 rootless 모드는 사용자의 필요에 따라서 아래와 같이 전환할 수 있다.
- **Rootful** 모드로 전환하려면 아래와 같이 할 수 있다.
  ```sh
  $ docker context use default
  ```
  아래와 같이 확인해 볼 수 있다.
  ```sh
  $ docker context show
  default
  ```
- **Rootless** 모드로 전환하려면 아래와 같이 할 수 있다.
  ```sh
  $ docker context use rootless
  ```
  아래와 같이 확인해 볼 수 있다.
  ```sh
  $ docker context show
  rootless
  ```
