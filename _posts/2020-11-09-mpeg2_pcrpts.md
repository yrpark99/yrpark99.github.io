---
title: "MPEG-2 시스템에서 PCR/DTS/PTS 간단 정리"
category: [MPEG]
toc: true
toc_label: "이 페이지 목차"
---

MPEG-2 시스템에서 A/V 동기화를 위한 PCR, DTS, PTS 등을 간단히 정리해 본다.

## 약어
* **DTS**: Decoding Time Stamp
* **ES**: Elementary Stream
* **PCR**: Program Clock Reference
* **PES**: Packetized Elementary Stream
* **PS**: Program Stream
* **PTS**: Presentation Time Stamp
* **SCR**: System Clock Reference
* **STC**: System Timing Clock
* **TS**: Transport Stream

## MPEG-2 시스템 다중화 및 동기화
MPEG-2 시스템은 아래 그림과 같이 다중화 및 역다중화되고, STC/PCR/DTS/PTS를 사용하여 encoder와 decoder에서 A/V의 동기를 맞춘다.  
![](/assets/images/mpeg2_encoder_decoder.svg)

> 참고로 위에서는 편의상 하나의 프로그램인 경우로 표시하였지만, 실제로 TS에는 여러 개의 프로그램이 포함될 수 있다.

## STC(System Timing Clock)
MPEG 시스템에서 송신 측과 수신 측의 동기를 맞추기 위하여 송신 측에서 발생시키는 공통의 기준 클럭 (27 MHz 기준 클럭)으로, 수신 측에서는 이에 맞추어 STC 타이밍을 재생한다.  
MPEG-2에서는 encoder와 decoder의 기본 클럭으로 27MHz(허용 오차: $\pm$ 810Hz)를 권고하고 있다.

## PCR(Program Clock Reference)
MPEG-1에서는 시스템에 기준이 되는 시각 참조값으로 SCR을 사용한다. MPEG-1에서 PS는 한 개 이상의 PES 스트림을 포함하는 단일 프로그램으로 이루어지므로 SCR 값은 항상 하나이다.  
반면에 MPEG-2에서 TS는 여러 개의 프로그램을 포함할 수 있으므로, PCR은 SCR과 비슷한 용도이지만 각 프로그램마다 다른 시각 기준값을 가질 수 있다는 차이점이 있다.  
<br>
PCR은 MPEG-2 TS에서 프로그램에 대한 상대적인 시간 기준값을 나타내고, 아래식으로 정의된다.  
$PCR(i) = PCR\\_base(i) \times 300 + PCR\\_ext(i)$  
<br>

위에서 언급했듯이 system_clock_frequency는 27Mhz이고, 위 식에서 알 수 있듯이 PCR_base는 90Khz 단위이고, PCR_ext는 27Mhz 단위이다.
> 90KHz를 27MHz로 변경하려면 300을 곱하면 된다. (90KHz $\times$ 300 = 27MHz)

이 PCR 값은 TS 헤더의 adaptation field에 들어 있는데, PCR_base 값은 33bit, PCR_ext 값은 9bit이므로, 전체 PCR 값은 42bit로 구성된다.
> 참고로 이렇게 PCR 값이 90KHz와 27MHz 부분으로 나누어진 것은, MPEG-1에서 SCR은 90KHz를 사용했는데 이것과의 호환성을 위해서라고 한다.
<br>

PCR 값은 인코더의 system clock으로부터 만들어지게 된다. 디코더에서는 이 PCR 값을 수신하여 현재 디코딩 하려는 프로그램의 기준 시간으로 설정하고 뒤에서 설명할 DTS, PTS 시간을 이 PCR 값과 비교하여 디코딩 및 재생을 하게 된다.

## GOP(Group Of Pictures)
MPEG 시스템에서 인코더는 동영상의 압축 효율을 높이기 위하여 각 프레임을 순서대로 압축하지 않고, 여러 개의 프레임을 GOP라는 이름으로 그룹화해서 이전/이후 프레임 정보를 이용하여 예측을 활용하여 압축한다.  
GOP에는 다음과 같이 3가지 종류의 프레임이 있다.
* `I(Intra)-frame`: 이 프레임만으로 완전한 이미지를 구성하는 데이터를 포함함 (즉, 예측을 사용하지 않음, JPEG 수준의 압축이 됨, GOP 간격을 결정할 때 기준이 되는 key 프레임의 역할을 함)
* `P(Predicted)-frame`: 이전의 I 또는 P 프레임을 참조해서 변경 부분의 데이터 만을 포함함 (즉, 순방향 예측을 사용함)
* `B(Bi-directional)-frame`: 이전과 이후의 I/P 프레임을 참조해서 변경 부분의 데이터 만을 포함함 (즉, 양방향 예측을 사용함, 프레임을 가장 많이 압축하지만 화질이 가장 좋지 않음)

