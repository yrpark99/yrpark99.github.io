---
title: "안드로이드 디바이스와 ADB로 연결하기"
category: Android
toc: true
toc_label: "이 페이지 목차"
---

안드로이드 디바이스 개발시 Ethernet으로 ADB 연결하는 방법에 대하여 정리해 본다.

## 개발 Network 환경
현재 내 Android 개발 환경은 사내망에 아래와 같이 연결되어 있다.
![](/assets/images/android_ethernet_diagram.svg)

> 개발 서버는 팀원들이 공용으로 사용하는 서버로, 동시에 여러 명의 사용자가 각자의 안드로이드 디바이스에 연결할 수 있다.

각자 공용 개발 서버에서 Android 소스를 빌드하고, 여기에서 안드로이드 디바이스에 ADB 연결하여 디버깅하는 것이 목표이다.  
그런데 네트웍 기본 설정으로는 안드로이드 디바이스에서 개발 서버로는 접속할 수 있지만, 그 반대 방향의 접속은 되질 않는다.  
이 문제점을 해결하기 위하여 개인 공유기 설정에서 안드로이드 디바이스의 IP 값으로 <span style="color:blue">포트 포워딩</span>을 추가한다. (IP 범위는 ADB가 사용하는 포트 범위인 `5555 ~ 5585`로 지정하면 됨, 또는 간단히 전체 포트를 포워딩해주는 <span style="color:blue">DMZ</span>를 추가해도 됨)  
> 개발 서버에서 안드로이드 디바이스에 접근할 때는 안드로이드 디바이스의 내부 IP가 아닌 개인 공유기의 WAN IP로 (위의 예에서는 `172.16.x.yy`) 접근해야 한다.

## Ethernet으로 ADB 연결 및 끊기
1. 개발 서버는 여러 명이 공용으로 사용하기 때문에 이들을 구분하여 연결하기 위해서는 각자의 안드로이드 디바이스에서 서로 다른 ADB 포트 번호를 사용해야 한다. (만약 지정하지 않으면 디폴트 포트 번호는 `5555`)  
이를 위해 안드로이드 디바이스에서 <span style="color:red">su</span> 명령으로 root에 로그인한 후에, 아래 예와 같이 사용할 ADB 포트를 지정한다. (가능 범위는 `5555 ~ 5585` 사이의 홀수값)
   ```xml
   setprop service.adb.tcp.port <port>
   ```
   참고로 현재 세팅된 ADB 포트 번호는 아래와 같이 확인할 수 있다.
   ```xml
   getprop service.adb.tcp.port
   ```
1. 이후 안드로이드 디바이스에서 아래와 같이 ADB 데몬을 재시작시킨다.
   ```xml
   stop adbd
   start adbd
   ```
   결과로 USB 디버깅을 allow 하겠냐는 팝업이 뜨면 allow 시킨다. (최초 한 번만 등록되면 이후에는 팝업이 뜨지 않음)
1. 이제 개발 서버에서 아래와 같이 `-s` 옵션으로 안드로이드 디바이스의 IP와 포트 번호를 주어 연결시킬 수 있다.
   ```sh
   $ adb connect <ipaddr:port>
   ```
   ADB 연결된 디바이스 리스트들은 아래와 같이 얻을 수 있다. (아래에서는 디바이스 상세 정보를 보기 위하여 `-l` 옵션을 추가했음)
   ```sh
   $ adb devices -l
   ```
   ADB 연결을 끊으려면 아래와 같이 하면 된다.
   ```sh
   $ adb disconnect <ipaddr:port>
   ```

## 기타 ADB 명령 예
1. ADB shell은 아래와 같이 얻을 수 있다.
   ```sh
   $ adb -s <ipaddr:port> shell
   ```
   또는 아래 형식으로 커맨드를 실행시킬 수도 있다.
   ```sh
   $ adb -s <ipaddr:port> shell "커맨드"
   ```
1. 안드로이드 디바이스로 파일 복사나 APK 설치를 위해서 remount를 해야 하는데, 아래와 같이 할 수 있다.
   ```sh
   $ adb -s <ipaddr:port> root remount   
   ```
   이후 호스트에서 안드로이드 디바이스로의 파일 복사는 아래와 같이 할 수 있다.
   ```sh
   $ adb -s <ipaddr:port> push <호스트 파일 경로> <보드 경로>
   ```
   반대로 안드로이드 디바이스의 파일을 호스트로의 복사는 아래와 같이 하면 된다.
   ```sh
   $ adb -s <ipaddr:port> pull <보드 파일 경로> <호스트 받을 경로>
   ```
   안드로이드 디바이스에 APK 설치/재설치/삭제는 각각 아래와 같이 하면 된다.
   ```sh
   $ adb -s <ipaddr:port> install <APK 파일>
   $ adb -s <ipaddr:port> install -r <APK 파일>
   $ adb -s <ipaddr:port> uninstall <APK 파일>
   ```

## alias 이용
1. 나는 편리하기 ADB 관련 명령어를 사용하기 위하여 ~/.bashrc 파일에 아래와 같이 추가하였다. (각자 자신의 사내망 IP와 서로 다른 ADB 포트 번호를 세팅하면 됨)
   ```sh
   ADB_IP=172.16.x.yy
   ADB_PORT=5577

   alias adblist='adb devices -l'
   alias adbcon='adb connect $ADB_IP:$ADB_PORT'
   alias adbdis='adb disconnect $ADB_IP:$ADB_PORT'
   alias adbroot='adb -s $ADB_IP:$ADB_PORT root'
   alias adbshell='adb -s $ADB_IP:$ADB_PORT shell'
   alias adbremount='adb -s $ADB_IP:$ADB_PORT root remount'
   alias adbpush='adb -s $ADB_IP:$ADB_PORT push $1 $2'
   alias adbapkinstall='adb -s $ADB_IP:$ADB_PORT install $1'
   ```
   위와 같은 alias 덕분에 이제 복잡한 ADB 명령은 못 외워도 된다. 😅  
   간단히 `adb`를 타이핑 한 후에 `Tab` 키를 누르면 위 alias 명령을 모두 보여주므로 쉽게 선택할 수 있다. 👍🏻
1. 참고로 설정된 alias 확인은 아래 예와 같이 하면 된다.
   ```sh
   $ alias adbpush
   ```

## 개인 네트웍인 경우
참고로 ADB를 공용 서버가 아닌 개인 네트웍에 연결하는 경우에는 위에서처럼 ADB 포트를 개별화할 필요가 없다. PC에서 안드로이드 스튜디오로 앱을 개발하고 안드로이드 기기에서 실행시킬 때에 사용한다.  
즉, 유무선 Ethernet으로 연결된 경우에는 단순히 아래 예와 같이 ADB connect 하면 된다. (안드로이드 기기의 IP가 192.168.0.3 이라고 가정, 물론 <span style="color:blue">포트 포워딩</span>도 필요없음)
```sh
adb connect 192.168.0.3
```
