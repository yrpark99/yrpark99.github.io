---
title: "안드로이드 Java console app 작성하기"
category: [Android]
toc: true
toc_label: "이 페이지 목차"
---

안드로이드에서 Java로 일반적인 CLI 콘솔 앱을 작성해 보았다.  
<br>

간단한 디버깅이나 테스트 용도로 GUI 앱보다 CLI 콘솔 앱을 작성하는 것이 더 편리한 경우가 생겨서 시도해서 성공하였고, 이 글에서는 다음 2가지 예를 들겠다.
- 단순히 콘솔에 출력하는 예제
- 내가 예전에 구현했었던 [HIDL 서비스](https://yrpark99.github.io/android/android_hidl/)를 사용하는 예제

## Java console app
Android ART(Android Run Time)에서는 class 파일은 실행시킬 수 없고 **dex** 파일을 실행시킬 수 있으므로, class 파일을 **dex** 파일로 변환시켜야 한다.  
이후 **app_process** 툴을 이용하여, dex 파일이나 dex 파일을 포함한 jar 파일을 실행시킬 수 있다. 여기서는 jar 파일을 빌드하여 이를 실행시키는 방법을 예로 들겠다.

## 단순 콘솔 출력 예제
1. AOSP base 디렉토리에서 아래와 같이 빌드 환경을 설정한다.
   ```sh
   $ source build/envsetup.sh
   $ lunch {메뉴}
   ```
1. 아래 예와 같이 테스트할 base 디렉토리를 생성한 후에 이동한다.
   ```sh
   $ mkdir vendor/console_test
   $ cd vendor/console_test/
   ```
1. 이 경로에서 HelloWorld.java 파일을 아래와 같이 작성한다.
   ```java
   public class HelloWorld {
       public static void main(String[] args) {
           System.out.println("Hello world!");
       }
   }
   ```
1. 아래와 같이 java 파일을 빌드하여 class 파일을 얻고, 이것을 **dex** 파일로 변환한 후, **jar** 파일로 묶는다.
   - 방법 1: 수동 빌드  
     아래와 같이 빌드한다.
     ```sh
     $ javac HelloWorld.java
     ```
     결과로 HelloWorld.class 파일이 빌드된다.
     아래와 같이 class 파일들을 dex 파일로 변환시킨다.
     ```sh
     $ d8 *.class
     ```
     결과로 classes.dex 파일이 빌드된다.
     아래와 같이 dex 파일로 jar 파일을 생성한다. (자동으로 `Manifest`가 추가됨)
     ```sh
     $ jar -cvf HelloWorld.jar *.dex
     ```
     결과로 HelloWorld.jar 파일이 생성된다. 참고로 결과로 생성된 jar 파일을 보면 아래와 같이 구성되어 있다.
     ```sh
     $ jar -tf HelloWorld.jar
     META-INF/
     META-INF/MANIFEST.MF
     classes.dex
     ```
   - 방법 2: 빌드 시스템에 포함  
     Android 빌드 시스템에 포함시키려면, vendor/console_test/Android.mk 파일을 아래 예와 같이 작성한다.
     ```makefile
     LOCAL_PATH := $(call my-dir)

     include $(CLEAR_VARS)

     LOCAL_MODULE := HelloWorld
     LOCAL_SRC_FILES := HelloWorld.java
     LOCAL_MODULE_CLASS := EXECUTABLES
     LOCAL_MODULE_PATH := $(TARGET_OUT_VENDOR)/bin/

     include $(BUILD_JAVA_LIBRARY)
     ```
     이후 해당 디렉토리에서 아래와 같이 Android 빌드 시스템을 이용하여 빌드할 수 있다.
     ```sh
     $ mm
     ```
     결과로 `$OUT/vendor/bin/HelloWorld.jar` 파일이 빌드된다. 마찬가지로 jar 파일의 구성을 확인해 보면 다음과 같이 나온다.
     ```sh
     $ jar -tf $OUT/vendor/bin/HelloWorld.jar
     META-INF/MANIFEST.MF
     classes.dex
     ```
1. 빌드된 jar 파일을 아래 예와 같이 ADB로 타겟 디바이스에 push 한다.
   ```sh
   adb push vendor/console_test/HelloWorld.jar /data/local/tmp/
   ```
   또는 Android 빌드 시스템에 포함된 방법으로 jar 파일을 빌드한 경우에는 아래 예와 같이 push 한다.
   ```sh
   adb push $OUT/vendor/bin/HelloWorld.jar /data/local/tmp/
   ```
1. 이제 타겟 디바이스에 ADB shell로 접속한 후에, **app_process** 툴을 이용하여 아래 예와 같이 실행시킬 수 있다.
   ```java
   / $ CLASSPATH=/data/local/tmp/HelloWorld.jar app_process / HelloWorld
   Hello world!
   ```

## HIDL 서비스 사용 예제
이번에는 HIDL 서비스를 사용하는 Java console app를 작성해본다.  
여기서는 예제로 [안드로이드에서 HIDL 작성, 빌드 및 테스트](https://yrpark99.github.io/android/android_hidl/) 글에서 작성했었던 HIDL 시스템 서비스인 "vendor.my.system"을 이용한다.
1. AOSP base 디렉토리에서 아래와 같이 테스트할 base 디렉토리를 생성한 후에 이동한다.
   ```sh
   $ mkdir vendor/java_console_hidl
   $ cd vendor/java_console_hidl/
   ```
1. 이 경로에서 JavaSystemTest.java 파일을 아래 내용으로 작성한다.
   ```java
   package vendor.java_console_hidl;

   import android.util.Log;

   public class JavaSystemTest {
       private static final String TAG = "JavaSystemTest";

       public static void main(String[] args) {
           Log.i(TAG, "Call HidlTest()");
           int rc = HidlTest.HidlSystemTest();
           String str = "Call HidlTest() is done, rc=" + String.valueOf(rc);
           Log.i(TAG, str);
       }
   }
   ```
   또, 아래 예와 같이 HidlTest.java 파일을 작성한다. (파일은 1개로 하는 것이 더 편리하지만, 여기서는 의도적으로 복잡도를 높이기 위하여 2개로 분리하였음)
   ```java
   package vendor.java_console_hidl;

   import android.os.RemoteException;
   import android.os.SystemClock;
   import android.util.Log;

   import vendor.my.system.V1_0.ISystem;

   public class HidlTest {
       private static final String TAG = "HidlTest";

       public static int HidlSystemTest() {
           ISystem system;
           try {
               Log.i(TAG, "Get HIDL system service");
               system = ISystem.getService();
           } catch (RemoteException e) {
               Log.e(TAG, "Failed to get system service: " + e.toString());
               return -1;
           }
           Log.i(TAG, "Get HIDL system service is done");

           int value = 3;
           Log.i(TAG, "Call HIDL systemTest(" + String.valueOf(value) + ")");
           long start_time = System.currentTimeMillis();
           int rc = -1;
           try {
               rc = system.systemTest(value);
           } catch (RemoteException e) {
               Log.e(TAG, "Failed to call HIDL systemTest(): " + e.toString());
               return -1;
           }
           long end_time = System.currentTimeMillis();
           String str = "Elapsed time=" + String.valueOf(end_time - start_time) + "msec, rc=" + String.valueOf(rc);
           Log.i(TAG, str);
           return rc;
       }
   }
   ```
1. 아래와 같이 java 파일들을 빌드하여 class 파일들을 얻고, 이것을 **dex** 파일로 변환한 후, **jar** 파일로 묶는다.
   - 방법 1: 수동 빌드  
     아래와 같이 빌드한다. (이 console app은 Android 시스템과 HIDL 서비스를 사용하므로, 아래 예와 같이 class path를 지정해서 빌드해야 성공함)
     ```sh
     $ export ANDROID_JAR=$ANDROID_BUILD_TOP/prebuilts/sdk/34/system/android.jar
     $ export HIDL_BASE_JAR=$ANDROID_BUILD_TOP/out/target/common/obj/JAVA_LIBRARIES/android.hidl.base-V1.0-java_intermediates/classes.jar
     $ export VENDOR_MY_SYSTEM_JAR=$ANDROID_BUILD_TOP/out/target/common/obj/JAVA_LIBRARIES/vendor.my.system-V1.0-java_intermediates/classes.jar
     $ javac -classpath $ANDROID_JAR:$HIDL_BASE_JAR:$VENDOR_MY_SYSTEM_JAR *.java
     ```
     결과로 HidlSystemTest.class, JavaSystemTest.class 파일이 빌드된다.
     안드로이드 ART(Android Run Time)에서 실행시키기 위해서 아래와 같이 class 파일들을 **dex** 파일로 변환시킨다.
     ```sh
     $ d8 --classpath $ANDROID_JAR $VENDOR_MY_SYSTEM_JAR *.class
     ```
     결과로 classes.dex 파일이 생성된다.
     아래와 같이 **dex** 파일로부터 **jar** 파일을 생성한다. (자동으로 `Manifest`가 추가됨)
     ```sh
     $ jar -cvf JavaSystemTest.jar *.dex
     ```
     참고로 결과로 생성된 jar 파일을 보면 아래와 같이 구성되어 있다.
     ```sh
     $ jar -tf JavaSystemTest.jar
     META-INF/
     META-INF/MANIFEST.MF
     classes.dex
     ```
   - 방법 2: 빌드 시스템에 포함  
     위와 같은 수동 빌드 대신에 Android 빌드 시스템에 포함시키려면 vendor/java_console_hidl/Android.mk 파일을 아래와 같이 작성한다.
     ```makefile
     LOCAL_PATH := $(call my-dir)

     include $(CLEAR_VARS)

     LOCAL_MODULE := JavaSystemTest
     LOCAL_SRC_FILES := JavaSystemTest.java HidlTest.java
     LOCAL_MODULE_CLASS := EXECUTABLES
     LOCAL_MODULE_PATH := $(TARGET_OUT_VENDOR)/bin/

     LOCAL_STATIC_JAVA_LIBRARIES := \
         android.hidl.base-V1.0-java \
         vendor.my.system-V1.0-java

     include $(BUILD_JAVA_LIBRARY)
     ```
     이후 해당 디렉토리에서 아래와 같이 Android 빌드 시스템을 이용하여 빌드할 수 있다.
     ```sh
     $ mm
     ```
     결과로 $OUT/vendor/bin/JavaSystemTest.jar 파일이 빌드된다. 마찬가지로 구성을 확인해 보면 다음과 같이 나온다.
     ```sh
     $ jar -tf $OUT/vendor/bin/JavaSystemTest.jar
     META-INF/MANIFEST.MF
     classes.dex
     ```
1. 빌드된 JavaSystemTest.jar 파일을 아래 예와 같이 ADB로 타겟 디바이스에 push 한다.
   ```sh
   adb push vendor/java_console_hidl/JavaSystemTest.jar /data/local/tmp/
   ```
   또는 Android 빌드 시스템에 포함된 방법으로 jar 파일을 빌드한 경우에는 아래 예와 같이 push 한다.
   ```sh
   adb push $OUT/vendor/bin/JavaSystemTest.jar /data/local/tmp/
   ```
1. 이제 타겟 디바이스에 ADB shell로 접속한 후에, **app_process** 툴을 이용하여 아래 예와 같이 실행시킬 수 있다.
   ```java
   / # CLASSPATH=/data/local/tmp/JavaSystemTest.jar app_process / vendor.java_console_hidl.JavaSystemTest
   ```
   또는 아래와 같이 패키지와 클래스 이름을 `/` 문자로 구분하여 실행시킬 수도 있다.
   ```java
   / # CLASSPATH=/data/local/tmp/JavaSystemTest.jar app_process / vendor.java_console_hidl/JavaSystemTest
   ```
   Logcat 로그도 확인해 보면, 아래 예와 같이 기대대로 출력된다.
   ```sh
   $ logcat -s JavaSystemTest HidlTest
   15:08:00.676 26403 26403 I JavaSystemTest: Call HidlTest()
   15:08:00.676 26403 26403 I HidlTest: Get HIDL system service
   15:08:00.679 26403 26403 I HidlTest: Get HIDL system service is done
   15:08:00.679 26403 26403 I HidlTest: Call HIDL systemTest(3)
   15:08:03.679 26403 26403 I HidlTest: Elapsed time=3000msec, rc=0
   15:08:03.679 26403 26403 I JavaSystemTest: Call HidlTest() is done, rc=0
   ```

## 맺음말
이와 같은 방법으로 필요에 따라서 디버깅이나 테스트 용도로 C/C++ 콘솔 앱 외에도 Java 콘솔 앱을 작성해서 테스트할 수 있게 되어서 편리해졌다. 👍
