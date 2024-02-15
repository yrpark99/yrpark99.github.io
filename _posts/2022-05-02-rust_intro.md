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
* [crates.io](https://crates.io/): Rust 커뮤니티 패키지(crate)
* [The Rust Programming Language](https://rinthel.github.io/rust-lang-book-ko/): Rust 책 (한글판)

## Modern language
Rust는 신생 언어답게 아래와 같은 modern language 기능들을 지원하고 있다.
* 빌드 툴 통합
* 패키지 관리자
* 오픈소스 패키지 저장소
* 디폴트 테스트 프레임워크
* 문서 자동화

## Rust로 작성된 프로그램들 소개
아래는 내가 관심있거나 애용하는 Rust로 구현된 open source 프로그램들이다. 앞으로도 좋은 프로그램들이 많이 나오길 기대해 본다.
* [Actix](https://actix.rs/)  
  Rust를 위한 Web 프레임워크이다. 속도가 아주 빠르다고 한다.

* [AppFlowy](https://github.com/AppFlowy-IO/appflowy)  
  [Notion](https://www.notion.so)을 대체할 수 있는 오픈 소스로 Rust와 Flutter로 구현되었다.

* [bat](https://github.com/sharkdp/bat)  
  `cat`을 대체할 수 있는 툴로, 파일의 내용을 신택스 하이라이팅해서 보여주고, 내용을 up/down 하거나 찾기 기능 등도 제공한다. 또 tab 간격이 디폴트로 4로 되어 있어서 편한데다가 `--tabs=n` 옵션으로 변경도 가능한다.  
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
  alias ll='exa --binary -lg --group-directories-first --sort=name --time-style=long-iso'
  alias llb='exa -lgB --group-directories-first --sort=name --time-style=long-iso'
  ```
  추가로 파일 아이콘도 출력하게 하려면 [Nerd Fonts](https://www.nerdfonts.com/)를 설치한 후에, `--icons` 옵션을 추가로 주면 된다.

* [fd](https://github.com/sharkdp/fd)  
  `find`와 유사한 파일 검색 툴로, `.gitignore` 파일에 명시된 패턴은 찾지 않는다(찾게 하려면 `-I` 옵션을 추가하면 됨). 또 hidden 파일도 찾지 않는데, 찾게 하려면 `-H` 옵션을 추가하면 된다.

* [GitUI](https://github.com/Extrawurst/gitui)  
  터미널용 Git 클라이언트 툴이다. 비슷한 툴로는 [tig](https://github.com/jonas/tig), [lazygit](https://github.com/jesseduffield/lazygit) 등이 있는데, 대부분의 경우에 이것들보다 속도가 빠르고 기능도 편리하여, 나의 경우 CLI 환경에서는 이 툴을 많이 사용하고 있다.  
  참고로 코드 diff 시에 **tab**은 **space 2**로 표시되고 있는데, 이것을 **space 4**로 변경하려면 (현재 기준에서는 사용자가 설정할 수 있는 기능이 없으므로) 소스 코드를 받아서 src/string_utils.rs 파일의 tabs_to_spaces() 함수를 아래와 같이 수정한 후, 재빌드하면 된다.
  ```rs
  pub fn tabs_to_spaces(input: String) -> String {
      let mut output = String::new();
      let mut space_count = 0;

      for c in input.chars() {
          if c == '\t' {
              let num_spaces = 4 - (space_count % 4);
              output.push_str(&" ".repeat(num_spaces));
              space_count = 0;
          } else {
              output.push(c);
              space_count += 1;
          }
      }

      output
  }
  ```

* [Helix](https://github.com/helix-editor/helix)  
  [Kakoune](https://kakoune.org/), [Neovim](https://neovim.io/) 등과 유사한 소스 코드 에디터이다. Rust로 작성되어 상당히 빠르며, mult-cursor, LSP(Lanaugage Server Protocol), tree-sitter 등을 기본으로 지원한다. 단, 시스템에 [How to install the default language servers](https://github.com/helix-editor/helix/wiki/How-to-install-the-default-language-servers) 페이지를 참조하여 사전에 해당 language server를 설치해 놓아야 한다.  
  단점으로는 현재까지는 플러그인을 지원하지 않고 있다는 것인데, 조만간 WASM을 이용하여 플러그인을 지원할 것으로 보인다.  
  이에 비해 Neovim은 플러그인을 지원하므로 아직은 Helix가 Neovim을 대체할 수는 없지만, Neovim보다 속도가 빠르다는 장점이 있다.

* [Lapce](https://github.com/lapce/lapce)  
  Rust로 작성된 멀티 플랫폼을 지원하는 범용 코드 에디터이다. 자체적으로 LSP(Lanaugage Server Protocol), 원격 개발 지원, 터미널 등의 기능을 내장하고 있고, 플러그인도 지원하고 있다. (WASI 포맷 사용)  
  아직은 VSCode에 비해 기능도 적고, 플러그인도 턱없이 부족하긴 하지만, 실행 속도가 빠르고 오픈 소스로써 VSCode에 대항할 만한 코드 에디터로 내가 주목하고 있는 에디터이다.

* [Redox](https://gitlab.redox-os.org/redox-os/redox)  
  Rust로 작성된 운영 체제이다.

* [Ripgrep](https://github.com/BurntSushi/ripgrep)  
  `grep`과 `ack` 계열의 장점을 합친 파일 내용 검색 툴로 상당히 빠른 속도를 자랑한다. Git 저장소인 경우에 `.gitignore` 파일에 있는 파일 패턴들은 검색하지 않으므로 더 빠르고 편리하게 사용할 수 있다. (마찬가지로 `.ignore` 파일이나 `.rgignore` 파일에 있는 파일 패턴들도 검색하지 않음)  
  [Platinum Searcher](https://github.com/monochromegane/the_platinum_searcher)와 함께 내가 주로 사용하는 검색 툴이다.
  > 참고로 검색	결과는 디폴트로 UTF-8로 출력하는데, 한글 인코딩을 EUC-KR로 하고 싶으면 아래 예와 같이 지정하면 된다.
  ```sh
  $ rg --encoding=euc-kr "문자열"
  ```

* [RustDesk](https://github.com/rustdesk/rustdesk)  
  [TeamViewer](https://www.teamviewer.com), [AnyDesk](https://anydesk.com/) 등과 같은 원격 데스크톱 툴인데, 한국에도 서버가 있고 현재 무료이다. (나는 Oracle 평생 무료 서버에 설치해서 이용 중임)

* [Tauri](https://github.com/tauri-apps/tauri)  
  [Electron](https://github.com/electron/electron)과 같은 desktop Web application 프레임워크인데, Rust로 작성되어 Electron보다 크기는 작고 속도는 빠르다.  
  추가로 [Awesome Tauri](https://github.com/tauri-apps/awesome-tauri) 페이지에 들어가 보면 Tauri를 사용한 앱 등을 확인할 수 있다. 예를 들어 [Xplorer](https://xplorer.space/) 앱은 멀티 플랫폼 용 파일 탭과 preview 등의 기능을 지원하는 파일 탐색기인데, 처음에는 Electron을 사용했었다가 이후 빠른 속도를 위하여 Tauri로 변경되었다.

* [uutils coreutils](https://github.com/uutils/coreutils)  
  GNU coreutils를 Rust로 재구현하는 오픈소스 프로젝트이다. Rust로 작성해서 안정성을 높였고, 크로스 플랫폼을 지원한다. (따라서 임베디드 장치에서 기존에 C로 구현되었던 Busybox를 이것으로 대체할 수도 있음)

* [Zed](https://zed.dev/)  
  VSCode와 같은 GUI 편집기로, 현재는 beta 상태이고 macOS만 지원하지만, 추후 Windows와 Linux 플랫폼도 지원 계획이 있다.  
  Rust로 구현되어 메모리 사용량이 적고, 속도가 상당히 빠르고(랜더링에 GPU도 이용함), LSP(Language Server Protocol)가 내장되어 있어서 현재 C/C++, Go, JavaScript, Python, Rust, TypeScript 등의 언어를 기본 지원하고 있다. 또, 협업 기능과, AI assistant 지원 기능도 내장하고 있다.  
  다만 현재는 플러그인은 지원하지 않고 있는데, 크로스 플랫폼 지원과 플러그인을 지원하게 되면, VSCode의 강력한 경쟁자가 될 수 있을 것 같아서 관심을 가지고 지켜보고 있다.

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
   실행 파일들은 `~/.cargo/bin/` 디렉토리에 설치되는데, 해당 경로가 PATH에 추가되도록 자동으로 ~/.bashrc 파일에서 아래 내용이 추가된다.
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
1. 아래와 같이 실행하면 자동으로 `git init` 명령과 **src/main.rs**, **.gitignore**, **Cargo.toml** 파일을 생성해 준다. (프로젝트명은 디폴트로 현재 디렉토리 이름으로 세팅됨)
   ```shell
   $ cargo init
   ```
1. 빌드는 아래와 같이 할 수 있다.
   ```shell
   $ cargo build
   ```
   결과로 `target/debug/` 디렉토리에 빌드 파일이 생성된다.

## Cargo 사용 예
1. 새 프로젝트 생성
   ```shell
   $ cargo new <디렉토리명>
   $ cd <디렉토리명>
   ```
1. Crate(패키지) 찾기
   ```shell
   $ cargo search "찾을 이름"
   ```
1. 특정 패키지 설치하기
   ```shell  
   $ cargo add <패키지명>
   ```
   결과로 `Cargo.toml` 파일에서 **[dependencies]** 섹션에 추가된다.  
   추가된 특정 패키지를 다시 제거하려면 아래와 같이 실행하면 된다.
   ```shell
   $ cargo remove <패키지명>
   ```
1. 패키지를 최신 버전으로 업그레이드하기
   ```shell  
   $ cargo upgrade
   ```
1. 빌드
   ```shell
   $ cargo build
   ```
   릴리즈용 이미지 빌드시에는 아래와 같이 `--release` 아규먼트를 추가하면 **target/release/** 디렉토리에 최적화된 빌드파일이 생성된다.
   ```shell
   $ cargo build --release
   ```
   참고로 만약에 release 파일은 디버그 정보를 strip 하고 싶으면 빌드 후에 `strip` 명령으로 해당 실행 파일을 strip 하거나, `Cargo.toml` 파일에 아래 내용을 추가하면 빌드시 자동으로 strip 된다.
   ```toml
   [profile.release]
   strip = true
   ```
1. 빌드 Clean 하기
   ```
   $ cargo clean
   ```
   결과로 **target** 디렉토리가 삭제된다.
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
1. 이후 해당 디렉토리에서 아래 예와 같이 빌드할 수 있다. (아래 예는 ARM64로 cross 빌드하는 예제)
   ```shell
   $ cross build --target aarch64-unknown-linux-gnu
   ```

## Static link(정적 링크) 방법
참고로 Windows에서 Rust로 빌드한 실행 프로그램을 Microsoft VC(이하 `MSVC`) runtime 라이브러리가 설치되지 않은 Windows 환경에서 실행시키면 `VCRUNTIME140.dll`이 없다고 나오면서 실행이 안 되었다.  
이는 빌드된 실행 프로그램이 MSVC runtime 라이브러리를 static으로 포함하고 있지 않아서인데, 라이브러리들을 static으로 포함시키려면 프로젝트에서 `.cargo/config.toml` 파일을 생성한 후, 아래와 같이 작성하면 된다.
```toml
[target.x86_64-pc-windows-msvc]
rustflags = ["-C", "target-feature=+crt-static"]
```
이후 다시 빌드해 보면 MSVC 라이브러리들이 static으로 포함되고, MSVC 라이브러리가 설치되지 않은 Windows 시스템에서도 정상적으로 실행됨을 확인할 수 있다.  
<br>
Linux 플랫폼에서도 마찬가지로 빌드된 실행 파일을 `ldd`로 확인해 보면 `GLIBC` 라이브러리를 dynamic link로 사용하고 있음을 확인할 수 있고, 다른 버전이 GLIBC 라이브러리가 설치된 시스템에서는 정상적으로 실행되지 않는다.  
시스템에 설치된 GLIBC 라이브러리 버전과 무관하게 실행되게 하려면, GLIBC 라이브러리 대신에 MUSL 라이브러리를 사용할 수 있는데, 이를 위해서 `.cargo/config.toml` 파일은 수정할 필요가 없고, 아래와 같이 빌드하면 된다.
```sh
$ sudo apt install musl-tools
$ rustup target add x86_64-unknown-linux-musl
$ cargo build --target=x86_64-unknown-linux-musl
```
이후 빌드된 실행 파일을 다시 `ldd`로 확인해보면 **statically link**로 표시되고, 실제로 다른 GLIBC 라이브러리 버전이 설치된 시스템에서도 정상적으로 실행된다.

## Android Rust
안드로이드 11부터는 네이티브 OS 구성 요소를 개발하기 위하여 Rust를 사용할 수 있다. 자세한 내용은 [Android Rust](https://source.android.com/docs/setup/build/rust/building-rust-modules/overview) 페이지를 참고한다.

> 구글 Security Blog [Memory Safe Languages in Android 13](https://security.googleblog.com/2022/12/memory-safe-languages-in-android-13.html) 페이지를 보면, 안드로이드에서의 Rust 코드 비중이 점점 늘어나고 있고 (Android 13의 경우 새로 작성된 Rust 코드의 비중은 C 언어와 비슷), 이 결과로 메모리 취약점은 2019년 223개에서 2022년 85개로 감소되었다고 한다.  
더구나 현재까지 Rust로 작성된 코드에서 발생한 메모리 취약점은 없었다고 한다. 😲

## Windows Rust
Microsoft는 최근부터 보안상의 이유로 C/C++를 사용하지 말 것을 권장하고 있고, Windows의 주요 부분들을 Rust로 재구현하고 있다. (아래는 기사에서 발췌)
> Win32k에서는 취약점이 종종 나오는 편입니다. 공격자들이 이 요소를 자주 노리기도 하고요. 그래서 최근 MS는 Win32k에 해당하는 부분만 Rust로 재구성했습니다.
