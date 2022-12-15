---
title: "Windows에서 Go로 WebApp 작성하기"
category: [Go]
toc: true
toc_label: "이 페이지 목차"
---

Go 언어를 사용하여 Windows용 WebApp 프로그램을 구현하는 방법을 간단히 정리해 본다.

## Go WebApp 프레임워크
여러 프레임워크가 있지만, 나는 주로 아래 프레임워크를 검토하였다.
- [Walk](https://github.com/lxn/walk): Windows용 GUI 프레임워크이고 WebView도 지원하는데, 불행히도 WebView2가 아니라서 대부분의 최신 JavaScript가 안 되는 단점이 있다.
- [Lorca](https://github.com/zserge/lorca): UI layer로 Chrome browser를 사용한다.
- [webview](https://github.com/webview/webview): WebView2 바인딩 패키지로 빌드시 CGo를 사용하여 빌드 및 실행이 번거롭긴 하지만, 최신 JavaScript도 잘 동작한다.
- [go-webview2](https://github.com/jchv/go-webview2): CGo를 사용하지 않고 순수하게 Go로 구현된 WebView2 패키지이다.

## go-webview2 사용
위에서 `Walk`는 WebView2를 지원하지 않아서 사용이 사실상 사용이 곤란하였고, `Lorca`는 자체적으로 시스템에 설치된 Chrome browser를 사용하므로 내가 원하는 방향이 아니었다.  
따라서 위의 프레임워크 중에서 남은 솔루션은 WebView2를 사용하는 프레임워크인데, [webview](https://github.com/webview/webview)는 CGo로 바인딩을 하는 것이라서 사용이 번거로웠다.

> [webview](https://github.com/webview/webview) 페이지에는 C, C++, Go를 사용하는 예제가 있었고, 모두 빌드 및 정상 확인하였지만, Go를 사용할 때는 CGo를 사용해야 해서 번거로웠다.

그러다 [go-webview2](https://github.com/jchv/go-webview2) 패키지를 찾았는데 이것은 순수하게 Go로 구현되어 있어서 아주 간단하게 WebView2를 사용할 수 있었다.  
[GitHub go-webview2 페이지](https://github.com/jchv/go-webview2)에 아주 간단히 웹 페이지를 띄우는 데모 코드가 있고, 실제로 빌드해서 테스트해보니 JavaScript 코드도 잘 실행되었고 팝업 윈도우도 잘 떴다. 😋  

> WebView2를 사용하려면 Windows에 WebView2 엔진이 설치되어 있어야 한다. WebView2는 Windows10 이상에서는 기본적으로 설치가 되어 있는 상태이지만, 미설치 되었거나 Windows7과 같이 WebView2가 디폴트로 미설치된 시스템의 경우에는 [Microsoft WebView2 runtime](https://developer.microsoft.com/en-us/microsoft-edge/webview2/)을 수동으로 설치해 주면 된다.

## 내 go-webview2 테스트 예
아래는 내가 테스트로 작성한 네이버 로그인 페이지을 열고 ID/PW를 세팅하는 코드이다.
```go
package main

import (
    "fmt"

    "github.com/jchv/go-webview2"
)

var w webview2.WebView

func main() {
    w = webview2.NewWithOptions(webview2.WebViewOptions{
        Debug:     false,
        AutoFocus: true,
        WindowOptions: webview2.WindowOptions{
            Title:  "GoWebView2 Example",
            Width:  1024,
            Height: 768,
            IconId: 2,
            Center: true,
        },
    })
    if w == nil {
        fmt.Println("Failed to load webview2.")
        return
    }
    defer w.Destroy()

    // 웹페이지가 로드되면 pageLoaded()을 호출한다.
    w.Init("window.addEventListener('load', function(event) {pageLoaded(location.href);})")
    // pageLoaded() 함수를 onPageLoaded()에 바인딩 시킨다.
    w.Bind("pageLoaded", onPageLoaded)

    // 네이버 로그인 페이지를 로드한다.
    w.Navigate("https://nid.naver.com/nidlogin.login")
    w.Run()
}

// 웹페이지가 로드되면 호출된다. 테스트로 ID/PW를 세팅한다.
func onPageLoaded(url string) {
    fmt.Println("onPageLoaded():", url)
    w.Eval("document.querySelector('#id').value = 'your_id'")
    w.Eval("document.querySelector('#pw').value = 'your_password'")
}
```

참고로 위에서 webview2.NewWithOptions() 호출 부분은 원하면 아래와 같이 풀어서 쓸 수도 있다.
```go
windowOptions := webview2.WindowOptions{
    Title:  "GoWebView2 Example",
    Width:  1024,
    Height: 768,
    IconId: 2,
    Center: true,
}
options := webview2.WebViewOptions{
    Debug:         false,
    AutoFocus:     true,
    WindowOptions: windowOptions,
}
w = webview2.NewWithOptions(options)
```

위 코드에서 보듯이 JavaScript 코드 실행과 바인딩이 잘 된다.
> 참고로 브라우저 디버그가 필요한 경우에는 위의 **NewWithOptions** 함수 파라미터에서 `Debug` 값을 `true`로 변경하여 빌드하고 실행한 후, F12 키를 누르면 브라우저 디버그 창이 열린다.

빌드는 아래와 같이 하면 되는데, 만약에 디버깅 용도로 로그를 출력하고 싶으면 아래 ldflags 옵션에서 `-H=windowsgui` 내용을 빼면 된다.
```shell
C:\>go build -ldflags "-s -H=windowsgui"
```

## WebApp 아이콘 설정
참고로 이 WebApp의 아이콘을 세팅하고 싶으면 [rsrc](https://github.com/akavel/rsrc) 패키지를 이용할 수 있다.  
먼저 아래와 같이 `rsrc` 패키지를 설치한다.
```shell
C:\>go get github.com/akavel/rsrc
```

아래와 같이 `app.manifest` 파일을 작성한다.
```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">
    <assemblyIdentity version="1.0.0.0" processorArchitecture="*" name="App" type="win32"/>
    <dependency>
        <dependentAssembly>
            <assemblyIdentity type="win32" name="Microsoft.Windows.Common-Controls" version="6.0.0.0" processorArchitecture="*" publicKeyToken="6595b64144ccf1df" language="*"/>
        </dependentAssembly>
    </dependency>
</assembly>
```

이제 아래와 같이 실행하면 **app.manifest** 파일과 **app.ico** 파일을 사용하여 **rsrc.syso** 파일을 생성한다.
```shell
C:\>rsrc -manifest app.manifest -ico app.ico -o rsrc.syso
```

위와 같이 실행하여 **rsrc.syso** 파일이 생성되었으면 (사실상 파일 이름은 관계없음), 다시 `go build`를 실행하면 실행 파일에 app.ico 아이콘이 표시된다.

## 기존 윈도우에 웹뷰 띄우기
그런데 [go-webview2](https://github.com/jchv/go-webview2) 패키지는 웹뷰를 새로운 윈도우로 띄우는 것은 잘 되었지만, 기존 윈도우(예: app 내에 레이아웃으로 나눈 윈도우)로 띄우는 것은 되지 않았다.  
이상해서 [webview](https://github.com/webview/webview)를 확인해 보니 이건 잘 되었지만, CGo로 빌드해야 하고 **WebView2Loader.dll** 파일도 함께 배포해야 하므로, 이건 내키지가 않았다.  
아무리 구글링을 해봐도 관련 자료가 없어서, 결국 go-webview2 패키지 소스를 살펴보니, 관련 코드가 구현되어 있지 않아서 발생한 문제였다. 즉, go-webview2 패키지의 `webview.go` 파일에서 NewWithOptions() 함수는 아래와 같이 되어 있었다. (**options.Window** 값이 **nil**이 아닌 경우를 처리하지 않고 있음)
```go
func NewWithOptions(options WebViewOptions) WebView {
    ...

    w.browser = chromium
    w.mainthread, _, _ = w32.Kernel32GetCurrentThreadID.Call()
    if !w.CreateWithOptions(options.WindowOptions) {
        return nil
    }

    ...
}
```

그래서 아래와 같이 수정하니, 기존 윈도우에 웹뷰를 띄울 수 있었다.
```go
func NewWithOptions(options WebViewOptions) WebView {
    ...

    w.browser = chromium
    w.mainthread, _, _ = w32.Kernel32GetCurrentThreadID.Call()
    if options.Window != nil {
        w.hwnd = uintptr(options.Window)
        if !w.browser.Embed(w.hwnd) {
            return nil
        }
        w.browser.Resize()
    } else if !w.CreateWithOptions(options.WindowOptions) {
        return nil
    }

    ...
}
```
<br>

위 수정 사항으로 끝인 줄 알았는데, 테스트 하다 보니 메인 윈도우의 위치를 움직인 후에는 웹뷰에서 드랍 다운 메뉴의 위치가 옮기기 전의 위치로 잘못 나오는 이슈를 발견하였다. 다시 구글링 삽질을 하였으나 역시나 관련 자료를 찾을 수는 없었고, 패키지 소스를 보다가 이 경우에는 웹뷰 브라우저로 <font color=purple>NotifyParentWindowPositionChanged</font> 함수를 호출해주어야 한다는 것을 깨달았다.  
역시 원래 패키지 소스에는 구현이 되어 있지 않은 관계로, go-webview2 패키지의 `common.go` 파일에서 아래 내용을 추가하였고,
```go
type WebView interface {
    ...

    NotifyWinowPosChanged()
}
```
`webview.go` 파일에서 아래와 같이 구현하였다.
```go
func (w *webview) NotifyWinowPosChanged() {
    w.browser.NotifyParentWindowPositionChanged()
}
```
<br>

이제 메인 윈도우 쪽에서 <font color=blue>WM_WINDOWPOSCHANGED</font> 메시지를 받으면 웹뷰의 <font color=purple>NotifyWinowPosChanged</font> 함수를 호출해 주면 된다.  
나의 경우에는 [walk](https://github.com/lxn/walk) 패키지로 Windows GUI 프로그램을 구현하고 있었으므로, 아래와 같이 웹뷰를 생성하였다. (아래에서 **mw.webviewWindow**가 walk.TextEdit로 생성한 기존 윈도우이고, 이것의 윈도우 핸들을 얻어서 웹뷰 생성시 **Window** 파라미터로 넘겨주었음)
```go
hWnd := mw.webviewWindow.Handle()
options := webview2.WebViewOptions{Window: unsafe.Pointer(hWnd), Debug: false, AutoFocus: true}
mw.webView = webview2.NewWithOptions(options)
walk.InitWrapperWindow(mw)
```
위와 같이 <font color=purple>InitWrapperWindow</font> 함수를 호출하여 내 윈도우 프로시저가 호출되게 하였다. 여기서는 <font color=blue>WM_WINDOWPOSCHANGED</font>, <font color=blue>WM_CLOSE</font> 메시지 처리만 하면 되므로 아래와 같이 작성하였다.
```go
func (mw *MyMainWindow) WndProc(hwnd win.HWND, msg uint32, wParam, lParam uintptr) uintptr {
    switch msg {
    case win.WM_WINDOWPOSCHANGED:
        if mw.webView != nil {
            mw.webView.NotifyWinowPosChanged()
        }
    case win.WM_CLOSE:
        mw.Close()
    }

    return mw.AsContainerBase().WndProc(hwnd, msg, wParam, lParam)
}
```

## 결론
Windows WebApp이 필요하여 여러 방법들을 찾아보다가, go-webview2 패키지를 이용하는 방법이 괜찮아 보여서 간단히 기록하였다. Go로 웹브라우저가 필요한 Windows GUI 앱 작성시 도움이 되길 기대한다.
