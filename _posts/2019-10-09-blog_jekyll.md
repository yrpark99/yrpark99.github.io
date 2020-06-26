---
title: "GitHub 블로그 생성"
category: jekyll
toc: true
toc_label: "이 페이지 목차"
---

GitHub 블로그를 만든 방법을 기술한다.

## GitHub 저장소 생성
GitHub page에 로그인 한 후, `USERNAME.github.io` 와 같은 이름으로 생성하면 된다고 하여, yrpark99.github.io 이름으로 저장소를 생성하였다. 별도의 파일은 추가하지 않아서 empty 상태로 생성되었다.

## 테마 구성
GitHub IO는 Jekyll 테마를 사용할 수 있다고 하여, 이 중에서 가장 별을 많이 받아서 첫 번째로 나오는 Minimal Mistakes라는 테마를 사용해 보기로 하였다.
아래와 같이 Minimal Mistakes 소스를 clone 했다.  
```sh
$ git clone https://github.com/mmistakes/minimal-mistakes.git
```

이후 아래와 같이 Minimal Mistakes 개발용으로만 사용되므로 필요없는 디렉토리와 파일들을 삭제하였다.  
```sh
$ cd minimal-mistakes/
$ rm -rf .editorconfig .git/ .gitattributes .github/ docs/ test/ CHANGELOG.md README.md screenshot-layouts.png screenshot.png
```

이후 아래와 같이 위에서 생성한 내 GitHub 저장소에 올렸다.  
```sh
$ git init
$ git add .
$ git commit -m "Initial commit"
$ git remote add origin https://github.com/yrpark99/yrpark99.github.io.git
$ git push -u origin master
```

이후 https://yrpark99.github.io 주소로 접속해 보니깐 기본 블로그 화면이 보였다. 이로써 기본 블로그 구성이 끝났다.

## 화면 구성 설정하기
화면 구성은 대부분 _config.yml 파일에서 적절히 수정하면 된다.

## 렌더링 변경하기
글자의 폰트나 크기, 색깔, margin 등을 변경하려면 해당 **scss** 파일을 찾아서 수정하면 된다.

## 포스팅 하기
포스팅은 **_posts** 디렉토리에 YYYY-MM-DD-title.md 파일 이름 형식으로 UTF-8 인코딩으로 아래 예와 같이 작성하면 된다고 한다.
```markdown
---
title: "포스팅 제목"
---
이후 본문 내용은 markdown 형식으로 작성하면 된다.
```

마크다운 파일을 작성하여 GitHub에 올리면 GitHub IO 페이지에 반영된다.
이 글은 이에 따라 작성한 첫 번째 포스팅 글이다.