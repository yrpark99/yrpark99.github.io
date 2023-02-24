---
title: "SSH 설치/접속/설정 정리"
category: Environment
toc: true
toc_label: "이 페이지 목차"
---

추후 참조를 위하여 SSH 설치/접속 및 설정을 간단히 정리해 본다.

## SSH 설치
1. 우부투 서버인 경우에는 아래와 같이 설치하면 된다. (보통은 배포판에 사전 설치되어 있음)
   ```shell
   $ sudo apt install openssh-server
   ```
1. 설치가 완료되었으면, 아래와 같이 서비스를 start 시키면 된다.
   ```shell
   $ sudo service ssh restart
   ```

## SSH 접속
1. 클라이언트에서 아래와 같이 원하는 유저로 로그인 할 수 있다. (아래 예는 user ID는 **user_id**, 서버 주소는 **host_addr**로 간주하였음)
   ```shell
   $ ssh user_id@host_addr
   ```
   또는 user ID를 아래와 같이 `-l` 옵션으로 지정해도 된다.
   ```shell
   $ ssh host_addr -l user_id
   ```
   > 물론 만약 현재 클라이언트의 user ID와 동일한 ID로 SSH 서버에 접속하는 경우에는 아래와 같이 user ID 정보를 생략해도 된다.
   ```shell
   $ ssh host_addr
   ```
1. 참고로 단순히 특정 명령만 실행하길 원하는 경우에는 간단히 아래와 같이 할 수 있다.
   ```shell
   $ ssh user_id@host_addr "명령어"
   ```

## 암호 입력의 번거움
그런데 SSH 접속시마다 매번 로그인 암호를 입력하는 것은 조금 번거롭다. 그나마 로그인은 자주 하는 것이 아니니 덜 성가시지만, <font color=purple>Subversion</font>이나 <font color=purple>Git</font> 서버에서 SSH 프로토콜로 사용하는 경우에는 명령어 입력시마다 암호를 입력해야 하므로 아주 번거로워진다. 또, `scp` 명령과 같이 SSH 프로토콜을 이용하는 경우도 마찬가지로 매번 암호를 입력하는 것은 번거롭다.

## SSH 암호 입력없이 접속하기
1. 클라이언트에서 아래와 같이 SSH key pair를 생성한다.
   ```shell
   $ ssh-keygen
   ```
   실행하면 암호(passphrase)를 묻는데, 원하면 입력할 수도 있고, 그냥 Enter 키를 눌러서 입력하지 않을 수도 있다(입력하지 않는 것이 편하긴 함). 또, 키가 저장될 경로와 파일 이름을 입력받는데, 그냥 Enter 키를 누르면 디폴트 경로에 디폴트 이름으로 저장된다.  
   결과로 디폴트 경로와 이름을 사용한 경우에는 `~/.ssh/id_rsa` 파일과 `~/.ssh/id_rsa.pub` 파일이 생성되는데, 전자는 개인키이고 후자는 공개키이다.
   > 참고로 공개키의 내용은 **ssh-rsa**로 시작하고, **유저ID@호스트이름**으로 끝나는데, 만약에 맨 끝의 **유저ID@호스트이름** 정보를 변경하고 싶으면, 아래와 같이 아래와 같이 `-C` 옵션으로 원하는 내용을 적으면 된다.
   ```shell
   $ ssh-keygen -C "원하는내용"
   ```
1. 생성된 공개키를 <font color=blue>ssh-copy-id</font> 명령을 이용하여 접속할 서버로 전송한다. (아래 예는 user ID는 **user_id**, 서버 주소는 **host_addr**로 간주하였음)
   ```shell
   $ ssh-copy-id user_id@host_addr
   ```
   마찬가지로 만약 현재 클라이언트의 user ID와 SSH 서버의 ID가 동일한 경우에는 user ID 정보를 생략해도 된다.  
   결과로 SSH 서버의 `~/.ssh/authorized_keys` 파일에 클라이언트의 공개키가 추가된다.
   > 간혹 이 `ssh-copy-id` 명령을 모르고, SSH 서버에서 수동으로 **~/.ssh/authorized_keys** 파일을 직접 수정하는 사람도 있음 😓
