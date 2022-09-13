---
title: "Doxygen config 파일을 저장소에서 관리하는 방법"
category: [Environment]
toc: true
toc_label: "이 페이지 목차"
---

[Doxygen](https://doxygen.nl/) config 파일을 소스 저장소에서 쉽게 관리하는 방법을 정리한다.

즉, 본 글에서는 최종 Doxygen config 파일을 소스 저장소에서 관리하는 대신에 업데이트 사항만 저장소에서 관리하는 방식을 사용할 것이다.

## Doxygen 설치
Doxygen은 [Doxygen download 페이지](https://doxygen.nl/download.html)에서 해당 OS에 맞는 설치 파일을 받아서 설치할 수 있다.

<br>
또는 Windows에서는 아래와 같이 설치할 수 있다.
```shell
C:\>winget install doxygen
```
설치가 되면 아래와 같이 doxygen과 Doxygen GUI front-end인 doxywizard가 설치되고, 해당 디렉터리에서 아래와 같이 실행할 수 있다.
```shell
C:\>doxygen
C:\>doxywizard.exe
```

<br>
또, 우분투에서는 아래와 같이 설치할 수 있다.
```shell
$ sudo apt install doxygen
```
우분투에서는 doxywizard가 별도의 패키지로 설치해야 하는데, 필요하면 아래와 같이 설치 및 실행할 수 있다.
```shell
$ sudo apt install doxygen-gui
$ doxywizard
```

## Doxygen config 파일
Doxygen은 입력 config 파일을 사용하여 Doxygen 문서를 생성하는데, 아래와 같은 형식으로 사용된다. (만약에 **[configName]**을 지정하지 않는 경우에는 디폴트로 `Doxyfile` 이름의 파일을 사용함)
```shell
$ doxygen [configName]
```
여기에서 사용되는 config 파일에는 Doxygen 버전 정보와 해당 버전에 유효한 각종 설정들이 포함되어 있다. 따라서 최종으로 사용된 config 파일을 그대로 소스 저장소에서 관리하게 되면, 다른 버전을 사용하는 시스템에서는 불일치가 발생할 수 있다.  
물론 해당 버전에서 지원하지 않는 설정인 경우에는 단순히 warning 메시지만 출력되긴 하지만, 이 방식의 문제점은 디폴트 설정값에서 프로젝트를 위해 변경한 사항들만 추적하기가 번거롭다는 것이다.
> 마치 Linux Kernel config도 최종으로 사용되는 `.config` 파일을 소스 저장소에서 관리하는 경우에는, Kernel 버전이 바뀌는 경우에 변경 내역 추적이 힘든 것과 마찬가지 상황이다.

## Doxygen config 업데이트 하기
프로젝트에서 설정한 값들만 별도의 config 파일로 소스 저장소에서 관리하고 이 파일로 최종 Doxygen에서 사용할 config 파일을 만들어 낼 수 있으면 이 문제가 해결되는데, doxygen 도움말을 보니 아래와 같이 `-u` 옵션을 주면 입력 config 파일을 시스템에 설치된 Doxygen의 config 파일로 업데이트해 주는 기능이 있었다.
```shell
$ doxygen -u [configName]
```

이제 이 기능을 이용하여 아래와 같은 스크립트 파일을 작성하였다. (여기에서는 예제로 프로젝트용 Doxygen config 파일로 **project.doxyfile** 파일을 사용)  
(따라서 소스 저장소에는 **project.doxyfile** 파일과 아래 스크립트 파일만 올리면 되고, Doxygen 문서를 생성하려면 간단히 이 스크립트만 실행하면 됨)
```bash
rm -rf html/
cp project.doxyfile Doxyfile && doxygen -u Doxyfile && rm -f Doxyfile.bak
doxygen Doxyfile
```
> 🚩 즉, 소스 저장소에는 `Doxyfile` 파일은 올리지 않음

이 방법을 사용함으로써, 기존에 전체 config 파일을 관리하던 방식 대신에 프로젝트를 위해서 설정한 값들만 관리하는 방식을 사용할 수 있게 되었다.

## Doxygen config 예제
참고로 아래는 내가 사용한 **project.doxyfile** 파일이다. (이런 식으로 소스 저장소에서는 아주 간단하게 설정한 정보들로만 config 파일을 운영할 수 있게 되고, 이로써 Doxygen 버전 관련 문제도 해결된다. 🧐)
```ini
DOXYFILE_ENCODING      = UTF-8
PROJECT_NAME           = "Project name"
OUTPUT_DIRECTORY       = .
BRIEF_MEMBER_DESC      = YES
ABBREVIATE_BRIEF       =
FULL_PATH_NAMES        = NO
TAB_SIZE               = 4
OPTIMIZE_OUTPUT_FOR_C  = YES
MARKDOWN_SUPPORT       = YES
SORT_MEMBER_DOCS       = NO
INPUT                  = ..
INPUT_ENCODING         = UTF-8
FILE_PATTERNS          = *.h *.c *.cpp *.md
RECURSIVE              = YES
EXAMPLE_PATH           = ..
EXAMPLE_PATTERNS       = *
IMAGE_PATH             = ..
SOURCE_BROWSER         = YES
REFERENCED_BY_RELATION = YES
REFERENCES_RELATION    = YES
GENERATE_HTML          = YES
HTML_OUTPUT            = html
GENERATE_TREEVIEW      = YES
GENERATE_LATEX         = NO
HAVE_DOT               = YES
UML_LOOK               = YES
CALL_GRAPH             = YES
CALLER_GRAPH           = YES
DOT_IMAGE_FORMAT       = svg
INTERACTIVE_SVG        = YES
DOT_PATH               = /usr/bin/dot
PLANTUML_JAR_PATH      = /usr/share/plantuml/plantuml.jar
```
