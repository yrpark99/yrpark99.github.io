---
title: "Web 자동화 툴에서 팝업 처리하기"
category: [Web]
toc: true
toc_label: "이 페이지 목차"
---

업무 자동화 툴에서 Web 서버에서 자바스크립트를 이용하여 팝업을 처리하는 방법을 공유한다.

## Web 자동화 시작
내가 작성한 업무 자동화 툴 중에서 Web 서버에 접속하여 정보를 가져와서 처리한 후에, 처리가 끝나면 "승인" 버튼을 눌러서 해당 태스크를 완료로 처리하는 과정이 있었다.  
업무 자동화를 위하여 나는 Go로 [PhantomJS](https://phantomjs.org/)를 이용하여 작성하였는데, 주요 부분은 아래와 같다.
```go
// 브라우저 driver를 open 한다.
var driver *agouti.WebDriver
driver = agouti.PhantomJS()

// 브라우저를 start 한다. (종료시에는 stop 시킴)
if err := driver.Start(); err != nil {
    return
}
defer driver.Stop()

// 브라우저에서 신규 페이지를 연다.
page, err := driver.NewPage()
if err != nil {
    return
}

// 로그인 페이지로 이동한다.
if err := page.Navigate("your_server_login_url"); err != nil {
    return
}

// 로그인을 한다.
page.FindByID("your_server_id_ID").SendKeys("your_id")
page.FindByID("your_server_password_ID").SendKeys("your_password")
page.FindByID("your_server_login_button_ID").Click()

// 기타 작업을 처리한다. (생략)

// 승인 페이지로 이동한다.
if err = page.Navigate("your_server_approval_url"); err != nil {
    return
}

// 승인 버튼을 누른다.
page.FindByXPath("your_server_approval_button_xpath").Click()
```

## 팝업 처리 문제
그런데, 어찌된 일인지 위 코드로는 승인이 제대로 처리되지 않았다. 이유를 찾아보니 웹 서버에서 승인 버튼을 누르면 확인 팝업이 뜨고, 여기에서 확인 버튼을 눌러주어야지만 최종 승인이 되도록 구현했기 때문이었다.  
그래서 PhantomJS를 이용하여 팝업에서 확인 버튼을 누르도록 해 보려고 했는데, 이 방법은 PhantomJS에서 팝업 처리를 해주지 않는 것 같아서 구현하지 못하였다.

## 팝업 처리 방법
관련해서 구글링을 하다 보니, 간단한 자바스크립트를 작성하여 이를 실행하는 방법으로 팝업 문제를 해결할 수 있었다.  
예를 들어 <font color=blue>confirm</font> 팝업을 띄우지 않고 무조건 확인을 리턴하도록 하는 자바스크립트 코드는 아래와 같다.
```javascript
window.confirm = function(msg){return true;};
```
마찬가지로, <font color=blue>alert</font> 팝업을 띄우지 않고 무조건 확인을 리턴하도록 하는 자바스크립트 코드는 아래와 같다.
```javascript
window.alert = function(msg){return true;};
```
브라우저에서 개발자 도구의 console 창에서 위 방법을 사용하니, 팝업이 뜨지 않고 세팅한 값이 리턴되는 것을 확인하였다.

## 자바스크립트를 이용한 팝업 처리
PhantomJS에서는 `RunScript()` 함수로 자바스크립트를 실행시킬 수 있으므로, 이제 승인 버튼을 누르는 코드 전에 아래 코드를 삽입하기만 하면 된다.
```go
// 승인 버튼을 눌렀을 때, 확인/취소 팝업을 띄우지 않고, 무조건 확인을 리턴하도록 한다.
if err = page.RunScript("window.confirm = function(msg){return true;};", nil, nil); err != nil {
    return
}
```

## 결론
이 글에서는 Go로 예를 들었지만, Python에서도 마찬가지로 PhantomJS를 사용하여 RunScript() 함수를 동일하게 이용할 수 있다.  
이 방법을 사용하여 Web 서버에서 confirm/alert 팝업을 띄우는 경우에도 완전한 자동화를 할 수 있었다. 😋
