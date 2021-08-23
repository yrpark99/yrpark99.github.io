---
title: "Android parallel job 빌드 관련"
category: Android
toc: true
toc_label: "이 페이지 목차"
---

Android 빌드시 시스템 CPU 리소스를 모두 사용하지 않도록 하기

## Parallel job 빌드
AOSP 소스를 비롯하여 각 프로젝트의 소스 코드를 빌드할 때는 parallel job을 이용하여 빌드하는 것이 사용하는 core 수 만큼 빌드 시간이 단축되므로 바람직한 방법이다.  
예를 들어 `make`나 `ninja`에서는 <mark style='background-color: #dcffe4'>-j</mark> 옵션을 이용하면 parallel job을 설정할 수 있다.  
이때 `-j` 옵션 뒤에 job 개수 추가하지 않으면 가능한 job을 모두 사용하고, job 개수가 있으면 이 개수로 제한하여 사용한다.

<br>
그런데 AOSP를 빌드시키면 디폴트로 가능한 모든 CPU 리소스를 사용하여 parallel job으로 빌드하므로, 종종 CPU 사용율이 <span style="color:red">99%</span>까지 치솟게 된다.  
혼자 빌드 시스템을 사용하는 경우라면 별 문제가 없을 수도 있겠지만, 동일 빌드 서버를 여러 명의 팀원이 함께 사용하는 경우에는 다른 사용자가 이 때 서버를 원할히 이용할 수 없는 문제가 있다.

## AOSP 빌드시 parallel job 제한
안드로이드 AOSP 빌드는 보통 `m`이나 `mm` 명령 등을 사용하는데, 이때 디폴트로 가능한 모든 CPU 리소스를 사용해 버린다. 이 경우 서버의 다른 사용자들은 시스템을 이용하기가 힘들어져서, 이를 막기 위한 방법을 찾아 보았고, 아래와 같은 2가지 방법을 찾았다.  
아래 예에서는 job 개수를 10으로 제한한 예이다.
1. `make` 명령으로 빌드시
   ```sh
   $ make -j10
   ```
1. `m`이나 `mm` 명령 등으로 빌드시
   ```sh
   $ m -j10
   $ mm -j10
   ```

사실 첫 번째 방법은 기존에도 알고 있었는데, 보통 `make` 대신에 `m`이나 `mm`을 이용하므로, 이 경우를 위한 대처인 2번째 방법을 새로 찾은 것이다. 😅

## 결론
즉, `m`이나 `mm` 명령 등은 디폴트로 **-j** 옵션을 사용하며, `make`와 마찬가지로 <mark style='background-color: #dcffe4'>-j</mark> 옵션을 이용하여 parallel job 개수를 제한할 수 있다는 것이다. 의외로 이것을 모르는 사람들이 많아서 간단히 공유해 본다.
