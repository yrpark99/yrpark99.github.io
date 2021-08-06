---
title: "안드로이드 시스템 앱 설치 및 삭제"
category: Android
toc: true
toc_label: "이 페이지 목차"
---

안드로이드에서 시스템 앱을 설치하거나 삭제하는 방법을 정리해 본다.

<br>
오랜만에 안드로이드에서 시스템 앱을 교체할 일이 생겼는데, 일반적인 방법으로는 문제가 있어서 삽집을 하였고, 이에 간략히 정리해 본다.

## 안드로이드 시스템 앱 삭제
먼저 안드로이드 기기에 설치된 <font color=blue>시스템 앱</font>의 삭제는, 일반적인 앱과는 다르게 삭제가 되질 않지만, ADB와 삭제할 앱의 패키지 이름을 알면 쉽게 삭제할 수 있다.  
앱의 패키지 이름은 만약 사용하는 기기에서 해당 기능을 제공하지 않으면, PlayStore에서 `설치된 앱 분석기(Application Inspector)` 앱 등을 설치하여 이용하면 된다.
1. 삭제할 앱의 패키지 이름을 얻는다. (보통 `com.xxx.yyy` 형태)
1. 아래와 같이 ADB를 연결한다. (이하 모든 ADB 명령은 Windows의 경우도 마찬가지임)
```sh
$ adb shell
```
1. 이제 아래와 같은 명령으로 시스템 앱을 삭제할 수 있다.
```sh
$ pm uninstall -k --user 0 <패키지 이름>
```
정상적이라면 "Success" 메시지가 출력되고 앱이 삭제된다.

## 시스템 앱 삭제 예
아래는 위와 같은 방식으로 내 안드로이드 폰에서 선탑재된 시스템 앱을 삭제한 예이다.
- KT WiFi
   ```sh
   $ pm uninstall -k --user 0 com.kt.wificm
   ```
- 원스토어
   ```sh
   $ pm uninstall -k --user 0 com.kt.olleh.storefront
   ```
- Galaxy Store
   ```sh
   $ pm uninstall -k --user 0 com.sec.android.app.samsungapps
   ```
- 스마트 TV
   ```sh
   $ pm uninstall -k --user 0 com.omnitel.android.dmb
   ```
- OneDrive
   ```sh
   $ pm uninstall -k --user 0 com.microsoft.skydrive
   ```
- 삼성 Pay
   ```sh
   $ pm uninstall -k --user 0 com.samsung.android.spay
   ```

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
