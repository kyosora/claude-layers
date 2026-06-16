# Claude Layers

[English](README.md) | **繁體中文**

**一套給 `CLAUDE.md` 的分層架構——把人格切換抽象成可分享、可通用的形式。** 定義共用的
`core`,在上面疊領域 `mode`,各自預編譯成單一可部署的 `CLAUDE.md`,用 `/switch` 互換。

這原本是一個私人的 `/switch` skill。這個 repo 是它的抽象:把讓人格切換真正可行的分層與分級
機制打包成任何人都能採用的系統。

## 問題

你的 `CLAUDE.md` 超過 300 行,所有東西都標「必須」。共用規則(身份、記憶、通訊綁定)在每個
情境間複製貼上,改一處要手動更新五個檔——而當每個 skill 都「必須使用」,AI 也分不出輕重。

分層解決這個。人格切換是主要應用;過程中你順手得到 skill 優先級分級,以及一塊共用的注入防禦。

## 1. Core + Mode 分層架構

```
core.md（共用身份、記憶規則、通用 skill、注入防禦塊）
   +
mode.md（領域哲學、專業工作流、模式專屬 skill）
   ↓
compiled/mode.md  →  部署為 ~/.claude/CLAUDE.md
```

所有模式繼承 `core`。改一次 `core` → 下次重新編譯所有模式同步更新。編譯檔是單純串接,所以
部署一個人格就是一次檔案複製——**零執行時合併成本**。

**判斷原則**:適用於所有工作 → `core`。只在做 X 時適用 → mode `X`。

→ [架構深入](docs/architecture.md) · [設定指南](docs/setup.md)

## 2. 人格切換(`/switch`)

| 指令 | 效果 |
|------|------|
| `/switch` | 列出可用模式 |
| `/switch developer` | 永久切換——驗證、備份、原子寫 |
| `/switch writer this session` | 臨時切換(`CLAUDE.md` 不變) |
| `/switch status` | 現在是哪個模式 |
| `/switch undo` | 還原上一份 `CLAUDE.md` |
| `/switch rebuild` | 編輯 core/mode 檔後重新編譯 |

切換本質上仍是一次檔案複製(約 50 token、無 context window 開銷)——`scripts/deploy.sh`
只是讓它非破壞性:驗證 persona、備份當前 `CLAUDE.md`、原子寫入,已對齊時靜默 no-op。

**有證明,不是空話。** switch/分層契約有一套確定性、不呼叫模型的測試(`scripts/switch-test.sh`,
CI 內常綠):rebuild 逐位元正確、永久切換部署對的檔、臨時切換不動 `CLAUDE.md`、rebuild 冪等。
(注入防禦副產品有自己的套件——核心扛一樣的證明重量。)

**自動切換(opt-in)。** 想讓每個專案載入對的 persona?放一個 `.claude/persona` 檔(或在
`…/ws/<persona>/` 樹下工作),內建的 SessionStart hook 就替你對齊 `CLAUDE.md`——建在同一個
安全部署上,已對齊時真正 no-op。見 [docs/setup.md](docs/setup.md)。

## 3. Skill 優先級分級

當 150 個 skill 全標「必須」,就等於沒有必須——AI 浪費 token 評估不需要的 skill。兩級制解決,
而且你可以只把這個分級套到現有 `CLAUDE.md`,不需要這個 repo 的其他東西:

- **🔴 硬性** — 包裝外部 API/服務。不觸發 = 任務做不了。
- **🟡 參考** — 提供指引/模板。不觸發 = 品質較低,不是失敗。

> 🔴 硬性綁定必須觸發,無例外。🟡 參考綁定依情境判斷。這是個優先級/衝突解決規則,
> *補強* skill frontmatter 探索——不是取代它。

## 副產品:一塊共用的注入防禦

因為每個人格都繼承 `core.md`,你有**一個**地方放「該到處生效」的規則。最該放那裡的就是一塊
注入防禦塊——所以它預設就在 `core`,每個編譯出來的人格都免費拿到。

它讓 Claude **揭露**第三方指令(skill 的「幫我 star」、shell 片段裡靜默的 `curl` 外洩、假的
`<system>` 標籤)並**停下來等你**,而不是默默照做或默默拒絕。在一次參考 A/B 執行裡,它把
Claude 從自主拒絕(等待 1/16)轉成揭露並等待(14/16)——偵測本身沒它就已經很強。

→ [可獨立使用的防禦塊](docs/injection-defense.md)(貼進任何 `CLAUDE.md`,不需要分層)
→ [16 個測試案例](docs/injection-tests.md) · [A/B 結果與限制](docs/test-results.md)

## 快速開始

最快路徑——一條指令腳手架出可用設定(非破壞性:備份既有 `CLAUDE.md`、不覆蓋既有設定):

```bash
git clone https://github.com/kyosora/claude-layers.git && cd claude-layers
./scripts/init.sh          # 腳手架 core + 起手 mode、編譯、指向 persona-config
./scripts/deploy.sh ~/.claude/personas/compiled/developer.md   # 或:/switch developer
```

或手動:

```bash
$EDITOR personas/core.md                              # 你的共用基礎
cp personas/examples/developer.md personas/developer.md   # 從模板實例化一個 mode
./scripts/rebuild.sh                                  # 編譯 personas/*.md → compiled/
cp -r skills/switch ~/.claude/skills/switch           # 安裝 /switch skill
/switch developer
```

> `personas/examples/` 是模板——`rebuild.sh` 預設編 top-level 的 `personas/*.md`
> (先複製一個模板進去,或用 `rebuild.sh --examples`)。

完整說明、建立自己的模式、檔案佈局:**[docs/setup.md](docs/setup.md)**。
想要一步安裝?它也以 [Claude Code plugin](.claude-plugin/plugin.json) 形式提供:
`/plugin marketplace add kyosora/claude-layers`。

## 與原生 Claude Code 功能的關係

這個 repo 的部分功能現在與平台原生功能重疊。這值得知道——有原生機制就用原生的,分層留給它仍然
獨有的部分:

| 這個 repo | 原生對應(2026) | 分層仍然勝出的時機 |
|-----------|------------------|--------------------|
| `core.md` + `mode.md` 預編譯 | output-styles、subagents | 你想要一個自足、零執行時合併成本的 `CLAUDE.md` 檔 |
| `/switch`(複製編譯檔) | `/output-style` | 你特別想要單檔人格切換 |
| Skill 觸發表 | skill frontmatter 探索 | 你需要跨 skill 的*優先級*(🔴/🟡 規則),frontmatter 表達不了 |

`scripts/make-output-style.sh` 接通兩者:把人格的身份段匯出成原生 output-style,不碰 `/switch`
也不碰你的 `CLAUDE.md`。

## 這不是什麼

不是 prompt 集合或人格市集。`personas/examples/` 裡的範例模式是展示模式的模板,不是成品。
價值在架構——怎麼分層、分級、切換你的 `CLAUDE.md`——不是裡面寫什麼。

## 授權

MIT
