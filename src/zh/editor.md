# 编辑器

> 子曰：“工欲善其事，必先利其器。居是邦也，事其大夫之贤者，友其士之仁者。”  
> ———《论语·卫灵公》

- [1. Visual Studio Code](#1-visual-studio-code)
  - [1.1. 简介](#11-简介)
  - [1.2. 快捷键](#12-快捷键)

## 1. Visual Studio Code

虽然 tmm 里面有预装 code-server（web 网页服务器）的容器，但是本节将主要讲桌面版的 vscode。

~~二萌更喜欢桌面版的 vscode, 而不是网页版的。~~  
对于天萌用户，您之后可以用 `apt install code-no-sandbox` 来安装，它将包含两个启动图标。(现在还而没有打包啦)

> 除了 code-server 之外，目前比较流行的网页版 vscode 还有 2 个。
>
> 1. 官方的 [vscode.dev](https://vscode.dev)
> 2. github dev, 假设某仓库为 github.com/xx/yy, 将 com 修改为 dev：（github.dev/xx/yy）。

### 1.1. 简介

vscode 是由微软（Microsoft）主导开发的一款开源编辑器。

> Why is vscode？

有很多人都喜欢 **JetBrains** 家的 IDE(s), 还有 **vscode** 的老大哥 **Visual Studio**。  
在本节中，我们并不会讨论 vscode 相较于其它编辑器或集成开发环境的优劣。

正如《周易·系辞（上）》中所言：“仁者见之谓之仁，智者见之谓之智。”

对于相同问题，不同用户站在不同角度有不同的看法。  
您如果不喜欢 vscode 的话，那可以跳过本节的内容。  
对于二萌来说，使用 vscode 的主要原因是习惯了。

---

如果您对它感兴趣的话，那让我们带着愉快的心情，一起去了解 vscode 吧！

### 1.2. 快捷键

了解一款软件的快捷键，在某些方面能极大程度地提高您的效率。

以下表格是开发者根据 [官方文档](https://code.visualstudio.com/docs/getstarted/keybindings#_keyboard-shortcuts-reference) 整理出来的。  
网上有很多基于官方文档的表格，但是应该很少有人将 **windows** 、**linux** & **macos** 三者的 vscode 整合在一起并进行比较吧？

截止 2021-10-23，以下表格会比官方的 pdf 文档多一些内容，之后 vscode 可能会进行更新, 具体内容请以官方文档为主。

对于 **Linux** 和 **Windows** 中相同的快捷键，**Win** 处留空。  
对于冲突快捷键，或者是默认为空键位的地方，使用 🤔️。  
例如： ctrl+alt+方向键：（Move editor into next/previous group） 与 cinnamon 的切换工作区(switch work space) 快捷键冲突。

其实正确的做法，不是看这个表格。  
而是先按下 <kbd>ctrl</kbd> + K 组合键，再按下 <kbd>ctrl</kbd> + S, 最后进行搜索。  
不管怎么说，只要能帮到您，开发者就觉得很开心了。

---

<!-- <kbd>ctrl</kbd> -->

| Linux            | Win          | Mac     | **General**             | 一般操作       |
| ---------------- | ------------ | ------- | ----------------------- | -------------- |
| Ctrl+Shift+P, F1 |              | ⇧⌘P, F1 | Show Command Palette    | 显示命令选项板 |
| Ctrl+P           |              | ⌘P      | Quick Open, Go to File… | 快速打开       |
| Ctrl+Shift+N     |              | ⇧⌘N     | New window/instance     | 新窗口/实例    |
| Ctrl+W           | Ctrl+Shift+W | ⌘W      | Close window/instance   | 关闭窗口/实例  |
| Ctrl+,           |              | ⌘,      | User Settings           | 用户设置       |
| Ctrl+K Ctrl+S    |              | ⌘K ⌘S   | Keyboard Shortcuts      | 键盘快捷键     |

---

| Linux                               | Win         | Mac              | **Basic editing**                    | 基础编辑                                          |
| ----------------------------------- | ----------- | ---------------- | ------------------------------------ | ------------------------------------------------- |
| Ctrl+X                              |             | ⌘X               | Cut (if empty selection, cut line)   | 剪切（若为空白则剪切整行，若非空则剪切选中内容）  |
| Ctrl+C                              |             | ⌘C               | Copy (if empty selection, copy line) | 复制 （若为空白则复制整行，若非空则复制选中内容） |
| Ctrl+V                              |             | ⌘V               | Paste                                | 粘贴                                              |
| Ctrl+Z                              |             | ⌘Z               | Undo                                 | 撤销（回退到上一步）                              |
| Ctrl+Y, Ctrl+Shift+Z                |             | ⇧⌘Z              | Redo                                 | 重做/反撤销/恢复                                  |
| `Alt+ ↓` / `Alt+ ↑`                 |             | ⌥↓ / ⌥↑          | Move line down/up                    | 移动行（向下/上）                                 |
| `Shift+Alt+ ↓` / `Shift+Alt+ ↑`     |             | ⇧⌥↓ / ⇧⌥↑        | Copy line down/up                    | 复制行（向下/上）                                 |
| Ctrl+Shift+K                        |             | ⇧⌘K              | Delete line                          | 删除行                                            |
| `Ctrl+Enter` / `Ctrl+Shift+Enter`   |             | ⌘Enter / ⇧⌘Enter | Insert line below/above              | 插入行（下方/上方）                               |
| Ctrl+Shift+\                        |             | ⇧⌘\              | Jump to matching bracket             | 跳到匹配的括号内                                  |
| `Ctrl+]` / `Ctrl+[`                 |             | ⌘] / ⌘[          | Indent/outdent line                  | 缩进/缩出（取消缩进）行                           |
| Home / End                          |             | Home / End       | Go to beginning/end of line          | 转到行首/行尾                                     |
| `Ctrl+ Home` / `Ctrl+ End`          |             | ⌘↑ / ⌘↓          | Go to beginning/end of file          | 转到文件的开头/结尾处                             |
| `Ctrl+ ↑` / `Ctrl+ ↓`               |             | ⌃PgUp / ⌃PgDn    | Scroll line up/down                  | 滚动行（向上/下）                                 |
| `Alt+ PgUp` / `Alt+ PgDn`           |             | ⌘PgUp /⌘PgDn     | Scroll page up/down                  | 滚动页面（向上/下）                               |
| `Ctrl+Shift+ [` / `Ctrl+Shift+ ]`   |             | ⌥⌘[ / ⌥⌘]        | Fold/unfold region                   | 折叠/展开（解除折叠）区域（代码块）               |
| `Ctrl+K Ctrl+ [` / `Ctrl+K Ctrl+ ]` |             | ⌘K ⌘[ / ⌘K ⌘]    | Fold/unfold all subregions           | 折叠/展开所有子区域                               |
| `Ctrl+K Ctrl+0` / `Ctrl+K Ctrl+J`   |             | ⌘K ⌘0 / ⌘K ⌘J    | Fold/unfold all regions              | 折叠/展开所有区域                                 |
| Ctrl+K Ctrl+C                       |             | ⌘K ⌘C            | Add line comment                     | 添加行注释                                        |
| Ctrl+K Ctrl+U                       |             | ⌘K ⌘U            | Remove line comment                  | 删除行注释                                        |
| Ctrl+/                              |             | ⌘/               | Toggle line comment                  | 切换行注释(注释或取消注释)                        |
| Ctrl+Shift+A                        | Shift+Alt+A | ⇧⌥A              | Toggle block comment                 | 切换块注释                                        |
| Alt+Z                               |             | ⌥Z               | Toggle word wrap                     | 切换自动换行                                      |

---

| Linux                           | Win                                            | Mac             | **Multi-cursor and selection**              | 多光标与选择（主要：列块编辑）                                         |
| ------------------------------- | ---------------------------------------------- | --------------- | ------------------------------------------- | ---------------------------------------------------------------------- |
| Alt+Click                       |                                                | ⌥ + click       | Insert cursor                               | 插入光标                                                               |
| Shift+Alt+↑                     | Ctrl+Alt+↑                                     | ⌥⌘↑             | Insert cursor above                         | 在上方插入光标                                                         |
| Shift+Alt+↓                     | Ctrl+Alt+↓                                     | ⌥⌘↓             | Insert cursor below                         | 在下方插入光标                                                         |
| Ctrl+U                          |                                                | ⌘U              | Undo last cursor operation                  | 撤销上一次光标操作                                                     |
| Shift+Alt+I                     |                                                | ⇧⌥I             | Insert cursor at end of each line selected  | 在选中行的末尾插入光标                                                 |
| Ctrl+L                          |                                                | ⌘L              | Select current line                         | 选择当前行                                                             |
| Ctrl+Shift+L                    |                                                | ⇧⌘L             | Select all occurrences of current selection | 选择当前选中项的所有匹配项                                             |
| Ctrl+F2                         |                                                | ⌘F2             | Select all occurrences of current word      | 选择当前词的所有匹配项                                                 |
| `Shift+Alt+ →` / `Shift+Alt+ ←` |                                                | ⌃⇧⌘→ / ←        | Expand / shrink selection                   | 扩大/缩小选择                                                          |
| Shift+Alt + drag mouse          |                                                | ⇧⌥ + drag mouse | Column (box) selection                      | 列块选择（先按住 shift+alt，再按住鼠标左键，最后拖拽鼠标选中指定列块） |
| 🤔️                             | `Ctrl+Shift+Alt+ ↑` / `Ctrl+Shift+Alt+ ↓`      | ⇧⌥⌘↑ / ↓        | Column (box) selection up/down              | 列块选择（向上/向下）                                                  |
| 🤔️                             | `Ctrl+Shift+Alt+ ←` / `Ctrl+Shift+Alt+ →`      | ⇧⌥⌘← / →        | Column (box) selection left/right           | 列块选择（左/右）                                                      |
| 🤔️                             | `Ctrl+Shift+Alt+ PgUp`/ `Ctrl+Shift+Alt+ PgDn` | ⇧⌥⌘PgUp / PgDn  | Column (box) selection page up/down         | 列块选择（页面 上/下 移）                                              |
| Ctrl+A                          |                                                | ⌘A              | Select all                                  | 全选                                                                   |

---

| Linux                       | Win | Mac         | **Search and replace**                     | 搜索与替换                          |
| --------------------------- | --- | ----------- | ------------------------------------------ | ----------------------------------- |
| Ctrl+F                      |     | ⌘F          | Find                                       | 查找                                |
| Ctrl+H                      |     | ⌥⌘F         | Replace                                    | 替换                                |
| `F3` / `Shift+F3`           |     | ⌘G / ⇧⌘G    | Find next/previous                         | 查找下一个/上一个                   |
| Alt+Enter                   |     | ⌥Enter      | Select all occurrences of Find match       | 选择所有匹配项                      |
| Ctrl+D                      |     | ⌘D          | Add selection to next Find match           | 选择下一个匹配项                    |
| Ctrl+K Ctrl+D               |     | ⌘K ⌘D       | Move last selection to next Find match     | 跳过当前选择项                      |
| `Alt+C` / `Alt+R` / `Alt+W` |     | ⌥⌘C/⌥⌘R/⌥⌘W | Toggle case-sensitive / regex / whole word | 切换 区分大小写/正则表达式/全字匹配 |

---

| Linux              | Win         | Mac        | **Rich languages editing**  | 富文本编辑     |
| ------------------ | ----------- | ---------- | --------------------------- | -------------- |
| Ctrl+Space, Ctrl+I |             | ⌃Space, ⌘I | Trigger suggestion          | 触发建议       |
| Ctrl+Shift+Space   |             | ⇧⌘Space    | Trigger parameter hints     | 触发参数提示   |
| Ctrl+Shift+I       | Shift+Alt+F | ⇧⌥F        | Format document             | 格式化文档     |
| Ctrl+K Ctrl+F      |             | ⌘K ⌘F      | Format selection            | 格式化所选部分 |
| F12                |             | F12        | Go to Definition            | 转到定义       |
| Ctrl+Shift+F10     | Alt+F12     | ⌥F12       | Peek Definition             | 速览定义       |
| Ctrl+K F12         |             | ⌘K F12     | Open Definition to the side | 在侧边显示定义 |
| Ctrl+.             |             | ⌘.         | Quick Fix                   | 快速修复       |
| Shift+F12          |             | ⇧F12       | Show References             | 显示引用       |
| F2                 |             | F2         | Rename Symbol               | 重命名符号     |
| Ctrl+K Ctrl+X      |             | ⌘K ⌘X      | Trim trailing whitespace    | 裁剪尾随空格   |
| Ctrl+K M           |             | ⌘K M       | Change file language        | 更改文件语言   |

---

| Linux                         | Win                              | Mac      | **Navigation**                       | 导航                                                                     |
| ----------------------------- | -------------------------------- | -------- | ------------------------------------ | ------------------------------------------------------------------------ |
| Ctrl+T                        |                                  | ⌘T       | Show all Symbols                     | 显示所有符号                                                             |
| Ctrl+G                        |                                  | ⌃G       | Go to Line...                        | 转到指定行...                                                            |
| Ctrl+P                        |                                  | ⌘P       | Go to File...                        | 转到文件...                                                              |
| Ctrl+Shift+O                  |                                  | ⇧⌘O      | Go to Symbol...                      | 转到符号...                                                              |
| Ctrl+Shift+M                  |                                  | ⇧⌘M      | Show Problems panel                  | 显示问题面板                                                             |
| `F8`/`Shift+F8`               |                                  | F8 / ⇧F8 | Go to next/previous error or warning | 转到下一个/上一个错误或警告                                              |
| Ctrl+Shift+Tab                |                                  | ⌃⇧Tab    | Navigate editor group history        | 在编辑器组（窗口）历史记录间进行导航（先按住 Ctrl+Shift，再按 tab 切换） |
| `Ctrl+Alt+ -`/`Ctrl+Shift+ -` | `Alt+ ←` / `Alt+ →`              | ⌃- / ⌃⇧- | Go back/forward                      | 后退/前进                                                                |
| Ctrl+M                        |                                  | ⌃⇧M      | Toggle Tab moves focus               | 切换 tab 键移动焦点（先按下 ⌃⇧M / Ctrl+M，再多按几次 tab 键 移动焦点 ）  |
| Ctrl+Shift+B                  |                                  | ⌃⇧B      | Run build task                       | 运行生成(构建)任务                                                       |
| 🤔️                           | <!-- 可以自定义为 ctrl+win+B --> |          | Run task                             | 运行任务，默认为空，您可以自定义为 ⌃⌘B                                   |

---

| Linux                                 | Win                           | Mac             | **Editor management**                 | 编辑器管理                                      |
| ------------------------------------- | ----------------------------- | --------------- | ------------------------------------- | ----------------------------------------------- |
| Ctrl+W                                | Ctrl+F4, Ctrl+W               | ⌘W              | Close editor（file/tag)               | 关闭编辑器（文件/标签页)                        |
| Ctrl+K F                              |                               | ⌘K F            | Close folder                          | 关闭文件夹                                      |
| Ctrl+\                                |                               | ⌘\              | Split editor                          | 拆分编辑器窗口                                  |
| `Ctrl+1` / `Ctrl+2` / `Ctrl+3`        |                               | ⌘1 / ⌘2 / ⌘3    | Focus into 1st, 2nd, 3rd editor group | 聚焦（切换）到第 1、第 2 或 第 3 个编辑组(窗口) |
| `Ctrl+K Ctrl+←` / `Ctrl+K Ctrl+→`     |                               | ⌘K ⌘← / ⌘K ⌘→   | Focus into previous/next editor group | 切换到上一个/下一个窗口                         |
| `Ctrl+Shift+PgUp` / `Ctrl+Shift+PgDn` |                               | ⌘K ⇧⌘← / ⌘K ⇧⌘→ | Move editor left/right                | 向左/右移动编辑器                               |
| `Ctrl+K ←` / `Ctrl+K →`               |                               | ⌘K ← / ⌘K →     | Move active editor group              | 向左/右移动正在使用（活动中）的窗口             |
| `Ctrl+PgUp` / `Ctrl+PgDn`             |                               | ⌥⌘←/⌥⌘→         | Focus into previous/next editor       | 切换到上一个/下一个编辑器                       |
| 🤔️                                   | `Ctrl+Alt+ →` / `Ctrl+Alt+ ←` | ⌃⌘→/⌃⌘←         | Move editor into next/previous group  | 将编辑器移动到下一组/上一组                     |
| Alt+F4                                |                               | ⌘Q              | Quit vscode                           | 退出 vscode                                     |

<!-- ctrl+alt+方向键 与 cinnamon 的切换工作区 快捷键冲突 -->

---

| Linux                         | Win      | Mac          | **File management**                     | 文件管理                                                            |
| ----------------------------- | -------- | ------------ | --------------------------------------- | ------------------------------------------------------------------- |
| Ctrl+N                        |          | ⌘N           | New file                                | 新文件                                                              |
| Ctrl+O                        |          | ⌘O           | Open file...                            | 打开文件...                                                         |
| Ctrl+S                        |          | ⌘S           | Save                                    | 保存                                                                |
| Ctrl+Shift+S                  |          | ⇧⌘S          | Save as...                              | 另存为...                                                           |
| 🤔️                           | Ctrl+K S | ⌥⌘S          | Save all                                | 全部保存                                                            |
| Ctrl+W                        | Ctrl+F4  | ⌘W           | Close                                   | 关闭                                                                |
| Ctrl+K Ctrl+W                 |          | ⌘K ⌘W        | Close all                               | 全部关闭                                                            |
| Ctrl+Shift+T                  |          | ⇧⌘T          | Reopen closed editor                    | 重新打开关闭的编辑器                                                |
| Ctrl+K Enter                  |          | ⌘K Enter     | Keep preview mode editor open           | 保持预览模式下的编辑器处于打开状态                                  |
| `Ctrl+Tab` / `Ctrl+Shift+Tab` |          | ⌃Tab / ⌃⇧Tab | Open next / previous                    | 打开下一个/上一个                                                   |
| Ctrl+K P                      |          | ⌘K P         | Copy path of active file                | 复制活动文件的路径                                                  |
| Ctrl+K R                      |          | ⌘K R         | Reveal active file in File Explorer     | 在文件管理器中显示活动文件                                          |
| Ctrl+K O                      |          | ⌘K O         | Show active file in new window/instance | 在新窗口/实例中显示活动文件                                         |
| Space, Enter                  |          | Space        | Open file in explorer                   | 先按下 ⇧⌘E 打开资源管理器,然后按方向键选择文件,最后按下空格打开文件 |
| Ctrl+Enter                    |          | ⌃Enter       | Open file to the side                   | 在侧边打开文件                                                      |
| F2                            |          | Enter        | Rename file in explorer                 | 在资源管理器中重命名文件                                            |
| Delete                        |          | ⌘Backspace   | delete file in explorer                 | 在资源管理器中删除文件                                              |

---

| Linux                 | Win          | Mac      | **Display**                                | 显示                                  |
| --------------------- | ------------ | -------- | ------------------------------------------ | ------------------------------------- |
| F11                   |              | ⌃⌘F      | Toggle full screen                         | 切换全屏                              |
| Shift+Alt+0           |              | ⌥⌘0      | Toggle editor layout (horizontal/vertical) | 切换编辑器布局（水平/垂直）           |
| `Ctrl+ =` / `Ctrl+ -` |              | ⌘= / ⇧⌘- | Zoom in/out                                | 放大/缩小                             |
| Ctrl+B                |              | ⌘B       | Toggle Sidebar visibility                  | 切换侧边栏的可见性（打开/关闭侧边栏） |
| Ctrl+Shift+E          |              | ⇧⌘E      | Show Explorer / Toggle focus               | 显示资源管理器/切换焦点               |
| Ctrl+Shift+F          |              | ⇧⌘F      | Show Search                                | 显示搜索                              |
| Ctrl+Shift+G          |              | ⌃⇧G      | Show Source Control                        | 显示源代码控制                        |
| Ctrl+Shift+D          |              | ⇧⌘D      | Show Debug                                 | 显示调试                              |
| Ctrl+Shift+X          |              | ⇧⌘X      | Show Extensions                            | 显示扩展                              |
| Ctrl+Shift+H          |              | ⇧⌘H      | Replace in files                           | 替换文件中的内容                      |
| Ctrl+Shift+J          |              | ⇧⌘J      | Toggle Search details                      | 切换搜索详情                          |
| Ctrl+K Ctrl+H         | Ctrl+Shift+U | ⇧⌘U      | Show Output panel                          | 显示输出面板                          |
| Ctrl+Shift+V          |              | ⇧⌘V      | Open Markdown preview                      | 打开 markdown 预览                    |
| Ctrl+K V              |              | ⌘K V     | Open Markdown preview to the side          | 在侧边打开 markdown 预览              |
| Ctrl+K Z              |              | ⌘K Z     | Zen Mode (Esc to exit)                     | 禅模式（按 Esc 退出）                 |
| Ctrl+Shift+C          |              | ⇧⌘C      | Open new command prompt/terminal           | 打开新的命令提示符/终端               |

---

| Linux               | Win | Mac        | **Debug**         | 调试                |
| ------------------- | --- | ---------- | ----------------- | ------------------- |
| F9                  |     | F9         | Toggle breakpoint | 切换断点            |
| F5                  |     | F5         | Start/Continue    | 开始/继续           |
| `F11` / `Shift+F11` |     | F11 / ⇧F11 | Step into/ out    | 单步调试：进入/跳出 |
| F10                 |     | F10        | Step over         | 单步跳过            |
| Shift+F5            |     | ⇧F5        | Stop              | 停止                |
| Ctrl+K Ctrl+I       |     | ⌘K ⌘I      | Show hover        | 显示悬停            |

---

| Linux                             | Win                               | Mac         | **Integrated terminal**               | 集成终端                               |
| --------------------------------- | --------------------------------- | ----------- | ------------------------------------- | -------------------------------------- |
| Ctrl+\`                           |                                   | ⌃\`         | Show integrated terminal              | 显示集成（内置）终端                   |
| Ctrl+Shift+\`                     |                                   | ⌃⇧\`        | Create new terminal                   | 创建新的终端                           |
| Ctrl+C                            |                                   |             | Interrupt foreground process          | 中断运行中的前台进程                   |
| Ctrl+Shift+C                      | Ctrl+C                            | ⌘C          | Copy selection                        | 先用鼠标选中，再按下“指定按键”进行复制 |
| Ctrl+Shift+V                      | Ctrl+V                            | ⌘V          | Paste into active terminal            | 粘贴                                   |
| `Ctrl+Shift+ ↑` / `Ctrl+Shift+ ↓` | `Ctrl+Alt+PgUp` / `Ctrl+Alt+PgDn` | ⌘↑ / ↓      | Scroll up/down                        | 向上/向下滚动（行）                    |
| `Shift+ PgUp` / `Shift+ PgDn`     |                                   | PgUp / PgDn | Scroll page up/down                   | 向上/向下滚动（页）                    |
| `Shift+ Home` / `Shift+ End`      | `Ctrl+ Home` / `Ctrl+ End`        | ⌘Home / End | Scroll to top/bottom                  | 滚动到顶部/底部                        |
| `Ctrl+Shift+5`                    |                                   | ⌘\\ , ⌃⇧5   | Split terminal                        | 拆分终端                               |
| `Ctrl+PgUp` / `Ctrl+PgDn`         |                                   | ⇧⌘[ / ]     | Focus previous/next terminal          | 聚焦（切换）上/下 一个 终端            |
| `Alt+ ↑` / `Alt+ ↓`               |                                   | ⌥⌘↑ / ↓     | Focus previous/next terminal in group | 在终端组中切换 上/下 一个终端          |
| `Ctrl+Shift+ ←` / `Ctrl+Shift+ →` | 🤔️                               | ⌃⌘← / →     | Resize terminal left/right            | 调整终端大小（左/右）                  |
| 🤔️                               |                                   | ⌃⌘↑ / ↓     | Resize terminal up/down               | 调整终端大小（上/下）                  |

---
