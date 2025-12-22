---
title: "Android Content Provider 테스트"
category: [Android]
toc: true
toc_label: "이 페이지 목차"
---

Android의 Content Provider에 대하여 간단히 정리하고 테스트 해 보았다.

## Content Provider
Android에서 동작하는 앱들은 격리된 sandbox 환경에서 실행되므로 서로의 데이터 영역에 접근이 불가능하다. 만약에 앱 간의 데이터 교환이 필요한 때가 있으면 Content Provider를 사용할 수 있다.  
Content Provider는 Activity, Service, Broadcast와 함께 Android 주요 컴포넌트 중의 하나로, 앱 간에 구조화된 데이터를 안전하고 표준화된 방식으로 (URI 기반 인터페이스) 공유하기 위한 매커니즘이다. (즉, 직접 DB 파일을 공유하지 않고, Content Provider를 통해서만 접근하게 함으로써 보안·호환성·캡슐화를 보장한다)  
Android 시스템은 ContactsContract, MediaStore, CalendarContract, Settings 등의 기본 Content Provider를 제공하고 있다.  
<br>

Content Provider의 주요 특징은 다음과 같다.
- Content Provider는 앱 간의 데이터 공유는 물론이고 다른 앱의 데이터를 저장하거나 가져오는 작업을 수행할 수 있다.
- 앱은 자신의 Content Provider를 작성해 외부에 공개할 수도 있다. 특정 앱이 공개한 Content Provider에 접근하기 위해선 URI(Uniform Resource Identifier)를 통해야 한다. Android에 기본으로 설치된 앱들은 자신들의 데이터에 접근이 가능하도록 URI를 공개하고 있다. (여기서 URI는 **content://** 문자열로 시작하고 데이터를 식별하기 위한 고유 주소를 나타낸다)
- Content Provider는 실제 데이터의 저장 방식(SQLite, 파일 등)을 숨기고 표준화된 인터페이스만 노출한다.
- Permission 시스템을 통해 데이터 접근이 제어되므로, Content Provider에 URI를 통해 접근하기 위해서는 해당 퍼미션이 필요하다.
- 데이터베이스와 같은 구조화된 데이터 공유에 적합하지만, 액세스 속도가 느려서 실시간 통신이나 요청/응답 처리에는 적합하지 않다.

## Content Provider 제작
ContentProvider는 다음 핵심 CRUD 메서드를 override하여 제공해야 한다.
- query(): 데이터 조회
- insert(): 데이터 추가
- update(): 데이터 수정
- delete(): 데이터 삭제

예를 들어서 MyProvider는 아래 형태와 같이 ContentProvider를 상속받아서 구현할 수 있다.
```java
public class MyProvider extends ContentProvider {
    @Override
    public boolean onCreate() {
        return true;
    }

    @Override
    public Cursor query(Uri uri, String[] projection, String selection, String[] selectionArgs, String sortOrder) {
        return cursor;
    }

    @Override
    public Uri insert(Uri uri, ContentValues values) {
        return uri;
    }

    @Override
    public int update(Uri uri, ContentValues values, String selection, String[] selectionArgs) {
        return 0;
    }

    @Override
    public int delete(Uri uri, String selection, String[] selectionArgs) {
        return 0;
    }

    @Override
    public String getType(Uri uri) {
        return "vnd.android.cursor.dir/example.item";
    }
}
```

이후 AndroidManifest.xml 파일에는 아래 예와 같이 export와 권한을 등록한다.
```xml
<provider
    android:name=".MyProvider"
    android:authorities="com.example.myprovider"
    android:exported="true"
    android:permission="com.example.permission.READ_DATA" />
```

## Content Resolver
Content Provide를 사용하려는 앱은 AndroidManifest.xml 파일에 아래와 같이 필요한 권한을 추가한다.
```xml
<uses-permission android:name="com.example.permission.READ_DATA"/>
```

앱은 ContentProvider를 직접 호출하지 않고, 아래와 같이 ContentResolver를 통해 접근한다. (내부적으로 Binder IPC를 사용)
```java
ContentResolver resolver = getContentResolver();
Cursor cursor = resolver.query(uri, ...);
```

## Content Provider 테스트
- 참고로 Content Provider의 새로운 컬럼을 추가하기 위해서는 해당 content provider 소스에서 DB 스키마를 수정하면 된다. 예를 들어 CBS(Common Broadcast Stack) 소스에서는 아래 파일들이 해당된다.
  - com/google/android/tv/dtvprovider/base/CasSingleTable.java
  - com/google/android/tv/dtvprovider/base/CasMultiTable.java
  - com/google/android/tv/dtvprovider/base/CasMessageTable.java
- URI 예: `content://com.google.android.tv.dtvprovider/single_castable`
- 각 DB는 key, value로 구성된다.
- 콘솔이나 ADB shell에서 커맨드로 테스트 할 수 있다.
- Content 읽기  
  아래 형식으로 URI를 지정하여 읽을 수 있다.
  ```java
  # content query --uri {URI}
  ```
  예로 아래와 같이 읽을 수 있다.
  ```java
  # content query --uri content://com.google.android.tv.dtvprovider/single_castable
  ```
  특정 column 들만 보고 싶다면 아래 형식과 같이 `--projection` 옵션을 사용하면 된다.
  ```java
  # content query --uri {URI} --projection {COLUMN1},{COLUMN2}
  ```
  예로 key 열만 보고 싶으면 아래와 같이 할 수 있다.
  ```java
  # content query --uri content://com.google.android.tv.dtvprovider/single_castable --projection key
  ```
  특정 key 값만 찾아서 보고 싶으면 아래 예와 같이 `--where` 옵션을 사용하면 된다.
  ```java
  # content query --uri content://com.google.android.tv.dtvprovider/single_castable --where key=\"cas.widevine.config\"
  ```
- Content 추가하기  
  아래 형식과 같이 추가할 수 있다.
  ```java
  # content insert --uri {URI} --bind {COLUMN}:{TYPE}:{VALUE}
  ```
  참고로 값의 TYPE을 지정하는 접미사에는 여러가지가 있는데, 다음 것들이 주로 많이 쓰인다.
  - `b`: boolean
  - `d`: double
  - `f`: float
  - `i`: 정수(integer)
  - `l`: long 정수
  - `s`: 문자열(string)

  아래 예와 같이 테스트해 보았다.
  ```java
  # content insert --uri content://com.google.android.tv.dtvprovider/single_castable --bind key:s:"licenseServerUrl" --bind value:s:"urlLsA"
  ```
- Content 업데이트  
  아래 형식으로 업데이트할 수 있다.
  ```java
  # content update --uri {URI} --bind {COLUMN1_NAME}:{TYPE}:{COLUMN1_VALUE} --bind {COLUMN2_NAME}:{TYPE}:{COLUMN2_VALUE}
  ```
  아래 예와 같이 테스트해 보았다.
  ```java
  # content update --uri content://com.google.android.tv.dtvprovider/single_castable --bind value:s:"urlLsB" --where key=\"licenseServerUrl\"
  ```
- Content 삭제  
  아래 형식으로 삭제할 수 있다.
  ```java
  # content delete --uri {URI} --where {COLUMN}={VALUE}
  ```
  아래 예와 같이 테스트해 보았다.
  ```java
  # content delete --uri content://com.google.android.tv.dtvprovider/single_castable --where key=\"licenseServerUrl\"
  # content delete --uri content://com.google.android.tv.dtvprovider/single_castable --where key=\"cas.widevine.config\"
  ```

## Content Provider DB
- Content Provider가 사용하는 DB 파일의 위치는 `/data/data/{package_name}/databases/{database_name}` 이다.  
  예를 들어 위에서 테스트로 사용했던 Content Provider의 DB는 **/data/data/com.google.android.tv.dtvprovider.service/databases/DtvProvider:single_castable** 파일이다.
- Shell에서 아래 형태로 SQLite로 DB 파일을 읽을 수 있다.
  ```java
  # sqlite3 /data/data/{package_name}/databases/{database_name}
  ```
  예로 위에서 사용했던 Content Provider의 DB 파일은 아래와 같이 읽을 수 있다.
  ```java
  # sqlite3 /data/data/com.google.android.tv.dtvprovider.service/databases/DtvProvider:single_castable
  ```
- 헤더와 칼럼 내용을 깔끔하게 정렬시키기 위하여 아래와 같이 설정한다.
  ```sql
  sqlite> .headers on
  sqlite> .mode column
  ```
- 아래와 같이 테이블의 schema(구조)를 확인할 수 있다.
  ```sql
  sqlite> .schema
  ```
- 아래와 같이 실행하면 전체 테이블 리스트가 출력된다.
  ```sql
  sqlite> .tables
  ```
- 원하는 테이블의 내용은 아래와 같이 출력할 수 있다.
  ```sql
  sqlite> .dump {테이블_이름}
  ```
  또는
  ```sql
  sqlite> SELECT * FROM {테이블_이름};
  ```
- 그 외에도 추가/업데이트/삭제 등 필요한 SQLite 동작을 직접 수행할 수 있다.
