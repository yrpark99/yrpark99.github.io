---
title: "PyInstaller로 PyQt ui 파일 포함 시키기"
category: python
toc: true
toc_label: "이 페이지 목차"
---

PyInstaller로 단일 실행 파일 생성시 PyQt UI 파일들을 포함시키는 방법을 정리해 본다.  

## 계기
나는 deploy 용도로는 Python이 적당하지 않다고 생각한다. 개발 생산성이 뛰어난 것은 인정하나, compile 언어가 아닌 interpreter라서 deploy 시 실행 파일 크기가 너무 크고 실행 속도도 느리고, multi-core도 지원도 힘들고 소스 코드 유효성이 체크되지 않는 등의 문제점이 있기 때문이다.  
Qt 또한 실행 파일의 크기가 너무 커져서 나는 해 본 적이 없었는데(Python에서 GUI 프로그램은 Tkinter로만 간단히 해보았음), 얼마 전에 팀원이 PyQt로 개발하고 있었는데 개발과 배포시에 그때마다 소스를 고쳐서 빌드하는 것을 보고 도와주기 위해서 PyInstaller로 단일 실행 파일 생성시에 PyQt의 ui 파일들도 포함시키는 방법을 시도해 보았다.

## 기존 PyQt ui 파일 이용 방법
QtDesigner로 ui 파일을 생성한다. 이 ui 파일은 (아래 예에서는 `UI_file_name.ui`) 파이썬 소스에서 아래 예와 같이 이용할 수 있다.
```python
import sys
from PyQt5.QtWidgets import *
from PyQt5 import uic

form_class = uic.loadUiType("UI_file_name.ui")[0]
class WindowClass(QMainWindow, form_class):
    def __init__(self) :
        super().__init__()
        self.setupUi(self)

if __name__ == "__main__":
    app = QApplication(sys.argv) 
    myWindow = WindowClass() 
    myWindow.show()
    app.exec_()
```
혼자서 이 코드로 개발 및 테스트하는 데에는 아무런 문제가 없다. UI를 변경하려면 QtDesigner에서 수정하고, 이 결과로 나오는 ui 파일을 직접 이용하고 있기 때문이다.  
문제는 PyInstaller로 단일 실행 파일을 만들 때 발생한다.  
기존 방법에서는 우선 아래와 같이 ui 파일들을 pyuic5 툴로 파이썬 소스로 변환한다. (아래 예에서는 `UI_file_name.ui` 파일로 `UI_file_name_generated.py` 파일을 생성)
```bash
pyuic5 -x <UI_file_name.ui> -o <UI_file_name_generated.py>
```

이후, 생성된 `UI_file_name_generated.py` 파일을 파이썬 소스에서 아래와 같이 이용하고 있었다.
```python
import sys
from PyQt5.QtWidgets import *
from PyQt5 import uic

form_class = UI_file_name_generated.Ui_MainWindow
class WindowClass(QMainWindow, form_class):
    def __init__(self) :
        super().__init__()
        self.setupUi(self)

if __name__ == "__main__":
    app = QApplication(sys.argv) 
    myWindow = WindowClass() 
    myWindow.show()
    app.exec_()
```
위에서 보듯이 form_class 내용이 바뀌었다. 즉, PyInstaller로 deploy 파일을 생성할 때는 직접 UI 파일을 로딩하여 사용하는 대신에, 해당 파일을 파이썬으로 변환한 후 이를 사용하도록 소스 코드를 수정해야 하는 문제점이 있었다.

## 개선한 방법
개선한 방법은 pyuic5 툴을 사용하지 않고, PyInstaller로 단일 실행 파일 생성시에 ui 파일을 포함시키는 것이다. PyInstaller 실행시에 아래 예와 같이 옵션을 주면 ui 파일들이 단일 실행 파일에 포함된다.
```bash
pyinstaller -F -w --add-data="*.ui;." <파이썬 파일명>
```
위에서 사용한 각 옵션의 의미는 아래와 같다.
  * -F: 단일 실행 파일로 생성
  * -w: 생성된 실행 파일 실행시 콘솔 윈도우를 보여주지 않음
  * --add-data="*.ui;.": 단일 실행 파일 생성시 현재 디렉토리의 *.ui 파일들을 포함시킴 (현재 디렉토리가 아닌 하위 디렉토리를 사용하려면 `.` 대신에 하위 디렉토리명을 사용하면 됨)

