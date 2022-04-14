---
title: "Python cross build"
category: Python
toc: true
toc_label: "이 페이지 목차"
---

최신 파이썬을 임베디드 시스템에서 동작시키기

## 동기
파이썬의 인기가 높아짐에 따라 최근에는 간혹 파이썬을 <mark style='background-color: #ffdce0'>임베디드 시스템</mark>에서도 동작시키려는 시도가 있는 것 같다.  
물론 현재의 파이썬이 속도나 용량, 메모리 사용량 등의 효율이 너무 안 좋은 관계로, 기존 C/C++ 등의 언어를 대체하기에는 불가능하지만, 기존 파이썬 소스를 활용하거나 특정 분야에서 파이썬으로 구현하는 것이 더 편리한 경우가 있을 수 있겠다.  
그런데 팀원이 파이썬을 임베디드 시스템에 올리는 것을 힘들어하고 있기에, 나도 한 번 해보면서 도움을 주고자 시작해 보았다.

## Cross-toolchain 설치
먼저 타겟 임베디드의 CPU를 위해서 아래 예와 같이 cross-toolchain 설치를 한다. (팀원의 경우 MIPS 시스템이었으므로 본 블로그에서는 `MIPS32`로 예를 들었다. 만약 `ARM32`인 경우에는 아래 예에서 `mipsel` 대신에 `arm`을 사용하면 되고, `ARM64`인 경우에는 `aarch64`를 사용하면 된다)
```shell
$ sudo apt install gcc-mipsel-linux-gnu g++-mipsel-linux-gnu
```
즉, ARM64의 경우라면 아래 예와 같이 해당 툴체인을 설치할 수 있다.
```shell
$ sudo apt install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu
```
> 물론 이미 사용 중인 cross 툴체인이 있으면 위와 같이 설치하지 않고 기존 것을 그대로 사용해도 된다. (단, 이 경우 해당 툴체인의 bin 경로에 PATH가 잡혀 있어야 하고, 아래 `--host` 옵션으로 지정되는 cross 툴체인 이름을 알맞게 수정해 주어야 할 것임)