GOP의 구성과 길이는 스펙으로 정해지지 않는다. 하나의 GOP로 묶인 프레임의 수를 "GOP number"라고 하며, B-frame의 개수가 많아질수록 압축률은 올라가지만 화질은 떨어지게 된다.
> 보통은 **IBP** 또는 **IBBP** 패턴을 많이 사용한다. (B-frame을 더 넣으면 화질 저하가 너무 심해지므로)

GOP의 프레임 수는 TV 전송과도 관계가 있는데, PAL의 경우에는 초당 24 또는 25 프레임, NTSC의 경우에는 초당 30 프레임으로 구성되기 때문이다.  
<br>

그런데 인코더에서 B-frame은 위에서도 언급했듯이 양방향 예측을 하는 것이므로 I-frame, P-frame을 먼저 생성한 후에야 얻을 수 있고, 디코더에서도 마찬가지로 B-frame은 I-frame, P-frame의 디코딩이 완료된 이후라야 B-frame을 얻을 수 있다.  
따라서 인코더에서는 프레임을 디코딩 프레임 순서대로 송출하고 (이 디코딩 시각은 **<font color=blue>DTS</font>**에 있음), 따라서 디코더 단에서는 프레임을 받아서 순서대로 디코딩은 하지만, 이 디코딩 순서대로 출력하는 것이 아니라 인코더에서 보내준 출력 시각(이 출력 시각은 **<font color=blue>PTS</font>**에 있음)에 맞추어서 출력해야 한다.  
<br>

DTS는 주로 <font color=purple>P-frame</font>의 경우에 실리게 되는데, 이는 P-frame을 먼저 디코딩은 되지만 재생 시에는 B-frame을 먼저 재생시켜야 하므로, P-frame의 경우에는 PTS와 DTS의 값이 달라지기 때문이다.  
반면에 <font color=purple>B-frame</font>의 경우에는 보통 디코딩 후에 곧바로 재생하면 되므로 PTS와 DTS의 값이 같게 된다. 따라서 이런 경우에 B-frame에는 DTS는 생략되고 PTS만 실리게 되고, 이 경우 디코더에서는 PTS 값을 DTS 값으로 사용한다.

## DTS(Decoding time Stamp)
위에서도 언급했듯이 DTS는 디코딩 되어야 하는 시점을 나타내는 시각 값으로, PCR을 레퍼런스로 사용한다.  
단위는 **(system_clock_frequency / 300)**, 즉, **90Khz** 단위이다.  
<br>
아래는 DTS를 계산하는 식이다.  
$DTS(j) = ((system\\_clock\\_frequency \times td_n(j)) \, DIV \, 300) \, \% \, 2^{33}$  

> 위에서 $td_n(j)$는 $n$번째 ES의 $j$번째 access unit이 디코딩 되어야 할 시간을 나타낸다.  
> 참고로 DTS 값은 PES header에서 33bit로 할당되어 있으므로 아래 식에서 $2^{33}$으로 나누었을 때의 나머지 값으로 표현되어 있다.

## PTS(Presentation Time Stamp)
디코더에서 프레임을 올바른 순서로 재생하기 위한 시각 정보는 PTS에 들어있다. DTS와 마찬가지로 PCR을 레퍼런스로 사용하고, 이 값은 PES header에 33bit로 들어있다.  
<br>

즉, 디코딩 된 access unit이 재생되어져야 하는 시점을 나타내는 PTS는 아래식과 같이 계산된다.  
$PTS(k) = ((system\\_clock\\_frequency \times tp_n(k)) \, DIV \, 300) \, \% \, 2^{33}$  

> 위에서 $tp_n(k)$는 $n$번째 ES의 $k$번째 access unit이 재생되어야 할 시간을 나타낸다.  
> DTS로 마찬가지로 300으로 나누어서 33bit로 이루어진 90KHz 단위를 사용한다.

Video PTS는 프레임 간의 시간 간격을 기준으로 단조 증가하게 된다. 예를 들어 25 fps인 경우라면 1초에 25 프레임이 재생되는 것이고, 따라서 프레임 재생 시간 및 프레임 간의 간격은 40 ms가 된다. 마찬가지로 초당 30 프레임이면 30 fps로 나타내고, 이때 프레임당 재생 시간 및 간격은 약 33ms가 된다.

## PCR 얻기
PCR은 아래 그림에서 보듯이 TS 헤더의 adaptation field 내에 들어 있다.
![](/assets/images/mpeg2_pcr.png)  
<br>

