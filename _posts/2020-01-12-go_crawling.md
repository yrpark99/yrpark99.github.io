---
title: "Go 언어로 crawling 테스트"
category: Go
toc: true
toc_label: "이 페이지 목차"
---

파이썬과 유사하게 Go 언어로 crawling 테스트를 해 보았다.

## 크롤링
보통 크롤링은 Python을 이용하여 쉽게 할 수 있는데, 이것의 단점이라면 실행 파일로 만들었을 때 실행 파일의 크기가 크고, 실행 속도가 느리다는 것이다.  
반면에 Go 언어를 이용해서도 마찬가지로 crawling을 쉽게 할 수 있는데, Python 보다는 적은 실행 파일 크기, 보다 빠른 실행 속도가 장점이다.

## 네이버 급상승 검색어 순위 얻기 예
html 파싱을 위해서는 Python에서는 BeautifulSoup 패키지를 많이 사용하는데 Go에서는 goquery 패키지를 사용할 수 있다. (아래 예에서는 Linux인 경우의 예를 들었지만, 다른 OS에서도 마찬가지임)

아래 명령을 실행하여 해당 패키지를 다운받는다.
```sh
$ go get github.com/PuerkitoBio/goquery
```
test.go 파일을 아래 예와 같이 작성한다. (물론 추후 Naver 페이지가 개편되어 급상승 검색어 순위를 출력하는 방식이 변경되면, 아래 예도 이에 맞추어서 변경이 필요할 것임)
```go
package main

import (
    "fmt"
    "net/http"
    "github.com/PuerkitoBio/goquery"
)

func main() {
    res, err := http.Get("https://www.naver.com/")
    if err != nil {
        fmt.Println("Error: ", err)
        return
    }
    defer res.Body.Close()

    doc, err := goquery.NewDocumentFromReader(res.Body)
    if err != nil {
        fmt.Println("Error: ", err)
        return
    }

    doc.Find("span.ah_k").Each(func(i int, s *goquery.Selection) {
        fmt.Println(i + 1, "위: " + s.Text())
    })
}
```
이제 아래와 같이 실행할 수 있다.  (또는 빌드 후에 실행시킬 수도 있음)
```sh
$ go run test.go
```

## 웹 페이지에 자동 로그인 구현하기 예
자동 로그인 등을 위해서는 Python에서는 selenium 패키지를 많이 사용하는데, Go에서는 이를 위해 agouti 패키지를 사용할 수 있다.

아래 명령을 실행하여 해당 패키지를 다운받는다.
```sh
$ go get github.com/sclevine/agouti
```
> 추가로 Headless(No GUI)를 위해서는 PhantomJS, GUI를 위해서는 Chrome driver가 설치되어 있어야 한다. (보통 개발할 때는 GUI 모드로 눈으로 확인하면서 개발하고, 개발이 완료되면 Headless 모드로 변환시키는 것이 편리함)

test.go 파일을 아래 예와 같이 작성한다.
```go
package main

import (
    "fmt"
    "strings"
    "github.com/sclevine/agouti"
)

func main() {
    headless := true
    var driver *agouti.WebDriver
    if headless == true {
        driver = agouti.PhantomJS()
    } else {
        driver = agouti.ChromeDriver()
    }

    if err := driver.Start(); err != nil {
        fmt.Println("Failed to start driver:", err)
        driver.Stop()
        return
    }

    page, err := driver.NewPage()
    if err != nil {
        fmt.Println("Failed to open page:", err)
        driver.Stop()
        return
    }
    if err := page.Navigate("home_page_address"); err != nil {
        fmt.Println("Failed to navigate:", err)
        driver.Stop()
        return
    }
    page.FindByID("user_id").SendKeys("your_id")
    page.FindByID("user_password").SendKeys("your_password")
    page.FindByID("login_button").Click()

    html, err := page.HTML()
    doc, err := goquery.NewDocumentFromReader(strings.NewReader(html))

    // ...
    driver.Stop()
}
```
> 위 예에서 user ID, password, login 버튼에 해당하는 실제 ID와 값으로 세팅해야 한다.
> 이후 html 파싱이 필요하면 위의 예처럼 PuerkitoBio/goquery 패키지를 이용할 수 있다.

이제 아래와 같이 실행할 수 있다.  (또는 빌드 후에 실행시킬 수도 있음)
```sh
$ go run test.go
```