## Python cross 빌드하기
1. 소스 받기  
   [Python Source Releases](https://www.python.org/downloads/source/) 페이지에서 원하는 버전을 찾아서 (아래 예에서는 v3.8.12), 아래와 같이 Python 소스를 다운받은 후, 압축을 푼다. 
   ```shell
   $ wget https://www.python.org/ftp/python/3.8.12/Python-3.8.12.tar.xz
   $ tar xf Python-3.8.12.tar.xz
   $ cd Python-3.8.12/
   ```
1. Python configuration  
   아래 예와 같이 configuration 한다. (`ARM64`인 경우에는 `mipsel` 대신에 `aarch64`를 사용하면 됨)
   ```shell
   $ ./configure --host=mipsel-linux-gnu --build=x86_64-linux-gnu --prefix=$HOME/python --disable-ipv6 ac_cv_file__dev_ptmx=no ac_cv_file__dev_ptc=no --enable-optimizations
   ```
1. 이제 아래와 같이 빌드한다.  
   ```shell
   $ make -j
   ```
   > 참고로 빌드가 성공적으로 끝나면 발견되지 않은 옵션 모듈들의 리스트가 나오는데, 이 중에서 <font color=blue>_ssl</font>과 <font color=blue>zlib</font> 모듈은 **pip**가 실행되는데 꼭 필요한 모듈이다. 따라서 타겟 시스템에서 pip로 패키지를 설치하려면 이 모듈들이 필요하고, 이를 위해서는 zlib와 openssl도 cross-build해서 cross-toolchain에 복사해야 한다.  
   하지만 이보다 더 간단한 방법으로 <font color=blue>crossenv</font>를 이용하는 방법이 있다. 아래에서 이 방법을 좀 더 자세히 설명한다.
1. 빌드가 정상적으로 끝난 후 아래와 같이 실행시키면, `--prefix` 옵션으로 지정된 경로에 실행에 필요한 파일들이 설치(복사)된다.
   ```shell
   $ make install
   ```

## 기본 테스트
1. 타겟 머신으로 제대로 빌드되었는지 확인해 보기 위하여, **test.py** 파일을 아래 내용과 같이 작성한다. (물론 이렇게 파일을 작성해서 실행하는 대신에 python3을 실행하면 `>>>` 프롬프트가 뜨는데, 이 상태에서 아래 코드를 실행해도 됨)
   ```python
   import platform
   print(platform.machine())
    ```
1. 우선 호스트에서 테스트해보면 아래와 같이 나온다.
   ```shell
   $ python3 --version
   Python 3.8.10
   $ python3 test.py
   x86_64
   ```
1. 타겟 보드를 사용하는 대신에 호스트에서 QEMU로 시뮬레이션 테스트를 해 보기 위해서, 아래와 같이 QEMU를 설치한다.
   ```shell
   $ sudo apt install qemu-user
   ```
1. 위에서 Python을 static이 아닌 dynamic으로 빌드하였으므로, 타겟 시스템이나 QEMU 시뮬레이션시에는 사용되는 타겟 시스템의 so 라이브러리들을 올바르게 구성해 주어야 Python이 정상적으로 실행된다. QEMU 테스트를 위해서는 아래 예와 같이 symbolic link를 걸어줘도 된다.
   ```shell
   $ sudo ln -s /usr/mipsel-linux-gnu/lib/ld.so.1 /lib/ld.so.1
   $ sudo ln -s /usr/mipsel-linux-gnu/lib/libc.so.6 /lib/libc.so.6
   $ sudo ln -s /usr/mipsel-linux-gnu/lib/libdl.so.2 /lib/libdl.so.2
   $ sudo ln -s /usr/mipsel-linux-gnu/lib/libm.so.6 /lib/libm.so.6
   $ sudo ln -s /usr/mipsel-linux-gnu/lib/libpthread.so.0 /lib/libpthread.so.0
   $ sudo ln -s /usr/mipsel-linux-gnu/lib/libutil.so.1 /lib/libutil.so.1
   ```
1. 이제 파이썬의 버전과 machine 결과를 시뮬레이션 테스트를 해 보면, 아래와 같이 나온다.
   ```shell
   $ qemu-mipsel ~/python/bin/python3 --version
   Python 3.8.12
   $ qemu-mipsel ~/python/bin/python3 test.py
   mips
   ```
   버전과 machine 정보가 타겟 시스템에서의 기대값으로 나왔다. 😉  
   (ARM64의 경우에는 `qemu-aarch64` 명령으로 시뮬레이션 할 수 있고, 머신 결과로는 `aarch64`가 나옴)

## PIP 설치를 위한 crossenv
위에서 언급한 바와 같이 타겟 시스템에서 pip로 패키지를 설치하는 방법 이외에, 호스트에서 [crossenv](https://github.com/benfogle/crossenv) 패키지를 이용하여 호스트에서 cross 환경의 패키지를 설치할 수도 있다. (단, 이 경우에도 빌드된 cross 타겟은 필요하다. 위에서 이미 Python을 cross 빌드하여 ~/python/ 디렉토리에 결과물이 있으므로 이것을 그대로 사용하면 됨)
1. 먼저 아래와 같이 필요한 패키지를 설치한다.
   ```shell
   $ sudo apt install python3-venv
   $ pip3 install crossenv
   ```
1. 아래 예와 같이 cross 가상 환경을 생성한다. (아래 예에서는 **cross_venv** 이름 사용)
   ```shell
   $ cd ~/
   $ python3 -m crossenv ~/python/bin/python3 cross_venv
   ```
1. 이제 아래 예와 같이 가상 환경을 activate 시켜서 패키지를 설치할 수 있다.
   ```shell
   $ . cross_venv/bin/activate
   (cross) $ pip install --upgrade pip
   (cross) $ pip install numpy
   (cross) $ pip list
   (cross) $ deactivate
   ```
1. 위에서 pip list로 확인해 보면 numpy가 정상적으로 설치되었음을 확인할 수 있다. 패키지가 설치된 경로는 ~/cross_venv/cross/lib/python3.8/site-packages/ 디렉토리이므로, 이를 아래와 같이 cross 빌드된 디렉토리로 복사한다.
   ```shell
   $ cp -rf ~/cross_venv/cross/lib/python3.8/site-packages/numpy* ~/python/lib/python3.8/site-packages/
   ```

## QEMU로 numpy 테스트
1. 타겟 시스템을 위한 numpy 패키지가 준비되었으므로 이제 아래와 같이 테스트해 보니, 잘 된다. 😊
   ```shell
   $ ~/python/qemu-mipsel bin/python3.8
   >>> import numpy as np
   >>> print(np.pi)
   ```

## 테스트 파일 삭제
QEMU 테스트가 끝났으면 임시로 만들었던 symbolic link 들을 아래와 같이 삭제해도 된다.
```shell
$ sudo rm /lib/ld.so.1 /lib/libc.so.6 /lib/libdl.so.2 /lib/libm.so.6 /lib/libpthread.so.0 /lib/libutil.so.1
```

## 전체 데모
<head>
  <link rel="stylesheet" type="text/css" href="/assets/css/asciinema-player.css"/>
</head>
<asciinema-player src="/assets/cast/python_cross_build.cast" cols="134" rows="25" font-size="medium" poster="data:text/plain,\e[15;1H\e[1;33mPython cross-build 테스트 예"></asciinema-player>
<script src="/assets/js/asciinema-player.js"></script>

## 타겟 시스템에 설치
파이썬 빌드 및 QEMU 시뮬레이션 테스트가 끝났으면, prefix 옵션으로 지정한 경로의 파일들을 타겟 보드의 /usr/local/python3.8/ 폴더에 넣으면 된다. 물론 사용되는 cross 툴체인 경로에 있는 so 파일들도 rootfs의 /lib/ 경로에 복사해 넣어야 할 것이다.
