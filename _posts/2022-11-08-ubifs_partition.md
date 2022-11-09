---
title: "효율적으로 UBIFS 파티셔닝 하기"
category: [NAND]
toc: true
toc_label: "이 페이지 목차"
---

NAND FLASH에서 데이터 파티션을 UBIFS로 사용시 효율적으로 파티셔닝 하는 방법을 정리한다.

## 동기
회사 제품에서 NAND FLASH를 사용하는 모델들에서 데이터 파티션이 필요한 경우, 용도별로 각각을 개별 파티션으로 나누고, 각각을 UBIFS로 마운트하여 사용하고 있었다.  
그런데 후속 모델에서 FLASH의 용량이 2배로 커지면서 기존에는 잘 되었던 6MiB 크기의 파티션을 UBIFS 마운트 시에 아래와 같은 로그가 나오면서 마운트가 실패하였다.
```
UBIFS error (ubi1:0 pid 1227): init_constants_early: too few LEBs (2), min. is 17
```
즉, 사용 가능한 LEB(Logical Erase Block) 부족으로 마운트가 실패한 것인데, 해당 파티션으로 기존과 동일한 크기를 사용하였는데, 왜 이 모델에서는 사용 가능한 공간이 줄어든 것인지 의문이 생겼다. 🤔  
<br>

위 에러의 원인을 알아보다가 기존 방식처럼 여러 개의 UBIFS 파티션을 운용하는 것이 비효율적인 방법임을 알게 되었다. 그래서 UBIFS 파티션을 여러 개로 나누면 왜 NAND 공간을 낭비하게 되는지와, 1개의 UBIFS 파티션만을 운용하여 공간 낭비없이 여러 개의 볼륨을 마운트하는 방법을 정리해 본다.

