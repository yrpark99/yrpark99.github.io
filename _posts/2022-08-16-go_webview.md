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
따라서 위의 프레임워크 중에서 남은 솔루션은 WebView2를 사용하는 프레임워크인데, [webview](https://github.com/webview/webview)는 CGo로 바인딩을 하는 것이라서 사용이 번거로웠고, [go-webview2](https://github.com/jchv/go-webview2) 패키지는 순수하게 Go로 구현되어 있어서 아주 간단하게 WebView2를 사용할 수 있었다.
<br>

[GitHub go-webview2 페이지](https://github.com/jchv/go-webview2)에 아주 간단히 웹 페이지를 띄우는 데모 코드가 있고, 실제로 빌드해서 테스트해보니 JavaScript 코드도 잘 실행되었고 팝업 윈도우도 잘 떴다. 😋  
> 그런데 이 패키지는 Windows에서 설치된 WebView2 엔진을 사용한다. WebView2는 Windows10 이상에서는 기본적으로 설치가 되어 있는 상태이지만, 미설치 되었거나 Windows7과 같이 WebView2가 디폴트로 미설치된 시스템의 경우에는 [Microsoft WebView2 runtime](https://developer.microsoft.com/en-us/microsoft-edge/webview2/)을 수동으로 설치해 주어야 한다.

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

## 결론
Windows WebApp이 필요하여 여러 방법들을 찾아보다가, go-webview2 패키지를 이용하여 방법이 괜찮아 보여서 간단히 기록하였다.
