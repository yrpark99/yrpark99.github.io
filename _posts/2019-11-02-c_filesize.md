---
title: "C로 2GiB 이상 크기의 파일 다루기"
category: [C/C++]
toc: true
toc_label: "이 페이지 목차"
---

C로 2GiB 이상 크기의 파일을 다루는 방법을 간단히 기록한다.

## C 파일 API
익히 알고 있듯이 C 언어에서는 파일을 다룰 때 아래와 같은 2가지 종류의 함수를 사용할 수 있다.
- 저수준 함수: open(), close(), read(), write(), lseek() 등
- 고수준 함수: fopen(), fclose(), fread(), fwrite(), fseek() 등
> 참고로 저수준과 고수준의 가장 큰 차이점은 저수준 함수는 OS 버퍼링을 사용하지 않고, 고수준 함수는 OS 버퍼링을 사용한다는 것이다.

## C 파일 API에서 오프셋 크기
C 파일 API 중에서 특히 파일의 오프셋을 옮기는 API에서 오프셋 타입의 크기가 중요한데, 아래 선언에서 보듯이 오프셋 값으로 lseek()는 **off_t** 타입을 사용하고 fseek()는 **long** 타입을 사용한다.
```c
off_t lseek(int fd, off_t offset, int whence);
int fseek(FILE *stream, long offset, int whence);
```

그런데 C에서 `long` 타입은 아래 표에서 보듯이 32비트/64비트 시스템에서 서로 다른 길이와 이에 따른 값의 범위를 갖는다.
<table>
  <thead>
    <tr>
      <th style="text-align: center">자료형</th>
      <th style="text-align: center">시스템</th>
      <th style="text-align: center">값 범위</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td style="text-align: center" rowspan="2">long</td>
      <td style="text-align: center">32비트</td>
      <td style="text-align: center">-2<sup>31</sup> ~ 2<sup>31</sup>-1</td>
    </tr>
    <tr>
      <td style="text-align: center">64비트</td>
      <td style="text-align: center">-2<sup>63</sup> ~ 2<sup>63</sup>-1</td>
    </tr>
  </tbody>
</table>

즉, 32비트 시스템에서는 long의 범위는 -2<sup>31</sup> ~ 2<sup>31</sup>-1 이고, 이로 인해 max 값이 2<sup>31</sup>-1 제한을 갖게 된다.  
<br>

또 아래와 같이 선언되 fseeko() API가 있는데, 이 함수는 컴파일시 `_LARGEFILE_SOURCE`와 `_FILE_OFFSET_BITS=64` 정의가 enable 되면 사용할 수 있다.
```c
int fseeko(FILE *stream, off_t offset, int whence);
```
이 함수는 위에서 보듯이 오프셋 타입이 `off_t`로 lseek()와 동일함을 알 수 있다.

<br>
lseek(), fseeko() 함수 등에서 사용된 `off_t` 타입을 조사해 보면 <font color=blue>_FILE_OFFSET_BITS</font> 정의 여부에 따라 아래와 같이 타입으로 정의되어 있다.
- **_FILE_OFFSET_BITS=64 정의된 경우**: 32비트 시스템에서는 <font color=purple>long long</font>(즉 64비트), 64비트 시스템에서는 <font color=purple>long</font>(즉 64비트)
- **_FILE_OFFSET_BITS=64 정의되지 않은 경우**: <font color=purple>long</font>(즉 32비트 시스템에서는 <font color=red>32비트</font>, 64비트 시스템에서는 <font color=red>64비트</font>)  
<br>

따라서 결론적으로 컴파일시에 `_LARGEFILE_SOURCE`, `_FILE_OFFSET_BITS=64` 옵션을 추가하면 시스템에 관계없이 항상 64bit 오프셋 크기를 가질 수 있음을 알 수 있다.

## C로 2GiB 이상 파일의 크기 얻기
C 언어로 파일의 크기를 얻는 방법에는 여러가지가 있는데, 예를 들어 아래와 같이 파일의 상태를 얻는 함수들을 이용할 수 있다.
```c
int stat(const char *pathname, struct stat *statbuf);
int fstat(int fd, struct stat *statbuf);
```

위에서 출력 파라미터로 얻는 **stat** 구조체 중에서 **st_size** 멤버는 `off_t` 타입으로 선언되어 있다. 따라서 위에서 살펴본 바와 마찬가지로, 컴파일시에 `_LARGEFILE_SOURCE`, `_FILE_OFFSET_BITS=64` 옵션을 추가하면 시스템에 관계없이 항상 2GiB 이상의 크기도 올바로 얻을 수 있음을 알 수 있다.  
<br>

예를 들어, 아래와 같이 파일의 크기를 얻을 수 있다. (아래에서 `off_t` 타입의 값을 출력하기 위하여 <font color=blue>%jd</font>로 포매팅 하였음, 참고로 `size_t` 타입인 경우에는 <font color=blue>%zd</font>로 포매팅하면 됨)
```c
struct stat st;
if (stat(file_name, &st) != 0)
{
    printf("Fail to get file info\n");
    return -1;
}
printf("File size: %jd bytes\n", st.st_size);
```

위와 같은 동일한 코드와 컴파일 옵션으로 MinGW, Linux에서 둘 다 2GiB 이상의 파일을 정상적으로 다룰 수 있었다.

## 파일 크기를 문자열로 출력
참고로 파일의 크기를 숫자로만 출력하면 보기가 불편하여, 아래와 같이 입력 숫자에 대하여 1000 자리수마다 `,` 기호를 넣은 문자열을 리턴하는 함수를 작성하였다.
```c
char *print_num_to_str(long long num)
{
    static char integer_comma_str[30];
    char integer_str[30];
    int integer_len, i, j;
    
    /* 값을 문자열로 변환한다. */
    sprintf(integer_str, "%lld", num);
    
    /* 정수 문자열에서 1000 자리수 마다 ',' 기호를 넣어서 integer_comma_str[]에 넣는다. */
    integer_len = strlen(integer_str);
    memset(integer_comma_str, 0, sizeof(integer_comma_str));
    for (i = 0, j = integer_len + ((integer_len - 1) / 3) - 1; i < integer_len; i++, j--)
    {
        integer_comma_str[j] = integer_str[integer_len - i - 1];
        if (j > 0 && (i + 1) % 3 == 0)
        {
            integer_comma_str[--j] = ',';
        }
    }
    
    return integer_comma_str;
}
```

이제 아래와 같이 위 함수를 호출하여 파일의 크기를 출력하니 한결 보기가 좋아졌다.
```c
struct stat st;
if (stat(file_name, &st) != 0)
{
    printf("Fail to get file info\n");
    return -1;
}
printf("File size: %s bytes\n", print_num_to_str((long long)st.st_size));
```
