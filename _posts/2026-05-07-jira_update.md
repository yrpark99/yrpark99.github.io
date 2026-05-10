---
title: "Go 자동화 툴로 Jira 이슈 업데이트하기"
category: [업무자동화]
toc: true
toc_label: "이 페이지 목차"
---

업무 자동화 중의 하나로 Jira 이슈를 업데이트하는 기능을 구현해 보았다.

## 동기
예전에 [Jira 작업 시간 기록 자동화](https://yrpark99.github.io/%EC%97%85%EB%AC%B4%EC%9E%90%EB%8F%99%ED%99%94/jira_worklog/) 페이지에서 기록했듯이, Jira에서 작업 시간 기록을 자동화하는 Python 툴을 만들어서 쓰고 있었는데, 이번에 기존 key 입수/조작/릴리즈 자동화 툴에서 해당 Jira 이슈를 찾아서 코멘트를 추가하고 담당자를 변경해야 할 필요성이 생겨서, 기존 툴(Go로 구현)에 이 기능을 추가로 구현해 보았다.  
아래에 실제로 구현한 코드에서 필요한 부분만 뽑아서 간략해 정리해 본다.

## Jira API
Jira 서버는 REST API를 제공하므로 ([Jira REST API documentation](https://developer.atlassian.com/cloud/jira/platform/rest/v3/intro/) 페이지 참고) 이것을 이용할 수도 있으나, Go 언어용으로 [go-jira](https://github.com/andygrunwald/go-jira) 패키지가 있으므로, 간단히 구현하기 위하여 이 패키지를 사용하였다.

## Jira 사용자 액세스 토큰
Jira에 접근하기 위해서는 사용자 액세스 토큰이 필요하므로, jira.json 파일을 아래와 같이 작성하였다.
```json
{
    "user_access_token": "Jira_유저_액세스_토큰"
}
```

이 정보를 얻기 위하여 아래와 같이 작성하였다.
```go
import (
    "encoding/json"
    "fmt"
)

const JIRA_JSON_FILE = "jira.json"

jsonFile, err := os.Open(JIRA_JSON_FILE)
if err != nil {
    fmt.Println("Failed to open " + JIRA_JSON_FILE + " file.")
    return
}
defer jsonFile.Close()
var jiraToken JiraToken
decoder := json.NewDecoder(jsonFile)
if err := decoder.Decode(&jiraToken); err != nil {
    fmt.Println("Failed to decode " + JIRA_JSON_FILE + " file.")
    return
}
if jiraToken.UserAccessToken == "" {
    fmt.Println("Failed to get user access token in " + JIRA_JSON_FILE + " file.")
    return
}
```

## Jira 서버에 로그인하기
아래와 같이 Jira 서버에 UserAccessToken을 사용하여 bearer auth 방식으로 로그인한다.
```go
import (
    "fmt"

    jira "github.com/andygrunwald/go-jira"
)

const JIRA_SERVER = "Jira_서버_URL"

tp := jira.BearerAuthTransport{
    Token: jiraToken.UserAccessToken,
}
jiraClient, err := jira.NewClient(tp.Client(), JIRA_SERVER)
if err != nil {
    fmt.Println("Failed to create JIRA client.")
    return
}
_, _, err = jiraClient.User.GetSelf()
if err != nil {
    fmt.Println("Failed to log in JIRA.")
    return
}
```

## Jira 이슈 업데이트 구현
나의 경우 먼저 Jira에서 특정 프로젝트와 컴포넌트로 이슈들을 찾은 후에, 해당 이슈들 중에서 코멘트에 입력 Request ID와 동일한 내용을 가지는 이슈들을 찾아야 했다.  
이 부분은 아래와 같이 `"project = XXX AND component = YYY"` 조건으로 검색하여 구현하였다. (최대 10개만 찾게 함)
```go
jql := "project = XXX AND component = YYY"
issues, _, err := jiraClient.Issue.Search(jql, &jira.SearchOptions{
    MaxResults: 10,
})
if err != nil {
    fmt.Println("Failed to search JIRA issues.")
    return
}
```

이후 검색된 Jira 티켓들의 Comments를 검색하여, "Request ID" 문자열 정보가 입력 passRequestID 값과 일치하는 이슈를 찾아서, 찾은 이슈(티켓)에 코멘트를 추가하고 담당자를 리포터로 변경하도록 구현하였다. (아래에서 releaseComment는 추가할 코멘트 문자열임)
```go
for _, issue := range issues {
    issueComments, _, err := jiraClient.Issue.Get(issue.Key, &jira.GetQueryOptions{
        Expand: "comments",
    })
    if err != nil {
        fmt.Println("Failed to get issue comments." )
        continue
    }

    ticketFound := false
    for _, comment := range issueComments.Fields.Comments.Comments {
        requestID := extractRequestID(comment.Body)
        if requestID != passRequestID {
            continue
        }
        fmt.Println("Found Request ID at Jira: " + requestID)
        ticketFound = true
        break
    }

    if ticketFound {
        fmt.Println("Found Jira ticket: " + issue.Key + " " + issue.Fields.Summary )
        for _, comment := range issueComments.Fields.Comments.Comments {
            if strings.Contains(comment.Body, releaseComment) {
                fmt.Println("Release comment is already exist.")
                return
            }
        }

        comment := &jira.Comment{
            Body: releaseComment + "\n" + pkReleaseDir,
        }
        _, _, err = jiraClient.Issue.AddComment(issue.Key, comment)
        if err != nil {
            fmt.Println("Failed to add release comment.")
            return
        }
        fmt.Println("Added release comment.")

        reporter := issue.Fields.Reporter
        if reporter == nil {
            fmt.Println("Failed to get reporter")
            return
        }
        if issue.Fields.Assignee.Name == reporter.Name {
            fmt.Println("Assignee is already same as reporter.")
            return
        }
        _, err = jiraClient.Issue.UpdateAssignee(issue.Key, issue.Fields.Reporter)
        if err != nil {
            fmt.Println("Failed to update assignee.")
            return
        }
        fmt.Println("Updated assignee to " + issue.Fields.Reporter.Name)
        return
    }
}
```

또, extractRequestID() 함수는 아래와 같이 정규 표현식을 이용하여 `"Request ID:"` 이후에 있는 문자열을 얻도록 구현하였다.
```go
import (
    "regexp"
    "strings"
)

func extractRequestID(comment string) string {
    re := regexp.MustCompile(`Request ID:\s*(\S+)`)
    matches := re.FindStringSubmatch(comment)
    if len(matches) > 1 {
        return strings.TrimSpace(matches[1])
    }
    return ""
}
```

## 효과
위와 같이 기존 자동화 툴을 Jira 이슈까지 업데이트하도록 구현하여, key 입수/조작/릴리즈의 전 과정이 Go로 빌드한 실행 파일만 실행시키면 완료되도록 하여, 잡업무들은 간단히 끝낼 수 있었다.
