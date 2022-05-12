# 編輯器

> 子曰：“工欲善其事，必先利其器。居是邦也，事其大夫之賢者，友其士之仁者。”  
> ———《論語·衛靈公》

- [1. Visual Studio Code](#1-visual-studio-code)
  - [1.1. 簡介](#11-簡介)
  - [1.2. 快捷鍵](#12-快捷鍵)

## 1. Visual Studio Code

雖然 tmm 裡面有預裝 code-server（web 網頁伺服器）的容器，但是本節將主要講桌面版的 vscode。

~~二萌更喜歡桌面版的 vscode, 而不是網頁版的。~~  
對於天萌使用者，您之後可以用 `apt install code-no-sandbox` 來安裝，它將包含兩個啟動圖示。(現在還而沒有打包啦)

> 除了 code-server 之外，目前比較流行的網頁版 vscode 還有 2 個。
>
> 1. 官方的 [vscode.dev](https://vscode.dev)
> 2. github dev, 假設某倉庫為 github.com/xx/yy, 將 com 修改為 dev：（github.dev/xx/yy）。

### 1.1. 簡介

vscode 是由微軟（Microsoft）主導開發的一款開源編輯器。

> Why is vscode？

有很多人都喜歡 **JetBrains** 家的 IDE(s), 還有 **vscode** 的老大哥 **Visual Studio**。  
在本節中，我們並不會討論 vscode 相較於其它編輯器或整合開發環境的優劣。

正如《周易·繫辭（上）》中所言：“仁者見之謂之仁，智者見之謂之智。”

對於相同問題，不同使用者站在不同角度有不同的看法。  
您如果不喜歡 vscode 的話，那可以跳過本節的內容。  
對於二萌來說，使用 vscode 的主要原因是習慣了。

---

如果您對它感興趣的話，那讓我們帶著愉快的心情，一起去了解 vscode 吧！

### 1.2. 快捷鍵

瞭解一款軟體的快捷鍵，在某些方面能極大程度地提高您的效率。

以下表格是開發者根據 [官方文件](https://code.visualstudio.com/docs/getstarted/keybindings#_keyboard-shortcuts-reference) 整理出來的。  
網上有很多基於官方文件的表格，但是應該很少有人將 **windows** 、**linux** & **macos** 三者的 vscode 整合在一起並進行比較吧？

截止 2021-10-23，以下表格會比官方的 pdf 文件多一些內容，之後 vscode 可能會進行更新, 具體內容請以官方文件為主。

對於 **Linux** 和 **Windows** 中相同的快捷鍵，**Win** 處留空。  
對於衝突快捷鍵，或者是預設為空鍵位的地方，使用 🤔️。  
例如： ctrl+alt+方向鍵：（Move editor into next/previous group） 與 cinnamon 的切換工作區(switch work space) 快捷鍵衝突。

其實正確的做法，不是看這個表格。  
而是先按下 <kbd>ctrl</kbd> + K 組合鍵，再按下 <kbd>ctrl</kbd> + S, 最後進行搜尋。  
不管怎麼說，只要能幫到您，開發者就覺得很開心了。

---

<!-- <kbd>ctrl</kbd> -->

| Linux            | Win          | Mac     | **General**             | 一般操作       |
| ---------------- | ------------ | ------- | ----------------------- | -------------- |
| Ctrl+Shift+P, F1 |              | ⇧⌘P, F1 | Show Command Palette    | 顯示命令選項板 |
| Ctrl+P           |              | ⌘P      | Quick Open, Go to File… | 快速開啟       |
| Ctrl+Shift+N     |              | ⇧⌘N     | New window/instance     | 新視窗/例項    |
| Ctrl+W           | Ctrl+Shift+W | ⌘W      | Close window/instance   | 關閉視窗/例項  |
| Ctrl+,           |              | ⌘,      | User Settings           | 使用者設定       |
| Ctrl+K Ctrl+S    |              | ⌘K ⌘S   | Keyboard Shortcuts      | 鍵盤快捷鍵     |

---

| Linux                               | Win         | Mac              | **Basic editing**                    | 基礎編輯                                          |
| ----------------------------------- | ----------- | ---------------- | ------------------------------------ | ------------------------------------------------- |
| Ctrl+X                              |             | ⌘X               | Cut (if empty selection, cut line)   | 剪下（若為空白則剪下整行，若非空則剪下選中內容）  |
| Ctrl+C                              |             | ⌘C               | Copy (if empty selection, copy line) | 複製 （若為空白則複製整行，若非空則複製選中內容） |
| Ctrl+V                              |             | ⌘V               | Paste                                | 貼上                                              |
| Ctrl+Z                              |             | ⌘Z               | Undo                                 | 撤銷（回退到上一步）                              |
| Ctrl+Y, Ctrl+Shift+Z                |             | ⇧⌘Z              | Redo                                 | 重做/反撤銷/恢復                                  |
| `Alt+ ↓` / `Alt+ ↑`                 |             | ⌥↓ / ⌥↑          | Move line down/up                    | 移動行（向下/上）                                 |
| `Shift+Alt+ ↓` / `Shift+Alt+ ↑`     |             | ⇧⌥↓ / ⇧⌥↑        | Copy line down/up                    | 複製行（向下/上）                                 |
| Ctrl+Shift+K                        |             | ⇧⌘K              | Delete line                          | 刪除行                                            |
| `Ctrl+Enter` / `Ctrl+Shift+Enter`   |             | ⌘Enter / ⇧⌘Enter | Insert line below/above              | 插入行（下方/上方）                               |
| Ctrl+Shift+\                        |             | ⇧⌘\              | Jump to matching bracket             | 跳到匹配的括號內                                  |
| `Ctrl+]` / `Ctrl+[`                 |             | ⌘] / ⌘[          | Indent/outdent line                  | 縮排/縮出（取消縮排）行                           |
| Home / End                          |             | Home / End       | Go to beginning/end of line          | 轉到行首/行尾                                     |
| `Ctrl+ Home` / `Ctrl+ End`          |             | ⌘↑ / ⌘↓          | Go to beginning/end of file          | 轉到檔案的開頭/結尾處                             |
| `Ctrl+ ↑` / `Ctrl+ ↓`               |             | ⌃PgUp / ⌃PgDn    | Scroll line up/down                  | 滾動行（向上/下）                                 |
| `Alt+ PgUp` / `Alt+ PgDn`           |             | ⌘PgUp /⌘PgDn     | Scroll page up/down                  | 滾動頁面（向上/下）                               |
| `Ctrl+Shift+ [` / `Ctrl+Shift+ ]`   |             | ⌥⌘[ / ⌥⌘]        | Fold/unfold region                   | 摺疊/展開（解除摺疊）區域（程式碼塊）               |
| `Ctrl+K Ctrl+ [` / `Ctrl+K Ctrl+ ]` |             | ⌘K ⌘[ / ⌘K ⌘]    | Fold/unfold all subregions           | 摺疊/展開所有子區域                               |
| `Ctrl+K Ctrl+0` / `Ctrl+K Ctrl+J`   |             | ⌘K ⌘0 / ⌘K ⌘J    | Fold/unfold all regions              | 摺疊/展開所有區域                                 |
| Ctrl+K Ctrl+C                       |             | ⌘K ⌘C            | Add line comment                     | 新增行註釋                                        |
| Ctrl+K Ctrl+U                       |             | ⌘K ⌘U            | Remove line comment                  | 刪除行註釋                                        |
| Ctrl+/                              |             | ⌘/               | Toggle line comment                  | 切換行註釋(註釋或取消註釋)                        |
| Ctrl+Shift+A                        | Shift+Alt+A | ⇧⌥A              | Toggle block comment                 | 切換塊註釋                                        |
| Alt+Z                               |             | ⌥Z               | Toggle word wrap                     | 切換自動換行                                      |

---

| Linux                           | Win                                            | Mac             | **Multi-cursor and selection**              | 多游標與選擇（主要：列塊編輯）                                         |
| ------------------------------- | ---------------------------------------------- | --------------- | ------------------------------------------- | ---------------------------------------------------------------------- |
| Alt+Click                       |                                                | ⌥ + click       | Insert cursor                               | 插入游標                                                               |
| Shift+Alt+↑                     | Ctrl+Alt+↑                                     | ⌥⌘↑             | Insert cursor above                         | 在上方插入游標                                                         |
| Shift+Alt+↓                     | Ctrl+Alt+↓                                     | ⌥⌘↓             | Insert cursor below                         | 在下方插入游標                                                         |
| Ctrl+U                          |                                                | ⌘U              | Undo last cursor operation                  | 撤銷上一次游標操作                                                     |
| Shift+Alt+I                     |                                                | ⇧⌥I             | Insert cursor at end of each line selected  | 在選中行的末尾插入游標                                                 |
| Ctrl+L                          |                                                | ⌘L              | Select current line                         | 選擇當前行                                                             |
| Ctrl+Shift+L                    |                                                | ⇧⌘L             | Select all occurrences of current selection | 選擇當前選中項的所有匹配項                                             |
| Ctrl+F2                         |                                                | ⌘F2             | Select all occurrences of current word      | 選擇當前詞的所有匹配項                                                 |
| `Shift+Alt+ →` / `Shift+Alt+ ←` |                                                | ⌃⇧⌘→ / ←        | Expand / shrink selection                   | 擴大/縮小選擇                                                          |
| Shift+Alt + drag mouse          |                                                | ⇧⌥ + drag mouse | Column (box) selection                      | 列塊選擇（先按住 shift+alt，再按住滑鼠左鍵，最後拖拽滑鼠選中指定列塊） |
| 🤔️                             | `Ctrl+Shift+Alt+ ↑` / `Ctrl+Shift+Alt+ ↓`      | ⇧⌥⌘↑ / ↓        | Column (box) selection up/down              | 列塊選擇（向上/向下）                                                  |
| 🤔️                             | `Ctrl+Shift+Alt+ ←` / `Ctrl+Shift+Alt+ →`      | ⇧⌥⌘← / →        | Column (box) selection left/right           | 列塊選擇（左/右）                                                      |
| 🤔️                             | `Ctrl+Shift+Alt+ PgUp`/ `Ctrl+Shift+Alt+ PgDn` | ⇧⌥⌘PgUp / PgDn  | Column (box) selection page up/down         | 列塊選擇（頁面 上/下 移）                                              |
| Ctrl+A                          |                                                | ⌘A              | Select all                                  | 全選                                                                   |

---

| Linux                       | Win | Mac         | **Search and replace**                     | 搜尋與替換                          |
| --------------------------- | --- | ----------- | ------------------------------------------ | ----------------------------------- |
| Ctrl+F                      |     | ⌘F          | Find                                       | 查詢                                |
| Ctrl+H                      |     | ⌥⌘F         | Replace                                    | 替換                                |
| `F3` / `Shift+F3`           |     | ⌘G / ⇧⌘G    | Find next/previous                         | 查詢下一個/上一個                   |
| Alt+Enter                   |     | ⌥Enter      | Select all occurrences of Find match       | 選擇所有匹配項                      |
| Ctrl+D                      |     | ⌘D          | Add selection to next Find match           | 選擇下一個匹配項                    |
| Ctrl+K Ctrl+D               |     | ⌘K ⌘D       | Move last selection to next Find match     | 跳過當前選擇項                      |
| `Alt+C` / `Alt+R` / `Alt+W` |     | ⌥⌘C/⌥⌘R/⌥⌘W | Toggle case-sensitive / regex / whole word | 切換 區分大小寫/正則表示式/全字匹配 |

---

| Linux              | Win         | Mac        | **Rich languages editing**  | 富文字編輯     |
| ------------------ | ----------- | ---------- | --------------------------- | -------------- |
| Ctrl+Space, Ctrl+I |             | ⌃Space, ⌘I | Trigger suggestion          | 觸發建議       |
| Ctrl+Shift+Space   |             | ⇧⌘Space    | Trigger parameter hints     | 觸發引數提示   |
| Ctrl+Shift+I       | Shift+Alt+F | ⇧⌥F        | Format document             | 格式化文件     |
| Ctrl+K Ctrl+F      |             | ⌘K ⌘F      | Format selection            | 格式化所選部分 |
| F12                |             | F12        | Go to Definition            | 轉到定義       |
| Ctrl+Shift+F10     | Alt+F12     | ⌥F12       | Peek Definition             | 速覽定義       |
| Ctrl+K F12         |             | ⌘K F12     | Open Definition to the side | 在側邊顯示定義 |
| Ctrl+.             |             | ⌘.         | Quick Fix                   | 快速修復       |
| Shift+F12          |             | ⇧F12       | Show References             | 顯示引用       |
| F2                 |             | F2         | Rename Symbol               | 重新命名符號     |
| Ctrl+K Ctrl+X      |             | ⌘K ⌘X      | Trim trailing whitespace    | 裁剪尾隨空格   |
| Ctrl+K M           |             | ⌘K M       | Change file language        | 更改檔案語言   |

---

| Linux                         | Win                              | Mac      | **Navigation**                       | 導航                                                                     |
| ----------------------------- | -------------------------------- | -------- | ------------------------------------ | ------------------------------------------------------------------------ |
| Ctrl+T                        |                                  | ⌘T       | Show all Symbols                     | 顯示所有符號                                                             |
| Ctrl+G                        |                                  | ⌃G       | Go to Line...                        | 轉到指定行...                                                            |
| Ctrl+P                        |                                  | ⌘P       | Go to File...                        | 轉到檔案...                                                              |
| Ctrl+Shift+O                  |                                  | ⇧⌘O      | Go to Symbol...                      | 轉到符號...                                                              |
| Ctrl+Shift+M                  |                                  | ⇧⌘M      | Show Problems panel                  | 顯示問題面板                                                             |
| `F8`/`Shift+F8`               |                                  | F8 / ⇧F8 | Go to next/previous error or warning | 轉到下一個/上一個錯誤或警告                                              |
| Ctrl+Shift+Tab                |                                  | ⌃⇧Tab    | Navigate editor group history        | 在編輯器組（視窗）歷史記錄間進行導航（先按住 Ctrl+Shift，再按 tab 切換） |
| `Ctrl+Alt+ -`/`Ctrl+Shift+ -` | `Alt+ ←` / `Alt+ →`              | ⌃- / ⌃⇧- | Go back/forward                      | 後退/前進                                                                |
| Ctrl+M                        |                                  | ⌃⇧M      | Toggle Tab moves focus               | 切換 tab 鍵移動焦點（先按下 ⌃⇧M / Ctrl+M，再多按幾次 tab 鍵 移動焦點 ）  |
| Ctrl+Shift+B                  |                                  | ⌃⇧B      | Run build task                       | 執行生成(構建)任務                                                       |
| 🤔️                           | <!-- 可以自定義為 ctrl+win+B --> |          | Run task                             | 執行任務，預設為空，您可以自定義為 ⌃⌘B                                   |

---

| Linux                                 | Win                           | Mac             | **Editor management**                 | 編輯器管理                                      |
| ------------------------------------- | ----------------------------- | --------------- | ------------------------------------- | ----------------------------------------------- |
| Ctrl+W                                | Ctrl+F4, Ctrl+W               | ⌘W              | Close editor（file/tag)               | 關閉編輯器（檔案/標籤頁)                        |
| Ctrl+K F                              |                               | ⌘K F            | Close folder                          | 關閉資料夾                                      |
| Ctrl+\                                |                               | ⌘\              | Split editor                          | 拆分編輯器視窗                                  |
| `Ctrl+1` / `Ctrl+2` / `Ctrl+3`        |                               | ⌘1 / ⌘2 / ⌘3    | Focus into 1st, 2nd, 3rd editor group | 聚焦（切換）到第 1、第 2 或 第 3 個編輯組(視窗) |
| `Ctrl+K Ctrl+←` / `Ctrl+K Ctrl+→`     |                               | ⌘K ⌘← / ⌘K ⌘→   | Focus into previous/next editor group | 切換到上一個/下一個視窗                         |
| `Ctrl+Shift+PgUp` / `Ctrl+Shift+PgDn` |                               | ⌘K ⇧⌘← / ⌘K ⇧⌘→ | Move editor left/right                | 向左/右移動編輯器                               |
| `Ctrl+K ←` / `Ctrl+K →`               |                               | ⌘K ← / ⌘K →     | Move active editor group              | 向左/右移動正在使用（活動中）的視窗             |
| `Ctrl+PgUp` / `Ctrl+PgDn`             |                               | ⌥⌘←/⌥⌘→         | Focus into previous/next editor       | 切換到上一個/下一個編輯器                       |
| 🤔️                                   | `Ctrl+Alt+ →` / `Ctrl+Alt+ ←` | ⌃⌘→/⌃⌘←         | Move editor into next/previous group  | 將編輯器移動到下一組/上一組                     |
| Alt+F4                                |                               | ⌘Q              | Quit vscode                           | 退出 vscode                                     |

<!-- ctrl+alt+方向鍵 與 cinnamon 的切換工作區 快捷鍵衝突 -->

---

| Linux                         | Win      | Mac          | **File management**                     | 檔案管理                                                            |
| ----------------------------- | -------- | ------------ | --------------------------------------- | ------------------------------------------------------------------- |
| Ctrl+N                        |          | ⌘N           | New file                                | 新檔案                                                              |
| Ctrl+O                        |          | ⌘O           | Open file...                            | 開啟檔案...                                                         |
| Ctrl+S                        |          | ⌘S           | Save                                    | 儲存                                                                |
| Ctrl+Shift+S                  |          | ⇧⌘S          | Save as...                              | 另存為...                                                           |
| 🤔️                           | Ctrl+K S | ⌥⌘S          | Save all                                | 全部儲存                                                            |
| Ctrl+W                        | Ctrl+F4  | ⌘W           | Close                                   | 關閉                                                                |
| Ctrl+K Ctrl+W                 |          | ⌘K ⌘W        | Close all                               | 全部關閉                                                            |
| Ctrl+Shift+T                  |          | ⇧⌘T          | Reopen closed editor                    | 重新開啟關閉的編輯器                                                |
| Ctrl+K Enter                  |          | ⌘K Enter     | Keep preview mode editor open           | 保持預覽模式下的編輯器處於開啟狀態                                  |
| `Ctrl+Tab` / `Ctrl+Shift+Tab` |          | ⌃Tab / ⌃⇧Tab | Open next / previous                    | 開啟下一個/上一個                                                   |
| Ctrl+K P                      |          | ⌘K P         | Copy path of active file                | 複製活動檔案的路徑                                                  |
| Ctrl+K R                      |          | ⌘K R         | Reveal active file in File Explorer     | 在檔案管理器中顯示活動檔案                                          |
| Ctrl+K O                      |          | ⌘K O         | Show active file in new window/instance | 在新視窗/例項中顯示活動檔案                                         |
| Space, Enter                  |          | Space        | Open file in explorer                   | 先按下 ⇧⌘E 開啟資源管理器,然後按方向鍵選擇檔案,最後按下空格開啟檔案 |
| Ctrl+Enter                    |          | ⌃Enter       | Open file to the side                   | 在側邊開啟檔案                                                      |
| F2                            |          | Enter        | Rename file in explorer                 | 在資源管理器中重新命名檔案                                            |
| Delete                        |          | ⌘Backspace   | delete file in explorer                 | 在資源管理器中刪除檔案                                              |

---

| Linux                 | Win          | Mac      | **Display**                                | 顯示                                  |
| --------------------- | ------------ | -------- | ------------------------------------------ | ------------------------------------- |
| F11                   |              | ⌃⌘F      | Toggle full screen                         | 切換全屏                              |
| Shift+Alt+0           |              | ⌥⌘0      | Toggle editor layout (horizontal/vertical) | 切換編輯器佈局（水平/垂直）           |
| `Ctrl+ =` / `Ctrl+ -` |              | ⌘= / ⇧⌘- | Zoom in/out                                | 放大/縮小                             |
| Ctrl+B                |              | ⌘B       | Toggle Sidebar visibility                  | 切換側邊欄的可見性（開啟/關閉側邊欄） |
| Ctrl+Shift+E          |              | ⇧⌘E      | Show Explorer / Toggle focus               | 顯示資源管理器/切換焦點               |
| Ctrl+Shift+F          |              | ⇧⌘F      | Show Search                                | 顯示搜尋                              |
| Ctrl+Shift+G          |              | ⌃⇧G      | Show Source Control                        | 顯示原始碼控制                        |
| Ctrl+Shift+D          |              | ⇧⌘D      | Show Debug                                 | 顯示除錯                              |
| Ctrl+Shift+X          |              | ⇧⌘X      | Show Extensions                            | 顯示擴充套件                              |
| Ctrl+Shift+H          |              | ⇧⌘H      | Replace in files                           | 替換檔案中的內容                      |
| Ctrl+Shift+J          |              | ⇧⌘J      | Toggle Search details                      | 切換搜尋詳情                          |
| Ctrl+K Ctrl+H         | Ctrl+Shift+U | ⇧⌘U      | Show Output panel                          | 顯示輸出面板                          |
| Ctrl+Shift+V          |              | ⇧⌘V      | Open Markdown preview                      | 開啟 markdown 預覽                    |
| Ctrl+K V              |              | ⌘K V     | Open Markdown preview to the side          | 在側邊開啟 markdown 預覽              |
| Ctrl+K Z              |              | ⌘K Z     | Zen Mode (Esc to exit)                     | 禪模式（按 Esc 退出）                 |
| Ctrl+Shift+C          |              | ⇧⌘C      | Open new command prompt/terminal           | 開啟新的命令提示符/終端               |

---

| Linux               | Win | Mac        | **Debug**         | 除錯                |
| ------------------- | --- | ---------- | ----------------- | ------------------- |
| F9                  |     | F9         | Toggle breakpoint | 切換斷點            |
| F5                  |     | F5         | Start/Continue    | 開始/繼續           |
| `F11` / `Shift+F11` |     | F11 / ⇧F11 | Step into/ out    | 單步除錯：進入/跳出 |
| F10                 |     | F10        | Step over         | 單步跳過            |
| Shift+F5            |     | ⇧F5        | Stop              | 停止                |
| Ctrl+K Ctrl+I       |     | ⌘K ⌘I      | Show hover        | 顯示懸停            |

---

| Linux                             | Win                               | Mac         | **Integrated terminal**               | 整合終端                               |
| --------------------------------- | --------------------------------- | ----------- | ------------------------------------- | -------------------------------------- |
| Ctrl+\`                           |                                   | ⌃\`         | Show integrated terminal              | 顯示整合（內建）終端                   |
| Ctrl+Shift+\`                     |                                   | ⌃⇧\`        | Create new terminal                   | 建立新的終端                           |
| Ctrl+C                            |                                   |             | Interrupt foreground process          | 中斷執行中的前臺程序                   |
| Ctrl+Shift+C                      | Ctrl+C                            | ⌘C          | Copy selection                        | 先用滑鼠選中，再按下“指定按鍵”進行復制 |
| Ctrl+Shift+V                      | Ctrl+V                            | ⌘V          | Paste into active terminal            | 貼上                                   |
| `Ctrl+Shift+ ↑` / `Ctrl+Shift+ ↓` | `Ctrl+Alt+PgUp` / `Ctrl+Alt+PgDn` | ⌘↑ / ↓      | Scroll up/down                        | 向上/向下滾動（行）                    |
| `Shift+ PgUp` / `Shift+ PgDn`     |                                   | PgUp / PgDn | Scroll page up/down                   | 向上/向下滾動（頁）                    |
| `Shift+ Home` / `Shift+ End`      | `Ctrl+ Home` / `Ctrl+ End`        | ⌘Home / End | Scroll to top/bottom                  | 滾動到頂部/底部                        |
| `Ctrl+Shift+5`                    |                                   | ⌘\\ , ⌃⇧5   | Split terminal                        | 拆分終端                               |
| `Ctrl+PgUp` / `Ctrl+PgDn`         |                                   | ⇧⌘[ / ]     | Focus previous/next terminal          | 聚焦（切換）上/下 一個 終端            |
| `Alt+ ↑` / `Alt+ ↓`               |                                   | ⌥⌘↑ / ↓     | Focus previous/next terminal in group | 在終端組中切換 上/下 一個終端          |
| `Ctrl+Shift+ ←` / `Ctrl+Shift+ →` | 🤔️                               | ⌃⌘← / →     | Resize terminal left/right            | 調整終端大小（左/右）                  |
| 🤔️                               |                                   | ⌃⌘↑ / ↓     | Resize terminal up/down               | 調整終端大小（上/下）                  |

---
