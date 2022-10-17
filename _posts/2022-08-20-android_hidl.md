---
title: "안드로이드 11에서 HIDL 작성 및 빌드"
category: Android
toc: true
toc_label: "이 페이지 목차"
---

AOSP에서 HIDL 소개 및 예제 코드를 작성/빌드/테스트하여 성공한 방법이다.  
<br>

회사 프로젝트에서 안드로이드 HAL(Hardware Abstraction Layer) 서비스를 구현할 일이 있어서 관련 예제를 구글링해 보았는데, 의외로 자료를 찾기가 쉽지가 않았다. 또 겨우 찾은 자료들도 기존 Android10 이하에서 **hardware/interfaces/** 디렉터리에 소스를 구성하는 예였다. 😓  
그런데 Android12 부터는 hardware/interfaces/ 디렉터리에 소스를 구성하는 것 보다는 **vendor/** 디렉터리에 구성하는 것이 좋아서, 직접 HIDL로 이렇게 구성해서 빌드 및 안드로이드 에뮬레이터로 테스트 해 보았고, 추후 참조 및 자료 공유 차원에서 자세히 기록을 남긴다.

## 안드로이드 HAL 참고 자료
- [HIDL](https://source.android.com/docs/core/architecture/hidl), [HIDL C++](https://source.android.com/docs/core/architecture/hidl-cpp)
- [Legacy HAL](https://source.android.com/devices/architecture/hal?hl=ko)
- [HAL type](https://source.android.com/devices/architecture/hal-types?hl=ko)
  
## 안드로이 HAL 요약
- HAL은 안드로이드에서 다양한 H/W와 연결을 지원하기 위한 방법으로, HAL 인터페이스를 정의하고 각 vendor에서 해당 인터페이스에 맞춰 드라이버 및 H/W 제작을 하도록 함으로써 유저 단에서 H/W 고려없이 H/W에 접근 및 통제가 가능하도록 해준다.
- HAL type (Android 8.0 이상): 다음 2가지 타입이 있음
  - **Passthrough**: 동일한 프로세스내 서버/클라이언트를 두어 진행하는 방식으로 현재는 지원하지 않는다. (Android 8로 upgrade되는 단말에 대해서만 지원함)
  - **Binder**: 하나의 프로세스에서 다른 프로세스의 함수 등을 호출할 때 연결해주기 위한 도구이다. 이러한 바인더는 안드로이드에서 서로 다른 APK 간의 통신에서 많이 사용하고 있으며 Android API에서 vendor사 HAL과 연결하는데에도 바인더를 이용한다.
- Legacy HAL (HAL module, Android 8.0 이전)
  - hardware/libhardware/include/hardware/hardware.h 파일에 저장된 hw_module_t 구조체를 사용한다.
  - HAL 모듈을 .so 파일로 만들고, JNI 파일로 이 so 파일을 엑세스 한다. (Framework - JNI - HAL - Hardware)
- Android 11버전 기준으로 바인더가 하나 더 추가되어(AIDL을 통해 HAL을 연결하는 바인더) 다음과 같이 3개의 바인더를 지원한다.
  - **/dev/binder**: AIDL 인터페이스를 통한 framework - app 간 IPC
  - **/dev/hwbinder**: HIDL을 통한 framework - vendor process 간 IPC 혹은 vendor process - vendor process 간 통신
  - **/dev/vnbinder**: AIDL을 통한 vendor process - vendor process 간의 통신
- `HIDL(HAL Interface Definition Language)`
  - HIDL은 /dev/hwbinder를 이용하며 framework와 vendor 프로세스, vendor 프로세스 간의 통신을 담당하는 인터페이스를 정의하기 위한 언어이다. HIDL을 이용해 바인딩함으로써 vendor 프로세스와의 통신을 가능하게 한다.  
  이는 JNI를 통한 HAL모듈과 같은 동작을 의미하며 HIDL 언어를 통해 모듈과 연결 및 송수신을 할 수 있도록 진행한다.
  - HIDL을 통해 작성한 <font color=blue>.hal</font> 파일을 <font color=blue>hidl-gen</font> 툴을 통해 실행하면 .cpp, .h 템플릿 파일이 만들어지고, 여기에 원하는 동작을 구현하면 된다.
  - HIDL은 서버/클라이언트 구조로 되어있으며 클라이언트는 함수를 호출하는 입장, 서버는 호출 신호를 수신하여 응답하는 역할이다. HIDL 공유 라이브러리를 통해 HIDL로 작성된 /dev/hwbinder를 사용할 수 있고 실제로 HW에 접근할 수 있게 된다.
