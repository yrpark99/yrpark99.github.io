---
title: "SonarQube 소개"
category: [Environment]
toc: true
toc_label: "이 페이지 목차"
---

SonarQube 소개와 간단히 사용법을 정리한다.

## 소개
프로그램 개발시 코드 정적 분석 툴은 코드 품질과 보안 등에 대하여 도움을 주므로, 중요한 프로젝트에는 도입을 하는 것이 좋은데, [SonarQube](https://www.sonarsource.com/products/sonarqube/)는 [SonarSource](https://www.sonarsource.com/)라는 회사에서 Java로 개발한 코드 정적 분석 툴의 하나이다.  
SonarQube는 오픈 소스로 무료 에디션을 비롯하여 여러 에디션을 제공하는데, 이 중에서 커뮤니티 에디션은 무료이고, on-premise 환경에서 호스팅해서 이용할 수 있다.  
<br>
SonarQube는 C, C++, C#, CSS, Go, HTML, Java, JavaScript, Kotlin, Objective-C, PHP, Python, Ruby, Scala, Swift, TypeScript, XML 등의 언어를 지원하는데, 다만 C, C++, Objective-C, Swift 등의 몇 가지는 커뮤니티 에디션에서는 포함되어 있지 않다.  
<br>
또한 SonarQube는 많은 편집기(Android Studio, Eclipse, IntelliJ IDEA, Visual Studio, VS Code 등)에서 **SonarLint** 플러그인을 통해서 사용할 수도 있어서 편리한 개발 환경을 제공한다.

## SonarQube 설치
SonarQube 관련 문서는 [SonarQube Documentation](https://docs.sonarsource.com/sonarqube/latest/) 페이지에서 볼 수 있고, SonarQube 설치는 이 중에서 [Try out SonarQube](https://docs.sonarsource.com/sonarqube/latest/try-out-sonarqube/) 내용을 따라하면 된다. 본 글에서는 무료인 Community Edition을 예로 든다.  
위 문서에도 나와 있듯이 설치는 아래와 같은 2가지 방법이 있다.
- ZIP 파일을 ([Download](https://www.sonarsource.com/products/sonarqube/downloads/) 페이지에서 Community Edition 용 ZIP 파일을 다운로드) 이용하는 방법
- Docker image를 ([DockerHub](https://hub.docker.com/_/sonarqube/)에서 Community Edition 용을 설치) 이용하는 방법

본 글에서는 자세한 설치 방법은 생략한다. 다만 SonarQube는 Java로 개발되어 JRE 환경이 필요한데, SonarQube 버전에 따라 요구하는 JDK 버전이 다르므로 이 점을 유의해야 하고, database를 사용하는 경우에는 관련 설정을 잘해야 한다.  
<br>
물론 위 2가지 방법 중에서 Docker로 설치하는 것이 훨씬 간단하고 기존 시스템에도 문제를 일으키지 않는 방법인데, 예를 들어 아래와 같이 실행하면 Communitiy Edition 용 Docker 이미지를 다운로드 받은 후, 컨테이너를 생성하고 실행한다.
```sh
$ docker run -d --name sonarqube -p 9000:9000 sonarqube
```
단, 이렇게 하면 embedded database를 사용하게 되고, 이 경우에는 사용하던 DB를 다른 database 엔진으로 이전하는 것 등이 지원되지 않는다.  
<br>
만약에 내장된 DB가 아닌 외부 DB와 연동시키려면 Docker compose를 이용하는 것이 편리한데, 아래 예제를 참조한다.
```yml
version: "3"
services:
  sonarqube:
    image: sonarqube:community
    depends_on:
      - db
    environment:
      SONAR_JDBC_URL: jdbc:postgresql://db:5432/sonar
      SONAR_JDBC_USERNAME: sonar
      SONAR_JDBC_PASSWORD: sonar
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_extensions:/opt/sonarqube/extensions
      - sonarqube_logs:/opt/sonarqube/logs
    ports:
      - "9000:9000"
  db:
    image: postgres:12
    environment:
      POSTGRES_USER: sonar
      POSTGRES_PASSWORD: sonar
    volumes:
      - postgresql:/var/lib/postgresql
      - postgresql_data:/var/lib/postgresql/data
volumes:
  sonarqube_data:
  sonarqube_extensions:
  sonarqube_logs:
  postgresql:
  postgresql_data:
```

## 프로젝트 연동
SonarQube의 설치가 완료되면 <font color=blue>http://localhost:9000</font> 주소로 접속할 수 있다. 웹페이지에서 관리자의 초기 ID/PW는 **admin/admin**이다.  
관리자로 로그인하여 설정, 사용자 추가, 프로젝트 추가, 마켓 등을 이용할 수 있다.  
이후 마켓플레이스에서 언어별 플러그인을 설치한다. 참고로 마켓플레이스에 없는 플러그인을 수동으로 설치하려면, 해당 jar 파일을 다운로드하여 sonarqube가 설치된 경로의 extensions/plugins/ 경로에 복사한 후, sonaqube를 restart 하면 된다.  
> 🚨 그런데 위에서 Community Edition은 C/C++ 검사를 포함하고 있지 않다고 하였는데, 커뮤니티에서 오픈소스로 구현한 아래 플러그인을 다운받아서 설치하면, C/C++도 지원되도록 할 수 있다.
> - C++ 플러그인: [sonar-cxx](https://github.com/SonarOpenCommunity/sonar-cxx)

이후 웹페이지에서 타겟 프로젝트를 생성하고 연동시키면 된다.

## CI 연동
Jenkins에서 SonarQube와 연동시키려면 Jenkins에서 **SonarQube Scanner** 플러그인을 설치하면 된다.  
GitHub이나 GitLab에서도 연동시킬 수 있는데, 자세한 방법은 [GitHub integration](https://docs.sonarsource.com/sonarqube/latest/devops-platform-integration/github-integration/), [GitLab integration](https://docs.sonarsource.com/sonarqube/latest/devops-platform-integration/gitlab-integration/) 내용을 참조한다.

## VS Code 용 익스텐션
[SonarLint for Visual Studio Code](https://github.com/SonarSource/sonarlint-vscode) 익스텐션 익스텐션은 SonarQube와 연동하여 C/C++, Go, JavaScript, TypeScript, Python, Java, HTML, PHP 등의 정적 검사를 지원한다.  
참고로 C/C++ 코드를 검사하려면 compilation database 파일(`compile_commands.json`)이 있어야 하고 ([C and CPP Analysis](https://github.com/SonarSource/sonarlint-vscode/wiki/C-and-CPP-Analysis) 참조), 이후 아래 예와 같이 설정을 추가하면 된다.
```json
"sonarlint.pathToCompileCommands": "${workspaceFolder}/compile_commands.json",
```
<br>
그런데 만약에 프로젝트를 SonarQube와 binding 시킬 것이 아니라면, SonarQube는 설치하지 않고 SonarLint 단독으로 사용할 수도 있다. (나는 주로 이 환경으로 사용하고 있음)  
<br>
또, SonarLint에서 체크되는 케이스들은 모두 개별적으로 deactivate/activate 설정이 가능한데, 예를 들어 아래와 같이 **Quick Fix** 팝업을 띄워서 해당 rule을 보거나 deactivate/activate 시킬 수 있다.  
![](/assets/images/sonarqube_popup.png)  
결과로 VS Code의 설정 파일에 **sonarlint.rules** 항목으로 각 case의 레벨값이 기록된다.
