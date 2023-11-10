---
title: "Linux capability"
category: Linux
toc: true
toc_label: "이 페이지 목차"
---

Linux capability 정리  

## Capability
Linux 시스템에서 capability는 실행할 수 있는 권한을 검사함으로써 보안을 높이는 중요한 도구이다.  
일반적으로 Linux에서 <font color=blue>root(UID=0)</font>에 실행되는 프로세스는 권한이 있고, 그렇지 않은 프로세스는 권한을 갖고 있지 않다. 예를 들어 시스템의 시간을 변경하는 것은 root에게만 허용하고, 일반 사용자는 시스템의 시간을 변경할 수 없게 해야 한다.   
Kernel은 프로세스 실행시 권한을 검사하는데, 권한이 있는 프로세스는 모든 커널 권한 검사를 우회하는 반면에, 권한이 없는 프로세스는 프로세스의 자격 증명(일반적으로 effective UID, effective GID 등)을 기반으로 전체 권한 검사를 받게 된다.  
<br>

그런데 예를 들어 **passwd** 명령의 경우, 사용자 계정의 암호를 변경하는 기능인데, 이 과정에서 **/etc/passwd**, **/etc/shadow** 파일과 같은 시스템 파일을 수정해야 한다. 그런데 이 파일들은 일반 유저에게는 write 권한이 없으므로, 이 파일들을 수정하기 위해서는 root 권한이 필요하다.  
이러한 경우를 위하여 Linux는 <font color=purple>SUID</font>(Set User ID)/<font color=purple>SGID</font>(Set Group ID) 비트를 사용하여 일반 사용자에서 root로 권한을 상승시키는 방법을 제공한다.  
예를 들어 passwd를 확인해 보면, 아래 캡쳐와 같이 passwd 파일에 SUID 비트(<font color=red>s</font>)가 설정되어 있음을 확인할 수 있다.
```sh
$ ll /usr/bin/passwd
-rwsr-xr-x 1 root root 68208 11월 29  2022 /usr/bin/passwd
```
따라서 일반 사용자가 passwd 명령을 실행하면 SUID 비트를 통해 root 권한으로 상승하여, 시스템 파일을 수정할 수 있게 된다.  
그런데 root는 모든 권한을 가지고 있으므로 (all mighty), root의 특정 권한만이 필요한 경우에도 root의 모든 권한을 할당하는 방식은 해당 프로그램이 해킹되었을 때에 root의 모든 권한을 탈취당할 수 있는 보안 위협이 있다.  
예를 들어, 만약에 공격자가 passwd 명령의 보안 취약점을 이용해서 권한을 탈취하게 되면 공격자는 root의 모든 권한을 얻을 수 있게 된다.  
<br>

**Capability**는 root의 권한을 세분화(시스템의 시간 변경, 커널 모듈 load/remove, 파일 소유자/소유그룹 변경, kill 권한, 네트워크 관리, 리부팅 등)하여, 일반 유저에게 세분화되고 제한된 root의 권한을 갖도록 만든 보안 모델이다.  
이는 SUID/SGID 비트를 사용하는 방법에 비해서 추가적인 접근 제어가 필요하지 않다는 편리한 점이 있다.  

## 지원되는 capability 
Linux에서 아래와 같이 실행하면, 간단한 capability 관련 매뉴얼을 볼 수 있다.
```sh
$ man capabilities
```
아래와 같이 실행하면 시스템에서 지원하는 전체 capability 항목이 출력된다.
```sh
$ capsh --print | grep Bounding
```

Linux에서 capability는 파일에 대한 capability와 프로세스에 대한 capability를 각각 운용할 수 있는데, 아래에서 각각 다루겠다.

## 파일 capability
파일 capability는 security namespace에서 확장된 속성(**xattr**)을 이용하여 구현되었으므로, 해당 파일시스템에서 xattr을 지원해야 한다.  
예를 들어 임베디드 장치에서 squashfs를 사용하는 경우라면, Kernel config 설정에서 아래 항목이 있어야 한다.
```sh
CONFIG_SQUASHFS_XATTR=y
```

