---
title: "Docker 기본 사용법"
category: Docker
toc: true
toc_label: "이 페이지 목차"
---

추후 참조를 위하여 Docker(도커)의 기본적인 사용법을 간단히 정리한다.

## Docker 설치
우분투에서는 아래와 같이 설치할 수 있다.
```sh
$ sudo apt install docker.io
```

편의상 docker 명령시에 sudo 명령을 생략할 수 있도록 아래와 같이 docker 그룹에 추가한다.
```sh
$ sudo usermod -aG docker $(whoami)
```
이제 다시 로그인을 하면 sudo와 암호 입력없이 `docker` 명령을 사용할 수 있다.

설치된 Docker 버전은 다음과 같이 확인할 수 있다.
```sh
$ docker -v
```

## Docker 도움말 보기
아래와 같이 옵션없이 실행하면 전체 명령에 대한 간략한 도움말이 출력된다.
```sh
$ docker
```

각 command에 대하여 세부 사용법을 보고 싶으면, 아래와 같이 실행하면 된다.
```sh
$ docker {command} --help
```

예를 들어 아래와 같이 실행하면 도커 이미지 관련 전체 명령 목록과 간단한 설명이 출력된다.
```sh
$ docker image --help
```
또 **image** 명령의 특정 sub-command에 대한 자세한 도움말은 아래와 같이 얻을 수 있다.
```sh
$ docker image <sub-command> --help
```

마찬가지로 아래와 같이 실행하면 도커 컨테이너 관련 전체 명령 목록과 간단한 설명이 출력된다.
```sh
$ docker container --help
```
또 **container** 명령의 특정 sub-command에 대한 자세한 도움말은 아래와 같이 얻을 수 있다.
```sh
$ docker container <sub-command> --help
```

> 참고로 위에서 사용한 `image`와 `container` 명령은 생략 가능한 경우가 많으며, 이하 글에서도 가능한 경우에는 편의상 생략하였다.

