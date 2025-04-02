---
title: "Jenkins에서 Docker 환경으로 빌드하기"
category: [Docker]
toc: true
toc_label: "이 페이지 목차"
---

Jenkins에서 SVN으로 소스를 가져와서 Docker 환경을 사용하여 프로젝트 소스를 빌드하는 방법이다.

구글링해도 관련 자료를 찾기가 힘들었는데, 직접 여러가지 시도를 하면서 찾은 방법을 기록한다.

## Docker 환경으로 빌드
당연한 얘기지만 Jenkins에서 Docker 환경으로 빌드하기 전에, 먼저 로컬 서버에서 Dokcer 환경으로 빌드할 수 있는 환경을 구성해야 한다.  
이 글에서는 이미 작성한 **Dockerfile** 파일을 이용하여 정상적으로 Docker 컨테이너에서 타겟 프로젝트의 빌드가 성공하였다고 가정한다.

## Jenkins 설치
아직 로컬 Linux 서버에 Jenkins를 설치하지 않았다면 [[Jenkins 설치]](https://www.jenkins.io/doc/book/installing/linux/) 페이지를 참고하여 설치한 후, 실행시킨다.  
Jenkins를 설치한 로컬 서버에서는 아래 **/etc/passwd** 파일에서 볼 수 있듯이 자동으로 **jenkins** 사용자가 생성되어 있는 상태이다. (홈 디렉토리는 **/var/lib/jenkins** 임을 확인할 수 있음)
```
jenkins:x:140:140:Jenkins,,,:/var/lib/jenkins:/bin/bash
```

Jenkins에서 타겟 프로젝트 빌드시에 `docker` 명령을 수행할 것으로, 아래와 같이 **jenkins** 사용자에게 `docker` 명령을 수행할 수 있도록 권한을 준다.
```sh
$ sudo usermod -aG docker jenkins
```

## svn+ssh 프로토콜 지원
Jenkins에서 빌드를 시키면 Jenkins 스크립트에서 명시한 대로 소스를 받아오므로, 보통의 경우 Docker 컨테이너에서 SVN 소스를 받을 필요는 없다.  
그런데 내 프로젝트의 경우에는 소스 빌드시에 SVN 서버로부터 소스를 받아오는 부분이 있었고, 특히 SVN의 `svn+ssh` 프로토콜을 사용하는 경우여서, 소스를 SVN 서버에서 받아올 때 SSH 암호가 자동으로 입력되어야 했다.  
이를 위해서는 다음 과정과 같이 SVN 서버에 **jenkins** 사용자를 추가한 후에, 로컬 서버에서 Jenkins 사용자의 SSH key를 생성하여 public key를 SVN 서버의 **jenkins** 사용자의 **~/.ssh/authorized_keys** 파일에 추가하는 작업이 필요하다.  
1. SVN 서버에서 **jenkins** 사용자를 추가한다.
1. Jenkins를 설치한 로컬 서버에서 아래와 같이 **jenkins** 사용자로 로그인한다.
   ```sh
   $ sudo su jenkins
   ```
1. 이후 아래와 같이 실행하여 **jenkins** 사용자의 SSH key를 생성한다.
   ```sh
   $ ssh-keygen -t rsa
   ```
   암호 저장 경로는 <kbd>Enter</kbd>를 쳐서 디폴트 경로를 사용하고, 암호 입력시에도 그냥 <kbd>Enter</kbd> 키를 쳐서 암호를 입력하지 않는다. 결과로 다음 파일들이 생성된다.
   * /var/lib/jenkins/.ssh/id_rsa
   * /var/lib/jenkins/.ssh/id_rsa.pub
1. 이후 아래와 같이 실행하면 생성된 SSH public key가 SVN 서버에서 **jenkins** 사용자의 ~/.ssh/authorized_keys 파일에 추가된다.
   ```sh
   $ ssh-copy-id {SVN_서버_주소}
   ```
   > 참고로 만약에 SVN 서버의 SSH 버전이 오래된 경우에는 이때 "**no matching host key type found. Their offer: ssh-rsa,ssh-dss**" 에러가 발생할 수 있는데, 대응 방법으로 로컬 서버에서 jenkins 사용자의 **~/.ssh/config** 파일을 아래와 같이 작성하면 된다.
   > ```scala
   > Host {SVN_서버_주소}
   >     HostkeyAlgorithms +ssh-rsa
   >     PubkeyAcceptedKeyTypes +ssh-rsa
   ```
1. 이제 아래와 같이 실행하면 암호 입력없이 SVN 서버의 **jenkins** 사용자로 SSH 로그인이 된다.
   ```sh
   $ ssh {SVN_서버_주소}
   ```
  SVN 서버로 정상 로그인을 확인하였으면 로그아웃 한다.

## Jenkins Docker 환경 구성
Jenkins에서 Docker를 이용하여 빌드하기 전에, 당연히 로컬 서버에서 먼저 Docker 이미지를 빌드하고, Docker 컨테이너를 사용하여 타겟 소스를 빌드할 수 있어야 한다. 앞서 언급하였듯이 이 글에서는 이미 **Dockerfile**을 이용하여 Docker 컨테이너에서 빌드하는 환경이 구성되었다고 가정하고, Jenkins에서도 Docker 컨테이너를 사용하여 빌드하는 방법을 설명한다.  
참고로 아래 예에서는 Docker 컨테이너에서 `svn+ssh` 프로토콜을 사용하기 위하여 관련 내용을 추가하였다.
1. 아래와 같이 실행하여 **jenkins** 사용자로 로그인한다.
   ```sh
   $ sudo su jenkins
   ```
1. **jenkins** 사용자로 로그인하였으면 **~/.ssh/** 디렉토리로 이동한다. 이전 과정을 진행했으면 여기에서 **id_rsa**, **id_rsa.pub** 등의 파일을 확인할 수 있다.
   ```sh
   $ cd ~/.ssh/
   $ ls
   config  id_rsa  id_rsa.pub
   ```
1. 기존에 사용하였던 **Dockerfile** 파일을 **jenkins** 사용자의 **~/.ssh/** 경로에 복사한 후에, 필요에 따라 수정한다.  
   아래 예에서는 아규먼트로 받은 정보로 사용자(**jenkins**)를 추가하였고, Docker 컨테이너 내에서 `svn+ssh` 사용을 위하여 SSH 관련 파일도 복사하였다. 또, root 권한 대신에 **jenkins** 사용자 권한으로 실행하도록 하였다.
   ```Dockerfile
   ARG user
   ARG uid
   ARG gid   
   RUN groupadd -g ${gid} ${user} && useradd -m -u ${uid} -g ${gid} ${user}

   RUN mkdir /home/jenkins/.ssh && chown jenkins:jenkins /home/jenkins/.ssh/
   COPY --chown=jenkins:jenkins ./config /home/jenkins/.ssh/
   COPY --chown=jenkins:jenkins ./id_rsa /home/jenkins/.ssh/
   COPY --chown=jenkins:jenkins ./id_rsa.pub /home/jenkins/.ssh/
   COPY --chown=jenkins:jenkins ./known_hosts /home/jenkins/.ssh/

   USER jenkins
   ```
1. 이제 **jenkins** 사용자 상태에서 ~/.ssh/ 경로에서 아래와 같이 실행하여 Docker 이미지를 빌드한다. (현재 사용자 uid/gid 등의 정보도 전달함, Docker 이미지 이름은 예로 **jenkins_docker_image**로 지정함)
   ```sh
   $ docker build --tag jenkins_docker_image --build-arg user="$USER" --build-arg uid="$(id -u)" --build-arg gid="$(id -g)" .
   ```
   성공하였으면 `docker images` 명령으로 Docker 이미지가 (이름은 **jenkins_docker_image**) 생성되었음을 확인할 수 있다.
1. 테스트로 아래와 같이 Docker 컨테이너를 생성해 본다. (컨테이너 이름은 예로 **jenkins_docker_container**로 지정함)
   ```sh
   $ docker create --name jenkins_docker_container -it --net=host jenkins_docker_image
   ```
   성공하였으면 `docker ps -a` 명령으로 Docker 컨테이너가 (이름은 **jenkins_docker_container**) 생성되었음을 확인할 수 있다.  
   테스트로 아래와 같이 Docker 컨테이너를 실행하고 attach 시키면 shell을 얻을 수 있다.
   ```sh
   $ docker start jenkins_docker_container && docker attach jenkins_docker_container
   ```
   이제 Docker 컨테이너에서 필요한 동작을 확인해 볼 수 있다. (아래 예는 SVN 서버에 접속 테스트, 암호 입력 없이 로그인이 되면 성공)
   ```sh
   $ id
   $ ssh {SVN_서버_주소}
   ```
   Docker 컨테이너가 정상적으로 동작했으면, Docker 컨테이너를 빠져나온다. (결과로 **jenkins** 사용자 쉘로 돌아옴)
1. 아래와 같이 테스트로 만들었던 Docker 컨테이너를 삭제한 후에, **jenkin** 사용자도 로그 아웃한다.
   ```sh
   $ docker rm jenkins_docker_container
   $ exit
   ```

이로써 **jenkins** 사용자를 위한 Docker를 이용한 빌드 환경이 구성되었다.  
이제 Jenkins의 해당 프로젝트에서 파이프라인 스크립트를 작성하여, 소스를 받고 Docker 컨테이너에서 빌드가 수행되도록 하면 된다.

## Jenkins 환경 설정
Jenkins에서 SVN을 사용하려면 먼저 [<u>Subversion</u>](https://plugins.jenkins.io/subversion/) plugin이 설치되어 있어야 한다.  
이후 Jenkins 관리에서 Credentials 항목으로 들어간 후, Global credentials에서 "Global credentials" 버튼을 눌러서 필요한 SVN 서버의 SSH 접속에 필요한 credentail을 추가한다.  
결과로 서버 접속을 위한 credentail ID를 얻을 수 있다. (이 값은 이후 pipeline 스크립트에서 `credentialsId` 항목에 사용됨)  
<br>

또, pipeline에서 Docker 환경을 사용하여 빌드하려면 [<u>Docker Pipeline</u>](https://plugins.jenkins.io/docker-workflow/) 플러그인을 설치해야 한다. 플러그인을 설치한 후에 Jenkins를 재시작 시킨다.

## Jenkins pipeline script
이제 Jenkins에서 타겟 프로젝트를 빌드할 신규 아이템을 생성한다. 여기서는 예로 pipeline 타입으로 생성하였고, 스크립트는 아래 예와 같이 작성할 수 있다.
```groovy
pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout([$class: 'SubversionSCM', // SVN에서 소스 체크아웃
                    locations: [[
                        credentialsId: '{SVN서버_credential_ID}', // SVN 서버 접속을 위한 credential ID
                        local: '.', // 소스 체크아웃 위치
                        remote: 'svn+ssh://{SVN_소스_저장소_URL}' // SVN 저장소 URL
                    ]]
                ])
            }
        }

        stage('Build') {
            agent {
                docker {
                    image 'jenkins_docker_image' // 빌드에 사용할 Docker 이미지
                    args '-v /opt/:/opt/ -v /tftpboot/:/tftpboot/ --net=host' // 호스트 볼륨 마운트, 호스트 네트워크 사용
                    reuseNode true // Docker 컨테이너가 Jenkins 에이전트의 작업 공간을 공유하도록 함
                }
            }
            steps {
                sh 'make -j' // Docker 컨테이너 내에서 빌드 실행
            }
        }
    }
}
```

Jenkins가 SVN checkout 한 소스를 Docker 컨테이너에서 그대로 사용하기 위하여 **"reuseNode true"** 항목을 추가하였다. 결과로 Docker 컨테이너가 생성될 때, 아래와 같은 아규먼트가 추가된다.
```sh
-w /var/lib/jenkins/workspace/{아이템명} -v /var/lib/jenkins/workspace/{아이템명}:/var/lib/jenkins/workspace/{아이템명}:rw,z
```
즉, 호스트에서 체크아웃 한 소스 **/var/lib/jenkins/workspace/{아이템명}/** 디렉토리를 Docker 컨테이너의 **/var/lib/jenkins/workspace/{아이템명}/** 디렉토리로 마운트하고, 해당 디렉토리를 working 디렉토리로 지정한다.

## Jenkins에서 아이템 빌드
이제 Jenkins에서 해당 아이템을 빌드시키면 소스를 받은 후에, Docker 컨테이너가 생성되고, Docker 컨테이너 안에서 빌드가 수행됨을 확인할 수 있다. 또 빌드가 종료되면 자동으로 생성되었던 Docker 컨테이너는 삭제됨을 확인할 수 있다.  
언급하였듯이 `reuseNode` 설정을 이용하여 Docker 컨테이너에서는 호스트의 jenkins 사용자로 checkout 받은 소스 디렉토리를 사용하므로, 빌드시에는 Docker 컨테이너가 생성되고 삭제되는 아주 짧은 시간의 오버헤드만 있고, 원하는대로 Docker 컨테이너에서 정상적으로 빌드가 되었다.
