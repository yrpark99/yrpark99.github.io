---
title: "원격 데스크톱 접속 방법 정리"
category: Environment
toc: true
toc_label: "이 페이지 목차"
---

회사 PC에 원격 접속하는 몇가지 방법들을 소개한다.

<br>
참고로 원격 접속에는 메신저나 크롬 원격 데스크톱 등과 같은 다른 여러 가지 솔루션이 있지만, 이와 같은 일회성 솔루션들은 본 글에서는 다루지 않았다.

## Windows 원격 데스크톱
타겟 PC의 OS가 Windows인 경우에는 Windows가 지원하는 Remote Desktop 기능을 사용하면 편리하다. 간단히 요약하면 아래와 같이 할 수 있다.
1. 타겟 PC에서 원격 데스크톱 연결을 활성화 시킨다. (설정 -> 시스템 -> 원격 데스크톱 -> `원격 데스크톱 활성화` 항목 체크)
1. 원격 PC에서 `원격 데스크톱 연결`(또는 `mstsc` 명령)을 실행한 후, 컴퓨터 이름에는 타겟 PC의 IP 주소를 입력하면 된다.

그런데 회사 내부망 내의 PC에 원격 접속하려는 경우에는, <mark style='background-color: #ffdce0'>VPN으로 회사 내부망에 접속</mark>을 이용할 수 있는 환경이면 아래 방법이 가장 간단한 것 같다.
1. 타겟 PC의 공유기에서 RDP(Remote Desktop Protocol) 디폴트 포트인 <font color=blue>3389</font>를 타겟 PC로 <font color=blue>포트 포워드</font> 규칙에 추가한다.
1. VPN을 이용하여 회사 내부망에 접속 가능한 상태로 만든다
1. 원격 PC에서 `원격 데스크톱 연결`을 실행한 후, 컴퓨터 이름에 타겟 PC의 IP 주소를 입력하면 된다.

