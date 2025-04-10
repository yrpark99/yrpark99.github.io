---
title: "LXC 실습"
category: [Linux]
toc: true
toc_label: "이 페이지 목차"
---

간단히 LXC(LinuX Containers)를 실습해 본다.

## LXC
LXC는 Linux Containers의 줄임말로, Linux 커널의 기능을 활용하여 격리된 환경에서 애플리케이션을 실행할 수 있도록 한다.  

LXC는 다음과 같은 Linux 커널 기능들을 사용하여 격리된 환경을 구현한다.
- Kernel CGroups (control groups): 자원에 대한 제어를 가능하게 해 주고, 아래와 같은 리소스들을 제어할 수 있다.
  - 메모리
  - CPU
  - I/O
  - 네트워크
  - device node (/dev/)
- Kernel namespaces: 독립적인 공간을 제공, 아래와 같은 namespace가 있다.
  - **ipc**: 프로세스 간의 독립적인 SystemV IPC 통신 통로 할당
  - **mnt**: 독립적인 파일시스템 mount/unmount 가능
  - **net**: 독립적인 network interface 할당
  - **pid**: 독립적인 프로세스 공간을 할당
  - **user**: 독립적인 user 할당
  - **uts**: 독립적인 host name 할당
- Kernel capabilities: capability 제한 (lxc-setcap 명령어 참조)
- Chroot: 파일 시스템에서 root 경로를 변경 (pivot_root 사용)
- clone(): 새로운 namespace를 생성하여 프로세스를 만듬 (예: CLONE_NEWPID 플래그를 사용하면 새로운 PID namespace를 생성)

Linux namespace는 주요 시스템 공간을 격리하여 할당할 수 있게 해주고, cgroups는 주요 시스템의 리소스 사용을 제한할 수 있게 해준다. 이를 통해 프로세스의 격리와 리소스 사용 제한을 동시에 달성하는 컨테이너를 생성할 수 있다.​

참고로 LXC의 컨테이너는 다음 2가지로 분류할 수 있다.
- `init`을 처음 시작하여 보통의 OS가 시작하는 것과 같은 환경: **system 컨테이너**라고 부름
- 목적에 맞는 프로세스만 존재하는 환경: **application 컨테이너**라고 부름