파일에 대한 capability 설정은 `setcap` 명령으로 하고, 형식은 다음과 같다.
```sh
$ sudo setcap 'capability 설정' <타겟 파일>
```
위에서 **capability 설정**은 '1개 이상의 capability 항목, operator, flag'로 구성된다.
- **capability 항목**: 설정할 `cap_xxx` (또는 `CAP_XXX`로 대소문자 무관)
- **operator**: 아래 중의 하나
  - **+**: 추가
  - **-**: 제거
  - **=**: 대입
- **flag**: 아래 중의 하나
  - **e**: Effective (효력 부여)
  - **i**: Inheritable (exec 계열의 시스템 콜을 사용할 때 권한 상속 여부)
  - **p**: Permitted (허용)

파일에 할당된 capability 조회는 아래와 같이 `getcap` 명령을 이용하면 된다.
```sh
$ getcap <타겟 파일>
```

파일에 할당된 capability를 제거하려면 아래와 같이 **-r** (remove) 아규먼트를 사용하면 된다.
```sh
$ sudo setcap -r <타겟 파일>
```
<br>

이제 예로 **tcudmp** 명령으로 파일 capability를 실습해 보자. (tcpdump는 WireShark와 마찬가지로 네트워크 패킷을 캡쳐하는 CLI 툴로, **cap_net_raw**와 같은 root 권한이 필요함)  
먼저 아래와 같이 실행해 보면, SUID 비트가 설정되지 않았음을 확인할 수 있다.
```sh
$ ls -l /usr/sbin/tcpdump
-rwxr-xr-x 1 root root 1044232  2월 10  2023 /usr/sbin/tcpdump
```
아래와 같이 파일에 capability가 설정되었는지 확인해보면, 아무 capability도 설정되어 있지 않다.
```sh
$ getcap /usr/sbin/tcpdump
$
```
아래와 같이 일반 사용자 권한으로 실행시키면, 당연히 권한이 없다는 에러가 발생한다.
```sh
$ tcpdump
tcpdump: eth0: You don't have permission to capture on that device
(socket: Operation not permitted)
```
반면에 아래와 같이 root 권한으로 실행시키면, 정상적으로 실행된다.
```sh
$ sudo tcpdump
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), capture size 262144 bytes
```
<br>

이제 연습으로 파일 capability를 이용하여 일반 사용자에게도 tcpdump를 실행할 수 있는 권한을 할당해 보자.  
아래와 같이 `setcap` 명령으로 tcpdump 파일에 **cap_net_raw** capability를 할당한 후, `getcap` 명령으로 확인해 본다.
```sh
$ sudo setcap 'cap_net_raw+eip' /usr/sbin/tcpdump
$ getcap /usr/sbin/tcpdump
/usr/sbin/tcpdump = cap_net_raw+eip
```
이제부터는 아래 캡쳐와 같이 일반 사용자가 실행해도 권한 에러 없이 잘 동작한다.
```sh
$ tcpdump
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), capture size 262144 bytes
```

참고로 실행 중인 프로세스의 capability는 아래와 같이 `pscap` 툴로 확인할 수 있다.
```sh
$ getpcaps {PID}
```
이를 이용하여 위에서 실행 중인 tcpdump의 capability를 확인해 보면, 기대대로 아래 캡쳐와 같이 **cap_net_raw** capability가 출력된다.
```sh
$ getpcaps `pidof tcpdump`
34274: = cap_net_raw+ep
```
<br>

테스트를 마쳤으면, 아래와 같이 파일에 할당된 capability를 제거한 후, 확인해 본다.
```sh
$ sudo setcap -r /usr/sbin/tcpdump
$ getcap /usr/sbin/tcpdump
$
```

