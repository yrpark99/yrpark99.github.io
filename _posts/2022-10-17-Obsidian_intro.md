---
title: "노트 앱 Obsidian 소개"
category: [Markdown]
toc: true
toc_label: "이 페이지 목차"
---

개인 지식 관리를 위한 노트 앱 중의 하나인 Obsidian(옵시디언)을 소개한다.  

며칠 전에 노트 앱 Obisidian이 기존 0.15.9 버전에서 갑자기 1.0.0 버전으로 업그레이드 되어서, 간단히 사용해 보고 정리 및 소개글을 쓴다.

## 노트의 중요성
아래 글들은 내가 좋아하는 노트의 중요성에 대한 글들이다.
- “그때의 두려움을 어찌 잊을 수 있으리오!” 왕이 말했다. “하지만” 여왕은 말을 이었다. “메모해 두지 않으면 잊고 말 겁니다.”
- 기록은 기억을 지배한다.
- 기록은 재산이다.
- 머리속에 든 지식은 오픈해서 검증받아야 산지식이 된다.
- 모든 지식은 공유되야 하며 실천 없는 지식은 껍데기에 불과하다.
- 세상에 가장 흐린 먹물도 가장 좋은 기억력보다 낫다.

나의 경우 노트 앱으로 주로 Onenote와 GitHub 블로그, 위키 등을 이용하고 있는데, Obisidian은 무료로 로컬에서도 Markdown 베이스로 강력한 지식 관리 시스템을 구축할 수 있어서, 앞으로 종종 이용해 보려고 한다.
>물론 비슷한 용도로 [Notion](https://www.notion.so/ko-kr)도 있지만, Notion의 경우 지나치게 복잡하면서 기능이 많고, 나중에는 이 플랫폼에 종속될 것 같아서 내가 원하는 바와는 조금 맞지 않는 것 같다.

## Obisidian
[Obisidian](https://obsidian.md/)은 흑요석이란 뜻으로 마인크래프트에도 나오는 광물 중의 하나이다. (로고가 흑요석 모양임)  
"**A second brain**"을 표방하는 노트 앱으로, 아래와 같은 특징을 갖고 있다.
  - 멀티 플랫폼 지원
  - Markdown 기반 노트 작성
  - 파일 시스템 base
  - 로컬 및 클라우드 운용 가능
  - PDF export 지원
  - 플러그인 지원

## 설치
[Obisidian 홈페이지](https://obsidian.md/) 또는 [Obisidian 릴리즈 페이지](https://github.com/obsidianmd/obsidian-releases/releases)에서 다운로드 받아서 설치하면 된다. Electron base로 알고 있는데, 실행 속도는 빠른 편이다.  
Android 앱은 **Play 스토어**에서 [Obsidian](https://play.google.com/store/apps/details?id=md.obsidian) 앱을 찾아서 설치하면 된다.

## 파일 저장 경로
위에서 언급했듯이 Obsidian은 파일 시스템 base로 디렉터리와 md 파일로 구성된다.  
Windows의 경우에는 디폴트로 `%USERPROFILE%\Documents\` 디렉터리 밑에 **Obsidian Vault** 디렉터리에 저장되는데, 물론 이 디렉터리는 사용자가 원하는대로 변경할 수 있다.  
Obisidian에서 디렉터리와 노트를 생성하면 로컬 디렉터리에도 해당 디렉터리와 md 파일이 생성되고, 반대로 로컬 디렉터리에 디렉터리와 md 파일을 복사하면 Obisidian에도 반영되어 나타난다.

## 클라우드에 저장하기
여러 디바이스의 Obisidian에서 동일 저장소를 sync를 맞추어서 사용하려면 Obsidian 파일들을 클라우드에 저장한 후 sync 매커니즘을 이용하면 한다.  
가장 간단하고 쉬운 방법은 [Obsidian Sync](https://help.obsidian.md/Obsidian+Sync/Introduction+to+Obsidian+Sync)를 사용하는 것인데, 이를 위해서는 유료로 Obsidian 계정을 만들어야 한다.

<br>
만약에 무료로 이용하고 싶으면 Google drive와 같이 desktop client 프로그램을 제공해서 클라이드 저장소를 로컬 드라이브처럼 탐색기 경로로 접근할 수 있으면 된다.  
예를 들어, Google drive를 이용하려는 경우에는 [Google Drive desktop client](https://www.google.com/intl/en_in/drive/download/) 페이지에서 <mark style='background-color: #1a73e8'><font color=white>&nbsp;Download Drive for desktop&nbsp;</font></mark> 버튼을 눌러서 설치 파일을 다운로드한 후에 클라이언트 프로그램을 설치하면, Windows 탐색기에서 `Google Drive` 드라이브가 보인다. (디폴트로 **G** 드라이브에 연결되고 Windows 재시작시에도 자동으로 연결됨)

<br>
이후 Google 드라이브 밑에 Obsidian을 위한 디렉터리를 생성하고 (예: **Obsidian Notes**), 이 밑에 Obsidian 디렉터리와 md 파일들을 구성한다.

이제 Obisidian에서 좌측 하단의 **다른 저장고 열기** 버튼을 클릭하면 저장소 관련 팝업이 뜨는데, 여기에서 **저장소로 폴더 열기**의 **열기** 버튼을 눌러서 Google Drive의 Obisidian 디렉터리를 세팅하면 된다.

>다만 이 방법은 다수의 컴퓨터끼리는 정상 동작하나, Android에서는 Google drive가 마운트 되지 않으므로 아쉽게도 Obsidian 앱에서는 이용할 수 없었다. (물론 Android에서도 로컬 저장소 경로는 잘 됨)

Obisidian 노트가 클라우드에 있으므로, 변경 사항은 다른 디바이스에서도 자동으로 반영된다. 또, 원하면 노트 자체를 Git과 같은 SCM을 사용하여 운용할 수 있다.

## 맺음말
일단 잠깐 확인해 보니, 버전 1.0.0으로의 점프는 사실상 낚시인 것 같다. 기존 버전에 비해서 사실상 크게 바뀐 것은 없었다. 😓  
아무래도 Git으로 Markdown을 관리하면서 노트를 작성하는 것이 여러 면에서 좋은데, 무료 솔루션으로 Obisidian도 괜찮을 것 같다.
