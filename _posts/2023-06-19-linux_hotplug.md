---
title: "Linux에서 USB, Ethernet hot plug 처리"
category: Linux
toc: true
toc_label: "이 페이지 목차"
---

Linux에서 USB, Ethernet 장치의 hot plug 처리에 대해서 정리한다.

## 정리 동기
회사 디바이스에서 USB 장치의 hot plug 처리가 복잡하게 되어 있었고, Ethernet 장치의 hot plug는 제대로 처리되어 있지 않아서 이를 수정하였다.

## Linux에서 hot plug 처리
1. Kernel 버전에 따라서 `CONFIG_HOTPLUG` 항목이 있는 경우에는 아래와 같이 enable 되어 있어야 한다.
   ```ini
   CONFIG_HOTPLUG=y
   ```
1. 위 설정을 enable 하면 함께 자동으로 enable 되는 설정이 있는데, 이 중에서 아래와 같이 hot plug 이벤트 발생시 호출할 스크립트의 경로 설정이 있다.
   ```ini
   CONFIG_UEVENT_HELPER_PATH="/sbin/hotplug"
   ```
1. Hot plug 이벤트시 실행될 스크립트(**agent**라고도 부름)를 위와 같은 Kernel 디폴트 값이 아닌 다른 경로로 변경하고 싶으면 `/proc/sys/kernel/hotplug` 파일에 지정하면 된다.  
디바이스 장치에서는 rootfs의 init 스크립트에서 세팅하면 된다.
1. Kernel은 hot plug 이벤트가 감지되면 적절한 환경 변수를 세팅하여 `/proc/sys/kernel/hotplug`에 등록된 agent를 호출한다.
1. Hot plug 이벤트 스크립트에서는 USB의 경우 `ACTION`, `DEVPATH`, `PRODUCT`, `INTERFACE`, `TYPE` 등의 환경 변수가 전달된다.  
   만약에 "**usbdevfs**"가 설정된 경우에는 `DEVICE`, `DEVFS` 환경 변수도 전달된다.

## mdev 이용법
- `mdev`는 mini udev를 뜻하고, **udev**의 경량화 버전이라고 볼 수 있는데, Busybox에도 포함되어 있어서 많이 사용되고 있다.  
참고로 Busybox에 구현된 mdev는 데몬 형태가 아니고, netlink를 사용하지도 않는다. 따라서 커널 config에서 네트워크가 완전히 빠지는 경우에도 사용할 수가 있다.

1. 아래 예와 같이 `/proc/sys/kernel/hotplug` 파일에 **mdev**를 설정한다.
   ```sh
   $ sudo echo "/sbin/mdev" > /proc/sys/kernel/hotplug
   ```
1. **mdev**는 실행시 `/etc/mdev.conf` 파일에 명시된 설정 파일을 참조한다. `/etc/mdev.conf` 파일은 아래 예와 같이 작성할 수 있다. (아래 예는 USB 저장 장치와 SD카드 장치에 대한 처리이다. 아래 예에서는 SD카드가 삽입된 경우에는 추가로 **/etc/mount.sh** 스크립트를 호출함)
   ```sh
   sda[0-9]*           root:root   660
   mmcblk[0-9]p[0-9]   root:root   660   @/etc/mount.sh $MDEV
   ```
   > 위에서 스크립트 호출 앞의 **<font color=blue>@</font>** 마크는 장치가 생성된 후에 수행되고, **<font color=blue>$</font>** 마크는 장치가 제거되기 전에 수행되고, **<font color=blue>*</font>** 마크는 두 경우에 모두 수행됨)  
   또 `$MDEV` 환경 변수는 해당 device node의 이름을 나타낸다.

   **/etc/mount.sh** 파일은 아래 예와 같이 작성할 수 있다.
   ```sh
   mount /dev/$1 /mnt/sdcard
   ```
   
   > 물론 위의 예제는 일부러 외부 스크립트를 호출하는 예를 보이기 위한 것이고, `/etc/mdev.conf` 파일에서 직접 해당 디바이스를 마운트/언마운트시킬 수도 있다.

