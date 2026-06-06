---
title: "dm-crypt, dm-verity 실습"
category: [Crypto]
toc: true
toc_label: "이 페이지 목차"
---

임베디드 장치에서 많이 사용되는 dm-crypt, dm-verity를 Linux host 환경에서 실습해 본다.

## dm-crypt, dm-verity 개념
Linux에서 Device Mapper(DM)는 블록 장치 위에 가상 블록 장치를 생성하는 프레임워크인데, dm-crypt와 dm-verity는 이 
프레임워크 위에서 동작하는 블록 장치 계층 기술이다.  
이 중에서 **<font color=blue>dm-crypt</font>**는 데이터의 기밀성(암호화)를 위한 것이고, **<font color=blue>dm-verity</font>**는 데이터의 무결성(변조 검출)을 위한 것이다. 이때 dm-crypt는 **AES**로 데이터를 블럭 암호화하고, dm-verity는 데이터를 **hash**로 검증한다. Hash는 Merkle Tree 방식을 사용하는데, 이 방식은 모든 데이터를 block 단위로 hash 값을 계산하고, hash 값 block의 hash를 계산하여, 최종 root hash가 남을 때까지 반복한다.  
<br>

시스템 용도에 따라서 dm-crypt, dm-verity를 1개만 사용할 수도 있고, 2개 모두 사용할 수도 있다. 일반적인 임베디드 장치에서는 기밀성과 무결성이 모두 필요하므로 2가지 모두 사용된다.  
각각의 간략한 문서는 아래 페이지에서 찾아볼 수 있다.
- [DMCrypt](https://gitlab.com/cryptsetup/cryptsetup/-/wikis/DMCrypt): dm-crypt, Linux kernel device-mapper crypto target
- [DMVerity](https://gitlab.com/cryptsetup/cryptsetup/-/wikis/DMVerity): dm-verity, device-mapper block integrity checking target

특히 임베디드 장치에서는 기존에도 보안상 rootfs를 암호화하고 verify를 하는 기능이 있었는데, dm-crypt와 dm-verity는 기존 방식과 목적은 동일하지만, 메모리를 효율적으로 사용하고 startup 시간을 줄이기 위하여 도입되었고, 이를 위하여 lazy decryption, authentication 메카니즘을 사용한다.

참고로 이 기능들을 사용하기 위해서는 Linux Kernel에서 다음과 같은 설정들이 enable 되어야 한다.
- `CONFIG_DM_CRYPT`
- `CONFIG_DM_VERITY`
- `BLK_DEV_DM`

## cryptsetup 패키지
[cryptsetup](https://github.com/mbroz/cryptsetup) 패키지는 Kernel의 dm-crypt에 기반하여 기밀성, dm-verity에 기반하여 무결성을 셋업해 주는 오픈소스 툴이다.  
우분투 서버에서는 아래와 같이 패키지로 설치할 수 있다.
```sh
$ sudo apt install cryptsetup-bin
```

크로스 플랫폼 환경이라면 소스를 직접 받아서 빌드할 수도 있는데, LVM2, libaio, json-c와 같은 외부 라이브러리를 사용하므로, 사전에 이들 라이브러리들이 빌드되어 있어야 한다. 이 경우 buildroot를 이용하면 더 편리하게 빌드할 수 있다.  
<br>

패키지를 설치하거나 소스를 빌드하면, 다음과 같은 툴들을 얻을 수 있다.
- **cryptsetup**: Kernel의 dm-crypt를 setup
  - dm-crypt 암호화 방식은 AES-256 이상을 사용해야 하고 XTS나 CBS 모드 사용이 권장된다.
  - IV 생성 전략은 XTS 모드에서는 plain64가 권장되고, CBC 모드에서는 ESSIV가 권장된다.
  - 암호화 알고리즘에는 "aes-xts-plain64", "aes-cbc-essiv:sha256" 등이 있다.(`--cipher` 옵션으로 설정할 수 있고, 이 옵션이 없으면 디폴트가 선택됨)
  - AES 암호화는 sector 단위로 수행하고, sector의 크기는 항상 512 바이트이다.
- **veritysetup**: Kernel의 dm-verity를 setup
  - 입력 이미지에 대한 hash를 merkle tree로 구성하거나, 구성된 hash가 올바른지 verify 한다.
  - 보통 hash는 SHA256을 사용한다. (`hash = SHA256(salt || data_block)`)
  - Merkle tree는 각 data block에(크기는 **4096** 바이트) 대하여 hash를 계산하고, hash block에 대하여 다시 상위 트리로 hash 하여, 최종 top hash (또는 root hash) 만 남을 때까지 hash를 계산하여 구성한다. (1개 data block(4096 바이트)는 32바이트 hash로 계산되고, 1개 hash block(4096 바이트)는 4096/32=128개의 hash를 가짐)
    ```
                                [   root    ]
                               /    . . .    \
                    [entry_0]                 [entry_1]
                   /  . . .  \                 . . .   \
        [entry_0_0]   . . .  [entry_0_127]    . . . .  [entry_1_127]
          / ... \             /   . . .  \             /           \
    blk_0 ... blk_127  blk_16256   blk_16383      blk_32640 . . . blk_32767
    ```

## Host에서 dm-crypt, dm-verity 마운트 테스트
1. Loopback 파일을 생성하고 block 디바이스로 연결하기  
   아래 예와 같이 10MiB 크기의 loopback 파일을 생성한다. (결과로 10MiB 크기의 disk.img 파일이 생성됨)
   ```sh
   $ dd if=/dev/zero of=disk.img bs=10M count=1
   ```
   아래와 같이 loop 디바이스를 생성하고 연결하한다. (결과로 /dev/loop**X** 디바이스 노드가 생성되고, disk.img 파일이 연결됨)
   ```sh
   $ LOOP_DEV=$(losetup --find)
   $ sudo losetup $LOOP_DEV disk.img
   ```
   확인해 보면 아래 예와 같이 나온다.
   ```sh
   $ losetup --all
   /dev/loop0: []: (disk.img 경로)
   ```
   이제 disk.img 파일을 블록 디바이스처럼 사용할 수 있게 된다. 아래에서는 생성된 /dev/loop**X** 디바이스를 `LOOP_DEV` 이름으로 사용한다.
1. dm-crypt block 디바이스를 셋업하기  
   먼저 32바이트(256bit) 크기의 랜덤 encryption key를 keyfile.bin 파일 이름으로 생성한다.
   ```sh
   $ dd if=/dev/random of=keyfile.bin bs=32 count=1
   ```
   아래와 같이 **cryptsetup** 툴을 실행하면 loop 디바이스를 dm-crypt 하여 device mapper 디바이스에 매핑시킨다. (제공된 encryption 키와 속성을 사용, 마지막 아규먼트가 /dev/mapper/ 밑에 생성될 이름으로, 여기서는 **cryptdisk** 이름을 사용함)
   ```sh
   $ sudo cryptsetup open --type plain --cipher aes-xts-plain64 --key-size 256 --key-file keyfile.bin $LOOP_DEV cryptdisk
   ```
   결과로 아래 예와 같이 **/dev/mapper/cryptdisk** 파일이 생성되고, 기타 정보를 확인할 수 있다.
   ```sh
   $ file /dev/mapper/cryptdisk
   /dev/mapper/cryptdisk: block special (254/0)

   $ sudo dmsetup info cryptdisk
   Name:              cryptdisk
   State:             ACTIVE
   Read Ahead:        256
   Tables present:    LIVE
   Open count:        0
   Event number:      0
   Major, minor:      254, 0
   Number of targets: 1
   UUID: CRYPT-PLAIN-cryptdisk
   ```
1. dm-crypt 된 디바이스를 포맷하고 마운트한 후에 파일 생성하기  
   아래 예와 같이 dm-crypt 된 디바이스를 파일시스템으로 포맷한다.
   ```sh
   $ sudo mkfs.ext4 -b 4096 /dev/mapper/cryptdisk
   ```
   이제 아래 예와 같이 dm-crypt 된 디바이스를 마운트하고, 파일을 생성할 수 있다.
   ```sh
   $ mkdir mnt_dmcrypt
   $ sudo mount -t ext4 /dev/mapper/cryptdisk mnt_dmcrypt/
   $ ls mnt_dmcrypt/
   lost+found
   $ echo "Hello, dmcrypt" > test.txt
   $ sudo cp test.txt mnt_dmcrypt/
   ```
   아래와 같이 파일의 내용을 확인하면 정상적으로 읽힌다.
   ```sh
   $ cat mnt_dmcrypt/test.txt
   Hello, dmcrypt
   ```      
1. dm-crypt 된 디바이스를 언마운트하기
   아래와 같이 언마운트시킨다.
   ```sh
   $ sudo umount /dev/mapper/cryptdisk
   ```
1. dm-verity 셋업하기
   아래 예와 같이 dm-crypt 된 디바이스에 대하여 **veritysetup** 툴을 실행한다.
   ```sh
   $ sudo veritysetup format /dev/mapper/cryptdisk hash.table
   VERITY header information for hash.table
   UUID:                   b3930802-8e21-4405-b99a-f705d8ca4edb
   Hash type:              1
   Data blocks:            2560
   Data block size:        4096
   Hash block size:        4096
   Hash algorithm:         sha256
   Salt:                   308ca9af0fb1e987feec266ce31895ac95cc29329b7ad532bc457bd2dd5843cb
   Root hash:              23506671eb9f8ffe99b41bf0abaedad32fa2da2cac14767015838c4d4e7b3b5e
   ```
   결과로 hash tree 파일(위 예에서는 hash.table), "Salt", Root hash" 등을 얻을 수 있다. (참고로 hash table 파일에는 **Salt** 정보가 저장됨, 단, **Root hash** 정보는 변조를 방지하기 위하여 hash table 파일에 저장되지 않음)  
   이제 아래 예와 같이 실행하면 dm-verity 디바이스가 생성된다. (예로 디바이스 이름은 **veritydisk** 사용, {root_hash_값}은 위에서 "Root hash"로 출력된 hex 문자열) 
   ```sh
   $ sudo veritysetup create veritydisk /dev/mapper/cryptdisk hash.table {root_hash_값}"
   $ file /dev/mapper/veritydisk
   /dev/mapper/veritydisk: block special (254/1)
   ```
   아래와 같이 hash가 맞는지 verify 해 볼 수 있다.
   ```sh
   $ sudo veritysetup verify /dev/mapper/veritydisk hash.table {root_hash_값}
   $ echo $?
   0
   ```
   테스트로 만약에 틀린 root hash 값을 주면 아래 예와 같이 verify가 실패했다고 나온다.
   ```sh
   $ sudo veritysetup verify /dev/mapper/veritydisk hash.table {틀린_root_hash_값}
   Verification of root hash failed.
   $ echo $?
   2
   ```
   아래 예와 같이 "veritysetup status" 명령으로 현재 verify 상태를 확인할 수 있다.
   ```sh
   $ sudo veritysetup status veritydisk
   /dev/mapper/veritydisk is active.
   type:        VERITY
   status:      verified
   hash type:   1
   data block:  4096
   hash block:  4096
   hash name:   sha256
   salt:        308ca9af0fb1e987feec266ce31895ac95cc29329b7ad532bc457bd2dd5843cb
   data device: /dev/mapper/cryptdisk
   size:        20480 sectors
   mode:        readonly
   hash device: /dev/loop1
   hash loop:   {hash table 파일 경로}
   hash offset: 8 sectors
   ```
1. dm-verity 된 디바이스를 마운트하고 파일 확인하기
   아래와 같이 마운트한다.
   ```sh
   $ mkdir mnt_dmverity
   $ sudo mount -t ext4 -o ro /dev/mapper/veritydisk mnt_dmverity
   ```
   마운트된 dm-verity 디바이스의 파일을 확인해 보면 정상적으로 읽힌다.
   ```sh
   $ ls mnt_dmverity/
   lost+found  test.txt
   $ cat mnt_dmverity/test.txt
   Hello, dmcrypt
   ```
   아래와 같이 언마운트 시킨다.
   ```sh
   $ sudo umount /dev/mapper/veritydisk
   ```
1. dm-verity 된 디바이스 닫기
   ```sh
   $ sudo veritysetup close veritydisk
   ```
1. dm-crypt 된 디바이스 닫기
   ```sh
   $ sudo cryptsetup close cryptdisk
   ```      
1. Loop 디바이스 detach 시키기
   ```sh
   $ sudo losetup --detach $LOOP_DEV
   ```

## Host에서 dm-crypt 이미지 생성 및 verify 테스트
위에서는 이미지를 loop device에 연결하여 마운트하여 dm-crypt 이미지를 생성하였는데 이렇게 하려면 root 권한이 필요하다. 따라서 단순히 임베디드 장치에서 사용하는 rootfs squashfs 이미지에 대하여 dm-crypt 이미지를 생성하는 용도라면 이 방법은 매우 불편하므로,  일반 사용자 권한으로 dm-crypt 이미지를 생성하는 프로그램을 작성해 보았다.  
<br>

1. dm-crypt에서 사용하는 암호화 방식을 흉내내어 입력 파일에 대한 dm-crypt 이미지 생성을 담당하는 dmcrypt.py 코드를 작성하였다. (단, 아래 코드는 암호화 알고리즘으로 "aes-xts-plain64"인 경우이고, 만약에 "aes-cbc-essiv:sha256"인 경우에는 IV 관련하여 약간의 수정이 필요함)
   ```python
   #!/usr/bin/env python3

   import struct
   import sys
   from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
   from cryptography.hazmat.backends import default_backend

   SECTOR_SIZE = 512

   def dmcrypt_xts_plain64(in_file: str, out_file: str, key_file: str) -> None:
       key = open(key_file, "rb").read()
       if len(key) != 64:
           raise RuntimeError("Key must be exactly 64 bytes (512 bits)")
       print("Key:", key.hex())

       with open(in_file, "rb") as fin, open(out_file, "wb") as fout:
           sector_number = 0
           while True:
               sector = fin.read(SECTOR_SIZE)
               if not sector:
                   break
               if len(sector) < SECTOR_SIZE:
                   sector += b'\x00' * (SECTOR_SIZE - len(sector))
               tweak = struct.pack("<Q", sector_number) + b'\x00' * 8
               cipher = Cipher(algorithms.AES(key), modes.XTS(tweak), backend=default_backend())
               encryptor = cipher.encryptor()
               encrypted = encryptor.update(sector) + encryptor.finalize()
               fout.write(encrypted)
               sector_number += 1

   def main() -> None:
       if len(sys.argv) < 4:
           print("Argument: <input_file> <output_file> <key_file>")
           sys.exit(1)

       input_file = sys.argv[1]
       output_file = sys.argv[2]
       key_file = sys.argv[3]
       dmcrypt_xts_plain64(input_file, output_file, key_file)

   if __name__ == "__main__":
       main()
   ```
1. 테스트에 사용할 squashfs 이미지를 아래 예와 같이 생성한다. (INPUT_FILE 변수는 원하는 이름으로 설정 필요)
   ```sh
   $ sudo apt install squashfs-tools
   $ mkdir rootfs_dir
   $ mksquashfs rootfs_dir/ "${INPUT_FILE}"
   ```
1. 아래 예와 같이 사용할 crypto key를 준비한다. (KEY_FILE 변수는 원하는 이름으로 설정 필요)
   ```sh
   $ dd if=/dev/urandom of="${KEY_FILE}" bs=64 count=1 2> /dev/null
   ```
   이제 아래와 같이 입력 파일에 대한 dm-crypt 이미지를 생성할 수 있다. (DMCRYPTED_FILE 변수는 원하는 이름으로 설정 필요)
   ```sh
   $ ./dmcrypt.py "${INPUT_FILE}" "${DMCRYPTED_FILE}" "${KEY_FILE}"
   ```
1. 아래 예와 같이 veritysetup 툴을 실행시키면 입력 dm-crypt 이미지에 대한 hash 파일을 얻을 수 있다. (HASH_FILE 변수는 원하는 이름으로 설정 필요)
   ```sh
   $ veritysetup format "${DMCRYPTED_FILE}" "${HASH_FILE}"
   ```
   결과로 hash 파일과 Salt, Root hash 등을 얻을 수 있다. (이후 verify 시 사용하기 위하여 Root hash 값은 ROOT_HASH 변수에 저장)  
   참고로 salt 값을 입력값으로 설정하고 싶은 경우에는 `--salt=${SALT}` 아규먼트를 추가하면 된다.
1. Hash가 맞는지 아래 예와 같이 verify 할 수 있다.
   ```sh
   $ veritysetup verify "${DMCRYPTED_FILE}" "${HASH_FILE}" "${ROOT_HASH}"
   ```
   결과로 기대대로 hash가 맞는 경우에만 verify가 성공하는 것을 확인할 수 있다.

참고로 위 방식은 hash table을 별도의 파일로 분리하고, verify 할 때에도 이 분리된 hash 파일을 사용하는 방식이다.  
물론 이 방식을 사용할 수도 있지만, 만약에 hash table을 dm-crypt 이미지에 이어서 붙여서 생성하고, verify 할 때에도 이 통합된 dm-crypt 이미지를 이용할 수 있다.  
이를 위해서 아래와 같이 "veritysetup format"의 결과로 얻은 dm-crypt 이미지와 hash 파일을 합친다. (DMCRYPTED_HASH_FILE 변수는 원하는 이름으로 설정 필요)
```sh
$ cat "${DMCRYPTED_FILE}" "${HASH_FILE}" > "${DMCRYPTED_HASH_FILE}"
```

아래와 같이 HASH_OFFSET 값을 구한다.
```sh
$ BLOCK_SIZE=4096
$ DATA_BLOCKS=$((($(stat -c %s "${INPUT_FILE}") + 4095) / 4096))
$ HASH_OFFSET=$((DATA_BLOCKS * BLOCK_SIZE))
```

이제 이 통합된 이미지에 대한 verify는 아래 예와 같이 data_device와 hash_device에 동일하게 통합된 이미지 파일을 주고, `--hash-offset=${HASH_OFFSET}` 아규먼트로 hash 옵셋값을 설정하여 수행할 수 있다.
```sh
$ veritysetup verify --hash-offset="${HASH_OFFSET}" "${DMCRYPTED_HASH_FILE}" "${DMCRYPTED_HASH_FILE}" "${ROOT_HASH}"
```

## dm-crypt squashfs on top of UBI
임베디드 장치에서 NAND에 squashfs rootfs 이미지를 올리는 경우에는 bad block의 존재 때문에 추가적인 고려가 필요하다. 왜냐하면 dm-crypt, dm-verity는 bad block이 없는 블럭 장치만을 위하여 구현되었고, 중간에 bad block이 있는 경우에는 제대로 처리하지 못하기 때문이다.  
사실 NAND 저장장치를 위하여 bad block 처리와 wear leveling을 담당하는 UBI(Unsorted Block Image) block layer가 있으므로, 이때 주로 사용되는 해결책은 dm-crypt squashfs rootfs 이미지를 UBI로 올리는 것이다. ([SquashFS on top of UBI 테스트 예](https://yrpark99.github.io/nand/nandsim/#squashfs-on-top-of-ubi-%ED%85%8C%EC%8A%A4%ED%8A%B8-%EC%98%88) 페이지 참고)  
<br>

1. 아래 예와 같이 `ubinize.cfg` 파일을 작성한다. (아래에서 "your_dmcrypted_file" 부분은 위에서 사용했던 "${DMCRYPTED_FILE}" 이름으로 변경 필요)
   ```ini
   [squashfs]
   mode=ubi
   image="your_dmcrypted_file"
   vol_id=0
   vol_size=28MiB
   vol_type=dynamic
   vol_name=squashfs
   vol_flags=autoresize
   ```
1. 아래 예와 같이 `ubinize` 툴로 UBI 이미지를 생성한다. (UBI_DMCRYPTED_FILE 변수는 원하는 이름으로 설정 필요)
   ```sh
   $ ubinize -o "${UBI_DMCRYPTED_FILE}" -m 2048 -p 128KiB -s 512 -O 2048 ubinize.cfg
   ```
   결과로 "${UBI_DMCRYPTED_FILE}" 이름의 UBI 이미지가 생성된다.
1. 위에서 생성된 UBI 이미지에 대하여 아래와 같이 dm-verity를 실행하여 hash table을 얻을 수 있다.
   ```sh
   $ veritysetup format "${UBI_DMCRYPTED_FILE}" "${HASH_FILE}"
   ```
1. 이후 아래와 같이 verify도 할 수 있다.
   ```sh
   $ veritysetup verify "${UBI_DMCRYPTED_FILE}" "${HASH_FILE}" "${ROOT_HASH}"
   ```   

## 맺음말
위와 같은 방식으로 host에서 root 권한으로 dm-crypt 생성, 마운트, verify를 할 수 있었다. 또한 일반 유저 권한으로도 dm-crypt 이미지를 생성할 수 있었고 verify까지 할 수 있었다.
