---
title: "Windows 콘솔에서 색깔 출력하기"
category: [C, Go]
toc: true
toc_label: "이 페이지 목차"
---

Windows command console(`cmd.exe`)에서 색깔을 출력하는 방법이다.

## Windows 콘솔 종류
Windows 콘솔 프로그램에는 디폴트인 `cmd.exe`가 있고, 그 외에 [Cmder](https://github.com/cmderdev/cmder), [ConEmu](https://github.com/Maximus5/ConEmu), [Mintty](https://mintty.github.io/), [Windows Terminal](https://github.com/microsoft/terminal) 등과 같은 프로그램들이 있다.  
이 중에서는 Windows command console(`cmd.exe`)은 디폴트로 색깔 출력을 지원하지 않고 있고, 그 외의 프로그램들은 디폴트로 색깔 출력을 지원하고 있다.

>나는 Windows Terminal이 출시된 이후로는 주로 이것만 사용하지만, **cmd.exe**는 별도의 설치가 필요없는 Windows 디폴트 콘솔 프로그램이므로, 이 프로그램에서도 내가 작성한 CLI(Command Line Interface) 프로그램에서 색깔이 정상적으로 출력이 되도록 지원해 줄 필요가 있었다.

## cmd.exe에서 색깔 지원하기
Windows command console(**cmd.exe**)에서 색깔 출력을 하려면 Windows API인 <font color=blue>SetConsoleMode()</font> 함수로  <mark style='background-color: #ffdce0'>ENABLE_VIRTUAL_TERMINAL_PROCESSING</mark> 모드를 enable 시키면 된다. 관련 API의 상세 정보는 아래 Microsoft 문서 페이지를 참조한다.
* [GetConsoleMode()](https://docs.microsoft.com/ko-kr/windows/console/getconsolemode)
* [SetConsoleMode()](https://docs.microsoft.com/ko-kr/windows/console/setconsolemode)

아래에 C와 Go 언어를 사용한 간단한 예제를 작성하였고, **cmd.exe**를 비롯한 여러 Windows 콘솔 프로그램에서 정상적으로 색깔이 출력되는 것을 확인하였다.  
(아래 예제들은 GetConsoleMode() 함수로 output 모드를 얻어서 **ENABLE_VIRTUAL_TERMINAL_PROCESSING** 비트가 enable 되어 있지 않으면 SetConsoleMode() 함수로 이 bit를 enable 시키는 방식임)

## C 예제
```c
#include <windows.h>
#include <stdio.h>

#define COLOR_FG_RED        "\x1b[31m"
#define COLOR_FG_GREEN      "\x1b[32m"
#define COLOR_FG_YELLOW     "\x1b[33m"
#define COLOR_FG_BLUE       "\x1b[34m"
#define COLOR_FG_MAGENTA    "\x1b[35m"
#define COLOR_FG_CYAN       "\x1b[36m"
#define COLOR_OFF           "\x1b[0m"

int main(int argc, char *argv[])
{
    HANDLE hOutput = GetStdHandle(STD_OUTPUT_HANDLE);
    DWORD outMode;

    if (GetConsoleMode(hOutput, &outMode) != 0) {
        if ((outMode & ENABLE_VIRTUAL_TERMINAL_PROCESSING) == 0) {
            SetConsoleMode(hOutput, outMode | ENABLE_VIRTUAL_TERMINAL_PROCESSING);
        }
    }

    printf("%sRED color%s\n", COLOR_FG_RED, COLOR_OFF);
    printf("%sGREEN color%s\n", COLOR_FG_GREEN, COLOR_OFF);
    printf("%sBLUE color%s\n", COLOR_FG_BLUE, COLOR_OFF);
    return 0;
}
```
아래와 같이 GCC로 빌드한 후, 실행시킬 수 있다.
```shell
C:\>gcc -o <실행파일이름.exe> <파일이름.c>
```

## Go 예제
```go
package main

import (
    "fmt"
    "os"

    "golang.org/x/sys/windows"
)

const (
    COLOR_FG_RED     = "\x1b[31m"
    COLOR_FG_GREEN   = "\x1b[32m"
    COLOR_FG_YELLOW  = "\x1b[33m"
    COLOR_FG_BLUE    = "\x1b[34m"
    COLOR_FG_MAGENTA = "\x1b[35m"
    COLOR_FG_CYAN    = "\x1b[36m"
    COLOR_OFF        = "\x1b[0m"
)

func main() {
    var outMode uint32
    windowsOutHandle := windows.Handle(os.Stdout.Fd())
    if err := windows.GetConsoleMode(windowsOutHandle, &outMode); err == nil {
        if outMode&windows.ENABLE_VIRTUAL_TERMINAL_PROCESSING == 0 {
            windows.SetConsoleMode(windowsOutHandle, outMode|windows.ENABLE_VIRTUAL_TERMINAL_PROCESSING)
        }
    }

    fmt.Println(COLOR_FG_RED + "RED color" + COLOR_OFF)
    fmt.Println(COLOR_FG_GREEN + "GREEN color" + COLOR_OFF)
    fmt.Println(COLOR_FG_BLUE + "BLUE color" + COLOR_OFF)
}
```

Windows 표준 출력 핸들을 얻는 부분이 약간 다른 것 외에는 C 예제와 동일하다.

## 결론
Linux/macOS 터미널의 경우나 Windows Terminal 등의 경우에는 디폴트로 색깔 출력이 지원되어서 신경쓸 것이 없었지만, Windows 디폴트 콘솔 프로그램인 **cmd.exe**는 디폴트로는 색상 출력을 지원하지 않아서 CLI 프로그램 구현시에 불편한 점이 있는데, 이 경우에도 위와 같이 간단한 세팅을 통해 정상적으로 색깔이 출력되게 할 수 있다.