## USB 저장 장치 hot plug
회사 모델에서는 hot plug 스크립트에서는 직접적으로 마운트/언마운트 처리를 하지 않고, application으로 메시지만 전달하고, application에서 마운트를 비롯한 필요한 모든 처리를 하는 방식이다.  
<br>
USB 저장 장치를 hot plug 시켰을 때에 실제로 구현된 흐름은 다음과 같다.
1. USB 저장 장치가 hot plug가 되면 Kernel에 의해 /sbin/hotplug 스크립트가 실행된다.
1. /sbin/hotplug 스크립트는 아래 형태로 작성하였다.
   ```bash
   #!/bin/sh
   if [ "$1" = "block" ]; then
       if [ "$ACTION" = "add" ]; then
           FULLPATH=$DEVPATH
           DEVNAME=${FULLPATH##*/}
           DEV=/dev/$DEVNAME
           /sbin/HotPlugMsg $ACTION $DEVNAME
       elif [ "$ACTION" = "remove" ]; then
           FULLPATH=$DEVPATH
           DEVNAME=${FULLPATH##*/}
           DEV=/dev/$DEVNAME
           /sbin/HotPlugMsg $ACTION $DEVNAME
       fi
   fi
   ```
   즉, USB 저장 장치가 hot plug 된 경우에 /sbin/HotPlugMsg 파일을 실행하면서 **add**/**remove** 이벤트와 **device name**을 넘긴다.  
1. HotPlugMsg 실행 파일은 application에게 IPC 메시지로 해당 이벤트를 알려주도록 C 언어로 msgsnd()를 이용하여 구현하였다.
1. Application은 해당 added/removed 이벤트 메시지를 수신하여 실제로 원하는 작업을 구현하였다.

## Ethernet 포트 hot plug
1. Kernel에서는 Ethernet 포트의 hot plug가 발생하면 netlink를 통해서 알린다. 따라서 이 netlink를 수신하는 데몬이 필요하다. 이 데몬으로는 [ifplugd](https://0pointer.de/lennart/projects/ifplugd/)를 사용할 수 있는데, Busybox에도 포함되어 있으므로 이것을 사용하면 된다.
1. 이 **ifplugd**를 실행시키지 않으면, Ethernet 포트의 hot plug 이벤트를 감지하지 못하므로, DHCP로 IP를 받아오지 못하는 등의 문제가 발생한다. 그래서 init 스크립트에서 아래 내용과 같이 추가하여 **ifplugd** 데몬을 실행시켰다.
   ```sh
   /sbin/ifplugd -i eth0 -I -r /sbin/hotplug
   ```
   결과로 Ethernet 포트의 hot plug 이벤트가 발생하면, **ifplugd**는 **/sbin/hotplug**를 호출하는데, 이때 첫번째 아규먼트($1)로는 "eth0"를 보내고, `IFPLUGD_PREVIOUS` 환경 변수에는 이전 상태(예: "down"), `IFPLUGD_CURRENT` 환경 변수에는 현재 상태(예: "up")를 세팅한다.
   > 참고: **ifplugd** 툴은 rootfs에 `/var/run/` 경로가 있어야 정상적으로 동작한다.
1. **/sbin/hotplug** 파일은 아래 형태로 작성하였다.
   ```sh
   #!/bin/sh
   if [ "$1" = "eth0" ]; then
       if [ "$IFPLUGD_CURRENT" = "up" ]; then
           udhcpc -i eth0 -p /tmp/udhcpc.pid -s /etc/udhcpc.script >& /dev/null &
       elif [ "$IFPLUGD_CURRENT" = "down" ]; then
           pidfile=/tmp/udhcpc.pid
           if [ -e $pidfile ]; then
               kill `cat $pidfile` 2> /dev/null
               rm -f $pidfile
           fi
           ifconfig eth0 down
       fi
   fi
   ```
   즉, Ethernet 포트가 꼽혔으면 DHCP client(위에서는 **udhcpc**)를 실행켜서 IP를 할당받고, Ethernet 포트가 제거되었으면 DHCP client를 kill 시키고 해당 interface를 down 시킨다.
1. 필요하면 IPC 메시지로 application에게 해당 이벤트를 알릴 수도 있다.
