---
title: "안드로이드 앱에서 pre-built 라이브러리 사용하기"
category: android
toc: true
toc_label: "이 페이지 목차"
---

안드로이드 앱 개발시 pre-built 된 정적/동적 라이브러리를 사용하는 방법을 기술한다.

<br>
오랜만에 안드로이드 테스트 앱을 작성할 필요가 생겼는데, 안드로이드 앱에서 C로 짠 pre-built 된 정적 라이브러리를 호출해야 했다. 관련하여 작업을 하고 블로그에 방법을 정리해 보았다.

## Native C/C++ 예제 앱 준비
안드로이드 앱에서 Native C/C++ 라이브러리 호출은 JNI를 통해서 할 수 있다.  
여기서는 전체 코드를 나열하지 않고 필요한 부분만 설명하기 위하여 안드로이드 스튜디오에서 제공하는 템플릿을 이용하기로 한다.  
안드로이드 스튜디오에서 "Create New Project" -> "Phone and Table" 탭 -> "Native C++" 템플릿을 선택한다. 여기서는 프로젝트 이름을 `LibTest`로 하였고, 패키지 이름은 자동으로 생성되는 `com.example.libtest`를 그대로 사용하였다.  
결과로 `app/src/main/cpp/` 디렉토리 밑에 `CMakeLists.txt` 파일과 `native-lib.cpp` 파일이 생성된다.

## ADB 연결
안드로이드 기기에서 실행시키려면 platform-tools 디렉토리에서 아래 예와 같이 ADB를 연결시킨다. (예로 안드로이드 기기의 IP는 **192.168.0.103**이라고 가정)
```sh
adb connect 192.168.0.103
```

## Native C/C++ 예제 앱 실행
이 앱을 실행시키면 `app/src/main/java/com/example/libtest/MainActivity.java` 파일에서 **stringFromJNI()** 함수를 호출하고, 결과로 `app/src/main/cpp/native-lib.cpp` 파일에 있는 **Java_com_example_libtest_MainActivity_stringFromJNI()** 함수를 호출한다.
> JNI 함수명은 규약에 따라 `Java_패키지명_클래스명_함수명` 이라야 한다.

앱 실행 결과로 화면에 "Hello from C++" 메시지가 출력된다.

그런데 이 예제 앱은 cpp 코드가 있고 이것을 CMake에 의해 빌드하여 라이브러리를 생성하고, 이것을 안드로이드 앱에서 이용하고 있었다.  
하지만 나는 앱에서 3rd party에서 릴리즈하는 pre-built 된 정적 라이브러리를 사용해야 했으므로, 관련하여 한참을 구글링 한 끝에 방법을 찾아서 본 블로그에 정리해 보았다. 😅

## Pre-built 라이브러리 준비
여기서는 사전에 정적 라이브러리를 빌드해 놓고, 이것을 안드로이드 앱에서 사용하는 경우를 예로 들었다. (동적 라이브러리인 경우도 거의 유사하므로 생략)  
이 pre-built 라이브러리는 안드로이드 앱과는 무관하므로 별도의 디렉토리를 생성하고, 여기에서 testlib.c 파일을 아래 예와 같이 minus 기능의 함수를 작성한다.
```c
#include "testlib.h"

int testFunc(int a, int b)
{
    return a - b;
}
```
testlib.h 파일은 아래와 같이 작성한다.
```c
#ifndef __TEST_LIB_H__
#define __TEST_LIB_H__

#ifdef __cplusplus
extern "C" {
#endif

int testFunc(int a, int b);

#ifdef __cplusplus
}
#endif

#endif
```

빌드는 `clang`과 `llvm`으로 할 것이므로, 패키지가 아직 설치되어 있지 않은 상태이면 아래와 같이 설치한다.
```sh
$ sudo apt install clang
$ sudo apt install llvm
```

이후 아래와 같이 clang으로 빌드하면, `libmytest.a` 정적 라이브러리가 생성된다.
```sh
$ clang -fPIC -msoft-float -march=armv7-a -mfloat-abi=softfp -mfpu=neon -target armv7a-linux-androideabi -mthumb -c testlib.c
$ llvm-ar rscv libmytest.a testlib.o
```
참고로 아키텍쳐별 target 값은 아래 표와 같다.

|Name|arch|ABI|triple|
|:---:|:---:|:---:|:----:|
|32-bit ARMv7|arm|armeabi-v7a|arm-linux-androideabi|
|64-bit ARMv8|aarch64|aarch64-v8a|aarch64-linux-android|
|32-bit Intel|x86|x86|i686-linux-android|
|64-bit Intel|x86_64|x86_64|x86_64-linux-android|

빌드의 결과물인 libmytest.a 파일과 헤더 파일인 testlib.h 파일을 앱의 `app/libs/` 디렉토리에 복사한다.

## JNI 준비
app/src/main/cpp/native-lib.cpp 파일에서 아래와 같이 testFunc() JNI를 작성한다. (즉, libmytest.a 라이브러리가 제공하는 testFunc() 함수를 호출함)
```c
#include "../../../libs/testlib.h"

extern "C" JNIEXPORT jint JNICALL
Java_com_example_libtest_MainActivity_testFunc(
    JNIEnv *env,
	  jobject /* this */,
	  jint value1,
	  jint value2) {
	  return testFunc(value1, value2);
}
```
> 마찬가지로 JNI 함수명은 규약에 따라 `Java_패키지명_클래스명_함수명` 이라야 한다.

## CMake 추가
안드로이드 앱 프로젝트의 app/src/main/cpp/CMakeLists.txt 파일에서 아래와 같이 추가한다. (즉, 정적 라이브러리를 사용하도록 세팅함)
```cmake
set(LIBPATH ${CMAKE_CURRENT_SOURCE_DIR}/../../../libs/)
include_directories(${LIBPATH})
add_library(mytest STATIC IMPORTED)
set_target_properties(mytest PROPERTIES IMPORTED_LOCATION ${LIBPATH}/libmytest.a)

target_link_libraries(native-lib mytest ${log-lib})
```

## 자바 코드에서 호출
이제 app/src/main/java/com/example/libtest/MainActivity.java 파일에서 prebuilt 라이브러리의 API를 아래와 같이 호출할 수 있다.
```java
public class MainActivity extends AppCompatActivity {
    static {
        System.loadLibrary("native-lib");
    }

    protected void onCreate(Bundle savedInstanceState) {
        // ...
        tv.setText(Integer.toString(testFunc(10, 3)));
    }

    public native int testFunc(int value1, int value2);
}
```
이제 앱을 실행해보면 예상대로 화면에 `10 - 3`의 계산값인 **7**이 정상적으로 출력된다.
