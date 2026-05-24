---
title: "JSON-RPC 심플 구현"
category: [C/C++]
toc: true
toc_label: "이 페이지 목차"
---

C++을 사용하여 최대한 간단하게 자체 JSON-RPC를 심플하게 구현해 보았다.

## 머릿말
RPC(Remote Procedure Call)는 두 프로세스 간의 함수 호출을 뜻하는데, 소켓 통신과 같은 IPC(Inter-Process Communication)를 이용하여 구현할 수 있다.  
예전에 [JSON-RPC 정리](https://yrpark99.github.io/c/c++/jsonrpc_usage/) 글에서 JSON-RPC를 소개하고, C/C++로 오픈소스 패키지를 이용한 JSON-RPC 사용법을 간단히 다루었다.  
이번 글에서는 단순한 파라미터로 함수 몇 개만 호출하는 경우에 적합한 용도로, JSON-RPC 외부 패키지를 사용하지 않고, JSON 라이브러리만 사용하여 간단하게 JSON-RPC를 직접 구현해 보았다.  
<br>

여기서는 **<font color=blue>AF_INET</font>** 소켓을 이용하여 JSON RPC를 구현하였다. AF_INET 소켓은 포트를 이용하므로, 시스템이 사용 중이지 않은 포트를 사용해야 한다. 만약에 **<font color=blue>AF_UNIX</font>** 소켓을 사용하려는 경우에는 포트 대신에 소켓 파일을 사용해야 하는데, 이 방법은 AF_INET 소켓을 이용하는 예제 이후에, 필요한 변경 사항만 간략히 언급하겠다.

## Makefile 파일
아래와 같이 Makefile 파일을 작성한다. 즉, `make` 명령을 실행하면 예제 RPC client, server 프로그램이 빌드된다.
```makefile
CXX = g++
CXXFLAGS = -Wall
LDFLAGS = -ljsoncpp

TARGET_CLIENT = client
TARGET_SERVER = server

CLIENT_SRCS = Client.cpp JsonRpc.cpp
CLIENT_OBJS = $(CLIENT_SRCS:%.c=%.o)

SERVER_SRCS = Server.cpp JsonRpc.cpp
SERVER_OBJS = $(SERVER_SRCS:%.c=%.o)

all: $(TARGET_CLIENT) $(TARGET_SERVER)

$(TARGET_CLIENT): $(CLIENT_OBJS)
	$(CXX) -o $@ $^ $(LDFLAGS)

$(TARGET_SERVER): $(SERVER_OBJS)
	$(CXX) -o $@ $^ $(LDFLAGS)

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -o $@ -c $<

clean:
	@rm -rf *.o $(TARGET_CLIENT) $(TARGET_SERVER)
```

## RPC server 헤더 파일
RPC server와 client가 공통으로 사용하는 JsonRpc.h 헤더 파일을 아래와 같이 작성한다. (예로 **12345** 포트 번호 사용)
```cpp
#pragma once

#include <json/json.h>

#define PORT    12345

bool SendJsonRpc(int fd, const Json::Value &root);
bool RecvJsonRpc(int fd, Json::Value &outRoot);
```

## JSON-RPC 구현
RPC server와 client가 공통으로 사용하는 JsonRpc.cpp 파일을 아래와 같이 작성한다.  
JSON-RPC 수신은 입력 소켓 파일 디스크립터를 read 해서 JSON 데이터로 파싱하고, JSON-RPC 송신은 입력 JSON 데이터를 입력 소켓 파일 디스크립터로 write 한다.
```cpp
#include <arpa/inet.h>
#include <unistd.h>

#include <json/json.h>

bool RecvJsonRpc(int fd, Json::Value &outRoot) {
    Json::Reader reader;
    uint32_t payloadLen = 0;

    if (read(fd, &payloadLen, sizeof(payloadLen)) != sizeof(payloadLen)) {
        return false;
    }

    uint32_t len = ntohl(payloadLen);
    std::string payload(len, '\0');
    if (read(fd, &payload[0], len) != (size_t)len) {
        return false;
    }
    if (!reader.parse(payload, outRoot, false)) {
        return false;
    }
    return true;
}

bool SendJsonRpc(int fd, const Json::Value &root) {
    Json::FastWriter w;
    std::string payload = w.write(root);
    uint32_t len = htonl(static_cast<uint32_t>(payload.size()));

    if (len == 0) {
        return false;
    }
    if (write(fd, &len, sizeof(len)) != sizeof(len)) {
        return false;
    }
    if (write(fd, payload.data(), payload.size()) != payload.size()) {
        return false;
    }
    return true;
}
```

## RPC server
RPC server 프로그램으로 Server.cpp 파일을 아래와 같이 작성한다.  
이 server 프로그램은 AF_INET 소켓을 생성한 후에 소켓으로 들어온 입력 JSON 데이터를 파싱하여 해당 메쏘드를 처리하고, 그 처리 결과를 JSON 데이터로 만들어서 다시 client로 보낸다. 아래에서는 메쏘드 예로 "add"와 "multiply"를 구현하였다.
```cpp
#include <arpa/inet.h>
#include <stdio.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <unistd.h>

#include "JsonRpc.h"

static Json::Value ProcessMethod(const Json::Value &req) {
    Json::Value resp(Json::objectValue);

    if (!req.isMember("method") || !req["method"].isString()) {
        resp["ok"] = false;
        resp["error"] = "missing_method";
        return resp;
    }
    const std::string method = req["method"].asString();
    const Json::Value params = req.get("params", Json::Value(Json::objectValue));

    if (method == "add") {
        int arg1 = params.get("arg1", 0).asInt();
        int arg2 = params.get("arg2", 0).asInt();
        printf("server: method=%s, arg1=%d, arg2=%d\n", method.c_str(), arg1, arg2);
        resp["result"] = arg1 + arg2;
        resp["ok"] = true;
        return resp;
    }

    if (method == "multiply") {
        int arg1 = params.get("arg1", 0).asInt();
        int arg2 = params.get("arg2", 0).asInt();
        printf("server: method=%s, arg1=%d, arg2=%d\n", method.c_str(), arg1, arg2);
        resp["result"] = arg1 * arg2;
        resp["ok"] = true;
        return resp;
    }

    resp["ok"] = false;
    resp["error"] = "unknown_method";
    return resp;
}

int JsonRpcServer() {
    struct sockaddr_in addr;

    int server_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (server_fd < 0) {
        printf("%s(): Failed to create socket\n", __func__);
        return -1;
    }

    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = INADDR_ANY;
    addr.sin_port = htons(PORT);
    if (bind(server_fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        printf("%s(): Failed to bind\n", __func__);
        close(server_fd);
        return -1;
    }

    if (listen(server_fd, 1) < 0) {
        printf("%s(): Failed to listen\n", __func__);
        close(server_fd);
        return -1;
    }

    int client_fd = accept(server_fd, nullptr, nullptr);
    if (client_fd < 0) {
        printf("%s(): Failed to accept\n", __func__);
        close(server_fd);
        return -1;
    }

    for (;;) {
        Json::Value req, resp;
        if (!RecvJsonRpc(client_fd, req)) {
            break;
        }
        resp = ProcessMethod(req);
        if (!SendJsonRpc(client_fd, resp)) {
            printf("%s(): Failed to send JSON RPC\n", __func__);
            break;
        }
    }

    close(client_fd);
    close(server_fd);
    return 0;
}

int main() {
    JsonRpcServer();

    return 0;
}
```

## RPC client
RPC client 프로그램으로 Client.cpp 파일을 아래와 같이 작성한다.  
이 client 프로그램은 AF_INET 소켓을 사용하여 RPC server에 연결한 후에, "add"와 "multiply" 메쏘드를 파라미터와 함께 JSON RPC로 보내고, server로부터 응답을 받아서 결과를 출력한다.
```cpp
#include <arpa/inet.h>
#include <stdio.h>
#include <sys/socket.h>
#include <unistd.h>

#include "JsonRpc.h"

int ConnectJsonRpcServer(void) {
    struct sockaddr_in addr;
    int sock_fd;

    sock_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (sock_fd < 0) {
        printf("%s(): Failed to create socket\n", __func__);
        return -1;
    }

    addr.sin_family = AF_INET;
    addr.sin_port = htons(PORT);
    inet_pton(AF_INET, "127.0.0.1", &addr.sin_addr);
    if (connect(sock_fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        printf("%s(): Failed to connect\n", __func__);
        close(sock_fd);
        return -1;
    }

    return sock_fd;
}

bool CallJsonRpc(int fd, Json::Value req, Json::Value &resp) {
    if (!req.isMember("method") || !req["method"].isString()) {
        resp["error"] = "missing_method";
        return false;
    }
    const std::string strMethod = req["method"].asString();

    if (!SendJsonRpc(fd, req)) {
        printf("%s(): Failed to send json frame\n", __func__);
        return false;
    }
    if (!RecvJsonRpc(fd, resp)) {
        printf("%s(): Failed to receive json frame\n", __func__);
        return false;
    }
    return resp.isMember("ok") && resp["ok"].asBool();
}

bool JsonRpc_add(int fd, int arg1, int arg2, int &result) {
    Json::Value req, resp;

    req["method"] = "add";
    req["params"]["arg1"] = arg1;
    req["params"]["arg2"] = arg2;
    if (CallJsonRpc(fd, req, resp) == false) {
        printf("%s(): Failed, error=%s\n", __func__, resp["error"].asString().c_str());
        return false;
    }
    result = resp["result"].asInt();
    return true;
}

bool JsonRpc_multiply(int fd, int arg1, int arg2, int &result) {
    Json::Value req, resp;

    req["method"] = "multiply";
    req["params"]["arg1"] = arg1;
    req["params"]["arg2"] = arg2;
    if (CallJsonRpc(fd, req, resp) == false) {
        printf("%s(): Failed, error=%s\n", __func__, resp["error"].asString().c_str());
        return false;
    }
    result = resp["result"].asInt();
    return true;
}

int main(void) {
    int result;
    int fd = ConnectJsonRpcServer();
    if (fd == -1) {
        printf("Failed to connect JSON-RPC server\n");
        return 1;
    }

    if (JsonRpc_add(fd, 2, 3, result)) {
        printf("client: add(2, 3) = %d\n", result);
    } else {
        printf("Failed to call JSON-RPC add\n");
    }

    if (JsonRpc_multiply(fd, 4, 5, result)) {
        printf("client: multiply(4, 5) = %d\n", result);
    } else {
        printf("Failed to call JSON-RPC multiply\n");
    }

    close(fd);
    return 0;
}
```

## 테스트 실행
먼저 server 프로그램을 실행시키고, 터미널을 1개 더 열어서 client를 실행시킨다.  
결과로 아래와 같이 정상적인 결과가 출력된다.
- server 로그
  ```sh
  server: method=add, arg1=2, arg2=3
  server: method=multiply, arg1=4, arg2=5
  ```
- client 로그
  ```sh
  client: add(2, 3) = 5
  client: multiply(4, 5) = 20
  ```

## AF_UNIX 소켓 사용하기
만약에 AF_INET 소켓 대신에 AF_UNIX 소켓을 사용하고자 하는 경우에는 다음과 같은 내용들만 변경하면 된다.  
<br>

JsonRpc.h 파일에서 PORT 대신에 아래 예와 같이 소켓 파일의 경로를 지정한다.
```cpp
#define SOCKET_PATH "/tmp/ipc.sock"
```
<br>

Server.cpp 파일에서 `<arpa/inet.h>` 헤더는 제거하고, 아래 헤더 파일을 include 한다.
```cpp
#include <sys/un.h>
```
또, JsonRpcServer() 함수는 아래와 같이 변경한다.
```cpp
int JsonRpcServer() {
    struct sockaddr_un addr;

    int server_fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (server_fd < 0) {
        printf("%s(): Failed to create socket\n", __func__);
        return -1;
    }

    if (access(SOCKET_PATH, F_OK) == 0) {
        unlink(SOCKET_PATH);
    }

    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, SOCKET_PATH, sizeof(addr.sun_path) - 1);
    if (bind(server_fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        printf("%s(): Failed to bind\n", __func__);
        close(server_fd);
        return -1;
    }
    chmod(SOCKET_PATH, 0660);

    if (listen(server_fd, 1) < 0) {
        printf("%s(): Failed to listen\n", __func__);
        close(server_fd);
        return -1;
    }

    int client_fd = accept(server_fd, nullptr, nullptr);
    if (client_fd < 0) {
        printf("%s(): Failed to accept\n", __func__);
        close(server_fd);
        return -1;
    }

    for (;;) {
        Json::Value req, resp;
        if (!RecvJsonRpc(client_fd, req)) {
            break;
        }
        resp = ProcessMethod(req);
        if (!SendJsonRpc(client_fd, resp)) {
            printf("%s(): Failed to send JSON RPC\n", __func__);
            break;
        }
    }

    close(client_fd);
    close(server_fd);
    unlink(SOCKET_PATH);
    return 0;
}
```
<br>

Client.cpp 파일에서도 마찬가지로 `<arpa/inet.h>` 헤더는 제거하고, 아래 헤더 파일을 include 한다.
```cpp
#include <sys/un.h>
```
또, ConnectJsonRpcServer() 함수는 아래와 같이 변경한다.
```cpp
int ConnectJsonRpcServer(void) {
    struct sockaddr_un addr;
    int sock_fd;

    sock_fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (sock_fd < 0) {
        printf("%s(): Failed to create socket\n", __func__);
        return -1;
    }

    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, SOCKET_PATH, sizeof(addr.sun_path) - 1);
    if (connect(sock_fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        printf("%s(): Failed to connect\n", __func__);
        close(sock_fd);
        return -1;
    }

    return sock_fd;
}
```
<br>

빌드해서 실행해보면 이전의 AF_INET 소켓을 사용했던 결과와 동일한 결과를 얻을 수 있다.  
참고로 server에서 생성한 소켓 파일의 속성을 보면, 아래와 같이 **socket**으로 나옴을 확인할 수 있다.
```sh
$ file /tmp/ipc.sock
/tmp/ipc.sock: socket
```

## 맺음말
위와 같이 기본 형태만 구현하여, 두 프로세스 간의 함수 호출을 구현해 보았다.  
물론 추가로 서버에서의 RPC 함수 호출과 클라이언트에서의 함수 부분을 구조화할 수 있겠으나, 여기서는 의도적으로 가장 간단한 형태로 구현하였고, 추후 참조용으로 남긴다.
