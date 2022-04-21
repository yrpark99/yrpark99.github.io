---
title: "Markdown 파일을 PDF로 변환하기"
category: Markdown
toc: true
toc_label: "이 페이지 목차"
---

Markdown 파일을 PDF로 변환하는 방법을 정리한다.

<br>
소스 코드 저장소에는 Markdown(.md) 파일로 관리하지만, 이를 외부에 배포할 때에는 당연히 Markdown 파일보다는 PDF 파일로 변환하여 배포하는 것이 더 좋다.  
이때 Markdown 파일을 PDF 파일로 변환할 필요가 있는데, 변환 방법에는 여러 가지가 있겠지만, 일단 간단히 아래와 같이 정리해 보았다.

## 온라인 Markdown 변환 서비스 이용
간단한 방법이기는 하지만 보통 세부적인 설정이 안 되는 문제점이 있다. 예를 들어 아래와 같은 웹사이트가 있다.
* [Aspose Markdown-PDF 변환기](https://products.aspose.app/words/conversion/markdown-to-pdf)

## Pandoc 툴 이용
통합 문서 변환기인 [pandoc](https://pandoc.org/) 툴을 이용하는 방법이다. 소스는 [pandoc](https://github.com/jgm/pandoc) 저장소에 있고, 우분투에서는 아래와 같이 설치할 수 있다.
```shell
$ sudo apt install pandoc
```
Markdown 파일을 PDF로 변환하려면 사용할 PDF 엔진 타입에 필요한 패키지를 추가로 설치해야 한다. 예를 들어 **wkhtmltopdf** 엔진을 사용하려면 아래와 같이 패키지를 설치한다.
```shell
$ sudo apt install wkhtmltopdf
```
이후 아래 예와 같이 변환할 수 있다.
```shell
$ pandoc <입력_마크다운_파일> -f markdown --pdf-engine=wkhtmltopdf -o <출력_PDF_파일>
```
이 방법은 Markdown, PDF 이외에도 다양한 문서 포맷을 지원하지만, 세부적인 설정이 어렵다는 단점이 있다.

## Python 패키지 이용
* [md2pdf](https://github.com/jmaupetit/md2pdf)
  ```shell
  $ pip3 install md2pdf
  $ md2pdf [options] <입력_마크다운_파일> <출력_PDF_파일>
  ```
  **[options]**에는 `--css`가 있다. 이 방법은 세부적인 설정이 어렵고 한글은 아예 변환되지 않았다.

## Node.js 패키지 이용
* [md-to-pdf](https://www.npmjs.com/package/md-to-pdf)
  ```shell
  $ sudo apt install libnss3-dev libgbm-dev libasound2
  $ sudo npm install -g md-to-pdf
  $ md-to-pdf [options] <입력_마크다운_파일>
  ```
  **[options]**에는 `--stylesheet`, `--highlight-style`, `--pdf-options`, `--md-file-encoding` 등이 있다. 그런데 한글은 아예 변환되지 않았다.
* [mdpdf](https://www.npmjs.com/package/mdpdf)
  ```shell
  $ sudo npm install -g mdpdf
  $ mdpdf [options] <입력_마크다운_파일>
  ```
  **[options]**에는 `--stylesheet`, `--css`, `--md-file-encoding` 등이 있다. 그런데 한글은 아예 변환되지 않았다.

## Markdown 전용 에디터 이용
### 온라인 Markdown 에디터 이용
간단한 방법이기는 하지만 보통 세부적인 설정이 안 되는 문제점이 있다. 예를 들어 [Dillinger](https://dillinger.io/)와 같은 웹사이트가 있다.

### [Typora](https://typora.io/) 이용
버전 1.0 이전까지 내가 필요시 이용하던 방법으로 [PlantUML](https://plantuml.com/ko/) 등은 변환되지 않았지만, PDF 품질이 좋은 편이었다. 그런데 버전 1.0 이후로 유료(💰)로 변경되면서 더 이상 사용하지 않게 되었다.  

### [VNote](https://github.com/vnotex/vnote) 이용
간혹 이용하던 방법 중의 하나로, PlantUML도 제대로 나오고, 세부 설정도 가능한 방법이다.  
참고로 디폴트로 코드 블록 안에서 줄 번호가 표시되는데, 줄 번호를 안 나오게 하려면 아래와 같이 하면 된다.  
1. `%APPDATA%\vnote\VNote\web\js\prism\prism.min.js` 파일을 열어서 [Prism](https://prismjs.com/) 페이지에서 사용한 설정 정보를 찾는다.
1. 이 URL 전체를 브라우저로 열면 Prism에서 사용한 config가 뜬다.
1. 여기에서 **Plugins** 중에 `Line Numbers` 항목을 끈 후, **DOWNLOAD JS** 버튼을 누르면 prism.js 파일이 받아진다. (즉, 디폴트 config에서 줄 번호만 disable 시킨 것임)
1. 이것을 prism.min.js 이름으로 바꿔서 원래 파일에 덮어쓰면 된다.

## 에디터에서 Markdown 플러그인 이용
### VSCode
VSCode에서 Markdown 파일을 작성한 후 (물론 preview를 보면서), PDF로 변환이 필요하면 [Markdown PDF](https://marketplace.visualstudio.com/items?itemName=yzane.markdown-pdf)와 같은 익스텐션을 이용하여 PDF export 하는 방법으로 내가 가장 애용하는 방법이다.  
참고로 아래는 내가 **settings.json** 파일에서 추가로 설정한 내용들이다.
```json
"markdown-pdf.breaks": true,
"markdown-pdf.displayHeaderFooter": false,
"markdown-pdf.highlightStyle": "atom-one-dark.css",
"markdown-pdf.includeDefaultStyles": false,
"markdown-pdf.margin.left": "1.5cm",
"markdown-pdf.margin.right": "1.5cm",
"markdown-pdf.margin.top": "1.5cm",
"markdown-pdf.margin.bottom": "1.5cm",
"markdown-pdf.plantumlCloseMarker": "```",
"markdown-pdf.plantumlOpenMarker": "```plantuml",
"markdown-pdf.scale": 0.85,
"markdown-pdf.styles": [
    "doc/markdown-pdf.css"
],
```

또 위 설정에서 명시한 바와 같이 프로젝트의 하위 **doc** 디렉토리에는 markdown-pdf.css 파일을 넣었는데, 이 파일의 내용은 아래와 같이 작성하여 내 취향에 맞는 PDF 파일을 얻었다. (참고로 이 익스텐션은 중간 파일로 html을 사용하고 있어서 이 html 파일을 이용하여 css를 수정하였음)
```css
/* body */
body {
    margin: 20px auto;
    width: 800px;
    background-color: #fff;
    color: #222222;
    font-family: 'malgun-gothic', Arial, sans-serif;
    font-size: 14px;
    line-height: 150%;
}

/* links */
a:link {
    color: #00f;
    text-decoration: none;
}

/* blockquote */
blockquote {
	margin: 0px;
	padding: 0 5px 0 5px;
	border-left: 5px solid;
	background: rgba(127, 127, 127, 0.1);
    border-color: rgba(0, 122, 204, 0.5);
}

/* html tags */

* html code {
    font-size: 101%;
}

* html pre {
    font-size: 101%;
}

/* code */

pre,
code {
    font-size: 14px;
    font-family: D2Coding, Consolas, Monaco, monospace;
}

pre {
    margin-top: 3px;
    margin-bottom: 5px;
    border: 1px solid #c7cfd5;
    border-radius: 3px;
    background: #f1f5f9;
    margin: 2px 0 5px 0;
    padding: 5px;
    text-align: left;
    overflow-x: auto;
	white-space: pre-wrap;
	overflow-wrap: break-word;
}

code {
    line-height: 150%;
}

hr {
    height: 12px;
    border: 0;
    box-shadow: inset 0 12px 12px -12px rgba(0, 0, 0, 0.5);
}

/* for inline code */
:not(pre):not(.hljs) > code {
    background: #f2f4f4;
    border: 1px solid #e7e9ec;
    border-radius: 3px;
    color: rgb(102, 5, 117);
    font-family: D2Coding, Consolas, Monaco, monospace;
    font-size: inherit;
    padding: 0 0.1em;
    overflow-x: auto;
    white-space: pre-wrap;
}

/* headers */

h1,
h2,
h3,
h4,
h5,
h6 {
    font-family: 'malgun-gothic', Arial, serif;
    font-weight: bold;
    color: #111111;
}

h1 {
    margin-top: 1em;
    margin-bottom: 20px;
    font-weight: bold;
    font-size: 28px;
    border-bottom: 0;
}

h1 {
    background-image: linear-gradient(
        to right,
        rgba(0, 0, 0, 0),
        rgba(0, 0, 0, 0.75),
        rgba(0, 0, 0, 0)
    );
    background-position: 0 100%;
    background-repeat: no-repeat;
    background-size: 100% 1px;
    padding-bottom: 8px;
}

h2 {
    margin-top: 1.6em;
    margin-bottom: 15px;
    font-size: 24px;
    padding-bottom: 2px;
    border-bottom: 1px solid #efeaea;
}

h3 {
    margin-top: 1.5em;
    margin-bottom: 0.5em;
    font-size: 20px;
}

h4 {
    margin-top: 1.5em;
    margin-bottom: 0.5em;
    font-size: 16px;
}

h5 {
    margin-top: 20px;
    margin-bottom: 0.5em;
    padding: 0;
    font-size: 12px;
}

h6 {
    margin-top: 20px;
    margin-bottom: 0.5em;
    padding: 0;
    font-size: 10px;
}

p {
    margin-top: 0px;
    margin-bottom: 3px;
}

/* lists */

ul {
    margin: 0 0 0 30px;
    padding: 0 0 12px 6px;
}

li {
    margin-top: 6px;
}

ol {
    list-style-type: decimal;
    list-style-position: outside;
    margin: 0 0 0 30px;
    padding: 0 0 12px 6px;
}

ol ol {
    list-style-type: lower-alpha;
    list-style-position: outside;
    margin: 7px 0 0 30px;
    padding: 0 0 0 6px;
}

ul ul {
    margin-left: 30px;
    padding: 0 0 0 6px;
}

li > p {
    display: inline;
}

li > p + p {
    display: block;
}

li > a + p {
    display: block;
}

/* table */

table {
    width: 100%;
    border-top: 1px solid #919699;
    border-left: 1px solid #919699;
    border-spacing: 0;
}

table th {
    padding: 4px 8px 4px 8px;
    background: #e2e2e2;
    font-size: 18px;
    border-bottom: 1px solid #919699;
    border-right: 1px solid #919699;
}

table th p {
    font-weight: bold;
    margin-bottom: 0px;
}

table td {
    padding: 8px;
    font-size: 15px;
    vertical-align: top;
    border-bottom: 1px solid #919699;
    border-right: 1px solid #919699;
}

table td p {
    margin-bottom: 0px;
}

table td p + p {
    margin-top: 5px;
}

table td p + p + p {
    margin-top: 5px;
}

/* forms */

form {
    margin: 0;
}

button {
    margin: 3px 0 10px 0;
}

input {
    vertical-align: middle;
    padding: 0;
    margin: 0 0 5px 0;
}

select {
    vertical-align: middle;
    padding: 0;
    margin: 0 0 3px 0;
}

textarea {
    margin: 0 0 10px 0;
    width: 100%;
}
```

## 결론
Markdown 파일을 품질 좋은 PDF 파일로 변환하기가 쉽지가 않은데, 이렇게 정리하고 공유하여서 누군가에게는 도움이 될 것으로 생각한다. 😊