구체적으로 TS 헤더의 adaptation_field는 아래와 같이 정의되어 있다.
```c
adaptation_field() {
    adaptation_field_length                     // 8bit
    if (adaptation_field_length > 0) {
        discontinuity_indicator                 // 1bit
        random_access_indicator                 // 1bit
        elementary_stream_priority_indicator    // 1bit
        PCR_flag                                // 1bit
        OPCR_flag                               // 1bit
        splicing_point_flag                     // 1bit
        transport_private_data_flag             // 1bit
        adaptation_field_extension_flag         // 1bit
        if (PCR_flag == '1') {
            program_clock_reference_base        // 33bit
            reserved                            // 6bit
            program_clock_reference_extension   // 9bit
        }
        ...
    }
}
```
즉, TS 헤더의 adaptation_field 중에서 `PCR_flag` 값이 **1**이면 **program_clock_reference_base**(PCR_base 값임, 33bit)와 **program_clock_reference_extension**(PCR_ext, 9bit) 값으로부터 아래와 같이 PCR을 얻을 수 있다.
```c
PCR = program_clock_reference_base * 300 + program_clock_reference_extension
```

## PTS/DTS 얻기
PTS/DTS는 아래와 같이 PES 헤더에 옵션으로 들어 있다.
![](/assets/images/mpeg2_pts.png)  
<br>

구체적으로 PES 패킷 데이터는 아래와 같이 정의되어 있다.
```c
PES_packet() {
    packet_start_code_prefix            // 24bit (0x000001)
    stream_id                           // 8bit
    PES_packet_length                   // 16bit
    if (stream_id != program_stream_map
    && stream_id != padding_stream
    && stream_id != private_stream_2
    && stream_id != ECM
    && stream_id != EMM
    && stream_id != program_stream_directory
    && stream_id != DSMCC_stream
    && stream_id != ITU-T Rec. H.222.1 type E stream) {
        '10'                            // 2bit
        PES_scrambling_control          // 2bit
        PES_priority                    // 1bit
        data_alignment_indicator        // 1bit
        copyright                       // 1bit
        original_or_copy                // 1bit
        PTS_DTS_flags                   // 2bit
        ESCR_flag                       // 1bit
        ES_rate_flag                    // 1bit
        DSM_trick_mode_flag             // 1bit
        additional_copy_info_flag       // 1bit
        PES_CRC_flag                    // 1bit
        PES_extension_flag              // 1bit
        PES_header_data_length          // 8bit
        if (PTS_DTS_flags == '10') {
            '0010'                      // 4bit
            PTS [32..30]                // 3bit
            marker_bit                  // 1bit
            PTS [29..15]                // 15bit
            marker_bit                  // 1bit
            PTS [14..0]                 // 15bit
            marker_bit                  // 1bit
        }
        if (PTS_DTS_flags == '11') {
            '0011'                      // 4bit
            PTS [32..30]                // 3bit
            marker_bit                  // 1bit
            PTS [29..15]                // 15bit
            marker_bit                  // 1bit
            PTS [14..0]                 // 15bit
            marker_bit                  // 1bit
            '0001'                      // 4bit
            DTS [32..30]                // 3bit
            marker_bit                  // 1bit
            DTS [29..15]                // 15bit
            marker_bit                  // 1bit
            DTS [14..0]                 // 15bit
            marker_bit                  // 1bit
        }
        ...
    }
    ...
}
```

즉, PES 헤더에서 `PTS_DTS_flags` 값이 **2**이면 PTS가 들어있고, **3**이면 **PTS**와 **DTS**가 들어있다. PTS와 DTS 값은 여러 개의 비트 필드로 나누어져 있으므로 비트 연산을 제대로 해야 올바른 PTS/DTS 값을 얻을 수 있다.

## PCR/PTS/DTS 분석 툴
나는 입력 TS 스트림 파일을 분석하여 PCR/PTS/DTS 값을 출력하는 툴을 자작하여 사용하고 있는데, 여기서는 쉽게 사용할 수 있는 오픈 소스 툴을 소개하겠다.
- [DVB Inspector](https://github.com/EricBerendsen/dvbinspector)
- [TSDuck](https://tsduck.io/)

시각적으로 보려면 **DVB Inspector** 툴이 낫고, 각 값들을 파일로 저장해서 분석하기에는 **TSDuck** 툴이 낫다. 예를 들어 DVB Inspector로 확인해 보면 PCR/PTS/DTS 값을 16진수/10진수 및 시각값으로 보여주고, 그래프로도 볼 수 있다.  
또, 아래는 TSDuck으로 PCR/PTS/DTS 값을 CSV 파일로 저장하는 예이다.
```sh
$ tsp -I file {입력 TS 파일} -P pcrextract -p {PID} -o {출력 CSV 파일} > /dev/null
```
결과로 CSV 파일이 얻어지고, 열어보면 PCR/PTS/DTS 값이 십진수로 들어있다.  
