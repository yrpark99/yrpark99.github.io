---
title: "Confluence 페이지 자동 생성하기"
category: [업무자동화]
toc: true
toc_label: "이 페이지 목차"
---

Confluence 페이지를 자동으로 생성하는 툴을 작성하였다.

## 동기
팀 회의를 위하여 매주마다 지난 주 Confluence 회의 페이지를 복사해서 이번 주 Confluence 페이지를 생성하고, 지난 주 페이지는 년도별 페이지로 이동시키는 반복 업무가 있어서, 이를 간단히 Python으로 자동화를 구축하였다.  
추후에 Confluence 관련한 자동화 툴을 작성할 필요가 있을 때에 참조하기 위하여 간략히 기록을 남긴다.

## Confluence REST API
Confluence는 REST API를 지원한다.  
관련 문서는 Cloud 서버를 사용하는 경우에는 [Confluence Cloud Reference](https://developer.atlassian.com/cloud/confluence/rest/v2/) 페이지에서 확인할 수 있고, on-premise로 운영하는 경우에는 웹 주소가 다를 수 있을텐데, 내 회사 같은 경우에는 [https://{Confluence_URL}/rest/api/content/](https://{Confluence_URL}/rest/api/content/) 페이지에서 확인할 수 있었다.

## Confluence 액세스
Confluence에 액세스하기 위해서는 PAT(Personal Access Token)가 필요한데, 이것은 웹브라우저로 Confluence에 로그인 한 후에 메뉴 상에서 생성할 수 있다.  
<br>

PAT를 authentication에 사용하기 위해서는 REST API 호출시 Authorization header에서 bearer token으로 사용하면 하는데, 아래와 같은 형식으로 사용할 수 있다.
```sh
curl -H "Authorization: Bearer <yourToken>" https://{Confluence_URL}/rest/api/content
```
<br>
이후에는 REST API 사용이 가능해지는데, 모든 액세스를 REST API로 구현하는 것은 너무 번거로우므로, 해당 언어에서 Confluence 패키지를 찾아서 이용하는 것이 편리하다. 여기서는 Python과 Atlassian의 Confluence 패키지를 이용하여 구현하였다.

## 패키지 설치
아래와 같이 atlassian-python-api 패키지를 설치한다.
```sh
$ pip3 install atlassian-python-api
```

## Confluence 로그인 설정 예제
```python
#!/usr/bin/env python3

from atlassian import Confluence
from atlassian.errors import ApiError

# Confluence 관련 설정
CONFLUENCE_URL = ""
USER_PAT = ""
CONFLUENCE_TOP_PAGE_ID = ""

# Confluence 객체 초기화
confluence = Confluence(
    url = CONFLUENCE_URL
)
confluence.session.headers.update({
    "Authorization": f"Bearer {USER_PAT}"
})
```

## Confluence 페이지 읽기 예제
```python
import re
from datetime import datetime, timedelta

def get_last_week_page() -> tuple[str, str, str]:
    # Top 페이지에서 모든 하위 페이지 ID를 얻는다.
    page_ids = confluence.get_child_id_list(CONFLUENCE_TOP_PAGE_ID)
    if not page_ids:
        print(f"Failed to get top top page ID {CONFLUENCE_TOP_PAGE_ID}")
        return "", "", ""

    # 모든 하위 페이지 ID를 순회하면서 지난 주 타겟 페이지를 찾아서 해당 정보를 리턴한다.
    for page_id in page_ids:
        # 해당 페이지 ID의 정보를 얻는다.
        page = confluence.get_page_by_id(page_id, expand="body.storage,space")
        if page is None:
            print(f"Failed to get page ID {page_id}")
            continue
        title = page["title"]

        # "YYYY-MM-DD Wnn XXX 회의" 제목이고 올바른 날짜이면, 해당 페이지의 page ID, title, body를 리턴한다.
        if re.match(r"^\d{4}-\d{2}-\d{2} W\d{1,2} XXX 회의$", title):
            # 제목에 있는 년월일이 오늘 지난주 날짜가 맞는지 검사한다.
            if not is_last_week_title(title):
                continue

        # 지난 주 타겟 페이지이면 해당 페이지의 page ID, title, body를 리턴한다.
        body = page["body"]["storage"]["value"]
        return page_id, title, body

    # 지난 주 타겟 페이지를 찾지 못한 경우
    return "", "", ""

def is_last_week_title(title: str) -> bool:
    parts = title.split(" ")
    if len(parts) < 3:
        return False
    last_week_date_str = parts[0]
    last_week_date = datetime.strptime(last_week_date_str, "%Y-%m-%d")
    this_week_monday = last_week_date + timedelta(days=3)
    this_week_saturday = last_week_date + timedelta(days=8)

    # 오늘 날짜가 이번 주 범위에 있는지 검사한다.
    today = datetime.today()
    if today >= this_week_monday and today < this_week_saturday:
        return True
    return False
```

## Confluence 페이지 생성 예제
```python
def create_this_week_page(title: str, body: str) -> str:
    # Top 페이지에서 공간 키를 얻는다.
    page = confluence.get_page_by_id(CONFLUENCE_TOP_PAGE_ID, expand="body.storage,space")
    if page is None:
        print(f"Failed to get top page ID {CONFLUENCE_TOP_PAGE_ID}")
        return ""
    space_key = page["space"]["key"]

    # Top 페이지에 이번 주 타겟 페이지를 생성한다.
    response = confluence.create_page(space=space_key, title=title, body=body, parent_id=CONFLUENCE_TOP_PAGE_ID, representation="storage")
    if response is None:
        print("Failed to create this week page")
        return ""
    created_page_id = response["id"]
    return created_page_id
```

## Confluence 페이지 이동 예제
```python
def move_last_week_page(last_week_page_id: str) -> bool:
    year_page_id = ""
    try:
        page = confluence.get_page_by_id(last_week_page_id, expand="body.storage,space")
        if page is None:
            print(f"Failed to get page ID {last_week_page_id}")
            return False
        space_key = page["space"]["key"]
        title = page["title"]

        # 지난 주 타겟 타이틀에서 날짜와 Week 값을 추출한다.
        parts = title.split(" ")
        if len(parts) < 3:
            return False
        last_week_date_str = parts[0]
        year = last_week_date_str.split("-")[0]
        year_title = f"{year}년"

        # Top 페이지에서 하위 페이지의 제목이 해당 년도인 페이지를 찾는다.
        titles = confluence.get_child_title_list(CONFLUENCE_TOP_PAGE_ID)
        for title in titles:
            if title == year_title:
                year_page_id = confluence.get_page_id(space_key, title)
                break
    except ApiError as err:
        print("Exception:", err)
        return False

    # 해당 년도의 페이지 ID가 없으면 해당 년도의 페이지를 새로 생성한다. (해당 년도의 첫번째 주인 경우임)
    if year_page_id == "":
        response = confluence.create_page(space_key, year_title, "", CONFLUENCE_TOP_PAGE_ID)
        if response is None:
            print(f"Failed to create {year_title} page")
            return False
        year_page_id = response["id"]

    # 지난 주 타겟 페이지를 해당 년도의 페이지로 이동시킨다.
    response = confluence.move_page(space_key, last_week_page_id, target_id=year_page_id)
    if response is None:
        print("Failed to move last week page")
        return False
    return response["successful"]
```

## 자동 호출 등록하기
예를 들어 매주 월요일 오전 8시에 파이썬 파일이 자동으로 실행되도록 하는 경우이다.  

Linux에서는 `crontab -e` 명령을 실행한 후에, crontab에 아래 예와 같이 추가하면 된다.
```sh
0  8  *  *  1  python3 파이썬파일경로
```

Windows에서는 콘솔에서 아래 예와 같이 실행하면 작업 스케줄러에 추가된다.
```sh
schtasks /CREATE /TN "스케쥴러이름" /SC WEEKLY /D MON /ST 08:00 /TR "cmd /C 'python 파이썬파일경로'"
```
