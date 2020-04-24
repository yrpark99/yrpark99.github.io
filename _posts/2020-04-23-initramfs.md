---
title: "Linux initramfs"
category: kernel
toc: true
toc_label: "이 페이지 목차"
---

Linux Kernel에서 initrd와 initramfs 이미지 사용법을 정리한다.

## rootfs
Linux Kernel 자체는 monolitic 구조로 되어 있고, 부팅과 동작을 위해서는 rootfs(root 파일 시스템)가 필요하다. 이를 위해서 Kernel에서는 과거부터 initrd를 지원했고, v2.6부터는 향상된 initramfs를 지원한다.

initrd는 disk가 아닌 RAM을 이용하여 disk drive를 구현한 것으로, 완전히 구색을 갖춘 블록 장치이며 고정 크기를 지니고 있다. 따라서 작은 inintrd를 사용하면 모든 필요한 rootfs를 넣을 수 없고 너무 크게 잡으면, 메모리를 쓸데없이 많이 사용하게 되는 단점이 있다.  
initrd는 나중에 실제 사용될 파일 시스템을 부팅시키기 위하여 일시적으로 사용될 수 있지만, 스토리지가 없는 임베디드 시스템에서는 영구적인 rootfs가 될 수도 있다.

initramfs는 간단히 말하면 initrd의 고정 크기, 메모리 점유의 단점을 해소한 것이다. (즉, 크기가 자동으로 관리되고 메모리가 해제됨)

Embedded 제품들에서는 대부분 initrd를 사용하고 initramfs는 잘 사용되지 않고 있어서, initramfs 사용법에 대해서 간단히 정리해 보았다.

## initrd
initrd를 지원하기 위해서는 Kernel config에서 아래와 같이 세팅되어야 한다.
```make
CONFIG_BLK_DEV_INITRD=y
CONFIG_INITRAMFS_SOURCE=""
```

Kernel은 initrd 이미지를 ramdisk로 마운트 한 후 (ramdisk device인 /dev/ram으로 복사, init/do_mounts_rd.c 파일의 rd_load_image() 함수 참조), linuxrc 또는 init 스크립트를 실행한다.  
Kernel에서 할당하는 ram disk 크기는 아래 예와 같이 boot 아규먼트 또는 CONFIG_CMDLINE 항목에서 아래 예와 같이 설정할 수 있다.
```make
CONFIG_CMDLINE="root=/dev/ram0 rd_start=0x81000000 rd_size=0x2000000 console=ttyS0,115200"
```
위 예에서는 `rd_start` 옵션으로 RAM offset을 0x81000000, `rd_size` 옵션으로 RAM disk 크기를 0x2000000(32MiB)로 설정하였다.

결과로 arch/XXX/kernel/setup.c 파일의 init_initrd(), finalize_initrd() 함수에서 initrd_start, initrd_end 값이 세팅된다.
> ramdisk_size 옵션은 KiB 단위로 RAM disk 크기를 세팅하는 옵션인데, rd_size 옵션이 있으므로 사실상 이건 세팅이 불필요함

> 옵션으로 "rootfstype=squashfs ro" 예와 같이 rootfs 타입을 추가할 수 있으나, Kernel이 자동 디텍트하므로 사실상 불필요함

initrd rootfs은 별도의 고정된 영역에 위치해야 하고, 부트로더에서는 initrd rootfs 이미지를 위의 rd_start 값으로 정해진 주소에 로딩해 놓고, Kernel로 점프하면 정상적으로 부팅이 된다. (만약 rootfs 이미지가 압축이 되어 있다면 압축을 풀어서 메모리에 로딩해야 함)

## initramfs
initramfs는 rootfs 이미지가 initrd의 경우에는 별도의 영역을 사용하는 것과는 달리 Kernel 이미지에 통합되어 있으므로, downloader나 updater와 같이 주 파티션과 분리된 Linux Kernel을 기반으로 하는 간단한 애플리케이션을 구현하기에 편리하다.

즉, initrd는 부트로더에서 rootfs를 램에 로딩하는 과정이 필요하지만, initramfs는 부트로더에서 이런 과정이 필요없이 바로 커널로 점프하면 된다.

initramfs를 지원하기 위해서는 Kernel config에서 아래와 같이 세팅되어야 한다. (아래에서 `CONFIG_INITRAMFS_SOURCE`에 실제로 사용할 rootfs cpio 이미지 경로 또는 rootfs 디렉토리 경로를 절대 경로 또는 현재 Kernel 경로 대비한 상대 경로를 적어야 함, 통상 rootfs 디렉토리 경로를 상대 경로로 세팅하는 것이 편리하고, rootfs 디렉토리 구성은 initrd에서 사용하는 rootfs 디렉토리와 동일함)
```make
CONFIG_BLK_DEV_INITRD=y
CONFIG_INITRAMFS_SOURCE="your_rootfs_path"
```

그리고 CONFIG_CMDLINE 내용은 아래 예와 같이 세팅하면 된다. (즉, initrd 시에 세팅했던 내용에서 initrd 관련인 rd_start, rd_size 옵션을 제거하면 됨)
```make
CONFIG_CMDLINE="root=/dev/ram0 console=ttyS0,115200"
```

Kernel을 빌드해보면 아래와 같이 빌드 중에 init/initramfs.c, usr/initramfs_data.S 파일이 빌드되고, usr/initramfs_data.cpio 파일이 생성됨을 확인할 수 있다.
```c
CC      init/initramfs.o
GEN     usr/initramfs_data.cpio
AS      usr/initramfs_data.o
```

참고로 위에서 생성된 cpio 파일은 아래와 같이 확인해 볼 수 있다.
```bash
$ cpio -idm < usr/initramfs_data.cpio
```
또는 binwalk 툴로도 cpio archive 되었음을 확인할 수 있다.
```
$ binwalk usr/initramfs_data.cpio
```

참고로 initramfs는 tmpfs를 이용한 read/write 가능 상태이다. (물론 write 하였다고 하더라도 재부팅하면 write 한 데이터는 날라감) 만약 명백하게 ready only로 세팅하려면, rootfs의 /etc/init.d/rcS 파일에 아래 내용을 추가하면 된다.
```bash
mount -o remount,ro /
```
