---
title: "간단한 Linux 배포판 만들기 실험"
category: [Linux]
toc: true
toc_label: "이 페이지 목차"
---

직접 간단한 Linux 배포판을 만들어보는 실험이다.
<br>

참고로 여기서는 편의상 x86_64 용으로 만들어 보았는데, 다른 아키텍처에 대해서도 마찬가지로 방법으로 만들 수 있다.

## 작업용 디렉토리 준비
아래 예와 같이 원하는 이름으로 작업용 디렉토리를 생성한 후에 이동한다.
```sh
$ mkdir distro
$ cd distro/
```

## Kernel 빌드
1. 원하는 Kernel 버전의 소스를 다운로드 받거나, 아래와 같이 최신 버전의 Linux Kernel 소스를 받은 후에, 해당 디렉토리로 이동한다.
   ```sh
   $ git clone --depth 1 https://github.com/torvalds/linux.git
   $ cd linux/
   ```
1. Kernel configuration을 한다. 여기서는 편의상 아래와 같이 x86_64_defconfig를 사용한다.
   ```sh
   $ make x86_64_defconfig
   ```
   > 참고로 Kernel 크기를 최대한으로 줄이려면 아래와 같이 tinyconfig를 한 후에, menuconfig를 실행하여 필요한 항목들만 enable 시키면 된다.
   > ```sh
   > $ make tinyconfig
   > $ make menuconfig
   > ```

   결과로 **.config** 파일이 생성된다.
1. 이제 아래와 같이 빌드한다.
   ```sh
   $ make -j
   ```
   만약에 빌드 중에 "fatal error: gelf.h: No such file or directory" 에러가 발생한다면, 아래와 같이 libelf-dev 패키지를 설치하면 된다.
   ```sh
   $ sudo apt install libelf-dev
   ```
1. Kernel이 성공적으로 빌드되었으면 **arch/x86/boot/bzImage** 파일이 생성된다.  
   아래와 같이 QEMU를 설치한 후에, QEMU로 테스트해 볼 수 있다. (단, GUI app이 실행될 수 있는 환경이라야 함)
   ```sh
   $ sudo apt install qemu-system
   $ qemu-system-x86_64 -kernel arch/x86/boot/bzImage
   ```
   테스트 결과로 Kernel이 정상적으로 실행되고, 마지막 부분에 아래와 같이 rootfs를 마운트하지 못해서 Kernel panic이 발생한 것을 확인할 수 있다.
   ```
   Kernel panic - not syncing: VFS: Unable to mount root fs on unknown-block(0,0)
   ```

   이제 Busybox와 initramfs를 이용해서 rootfs를 구성해 보자.

## Busybox 빌드
Busybox는 shell과 각종 기본적인 Linux tool들을 포함하고 있어서 아주 편리하므로, 이것을 기본적인 initramfs 디렉토리 구축에 사용할 것이다.
1. Base 경로에서 원하는 버전의 Busybox 소스를 받거나, 아래와 같이 최신 버전의 Busybox 소스를 받은 후에, 해당 디렉토리로 이동한다.
   ```sh
   $ git clone --depth 1 https://git.busybox.net/busybox/
   $ cd busybox/
   ```
1. 아래와 같이 menuconfig를 실행한다.
   ```sh
   $ make menuconfig
   ```
   Busybox를 shared library 없이 실행시키기 위해 CONFIG_STATIC 항목을 'y'로 변경한다. (**Settings** -> **Build static binary (no shared libs)** 항목)  
1. 결과로 .config 파일이 생성되었으면 아래와 같이 빌드한다.
   ```sh
   $ make -j
   ```
1. 빌드가 성공하였으면 아래와 같이 initramfs 디렉토리를 생성한 후, 이곳에 빌드 결과물이 생성되도록 실행한다.
   ```sh
   $ mkdir ../initramfs
   $ make CONFIG_PREFIX=../initramfs install
   $ cd ..
   ```
1. 결과로 아래와 같이 Busybox 결과물을 확인할 수 있다.
   ```sh
   $ ls -l initramfs/ 
   ```

## rootfs 이미지 생성
1. 여기서는 rootfs 이미지는 편의상 initramfs를 이용한다. 아래와 같이 initramfs 디렉토리로 이동한다.
   ```sh
   $ cd initramfs/
   ```
1. linuxrc는 필요하지 않으므로 아래와 같이 삭제하고 (삭제하지 않아도 무방함), procfs와 sysfs 마운트에 필요한 디렉토리를 생성한다.
   ```sh
   $ rm linuxrc
   $ mkdir proc
   $ mkdir sys
   ```
