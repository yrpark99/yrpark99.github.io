---
title: "서버 시작시 프로그램 자동 시작 설정하기"
category: Shell
toc: true
toc_label: "이 페이지 목차"
---

서버 시작시에 자동으로 특정 프로그램을 실행하는 방법에 대하여 간단히 기술한다.

## 우분투 systemctl
시스템 기동 중에 주기적인 실행은 `cron`을 이용하면 되지만, 시작시에 한 번만 특정 프로그램을 시작시키려면 (서버를 띄우는 것과 같이), 우분투 기준으로 `/etc/rc.local` 파일을 이용하거나 (표준 방법은 아님), `systemctl`을 이용할 수 있다.

아래에 예를 들어서 작성해 본다. (아래 예에서는 사용자 ID를 **ubuntu**, 실행할 프로그램이 **ubuntu** 홈 디렉토리에 **MyServer** 이름으로 있다고 가정)

1. 아래 내용과 같이 `/home/ubuntu/MyServer.sh` 파일을 생성한다.
   ```bash
   #!/bin/sh
   cd /home/ubuntu/; ./MyServer
   ```
   이후 아래와 같이 실행 권한을 준다.
   ```bash
   $ chmod +x /home/ubuntu/MyServer.sh
   ```
1. 아래 내용과 같이 `/lib/systemd/system/MyServer.service` 파일을 생성한다.
   ```ini
   [Unit]
   Description=My Server
   [Service]
   ExecStart=/home/ubuntu/MyServer.sh
   [Install]
   WantedBy=multi-user.target
   ```
   이후 아래와 같이 실행 권한을 준다.
   ```bash
   $ sudo chmod +x /lib/systemd/system/MyServer.service
   ```
1. 아래와 같이 `systemctl`을 configure 및 start 시킨다.
   ```bash
   $ sudo systemctl daemon-reload
   $ sudo systemctl enable MyServer.service
   $ sudo systemctl start MyServer.service
   ```
   필요하면 아래와 같이 해당 서비스 상태를 확인해 볼 수 있다.
   ```bash
   $ systemctl status MyServer.service
   ```
   또는 필요시 아래와 같이 전체 서비스 상태를 확인해 볼 수도 있다.
   ```   
   $ systemctl list-units --type=service
   ```

## Docker 컨테이너인 경우
만약 시스템 부팅시 자동으로 Docker 컨테이너를 시작시키고 싶으면 docker run 명령시에 `--restart=always` 옵션을 추가하면 된다.  또는 Docker compose 이용시에는 `restart: always` 설정을 추가하면 된다.
