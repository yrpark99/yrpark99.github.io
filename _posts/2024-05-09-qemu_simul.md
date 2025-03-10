---
title: "QEMU로 시뮬레이션하기"
category: [Environment]
toc: true
toc_label: "이 페이지 목차"
---

ARM, MIPS 등의 실행 파일을 QEMU로 시뮬레이션 실행시켜 보자.

## QEMU(Quick EMUlator) 이용
나는 타겟 시스템이나 보드가 없는 경우에, 빌드 테스트나 간단한 실행 테스트 등을 위해서 가끔 QEMU를 이용하는 경우가 있다. 또 얼마 전에는 업로드된 실행 프로그램의 (ARM, MIPS 등 지원) 보안 검사를 수행하는 웹서버를 구현하였는데, 이때에도 업로드된 프로그램을 실행해 보기 위하여 QEMU를 이용하였다.  

QEMU는 특히 임베디드 시스템을 하는 엔지니어들에게 좋은 툴인데, 이를 이용하지 않는 엔지니어들이 많아서, 이 글에서는 간단히 QEMU를 이용하는 방법을 공유한다.

## QEMU 설치
1. 일반 applicaton을 시뮬레이션하는 경우라면 아래와 같이 설치하면 된다.
   ```sh
   $ sudo apt install qemu-user qemu-user-static
   ```
   참고로 `qemu-user`로 설치한 QEMU 툴들은 여러 동적 라이브러를 사용하는데 반하여, `qemu-user-static`으로 설치한 QEMU 툴들은 동적 라이브러리를 사용하지 않고 단독으로 실행되므로, chroot와 같은 환경에서는 qemu-user-static으로 설치한 QEMU 툴을 사용하는 것이 편리하다.
1. 만약에 Bootloader, Kernel, rootfs 등을 시뮬레이션하는 경우라면 아래와 같이 설치하고 이것을 이용하면 되는데, 이 글에서는 다루지 않겠다.
   ```sh
   $ sudo apt install qemu-system
   ```

## 빌드 및 시뮬레이션
빌드 및 시뮬레이션 방법은 동적 library를 사용하여 빌드하는지 또는 static으로 빌드하는지에 따라서 조금 다르다.  
아래에서는 ARM 타겟으로 예를 들겠다. (ARM 용 크로스툴체인이 설치되어 있고, PATH도 추가된 상태라고 가정)

### 동적 library를 사용하여 빌드하는 경우  
아래 예와 같이 크로스툴체인으로 빌드한다.
```sh
$ arm-linux-gcc -o test test.c
```
이후 아래와 같이 **file** 명령으로 확인해 보면, **ARM** 용 실행 파일로 빌드되었고, **dynamically linked** 되어서 기본적으로 **ld-linux-armhf.so.3** 파일이 필요함을 확인할 수 있다.
```sh
$ file test
test: ELF 32-bit LSB executable, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-armhf.so.3, for GNU/Linux 2.6.16, with debug_info, not stripped
```

동적 라이브러리를 구성하는 방법에는 아래 방법 중의 하나를 사용할 수 있다.
1. `chroot`를 이용하여 격리된 환경을 만들고 여기에 lib를 구성한 후에 (QEMU tool과 시뮬레이션 할 실행 파일도 chroot 경로에 구성해야 함), 아래 예와 같이 실행시킬 수 있다. (이때 QEMU 툴은 static 툴을 사용해야 동적 라이브러리 관련 에러가 발생하지 않음)
```sh
$ sudo chroot {chroot_dir} ./qemu-mipsel-static {test_app}
```
1. 또는 아래 예와 같이 구성한 동적 lib 경로를 주어서 실행시킬 수 있다. (**{lib_path}** 경로에 ld 라이브러리와 동적 링크되는 라이브러리를 포함시키면 됨)
```sh
$ qemu-arm {lib_path}/{ld_library_파일} --library-path {lib_path} {test_app}
```

위 방법 중에서 일반적으로 2번 방법이 더 편리하므로, 여기서는 2번 방법으로 예를 들어보겠다.  
해당 실행 프로그램이 동적 링크하는 라이브러리 전체를 알아야 하는데, `readelf` 툴을 이용하여 아래 예와 같이 실행하면 알아낼 수 있다.
```sh
$ readelf -d test | grep "Shared library:"
 0x00000001 (NEEDED)                     Shared library: [libc.so.6]
```

