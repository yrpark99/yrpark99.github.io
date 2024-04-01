---
title: "C/C++ 용 LSP(Language Server Protocol) 이용하기"
category: [C/C++]
toc: true
toc_label: "이 페이지 목차"
---

LSP를 지원하는 편집기에서 C/C++ 소스 코드의 navigation 등을 위한 방법을 기술한다.  
<br>

특정 컴퓨터 언어를 사용하여 코딩 시에, 편집기에서 해당 언어의 문법 강조, 자동 완성, symbol로 이동, symbol 찾기, hover 도움말, 구문 에러 검사, 포매팅, 리팩토링 등의 기능을 이용하면 빠르고 쉽게 코딩할 수 있다. 그런데, 의외로 이런 기능들을 제대로 이용하지 않고 (또는 일부만 이용하면서) 코딩을 하는 사람들도 많이 있어서 (이런 환경 구축에도 어려운 점이 있으므로), 기록 및 공유 차원에서 정리해 본다.  
<br>
LSP(Language Server Protocol)를 지원하는 편집기인 경우에는 위의 모든 기능들은 LSP 환경만 구축하면 쉽게 이용할 수 있다. (Modern 편집기들은 이제 대부분 LSP를 지원함)

## LSP 소개
`LSP(Language Server Protocol)`는 Microsoft 사에서 개발한 프레임워크로, JSON-RPC를 이용하여 M 개의 에디터에서 N 개의 언어를 지원하는 효율적인 프로토콜을 제공한다.  
즉, 예전에는 각 에디터에서 해당 언어마다 native나 플러그인으로 구현하였지만 이 방법은 많은 리소스가 들어가고 이것을 다른 에디터에서는 전혀 사용하지 못했는데, LSP를 이용하면 서로 다른 에디터에서도 동일한 language server를 이용하여 쉽게 다른 언어를 지원할 수 있게 되었다. 이로 인해 편집기에서는 해당 언어를 지원하기 위하여 LSP 프로토콜에 맞추어 클라이언트를 구현하기만 하면 된다.  
참고로 현재 구현된 language server는 [Language server 목록](https://microsoft.github.io/language-server-protocol/implementors/servers/) 페이지에서 확인해 볼 수 있다.  
<br>
사용자 입장에서는 여러 언어를 사용해야 하는 경우에도, 해당 언어를 지원하는 전용 편집기를 사용할 필요없이, LSP를 지원하는 편집기를 사용하는 경우에는 해당 언어의 language server를 설치한 후, 편집기에서 해당 플러그인만 설치하면 기존 편집기를 그대로 사용할 수  있는 이점이 있다.  
<br>
참고로 LSP를 사용하지 않는 경우와 LSP를 사용하는 경우는 아래 그림을 보면 쉽게 알 수 있을 것이다.  
![](/assets/images/lsp-languages-editors.png)

<br>
상세 내용은 [Language Server Protocol](https://microsoft.github.io/language-server-protocol/) 페이지에서 찾아볼 수 있다.  
<br>
실제로 Visual Studio를 비롯하여 VS Code, Neovim, Sublime Text, Helix, Lapse 등이 LSP를 지원하고 있다. 이 중에서 유료인 Visual Studio를 제외한 나머지 편집기들에서 아래 방법을 사용하여 모두 정상적으로 LSP가 동작함을 확인하였고, 아래에서 간단히 정리하였다.

## C/C++ 용 language server
C/C++를 위한 LSP를 사용하기 위해서는 시스템에 C/C++를 위한 language server가 설치되어 있어야 하는데, 여기에는 대표적으로 `clangd`, `ccls` 등이 있다. 이 글에서는 가장 많이 사용되는 **clangd** 설치를 예로 든다.  
아래와 같이 실행하면 우분투 APT 저장소에 있는 최신 clangd 패키지를 설치한다.
```shell
$ sudo apt install clangd
```
또는 아래 예와 같이 원하는 버전을 수동으로 다운받아서 설치할 수 있다. (아래 예는 v12.0.1 설치)
```shell
$ wget https://github.com/clangd/clangd/releases/download/12.0.1/clangd-linux-12.0.1.zip
$ unzip clangd-linux-12.0.1.zip
$ sudo chown -R root:root clangd_12.0.1/
$ sudo cp -arf clangd_12.0.1/* /usr/
```
설치가 되었으면 아래와 같이 버전을 확인할 수 있다. (버전이 제대로 표시되면 설치는 완료된 것임)
```shell
$ clangd --version
```

> ✅ VS Code와 같은 편집기는 자체적으로 language server를 설치하므로, 이런 경우에는 위와 같이 시스템에 별도로 language server를 설치할 필요가 없고, 간단히 해당 플러그인([C/C++](https://marketplace.visualstudio.com/items?itemName=ms-vscode.cpptools))을 설치하기만 하면 된다.

그런데 매크로를 지원하지 않는 언어에서는 간단하게 소스 navigation 등이 잘 되지만 C/C++는 매크로를 지원하고, 이로 인해 Makefile에 의한 define이나 include 경로가 복잡해 지는데 😵, 이로 인해 정상적인 코드 navigation이 안 된다.  
<br>
💡 해결책은 이런 define이나 include 설정들을 language server에 알려 주는 것인데, 이를 위해서는 VS Code처럼 편집기에서 지원하는 세팅에 추가해 주거나, <font color=blue>compilation database</font> <font color=purple>(compile_commands.json)</font> 파일을 사용하면 된다.

## Compilation database 파일 생성 방법
Compilation DB 파일의 생성 방법은 빌드 시스템에 따라서 다른데, 아래에 많이 사용되는 빌드 시스템의 경우를 예시하였다.
### Make 빌드 시스템인 경우
빌드 로그를 이용하여 compilation DB 파일을 생성해 주는 툴이 몇가지 있다. 대표적으로 [bear](https://github.com/rizsotto/Bear), [compiledb](https://github.com/nickdiego/compiledb) 등이 있는데, 이 글에서는 좀 더 기능이 많은 **compiledb**를 사용하겠다. 먼저 아래와 같이 compiledb 파이썬 패키지를 설치한다.
```shell
$ pip3 install compiledb
```
이제 프로젝트 디렉토리에서 아래 예와 같이 실행하면 compile_commands.json 파일이 생성된다.
```shell
$ compiledb -n -f --command-style make -j
```
>참고로 위에서 사용한 옵션의 의미는 아래와 같다.
>* `-n` 또는 `--no-build`: 실제로 빌드는 하지 않음 (즉, dry-run, 물론 원하면 이 옵션을 사용하지 않고 실제로 빌드를 시켜도 됨)
>* `-f` 또는 `--overwrite`: 기존 compile_commands.json 파일을 업데이트하는 대신에 덮어 쓰기함
>* `--command-style`: compile_commands.json 파일에서 `"arguments"`에 여러 줄 대신에 `"command"`에 한 줄로 저장함 (여러 줄이든 한 줄이든 둘 다 정상 동작은 하나, compile_commands.json 파일의 줄 수를 줄이기 위하여)

또는 아래 예와 같이 빌드시 생성한 로그 파일을 이용할 수도 있다.
```shell
$ compiledb < build-log.txt
```
물론 이때 위에서와 마찬가지로 옵션을 지정할 수도 있다.
```shell
$ compiledb -n -f --command-style < build-log.txt
```
> 🚩 **compiledb**의 경우 빌드 출력에 한글이 섞여 있으면 compile_commands.json 파일이 올바르게 생성되지 않을 수 있다. 이 경우에는 아래 예와 같이 언어 설정을 초기화해 주면 (즉, 디폴트인 영어를 사용) 된다.
> ```shell
> $ unset LANG
> ```

참고로 Linux Kernel의 경우라면 아래와 같은 방법들로 생성할 수 있다.
1. Kernel v5.10 이전 버전이라면 아래 예와 같이 빌드 로그 출력 파일을 이용할 수 있다.
   ```shell
   $ make -j V=1 --dry-run |& tee build-log.txt
   $ compiledb < build-log.txt
   ```
1. Kernel v5.10 이후 버전이라면 bear나 compiledb와 같은 외부 패키지 없이도, 새롭게 추가된 `scripts/clang-tools/gen_compile_commands.py` 스크립트를 이용하여 아래와 같이 생성할 수 있다.
   ```shell
   $ make -j
   $ scripts/clang-tools/gen_compile_commands.py
   ```

> 또는 Linux Kernel인 경우에는 VS Code를 위하여 Linux Kernel 프로젝트를 셋업 해주는 [vscode-linux-kernel
](https://github.com/amezin/vscode-linux-kernel)와 같은 툴을 사용하면 편리하다. 아래와 같이 실행하면 된다.
> 1. Linux Kernel을 빌드 한다. (결과로 ***.cmd** 파일이 생성되어 있어야 함)
> 1. Linux 소스 base 경로에서 아래와 같이 `.vscode` 디렉토리로 clone 받은 후, **generate_compdb.py**를 실행하면 **compile_commands.json** 파일이 생성된다.
>    ```shell
>    $ git clone https://github.com/amezin/vscode-linux-kernel.git .vscode
>    $ python .vscode/generate_compdb.py
>    ```
> 1. 이제 VS Code로 열어서 소스 브라우징을 해보면, 정상적으로 LSP가 동작함을 확인할 수 있다.

### Clang 빌드 시스템인 경우
빌드시에 -MJ 옵션을 주면 된다.

### CMake 빌드 시스템인 경우
빌드시에 아래와 같이 `-DCMAKE_EXPORT_COMPILE_COMMANDS=ON` 옵션을 추가하면 된다.
```shell
$ cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON .
```

### Ninja 빌드 시스템인 경우
아래와 같이 `-t compdb` 옵션을 이용하면 된다. 
```shell
$ ninja -t compdb > compile_commands.json
```

### Android AOSP인 경우
안드로이드 AOSP에서는 아래와 같이 환경 변수를 세팅한 후에 빌드하면 C/C++ 파일에 대한 **compile_commands.json** 파일이 현재 경로에 생성된다.
```shell
$ export SOONG_GEN_COMPDB=1
$ export SOONG_GEN_COMPDB_DEBUG=1
$ export SOONG_LINK_COMPDB_TO=$PWD
$ m
```

## C/C++ cross-toolchain인 경우
C/C++ 빌드시 시스템 툴체인을 사용하는 경우에는 디폴트 시스템 경로에서 표준 헤더 파일을 찾으므로 문제가 없지만, cross-toolchain을 사용하는 경우에는 표준 헤더 파일을 cross-toolchain 경로에서 찾아야 한다.  
Cross-toolchain을 사용하는 경우에 표준 헤더 파일을 cross-toolchain 경로에서 찾게 하려면, **Makefile** 파일에서 아래 예와 같이 CFLAGS에 <font color=purple>--sysroot</font> 옵션으로 해당 경로를 지정해 주면 된다. (아래 예에서 `$(CC)`는 cross-toolchain의 C compiler 이름으로 세팅되어 있어야 함)
```make
CFLAGS += --sysroot=$(abspath $(shell $(CC) -print-sysroot))
```

## Vim 류에서 LSP 사용하기
Vim, Neovim, Helix 등의 Vim 류의 편집기들은 터미널 base의 편집기로 특히 쉬운 설치와 빠른 속도가 강점이다.
이들은 시스템에 해당 언어의 툴체인과 language server를 설치해야 하는데, 위에서도 언급했듯이 C/C++의 경우에는 language server로 `clangd`를 설치하면 된다.  
그러면 `compile_commands.json` 파일의 내용에 따라서 코드 navigation도 잘 되고, 자동 완성, 구문 에러 검사, refactoring 등의 기능도 잘 동작한다. (그런데 <font color=violet>inactive</font> 된 코드들이 흐리게 표시되는 기능은 Neovim에서는 잘 동작하지만 Vim이나 Helix에서는 동작하지 않았다)
1. [Vim](https://github.com/vim/vim)  
   [CoC](https://github.com/neoclide/coc.nvim) 플러그인을 설치한다.  
   아래와 같이 LSP 목록을 확인할 수 있다.
   ```c
   :CocInstall coc-marketplace
   ```
   예를 들어 clangd는 아래와 같이 설치할 수 있다.
   ```c
   :CocInstall coc-clangd
   ```
1. [Neovim](https://github.com/neovim/neovim)  
   Neovim은 자체적으로 LSP를 지원하는데, [lspconfig](https://github.com/neovim/nvim-lspconfig) 플러그인을 함께 사용하면 편리하다.  
   Neovim 자체적으로 C/C++ 용 language server를 설치하려면 아래와 같이 실행하면 된다.
   ```c
   :LspInstall clangd
   ```
   추가로 [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) 플러그인을 설치하면 신택스 하이라이트가 좀 더 개선되어 표시된다.
   <br>
   > 참고로 나는 CLI 환경에서는 주로 Neovim을 사용하는데, Neovim 사용 시에는 [LazyVim](https://www.lazyvim.org/) 또는 [LunarVim](https://www.lunarvim.org/)을 사용하여 환경을 구축하고 있다. 이것들을 이용하면 다른 개발 서버에서 CLI 환경을 이용하는 경우에도 아주 쉽게 Neovim으로 IDE와 유사한 환경을 구축을 할 수 있다.
1. [Helix](https://github.com/helix-editor/helix)  
   Helix는 자체적으로 LSP를 지원하므로, 시스템에 해당 언어의 language server만 설치되면 된다. 예를 들어 C/C++인 경우에는 시스템에 `clangd`를 설치하면 된다.  
   이 편집기는 Rust로 구현되어 Vim이나 Neovim보다 빠른 속도를 자랑하고, 웬만한 기능들이 모두 편집기에 내장되어 있으므로, 추후에 플러그인도 지원하게 된다면 Vim/Neovim 사용자는 Helix도 시도해 볼 만하다.

참고로 만약에 "Too many errors emitted, stopping now"와 같은 LSP 에러가 발생하면서 LSP가 정상 동작하지 않는 경우에는, 아래 예와 같이 CFLAGS 옵션에 `-ferror-limit=0` 내용을 추가해 주면 LSP가 stop 되지 않게 할 수 있다.
```shell
$ compiledb -n -f --command-style make CFLAGS="-ferror-limit=0"
```
<br>

🛠️ 추가로 clangd에서 디폴트 설정을 변경하고 싶으면, [clangd Configuration](https://clangd.llvm.org/config.html) 페이지를 참조하여 유저 홈 디렉토리나(전체 적용), 해당 프로젝트의 base 경로에 `.clangd` 파일을 작성하면 된다. 예를 들어 아래 설정은 "**Included header XXX is not used directly**" warning을 disable 시킨다.
```yml
Diagnostics:
  Suppress: unused-includes
```

## Sublime Text에서 LSP 사용하기
[Sublime Text](https://www.sublimetext.com/)는 멀티 플랫폼을 지원하는 편집기로 빠른 속도, 다양한 설정, 예쁜 테마, 다양한 플러그인 패키지 등이 장점이다.
> 참고로 Windows에서 WSL을 사용하는 경우에는 Windows10인 경우에는 [GWSL](https://apps.microsoft.com/store/detail/gwsl/9NL6KD1H33V3?hl=ko-kr&gl=KR), Windows11인 경우에는 [WSLg](https://github.com/microsoft/wslg)를 이용하면 Sublime Text와 같은 GUI 앱도 쉽게 사용할 수 있다.

LSP를 사용하기 위해서 Sublime Text도 Vim 류의 편집기와 마찬가지로 시스템에 language server를 설치해야 하는데, C/C++의 경우에는 마찬가지로 `clangd`를 설치하면 된다.  
이후 Sublime Text에서 [LSP](https://github.com/sublimelsp/LSP) 패키지를 설치한 후, 각 언어용 LSP 패키지를 설치한다. (C/C++의 경우에는 빌트인으로 포함되어 있으므로 추가로 LSP 패키지를 설치할 필요가 없고, 그 외의 언어인 경우에는 예를 들어 Go는 [LSP-gopls](https://github.com/sublimelsp/LSP-gopls), Python은 [LSP-pyright](https://github.com/sublimelsp/LSP-pyright), Rust는 [LSP-rust-analyzer](https://github.com/sublimelsp/LSP-rust-analyzer), TypeScript는 [LSP-typescript](https://github.com/sublimelsp/LSP-typescript) 패키지를 설치하면 됨)  
그런데 테스트 해 보니 다른 언어는 바로 LSP가 동작하였지만, C/C++의 경우에는 바로 동작하지는 않았고, Sublime Text에서 Command Palette를  실행하여 **"LSP: Enable Language Server Globally" -> "clangd"** 항목을 선택하니까 되었다. 또는 수동으로 메뉴에서 Preferences -> Packages Settings -> LSP -> Settings 항목을 실행하여 아래와 같이 수정해도 된다.
```json
{
   "clients":
   {
      "clangd":
      {
         "enabled": true,
      },
   },
   "semantic_highlighting": true
}
```
참고로 Sublime Text는 C/C++의 경우에 매크로에 의해서 inactive 된 코드들이 디폴트 설정으로는 흐리게 표시되지 않았는데, 찾아보니 **semantic_highlighting** 설정이 디폴트로 false 상태이기 때문이었다.  
그래서 LSP 설정 파일에 위와 같이 `"semantic_highlighting": true` 항목을 수동으로 추가하였고, 결과로 inactive 된 코드들이 정상적으로 흐리게 표시되었다. 👍

## Lapce에서 LSP 사용하기
[Lapce](https://lapce.dev/)는 멀티 플랫폼을 지원하는 편집기로 Rust로 구현된 오픈 소스이다 (소스는 [lapce](https://github.com/lapce/lapce)에서 받을 수 있음). VS Code와 유사한 UI 구성에 빠른 속도가 강점이다.  
C/C++ LSP를 사용하기 위해서는 `clangd`를 설치한 후, 설정에서 Plugin Settings -> C/C++ (clangd) -> Path to clangd 항목에서 clangd가 설치된 전체 경로를 세팅하면 된다. 또는 **~/.config/lapce-stable/settings.toml** 파일에서 아래 예와 같이 세팅해도 된다.
```toml
[lapce-cpp-clangd]
"volt.serverPath" = "/usr/bin/clangd"
```
이후부터는 해당 프로젝트에서 `compile_commands.json` 파일을 생성하면 LSP를 사용할 수 있다.

## VS Code에서 LSP 사용하기
[VS Code](https://code.visualstudio.com/)는 원하는 언어를 지원하는 익스텐션을 설치하면 해당 language server가 자동으로 설치되므로 아주 편리하다. C/C++의 경우에는 [C/C++ 익스텍션](https://marketplace.visualstudio.com/items?itemName=ms-vscode.cpptools)을 설치하면 된다.  
이후 관련 세팅은 해당 프로젝트의 `.vscode/c_cpp_properties.json` 파일에서 설정하면 되는데, 자동으로 아래와 같은 형태로 만들어진다.
```json
{
    "configurations": [
        {
            "name": "Linux",
            "includePath": [
                "${workspaceFolder}/**"
            ],
            "defines": [],
            "compilerPath": "/usr/bin/gcc",
            "cStandard": "gnu17",
            "cppStandard": "gnu++17",
            "intelliSenseMode": "linux-gcc-x64",
        }
    ],
    "version": 4
}
```
**Makefile**에서 사용하는 <mark style='background-color: #ffdce0'>-I</mark>로 지정되는 include path와 <mark style='background-color: #ffdce0'>-D</mark>로 지정되는 define 내용을 위 파일에서 `"includePath"`, `"defines"`에 추가하면 된다. 이 방법은 아주 편리하긴 하지만, VS Code의 경우 define 매크로에 의해 코드가 inactive 인 경우에는 백그라운드가 흐리게 표시되므로 (물론 이것도 설정 변경이 가능하지만 이 상태가 코딩시 훨씬 편리함), define 정보가 누락된 경우에는 active/inactive 영역이 잘못 표시될 수 있으므로 주의가 필요하다.  
<br>
또, VS Code는 이 방법 외에도 compile DB (**compile_commands.json**) 파일도 지원하는데, 만약에 프로젝트 디렉토리에서 **compile_commands.json** 파일이 발견되면, 아래 팝업을 띄우면서 이 파일을 사용할 것인지 묻는다.  
![](/assets/images/vscode_compiledb.png)  
위에서 **Yes** 버튼을 누르면 `.vscode/c_cpp_properties.json` 파일에 자동으로 아래 내용이 추가된다. (물론 위의 팝업을 이용하는 대신에 그냥 JSON 파일에 수동으로 아래와 같이 추가해도 됨)
```json
"compileCommands": "compile_commands.json"
```
만약에 cross-toolchain을 사용하는 경우에는 컴파일러가 gcc가 아니므로, **c_cpp_properties.json** 파일에서 `"compilerPath"` 내용을 사용되는 cross 컴파일러의 경로로 수정한다. 그러면 `"intelliSenseMode"` 내용은 자동으로 올바르게 세팅된다.
> 참고로 소스 코드가 원격 서버에 있는 경우에는 [Remote - SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh), WSL에 있는 경우에는 [Remote - WSL](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl) 익스텐션을 이용하여 해당 서버에 접속하면 된다.

위에서도 언급했듯이 VS Code에서는 inactive 코드가 쉽게 분간이 되고, 사용법이 쉽고 편리하면서도 막강한 기능과 수많은 익스텐션으로 수년 전부터 내가 가장 선호하는 편집기이다. 물론 이것도 LSP를 제대로 활용해야 한결 편리한 프로그래밍이 환경이 될 것이기에 시간을 들여서 기록을 남긴다.
