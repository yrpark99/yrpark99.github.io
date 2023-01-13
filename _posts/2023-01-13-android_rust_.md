---
title: "Android에서 Rust로 Native 서비스 작성하기"
category: [Android, Rust]
toc: true
toc_label: "이 페이지 목차"
---

Android 11부터 지원되는 Rust로 Native 서비스를 구현 및 테스트 해 본다.

## 서론
안드로이드 11부터는 네이티브 OS 구성 요소를 개발하기 위하여 Rust를 사용할 수 있다.  
Rust를 지원하는 이유는 Rust로 구현시 기존 C/C++로 구현했을 때보다 보안 취약점이 획기적으로 줄기 때문이다. 실제로 구글은 안드로이드에서 Rust의 사용 비중을 계속해서 올리고 있고, 결과로 보안 취약점이 획기적으로 줄어들고 있다고 밝혔다. ([구글이 안드로이드OS를 러스트로 짜는 이유](https://zdnet.co.kr/view/?no=20230102112009#_enliple) 기사 참조)  

<br>
여기서는 구글이 제공하는 Rust 예제를 AOSP와 에뮬레이터를 이용하여 간단히 실습해 보고 정리해 보았다.

## AOSP 소스 받기
[안드로이드 Codenames, Tags, and Build Numbers](https://source.android.com/source/build-numbers.html#source-code-tags-and-builds) 페이지에서 안드로이드 전체 태그 목록을 확인하여 사용할 태그를 선택한다. 이 글에서는 Android 12 중에서 최신 태그인 `android-12.1.0_r27`을 선택하였다.

1. 작업용 디렉터리를 만든 후에 이 디렉터리로 이동한다.
1. 아래와 같이 `repo init` 명령을 실행한다.
   ```sh
   $ repo init -u https://android.googlesource.com/platform/manifest -b android-12.1.0_r27
   ```
   결과로 현재 디렉터리 밑에 **.repo** 디렉터리가 생성된다.  
1. 이제 아래와 같이 `repo sync` 명령을 실행하면 안드로이드 소스를 다운로드 받는다. (시간이 오래 걸림)
   ```sh
   $ repo sync
   ```

## AOSP 빌드
1. 아래와 같이 빌드 환경 스크립트를 실행한다.
   ```sh
   $ source build/envsetup.sh
   ```
1. 아래 예와 같이 점심 메뉴로 적절히 타겟을 선택한다.
   ```sh
   $ lunch sdk_car_x86_64-userdebug
   ```
1. 이제 아래와 같이 전체 빌드할 수 있다.
   ```sh
   $ m
   ```

## Rust 모듈 위치
현재 Rust 모듈은 `build/soong/rust/config/allowed_list.go` 파일에서 **<font color=purple>RustAllowedPaths</font>** 이름으로 정의된 특정 디렉터리에 위치해야만 한다. 이 글에서는 이 중에서 **external/rust** 경로를 사용하기로 한다.

## Rust 바이너리 예제
1. 빌드를 위해 **external/rust/hello_rust/Android.bp** 파일을 아래와 같이 작성한다.
   ```json
   rust_binary {
       name: "hello_rust",
       crate_name: "hello_rust",
       srcs: ["src/main.rs"],
   }
   ```
1. Rust 소스로 **external/rust/hello_rust/src/main.rs** 파일을 아래와 같이 작성한다.
   ```rust
   fn main() {
       println!("Hello from Rust!");
   }
   ```
1. 아래와 같이 빌드한다.
   ```sh
   $ m hello_rust
   ```
   빌드 결과로 나온 실행 파일을 확인해 본다.
   ```sh
   $ ls $OUT/system/bin/hello_rust
   ```
1. GUI가 실행될 수 있는 환경에서 아래와 같이 실행하면 GUI 안드로이드 에뮬레이터가 실행된다.
   ```sh
   $ emulator
   ```
   안드로이드 에뮬레이터가 실행되면 아래와 같이 ADB(Android Debug Bridge) 디바이스 목록에서 확인할 수 있다. (정상적이라면 아래와 같이 에뮬레이터가 연결된 것이 보임)
   ```sh
   $ adb devices
   List of devices attached
   emulator-5554   device
   ```
1. 아래와 같이 ADB를 이용하여 **hello_rust**를 push 한다.
   ```sh
   $ adb push $OUT/system/bin/hello_rust /data/local/tmp
   ```
   아래와 같이 ADB를 이용하여 **hello_rust**를 실행하면 기대대로 문자열이 출력된다.
   ```sh
   $ adb shell /data/local/tmp/hello_rust
   Hello from Rust!
   ```

## Rust 라이브러리 예제
1. 빌드를 위해 **external/rust/hello_rust_lib/Android.bp** 파일을 아래와 같이 작성한다. (참고로 **libtextwrap**는 **external/rust/crates/textwrap/** 경로에 이미 있는 lib이고, **libgreetings**가 지금 구현하는 lib임)
   ```json
   rust_binary {
       name: "hello_rust_with_dep",
       crate_name: "hello_rust_with_dep",
       srcs: ["src/main.rs"],
       rustlibs: [
           "libgreetings",
           "libtextwrap",
       ],
       prefer_rlib: true,
   }

   rust_library {
       name: "libgreetings",
       crate_name: "greetings",
       srcs: ["src/lib.rs"],
   }
   ```
1. Rust main 소스로 **external/rust/hello_rust_lib/src/main.rs** 파일을 아래와 같이 작성한다.
   ```rust
   use greetings::greeting;
   use textwrap::fill;

   fn main() {
       println!("{}", fill(&greeting("Bob"), 24));
   }
   ```
1. Rust 라이브러리 소스로 **external/rust/hello_rust/src/lib.rs** 파일을 아래와 같이 작성한다.
   ```rust
   #![feature(format_args_capture)]
   pub fn greeting(name: &str) -> String {
       format!("Hello {name}, it is very nice to meet you!")
   }
   ```
1. 아래와 같이 빌드한다.
   ```sh
   $ m hello_rust_with_dep
   ```
   빌드 결과로 나온 실행 파일을 확인해 본다.
   ```sh
   $ ls $OUT/system/bin/hello_rust_with_dep
   ```
1. 안드로이드 에뮬레이터가 띄워진 상태에서 아래와 같이 ADB를 이용하여 push 한다.
   ```sh
   $ adb push $OUT/system/bin/hello_rust_with_dep /data/local/tmp
   ```
1. 아래와 같이 ADB를 이용하여 실행하면 기대대로 문자열이 출력된다.
   ```sh
   $ adb shell /data/local/tmp/hello_rust_with_dep
   Hello Bob, it is very
   nice to meet you!
   ```

## Rust AIDL 서비스 예제
1. AIDL 인터페이스 선언을 한다.  
   **external/rust/birthday_service/aidl/com/example/birthdayservice/IBirthdayService.aidl** 파일을 아래와 같이 작성한다.
   ```java
   package com.example.birthdayservice;

   interface IBirthdayService {
       String wishHappyBirthday(String name, int years);
   }
   ```
   또, 빌드를 위해 **external/rust/birthday_service/aidl/Android.bp** 파일을 아래와 같이 작성한다.
   ```json
   aidl_interface {
       name: "com.example.birthdayservice",
       srcs: ["com/example/birthdayservice/*.aidl"],
       unstable: true,
       backend: {
           rust: {
               enabled: true,
           },
       },
   }
   ```
1. Rust로 AIDL 서비스 구현을 위해 **external/rust/birthday_service/src/lib.rs** 파일을 아래와 같이 작성한다.
   ```rust
   #![feature(format_args_capture)]

   use com_example_birthdayservice::aidl::com::example::birthdayservice::IBirthdayService::IBirthdayService;
   use com_example_birthdayservice::binder;

   pub struct BirthdayService;

   impl binder::Interface for BirthdayService {}

   impl IBirthdayService for BirthdayService {
       fn wishHappyBirthday(&self, name: &str, years: i32) -> binder::Result<String> {
           Ok(format!(
               "Happy Birthday {name}, congratulations with the {years} years!"
           ))
       }
   }
   ```
   또, 빌드를 위해 **external/rust/birthday_service/Android.bp** 파일을 아래와 같이 작성한다.
   ```json
   rust_library {
       name: "libbirthdayservice",
       srcs: ["src/lib.rs"],
       crate_name: "birthdayservice",
       rustlibs: [
           "com.example.birthdayservice-rust",
           "libbinder_rs",
       ],
   }
   ```
1. 이제 서비스를 노출시키는 서버로 **external/rust/birthday_service/src/server.rs** 파일을 아래와 같이 작성한다.
   ```rust
   use birthdayservice::BirthdayService;
   use com_example_birthdayservice::aidl::com::example::birthdayservice::IBirthdayService::BnBirthdayService;
   use com_example_birthdayservice::binder;

   const SERVICE_IDENTIFIER: &str = "birthdayservice";

   fn main() {
       let birthday_service = BirthdayService;
       let birthday_service_binder = BnBirthdayService::new_binder(
           birthday_service,
           binder::BinderFeatures::default(),
       );
       binder::add_service(SERVICE_IDENTIFIER, birthday_service_binder.as_binder())
           .expect("Failed to register service");
       binder::ProcessState::join_thread_pool()
   }
   ```
   또, **external/rust/birthday_service/Android.bp** 파일에 아래 내용을 추가한다.
   ```json
   rust_binary {
       name: "birthday_server",
       crate_name: "birthday_server",
       srcs: ["src/server.rs"],
       rustlibs: [
           "com.example.birthdayservice-rust",
           "libbinder_rs",
           "libbirthdayservice",
       ],
       prefer_rlib: true,
   }
   ```
1. 이제 아래와 같이 빌드한다.
   ```sh
   $ m birthday_server
   ```
   빌드 결과로 나온 실행 파일을 확인해 본다.
   ```sh
   $ ls $OUT/system/bin/birthday_server
   ```
1. 안드로이드 에뮬레이터가 띄워진 상태에서 아래와 같이 ADB를 이용하여 push 한다.
   ```sh
   $ adb push $OUT/system/bin/birthday_server /data/local/tmp
   ```
   그런데 SELinux 정책상 디폴트가 **<font color=red>Enforcing</font>**이므로, 그냥 **birthday_server**를 실행하면 **'Failed to register service: PERMISSION_DENIED'** 에러 메시지가 출력되면서 서비스 등록에 실패할 것이다.  
   여기서는 간단히 테스트만 할 것이므로, 아래와 같이 SELinux 모드를 **<font color=blue>Permissive</font>**으로 변경하였다.
   ```sh
   $ adb shell getenforce
   Enforcing
   $ adb root
   restarting adbd as root
   $ adb shell setenforce 0
   $ adb shell getenforce
   Permissive
   ```
   SELinux 모드가 바뀌었으므로, 이제 아래와 같이 서비스 서버를 실행시키면 에러 없이 실행된다. (Foreground로 계속 실행됨)
   ```sh
   $ adb shell /data/local/tmp/birthday_server
   ```
   다른 터미널을 연 후, 서비스가 실행 중인지 아래와 같이 확인할 수 있다.
   ```sh
   $ adb shell service check birthdayservice
   Service birthdayservice: found
   ```
1. 위에서 테스트가 성공했으면, 이제 구현한 서비스를 이용하는 클라이언트도 Rust로 구현한다.  
   **external/rust/birthday_service/src/client.rs** 파일을 아래와 같이 작성한다.   
   ```rust
   #![feature(format_args_capture)]

   use com_example_birthdayservice::aidl::com::example::birthdayservice::IBirthdayService::IBirthdayService;
   use com_example_birthdayservice::binder;

   const SERVICE_IDENTIFIER: &str = "birthdayservice";

   pub fn connect() -> Result<binder::Strong<dyn IBirthdayService>, binder::StatusCode> {
       binder::get_interface(SERVICE_IDENTIFIER)
   }

   fn main() -> Result<(), binder::Status> {
       let name = std::env::args()
           .nth(1)
           .unwrap_or_else(|| String::from("Bob"));
       let years = std::env::args()
           .nth(2)
           .and_then(|arg| arg.parse::<i32>().ok())
           .unwrap_or(42);

       binder::ProcessState::start_thread_pool();
       let service = connect().expect("Failed to connect to BirthdayService");
       let msg = service.wishHappyBirthday(&name, years)?;
       println!("{msg}");
       Ok(())
   }
   ```
   또, **external/rust/birthday_service/Android.bp** 파일에 아래 내용을 추가한다.
   ```json
   rust_binary {
       name: "birthday_client",
       crate_name: "birthday_client",
       srcs: ["src/client.rs"],
       rustlibs: [
           "com.example.birthdayservice-rust",
           "libbinder_rs",
       ],
       prefer_rlib: true,
   }
   ```
1. 아래와 같이 테스트 클라이언트를 빌드한다.
   ```sh
   $ m birthday_client
   ```
   빌드 파일을 확인해 본다.
   ```sh
   $ ls $OUT/system/bin/birthday_client
   ```
1. 아래와 같이 ADB를 이용하여 push 한 후, 실행시켜보면 기대대로 동작한다.
   ```sh
   $ adb push $OUT/system/bin/birthday_client /data/local/tmp
   $ adb shell /data/local/tmp/birthday_client Charlie 60
   Happy Birthday Charlie, congratulations with the 60 years!
   ```

## 결론
안드로이드 Native 서비스를 Rust로 작성하는 방법은 기존 C/C++로 작성할 때와 별반 다르지 않았다. 앞에서 언급했듯이 Rust로 구현하면 C/C++에 비해서 코드의 안정성을 높일 수 있므로, 구글은 계속해서 Rust의 비중을 높여 나갈 것이다.  
신규로 안드로이드 Native 서비스를 작성하는 경우라면 Rust로 구현할 것을 권장한다.