## 프로세스 capability
프로세스 capability는 실행 중인 프로세스의 capability를 변경하는 것으로, 마찬가지로 Linux에서 native하게 지원하지만, [libcap](https://www.kernel.org/pub/linux/libs/security/linux-privs/libcap2) 패키지를 이용하는 것이 편리하다.  
우분투에서는 아래와 같이 libcap2 패키지를 설치하면 이용할 수 있다.
```sh
$ sudo apt install libcap2 libcap2-bin
```
libcap2 패키지는 파일과 프로세스에 대한 capability를 모두 지원하는데, 여기서는 프로세스의 capability를 설정하는 예제를 작성해 보았다. (빌드시에 `-lcap` 옵션으로 libcap 라이브러리를 링크해야 하고, 실행은 root 권한으로 해야 함)  
<br>

아래는 실행 프로세스에 원하는 capability는 추가하고, 원하지 않는 capability는 제거하는 예제이다.
```c
#define _GNU_SOURCE
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/capability.h>

int set_capabilities(const cap_value_t caps_list[], int caps_list_num)
{
    if (caps_list == NULL || caps_list_num <= 0)
    {
        printf("%s(): Wrong input\n", __func__);
        return -1;
    }

    cap_t caps = cap_get_proc();
    if (caps == NULL)
    {
        printf("%s(): Failed to get capability\n", __func__);
        return -1;
    }
    if (cap_clear(caps) == -1)
    {
        printf("%s(): Failed to clear all capability\n", __func__);
        cap_free(caps);
        return -1;
    }
    if (cap_set_flag(caps, CAP_EFFECTIVE, caps_list_num, caps_list, CAP_SET) == -1 ||
        cap_set_flag(caps, CAP_PERMITTED, caps_list_num, caps_list, CAP_SET) == -1 ||
        cap_set_flag(caps, CAP_INHERITABLE, caps_list_num, caps_list, CAP_SET) == -1)
    {
        printf("%s(): Failed to set capability flag\n", __func__);
        cap_free(caps);
        return -1;
    }
    if (cap_set_proc(caps) == -1)
    {
        printf("%s(): Failed to set capability\n", __func__);
        cap_free(caps);
        return -1;
    }
    cap_free(caps);
    return 0;
}

int drop_capabilities(const cap_value_t caps_list[], int caps_list_num)
{
    if (caps_list == NULL || caps_list_num <= 0)
    {
        printf("%s(): Wrong input\n", __func__);
        return -1;
    }

    cap_t caps = cap_get_proc();
    if (caps == NULL)
    {
        printf("%s(): Failed to get capability\n", __func__);
        return -1;
    }
    if (cap_set_flag(caps, CAP_EFFECTIVE, caps_list_num, caps_list, CAP_CLEAR) == -1 ||
        cap_set_flag(caps, CAP_PERMITTED, caps_list_num, caps_list, CAP_CLEAR) == -1 ||
        cap_set_flag(caps, CAP_INHERITABLE, caps_list_num, caps_list, CAP_CLEAR) == -1)
    {
        printf("%s(): Failed to clear capability flag\n", __func__);
        cap_free(caps);
        return -1;
    }
    if (cap_set_proc(caps) == -1)
    {
        printf("%s(): Failed to set capability\n", __func__);
        cap_free(caps);
        return -1;
    }
    cap_free(caps);
    return 0;
}

int main(int argc, char *argv[])
{
    cap_value_t caps_list[] = {CAP_SETGID, CAP_SETUID, CAP_SYS_BOOT, CAP_SYS_TIME};
    cap_value_t caps_drop_list[] = {CAP_SETGID, CAP_SETUID};
    int caps_list_num = sizeof(caps_list) / sizeof(caps_list[0]);
    int caps_drop_list_num = sizeof(caps_drop_list) / sizeof(caps_drop_list[0]);

    if (getuid() != 0)
    {
        printf("Current uid=%d is not root\n", getuid());
        return 1;
    }
    if (set_capabilities(caps_list, caps_list_num) != 0)
    {
        printf("Failed to set capability\n");
        return 1;
    }
    if (drop_capabilities(caps_drop_list, caps_drop_list_num) != 0)
    {
        printf("Failed to drop capability\n");
        return 1;
    }
    return 0;
}
```

위에서 보듯이 <font color=purple>cap_get_proc()</font>를 호출하여 현재 프로세스의 capability를 얻은 후에, capability를 추가할 때는 <font color=purple>cap_set_flag()</font> 호출시 **CAP_SET** 값을 사용하고, capability를 제거할 때는 **CAP_CLEAR** 값을 사용하여 세팅한 후, <font color=purple>cap_set_proc()</font>를 호출하면 된다.
