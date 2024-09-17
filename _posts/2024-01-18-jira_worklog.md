---
title: "Jira 작업 시간 기록 자동화"
category: [Python]
toc: true
toc_label: "이 페이지 목차"
---

Jira에서 일일 작업 시간 기록을 자동화하는 툴을 작성해 보았다.  
<br>

회사에서 Jira를 도입하면서 이슈별 일일 작업 시간 기록을 의무화하여, 웹브라우저에 들어가서 기록할 필요없이 편리하게 기록할 수 있는 간단한 Python 자동화 툴을 작성하여 사용 중이다.  
추후 다른 Jira 자동화 작업시에도 아래 코드를 이용하면 쉽게 구현할 수 있으므로, 간단히 기록을 남긴다.

## Jira 계정 로그인 방식
Jira 계정에 로그인하는 방식에는 다음 3가지 방식이 있다.
- basic_auth: ID와 PW를 이용한 인증 방식
- token_auth: 토큰(PAT: Personal Access Token)을 이용한 인증 방식 (**Jira Cloud**가 아닌 **self hosted**인 경우에 사용)
  > 액세스 토큰은 Jira 로그인한 후, 개인 프로파일에서 `개인용 액세스 토큰` 탭에서 만들 수 있다.
- oauth: OAuth를 이용한 인증 방식

> 주의: REST API로 여러 번 로그인이 실패한 경우에는 웹브라우저에서 CAPTCHA를 사용하여 올바르게 로그인을 해야만 이후 다시 REST API로 로그인이 된다.

## 파이썬 Jira 패키지 설치
아래 예와 같이 설치한다.
```sh
pip install jira
```

## 내 코드
아래와 같이 Python으로 작업 시간 JSON 파일을 읽어서 해당 Jira 이슈에 작업 시간을 추가하도록 구현하였다. 처음에 Jira 서버에 로그인하는 것에서 조금 애를 먹었는데, 최종적으로 token auth 방식으로 로그인하고 로그인은 1회만 시도하게 하니, 잘 동작하였다. 😋  
그 외에는 코드 자체가 간단하고 주석도 달았으므로 별도의 설명은 생략한다.
```python
# -*- coding:utf-8 -*-

import datetime
import jira
import json
import keyboard
import sys

# JSON 파일
JSON_FILE = 'worklog.json'

# JSON 파일을 연다.
try:
    json_file = open(JSON_FILE, encoding="UTF-8")
except:
    print(f"Fail to open {JSON_FILE} file")
    sys.exit(1)

# JSON 내용을 파싱한다.
try:
    json_data = json.load(json_file)
except json.JSONDecodeError as e:
    print(f"Fail to parse {JSON_FILE} ({e})")
    json_file.close()
    sys.exit(1)

# JSON 파일을 닫는다.
json_file.close()

# JSON 내용에서 Jira 서버 URL과 사용자 액세스 토큰을 얻는다.
jira_server = json_data['jira_server']
jira_user_access_token = json_data['jira_user_access_token']

# Jira 서버의 token auth 방식으로 로그인한다. (로그인은 1회만 시도)
jira_auth = jira.JIRA(server=jira_server, token_auth=jira_user_access_token, max_retries=1)

# JSON 내용에서 추가할 작업 기록 정보들을 얻는다.
add_work_logs = json_data['add_work_logs']

# 각 추가할 작업 기록 정보를 얻어서 추가한다.
for add_work_log in add_work_logs:
    print("\n----------------------------------------------------------------")

    # JSON 내용에서 add 할 작업 기록 정보를 얻는다.
    issue_id = add_work_log['issue_id']
    add_work_log_time = add_work_log['work_log_time']
    add_work_log_comment = add_work_log['work_log_comment']

    # 해당 Jira 이슈를 얻는다.
    try:
        jira_issue = jira_auth.issue(issue_id)
    except jira.JIRAError as e:
        print(f"Fail to get issue {issue_id} ({e.text})")
        continue

    # 해당 Jira 이슈 정보를 출력한다.
    print("프로젝트:", jira_issue.fields.project.name)
    print("이슈 키:", jira_issue.key)
    print("이슈 제목:", jira_issue.fields.summary)
    print("담당자:", jira_issue.fields.assignee)

    # 추가할 작업 기록 시간이 0이면 추가하지 않는다.
    if add_work_log_time == "0h":
        print("\n작업 기록 시간이 0이므로 추가하지 않음")
        continue

    # 해당 Jira 이슈의 전체 작업 기록 정보를 얻는다.
    total_work_logs = jira_auth.worklogs(issue=issue_id)

    if len(total_work_logs) > 0:
        # 해당 Jira 이슈의 마지막 작업 기록 정보을 얻는다.
        last_work_log = total_work_logs[-1]

        # 해당 Jira 이슈의 마지막 작업 기록 정보를 출력한다.
        date_time = datetime.datetime.strptime(last_work_log.updated, "%Y-%m-%dT%H:%M:%S.%f%z")
        print("\n마지막 작업 기록 날짜:", date_time.strftime("%Y년 %m월 %d일 (%H:%M:%S)"))
        print("마지막 작업 기록 시간:", last_work_log.timeSpent)
        print("마지막 작업 기록 설명:", last_work_log.comment)

    # 작업 추가할 내용을 미리 출력하고, 사용자의 확인을 받는다.
    now = time.localtime()
    month_str = "%02d" % now.tm_mon
    day_str = "%02d" % now.tm_mday
    today_str = "[" + str(now.tm_year) + "년 " + month_str + "월 " + day_str + "일]"
    print("\n" + today_str)
    print("추가할 작업 기록 시간:", add_work_log_time)
    print("추가할 작업 기록 설명:", add_work_log_comment)
    answer = input("=> 이 작업 기록을 추가하시겠습니까? (y/n) ")
    if answer != 'y':
        continue

    # 해당 Jira 이슈에서 작업 기록 정보를 추가한다.
    added_work_log = jira_auth.add_worklog(issue=issue_id, timeSpent=add_work_log_time, comment=add_work_log_comment)

    # 해당 Jira 이슈에서 추가된 작업 기록 정보를 출력한다.
    date_time = datetime.datetime.strptime(added_work_log.updated, "%Y-%m-%dT%H:%M:%S.%f%z")
    print("\n추가된 작업 기록 날짜:", date_time.strftime("%Y년 %m월 %d일 (%H:%M:%S)"))
    print("추가된 작업 기록 시간:", added_work_log.timeSpent)
    print("추가된 작업 기록 설명:", added_work_log.comment)
```

## 작업 시간 JSON 파일
아래 예와 같이 작성하였다. 아래 예에서 보듯이 work log는 이슈 ID 별로 여러 개를 입력할 수도 있다.
```json
{
    "jira_server": "Jira_서버_URL",
    "jira_user_access_token": "Jira_유저_액세스_토큰",
    "add_work_logs": [
        {
            "model": "MODEL_NAME1",
            "issue_id": "TEST-1",
            "work_log_time": "5h",
            "work_log_comment": "테스트 1"
        },
        {
            "model": "MODEL_NAME2",
            "issue_id": "TEST-2",
            "work_log_time": "3h",
            "work_log_comment": "테스트 2"
        }
    ]
}
```
