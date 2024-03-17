---
title: "파이썬으로 SQLite DB 생성 및 내용 보기"
category: [Database, Python]
toc: true
toc_label: "이 페이지 목차"
---

파이썬으로 SQLite DB를 생성하고 확인하는 간단한 툴을 작성해 보았다.

## 동기
회사 임베디드 모델에서는 데이터 베이스로 SQLite를 사용하고 있는데, 채널 스캔을 하여 채널 DB를 SQLite로 구성하여 사용하고 있다. 그런데 간혹 임베디드 장치가 아닌 PC 툴로 해당 DB를 생성하거나 수정하면 편리한 경우가 있었다.  
물론 이런 경우에는 SQLite 관련 툴을 이용할 수는 있지만 이 경우에는 자동화가 되지 않아서, 이런 경우의 자동화를 위하여 간단히 파이썬으로 필요한 SQLite 툴을 구현하기로 하였다.

## SQLite 소개
[SQLite](https://sqlite.org/index.html)는 C 언어로 구현된 작고 빠른 SQL(Structured Query Language) 데이터 베이스 엔진으로, 거의 모든 크로스 플랫폼에 이식되어 널리 사용되고 있다.  
SQLite의 소스 코드는 공개되어 있고, 실질적으로 상용 제품에서도 아무런 제약 없이 사용할 수 있는데, 실제로 회사 임베디드 모델에서도 사용 중이고, 안드로이드 OS 제품군에서도 사용되고 있다.  
<br>
참고로 SQLite 소스는 SQLite 홈페이지에서 [SQLite Download Page](https://sqlite.org/download.html)에서 받을 수 있다. (이것을 받아서 임베디드 시스템에서도 간단하게 SQLite를 사용할 수 있음)

> GeekNews에 올라온 [SQLite의 알려지지 않은 이야기](https://news.hada.io/topic?id=4558)를 한 번 읽어보기를 권장한다.

## SQLite 관련 툴
* [DB Browser for SQLite](https://sqlitebrowser.org/): 오픈 소스 ([GitHub 소스](https://github.com/sqlitebrowser/sqlitebrowser))
* [sqlite-gui](https://github.com/little-brother/sqlite-gui): Windows 전용, 작고 간단하고 가벼움
* [SQLite Viewer Web App](https://sqliteviewer.app/): Web 툴
* [SQLite Viewer](https://marketplace.visualstudio.com/items?itemName=qwtel.sqlite-viewer): VS Code 용 익스텐션

## Linux SQLite CLI 툴
1. 가장 많이 사용되는 sqlite3 패키지는 우분투에서 다음과 같이 설치할 수 있다.
   ```sh
   $ sudo apt install sqlite3
   ```
1. DB 파일 로딩 예
   ```sh
   $ sqlite3 <DB_file_name>
   ```

## Linux SQLite CLI 툴 사용 예
- 툴에서 sQL 명령은 일반적인 SQL 명령을 그대로 사용할 수 있다. (아래 예 참조)
- sqlite3 종료
  ```sql
  sqlite> .exit
  ```
  또는
  ```sql
  sqlite> .quit
  ```
- DB 전체 테이블 리스트 출력
  ```sql
  sqlite> .tables
  ```
- 칼럼과 헤더 표시 세팅
  ```sql
  sqlite> .mode column
  sqlite> .headers on
  ```
  또는 ~/.sqliterc 파일을 아래와 같이 작성해 놓으면 매번 세팅할 필요가 없으므로 편리하다.
  ```sql
  .headers on
  .mode column
  ```
- 입력 DB 테이블 내용 출력
  ```sql
  sqlite> .dump <테이블_이름>
  ```
  또는
  ```sql
  sqlite> SELECT * FROM <테이블_이름>;
  ```
- 테이블 내 레코드 개수 출력
  ```sql
  sqlite> SELECT COUNT(*) FROM <테이블_이름>;
  ```
- 테이블 내 조건 추가하여 출력 예
  ```sql
  sqlite> SELECT * FROM <테이블_이름> WHERE <조건>;
  ```

## SQLite 생성 및 덤프 코드
아래는 내가 작성한 코드의 일부이다. (단, 간략히 방법만 보이기 위하여 많은 부분을 생략하였고, 코드에 주석을 달았으므로, 자세한 코드 설명은 생략한다)
```python
#!/usr/bin/python3
# -*- coding: utf-8 -*-

import argparse
import os
import sqlite3
import sys

CHANNEL_DB_FILE = "channel.db"

def create_channel_db(args: argparse.Namespace) -> None:
    # 이미 파일이 존재하면 기존 파일은 삭제한다.
    if os.path.exists(CHANNEL_DB_FILE) is True:
        os.remove(CHANNEL_DB_FILE)

    # 채널 DB 파일을 연결한다.
    conn = sqlite3.connect(CHANNEL_DB_FILE)

    # DB 커서를 생성한다.
    cursor = conn.cursor()

    # 필요한 최소한의 DB 테이블을 생성하고, 데이터를 넣는다.
    create_add_channel_data(cursor)
    create_add_av_info_data(cursor)

    # DB 변경 내용을 저장한다.
    conn.commit()

    # DB 연결을 닫는다.
    conn.close()

def create_add_channel_data(cursor: sqlite3.Cursor) -> None:
    """Channel 테이블을 생성하고 데이터를 넣는다."""
    cursor.execute(
        """
        CREATE TABLE IF NOT EXISTS Channel
        (
        ChannelId INTEGER PRIMARY KEY,
        ChannelMode INTEGER,
        ChannelNumber INTEGER,
        ChannelName TEXT,
        Lock INTEGER,
        Attribute INTEGER,
        VolumeOffset INTEGER
        )
        """
    )
    channel_data = (
        (1, 1, 11, 'Service 11', 0, 0, 0),
        (2, 1, 12, 'Service 12', 0, 0, 0),
        (3, 1, 13, 'Service 13', 0, 0, 0),
        (4, 1, 14, 'Service 14', 0, 0, 0),
        (5, 1, 15, 'Service 15', 0, 0, 0),
    )
    cursor.executemany(
        """
        INSERT INTO Channel
        (
        ChannelId,
        ChannelMode,
        ChannelNumber,
        ChannelName,
        Lock,
        Attribute,
        VolumeOffset
        )
        VALUES(?, ?, ?, ?, ?, ?, ?)
        """,
        channel_data
    )

def create_add_av_info_data(cursor: sqlite3.Cursor) -> None:
    """AvInfo 테이블을 생성하고 데이터를 넣는다."""
    cursor.execute(
        """
        CREATE TABLE IF NOT EXISTS AvInfo
        (
        ChannelId INTEGER PRIMARY KEY,
        VideoCodec INTEGER,
        AudioCodec INTEGER,
        VideoPid INTEGER,
        AudioPid INTEGER,
        PcrPid INTEGER,
        AudioLang TEXT,
        AudioLR INTEGER,
        SubtitlePid INTEGER
        )
        """
    )
    av_info_data = (
        (1, 2, 11, 0x1110, 0x1112, 0x1110, 'eng', 0, -1),
        (2, 2, 11, 0x1120, 0x1122, 0x1120, 'eng', 0, -1),
        (3, 2, 11, 0x1130, 0x1132, 0x1130, 'eng', 0, -1),
        (4, 2, 11, 0x1140, 0x1142, 0x1140, 'eng', 0, -1),
        (5, 2, 11, 0x1150, 0x1152, 0x1150, 'eng', 0, -1),
    )
    cursor.executemany(
        """
        INSERT INTO AvInfo
        (
        ChannelId,
        VideoCodec,
        AudioCodec,
        VideoPid,
        AudioPid,
        PcrPid,
        AudioLang,
        AudioLR,
        SubtitlePid
        )
        VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        av_info_data
    )

def dump_channel_db() -> None:
    """채널 DB 파일을 dump 한다."""
    # DB 파일이 없으면 리턴한다.
    if os.path.exists(CHANNEL_DB_FILE) is False:
        print(CHANNEL_DB_FILE + " file is not exist.")
        return

    # 채널 DB 파일을 연결한다.
    conn = sqlite3.connect(CHANNEL_DB_FILE)

    # DB 커서를 생성한다.
    cursor = conn.cursor()

    # 모든 테이블의 데이터를 출력한다.
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
    tables = cursor.fetchall()
    for table in tables:
        table_name = table[0]
        print(f"[{table_name}] table")
        cursor.execute(f"SELECT * FROM {table_name};")
        cols = [column[0] for column in cursor.description]
        print(" ", cols)
        rows = cursor.fetchall()
        for row in rows:
            print(" ", row)
        print("")

     # DB 연결을 닫는다.
    conn.close()

if __name__ == '__main__':
    # 아규먼트 파서를 생성한다.
    parser = argparse.ArgumentParser(description="Create channel DB or dump channel DB")

    # 입력받을 아규먼트를 등록한다.
    parser.add_argument("-c", "--create", help="create channel DB with frontend type")
    parser.add_argument("-d", "--dump", action="store_true", help="dump channel DB")

    # 입력받은 아규먼트를 파싱한다.
    args = parser.parse_args()

    # create나 dump 아규먼트가 없으면 종료한다.
    if (args.create is None) and (args.dump is False):
        print("No option is specified. -h or --help option for help.")
        sys.exit(1)

    # create 아규먼트가 있으면 채널 DB 파일을 생성한다.
    if args.create is not None:
        create_channel_db(args)

    # dump 아규먼트가 있으면 채널 DB 파일을 dump 한다.
    if args.dump is True:
        dump_channel_db()
```

아래와 같이 실행하면 DB 파일이 생성된다. (실제로는 실행 시에 입력 아규먼트에 따라서 원하는 대로 DB가 구성되게 구현하였지만, 위 예제에서는 이런 코드는 모두 제거하였음)
```sh
$ ./channel_db.py -c
```
또 아래와 같이 실행하면 DB 내용이 덤프된다.
```sh
$ ./channel_db.py -d
```

## 맺음말
이와 같이 파이썬으로 작성하니, 실제 임베디드 장치가 없이 SQLite DB 파일을 원하는 데이터로 생성할 수 있었고 내용도 간단히 덤프하여 확인할 수 있었다.  
이 방법은 실제 임베디드 장치를 사용하는 경우보다 훨씬 더 빠르고 편리하게 DB를 구축할 수 있고, 다른 SQLite 외부 툴을 사용할 때보다 편리하게 자동화시킬 수 있으므로, 괜찮은 방법인 것 같다.😊
