---
title: "안드로이드에서 ClearKey DRM 테스트"
category: Android
toc: true
toc_label: "이 페이지 목차"
---

안드로이드에서 ClearKey DRM을 테스트하는 방법을 서술한다.  
<br>

ClearKey DRM은 DRM 솔루션에 대한 이해를 돕고, 자체적으로 DRM 테스트 솔루션을 구축해 볼 수 있어서 study 용도로 좋은데, 구글링을 해 봐도 ClearKey에 대해 전체적으로 설명한 자료가 없어서, 직접 분석해 가면서 정리해 보았다.

## ClearKey DRM 소개
- AOSP에 Google이 구현한 소스가 포함되어 있어서 DRM 구현을 참조할 수 있다.
- 국제 표준화 기구 W3C에서 제정한 EME(Encrypted Media Extensions) 스펙을 기반으로 하고 있어, 웹 브라우저에서도 편리하게 사용할 수 있다.
- AES-128 블록 암호화를 사용하여 미디어를 암호화한다.
- Device provisioning은 사용하지 않고, 따라서 provisioning 서버도 필요하지 않다.
- 자체 라이선스 서버를 구축하여 사용할 수 있고, 원하면 라이선스 서버 없이도 사용할 수 있다.
- 일반적인 상용 DRM과 마찬가지로 AES-128 블록의 복호화 key를 얻기 위해서 라이선스 서버에 key를 request하고, 응답으로 key를 받는다.
- 응답으로 받는 key 값은 해당 device 만 풀 수 있도록 암호화되지는 않고 (디바이스별 인증서를 사용하지 않으므로), base64_url 형식의 plain-text로 온다.
- 위에서 보듯이 보안이 매우 취약하므로 study 용도로만 사용되고, 실제 상용 서비스에서는 사용되지 않는다. (상용 서비스의 경우에는 PlayReady, Widevine 등의 다른 DRM 시스템이 사용됨)