1. Kernel에 의해서 최초로 실행되는 init 프로그램을 initramfs top 경로에 아래와 같이 작성한다. (즉 procfs, sysfs 마운트한 후에 shell 실행)
   ```sh
   #!/bin/sh
   mount -t proc none /proc
   mount -t sysfs none /sys
   exec /bin/sh
   ```
1. 이후 init 파일에 아래와 같이 실행 권한을 준다.
   ```sh
   $ chmod +x init
   ```
1. 이제 아래와 같이 initramfs cpio 이미지를 생성한다.
   ```sh
   $ find . -print0 | cpio --null -o --format=newc > ../initramfs.cpio
   $ cd ..
   ```
   결과로 initramfs 디렉토리와 파일들이 **initramfs.cpio** 파일로 생성된다.  
   이것을 그대로 사용할 수도 있지만, 이미지 크기를 줄이려면 아래와 같이 압축을 할 수도 있다. (단, 이 기능을 사용하려면 Kernel config에서 `CONFIG_RD_GZIP` 항목이 enable 되어 있어야 함)
   ```sh
   $ gzip -k ./initramfs.cpio
   ```
   결과로 **initramfs.cpio.gz** 파일이 생성된다.

## ISO 이미지 생성
1. 아래와 같이 필요한 패키지를 설치한다.
   ```sh
   $ sudo apt install syslinux isolinux genisoimage
   ```
1. Kernel 디렉토리로 이동한 후, 아래와 같이 ISO 이미지를 생성한다.
   ```sh
   $ cd linux/
   $ make isoimage FDARGS="initrd=/initramfs.cpio" FDINITRD=../initramfs.cpio   
   ```
   결과로 **arch/x86/boot/image.iso** 파일이 생성된다.  
   참고로 initramfs 압축 이미지를 (위에서 생성한 **initramfs.cpio.gz** 파일) 사용하여 ISO 이미지를 생성하려면 아래와 같이 하면 된다.
   ```sh
   $ make isoimage FDARGS="initrd=/initramfs.cpio.gz" FDINITRD=../initramfs.cpio.gz
   ```

## ISO 이미지 테스트
1. 생성된 **image.iso** 이미지는 VirtualBox로 설치할 수 있는데, 먼저 QEMU로 아래와 같이 테스트해 볼 수도 있다.
   ```sh
   $ qemu-system-x86_64 -cdrom arch/x86/boot/image.iso
   ```
   결과로 정상적으로 부팅되고, shell 프롬프트도 얻어지고, 아래와 같이 Busybox가 지원하는 명령도 정상적으로 동작한다.
   ```
   [    1.902518] netconsole: network logging started
   [    1.904535] cfg80211: loading compiled-in X.509 certificates for regulatory database
   [    1.908997] modprobe (51) used greatest stack depth: 14112 bytes left
   [    1.913013] Loaded X.509 cert 'sforshee: 00b28ddf47aef9cea7'
   [    1.915234] Loaded X.509 cert 'wens: b1c038651aabdcf94bd0ac7ff06c7248db18c600'
   [    1.918051] platform regulatory.0: Direct firmware load for regulatory.db failed with error -2
   [    1.921193] ALSA device list:
   [    1.922543] cfg80211: failed to load regulatory.db
   [    1.924312]   No soundcards found.
   [    1.926113] Freeing unused kernel image (initmem) memory: 2028K
   [    1.928244] Write protecting the kernel read-only data: 26624k
   [    1.930616] Freeing unused kernel image (text/rodata gap) memory: 544K
   [    1.933136] Freeing unused kernel image (rodata/data gap) memory: 1080K
   [    1.983929] x86/mm: Checked W+X mappings: passed, no W+X pages found.
   [    1.986684] Run /init as init process
   [    1.991595] mount (54) used greatest stack depth: 14096 bytes left
   /bin/sh: can't access tty; job control turned off
   # id
   uid=0 gid=0
   # cat /proc/cmdline
   BOOT_IMAGE=linux initrd=/initramfs.cpio
   #
   ```
1. VirtualBox에서도 **image.iso** 이미지로 가상 머신을 생성할 수 있다. 단, 운영체제 종류는 **Linux**, Subytype은 **Other Linux**로 한다.  
   가상 머신을 생성하고 실행하면 아래와 같이 부팅되고, 명령의 실행 결과도 QEMU로 테스트했던 것과 일치함을 확인할 수 있다.  
   ![](/assets/images/VirtualBox_MyDistro.png)
