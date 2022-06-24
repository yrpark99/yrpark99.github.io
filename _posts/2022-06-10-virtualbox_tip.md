---
title: "VirtualBox 명령어 팁"
category: Environment
toc: true
toc_label: "이 페이지 목차"
---

VirtualBox 명령어 팁을 기록한다.

<br>
몇 년 전부터는 가상 개발 환경 구축시 Docker나 WSL를 주로 사용하기 때문에 [VirtualBox](https://www.virtualbox.org/)의 사용 빈도가 상당히 줄었고, 그러다 보니 간혹 VirtualBox를 사용할 때 (특히 커맨드 라인으로 작업 필요시에) 사용법이 기억나지 않는 경우가 있어서 주요 명령어 관련 팁을 기록으로 남긴다.

## Windows에서 VirtualBox 설치
예전 5.x 버전 때에는 Windows Hyper-V가 켜져 있으면 문제가 좀 있었는데, v6.x 이상부터는 이런 문제가 없어졌다. 간단히 VirtualBox 홈페이지에서 최신 버전을 다운받아서 설치하면 된다.  
설치가 끝나면 필요에 따라서 게스트 확장 패키지도 다운받아서 설치한다.

## Ubuntu에서 VirtualBox 설치
1. 방법 1  
   **/etc/apt/sources.list** 파일에 아래 내용과 같이 추가한다. (단, 아래에서 `<mydist>` 부분에 자신의 OS 배포판 이름을 넣어야 함, 예를 들어 18.04는 bionic, 20.04는 focal, 22.04는 jammy)
   ```shell
   deb [arch=amd64] https://download.virtualbox.org/virtualbox/debian <mydist> contrib
   ```
   아래와 같이 VirtualBox key를 추가한다.
   ```shell
   $ wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -
   ```
   이제 아래 예와 같이 설치할 수 있다.
   ```shell
   $ sudo apt-get update
   $ sudo apt-get install virtualbox-6.1
   ```
1. 방법 2  
   아래와 같이 `virtualbox-qt` 패키지로 설치할 수 있다.
   ```shell
   $ sudo apt install virtualbox-qt
   ```
1. 방법 3  
   [VirtualBox 홈페이지 다운로드 페이지](https://www.virtualbox.org/wiki/Linux_Downloads)에서 자신의 OS에 맞는 패키지 파일을 다운받아서 아래와 같이 설치하면 된다.
   ```shell
   $ sudo dpkg -i <패키지 이름.deb>
   ```

* 필요시 게스트 확장 패키지는 아래와 같이 설치할 수 있다.
  ```shell
  $ sudo apt install virtualbox-guest-additions-iso
  ```

## VirtualBox 실행
VirtualBox 관리자 UI는 Windows에서는 `VirtualBox.exe` 파일을 실행시키면 되고, Linux에서는 아래와 같이 `virtualbox` 파일을 실행시키면 된다.
```shell
$ virtualbox
```
`VirtualBoxVM`, `VBoxHeadless` 등의 기타 툴들은 Windows, Linux에서 동일하게 사용할 수 있는데, 여기서는 편의상 Linux에서의 예를 들었다.

<br>
참고로 특정 VM을 GUI로 띄워서 실행시키려면 아래와 같이 `VirtualBoxVM`를 실행하면 된다.
```shell
$ VirtualBoxVM --separate --startvm <VM 이름>
```
또 GUI 없이 특정 VM을 실행시키려면 아래와 같이 `VBoxHeadless`를 실행하면 된다.
```
$ VBoxHeadless --startvm <VM 이름>
```

## 공용 서버 VM의 웹 서버에 접속하기
공용 서버의 VirtualBox VM에서 특정 용도의 웹 서버 프로그램을 운용하고, 동일 망의 클라이언트에서 VM의 웹 서버에 접속하려면 `VM 설정 -> 네트워크 -> 어댑터 1`에서 **"고급"**을 클릭하고 **"포트 포워딩"** 버튼을 눌러서 아래 예와 같이 rule을 추가한다.  (아래 예에서는 클라이언트가 사용할 포트를 8080, VM 웹 서버는 80 포트를 사용한다고 가정)
```s
프로토콜: TCP, 호스트 IP: 공용 서버 IP, 호스트 포트: 8080, 게스트 IP: VM IP, 게스트 포트: 80
```
이후 동일 망의 클라이언트에서 http://ip:8080/url/ 주소 형태로 연결하면 VM 웹 서버에 접속이 된다.

## 가상 디스크 용량 늘리기
>편의상 아래에서는 Linux에서 실행하는 예인데, Windows에서도 동일하게 실행할 수 있다.

1. 만약 VMDK 파일이면 아래 예와 같이 `VBoxManage`의 **clonehd** 기능으로 vmdk 파일을 vdi로 변경한다. (예: test.vmdk -> test.vdi)
   ```shell
   $ VBoxManage clonehd test.vmdk test.vdi --format vdi
   ```
1. 아래 예와 같이 `VBoxManage`의 **modifyhd** 기능으로 사이즈를 변경한다. (예: test.vdi 파일을 40GiB(40960MiB) 크기로 변경)
   ```shell
   $ VBoxManage modifyhd test.vdi --resize 40960
   ```
   (참고로 modifyhd 옵션은 UUID를 변경하고, modifymedium 옵션은 UUID를 변경하지 않으므로 속도가 더 빠름)
1. 만약에 VMDK로 사용 중이었다면, VirtualBox GUI 관리자에서 `설정 -> 저장소`를 선택 후 기존 vmdk 연결을 제거하고 새로운 vdi 파일을 추가해 준다.
1. 이후 가상 머신을 기동시킨 후, guest OS에서 아래와 같이 디스크 볼륨을 확장하면 된다. (아래 커맨드 대신 `gparted` GUI 툴을 이용해도 됨)
   ```shell
   # 파티션 layout확인, 디스크 디바이스 리스트를 확인한다.
   $ sudo fdisk -l
   # 아래 예는 /dev/sda2 인 경우로 가정
   $ sudo fdisk /dev/sda
   ```
   이후 fdisk 프롬프트에서 아래와 같이 명령을 입력한다. (아래에서 `#` 이후는 각각의 의미를 설명한 것임)
   ```ini
   d # 파티션 지우기를 선택
   2 # /dev/sda2을 실제로 삭제
   n # 새로운 파티션을 생성
   p # Primary 파티션을 선택
   2 # 2번 파티션을 생성
   엔터
   엔터
   w # 파티션 정보를 write
   ```
   이제 VM을 리부팅 시킨 후, 아래 예와 같이 실행하면 가상 디스크 용량이 늘어난다.
   ```shell
   $ sudo pvresize /dev/sda2
   $ sudo pvscan
   $ sudo lvextend -l +100%FREE /dev/mapper/VolGroup-lv_root
   $ sudo resize2fs /dev/mapper/VolGroup-lv_root
   ```

## KVM 이미지를 VirtualBox 이미지로 변환하기
Linux에서는 VirtualBox 대신에 `KVM`(Kernel-based Virtual Machine)을 사용하는 경우도 있는데, 여기에서 사용된 KVM 이미지를 VirtualBox 이미지로 변환하려면 VirtualBox에 있는 `VBoxManage`를 이용하여 아래 예와 같이 실행시키면 된다. (Windows도 마찬가지)  
```shell
$ VBoxManage convertfromraw -format VDI input.img output.vdi
```

## Vargrant
[Vargant](https://www.vagrantup.com/)는 VirtualBox를 커맨드 라인으로 제어할 수 있는 툴로, 나도 오래전에 VirtualBox 이미지를 배포하거나 관리할 때는 사용을 했었다.  
그러다 Docker나 WSL을 사용하면서 VirtualBox의 사용 빈도가 많이 줄었고, 이에 따라 Vagrant도 자연스럽게 거의 사용하지 않게 되어, 여기서 별도의 사용법은 기록에 남기지 않는다.
