---
title: "Docker container에서 포트 매핑 변경하기"
category: Docker
toc: false
toc_label: "이 페이지 목차"
---

현재 Docker 컨테이너에서 수동으로 포트 매핑을 변경하는 팁을 공유한다. (볼륨 변경도 마찬가지)

<br>
현재 운용 중인 Docker 컨테이너에서 포트 매핑을 변경할 일이 생겼다. 구체적으로는 GitLab 서버를 Docker 컨테이너로 운용하고 있었는데, 
Docker 이미지로부터 컨테이너를 생성할 때 http와 https를 모두 지원하기 위하여 Docker compose 파일에서 아래와 같이 세팅하여 생성하였었다.
```jsx
ports:
  - '80:80'
  - '443:443'
```

그런데 https 환경을 구성한 이후에는 현재 컨테이너를 그대로 유지한채, http 연결만을 제거하고 싶어졌다.  
구글링을 해 보니, 이 경우 공식으로 컨테이너의 포트 매핑을 변경할 수는 없고, 아래와 같이 일단 현재 컨테이너를 stop 시킨 후 이미지로 저장한다.
```bash
$ docker stop <container_name>
$ docker commit <container_name> <image_name>
```
이후, 다시 저장된 이미지로부터 컨테이너를 생성할 때 포트 변경을 적용하는 방법이었다.  
물론 이 방법을 그대로 사용할 수 있었지만, 나는 이 방법이 컨테이너가 사용하는 이미지 이름이 원래 이미지와 다른 이름으로 나올 것이므로 마음에 들지 않았다.

그래서 좀 더 구글링을 해 보니, 호스트의 아래 두 파일을 변경하면 된다는 것이었다.
* /var/lib/docker/containers/[컨테이너의 hash 값]/hostconfig.json
* /var/lib/docker/containers/[컨테이너의 hash 값]/config.v2.json

그런데 위 두 파일에서 포트 매핑 내용을 모두 변경해 보아도 컨테이너를 다시 restart 시키면 이 파일들이 다시 원래값으로 복구되면서 계속 실패하였다.😢

포기하려다가 계속 찾아보니 컨테이너 재시작 전에 Docker 서비스를 restart 시키면 된다는 글을 발견하였고, 혹시나 하고 시도해 보았더니 포트 변경이 적용되는 것이었다.😜  
따라서 전체 순서는 아래와 같이 하면 된다.
```bash
$ docker stop <container_name>
# /var/lib/docker/containers/[컨테이너의 hash 값]/hostconfig.json 수정
# /var/lib/docker/containers/[컨테이너의 hash 값]/config.v2.json 수정
$ sudo service docker restart
$ docker restart <container_name>
```

위 방법으로 기존 컨테이너에서 포트 변경만 깔끔하게 수정되었다. 물론 포트 매핑 뿐만 아니라 볼륨 매핑 등도 이 방법으로 변경할 수 있겠다. 간단하지만 별로 알려지지 않은 팁이라서 공유해 본다.