1. 이제 다시 SSH 접속 테스트를 해 본다. 만약에 위에서 `ssh-keygen` 명령으로 key pair를 생성할 때에 암호를 입력하지 않은 경우에는 SSH 접속 시에 암호 입력 없이 바로 로그인이 된다.
1. 만약에 위에서 `ssh-keygen` 명령으로 key pair를 생성할 때에 암호를 입력한 경우에는 SSH 접속시에 이 암호를 입력해야 한다. 매번 암호를 입력하지 않으려면 아래와 같이 **<font color=blue>ssh-agent</font>**를 이용하면 된다. (<font color=blue>ssh-add</font> 시에 암호를 입력하면 이후부터는 암호를 묻지 않음)
   ```shell
   $ eval $(ssh-agent)
   $ ssh-add key_경로
   ```
   그런데 매번 로그인 한 이후, 위를 실행하여 그때마다 암호를 입력하는 것은 매우 귀찮다. (`~/.bashrc` 파일 등에 넣어도 매번 암호를 입력해야 하는 것은 마찬가지임)  
   이를 해결하는 가장 간단하고도 암호를 숨기는 좋은 방법은 OpenSSH v7.2 이후부터 지원하는 key를 agent에 등록하는 방법이다. OpenSSH v7.2는 2016년 2월에 릴리즈 되었으므로 Ubuntu 16.04 이후부터는 사용할 수 있는 방법이다.  
   필요하면 시스템에 설치된 OpenSSH 버전은 아래와 같이 확인할 수 있다.
   ```shell
   $ ssh -V
   ```
   Agent에 등록하는 방법은 `~/.ssh/config` 파일에 아래 내용을 추가하면 된다.
   ```scala
   AddKeysToAgent yes
   ```
   이후부터는 다시 로그인해도 이제는 암호 입력없이 잘 됨을 확인할 수 있다. (사실 이 knowhow는 잘 알려져 있지 않아서, 보통은 위에서 언급한대로 키 생성시 암호를 입력하지 않는 방법을 많이 사용한다. 😛)

