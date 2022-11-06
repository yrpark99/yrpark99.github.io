---
title: "파이썬으로 안드로이드 앱 제어 예"
category: [Android, Python]
toc: true
toc_label: "이 페이지 목차"
---

파이썬으로 안드로이드 앱을 간단히 제어하는 예제를 작성해 보았다.

## 동기
회사에서 저녁 식사를 하기 위해서는 안드로이드/iOS 앱으로 식권을 신청하여 받은 후에, 이것으로 식당에서 식사를 하는데, 매일 식권을 신청해야 하는 번거로움이 있어서 이를 자동화 해보기로 하였다. 🤥  
우선 안드로이드 UI 컨트롤을 자동해 주는 앱을 찾아 보았으나, 무료로 쓸만한 앱은 찾지 못해서 간단한 프로그래밍을 통한 방법을 찾아 보았다.

## ADB 연결
시스템에 아직 ADB가 설치되지 않은 상태라면 [안드로이드 platform-tools](https://developer.android.com/studio/releases/platform-tools) 페이지에서 플랫폼에 맞는 platform tools를 다운받아서 설치하고, 설치 경로를 PATH에 추가한다.  
이후 안드로이드 폰에서 USB 디버깅을 허용한 후, USB로 연결한다. 이 때 안드로이드 폰에서 USB 디버깅을 허용하겠냐는 팝업이 뜨면 허용한다(매번 이렇게 하면 자동화가 안되므로 영구적으로 허용시킨다).  
이후 Windows 콘솔에서 아래와 같이 명령을 실행해서 디바이스가 리스트에 보이면 성공적으로 연결된 상태이다.
```batch
C:\>adb devices
```

## 필요한 패키지 설치
간단히 파이썬과 `OpenCV`를 이용하여 프로그램을 작성할 것이므로, 아래와 같이 OpenCV 파이썬 패키지를 설치한다.
```batch
C:\>pip install opencv-python
```

## 자동화 코드 순서
아래와 같은 순서로 자동화를 수행하면 된다.
1. 폰 wakeup (아래 코드에서 **wakeup** 함수)  
단, 이미 깨어있는 상태라도 문제없어야 한다.
1. 폰 잠금 해제 (아래 코드에서 **unlock** 함수)  
단, 이미 잠금 해제된 상태라도 문제없어야 한다. 나의 경우 PIN 잠금을 사용하는데, 이 팝업이 떠 있는 상태인지를 판단하기 위하여 화면을 캡쳐해서 OpenCV로 검사했다.
1. 원하는 앱을 실행 (아래 코드에서 **open_food_app** 함수)  
앱 정보는 `Application Inspector` 앱 등의 방법을 통해서 얻을 수 있다. 나의 경우에는 com.vlocally.mealc.android/.mvvm.view.IntroActivity 액티비티를 이용하여 실행시킬 수 있었다.
1. 해당 앱에서 원하는 동작을 수행 (아래 코드에서 **request_food_ticket** 함수)  
나의 경우에는 앱에서 해당 항목의 클릭을 통해서 식권을 신청하는 것이다.

## 예제 코드
아래는 내가 필요한 용도로 작성해 본 예제 소스이다.
```python
import cv2
import os
import subprocess
import time

def adb_cmd(command):
    proc = subprocess.Popen(command.split(' '), stdout=subprocess.PIPE, shell=True)
    (out, _) = proc.communicate()
    return out.decode('utf-8')

def screenshot(file_name):
    adb_cmd(f"adb exec-out screencap -p > {file_name}")

def get_image_position(small_image, big_image):
    img_rgb = cv2.imread(big_image)
    img_gray = cv2.cvtColor(img_rgb, cv2.COLOR_BGR2GRAY)
    template = cv2.imread(small_image, 0)
    height, width = template.shape[::]
    res = cv2.matchTemplate(img_gray, template, cv2.TM_SQDIFF)
    _, _, top_left, _ = cv2.minMaxLoc(res)
    bottom_right = (top_left[0] + width, top_left[1] + height)
    return (top_left[0]+bottom_right[0])//2, (top_left[1]+bottom_right[1])//2

def click(tap_x, tap_y):
    adb_cmd(f"adb shell input tap {tap_x} {tap_y}")

def wakeup():
    adb_cmd("adb shell input keyevent KEYCODE_WAKEUP")

def unlock():
    fileName = "screen.png"
    adb_cmd("adb shell input keyevent KEYCODE_MENU")
    time.sleep(0.2)
    screenshot(fileName)
    x, y = get_image_position("images/pin_input.png", f"{fileName}")
    os.remove(fileName)
    if (x > 500 and x < 600 and y > 700 and y < 800): # check if PIN code popup
        adb_cmd("adb shell input text 7878") # Enter my PIN code

def open_food_app():
    adb_cmd("adb shell am start com.vlocally.mealc.android/.mvvm.view.IntroActivity")
    time.sleep(3)

def request_food_ticket():
    click(60, 140)
    time.sleep(1)
    click(150, 1900)
    time.sleep(0.5)
    click(170, 400)
    time.sleep(0.5)
    click(500, 1895)

wakeup()
unlock()
open_food_app()
request_food_ticket()
```
> 참고로 위 소스는 최대한 간단히 하기 위하여, 내 환경에서만 테스트 하였고 예외 상황에 대한 고려도 하지 않았다. 또, ADB로 화면 스크롤도 가능하지만 나의 경우에는 스크롤이 필요하지 않아서 위의 소스에서는 뺐다.

> 추가로 만약에 여러 개의 안드로이드 device가 연결된 경우에는 (예로 실제 핸드폰이 USB로 연결되었고, 안드로이드 에뮬레이터도 있는 상태) adb 명령시 타겟이 설정되지 않았으므로 실패하게 되는데, 이런 경우까지 대비하려면 adb 명령시에 `-d` 옵션을 추가하면 연결된 USB device를 대상으로 하므로 정상적으로 동작한다.

## PIN 입력 화면
images/pin_input.png 파일은 아래와 같이 PIN 입력을 캡쳐한 사진이다.  
![](/assets/images/pin_input.png)

## Windows 스케줄러 생성
식권 신청 앱은 특정 시간대에만 식권 신청이 가능한데, 위 예제 코드는 시간 검사를 구현하는 않았다.  
이를 위해서 Windows에서 스케줄러를 (`taskschd.msc` 실행) 만들어서 근무 요일(월 ~ 금)의 특정 시간대에만 위 코드를 실행하도록 하면 된다. 또는 Windows 콘솔을 관리자 권한으로 연 후, 아래 예와 같이 실행하면 Windows 작업 스케줄러에 추가된다. (아래 예는 매일 오후 5시 58분에 수행)
```batch
C:\>schtasks /CREATE /TN "식권 자동신청" /SC DAILY /ST 17:58 /TR "cmd /C 'cd /D D:\dailyFoodTicket\ && python ticketRequest.py'"
```

결과로 기대대로 월 ~ 금요일에 세팅한 시각에 앱 동작이 자동화되었다. 🍕  
물론 년차로 쉬는 날에는 회사 컴퓨터에 폰이 연결되지 않은 상태이므로, 년차인 날에 식권이 자동으로 신청되는 불상사는 일어나지 않는다.

## 결론
이와 같이 파이썬과 OpenCV를 조합하여 안드로이드 폰에서의 반복적인 작업을 필요에 의해 간단히 자동화할 수 있었다.
