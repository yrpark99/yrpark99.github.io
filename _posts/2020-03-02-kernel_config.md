---
title: "Linux Kernel config"
category: kernel
toc: true
toc_label: "이 페이지 목차"
---

Linux 커널 default config 관련

## Kernel config
Kernel 소스 트리에서 arch/XXX/configs/ 디렉토리에 (XXX는 chip 아키텍쳐) xxx_defconfig 파일들이 있다.  
이 default config 파일들은 최소한의 config 세팅으로, conf 실행 파일에 의해 이 파일과 Kconfig 정책에 따라 최종으로 사용될 .config 파일이 생성된다.  
최종 사용되는 .config 파일은 자동으로 생성되는 파일이고, 수동으로 편집하는 대신에 menu config 등에 의해서 관리되어야 한다.  
Default config 파일은 .config 파일에 비하여 소스 저장소로 관리하여 변경 이력을 보기에 더 낫고, Kernel 버전 변경 등에 따른 변화에도 변경 사항이 적다.

## Default config 이용하기
아래 예와 같이 실행하면 arch/mips/configs/XXX_defconfig 파일을 base로 하여 .config 파일을 생성한다. (아래 예들은 MIPS 아키텍쳐로 하였으며, ARM64 아키텍쳐인 경우에는 `mips` 대신에 `arm64`로 대체하면 됨)
```bash
$ make ARCH=mips XXX_defconfig
```
결과로 scripts/kconfig/Makefile 파일의 아래 내용이 실행된다.
```makefile
%_defconfig: $(obj)/conf
    $(Q)$< --defconfig=arch/$(SRCARCH)/configs/$@ $(Kconfig)
```
즉, 아래와 같이 실행된다.
```bash
scripts/kconfig/conf --defconfig=arch/mips/configs/XXX_defconfig Kconfig
```
scripts/kconfig/conf 실행 파일의 소스는 scripts/kconfig/conf.c 파일이다. 이 conf 실행 파일은 Kconfig와 입력 default config를 참조하여 최종 .config 파일을 생성한다.  
또한 conf 실행 파일은 최종 .config 파일의 내용으로 include/generated/autoconf.h 파일을 생성하고, 각 소스에서는 이 파일을 include하여 참조한다.
	
## 현재 config 수정하기
 이후 config를 수정하고 싶으면 아래 예와 같이 실행하여 수정하고 저장하면 .config 파일이 업데이트 된다.
 ```bash
$ make menuconfig
```

## Default config 생성하기
실제로 이 부분을 모르는 사람이 많았다. 그래서 소스 저장소에도 상기와 같은 default config를 이용하는 방법을 사용하는 대신에 .config 파일을 그대로 사용하는 경우가 많았다.  
수정된 .config 파일 내용으로 다시 default config 파일을 만들고 싶으면 아래 예와 같이 `savedefconfig` 타겟으로 실행하면 된다.
```bash
$ make ARCH=mips savedefconfig
```
결과로 scripts/kconfig/Makefile 파일의 아래 내용이 실행된다.
```makefile
savedefconfig: $(obj)/conf
    $< --$@=defconfig $(Kconfig)
```
즉, 아래와 같이 실행된다.
```bash
scripts/kconfig/conf --savedefconfig=defconfig Kconfig
```
결과로 scripts/kconfig/conf 실행 파일이 Kernel base 디렉토리에 `defconfig` 파일을 생성한다. 생성된 defconfig 파일을 원본 default config 파일에 overwrite 하거나 별도의 이름으로 (단, XXX_defconfig 형식이라야 함) 변경하여 arch/XXX/configs/ 경로에 저장하여 사용할 수 있다.

## Makefile 예제
Kernel 상위 경로에서 아래 예와 같이 Makefile을 작성하여 이용할 수 있겠다.
```makefile
# Default config 파일로 .config 파일을 생성한 후 빌드
all:
    $(MAKE) -C $(KERNEL_DIR) arch=mips my_defconfig
    $(MAKE) -C $(KERNEL_DIR)

# 현재 .config 파일로 default config 파일 업데이트
update_config:
    $(MAKE) -C $(KERNEL_DIR) arch=mips savedefconfig
    $(CP) $(KERNEL_DIR)/defconfig $(KERNEL_DIR)/arch/mips/configs/my_defconfig
```
