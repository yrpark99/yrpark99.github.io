---
title: "웹 파일 서버 구성하기"
category: [Server]
toc: true
toc_label: "이 페이지 목차"
---

초간단 Web 파일 서버 구축하기

## 동기
업무 목적으로 많은 경로와 파일들을 Linux 서버에서 Samba로 공유하고 있는데, Windows11에서는 간혹 삼바 접속이 되지 않는다는 문의를 받았다.  
대부분 삼바 서버에 접근시 "네트워크 자격 증명 입력" 팝업이 뜨면서 연결이 되지 않거나 아예 연결이 안되는 경우인데, 이때는 "로컬 그룹 정책 편집기"(또는 gpedit.msc)를 실행한 후에, `"컴퓨터 구성 → 관리 템플릿 → 네트워크 → Lanman 워크스테이션"`에서 "**보안되지 않은 게스트 로그온 사용**" 항목에서 디폴트 "**구성되지 않음**"을 "**사용**"으로 변경하면 된다.  
<br>

만약에 그래도 안 되면, 관리자 권한으로 PowerShell을 연 후에, 아래와 같이 확인해 본다.
```powershell
PS C:\> (Get-SmbClientConfiguration).RequireSecuritySignature
```
만약에 결과가 **False**가 아니고 **True**로 출력된다면, 아래와 같이 실행하여 SMB 보안 서명을 필수로 요구하지 않도록 설정한다.
```powershell
PS C:\> Set-SmbClientConfiguration -RequireSecuritySignature $false
```

보통 위와 같은 수정으로 삼바 접속이 해결되긴 하지만, 담당자가 바뀌거나 신규로 노트북을 받는 경우 등에도 동일 문제가 발생하여, 삼바 이외에도 Web으로 접속할 수 있도록 Web 파일 서버를 구축해 보기로 하였다.

## Web 파일 서버
여러 솔루션들이 있겠지만, 내 용도에 맞는 간단한 솔루션을 찾아 보았는데 대략 아래와 같은 것들을 찾을 수 있었다.
- [Copyparty](https://github.com/9001/copyparty)
- [gohttpserver](https://github.com/codeskyblue/gohttpserver)
- [<mark style='background-color: yellow'>goshs</mark>](https://github.com/patrickhener/goshs)
- [HFS(HTTP File Server)](https://github.com/rejetto/hfs)

각각을 테스트해 보니, 내 용도에는 goshs가 가장 알맞아서 이 글에서 간단하게 소개와 사용법을 기록한다.

## [goshs](https://github.com/patrickhener/goshs) 소개
Go 언어로 개발된 Web 파일 서버로, HTTP/HTTPS, WebDAV, SFTP, SMB, LDAP/S 등 다양한 프로토콜을 지원한다. 최근에도 계속 활발히 개발되고 있는 프로젝트로, 개발자를 위한 기능도 있고, 특히 단일 바이너리 실행 파일만 있어서 간단하게 실행시킬 수 있다.  
그 외에 읽기 전용, 업로드 전용, 삭제 불가, silent, invisible 등이 다양한 서버 모드를 지원한다.  
<br>

아래와 같이 설치할 수 있다.
```sh
$ curl -sSfL https://goshs.de/install.sh | sh
```
<br>

이제 아래 예와 같이 실행시킬 수 있다.
```sh
$ goshs
```
위와 같이 아무 옵션없이 실행시키면 현재 디렉토리 이하의 디렉토리/파일이 대상이 되고, 포트는 8000 번을 사용하게 된다.  
만약에 포트 번호를 변경하고 싶으면 `--port 8080`와 같은 옵션으로 원하는 포트를 지정하면 된다.  
또, 현재 디렉토리가 아닌 다른 디렉토리를 지정하고 싶으면 `--dir {디렉토리}` 옵션으로 지정할 수 있다.  
<br>

그 외에도 도움말을 보면 여러 가지 서버 모드를 설정할 수 있는데, 예를 들어 나는 간단히 read only로 공유하기 위하여 아래와 같은 옵션을 사용해 보았다.
- `--read-only`: Read 만 가능, write는 불가능
- `--no-delete`: 삭제 불가능
- `--no-clipboard`: 클립보드 기능 지원 안함

만약에 서버를 띄운 후에 shell을 종료해도 서버는 계속해서 동작되게 하려면, 아래와 같이 `nohup`을 이용하여 실행시킬 수 있다.
```sh
$ nohup goshs --read-only --no-delete --no-clipboard --dir {디렉토리} 1>/dev/null 2>&1 &
```

또는 host 서버 부팅시 자동으로 Web 파일 서버를 기동시키려면 [서버 시작시 프로그램 자동 시작 설정하기](https://yrpark99.github.io/server/ubuntu_start/) 페이지를 참고하여 설정하면 된다. (나는 우분투 서버에서 부팅시 자동으로 goshs를 실행시키기 위하여 이 방법 사용했음)

> 그런데 한글 이름의 디렉토리/파일에 대한 엑세스가 제대로 되지 않는 버그가 있었다. Claude Code에게 수정해 달라고 요청했더니, 바로 올바르게 수정해 주었다. 또, `COLLAB` 탭을 숨길 수 있는 옵션이 제공되지 않아서, 이것도 Claude Code에게 요청하였더니 바로 수정해 주었고, 결과로 빌드된 goshs를 사용해서 운용 중이다.

## 맺음말
goshs Web 파일 서버는 완전 간단하게 내 파일들을 Web으로 접근할 수 있게 해준다. 특히 빠른 속도와 간단한 설정, 깔끔한 Web UI가 맘에 들어서 팀 서버에도 적용해 보았는데, 간단한 (하지만 기능은 막강함) Web 파일 서버로 추천할 수 있을 것 같다.
