---
title: "SQLite DB 무결성 검사하기"
category: [Database]
toc: true
toc_label: "이 페이지 목차"
---

SQLite3 DB 파일의 무결성(integrity) 검사를 구현해 보았다.

## SQLite DB 무결성 검사
사내 기존 모델에서 구현되지 않았던 기능으로, SQLite DB 파일의 무결성을(파일이 깨지거나 변조되지 않았는지) 구현해야 할 일이 생겼다. 이 SQLite DB 파일은 사용자의 USB 저장 장치에 저장되고, 따라서 사용자가 얼마든지 변조가 가능했기 때문에, 무결성 검사의 도입이 필요해졌다.  
그런데 SQLite 파일은 SQLite 엔진에 의해 read/write 되므로, 무결성 검사 구현에 약간의 허들이 있었다.

## SQLite 자체 무결성 검사
우선 SQLite 자체적으로 무결성 검사를 지원하는지 찾아보니, `PRAGMA integrity_check`를 지원하고 있었다. 아래와 같이 명령을 실행하여 간단히 검사해 볼 수 있다.
```sh
$ sqlite3 {SQLite_DB_file} "PRAGMA integrity_check"
```
또는 아래와 같이 sqlite3 툴을 실행한 후, 해당 커맨드를 실행해도 된다.
```sh
$ sqlite3 {SQLite_DB_file}
sqlite> PRAGMA integrity_check;
```
또는 파이썬 코드로는 아래와 같이 작성할 수 있겠다.
 ```python
#!/usr/bin/python3
import os
import sqlite3
import sys

db_file = "sqlite3.db"

if os.path.exists(db_file) is False:
    print(db_file + " is not exist")
    sys.exit(1)

connection = sqlite3.connect(db_file)
cursor = connection.cursor()
cursor.execute("PRAGMA integrity_check;")
result = cursor.fetchone()
if result[0] == 'ok':
    print("integrity_check: ok")
else:
    print("integrity_check: ", result[0])

connection.close()
```

결과로 무결성이 올바른 경우에는 <font color=green>ok</font> 결과가 출력되고, 그렇지 않은 경우에는 에러 내용이 출력된다.  
<br>

그런데 위 `PRAGMA integrity_check` 검사로는 정상적인 schema로 database의 내용이 변경된 경우에도 <font color=green>ok</font>가 출력되어, 내 목적과 같이 데이터 변조 여부는 검사가 되질 않았다. 😡

## HMAC을 이용한 무결성 검사
그래서 SQLite DB에 commit 시에는 DB 파일 전체 데이터로 `HMAC`(Hash-based Message Authentication Code)을 계산해서 파일의 끝에 붙이고, SQLite DB를 connect 시에는 파일의 맨 끝에 붙어있는 HMAC을 읽어서 올바른 경우에만 진행시키도록 구현해 보았다.  
<br>

실제 구현에 앞서 먼저 POC로 아래와 같이 파이썬으로 작성해 보았다. (SQLite DB 파일의 끝에 32 바이트 HMAC signature를 붙였고, 이어서 32 바이트 HMAC 값을 붙였음)
```python
#!/usr/bin/python3

import hashlib
import hmac
import os
import sys
import sqlite3

db_file = 'sqlite3.db'

def calculate_hmac(key, data):
    h = hmac.new(key, digestmod=hashlib.sha256)
    h.update(data)
    return h.digest()

def verify_hmac_in_file(filename, key):
    hmac_signature = b'\x00\x00\x00\x00\x00\x09\x00\x00\x00\x01\x00\x00\x00\x00\x00\x10' + \
                     b'\x00\x00\x00\x00\x03\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00'
    with open(filename, 'rb') as f:
        file_data = f.read()
    stored_signature = file_data[-64:-32]

    if stored_signature != hmac_signature:
        conn = sqlite3.connect(db_file)
        cursor = conn.cursor()
        cursor.execute("VACUUM;")
        conn.commit()
        conn.close()
        f.close()
        with open(filename, 'rb') as f:
            file_data = f.read()

        hmac_value = calculate_hmac(key, file_data)
        print("Calculated HMAC: " + ' '.join([f'{byte:02X}' for byte in hmac_value]))
        data_to_write = file_data + hmac_signature + hmac_value
        print("Append HMAC to file")
        with open(filename, 'wb') as f:
            f.write(data_to_write)
            return True

    stored_hmac = file_data[-32:]
    print("File HMAC: " + ' '.join([f'{byte:02X}' for byte in stored_hmac]))
    data_to_verify = file_data[:-64]
    calculated_hmac = calculate_hmac(key, data_to_verify)
    if stored_hmac == calculated_hmac:
        print("HMAC is correct")
        return True
    else:
        print("HMAC is not correct")
        return False

if __name__ == '__main__':
    hmac_key = b'\xe4\x62\x76\x1a\x7d\xd4\x8c\x22\x27\x9f\xc9\x6c\xc8\x66\xec\x10'

    if os.path.exists(db_file) is False:
        print(db_file + " is not exist")
        sys.exit(1)

    verify_hmac_in_file(db_file, hmac_key)
```

참고로 위에서 최초 HMAC을 추가할 때 **<font color=blue>VACUUM</font>** 명령을 실행한 것은, 이렇게 해야 HMAC 데이터가 추가된 DB 파일을 `PRAGMA integrity_check`로 검사할 때에 <font color=green>ok</font> 결과가 나오기 때문이다.  

## 맺음말
위 파이썬 코드로 원하는대로 무결성이 검사되는 것을 확인한 후에, 실제 장치에서는 C++로 구현하였다.  
테스트해 보니 기대대로 DB가 업데이트될 때마다 (HMAC 데이터는 자동으로 삭제됨) SQLite DB 내용 바로 뒤에 HMAC 데이터가 추가되고, 이를 이용하여 정상적으로 무결성 검사가 잘 됨을 확인하였다. 🙂

## SQLCipher 소개
참고로 SQLite의 기밀성과 무결성을 모두 지원하는 [SQLCipher](https://github.com/sqlcipher/sqlcipher) 소스를 찾을 수 있었다.  
나의 경우는 기존 버전과의 역호환성 때문에 이 패키지를 사용할 수 없었지만, SQLite를 새로이 도입하는 경우에는 이 패키지의 사용을 추천한다.