그런데 맨 위 파이썬 소스를 그대로 사용하여 PyInstaller로 실행 파일을 만들어서 실행시켜보면 ui 파일을 제대로 읽어오지 못하였는데, 이는 PyInstaller로 생성되는 단일 실행 파일에서는 ui 파일 경로가 바뀌기 때문이었다.  
이 문제를 해결하기 위해 파이썬 코드를 아래와 같이 수정하였다.
```python
import sys
from PyQt5.QtWidgets import *
from PyQt5 import uic

def resource_path(relative_path):
    if hasattr(sys, '_MEIPASS'):
        return os.path.join(sys._MEIPASS, relative_path)
    return os.path.join(os.path.abspath("."), relative_path)

form_class = uic.loadUiType(def resource_path("UI_file_name.ui"))[0]
class WindowClass(QMainWindow, form_class):
    def __init__(self) :
        super().__init__()
        self.setupUi(self)

if __name__ == "__main__":
    app = QApplication(sys.argv) 
    myWindow = WindowClass() 
    myWindow.show()
    app.exec_()
```
즉, resource_path 함수를 이용하여 PyInstaller 단독 실행 파일을 실행시에는 사용하는 임시 폴더의 경로(`sys._MEIPASS`)를 얻도록 하여 항상 올바른 ui 파일의 경로를 얻을 수 있었다.  
그런데 위 방법은 실행 파일 압축 툴인 UPX가 설치되어 있지 않거나, pyinstaller 실행시 `--noupx` 옵션을 붙이면 잘 되지만, UPX를 사용하는 환경에서는 "ImportError: DLL load failed:"와 같은 콘솔 에러나, "Failed to execute script"와 같은 GUI 에러가 발생하였다.  

## UPX 사용하기
나같은 경우에는 UPX 툴이 PATH에 잡혀 있어서 PyInstaller 실행시 (디폴트로 UPX가 on 되어 있음, 명시적으로 off 시키려면 `--noupx` 옵션을 붙이면 되나, 이 경우 실행 파일 크기가 아주 커짐) UPX가 작동 되었다.  
결과로 각종 DLL 파일들도 실행 압축이 되는데, 이후 단일 실행 파일을 실행시 제대로 압축이 안 풀리면서 "ImportError: DLL load failed:"와 같은 콘솔 에러나, "Failed to execute script"와 같은 GUI 에러가 발생하였다.  
이 부분에서 구글링을 해 보아도 해결이 잘 되질 않았는데, PyInstaller가 실행시 사용하는 디렉토리(`%APPDATA%\pyinstaller\` 경로 밑에 생성됨)를 조사해 보다가 문제점을 찾을 수 있었다.  
문제를 일으킨 파일들은 msvcp140.dll, vcruntime140.dll, qwindows.dll 파일들이어서, pyinstaller 실행시 아래와 같이 `--upx-exclude` 옵션을 사용하여 제대로 풀리지 않는 파일들을 UPX에서 제외시켰더니, UPX가 적용되어도 정상적으로 실행이 되었다.
```bash
pyinstaller -F -w --add-data="*.ui;." --upx-exclude=msvcp140.dll --upx-exclude=vcruntime140.dll --upx-exclude=qwindows.dll <파이썬 파일명>
```

## 결론
위 개선된 방법을 사용함으로써 pyuic5 툴로 UI 파일을 파이썬 소스로 변환시킬 필요가 없어졌고, 파이썬 소스 코드에서 개발용과 PyInstaller deploy 용으로 같은 소스 코드를 그대로 사용할 수 있게 되었다.