- `AIDL(Android Interface Definition Language)`  
   Android 11버전부터는 vendor 내 프로세스 간의 통신에서도 AIDL을 사용할 수 있다.

## AOSP 소스 받기
1. 시스템에 repo 툴이 설치되어 있지 않은 상태이면, 아래 예와 같이 설치한다.
   ```shell
   $ mkdir ~/bin
   $ curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
   $ chmod a+x ~/bin/repo
   ```
1. 아래와 같이 `repo init` 명령을 실행한다.  
(`-b` 옵션으로 태그를 지정할 수 있음, 전체 태그 목록은 ["안드로이드 Codenames, Tags, and Build Numbers"](https://source.android.com/source/build-numbers.html#source-code-tags-and-builds) 페이지에서 확인할 수 있음)
   - Android 11 버전의 태그 예
     ```shell
     $ repo init -u https://android.googlesource.com/platform/manifest -b android-11.0.0_r33
     ```
   - Android 12 버전의 태그 예
     ```shell
     $ repo init -u https://android.googlesource.com/platform/manifest -b android-security-12.0.0_r38
     ```
   - 결과로 현재 디렉터리 밑에 **.repo** 디렉터리가 생성된다.
1. 이제 아래와 같이 `repo sync` 명령을 실행하면 안드로이드 소스를 다운로드 받는다. (시간이 오래 걸림)
   ```shell
   $ repo sync
   ```
   참고로 repo sync 명령으로 다운로드 받은 디렉터리에서 repo 시 사용한 태그 정보는 아래와 같이 얻을 수 있다. (내가 임시로 찾은 방법이고, 다른 정식 방법이 있을 듯함)
   ```shell
   $ ls .repo/manifests.git/refs/remotes/m/
   ```

## AOSP 빌드
1. 아래와 같이 환경 설정을 한다.
   ```shell
   $ source build/envsetup.sh
   ```
   아래 예와 같이 실행한 후, 메뉴에서 원하는 target을 고른다.
   ```shell
   $ lunch
   ```
   참고로 모든 타겟은 <font color=violet>BUILD</font>-<font color=blue>BUILDTYPE</font> 이름으로 구성되고, 이 중에 <font color=blue>BUILDTYPE</font>은 아래와 같이 3가지가 있다.
   - `user`: 액세스 제한, 양산용으로 적합
   - `userdebug`: user 빌드타입과 유사하지만 루트 액세스 및 디버그 기능이 있으며 디버깅에 적합
   - `eng`: 디버깅 도구가 추가된 개발 구성
   대부분의 개발 상황에서는 **userdebug**를 선택하면 된다.

   X86_64 환경에서 안드로이드 에뮬레이터로 테스트 할 용도라면 aosp_car_x86_64-userdebug, sdk_car_x86_64-userdebug 등에서 선택하면 편리하므로, 나는 **sdk_car_x86_64-userdebug** 타겟을 선택하였다. (여기에서 **car**는 자동차 플랫폼을 의미함)  
   또는 아래 예와 같이 원하는 target을 lunch 실행시 아규먼트로 주어 바로 실행시킬 수 있다.
   ```shell
   $ lunch sdk_car_x86_64-userdebug
   ```
1. 이제 아래와 같이 전체 빌드할 수 있다.
   ```shell
   $ m
   ```
1. 빌드가 완료되었으면 **out** 디렉터리에 이미지들이 생성된다. 타겟용으로 생성된 이미지는 아래와 같이 확인할 수 있다. (super.img 등)
   ```shell
   $ ll $OUT
   ```

## AOSP 에뮬레이터 실행
- AOSP에 포함된 안드로이드 `emulator` 실행 파일의 경로는 prebuilts/android-emulator/linux-x86_64/emulator 인데, lunch 스크립트에 의해 자동으로 PATH에 추가된다.

1. 사전 준비로 아래와 같이 현재 사용자를 **kvm** 그룹에 추가한다.
```shell
$ sudo gpasswd -a $USER kvm
```
1. GUI가 실행될 수 있는 환경에서 아래와 같이 실행하면 GUI 에뮬레이터가 실행된다.
```shell
$ emulator
```
1. 에뮬레이터가 실행되면 아래와 같이 ADB(Android Debug Bridge) 디바이스 목록에서 확인할 수 있다. (아래 예와 같이 에뮬레이터가 연결되었음)
```shell
$ adb devices
List of devices attached
emulator-5554   device
```
1. 필요하면 아래와 같이 ADB shell에 진입할 수 있다. (에뮬레이터 shell을 얻었음)
```shell
$ adb shell
emulator_car_x86_64:/ #
```
또는 에뮬레이터 실행시에 다음과 같이 `-shell` 옵션을 추가하면 Kernel 로그도 볼 수 있고, 바로 shell에 진입된다.
```shell
$ emulator -shell
```

## 내 HIDL 구현
참고한 예제 소스는 [Android-HIDL echo example](https://github.com/fadhel086/Android-HIDL) 코드인데, Android 12부터는 HIDL 소스가 **hardware/interfaces/** 디렉터리에 있으면 아래와 같은 에러 메시지가 출력되면서 HIDL 빌드가 안 된다.
```
"No more HIDL interfaces can be added to Android. Please use AIDL."
```
따라서 나는 **vendor/my/** 디렉터리 밑에 구성하였다. (이렇게 하니 Android 11, 12 모두 잘 되었음)  
구체적인 전체 작업 순서는 아래와 같다.

1. AOSP 소스의 base 디렉터리에서 아래와 같이 작업용 디렉터리를 생성한다. (버전은 **1.0**으로 하였음)
   ```shell
   $ mkdir -p vendor/my/echo/1.0/default
   ```
1. vendor/my/echo/1.0/IEcho.hal 파일을 아래 내용과 같이 생성한다.
   ```cpp
   package my.hardware.echo@1.0;

   interface IEcho {
       echo(string word) generates (string echo_word);
   };
   ```
1. 아래와 같이 `hidl-gen`을 실행한다.
   ```shell
   $ LOC=vendor/my/echo/1.0/default
   $ PACKAGE=my.hardware.echo@1.0
   $ hidl-gen -o $LOC -L c++-impl -r my.hardware:vendor/my/ -r android.hidl:system/libhidl/transport $PACKAGE
   ```
   결과로 다음 파일들이 생성된다.
   - vendor/my/echo/1.0/default/Echo.h
   - vendor/my/echo/1.0/default/Echo.cpp
1. vendor/my/echo/1.0/default/Echo.h 파일을 아래와 같이 수정한다.
   ```cpp
   #pragma once

   #include <my/hardware/echo/1.0/IEcho.h>
   #include <hidl/MQDescriptor.h>
   #include <hidl/Status.h>

   namespace my::hardware::echo::V1_0::implementation {

   using ::android::hardware::hidl_array;
   using ::android::hardware::hidl_memory;
   using ::android::hardware::hidl_string;
   using ::android::hardware::hidl_vec;
   using ::android::hardware::Return;
   using ::android::hardware::Void;
   using ::android::sp;

   struct Echo : public IEcho {
       // Methods from ::my::hardware::echo::V1_0::IEcho follow.
       Return<void> echo(const hidl_string& word, echo_cb _hidl_cb) override;

       // Methods from ::android::hidl::base::V1_0::IBase follow.
   };

   // FIXME: most likely delete, this is only for passthrough implementations
   extern "C" IEcho* HIDL_FETCH_IEcho(const char* name);

   }  // namespace my::hardware::echo::V1_0::implementation
   ```
1. vendor/my/echo/1.0/default/Echo.cpp 파일을 아래와 같이 수정한다.
   ```cpp
   #include "Echo.h"

   namespace my::hardware::echo::V1_0::implementation {

   // Methods from ::my::hardware::echo::V1_0::IEcho follow.
   Return<void> Echo::echo(const hidl_string& word, echo_cb _hidl_cb) {
       // Reply back what you get
       _hidl_cb(word);

       return Void();
   }

   // Methods from ::android::hidl::base::V1_0::IBase follow.

   IEcho* HIDL_FETCH_IEcho(const char* /* name */) {
       return new Echo();
   }

   }  // namespace my::hardware::echo::V1_0::implementation
   ```
1. 아래와 같이 실행한다.
   ```shell
   $ hidl-gen -o $LOC -L androidbp-impl -r my.hardware:vendor/my/ -r android.hidl:system/libhidl/transport $PACKAGE
   ```
   결과로 vendor/my/echo/1.0/default/Android.bp 파일이 생성된다.
1. 아래와 같이 실행한다.
   ```shell
   $ source system/tools/hidl/update-makefiles-helper.sh
   $ do_makefiles_update my.hardware:vendor/my/ "android.hidl:system/libhidl/transport"
   ```
   결과로 vendor/my/echo/1.0/Android.bp 파일이 생성된다.
1. vendor/my/echo/1.0/default/my.hardware.echo@1.0-service.rc 파일을 아래와 같이 작성한다. (즉, /vendor/bin/hw/my.hardware.echo@1.0-service 파일을 HAL 서비스로 실행시킴)
   ```yaml
   service echo_hal_service /vendor/bin/hw/my.hardware.echo@1.0-service
       class hal
       user root
       group root
       seclabel u:r:su:s0
   ```
1. vendor/my/echo/1.0/default/service.cpp 파일을 아래와 같이 작성한다.
   ```cpp
   #define LOG_TAG "my.hardware.echo@1.0-service"
   #include <my/hardware/echo/1.0/IEcho.h>
   #include <hidl/LegacySupport.h>

   using my::hardware::echo::V1_0::IEcho;
   using android::hardware::defaultPassthroughServiceImplementation;

   int main() {
       ALOGI("Echo service main");
       return defaultPassthroughServiceImplementation<IEcho>();
   }
   ```
1. vendor/my/echo/1.0/default/Android.bp 파일에 아래 내용을 추가한다. (서비스 실행 파일 빌드)
   ```yaml
   cc_binary {
       name: "my.hardware.echo@1.0-service",
       defaults: ["hidl_defaults"],
       proprietary: true,
       relative_install_path: "hw",
       init_rc: ["my.hardware.echo@1.0-service.rc"],
       srcs: ["service.cpp"],

       shared_libs: [
           "my.hardware.echo@1.0",
           "libhidlbase",
           "libhidltransport",
           "liblog",
           "libbase",
           "libdl",
           "libhidlbase",
           "libutils",
       ],
   }
   ```
   참고로 위에서 `init_rc` 항목으로 설정한 파일은 빌드시 vendor/etc/init/ 디렉터리 밑에 복사된다. (Android.mk 파일에서는 `LOCAL_INIT_RC` 항목에 해당함)  
   빌드 후에, 아래와 같이 확인할 수 있다.
   ```shell
   $ ls $OUT/vendor/etc/init/my.hardware.echo@1.0-service.rc
   ```
1. vendor/my/Android.bp 파일을 아래와 같이 작성한다.
   ```yaml
   hidl_package_root {
       name: "my.hardware",
       path: "vendor/my",
   }
   optional_subdirs = [
       "echo/1.0",
   ]
   ```
1. 타겟 디바이스의 manifest.xml 파일에서 (여기서는 안드로이드 에뮬레이터를 사용하므로 **device/generic/goldfish/manifest.xml** 파일이 됨) 아래 내용을 추가한다.  
   ```xml
   <hal format="hidl">
       <name>my.hardware.echo</name>
       <transport>hwbinder</transport>
       <version>1.0</version>
       <interface>
           <name>IEcho</name>
           <instance>default</instance>
       </interface>
   </hal>
   ```
   > 이 작업을 하지 않으면 디폴트로 Android SELinux에 의해, service 실행되고 registerAsService() 호출시 "HidlServiceManagement: Service my.hardware.echo@1.0::IEcho/default must be in VINTF manifest in order to register/get"과 같은 에러 메시지가 출력되면서 서비스가 등록되지 않게 된다.

   또 안드로이드는 디폴트로 SEPolicy가 적용되므로, SELinux에 해당 서비스 실행을 위하여 <font color=blue>TE</font>(Type Enforcement) 파일에 (여기서는 에뮬레이터를 사용하므로 **device/generic/goldfish/sepolicy/common/init.te** 파일) 아래 내용을 추가하여 필요한 권한을 허용해 준다.
   ```yaml
   allow init vendor_file:file { execute };
   allow init su:process { transition };
   ```
   만약에 SELinux에 허용을 추가해 주지 않으면 서비스 실행시 아래와 같은 <font color=red>denied</font> 에러가 발생하면서 해당 서비스가 실행되지 않는다.
   ```
   avc: denied { execute } for comm="init" name="my.hardware.echo@1.0-service" dev="dm-3" ino=121 scontext=u:r:init:s0 tcontext=u:object_r:vendor_file:s0 tclass=file permissive=0
   ```
   만약에 서비스가 SELinux 권한 문제로 실행이 되지 않으면 `dmesg` 명령으로 **avc: denied** 메시지를 찾아서, [SELinux](https://source.android.com/docs/security/features/selinux?hl=ko) 페이지를 참조하여 TE 파일에서 추가로 필요한 권한을 허용해 주어야 한다.
1. 서비스 테스트를 위해 vendor/my/echo/1.0/test/echoTest.cpp 파일을 아래와 같이 작성한다. (입력된 아규먼트를 그대로 출력하는 테스트 코드)
   ```cpp
   #include <my/hardware/echo/1.0/IEcho.h>
   #include <hidl/Status.h>
   #include <hidl/LegacySupport.h>
   #include <utils/misc.h>
   #include <hidl/HidlSupport.h>
   #include <iostream>
   #include <cstdlib>
   #include <string>

   using my::hardware::echo::V1_0::IEcho;
   using android::hardware::hidl_string;
   using ::android::sp;

   int main(int argc, char *argv[])
   {
       std::string str;
       if (argc < 2) {
           // Exit the application from here
           std::cout << "USAGE ./echo_client <string to echo>\n";
           exit(0);
       } else {
           // Get the Text from user to be echoed
           int i = 1;
           while (argv[i]) {
               str += argv[i];
               str += " ";
               ++i;
           }
       }

       android::sp<IEcho> service = IEcho::getService();
       if (service == nullptr) {
           std::cout << "Failed to get echo service\n";
           exit(-1);
       }

       service->echo(str, [&](hidl_string result) {
           std::cout << "ECHO_HAL: " << result << std::endl;
       });

       return 0;
   }
   ```

   또, vendor/my/echo/1.0/test/Android.bp 파일을 아래와 같이 작성한다. (즉, 테스트 프로그램인 /vendor/bin/hw/echo_client를 빌드하기 위하여 echoTest.cpp를 사용함)
   ```yaml
   cc_binary {
       relative_install_path: "hw",
       defaults: ["hidl_defaults"],
       name: "echo_client",
       proprietary: true,
       srcs: ["echoTest.cpp"],

       shared_libs: [
           "liblog",
           "libhardware",
           "libhidlbase",
           "libhidltransport",
           "libutils",
           "my.hardware.echo@1.0",
       ],
   }
   ```
1. 아래와 같이 빌드한다.
   ```shell
   $ mmm vendor/my/
   $ m
   ```
   결과로 아래와 같이 테스트 실행 파일이 빌드된다.
   ```shell
   $ ls $OUT/vendor/bin/hw/echo_client
   ```
   또, 아래와 같이 라이브러리가 빌드되었음을 확인할 수 있다.
   ```shell
   $ ls $OUT/vendor/lib64/*echo*
   my.hardware.echo@1.0-adapter-helper.so
   my.hardware.echo@1.0.so

   $ ls $OUT/vendor/lib64/hw/*echo*
   my.hardware.echo@1.0-impl.so
   ```
1. 빌드가 끝났으므로, 이제 테스트를 위해 안드로이드 에뮬레이터를 실행한다.
   ```shell
   $ emulator
   ```
1. 아래와 같이 ADB shell을 실행하면 shell을 얻을 수 있다.
   ```shell
   $ adb shell
   ```
   또는 별도로 ADB shell을 띄우는 대신에 아래와 같이 에뮬레이터 실행시에 `-shell` 옵션을 주면 바로 shell로 접근할 수 있다.
   ```shell
   $ emulator -shell
   ```
1. 이후 ADB shell에서 아래와 같이 해당 서비스가 실행 중인지 확인할 수 있다.
   ```shell
   $ lshal | grep echo
   DM    N my.hardware.echo@1.0::IEcho/default                            0/1        400    173
   X     ? my.hardware.echo@1.0::IEcho/default                            N/A        400    400
   X     ? my.hardware.echo@1.0::I*/* (/vendor/lib/hw/)                   N/A        N/A
   X     ? my.hardware.echo@1.0::I*/* (/vendor/lib64/hw/)                 N/A        N/A    400
   $ ls /vendor/lib/hw/ | grep echo
   my.hardware.echo@1.0-impl.so
   $ ls /vendor/bin/hw/my.hardware.echo@1.0-service
   /vendor/bin/hw/my.hardware.echo@1.0-service
   $ ps -A | grep echo
   root           400     1 10906332  5156 binder_wait_for_work 0 S my.hardware.echo@1.0-service
   ```
   이제 echo_client 테스트 프로그램으로 아래 예와 같이 테스트를 해 보면, 기대대로 정상 동작함을 확인할 수 있다.
   ```shell
   $ /vendor/bin/hw/echo_client Hellow world
   ECHO_HAL: Hellow world
   ```

## 맺음말
오랜만에 Android 관련 개발 중에서 자료를 찾기 힘든 HIDL을 이용한 HAL 서비스를 구현해 보았다. 실제로 위와 같이 Android 에뮬레이터로 기본적인 구현을 해 본 후, 실제 프로젝트에서도 성공적으로 구현할 수 있었다.  
인터넷에서 관련 자료를 찾기가 쉽지가 않아서, 기본적인 내용이지만 (실제 프로젝트에서는 빌드 구성, 소스, SEPolicy 등이 훨씬 복잡해짐) 공유 및 기록 차원에서 포스팅 하였다. 😅
