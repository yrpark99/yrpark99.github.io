---
title: "FauxPilot (GitHub Copilot 로컬 운용) 소개"
category: [Environment]
toc: true
toc_label: "이 페이지 목차"
---

GitHub Copilot을 로컬 서버로 운용할 수 있게 해 주는 FauxPilot을 소개한다.  
<br>

[FauxPilot](https://github.com/moyix/fauxpilot)은 [GitHub Copilot](https://github.com/features/copilot)을 로컬 서버로 운용할 수 있게 해 주는 오픈 소스 툴이다. (즉, Copilot을 무료로 사용할 수 있게 해 줌, 물론 on-premis로 로컬 서버를 운용해야 하긴 하지만)

## 설치
1. 먼저 아래와 같이 필요한 패키지를 설치한다.
   ```shell
   $ sudo apt install curl zstd docker docker-compose
   ```
   단, docker-compose의 버전은 1.28 이상이어야 한다. 따라서 혹시 Docker compose file에서 에러가 발생하는 경우에는 다음과 같이 확인해 보자.
   ```shell
   $ docker-compose -v
   ```
   만약에 APT로 설치한 버전이 낮다면 [Docker Compose](https://github.com/docker/compose/) 페이지에서 직접 원하는 버전을 다운받아서 설치할 수 있다.
1. 아래와 같이 NVIDIA driver를 설치한다. (Host에서는 CUDA toolkit은 설치할 필요 없음)
   ```shell
   $ sudo ubuntu-drivers autoinstall
   ```
1. [NVIDIA Container Toolkit](https://github.com/NVIDIA/nvidia-docker)을 설치한다. [NVIDIA Installation Guide](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html#docker)를 참고하거나, 아래와 같이 실행하면 된다.
   ```shell
   $ distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
   $ curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
   $ curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
   $ sudo apt update
   $ sudo apt install nvidia-container-toolkit
   $ sudo systemctl restart docker
   ```
1. 아래와 같이 Fauxpilot 소스를 clone 받는다.
   ```shell
   $ git clone https://github.com/moyix/fauxpilot.git
   ```
1. 아래와 같이 setup을 실행한다.
   ```shell
   $ ./setup.sh
   ```
   필요한 패키지가 설치되었는지 검사한 후, 아래와 같이 사용할 AI 모델을 선택하라고 나온다.
   ```
   Models available:
   [1] codegen-350M-mono (2GB total VRAM required; Python-only)
   [2] codegen-350M-multi (2GB total VRAM required; multi-language)
   [3] codegen-2B-mono (7GB total VRAM required; Python-only)
   [4] codegen-2B-multi (7GB total VRAM required; multi-language)
   [5] codegen-6B-mono (13GB total VRAM required; Python-only)
   [6] codegen-6B-multi (13GB total VRAM required; multi-language)
   [7] codegen-16B-mono (32GB total VRAM required; Python-only)
   [8] codegen-16B-multi (32GB total VRAM required; multi-language)
   Enter your choice [6]:
   ```
   AI 모델을 선택하면 해당 모델을 다운로드 받고 셋업이 완료된다.
1. 셋업이 성공하였으면 아래와 같이 실행한다.
   ```shell
   $ ./launch.sh
   ```
   결과로 **fauxpilot-copilot_prox** 이름의 Docker 이미지가 빌드되고, 자동으로 Docker 컨테이너가 실행된다. (단, 콘솔로 출력되는 메시지 내용에서 error가 없어야 함)
   >참고로 만약에 포트 값을 변경하고 싶으면 docker-compose.yaml 파일에서 아래 부분의 `ports` 값을 변경하면 된다.
   >```yaml
   >ports:
   >   - "5000:5000"
   >```
1. [http://localhost:5000](http://localhost:5000) 주소로 접속해 보면 REST API 테스트를 할 수 있는 swagger 화면이 나온다.  
   아래와 같이 파이썬 코드로도 테스트 해 볼 수 있다. ("**def hello**"를 입력했을 때 Copilot이 제안해 주는 코드 테스트)
   ```python
   import openai
   openai.api_key = 'dummy'
   openai.api_base = 'http://localhost:5000/v1'
   result = openai.Completion.create(model='codegen', prompt='def hello', max_tokens=16, temperature=0.1, stop=["\n\n"])
   print(result)
   ```
   위 테스트 코드는 `openai` 패키지를 사용하므로 아래와 같이 해당 패키지를 설치한 후에 실행할 수 있다.
   ```shell
   $ pip3 install openai
   ```

## VSCode에서 사용하기
FauxPilot 페이지에서는 VSCode에서 로컬 Copilot을 사용하도록 설정(settings.json) 파일에서 아래와 같이 추가하면 된다고 나와 있다.
```json
"github.copilot.advanced": {
    "debug.overrideEngine": "codegen",
    "debug.testOverrideProxyUrl": "http://localhost:5000",
    "debug.overrideProxyUrl": "http://localhost:5000"
}
```

하지만 나의 경우에는 위 설정으로는 되질 않았고 (Copilot 익스텐션에서 계속해서 서버에 접속할 수 없다고 나옴), 대신에 [Fauxpilot](https://marketplace.visualstudio.com/items?itemName=Venthe.fauxpilot) 익스텐션을 설치하니깐, 내 로컬 서버와 연결되어 Copilot이 정상적으로 동작하였다.

## 결론
위에서 언급한 **setup.sh** 실행시에 AI 모델을 선택하게 되는데, 여기에서 선택한 AI 모델에 따라 AI 성능이 결정되게 된다. 물론 성능이 좋은 AI 모델을 선택하여 운용하려면 그에 상응하는 리소스가 있어야 할 것이다.  
괜찮은 NVIDIA 그래픽 카드만 있으면 on-premis로 서버를 운용하여 Copilot을 무료로 사용할 수 있으니, 일반 회사에서는 꽤나 매력적인 솔루션일 것 같다.  
GitHub Copilot과 같은 AI 기반의 코드 자동 완성 툴도 놀라운데, 이것을 로컬 서버로 운용할 수 있게 해 주는 툴이 오픈 소스로 나오다니, 정말 프로그래밍의 세계는 정신없이 발전하고 있음을 새삼 느낀다.
