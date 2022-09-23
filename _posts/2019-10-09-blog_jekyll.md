---
title: "GitHub 블로그 생성"
category: Markdown
toc: true
toc_label: "이 페이지 목차"
---

GitHub 블로그를 만든 방법을 기술한다.

## GitHub 저장소 생성
GitHub page에 로그인 한 후, `USERNAME.github.io` 와 같은 이름으로 생성하면 된다고 하여, yrpark99.github.io 이름으로 저장소를 생성하였다. 별도의 파일은 추가하지 않아서 empty 상태로 생성되었다.

## 테마 구성
GitHub IO는 Jekyll 테마를 사용할 수 있다고 하여, 이 중에서 가장 별을 많이 받아서 첫 번째로 나오는 <span style="color:blue">Minimal Mistakes</span>라는 테마를 사용해 보기로 하였다.  
일단 아래와 같이 Minimal Mistakes 소스를 clone 했다.  
```sh
$ git clone https://github.com/mmistakes/minimal-mistakes.git
```

이후 아래와 같이 Minimal Mistakes 개발용으로만 사용되므로 필요없는 디렉터리와 파일들을 삭제하였다.  
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

이후 [내 블로그 웹페이지](https://yrpark99.github.io) 주소로 접속해 보니깐 기본 블로그 화면이 보였다. 이로써 기본 블로그 구성이 끝났다.

## 화면 구성 설정하기
화면 구성은 대부분 `_config.yml` 파일에서 적절히 수정하면 된다.

## 렌더링 변경하기
글자의 폰트나 크기, 색깔, margin 등을 변경하려면 해당 **scss** 파일을 찾아서 수정하면 된다.

## 포스팅 하기
포스팅은 **_posts** 디렉터리에 **YYYY-MM-DD-title.md** 파일 이름 형식으로 UTF-8 인코딩으로 아래 예와 같이 작성하면 된다고 한다.
```markdown
---
title: "포스팅 제목"
---
이후 본문 내용은 markdown 형식으로 작성하면 된다.
```

마크다운 파일을 작성하여 GitHub에 올리면 GitHub IO 페이지에 반영된다.
이 글은 이에 따라 작성한 첫 번째 포스팅 글이다.

## 새로운 Linux에서 구성하기
1. 아래와 같이 내 블로그 저장소를 clone 한 후, 해당 디렉토리로 이동한다.
   ```sh
   $ git clone https://github.com/yrpark99/yrpark99.github.io.git
   $ cd yrpark99.github.io/
   ```
   이후 Git commit 및 저장소에 push를 위해서 아래와 같이 Email과 이름을 세팅한다.
   ```sh
   $ git config user.email "yrpark99@gmail.com"
   $ git config user.name "Youngrok Park"
   ```
1. 아래와 같이 필요한 빌드에 필요한 패키지를 설치한다.
   ```sh
   $ sudo apt install make gcc g++
   $ sudo apt install ruby ruby-dev ruby-bundler
   ```
   이제 아래와 같이 실행하면 Ruby bundler를 통해서 gem 패키지들이 설치된다.
   ```sh
   $ sudo bundle install
   ```
1. 아래와 같이 서비스를 실행시킨다.
   ```sh
   $ bundle exec jekyll serve
   ```
	(나는 편의상 위의 내용으로 **start_local_server.sh** 파일을 만들어서 GitHub에 올려두고 이것을 사용함)  
  결과로 **_posts** 디렉토리에 만든 **md** 파일들이 static html 파일로 빌드되고, 마지막 부분에 `Server address: http://127.0.0.1:4000//` 메시지가 출력된다.
1. 이제 브라우저에서 [http://127.0.0.1:4000](http://127.0.0.1:4000) 주소로 접속하면 로컬 환경에서 블로그 내용을 확인해 볼 수 있다.
1. 이후 **md** 파일이나 **scss** 파일 등이 추가되거나 수정되면 자동으로 html 빌드가 수행되어서, 바로 로컬 환경에서 확인할 수 있다.
1. 로컬 환경에서 웹브라우저로 확인을 마친 후에 변경 사항을 GitHub에 push하면, 자동으로 포스팅이 된다.

## Git 없는 환경에서 포스팅하기
참고로 Git이 없는 환경에서 기존 포스팅 내용을 간단히 수정하는 경우에는 [Prose](http://prose.io/)를 이용하면 편하다. Prose 사이트에 접속하여 GitHub ID로 로그인한 후, 본인의 github.io를 선택하면 online 상에서 바로 수정을 할 수 있다.
