---
title: "내 Neovim(LazyVim) 설정"
category: [Editor]
toc: true
toc_label: "이 페이지 목차"
---

내 Neovim(LazyVim)의 설정 내용이다.  
<br>

나의 주력 에디터는 [VS Code](https://code.visualstudio.com/)지만, Linux 콘솔 환경에서 편의상 가끔 [Neovim](https://neovim.io/)도 보조적으로 사용하고 있어서, Neovim을 VS Code와 유사한 환경을 갖추어서 사용 중이다.  
그런데 국내에서는 Neovim 관련 설정 자료들을 찾기 힘들어서 여기에 내가 구성한 내용들을 정리해 본다.

## 머릿말
기본적으로 Neovim 에디터는 터미널 환경에서도 동작하는 에디터이므로 사용하는 터미널 환경에 영향을 받아서, VS Code와 같이 독자적으로 동작하는 에디터와 달리 색깔, 핫키, 플러그인 등의 설정이 아주 까다로운 편이다.  
나는 최대한 터미널 환경에서 Neovim을 주력으로 사용하는 VS Code와 유사한 환경을 갖추도록 Neovim을 설정하는 것을 목표로 하였고, 어느 정도 VS Code 비슷하게 환경을 구축하여 사용 중이다.
> 물론 VS Code와 어느 정도 비슷하게 구성하였다는 것이지, VS Code 만큼의 완성도가 있거나 편리하지는 않다.

> 참고로 [[Awesome Neovim]](https://github.com/rockerBOO/awesome-neovim) 페이지에서 유용한 Neovim 플러그인을 찾을 수 있다.

먼저 Neovim의 기본적인 환경 구축을 위하여 [LazyVim](https://github.com/LazyVim/LazyVim)을 이용하였고, 나는 여기에 VS Code와 유사하도록 추가 설정하였다.  
이 글에서는 Neovim이나 각 플러그인의 사용법, LSP 등을 다루기에는 내용이 너무 방대해지므로, 내가 추가로 설정한 사항에 대해서만 정리하겠다.  

## 사전 체크
[LazyVim](https://github.com/LazyVim/LazyVim)은 [lazy.nvim](https://github.com/folke/lazy.nvim) 플러그인 매니저를 이용하여 Neovim을 IDE 환경으로 쉽게 구축할 수 있게 해준다.  
LazyVim은 Nerd 폰트를 사용하므로 시스템에 사용하려는 폰트의 Nerd 버전을 설치하고, 아래 예와 같이 확인시 정상적으로 아이콘이 표시되는지 확인한다.
(참고로 나는 터미널은 주로 [[Windows Terminal]](https://github.com/microsoft/terminal)을 사용하고, 폰트는 주로 [[D2Coding Nerd Font]](https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/D2Coding)를 사용하고 있다)  
아래 데모와 같이 아이콘과 true color가 제대로 표시되면 터미널 환경이 정상적으로 된 것이다.  
<head>
  <link rel="stylesheet" type="text/css" href="/assets/css/asciinema-player.css"/>
</head>
<div id="terminal_test"></div>
<script src="/assets/js/asciinema-player.js"></script>
<script>AsciinemaPlayer.create('/assets/cast/terminal_test.cast', document.getElementById('terminal_test'), {cols: 92, rows: 31, poster: 'npt:0:7', fit: false, terminalFontSize: "16px", terminalLineHeight: 1.1});</script>

<br>

그런데, LazyVim은 fd, fzf, ripgrep 등의 툴을 적극적으로 사용하므로, 아래와 같은 패키지들도 설치하는 것이 좋다.
```sh
$ sudo apt install build-essential fd-find fzf ripgrep
```
또한, LazyVim은 Git 관련 기능시 [Lazygit](https://github.com/jesseduffield/lazygit)을 이용하므로 이것도 설치하는 것이 좋겠다. (사실 나는 이미 콘솔에서 작업시 이런 툴들을 애용하고 있었다)

## 내 LazyVim 환경 설치
만약에 기존 Neovim 환경을 모두 제거하고 새로 환경을 구성하려면 아래와 같이 기존 관련 디렉토리를 삭제하면 된다.
```sh
$ rm -rf ~/.config/nvim/
$ rm -rf ~/.local/share/nvim/
$ rm -rf ~/.local/state/nvim/
$ rm -rf ~/.cache/nvim/
```

내 전체 LazyVim 설정은 [https://github.com/yrpark99/nvim.git](https://github.com/yrpark99/nvim.git) 페이지에서 확인할 수 있다.  
Neovim을 설치한 후에 아래와 같이 실행하면 **~/.config/nvim/** 경로에 설정 파일들이 받아진다.
```sh
$ git clone https://github.com/yrpark99/nvim.git ~/.config/nvim
```

이후 Neovim을 실행하면 자동으로 플러그인들이 설치되고, 이후에 본인의 용도에 따라서 언어별로 필요한 TreeSitter나 LSP를 설치하면 된다.  
편의상 이 글에서 lua 파일의 경로는 **~/.config/nvim/** 경로를 기준으로 설명하겠다.

플러그인들이 모두 설치되고 나면, 이제 Neovim이 아래 데모 예와 같이 동작한다.  
<head>
  <link rel="stylesheet" type="text/css" href="/assets/css/asciinema-player.css"/>
</head>
<div id="nvim_demo"></div>
<script src="/assets/js/asciinema-player.js"></script>
<script>AsciinemaPlayer.create('/assets/cast/nvim_demo.cast', document.getElementById('nvim_demo'), {poster: 'npt:0:23', fit: false, terminalFontSize: "16px", terminalLineHeight: 1});</script>

## 인코딩 등 기본 설정
UTF-8과 EUC-KR 인코딩을 자동으로 디텍트하고, 상대적인 줄 번호를 사용하지 않고 (즉, 절대 줄 번호로 표시), 터미널 full 색상을 사용하도록 **init.lua** 파일에서 아래와 같이 설정하였다.
```lua
-- Set Vim options
vim.opt.fileencodings = "utf-8, euc-kr"
vim.opt.relativenumber = false
vim.opt.termguicolors = true
```

## 칼라 설정
칼라 테마로 VS Code 테마를 사용하고, 현재 줄 번호 색깔과 플로팅 팝업 배경색을 **init.lua** 파일에서 아래와 같이 설정하였다.
```lua
-- Set color scheme
vim.cmd("colorscheme vscode")

-- Set cursor line number foreground color
vim.cmd("highlight CursorLineNr guifg=#ff8c00")

-- Set float popup background color
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#2c2c2c" })
```

## RGB 색깔 표시
CSS 파일이나 lua 파일 등에서 **#RRGGBB** 형태의 숫자나 색상 문자열인 경우에 해당 색깔을 표시하기 위하여 [nvim-colorizer.lua](https://github.com/catgoose/nvim-colorizer.lua) 플러그인을 이용하여 **lua/plugins/colorizer.lua** 파일을 아래와 같이 작성하였다.
```lua
return {
  "catgoose/nvim-colorizer.lua",
  config = function()
    vim.api.nvim_create_autocmd("BufReadPost", {
      pattern = "*",
      callback = function()
        require("colorizer").attach_to_buffer(0)
      end,
    })
  end,
}
```

## 파일 탭 관련
파일 탭(Neovim에서는 bufferline이라고 함) 설정을 **lua/config/lazy.lua** 파일에 아래와 같이 하였다.  
(파일 탭은 항상 보이도록 하고, close 버튼을 표시하고, 색상 설정하였고, 마우스 우클릭시 해당 파일을 수직 나누도록 하였다)
```lua
-- bufferline plugin configuration
require("bufferline").setup({
  options = {
    always_show_bufferline = true,
    diagnostics = nil,
    hover = {
      enabled = true,
      reveal = { "close" },
    },
    max_name_length = 33,
    right_mouse_command = "vertical sbuffer %d",
  },
  highlights = {
    background = {
      fg = "#eeeeee",
      bg = "#333333",
    },
    buffer_selected = {
      fg = "#eeeeee",
      bg = "#443377",
      italic = false,
    },
    close_button = {
      fg = "#ffff00",
    },
    close_button_selected = {
      fg = "#ff0000",
    },
  },
})
```

## TODO 관련
[Todo Comments](https://github.com/folke/todo-comments.nvim) 설정을 **lua/config/lazy.lua** 파일에 **FIX**, **FIXME**, **WARN**, **WARNING**, **TODO**, **NOTE**, **INFO** 문구에 대한 아이콘과 색생을 지정하였다.
```lua
-- todo-comments plugin configuration
require("todo-comments").setup({
  signs = true,
  keywords = {
    FIX = { icon = " ", color = "error", alt = { "FIXME" } },
    WARN = { icon = " ", color = "warning", alt = { "WARNING" } },
    TODO = { icon = " ", color = "info" },
    NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
  },
  merge_keywords = false,
  highlight = {
    keyword = "bg",
    after = "",
    pattern = [[\s(KEYWORDS)\s]],
  },
  search = {
    pattern = [[\b(KEYWORDS)\b]],
  },
})
```

또, **lua/config/keymaps.lua** 파일에 아래 내용을 추가하여 <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>t</kbd> 키를 누르면 전체 목록이 표시되고 이동도 할 수 있다.
```lua
-- Todo-comments
vim.keymap.set({ "n", "i", "v" }, "<C-A-t>", "<esc><cmd>TodoLocList<CR>", { noremap = true, silent = true })
```

## Bootmark 플러그인
VS Code에서 내가 사용하는 북마크 익스텐션과 유사한 [navimark.nvim](https://github.com/zongben/navimark.nvim) 플러그인을 사용해 보았는데, 일부 내가 원하는 것과 다르게 동작하는 부분이 있어서 이것을 fork하여 [[내 navimark.nvim]](https://github.com/yrpark99/navimark.nvim) 플러그인을 만들어서 사용하였다. 아래 **lua/plugins/bookmark.lua** 파일을 참조한다.  
참고로 핫키는 아래와 같이 지정하였다.
- <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>k</kbd>: 북마크 토글
- <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>l</kbd>: 다음 북마크로 이동
- <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>p</kbd>: 전체 북마크 목록 표시 및 이동
```lua
return {
  "yrpark99/navimark.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("navimark").setup({
      keymap = {
        base = {
          mark_toggle = "<C-A-k>",
          goto_next_mark = "<C-A-l>",
          open_mark_picker = "<C-A-p>",
        },
      },
      sign = {
        text = "",
        color = "#0c61f4",
      },
      persist = true,
    })
  end,
}
```

추가로 북마크 표시 색상을 파란색 계통으로 설정하도록 **init.lua** 파일에서 아래와 같이 설정하였다.
```lua
-- Set bookmark color
vim.api.nvim_set_hl(0, "navimark_hl", { fg = "#0c61f4" })
```

> 참고로 내가 구현한 북마크 플러그인은 북마크 저장 파일을 global하게 쓰는 대신에, 프로젝트 소스 base 경로에 `.navimark.json` 파일로 저장하게 하여, 북마크 순회시 다른 프로젝트의 북마크로 이동하지 않게 하였다.

## 비주얼 영역 관련
VS Code에서는 코드 영역 선택시 tab/space 문자가 표시되는데, 이와 유사하게 비주얼 영역 선택시 tab/space 문자가 표시되도록 **lua/plugins/visual_whitespace.lua** 파일을 아래와 같이 작성하였다.
```lua
return {
  "mcauley-penney/visual-whitespace.nvim",
  config = true,
  opts = {
    highlight = { link = "Visual" },
    space_char = "·",
    tab_char = "→",
    nl_char = "",
    cr_char = "",
    enabled = true,
    excluded = {
      filetypes = {},
      buftypes = {},
    },
  },
}
```

또, tab/space 문자의 색상을 **init.lua** 파일에서 아래와 같이 연한 회색으로 조정하였다.
```lua
-- Set visual non text foreground color (for tab/space charachter color in visual area)
vim.api.nvim_set_hl(0, "VisualNonText", {
  bg = vim.api.nvim_get_hl(0, { name = "Visual" }).bg,
  fg = "#585858",
})
```

## 클립보드 관련
자유로운 클립보드 사용을 위하여 (Linux <-> Windows 간 포함) **lua/config/options.lua** 파일에서 아래와 같이 설정하였다.
```lua
vim.opt.clipboard = "unnamedplus"
```
Windows Terminal로 WSL Linux 배포판에 접속하는 경우에는 아래와 같이 **xsel**이나 **xclip** 툴을 설치하면 된다.
```sh
$ sudo apt install xsel
```
그런데 Windows Terminal로 SSH로 Linux 서버에 접속하는 경우에는 이 방법이 되지 않고 (단, X GUI 환경을 이용하는 경우에는 됨), [Lemonade](https://github.com/lemonade-command/lemonade) 툴을 이용하면 된다. 이 툴은 서버/클라이언트 구조로 TCP 통신을 하는데, Windows에서는 서버를 실행하고 Linux에서는 클라이언트가 실행된다. (여기서는 상세 방법은 생략한다)

## Tab, space 디텍트
Neovim은 v0.9부터 빌트인으로 [EditorConfig](https://editorconfig.org/)를 지원하므로 이것을 사용하면 좋은데, 해당 프로젝트에서 이것을 사용하지 않는 경우에는 소스의 tab/space를 자동으로 디텍트 하는 것이 좋다.  
나는 일단 **lua/config/options.lua** 파일에서 아래와 같이 디폴트 tab, space 설정을 하였다. (S/W tab 즉, space를 디폴트로 함)
```lua
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true
```
그런데 VS Code에서는 소스에서 H/W tab을 사용하는지 S/W tab(즉 space)을 사용하는지, space인 경우에는 간격이 얼마인지가 자동으로 디텍트되어서 표시되지만, Neovim에서는 이를 지원하지 않고 있다. 이 기능을 구현하기 위하여 아래와 같이 **lua/plugins/indent_automatic.lua** 파일에서 [indent-o-matic](https://github.com/Darazaki/indent-o-matic) 플러그인을 사용하였다.
```lua
return {
  "Darazaki/indent-o-matic",
}
```
이후 이 정보를 상태바에 출력하기 위하여 **lua/plugins/lualine.lua** 파일에서 display_indent_info() 함수를 구현하였다.

## 상태바 관련
상태바를 내 VS Code와 유사하게 표시하게 위하여 **lua/plugins/lualine.lua** 파일을 아래와 같이 작성하였다.  
즉, 기본적으로 현재 파일의 상대 경로, 파일 인코딩, 라인 엔디언, 파일 타입, tab/space 정보, 현재 줄 위치 퍼센트, 커서 라인과 컬럼 위치를 표시하고, 비주얼 영역이 선택되면 선택된 비주얼 영역의 줄 수와 글자 수를 표시한다.
```lua
return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  opts = {
    options = {
      icons_enabled = true,
      theme = {
        normal = {
          a = { bg = "#98c379", fg = "#000000" },
          b = { bg = "#333333", fg = "#e8e8e8" },
          c = { bg = "#333333", fg = "#d75bea" },
          x = { bg = "#333333", fg = "#ffb27d" },
          y = { bg = "#333333", fg = "#fff200" },
          z = { bg = "#333333", fg = "#60c5f1" },
        },
        insert = {
          a = { bg = "#61afef", fg = "#000000" },
          z = { bg = "#333333", fg = "#60c5f1" },
        },
        visual = {
          a = { bg = "#c678dd", fg = "#000000" },
          z = { bg = "#333333", fg = "#60c5f1" },
        },
        replace = {
          a = { bg = "#e06c75", fg = "#000000" },
          z = { bg = "#333333", fg = "#60c5f1" },
        },
        command = {
          a = { bg = "#e5c07b", fg = "#000000" },
          z = { bg = "#333333", fg = "#60c5f1" },
        },
      },
      component_separators = { left = "", right = "" },
      section_separators = { left = "", right = "" },
      disabled_filetypes = {
        statusline = {},
        winbar = {},
      },
      ignore_focus = {},
      always_divide_middle = true,
      globalstatus = true,
      refresh = {
        statusline = 200,
        tabline = 1000,
        winbar = 1000,
      },
    },
    sections = {
      lualine_a = { "mode" },
      lualine_b = { { "filename", path = 1 } },
      lualine_c = { visual_selection_count },
      lualine_x = { "encoding", "fileformat", "filetype", display_indent_info },
      lualine_y = { "progress" },
      lualine_z = { cursor_position },
    },
  },
}
```
> 실제 visual_selection_count(), display_indent_info(), cursor_position() 함수는 길이상 여기서는 생략하였다.

## 직전에 닫은 파일 다시 열기
의외로 Neovim에서 이 기능을 찾을 수 없어서 아래와 같이 **lua/reopen_latest.lua** 파일에 직접 구현하였다. (핫키는 키맵에서 <kbd>Shift</kbd>+<kbd>t</kbd> 키로 설정함)
```lua
local M = {}

M.last_closed = nil

vim.api.nvim_create_autocmd("BufDelete", {
  callback = function(args)
    M.last_closed = vim.api.nvim_buf_get_name(args.buf)
  end
})

function M.reopen_latest()
  if M.last_closed and M.last_closed ~= "" then
    vim.cmd("tabnew " .. vim.fn.fnameescape(M.last_closed))
  else
    print("No recently closed buffer found!")
  end
end

vim.api.nvim_create_user_command("ReopenLatest", M.reopen_latest, {})

return M
```

## Git 차이점 관련
Git 차이점으로 이동하거나, 차이점을 보거나, 변경 사항을 reset(즉, 원래 코드로 되돌림) 시키는 핫키를 **lua/plugins/gitsigns.lua** 파일에 아래와 같이 작성하였다.
```lua
return {
  "lewis6991/gitsigns.nvim",
  config = function()
    require("gitsigns").setup()
    vim.keymap.set("n", "<leader>gn", "<cmd>Gitsigns next_hunk<CR>", { desc = "Move to next hunk" })
    vim.keymap.set("n", "<leader>gp", "<cmd>Gitsigns prev_hunk<CR>", { desc = "Move to prev hunk" })
    vim.keymap.set("n", "<leader>gd", "<cmd>Gitsigns preview_hunk<CR>", { desc = "Difference hunk" })
    vim.keymap.set("n", "<leader>gr", "<cmd>Gitsigns reset_hunk<CR>", { desc = "Reset hunk" })
    vim.keymap.set("n", "<F5>", "<cmd>Gitsigns next_hunk<CR>", {})
    vim.keymap.set("n", "<F17>", "<cmd>Gitsigns prev_hunk<CR>", {}) -- Shift+F5
    vim.keymap.set("n", "<F6>", "<cmd>Gitsigns preview_hunk<CR>", {})
    vim.keymap.set("n", "<F7>", "<cmd>Gitsigns reset_hunk<CR>", {})
  end,
}
```
즉, 아래와 같이 핫키를 설정하였다.
- 다음 변경점으로 이동: <kbd>F5</kbd>
- 이전 변경점으로 이동: <kbd>Shift</kbd>+<kbd>F5</kbd>
- 현재 변경점 차이점 보기: <kbd>F6</kbd>
- 현재 변경점을 되돌리기: <kbd>F7</kbd>

## 멀티 커서 관련
Neovim 자체적으로는 멀티 커서를 지원하지 않고 있어서 [multiple-cursors.nvim](https://github.com/brenton-leighton/multiple-cursors.nvim) 플러그인을 이용하였고, 핫키도 지정하도록 **lua/plugins/multicursor.lua** 파일에 아래와 같이 작성하였다.  
(핫키는 아래에서 보듯이 <kbd>Ctrl</kbd>+<kbd>up</kbd>, <kbd>Ctrl</kbd>+<kbd>down</kbd>, <kbd>Ctrl</kbd>+<kbd>d</kbd> 키로 하였음)
```lua
return {
  "brenton-leighton/multiple-cursors.nvim",
  version = "*",
  opts = {},
  keys = {
    {"<C-j>", "<cmd>MultipleCursorsAddDown<CR>", mode = {"n", "x"}, desc = "Add cursor and move down"},
    {"<C-k>", "<cmd>MultipleCursorsAddUp<CR>", mode = {"n", "x"}, desc = "Add cursor and move up"},
    {"<C-Up>", "<cmd>MultipleCursorsAddUp<CR>", mode = {"n", "i", "x"}, desc = "Add cursor and move up"},
    {"<C-Down>", "<cmd>MultipleCursorsAddDown<CR>", mode = {"n", "i", "x"}, desc = "Add cursor and move down"},
    {"<C-d>", "<cmd>MultipleCursorsAddJumpNextMatch<CR>", mode = {"n", "x"}, desc = "Add cursor and jump to next cword"},
  },
}
```

## 심볼 outline 관련
이미 <kbd>leader</kbd><kbd>s</kbd><kbd>s</kbd> 키를 눌러서 **Lsp Symbols**를 통해 심볼 목록과 내용을 미리보면서 순회할 수 있긴 하지만, 언어에 따라서 제대로 표시되지 않는 것들도 있어서, 아래와 같이 **lua/plugins/outline.lua** 파일을 작성하여 [aerial.nvim](https://github.com/stevearc/aerial.nvim) 플러그인을 이용하고 있다.
```lua
return {
  "stevearc/aerial.nvim",
  backends = { "lsp" },
  opts = {
    filter_kind = {
      "Class",
      "Constructor",
      "Function",
      "Interface",
      "Method",
      "Module",
    },
    autojump = true,
  },
  keys = {
    { "<leader>o", "<cmd>AerialToggle!<CR>", desc = "Toggle Outline" },
  },
}
```

## 키맵 설정
플러그인에서 자체적으로 설정을 지원해 주는 키 이외에는 **lua/config/keymaps.lua** 파일에서 설정할 수 있다. 아래는 내가 설정한 키맵 예제들이다. (<kbd>leader</kbd> 키는 디폴트대로 <kbd>space</kbd> 키를 사용하고 있음)
```lua
-- Exit(quit all)
vim.keymap.set({ "n", "i", "v" }, "<C-A-q>", "<esc><cmd>quitall<CR>", { noremap = true, silent = true })

-- Shift-Del
vim.keymap.set({ "n", "v", "i" }, "<S-Del>", function()
  local mode = vim.api.nvim_get_mode().mode
  if mode == "i" then
    return "<esc>ddi"
  else
    return "dd"
  end
end, { expr = true, desc = "Delete current line" })

-- Alt-Del
vim.keymap.set({ "n", "v", "i" }, "<A-Del>", function()
  local mode = vim.api.nvim_get_mode().mode
  if mode == "i" then
    return "<C-o>D"
  else
    return "D"
  end
end, { expr = true, desc = "Delete from cursor to end of line" })

-- Move lines
map("n", "<A-Down>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
map("n", "<A-Up>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
map("i", "<A-Down>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<A-Up>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "<A-Down>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
map("v", "<A-Up>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })

-- Line/block comment (Ctrl+\)
vim.keymap.set("n", "<C-\\>", "gcc", { remap = true })
vim.keymap.set("v", "<C-\\>", "gc", { remap = true })

-- Tab indent
vim.keymap.set("v", "<Tab>", ">gv", { noremap = true, silent = true })
vim.keymap.set("v", "<S-Tab>", "<gv", { noremap = true, silent = true })

-- Reopen latest file tab
vim.keymap.set("n", "<S-t>", "<cmd>ReopenLatest<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>br", "<cmd>ReopenLatest<CR>", { noremap = true, silent = true, desc = "Reopen latest closed tab" })

-- Jump to last modified position in current file
vim.keymap.set("n", "<C-q>", "`.", { noremap = true, silent = true, desc = "Jump to last modified position" })
vim.keymap.set("n", "<leader>bq", "`.", { noremap = true, silent = true, desc = "Jump to last modified position" })

-- File tabs
vim.keymap.set({ "n", "i", "v" }, "<F28>", "<esc><cmd>bdelete<CR>", { noremap = true, silent = true }) -- Ctrl+F4
vim.keymap.set({ "n", "i", "v" }, "<A-Right>", "<esc><cmd>BufferLineMoveNext<CR>", { noremap = true, silent = true })
vim.keymap.set({ "n", "i", "v" }, "<A-Left>", "<esc><cmd>BufferLineMovePrev<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>b>", "<cmd>BufferLineMoveNext<CR>", { noremap = true, silent = true, desc = "Move current tab to next" })
vim.keymap.set("n", "<leader>b<", "<cmd>BufferLineMovePrev<CR>", { noremap = true, silent = true, desc = "Move current tab to previous" })

-- Copy current file name
vim.keymap.set("n", "<leader>fx", function()
  local path = vim.fn.expand("%:o")
  local name = vim.fs.basename(path)
  vim.fn.setreg("+", name)
  print("Copied: " .. name)
end, { desc = "Copy current file name" })

-- Copy current file absolute path
vim.keymap.set("n", "<leader>fy", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  print("Copied: " .. path)
end, { desc = "Copy current file absolute path" })

-- Copy current file relative path
vim.keymap.set("n", "<leader>fz", function()
  local path = vim.fn.expand("%:.")
  vim.fn.setreg("+", path)
  print("Copied: " .. path)
end, { desc = "Copy current file relative path" })
```

위에서 다음 키맵들을 확인할 수 있다.
- Neovim 종료하기: <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>q</kbd>
- 한 줄 또는 여러 비주얼 줄을 옮기기: <kbd>Alt</kbd>+<kbd>up</kbd>, <kbd>Alt</kbd>+<kbd>down</kbd>
- 한 줄 또는 여러 비주얼 줄을 주석 토글하기: <kbd>Ctrl</kbd>+<kbd>\</kbd>
- 비주얼 영역을 tab indent, unindent 하기: <kbd>Tab</kbd>, <kbd>Shift</kbd>+<kbd>Tab</kbd>
- 가장 마지막에 닫은 파일을 다시 열기: <kbd>Shift</kbd>+<kbd>t</kbd>
- 현재 파일에서 가장 마지막으로 수정한 위치로 이동하기: <kbd>Ctrl</kbd>+<kbd>q</kbd>
- 파일 탭에서 현재 파일 탭을 이전/이후 위치로 옮기기: <kbd>Alt</kbd>+<kbd>left</kbd>, <kbd>Alt</kbd>+<kbd>right</kbd>
- 현재 파일 이름 복사: <kbd>leader</kbd><kbd>f</kbd><kbd>x</kbd>
- 현재 파일 절대 경로 복사: <kbd>leader</kbd><kbd>f</kbd><kbd>y</kbd>
- 현재 파일 상대 경로 복사: <kbd>leader</kbd><kbd>f</kbd><kbd>z</kbd>

## LSP 관련
Neovim은 LSP(Lanaugage Server Protocol)를 지원하는데, LazyVim은 LSP 플러그인을 관리해주는 [mason.nvim](https://github.com/williamboman/mason.nvim) 플러그인을 사용하므로, 사용자는 mason을 통해 사용하려는 LSP server 프로그램을 쉽게 설치할 수 있다.  
사용법은 `MasonInstall` **{설치하려는_LSP_server}** 명령을 실행하면 되는데 (또는 `LspInstall` 명령으로 설치할 수도 있음), LSP server는 예를 들어 아래와 같은 것들이 있다. (특정 언어에 LSP server 프로그램이 여러 개 있으면 그 중에 원하는 것을 선택하면 됨)
- `Bash`: bash-language-server
- `C/C++`: clangd
- `CSS`: css-lsp
- `Dockerfile`: dockerfile-language-server
- `Go`: gopls
- `Java`: jdtls
- `JavaScript` / `TypeScript`: typescript-language-server
- `JSON`: json-lsp
- `Kotlin`: kotlin-language-server
- `Python`: pyright
- `Rust`: rust-analyzer

LSP server 프로그램 설치시 사전에 설치가 필요한 패키지가 있는 경우가 많으므로 실패하는 경우에는 에러 로그를 확인하여 조치하면 된다.  
> 예를 들어 pyright 서버 프로그램은 [Node.js](https://nodejs.org/ko)를 이용하므로 아래 예와 같이 최신 Node.js LTS 버전을 설치해야 한다.
> ```sh
> $ curl -sL install-node.now.sh/lts | sudo bash
> ```

그런데 당연하겠지만 해당 언어의 SDK도 설치되어 있어야 LSP가 정상 동작한다. 예를 들어 Java 소스라면 JDK가 설치되어 있어야 한다.  
또, C/C++ 소스인 경우에는 **clangd** 툴이 사용하는 **compile_commands.json** 파일이 있어야 한다.  
만약에 LSP가 정상 동작하지 않는다면 `LspInfo` 명령으로 상태를 확인하고, `LspLog` 명령으로 LSP 서버 로그를 확인하면서 에러 내용을 대처하면 된다.  
<br>

그런데 LSP 디폴트 설정에 의해 함수의 inlay 힌트가 출력되는데, 나는 이것을 선호하지 않아서 **lua/plugins/lsp_config.lua** 파일에서 아래와 같이 이 feature를 disabled 시켰다.
```lua
return {
  "nvim-lspconfig",
  opts = {
    inlay_hints = { enabled = false },
  },
}
```

## Tree-sitter
LSP를 설치하면 어느 정도는 해당 소스가 신택스 하이라이팅되긴 하지만 조금 부족해 보인다. 이 경우에는 [Tree-sitter](https://tree-sitter.github.io/tree-sitter/)를 이용하면 해당 언어의 신택스 하이라이팅을 향상시킬 수 있다.  
Neovim에서 Tree-sitter 언어 설치는 `:TSInstall` 후에 아래 예와 같이 타겟 언어를 지정하면 된다.
- `C`: c
- `CPP`: cpp
- `Go`: go
- `Java`: java
- `JavaScript`: javascript
- `Kotlin`: kotlin
- `Make`: make
- `Python`: python
- `Rust`: rust
- `TypeScript`: typescript

참고로 Tree-sitter 언어별 설치 여부는 `:TSInstallInfo` 명령으로 확인할 수 있다.

## 맺음말
VS Code에서는 필요한 대부분의 기능이 이미 내장되어 있거나 쉽게 할 수 있고 완성도 또한 아주 좋은데 반해, Neovim은 그렇지가 못하고 대부분을 플러그인에 의존하고 있는데다가, 플러그인을 찾고 설정하기가 어려울 뿐만 아니라 완성도 또한 좋지는 못하다.  
그럼에도 불구하고 터미널 환경에서 Neovim을 사용하는 경우에 최대한 VS Code와 유사하게 사용하기 위하여 환경을 구성해 보았다.  
다만 환경을 구성하면서 직접 Neovim 플러그인도 작성해 보았는데 **lua**라는 스크립트 언어를 이용하므로, VS Code의 익스텐션에 비하면 패키징을 안 해도 되고, 마켓 플레이스에 올리지 않아도 되어서, 편리하게 작성 및 업데이트할 수 있었다.  
다만 VS Code는 익스텐션을 찾기도 편하고 설치 및 설정이 편리한 데 비하여, Neovim의 경우에는 플러그인 자체는 많지만 찾기가 어려웠고, 설치 및 설정이 까다로웠다.  
터미널 환경에서 Neovim을 사용하는 개발자들이 환경 설정을 할 때에 도움이 될 것 같아서 시간을 내어 정리해 보았다.
