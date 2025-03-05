---
title: "Linux에서 유용한 툴들의 업데이트 스크립트"
category: [Linux]
toc: true
toc_label: "이 페이지 목차"
---

Linux 환경에서 유용하게 사용 중인 tool 들의 업데이트를 자동화하는 스크립트를 작성해 보았다.

## 스크립트 작성 이유
나는 개발 서버로 Ubuntu를 사용 중인데, 대부분의 유용한 tool 들이 최신 우분투가 아니면 ATP 저장소에 있지 않은 경우도 있고, ATP 저장소에 있는 경우에도 최신 버전으로는 업데이트가 자주 되지 않는다.  
그래서 최신 버전으로 업데이트하려면 각 tool 들의 GitHub 페이지에서 최신 릴리즈를 직접 다운로드 받아서 설치해야 하는 번거로움이 있었다.  
그런데 [https://api.github.com/repos](https://api.github.com/repos) 페이지를 통해서 해당 툴의 최신 버전 정보를 얻을 수 있다는 사실을 알게 되어서, 이를 이용한 업데이트 스크립트를 작성하였고, 사용해 보니 꽤 편리하여 스크립트 내용을 공유한다.  
<br>

아래는 주로 내가 애용하는 tool 들의 업데이트 스크립트 예제들이고, 마찬가지로 방법으로 다른 tool 들도 업데이트 스크립트를 작성하여 이용할 수 있다.

> ℹ️ 참고로 아래 스크립트들은 해당 툴이 설치가 되지 않은 상태이면 해당 툴을 최신 버전으로 설치한다.

## [bat](https://github.com/sharkdp/bat)
```sh
#!/bin/sh
APP="bat"
INSTALLED_VERSION=v$(bat --version | awk '{print $2}')
LATEST_VERSION=$(curl -s "https://api.github.com/repos/sharkdp/bat/releases/latest" | grep -Po '"tag_name": "\K[^"]*')
echo "${APP} installed version: ${INSTALLED_VERSION}"
echo "${APP} latest version: ${LATEST_VERSION}"
if [ "${INSTALLED_VERSION}" = "${LATEST_VERSION}" ]; then
    echo "You already have latest version ${APP}"
    exit
fi
wget -q "https://github.com/sharkdp/bat/releases/download/${LATEST_VERSION}/bat-${LATEST_VERSION}-x86_64-unknown-linux-musl.tar.gz"
tar xfz bat-"${LATEST_VERSION}"-x86_64-unknown-linux-musl.tar.gz
sudo install bat-"${LATEST_VERSION}"-x86_64-unknown-linux-musl/bat /usr/bin/
rm -rf bat-"${LATEST_VERSION}"-x86_64-unknown-linux-musl.tar.gz bat-"${LATEST_VERSION}"-x86_64-unknown-linux-musl/
echo "Install latest ${APP} is done"
```

## [eza](https://github.com/eza-community/eza)
```sh
#!/bin/sh
APP="eza"
INSTALLED_VERSION=$(eza --version | awk 'NR==2 {print $1}')
LATEST_VERSION=$(curl -s "https://api.github.com/repos/eza-community/eza/releases/latest" | grep -Po '"tag_name": "\K[^"]*')
echo "${APP} installed version: ${INSTALLED_VERSION}"
echo "${APP} latest version: ${LATEST_VERSION}"
if [ "${INSTALLED_VERSION}" = "${LATEST_VERSION}" ]; then
    echo "You already have latest version ${APP}"
    exit
fi
wget -q "https://github.com/eza-community/eza/releases//download/${LATEST_VERSION}/eza_x86_64-unknown-linux-musl.tar.gz"
tar xfz eza_x86_64-unknown-linux-musl.tar.gz
sudo install eza /usr/bin/
rm -f eza_x86_64-unknown-linux-musl.tar.gz eza
echo "Install latest ${APP} is done"
```

## [fd](https://github.com/sharkdp/fd)
```sh
#!/bin/sh
APP="fd"
INSTALLED_VERSION=v$(fd --version | awk '{print $2}')
LATEST_VERSION=$(curl -s "https://api.github.com/repos/sharkdp/fd/releases/latest" | grep -Po '"tag_name": "\K[^"]*')
echo "${APP} installed version: ${INSTALLED_VERSION}"
echo "${APP} latest version: ${LATEST_VERSION}"
if [ "${INSTALLED_VERSION}" = "${LATEST_VERSION}" ]; then
    echo "You already have latest version ${APP}"
    exit
fi
wget -q "https://github.com/sharkdp/fd/releases/download/${LATEST_VERSION}/fd-${LATEST_VERSION}-x86_64-unknown-linux-musl.tar.gz"
tar xfz fd-"${LATEST_VERSION}"-x86_64-unknown-linux-musl.tar.gz
sudo install fd-"${LATEST_VERSION}"-x86_64-unknown-linux-musl/fd /usr/bin/
rm -rf fd-"${LATEST_VERSION}"-x86_64-unknown-linux-musl.tar.gz fd-"${LATEST_VERSION}"-x86_64-unknown-linux-musl/
echo "Install latest ${APP} is done"
```

## [fzf](https://github.com/junegunn/fzf)
```sh
#!/bin/sh
APP="fzf"
INSTALLED_VERSION=$(fzf --version | awk '{print $1}')
LATEST_VERSION=$(curl -s "https://api.github.com/repos/junegunn/fzf/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
echo "${APP} installed version: ${INSTALLED_VERSION}"
echo "${APP} latest version: ${LATEST_VERSION}"
if [ "${INSTALLED_VERSION}" = "${LATEST_VERSION}" ]; then
    echo "You already have latest version ${APP}"
    exit
fi
wget -q "https://github.com/junegunn/fzf/releases/download/v${LATEST_VERSION}/fzf-${LATEST_VERSION}-linux_amd64.tar.gz"
tar xfz fzf-"${LATEST_VERSION}"-linux_amd64.tar.gz
sudo install fzf /usr/bin/
rm -f fzf-"${LATEST_VERSION}"-linux_amd64.tar.gz fzf
echo "Install latest ${APP} is done"
```

## [GitUI](https://github.com/gitui-org/gitui)
```sh
#!/bin/sh
APP="gitui"
INSTALLED_VERSION=v$(gitui --version | awk '{print $2}')
LATEST_VERSION=$(curl -s "https://api.github.com/repos/gitui-org/gitui/releases/latest" | grep -Po '"tag_name": "\K[^"]*')
echo "${APP} installed version: ${INSTALLED_VERSION}"
echo "${APP} latest version: ${LATEST_VERSION}"
if [ "${INSTALLED_VERSION}" = "${LATEST_VERSION}" ]; then
    echo "You already have latest version ${APP}"
    exit
fi
wget -q "https://github.com/gitui-org/gitui/releases/download/${LATEST_VERSION}/gitui-linux-x86_64.tar.gz"
tar xfz gitui-linux-x86_64.tar.gz
sudo install gitui /usr/bin/
rm -f gitui-linux-x86_64.tar.gz gitui
echo "Install latest ${APP} is done"
```

## [Lazygit](https://github.com/jesseduffield/lazygit)
```sh
#!/bin/sh
APP="lazygit"
INSTALLED_VERSION=$(lazygit --version | awk -F 'version=' '{print $2}' | awk -F ',' '{print $1}')
LATEST_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
echo "${APP} installed version: ${INSTALLED_VERSION}"
echo "${APP} latest version: ${LATEST_VERSION}"
if [ "${INSTALLED_VERSION}" = "${LATEST_VERSION}" ]; then
    echo "You already have latest version ${APP}"
    exit
fi
wget -q "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LATEST_VERSION}_Linux_x86_64.tar.gz"
tar xfz lazygit_"${LATEST_VERSION}"_Linux_x86_64.tar.gz lazygit
sudo install lazygit /usr/bin/
rm -f lazygit_"${LATEST_VERSION}"_Linux_x86_64.tar.gz lazygit
echo "Install latest ${APP} is done"
```

## [Neovim](https://github.com/neovim/neovim)
```sh
#!/bin/sh
APP="nvim"
INSTALLED_VERSION=$(nvim --version | awk 'NR==1 {print $2}')
LATEST_VERSION=$(curl -s "https://api.github.com/repos/neovim/neovim/releases/latest" | grep -Po '"tag_name": "\K[^"]*')
echo "${APP} installed version: ${INSTALLED_VERSION}"
echo "${APP} latest version: ${LATEST_VERSION}"
if [ "${INSTALLED_VERSION}" = "${LATEST_VERSION}" ]; then
    echo "You already have latest version ${APP}"
    exit
fi
GLIBC_VERSION=$(getconf GNU_LIBC_VERSION | awk '{print $2}')
COMPARE_RESULT=$(echo "${GLIBC_VERSION} <= 2.27" | bc -l)
if [ "$COMPARE_RESULT" -eq 1 ]; then
    wget -q "https://github.com/neovim/neovim-releases/releases/download/${LATEST_VERSION}/nvim-linux-x86_64.tar.gz"
else
    wget -q "https://github.com/neovim/neovim/releases/download/${LATEST_VERSION}/nvim-linux-x86_64.tar.gz"
fi
tar xfz nvim-linux-x86_64.tar.gz
sudo chown -R root:root nvim-linux-x86_64/
sudo cp -arf nvim-linux-x86_64/* /usr/local/
sudo rm -rf nvim-linux-x86_64/
rm -rf nvim-linux-x86_64.tar.gz nvim-linux-x86_64/
echo "Install latest ${APP} is done"
```

## [ripgrep (rg)](https://github.com/BurntSushi/ripgrep)
```sh
#!/bin/sh
APP="ripgrep"
INSTALLED_VERSION=$(rg --version | awk 'NR==1 {print $2}')
LATEST_VERSION=$(curl -s "https://api.github.com/repos/BurntSushi/ripgrep/releases/latest" | grep -Po '"tag_name": "\K[^"]*')
echo "${APP} installed version: ${INSTALLED_VERSION}"
echo "${APP} latest version: ${LATEST_VERSION}"
if [ "${INSTALLED_VERSION}" = "${LATEST_VERSION}" ]; then
    echo "You already have latest version ${APP}"
    exit
fi
wget -q "https://github.com/BurntSushi/ripgrep/releases/download/${LATEST_VERSION}/ripgrep-${LATEST_VERSION}-x86_64-unknown-linux-musl.tar.gz"
tar xfz ripgrep-"${LATEST_VERSION}"-x86_64-unknown-linux-musl.tar.gz
sudo install ripgrep-"${LATEST_VERSION}"-x86_64-unknown-linux-musl/rg /usr/bin/
rm -rf ripgrep-"${LATEST_VERSION}"-x86_64-unknown-linux-musl.tar.gz ripgrep-"${LATEST_VERSION}"-x86_64-unknown-linux-musl/
echo "Install latest ${APP} is done"
```

## [repgrep (rgr)](https://github.com/acheronfail/repgrep)
```sh
#!/bin/sh
APP="rgr"
INSTALLED_VERSION=$(rgr --version | awk 'NR==1 {print $2}')
LATEST_VERSION=$(curl -s "https://api.github.com/repos/acheronfail/repgrep/releases/latest" | grep -Po '"tag_name": "\K[^"]*')
echo "${APP} installed version: ${INSTALLED_VERSION}"
echo "${APP} latest version: ${LATEST_VERSION}"
if [ "${INSTALLED_VERSION}" = "${LATEST_VERSION}" ]; then
    echo "You already have latest version ${APP}"
    exit
fi
wget -q "https://github.com/acheronfail/repgrep/releases/download/${LATEST_VERSION}/repgrep-${LATEST_VERSION}-x86_64-unknown-linux-musl.tar.gz"
tar xfz repgrep-"${LATEST_VERSION}"-x86_64-unknown-linux-musl.tar.gz
sudo install repgrep-"${LATEST_VERSION}"-x86_64-unknown-linux-musl/rgr /usr/bin/
rm -rf repgrep-"${LATEST_VERSION}"-x86_64-unknown-linux-musl.tar.gz repgrep-"${LATEST_VERSION}"-x86_64-unknown-linux-musl/
echo "Install latest ${APP} is done"
```

## [Yazi](https://github.com/sxyazi/yazi)
```sh
#!/bin/sh
APP="yazi"
INSTALLED_VERSION=v$(yazi --version | awk '{print $2}')
LATEST_VERSION=$(curl -s "https://api.github.com/repos/sxyazi/yazi/releases/latest" | grep -Po '"tag_name": "\K[^"]*')
echo "${APP} installed version: ${INSTALLED_VERSION}"
echo "${APP} latest version: ${LATEST_VERSION}"
if [ "${INSTALLED_VERSION}" = "${LATEST_VERSION}" ]; then
    echo "You already have latest version ${APP}"
    exit
fi
wget -q "https://github.com/sxyazi/yazi/releases/download/${LATEST_VERSION}/yazi-x86_64-unknown-linux-musl.zip"
unzip -q yazi-x86_64-unknown-linux-musl.zip
sudo install yazi-x86_64-unknown-linux-musl/yazi /usr/local/bin/
sudo install yazi-x86_64-unknown-linux-musl/ya /usr/local/bin/
rm -rf yazi-x86_64-unknown-linux-musl.zip yazi-x86_64-unknown-linux-musl/
echo "Install latest ${APP} is done"
```

## [zoxide](https://github.com/ajeetdsouza/zoxide)
```sh
#!/bin/sh
APP="zoxide"
INSTALLED_VERSION=$(zoxide --version | awk '{print $2}' | cut -d'-' -f1)
LATEST_VERSION=$(curl -s "https://api.github.com/repos/ajeetdsouza/zoxide/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
echo "${APP} installed version: ${INSTALLED_VERSION}"
echo "${APP} latest version: v${LATEST_VERSION}"
if [ "${INSTALLED_VERSION}" = "${LATEST_VERSION}" ]; then
    echo "You already have latest version ${APP}"
    exit
fi
wget -q "https://github.com/ajeetdsouza/zoxide/releases/download/v${LATEST_VERSION}/zoxide-${LATEST_VERSION}-x86_64-unknown-linux-musl.tar.gz"
tar xfz zoxide-"${LATEST_VERSION}"-x86_64-unknown-linux-musl.tar.gz zoxide
sudo install zoxide /usr/bin/
rm -rf zoxide-"${LATEST_VERSION}"-x86_64-unknown-linux-musl.tar.gz zoxide
echo "Install latest ${APP} is done"
```
