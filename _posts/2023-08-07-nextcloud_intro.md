---
title: "NextCloud로 cloud 파일 서버 구축하기"
category: 노트
toc: true
toc_label: "이 페이지 목차"
---

Cloud 파일 서버 솔루션 NextCloud를 간단히 소개한다.  
<br>
회사에서 웹브라우저로 액세스할 수 있는 on-premise 파일 서버를 구축하려고 서버 프로그램을 찾아보다가, [NextCloud](https://nextcloud.com/)를 발견하여 설치 및 사용해 보고, 괜찮은 솔루션이라서 서버 설치법에 대하여 간략히 기록을 남긴다. 

## NextCloud 소개
[NextCloud](https://nextcloud.com/)는 웹브라우저로 액세스할 수 있는 cloud 파일 서버 솔루션으로, on-premise로 셀프 호스팅을 하면 무료로 파일 서버를 구축할 수 있다.

## NextCloud 서버 설치
NextCloud 홈페이지에서 [Download Server](https://nextcloud.com/install/#instructions-server) 섹션을 보면 자체 서버 설치에 대한 설명이 나와 있다.  
설치 방법 중에서 Docker로 설치하는 것이 가장 간편하므로, [Nextcloud All-in-One](https://github.com/nextcloud/all-in-one#how-to-use-this) 페이지를 참고하여 Docker로 설치하면 된다.  
참고로 DockerHub에서 NextCloud 이미지는 [nextcloud](https://hub.docker.com/_/nextcloud) 페이지에서 찾을 수 있다.

## 기본적인 설치
1. 아래와 같이 실행하면 `nextcloud` Docker 이미지가 설치된다.
   ```sh
   $ docker run -d -p 8585:80 nextcloud
   ```
   이제 http://localhost:8585 주소로 접속하면 된다.  
   > 단, 이 방식은 DB로 SQLite를 사용하는데, 이것보다는 MySQL, MariaDB, PostgreSQL DB를 추천한다.
1. Docker 컨테이너는 컨테이너의 /var/www/html/ 경로에 각종 데이터를 저장한다.  
   따라서 컨테이너를 삭제해도 이 데이터를 유지하려면 아래 예와 같이 `-v` 옵션으로 호스트 경로를 지정해 주면 된다.
   ```sh
   $ docker run -d -v nextcloud:/var/www/html -p 8585:80 nextcloud
   ```
1. 별도의 DB 컨테이너를 사용하려면 아래 예와 같이 DB 컨테이너를 실행한다. (아래는 MariaDB 사용 예)
   ```sh
   $ docker run -d -v db:/var/lib/mysql mariadb
   ```
   이후 아래 예와 같이 사용하는 database에 따라 DB 환경 변수를 세팅한 후, NextCloud 컨테이너를 실행하면 된다.
   - MySQL/MariaDB인 경우
     - `MYSQL_DATABASE`: Database 이름
     - `MYSQL_USER`: Database 유저
     - `MYSQL_PASSWORD`: Database 암호
     - `MYSQL_HOST`: Database 서버의 호스트명
   - PostgreSQL인 경우
     - `POSTGRES_DB`: Database 이름
     - `POSTGRES_USER`: Database 유저
     - `POSTGRES_PASSWORD`: Database 암호
     - `POSTGRES_HOST`: Database 서버의 호스트명

## Docker compose 이용 예
1. 별도의 DB 컨테이너를 사용하려면 Docker compose를 이용하는 것이 편하다.  
   아래 예와 같이 `docker-compose.yml` 파일을 작성한다.
   ```yml
   version: '2'
   volumes:
     nextcloud:
     db:
   services:
     db:
       image: mariadb:10.6
       restart: always
       command: --transaction-isolation=READ-COMMITTED --log-bin=binlog --binlog-format=ROW
       volumes:
         - db:/var/lib/mysql
       environment:
         - MYSQL_ROOT_PASSWORD=
         - MYSQL_PASSWORD=
         - MYSQL_DATABASE=nextcloud
         - MYSQL_USER=nextcloud
     app:
       image: nextcloud
       restart: always
       ports:
         - 8585:80
       links:
         - db
       volumes:
         - nextcloud:/var/www/html
       environment:
         - MYSQL_PASSWORD=
         - MYSQL_DATABASE=nextcloud
         - MYSQL_USER=nextcloud
         - MYSQL_HOST=db
   ```
1. 아래와 같이 실행하면 컨테이너가 생성되고 실행된다.
   ```sh
   $ docker-compose up -d
   ```
1. 이후 웹브라우저에서 [http://localhost:8585](http://localhost:8585) 주소로 접속할 수 있다.

## 사용 팁
파일의 링크 공유 시 공개 링크가 클립 보드에 복사가 되지 않는 경우에는, 아래 버튼을 우클릭한 후에 링크 주소 복사를 선택하면 된다.  
![](/assets/images/nextcloud_link_share.png)
