---
title: "Windows에서 NFS 서버 설치"
category: Windows
toc: true
toc_label: "이 페이지 목차"
---

Windows에서 NFS 서버를 설치하는 방법을 소개한다.

<br>
보통 Windows를 개발 서버로 쓰는 일은 드물어서 Linux 서버와는 다르게 Windows를 NFS 서버로 사용할 일은 별로 없지만, 필요한 경우에 참조하기 위하여 기록한다.

## Windows Server에서 NFS 서버 설치
Windows Server는 자체적으로 NFS 서버 기능을 제공하므로 별도의 설치가 필요하지 않고, 제공하는 기능을 이용하여 설정을 하면 된다. (나는 Windows Server를 사용하지 않으므로 상세 내용은 pass)

## Windows 7/10/11에서 NFS 서버 설치
Windows 7/10/11에서는 OS 자체적으로는 NFS 서버 기능을 지원하지 않으므로, [WinNFSd](https://github.com/winnfsd/winnfsd) 툴을 이용하여 아래와 같이 할 수 있다.
1. Windows에서 아래 예와 같이 NFS 서버 프로그램을 실행시킨다. (아래 예에서는 현재 디렉토리를 NFS 디렉토리로 사용, export 경로를 **/exports**로 지정)
   ```bat
   C:\>WinNFSd.exe . /exports
   ```
   NFS 관련 로그 출력이 나오지 않게 하려면 아래 예와 같이 **-log off** 옵션을 추가하면 된다.
   ```bat
   C:\>winnfsd -log off . /exports
   ```
1. 이후 Linux 클라이언트에서 아래 예와 같이 NFS 마운트시킬 수 있다.
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
   NFS 디렉토리로 /opt/nfs/ 디렉토리를 생성한 후, /etc/exports 파일에서 아래 예와 같이 추가한다.
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
1. `Windows 기능 켜기/끄기`를 실행한 후 (또는 콘솔에서 `OptionalFeatures.exe` 실행), **Hyper-V** 항목의 체크를 켠다.
1. `Hyper-V 관리자`를 관리자 권한으로 실행시킨 후, 해당 가상 컴퓨터에서 `가상 스위치 관리자` 항목을 클릭한다.  
   가상 스위치 항목 중에서 "WSL" 항목을 선택한 후, 아래 캡쳐와 같이 **연결 형식**을 디폴트 <font color=purple>내부 네트워크</font>에서 <font color=purple>외부 네트워크</font>로 변경하고 사용할 이더넷 장치를 선택한다.
   <p><img src="/assets/images/hyperv_switch_setting.png"></p>
   **확인** 버튼을 눌러서 변경 사항을 적용한다.
1. 변경 내용이 적용되었으면 다시 WSL에 로그인 후, 아래와 같이 실행한다.
   ```shell
   $ sudo ip addr flush dev eth0
   $ sudo dhclient eth0
   ```
   결과로 아래 예와 같이 eth0 장치가 IP를 192.168.0.XXX로 할당받았음을 확인할 수 있다. (나의 경우 공유기에서 DHCP로 192.168.0.XXX로 할당하게 세팅해놨음)
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
   외부 디바이스에서 위 192 대역의 IP로 ping 테스트를 해 보면 ping이 잘 됨을 확인할 수 있다.
1. 이제 아래와 같이 RPC bind 서비스와 NFS 서버를 start 시킨다.
   ```shell
   $ sudo mkdir -p /run/sendsigs.omit.d/
   $ sudo service rpcbind start
   $ sudo /etc/init.d/nfs-kernel-server start
   ```
1. 외부 디바이스에서 WSL 주소로 NFS 마운트를 해보면 잘된다. 😋  
   (단, WSL을 재시작시키면 DHCP IP 할당과 NFS 서버 시작을 다시 시켜줘야 한다)

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
   또는 콘솔에서 아래 예와 같이 마운트시킬 수 있다. (아래에서는 예를 들어 위의 WSL NFS 디렉토리를 **N** 드라이브에 마운트 함)
   ```bat
   C:\>mount \\192.168.0.180\opt\nfs N:
   ```
   콘솔에서 아래와 같이 실행하면 마운트된 디렉토리와 속성을 확인할 수 있다.
   ```bat
   C:\>mount
   ```
1. 마운트를 끊으려면 아래와 같이 한다. (아래 예에서는 **N** 드라이브의 마운트를 끊음)
   ```bat
   C:\>umount N:
   ```
