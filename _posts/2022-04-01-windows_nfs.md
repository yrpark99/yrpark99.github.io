---
title: "Windows에서 NFS 서버 설치"
category: WSL
toc: true
toc_label: "이 페이지 목차"
---

Windows에서 NFS 서버를 설치하는 방법을 소개한다.

<br>
보통 Windows를 개발 서버로 쓰는 일은 드물어서 Linux 서버와는 다르게 Windows를 NFS 서버로 사용할 일은 별로 없지만, 필요한 경우에 참조하기 위하여 기록한다.

## Windows Server에서 NFS 서버 설치
Windows Server는 자체적으로 NFS 서버 기능을 제공하므로 별도의 설치가 필요하지 않고, 제공하는 기능을 이용하여 설정을 하면 된다. (나는 Windows Server를 사용하지 않으므로 상세 내용은 pass)

## Windows 7/10/11에서 NFS 서버 설치
Windows 7/10/11에서는 OS 자체적으로는 NFS 서버 기능을 지원하지 않으므로, [WinNFSd](https://github.com/winnfsd/winnfsd) 툴을 이용하여 아래와 같이 할 수 있다. (이름은 Windows NFS daemon을 뜻함)
1. Windows에서 아래 예와 같이 NFS 서버 프로그램을 실행시킨다. (아래 예에서는 현재 디렉터리를 NFS 디렉터리로 사용, export 경로를 **/exports**로 지정)
   ```bat
   C:\>WinNFSd.exe . /exports
   ```
   NFS 관련 로그 출력이 나오지 않게 하려면 아래 예와 같이 **-log off** 옵션을 추가하면 된다.
   ```bat
   C:\>WinNFSd.exe -log off . /exports
   ```
   참고로 이 툴은 NFS write도 지원하므로, 이후 접속한 NFS 클라이언트에서는 write도 가능하다.
1. 이후 Linux 클라이언트에서 아래 예와 같이 NFS 마운트시킬 수 있다. (내 Windows PC의 IP가 **192.168.0.2** 인 경우)
   ```shell
   $ sudo mount -t nfs -o vers=3 192.168.0.2:/exports /mnt/
   ```

## WSL에서 NFS 서버 설치
WSL2의 네트워크는 Hyper-V 가상화 기반으로 동작하는데, internal 유형으로 NAT를 사용하기 때문에 172 대역의 IP를 동적으로 할당받아서, Windows에서는 잘 접근이 되지만, 외부에서는 접근이 되지 않는다.  
WSL에서 NFS 서버를 세팅하고 외부 디바이스에서 NFS로 접속하는 방법을 구글링 해보면서 여러 방법으로 시도해 보다가, 아래 방법으로 성공하여서 정리해 본다.
1. WSL에서 아래와 같이 NFS 서버를 설치한다.
   ```shell
   $ sudo apt install nfs-kernel-server
   ```
   NFS 디렉터리로 /opt/nfs/ 디렉터리를 생성한 후, /etc/exports 파일에서 아래 예와 같이 추가한다.
   ```shell
   /opt/nfs *(rw,no_root_squash,sync,no_subtree_check)
   ```
   > WSL은 혼자만 사용하는 환경이므로 의도적으로 편의상 root write 권한도 주기 위하여 <font color=blue>root_squash</font> 대신에 <font color=blue>no_root_squash</font> 옵션을 사용하였다. 여러 사람이 사용하는 공용 서버에서는 <font color=blue>no_root_squash</font> 옵션을 사용하면 쉽게 root 권한이 해킹된다.
1. 현재 WSL에서 eth0 장치를 확인해 보면 아래 예와 같이 172 대역으로 IP를 할당받았음을 확인할 수 있다.
   ```shell
   $ ifconfig eth0
   eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
           inet 172.22.179.136  netmask 255.255.240.0  broadcast 172.22.191.255
           inet6 fe80::215:5dff:fea8:e6a9  prefixlen 64  scopeid 0x20<link>
           ether 00:15:5d:a8:e6:a9  txqueuelen 1000  (Ethernet)
           RX packets 36  bytes 4987 (4.9 KB)
           RX errors 0  dropped 0  overruns 0  frame 0
           TX packets 13  bytes 1086 (1.0 KB)
           TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
   ```
   이후 작업을 하기 위하여, 현재 실행 중인 WSL이 있으면 아래와 같이 종료시킨다.
   ```bat
   C:\>wsl --shutdown
   ```
1. `Windows 기능 켜기/끄기`를 실행한 후 (또는 콘솔에서 `OptionalFeatures.exe` 실행), **Hyper-V** 항목의 체크를 켠다. 이후 Windows가 재부팅된다.
1. 바로 `Hyper-V 관리자`로 들어가면 "WSL" 항목이 보이지 않으므로, WSL을 실행시켰다가 다시 shutdown 시킨다.
1. `Hyper-V 관리자`를 관리자 권한으로 실행시킨 후, 해당 가상 컴퓨터에서 `가상 스위치 관리자` 항목을 클릭한다.  
   가상 스위치 항목 중에서 "WSL" 항목을 선택한 후, 아래 캡쳐와 같이 **연결 형식**을 디폴트 <font color=purple>내부 네트워크</font>에서 <font color=purple>외부 네트워크</font>로 변경하고 사용할 이더넷 장치를 선택한다.  
   ![](/assets/images/hyperv_switch_setting.png)  
   **확인** 버튼을 눌러서 변경 사항을 적용한다.
1. 변경 내용이 적용되었으면 다시 WSL에 로그인 후, 아래와 같이 실행한다.
   ```shell
   $ sudo ip addr flush dev eth0
   $ sudo dhclient eth0
   ```
   결과로 아래 예와 같이 eth0 장치가 IP를 **192.168.0.XXX** 주소로 할당받았음을 확인할 수 있다.
   ```shell
   $ ifconfig eth0
   eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
           inet 192.168.0.180  netmask 255.255.255.0  broadcast 192.168.0.255
           ether 00:15:5d:a8:e6:a9  txqueuelen 1000  (Ethernet)
           RX packets 42  bytes 8484 (8.4 KB)
           RX errors 0  dropped 0  overruns 0  frame 0
           TX packets 18  bytes 2020 (2.0 KB)
           TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
   ```
   외부 디바이스에서 위 **192.168.0.XXX** IP로 ping 테스트를 해 보면 ping이 잘 됨을 확인할 수 있다.
1. 이제 아래와 같이 RPC bind 서비스와 NFS 서버를 start 시킨다.
   ```shell
   $ sudo mkdir -p /run/sendsigs.omit.d/
   $ sudo service rpcbind start
   $ sudo /etc/init.d/nfs-kernel-server start
   ```
1. 외부 디바이스에서 WSL 주소로 NFS 마운트를 해보면 잘된다. 😋  
   (단, WSL을 재시작시키면 DHCP IP 할당과 NFS 서버 시작을 다시 시켜줘야 한다)

> 그런데 Windows 재부팅을 하면, 로컬 네트워크가 제대로 동작하지 않았고 위에서 수정한 WSL 가상 스위치의 연결 형식도 다시 원래값으로 되돌아왔다.  
해결책으로 해당 로컬 네트워크의 속성에서 **Hyper-V 확장 가능 가상 스위치** 항목의 체크를 끈 후, WSL 가상 스위치의 연결 형식을 **외부 네트워크**로 변경하였더니, 로컬 네트워크와 WSL 배포판의 NFS도 다시 정상적으로 동작하였다.  
즉, Windows를 재부팅 할 때마다 이 작업을 수동으로 해 주어야 하는 불편함이 있다. (WSL 가상 스위치의 연결 형식을 원하는 **외부 네트워크**로 변경하는 것은 간단한 커맨드로 가능한데, 해당 로컬 네트워크의 속성에서 **Hyper-V 확장 가능 가상 스위치** 항목의 체크를 끄는 커맨드는 알아내지 못했음)

## Linux에서 NFS 마운트하기
NFS 마운트는 간단히 아래 예와 같이 할 수 있다.
```shell
$ sudo mount -o nolock 192.168.0.180:/opt/nfs /mnt/nfs/
```
만약 특정 NFS 버전을 명시하려면 아래 예와 `-o` 옵션으로 <mark style='background-color: #ffdce0'>vers=n</mark>이나 <mark style='background-color: #ffdce0'>nfsvers=n</mark> 형태로 지정하면 된다.
```shell
$ sudo mount -o nolock,vers=3 192.168.0.180:/opt/nfs /mnt/nfs/
```
마운트를 끊으려면 아래와 같이 한다.
```shell
$ sudo umount /mnt/nfs/
```

## Windows에서 NFS 마운트하기
Windows에서 NFS 클라이언트를 사용하여 다른 NFS 서버에 접속할 일은 별로 없긴 한데, 필요하면 아래와 같이 할 수 있다.
1. `Windows 기능 켜기/끄기`를 실행한 후 (또는 콘솔에서 `OptionalFeatures.exe` 실행), `NFS용 서비스` 항목의 체크를 켠다.  
   결과로 <font color=blue>mount</font>, <font color=blue>umount</font> 명령이 활성화된다.
1. 이후 탐색기에서 `네트워크 드라이브 연결`을 실행하여 NFS 마운트하려는 호스트 주소와 NFS 경로를 입력하면 NFS로 마운트된다.  
   또는 콘솔에서 아래 예와 같이 마운트시킬 수 있다. (아래에서는 예를 들어 위의 WSL NFS 디렉터리를 **N** 드라이브에 마운트 함)
   ```bat
   C:\>mount \\192.168.0.180\opt\nfs N:
   ```
   콘솔에서 아래와 같이 실행하면 마운트된 디렉터리와 속성을 확인할 수 있다.
   ```bat
   C:\>mount
   ```
1. 마운트를 끊으려면 아래와 같이 한다. (아래 예에서는 **N** 드라이브의 마운트를 끊음)
   ```bat
   C:\>umount N:
   ```

## WSL NFS 서버 혼합 방법
위의 Hyper-V 관리자를 이용한 방법의 단점은 Windows를 재부팅하면 가상 스위치 연결 형식이 다시 디폴트로 돌아와 버려서 매번 재설정해야 한다는 것이다.  
그래서 나는 현재 이 방법 대신에 아래와 같은 WinNFSd 툴을 이용한 방식을 사용하고 있다.
1. [WSL2에서 삼바(Samba) 서버 사용하기](https://yrpark99.github.io/windows/wsl2_samba/) 페이지에서 설명한 방식으로 WSL에 **192.168** 대역의 IP를 할당한다.
1. WSL의 내 유저 디렉터리에서 NFS 디렉터리를 symbolic link로 만들어서 삼바 경로로 NFS 디렉터리가 access 되게 만든다. (예로 **nfs** 이름으로 생성)  
참고로 삼바의 symbolic link가 동작되게 하려면 samba 설정 파일(`/etc/samba/smb.conf`)의 `[global]` 섹션에 아래 내용을 추가해야 한다.
   ```ini
   wide links = yes
   unix extensions = no
   ```
1. 이후 Windows에서 WinNFSd 툴을 이용하여 아래와 같이 삼바 NFS 경로로 NFS 서버를 실행시킨다. (아래 예에서는 내 WSL 유저 디렉터리를 네트워크 드라이브 **W** 이름으로 연결한 경우)
   ```bat
   C:\>WinNFSd.exe -log off W:\nfs /exports
   ```
   Windows 부팅시마다 자동으로 이 명령을 실행하도록 하려면, 해당 내용으로 배치 파일을 작성한 후, Windows + R 키를 눌러서 `shell:startup` 명령을 실행하면 열리는 경로에 넣으면 된다.
1. 이제 NFS 클라이언트 디바이스에서 아래 예와 같이 NFS 마운트시킬 수 있다. (내 Windows PC의 IP가 **192.168.0.2** 인 경우)
   ```sh
   $ sudo mount -o nolock 192.168.0.2:/exports/ /mnt/
   ```

> 참고로 WinNFSd 툴은 NFS server 포트로 2049, mount daemon 포트로 1058을 사용하는데, 이 중의 하나가 이미 사용 중이면 관련 로그를 출력하면서 실패한다.  
이 경우에는 해당 포트를 사용하는 프로세스를 찾아서 중단시키면 된다. 예를 들어 각각의 포트를 사용 중인 프로세스 ID는 다음과 같이 얻을 수 있다.
```bat
C:\>netstat -ano | find "2049"
C:\>netstat -ano | find "1058"
```
만약에 위 결과로 리스트가 나온다면 맨 마지막 컬럼 값이 **PID**(Process ID)이므로 이 값을 `작업 관리자`에서 찾으면 해당 포트를 사용 중인 프로그램이나 서비스를 찾을 수 있다.

## 맺음말
몇 번의 시행 착오가 있었지만 😅, 외부 디바이스에서 WSL을 NFS 마운트해서 개발할 수 있게 되어 WSL의 사용 편의성이 좀 더 좋아졌다.
