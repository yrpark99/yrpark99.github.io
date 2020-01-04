---
title: "자바 코드를 make로 빌드하기"
category: java
toc: true
toc_label: "이 페이지 목차"
---

Console 환경에서 make로 자바 소스 빌드하기


## 목적
프로젝트 빌드 트리가 Maven, Ant 등으로 빌드 구성이 되어 있지 않아서, IDE 환경에서만 빌드할 수 있어서 불편한 관계로, console에서 단순히 make만 실행하여 빌드되도록 구성한다.  
(실제로 빌드 구성 완료한 이후에는 자바 소스는 VSCode 등으로 간단히 수정하고 빌드는 make만 실행하면 되므로, IDE를 띄우는 것보다 훨씬 빠르고 편리하였다) 

## 환경 설정
JDK가 설치되어 있고 java, javac, jar 등의 실행 파일들이 PATH에 잡혀 있어야 한다.  
Windows 환경인 경우에는 MSys2 등을 사용하면 되고, Linux 환경이면 바로 console을 사용하면 된다.

## 소스 트리 구성
자바 소스는 base 디렉토리에서 src 디렉토리 밑에 1단계 하위 디렉토리들 밑에 있다고 가정한다. 컴파일한 파일들은 bin 디렉토리 밑에 1단계 하위 디렉토리들로 구성한다. (당연히 소스 트리가 이렇게 구성되어 있지 않은 경우에는 Makefile도 대응하여 수정해줘야 함)

## Makefile 파일 예
Base 디렉토리에서 아래 예와 같이 작성한다. (구글링해도 관련 자료를 찾기가 힘들어서 자작했음)
```makefile
TARGET = test.jar

SRC_DIR = src
OUT_DIR = bin

SUB_DIRS = $(shell ls $(SRC_DIR))
SRC_DIRS = $(addprefix $(SRC_DIR)/,$(SUB_DIRS))
SRC_FILES = $(foreach dir,$(SRC_DIRS),$(wildcard $(dir)/*.java))
CLASS_DIRS = $(addprefix -C $(OUT_DIR) ,$(SUB_DIRS))

all:
    @test -d $(OUT_DIR) || mkdir $(OUT_DIR)
    @javac -d $(OUT_DIR) -sourcepath src $(SRC_FILES)
    @jar -cmf Manifest.mf $(TARGET) $(CLASS_DIRS)
    @echo "Build is done. Output file is $(TARGET)"

clean:
    @rm -rf $(OUT_DIR) $(TARGET)
    @$(RM) $(TARGET)
    @echo "Clean is done"
```

## Manifest.mf 파일 예
Base 디렉토리에서 아래 예와 같이 작성한다. (구글링해도 Class-Path 세팅이 없어서 힘들었음)  
(Main-Class 항목에 `패키지명.메인클래스`와 같이 세팅하는데, 아래 예에서는 Main 패키지의 AppMain 클래스라고 가정)  

```makefile
Class-Path: .
Main-Class: Main.AppMain

```
> **주의**: 반드시 맨 마지막에 빈 줄이 있어야 함

## 클린 및 빌드
이제 아래와 같이 clean, build 할 수 있다. (Windows 환경도 마찬가지)
```bash
$ make clean
$ make
```

## 실행
아래 예와 같이 실행시킬 수 있다. (Windows 환경도 마찬가지)
```bash
$ java -jar test.jar
```