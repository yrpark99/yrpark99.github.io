---
title: "Bash 팁 정리"
category: Linux
toc: true
toc_label: "이 페이지 목차"
---

내가 참조하기 위한 Bash 팁 정리

## Shell 관련 도움말 얻기
- 아래와 같이 실행하면 GNU core util의 도움말을 볼 수 있다.
  ```sh
  $ info coreutils
  ```
- Bash 관련 도움말은 아래와 같이 얻을 수 있다.
   ```sh
   $ man bash
   $ info bash
   ```
- 아래와 같이 실행하면 사용하는 쉘의 간단한 도움말이 출력된다.
   ```sh
   $ help
   ```
   특정 bash function의 도움말은 아래와 같이 얻을 수 있다.
   ```sh
   $ help <bash_function>
   ```

## Sell script 정적 검사 툴
- [ShellCheck](https://github.com/koalaman/shellcheck)  
  다음과 같이 설치할 수 있다.
  ```sh
  $ sudo apt install shellcheck
  ```
  이후 아래와 같이 검사할 수 있다.
  ```sh
  $ shellcheck <shell_script_파일이름>
  ```
  또는 설치할 필요없이 [ShellCheck 온라인](https://www.shellcheck.net/) 페이지를 이용할 수도 있다.

## Shell script 포매팅
- 아래와 같이 shfmt 툴을 설치한다.
  ```sh
  $ sudo apt install shfmt
  ```
  또는 아래와 같이 설치할 수도 있다.
  ```sh
  $ curl -sS https://webinstall.dev/shfmt | bash
  ```
  shfmt 툴을 이용하여 아래 예와 같이 포매팅할 수 있다.
  ```sh
  $ shfmt -w -sr -fn <shell_script_파일이름>
  ```
- VS Code 용 [shell-format](https://marketplace.visualstudio.com/items?itemName=foxundermoon.shell-format) 익스텐션을 이용하면 편리하다.
- 스타일 가이드 참조: [Shell Style Guide (by Google)](https://google.github.io/styleguide/shellguide.html)

## Shebang
Bash 스크립트 파일에서 첫 줄은 아래와 같은 shebang(`#!`)으로 시작하는 것이 좋다.
```sh
#!/bin/sh
```
즉, 인터프리터를 shell로 지정하는 것인데, 이렇게 하면 에디터에서 shell script로 인식하여 syntax 하이라이팅이 잘 되고, 파일에 실행 권한을 주면 파일 이름만으로 실행시킬 수 있게 된다.

## Argument 처리
- 아규먼트 개수는 `$#`로 얻을 수 있다.
- 각 아규먼트는 `$0`, `$1`, `$2` 등으로 얻을 수 있다.
- 모든 아규먼트는 `$@`로 얻을 수 있다.
- 예제
  ```sh
  if [ $# != 2 ]; then
      echo "Usage: $0 arg1 arg2"
      exit 1
  fi
  ```

## Bash $ 처리
- Shell 스크립트에서는 `$`가 특수 용도로 사용되는데, `$` 문자 자체를 표현하기 위해서는 `$$`와 같이 사용하면 된다.
- 만약 `$$` 문자열을 표현하려면 `\$\$`와 같이 쓰면 된다.

## Shell 세팅
현재 자신이 사용하고 있는 shell은 아래와 같이 확인할 수 있다. (**/etc/passwd** 파일에 있는 정보임)
```sh
$ echo $SHELL
```
Shell 변경은 아래와 같이 change shell 명령어로 할 수 있다.
```sh
$ chsh -s <shell 경로>
```

## Shell prompt 변경
Shell prompt는 PS1 환경 변수에 세팅하면 된다.  
예를 들어 아래 내용을 `~/.bashrc` 파일에 추가하면 적용된다. (`\u`는 user ID, `\h`는 host name, `\w`는 working directory를 나타냄)
```sh
export PS1="\[\033[01;32m\]\u\[\033[00m\]:\[\033[01;94m\]\W\[\033[00m\]\$ "
```

## 단축 명령(alias) 지정하기
- 아래와 같이 별명을 지정할 수 있다.
  ```sh
  $ alias 별명이름='내용'
  ```
  이후 아래와 같이 별명이름으로 실행시킬 수 있다.
  ```sh
  $ 별명이름
  ```
- 별명이름의 실제 내용 확인은 아래와 같이 할 수 있다.
  ```sh
  $ alias 별명이름
  ```

## Shell 명령의 결과가 표시되지 않게 하기
- 표준 입력/출력/에러의 파일 디스크립터 값
  - `0`: 표준 입력 (stdin)
  - `1`: 표준 출력 (stdout)
  - `2`: 표준 에러 (stderr)
- 표준 출력을 표시하지 않는 예제
  ```sh
  $ cat test > /dev/null
  $ cat test 1> /dev/null
  ```
- 표준 에러를 표시하지 않는 예
  ```sh
  $ cat test 2> /dev/null
  ```
- 표준 출력과 표준 에러를 모두 표시하지 않는 예제  
  (표준 출력을 null로 리다이렉션하고, 표준 에러(2)도 표준 출력(1)으로 리다이렉션 시킴)
  ```sh
  $ cat test 1> /dev/null 2>&1
  $ cat test > /dev/null 2>&1
  ```

## 커맨드 history에서 찾기
- 아래 예와 같이 history 명령을 이용해서 찾을 수 있다.
  ```sh
  $ history | grep "xxx"
  ```
- 입력 명령을 사용한 마지막 명령을 재실행하기 (예를 들어 **!vi** 라고 명령하면 마지막으로 **vi**를 실행한 명령을 재실행)
  ```sh
  $ !{명령}
  ```
- Reverse search 이용하기: Shell에서 <kbd>Ctrl</kbd>+<kbd>R</kbd>을 누른 후, 찾으려는 문자열을 입력한다.  
  다른 후보를 찾으려면 다시 <kbd>Ctrl</kbd>+<kbd>R</kbd>을 누르면 되고, 원하는 것이 찾아졌으면 <kbd>Enter</kbd> 키를 누르면 선택된다.

## 직전 경로로 돌아가기
- 아래와 같이 cd 명령을 실행하면 된다.
  ```sh
  $ cd -
  ```
- 또는 아래와 같이 pushd, popd를 이용할 수도 있다.
  ```sh
  $ pushd .
  $ cd {신규_경로}
  $ popd
  ```

## 특정 문자열 포함 여부 검사
- 특정 **변수**가 특정 **문자열**을 포함하고 있는지는 아래 예와 같이 할 수 있다.
  ```sh
  if [[ "$변수" == *"문자열"* ]]; then
      echo "Found"
  fi
  ```
- 또는 아래 예와 같이 할 수도 있다.
  ```sh
  if [[ "$변수" =~ "문자열" ]]; then
      echo "Found"
  fi
  ```

## 터미널에서 ANSI color 출력
터미널에서 ANSI color 출력은 ESC key를 이용하면 된다.  
ESC key는 `\e`, `\x1b` (또는 `\x1B`), `\033` 중의 하나를 사용하면 된다. (**ESC**는 16진수로 0x1B, 8진수로 033 임)
예를 들어 주요 색깔은 아래와 같다.
- 빨간색: **\e[31m**
- 초록색: **\e[32m**
- 노란색: **\e[33m**
- 파란색: **\e[34m**
- 자홍색: **\e[35m**
- 청록색: **\e[36m**
- 속성 off: **\e[0m**

예를 들어, 아래와 같이 출력할 수 있다.
```sh
$ echo -e "\e[31mHello \e[33mthe world! \e[0m"
```

## 직전에 실행한 명령어의 리턴값 출력
직전에 실행한 명령어의 리턴값은 아래와 같이 `$?`로 확인할 수 있다.
```sh
$ echo $?
```
Bash 스크립트에서 아래 예와 같이 이용할 수 있다.
```sh
if [ $? == 0 ]; then
    echo "Success"
fi

if [ $? != 0 ]; then
    echo "Failed"
fi

if [ $? -ne 0 ]; then
    echo "Failed"
fi
```

## 직전 명령어 결과로 실행 조건 걸기
- 아래 예와 같이 `command1 && command2` 하는 경우에는 **command1**이 성공하면 **command2**를 실행한다.
  ```sh
  $ make && echo "Success"
  ```
- 아래 예와 같이 `command1 || command2` 하는 경우에는 **command1**이 실패하면 **command2**를 실행한다.
  ```sh
  $ make || echo "Failed"
  ```
- 아래 예와 같이 `command1 && command2 || command3` 하는 경우에는, **command1**이 성공하면 **command2**를 실행하고, 실패하면 **command3**를 실행한다.
  ```sh
  $ make && echo "Success" || echo "Failed"
  ```

## 문자열 비교하기
- 문자열이 비어 있는지 (0 바이트인지) 검사하는 예
  ```sh
  if [ -z $1 ]; then
      echo "Empty"
  else
      echo "Non empty"
  fi
  ```
- 문자열이 비어 있지 않은지 검사하는 예 (`-n`은 non-empty의 약자)
  ```sh
  if [ -n $1 ]; then
      echo "Non empty"
  else
      echo "Empty"
  fi
  ```
- 문자열이 같은지 검사하는 예 (변수를 사용하는 경우에는 비어있을 수도 있으므로, "변수명"과 같이 사용하는 것이 좋음)
  ```sh
  if [ "$1" = "문자열" ]; then
      echo "Same"
  else
      echo "Different"
  fi

  if [ "$1" != "문자열" ]; then
      echo "Different"
  else
      echo "Same"
  fi
  ```

## 실행 결과를 환경 변수에 저장하기
- 아래 형태로 하면 된다.
  ```sh
  변수명=`명령어`
  변수명=$(명령어)
  ```
- 실행 결과가 (아래 예에서는 **df** 명령의 실행 결과) 여러 줄인 경우에는 echo 시 따옴표(**"**)가 없으면 1 줄에 모두 표시되고, 아래와 같이 따옴표(**"**)를 붙이면 여러 줄로 제대로 표시된다.
  ```sh
  RESULT=`df`
  echo "$RESULT"
  ```
- 환경 변수를 자식 프로세스에게도 전달하고 싶으면 아래와 같이 export 시키면 된다.
  ```sh
  export {환경 변수명}
  ```

## 현재 절대 경로 얻기
현재 경로의 절대 경로는 아래 방법 등으로 얻을 수 있다.
```sh
`pwd`
$(pwd)
`readlink -e .`
```

## 입력 파일의 경로 얻기
- dirname 명령: 입력 {경로/파일명}에서 파일 이름을 제외한 경로를 리턴한다.
  ```sh
  $ dirname {경로/파일명}
  ```
- basename 명령: 입력 {경로/파일명}에서 파일명을 리턴한다.
  ```sh
  $ basename {경로/파일명}
  ```
  참고로 아래와 같이 "-s .확장자" 아규먼트를 추가하면 해당 확장자를 제거한 파일명을 리턴한다.
  ```sh
  $ basename -s .확장자 {경로/파일명}
  ```
- readlink 명령: 입력 {경로/파일명}의 절대 경로를 얻는다.
  ```sh
  $ readlink -e {경로/파일명}
  ```
- realpath 명령: 입력 {경로/파일명}의 절대 경로를 얻는다.
  ```sh
  $ realpath {경로/파일명}
  ```
  또, 아래 예와 같이 현재 경로에 대한 입력 {경로/파일명}의 상대 경로를 얻을 수 있다.
  ```sh
  $ realpath --relative-to=. {경로/파일명}
  ```
- 현재 실행되는 스크립트의 절대 경로는 아래와 같이 얻을 수 있다.
  ```sh
  abspath=$(cd ${0%/*} && echo $PWD/${0##*/})
  ```
  또는
  ```sh
  abspath=$(cd ${0%/*} && echo $PWD)
  ```

## PATH 추가시 중복 방지하기
- PATH를 추가하는 스크립트를 아래 예와 같이 작성하여 실행시키면 중복된 것은 다시 추가되지 않는다.
  ```sh
  function addToPath {
      case ":$PATH:" in
      *":$1:"*) :;; # already there
      *) PATH="$1:$PATH";; # or PATH="$PATH:$1"
      esac
  }
  addToPath {추가할_경로}
  ```
- 또는 아래 예와 같이 할 수도 있다.
  ```sh
  if [[ ! "$PATH" == *{추가할_경로}* ]]; then
      export PATH=$PATH:{추가할_경로}
  fi
  ```
- 참고로 아래와 같이 실행하면 현재 PATH에서 중복된 PATH가 제거된다.
  ```sh
  $ PATH=$(printf "%s" "$PATH" | awk -v RS=':' '!a[$1]++ { if (NR > 1) printf RS; printf $1 }')
  ```

## 파일/경로 존재 여부 검사
- 입력 normal 파일이 존재하는지 검사
  ```sh
  $ test -e {파일명}
  ```
  입력 character device node가 존재하는지 검사
  ```sh
  $ test -c {디바이스_노드명}
  ```
  입력 경로가 존재하는지 검사
  ```sh
  $ test -d {경로명}
  ```
  결과는 아래와 같이 명령의 실행 결과를 보면 된다. (존재하면 **0**, 존재하지 않으면 **1**이 출력됨)
  ```sh
  $ echo $?
  ```
- 아래 예와 같이 응용할 수 있다.
  ```sh
  if [ ! -d ${TARGET_DIR} ]; then
      mkdir ${TARGET_DIR}
  fi

  if [ ! -e ${TARGET_FILE} ]; then
      touch ${TARGET_FILE}
  fi

  [ ! -d "$TARGET_DIR" ] && mkdir "$TARGET_DIR"
  ```

## 표준 입력으로 읽기
- 표준 입력으로 읽으려는 경우에는 아래 예와 같이 읽을 수 있다.
  ```sh
  $ read {변수명}
  ```
- 메시지를 출력하고 사용자 입력을 받으려면 아래 예와 같이 `-p` 아규먼트를 추가하면 된다.
  ```sh
  $ read -p "Enter the number: " {변수명}
  ```
- 입력시 타임아웃을 주고 싶으면 아래 예와 같이 `-t` 아규먼트를 추가하면 된다. (아래 예는 3초 타임아웃)
  ```sh
  $ read -p "Enter the number in 3sec: " -t 3 {변수명}
  ```
- Bash 스크립트에서 여러 줄을 읽으려는 경우에는 아래 예와 같이 읽을 수 있다.
  ```sh
  while read var
      do echo "$var"
  done
  ```
  
## Bash 표준 입력 내용으로 실행하기
- 예제 1
  ```sh
  $ bash <(curl -s http://test.sh)
  ```
- 예제 2
  ```sh
  $ curl -s http://test.sh | bash -s
  ```

## 파일을 줄 단위로 읽어 처리하기
- Redirection을 이용하는 예
  ```sh
  while read [라인변수명]; do
      [반복작업할 내용 작성]
  done < [파일명]
  ```
- Pipeline을 이용하는 예
  ```sh
  cat [파일명] | while read [라인변수명]; do
      [반복작업할 내용 작성]
  done
  ```
  파일이 2개의 칼럼(space로 분리)을 가지는 경우의 예
  ```sh
  cat $file_name | while read dir_name file_name; do
      echo "base_dir: $dir_name, file_name: $file_name"
  done
  ```

## 명령 실행시 사용자 입력을 자동으로 넣기
- 아래 예와 같이 할 수 있다.
  ```sh
  $ (echo "6"; echo "69") | sudo apt install -y tcl
  ```
- 또는 아래 예와 같이 할 수 있다. (아래에서 **EOF**는 다른 문자열로도 대체 가능)
  ```sh
  $ sudo apt install -y tcl <<EOF
  6
  69
  EOF
  ```
- 또는 **expect** 툴을 설치한 후, 아래 예와 같이 이용할 수 있다.
  ```sh
  PW="Password"
  expect -c "
  set timeout 5
  spawn env LANG=C /usr/bin/ssh ServerName
  expect \"password:\"
  send \"${PW}\n\"
  expect \"$\"
  exit 0
  "
  ```

## 변수 이름으로 변수 값 얻기
아래 예와 같이 `eval`과 `'$'{변수명}`을 사용하면 된다. (아래 예의 결과로 **SUCCESS**가 출력됨)
```sh
FOO="BAR"
BAR="SUCCESS"
eval echo '$'$FOO
```

## for 문을 이용한 반복 처리 예제
아래 예는 dd를 이용해서 입력 파일에서 여러 부분을 추출하는 예이다.
```sh
INPUT_FILE=input.bin
OFFSET0=$(expr $[0x000000] / $[0x10000]) SIZE0=$(expr $[0x080000] / $[0x10000]) OUT_FILE0=boot.bin
OFFSET1=$(expr $[0x100000] / $[0x10000]) SIZE1=$(expr $[0x120000] / $[0x10000]) OUT_FILE1=downloader.bin
OFFSET2=$(expr $[0x220000] / $[0x10000]) SIZE2=$(expr $[0x280000] / $[0x10000]) OUT_FILE2=app.bin
OFFSET3=$(expr $[0x4A0000] / $[0x10000]) SIZE3=$(expr $[0x080000] / $[0x10000]) OUT_FILE3=see.bin
OFFSET4=$(expr $[0x220000] / $[0x10000]) SIZE4=$(expr $[0x300000] / $[0x10000]) OUT_FILE4=back.bin
if [ -f ${INPUT_FILE} ]; then
    for ((i = 0; i < 5; ++i)); do
        eval OUT_FILE=\$OUT_FILE${i}
        eval OFFSET=\$OFFSET${i}
        eval SIZE=\$SIZE${i}
        dd if=${INPUT_FILE} of=${OUT_FILE} bs=64k skip=${OFFSET} count=${SIZE} 2> /dev/null
    done
fi
```

## 대소문자 변환하기
- Bash 4 버전 이상부터는 문자열 오른쪽에 `^^` 키워드를 붙이면 문자열이 모두 대문자로 변환되고, 문자열의 오른쪽에 `,,` 키워드를 붙이면 모두 소문자로 변환된다. (아래 예 참조)
  ```sh
  str="ApPlE"
  uppercase=${str^^}
  lowercase=${str,,}
  echo "Uppercase: ${uppercase}"
  echo "Lowercase: ${lowercase}"
  ```
- 또는 아래 예와 같이 `tr` 명령을 이용할 수도 있다.
  ```sh
  text="Hello, World!"
  echo ${text} | tr [:upper:] [:lower:]
  echo ${text} | tr [A-Z] [a-z]
  ```

## 산술 연산하기
- 간단한 연산은 아래 예와 같이 할 수 있다.
  ```sh
  echo $((2 + 3))
  echo $((2 * 3))
  ```
- 또는 `expr` 명령을 이용하여 아래 예와 같이 할 수 있다. (띄워쓰기 필요함)
  ```sh
  TEST=`expr 24 - 9`
  echo $TEST
  DAY_in_SECONDS=`expr 24 \* 3600`
  echo $DAY_in_SECONDS
  ```
- 또는 `bc` 명령을 이용하여 아래 예와 같이 할 수 있다.
  ```sh
  echo "24 - 9" | bc
  echo "24 * 3600" | bc
  ```
  10진수를 16진수로 출력은 아래와 같이 할 수 있다.
  ```sh
  echo "obase=16; <10진수 숫자>" | bc
  ```
- 참고로 expr, bc 명령은 아래 예와 같이 사칙연산, 크기 비교, 문자열 길이 등도 지원한다.
  ```sh
  echo "2.20 > 2.21" | bc
  echo "2.22 > 2.21" | bc
  ```