## UBIFS
UBIFS는 **UBI File System**의 약어로 **UBI**(Unsorted Block Image)를 위한 파일시스템이다.  
JFFS2의 후계자로 시작되었고, 압축과 마운트 시간, read/write의 성능이 뛰어나다. 특히 NAND FLASH에서 bad block 발생을 완화시킬 수 있는 wear leveling을 지원한다.  
자세한 내용은 [UBIFS - UBI File-System](http://www.linux-mtd.infradead.org/doc/ubifs.html) 글을 참고한다.

## Kernel UBI BEB 설정
NAND 디바이스는 bad block이 발생할 수 있으므로, UBIFS 파티션에서도 이 경우를 대비하기 위하여 예약 공간을 할당해 놓는다.  
실제로 Linux Kernel config에는 UBI 관련하여 reserved 할 BEB(Bad Erase Block) 개수를 다음과 같은 항목으로 정의하고 있다.
  - **Kernel v3.6 이하**: `CONFIG_MTD_UBI_BEB_RESERVE` (퍼센트 단위로 디폴트 `2`, 즉 2%를 할당함)
  - **Kernel v3.7 이상**: `CONFIG_MTD_UBI_BEB_LIMIT` (1024 block 당 개수로, 디폴트 `20`)

즉, Kernel v3.7 이상부터는 기존 퍼센트 단위 대신에, 1024 block 당 reserved 개수를 정의하게 함으로써, 더 세밀히 reserved 할 양을 정의할 수 있게 하였다. 만약에 디폴트인 **20**을 그대로 사용하면, 아래 계산과 같이 약 **2%**를 할당하게 된다.
>20 / 1024 = 0.01953125 = 약 2%

참고로 Kernel config에서 `CONFIG_MTD_UBI_BEB_LIMIT` 항목의 도움말을 보면 다음과 같은 내용이 있어서 좋은 참조가 되었다.
```
NAND datasheets often specify the minimum and maximum NVM (Number of
Valid Blocks) for the flashes' endurance lifetime. The maximum
expected bad eraseblocks per 1024 eraseblocks then can be calculated
as "1024 * (1 - MinNVB / MaxNVB)", which gives 20 for most NANDs
(MaxNVB is basically the total count of eraseblocks on the chip).

To put it differently, if this value is 20, UBI will try to reserve
about 1.9% of physical eraseblocks for bad blocks handling. And that
will be 1.9% of eraseblocks on the entire NAND chip, not just the MTD
partition UBI attaches. This means that if you have, say, a NAND
flash chip admits maximum 40 bad eraseblocks, and it is split on two
MTD partitions of the same size, UBI will reserve 40 eraseblocks when
attaching a partition.

This option can be overridden by the "mtd=" UBI module parameter or
by the "attach" ioctl.
```

위 도움말의 마지막 내용에서 보듯이 Kernel은 UBI 볼륨 생성시에 사용할 `CONFIG_MTD_UBI_BEB_LIMIT` 값을 변경할 수 있도록 ioctl을 제공한다.  
<br>

실제로 **<font color=blue>ubiattach</font>** 툴에는 `-b` 또는 `--max-beb-per1024` 옵션이 있는데, 이 옵션에 대한 도움말은 다음과 같다.
```
maximum expected bad block number per 1024 eraseblock.
The default value is correct for most NAND devices
Allowed range is 0-768, 0 means the default kernel value.
```

소스 코드를 보면 ubiattach는 **<font color=blue>mtd-utils</font>** 패키지에 포함되어 있는데, 이 중 ubiattach.c 파일에서 ubi_attach() -> do_attach() -> ioctl()이 호출되면서 Kernel의 UBI 모듈이 호출된다.  
ubiattach 실행시 `-b` 옵션이 없거나 `-b 0`과 같이 옵션을 주면, Kernel에서 `CONFIG_MTD_UBI_BEB_LIMIT`로 설정한 값을 그대로 사용하고, 그 외의 유효한 값이면 `CONFIG_MTD_UBI_BEB_LIMIT` 값 대신에 이 값이 사용된다.

## Bad 대비 용량
위에서 보듯이 UBIFS는 1024개 block 당 20개(약 2%)를 bad block을 대비하여 reserved 하는데, 테스트를 해 보니 모든 UBIFS 파티션마다 이 동일한 크기를 reserved 한다. (전에는 이 사실을 미처 몰랐었음 😓)  

<br>
즉 내가 겪은 이슈는 기존 모델은 NAND FLASH 크기가 128MiB (전체 block 1024개 * 128KiB)로 이 경우 20개를 bad 용으로 reserved 하였고, 크기로는 20 * 128KiB = 2560KiB 여서, 파티션 크기가 6MiB인 경우에 남은 사용 가능한 공간이 충분하여 UBIFS 마운트가 성공하였는데, 후속 모델은 256MiB (전체 block 2048개 * 128KiB)로 2048개의 block이 있어서, reserved 영역은 UBIFS 파티션마다 40개이고, 크기로는 40 * 128KiB = 5,120KiB 이어서, 파티션으로 6MiB를 할당한 경우에는 사용 가능한 block 개수가 모자라서 UBIFS 마운트가 실패하게 되었던 것이다.❗  
<br>

이에 대한 해결책으로는 크게 다음 2가지 방법이 있다.
1. 현재 여러 개의 UBIFS 파티션을 유지하면서 각각의 bad reserved 공간을 줄이는 방법
1. 여러 개의 UBIFS 파티션을 1개로 통합하고, 이 파티션에서 볼륨을 나누어서 사용하는 방법

당연히 위에서 1번째 방법은 기존 파티션을 유지할 수 있는 임시 방편이고, 2번째가 좀 더 좋은 방법이다. 1번째 방법은 각 파티션별로 쓸데없이 전체 FLASH 크기에 대응하는 bad block reserved를 해서 공간을 낭비하기 때문이다.

## UBI 볼륨으로 나누기
**<font color=blue>ubimkvol</font>** 툴 실행시에 아래 예와 같이 `-m` 옵션을 사용하면, 해당 파티션의 사용 가능한 모든 공간을 볼륨 1개로 만드라는 의미이다.
```sh
ubimkvol /dev/ubi1 -N name -m
```

그렇지 않고 하나의 UBIFS 파티션을 여러 개의 볼륨으로 나누고자 한다면, 아래 예와 같이 `-s` 옵션을 사용하여 각각의 볼륨 크기를 지정하면 된다. (맨 마지막 볼륨은 `-m` 옵션을 사용하여 남은 공간을 모두 할당하였는데, `-s` 옵션으로 용량을 지정해도 됨)
```sh
ubimkvol /dev/ubi0 -N name1 -s 3MiB
ubimkvol /dev/ubi0 -N name2 -s 5MiB
ubimkvol /dev/ubi0 -N name3 -m
```
이후 마운트는 각 볼륨마다 원하는 볼륨명으로 마운트하면 된다.

## UBIFS 마운트 방법
UBIFS 마운트는 아래와 같은 방법으로 하면 된다. (아래 예에서는 **MTD_NUM** 환경 변수에 사용할 MTD 번호를 세팅했다고 가정, 볼륨 이름은 **name**이라고 가정, 볼륨 크기를 사용 가능한 모든 공간을 사용)
```sh
ubiformat /dev/mtd{MTD_NUM} --yes
ubiattach -m {MTD_NUM}
mdev -s
ubimkvol /dev/ubi0 -N name -m
mount -t ubifs ubi0:name /mount_directory/
```

참고로 UBIFS는 NAND 제조사에서 제공하는 OOB(Out Of Band) 영역을 사용하지 않고, PEB(Physical Erase Block) 내에서 자체적으로 OOB 데이터를 관리하므로 보통 실제 LEB의 크기는 PEB 크기인 128KiB가 아니고, 그보다 작은 124KiB나 126KiB 정도가 된다.  
또, UBI 파일 시스템을 운용하기 위하여 몇 개의 LEB block을 추가적으로 사용하므로 (아래 예를 보면 4개 LEB 사용), 실제 사용 가능한 LEB는 이런 LEB 개수들을 뺀 숫자가 된다.

## NAND simulator로 UBIFS 마운트 실습
상세한 NAND simulator 사용 방법은 [`NAND simulator`](https://yrpark99.github.io/nand/nandsim/) 페이지를 참조한다.  
> 참고로 WSL에서 실습하려면 Kernel config에서 `CONFIG_MTD_NAND_NANDSIM`, `CONFIG_MTD_UBI`, `CONFIG_UBIFS_FS` 항목을 enable 한 후에 빌드된 Kernel을 사용해야 한다.

### 여러 개의 UBIFS 파티션 생성
1. 먼저 128MiB FLASH 디바이스에서 아래와 같이 3개의 파티션을 생성해 보자. (각 파티션의 크기는 50 PEB, 100 PEB, 마지막 파티션은 나머지 블럭 전부 할당)
   ```sh
   $ sudo modprobe nandsim id_bytes=0x1,0xA1,0x0,0x15 parts=50,100
   $ cat /proc/mtd
   dev:    size   erasesize  name
   mtd0: 00640000 00020000 "NAND simulator partition 0"
   mtd1: 00c80000 00020000 "NAND simulator partition 1"
   mtd2: 06d40000 00020000 "NAND simulator partition 2"
   ```
   아래와 같이 1번째 mtd0 파티션을 UBIFS로 마운트 시킨다.
   ```sh
   $ sudo ubiformat /dev/mtd0 --yes
   ubiformat: mtd0 (nand), size 6553600 bytes (6.2 MiB), 50 eraseblocks of 131072 bytes (128.0 KiB), min. I/O size 2048 bytes
   libscan: scanning eraseblock 49 -- 100 % complete
   ubiformat: 50 eraseblocks are supposedly empty
   ubiformat: formatting eraseblock 49 -- 100 % complete

   $ sudo ubiattach -m 0
   UBI device number 0, total 50 LEBs (6451200 bytes, 6.2 MiB), available 26 LEBs (3354624 bytes, 3.2 MiB), LEB size 129024 bytes (126.0 KiB)

   $ sudo ubimkvol /dev/ubi0 -N name1 -m
   Set volume size to 3354624
   Volume ID 0, size 26 LEBs (3354624 bytes, 3.2 MiB), LEB size 129024 bytes (126.0 KiB), dynamic, name "name1", alignment 1

   $ sudo mkdir /mnt/ubifs1
   $ sudo mount -t ubifs ubi0:name1 /mnt/ubifs1/
   ```
   FLASH 전체에 1024개 block이 있으므로 CONFIG_MTD_UBI_BEB_LIMIT 디폴트 값인 20에 의해 20 LEB가 bad reserved 용으로 할당되었고, UBIFS 용으로 4개의 LEB가 할당되었고, 남은 26개 LEB가 available 한 개수가 된다. 즉,  
   $available = 50 - 20 - 4 = 26$  
   <br>

   이번에는 마찬가지로 아래와 같이 2번째 mtd1 파티션을 마운트시켜 보자.
   ```sh
   $ sudo ubiformat /dev/mtd1 --yes
   ubiformat: mtd1 (nand), size 13107200 bytes (12.5 MiB), 100 eraseblocks of 131072 bytes (128.0 KiB), min. I/O size 2048 bytes
   libscan: scanning eraseblock 99 -- 100 % complete
   ubiformat: 100 eraseblocks are supposedly empty
   ubiformat: formatting eraseblock 99 -- 100 % complete

   $ sudo ubiattach -m 1
   UBI device number 1, total 100 LEBs (12902400 bytes, 12.3 MiB), available 76 LEBs (9805824 bytes, 9.4 MiB), LEB size 129024 bytes (126.0 KiB)

   $ sudo ubimkvol /dev/ubi1 -N name2 -m
   Set volume size to 9805824
   Volume ID 0, size 76 LEBs (9805824 bytes, 9.4 MiB), LEB size 129024 bytes (126.0 KiB), dynamic, name "name2", alignment 1

   $ sudo mkdir /mnt/ubifs2
   $ sudo mount -t ubifs ubi1:name2 /mnt/ubifs2/
   ```
   마찬가지로 FLASH 전체에 1024개 block이 있으므로 CONFIG_MTD_UBI_BEB_LIMIT 디폴트 값인 20에 의해 20 LEB가 bad reserved 용으로 할당되었고, UBIFS 용으로 4개의 LEB가 할당되었고, 남은 76개 LEB가 available 한 개수가 된다. 즉,  
   $available = 100 - 20 - 4 = 76$  
   <br>

   > ✅ 위에서 보듯이 각각의 UBIFS 파티션에서 동일한 크기의 bad reserved 공간이 할당되어, 파티션을 여러개로 나누면 그만큼 쓸데없이 용량 낭비가 발생하게 된다. 사실 UBIFS 문서에서도 이런 이유로 UBIFS 파티션은 1개로 만들고 이 안에서 필요시 볼륨을 여러 개 만들 것을 권장하고 있다.

   참고로 df 툴로 확인해 보면 아래와 같이 나온다.
   ```sh
   $ df -h | grep ubi
   ubi0:name1      1.2M   20K  1.1M   2% /mnt/ubifs1
   ubi1:name2      7.0M   16K  6.6M   1% /mnt/ubifs2
   ```

   테스트를 마쳤으므로 아래와 같이 unmount, ubidetach 시킨 후에 simulated NAND 디바이스를 제거한다.
   ```sh
   $ sudo umount /mnt/ubifs1
   $ sudo umount /mnt/ubifs2
   $ sudo ubidetach -m 0
   $ sudo ubidetach -m 1
   $ sudo rmmod nandsim
   ```
1. 그럼 이제 문제가 되었던 256MiB FLASH 디바이스에서 동일한 파티션 크기로 테스트 해보자.
   ```sh
   $ sudo modprobe nandsim id_bytes=0x2C,0xDA,0x90,0x95 parts=50,100
   $ cat /proc/mtd
   dev:    size   erasesize  name
   mtd0: 00640000 00020000 "NAND simulator partition 0"
   mtd1: 00c80000 00020000 "NAND simulator partition 1"
   mtd2: 0ed40000 00020000 "NAND simulator partition 2"
   ```
   아래와 같이 1번째 mtd0 파티션을 UBIFS로 마운트 시킨다.
   ```sh
   $ sudo ubiformat /dev/mtd0 --yes
   ubiformat: mtd0 (nand), size 6553600 bytes (6.2 MiB), 50 eraseblocks of 131072 bytes (128.0 KiB), min. I/O size 2048 bytes
   libscan: scanning eraseblock 49 -- 100 % complete
   ubiformat: 50 eraseblocks are supposedly empty
   ubiformat: formatting eraseblock 49 -- 100 % complete

   $ sudo ubiattach -m 0
   UBI device number 0, total 50 LEBs (6451200 bytes, 6.2 MiB), available 6 LEBs (774144 bytes, 756.0 KiB), LEB size 129024 bytes (126.0 KiB)
   ```
   위에서 보듯이 available LEB 개수가 6개로 줄었다. 이는 FLASH 전체에 2048개 block이 있으므로 CONFIG_MTD_UBI_BEB_LIMIT 디폴트 값인 20에 의해 40 LEB가 bad reserved 용으로 할당되었고, UBIFS 용으로 4개의 LEB가 할당되었으므로, 남은 4개 LEB가 available 한 개수가 되기 때문이다. 즉,  
   $available = 50 - 40 - 4 = 6$  
   <br>

   당연히 이후, available 용량 부족으로 인해 실제로 UBIFS 마운트도 실패한다.  
   그런데 만약에 아래 테스트와 같이 <font color=blue>ubiattach</font> 시에 bad reserved 설정값을 10으로 변경하면 (1024개 block 당 10개이므로, 2048개 block인 경우에는 20개 LEB를 할당하게 됨) 이번에는 마운트가 성공하는 것도 확인할 수 있다.
   ```sh
   $ sudo ubidetach -m 0
   $ sudo ubiattach -m 0 -b 10
   UBI device number 0, total 50 LEBs (6451200 bytes, 6.2 MiB), available 26 LEBs (3354624 bytes, 3.2 MiB), LEB size 129024 bytes (126.0 KiB
   ```
   즉, 아래와 같이 계산된다.  
   $available = 50 - 20 - 4 = 26$  
   <br>

   테스트를 마쳤으므로 아래와 같이 unmount, ubidetach 시킨 후에 simulated NAND 디바이스를 제거한다.
   ```sh
   $ sudo umount /mnt/ubifs0
   $ sudo ubidetach -m 0
   $ sudo rmmod nandsim
   ```

### UBIFS 1개 파티션에 여러 개의 볼륨 생성
1. 아래와 같이 256MiB NAND 플래시에서 2개의 파티션을 만든다.
   ```sh
   $ sudo modprobe nandsim id_bytes=0x2C,0xDA,0x90,0x95 parts=400
   $ cat /proc/mtd
   dev:    size   erasesize  name
   mtd0: 03200000 00020000 "NAND simulator partition 0"
   mtd1: 0ce00000 00020000 "NAND simulator partition 1"
   ```
1. 아래와 같이 첫번째 mtd0 파티션을 UBIFS로 마운트 시킨다.
   ```sh
   $ sudo ubiformat /dev/mtd0 --yes
   ubiformat: mtd0 (nand), size 52428800 bytes (50.0 MiB), 400 eraseblocks of 131072 bytes (128.0 KiB), min. I/O size 2048 bytes
   libscan: scanning eraseblock 399 -- 100 % complete
   ubiformat: 400 eraseblocks are supposedly empty
   ubiformat: formatting eraseblock 399 -- 100 % complete

   $ sudo ubiattach -m 0
   UBI device number 0, total 400 LEBs (51609600 bytes, 49.2 MiB), available 356 LEBs (45932544 bytes, 43.8 MiB), LEB size 129024 bytes (126.0 KiB)
   ```
   Bad reserved 용으로 40 block이 할당되므로, 위 결과에서 볼 수 있듯이 available LEB 개수는 아래 식과 나온다.  
   $available = 400 - 40 - 4 = 356$
1. 이제 테스트로 이 파티션에서 3개의 UBI 볼륨을 생성해 보자. (크기는 차례로 3MiB, 5MiB, 나머지 영역)  
   (참고로 볼륨 크기는 LEB 크기 단위로 하면 딱 떨어지고, 그렇지 않으면 올림 처리된다)
   ```sh
   $ sudo ubimkvol /dev/ubi0 -N name1 -s 3MiB
   Volume ID 0, size 25 LEBs (3225600 bytes, 3.1 MiB), LEB size 129024 bytes (126.0 KiB), dynamic, name "name1", alignment 1

   $ sudo ubimkvol /dev/ubi0 -N name2 -s 5MiB
   Volume ID 1, size 41 LEBs (5289984 bytes, 5.0 MiB), LEB size 129024 bytes (126.0 KiB), dynamic, name "name2", alignment 1

   $ sudo ubimkvol /dev/ubi0 -N name3 -m
   Set volume size to 37416960
   Volume ID 2, size 290 LEBs (37416960 bytes, 35.7 MiB), LEB size 129024 bytes (126.0 KiB), dynamic, name "name3", alignment 1
   ```
   즉, 이 파티션의 사용 가능한 LEB는 356개이고, 각각의 볼륨에서 25개, 41개, 290개를 사용하여, 기대대로 낭비되는 공간없이 모든 용량을 사용하였다.  
   $356 = 25 + 41 + 290$  
1. 이제 아래와 같이 각 볼륨별로 마운트 시킬 수 있다.
   ```sh
   $ sudo mkdir /mnt/ubifs1 /mnt/ubifs2 /mnt/ubifs3
   $ sudo mount -t ubifs ubi0:name1 /mnt/ubifs1/
   $ sudo mount -t ubifs ubi0:name2 /mnt/ubifs2/
   $ sudo mount -t ubifs ubi0:name3 /mnt/ubifs3/
   ```
   결과로 df 툴로 확인해 보면 아래와 같이 나온다.
   ```sh
   $ df -h | grep ubi
   ubi0:name1      1.2M   20K  1.1M   2% /mnt/ubifs1
   ubi0:name2      2.9M   16K  2.7M   1% /mnt/ubifs2
   ubi0:name3       32M   16K   31M   1% /mnt/ubifs3
   ```
1. 테스트를 끝났으면 아래와 같이 unmount, ubidetach 시킨 후에 simulated NAND 디바이스를 제거한다.
   ```sh
   $ sudo umount /mnt/ubifs1
   $ sudo umount /mnt/ubifs2
   $ sudo umount /mnt/ubifs3
   $ sudo ubidetach -m 0
   $ sudo rmmod nandsim
   ```

## UBIFS 용량
위 실습 로그에서도 볼 수 있듯이 `df` 툴로 용량을 확인해 보면, 사용 가능한 UBIFS 용량이 실제 크기보다 작게 표시된다.  
사실 UBIFS에서는 free 용량을 예측을 정확하게 할 수 없는데, 왜냐하면 compression, write-back, space wastage, garbage-collection 등이 사용되기 때문이다. 즉, UBIFS 용량은 계산은 애초에 정확한 값을 얻는 것이 가능하지 않고, df 툴은 단지 압축을 제외한 예상값을 리포팅하는 것 같다.  
따라서 정확한 free 용량을 얻기 위해서는 실제로 UBIFS에 데이터를 write 해 보아야 한다. 물론 이 경우에도 write 하는 데이터의 압축률에 따라서 실제 write 가능한 크기가 실시간으로 결정된다.  
<br>

예를 들어 아래와 같이 데이터를 0으로 채우면 df 예상치보다 더 많은 용량이 출력된다.
```sh
$ df -h | grep name1
ubi0:name1      1.2M   20K  1.1M   2% /mnt/ubifs1

$ sudo dd if=/dev/zero of=/mnt/ubifs1/test bs=4096
dd: error writing '/mnt/ubifs1/test': No space left on device
8039+0 records in
8038+0 records out
32923648 bytes (33 MB, 31 MiB) copied, 0.0450664 s, 731 MB/s

$ ls -l /mnt/ubifs1/test
-rw-r--r-- 1 root root 32M 11월  8 10:33 /mnt/ubifs1/test
```

반면에 아래와 같이 랜덤(즉, 압축이 잘 되지 않는) 데이터를 write 해 보면, df 툴에서 예상한 용량이 출력된다.
```sh
$ sudo rm /mnt/ubifs1/test

$ sudo dd if=/dev/urandom of=/mnt/ubifs1/test bs=4096
dd: error writing '/mnt/ubifs1/test': No space left on device
302+0 records in
301+0 records out
1232896 bytes (1.2 MB, 1.2 MiB) copied, 0.00860278 s, 143 MB/s

$ ls -lh /mnt/ubifs1/test
-rw-r--r-- 1 root root 1.2M 11월  8 10:28 /mnt/ubifs1/test
```

## 맺음말
NAND FLASH를 사용할 때는 데이터 R/W를 위하여 UBIFS를 많이 사용하는데, 별개의 영역이 필요한 경우에는 각각을 별개의 UBIFS 파티션으로 나누는 것보다는, UBIFS 파티션은 1개만 만들고 이 안에서 별개의 볼륨을 나누어 사용하는 것이 NAND FLASH 공간 절약 면에서 더 좋은 솔루션임을 알게 되었고, 실제 타겟 보드에도 적용하여 정상 동작되는 것을 확인하였다. 이 글에서는 nandsim으로 시뮬레이션 하였고, 마찬가지로 기대대로 동작하였다.  
이런 식으로 1개의 UBIFS 파티션 내에 필요시 여러 개의 UBI 볼륨을 운용하는 방법을 권장하는데, 사실 이 방법이 큰 파티션 1개만 할당하면 되므로 파티셔닝 하기가 더 쉽고, 추후에도 필요시 내부적으로 개별 영역별로 볼륨 크기를 조정할 수 있으므로 공간 절약 뿐만 아니라, 실제 운용 면에서도 더 좋은 방법이다.