## Docker 이미지 검색
도커 이미지는 [Docker Hub](https://hub.docker.com/)에서 검색할 수 있다. 또는 아래와 같이 docker search 명령으로도 검색할 수 있다.
```sh
$ docker search [옵션] <이미지명>
```
결과는 STARS(인기) 순으로 나열된다. 참고로 이미지명은 공식 이미지인 경우에는 사용자명 없이 이미지명만 있고, 공식 이미지가 아닌 경우에는 사용자명/이미지명으로 구성된다.

## Docker 이미지 다운로드
도커 이미지는 docker pull 명령으로 (디폴트로) docker hub에서 다운받을 수 있다. 만약 docker hub가 아닌 별도의 저장소에서 받고 싶다면 이미지명 앞에 해당 URL을 지정하면 된다.  
커맨드 형식은 다음과 같다. (태그명을 생략하면 디폴트로 `latest`로 지정됨)
```sh
$ docker pull [옵션] <이미지명>[:태그명]
```

## Dockerfile로 Docker 이미지 빌드하기
`Dockerfile` 파일을 사용하여 도커 이미지를 생성하려면 아래와 같이 실행한다.
```sh
$ docker build [옵션] <Dockerfile 경로>
```
주요 옵션에는 다음과 같은 것들이 있다.
* `--net=host`: 호스트 네트워크 환경을 그대로 사용
* `-t <태그명>`: 이미지 태그를 지정함 (지정하지 않으면 자동으로 `latest`로 지정됨)

## 설치된 Docker 이미지 목록
시스템에 설치된 도커 이미지 목록은 아래와 같이 실행하면 출력된다.
```sh
$ docker images [옵션] [이미지명][:태그명]
```
예를 들어 아래와 같이 실행하면 해당 이미지명의 모든 태그 목록이 출력된다.
```sh
$ docker images [이미지명]
```

## Docker 이미지 상세 정보
설치된 도커 이미지의 상세 정보는 아래와 같이 얻을 수 있다.
```sh
$ docker inspect [옵션] <이미지명[:태그명] | 이미지 ID>
```

## Docker 이미지 history 보기
아래와 같이 실행하면 도커 이미지의 history를 볼 수 있다. (`Dockerfile` 파일로 Docker 이미지를 빌드했던 과정과 유사하게 출력됨)
```sh
$ docker history [옵션] <이미지명[:태그명] | 이미지 ID>
```

## Docker 이미지 삭제
도커 이미지는 다음과 같이 삭제할 수 있다.
```sh
$ docker rmi [옵션] <이미지명[:태그명] | 이미지 ID>
```
주요 옵션에는 다음과 같은 것들이 있다.
* `-t`: 강제로 이미지 삭제

만약에 이미지명은 동일한데 태그가 다른 이미지가 여러개 있는 경우에, 아래와 같이 이미지명만 지정하면 동일 이미지명의 다른 태그를 가진 모든 이미지들이 삭제된다.
```sh
$ docker rmi [옵션] <이미지명>
```

## 컨테이너 생성
Docker 컨테이너는 다음과 같이 `create` 명령으로 생성할 수 있다.
```sh
$ docker create [옵션] <이미지명>[:태그명] [명령] [명령 옵션]
```
주요 옵션에는 다음과 같은 것들이 있다.
* `--env=[환경변수]`: 환경변수 설정
* `--link <컨테이너명>:<별칭>`: 다른 컨테이너를 연결 (예: DB)
* `--name <이름>`:  컨테이너의 이름을 지정 (이름을 지정하지 않으면 docker가 자동으로 이름을 생성하여 지정함)
* `--network <네트워크 이름>`: 컨테이너를 입력 Docker 네트워크에 연결
* `--restart <no | on-failure | always>`: 컨테이너 종료시 재시작 정책
* `--rm`: 동일 이름의 컨테이너가 이미 존재하면 기존 컨테이너를 삭제하고 생성
* `-i`: 컨테이너의 interactive shell을 얻음
* `-p <호스트 포트 번호>:<컨테이너 포트 번호>`: 호스트 포트 번호를 컨테이너 포트 번호로 매핑
* `-t`: 컨테이너의 shell에 pseudo-TTY를 할당
* `-u <name | uid>`: 컨테이너의 커맨드를 실행할 유저 이름이나 유저 ID
* `-v <호스트 디렉토리>:<컨테이너 디렉토리>`: 호스트 디렉토리 공유
* `-w <디렉토리>`: 컨테이너의 작업 디렉토리 지정

## 컨테이너 생성 및 시작
아래 형식으로 컨테이너를 생성하고 바로 실행시킬 수 있다. (만약에 아직 컨테이너가 생성되지 않은 상태이면 생성한 후 실행함)
```sh
$ docker run [옵션] <이미지명[:태그명] | 이미지 ID> [명령] [명령 옵션]
```
주요 옵션에는 다음과 같은 것들이 있다.
* `--env=[환경변수]`: 환경변수 설정
* `--link <컨테이너명>:<별칭>`: 다른 컨테이너를 연결 (예: DB)
* `--name <이름>`:  컨테이너의 이름을 지정 (이름을 지정하지 않으면 docker가 자동으로 이름을 생성하여 지정함)
* `--network <네트워크 이름>`: 컨테이너를 입력 Docker 네트워크에 연결
* `--restart <no | on-failure | always>`: 컨테이너 종료시 재시작 정책
* `--rm`: 컨테이너 종료시 자동으로 컨테이너를 삭제시킴
* `-d`: 컨테이너를 백그라운드에서 실행
* `-i`: 컨테이너의 interactive shell을 얻음
* `-p <호스트 포트 번호>:<컨테이너 포트 번호>`: 호스트 포트 번호를 컨테이너 포트 번호로 매핑
* `-t`: 컨테이너의 shell에 pseudo-TTY를 할당
* `-u <name | uid>`: 컨테이너의 커맨드를 실행할 유저 이름이나 유저 ID
* `-v <호스트 디렉토리>:<컨테이너 디렉토리>`: 호스트 디렉토리 공유
* `-w <디렉토리>`: 컨테이너의 작업 디렉토리 지정

## 컨테이너 목록 보기
현재 실행 중인 컨테이너의 목록은 아래와 같이 얻을 수 있다.
```sh
$ docker ps [옵션]
```
실행 중이 아닌 컨테이너의 목록까지 얻으려면 `-a` 옵션을 추가하면 된다.  
참고로 위에서 **ps** 명령 대신에 **container ls** 명령을 사용해도 된다.

## 컨테이너 시작
아래와 같이 정지한 컨테이너를 시작시킬 수 있다.
```sh
$ docker start [옵션] <컨테이너명 | 컨테이너 ID>
```
주요 옵션에는 다음과 같은 것들이 있다.
* `-i`: 컨테이너의 interactive shell을 얻음

## 실행 중인 컨테이너에 접속
아래와 같이 실행 중인 컨테이너에 접속할 수 있다.
```sh
$ docker attach [옵션] <컨테이너명 | 컨테이너 ID>
```

## 컨테이너 안의 명령 실행
직접 컨테이너의 명령을 실행하려면 다음과 같이 하면 된다.
```sh
$ docker exec [옵션] <컨테이너명 | 컨테이너 ID> <명령> [명령 옵션]
```
주요 옵션에는 다음과 같은 것들이 있다.
* `-i`: 컨테이너의 interactive shell을 얻음
* `-t`: 컨테이너의 shell에 pseudo-TTY를 할당

## Host와 컨테이너 간의 파일/디렉토리 복사
호스트에서 컨테이너로 파일이나 디렉토리 복사는 아래와 같이 할 수 있다.
```sh
$ docker cp [옵션] <host 경로> <컨테이너명 | 컨테이너 ID>:<컨테이너 경로>
```
마찬가지로 컨테이너에서 호스트로 파일이나 디렉토리 복사는 아래와 같이 할 수 있다.
```sh
$ docker cp [옵션] <컨테이너명 | 컨테이너 ID>:<컨테이너 경로> <host 경로>
```

## 컨테이너 중지
실행 중인 컨테이너는 아래와 같이 강제로 중지시킬 수 있다.
```sh
$ docker stop [옵션] <컨테이너명 | 컨테이너 ID>
```

## 컨테이너 재시작
중지된 컨테이너는 아래와 같이 재시작시킬 수 있다.
```sh
$ docker restart [옵션] <컨테이너명 | 컨테이너 ID>
```
참고로 컨테이너가 종료되는 경우에 자동으로 다시 컨테이너를 시작시키고 싶으면 docker run 명령시 `--restart=always` 옵션을 추가하면 된다.

## 컨테이너 상세 정보
컨테이너의 상세 정보는 아래와 같이 얻을 수 있다.
```sh
$ docker inspect [옵션] <컨테이너명 | 컨테이너 ID>
```

## 컨테이너 리소스 사용량 보기
아래와 같이 stats 명령을 이용하면 실행 중인 컨테이너의 CPU, 메모리, 네트워크 사용률 등의 정보를 볼 수 있다.
```sh
$ docker stats [옵션] <컨테이너명 | 컨테이너 ID>
```

## 컨테이너 삭제
컨테이너는 다음과 같이 삭제할 수 있다.
```sh
$ docker rm [옵션] <컨테이너명 | 컨테이너 ID>
```
주요 옵션에는 다음과 같은 것들이 있다.
* `-f`: 실행 중인 컨테이너도 강제로 삭제

## Docker 볼륨 사용하기
1. 먼저 사용할 docker 볼륨을 생성한다.
   ```sh
   $ docker volume create --name <볼륨명>
   ```
   아래와 같이 생성된 볼륨을 확인할 수 있다.
   ```sh
   $ docker volume ls
   ```
   실제 경로는 아래와 같이 확인할 수 있다.
   ```sh
   $ sudo ls -l /var/lib/docker/volumes/
   ```
   또, 아래와 같이 볼륨명으로 상세 정보를 볼 수 있다.
   ```sh
   $ docker volume inspect <볼륨명>
   ```
1. 이제 다음과 같이 만들어진 볼륨을 이용하는 컨테이너를 생성할 수 있다.
   ```sh
   $ docker run -it --name <컨테이너명 | 컨테이너 ID> -v <볼륨명>:/data <이미지명[:태그명] | 이미지 ID>
   ```
   컨테이너가 사용하는 볼륨 정보는 아래 예와 같이 확인할 수 있다.
   ```sh
   $ docker container inspect <컨테이너명 | 컨테이너 ID> | grep "Source"
   ```
1. 특정 Docker 볼륨의 삭제는 다음과 같이 한다.
   ```sh
   $ docker volume rm <볼륨명>
   ```
   전체 Docker 볼륨의 삭제는 다음과 같이 할 수 있다.
   ```sh
   $ docker volume prune
   ```
1. 아직 컨테이너에 연결되지 않은 볼륨 목록은 아래와 같이 얻을 수 있다.
   ```sh
   $ docker volume ls -qf dangling=true
   ```

## Docker 네트워크
1. Docker 네트워크 목록 보기
   ```sh
   $ docker network ls
   ```
1. Docker 네트워크 생성하기
   ```sh
   $ docker network create [옵션] <Docker 네트워크명>
   ```
1. 컨테이너 네트워크 정보 보기
   ```sh
   $ docker network inspect <컨테이너 네트워크명 | 컨테이너 네트워크 ID>
   ```
1. Docker 네트워크로부터 컨테이너의 연결 끊기
   ```sh
   $ docker network disconnect <Docker 네트워크명 | Docker 네트워크 ID> <컨테이너명 | 컨테이너 ID>
   ```
1. Docker 네트워크 삭제하기
   ```sh
   $ docker network rm <Docker 네트워크명 | Docker 네트워크 ID>
   ```
1. 아무 컨테이너에도 연결되지 않은 Docker 네트워크를 모두 제거하기
   ```sh
   $ docker network prune
   ```

## 컨테이너를 새로운 이미지로 저장
아래와 같이 컨테이너를 새로운 이미지로 저장할 수 있다.
```sh
$ docker commit [옵션] <컨테이너명 | 컨테이너 ID> [저장소 IP/]<이미지명[:태그명] | 이미지 ID>
```
주요 옵션에는 다음과 같은 것들이 있다.
* `-a <사용자>`: Commit 한 사용자 정보
* `-m <메시지>`: 로그 메시지 지정

## 컨테이너의 변경 파일 목록 출력
컨테이너의 변경 목록은 아래와 같이 얻을 수 있다.
```sh
$ docker diff <컨테이너명 | 컨테이너 ID>
```

## Docker 이미지를 파일로 저장 및 로드하기
도커 이미지를 파일로 저장하려면 다음과 같이 실행한다.
```sh
$ docker save -o <파일이름.tar> <이미지명[:태그명] | 이미지 ID>
```
저장된 도커 이미지 파일을 (주로 다른 서버에서) 로드하려면 다음과 같이 실행한다.
```sh
$ docker load -i <파일이름.tar>
```
결과로 해당 도커 이미지가 생성된다.  
한편, 도커 컨테이너를 파일로 저장하려면 다음과 같이 실행한다.
```sh
$ docker export -o <파일이름.tar> <컨테이너명>
```
마찬가지로 저장된 도커 컨테이너 파일을 로드하려면 다음과 같이 실행한다.
```sh
$ docker import -i <컨테이너.tar>
```

## 로컬 Docker 이미지를 Docker Hub에 올리기
1. [Docker Hub 웹사이트](https://hub.docker.com/)에 로그인하여 저장소를 생성한다.
1. 콘솔에서 아래와 같이 Docker Hub에 로그인한다.
   ```sh
   $ docker login
   ```
1. 아래 형식으로 현재 로컬에 있는 도커 이미지로 Docker Hub에 저장소와 태그를 만든다.
   ```sh
   $ docker tag <이미지명> <사용자이름>/<저장소>:태그명
   ```
1. 올릴 Docker 이미지를 아래와 같이 Docker Hub에 push 한다.
   ```sh
   $ docker push <사용자이름>/<이미지명>:<태그명>
   ```
   이후 Docker Hub 웹사이트에서 정상적으로 push가 되었는지 확인해 본다.
1. Docker Hub 웹사이트에 이미지가 올라갔으면, 이제 Docker Hub에서 다음과 같이 pull 할 수 있다.
   ```sh
   $ docker pull <사용자이름>/<이미지명>:<태그명>
   ```

## Docker compose 사용 예
1. 우분투의 경우에는 다음과 같이 설치한다.
   ```sh
   $ sudo apt install docker-compose
   ```
1. `docker-compose.yml` 파일을 작성한다.
1. 도커 이미지 생성은 아래와 같이 할 수 있다.
   ```sh
   $ docker-compose build [옵션]
   ```
1. 컨테이너 생성 및 실행은 아래 예와 같이 한다.
   ```sh
   $ docker-compose up [옵션]
   ```
   주요 옵션에는 다음과 같은 것들이 있다.
   * `-d`: 컨테이너를 background로 실행
1. 컨테이너 삭제 및 중지는 아래와 같이 한다.
   ```sh
   $ docker-compose down [옵션]
   ```
