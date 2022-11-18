---
title: "C/C++ 빌드시 security hardening"
category: [C, Security]
toc: true
toc_label: "이 페이지 목차"
---

Linux에서 C/C++로 코딩 후 빌드시 security hardening 관련을 기술한다.

<br>
시스템의 보안 강화는 구성하는 모든 컴포넌트 들에서 이루어져야 하는데, 이 글에서는 가장 기본이 되는 C/C++로 빌드된 실행 파일의 security 강화 기법을 간단히 정리해 본다.

## PIE
`PIE(Position Independent Executable)` 또는 `PIC(Position Independent Code)`는 코드를 메모리에 올릴 때 동일한 절대 주소가 아닌 임의의 다른 주소에 로딩함으로써 (여러 프로그램에서 사용되는 공유 라이브러리인 경우도 마찬가지) reverse 엔지니어링을 힘들게 한다.  
기본 개념은 dynamic 링킹 과정에서 text 섹션은 수정이 불가능하기 때문에 함수 call을 할 때 미리 data 영역에 위치하는 PLT(Procedure Linkage Table), GOT(Global Offset Table)를 만들어 놓고 해당 테이블을 가리키게 하고, data 영역은 수정이 가능하기 때문에 lazy binding 식으로 GOT에 함수 주소를 write 하는 것이다.
> Linux `ASLR(Address Space Layout Randomization)`에 의해서 프로그램이 매번 실행될 때마다 stack, heap, library의 position은 바뀌지만, main executable 영역은 매번 같은 메모리 주소에 로드된다. 여기에 PIE를 추가로 적용하게 되면 stack, heap, library 뿐만 아니라, main executable의 base address까지 매번 바뀌게 된다. (실행 중인 프로그램의 메모리 맵은 /proc/pid/maps 파일로 확인 가능)  
<br>
참고로 Linux에서 ASLR의 현재 상태는 아래와 같이 확인할 수 있다.
>```shell
>$ cat /proc/sys/kernel/randomize_va_space
>```
>각 값의 의미는 아래와 같다.
>- randomize_va_space=0: ASLR disable
>- randomize_va_space=1: stack, shared 메모리 영역 등 random
>- randomiza_va_space=2: tack, shared 메모리 영역, data segment 등 random (디폴트 값임)

PIE를 활성화시키기 위해서는 컴파일 시에 `-fPIE` 옵션을 추가하고, 링킹 시에 `-pie` 옵션을 추가하면 된다. 또 shared library를 빌드하는 경우에는 `-fPIC` 옵션으로 컴파일해야 한다.  
<br>
🚩또한 static library를 빌드하는 경우에도 `-fPIC` 옵션을 추가하여 빌드해야, 이 정적 라이브러리를 빌드하는 프로그램에서 PIE 활성화가 가능해지므로 보안을 중요시해야 하는 library인 경우에는 정적/동적 라이브러리 무관하게 무조건 `-fPIC` 옵션을 사용하는 것이 좋다.

## Stack protect
Stack BOF(Buffer OverFlow) 공격은 가장 기본적인 해킹 방법의 하나인데, stack은 SSP(Stack Smashing Protector)에 보호될 수 있다. SSP는 스택 버퍼와 스팩 프레임 포인터 사이에 canary 값을 삽입하고, 함수가 리턴될 때 이 값이 변경되었는지 여부를 검사함으로써 stack 버퍼 오버플로우를 감지한다. (참고로 canary 값의 변경이 감지되면 **__stack_chk_fail()** 함수가 호출되고 프로그램이 종료됨)  
SSP 활성화는 간단히 컴파일 시에 필요에 따라 `-fstack-protector`, `-fstack-protector-strong`, `-fstack-protector-all` 옵션 중의 하나를 추가하면 되는데, GCC 버전 4.1 이후부터는 거의 자동으로 enable 된다.

## RELRO
RELRO(RELocation Read-Only)는 GOT(Global Offset Table) overwrite와 같은 공격에 대비하는 메모리 보호 기술로, 아래와 같은 종류가 있다.
1. Partial RELRO
   - 링크 옵션: `-z relro` (gcc 사용시에는 `-Wl,-z,relro`)
   - Lazy binding으로 함수 호출시 해당 주소를 알아옴, 단, GOT는 write 가능함
1. Full RELRO
   - 링크 옵션: `-z relro -z now` (gcc 사용시에는 `-Wl,-z,relro,-z,now`)
   - Now binding으로 프로그램 실행시 GOT에 모든 라이브러리 주소를 바인딩함, GOT는 read-only 임
   - 만약에 GOT에 데이터 쓰기를 시도하면 segmentation fault가 발생함

해당 ELF 바이너리 파일에서 RELRO는 `readelf` 툴로 확인해 볼 수 있다.  
참고로 FULL RELRO가 GOT가 읽기 전용이라 보안상 더 안전하긴 하지만 실제로는 Partial RELRO가 더 널리 사용된다. 왜냐하면 full RELRO의 경우 프로세스가 시작될 때 링커에 의해 모든 메모리에 대해 재배치 작업을 완료한 후에 실행하므로 프로그램의 로딩 속도가 느려지기 때문이다.

