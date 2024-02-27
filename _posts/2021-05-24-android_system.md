---
title: "안드로이드 시스템 앱 설치 및 삭제"
category: Android
toc: true
toc_label: "이 페이지 목차"
---

안드로이드에서 시스템 앱을 설치하거나 삭제하는 방법을 정리해 본다.

<br>
오랜만에 안드로이드에서 시스템 앱을 교체할 일이 생겼는데, 일반적인 방법으로는 문제가 있어서 삽집을 하였고, 이에 간략히 정리해 본다.

## Windows의 경우
아래 사용 예시에는 Linux 시스템인 경우를 예로 들었는데, Windows의 경우도 마찬가지이다.  
만약 Windows에 아직 ADB를 설치하지 않은 상태라면 [안드로이드 platform-tools](https://developer.android.com/studio/releases/platform-tools) 페이지에서 플랫폼에 맞는 platform tools를 다운받아서 설치하고, 설치 경로를 PATH에 추가한다.  
이후 안드로이드 폰에서 USB 디버깅을 허용한 후, USB로 연결한다. 이 때 안드로이드 폰에서 USB 디버깅을 허용하겠냐는 팝업이 뜨면 허용 한다. 이후 Windows 콘솔에서 아래와 같이 명령을 실행해서 디바이스가 리스트에 보이면 성공이다.
```batch
C:\>adb devices
```

## 설치된 전체 패키지 리스트 출력
아래와 같이 실행하면 설치된 모든 패키지 리스트가 출력된다.
```sh
$ adb shell pm list packages
```
여기에서 얻은 <패키지 이름>을 아래에서 설명할 앱 삭제시 이용할 수 있다.

## 안드로이드 시스템 앱 삭제
먼저 안드로이드 기기에 설치된 <font color=blue>시스템 앱</font>의 삭제는, 일반적인 앱과는 다르게 폰에서 직접 삭제가 되지 않지만, ADB와 삭제할 앱의 패키지 이름을 알면 쉽게 삭제할 수 있다.  
앱의 패키지 이름은 만약 사용하는 기기에서 해당 기능을 제공하지 않으면, PlayStore에서 [설치된 앱 분석기(Application Inspector)](https://apkcombo.com/ko/app-inspector/com.ubqsoft.sec01/) 앱 등을 설치하여 이용하면 된다.
1. `설치된 앱 분석기` 앱을 통해 삭제할 앱의 패키지 이름을 얻는다. (보통 `com.xxx.yyy` 형태)
1. 아래와 같이 ADB를 연결한다. (이하 모든 ADB 명령은 Windows의 경우도 마찬가지임)
   ```sh
   $ adb shell
   ```
1. 이제 아래와 같은 명령으로 시스템 앱을 삭제할 수 있다.
   ```sh
   $ pm uninstall -k --user 0 <패키지 이름>
   ```
   정상적이라면 "**Success**" 메시지가 출력되고 해당 앱이 삭제된다.

## 시스템 앱 삭제 예
다음은 위와 같은 방식으로 내 안드로이드 폰에서 선탑재된 시스템 앱을 삭제한 예이다. (참고로 아래 예는 `adb shell` 명령으로 ADB shell에 진입한 이후의 명령 예이다. ADB shell에 진입하지 않고 바로 명령을 실행하려면 각 명령 앞에 `adb shell`을 추가하면 된다.)
- Briefing
  ```sh
  $ pm uninstall -k --user 0 flipboard.boxer.app
  ```
- DMB
  ```sh
  $ pm uninstall -k --user 0 com.sec.android.app.dmb
  ```
- Galaxy Store
  ```sh
  $ pm uninstall -k --user 0 com.sec.android.app.samsungapps
  ```
- Google Assistant
  ```sh
  $ pm uninstall -k --user 0 com.android.hotwordenrollment.okgoogle
  ```
- Google Meet
  ```sh
  $ pm uninstall -k --user 0 com.google.android.apps.tachyon
  ```
- Google Play 무비
  ```sh
  $ pm uninstall -k --user 0 com.google.android.videos
  ```
- Google Play 뮤직
  ```sh
  $ pm uninstall -k --user 0 com.google.android.music
  ```
- Google 드라이브
  ```sh
  $ pm uninstall -k --user 0 com.google.android.apps.docs
  ```
- KT WiFi
  ```sh
  $ pm uninstall -k --user 0 com.kt.wificm
  ```
- OneDrive
  ```sh
  $ pm uninstall -k --user 0 com.microsoft.skydrive
  ```
- T world
  ```sh
  $ pm uninstall -k --user 0 Com.sktelecom.minit
  ```
- 게임툴즈
  ```sh
  $ pm uninstall -k --user 0 com.samsung.android.game.gametools
  ```
- 삼성 사전
  ```sh
  $ pm uninstall -k --user 0 com.sec.android.app.dictionary
  ```
- 삼성 클라우드
  ```sh
  $ pm uninstall -k --user 0 com.samsung.android.scloud
  ```
- 삼성 Pay
  ```sh
  $ pm uninstall -k --user 0 com.samsung.android.spay
  ```
- 삼성 TTS 엔진
  ```sh
  $ pm uninstall -k --user 0 com.samsung.SMT
  ```
- 삼성 인터넷
  ```sh
  $ pm uninstall -k --user 0 com.sec.android.app.sbrowser
  ```
- 스마트 TV
  ```sh
  $ pm uninstall -k --user 0 com.omnitel.android.dmb
  ```
- 원스토어
  ```sh
  $ pm uninstall -k --user 0 com.skt.skaf.A000Z00040
  ```
- 원스토어 서비스
  ```sh
  $ pm uninstall -k --user 0 com.skt.skaf.OA00412131
  ```
- 행아웃
   ```sh
  $ pm uninstall -k --user 0 com.google.android.talk
  ```

> 실제로 나는 이 방법으로 내 안드로이드 폰에 설치된 각종 통신사 앱, 제조사 앱, 구글 앱 등에서 내가 사용하지 않는 앱들은 모두 지우고 사용하고 있다.

## 시스템 앱으로 설치하기
일반적인 앱(즉, 시스템 앱이 아닌)은 ADB를 이용시 ADB <mark style='background-color: #ffdce0'>install</mark> 명령으로 설치하거나, 안드로이드 기기에서 APK 파일을 이용하여 직접 설치할 수 있으나, <font color=blue>시스템 앱</font>은 이렇게 설치하면 정상적으로 실행되지 않을 수 있다. (이것 때문에 삽질하였음. 😠)  

따라서 ADB install 명령 대신에 ADB <mark style='background-color: #dcffe4'>push</mark> 명령을 이용하여 해당 APK를 `/system/app/` 디렉토리의 원하는 경로에 직접 복사하는 방법을 사용하였다.  
1. ADB를 연결한 후 아래와 같이 root 권한으로 /system/ 디렉토리를 쓰기 가능하도록 리마운트한다.
   ```sh
   $ adb root
   $ adb remount /system
   ```
1. 아래 예와 같이 ADB로 앱을 /system/app/ 밑의 원하는 디렉토리로 복사한다. (보통 앱 별로 자신의 하위 디렉토리 사용함)
   ```sh
   $ adb push "APK 파일" /system/app/
   ```
1. 이후 아래와 같이 sync 명령을 수행한 후 reboot 시키면 된다.
   ```sh
   $ adb shell sync
   $ adb shell reboot
   ```

그런데 나는 기존 시스템 앱을 업데이트시키는 경우였는데 (내가 소스를 수정하여 빌드시킨 앱으로), 설치한 후에 정상 실행에 문제가 있었다.  
혹시나 하여 factory reset을 한 후에 위 과정으로 다시 시도해 보니, 문제없이 정상적으로 설치 및 실행되었다. 😅