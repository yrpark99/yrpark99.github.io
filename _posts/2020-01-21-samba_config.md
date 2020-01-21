---
title: "Samba 서버 설정 팁"
category: samba
toc: true
toc_label: "이 페이지 목차"
---

Windows에서 Linux를 samba로 연결시 설정 관련 팁을 공유한다.

## Symbolic link 동작되게 하기
Samba 기본 설정에서는 Windows에서 Linux에서의 symbolic link가 동작하지 않는다. 즉, 디렉토리 이동이 되지 않는다.  
Symbolic link가 동작되게 하려면 samba 설정 파일(/etc/samba/smb.conf)의 `[global]` 섹션에 아래 내용을 추가하면 된다.
```sh
wide links = yes
unix extensions = no
```

## Windows에서 파일/디렉토리 생성시 모드값
사용자별 섹션에 아래 예와 추가하면 Windows에서 파일/디렉토리 생성시 Linux에서의 모드값이 세팅한대로 결정된다. (아래 예에서는 파일 생성시 모드값은 644(-rw-r--r--), 디렉토리 생성시 모드값은 755(drwxr-xr-x)로 세팅하였음)
```sh
create mask = 644
directory mask = 755
```

## Windows에서 수정시 실행 권한 추가 문제
Samba 기본 설정에서는 Windows에서 파일을 수정하면 Linux에서 해당 파일에 실행(x) 권한이 추가된다. 이는 파일 모드가 변경되는 것으로 원하지 않는 결과인데, 원인은 Windows에서의 파일 속성 중에 archive 속성 때문이다.  
Windows에서 파일을 수정해도 Linux에서 파일 모드가 변경되지 않게 하려면 samba 설정 파일(/etc/samba/smb.conf)의 `[global]` 섹션에 아래 내용을 추가하면 archive 속성이 무시되어 Windows에서 파일을 수정하더라도 실행 권한이 변경되지 않게 된다.
```sh
map archive = no
```

## 공유 디렉토리 환경 설정하기
자신이 생성한 파일/디렉토리는 자신만이 삭제할 수 있는 환경 구성이 (다른 사용자가 생성한 디렉토리 안에서도 추가로 파일/디렉토리 생성은 가능) 목표이다.  
디렉토리 생성시 sticky bit가 세팅되도록 samba 설정 파일(/etc/samba/smb.conf)에 아래 예와 같이 구성할 수 있다. (아래 예에서 그룹 이름은 group_name, base 디렉토리는 /home/public 임)
```sh
[public]
    comment = public (for data share)
    path = /home/public
    writeable = yes
    browseable = yes
    guest ok = yes
    write list = @group_name
    create mask = 644
    force directory mode = 1775
    force group = group_name
```
즉, 디렉토리 생성시 sticky bit를 세팅하고, 그룹에도 write 권한을 주는 것이 핵심이다.

## 접속시 SMB 버전 제한하기
SMBv2는 대용량 파일 복사시에 Linux 서버의 응답이 느려질 수 있다. 반면에 SMBv3는 (Windows10에서 지원) SMB direct 기능을 지원하여 이런 문제가 없으므로, 필요하면 SMBv3로만 접속을 제한할 수 있다.  
Samba 설정 파일(/etc/samba/smb.conf)의 `[global]` 섹션에 아래와 같이 추가하면 SMBv3 이상만 접속이 허가된다.
```sh
client min protocol = SMB3
```
