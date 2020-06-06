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

## 추가: SWT 프로젝트 예
회사에서 사용하는 툴 중에서 소스 트리가 여러 하위 디렉트리로 구성되어 있고 소스 파일도 많은 SWT를 사용하는 툴이 있는데, 이것도 Eclipse에서의 빌드가 번거로워서 Makefile로 구성해 보았다. (실제로 소스를 수정할 일이 있어서 VSCode에서 소스 수정 및 디버깅/실행을 하였고, 최종 jar 파일을 생성하기 위해서 구성해 보았음)

처음에는 각각의 java 파일을 빌드하는 것으로 접근하였는데 이것이 쉽지 않아서 (사실은 java 파일 빌드시 호출하는 패키지의 java 파일들도 빌드되는 바람에 전체 빌드 시간이 너무 오래 걸려서), 그냥 간단히 main 자바 파일을 이용하여 전체를 빌드하도록 구성하였다.  
Makefile 내용은 아래와 같이 구성하였다. (실제로 자바 소스 파일들은 각 디렉토리 밑에 여러 다단계 하위 디렉토리로 구성되어 있는데, 아래와 같이 top 경로만 지정해주면 됨) 
```makefile
JAVAC = javac
JAR = jar
MKDIR = mkdir
RM = rm -rf

SRC_TOP = src
OUT_TOP = bin
LIB_DIR = lib

TARGET = MyTool.jar
MAIN_SRC = AppMain.java

SRC_DIRS = \
	src_dir1 \
	src_dir2 \
	src_dir3 \
	src_dir4 \
	org

SRC_DIRS_PATH = $(addprefix $(SRC_TOP)/,$(SRC_DIRS))
OUT_DIRS_PATH = $(addprefix $(OUT_TOP)/,$(SRC_DIRS))

vpath %.java $(SRC_DIRS_PATH)
vpath %.class $(OUT_DIRS_PATH)

BUILD_FLAGS = $(addprefix -C $(OUT_TOP) ,$(SRC_DIRS)) $(OUT_TOP)/*.dll

MAIN_CLASS = $(MAIN_SRC:.java=.class)

all: $(MAIN_CLASS)
	cd $(OUT_TOP) && $(JAR) xf ../$(LIB_DIR)/swt.jar
	$(JAR) -cmf Manifest.mf $(TARGET) $(BUILD_FLAGS)
	@echo "Build is done. Output file is $(TARGET)"

clean:
	@$(RM) $(OUT_TOP)/* $(TARGET)
	@echo "Clean is done"

%.class: %.java
	$(JAVAC) -d $(OUT_TOP) -sourcepath $(SRC_TOP) -classpath $(LIB_DIR)/* $<
```

SWT를 사용하기 위하여 `swt.jar` 파일을 포함해야 하는데, jar 파일에서 다른 jar 파일을 포함시킬 수 없어서 swt.jar 파일을 압축을 푼 후, 이것을 포함시키도록 하였다(SWT DLL 파일들 포함).

Manifest.mf 파일은 위의 예와 마찬가지로 Main-Class 항목에 `패키지명.메인클래스`와 같이 세팅하여 구성하였다.

Make로 빌드하면 jar 파일이 만들어지고, 내용을 분석해보면 Eclipse에서 만든 것과 동일하게 구성되어 있었고, 실제로 실행을 해 보면 정상적으로 잘 실행이 되었다.
