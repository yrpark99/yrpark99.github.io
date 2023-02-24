---
title: "Docker 네트워크 IP 대역 변경하기"
category: Docker
toc: true
toc_label: "이 페이지 목차"
---

Docker 컨테이너에서 네트워크를 사용할 때 내부 네트워크 망과 충돌이 발생하는 경우를 정리한다.

## 동기
얼마 전에 회사 서버에 마크다운 문서를 협업하여 작성할 수 있는 HedgeDoc을 Docker로 설치하여 운영하고 있었다. ([마크다운으로 협업하는 HedgeDoc 소개](https://yrpark99.github.io/markdown/hedgedoc_intro/) 참조)  
그런데 어느 순간부터 이 서버에 회사 유선망으로 접속 시에는 아무 문제가 없는데, 회사 WiFi 망으로 연결하면 접속이 되지 않는 문제가 발생하였다. 🤔  
Docker 컨테이너를 추가한 것 때문에 문제가 발생했을 줄은 생각지도 못했기 때문에 전혀 원인을 모르고 있다가, 우연히 이 서버에서 `netstat` 명령으로 라우트 테이블을 확인해 보다가, Docker 네트워크가 회사 WiFi 대역과 동일한 대역을 사용하여 충돌이 발생했기 때문임을 발견하였다.  
이에 이 문제를 회피하도록 수정하였고, 블로그에도 해결 방법을 간단히 정리한다.

## Docker 네트워크
Docker 네트워크는 Docker 컨테이너가 이더넷을 사용하거나 컨테이너 간에 통신을 할 경우에 필요하다.  
Docker 네트워크의 driver 종류에는 다음과 같은 것들이 있다.
- `bridge`: 하나의 호스트 내에서 여러 컨테이너들이 서로 통신할 수 있도록 해줌
- `host`: 컨테이너에서 호스트와 동일한 네트워크를 사용함
- `overlay`: 여러 호스트에 분산되어 돌아가는 컨테이너들 간에 네트워킹을 위해서 사용됨

이 글에서는 **bridge** 네트워크를 사용할 때 호스트 네트워크와 충돌되는 경우에 관하여 다룬다.

## Docker 네트워크 생성
Docker 네트워크는 다음 방법으로 생성할 수 있다.
1. Docker 명령으로 수동 생성: 아래 형식으로 생성할 수 있다. (`--driver` 옵션을 지정하지 않으면 디폴트로 `bridge` 사용)
   ```sh
   $ docker network create [옵션] <Docker 네트워크명>
   ```
1. Docker compose 이용: Docker compose 파일의 `networks` 섹션에서 설정하면 자동으로 생성된다.

그런데 Docker 네트워크의 IP 대역은 디폴트로 **<font color=blue>172.17</font>** 대역부터 할당되고, 새로운 이미지로 컨테이너를 생성하면 **<font color=purple>172.18</font>** 대역, 그 다음은 **<font color=purple>172.19</font>**, 또 그 다음은 **<font color=red>172.20</font>** 대역과 같이 +1 되면서 할당된다.  
<br>
나의 경우에는 회사의 유선 네트워크는 IP가 **<font color=blue>172.16</font>** 대역이라서 Docker 네트워크와 충돌이 발생할 경우가 없었지만, WiFi의 IP 대역은 **<font color=red>172.20</font>** 이라서, 이것이 마지막에 추가된 Docker 네트워크의 IP 대역과 동일하였고, 이 충돌 때문에 WiFi로 연결하면 해당 서버로 접속이 되지 않는 문제가 발생하였다. (서버에서 `netstat` 명령으로 라우트 테이블을 확인하면 알 수 있음)

## Docker 네트워크 정보
Docker 네트워크의 전체 목록은 아래와 같이 볼 수 있다.
```sh
$ docker network ls
```
이 중에서 `bridge` 이름의 네트워크는 모든 Docker bridge 네트워크를 위한 인터페이스로 `docker0` 이름으로 할당되어 있고, IP 주소를 확인해 보면 아래와 같이 **172.17** 대역으로 나온다.
```sh
ifconfig docker0 | grep -w inet
        inet 172.17.0.1  netmask 255.255.0.0  broadcast 172.17.255.255
```
나머지는 bridge 네트워크 목록은 해당 네트워크를 사용하는 컨테이너 개수만큼 표시되고, 여기에서 **NETWORK ID**는 호스트에서 **br-NETWORK ID** 네트워크 인터페이스로 할당된다. (예를 들어 **NETWORK ID** 값이 07f822c652ac 이면 호스트 네트워크 인터페이스에 **br-07f822c652ac**가 생성됨)  
<br>

또 아래와 같이 호스트의 라우트 정보를 보면,
```sh
$ netstat -rn
```
Destination(목적지) IP에 **172.17.0.0**와 이후 컨테이너에서 사용되는 **172.18.0.0** 등의 목록과 해당 인터페이스 정보(**br-NETWORK ID**)가 표시된다.  

특정 컨테이너가 사용하는 bridge 네트워크에 할당된 IP를 확인해 보면, 아래 예와 같이 **172** 대역으로 할당되었음을 확인할 수 있다.
```sh
$ ifconfig br-07f822c652ac | grep -w inet
        inet 172.18.0.1  netmask 255.255.0.0  broadcast 172.18.255.255
$ ifconfig br-7ac9bfb1ebfe | grep -w inet
        inet 172.19.0.1  netmask 255.255.0.0  broadcast 172.19.255.255
```
또 그 다음 컨테이너는 **172.19**, **172.20**과 같은 대역으로 할당되어 있음을 볼 수 있다.

> 참고로 만약에 `ifconfig`나 `netstat` 명령으로 확인한 호스트 네트워크의 인터페이스 개수보다 `docker network ls` 개수가 더 많은 경우에는, 아래와 같이 실행하여 아무 컨테이너에도 연결되지 않은 Docker 네트워크는 모두 제거시키면 일치하게 된다.
```sh
$ docker network prune
```

## 컨테이너 IP 대역 변경하기
이와 같이 Docker 네트워크에서 사용하는 IP 대역과 내부 네트워크의 IP 대역이 겹치면 충돌이 발생하여 정상적으로 액세스가 되지 않는다. 이 문제를 해결하려면 Docker 네트워크의 IP 대역을 변경해야 하는데, 다음과 같은 방법이 있다.
1. 전체 컨테이너 대상 방법: **/etc/docker/daemon.json** 파일에서 `bip`로 지정 (아래 예 참조)
   ```json
   {
       "bip": "10.10.0.1/24",
   }
   ```
1. 개별 컨테이너 대상 방법
   - Docker network 생성시 옵션으로 **subnet**, **gateway**를 지정하는 방법 (아래 예 참조)
     ```sh
     $ docker network create --driver bridge --subnet 172.100.0.0/16 --gateway 172.100.0.1 <컨테이너 네트워크명>
     ```
     생성한 컨테이너 네트워크는 컨테이너 생성/실행시에 `--network <컨테이너 네트워크명>` 옵션으로 지정해서 사용하면 된다.
   - Docker compose 파일의 `networks` 섹션에서 지정 (아래 HedgeDoc **192.168.100** 대역 할당 예 참조)
     ```yml
     version: '3'
     services:
       database:
         image: postgres:13.4-alpine
         environment:
           - POSTGRES_USER=hedgedoc
           - POSTGRES_PASSWORD=password
           - POSTGRES_DB=hedgedoc
         volumes:
           - database:/var/lib/postgresql/data
         restart: always
         networks:
           client1:
             ipv4_address: 192.168.100.2
       app:
         image: quay.io/hedgedoc/hedgedoc:1.9.6
         environment:
           - CMD_DB_URL=postgres://hedgedoc:password@database:5432/hedgedoc
           - CMD_DOMAIN={your_host_url}
           - CMD_URL_ADDPORT=true
         volumes:
           - uploads:/hedgedoc/public/uploads
         ports:
           - "3000:3000"
         restart: always
         networks:
           client1:
             ipv4_address: 192.168.100.3
         depends_on:
           - database
     volumes:
       database:
       uploads:
     networks:
       client1:
         driver: bridge
         ipam:
           driver: default
           config:
             - subnet: 192.168.100.0/24
     ```

## 변경된 컨테이너 IP 대역 확인
위와 같이 Docker compose 파일을 변경하고, 다시 Docker 컨테이너를 실행시켰다. 이후 Docker 네트워크를 확인하니, 아래 캡쳐와 같이 **hedgedoc_client1** 이름의 Docker 네트워크가 생성되었다.
```sh
$ docker network ls
NETWORK ID     NAME                           DRIVER    SCOPE
65d4058cd8db   hedgedoc_client1               bridge    local
```

추가로 이 네트워크의 상세 정보를 inspect로 확인해 보았다.
```sh
$ docker inspect network hedgedoc_client1
```
이 중에서 IP 대역 관련 부분만 간추려 보면, 위에서 세팅한 것처럼 **192.168.100** 대역으로 할당받은 것으로 나온다. (또, Docker compose 파일에서 세팅한 것처럼 database 컨테이너는 **192.168.100.2**, app 컨테이너는 **192.168.100.3** IP를 할당받았다고 나옴)
```json
"IPAM": {
    "Driver": "default",
    "Config": [
        {
            "Subnet": "192.168.100.0/24"
        }
    ]
},
"Containers": {
    "{hedgedoc_app_1_ID}": {
        "Name": "hedgedoc_app_1",
        "IPv4Address": "192.168.100.3/24",
    },
    "{hedgedoc_database_1_ID}": {
        "Name": "hedgedoc_database_1",
        "IPv4Address": "192.168.100.2/24",
    }
},
```

또, `netstat` 명령으로 확인해 보아도 **172.20** 대역 대신에 **192.168.100** 대역이 사용되었음을 확인할 수 있다.
```sh
$ netstat -rn
Kernel IP routing table
Destination     Gateway         Genmask         Flags   MSS Window  irtt Iface
0.0.0.0         172.16.7.2      0.0.0.0         UG        0 0          0 eth0
172.17.0.0      0.0.0.0         255.255.0.0     U         0 0          0 docker0
172.18.0.0      0.0.0.0         255.255.0.0     U         0 0          0 br-07f822c652ac
172.19.0.0      0.0.0.0         255.255.0.0     U         0 0          0 br-7ac9bfb1ebfe
192.168.100.0   0.0.0.0         255.255.255.0   U         0 0          0 br-65d4058cd8db
```
또한 호스트의 해당 bridge 네트워크 인터페이스를 확인해 보아도, 마찬가지로 **192.168.100** 대역으로 할당받았음을 확인할 수 있다.
```sh
$ ifconfig br-65d4058cd8db | grep -w inet
        inet 192.168.100.1  netmask 255.255.255.0  broadcast 192.168.99.255
```

## 맺음말
따라서 사용하는 내부 네트워크의 IP 대역이 **<font color=red>172.17</font>** 이후인 경우에는 Docker 네트워크와 겹칠 수 있으므로, 이 경우에는 Docker 네트워크 사용시에 주의를 해야만 한다. 만약에 두 대역이 겹치게 되는 경우에는, 여기에서 예시한 바와 같이 Docker 네트워크 IP 대역을 내부망 IP 대역과 겹치지 않게 변경해야 한다.  
Docker 네트워크에 대해서 전혀 신경을 쓰고 있지 않다가, 이번 문제를 만나면서 Docker 네트워크에 대하여 공부하면서 이슈도 해결하였다. 🙂
