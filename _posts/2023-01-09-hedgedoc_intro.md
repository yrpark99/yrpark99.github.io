---
title: "마크다운으로 협업하는 HedgeDoc 소개"
category: 노트
toc: true
toc_label: "이 페이지 목차"
---

마크다운 문서를 협업하여 작성할 수 있는 HedgeDoc을 소개한다.

## 배경
사내에서 자주 팀원들이 간단한 내용을 공통으로 작성하는 문서가 있는데, 구글 docs나 MS Office를 이용하기는 어려웠고, 사내 협업 툴은 문서 협업을 지원하지 않아서 사용에 무리가 많았다.
> ✅ 사실 Slack, Notion, 두레이 등의 협업 툴들은 마크다운으로 협업을 지원하므로, 이런 협업 툴을 사용하는 경우에는 고민없이 해당 툴을 이용하면 된다.

그동안은 대안으로 `Google Keep`을 사용하고 있었는데, 이것은 각자의 구글 계정이 필요하였고, 또 포매팅을 맞추기가 불편한 점이 있었다.  
🧐 그래서 이번에 더 나은 대안으로 마크다운을 이용하는 방법을 찾아보다가, [HedgeDoc](https://hedgedoc.org/)이라는 괜찮은 오픈 소스 툴을 찾아서, 적용해 본 후 포스팅한다.

## HedgeDoc 소개
[HedgeDoc](https://hedgedoc.org/) 툴은 여러 사람이 동일 문서(마크다운)를 동시에 편집할 수 있는 솔루션으로, 
대표적인 특징은 다음과 같다.
* 오픈 소스([소스 저장소](https://github.com/hedgedoc/hedgedoc))
* 마크다운 동시 편집 지원, preview 지원, syntax highlight 지원
* Web-based, self-hosting 지원, 로그인 지원
* 자동 완성 지원
* MathJax, UML 등 지원

## 설치
다음은 self-hosting 하기 위한 방법이다. (라즈베리파이 보드에서도 돌아갈 정도로 적은 리소스를 사용하므로, 나는 기존 서버에서 Docker로 운용하였음)  
아래와 같이 `docker-compose.yml` 파일을 작성한다. (아래 예에서 **{your_host_url}** 부분에 self hosting 하는 서버의 URL 주소를 입력하면 됨)
```yml
version: '3'
services:
  database:
    image: postgres:13.4-alpine
    environment:
      - POSTGRES_USER=hedgedoc
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=hedgedoc
    volumes:
      - database:/var/lib/postgresql/data
    restart: always
  app:
    image: quay.io/hedgedoc/hedgedoc:1.9.6
    environment:
      - CMD_DB_URL=postgres://hedgedoc:password@database:5432/hedgedoc
      - CMD_DOMAIN={your_host_url}
      - CMD_URL_ADDPORT=true
    volumes:
      - uploads:/hedgedoc/public/uploads
    ports:
      - "3000:3000"
    restart: always
    depends_on:
      - database
volumes:
  database:
  uploads:
```

이후 아래와 같이 실행시시키면 된다.
```sh
$ docker-compose up
```

## 접속
접속 주소는 [http://your_host_url:3000/](http://your_host_url:3000/) 이다.  
<br>
로그인 계정을 만들려면 `로그인` 버튼을 눌러서 E-Mail 주소와 Password를 입력한 후에 `회원 가입` 버튼을 누르면 된다. 이후부터는 등록한 E-Mail 주소와 암호로 로그인이 된다.  
로그인을 하면 `소개` 탭과 `기록` 탭이 있는데, `기록` 탭을 클릭하면 본인이 작성한 문서가 보인다. 또, 다른 사람이 공유한 링크를 접속하면 이후부터는 해당 문서도 `기록` 탭에 추가로 보인다.

## 문서 작성
HedgeDoc에서 `+신규`를 눌러서 마크다운으로 문서를 생성하면 디폴트로 **<font color=blue>EDITABLE</font>** 상태가 된다. (물론 변경 가능함)  
태그를 달고 싶으면 문서 제일 윗 부분에 아래 예와 같이 `tags`로 태그를 명시하면, 이후 `기록` 탭에서 표시되는 태그를 선택해서 해당 문서들을 검색할 수 있다.
```yml
---
tags: 태그명
---
```

이후에 아래와 같이 입력하면 문서의 제목으로 표시된다.
```markdown
이것이 문서 제목
===
```
또는 아래 예와 같이 해도 문서의 제목으로 인식된다.
```markdown
# 이것이 문서 제목
```
<br>

이후의 문서 작성은 마크다운에 의거해서 작성하면 되고, 마크다운용 툴바도 표시되므로 마크다운 초보자라도 작성에 별 어려움은 없을 것이다.
<br>

마크다운 에디터에서는 **Sublime**, **Emacs**, **Vim** 3가지 에디터 모드를 지원하고 디폴트는 Sublime이다. 에디터 창의 맨 아래 상태바에서 tab과 space를 선택할 수 있고, 크기도 선택할 수 있다. (보통은 space 2를 선택하는 것이 편할 것임)  
참고로 Sublime 에디터 모드에서는 아래 예와 같은 Sublime Text 기능을 지원하므로 편리하게 이용할 수 있다.
- 멀티 커서 선택: <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>Up</kbd>/<kbd>Down</kbd>
- 현재 선택된 단어 멀티 선택 추가: <kbd>Ctrl</kbd> + <kbd>D</kbd>
- 문자열 찾기: <kbd>Ctrl</kbd> + <kbd>F</kbd>
- 문자열 변경하기: <kbd>Ctrl</kbd> + <kbd>H</kbd>
- 현재 줄 복사하기: <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>D</kbd> (또는 <kbd>Ctrl</kbd> + <kbd>C</kbd>, <kbd>Ctrl</kbd> + <kbd>V</kbd>)
- 현재 줄 삭제하기: <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>K</kbd> (또는 <kbd>Shift</kbd> + <kbd>Del</kbd>)
- 줄 이동: <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>Up</kbd>/<kbd>Down</kbd>
- 다음 줄에 한 줄 삽입하고 이동: <kbd>Ctrl</kbd> + <kbd>Enter</kbd>
- Sort/Unsort 리스트를 indent, outdent: <kbd>Tab</kbd>, <kbd>Shift</kbd> + <kbd>Tab</kbd>

## 문서 공동 작업
해당 문서를 원하는 사람들에게 공유하려면 해당 문서의 URL을 전달하면 된다. 문서에서 **공개하기** 버튼을 누르면 read only URL이 표시되는데 이 주소를 전달해도 되고, 수정/미리보기 URL 주소를 전달해도 된다.  
작성한 문서의 링크를 다른 사람에게 공유하면, 로그인하지 않은 사용자는 보기만 가능하고, 로그인한 사람은 수정까지 가능해 진다.  
<br>

해당 문서에 여러 사람이 참여한 경우에는 우측 상단에 **<font color=337ab7>ONLINE</font>** 숫자로 표시되고, 여기를 클릭하면 참여한 사람들이 보인다. 또 **메뉴** 항목을 눌러서 **기록**을 누르면 기존 수정 이력도 확인할 수 있다(단, 수정한 사람의 정보는 표시되지 않는 것이 조금 아쉬움).

## 문서 삭제
해당 문서에서 **<font color=blue>EDITABLE</font>** 버튼을 누른 후, "**Delete this note**"를 실행하면 해당 문서가 삭제된다.

## 맺음말
마크다운의 다양한 활용 용도 중의 한 가지로, 마크다운 문서 협업을 지원하는 **HedgeDoc**에 대한 소개와 사용법을 간단히 정리해 보았다. 마크다운을 이용한 무료 문서 협업 솔루션을 찾고 있다면 괜찮은 툴 중의 하나인 것 같다.  
실제로 테스트를 해 보니, 구글 계정 없이도 자체 호스팅 서버로 여러 사람이 동시에 편집할 수 있었고 (Google Keep보다 더 자연스러웠음), 마크다운을 사용하여 포매팅이 간단하게 저절로 되어서 좋았다.  
또 덤으로 이모지, 체크 박스, 소스 코드, 그림, 수식, UML 등도 넣을 수 있고, `기록`에 기존 히스토리가 남아서 의도치 않게 내용이 지워져도 쉽게 복구할 수 있다.
