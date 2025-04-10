---
title: "Launch4j JRE 관련"
category: Java
toc: true
toc_label: "이 페이지 목차"
---

자바 jar 파일을 Windows 실행 파일로 만들기 위한 [launch4j](http://launch4j.sourceforge.net/) 툴에서 JRE 관련하여 정리한다.

<br>
내가 오래전에 회사에서 업무용으로 [JavaFX](https://openjfx.io/)로 웹브라우저 기반의 애플리케이션을 개발했었는데, 오랜만에 이를 업데이트할 일이 생겨서 소스 코드를 수정하여 Jar 파일을 빌드 한 후에 exe 파일로 변환하였다. 그런데 필요한 JRE 버전이나 설치 유무에 영향을 받는 문제가 있어서, 이의 영향을 받지 않고 정상 동작될 수 있는 해결책을 알아보았다.

## JRE 필요
자바 애플리케이션이 실행되려면 JRE가 필요한데, 특히 <mark style='background-color: #ffdce0'>JavaFX</mark>는 Oracle 자바 v1.8 까지에서만 포함되어 있고 이후 버전에서는 포함되어 있지 않아서 별도로 설치해야 한다. 따라서 내가 Windows 실행 파일로 배포하더라도 (이때 `launch4j` 툴 이용) JavaFX가 포함된 JRE가 설치되어 있지 않은 환경이라면 정상적으로 동작이 되지 않는다.  
기존에 v1.8이 주류로 사용될 때에는 별 문제가 되지 않았지만, 요즘은 다양한 버전의 JRE/JDK가 사용되는 상황이기 때문에 각 사용자 시스템에 설치된 (또는 설치되지 않은) JRE/JDK와 무관하게, 배포하는 자바 애플리케이션이 정상 동작하는 것을 목표로 삼았다.  
나의 경우는 자바 v1.8 + JavaFX가 필요한 상황이었으므로, 이를 launch4j 툴을 이용하여 설정하도록 해 보았다.

## 필요한 JRE 준비
먼저 JRE를 포함하기 위한 디렉토리를 준비한다. 나의 경우 `jre`라는 이름으로 디렉토리를 생성하였다. 이 밑에 아래와 같이 디렉토리를 구성하여 JDK에 포함된 JRE 디렉토리에서 복사를 하였다. 나의 경우는 자바 v1.8 JDK (JavaFX 포함) 디렉토리에서 JRE 디렉토리를 복사하였다.
```
jre
  ├─bin
  └─lib
```
> JDK 디렉토리에는 내 자바 애플리케이션 실행에 필요없는 파일들도 많이 있어서, 나의 경우는 파일 이름으로 판단한 직감과 테스트를 통해 없어도 되는 파일들을 삭제하여 용량을 상당량 줄였다.

## Launch4j에서 JRE 설정
Launch4j를 실행한 후에, `JRE` 탭에서 관련 설정을 한다.  
Launch4j로 빌드한 실행 파일 실행시 JRE를 하위 지정한 디렉토리에서 찾게 하려면 **Bundled JRE paths** 입력에 준비한 `jre` 디렉토리 이름을 세팅하고, `Fallback option`에 체크를 한다. 즉, 시스템에서 JRE 찾기가 실패한 경우에는 하위 **jre**라는 디렉토리에서 JRE를 찾도록 한 것이다. 또 JDK preference로는 **Only use private JDK runtimes**를 선택한다.  
<br>
이에 따라 나의 경우는 아래 캡쳐와 같이 설정하였다.  
![](/assets/images/launch4j_jre_my.png)

<br>

참고로 launch4j 설정을 저장한 후, 설정 xml 파일에서 `jre` 부분을 확인해 보면 아래와 같았다. (나의 경우 버전은 1.8로 했으나, 아래 예에서는 지웠음)
```xml
<jre>
  <path>jre</path>
  <bundledJre64Bit>true</bundledJre64Bit>
  <bundledJreAsFallback>true</bundledJreAsFallback>
  <minVersion></minVersion>
  <maxVersion></maxVersion>
  <jdkPreference>jdkOnly</jdkPreference>
  <runtimeBits>64/32</runtimeBits>
</jre>
```

## 실행 파일 배포
이후 launch4j 빌드 결과로 나온 exe 파일과 위에서 준비한 **jre** 폴더를 배포하면 된다. 결과로 시스템에 타겟 버전의 자바 JDK가 설치되어 있으면 이것을 사용하고, 그렇지 않은 경우에는 (즉, 타겟 자바 버전의 JDK가 설치되어 있지 않은 다른 모든 경우) **jre** 폴더의 JRE가 사용되어, 배포한 실행 파일이 정상적으로 동작하게 된다.

## Launch4j로 만든 실행 파일에서 jar 파일 추출
참고로 launch4j는 단순히 PE 파일 wrapper이므로 launch4j로 생성한 exe 파일을 jar 파일로 만들수 있다. 사실상 jar 파일은 PK ZIP 포맷이므로 exe 파일에서 첫번째 "PK" 문자열의 위치를 찾아서, 이전 PE 내용을 모두 삭제하면 원래 jar 파일을 얻을 수 있는 것이다.  
예를 들어 내 예제 파일을 `binwalk` 툴로 검사해 보니 아래와 같이 출력되었다.
```bash
$ binwalk test.exe

DECIMAL       HEXADECIMAL     DESCRIPTION
--------------------------------------------------------------------------------
0             0x0             Microsoft executable, portable (PE)
38912         0x9800          Zip archive data, at least v2.0 to extract, name: META-INF/
38973         0x983D          Zip archive data, at least v2.0 to extract, name: META-INF/MANIFEST.MF
...
...
...
2800663       0x2ABC17        Zip archive data, at least v2.0 to extract, name: resources/test.ico
2802393       0x2AC2D9        Zip archive data, at least v2.0 to extract, name: resources/test.fxml
2807620       0x2AD744        Obfuscated Arcadyan firmware, signature bytes: 0x56C38CD9,
3079212       0x2EFC2C        End of Zip archive
```
즉, 위의 경우에는 실행 파일의 0x0 ~ 0x97FF 영역은 PE 영역이고, 0x9800 오프셋부터 끝까지는 jar 파일임을 알 수 있다.  
따라서 [HxD](https://mh-nexus.de/en/hxd/)와 같은 hex 에디터나 [HexEd.it](https://hexed.it/)과 같은 온라인 툴에서 타겟 exe 파일을 열어서 첫번째 "PK" 문자열을 찾아서 처음부터 이 주소 이전까지의 내용을 모두 삭제후 **.jar** 파일로 저장하면 Jar 파일을 얻을 수 있다.

<br>
자바로 개발은 아주 간헐적으로 하다 보니 추후 참조를 위하여 간단히 기록을 남긴다.
