---
title: "TSDuck 소개 및 기본적인 사용법"
category: MPEG
toc: true
toc_label: "이 페이지 목차"
---

MPEG-2 TS(Transport Stream)을 다루는 tool 중에서 TSDuck 소개와 기본적인 사용법이다.

## TS tools
많은 무료 TS(Transport Stream) 툴이 있는데, 내가 주로 이용하는 툴은 다음과 같다.
* [DVB Inspector](https://github.com/EricBerendsen/dvbinspector)
  - Java로 구현된 DVB analyzer 오픈 소스 (실행시 JRE 필요함)
  - 멀티플랫폼 지원
  - 기능도 많고 업데이트도 자주 됨, 일반적인 스트림 분석 용도로는 이 툴을 가장 많이 사용함
  - EIT view, PCR/PTS/DTS view 등의 기능도 지원함
  - TS payload 데이터는 메뉴 Setting -> Enable TS Packets 항목을 체크하면 볼 수 있음

  > 2020년 5월에 소스 저장소가 [SourceForge](https://sourceforge.net/projects/dvbinspector/)에서 [GitHub](https://github.com/EricBerendsen/dvbinspector)으로 옮겨졌다.
* [dvbsnoop](http://dvbsnoop.sourceforge.net)
  - CLI 기반의 오픈 소스 DVB parser
  - TS 덤프 및 파싱, PSI 덤프 및 파싱 기능 등
  - 업데이트 안 된지 오래 되었음
  - 우분투에서의 설치 예  
    ```sh
    $ sudo apt install dvbsnoop
    ```
  - TS 파일 분석은 아래 예와 같이 할 수 있다. (TS 파일인 경우 `-s ts` 옵션 사용, PS 파일이면 `-s ps`, PES 파일이면 `-s pes` 사용하면 됨)
    ```sh
    $ dvbsnoop -if {TS 파일} -s ts
    ```
  - 세부 PSI 파싱은 아래 예와 같이 할 수 있다. (`-s ts -tssubdecode` 옵션 사용, 만약 payload가 여러 TS 패킷에 걸쳐 있으면, 모두 받은 시점에서 디코딩함)
    ```sh
    $ dvbsnoop -if {TS 파일} -s ts -tssubdecode
    ```
* [MPEG-2 Transport Stream Packet Analyser](https://github.com/daniep01/MPEG-2-Transport-Stream-Packet-Analyser)
  - Visual Basic .NET로 구현한 오픈 소스 TS 패킷 analyser 
  - Windows용 무설치 실행 파일만 제공
  - MPEG-2 TS 패킷 덤프 및 TS 헤더 분석 등
* [TSDuck](https://tsduck.io)
  - C++로 구현한 MPEG Transport Stream Toolkit로 TS 분석, 수정, play 등이 가능하고 오픈 소스임
  - 멀티플랫폼 지원, CLI base 임
  - 기능이 막강하고 업데이트가 자주 되고 문서화도 잘 되어 있음, 스트림 조작 등의 용도로 최적의 툴임
  - 기존 플러그인을 사용하여 추가 기능을 사용하거나, 기존 플러그인 소스를 수정/빌드하면 본인만의 기능을 추가 구현할 수 있음, 새로운 플러그인을 만들 수도 있음
* [TSR](http://www.digital-digest.com/dvd/downloads/showsoftware_tsr_263.html)
  - Transport Stream Reader
  - PSI 파싱, PID 추출 기능 등
  - 업데이트 안 된지 오래 되었음
* [TSReader](http://www.coolstf.com)
  - Transport Stream analyzer, decoder, recorder and stream manipulator for MPEG2 systems
  - Clear 채널인 경우 play 됨, ATSC도 지원함

## TSDuck 정보
위에서 **TSDuck**의 특징과 장점을 간단히 언급하였는데, 세부 정보는 아래에서 얻을 수 있다.
- 홈페이지: [https://tsduck.io/](https://tsduck.io/)
- 소스: [GitHub TSDuck](https://github.com/tsduck/tsduck)
- 설치: [TSDuck release](https://github.com/tsduck/tsduck/releases)
- 문서: [TSDuck User's Guide](https://tsduck.io/download/docs/tsduck.pdf), [TSDuck Presentation](https://tsduck.io/download/docs/tsduck-presentation.pdf)

## TSDuck 기본 사용법
**TSDuck**은 많은 툴들을 포함하고 있다. 아래 외에도 더 있으니 자신에게 필요한 것이 있는지 확인해 보기 바란다. (아래에서는 Linux에서의 사용 예를 들었는데 Windows 등에서도 마찬가지임)
1. TS 파일의 기본적인 정보 출력
   ```sh
   $ tsanalyze {TS 파일}
   ```
1. TS 파일의 bitrate 정보 출력
   ```sh
   $ tsbitrate {TS 파일}
   ```
1. TS 파일 자르기 예
   ```sh
   $ tsftrunc --packet <TS 패킷 인덱스> {TS 파일}
   ```
1. TS 파일의 TS 패킷 덤프
   ```sh
   $ tstables {TS 파일}
   ```
   특정 PID의 TS 패킷 덤프 (table ID, section length 이후부터 출력)
   ```sh
   $ tstables --pid <PID 값> {TS 파일}
   ```
   특정 PID의 TS 패킷 덤프 (table ID 부터 출력)
   ```sh
   $ tstables --pid <PID 값> --raw-dump {TS 파일}
   ```
   특정 PID와 table ID가 매칭되는 TS 패킷 덤프
   ```sh
   $ tstables --pid <PID 값> --tid <TID 값> {TS 파일}
   ```
1. TS 파일의 PSI 파싱
   ```sh
   $ tspsi {TS 파일}
   ```
1. <span style="color:purple">**tsp**</span> (TS Processor)  
   다양한 용도로 활용할 수 있는 TS 처리기로 <font color=blue>tsp</font> 툴이 있다. TSDuck에서 핵심점인 툴로, 아래에서 몇 가지 사용 예를 들겠다.

## TSDuck tsp 툴 사용 예
1. tsp가 지원하는 전체 플러그인 리스트 출력
   ```sh
   $ tsp -l
   ```
1. tsp 특정 플러그인의 도움말 출력
   ```sh
   $ tsp -P {플러그인 이름} --help
   ```
1. 출력 파일을 입력 파일과 동일하게 생성 (기본 테스트 목적)
   ```sh
   $ tsp -I file {입력 TS 파일} -O file {출력 TS 파일}
   ```
1. TS 파일 play 예  
   아래 예와 같이 실행할 수 있다 (service_id 대신에 service_name을 사용해도 됨).  
   참고로 디폴트로 [VLC media player](https://www.videolan.org/index.ko.html)로 play 된다. (다른 운영 체제에서도 마찬가지임, 따라서 사전에 VLC media player를 설치해야 함)
   ```sh
   $ sudo apt install vlc
   $ tsp -I file {TS 파일} -P zap {service_id} -O play
   ```
   만약에 VLC media player 대신에 [MPlayer](http://www.mplayerhq.hu/design7/news.html)로 play 하려면 아래와 같이 `-m` 옵션을 추가하면 된다.
   ```sh
   $ sudo apt install mplayer
   $ tsp -I file {TS 파일} -P zap {service_id} -O play -m
   ```
1. PMT에서 Video PID 변경하기 예
   ```sh
   $ tsp -I file {입력 TS 파일} -P pmt --move-pid {old_pid}/{new_pid} --pcr-pid {new_pid} -O file {출력 TS 파일}
   ```
1. SDT 생성 예 (Service ID 추가)
   ```sh
   $ tsp -I file {입력 TS 파일} -P sdt --create --ts-id {TSID 값} --original-network-id {ONID 값} --service-id {service_id} --provider {provider name} --name {service name} -O file {출력 TS 파일}
   ```
1. 서비스 제거 예
   ```sh
   $ tsp -I file {입력 TS 파일} -P svremove {제거할 service_id} -O file {출력 TS 파일}
   ```
1. 스트림 합치기 예
   ```sh
   $ tsp -I file {입력 TS1 파일} -P merge 'tsp -I file {입력 TS2 파일}' -O file {출력 TS 파일}
   ```
1. 입력 파일을 UDP로 multicast 전송하기 예 (아래 예에서는 multicast IP 주소는 **224.10.11.12**, 포트 번호는 **9999** 사용)
   ```sh
   $ tsp -I file {TS 파일} -P regulate -P zap {service_id} -O ip 224.10.11.12:9999
   ```
   이것을 VLC media player에서 재생하려면 메뉴에서 `미디어` -> `네트워크 스트림 열기` -> `네트워크` 탭에서 네트워크 주소에 `"udp://@224.10.11.12:9999"`와 같이 입력한 후에 재생 버튼을 누르면 된다.
1. UDP multicast 수신하여 VLC media player로 play 하기 예 (아래 예에서는 **192.168.0.2** local 인터페이스를 listen, multicast IP 주소는 **224.10.11.12**, 포트 번호는 **9999** 사용)
   ```sh
   $ tsp -I ip -l 192.168.0.2 224.10.11.12:9999 -O play
   ```

## 맺음말
TS 파일을 파싱하거나 조작하기에 아주 막강한 TSDuck을 간단히 소개하였다.  
실제로 나는 TS 파일을 아래와 같이 조작하는 기능이 필요하였는데 TSDuck에 해당 기능들이 없어서, TSDuck을 fork해서 ([내 TSDuck](https://github.com/yrpark99/tsduck) 참조) 해당 플러그인 소스에서 이 기능을 추가한 후 사용한 적도 있다. 😋
* PMT에 scrambling_descriptor를 추가하기
* NIT의 original_network_id 값 변경하기

물론 나도 TSDuck을 사용하지 않고, 내가 직접 툴을 만들어서 사용하는 경우도 있는데, 추가로 필요할 때 이런 툴을 사용하면 한층 더 편리하였다. 혹시 TS를 조작할 일이 있는 경우에는 TSDuck을 사용해 보기를 적극 권장한다. 👍