> 최근에 COVID-19로 인하여 많은 회사에서 재택 근무를 위하여 VPN 접속 환경을 제공하는데, 이런 경우라면 아래와 같은 별도의 원격 제어 프로그램을 설치하지 않고도, Windows Remote Desktop을 이용하여 간편하게 원격 제어를 할 수 있다.  
만약에 회사에서 VPN 환경이 제공되지 않고 대신에 공인 IP를 할당받을 수 있는 환경이라면, 수동으로 [OpenVPN](https://openvpn.net/) 등의 VPN 프로그램으로 VPN을 구축하면 (서버/클라이언트) 마찬가지로 Windows Remote Desktop을 이용할 수 있다.

## VNC 이용
VNC(Virtual Network Computing)를 이용한 방법으로 [RealVNC](https://www.realvnc.com/)(단, server는 유료임), [TightVNC](https://www.tightvnc.com/), [UltraVNC](https://uvnc.com/) 등을 사용할 수 있다. 마찬가지로 회사 내부망의 PC에 원격 접속하려는 경우에는 VPN으로 회사 내부망에 접속할 수 있는 환경이라야 한다.

## Teamviewer
[Teamviewer](https://www.teamviewer.com/)는 개인용과 비상용 목적으로는 무료이고, 멀티 플랫폼을 지원한다. 원격 데스크톱 프로그램 중에서는 가장 기능이 많은 것 같다.  
나는 현재 Teamviewer를 10년 이상 사용 중인데 (회사에서 라이선스 구입), 핸드폰으로도 언제 어디서나 회사 PC에 접속할 수 있고, 속도/기능/품질 면에서 만족스러운 수준이다.

## Anydesk
[Anydesk](https://anydesk.com/)는 개인용으로 무료이고 멀티 플랫폼을 지원한다.  
나는 예전에 잠깐 회사 팀뷰어의 라이선스가 없을 때 대안으로 사용해 보았는데, 팀뷰어의 대체재로 괜찮은 것 같았다.

## RustDesk
[RustDesk](https://rustdesk.com/)는 팀뷰어를 대체할 수 있는 멀티 플랫폼을 지원하는 원격 데스크톱 솔류션인데, 특이한 것은 Rust 언어로 구현된 open source 무료 솔루션이라는 것이다. (그래서 바로 구미가 당겼음 🤔)  
1. RustDesk 설치  
[RustDesk](https://rustdesk.com/) 홈페이지에 접속하여 본인이 원하는 플랫폼을 선택하여 다운받아서 설치하면 된다. 또는 [GitHub RustDesk release](https://github.com/rustdesk/rustdesk/releases) 페이지에서 원하는 버전의 타겟 OS용 이미지를 다운받아서 설치해도 된다.  
설치 자체는 아주 간단하므로 과정은 생략한다.
1. RustDesk 실행  
설치된 프로그램을 실행하면 RustDesk가 실행되는데, 다른 컴퓨터에서 해당 ID로 원격 접속해 보면 잘 동작하는 것을 확인할 수 있었다.  
그런데 RustDesk는 디폴트로 free public 서버를 사용한다. 다행히 한국 내 서울에도 free public 서버가 있긴 하지만, 실제 테스트를 해 보니 속도를 위해서 원격 이미지 품질을 낮춘 것을 확인할 수 있었다.
1. 원격 이미지 품질을 높이려면 더 좋은 서버를 단독으로 사용하면 될텐데, 다행히 RustDesk는 open source로 서버 프로그램의 소스도 공개하고 있었다 (실행 프로그램만 다운로드도 가능). 그래서 [RustDesk Own Your Server](https://rustdesk.com/server/) 페이지를 참조하여 자체 RustDesk 서버를 아래와 같이 구축해 보았다.
   - [RustDesk server 다운로드](https://github.com/rustdesk/rustdesk-server/releases) 페이지에서 원하는 OS와 버전의 이미지를 다운로드한다. 예를 들어 나의 경우는 [Oracle Cloud](https://cloud.oracle.com/) VM에서 아래와 같이 RustDesk server 실행 파일을 다운로드해서 압축을 풀었다.
     ```shell
     $ wget https://github.com/rustdesk/rustdesk-server/releases/download/1.1.5/rustdesk-server-linux-x64.zip
     $ unzip rustdesk-server-linux-x64.zip
     ```
   - 결과로 아래 2개의 실행 파일이 얻어진다.
      - <span style="color:purple">hbbs</span> - RustDesk ID/Rendezvous server
      - <span style="color:purple">hbbr</span> - RustDesk relay server
   - 서버 프로그램은 아래와 같은 형식으로 실행시키면 된다.
     ```shell
     $ ./hbbs &
     $ ./hbbr &
     ```
   - 그런데 <font color=blue>hbbs</font>는 21115(tcp), 21116(tcp/udp), 21118(tcp) 포트를 사용하고, <font color=blue>hbbr</font>은 21117(tcp), 21119(tcp) 포트를 사용하므로, 방화벽에서 해당 포트들을 허용해 주어야 한다.  
   참고로 각 포트의 open 여부는 [you get signal](https://www.yougetsignal.com/tools/open-ports/) 웹페이지에 접속해서 확인할 수 있다.
   - RustDesk 서버 프로그램들이 정상적으로 실행 중인 상태이면, 이제 RustDesk 클라이언트 프로그램에서 **ID** 옆의 버튼을 눌러서 **ID/Relay Server** 항목을 선택한다.  
   그러면 아래와 같이 ID/Replay Server 팝업이 뜨는데, 여기에서 `ID Server`와 `Relay Server` 란에 자체 구축한 RustDesk 서버 IP 주소를 입력하면 된다. (타겟, 클라언트 둘 다)  
![](/assets/images/rust_server_setting.png)
1. 위와 같이 나는 [Oracle Cloud](https://cloud.oracle.com/)로 평생 무료 티어를 사용하여 VM instance를 생성하고, 여기에 RustDesk server를 설치하여 테스트해 보았는데, 기대대로 free public 서버보다 이미지 품질이 좋았다.  
또 안드로이드의 경우 `RustDesk Remote Desktop` 앱이 있어서 (또는 [GitHub RustDesk release](https://github.com/rustdesk/rustdesk/releases)에서 Android 용 APK 파일을 다운받아서) 설치한 후에 테스트해 보니, 핸드폰에서 PC로 원격 접속도 잘 되었고, 반대로 PC에서 핸드폰으로도 원격 접속이 잘 되었다.  
RustDesk 덕분에 라이선스 제약 없이 내가 자체 구축한 서버를 사용하여 속도와 이미지 품질까지 제법 괜찮은 무료 원격 솔루션을 구축할 수 있게 되었다. 🍺

## TopDesk
[TopDesk](https://topdesk.co.kr/)는 드물게 국산 프로그램으로 개인 뿐만 아니라 비즈니스 용도로도 무료이다. 현재는 Windows 플랫폼만 지원하고 있으며 향후에는 크로스 플랫폼도 지원할 계획인 것 같다.

## UltraViewer
[UltraViewer](https://www.ultraviewer.net/)는 현재 Windows 플랫폼만 지원하는 단점이 있지만, 아주 간단히 무료로 이용할 수 있고, 속도 면에서도 만족스러워서 애용하고 있다.
