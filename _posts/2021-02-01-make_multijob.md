---
title: "make -j 옵션으로 하위 디렉터리를 multi-job 빌드하기"
category: Make
toc: true
toc_label: "이 페이지 목차"
---

make -j 옵션으로 빌드시 각 하위 디렉터리들도 동시에 multi-job 빌드하는 방법을 정리한다.

## 빌드 트리
프로젝트는 단순히 소스를 하위 디렉터리들도 나누어서 구성한 후, 하나의 `Makefile`에서 각 하위 디렉터리들의 소스들을 빌드하게 구성할 수 있고, 이 경우에는 make 명령시 `-j` 옵션을 붙이면 정상적으로 multi-job 빌드가 된다.  
그런데 프로젝트를 하위 디렉터리들도 별도의 `Makefile`을 구성하여 make 명령으로 각 하위 디렉터리만 빌드가 가능하도록 하고, base 디렉터리의 `Makefile`에서는 각 하위 디렉터리들을 `-C` 옵션인 change directory를 이용하여 빌드하는 방식으로 구현할 수도 있다.  
이때는 최상위 `Makefile`을 올바르게 구성하지 않으면 `-j` 옵션을 붙이더라도 하나의 하위 디렉터리 내에서만 parallel 빌드가 되고, 하위 디렉터리들이 동시에는 parallel 빌드가 되지 않는 현상을 볼 수 있다.
<br>
<br>
여기서는 이때 base 디렉터리에서 make로 `-j` 옵션을 붙여서 빌드할 경우에 하위 디렉터리들이 정상적으로 multi-job(즉, parallel) 모드로 빌드되는 방법을 기술한다.  
굉장히 간단하지만 실제로는 잘못 구성된 프로젝트가 많아서 (회사에서 주력으로 사용하는 프로젝트에서조차.. 😰) 이를 제대로 사용하도록 수정하였고, 이에 대해 간단히 정리해 본다.

## 하위 디렉터리 list 얻기
1. 하위 디렉터리 리스트는 아래 예와 같이 얻을 수 있다.
   ```makefile
   SUBDIRS = $(shell ls -p | grep "/$|" | cut -d/ -f1)
   ```
   또는
   ```makefile
   SUBDIRS = $(wildcard */))
   ```
1. 만약에 특정 디렉터리를 제거하고 싶으면, 각각 위의 방법에서 아래 예와 같이 제거할 수 있다. (아래 예에서는 **include** 디렉터리)
   ```makefile
   SUBDIRS = $(shell ls -p --ignore="include" | grep "/$|" | cut -d/ -f1)
   ```
   또는
   ```makefile
   SUBDIRS = $(filter-out include/, $(wildcard */))
   ```

## 하위 디렉터리의 잘못된 multi-job 방법
일반적으로 하위 디렉터리 빌드는 아래 예와 같이 할 수 있다. (shell 스크립트에서 `$`를 표현하기 위해서 `$$`를 사용하였음)  
많은 프로젝트들이 이런 방식으로 하위 디렉터리들을 빌드하고 있었다.
```makefile
SUBDIRS = $(wildcard */)
all:
    @for dir in $(SUBDIRS); do \
        $(MAKE) -C $$dir || exit 1; \
    done
clean:
    @for dir in $(SUBDIRS); do \
        $(MAKE) -C $$dir clean || exit 1; \
    done
```
그런데, 이 방법은 make `-j` 옵션으로 실행시 각각의 하위 디렉터리 내에서는 parallel 빌드가 되지만, 디렉터리들이 동시에는 parallel 빌드가 되지 않는 문제점이 있다. (실제로 **htop** 명령으로 CPU 사용률을 확인해 보거나, zsh에서 **time** 명령으로 CPU 사용률 및 빌드 시간을 확인해 볼 수 있다)

## 하위 디렉터리 올바른 multi-job 빌드 방법
여러 디렉터리들도 parallel 빌드가 되게 하려면 아래 예와 같이 하면 된다. (사실 이것 관련해서 정보가 거의 없어서 알아내기 위해서 한참을 찾았다. 😅)  
디렉터리명과 target 이름이 같을 경우에는 아래 예에서와 같이 `.PHONY`로 명시해야 한다.
```makefile
SUBDIRS = $(wildcard */)
.PHONY: $(SUBDIRS)
all: $(SUBDIRS)
clean: $(SUBDIRS)
$(SUBDIRS):
    @$(MAKE) $(MAKECMDGOALS) -C $@
```
참고로 이 방식에서는 에러가 발생하면 자동으로 빌드가 중지되므로 `|| exit 1` 추가는 필요하지 않다.  
이렇게 구성한 후에, 다시 **htop** 명령과, zsh에서 **time** 명령으로 CPU 사용률 및 빌드 시간을 확인해 보니, 정상적으로 하위 디렉터리들도 parallel 빌드가 됨을 확인하였다. 빌드 시간이 확연이 줄어들어 만족스럽다.  🍺

## 기타
빌드 시간을 단축시키는 방법에는 `-j` 옵션에 의한 multi-job 빌드 이외에도, `ccache`(compiler cache)를 이용한 방법도 있고, `distcc`(분산형 cc)를 이용할 수도 있는데, 여기서는 다루지 않겠다.