## ClearKey 라이선스 서버
ClearKey 라이선스 서버와의 통신 규격은 [ClearKey Content Protection](https://github.com/Dash-Industry-Forum/ClearKey-Content-Protection/blob/master/README.md) 페이지에 나와 있다.  
<br>

ClearKey DRM을 지원하는 player(이 글에서는 **ExoPlayer**를 사용)를 테스트해 보니, 이 규격에 맞게 linense request를 하는 것을 확인하였다. 그런데 ClearKey 라이선스 서버 역할을 해 주는 오픈소스를 찾을 수 없어서, 아래 예제와 같이 직접 파이썬의 Flask를 이용하여 구현하였다.  (위 규격에 맞추어 license response를 보내도록 함)  
즉, lincese request 시에는 key ID 정보가 오고, license response 시에는 key와 key ID 정보를 보내주면, player에서 올바르게 decryption이 처리된다.  
(테스트로 key ID는 **"01020304050607080910111213141516"**, key는 **"00112233445566778899AABBCCDDEEFF"** 1개 쌍을 사용함)

```python
#!/usr/bin/env python3

import base64
from flask import Flask, request, jsonify

# 테스트 Key ID, Key 매핑 테이블
key_mappings = {
    "01020304050607080910111213141516": "00112233445566778899AABBCCDDEEFF",
}

app = Flask(__name__)

# Base64url 디코딩 (패딩을 추가하여 Base64 형태로 만들고, 그 후 디코딩)
def base64url_to_bytes(encoded_string):
    padded_string = encoded_string + '=' * (-len(encoded_string) % 4)
    decoded_bytes = base64.urlsafe_b64decode(padded_string)
    return decoded_bytes

# Base64url 인코딩 (Base64 인코딩 후 URL safe 문자로 변환)
def bytes_to_base64url(data):
    encoded_string = base64.urlsafe_b64encode(data).decode('utf-8')
    return encoded_string.rstrip('=')

# /clearkey 라우팅
@app.route('/clearkey', methods=['POST'])
def handle_license_request():
    try:
        json_data = request.get_json()
        kids = json_data.get('kids', [])
        license_type = json_data.get('type', '')

        # Key ID를 얻는다.
        key_id_base64 = kids[0]
        key_id = base64url_to_bytes(key_id_base64)
        key_id_hex = key_id.hex()

        # Key ID가 매핑 테이블에 있으면 대응하는 key를 response에 넣는다.
        key_value = key_mappings.get(key_id_hex)
        if key_value:
            key_value_array = bytes.fromhex(key_value)
            key_value_base64 = bytes_to_base64url(key_value_array)
            response_data = {
                'keys': [
                    {
                        'kty': 'oct',
                        'k': key_value_base64,
                        'kid': key_id_base64,
                    }
                ],
                'type': license_type,
            }
            return jsonify(response_data), 200
        else:
            return jsonify({'Error': f'kid is not found. kid: {key_id_base64}'}), 404

    except Exception as e:
        return jsonify({'Error': 'Error. Request JSON data is wrong'}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3000, debug=True)
```

이제 위 파이썬 프로그램을 실행시킨다.  
<br>

위 프로그램이 정상적으로 동작하는지 테스트 해보려면, 아래와 같이 key ID "01020304050607080910111213141516"를 base64_url로 변환한 후 <font color=blue>curl</font>로 **"kids"** 항목에 담아서 POST를 보내면 된다.
```sh
$ echo -n "01020304050607080910111213141516" | xxd -r -p | base64 | tr '+/' '-_' | tr -d '='
AQIDBAUGBwgJEBESExQVFg
$ curl --location 'http://ca.kaonmedia.com:3000/clearkey' --header 'Content-Type: application/json' --data '{"kids":["AQIDBAUGBwgJEBESExQVFg"],"type":"temporary"}'
{
  "keys": [
    {
      "k": "ABEiM0RVZneImaq7zN3u_w",
      "kid": "AQIDBAUGBwgJEBESExQVFg",
      "kty": "oct"
    }
  ],
  "type": "temporary"
}
```

결과로 위에서 보듯이 **"k"** 응답으로 "ABEiM0RVZneImaq7zN3u_w"이 온다. 그런데 이 값은 base64_url 포맷이므로, 이를 hex 문자열로 보기 위하여 아래와 같이 실행한다.
```sh
$ echo -n "ABEiM0RVZneImaq7zN3u_w" | tr -- '-_' '+/' | awk '{ if (length($0) % 4 == 3) print $0"="; else if (length($0) % 4 == 2) print $0"=="; else print $0; }' | base64 -d | xxd -p
00112233445566778899aabbccddeeff
```
결과로 기대대로 key 값이 "00112233445566778899AABBCCDDEEFF"로 왔으므로 위 라이선스 서버 프로그램은 정상 동작함을 확인할 수 있다. 😊  
<br>

이제 MP4 파일을 (여기서는 Big Buck Bunny 콘텐츠 사용) ClearKey DRM으로 encryption하여 DASH 스트림으로 만들고, 이를 ExoPlayer에서 play 시키면 된다.

## ClearKey DASH 스트림 만들기
여기에서 스트림 생성 툴은 [Bento4](https://www.bento4.com/)와 [Shaka Packager](https://github.com/shaka-project/shaka-packager)를 이용하였다.  
MPD(Media Presentation Description) 파일의 PSSH(Protection System Specific Header) box 형식에 대해서는 [Common SystemID and PSSH Box Format](https://w3c.github.io/encrypted-media/format-registry/initdata/cenc.html) 페이지를 참조한다.  
<br>
아래와 같이 MPEG-DASH 스트림을 생성한다.

1. Clear MP4 테스트 파일을 준비한다. (예로 파일 이름은 input.mp4)
1. [Bento4](https://www.bento4.com/) 툴을 이용하여 아래와 같이 encrypted DASH 스트림을 생성한다. (여기서는 Key ID는 **01020304050607080910111213141516**, Key는 **00112233445566778899AABBCCDDEEFF** 사용)
   ```sh
   $ mp4fragment input.mp4 output.mp4
   $ mp4dash --encryption-key=01020304050607080910111213141516:00112233445566778899AABBCCDDEEFF --clearkey output.mp4
   ```
   참고로 `--clearkey-license-uri` 아규먼트로 라이선스 서버의 URI를 지정할 수도 있지만 이 경우 HTTPS만 가능하므로, 여기서는 편의상 HTTP를 사용하기 위하여 이 옵션은 사용하지 않았다.  
   결과로 MPD 파일과 DASH 스트림이 생성된다. (파일 이름은 편의상 **big_buck_bunny.mpd**로 변경)
   > 그런데, 생성된 MPD 파일에는 PSSH box 내용이 들어가 있지 않았다. 😠  
   > 대응책으로 아래 단계와 같이 별도의 툴을 이용하여 직접 PSSH 내용을 얻은 후, MPD 파일에 수동으로 구성하는 방법을 사용하였다.
1. [Shaka Packager](https://github.com/shaka-project/shaka-packager)에 포함된 pssh-box.py 프로그램을 이용하여 아래 예와 같이 PSSH 내용을 얻는다. (System ID 값은 Common PSSH box 용 ID 값을 사용)
   ```sh
   $ ./pssh-box.py --base64 --system-id 1077efecc0b24d02ace33c1e52e2fb4b --key-id 01020304050607080910111213141516
   AAAANHBzc2gBAAAAEHfv7MCyTQKs4zweUuL7SwAAAAEBAgMEBQYHCAkQERITFBUWAAAAAA==
   ```
   > 참고로 이 PPSH 내용을 분석해 보려면, 아래와 실행하면 hex 값으로 출력된다.
   > ```sh
   > $ ./pssh-box.py --hex --system-id 1077efecc0b24d02ace33c1e52e2fb4b --key-id 01020304050607080910111213141516
   > 0000003470737368010000001077EFECC0B24D02ACE33C1E52E2FB4B000000010102030405060708091011121314151600000000
   > ```
   > 이 PSSH 데이터는 아래와 같이 파싱된다. (즉, 기대대로 PSSH가 구성되었음 📌)  
   > `00 00 00 34`: total_len (0x34)  
   > `70 73 73 68`: BMFF box header ("pssh")  
   > `01 00 00 00`: Full box header (version=1, flags=0)  
   > `1077EFECC0B24D02ACE33C1E52E2FB4B`: System ID (Common PSSH)  
   > `00 00 00 01`: KID_count (1)  
   > `01020304050607080910111213141516`: KeyId  
   > `00 00 00 00`: Size of data (0)
1. 위에서 얻은 PSSH base64 문자열로 MPD 파일에서 아래 예와 같이 구성한다.
   ```xml
   <ContentProtection schemeIdUri="urn:mpeg:dash:mp4protection:2011" value="cenc" cenc:default_KID="02030507-0110-1301-7019-023029031037"/>
   <ContentProtection schemeIdUri="urn:uuid:1077efec-c0b2-4d02-ace3-3c1e52e2fb4b">
     <cenc:pssh>AAAANHBzc2gBAAAAEHfv7MCyTQKs4zweUuL7SwAAAAEBAgMEBQYHCAkQERITFBUWAAAAAA==</cenc:pssh>
   </ContentProtection>
   ```
1. 생성한 MPD 파일과 A/V 파일을 HTTP 서버의 경로에 복사한다.

이로써 ClearKey DRM 콘텐츠와 라이선스 서버가 준비되었다. 이제부터는 player를 준비해 보자.

## Player 테스트 환경
[ExoPlayer](https://github.com/google/ExoPlayer)를 사용하여 각각 다음과 같은 환경에서 테스트해 보았고, 모두 정상적으로 play 되었다. (웹 브라우저 환경에서도 쉽게 play 시킬 수 있지만, 본 글에서는 안드로이드 플랫폼만 다루므로 이 경우는 생략함)
- 실제 안드로이드 디바이스 (내 모바일폰 이용)
- Windows 환경에서 안드로이드 스튜디오의 에뮬레이터 이용 (pre-built 된 시스템 이미지 사용)
- Linux 환경에서 AOSP의 에뮬레이터 이용 (AOSP 빌드한 이미지 사용)

> ✅ 안드로이드 디바이스와 pre-built 된 시스템 이미지는 디폴트로 ClearKey DRM을 지원하고 있다. 따라서 이 경우에는 별도의 ClearKey DRM 빌드 작업이 필요하지 않다.  
> 단, AOSP에는 ClearKey DRM 소스가 포함되어 있지만 전체 빌드에는 포함되어 있지 않으므로, 이 경우에는 약간이 작업이 필요해진다.

테스트로 에뮬레이터로 pre-built 된 AVD(Android Virtual Device) 이미지를 실행한 후에 ADB(Android Debug Bridge)를 연결하여 확인해 보면, 아래와 clearkey 서비스를 확인할 수 있다.
```sh
$ lshal | grep "clearkey"
DM,FC Y android.hardware.drm@1.0::ICryptoFactory/clearkey                           N/A        372
DM,FC Y android.hardware.drm@1.0::IDrmFactory/clearkey                              N/A        372
DM,FC Y android.hardware.drm@1.1::ICryptoFactory/clearkey                           N/A        372
DM,FC Y android.hardware.drm@1.1::IDrmFactory/clearkey                              N/A        372
DM,FC Y android.hardware.drm@1.2::ICryptoFactory/clearkey                           N/A        372
DM,FC Y android.hardware.drm@1.2::IDrmFactory/clearkey                              N/A        372
DM,FC Y android.hardware.drm@1.3::ICryptoFactory/clearkey                           N/A        372
DM,FC Y android.hardware.drm@1.3::IDrmFactory/clearkey                              N/A        372
DM,FC Y android.hardware.drm@1.4::ICryptoFactory/clearkey                           N/A        372
DM,FC Y android.hardware.drm@1.4::IDrmFactory/clearkey                              N/A        372
X     ? android.hidl.base@1.0::IBase/clearkey                                       N/A        N/A
```

## ExoPlayer 빌드 및 설치
1. [ExoPlayer](https://github.com/google/ExoPlayer) 페이지에서 소스를 Git clone 받은 후, 안드로이드 스튜디오에서 프로젝트로 연다.
1. DASH, HLS 등의 테스트를 위해 안드로이드 스튜디오의 메뉴 `Run -> Profile` 항목에서 `demo` 항목을 선택한다.
1. ExoPlayer의 **demos/main/src/main/assets/media.exolist.json** 파일에서 아래 예와 같이 추가한다. (아래에서 **my_host** 대신에 자신의 호스트 IP 주소를 넣으면 됨)
   ```json
   {
     "name": "ClearKey DASH (Big Buck Bunny)",
     "uri": "http://my_host/clearkey/big_buck_bunny.mpd",
     "drm_scheme": "clearkey",
     "drm_license_uri": "http://my_host:3000/clearkey"
   }
   ```
1. 그런데 URI에서 https 대신에 http를 사용하면 "Cleartext HTTP traffic not permitted. See https://developer.android.com/guide/topics/media/issues/cleartext-not-permitted" 에러가 발생한다. 이 경우에 HTTP를 사용하려면 **demos/main/src/main/AndroidManifest.xml** 파일의 `<application>` 섹션에 아래 내용을 추가하면 된다.
   ```ini
   android:usesCleartextTraffic="true"
   ```
1. ADB로 연결된 실제 디바이스나 AVD에 ExoPlayer를 설치시키려면, 안드로이드 스튜디오에서 실행 버튼을 누르면 ExoPlayer 앱이 자동으로 설치되고 실행된다.  
또는 안드로이드 스튜디오 메뉴 `Build -> Build Bundle(s) / APK(s) -> Build APK(s)` 항목을 실행하면 APK 파일이 생성되고 (예: demo-noDecoderExtensions-release.apk), ADB로 아래 예와 같이 설치시킬 수 있다.
   ```sh
   $ adb install demo-noDecoderExtensions-release.apk
   ```

## AOSP 사용하여 테스트하기

### AOSP 소스 받기
1. 작업용 디렉토리를 만든 후에 이 디렉토리로 이동한다.
1. 아래와 같이 `repo init` 명령을 실행한다. (본 글에서는 현재 시점에서 가장 최신 태그인 **android-14.0.0_r21** 태그를 사용하였음)  
(참고로 전체 태그 목록은 [안드로이드 Codenames, Tags, and Build Numbers](https://source.android.com/docs/setup/reference/build-numbers?hl=ko) 페이지에서 확인할 수 있음)
   ```shell
   $ repo init -u https://android.googlesource.com/platform/manifest -b android-14.0.0_r21 --partial-clone
   ```
   결과로 현재 디렉토리 밑에 **.repo** 디렉토리가 생성된다.
1. 이제 아래와 같이 `repo sync` 명령을 실행하면 안드로이드 소스를 다운로드 받는다.
   ```shell
   $ repo sync -j16 -c
   ```

### ClearKey DRM 소스
AOSP에서 ClearKey DRM 소스는 **frameworks/av/drm/mediadrm/plugins/clearkey/** 경로에 있다.  
소스에서 ClearKey 관련은 특히 아래 부분을 살펴보면 된다.
- PSSH 파싱하는 부분: parsePssh() 함수
- 라이선스 request를 처리하는 부분: getKeyRequest() 함수
- 라이선스 response를 처리하는 부분: provideKeyResponse() 함수

빌드 관련해서 **frameworks/av/drm/mediadrm/plugins/clearkey/hidl/Android.bp** 파일에 보면 아래 발췌와 같이 `init_rc`, `vintf_fragments` 항목이 설정되어 있다. (`vintf`는 vendor interface를 나타냄)
```yaml
cc_binary {
    name: "android.hardware.drm@1.4-service.clearkey",
    defaults: ["clearkey_service_defaults"],
    srcs: ["service.cpp"],
    init_rc: ["android.hardware.drm@1.4-service.clearkey.rc"],
    vintf_fragments: ["manifest_android.hardware.drm@1.4-service.clearkey.xml"],
}
```
위에 명시된 init rc 파일과 vintf xml 파일의 경로는 각각 다음과 같다.
- frameworks/av/drm/mediadrm/plugins/clearkey/hidl/android.hardware.drm@1.4-service.clearkey.rc
- frameworks/av/drm/mediadrm/plugins/clearkey/hidl/manifest_android.hardware.drm@1.4-service.clearkey.xml

### AOSP 빌드
1. 아래와 같이 환경 설정을 한다.
   ```sh
   $ source build/envsetup.sh
   ```
   아래 예와 같이 lunch로 원하는 타겟을 설정한다. (여기서는 x86_64 환경에서 에뮬레이터를 사용하기 위하여 **sdk_car_x86_64-userdebug** 타겟을 선택하였음)
   ```sh
   $ lunch sdk_car_x86_64-userdebug
   ```
1. 전체 빌드시에 ClearKey를 포함시키기 위하여 **device/generic/goldfish/vendor.mk** 파일에서 아래와 같이 추가한다.
   ```makefile
   PRODUCT_PACKAGES += \
       android.hardware.drm@1.4-service.clearkey
   ```
1. 이제 아래와 같이 전체 빌드할 수 있다.
   ```sh
   $ m
   ```
1. 빌드가 완료되었으면 **out** 디렉토리에 이미지들이 생성된다.

### AOSP 에뮬레이터에서 테스트
1. GUI가 실행될 수 있는 환경에서 아래와 같이 실행하면 GUI 에뮬레이터가 실행된다.
   ```sh
   $ emulator
   ```
1. 에뮬레이터가 실행되면 아래와 같이 ADB 디바이스 목록에서 확인할 수 있다. (아래 예와 같이 에뮬레이터가 연결되었음)
   ```sh
   $ adb devices
   List of devices attached
   emulator-5554   device
   ```
1. 아래와 같이 ADB shell에 진입하여 clearkey 서비스를 확인해 보면, 정상적으로 서비스들이 등록된 것을 확인할 수 있다.
   ```sh
   $ adb shell
   emulator_car_x86_64:/ # lshal | grep clearkey
   DM,FC Y android.hardware.drm@1.0::ICryptoFactory/clearkey                           0/2        377    198
   DM,FC Y android.hardware.drm@1.0::IDrmFactory/clearkey                              0/2        377    198
   DM,FC Y android.hardware.drm@1.1::ICryptoFactory/clearkey                           0/2        377    198
   DM,FC Y android.hardware.drm@1.1::IDrmFactory/clearkey                              0/2        377    198
   DM,FC Y android.hardware.drm@1.2::ICryptoFactory/clearkey                           0/2        377    198
   DM,FC Y android.hardware.drm@1.2::IDrmFactory/clearkey                              0/2        377    198
   DM,FC Y android.hardware.drm@1.3::ICryptoFactory/clearkey                           0/2        377    198
   DM,FC Y android.hardware.drm@1.3::IDrmFactory/clearkey                              0/2        377    198
   DM,FC Y android.hardware.drm@1.4::ICryptoFactory/clearkey                           0/2        377    198
   DM,FC Y android.hardware.drm@1.4::IDrmFactory/clearkey                              0/2        377    198
   X     Y android.hidl.base@1.0::IBase/clearkey                                       0/2        377    198
   ```
1. 아래와 같이 ExoPlayer를 설치한 후, ExoPlayer에서 테스트해보면 정상적으로 play 된다.
   ```sh
   $ adb install demo-noDecoderExtensions-release.apk
   ```
