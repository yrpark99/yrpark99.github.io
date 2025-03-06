---
title: "Docker image로부터 Dockerfile 추출하기"
category: [Docker]
toc: true
toc_label: "이 페이지 목차"
---

Docker 이미지로부터 Dockerfile 파일을 추출하는 방법이다.  
<br>

Docker 이미지는 있는데 이미지를 빌드할 때 사용된 **Dockerfile** 파일은 없는 경우에, **Dockerfile** 파일을 얻어내야 할 필요가 생겼다. (Dockerfile 파일을 수정해서 새로운 이미지를 만들기 위함)  
그래서 역으로 Docker 이미지로부터 **Dockerfile** 파일을 추출하는 방법을 찾아보았고, 다음과 같이 2가지 방법을 찾았다.

## docker history 명령 이용
아래와 같이 **docker history** 명령을 실행하면 이미지를 빌드한 history 내용이 출력된다.
```sh
$ docker history --no-trunc {Docker 이미지 이름}
```

출력된 내용을 분석해서 **Dockerfile** 파일로 만들면 된다.
> 그런데 이 방법으로 **Dockerfile** 파일을 만들기에는 쉽지 않다.

## 별도의 툴 이용
위의 docker history를 이용하는 방법보다 좀 더 편리한 방법으로, 별도의 [dfimage](https://github.com/LanikSJ/dfimage) 툴을 이용할 수 있다.  
먼저 편의상 **~/.bashrc** 파일에 아래와 같이 alias를 추가한다.
```sh
alias dfimage="docker run -v /var/run/docker.sock:/var/run/docker.sock --rm ghcr.io/laniksj/dfimage"
```
> 즉, **dfimage** 명령을 실행하게 되면 `ghcr.io/laniksj/dfimage` Docker 이미지를 실행시킨다. (만약에 아직 해당 Docker 이미지가 다운되지 않은 상태에서 실행시킨 경우에는 자동으로 이미지가 다운로드 된 후에 실행됨)

이제부터 이 alias를 이용하여 아래와 같이 실행시키면 된다.
```sh
$ dfimage {Docker 이미지 이름}
```

결과로 출력된 내용은 거의 **Dockerfile** 파일로 사용될 수 있을 정도이다. 🤩