이제 예를 들어 **lib_arm** 디렉토리를 만들고, 여기에 **ld-linux-armhf.so.3** 파일과 **libc.so.6** 파일을 포함시키면 된다. (보통 사용한 툴체인의 sys-root 경로에서 얻을 수 있음)  
이후 아래 예와 같이 실행시키면, 정상적으로 실행됨을 확인할 수 있다.
```sh
$ qemu-arm lib_arm/ld-linux-armhf.so.3 --library-path lib_arm/ ./test
```

참고로 위에서 만약에 **libc.so.6** 파일을 포함시키지 않았다면 아래와 같은 에러가 발생할 것이다.
```
./test: error while loading shared libraries: libc.so.6: cannot open shared object file: No such file or directory
```

> ARM64(즉, aarch64) 타겟으로 빌드 및 시뮬레이션하는 경우라면 라이브러리 디렉토리(아래에서는 **lib_aarch64**)에 필요한 라이브러리 파일들을 구성한 후에, 아래 예와 같이 실행하면 된다.
```sh
$ aarch64-linux-gcc -o test test.c
$ file test
test: ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-aarch64.so.1, for GNU/Linux 3.7.0, with debug_info, not stripped
$ readelf -d test | grep "Shared library:"
$ qemu-aarch64 lib_aarch64/ld-linux-aarch64.so.1 --library-path lib_aarch64/ ./test
```

### 정적(static)으로 빌드하는 경우  
아래 예와 같이 `--static` 옵션을 추가하여 static으로 빌드하면 실행 시에 동적 라이브러리가 필요 없게 된다. (물론 실행 파일의 크기는 더 커지게 됨)
```sh
$ arm-linux-gcc -o test test.c --static
```
빌드된 실행 파일을 file 명령으로 확인해 보면, 아래 예와 같이 **statically linked** 되어 있음을 확인할 수 있다.
```sh
$ file test
test: ELF 32-bit LSB executable, ARM, EABI5 version 1 (SYSV), statically linked, for GNU/Linux 2.6.16, with debug_info, not stripped
```

이렇게 빌드한 실행 파일은 아래 예와 같이 QEMU로 시뮬레이션할 수 있다. (즉, 동적 라이브러리 없이 실행 가능)
```sh
$ qemu-arm ./test
```

## 파이썬에서 QEMU 실행하기
참고로 위 원리를 이용하여 파이썬으로 입력 실행 프로그램을 자동으로 아키텍쳐를 디텍트한 후에 해당하는 QEMU로 실행시키는 코드를 아래와 같이 작성해 보았고, 정상 동작함을 확인하였다.
```python
#!/usr/bin/env python3

import os
import sys
import subprocess
from pathlib import Path

def simulate_exec_file(file_name: str):
    chip_arch = get_chip_arch(file_name)
    if chip_arch == "":
        print("Error: Failed to find chip architecture")
        return

    script_path = os.path.abspath(__file__)
    directory_path = os.path.dirname(script_path)

    qemu_exec = ""
    library_path = ""
    ld_path = ""
    if chip_arch == "MIPS32":
        library_path = directory_path + "/lib_mips"
        ld_path = library_path + "/ld.so.1"
        qemu_exec = "qemu-mipsel"
    elif chip_arch == "aarch64":
        library_path = directory_path + "/lib_aarch64"
        ld_path = library_path + "/ld-linux-aarch64.so.1"
        qemu_exec = "qemu-aarch64"
    elif chip_arch == "ARM32":
        library_path = directory_path + "/lib_arm"
        ld_path = library_path + "/ld-linux-armhf.so.3"
        qemu_exec = "qemu-arm"
    else:
        return

    try:
        result = subprocess.run([qemu_exec, ld_path, "--library-path", library_path, file_name], stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True, check=False)
        output = result.stdout
        print(output)
    except subprocess.CalledProcessError as e:
        print(e.stdout)
        return

def get_chip_arch(file_name: str) -> str:
    try:
        result = subprocess.run(['file', file_name], stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True, check=False)
        output = result.stdout
    except subprocess.CalledProcessError as e:
        print(e.stdout)
        return ""

    if ": ELF" not in output:
        return ""

    if "MIPS32" in output:
        return "MIPS32"
    elif "aarch64" in output:
        return "aarch64"
    elif "ARM" in output:
        return "ARM32"
    elif "x86-64" in output:
        return "x86-64"
    return ""

if __name__ == '__main__':
    if (len(sys.argv) < 2):
        print("Error: No executable file name")
        sys.exit(1)

    file_path = Path(sys.argv[1]).resolve()

    if file_path.exists() is False:
        print(f"{file_path} is not exist")
        sys.exit(1)
    if file_path.is_file() == False:
        print(f"{file_path} is not a file")
        sys.exit(1)

    simulate_exec_file(str(file_path))
```
