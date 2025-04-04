---
title: "Linux에서 C/C++ 코드를 Windows 용으로 크로스 빌드하기"
category: [C/C++]
toc: true
toc_label: "이 페이지 목차"
---

Linux에서 C/C++ 코드를 Windows 용으로 크로스 빌드하는 방법을 소개한다.

## 동기
나는 C/C++ 코드를 Windows 용으로 빌드할 때는 [MSYS2 설치](https://yrpark99.github.io/windows/msys2_install/) 페이지에서 언급한 대로 MSYS2에 GCC 툴체인을 설치하여 빌드했었다. 그런데 새로 PC를 세팅하면서 MSYS2를 설치하지 않고 사용 중이었는데 갑자기 C/C++ 코드를 Windows 용으로 빌드해야 하는 일이 생겼다.  
MSYS2와 MinGW 툴체인을 설치하기에는 번거로워서, 그냥 Linux에서 Windows 용으로 크로스 빌드하는 방법이 없는지 찾아보았더니 역시나 있었고, 간단히 기록을 남긴다.

## 툴체인 설치
Windows 64bit 용 크로스 툴체인은 아래와 같이 설치할 수 있다.
```sh
$ sudo apt install gcc-mingw-w64-x86-64 g++-mingw-w64-x86-64
```
아래와 같이 C/C++ 툴체인의 버전을 확인할 수 있다.
```sh
$ x86_64-w64-mingw32-gcc --version
$ x86_64-w64-mingw32-g++ --version
```
<br>

Windows 32bit 용 크로스 툴체인은 아래와 같이 설치할 수 있다.
```sh
$ sudo apt install gcc-mingw-w64-i686 g++-mingw-w64-i686
```
아래와 같이 C/C++ 툴체인의 버전을 확인할 수 있다.
```sh
$ i686-w64-mingw32-gcc --version
$ i686-w64-mingw32-g++ --version
```
<br>

또는 아래와 같이 `mingw-w64` 패키지를 설치하면 Windows 32/64bit 용 툴체인이 모두 설치된다.
```sh
$ sudo apt install mingw-w64
```

## Linux에서 Windows 용으로 빌드하기
사실상 Windows 32bit 용으로 빌드할 필요는 없으므로, Windows 64bit로 빌드하기 위해서는 아래 형태로 사용하면 되겠다.
```sh
$ x86_64-w64-mingw32-gcc {C 파일명}
$ x86_64-w64-mingw32-g++ {C++ 파일명}
```
마찬가지로 아래와 같이 strip 할 수 있다.
```sh
$ x86_64-w64-mingw32-strip {실행 파일명}
```

## Makefile 작성 예
아래와 같이 Linux 용, Windows 용을 모두 빌드할 수 있도록 해보자.
* Windows에서 Windows 용으로 빌드
* Linux에서 Linux 용으로 빌드 (디폴트)
* Linux에서 Windows 용으로 크로스 빌드 (WIN_BUILD=1 옵션 사용시)

이를 위해 아래와 같이 **Makefile** 파일을 작성하였다. (일부만 발췌)
```make
ifeq ($(OS),Windows_NT)
	TARGET_OS = Windows
else ifeq ($(WIN_BUILD),1)
	TARGET_OS = Windows
	CROSS_TOOLCHAIN = x86_64-w64-mingw32-
endif

ifeq ($(TARGET_OS),Windows)
	EXT = .exe
endif

CC = $(CROSS_TOOLCHAIN)gcc
STRIP = $(CROSS_TOOLCHAIN)strip
MKDIR = mkdir

TARGET = AppName$(EXT)

all: $(TARGET)

$(TARGET): $(OBJS)
	@$(CC) $(CFLAGS) -o $(TARGET) $^ $(LDFLAGS)
	@$(STRIP) $(TARGET)
```

## 맺음말
간단한 팁이지만 많은 C/C++ 소프트웨어 개발자들이 Linux에서 Windows 용 GCC 크로스 툴체인을 제공하는지 몰라서, MSYS2나 MinGW를 설치하고 여기에 GCC 툴체인을 설치하여 사용하고 있어서, 간단히 내용을 공유한다.