필요시 아래 LXC 소스와 문서도 참고한다.
- [LXC 소스](https://github.com/lxc/lxc)
- [LXC 문서](https://linuxcontainers.org/lxc/)

> 컨테이너 기능을 제공하는 **Docker**는 LXC를 기반으로 시작했지만, 이후 독자적인 **Dockerfile**과 같은 선언적 설정 파일을 통해 컨테이너를 쉽게 정의하고 배포할 수 있고, 계층화된 이미지 시스템을 사용하여 빠르게 업데이트가 가능하고, [Docker Hub](https://hub.docker.com/)와 같은 이미지 레지스트리를 지원하여 생산성을 높이고, 대규모 배포에도 적합하도록 발전하여 방대한 생태계를 갖추게 되었다.

## PID namespace 테스트
1. 아래와 같이 cgroups feature를 확인할 수 있다.
   ```sh
   $ cat /proc/cgroups
   ```
1. 프로세스가 사용할 수 있는 namespace 목록은 아래와 같이 얻을 수 있다.
   ```sh
   $ ls /proc/$$/ns/
   ```
1. 아래와 같이 PID namespace를 테스트해 볼 수 있다.
   ```sh
   $ sudo unshare --fork --pid --mount-proc bash
   # ps -ef
   UID          PID    PPID  C STIME TTY          TIME CMD
   root           1       0  0 15:50 pts/1    00:00:00 bash
   root          11       1  0 15:52 pts/1    00:00:00 ps -ef
   ```
   즉, PID 격리된 환경에서 전체 프로세스를 확인해 보면 bash 프로세스가 PID 1로 할당되어 있음을 볼 수 있고, 호스트 환경에서의 ps 결과와 전혀 다름을 확인할 수 있다.

## 우분투에서 LXC 실습
1. 우분투에서는 아래와 같이 LXC 패키지를 설치할 수 있다.
   ```sh
   $ sudo apt install lxc lxc-utils lxc-templates
   ```
   LXC 템플릿 목록은 아래와 같이 확인할 수 있다.
   ```sh
   $ ls /usr/share/lxc/templates/
   ```
1. 아래와 같이 **test-container** 이름으로 Ubuntu base LXC 컨테이너를 생성한다.
   ```sh
   $ sudo lxc-create -n test-container -t ubuntu
   ```
   참고로 config 파일을 작성한 후에 아래 옝와 같이 이것을 사용하여 LXC 컨테이너를 생성할 수도 있다.
   ```sh
   $ sudo lxc-create -n test-container -f {config_파일} -t ubuntu
   ```
   결과로 **test-container**가 **/var/lib/lxc/test-container/** 디렉토리에 구성된다.  
   이 디렉토리에서 config 파일을 확인해 보면 아래 예와 같이 나온다.
   ```sh
   $ sudo cat /var/lib/lxc/test-container/config
   # Template used to create this container: /usr/share/lxc/templates/lxc-ubuntu
   # Parameters passed to the template:
   # For additional config options, please look at lxc.container.conf(5)

   # Uncomment the following line to support nesting containers:
   #lxc.include = /usr/share/lxc/config/nesting.conf
   # (Be aware this has security implications)

   # Common configuration
   lxc.include = /usr/share/lxc/config/ubuntu.common.conf

   # Container specific configuration
   lxc.rootfs.path = dir:/var/lib/lxc/test-container/rootfs
   lxc.uts.name = test-container
   lxc.arch = amd64

   # Network configuration
   lxc.net.0.type = veth
   lxc.net.0.link = lxcbr0
   lxc.net.0.flags = up
   lxc.net.0.hwaddr = 00:16:3e:fb:86:be
   ```
   또, rootfs를 확인해 보면 아래 예와 같이 나온다.
   ```sh
   $ sudo ls -l /var/lib/lxc/test-container/rootfs/
   total 60
   lrwxrwxrwx  1 root root    7 Apr  8 17:49 bin -> usr/bin
   drwxr-xr-x  2 root root 4096 Apr 18  2022 boot
   drwxr-xr-x  3 root root 4096 Apr  8 17:52 dev
   drwxr-xr-x 63 root root 4096 Apr  8 17:52 etc
   drwxr-xr-x  3 root root 4096 Apr  8 17:52 home
   lrwxrwxrwx  1 root root    7 Apr  8 17:49 lib -> usr/lib
   lrwxrwxrwx  1 root root    9 Apr  8 17:49 lib32 -> usr/lib32
   lrwxrwxrwx  1 root root    9 Apr  8 17:49 lib64 -> usr/lib64
   lrwxrwxrwx  1 root root   10 Apr  8 17:49 libx32 -> usr/libx32
   drwxr-xr-x  2 root root 4096 Apr  8 17:49 media
   drwxr-xr-x  2 root root 4096 Apr  8 17:49 mnt
   drwxr-xr-x  2 root root 4096 Apr  8 17:49 opt
   drwxr-xr-x  2 root root 4096 Apr 18  2022 proc
   drwx------  2 root root 4096 Apr  8 17:49 root
   drwxr-xr-x  9 root root 4096 Apr  8 17:52 run
   lrwxrwxrwx  1 root root    8 Apr  8 17:49 sbin -> usr/sbin
   drwxr-xr-x  2 root root 4096 Apr  8 17:49 srv
   drwxr-xr-x  2 root root 4096 Apr 18  2022 sys
   drwxrwxrwt  2 root root 4096 Apr  8 17:52 tmp
   drwxr-xr-x 14 root root 4096 Apr  8 17:49 usr
   drwxr-xr-x 11 root root 4096 Apr  8 17:49 var
   ```
   테스트로 **root** 계정으로 암호없이 로그인하기 위하여 **/var/lib/lxc/test-container/rootfs/etc/passwd** 파일에서 아래와 같이 **root** 사용자의 암호를 없앤다.
   ```
   root::0:0:root:/root:/bin/bash
   ```
1. LXC 컨테이너 목록을 출력해 보면 아래와 같이 test-container가 **STOPPED** 상태로 표시된다.
   ```sh
   $ sudo lxc-ls --fancy
   NAME           STATE   AUTOSTART GROUPS IPV4 IPV6 UNPRIVILEGED
   test-container STOPPED 0         -      -    -    false
   ```
1. 아래와 같이 LXC 컨테이너를 실행시킨다. (`-d`는 background 실행 옵션)
   ```sh
   $ sudo lxc-start -n test-container -d
   ```
   다시 아래와 같이 LXC 컨테이너 상태를 출력해 보면, test-container가 **RUNNING** 상태로 표시된다.
   ```sh
   $ sudo lxc-ls --fancy
   NAME           STATE   AUTOSTART GROUPS IPV4       IPV6 UNPRIVILEGED
   test-container RUNNING 0         -      10.0.3.154 -    false
   ```
1. 아래와 같이 LXC 컨테이너에 콘솔로 접속하여 **root** 계정으로 로그인할 수 있다. (위에서 root 암호를 없앴으므로 엔터키를 누르면 로그인이 됨)
   ```sh
   $ sudo lxc-console -n test-container
   test-container login: root
   ```
1. LXC 컨테이너에서 테스트로 아래와 같이 **nginx** 패키지를 설치한다.
   ```sh
   # apt-get update
   # apt-get install nginx
   # service nginx start
   ```
1. LXC 컨테이너에서 현재 network 설정을 확인한다. (10.0.3.0, 10.0.3.143 주소는 환경마다 다를 수 있음)
   ```sh
   # iptables -t nat -L
   Chain PREROUTING (policy ACCEPT)
   target     prot opt source               destination
   Chain INPUT (policy ACCEPT)
   target     prot opt source               destination
   Chain OUTPUT (policy ACCEPT)
   target     prot opt source               destination
   Chain POSTROUTING (policy ACCEPT)
   target     prot opt source               destination
   MASQUERADE  all  --  10.0.3.0/24         !10.0.3.0/24
   ```
   이후 아래 예와 같이 포트 포워딩 규칙을 추가한다.
   ```sh
   # iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j DNAT --to 10.0.3.143:80
   ```
1. 이후 PC에서 Web browser로 host IP 주소에 접속했을 때 "Welcome to nginx!"가 뜨면 성공이다.
1. 컨테이너 정지는 아래 예와 같이 할 수 있다.
   ```sh
   $ sudo lxc-stop -n test-container
   ```
1. 컨테이너 삭제는 아래 예와 같이 할 수 있다.
   ```sh
   $ sudo lxc-destroy -n test-container
   ```
   결과로 **/var/lib/lxc/test-container/** 디렉토리가 삭제된다.

> 위에서 보듯이 LXC 컨테이너의 대체적인 사용법은 `Docker`와 유사하다.

## 디바이스에서 LXC 환경 준비
1. Kernel 빌드  
   Kernel config에서 아래 옵션들을 enable 한다. (Kernel 버전에 따라 다를 수 있음)  
   ```
   General setup
     Control Group support (CONFIG_CGROUPS)
     Namespaces support (CONFIG_NAMESPACES)
   Device Drivers
     Character devices
       Unix98 PTY support (CONFIG_UNIX98_PTYS)
     Network device support
       MAC-VLAN support (CONFIG_MACVLAN)
       Virtual ethernet pair device (CONFIG_VETH)
   Networking support (CONFIG_NET)
     Networking options
       802.1d Ethernet Bridging (CONFIG_BRIDGE)
       802.1Q VLAN Support (CONFIG_VLAN_8021Q)
   ```
   이후 Kernel을 빌드한다.
1. Busybox 빌드  
   Busybox는 동적 링크 대신에 정적 링크를 사용하는 것이 편리하다. 아래와 같이 meuconfig 한 후에,
   ```sh
   $ make menuconfig
   ```
   **Busybox Settings** -> **Build Options** -> **Build BusyBox as a static binary (no shared libs)** 항목의 체크를 켠다.  
   또한, Busybox 모듈의 .config 파일에서 아래와 같이 옵션을 수정한 후 빌드한다.
   ```make
   CONFIG_ID=y
   CONFIG_GETOPT=y
   CONFIG_FEATURE_GETOPT_LONG=y
   CONFIG_PASSWD=y
   CONFIG_CHPASSWD=y
   ```
   예를 들어 CONFIG_GETOPT 옵션이 enable 되어 있지 않으면, **lxc-create** 실행 중에 아래와 같은 에러가 발생할 수 있다.
   ```
   /usr/local/share/lxc/templates/lxc-busybox: line 322: getopt: command not found
   ```
1. LXC 빌드  
   예를 들어 아래와 같이 LXC 소스를 다운받아서 압축을 푼다. (v1.1.5 예제)
   ```sh
   $ wget https://github.com/lxc/lxc/archive/refs/tags/lxc-1.1.5.tar.gz
   $ tar xfz lxc-1.1.5.tar.gz
   $ cd lxc-lxc-1.1.5/
   ```
   아래와 같이 실행하면 configure 파일이 생성된다.
   ```sh
   $ ./autogen.sh
   ```
   이제 아래 예와 같이 configuration 한다.
   ```sh
   $ ./configure --host=mipsel-linux --disable-doc --disable-api-docs
   ```
   참고로 LXC 관련 디폴트 경로는 configure 설정시 아래 옵션으로 변경할 수 있다.
   ```sh
   --with-runtime-path=dir: runtime directory (default: /run)
   --with-config-path=dir: lxc configuration repository path
   --with-global-conf=dir: global lxc configuration file
   --with-rootfs-path=dir: lxc rootfs mount point
   --with-log-path=dir: per container log path
   ```
   이후 아래와 같이 빌드한다.
   ```sh
   $ make
   ```
1. 아래와 같이 $ROOTFS 경로에 lxc 패키지를 구성한다.
   ```sh
   $ mkdir -p $ROOTFS/usr/local/lib/lxc/rootfs
   $ cp -af src/lxc/lxc-* $ROOTFS/bin/
   $ cp -af src/lxc/.libs/liblxc.so* $ROOTFS/lib/
   ```
1. $ROOTFS 경로의 /etc/init.d/rcS 파일에 아래와 같이 추가한다.
   ```sh
   #!/bin/sh
   mount proc /proc -t proc -o rw,nosuid,nodev,noexec
   mount -o nosuid,nodev,noexec -t sysfs sys /sys
   mount -t devpts devpts /dev/pts -o nosuid,noexec
   mount -t cgroup cgroup /sys/fs/cgroup -o nodev,noexec,nosuid
   ```

## 디바이스에서 LXC 테스트
1. 디바이스에서 **lxc-checkconfig** 툴로 설정을 확인할 수 있다. (아래 발췌 예제 참고)
   ```sh
   # /usr/bin/lxc-checkconfig
   --- Namespaces ---
   Namespaces: enabled
   Utsname namespace: enabled
   Ipc namespace: enabled
   Pid namespace: enabled
   User namespace: enabled
   Network namespace: enabled
   Multiple /dev/pts instances: enabled
   --- Control groups ---
   Cgroup: enabled
   Cgroup clone_children flag: enabled
   Cgroup device: enabled
   Cgroup sched: enabled
   Cgroup cpu account: enabled
   Cgroup memory controller: enabled
   --- Misc ---
   Veth pair device: enabled
   Macvlan: enabled
   Vlan: enabled
   File capabilities: enabled
   ```
1. cgroup 마운트 테스트  
   STB 부팅 후, 아래와 같이 cgroup 마운트를 확인할 수 있다.
   ```sh
   # mount | grep cgroup
   cgroup on /cgroup type cgroup (rw,nosuid,nodev,noexec,relatime,net_prio,freezer,devices,memory,cpuacct,cpu,cpuset)
   ```
   아래와 같이 cgroup이 지원하는 subsystem 목록을 확인할 수 있다. (커널 config에서 선택한 subsystem에 따라 다르게 나옴)
   ```sh
   # cat /proc/cgroups
   ```
   또, 아래와 같이 cgroup 디렉토리 목록을 보면 각 subsystem 별 파일 리스트가 출력된다.
   ```sh
   # ls -l /sys/fs/cgroup/
   ```
   아래와 같이 PID에 대하여 namespace를 확인할 수 있다.
   ```sh
   # ls /proc/${PID}/ns/
   # ls /proc/$$/ns/
   ```
   또, 아래와 같이 cgroup 테스트를 할 수 있다. (정상적으로 디렉토리 생성되어야 함)
   ```sh
   # mkdir -p /sys/fs/cgroup/lxc/container1
   ```
1. 테스트로 rootfs의 /opt/lxc/container1/ 경로를 만들고 container 이미지를 구성해 본다.  
   Busybox template로 생성한 rootfs를 복사한 후, 아래와 같이 구성한다. (편의상 sh, busybox는 root의 것을 bind하여 사용)
   ```sh
   $ rm -f opt/lxc/container1/bin/*
   $ rm -f opt/lxc/container1/sbin/init
   $ touch opt/lxc/container1/bin/sh
   $ touch opt/lxc/container1/bin/busybox
   $ touch opt/lxc/container1/bin/echo
   $ touch opt/lxc/container1/bin/ls
   $ touch opt/lxc/container1/bin/mount
   ```
   $ROOTFS/opt/lxc/container1/etc/init.d/rcS 파일을 아래 예와 같이 구성한다.
   ```sh
   #!/bin/sh
   echo "LXC container1 /etc/init.d/rcS"
   ```
1. 해당 컨테이너용 LXC config 파일로 사용할 $ROOTFS/opt/lxc/container1.conf 파일을 아래 예와 같이 구성한다.
   ```toml
   lxc.utsname = container1
   lxc.rootfs = /opt/lxc/container1
   lxc.console = none
   lxc.autodev = 1

   # devices
   lxc.cgroup.devices.deny = a
   lxc.cgroup.devices.allow = c 1:3 rwm # dev/null
   lxc.cgroup.devices.allow = c 1:5 rwm # dev/zero
   lxc.cgroup.devices.allow = c 1:1 rwm # dev/mem
   lxc.cgroup.devices.allow = c 30:0 rwm #dev/brcm0
   lxc.cgroup.devices.allow = c 5:1 rwm # dev/console
   lxc.cgroup.devices.allow = c 5:0 rwm # dev/tty
   lxc.cgroup.devices.allow = c 4:0 rwm # dev/tty0
   lxc.cgroup.devices.allow = c 1:9 rwm # dev/urandom
   lxc.cgroup.devices.allow = c 1:8 rwm # dev/random
   lxc.cgroup.devices.allow = c 136:* rwm # dev/pts/*
   lxc.cgroup.devices.allow = c 5:2 rwm # dev/pts/ptmx

   # mount bin
   lxc.mount.entry=/bin/sh /opt/lxc/container1/bin/sh none bind,ro,nosuid,nodev 0 0
   lxc.mount.entry=/bin/busybox /opt/lxc/container1/bin/busybox none bind,ro,nosuid,nodev 0 0
   lxc.mount.entry=/bin/echo /opt/lxc/container1/bin/echo none bind,ro,nosuid,nodev 0 0
   lxc.mount.entry=/bin/ls /opt/lxc/container1/bin/ls none bind,ro,nosuid,nodev 0 0
   lxc.mount.entry=/bin/mount /opt/lxc/container1/bin/mount none bind,ro,nosuid,nodev 0 0

   # mount libs
   lxc.mount.entry=/lib /opt/lxc/container1/lib none bind,ro,nosuid,nodev 0 0

   # mount tmp
   lxc.mount.entry = tmpfs /tmp tmpfs nosuid,nodev,noexec,mode=1777,create=dir 0 0
   ```
1. 디바이스에서 LXC start 테스트 (디폴트 경로 대신에 /opt/lxc/container1 경로를 사용)  
   (lxc-start는 실행할 command가 주어지지 않은 경우 lxc.init_cmd에 있는 커맨드를 실행하고, 이 파일이 없으면 디폴트로 "/sbin/init"을 실행함)
   ```sh
   # lxc-start --name=container1 --foreground --rcfile=/opt/lxc/container1.conf --lxcpath=/opt/lxc/container1 hostname
   container1
   ```
   기대대로 hostname이 container1으로 출력된다.
1. 디바이스에서 lxc-execute 테스트  
   rootfs를 /usr/local/lib/lxc/rootfs/ 경로에서 찾으므로 아래와 같이 링크를 걸어준다.
   ```sh
   # ln -s /usr/local/var/lib/lxc/container1/rootfs/ /usr/local/lib/lxc/rootfs/
   # lxc-execute --name=container1 --rcfile=/opt/lxc/container1.conf --lxcpath=/opt/lxc/container1 /bin/sh
   ```
   만약 실행에 문제가 있으면, 아래 예와 같이 옵션을 준 후, 생성된 로그 파일을 보면 됨 (다른 명령어도 마찬가지)
   ```sh
   # lxc-start --name=container1 --rcfile=/opt/lxc/container1.conf --lxcpath=/opt/lxc/container1 --logfile=a.txt --logpriority=debug
   ```
   이제부터는 container 환경에서 동작한다. 컨테이너에서 아래와 같이 proc 파일 시스템을 마운트 시킨 후, hostname으로 확인할 수 있다.
   ```
   # mount -t proc none /proc
   # hostname
   container1
   ```
1. 디바이스에서 Ethernet bridge 생성 예 (brctl 커맨드 사용, 예로 lxcbr0 생성)  
   Config 파일에서 `lxc.network.type = veth`와 같이 세팅한 경우에는, 컨테이너를 실행하기 전에 아래 예와 같이 Ethernet bridge를 생성해야 한다.
   ```sh
   # brctl addbr lxcbr0
   # brctl setfd lxcbr0 0
   # ifconfig lxcbr0 192.168.0.1 promisc up
   # ifconfig
   lxcbr0    Link encap:Ethernet  HWaddr 56:2F:4F:93:A6:50
           inet addr:192.168.0.1  Bcast:192.168.0.255  Mask:255.255.255.0
           UP BROADCAST RUNNING PROMISC MULTICAST  MTU:1500  Metric:1
           RX packets:0 errors:0 dropped:0 overruns:0 frame:0
           TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
           collisions:0 txqueuelen:0
           RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)
   eth0      Link encap:Ethernet  HWaddr 00:08:B9:00:00:73
           inet addr:172.16.7.73  Bcast:172.16.7.255  Mask:255.255.255.0
           UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
           RX packets:219979 errors:0 dropped:13908 overruns:0 frame:0
           TX packets:2826 errors:0 dropped:0 overruns:0 carrier:0
           collisions:0 txqueuelen:1000
           RX bytes:44500992 (42.4 MiB)  TX bytes:403896 (394.4 KiB)
   lo        Link encap:Local Loopback
           inet addr:127.0.0.1  Mask:255.0.0.0
           UP LOOPBACK RUNNING  MTU:16436  Metric:1
           RX packets:29 errors:0 dropped:0 overruns:0 frame:0
           TX packets:29 errors:0 dropped:0 overruns:0 carrier:0
           collisions:0 txqueuelen:0
           RX bytes:2684 (2.6 KiB)  TX bytes:2684 (2.6 KiB)
   # brctl addif lxcbr0 eth0
   device eth0 entered promiscuous mode
   lxcbr0: port 1(eth0) entering forwarding state
   lxcbr0: port 1(eth0) entering forwarding state
   # route add -net default gw <host default gateway>
   ```

## LXC config 파일
LXC config 파일은 아주 복잡한데 (특히 보안 관련), 여기서는 기본적인 부분만 일부 나열한다.
1. `devices` 관련  
   먼저 아래와 같이 전체(all) device에 대한 엑세스를 deny 시킨다. (보안 관점에서 실제 액세스가 필요한 device만 allow 하기 위함)
   ```toml
   lxc.cgroup.devices.deny = a
   ```
   이후 아래 예와 같이 필요한 device node를 권한과 함께 allow 시킨다.
   ```toml
   lxc.cgroup.devices.allow = c 1:2 rw
   lxc.cgroup.devices.allow = b 8:0 rw
   ```
1. `network` 관련  
   아래 예와 같이 설정할 수 있다. (Network 설정이 없으면 host와 컨테이너가 network을 공유함)
   ```toml
   lxc.network.type = veth
   lxc.network.name: "eth0"
   lxc.network.veth.pair: "br1"
   lxc.network.ipv4 = 192.168.0.1/24
   lxc.network.link = lxcbr0
   lxc.network.flags = up
   ```
   * **lxc.network.type**: 다음 중에서 선택할 수 있다.
     - empty: 네트워크 인터페이스 없음
     - none: 호스트 네트워크 인터페이스가 보이지만 실제 네트워크 통신은 불가능함
     - phys: lxc.network.link로 지정한 호스트 네트워크 인터페이스를 생성하여 사용함
     - veth: 사전에 lxc.network.link 이름으로 생성된 bridge 사용, host와 통신시 사용, 직접 외부 연결은 안됨
     - macvlan: lxc.network.link 이름으로 생성하여 사용함, 직접 외부 연결됨
   * **lxc.network.name**: 컨테이너 안에서 보이는 네트워크 이름
   * **lxc.network.veth.pair**: 호스트에서 보이는 컨테이너 브리지 네트워크 이름
1. `capability` 관련  
   아래 예와 같이 capability drop 시킬 것들을 lxc.cap.drop 파일에 list up 한다.
   ```toml
   lxc.cap.drop = mac_admin mac_override mknod net_raw setfcap setpcap sys_boot sys_module sys_nice sys_pacct sys_rawio sys_resource sys_time sys_admin
   ```
   또는 아래 예와 같이 유지할 capability만 나열하면, 리스트된 capability 외는 모두 제거된다.
   ```toml
   lxc.cap.keep = sys_boot
   ```
1. 컨테이너 자체의 proc, sys 생성하기
   ```toml
   lxc.mount.entry = proc proc proc nodev,noexec,nosuid 0 0
   lxc.mount.entry = sysfs sys sysfs nodev,noexec,nosuid 0 0
   ```
   또는 아래와 같이 할 수 있다.
   ```
   lxc.mount.auto = proc:mixed sys:ro
   ```
1. 컨테이너에서 콘솔 disable 시키기
   ```toml
   lxc.pts = 0
   lxc.tty = 0
   lxc.console = none
   ```

## 맺음말
임베디드 디바이스에서는 격리된 컨테이너 환경이 필요할 때, 여러 리소스 제한으로 인하여 Docker와 같은 솔류션을 사용하기는 힘든데, 대안으로 가벼운 LXC 컨테이너를 사용할 수 있다.  
나는 예전에 실제로 임베디드 디바이스에 여러 개의 system LXC 컨테이너를 구성하고 서로 다른 컨테이너 안에 있는 app끼리 통신도 하게 하였는데, 컨테이너를 사용하지 않을 때와 비교하여 메모리나 CPU 사용량이 거의 늘지 않고도, 각각 격리된 환경에서 app가 정상 동작하였다. 또한 시스템의 안정성과 보안을 위하여 격리된 환경을 구성한 것이었으므로 여러가지 보안 정책도 함께 구현했었다.  
다만 이 내용은 너무 방대하므로 여기서는 다루지 않고, 간단히 LXC를 소개하는 정도로 마무리한다.
