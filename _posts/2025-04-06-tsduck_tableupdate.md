---
title: "TSDuck 툴로 TS 파일의 DVB SI 테이블 수정하기"
category: [MPEG]
toc: true
toc_label: "이 페이지 목차"
---

TSDuck 툴로 MPEG-2 TS(Transport Stream) 파일의 DVB SI 테이블을 수정하는 방법이다.

## 머릿말
전에 [TSDuck 소개 및 기본적인 사용법](https://yrpark99.github.io/mpeg/tsduck_usage/) 페이지에서 [TSDuck](https://tsduck.io/) 툴의 기본적인 사용법을 예를 들어 소개했었다. 그런데 얼마 전에 DVB SI 테이블의 내용을 수정하거나 추가해야 할 필요가 생겨서 TSDuck 툴을 이용해 보기로 하였다.  
TSDuck 툴에서 제공하는 입력 TS 파일의 DVB SI 테이블(PMT/SDT/BAT/EIT 등)을 `XML` 파일로 추출하여 이를 수정한 후에, 수정된 `XML` 파일을 적용하여 출력 TS 파일을 생성하는 방법을 사용하면 된다.

> 참고로 아래에서 `generic_descriptor`를 사용할 때에는 **tag**에 해당 descriptor의 tag 값을 지정하고, length 값은 생략하고 이후 데이터를 hex 바이트로 구성하면 된다.

## PMT 수정
1. 입력 TS 파일의 PMT 정보를 XML 파일로 추출한다.
   ```sh
   $ tsp -I file {입력 TS 파일} -P tables --pid {PMT_PID} --xml {XML 파일} -O drop
   ```
1. 추출된 XML 파일에서 원하는대로 수정한다. (아래는 scrambling_descriptor 예제)
   ```xml
   <scrambling_descriptor>
     <scrambling_mode=3>
   </scrambling_descriptor>
   ```
   또는 아래와 같이 generic_descriptor를 이용할 수도 있다.
   ```xml
   <generic_descriptor tag="0x65">
     03
   </generic_descriptor>
   ```
1. 입력 TS 파일에 새로운 PMT를 적용하여 출력 TS 파일을 생성한다.
   ```sh
   $ tsp -I file {입력 TS 파일} -P inject --pid {PMT_PID} --replace {XML 파일} -O file {출력 TS 파일}
   ```

## NIT 수정
1. 입력 TS 파일의 NIT 정보를 XML 파일로 추출한다.
   ```sh
   $ tsp -I file {입력 TS 파일} -P tables --pid 0x10 --xml {XML 파일} -O drop
   ```
1. 추출된 XML 파일에서 원하는대로 수정한다. (아래는 satellite_delivery_system_descriptor 예제)
   ```xml
   <satellite_delivery_system_descriptor frequency="11,243,750,000" orbital_position="19.2" west_east_flag="east" polarization="horizontal" modulation_system="DVB-S" modulation_type="QPSK" symbol_rate="22,000,000" FEC_inner="5/6"/>
   </transport_stream>
   ```
   또는 아래와 같이 generic_descriptor를 이용할 수도 있다.
   ```xml
   <generic_descriptor tag="0x43">
     01 12 43 75 01 92 81 02 20 00 04
   </generic_descriptor>
   ```
1. 입력 TS 파일에 새로운 NIT를 적용하여 출력 TS 파일을 생성한다.
   ```sh
   $ tsp -I file {입력 TS 파일} -P inject --pid 0x10 --replace {XML 파일} -O file {출력 TS 파일}
   ```

## SDT 수정
1. 입력 TS 파일의 SDT 정보를 XML 파일로 추출한다.
   ```sh
   $ tsp -I file {입력 TS 파일} -P tables --pid 0x11 --tid 0x46 --xml {XML 파일} -O drop
   ```
1. 추출된 XML 파일에서 원하는대로 수정한다. (아래는 service_descriptor 예제)
   ```xml
   <service_descriptor service_type="0x01" service_provider_name="ARD" service_name="WDR Bielefeld"/>
   </service>
   ```
   또는 아래와 같이 generic_descriptor를 이용할 수도 있다.
   ```xml
   <generic_descriptor tag="0x48">
     01 03 41 52 44 0D 57 44 52 20 42 69 65 6C 65 66 65 6C 64
   </generic_descriptor>
   ```
1. 입력 TS 파일에 새로운 SDT를 적용하여 출력 TS 파일을 생성한다.
   ```sh
   $ tsp -I file {입력 TS 파일} -P inject --pid 0x11 --replace {XML 파일} -O file {출력 TS 파일}
   ```

## BAT 수정
1. 입력 TS 파일의 BAT 정보를 XML 파일로 추출한다.
   ```sh
   $ tsp -I file {입력 TS 파일} -P tables --pid 0x11 --tid 0x4A --xml {XML 파일} -O drop
   ```
1. 추출된 XML 파일에서 원하는대로 수정한다. (아래는 linkage_descriptor 예제)
   ```xml
   <linkage_descriptor transport_stream_id="0x0431" original_network_id="0x0001" service_id="0x6E3B" linkage_type="0x80">
     <private_data>
       00 00 00 26 03 04 01 02
     </private_data>
   </linkage_descriptor>
   ```
   또는 아래와 같이 generic_descriptor를 이용할 수도 있다.
   ```xml
   <generic_descriptor tag="0x4A">
     04 31 00 01 6E 3B 80 00 00 00 26 03 04 01 02
   </generic_descriptor>
   ```
1. 입력 TS 파일에 새로운 BAT를 적용하여 출력 TS 파일을 생성한다.
   ```sh
   $ tsp -I file {입력 TS 파일} -P inject --pid 0x11 --replace {XML 파일} -O file {출력 TS 파일}
   ```

## EIT 수정
1. 입력 TS 파일의 EIT 정보를 XML 파일로 추출한다.
   ```sh
   $ tsp -I file {입력 TS 파일} -P tables --pid 0x12 --xml {XML 파일} -O drop
   ```
1. 추출된 XML 파일에서 원하는대로 수정한다. (아래는 short_event_descriptor 예제)
   ```xml
   <short_event_descriptor language_code="eng">
     <event_name>Sunrise</event_name>
     <text>Hello, the world</text>
   </short_event_descriptor>   
   ```
   또는 아래와 같이 generic_descriptor를 이용할 수도 있다.
   ```xml
   <generic_descriptor tag="0x4D">
     65 6E 67 07 53 75 6E 72 69 73 65 10 48 65 6C 6C 6F 2C 20 74 68 65 20 77 6F 72 6C 64
   </generic_descriptor>
   ```
1. 입력 TS 파일에 새로운 EIT를 적용하여 출력 TS 파일을 생성한다.
   ```sh
   $ tsp -I file {입력 TS 파일} -P inject --pid 0x12 --replace {XML 파일} -O file {출력 TS 파일}
   ```

## 맺음말
위에서 보듯이 TSDuck 툴에서 XML 파일을 이용하면 MPEG-2 TS 파일에서 SI 내용도 쉽게 수정/추가/삭제할 수 있다.