## Windows에서 SSH 암호 입력 없애기
참고로 Windows에서 SSH 클라이언트를 사용하는 경우에도 Linux에서의 경우와 별반 다르지 않다.
1. 아래와 같이 실행하여 key pair를 생성한다.
   ```shell
   C:\>ssh-keygen -t rsa
   ```
   디폴트로 `%USERPROFILE%\.ssh\` 경로에 key가 저장되는데 이 경로를 그대로 사용하고, 암호는 입력하지 않는 것이 편리하다.  
   결과로 key 저장 경로에 `id_rsa`(개인키), `id_rsa.pub`(공개키) 2개 파일이 생성된다.
1. 아래 예와 같이 실행하면 생성한 공개키 내용이 SSH 서버의 **~/.ssh/authorized_keys** 파일에 추가된다. (아래에서 **user_id@host_addr** 부분은 해당 SSH 서버 상황에 맞게 바꾸어야 함)
   ```shell
   C:\>type %USERPROFILE%\.ssh\id_rsa.pub | ssh user_id@host_addr "cat >> .ssh/authorized_keys"
   ```
   또는 수동으로 **%USERPROFILE%\.ssh\id_rsa.pub** 파일의 내용을 SSH 서버의 **~/.ssh/authorized_keys** 파일에 추가해도 된다.
1. 이후부터는 아래와 같이 SSH 서버에 접속해 보면 암호 입력없이 로그인이 된다. (`scp` 명령도 마찬가지)
   ```shell
   C:\>ssh host_addr
   C:\>ssh user_id@host_addr
   C:\>ssh host_addr -l user_id
   ```

## SSH 서버마다 다른 SSH key 지정하기
1. 만약에 특정 서버에 특정 SSH 키를 사용하여 접속하려면 아래 예와 같이 `-i` 옵션으로 key 경로를 명시하면 된다.
   ```shell
   $ ssh -i key_경로 user_id@host_addr
   ```
1. 또는 `~/.ssh/config` 파일에 아래 예와 같이 세팅하면 된다. (아래 예에서는 `~/.ssh/` 디렉터리 밑에 호스트별로 디렉터리를 나누어서 키를 저장했음)
   ```scala
   Host third_party_server
       HostName third_party_ssh_addr
       User user_id
       IdentityFile ~/.ssh/third_party/id_rsa

   Host project_server
       HostName project_ssh_server_addr
       User user_id
       IdentityFile ~/.ssh/project_server/id_rsa
   ```
   위와 같이 세팅한 후에는 위에서 세팅한 **Host** 이름으로 SSH 접속을 하면 지정된 user ID와 키를 사용하게 접속하게 된다. 위에서 지정되지 않은 나머지 서버들은 디폴트 SSH 키를 이용하여 접속한다.  
1. 참고로 SSH config 전체 도움말은 아래와 같이 실행하면 얻을 수 있다.
   ```shell
   $ man ssh_config
   ```

## 동일 서버에서 유저로 구분하기
간혹 동일한 서버로 접속하지만 유저로 구분하여 다른 SSH key나 포트를 사용해야 하는 경우가 있다. 이 부분이 구글링했을 때 가장 찾기 힘들었는데 😓, 핵심은 `~/.ssh/config` 파일에서 <mark style='background-color: #dcffe4'>Match</mark> 키워드로 유저를 구분하는 것이다.
1. 예를 들어 동일한 GitHub 서버이지만, 개인 ID로 사용하는 경우와 회사 ID로 사용하는 경우에 다른 key를 지정하려면 아래 예와 같이 할 수 있다. (아래 예에서는 개인 ID는 **personal_github_id**, 회사 ID는 **company_github_id**로 지정했음)
   ```scala
   # 개인 계정
   Host github.com
       HostName github.com
       Match User personal_github_id
       IdentityFile ~/.ssh/id_rsa_personal

   # 회사 계정
   Host github.com
       HostName github.com
       Match User company_github_id
       IdentityFile ~/.ssh/id_rsa_company
   ```
1. 사내 방화벽에 의해 Git SSH 포트가 막혀 있어서, Git SSH 포트를 변경한 경우 (아래 예에서는 사내 Git 서버 주소를 **local.company.com**, 변경된 Git SSH 포트는 **2222**번 이라고 가정)
   ```scala
   Host local.company.com
       HostName local.company.com
       Match User git
       Port 2222
   ```
   > 위에서 만약에 <mark style='background-color: #dcffe4'>Match</mark> 키워드를 사용하지 않으면, 물론 Git SSH 프로토콜은 정상 동작하지만, SSH 접속을 하는 경우에도 22번 대신에 2222번을 사용하게 되므로 이때는 실패하게 된다.

   위와 같이 설정한 후에, 이제 아래 예와 같이 git clone을 해 보면 정상 동작한다.
   ```shell
   $ git clone git@local.company.com:your_git_url.git
   ```
   또, 아래 예와 같이 SSH 접속을 해 봐도 역시 정상적으로 동작한다.
   ```shell
   $ ssh local.company.com -l user_id
   ```

## Old SSH 버전의 서버 접속 이슈
우분투 22.04는 OpenSSH v8.9가 설치되어 있는데, 여기에서 오래된 SSH 버전의 서버에 접속하니 "Unable to negotiate with XXX port 22: no matching host key type found. Their offer: ssh-rsa,ssh-dss"와 같은 에러 메시지가 발생하면서 실패하였다.  
이는 SSH v8.8 이상에서는 디폴트로 RSA-SHA2 알고리즘을 사용하는데, 접속하려는 SSH 서버에서 이를 지원하지 않으면서 발생하는 문제이다.  
물론 SSH 서버에서 OpenSSH 버전을 업데이트하면 쉽게 해결되지만, 내가 관리할 수 없는 서버라면 대안으로 클라이언트의 `~/.ssh/config` 파일에서 SSH 서버에 대하여 아래 예와 같이 설정하면 된다.
```scala
Host xxx.yyy.zzz
    HostkeyAlgorithms +ssh-rsa
    PubkeyAcceptedKeyTypes +ssh-rsa
```

## scp 사용
`scp`는 Secure Copy Protocol의 약어로 SSH 기반이므로 SSH 환경만 구축해 놓으면 파일 복사를 아주 쉽게 해주는 툴이다. 나는 주로 Linux 시스템 간의 파일 전송, Linux 서버에서 VM 클라이언트와 호스트 간의 파일 전송, Windows와 Linux 간의 파일 전송시에 사용하는데, 물론 samba 등을 사용할 수 있지만 scp가 samba보다 빠르고 시스템 자원도 적게 사용하므로 애용하고 있다.  
대부분의 경우에 디렉터리인 경우에는 `-rp`, 파일인 경우에는 `-p` 옵션이 주로 사용되는데, 여기에서 **-r** 옵션은 하위의 디렉터리 및 파일까지 recursive 복사, **-p** 옵션은 속성(원본 파일의 변경 시간, 접근 시간, 퍼미션 등) 보존을 의미한다.  
Windows에서도 OpenSSH에 scp 툴이 포함되어 있으므로 별도의 설치없이 편리하게 이용할 수 있다.

<br>
물론 SSH 접속시 암호 입력을 없앤 상태에서는 scp 명령 시에도 암호를 묻지 않으므로, 더욱 편리하게 사용할 수 있다.

## 결론
초기 개발 환경 셋업시 큰 비중을 차지하는 SSH 환경 셋업이지만, 잘 모르는 개발자들이 많아서 공유와 이후 참조를 위하여 기록해 보았다.
