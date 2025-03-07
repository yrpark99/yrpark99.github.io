---
title: "노트 앱 Obsidian 소개"
category: 노트
toc: true
toc_label: "이 페이지 목차"
---

개인 지식 관리를 위한 노트 앱 중의 하나인 Obsidian(옵시디언)을 소개한다.  

며칠 전에 노트 앱 Obisidian이 기존 0.15.9 버전에서 갑자기 1.0.0 버전으로 업그레이드 되어서, 간단히 사용해 보고 정리 및 소개글을 쓴다.

## 노트의 중요성
아래 글들은 내가 좋아하는 노트의 중요성에 대한 글들이다.
>- "<font color=red>그때의 두려움을 어찌 잊을 수 있으리오!</font>" 왕이 말했다. "<font color=blue>하지만</font>" 여왕은 말을 이었다. "<font color=blue>메모해 두지 않으면 잊고 말 겁니다.</font>"
>- 기록은 기억을 지배한다.
>- 기록은 재산이다.
>- 기록이 쌓이면 뮈든 된다.
>- 기억은 희미해져도 기록은 선명하다.
>- 머리속에 든 지식은 오픈해서 검증받아야 산지식이 된다.
>- 모든 지식은 공유되야 하며 실천 없는 지식은 껍데기에 불과하다.
>- 세상에 가장 흐린 먹물도 가장 좋은 기억력보다 낫다.

