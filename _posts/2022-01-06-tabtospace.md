---
title: "소스 코드의 tab을 space로 변환하기"
category: Environment
toc: true
toc_label: "이 페이지 목차"
---

소스 코드의 tab을 space로 일괄 변환하는 방법이다.

<br>
개발 중인 프로젝트의 소스는 tab과 space가 혼용되어서 사용되고 있어서, 이를 보기 좋게 space로 통일시켜 보았고, 추후 참조를 위하여 간단히 정리해 본다.

## tab to space 변환 방법들
1. Source code 에디터를 이용한 방법: 편리하긴 하지만, 보통 여러 개의 파일들을 일괄적으로 변환하는 기능은 없다.
1. `sed` 명령어를 이용한 방법 (아래 예에서 space는 4개)  
   아래 형식으로 입력 파일을 변환시킬 수 있다. (`-i` 옵션을 사용하여 원본 파일을 replace 하게 함)
   ```shell
   $ sed -i 's/\t/    /g' <file_name>
   ```
   현재 디렉토리 이하의 모든 c, cpp, h 파일들을 한꺼번에 변환하려면 아래 예와 같이 할 수 있다.
   ```shell
   $ find -name "*.c*" -exec sed -i 's/\t/    /g' {} \;
   $ find -name "*.h" -exec sed -i 's/\t/    /g' {} \;
   ```
   그런데 이 방법은 모든 tab을 기계적으로 space 4개로 변환시키므로, 이전 소스 코드에서 칼럼에 맞추어 tab을 사용했던 경우에는 칼럼이 맞지 않게 되는 문제가 발생한다. (따라서 이 방법보다는 아래 방법을 추천)
1. `expand`, `sponge` 명령을 이용한 방법 (아래 예에서 space는 4개)  
   아래 형식으로 입력 파일을 변환시킬 수 있다. (`sponge` 툴을 이용하여 원본 파일을 replace 하게 함)
   ```shell
   $ expand -t 4 <file_name> | sponge <file_name>
   ```
   현재 디렉토리 이하의 모든 c, cpp, h 파일들을 한꺼번에 변환하려면 아래 예와 같이 할 수 있다.
   ```shell
   $ find -name "*.c*" -exec bash -c 'expand -t 4 "$0" | sponge "$0"' {} \;
   $ find -name "*.h" -exec bash -c 'expand -t 4 "$0" | sponge "$0"' {} \;
   ```
   이 방법을 사용하면 위의 sed를 사용했을 때의 칼럼이 맞지 않는 문제가 해결되므로, 나는 이 방법을 사용하여 소스 코드들을 일괄 변환시켰다.
   > 만약 sponge 툴이 설치되어 있지 않은 상태이면, 아래와 같이 설치할 수 있다.
   ```shell
   $ sudo apt install moreutils
   ```
1. 기타: 그 외에 awk나 전용 툴을 이용하는 방법도 있다.

## EditorConfig 설정
일단 전체 소스를 변경하였으므로 이제 [EditorConfig](https://editorconfig.org/) 설정을 해주면, 대부분의 소스 코드 에디터에서 자동으로 space를 넣어준다. (EditorConfig는 대부분의 편집기를 지원하므로 필수 툴처럼 설치하는 것을 권장함)  
기존에는 tab을 사용하였으나 이제 space로 바꾸었으므로, 업데이트된 `.editorconfig` 파일의 내용은 아래와 같다.
```ini
root = true

[*]
indent_style = space
indent_size = 4
tab_width = 4
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true

[Makefile]
indent_style = tab

[*.md]
trim_trailing_whitespace = false

[*.json]
insert_final_newline = false
```

## VS Code 설정
또한 소스 코드 에디터는 주로 VS Code를 사용하므로, 프로젝트의 `.vscode/settings.json` 파일은 아래와 같이 업데이트하였다.
```jsx
{
    "files.encoding": "utf8",
    "files.autoGuessEncoding": true,
    "files.eol": "\n",
    "files.trimTrailingWhitespace": true,
    "editor.detectIndentation": false,
    "editor.tabSize": 4,
    "editor.insertSpaces": true,
    "editor.formatOnPaste": true,
    "[c]": {
        "files.trimTrailingWhitespace": true,
        "editor.insertSpaces": true,
    },
    "[cpp]": {
        "files.trimTrailingWhitespace": true,
        "editor.insertSpaces": true,
    },
    "[markdown]": {
        "files.trimTrailingWhitespace": false,
    },
    "[makefile]": {
        "files.trimTrailingWhitespace": true,
        "editor.insertSpaces": false,
    },
}
```

## 결론
간단히 모든 소스 코드들을 tab에서 space로 변환시켜서 indent를 통일하였고, Subversion이나 Git으로 관리되는 `.editorconfig` 파일과 `.vscode/settings.json` 파일도 업데이트하여, 에디터에서 작업시 자동으로 지정된 indent를 사용하도록 하여 앞으로도 indent가 통일되도록 하였고, 추가로 줄 끝의 white space도 자동으로 삭제되게 하였다. 😊
