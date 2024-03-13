---
title: "파이썬으로 안드로이드 앱 제어 예"
category: [Android, Python]
toc: true
toc_label: "이 페이지 목차"
---

파이썬으로 안드로이드 앱을 간단히 제어하는 예제를 작성해 보았다.

## 동기
회사에서 저녁 식사를 하기 위해서는 모바일 앱으로 식권을 신청하여 받은 후에, 이것으로 식당에서 식사를 하는데, 매일 식권을 신청해야 하는 번거로움이 있어서 이를 자동화 해보기로 하였다. 🤥  
우선 안드로이드 UI 컨트롤을 자동해 주는 앱을 찾아 보았으나, 무료로 쓸만한 앱은 찾지 못해서 ADB(Android Debug Bridge)를 이용한 간단한 프로그래밍을 통한 방법을 찾아 보았다.

## ADB 연결
시스템에 아직 ADB가 설치되지 않은 상태라면 [안드로이드 platform-tools](https://developer.android.com/studio/releases/platform-tools) 페이지에서 플랫폼에 맞는 platform tools를 다운받아서 설치하고, 설치 경로를 PATH에 추가한다.  
이후 안드로이드 폰에서 USB 디버깅을 허용한 후, USB로 연결한다. 이 때 안드로이드 폰에서 USB 디버깅을 허용하겠냐는 팝업이 뜨면 허용한다(매번 이렇게 하면 자동화가 안되므로 영구적으로 허용시킨다).  
이후 Windows 콘솔에서 아래와 같이 명령을 실행해서 디바이스가 리스트에 보이면 성공적으로 연결된 상태이다.
```batch
C:\>adb devices
```

## 자동화 코드 순서
아래와 같은 순서로 자동화를 수행하면 된다. (모두 ADB 명령을 이용함)
1. 모바일폰을 wakeup 시킨다. (아래 코드에서 **wakeup** 함수)  
단, 이미 깨어있는 상태라도 문제없어야 한다.
1. 모바일폰을 잠금 해제한다. (아래 코드에서 **unlock** 함수)  
단, 이미 잠금 해제된 상태라도 문제없어야 한다. 나의 캐시워크 팝업이 먼저 뜨고, 이후 얼굴이나 PIN 잠금 화면이 뜬다. 이런 팝업이 떠 있는 상태이면 각 상태에 맞게 unlock 시켜야 한다.
1. 실행하려는 앱의 패키지 이름 등의 정보를 알아야 하는데, `Application Inspector` 앱을 통해서 간단히 얻을 수 있다.
1. 원하는 앱을 실행시킨다. (아래 예제에서는 ADB shell로 **<span style="color:blue">am start</span> com.vlocally.mealc.android/.mvvm.view.IntroActivity** 명령 부분)
1. 원하는 앱이 이미 실행 중인 상태이면 상태가 꼬일 수 있으므로 종료시킨다. (아래 예제에서는 ADB shell로 **<span style="color:blue">am force-stop</span> com.vlocally.mealc.android** 명령 부분)
1. 해당 앱에서 원하는 동작을 ADB shell 명령으로 수행시킨다.
나의 경우에는 앱에서 해당 항목의 클릭을 통해서 식권을 신청하는 것이다.

## 예제 코드
아래는 내가 필요한 용도로 작성해 본 예제 소스이다.
```python
import subprocess
import time

def adb_cmd(command):
    proc = subprocess.Popen(command.split(' '), stdout=subprocess.PIPE, shell=True)
    (out, _) = proc.communicate()
    return out.decode('utf-8')

def click(tap_x, tap_y):
    adb_cmd(f"adb -d shell input tap {tap_x} {tap_y}")

def scroll(start_x, start_y, end_x, end_y):
    adb_cmd(f"adb -d shell input swipe {start_x} {start_y} {end_x} {end_y}")

def roll(dx, dy):
    adb_cmd(f"adb -d shell input roll {dx} {dy}")

def wakeup():
    print("Wakeup")
    adb_cmd("adb -d shell input keyevent KEYCODE_WAKEUP")
    time.sleep(1)
    cur_focus_status = adb_cmd("adb -d shell dumpsys window | grep mCurrentFocus")
    if "com.cashwalk.cashwalk" in cur_focus_status:
        print("캐시워크 unlock")
        scroll(100, 800, 700, 800)

def unlock():
    adb_cmd("adb -d shell input keyevent KEYCODE_MENU")
    time.sleep(1)

    # 이미 식권대장 앱이 실행 중이면 종료시킨다.
    cur_focus_status = adb_cmd("adb -d shell dumpsys window | grep mCurrentFocus")
    if "com.vlocally.mealc.android" in cur_focus_status:
        adb_cmd("adb -d shell am force-stop com.vlocally.mealc.android")

    # Lock 상태이면 unlock 시킨다.
    cur_focus_status = adb_cmd("adb -d shell dumpsys window | grep mCurrentFocus")
    if "Bouncer" in cur_focus_status:
        print("PIN code 입력")
        adb_cmd("adb -d shell input text 123456") # PIN code
    elif "com.sec.android.app" in cur_focus_status:
        print("Ready 상태")
    else:
        print("지문으로 lock을 풀어주세요")
        time.sleep(10)

def open_food_app():
    # 이미 식권대장 앱이 실행 중이면 종료시킨다.
    adb_cmd("adb -d shell am force-stop com.vlocally.mealc.android")

    # Home으로 이동
    adb_cmd("adb -d shell input keyevent KEYCODE_HOME")

    print("식권대장 앱 실행")
    adb_cmd("adb -d shell am start com.vlocally.mealc.android/.mvvm.view.IntroActivity")
    time.sleep(6)

def request_food_ticket():
    print("전체 보기 클릭")
    click(900, 2100)
    time.sleep(1)

    scroll(100, 800, 100, 200)
    time.sleep(1)
    print("식대 신청 클릭")
    click(200, 1450)
    time.sleep(1)

    print("신청 가능 클릭")
    click(170, 400)
    time.sleep(1)

    print("식대 신청 클릭")
    click(500, 1750)

if __name__ == '__main__':
    wakeup()
    unlock()
    open_food_app()
    request_food_ticket()
```
> 참고로 위 소스는 최대한 간단히 하기 위하여, 내 환경에서만 테스트 하였고 예외 상황에 대한 고려도 하지 않았다.

> 추가로 만약에 여러 개의 안드로이드 device가 연결된 경우에는 (예로 실제 핸드폰이 USB로 연결되었고, 안드로이드 에뮬레이터도 있는 상태) adb 명령시 타겟이 설정되지 않았으므로 실패하게 된다. 위 예제에서는 이런 경우까지 대비하기 위하여 adb 명령시에 `-d` 옵션을 추가하여 연결된 USB device를 대상으로 하였고, 결과로 항상 ADB가 정상적으로 동작하였다.

## Windows 스케줄러 생성
식권 신청 앱은 특정 시간대에만 식권 신청이 가능한데, 위 예제 코드에서는 현재 시간을 검사하지는 않았다.  
대신에 Windows에서 스케줄러를 (`taskschd.msc` 실행) 만들어서 근무 요일(월 ~ 금)의 특정 시간대에만 위 코드를 실행하도록 하였다. 또는 Windows 콘솔을 관리자 권한으로 연 후, 아래 예와 같이 실행하면 Windows 작업 스케줄러에 추가된다. (아래 예는 매일 오후 5시 55분에 수행)
```batch
C:\>schtasks /CREATE /TN "식권 자동신청" /SC DAILY /ST 17:55 /TR "cmd /C 'cd /D D:\dailyFoodTicket\ && python ticketRequest.py'"
```

결과로 기대대로 월 ~ 금요일에 세팅한 시각에 앱이 자동으로 실행되어 식권을 신청하였다. 🍕  
물론 국경일이나 년차로 인해 쉬는 날에는 회사 컴퓨터에 폰이 연결되지 않은 상태이므로, 쉬는 날에 식권이 자동으로 신청되는 불상사는 일어나지 않는다.

## 맺음말
이와 같이 파이썬으로 ADB를 이용하여 안드로이드 폰에서의 반복적인 작업을 필요에 의해 간단히 자동화할 수 있었다.