## NX bit (실행 방지 비트)
NX Bit(Never eXecute bit)는 데이터 영역에서 코드가 실행되는 것을 막는 기법으로, 보통 chip core가 지원하는 H/W 자원을 운영체제에서 이용하는 방식으로 구현된다. 이 방법을 통해 공격자가 stack, heap, data 영역에서 공격자의 code를 실행시키는 것을 방지한다.  
최신 컴파일러에서는 디폴트로 이것이 활성화 되는데, 만약 인위적으로 disable 시키려면 빌드시에 `-z execstack` 옵션을 추가하면 된다.

## Fortify Source
GCC 컴파일 시에 `-D_FORTIFY_SOURCE=2 -Wformat -Wformat-security`와 같은 옵션을 추가해 주면 C/C++ 소스의 security 관련 함수를 검사해 준다. (_FORTIFY_SOURCE=1이면 약한 검사, _FORTIFY_SOURCE=2이면 강한 검사임)

## 검사 tool
Linux에서 실행 파일이나 so 파일의 security hardening 검사는 readelf 툴 등으로로 조사할 수도 있지만, 아래와 같은 툴들을 이용하면 훨씬 편리하게 확인할 수 있다. 😋
- hardening-check 툴  
  우분투인 경우 아래와 같이 설치할 수 있다.
  ```shell
  $ sudo apt install devscripts
  ```
  아래 예와 같이 타겟 파일을 검사할 수 있다.
  ```shell
  $ hardening-check --color <파일이름>
  ```
  결과는 아래 예와 같이 출력된다. (**결과**에 실제 검사 결과가 출력됨)
  ```shell
  파일이름:
   Position Independent Executable: 결과
   Stack protected: 결과
   Fortify Source functions: 결과
   Read-only relocations: 결과
   Immediate binding: 결과
   Stack clash protection: 결과
   Control flow integrity: 결과
  ```
- [hardening_check.pl](https://github.com/ProhtMeyhet/hardening-check) 툴  
  아래와 같이 다운받아서 실행 권한을 주면 사용할 수 있다.
  ```shell
  $ sudo wget https://raw.githubusercontent.com/ContinuumIO/anaconda-benchmarking/master/hardening_check.pl -O /usr/bin/hardening_check.pl
  $ sudo chmod +x /usr/bin/hardening_check.pl
  ```
  아래 예와 같이 타겟 파일을 검사할 수 있다.
  ```shell
  $ hardening_check.pl --color 파일이름
  ```
  결과는 아래 예와 같이 출력된다. (**결과**에 실제 검사 결과가 출력됨)
  ```shell
  파일이름:
    Position Independent Executable (PIE): 결과
    Stack Smashing Protector (SSP): 결과
    Fortified Functions (FFs): 결과
    String Format Security Functions (SFSFs): 결과
    Non-Executable Stack (NES): 결과
    Non-Executable Heap (NEH): 결과
    Relocation Read-Only (RELRO): 결과
    Immediate Symbol Binding (NOW): 결과
  ```
- [checksec](https://github.com/slimm609/checksec.sh) 툴  
  아래와 같이 `checksec` 패키지를 설치하면 된다.
  ```shell
  $ sudo apt install checksec
  ```  
  아래 예와 같이 타겟 파일을 검사할 수 있다.
  ```shell
  $ checksec --file=파일이름
  ```
  결과는 아래 예와 같이 출력된다. (**결과**에 실제 검사 결과가 출력됨)
  ```shell
  RELRO     STACK CANARY     NX        PIE       RPATH      RUNPATH      Symbols      FORTIFY Fortified      Fortifiable      FILE
  결과      결과             결과      결과      결과       결과         결과         결과    결과           결과             파일이름
  ```
  원하면 아래 예와 같이 `--output=json` 옵션을 추가하면 출력이 JSON 형식으로 표시된다.
  ```json
  $ checksec --file=파일이름 --output=json | jq
  {
    "파일이름": {
      "relro": "결과",
      "canary": "결과",
      "nx": "결과",
      "pie": "결과",
      "rpath": "결과",
      "runpath": "결과",
      "symbols": "결과",
      "fortify_source": "결과",
      "fortified": "결과",
      "fortify-able": "결과"
    }
  }
  ```
  만약 디렉터리 안의 파일들을 모두 검사하려면 아래와 같이 하면 된다.
  ```shell
  $ checksec --dir=디렉터리이름
  ```
  ✅ 사실상 이 툴이 위의 툴 들보다 기능이 많으므로 이 툴만 사용해도 충분하다. 또 디렉터리 내의 파일들도 한 번에 검사할 수 있어서, 내가 임베디드 시스템의 rootfs 파일들의 hardening 검사 용도로 애용하는 방법이다.

## 결론
GCC 툴체인은 계속해서 hardening을 강화하고 있어서 host에서 최신 GCC 툴체인을 사용해서 빌드해 보면 별도의 빌드 옵션을 추가하지 않아도 빌드된 파일의 hardening이 꽤 잘되어 있음을 확인할 수 있다.  
그런데 cross GCC 툴체인을 사용하는 경우에는 최신 버전이 아니고 오래된 버전을 사용하는 경우가 많고, 이 경우에는 별도의 빌드 옵션을 추가하지 않으면 hardening이 약하게 되어 있음을 확인할 수 있고, 이 경우에 hardening을 강화하고 확인하는 방법으로 이 글을 참조할 수 있겠다.
