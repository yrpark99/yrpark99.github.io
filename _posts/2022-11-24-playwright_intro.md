---
title: "Web 자동화 툴 Playwright 소개"
category: Web
toc: true
toc_label: "이 페이지 목차"
---

웹 페이지 자동화 시 Selenium을 대체할 수 있는 Playwright 소개  
<br>

웹 페이지 자동화 시에 보통 [Selenium](https://www.selenium.dev/)을 많이 사용하는데, 오랜만에 웹 페이지 자동화를 하려고 알아보다가 [Playwright](https://playwright.dev/)를 발견하였다.  
Playwright는 마이크로소프트가 2020년 경에 공개한 오픈 소스로 점점 많이 사용되는 것 같다. 나는 이번에 연습 삼아 간단히 사용해 보았는데, Selenium 보다 좋은 것 같아서 소개해 본다.

## Playwright 소개
* 홈페이지: [https://playwright.dev/](https://playwright.dev/)
* 문서: [TypeScript 용 문서](https://playwright.dev/docs/intro), [Python 용 문서](https://playwright.dev/python/docs/intro)
* Playwright 소스: [TypeScript 용 Playwright](https://github.com/microsoft/playwright), [Python 용 Playwright for Python](https://github.com/microsoft/playwright-python)
* VS Code 용 익스텐션: [Playwright Test for VS Code](https://marketplace.visualstudio.com/items?itemName=ms-playwright.playwright)
* 특징
  - 멀티플랫폼 지원
  - TypeScript, Python, Java, .NET 등의 언어 지원

## Playwright 설치
아래에서는 Linux에서 Python인 경우의 예로, 다른 플랫폼에서 다른 언어를 사용하는 경우는 적절히 알맞게 맞추자.  
Playwright 패키지는 아래와 같이 설치할 수 있다.
```sh
$ pip install playwright
```
이후 아래와 같이 실행하면 추가로 필요한 패키지(예: Chromium, FFMPEG, Firefox, Webkit) 들이 설치된다.
```sh
$ playwright install
```

## Generator 실행
아래와 같이 Generator를 실행시킬 수 있다.
```sh
$ playwright codegen <url>
```
결과로 브라우저에서 행하는 동작을 바탕으로 소스 코드를 생성해 주므로, 필요한 부분을 복사하여 사용할 수 있다.

## Playwright 장점
간단히 Playwright를 사용해 보았는데 일단 Selenium 보다 다음 사항들이 더 좋았다.
* Playwright는 자체적으로 웹브라우저를 설치하여 사용하므로 시스템에 설치된 웹브라우저 종류/버전과 관계없이 정상 동작하였다. (반면에 Selenium은 시스템에 설치된 웹브라우저를 사용하고 이것과 버전까지 일치하는 Selenium 드라이버를 다운로드해서 사용해야 하는 불편함이 있음)
  > ℹ️ 참고로 Selenium에서 이 불편함을 해소하기 위해서 [webdriver_manager](https://pypi.org/project/webdriver-manager/) 패키지를 이용하면 드라이버 다운로드를 자동화 할 수 있다.
* 웹페이지가 로딩될 때까지 기다리는 것이 간단하게 구현되었다.
* 소스 코드 Generator 툴인 `codegen`을 이용하여 간단히 기본 코드를 구성할 수 있었다.

## 사용 예제 1
회사 정책으로 매일 Redmine에서 나에게 할당된 프로젝트의 이슈에서 작업 시간을 기록해야 하는데, 이 단순 작업을 하기가 귀찮아서 이것을 자동화해 보았다.  
사용자마다 Redmine ID/PW가 다르고, 할당된 프로젝트 모델이 다르므로, 이를 소스 코드에서 하드 코딩하지 않기 위하여 아래와 같이 JSON 파일을 구성하였다. (파일 이름은 **user_issue.json**으로 함)
```json
{
    "user": {
        "USER_ID": "",
        "USER_PW": ""
    },
    "issue": {
        "TARGET_MODEL": ""
    }
}
```
이후 아래 예와 같이 Python 코드를 작성하였다. (아래는 블로그 참조용으로 내 최종 코드와는 일부 다름)
```python
import json
import re
import sys
import time
from playwright.sync_api import Playwright, Page, sync_playwright, expect

USER_JSON_FILE = "user_issue.json"
HR_ATTENDANCE = "인사시스템_근태_URL"
REDMINE_SERVER = "Redmine_서버_주소"
REDMINE_URL = REDMINE_SERVER + "/redmine"

def get_user_issue_info():
    global USER_ID
    global USER_PW
    global TARGET_MODEL

    # JSON 파일을 연다.
    try:
        json_file = open(USER_JSON_FILE)
    except FileNotFoundError:
        print('"' + USER_JSON_FILE + '" 파일을 읽을 수 없습니다.')
        sys.exit(1)

    # JSON 파일로부터 user 정보, issue 정보를 읽는다.
    json_data = json.load(json_file)
    try:
        USER_ID = json_data['user']['USER_ID']
        USER_PW = json_data['user']['USER_PW']
        TARGET_MODEL = json_data['issue']['TARGET_MODEL']
    except KeyError:
        print('"' + USER_JSON_FILE + '" 파일이 올바르게 구성되어 있지 않습니다.')
        sys.exit(1)

    # JSON 파일을 닫는다.
    json_file.close()

def get_start_work_time(page: Page) -> int:
    start_work_hour = 0
    start_work_hm = 0

    # 인사 시스템의 근태정보 페이지에 접속해서 오늘 날짜의 출근 시각을 얻는다.
    page.goto(HR_ATTENDANCE)
    page.wait_for_url(HR_ATTENDANCE)
    now = time.localtime()
    month_str = "%02d" % now.tm_mon
    day_str = "%02d" % now.tm_mday
    today_str = str(now.tm_year) + "-" + month_str + "-" + day_str
    try:
        ten_days_attendance = page.locator("xpath=/html/body/div[2]/div[2]/div/div[2]/div[3]/table/tbody").element_handle(timeout=500).inner_text()
    except:
        print("인사 시스템으로부터 출근 정보를 얻지 못했습니다.")
        return 0
    daily_attendance = ten_days_attendance.splitlines()
    for attendance in daily_attendance:
        if attendance.find(today_str) == -1:
            continue
        today_attendance = attendance.split()
        if len(today_attendance) < 10:
            continue
        start_work_str = today_attendance[9].split(sep=':')
        start_work_hour = int(start_work_str[0])
        start_work_min = int(start_work_str[1])
        start_work_hm = start_work_hour * 60 + start_work_min
    if start_work_hm == 0:
        print("인사 시스템에서 오늘 날짜의 출근 정보를 발견하지 못했습니다.")
        return 0

    # 현재 시각과 출근 시각으로 작업 시간을 얻는다. (단, 점심 시간, 저녁 시간은 작업 시간에서 제외)
    now_hm = now.tm_hour * 60 + now.tm_min
    work_hm = now_hm - start_work_hm
    if start_work_hour < 12:
        if now.tm_hour == 12:
            work_hm -= now.tm_min
        elif now.tm_hour >= 13:
            work_hm -= 60
    if start_work_hour < 18:
        if now.tm_hour == 18:
            work_hm -= now.tm_min
        elif now.tm_hour >= 19:
            work_hm -= 60

    # 작업 시간을 시간 단위로 리턴한다.
    work_hour = int(work_hm / 60)
    return work_hour

def set_redmine_work_time():
    playwright = sync_playwright().start()

    # 브라우저를 생성한다.
    browser = playwright.chromium.launch(headless=False)
    context = browser.new_context()
    page = context.new_page()

    # 오늘의 작업 시간을 얻는다.
    work_hour = get_start_work_time(page)

    # Redmine 사이트에 접속한 후 로그인한다.
    page.goto(REDMINE_URL + "/login")
    page.get_by_label("로그인:").fill(USER_ID)
    page.get_by_label("비밀번호:").fill(USER_PW)
    page.get_by_role("button", name=re.compile("로그인")).click()
    try:
        page.wait_for_url(REDMINE_URL + "/my/page", timeout=1000)
    except:
        print("Redmine에 로그인하지 못하였습니다. ID/PW가 맞는지 확인해 주세요.")
        sys.exit(1)

    # "프로젝트" 링크를 클릭한다.
    page.get_by_role("link", name="프로젝트").click()
    page.wait_for_url(REDMINE_URL + "/projects")

    # 타겟 모델로 이동한다. (타겟 모델이 없으면 종료)
    try:
        target_model = page.get_by_role("link", name=TARGET_MODEL).element_handle(timeout=500).get_attribute("href")
    except:
        print('타겟 모델 "' + TARGET_MODEL + '"를 찾을 수 없습니다.')
        sys.exit(1)
    target_model_link = REDMINE_SERVER + str(target_model)
    page.get_by_role("link", name=TARGET_MODEL).click()
    page.wait_for_url(target_model_link)

    # "일감"을 클릭한 후, 검색조건을 담당자로 선택해서 적용한다.
    page.get_by_role("link", name="일감").click()
    page.wait_for_url(target_model_link + "/issues")
    page.get_by_role("combobox", name="검색조건 추가").select_option("assigned_to_id")
    page.get_by_role("link", name="적용").click()
    page.wait_for_load_state("load")

    # 이슈 리스트에서 나에게로 할당된 첫번째 이슈를 타겟 이슈로 간주하고, 이 이슈의 첫번째 칼럼에서 이슈 번호를 얻는다.
    try:
        issue_text = page.locator("xpath=/html/body/div/div[2]/div[1]/div[3]/div[2]/form[2]/div/table/tbody").element_handle(timeout=500).inner_text().split()
    except:
        print("타겟 이슈를 찾을 수 없습니다.")
        sys.exit(1)
    issue_num = issue_text[0]

     # 이슈 번호를 클릭한다.
    page.get_by_role("link", name=issue_num).click()
    page.wait_for_url(REDMINE_URL + "/issues/" + issue_num)

    # "작업시간 기록" 링크를 클릭한다.
    page.get_by_role("link", name="작업시간 기록").nth(1).click()
    page.wait_for_url(REDMINE_URL + "/issues/" + issue_num + "/time_entries/new")

    # "시간"을 입력한다.
    page.get_by_role("textbox", name="시간 *").fill(str(work_hour))

    # "작업종류"를 선택한다.
    page.get_by_role("combobox", name="작업종류 *").select_option("9")

    # 사용자가 "만들기" 버튼을 클릭할 때까지 무한 대기한다. (이 버튼을 클릭하면 "생성 성공" 메시지가 출력됨)
    page.get_by_role("button", name="만들기").focus()
    print('내용 확인 후에 브라우저에서 "만들기" 버튼을 클릭해 주세요.')
    try:
        expect(page.get_by_text("생성 성공")).to_be_visible(timeout=0)
    except KeyboardInterrupt:
        playwright.stop()
        sys.exit(1)
    except:
        context.close()
        browser.close()
        playwright.stop()
        sys.exit(1)

    # 5초 후 종료한다.
    time.sleep(5)
    context.close()
    browser.close()
    playwright.stop()

if __name__ == '__main__':
    get_user_issue_info()
    set_redmine_work_time()
```

## 사용 예제 2
회사 인증 모델들에서 각 모델별로 인증서가 EOL(End Of Life) 되는 경우를 사전에 체크하여 담당팀으로 알람 메일을 보내는 기능을 구현하였다.  
먼저 아래와 같이 **config.json** 이름으로 설정 파일을 작성하였다. (아래에서는 실제 정보들은 의도적으로 비웠음)
```json
{
    "advance_day": 90,
    "user": {
        "user_id": "",
        "user_pw": ""
    },
    "mail": {
        "to": ""
    },
    "models": [
        ""
    ]
}
```
아래와 같이 코드를 작성하였다. (마찬가지로 실제 정보들은 비웠음)
```python
#!/usr/bin/python3
import json
import smtplib
import sys

from datetime import datetime, timedelta
from playwright.sync_api import sync_playwright
from email.mime.text import MIMEText
from typing import List

global NOTIFY_ADVANCE_DAY, no_product_models
global playwright, browser, context, page

# 설정 파일
MODELS_JSON_FILE = "config.json"

def get_configuration() -> None:
    '''JSON 파일로부터 각종 설정 정보를 얻는다.'''
    global NOTIFY_ADVANCE_DAY, USER_ID, USER_PW, mail_to, no_product_models

    # 설정 JSON 파일을 연다.
    try:
        json_file = open(MODELS_JSON_FILE, encoding="UTF-8")
    except FileNotFoundError:
        print(f"{MODELS_JSON_FILE} file is not found")
        sys.exit(1)

    # JSON 파일로부터 사전일, 유저 정보, 양산 중단된 모델 정보를 얻는다.
    json_data = json.load(json_file)
    try:
        NOTIFY_ADVANCE_DAY = json_data['advance_day']
        USER_ID = json_data['user']['user_id']
        USER_PW = json_data['user']['user_pw']
        mail_to = json_data['mail']['to']
        no_product_models = json_data['models']
    except KeyError:
        print(f"{MODELS_JSON_FILE} file is wrong")
        sys.exit(1)

    # JSON 파일을 닫는다.
    json_file.close()

def get_total_models_info() -> List[str]:
    '''전체 인증 모델 정보를 얻어서 리턴한다.'''
    global USER_ID, USER_PW
    global no_product_models
    global playwright, browser, context, page

    # 인증 페이지에 로그인한다.
    page.goto("")
    page.get_by_label("Username").fill(USER_ID)
    page.get_by_label("Password").fill(USER_PW)
    page.get_by_role("button", name="Logon").click()

    # 인증 모델별 인증 만료일 정보 페이지로 이동한다.
    page.goto("")

    # 테이블 정보를 얻어서 각 줄로 나누어서 문자열 리스트에 저장한다.
    table_rows = page.locator("body > div > table:nth-child(4)").inner_text().splitlines()

    return table_rows

def get_alarm_models(models_info: list) -> str:
    '''입력 모델들에서 인증서 만료일을 확인하여 만료되었거나 곧 만료될 모델들의 정보를 얻어서 리턴한다.'''
    global NOTIFY_ADVANCE_DAY, no_product_models
    expire_models = ""

    # 오늘 날짜를 얻는다.
    today = datetime.now()

    # 테이블 모델 시작 줄부터 각 줄을 파싱하면서, 만료일을 확인하여 만료되었거나 곧 만료될 모델들의 정보를 expire_models에 저장한다.
    for model in models_info[1:]:
        # 해당 줄 내용을 tab 문자로 나눈 후, 모델 이름, OP 이름, 인증서 만료일 정보를 얻는다. (인증서 만료일이 없는 모델은 무시한다)
        model_item = model.split("\t")
        model_name = model_item[2]
        op_name = model_item[3]
        expire_date_str = model_item[4]
        try:
            expire_date = datetime.strptime(expire_date_str, "%d %b %Y")
        except ValueError:
            continue

        # 사전 만료일(사전 알람 메일 시작일)을 구한다.
        advance_expire_date = expire_date - timedelta(days=NOTIFY_ADVANCE_DAY)

        # 오늘이 아직 사전 만료일을 지나지 않았으면 알람 대상 모델이 아니다.
        if today <= advance_expire_date:
            continue

        # 양산 중단된 모델이면 알람 대상에서 제외시킨다.
        if model_name in no_product_models:
            continue

        # 알람 대상 모델이면 관련 정보를 저장한다.
        expire_models += " - Model: " + model_name + ", OP: " + op_name + ", Expire date: " + expire_date.strftime("%Y-%m-%d")
        if today > expire_date:
            expire_models += " (EOL 되었음)<br>"
        else:
            expire_models += " (%d 일 후에 EOL 됨)<br>" % ((expire_date - today).days + 1)

    return expire_models

def open_web_browser() -> None:
    '''Playwright로 웹 브라우저를 생성한다.'''
    global playwright, browser, context, page

    playwright = sync_playwright().start()
    browser = playwright.chromium.launch(headless=True)
    context = browser.new_context()
    page = context.new_page()

def close_web_browser() -> None:
    '''Playwright로 생성된 웹 브라우저를 종료시킨다.'''
    global playwright, browser, context

    context.close()
    browser.close()
    playwright.stop()

def send_mail(mail_body: str) -> None:
    '''입력 메일 본문 내용을 바탕으로 인증서 만료 알람 메일을 발송한다.'''
    global NOTIFY_ADVANCE_DAY, mail_to

    # SMTP 세션을 생성하고 (TLS 사용) 시작시킨다.
    smtp = smtplib.SMTP('smtp.gmail.com', 587)
    smtp.starttls()

    # SMTP 로그인을 한다.
    smtp.login('', '')

    # 메일 HTML 시작/종료 내용을 세팅한다. (폰트 종류, 크기, 색깔 설정)
    mailBodyHtmlHead = ""
    mailBodyHtmlTail = ""

    # 메일 시작 및 종료 내용을 세팅한다.
    sayHello = ""
    sayGoodbye = ""

    # HTML을 포함하는 메일 본문 내용을 세팅한다.
    mailBodyMsg = mailBodyHtmlHead + sayHello + mail_body + sayGoodbye + mailBodyHtmlTail

    # 보낼 메시지의 본문과 제목을 설정한다.
    msg = MIMEText(mailBodyMsg, 'html')
    msg['Subject'] = ''

    # 메일을 발송한다.
    smtp.sendmail("", mail_to, msg.as_string())

    # SMTP 세션을 종료한다.
    smtp.quit()

if __name__ == '__main__':
    get_configuration()

    open_web_browser()
    models_info = get_total_models_info()
    close_web_browser()

    alarm_models_info = get_alarm_models(models_info)
    if alarm_models_info == "":
        print("No models to notify")
        sys.exit(0)

    send_mail(alarm_models_info)
```
Linux 및 Windows에서 정상적으로 동작하는 것을 확인하였다. 매주 한 번 정해진 시각에 실행되도록 하려면 Windows의 경우에는 `작업 스케줄러`에 추가하면 되는데, 나는 편의상 Linux 서버에서 `crontab`을 이용하여 추가하였다.

## 맺음말
처음 Playwright를 사용해 봤음에도 `codegen` generator를 이용하여 쉽게 기본 코드를 구성할 수 있었고, [Python 용 문서](https://playwright.dev/python/docs/intro) 페이지를 참조하여 필요에 맞게 수정하는 데 그리 오래 걸리지 않았다.  
다만, 구글링 해보면 아직 한글로 된 자료는 별로 없었지만, 온라인 문서 페이지를 참조하니 큰 어려움 없이 구현할 수 있었다.  
Playwright를 이용하면 웹 페이지를 아주 쉽게 자동화할 수 있으므로 필요한 경우 이용해 보기를 추천한다.
