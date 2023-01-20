---
title: "Rust 언어 소개"
category: Rust
toc: true
toc_label: "이 페이지 목차"
---

2016년 이후로 줄곧 개발자가 가장 사랑하는 언어 1위로 뽑히고 있는 [Rust](https://www.rust-lang.org/) 언어를 간략히 소개한다.

<br>
Rust는 모질라 리서치에서 개발한 범용 프로그래밍 언어로 2010년 처음으로 일반에 공개되었고, 2012년에 첫 번째 알파 버전인 0.1이 발표되었고, 오픈 소스로 개발되고 있다. C언어와 마찬가지로 저수준 프로그래밍이 가능하며 적은 크기와 빠른 속도가 강점이고 (Garbage Collector가 없음), 빌드 시에 메모리 오류 등을 방지해서 보다 안정적인 프로그램을 작성할 수 있다.  
<br>
그리고 꼭 Rust로 개발하지는 않는다고 하더라도, Rust의 secure 프로그래밍 개념을 익히면 다른 언어로 개발할 때에도 도움이 될 수 있으므로, low 레벨도 다루는 프로그래머라면 관심을 가져보는 것을 추천한다. 👍

## 관련 웹페이지
* [Rust 홈페이지](https://www.rust-lang.org/): 툴체인 설치, 문서, 툴, [Playground](https://play.rust-lang.org/) 등
* [GitHub Rust](https://github.com/rust-lang/rust): Rust 개발 소스 저장소
* [Rust awesome](https://github.com/awesome-rust-com/awesome-rust): Rust를 사용한 엄선된 프로그램들 목록
* [crates.io](https://crates.io/): Rust 커뮤니티 패키지

## Modern language
Rust는 아래와 같은 modern language 기능들을 지원하고 있다.
* 빌드 툴 통합
* 패키지 관리자
* 오픈소스 패키지 저장소
* 디폴트 테스트 프레임워크
* 자동 문서화

## Rust로 작성된 프로그램들 소개
아래는 내가 애용하는 Rust로 구현된 open source 프로그램들이다. 앞으로도 좋은 프로그램들이 많이 나오길 기대해 본다.
* [AppFlowy](https://github.com/AppFlowy-IO/appflowy)  
   [Notion](https://www.notion.so)을 대체할 수 있는 오픈 소스로 Rust와 Flutter로 구현되었다.
* [bat](https://github.com/sharkdp/bat)  
   `cat`을 대체할 수 있는 툴로, 파일의 내용을 신택스 하이라이팅해서 보여주고, 내용을 up/down 하거나 찾기 기능 등도 제공한다.  
   참고로 이 `bat`를 이용한 [bat-extras](https://github.com/eth-p/bat-extras) 툴들도 있다.

* [bottom](https://github.com/ClementTsang/bottom)  
   [btop](https://github.com/aristocratos/btop)과 비슷하게 시스템 리소스 관련 정보를 모니터링하는 툴이다.

* [bore](https://github.com/ekzhang/bore)  
   [ngrok](https://ngrok.com/), [localtunnel](https://github.com/localtunnel/localtunnel) 툴과 같은 http/https 터널링 툴이다.

* [delta](https://github.com/dandavison/delta)  
   Git diff 등의 명령시에 side-by-side view, syntax-highlighting 등의 기능을 제공한다.

* [dua](https://github.com/Byron/dua-cli)  
   `du` 툴을 대체할 수 있는 Disk Usage Analyzer 툴이다. 크기 순으로 소팅되며 색깔이 표시된다. 만약 실행시 `i` 옵션을 주면 interactive 모드로 동작한다.  비슷한 툴에는 Go로 구현된 [gdu](https://github.com/dundee/gdu) 툴 등이 있는데, `dua`의 속도가 더 빠르다.

* [exa](https://github.com/ogham/exa)  
  `ls`를 대체할 수 있는 툴로, 색깔이나 파일 아이콘 출력 등의 기능을 제공한다. 참고로 `~/.bashrc` 파일에 아래 예와 같이 alias를 세팅하여 사용하면 편리하다.
  ```shell
  alias l='exa'
  alias ll='exa -lg --group-directories-first --sort=name --time-style=long-iso'
  alias llb='exa -lgB --group-directories-first --sort=name --time-style=long-iso'
  ```
  추가로 파일 아이콘도 출력하게 하려면 [Nerd Fonts](https://www.nerdfonts.com/)를 설치한 후에, `--icons` 옵션을 추가로 주면 된다.

* [fd](https://github.com/sharkdp/fd)  
   `find`와 유사한 파일 검색 툴로, `.gitignore` 파일에 명시된 패턴은 찾지 않는다(찾게 하려면 `-I` 옵션을 추가하면 됨). 또 hidden 파일도 찾지 않는데, 찾게 하려면 `-H` 옵션을 추가하면 된다.

* [GitUI](https://github.com/Extrawurst/gitui)  
   터미널용 Git 클라이언트 툴이다. 비슷한 툴로는 [tig](https://github.com/jonas/tig), [lazygit](https://github.com/jesseduffield/lazygit) 등이 있는데, 대부분의 경우에 이것들보다 속도가 빠른 편이다.

* [Helix](https://github.com/helix-editor/helix)  
   [Kakoune](https://kakoune.org/), [Neovim](https://neovim.io/) 등과 유사한 소스 코드 에디터이다. Rust로 작성되어 상당히 빠르며, mult-cursor, LSP(Lanaugage Server Protocol), tree-sitter 등을 기본으로 지원한다. 단, 시스템에 [How to install the default language servers](https://github.com/helix-editor/helix/wiki/How-to-install-the-default-language-servers) 페이지를 참조하여 사전에 해당 language server를 설치해 놓아야 한다.  
   단점으로는 현재까지는 플러그인을 지원하지 않고 있으나 조만간 WASM을 이용하여 플러그인을 지원할 것으로 보인다.  
   나는 Windows 환경에서는 주로 VS Code, Linux 터미널에서는 Vim을 대체하여 Neovim을 사용하고 있는데, Helix는 Neovim보다 훨씬 빠른 속도를 자랑해서 내가 주목하고 있는 에디터 중의 하나이다.

* [Lapce](https://github.com/lapce/lapce)  
  Rust로 작성된 멀티 플랫폼을 지원하는 범용 코드 에디터이다. 자체적으로 LSP, 원격 개발 지원, 터미널 등의 기능을 내장하고 있고, 플러그인도 지원하고 있다. (WASI 포맷 사용)  
  현재는 아직 개발 초기 단계라서 C/C++, Go, Java, JavaScript, Python, Rust, TypeScript 등의 언어만 지원하고 있고, VS Code에 비해 기능도 적고, 플러그인도 턱없이 부족하긴 하지만, 실행 속도가 빠르고 오픈 소스로써 VS Code에 대항할 만한 코드 에디터로 내가 주목하고 있는 에디터이다.

* [Redox](https://gitlab.redox-os.org/redox-os/redox)  
   Rust로 작성된 운영 체제이다.

* [Ripgrep](https://github.com/BurntSushi/ripgrep)  
   `grep`과 `ack` 계열의 장점을 합친 파일 내용 검색 툴로 상당히 빠른 속도를 자랑한다. Git 저장소인 경우에 `.gitignore` 파일에 있는 파일 패턴들은 검색하지 않으므로 더 빠르고 편리하게 사용할 수 있다. (마찬가지로 `.ignore` 파일이나 `.rgignore` 파일에 있는 파일 패턴들도 검색하지 않음)  
   [Platinum Searcher](https://github.com/monochromegane/the_platinum_searcher)와 함께 내가 주로 사용하는 검색 툴이다.

* [RustDesk](https://github.com/rustdesk/rustdesk)  
   [TeamViewer](https://www.teamviewer.com), [AnyDesk](https://anydesk.com/) 등과 같은 원격 데스크톱 툴인데, 한국에도 서버가 있고 현재 무료이다.

* [Tauri](https://github.com/tauri-apps/tauri)  
   [Electron](https://github.com/electron/electron)과 같은 desktop Web application 프레임워크인데, Rust로 작성되어 Electron보다 크기는 작고 속도는 빠르다.  
   추가로 [Awesome Tauri](https://github.com/tauri-apps/awesome-tauri) 페이지에 들어가 보면 Tauri를 사용한 앱 등을 확인할 수 있다. 예를 들어 [Xplorer](https://xplorer.space/) 앱은 멀티 플랫폼 용 파일 탭과 preview 등의 기능을 지원하는 파일 탐색기인데, 처음에는 Electron을 사용했었다가 이후 빠른 속도를 위하여 Tauri로 변경되었다.

## Rust 툴체인 설치
1. 아래와 같이 rustc 패키지를 설치한다. (단, 이 방법은 APT 패키지를 사용하는 것이므로, 보통 최신 버전을 따라가지는 못함)
   ```shell
   $ sudo apt install rustc
   ```
   설치가 완료되면 rustc와 cargo가 설치된다. 버전은 아래와 같이 확인할 수 있다.
   ```shell
   $ rustc --version
   $ cargo --version
   ```
   아래와 같이 아규먼트없이 실행하면 기본적인 사용법이 출력된다.
   ```shell
   $ rustc
   $ cargo
   ```
   단일 rust 파일의 빌드는 아래와 같이 할 수 있다.
   ```shell
   $ rustc <파일이름>
   ```
1. 최신 툴체인과 기타 툴을 쉽게 설치/제거하는 권장하는 방법은 Rust 설치 관리자인 [rustup](https://github.com/rust-lang/rustup)을 이용하여 설치하는 것으로 아래와 같이 하면 된다.
   ```shell
   $ curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   ```
   또는 우분투인 경우에는 아래와 같이 SNAP 패키지로 설치할 수도 있다.
   ```shell
   $ sudo snap install rustup --classic
   ```
   실행 파일들은 `~/.cargo/bin/` 디렉터리에 설치되는데, 해당 경로가 PATH에 추가되도록 자동으로 ~/.bashrc 파일에서 아래 내용이 추가된다.
   ```shell
   . "$HOME/.cargo/env"
   ```
   설치된 툴체인 리스트 확인은 아래와 같이 할 수 있다
   ```shell
   $ rustup toolchain list
   ```
   Rust toolchain 삭제는 아래와 같이 하면 된다.
   ```shell
   $ rustup self uninstall
   ```
   Rust 버전 업데이트는 아래와 같이 한다.
   ```shell
   $ rustup update stable
   ```

## 기타 Rust 관련 툴
* [Cargo](https://github.com/rust-lang/cargo): Rust 패키지 매니저, 빌드 툴
* [Clippy](https://github.com/rust-lang/rust-clippy): Rust lint 툴
* [Miri](https://github.com/rust-lang/miri): Rust 소스 코드 검사 툴
* [Rust-analyzer](https://github.com/rust-lang/rust-analyzer): IDE/Editor LSP 용 Rust language server
* [rustfmt](https://github.com/rust-lang/rustfmt): Rust 소스 코드 포매팅 툴
* [Rustup](https://github.com/rust-lang/rustup): Rust 툴체인 매니저

## 프로젝트 소스 setup
1. 아래와 같이 실행하면 자동으로 `git init` 명령과 **src/main.rs**, **.gitignore**, **Cargo.toml** 파일을 생성해 준다. (프로젝트명은 디폴트로 현재 디렉터리 이름으로 세팅됨)
   ```shell
   $ cargo init
   ```
1. 빌드는 아래와 같이 할 수 있다.
   ```shell
   $ cargo build
   ```
   결과로 `target/debug/` 디렉터리에 빌드 파일이 생성된다.

## Cargo 사용 예
1. 새 프로젝트 생성
   ```shell
   $ cargo new <디렉터리명>
   $ cd <디렉터리명>
   ```
1. 빌드
   ```shell
   $ cargo build
   ```
   릴리즈용 이미지 빌드시에는 아래와 같이 `--release` 아규먼트를 추가하면 **target/release/** 디렉터리에 최적화된 빌드파일이 생성된다.
   ```shell
   $ cargo build --release
   ```
   참고로 만약에 release 파일은 디버그 정보를 strip 하고 싶으면 빌드 후에 `strip` 명령으로 해당 실행 파일을 strip 하거나, `Cargo.toml` 파일에 아래 내용을 추가하면 빌드시 자동으로 strip 된다.
   ```toml
   [profile.release]
   strip = true
   ```
1. 빌드된 파일을 바로 실행하기
   ```shell
   $ cargo run
   ```
   만약 cargo run 사용시 프로그램의 아규먼트가 있는 경우는, `cargo run` 뒤에 아규먼트를 순서대로 입력하면 된다.
1. 빌드 대신에 문법 검사만 하려면 아래와 같이 한다.
   ```shell
   $ cargo check
   ```
1. Unit 테스트 하기
   ```shell
   $ cargo test
   ```
1. 종속 패키지의 버전 업데이트
   `Cargo.toml` 파일에는 프로젝트가 사용하는 종속 패키지들을 지정할 수 있는데, 여기서 패키지명과 버전을 함께 지정한 후, 아래와 같이 실행하면 된다.
   ```shell
   $ cargo update
   ```
1. 소스 코드 포매팅
   ```shell
   $ cargo fmt
   ```
1. 문서화
   아래 명령을 수행하면 문서를 생성하고, 브라우저로 문서를 오픈하게 된다.
   ```shell
   $ cargo doc --open
   ```

## Cross 빌드
1. [Cross 툴체인](https://github.com/cross-rs/cross) 설치는 아래와 같이 한다.
   ```shell
   $ cargo install -f cross
   ```
   참고로 이 cross 툴체인은 미리 만들어진 <font color=purple>Dockerfile</font>을 사용하는데, 전체 Dockerfile 목록은 [이 페이지](https://github.com/cross-rs/cross/tree/main/docker) 에서 확인할 수 있다.
1. 이후 해당 디렉터리에서 아래 예와 같이 빌드할 수 있다. (아래 예는 ARM64로 cross 빌드하는 예제)
   ```shell
   $ cross build --target aarch64-unknown-linux-gnu
   ```

## Android Rust
안드로이드 11부터는 네이티브 OS 구성 요소를 개발하기 위하여 Rust를 사용할 수 있다. 자세한 내용은 [Android Rust](https://source.android.com/docs/setup/build/rust/building-rust-modules/overview) 페이지를 참고한다.

> 구글 Security Blog [Memory Safe Languages in Android 13](https://security.googleblog.com/2022/12/memory-safe-languages-in-android-13.html) 페이지를 보면, 안드로이드에서의 Rust 코드 비중이 점점 늘어나고 있고 (Android 13의 경우 새로 작성된 Rust 코드의 비중은 C 언어와 비슷), 이 결과로 메모리 취약점은 2019년 223개에서 2022년 85개로 감소되었다고 한다.  
더구나 현재까지 Rust로 작성된 코드에서 발생한 메모리 취약점은 없었다고 한다. 😲
