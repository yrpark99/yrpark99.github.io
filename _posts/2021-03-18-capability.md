---
title: "Linux capability"
category: Security
toc: true
toc_label: "이 페이지 목차"
---

Linux security hardening 기법 중의 하나인 capability 관련하여 정리해 본다.

## Capability 필요성
전통적인 유닉스/리눅스에서는 root가 모든 권한을 가진다. (All mighty)  
Capability는 전통적인 super user(root) 기반의 시스템 관리 권한을 좀 더 세분화하여 보안 위협에 대처하고자 만들어진 보안 모델로, 일반 유저도 제한된 root의 권한을 갖도록 해주어, 파일 실행시 setuid bit set 방법에 의한 all mighty root 권한으로 실행시키는 대신에, 제한된 root 권한을 이양받은 일반 유저 권한으로 실행시키는 방법이다.  

> 특정한 관리 작업을 수행할 때 root가 가지고 있는 모든 권한을 부여하는 것이 아니라 해당 작업에 필요한 권한 만을 부여하면, 프로그램의 버그 등으로 인해 해당 프로그램이 악의적인 사용자에게 제어 권한이 넘어갔다다고 하더라도, 다른 권한이 주어지지 않았으므로 시스템의 피해를 최소화시킬 수 있게 되는 것이다.

Capability는 커널에서 지원해야 하며, file capabilities를 위해서는 커널 v2.6.24 이상을 사용하면 된다.  

## 전체 capability 리스트 얻기
아래와 같이 얻을 수 있다.
```sh
$ capsh --print
```
결과로 `cap_XXX` 리스트를 얻을 수 있다. 이 리스트를 이후 `setcap` 명령에서 **[cap-set]** 부분에 사용할 수 있는데, 이 때 대소문자는 구분하지 않으므로 둘 다 된다.

## 실행에 필요한 capability 얻기
해당 파일을 정상적으로 실행시키기 위해 필요한 모든 권한을 얻을 수 있는 일반적인 방법은 없는 것 같다. 다만 현재 실행 중인 프로세스에 대해서는 아래 예와 같이 `getpcaps` 툴로 얻을 수 있다.
```sh
$ ping localhost &
$ getpcaps `pidof ping`
Capabilities for `32739': = cap_net_admin,cap_net_raw+p
```
위의 예에서는 `ping` 명령은 `cap_net_admin`, `cap_net_raw` 권한을 사용하고 있음을 얻을 수 있다.

## 실행 파일에 대한 capability 세팅하기
파일에 권한은 아래와 같이 `setcap` 명령으로 설정할 수 있다. (`caps-set` 부분에 capability 리스트와 속성을 세팅하면 됨)
```sh
$ sudo setcap [cap-set] <filename>
```

속성에는 아래와 같은 종류가 있다.
* <span style="color:blue">**e**</span>: **E**ffective, 프로세스가 현재 실제로 사용하고 있는 권한
* <span style="color:blue">**i**</span>: **I**nheritable, 상속이 가능한 권한 (exec 계열의 시스템 콜을 할 때의 상속 권한)
* <span style="color:blue">**p**</span>: **P**ermitted, 프로세스에 허용된 권한

Capability 리스트는 한꺼번에 여러 개의 capability를 적을 수도 있는데 이 때는 띄워쓰기 없이 `,`로 연결해 주면 된다 (또는 각각의 capability와 속성을 띄워서 열거해도 됨).

## 실행 파일에 대한 capability 얻기
현재 파일에 세팅된 capability는 아래와 같이 `getcap` 명령으로 얻을 수 있다.
```sh
$ getcap <filename>
```

## 실행 파일에 대한 capability 제거하기
파일에 대한 capability 제거는 아래와 같이 할 수 있다.
```sh
$ sudo setcap -r <filename>
```

## ping 실습 예제
현재 ping 파일은 아래 캡쳐와 같이 sticky bit가 enable 되어 있어서, 일반 사용자도 ping 명령을 실행할 수 있다.
```sh
$ ls -l /bin/ping
-rwsr-xr-x 1 root root 64424  6월 28  2019 /bin/ping
```

아래와 같이 필요한 `cap_net_raw` 권한을 drop해서 실행시키면 정상 실행되지 않음을 확인할 수 있다.
```sh
$ sudo capsh --drop=cap_net_raw -- -c "/bin/ping localhost"
ping: socket: 명령을 허용하지 않음
```

아래와 같이 sticky bit를 끈 후, ping 명령을 실행해 보면, root 권한이 없어서 정상 실행되지 않음을 확인할 수 있다.
```sh
$ sudo chmod u-s /bin/ping
$ ping localhost
ping: socket: 명령을 허용하지 않음
```

이제 아래와 같이 필요한 `cap_net_raw` 권한을 준 후 테스트하면, 정상적으로 실행된다.
```sh
$ sudo setcap 'cap_net_raw+p' /bin/ping
$ getcap /bin/ping
/bin/ping = cap_net_raw+p
$ ping localhost
PING localhost (127.0.0.1) 56(84) bytes of data.
64 bytes from localhost (127.0.0.1): icmp_seq=1 ttl=64 time=0.026 ms
```

테스트를 마쳤으면, 아래와 같이 실행하면 다시 원래 상태로 복원된다.
```sh
$ sudo setcap -r /bin/ping
$ sudo chmod u+s /bin/ping
```

## 타겟 보드에서 compartment 이용하기
Capability가 적절하게 세팅되었으면, 프로세스 실행시 user 권한으로 실행시킬 수 있다.  
나는 타겟 보드에서 security hardening(특히 root privilege 제한 용도)을 하기 위하여 편의상 compartment 툴을 이용해 보았다.  
Compartment 툴을 이용하기 위해서는 host의 `/etc/apt/sources.list` 파일에서 deb-src 부분을 uncomment 처리한 후, 아래와 같이 APT를 업데이트한 후, compartment 소스를 다운 받는다.
```sh
$ sudo apt update
$ apt-get source compartment
```
이후 소스에서 타겟 보드의 cross 환경에 맞게 `Makefile`을 수정한 후 빌드하여 사용하면 된다.

타겟 보드에서 원하는 실행 파일을 `compartment` 환경으로 아래 예와 같이 실행시킬 수 있었고, 기대대로 유저 privilege에서 정상적으로 실행이 되었다.
```console
# setcap [cap-set] <file_name>
# compartment --user <user_name> <file_name>
```

프로세스 privilege 확인은 아래와 같이 `ps` 명령으로 확인할 수 있다.
```console
# ps | grep <file_name>
```
