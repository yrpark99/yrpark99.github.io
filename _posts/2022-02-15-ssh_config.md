---
title: "SSH 설치/접속/설정"
category: Environment
toc: true
toc_label: "이 페이지 목차"
---

추후 참조를 위하여 SSH 설치/접속 및 설정을 간단히 정리해 본다.

## SSH 설치
1. 우부투 서버인 경우에는 아래와 같이 설치하면 된다. (보통은 배포판에 사전 설치되어 있음)
   ```bash
   $ sudo apt install openssh-server
   ```
1. 설치가 완료되었으면, 아래와 같이 서비스를 start 시키면 된다.
   ```bash
   $ sudo service ssh restart
   ```

## SSH 접속
1. 클라이언트에서 아래와 같이 원하는 유저로 로그인 할 수 있다. (아래 예는 user ID는 **user_id**, 서버 주소는 **host_addr**로 간주하였음)
   ```bash
   $ ssh user_id@host_addr
   ```
   또는 user ID를 아래와 같이 `-l` 옵션으로 지정해도 된다.
   ```bash
   $ ssh host_addr -l user_id
   ```
   > 참고로 만약 현재 클라이언트의 user ID와 동일한 ID로 SSH 서버에 접속하는 경우에는 user ID 정보를 생략해도 된다.
1. 참고로 단순히 특정 명령만 실행하길 원하는 경우에는 간단히 아래와 같이 할 수 있다.
   ```bash
   $ ssh user_id@host_addr "명령어"
   ```

## 암호 입력의 번거움
그런데 SSH 접속시마다 매번 로그인 암호를 입력하는 것은 조금 번거롭다. 그나마 로그인은 자주 하는 것이 아니니 그나마 덜 성가시지만, <font color=purple>Subversion</font>이나 <font color=purple>Git</font> 서버에서 SSH 프로토콜로 사용하는 경우에는 명령어 입력시마다 암호를 입력해야 하므로 아주 번거로워진다.

## SSH 암호 입력없이 접속하기
1. 클라이언트에서 아래와 같이 SSH key pair를 생성한다.
   ```bash
   $ ssh-keygen
   ```
   실행하면 암호(passphrase)를 묻는데, 원하면 입력할 수도 있고, 그냥 Enter 키를 눌러서 입력하지 않을 수도 있다(입력하지 않는 것이 편하긴 함). 또, 키가 저장될 경로와 파일 이름을 입력받는데, 그냥 Enter 키를 누르면 디폴트 경로에 디폴트 이름으로 저장된다.  
   결과로 디폴트 경로와 이름을 사용한 경우에는 `~/.ssh/id_rsa` 파일과 `~/.ssh/id_rsa.pub` 파일이 생성되는데, 전자는 개인키이고 후자는 공개키이다.
   > 참고로 공개키의 내용은 **ssh-rsa**로 시작하고, **유저ID@호스트이름**으로 끝나는데, 만약에 맨 끝의 **유저ID@호스트이름** 정보를 변경하고 싶으면, 아래와 같이 아래와 같이 `-C` 옵션으로 원하는 내용을 적으면 된다.
   ```bash
   $ ssh-keygen -C "원하는내용"
   ```
1. 생성된 공개키를 <font color=blue>ssh-copy-id</font> 명령을 이용하여 접속할 서버로 전송한다. (아래 예는 user ID는 **user_id**, 서버 주소는 **host_addr**로 간주하였음)
   ```bash
   $ ssh-copy-id user_id@host_addr
   ```
   마찬가지로 만약 현재 클라이언트의 user ID와 SSH 서버의 ID가 동일한 경우에는 user ID 정보를 생략해도 된다.  
   결과로 SSH 서버의 `~/.ssh/authorized_keys` 파일에 클라이언트의 공개키가 추가된다.
   > 간혹 이 `ssh-copy-id` 명령을 모르고, SSH 서버에서 수동으로 **~/.ssh/authorized_keys** 파일을 직접 수정하는 사람도 있음 😓
1. 이제 다시 SSH 접속 테스트를 해 본다. 만약에 위에서 `ssh-keygen` 명령으로 key pair를 생성할 때에 암호를 입력하지 않은 경우에는 SSH 접속 시에 암호 입력 없이 바로 로그인 된다.
1. 만약에 위에서 `ssh-keygen` 명령으로 key pair를 생성할 때에 암호를 입력한 경우에는 SSH 접속시에 이 암호를 입력해야 한다. 매번 암호를 입력하지 않으려면 아래와 같이 **<font color=blue>ssh-agent</font>**를 이용하면 된다. (<font color=blue>ssh-add</font> 시에 암호를 입력하면 이후부터는 암호를 묻지 않음)
   ```bash
   $ eval $(ssh-agent)
   $ ssh-add key_경로
   ```
   그런데 매번 로그인 한 이후, 위를 실행하여 그때마다 암호를 입력하는 것은 매우 귀찮다. (`~/.bashrc` 파일 등에 넣어도 매번 암호를 입력해야 하는 것은 마찬가지임)  
   이를 해결하는 가장 간단하고도 암호를 숨기는 좋은 방법은 OpenSSH v7.2 이후부터 지원하는 key를 agent에 등록하는 방법이다. OpenSSH v7.2는 2016년 2월에 릴리즈 되었으므로 Ubuntu 16.04 이후부터는 사용할 수 있는 방법이다.  
   필요하면 시스템에 설치된 OpenSSH 버전은 아래와 같이 확인할 수 있다.
   ```bash
   $ ssh -V
   ```
   Agent에 등록하는 방법은 `~/.ssh/config` 파일에 아래 내용을 추가하면 된다.
   ```yaml
   AddKeysToAgent yes
   ```
   이후부터는 다시 로그인해도 이제는 암호 입력없이 잘 됨을 확인할 수 있다. (사실 이 knowhow는 잘 알려져 있지 않아서, 보통은 위에서 언급한대로 키 생성시 암호를 입력하지 않는 방법을 많이 사용한다. 😛)

## SSH 서버마다 다른 SSH key 지정하기
1. 만약에 특정 서버에 특정 SSH 키를 사용하여 접속하려면 아래 예와 같이 `-i` 옵션으로 key 경로를 명시하면 된다.
   ```bash
   $ ssh -i key_경로 user_id@host_addr
   ```
1. 또는 `~/.ssh/config` 파일에 아래 예와 같이 세팅하면 된다. (아래 예에서는 `~/.ssh/` 디렉토리 밑에 호스트별로 디렉토리를 나누어서 키를 저장했음)
   ```yaml
   Host third_party_ssh
       HostName third_party_ssh_addr
       Port 29418
       User user_id
       IdentityFile ~/.ssh/third_party/id_rsa
   
   Host github_personal
       HostName github.com
       User gituser1
       IdentityFile ~/.ssh/github_personal/id_rsa

   Host github_company
       HostName github.com
       User gituser2
       IdentityFile ~/.ssh/github_company/id_rsa
   ```
   위와 같이 세팅한 후에는 위에서 세팅한 **Host** 이름으로 SSH 접속을 하면 지정된 키를 사용하게 접속하게 된다. 이부분 역시 모르는 개발자들이 많은데 공유와 이후 참조를 위하여 기록해 보았다.