나의 경우 PKM(Personal Knowledge Management)을 위한 노트로 주로 Onenote와 GitHub 블로그, 위키 등을 이용하고 있는데, Obisidian은 무료로 로컬 및 클라우드에서 Markdown 베이스로 강력한 지식 관리 시스템을 구축할 수 있어서, 앞으로 종종 이용해 보려고 한다.
> 물론 비슷한 용도로 [Notion](https://www.notion.so/ko-kr)이 있는데, Notion은 협업 툴로 아주 강력하지만, 무료로는 사용에 제한이 있고 지나치게 복잡하면서 기능이 많고 플랫폼에 종속될 우려가 있어서, 여기서 내가 원하는 개인 지식 관리 의도와는 조금 맞지 않는 것 같다.

> 또 [Silver Bullet](https://silverbullet.md/)라는 마크다운 기반의 개인 지식 관리 시스템도 있다. 이건 GitHub IO처럼 호스팅 방식인데, 자체적으로 호스팅하고 싶은 경우에는 이용할 수 있겠다. 일단 웹호스팅을 하면 대부분의 웹브라우저에서 해당 URL로 접속하기만 하면 내용을 볼 수 있다. 오픈 소스이므로 [Silver Bullet 소스 저장소](https://github.com/silverbulletmd/silverbullet)에서 소스를 확인할 수도 있다.

## Obisidian
[Obisidian](https://obsidian.md/)은 흑요석이란 뜻으로 마인크래프트에도 나오는 광물 중의 하나이다. (로고가 흑요석을 형상화한 모양임)  
"**A second brain**"을 표방하는 노트 앱으로, 아래와 같은 특징을 갖고 있다.
  - 멀티 플랫폼 지원
  - Markdown 기반 노트 작성
  - 멀티 탭 지원
  - PDF export 지원
  - 파일 시스템 base
  - 로컬 및 클라우드 운용 가능
  - 플러그인 지원

## 설치
[Obisidian 홈페이지](https://obsidian.md/) 또는 [Obisidian 릴리즈 페이지](https://github.com/obsidianmd/obsidian-releases/releases)에서 다운로드 받아서 설치하면 된다. Electron base로 알고 있는데, 실행 속도는 빠른 편이다.  
Android 앱은 **Play 스토어**에서 [Obsidian](https://play.google.com/store/apps/details?id=md.obsidian) 앱을 찾아서 설치하면 된다.

## Obsidian 플러그인
Obsidian 커뮤니티 플러그인은 무료로 이용할 수 있다. 상당히 많은 플러그인들이 있는데, 일단 나는 아래 플러그인들을 설치해 보았다.
- Obsidian Git
- Advanced Tables

## 파일 저장 경로
위에서 언급했듯이 Obsidian은 파일 시스템 base로 디렉토리와 md 파일로 구성된다.  
Windows의 경우에는 디폴트로 `%USERPROFILE%\Documents\` 디렉토리 밑에 구성되는데, Obisidian에서 좌측 하단의 `다른 저장고 열기` 버튼을 클릭하면 사용자가 원하는 다른 경로의 파일 저장고를 열 수 있다.  
Obisidian에서 디렉토리와 노트를 생성하면 로컬 디렉토리에도 해당 디렉토리와 md 파일이 생성되고, 반대로 로컬 디렉토리에 디렉토리와 md 파일을 복사하면 Obisidian에도 반영되어 나타난다.

> Obsidian은 파일 저장고를 workspace 개념으로 처리하며, 각각의 파일 저장고마다 설정을 따로 저장하는데, 이 위치는 파일 저장고의 최상위 디렉토리에서 **.obsidian** 디렉토리이다.  
> 참고로 열린 Obsidian을 모두 닫은 후 다시 실행시키면, 자동으로 마지막 파일 저장고를 다시 로딩한다.

## 클라우드에 저장하기
여러 디바이스의 Obisidian에서 동일 저장소를 sync를 맞추어서 사용하려면 Obsidian 파일들을 클라우드에 저장한 후 sync 매커니즘을 이용하면 한다.  
가장 간단하고 쉬운 방법은 [Obsidian Sync](https://help.obsidian.md/Obsidian+Sync/Introduction+to+Obsidian+Sync)를 사용하는 것인데, 이를 위해서는 유료로 Obsidian 계정을 만들어야 한다.  

그래서 무료로 이용할 수 있는 방법을 찾아 보았고, 일단 아래와 같은 2가지 방법을 찾았다.
### 네트워크 드라이브를 이용한 방법  
Google drive와 같이 desktop client 프로그램을 제공해서 클라이드 저장소를 로컬 드라이브처럼 탐색기 경로로 접근할 수 있으면 된다.  
예를 들어, Google drive를 이용하려는 경우에는 [Google Drive desktop client](https://www.google.com/intl/en_in/drive/download/) 페이지에서 <mark style='background-color: #1a73e8'><font color=white>&nbsp;Download Drive for desktop&nbsp;</font></mark> 버튼을 눌러서 설치 파일을 다운로드한 후에 클라이언트 프로그램을 설치하면, Windows 탐색기에서 `Google Drive` 드라이브가 보인다. (디폴트로 **G** 드라이브에 연결되고 Windows 재시작시에도 자동으로 연결됨)

<br>
이후 Google 드라이브 밑에 Obsidian을 위한 디렉토리를 생성하고 (예: **Obsidian Notes**), 이 밑에 Obsidian 디렉토리와 md 파일들을 구성한다.
이제 Obisidian에서 좌측 하단의 `다른 저장고 열기` 버튼을 클릭하면 저장소 관련 팝업이 뜨는데, 여기에서 **저장소로 폴더 열기**의 **열기** 버튼을 눌러서 Google Drive의 Obisidian 디렉토리를 세팅하면 된다.

> 다만 이 방법은 다수의 컴퓨터끼리는 정상 동작하나, Android에서는 Google drive가 마운트 되지 않아서 Android Obsidian 앱에서는 이용할 수 없었다. (물론 Android에서도 로컬 저장소 경로는 잘 됨)

Obisidian 노트가 클라우드에 있으므로, 변경 사항은 다른 디바이스에서도 자동으로 반영된다. 또, 원하면 노트 자체를 Git과 같은 SCM을 사용하여 운용할 수도 있다.

### Git 저장소를 이용한 방법
이 방법은 노트의 수정 이력을 Git으로 관리할 수 있고 여러 디바이스와 Android 디바이스에서도 사용할 수 있어서, 현재 내가 사용하고 있는 방법이다.  
방법은 본인의 GitHub에 Obisidian 노트를 위한 저장소를 생성한 후 (나의 경우 추후 노트에 개인 정보도 포함될 수 있을 것 같아서 `private`으로 생성했음), 사용할 여러 디바이스에서 이 Git 저장소를 clone 하고, Obisidian에서 `다른 저장고 열기` 버튼을 눌러서 이 경로를 선택하면 된다.  
Android의 경우에도 [MGit](https://play.google.com/store/apps/details?id=com.manichord.mgit&hl=en_US&gl=US)과 같은 Git 관련 앱을 이용하여 Android 로컬 디바이스에 Git 저장소를 clone 할 수 있고, [Obsidian](https://play.google.com/store/apps/details?id=md.obsidian) 앱에서 clone 한 경로를 저장고로 선택하면 된다.

<br>
이후 하나의 디바이스에서 변경을 하고 Git push 하면, 다른 디바이스에서는 Git pull을 하면 sync가 맞게 된다.

## 맺음말
일단 잠깐 확인해 보니, 버전 1.0.0으로의 점프는 사실상 낚시인 것 같다. 기존 버전에 비해서 사실상 크게 바뀐 것은 없었다. 😓  
아무래도 Git으로 Markdown을 관리하면서 노트를 작성하는 것이 여러 면에서 좋은데, 이를 위한 무료 솔루션으로 Obisidian도 괜찮을 것 같다.

> 2025년 2월부터 회사에서도 무료로 사용할 수 있도록 라이선스 정책이 변경되었다. 🆗
