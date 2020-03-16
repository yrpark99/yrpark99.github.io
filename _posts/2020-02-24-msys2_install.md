---
title: "MSYS2 설치"
category: msys2
toc: true
toc_label: "이 페이지 목차"
---

MSYS2 + MinGW 설치를 정리한다.

## MSYS2 소개
MSYS2는 Windows에서 gcc 등으로 작성된 소스를 빌드하거나 Linux 배시 파일 등을 실행시킬 때 유용하다. 나는 오래 전에는 이를 위해 Cygwin을 주로 사용되었으나, MSYS가 더 편리하여 MSYS로 넘어온지 오래되었고, 주로 MinGW의 gcc를 사용하여 Windows 프로그램을 빌드하는데 사용하였다.  
기존 MSYS는 32bit 운영체제 만을 지원했었는데 MSYS2로 넘어오면서 마침내 32/64bit 모두 지원하게 되었다.  
또 MSYS2는 pacman이라는 패키지 매니저도 지원하여, 리눅스 배포판에서 패키지를 설치할 때처럼 쉽게 (자동으로 의존하는 패키지까지 관리해줌) 패키지를 설치/제거할 수 있어서 패키지 관리가 아주 편리하다.  
물론 MinGW 설치 패키지를 이용하여 다른 패키지를 설치할 수도 있고, 이후 추가로 MSYS2를 설치하여 pacman을 이용할 수도 있는데, 이 포스팅에서는 MSYS2를 먼저 설치한 후에 pacman을 이용하여 MinGW 등 다른 패키지를 설치하는 방법을 정리한다.

## MSYS2 설치
[MSYS2 홈페이지](https://www.msys2.org/)에 접속하여 x86_64 용 설치 파일을(32bit/64bit 모두 포함되었음) 다운 받아서, 다운받은 설치 파일을 실행하면 설치가 진행된다. (설치 과정은 너무나 간단하므로 생략)

## MSYS2 shell 실행
설치가 완료되면 mintty 쉘을 열 수 있다. (32bit/64bit 쉘을 각각 열 수 있는데, 이제 32bit Windows는 사실상 거의 사용되지 않으므로, 32bit 쉘을 쓸 일은 거의 없을 것 같다)  
참고로 MSYS2 쉘을 실행시키지 않고, MSYS2 실행 경로를 PATH에 추가시킨 후 Windows 콘솔을 열어서 실행시킬 수도 있다. 이 경우에는 프롬프트가 bash가 아닌 Windows 프롬프트로 표시되는데, 본 포스팅에서는 MSYS2 쉘을 실행시킨 경우를 예로 들었다.

그런데 쉘은 아래와 같이 MSYS 쉘과 MINGW 쉘(다시 32bit, 64bit)이 따로 있다.  
1. MSYS2 MSYS: 쉘을 열면 프롬프트 앞에 `MSYS` 내용이 표시된다.
1. MSYS2 MinGW 64-bit: 쉘을 열면 프롬프트 앞에 `MINGW64` 내용이 표시된다.
1. MSYS2 MinGW 32-bit: 쉘을 열면 프롬프트 앞에 `MINGW32` 내용이 표시된다.

보통은 MSYS 쉘과 MinGW 쉘의 차이가 없으나, gcc 패키지의 경우와 같이 다른 경우가 있으므로, 필요에 알맞게 적절한 쉘을 열면 된다.

## 패키지 매니저
아래와 같이 실행하면 패키지 매니저의 도움말이 출력된다.
```bash
$ pacman --help
```

쉘에서 아래와 같이 실행하면 패키지 데이터베이스와 MSYS2 core 시스템 및 MSYS2 전체 시스템을 업데이트한다.
```bash
$ pacman -Syu
```
최초 업데이트가 완료되면 쉘을 닫은 후, 다시 쉘을 연다.  
(나중에도 원하면 언제든지 이 명령을 실행하여 MSYS2와 설치한 패키지를 업데이트할 수 있다.)

원격 패키지 검색은 아래와 같이 할 수 있다.
```bash
$ pacman -Ss <검색할 패키지 이름 일부>
```

패키지 설치는 아래와 같이 실행하면 된다.
```bash
$ pacman -S <패키지명>
```

## MinGW gcc 설치하기
MSYS2 shell 실행 부분에서 언급했듯이 먼저 적절한 shell을 골라야 한다.
MSYS 쉘을 실행한 경우에는  아래와 같이 gcc 패키지를 설치하고 설치된 경로를 확인할 수 있다.
```bash
$ pacman -S gcc
$ which gcc
/usr/bin/gcc
```

MinGW 쉘을 실행한 경우에는 아래와 같이 gcc 패키지를 설치하고 설치된 경로를 확인할 수 있다.
```bash
$ pacman -S mingw-w64-x86_64-gcc
$ which gcc
/mingw64/bin/gcc
```

설치가 완료되면 아래와 같이 버전을 확인해 볼 수 있다.
```bash
$ gcc --version
```

> 설치된 gcc 패키지를 통해 빌드하면 Windows 실행 파일이 나오는데, MSYS2 쉘에서 빌드한 실행 파일을 ldd로 확인해 보면 `msys-2.0.dll` 파일을 동적 링킹함을 알 수 있다. (즉, 배포시에 이 DLL도 함께 배포해야 함)  
> 반면에 MinGW 쉘에서 빌드한 실행 파일을 ldd로 확인해 보면 msys-2.0.dll 동적 링킹을 사용하지 않으므로 배포는 편리하지만 그만큼 파일 크기는 더 커졌음을 볼 수 있다.

## 추가 tool 설치 예
### make
```bash
$ pacman -S make
```
### vim
```bash
$ pacman -S vim
```
### git
```bash
$ pacman -S git
```
### base-devel
이 패키지에는 autoconf, automake, gdb, make, perl, python, sed 등의 개발 tool 들이 포함되어 있다.
```bash
$ pacman -S base-devel
```

## 설치한 패키지 업데이트
아래와 같이 실행하면 된다.
```bash
$ pacman -U <패키지명>
```

## 설치한 패키지 삭제
아래와 같이 실행하면 된다.
```bash
$ pacman -R <패키지명>
```

## MSYS2 제거
Windows에서 설치된 MSYS2 앱을 제거하면 된다.
