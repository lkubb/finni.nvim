# finni.nvim

```
███████╗██╗███╗   ██╗███╗   ██╗██╗   ███╗   ██╗██╗   ██╗██╗███╗   ███╗
██╔════╝██║████╗  ██║████╗  ██║██║   ████╗  ██║██║   ██║██║████╗ ████║
█████╗  ██║██╔██╗ ██║██╔██╗ ██║██║   ██╔██╗ ██║██║   ██║██║██╔████╔██║
██╔══╝  ██║██║╚██╗██║██║╚██╗██║██║   ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║     ██║██║ ╚████║██║ ╚████║██║██╗██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝  ╚═══╝╚═╝╚═╝╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝
```

Sublime autosessions.

A flexible, project-focused autosession plugin for Neovim,
unbound by the limits of `:mksession`.

## Table of Contents

1. [Introduction](<#finni-introduction>)
2. [✨ Features](<#finni-features>)
3. [⛓️ Dependencies](<#finni-dependencies>)
4. [📦 Setup](<#finni-setup>)
    * [`vim.pack`](<#finni-setup-vim-pack>)
    * [`lazy.nvim`](<#finni-setup-lazy-nvim>)
    * [`mini.deps`](<#finni-setup-mini-deps>)
5. [🚀 Usage](<#finni-usage>)
    * [Keymaps](<#finni-usage-keymaps>)
    * [Ex command](<#finni-usage-ex-command>)
    * [Pickers](<#finni-usage-pickers>)
6. [👤 Concepts](<#finni-concepts>)
7. [❗ Limitations and caveats](<#finni-limitations-and-caveats>)
8. [⚙️ Configuration](<#finni-configuration>)
    * [Defaults](<#finni-configuration-defaults>)
    * [`autosession`](<#finni-configuration-autosession>)
    * [`extensions`](<#finni-configuration-extensions>)
    * [`load`](<#finni-configuration-load>)
    * [`log`](<#finni-configuration-log>)
    * [`session`](<#finni-configuration-session>)
9. [📒 Recipes](<#finni-recipes>)
    * [Tab-scoped Sessions](<#finni-recipes-tab-scoped-sessions>)
    * [Custom Extension](<#finni-recipes-custom-extension>)
10. [🔌 API](<#finni-api>)
    * [`finni.session` (Module)](<#finni.session>)
    * [`finni.auto` (Module)](<#finni.auto>)
11. [🧩 Extensions](<#finni-extensions>)
    * [Built-in](<#finni-extensions-built-in>)
    * [External](<#finni-extensions-external>)
12. [❓ FAQ](<#finni-faq>)

<a id="finni-introduction"></a>
## Introduction
You switched to Neovim from a less advanced™ text editor and finally learned the dark arts of
exiting it. Never again shall your terminal emulator be trapped like Josef K.

Now, you urgently need to leave because your hamster has entered an Abstract Expressionist
phase and is preparing to "paint" the wall with a bottle of sriracha and a toothpick.
In the rush, you don't care about losing the intricate state of your 72h session and type
the ancient incantation: `:qa`.

Neovim refuses. An unnamed buffer contains a half-formed thought that must be judged before
you're allowed to go. You don't want to delete it. You don't want to commit to it.
You want to protect your wall from artistic reinterpretation.

Finni just lets you leave. When you return, everything will be like you left it: Buffers,
windows, tabs, jumplists, changelists, loclists, quickfix lists, and even that pesky
modified buffer.

The wall, sadly, may not be.

<a id="finni-features"></a>
## ✨ Features
- **Comprehensive snapshots** of the current Neovim state:
  - Preserve your entire workspace: tabs, window layout, open buffers, cursor positions, and relevant buffer/window/global options.
  - Preserve **unsaved changes** and corresponding **undo history**, including for unnamed buffers.
  - Preserve navigation state: **jumplists** (each window separately, unlike ShaDa), **changelists**, **loclists**, **quickfix** lists, including your current position in each, and buffer-local/global **marks**.
  - Snapshot restoration is compatible with `lazy.nvim` `VeryLazy`-loaded plugins.
- **Automatic session management** (opt-in):
  - Automatically create, save, and restore snapshots per directory, Git repository and branch.
  - Autoswitch sessions when changing branches (`git switch`) or directories (`:cd`).
- **Separate Neovim scopes**, by default: directory or Git repository/branch. This prevents[^1]
  - mangling of unrelated command/search/input/expr/debug histories.
  - going back the jumplist (`CTRL-o`) and ending up in a seemingly random file.
- **Highly customizable**:
  - Override, filter, or extend what gets saved or restored — globally, per project, or per session.
  - Add **custom extensions** to restore state from other plugins.
  - React to events with **custom hooks**.
  - **Define scopes** in code however you like: directory basename, weekday, `head -c 1 /dev/random` (y tho?), ...
  - E.g., it's possible to (ab)use autosession loading logic to start into predefined layouts, depending on the directory you execute Neovim in.
- [Lua API](#finni.session) for `'nomagic'` **manual session management**, including tab-scoped sessions
  - This API is mostly backwards-compatible with [`resession.nvim`](https://github.com/stevearc/resession.nvim).\
    (Finni started by forking it, a heartfelt thank you @stevearc for laying the arduous ground work! <3)
  - For the brave, an even more low-level session and snapshot API (`finni.core.session`, `finni.core.snapshot`)
    is available.
- Inbuilt pickers for `snacks.picker`, `fzf-lua`, `mini.pick` and `telescope.nvim`

[^1]: similar to scope-specific ShaDa via `'shadafile'`

<a id="finni-dependencies"></a>
## ⛓️ Dependencies
* Neovim 0.10+
* [`lewis6991/gitsigns.nvim`](https://github.com/lewis6991/gitsigns.nvim/) (optional) for branch monitoring

<a id="finni-setup"></a>
## 📦 Setup
A general description follows. For specific plugin managers, see below.

1. Add this plugin to your `'runtimepath'`.
1. (optional) Override the [configuration defaults](#finni-configuration-defaults) by assigning [a configuration table](#finni.UserConfig) to `g:finni_config`.
1. (optional) Enable startup autosessions by setting `g:finni_autosession` to `true`.
1. (optional) Define [keymaps](#finni-usage-keymaps).

You don't need to call `setup()`.
You don't need to handle lazy-loading yourself.
Finni is always there for you when you need him.
<a id="finni-setup-vim-pack"></a>
<details>
  <summary>

### `vim.pack`

  </summary>

```lua
vim.pack.add("https://github.com/lkubb/finni.nvim")
---@type finni.auto.InitHandler|boolean
vim.g.finni_autosession = true -- optionally enable startup autosessions
---@type finni.UserConfig
vim.g.finni_config = { --[[ custom options/overrides ]] }
```

</details>

<a id="finni-setup-lazy-nvim"></a>
<details>
  <summary>

### `lazy.nvim`

  </summary>

```lua
{
  "lkubb/finni.nvim",
  -- This plugin only ever loads as much as needed.
  -- You don't need to manage lazyloading manually.
  -- Initialization is only triggered if you enable startup autosessions
  -- and an autosession is defined for the current environment
  -- or once you invoke the Finni Lua API/Ex command.
  lazy = false,
  -- If you don't want to enable startup autosessions, you can use
  --  `opts` for custom configuration (or omit it if you want to use defaults).
  init = function()
    ---@type finni.auto.InitHandler|boolean
    vim.g.finni_autosession = true -- optionally enable startup autosessions
    ---@type finni.UserConfig
    vim.g.finni_config = { --[[ custom options/overrides ]] }
  end,
}
```

</details>

<a id="finni-setup-mini-deps"></a>
<details>
  <summary>

### `mini.deps`

  </summary>

```lua
MiniDeps.add({
  source = "lkubb/finni.nvim",
  checkout = "main",
})
---@type finni.auto.InitHandler|boolean
vim.g.finni_autosession = true -- optionally enable startup autosessions
---@type finni.UserConfig
vim.g.finni_config = { --[[ custom options/overrides ]] }
```

</details>


<a id="finni-usage"></a>
## 🚀 Usage
First, decide whether you want to follow a mostly hands-off approach with autosessions
or prefer the more predictable route of managing your sessions manually.

Especially with autosessions, try to get an intuition for its inner workings before relying on this plugin for important work.
If you prefer reading, see the [Concepts](#finni-concepts) section below for details on this topic.

In any case, make sure you give the [limitations and caveats](#finni-limitations-and-caveats) a quick read.

Later, you can customize the [configuration](#finni-configuration) and check
if you want to enable some [extensions](#finni-extensions) to restore windows of your plugins.

<a id="finni-usage-keymaps"></a>
### Keymaps
Finni does not include default keymaps since different users will have very divergent needs
and preferences. Set-and-forget startup autosession users might never need any in the first place,
especially since the `:Finni` command exposes large parts of the Lua API for the rare case
where they would want to intervene. The most useful command to map is `:Finni reset`, in the author's opinion.
<details>

<summary>

Still, here is an example setup that focuses on **autosessions**:

</summary>

```lua
-- Without startup autosessions, you need to enter Finni explicitly.
-- This runs the autosession logic and sets up environment monitoring.
vim.keymap.set("n", "<leader>Ss", "<cmd>Finni start<cr>", { desc = "[S]ession [S]tart" })
-- Delete active autosession, reset Neovim to a clean state and attach a fresh autosession.
vim.keymap.set("n", "<leader>SR", "<cmd>Finni reset<cr>", { desc = "[S]ession [R]eset" })
-- Detach active session. Autosessions are still triggered by environment changes.
vim.keymap.set("n", "<leader>Sd", "<cmd>Finni detach<cr>", { desc = "[S]ession [D]etach" })
-- Detach active session and stop environment monitoring.
vim.keymap.set("n", "<leader>SS", "<cmd>Finni stop<cr>", { desc = "[S]ession [S]top" })
-- List all sessions in the current project
vim.keymap.set("n", "<leader>Sl", "<cmd>Finni list<cr>", { desc = "[S]essions [L]ist" })
-- Inspect the active session
vim.keymap.set("n", "<leader>Si", "<cmd>Finni info<cr>", { desc = "[S]ession [I]nfo" })
```

</details>
<details>

<summary>

And here is a basic one for **manual sessions**

</summary>

```lua
-- Load a session. Displays an interactive selection.
vim.keymap.set("n", "<leader>Sl", function() require("finni.session").load() end, { desc = "[S]ession [L]oad" })
-- Save the current state to a global snapshot.
-- If no session is active, prompts for snapshot/session name to save as.
vim.keymap.set("n", "<leader>Ss", function() require("finni.session").save() end, { desc = "[S]ession [S]ave" })
-- Detach active session and reset all buffers/windows/tabs associated with it.
vim.keymap.set("n", "<leader>Sc", function() require("finni.session").detach(nil, nil, {reset = true}) end, { desc = "[S]ession [C]lose" })
-- Delete a session. Displays an interactive selection.
vim.keymap.set("n", "<leader>SD", function() require("finni.session").delete() end, { desc = "[S]ession [D]elete" })
```

</details>

<a id="finni-usage-ex-command"></a>
### Ex command
Finni creates an Ex command with the same name (`:Finni`). It currently exposes the [autosession API](#finni.auto) only.

1. Make the first argument the name of the Lua function to execute:

   ```
   :Finni reset
   ```
1. Follow with positional arguments (`nil`, `false`, `true` are parsed):

   ```
   :Finni load /home/me/code/my_project
   ```
1. Pass `opts` table keys as keyword arguments (by name):

   ```
   :Finni detach save=false reset=true
   ```
1. Full example:
   ```
   :Finni load /home/me/code/my_project modified=false
   ```

<a id="finni-usage-pickers"></a>
### Pickers
Finni comes with inbuilt support for most popular pickers (`snacks.picker`, `fzf-lua`, `mini.pick`, `telescope.nvim`).
You can load and manage manual sessions, autosessions and projects.

Pickers other than `snacks.picker` (where no such thing exists) and `telescope` (which is always available) are registered when
their module is required and the underlying picker has already been setup, when you explicitly launch a picker
(`require ("finni.pickers.mini_pick").manual_picker()`) or call the picker's `setup` function with
`register` being set to `true`. This means you can call them with the underlying plugin's Ex command afterwards:

* `:Telescope finni auto_all` (`telescope.nvim`)
* `:Pick finni_auto_all` (`mini.pick`)
* `:FzfLua finni_auto_all` (`fzf-lua`)

The pickers are called:
* `manual`: Pick manual sessions.
* `auto_all`: Pick all autosessions from all projects.
* `auto`: Pick autosessions from current project.
* `projects`: Pick known projects.

<a id="finni-usage-pickers-keybinds"></a>
#### Keybinds
Select a session and hit enter to load it. Delete a session or project by pressing `<M-d>` (Alt/Option + d) when selected. From the overview
of project autosessions, you can navigate to the projects overview by pressing `<C-^>` (`<C-6>`).

<a id="finni-usage-pickers-configuration"></a>
#### Configuration
When launching a picker, you can override any options that get passed to the underlying plugin via the `raw` key. There are some
Finni-specific options (such as `dir`) as well. If you want to override the defaults without specifying them in every picker call,
you can pass them to the picker's `setup` function (Telescope can handle this automatically for you).

<a id="finni.pickers.PickerConfig"></a>
##### `finni.pickers.PickerConfig` (Class)

**Fields:**

* **raw** [`finni.pickers.PickerRawOverrides`](<#finni.pickers.PickerRawOverrides>)\
  Override any options that are passed to a picker.
  Valid values depend on the specific picker plugin.

  Table fields:

  * **default** `table`\
    Override any (picker plugin-specific) options passed to all picker types.
  * **manual** `table`\
    Override any (picker plugin-specific) options passed to the manual session picker.
  * **auto** `table`\
    Override any (picker plugin-specific) options passed to the autosession picker.
  * **auto_all** `table`\
    Override any (picker plugin-specific) options passed to the global autosession picker.
  * **project** `table`\
    Override any (picker plugin-specific) options passed to the project autosession picker.
* **dir**? `string`\
  Override the default manual session directory (`session.dir`)
<a id="finni-usage-pickers-snacks-picker"></a>
<details>
  <summary>

#### `snacks.picker`

  </summary>

```lua
-- Pick manual sessions
require("finni.pickers.snacks").manual_picker()
-- Pick autosessions, spanning all known projects
require("finni.pickers.snacks").auto_all_picker()
-- Pick autosessions in the active project
require("finni.pickers.snacks").auto_picker()
-- Pick known projects
require("finni.pickers.snacks").project_picker()
```

<a id="finni.pickers.snacks"></a>
##### `finni.pickers.snacks` (Module)
<a id="finni.pickers.snacks.setup()"></a>
<details>
  <summary>

###### setup(`opts`)

  </summary>

Override picker defaults

**Parameters:**
  * **opts**? `Partial<`[`finni.pickers.PickerConfig`](<#finni.pickers.PickerConfig>)`>`\
    Defaults for future calls.

</details>

<a id="finni.pickers.snacks.manual_picker()"></a>
<details>
  <summary>

###### manual_picker(`opts`)

  </summary>

Load or delete existing manual sessions.

**Parameters:**
  * **opts**? `Partial<`[`finni.pickers.PickerConfig`](<#finni.pickers.PickerConfig>)`>`\
    Override Finni-specific and picker-specific options.

</details>

<a id="finni.pickers.snacks.auto_all_picker()"></a>
<details>
  <summary>

###### auto_all_picker(`opts`)

  </summary>

Load or delete existing autosessions spanning all projects.

**Parameters:**
  * **opts**? `Partial<`[`finni.pickers.PickerConfig`](<#finni.pickers.PickerConfig>)`>`\
    Override Finni-specific and picker-specific options.

</details>

<a id="finni.pickers.snacks.auto_picker()"></a>
<details>
  <summary>

###### auto_picker(`opts`, `project_name`)

  </summary>

Load or delete existing autosessions in specific project only.

**Parameters:**
  * **opts**? `Partial<`[`finni.pickers.PickerConfig`](<#finni.pickers.PickerConfig>)`>`\
    Override Finni-specific and picker-specific options.

  * **project_name**? `string`\
    List autosessions from this project. Defaults to current one.

</details>

<a id="finni.pickers.snacks.project_picker()"></a>
<details>
  <summary>

###### project_picker(`opts`)

  </summary>

Inspect or delete existing projects. Select project to manage/load its autosessions.

**Parameters:**
  * **opts**? `Partial<`[`finni.pickers.PickerConfig`](<#finni.pickers.PickerConfig>)`>`\
    Override Finni-specific and picker-specific options.

</details>

</details>

<a id="finni-usage-pickers-fzf-lua"></a>
<details>
  <summary>

#### `fzf-lua`

  </summary>

```lua
-- Pick manual sessions
require("finni.pickers.fzf_lua").manual_picker()
-- Pick autosessions, spanning all known projects
require("finni.pickers.fzf_lua").auto_all_picker()
-- Pick autosessions in the active project
require("finni.pickers.fzf_lua").auto_picker()
-- Pick known projects
require("finni.pickers.fzf_lua").project_picker()
```

<a id="finni.pickers.fzf_lua"></a>
##### `finni.pickers.fzf_lua` (Module)
<a id="finni.pickers.fzf_lua.setup()"></a>
<details>
  <summary>

###### setup(`opts`, `register`)

  </summary>

Override picker defaults and register extensions.

**Parameters:**
  * **opts**? `Partial<`[`finni.pickers.PickerConfig`](<#finni.pickers.PickerConfig>)`>`\
    Defaults for future calls.

  * **register**? `boolean`\
    Force registering extensions to be able to launch pickers via the `FzfLua` Ex command.
    Note: Loads `fzf-lua`.

</details>

<a id="finni.pickers.fzf_lua.manual_picker()"></a>
<details>
  <summary>

###### manual_picker(`opts`)

  </summary>

Load or delete existing manual sessions.

**Parameters:**
  * **opts**? `Partial<`[`finni.pickers.PickerConfig`](<#finni.pickers.PickerConfig>)`>`\
    Override Finni-specific and picker-specific options.

</details>

<a id="finni.pickers.fzf_lua.auto_all_picker()"></a>
<details>
  <summary>

###### auto_all_picker(`opts`)

  </summary>

Load or delete existing autosessions spanning all projects.

**Parameters:**
  * **opts**? `Partial<`[`finni.pickers.PickerConfig`](<#finni.pickers.PickerConfig>)`>`\
    Override Finni-specific and picker-specific options.

</details>

<a id="finni.pickers.fzf_lua.auto_picker()"></a>
<details>
  <summary>

###### auto_picker(`opts`, `project_name`)

  </summary>

Load or delete existing autosessions in specific project only.

**Parameters:**
  * **opts**? `Partial<`[`finni.pickers.PickerConfig`](<#finni.pickers.PickerConfig>)`>`\
    Override Finni-specific and picker-specific options.

  * **project_name**? `string`\
    List autosessions from this project. Defaults to current one.

</details>

<a id="finni.pickers.fzf_lua.project_picker()"></a>
<details>
  <summary>

###### project_picker(`opts`)

  </summary>

Inspect or delete existing projects. Select project to manage/load its autosessions.

**Parameters:**
  * **opts**? `Partial<`[`finni.pickers.PickerConfig`](<#finni.pickers.PickerConfig>)`>`\
    Override Finni-specific and picker-specific options.

</details>

</details>

<a id="finni-usage-pickers-mini-pick"></a>
<details>
  <summary>

#### `mini.pick`

  </summary>

```lua
-- Pick manual sessions
require("finni.pickers.mini_pick").manual_picker()
-- Pick autosessions, spanning all known projects
require("finni.pickers.mini_pick").auto_all_picker()
-- Pick autosessions in the active project
require("finni.pickers.mini_pick").auto_picker()
-- Pick known projects
require("finni.pickers.mini_pick").project_picker()
```

<a id="finni.pickers.mini_pick"></a>
##### `finni.pickers.mini_pick` (Module)
<a id="finni.pickers.mini_pick.setup()"></a>
<details>
  <summary>

###### setup(`opts`, `register`)

  </summary>

Override picker defaults and register extensions.

**Parameters:**
  * **opts**? `Partial<`[`finni.pickers.PickerConfig`](<#finni.pickers.PickerConfig>)`>`\
    Defaults for future calls.

  * **register**? `boolean`\
    Force registering extensions to be able to launch pickers via the `Pick` Ex command.
    Note: Loads `mini.pick`.

</details>

<a id="finni.pickers.mini_pick.manual_picker()"></a>
<details>
  <summary>

###### manual_picker(`opts`)

  </summary>

Load or delete existing manual sessions.

**Parameters:**
  * **opts**? `Partial<`[`finni.pickers.PickerConfig`](<#finni.pickers.PickerConfig>)`>`\
    Override Finni-specific and picker-specific options.

</details>

<a id="finni.pickers.mini_pick.auto_all_picker()"></a>
<details>
  <summary>

###### auto_all_picker(`opts`)

  </summary>

Load or delete existing autosessions spanning all projects.

**Parameters:**
  * **opts**? `Partial<`[`finni.pickers.PickerConfig`](<#finni.pickers.PickerConfig>)`>`\
    Override Finni-specific and picker-specific options.

</details>

<a id="finni.pickers.mini_pick.auto_picker()"></a>
<details>
  <summary>

###### auto_picker(`opts`, `project_name`)

  </summary>

Load or delete existing autosessions in specific project only.

**Parameters:**
  * **opts**? `Partial<`[`finni.pickers.PickerConfig`](<#finni.pickers.PickerConfig>)`>`\
    Override Finni-specific and picker-specific options.

  * **project_name**? `string`\
    List autosessions from this project. Defaults to current one.

</details>

<a id="finni.pickers.mini_pick.project_picker()"></a>
<details>
  <summary>

###### project_picker(`opts`)

  </summary>

Inspect or delete existing projects. Select project to manage/load its autosessions.

**Parameters:**
  * **opts**? `Partial<`[`finni.pickers.PickerConfig`](<#finni.pickers.PickerConfig>)`>`\
    Override Finni-specific and picker-specific options.

</details>

</details>

<a id="finni-usage-pickers-telescope-nvim"></a>
<details>
  <summary>

#### `telescope.nvim`

  </summary>

```lua
-- Pick manual sessions
require("finni.pickers.telescope").manual_picker()
-- Pick autosessions, spanning all known projects
require("finni.pickers.telescope").auto_all_picker()
-- Pick autosessions in the active project
require("finni.pickers.telescope").auto_picker()
-- Pick known projects
require("finni.pickers.telescope").project_picker()
```

Note: You can explicitly register the `finni` extension in Telescope's options:

```lua
require("telescope").setup({
  -- ...
  extensions = {
    -- ...
    finni = { --[[ custom overrides, see finni.pickers.PickerConfig]] }
  }
})
```

<a id="finni.pickers.telescope"></a>
##### `finni.pickers.telescope` (Module)
<a id="finni.pickers.telescope.setup()"></a>
<details>
  <summary>

###### setup(`opts`)

  </summary>

Override picker defaults

**Parameters:**
  * **opts**? `Partial<`[`finni.pickers.PickerConfig`](<#finni.pickers.PickerConfig>)`>`\
    Defaults for future calls.

</details>

<a id="finni.pickers.telescope.manual_picker()"></a>
<details>
  <summary>

###### manual_picker(`opts`)

  </summary>

Load or delete existing manual sessions.

**Parameters:**
  * **opts**? `Partial<`[`finni.pickers.PickerConfig`](<#finni.pickers.PickerConfig>)`>`\
    Override Finni-specific and picker-specific options.

</details>

<a id="finni.pickers.telescope.auto_all_picker()"></a>
<details>
  <summary>

###### auto_all_picker(`opts`)

  </summary>

Load or delete existing autosessions spanning all projects.

**Parameters:**
  * **opts**? `Partial<`[`finni.pickers.PickerConfig`](<#finni.pickers.PickerConfig>)`>`\
    Override Finni-specific and picker-specific options.

</details>

<a id="finni.pickers.telescope.auto_picker()"></a>
<details>
  <summary>

###### auto_picker(`opts`, `project_name`)

  </summary>

Load or delete existing autosessions in specific project only.

**Parameters:**
  * **opts**? `Partial<`[`finni.pickers.PickerConfig`](<#finni.pickers.PickerConfig>)`>`\
    Override Finni-specific and picker-specific options.

  * **project_name**? `string`\
    List autosessions from this project. Defaults to current one.

</details>

<a id="finni.pickers.telescope.project_picker()"></a>
<details>
  <summary>

###### project_picker(`opts`)

  </summary>

Inspect or delete existing projects. Select project to manage/load its autosessions.

**Parameters:**
  * **opts**? `Partial<`[`finni.pickers.PickerConfig`](<#finni.pickers.PickerConfig>)`>`\
    Override Finni-specific and picker-specific options.

</details>

</details>


<a id="finni-concepts"></a>
## 👤 Concepts
* A **project** is a container for one or more related sessions that can share some data.<a id="finni-concepts-project"></a>
  It's only relevant for autosessions currently.
* A **snapshot** is the save data required to restore a specific Neovim state. It consists of a JSON data file and optional related files (ShaDa, unwritten buffer contents, undo histories for unwritten buffers).<a id="finni-concepts-snapshot"></a>
* A **session** is the relation between current Neovim state and an on-disk snapshot.<a id="finni-concepts-session"></a>
* An **autosession** is a session that is derived from an environment.<a id="finni-concepts-autosession"></a>
  It's restored and attached automatically when triggered.
  Mixing manual and autosession usage is *discouraged* currently. Interplay is TBD.
* A **global session** persists everything into its snapshot. Autosessions are always global sessions currently.<a id="finni-concepts-global-session"></a>
* A **tab-scoped session** does not include global state.<a id="finni-concepts-tab-session"></a>
  It only persists windows in its associated tab.
  By default, persisted buffers are still the same as in global sessions.
* **Restoring** a snapshot loads the saved state into the Neovim instance.<a id="finni-concepts-snapshot-restore"></a>
  If it's a dirty instance, restoration can either reset Neovim's state to a clean one or merge it with the snapshot.
  By default, restoring a global snapshot resets everything in your Neovim instance,
  while tab snapshots are restored into a fresh tab.
  It's possible to restore snapshots without attaching the session after.
* **Attaching** a session means (auto)save operations overwrite the snapshot it points to, using the configuration that was derived when attaching it.<a id="finni-concepts-session-attach"></a>
  There can only be one attached (active) global session, but several tab sessions at a time.
  Mixing both types is *discouraged* currently. Interplay is TBD.
* **Detaching** a session means save operations no longer overwrite the snapshot it points to.<a id="finni-concepts-session-detach"></a>
  It can optionally be combined with closing associated buffers/windows/tabs (see reset below).
* A **reset** during *session detaching* implies **only session-associated** resources (those persisted to its snapshot) are closed.<a id="finni-concepts-session-detach-reset"></a>
* A **reset** during *snapshot restoration* implies **all** Neovim resources are closed (buffers, windows, tabs).<a id="finni-concepts-snapshot-restore-reset"></a>\
  **Hint:** Loading a global session implies potentially detaching an active session, followed by snapshot restoration.
* **Autosaving** means that an attached session is saved automatically at specific points in Neovim's lifetime:<a id="finni-concepts-autosave"></a>
  - before the session is detached
  - when Neovim is closed
  - in regular intervals

<a id="finni-limitations-and-caveats"></a>
## ❗ Limitations and caveats
* Although the snapshot logic is relatively proven, many aspects of how autosessions work,
  more "exotic" persistency types and their config have not been designed on a drafting board.
  The sole user has been me, while at the same time developing Finni over the last year.
  Expect surprises and some clunkiness, for now, but feel free to [create an issue](https://github.com/lkubb/finni.nvim/issues/new/choose) if that happens to you.
  I want this plugin to be useful to many people.
* A similar caveat applies to the interplay between different kinds of sessions, which is
  explicitly *to be determined*. The safest bet are global sessions, but stick to either
  manual OR automatic ones.
* Don't rely on preservation of modified buffers for highly valuable or
  otherwise significant work, or if you do, don't curse me when you lose it.
  With that said, it has been quite reliable during my usage.

<a id="finni-configuration"></a>
## ⚙️ Configuration
<a id="finni-configuration-defaults"></a>
<details>
  <summary>

### Defaults

  </summary>

```lua
{
  autosession = {
    config = {
      modified = false,
    },
    dir = "finni",
    spec = render_autosession_context,
    workspace = util.git.find_workspace_root,
    project_name = util.auto.workspace_project_map,
    session_name = util.auto.generate_name,
    enabled = function(meta)
      return true
    end,
    load_opts = function(meta)
      return {}
    end,
  },
  extensions = {
    quickfix = {},
  },
  load = {
    detail = true,
    order = "modification_time",
  },
  log = {
    level = "warn",
    format = "[%(level)s %(dtime)s] %(message)s%(src_sep)s[%(src_path)s:%(src_line)s]",
    notify_level = "warn",
    notify_format = "%(message)s",
    notify_opts = { title = "Finni" },
    time_format = "%Y-%m-%d %H:%M:%S",
  },
  session = {
    dir = "session",
    options = {
      "binary",
      "bufhidden",
      "buflisted",
      "cmdheight",
      "diff",
      "filetype",
      "modifiable",
      "previewwindow",
      "readonly",
      "scrollbind",
      "winfixheight",
      "winfixwidth",
    },
    buf_filter = default_buf_filter,
    tab_buf_filter = function(tabpage, bufnr, opts)
      return true
    end,
    modified = "auto",
    autosave_enabled = false,
    autosave_interval = 60,
    autosave_notify = true,
    command_history = "auto",
    search_history = "auto",
    input_history = "auto",
    expr_history = "auto",
    debug_history = "auto",
    jumps = "auto",
    changelist = "auto",
    global_marks = "auto",
    local_marks = "auto",
  },
}
```

</details>

<a id="finni.UserConfig"></a>

<a id="finni-configuration-autosession"></a>
### `autosession`
**Type:** [`finni.UserConfig.autosession`](<#finni.UserConfig.autosession>)`?`

Influence autosession behavior and contents.
Specify defaults that apply to all autosessions.
By overriding specific hooks, you can minutely customize almost any aspect
of when an autosession is triggered, how it's handled and what is persisted in it.


<details>
  <summary>

#### Table fields

  </summary>

* **config**? [`finni.core.Session.InitOpts`](<#finni.core.Session.InitOpts>)\
  Save/load configuration for autosessions.
  Definitions in here override the defaults in `session`.

  Table fields:

  * **autosave_enabled**? `boolean`\
    When this session is attached, automatically save it in intervals. Defaults to false.
  * **autosave_interval**? `integer`\
    Seconds between autosaves of this session, if enabled. Defaults to 60.
  * **autosave_notify**? `boolean`\
    Trigger a notification when autosaving this session. Defaults to true.
  * **on_attach**? [`finni.core.Session.AttachHook`](<#finni.core.Session.AttachHook>)\
    A function that's called when attaching to this session. No global default.
  * **on_detach**? [`finni.core.Session.DetachHook`](<#finni.core.Session.DetachHook>)\
    A function that's called when detaching from this session. No global default.
  * **options**? `string[]`\
    Save and restore these Neovim (global|buffer|tab|window) options.
  * **buf_filter**? [`finni.BufFilter`](<#finni.BufFilter>)\
    Function that decides whether a buffer should be included in a snapshot.
  * **tab_buf_filter**? [`finni.TabBufFilter`](<#finni.TabBufFilter>)\
    Function that decides whether a buffer should be included in a tab-scoped snapshot.
    `buf_filter` is called first, this is to refine acceptable buffers only.
  * **modified**? `(boolean|"auto")`\
    Save/load modified buffers and their undo history.
    If set to `auto` (default), does not save, but still restores modified buffers.
  * **jumps**? `boolean`\
    Save/load window-specific jumplists, including current position
    (yes, for **all windows**, not just the active one like with ShaDa).
    If set to `auto` (default), does not save, but still restores saved jumplists.
  * **changelist**? `boolean`\
    Save/load buffer-specific changelist (all buffers) and
    changelist position (visible buffers only).

    **Important**: Enabling this causes **buffer-local marks to be cleared** during restoration.
    Consider tracking `local_marks` in addition to this.
  * **global_marks**? `boolean`\
    Save/load global marks (A-Z, not 0-9 currently).

    _Only in global sessions._
  * **local_marks**? `boolean`\
    Save/load buffer-specific (local) marks.

    **Note**: Enable this if you track the `changelist`.
  * **search_history**? `(integer|boolean)`\
    Maximum number of search history items to persist. Defaults to false.
    If set to `true`, maps to the `'history'` option.

    _Only in global sessions._
  * **command_history**? `(integer|boolean)`\
    Maximum number of command history items to persist. Defaults to false.
    If set to `true`, maps to the `'history'` option.

    _Only in global sessions._
  * **input_history**? `(integer|boolean)`\
    Maximum number of input history items to persist. Defaults to false.
    If set to `true`, maps to the `'history'` option.

    _Only in global sessions._
  * **expr_history**? `boolean`\
    Persist expression history. Defaults to false.
    **Note**: Cannot set limit (currently), no direct support by neovim.

    _Only in global sessions._
  * **debug_history**? `boolean`\
    Persist debug history. Defaults to false.
    **Note**: Cannot set limit (currently), no direct support by neovim.

    _Only in global sessions._
* **dir**? `string`\
  Name of the directory to store autosession projects in.
  Interpreted relative to `$XDG_STATE_HOME/$NVIM_APPNAME`.
  Defaults to `finni`.
* **spec**? [`finni.auto.SpecHook`](<#finni.auto.SpecHook>)\
  This function implements the logic that derives the autosession spec from a path,
  usually the current working directory. If it returns an autosession spec, Finni
  automatically switches to the session's workspace root and tries to restore an
  existing matching session (matched by project name + session name).
  If it returns nothing, it's interpreted as "no autosession should be active".

  It is called during various points in Finni's lifecycle:
  1. Neovim startup (if startup autosessions are enabled)
  2. When Neovim changes its global working directory
  3. When a git branch is switched (if you have installed gitsigns.nvim)

  If the return value does not match the current state, the currently active
  session (if any) is saved + closed and the new session (if any) restored.

  The default implementation calls `workspace`, `project_name`, `session_name`,
  `enabled` and `load_opts` to piece together the specification.
  By overriding this config field, you can implement a custom logic.
  Mind that the other hooks have no effect then (unless you call them manually).
* **workspace**? [`finni.auto.WorkspaceHook`](<#finni.auto.WorkspaceHook>)\
  Receive the effective nvim cwd, return workspace root and whether it is git-tracked.
* **project_name**? [`finni.auto.ProjectNameHook`](<#finni.auto.ProjectNameHook>)\
  Receive the workspace root dir and whether it's git-tracked, return the project-specific session directory name.
* **session_name**? [`finni.auto.SessionNameHook`](<#finni.auto.SessionNameHook>)\
  Receive the effective nvim cwd, the workspace root, the project name and workspace repo git info and generate a session name.
* **enabled**? [`finni.auto.EnabledHook`](<#finni.auto.EnabledHook>)\
  Receive the effective nvim cwd, the workspace root and project name and decide
  whether an autosession with this configuration should be active.
* **load_opts**? [`finni.auto.LoadOptsHook`](<#finni.auto.LoadOptsHook>)\
  Influence how an autosession is loaded/persisted, e.g. load the session without attaching it or disable modified persistence.
  Merged on top of the default autosession configuration for this specific autosession only.

</details>


<a id="finni-configuration-extensions"></a>
### `extensions`
**Type:** `table<string,any>?`

Configuration for extensions, both Resession ones and those specific to Finni.
Note: Finni first tries to load specified extensions in `finni.extensions`,
but falls back to `resession.extension` with a warning. Avoid this overhead
for Resession extensions by specifying `resession_compat = true` in the extension config.

<a id="finni-configuration-load"></a>
### `load`
**Type:** [`finni.UserConfig.load`](<#finni.UserConfig.load>)`?`

Configure session list information detail and sort order.


<details>
  <summary>

#### Table fields

  </summary>

* **detail**? `boolean`\
  Show more detail about the sessions when selecting one to load.
  Disable if it causes lag.
* **order**? `("modification_time"|"creation_time"|"filename")`\
  Session list order

</details>


<a id="finni-configuration-log"></a>
### `log`
**Type:** [`finni.UserConfig.log`](<#finni.UserConfig.log>)`?`

Configure plugin logging.


<details>
  <summary>

#### Table fields

  </summary>

* **level**? `("trace"|"debug"|"info"|"warn"|"error"|"off")`\
  Minimum level to log at. Defaults to `warn`.
* **notify_level**? `("trace"|"debug"|"info"|"warn"|"error"|"off")`\
  Minimum level to use `vim.notify` for. Defaults to `warn`.
* **notify_opts**? `table`\
  Options to pass to `vim.notify`. Defaults to `{ title = "Finni" }`
* **format**? `string`\
  Log line format string. Note that this works like Python's f-strings.
  Defaults to `[%(level)s %(dtime)s] %(message)s%(src_sep)s[%(src_path)s:%(src_line)s]`.
  Available parameters:
  * `level` Uppercase level name
  * `message` Log message
  * `dtime` Formatted date/time string
  * `hrtime` Time in `[ns]` without absolute anchor
  * `src_path` Path to the file that called the log function
  * `src_line` Line in `src_path` that called the log function
  * `src_sep` Whitespace between log line and source of call, 2 tabs for single line, newline + tab for multiline log messages
* **notify_format**? `string`\
  Same as `format`, but for `vim.notify` message display. Defaults to `%(message)s`.
* **time_format**? `string`\
  `strftime` format string used for rendering time of call. Defaults to `%Y-%m-%d %H:%M:%S`
* **handler**? `fun(line: `[`finni.log.Line`](<#finni.log.Line>)`)`

</details>


<a id="finni-configuration-session"></a>
### `session`
**Type:** [`finni.UserConfig.session`](<#finni.UserConfig.session>)`?`

Configure default session behavior and contents, affects both manual and autosessions.
Note: In the following field descriptions, "this session" refers to all sessions
that don't override these defaults.


<details>
  <summary>

#### Table fields

  </summary>

* **autosave_enabled**? `boolean`\
  When this session is attached, automatically save it in intervals. Defaults to false.
* **autosave_interval**? `integer`\
  Seconds between autosaves of this session, if enabled. Defaults to 60.
* **autosave_notify**? `boolean`\
  Trigger a notification when autosaving this session. Defaults to true.
* **on_attach**? [`finni.core.Session.AttachHook`](<#finni.core.Session.AttachHook>)\
  A function that's called when attaching to this session. No global default.
* **on_detach**? [`finni.core.Session.DetachHook`](<#finni.core.Session.DetachHook>)\
  A function that's called when detaching from this session. No global default.
* **options**? `string[]`\
  Save and restore these Neovim (global|buffer|tab|window) options.
* **buf_filter**? [`finni.BufFilter`](<#finni.BufFilter>)\
  Function that decides whether a buffer should be included in a snapshot.
* **tab_buf_filter**? [`finni.TabBufFilter`](<#finni.TabBufFilter>)\
  Function that decides whether a buffer should be included in a tab-scoped snapshot.
  `buf_filter` is called first, this is to refine acceptable buffers only.
* **modified**? `(boolean|"auto")`\
  Save/load modified buffers and their undo history.
  If set to `auto` (default), does not save, but still restores modified buffers.
* **jumps**? `boolean`\
  Save/load window-specific jumplists, including current position
  (yes, for **all windows**, not just the active one like with ShaDa).
  If set to `auto` (default), does not save, but still restores saved jumplists.
* **changelist**? `boolean`\
  Save/load buffer-specific changelist (all buffers) and
  changelist position (visible buffers only).

  **Important**: Enabling this causes **buffer-local marks to be cleared** during restoration.
  Consider tracking `local_marks` in addition to this.
* **global_marks**? `boolean`\
  Save/load global marks (A-Z, not 0-9 currently).

  _Only in global sessions._
* **local_marks**? `boolean`\
  Save/load buffer-specific (local) marks.

  **Note**: Enable this if you track the `changelist`.
* **search_history**? `(integer|boolean)`\
  Maximum number of search history items to persist. Defaults to false.
  If set to `true`, maps to the `'history'` option.

  _Only in global sessions._
* **command_history**? `(integer|boolean)`\
  Maximum number of command history items to persist. Defaults to false.
  If set to `true`, maps to the `'history'` option.

  _Only in global sessions._
* **input_history**? `(integer|boolean)`\
  Maximum number of input history items to persist. Defaults to false.
  If set to `true`, maps to the `'history'` option.

  _Only in global sessions._
* **expr_history**? `boolean`\
  Persist expression history. Defaults to false.
  **Note**: Cannot set limit (currently), no direct support by neovim.

  _Only in global sessions._
* **debug_history**? `boolean`\
  Persist debug history. Defaults to false.
  **Note**: Cannot set limit (currently), no direct support by neovim.

  _Only in global sessions._
* **dir**? `string`\
  Name of the directory to store regular sessions in.
  Interpreted relative to `$XDG_STATE_HOME/$NVIM_APPNAME`.

</details>


<a id="finni-recipes"></a>
## 📒 Recipes
<a id="finni-recipes-tab-scoped-sessions"></a>
<details>
  <summary>

### Tab-scoped Sessions

  </summary>

When saving a session, only save the current tab

```lua
-- Bind `save_tab` instead of `save`
local session = require("finni.session")

vim.keymap.set("n", "<leader>ss", session.save_tab)
vim.keymap.set("n", "<leader>sl", session.load)
vim.keymap.set("n", "<leader>sd", session.delete)
```

This only saves the current tabpage layout, but _all_ of the open buffers.
You can provide a filter to exclude buffers.
For example, if you are using `:tcd` to have tabs open for different directories,
this only saves buffers in the current tabpage directory:

```lua
vim.g.finni_config = {
  tab_buf_filter = function(tabpage, bufnr)
    local dir = vim.fn.getcwd(-1, vim.api.nvim_tabpage_get_number(tabpage))
    -- ensure dir has trailing /
    dir = dir:sub(-1) ~= "/" and dir .. "/" or dir
    return vim.startswith(vim.api.nvim_buf_get_name(bufnr), dir)
  end,
}
```

</details>

<a id="finni-recipes-custom-extension"></a>
<details>
  <summary>

### Custom Extension

  </summary>

You can save custom session data with your own extension.

To create one, add a file to your runtimepath at `lua/finni/extensions/<myplugin>.lua`.
Add the following contents:

```lua
local M = {}

--- Called when saving a session. Should return necessary state.
---@param opts (resession.Extension.OnSaveOpts & finni.core.snapshot.Context)
---@param buflist finni.core.snapshot.BufList
---@return any
M.on_save = function(opts, buflist)
  return {}
end

--- Called before restoring anything, receives the data returned by `on_save`.
---@param data any Data returned by `on_save`
---@param opts finni.core.snapshot.Context
---@param buflist string[]
M.on_pre_load = function(data)
  -- This is run before the buffers, windows, and tabs are restored
end

--- Called after restoring everything, receives the data returned by `on_save`.
---@param data any Data returned by `on_save`
---@param opts finni.core.snapshot.Context
---@param buflist string[]
M.on_post_load = function(data)
  -- This is run after the buffers, windows, and tabs are restored
end

--- Called when Finni gets configured.
--- This function is optional.
---@param data table Configuration data passed in the config (in `extensions.<extension_name>`)
M.config = function(data)
  -- Optional setup for your extension
end

--- Check if a window is supported by this extension.
--- This function is optional, but if provided `save_win` and `load_win` must
--- also be present.
---@param winid integer
---@param bufnr integer
---@return boolean
M.is_win_supported = function(winid, bufnr)
  return false
end

--- Save data for a window. Called when `is_win_supported` returned true.
--- Note: Finni does not focus tabs or windows during session save,
---       so the current window/buffer will most likely be a different one than `winid`.
---@param winid integer
---@return any
M.save_win = function(winid)
  -- This is used to save the data for a specific window that contains a non-file buffer (e.g. a filetree).
  return {}
end

--- Called after creating a tab's windows with the data from `save_win`.
---@param winid integer
---@param data any
---@param win finni.core.layout.WinInfo
---@return integer? new_winid If the original window has been replaced, return the new ID that should replace it
M.load_win = function(winid, config, win)
  -- Restore the window from the config
end

return M
```

Enable your extension by adding a corresponding key in the `extensions` option:

```lua
vim.g.finni_config = {
  extensions = {
    myplugin = {
      -- This table is passed to M.config(). It can be empty.
    },
  },
}
```

For tab-scoped sessions, the `on_save` and `on_load` methods of extensions are **disabled by default**.
You can force-enable them by setting the `enable_in_tab` option to `true` (it's an inbuilt option respected for all extensions).

```lua
vim.g.finni_config = {
  -- ...
  extensions = {
    myplugin = {
      enable_in_tab = true,
    },
  }
}
```

</details>


<a id="finni-api"></a>
## 🔌 API


<a id="finni.session"></a>
### `finni.session` (Module)

Interactive API, (mostly) compatible with stevearc/resession.nvim.
<a id="finni.session.save()"></a>
<details>
  <summary>

#### save(`name`, `opts`)

  </summary>

Save the current global state to disk

**Parameters:**
  * **name**? `string`\
    Name of the global session to save.
    If not provided, takes name of attached one or prompts user.

  * **opts**? `(`[`finni.session.SaveOpts`](<#finni.session.SaveOpts>)` & `[`finni.core.PassthroughOpts`](<#finni.core.PassthroughOpts>)`)`

    Table fields:

    * **dir**? `string`\
      Name of session directory (overrides config.dir)
    * **autosave_enabled**? `boolean`\
      When this session is attached, automatically save it in intervals. Defaults to false.
    * **autosave_interval**? `integer`\
      Seconds between autosaves of this session, if enabled. Defaults to 60.
    * **autosave_notify**? `boolean`\
      Trigger a notification when autosaving this session. Defaults to true.
    * **on_attach**? [`finni.core.Session.AttachHook`](<#finni.core.Session.AttachHook>)\
      A function that's called when attaching to this session. No global default.
    * **on_detach**? [`finni.core.Session.DetachHook`](<#finni.core.Session.DetachHook>)\
      A function that's called when detaching from this session. No global default.
    * **options**? `string[]`\
      Save and restore these Neovim (global|buffer|tab|window) options.
    * **buf_filter**? [`finni.BufFilter`](<#finni.BufFilter>)\
      Function that decides whether a buffer should be included in a snapshot.
    * **tab_buf_filter**? [`finni.TabBufFilter`](<#finni.TabBufFilter>)\
      Function that decides whether a buffer should be included in a tab-scoped snapshot.
      `buf_filter` is called first, this is to refine acceptable buffers only.
    * **modified**? `(boolean|"auto")`\
      Save/load modified buffers and their undo history.
      If set to `auto` (default), does not save, but still restores modified buffers.
    * **jumps**? `boolean`\
      Save/load window-specific jumplists, including current position
      (yes, for **all windows**, not just the active one like with ShaDa).
      If set to `auto` (default), does not save, but still restores saved jumplists.
    * **changelist**? `boolean`\
      Save/load buffer-specific changelist (all buffers) and
      changelist position (visible buffers only).

      **Important**: Enabling this causes **buffer-local marks to be cleared** during restoration.
      Consider tracking `local_marks` in addition to this.
    * **global_marks**? `boolean`\
      Save/load global marks (A-Z, not 0-9 currently).

      _Only in global sessions._
    * **local_marks**? `boolean`\
      Save/load buffer-specific (local) marks.

      **Note**: Enable this if you track the `changelist`.
    * **search_history**? `(integer|boolean)`\
      Maximum number of search history items to persist. Defaults to false.
      If set to `true`, maps to the `'history'` option.

      _Only in global sessions._
    * **command_history**? `(integer|boolean)`\
      Maximum number of command history items to persist. Defaults to false.
      If set to `true`, maps to the `'history'` option.

      _Only in global sessions._
    * **input_history**? `(integer|boolean)`\
      Maximum number of input history items to persist. Defaults to false.
      If set to `true`, maps to the `'history'` option.

      _Only in global sessions._
    * **expr_history**? `boolean`\
      Persist expression history. Defaults to false.
      **Note**: Cannot set limit (currently), no direct support by neovim.

      _Only in global sessions._
    * **debug_history**? `boolean`\
      Persist debug history. Defaults to false.
      **Note**: Cannot set limit (currently), no direct support by neovim.

      _Only in global sessions._
    * **meta**? `table`\
      External data remembered in association with this session. Useful to build on top of the core API.
    * **attach**? `boolean`\
      Attach to/stay attached to session after operation
    * **notify**? `boolean`\
      Notify on success
    * **reset**? `boolean`\
      When detaching a session in the process, unload associated resources/reset
      everything during the operation when restoring a snapshot.

</details>

<a id="finni.session.save_tab()"></a>
<details>
  <summary>

#### save_tab(`name`, `opts`)

  </summary>

Save the state of the current tabpage to disk

**Parameters:**
  * **name**? `string`\
    Name of the tabpage session to save.
    If not provided, takes name of attached one in current tabpage or prompts user.

  * **opts**? `(`[`finni.session.SaveOpts`](<#finni.session.SaveOpts>)` & `[`finni.core.PassthroughOpts`](<#finni.core.PassthroughOpts>)`)`

    Table fields:

    * **dir**? `string`\
      Name of session directory (overrides config.dir)
    * **autosave_enabled**? `boolean`\
      When this session is attached, automatically save it in intervals. Defaults to false.
    * **autosave_interval**? `integer`\
      Seconds between autosaves of this session, if enabled. Defaults to 60.
    * **autosave_notify**? `boolean`\
      Trigger a notification when autosaving this session. Defaults to true.
    * **on_attach**? [`finni.core.Session.AttachHook`](<#finni.core.Session.AttachHook>)\
      A function that's called when attaching to this session. No global default.
    * **on_detach**? [`finni.core.Session.DetachHook`](<#finni.core.Session.DetachHook>)\
      A function that's called when detaching from this session. No global default.
    * **options**? `string[]`\
      Save and restore these Neovim (global|buffer|tab|window) options.
    * **buf_filter**? [`finni.BufFilter`](<#finni.BufFilter>)\
      Function that decides whether a buffer should be included in a snapshot.
    * **tab_buf_filter**? [`finni.TabBufFilter`](<#finni.TabBufFilter>)\
      Function that decides whether a buffer should be included in a tab-scoped snapshot.
      `buf_filter` is called first, this is to refine acceptable buffers only.
    * **modified**? `(boolean|"auto")`\
      Save/load modified buffers and their undo history.
      If set to `auto` (default), does not save, but still restores modified buffers.
    * **jumps**? `boolean`\
      Save/load window-specific jumplists, including current position
      (yes, for **all windows**, not just the active one like with ShaDa).
      If set to `auto` (default), does not save, but still restores saved jumplists.
    * **changelist**? `boolean`\
      Save/load buffer-specific changelist (all buffers) and
      changelist position (visible buffers only).

      **Important**: Enabling this causes **buffer-local marks to be cleared** during restoration.
      Consider tracking `local_marks` in addition to this.
    * **global_marks**? `boolean`\
      Save/load global marks (A-Z, not 0-9 currently).

      _Only in global sessions._
    * **local_marks**? `boolean`\
      Save/load buffer-specific (local) marks.

      **Note**: Enable this if you track the `changelist`.
    * **search_history**? `(integer|boolean)`\
      Maximum number of search history items to persist. Defaults to false.
      If set to `true`, maps to the `'history'` option.

      _Only in global sessions._
    * **command_history**? `(integer|boolean)`\
      Maximum number of command history items to persist. Defaults to false.
      If set to `true`, maps to the `'history'` option.

      _Only in global sessions._
    * **input_history**? `(integer|boolean)`\
      Maximum number of input history items to persist. Defaults to false.
      If set to `true`, maps to the `'history'` option.

      _Only in global sessions._
    * **expr_history**? `boolean`\
      Persist expression history. Defaults to false.
      **Note**: Cannot set limit (currently), no direct support by neovim.

      _Only in global sessions._
    * **debug_history**? `boolean`\
      Persist debug history. Defaults to false.
      **Note**: Cannot set limit (currently), no direct support by neovim.

      _Only in global sessions._
    * **meta**? `table`\
      External data remembered in association with this session. Useful to build on top of the core API.
    * **attach**? `boolean`\
      Attach to/stay attached to session after operation
    * **notify**? `boolean`\
      Notify on success
    * **reset**? `boolean`\
      When detaching a session in the process, unload associated resources/reset
      everything during the operation when restoring a snapshot.

</details>

<a id="finni.session.save_all()"></a>
<details>
  <summary>

#### save_all(`opts`)

  </summary>

Save all currently attached sessions to disk

**Parameters:**
  * **opts**? `(`[`finni.SideEffects.Notify`](<#finni.SideEffects.Notify>)` & `[`finni.core.PassthroughOpts`](<#finni.core.PassthroughOpts>)`)`

    Table fields:

    * **notify**? `boolean`\
      Notify on success

</details>

<a id="finni.session.load()"></a>
<details>
  <summary>

#### load(`name`, `opts`)

  </summary>

Load a session from disk.

Note: The default value of `opts.reset = "auto"` resets when loading a normal session,
but _not_ when loading a tab-scoped session.

**Parameters:**
  * **name**? `string`\
    Name of the session to load from session dir.
    If not provided, prompts user.

  * **opts**? `(`[`finni.session.LoadOpts`](<#finni.session.LoadOpts>)` & `[`finni.core.PassthroughOpts`](<#finni.core.PassthroughOpts>)`)`

    Table fields:

    * **dir**? `string`\
      Name of session directory (overrides config.dir)
    * **autosave_enabled**? `boolean`\
      When this session is attached, automatically save it in intervals. Defaults to false.
    * **autosave_interval**? `integer`\
      Seconds between autosaves of this session, if enabled. Defaults to 60.
    * **autosave_notify**? `boolean`\
      Trigger a notification when autosaving this session. Defaults to true.
    * **on_attach**? [`finni.core.Session.AttachHook`](<#finni.core.Session.AttachHook>)\
      A function that's called when attaching to this session. No global default.
    * **on_detach**? [`finni.core.Session.DetachHook`](<#finni.core.Session.DetachHook>)\
      A function that's called when detaching from this session. No global default.
    * **options**? `string[]`\
      Save and restore these Neovim (global|buffer|tab|window) options.
    * **buf_filter**? [`finni.BufFilter`](<#finni.BufFilter>)\
      Function that decides whether a buffer should be included in a snapshot.
    * **tab_buf_filter**? [`finni.TabBufFilter`](<#finni.TabBufFilter>)\
      Function that decides whether a buffer should be included in a tab-scoped snapshot.
      `buf_filter` is called first, this is to refine acceptable buffers only.
    * **modified**? `(boolean|"auto")`\
      Save/load modified buffers and their undo history.
      If set to `auto` (default), does not save, but still restores modified buffers.
    * **jumps**? `boolean`\
      Save/load window-specific jumplists, including current position
      (yes, for **all windows**, not just the active one like with ShaDa).
      If set to `auto` (default), does not save, but still restores saved jumplists.
    * **changelist**? `boolean`\
      Save/load buffer-specific changelist (all buffers) and
      changelist position (visible buffers only).

      **Important**: Enabling this causes **buffer-local marks to be cleared** during restoration.
      Consider tracking `local_marks` in addition to this.
    * **global_marks**? `boolean`\
      Save/load global marks (A-Z, not 0-9 currently).

      _Only in global sessions._
    * **local_marks**? `boolean`\
      Save/load buffer-specific (local) marks.

      **Note**: Enable this if you track the `changelist`.
    * **search_history**? `(integer|boolean)`\
      Maximum number of search history items to persist. Defaults to false.
      If set to `true`, maps to the `'history'` option.

      _Only in global sessions._
    * **command_history**? `(integer|boolean)`\
      Maximum number of command history items to persist. Defaults to false.
      If set to `true`, maps to the `'history'` option.

      _Only in global sessions._
    * **input_history**? `(integer|boolean)`\
      Maximum number of input history items to persist. Defaults to false.
      If set to `true`, maps to the `'history'` option.

      _Only in global sessions._
    * **expr_history**? `boolean`\
      Persist expression history. Defaults to false.
      **Note**: Cannot set limit (currently), no direct support by neovim.

      _Only in global sessions._
    * **debug_history**? `boolean`\
      Persist debug history. Defaults to false.
      **Note**: Cannot set limit (currently), no direct support by neovim.

      _Only in global sessions._
    * **meta**? `table`\
      External data remembered in association with this session. Useful to build on top of the core API.
    * **attach**? `boolean`\
      Attach to/stay attached to session after operation
    * **reset**? `(boolean|"auto")`\
      When detaching a session in the process, unload associated resources/reset
      everything during the operation when restoring a snapshot.
      `auto` resets only for global sessions.
    * **save**? `boolean`\
      Save/override autosave config for affected sessions before the operation
    * **silence_errors**? `boolean`\
      Don't error during this operation

</details>

<a id="finni.session.detach()"></a>
<details>
  <summary>

#### detach(`target`, `reason`, `opts`)

  </summary>

Detach from the session that contains the target (or all active sessions if unspecified).

**Parameters:**
  * **target**? `("__global"|"__active"|"__active_tab"|"__all_tabs"|string|integer...)`\
    The scope/session name/tabid to detach from. If unspecified, detaches all sessions.

  * **reason**? `(`[`finni.core.Session.DetachReasonBuiltin`](<#finni.core.Session.DetachReasonBuiltin>)`|string)`\
    Pass a custom reason to detach handlers. Defaults to `request`.

  * **opts**? `(`[`finni.core.Session.DetachOpts`](<#finni.core.Session.DetachOpts>)` & `[`finni.core.PassthroughOpts`](<#finni.core.PassthroughOpts>)`)`

    Table fields:

    * **reset**? `boolean`\
      When detaching a session in the process, unload associated resources/reset
      everything during the operation when restoring a snapshot.
    * **save**? `boolean`\
      Save/override autosave config for affected sessions before the operation

**Returns:** **detached** `boolean`\
Whether we detached from any session

</details>

<a id="finni.session.list()"></a>
<details>
  <summary>

#### list(`opts`)

  </summary>

List all available saved sessions in session dir

**Parameters:**
  * **opts**? [`finni.session.DirParam`](<#finni.session.DirParam>)

    Table fields:

    * **dir**? `string`\
      Name of session directory (overrides config.dir)

**Returns:** **sessions_in_dir** `string[]`

</details>

<a id="finni.session.delete()"></a>
<details>
  <summary>

#### delete(`name`, `opts`)

  </summary>

Delete a saved session from session dir

**Parameters:**
  * **name**? `string`\
    Name of the session. If not provided, prompts user

  * **opts**? `(`[`finni.session.DeleteOpts`](<#finni.session.DeleteOpts>)` & `[`finni.core.PassthroughOpts`](<#finni.core.PassthroughOpts>)`)`

    Table fields:

    * **dir**? `string`\
      Name of session directory (overrides config.dir)
    * **notify**? `boolean`\
      Notify on success
    * **reset**? `boolean`\
      When detaching a session in the process, unload associated resources/reset
      everything during the operation when restoring a snapshot.
    * **silence_errors**? `boolean`\
      Don't error during this operation

</details>



<a id="finni.auto"></a>
### `finni.auto` (Module)
<a id="finni.auto.explicit_ctx()"></a>
<details>
  <summary>

#### explicit_ctx(`session`, `project`, `opts`)

  </summary>

Get the autosession configuration for an explicit project/session name pair.
Note: Can fail if a directory can map to multiple sessions (e.g. with Git branches)
and its current state does not correspond to the session.

**Parameters:**
  * **session** `string`\
    Name of the session

  * **project**? `string`\
    Name of the project. If unspecified, defaults to current one

  * **opts**? [`finni.SideEffects.SilenceErrors`](<#finni.SideEffects.SilenceErrors>)

    Table fields:

    * **silence_errors**? `boolean`\
      Don't error during this operation

**Returns:** [`finni.auto.AutosessionContext`](<#finni.auto.AutosessionContext>)`?`

</details>

<a id="finni.auto.save()"></a>
<details>
  <summary>

#### save(`opts`)

  </summary>

Save the currently active autosession.

**Parameters:**
  * **opts**? `(`[`finni.auto.SaveOpts`](<#finni.auto.SaveOpts>)` & `[`finni.core.PassthroughOpts`](<#finni.core.PassthroughOpts>)`)`

    Table fields:

    * **attach**? `boolean`\
      Attach to/stay attached to session after operation
    * **notify**? `boolean`\
      Notify on success
    * **reset**? `boolean`\
      When detaching a session in the process, unload associated resources/reset
      everything during the operation when restoring a snapshot.

</details>

<a id="finni.auto.detach()"></a>
<details>
  <summary>

#### detach(`opts`)

  </summary>

Detach from the currently active autosession.
If autosave is enabled, save it. Optionally close **everything**.

**Parameters:**
  * **opts**? `(`[`finni.core.Session.DetachOpts`](<#finni.core.Session.DetachOpts>)` & `[`finni.core.PassthroughOpts`](<#finni.core.PassthroughOpts>)`)`

    Table fields:

    * **reset**? `boolean`\
      When detaching a session in the process, unload associated resources/reset
      everything during the operation when restoring a snapshot.
    * **save**? `boolean`\
      Save/override autosave config for affected sessions before the operation

</details>

<a id="finni.auto.load()"></a>
<details>
  <summary>

#### load(`autosession`, `opts`)

  </summary>

Load an autosession.

**Parameters:**
  * **autosession**? `(`[`finni.auto.AutosessionContext`](<#finni.auto.AutosessionContext>)`|string)`\
    The autosession table as rendered by `get_ctx` or cwd to pass to it

  * **opts**? [`finni.auto.LoadOpts`](<#finni.auto.LoadOpts>)

    Table fields:

    * **autosave_enabled**? `boolean`\
      When this session is attached, automatically save it in intervals. Defaults to false.
    * **autosave_interval**? `integer`\
      Seconds between autosaves of this session, if enabled. Defaults to 60.
    * **autosave_notify**? `boolean`\
      Trigger a notification when autosaving this session. Defaults to true.
    * **on_attach**? [`finni.core.Session.AttachHook`](<#finni.core.Session.AttachHook>)\
      A function that's called when attaching to this session. No global default.
    * **on_detach**? [`finni.core.Session.DetachHook`](<#finni.core.Session.DetachHook>)\
      A function that's called when detaching from this session. No global default.
    * **options**? `string[]`\
      Save and restore these Neovim (global|buffer|tab|window) options.
    * **buf_filter**? [`finni.BufFilter`](<#finni.BufFilter>)\
      Function that decides whether a buffer should be included in a snapshot.
    * **tab_buf_filter**? [`finni.TabBufFilter`](<#finni.TabBufFilter>)\
      Function that decides whether a buffer should be included in a tab-scoped snapshot.
      `buf_filter` is called first, this is to refine acceptable buffers only.
    * **modified**? `(boolean|"auto")`\
      Save/load modified buffers and their undo history.
      If set to `auto` (default), does not save, but still restores modified buffers.
    * **jumps**? `boolean`\
      Save/load window-specific jumplists, including current position
      (yes, for **all windows**, not just the active one like with ShaDa).
      If set to `auto` (default), does not save, but still restores saved jumplists.
    * **changelist**? `boolean`\
      Save/load buffer-specific changelist (all buffers) and
      changelist position (visible buffers only).

      **Important**: Enabling this causes **buffer-local marks to be cleared** during restoration.
      Consider tracking `local_marks` in addition to this.
    * **global_marks**? `boolean`\
      Save/load global marks (A-Z, not 0-9 currently).

      _Only in global sessions._
    * **local_marks**? `boolean`\
      Save/load buffer-specific (local) marks.

      **Note**: Enable this if you track the `changelist`.
    * **search_history**? `(integer|boolean)`\
      Maximum number of search history items to persist. Defaults to false.
      If set to `true`, maps to the `'history'` option.

      _Only in global sessions._
    * **command_history**? `(integer|boolean)`\
      Maximum number of command history items to persist. Defaults to false.
      If set to `true`, maps to the `'history'` option.

      _Only in global sessions._
    * **input_history**? `(integer|boolean)`\
      Maximum number of input history items to persist. Defaults to false.
      If set to `true`, maps to the `'history'` option.

      _Only in global sessions._
    * **expr_history**? `boolean`\
      Persist expression history. Defaults to false.
      **Note**: Cannot set limit (currently), no direct support by neovim.

      _Only in global sessions._
    * **debug_history**? `boolean`\
      Persist debug history. Defaults to false.
      **Note**: Cannot set limit (currently), no direct support by neovim.

      _Only in global sessions._
    * **meta**? `table`\
      External data remembered in association with this session. Useful to build on top of the core API.
    * **attach**? `boolean`\
      Attach to/stay attached to session after operation
    * **save**? `boolean`\
      Save/override autosave config for affected sessions before the operation
    * **reset**? `(boolean|"auto")`\
      When detaching a session in the process, unload associated resources/reset
      everything during the operation when restoring a snapshot.
      `auto` resets only for global sessions.
    * **silence_errors**? `boolean`\
      Don't error during this operation

</details>

<a id="finni.auto.switch()"></a>
<details>
  <summary>

#### switch(`session`, `project`, `opts`)

  </summary>

Load an existing autosession by project name and session name.
Note: This can fail, e.g. when an autosession is associated
with a git branch and the worktree has checked out
a different one.

**Parameters:**
  * **session** `string`\
    Name of the session to load

  * **project**? `string`\
    Name of the project. If unspecified, defaults to current one

  * **opts**? [`finni.auto.LoadOpts`](<#finni.auto.LoadOpts>)

    Table fields:

    * **autosave_enabled**? `boolean`\
      When this session is attached, automatically save it in intervals. Defaults to false.
    * **autosave_interval**? `integer`\
      Seconds between autosaves of this session, if enabled. Defaults to 60.
    * **autosave_notify**? `boolean`\
      Trigger a notification when autosaving this session. Defaults to true.
    * **on_attach**? [`finni.core.Session.AttachHook`](<#finni.core.Session.AttachHook>)\
      A function that's called when attaching to this session. No global default.
    * **on_detach**? [`finni.core.Session.DetachHook`](<#finni.core.Session.DetachHook>)\
      A function that's called when detaching from this session. No global default.
    * **options**? `string[]`\
      Save and restore these Neovim (global|buffer|tab|window) options.
    * **buf_filter**? [`finni.BufFilter`](<#finni.BufFilter>)\
      Function that decides whether a buffer should be included in a snapshot.
    * **tab_buf_filter**? [`finni.TabBufFilter`](<#finni.TabBufFilter>)\
      Function that decides whether a buffer should be included in a tab-scoped snapshot.
      `buf_filter` is called first, this is to refine acceptable buffers only.
    * **modified**? `(boolean|"auto")`\
      Save/load modified buffers and their undo history.
      If set to `auto` (default), does not save, but still restores modified buffers.
    * **jumps**? `boolean`\
      Save/load window-specific jumplists, including current position
      (yes, for **all windows**, not just the active one like with ShaDa).
      If set to `auto` (default), does not save, but still restores saved jumplists.
    * **changelist**? `boolean`\
      Save/load buffer-specific changelist (all buffers) and
      changelist position (visible buffers only).

      **Important**: Enabling this causes **buffer-local marks to be cleared** during restoration.
      Consider tracking `local_marks` in addition to this.
    * **global_marks**? `boolean`\
      Save/load global marks (A-Z, not 0-9 currently).

      _Only in global sessions._
    * **local_marks**? `boolean`\
      Save/load buffer-specific (local) marks.

      **Note**: Enable this if you track the `changelist`.
    * **search_history**? `(integer|boolean)`\
      Maximum number of search history items to persist. Defaults to false.
      If set to `true`, maps to the `'history'` option.

      _Only in global sessions._
    * **command_history**? `(integer|boolean)`\
      Maximum number of command history items to persist. Defaults to false.
      If set to `true`, maps to the `'history'` option.

      _Only in global sessions._
    * **input_history**? `(integer|boolean)`\
      Maximum number of input history items to persist. Defaults to false.
      If set to `true`, maps to the `'history'` option.

      _Only in global sessions._
    * **expr_history**? `boolean`\
      Persist expression history. Defaults to false.
      **Note**: Cannot set limit (currently), no direct support by neovim.

      _Only in global sessions._
    * **debug_history**? `boolean`\
      Persist debug history. Defaults to false.
      **Note**: Cannot set limit (currently), no direct support by neovim.

      _Only in global sessions._
    * **meta**? `table`\
      External data remembered in association with this session. Useful to build on top of the core API.
    * **attach**? `boolean`\
      Attach to/stay attached to session after operation
    * **save**? `boolean`\
      Save/override autosave config for affected sessions before the operation
    * **reset**? `(boolean|"auto")`\
      When detaching a session in the process, unload associated resources/reset
      everything during the operation when restoring a snapshot.
      `auto` resets only for global sessions.
    * **silence_errors**? `boolean`\
      Don't error during this operation

</details>

<a id="finni.auto.reload()"></a>
<details>
  <summary>

#### reload()

  </summary>

If an autosession is active, save it and detach.
Then try to start a new one.

</details>

<a id="finni.auto.start()"></a>
<details>
  <summary>

#### start(`cwd`, `opts`)

  </summary>

Start Finni:
1. If the current working directory has an associated project and session,
   closes everything and loads that session.
2. In any case, start monitoring for directory or branch changes.

**Parameters:**
  * **cwd**? `string`\
    Working directory to switch to before starting autosession. Defaults to nvim's process' cwd.

  * **opts**? [`finni.auto.LoadOpts`](<#finni.auto.LoadOpts>)

    Table fields:

    * **autosave_enabled**? `boolean`\
      When this session is attached, automatically save it in intervals. Defaults to false.
    * **autosave_interval**? `integer`\
      Seconds between autosaves of this session, if enabled. Defaults to 60.
    * **autosave_notify**? `boolean`\
      Trigger a notification when autosaving this session. Defaults to true.
    * **on_attach**? [`finni.core.Session.AttachHook`](<#finni.core.Session.AttachHook>)\
      A function that's called when attaching to this session. No global default.
    * **on_detach**? [`finni.core.Session.DetachHook`](<#finni.core.Session.DetachHook>)\
      A function that's called when detaching from this session. No global default.
    * **options**? `string[]`\
      Save and restore these Neovim (global|buffer|tab|window) options.
    * **buf_filter**? [`finni.BufFilter`](<#finni.BufFilter>)\
      Function that decides whether a buffer should be included in a snapshot.
    * **tab_buf_filter**? [`finni.TabBufFilter`](<#finni.TabBufFilter>)\
      Function that decides whether a buffer should be included in a tab-scoped snapshot.
      `buf_filter` is called first, this is to refine acceptable buffers only.
    * **modified**? `(boolean|"auto")`\
      Save/load modified buffers and their undo history.
      If set to `auto` (default), does not save, but still restores modified buffers.
    * **jumps**? `boolean`\
      Save/load window-specific jumplists, including current position
      (yes, for **all windows**, not just the active one like with ShaDa).
      If set to `auto` (default), does not save, but still restores saved jumplists.
    * **changelist**? `boolean`\
      Save/load buffer-specific changelist (all buffers) and
      changelist position (visible buffers only).

      **Important**: Enabling this causes **buffer-local marks to be cleared** during restoration.
      Consider tracking `local_marks` in addition to this.
    * **global_marks**? `boolean`\
      Save/load global marks (A-Z, not 0-9 currently).

      _Only in global sessions._
    * **local_marks**? `boolean`\
      Save/load buffer-specific (local) marks.

      **Note**: Enable this if you track the `changelist`.
    * **search_history**? `(integer|boolean)`\
      Maximum number of search history items to persist. Defaults to false.
      If set to `true`, maps to the `'history'` option.

      _Only in global sessions._
    * **command_history**? `(integer|boolean)`\
      Maximum number of command history items to persist. Defaults to false.
      If set to `true`, maps to the `'history'` option.

      _Only in global sessions._
    * **input_history**? `(integer|boolean)`\
      Maximum number of input history items to persist. Defaults to false.
      If set to `true`, maps to the `'history'` option.

      _Only in global sessions._
    * **expr_history**? `boolean`\
      Persist expression history. Defaults to false.
      **Note**: Cannot set limit (currently), no direct support by neovim.

      _Only in global sessions._
    * **debug_history**? `boolean`\
      Persist debug history. Defaults to false.
      **Note**: Cannot set limit (currently), no direct support by neovim.

      _Only in global sessions._
    * **meta**? `table`\
      External data remembered in association with this session. Useful to build on top of the core API.
    * **attach**? `boolean`\
      Attach to/stay attached to session after operation
    * **save**? `boolean`\
      Save/override autosave config for affected sessions before the operation
    * **reset**? `(boolean|"auto")`\
      When detaching a session in the process, unload associated resources/reset
      everything during the operation when restoring a snapshot.
      `auto` resets only for global sessions.
    * **silence_errors**? `boolean`\
      Don't error during this operation

</details>

<a id="finni.auto.stop()"></a>
<details>
  <summary>

#### stop()

  </summary>

Stop Finni:
1. If we're inside an active autosession, save it and detach.
   Keep buffers/windows/tabs etc. by default.
2. In any case, stop monitoring for directory or branch changes.

</details>

<a id="finni.auto.delete()"></a>
<details>
  <summary>

#### delete(`session`, `project`, `opts`)

  </summary>

Delete a specific autosession.

**Parameters:**
  * **session** `string`\
    Session to delete

  * **project**? `string`\
    Project name of session to delete. If unspecified, defaults to current one.

  * **opts**? `(`[`finni.SideEffects.Notify`](<#finni.SideEffects.Notify>)` & `[`finni.SideEffects.SilenceErrors`](<#finni.SideEffects.SilenceErrors>)`)`

    Table fields:

    * **notify**? `boolean`\
      Notify on success
    * **silence_errors**? `boolean`\
      Don't error during this operation

</details>

<a id="finni.auto.reset()"></a>
<details>
  <summary>

#### reset(`opts`)

  </summary>

Delete the currently active autosession. Close **everything**.
Attempt to start a new autosession (optionally).

**Parameters:**
  * **opts**? [`finni.auto.ResetOpts`](<#finni.auto.ResetOpts>)

    Table fields:

    * **silence_errors**? `boolean`\
      Don't error during this operation
    * **reset**? `boolean`\
      When detaching a session in the process, unload associated resources/reset
      everything during the operation when restoring a snapshot.
    * **notify**? `boolean`\
      Notify on success
    * **cwd**? `(string|true)`\
      Path to a directory associated with the session to reset
      instead of current one. Set this to `true` to use nvim's current global CWD.
    * **reload**? `boolean`\
      Attempt to restart a new autosession after reset. Defaults to true.

</details>

<a id="finni.auto.current_project()"></a>
<details>
  <summary>

#### current_project()

  </summary>

Get the name of the currently active project.

**Returns:** `string?`

</details>

<a id="finni.auto.reset_project()"></a>
<details>
  <summary>

#### reset_project(`opts`)

  </summary>

Remove all autosessions associated with a project.
If the target is the active project, reset current session as well and close **everything**.

**Parameters:**
  * **opts**? [`finni.auto.ResetProjectOpts`](<#finni.auto.ResetProjectOpts>)

    Table fields:

    * **notify**? `boolean`\
      Notify on success
    * **name**? `string`\
      Specify the project to reset. If unspecified, resets active project, if available.
    * **force**? `boolean`\
      Force recursive deletion of project dir outside of configured root

</details>

<a id="finni.auto.list()"></a>
<details>
  <summary>

#### list(`opts`)

  </summary>

List autosessions associated with a project.

**Parameters:**
  * **opts**? [`finni.auto.ListOpts`](<#finni.auto.ListOpts>)\
    Specify the project to list.
    If unspecified, lists active project, if available.

    Table fields:

    * **cwd**? `string`\
      Path to a directory associated with the project to list
    * **project_dir**? `string`\
      Path to the project session dir
    * **project_name**? `string`\
      Name of the project

**Returns:** **session_names** `string[]`\
List of known sessions associated with project

</details>

<a id="finni.auto.list_projects()"></a>
<details>
  <summary>

#### list_projects(`opts`)

  </summary>

List all known projects.

**Overloads:**
  * `fun() -> string[]`
  * `fun(opts: { with_sessions: true }) -> table<string,string[]>`

**Parameters:**
  * **opts**? [`finni.auto.ListProjectOpts`](<#finni.auto.ListProjectOpts>)

    Table fields:

    * **with_sessions**? `boolean`\
      Additionally list all known sessions for each listed project. Defaults to false.

**Returns:** `(string[]|table<string,string[]>)`

</details>

<a id="finni.auto.migrate_projects()"></a>
<details>
  <summary>

#### migrate_projects(`opts`)

  </summary>

Dev helper currently (beware: unstable/inefficient).
When changing the mapping from workspace to project name, all previously
saved states would be lost. This tries to migrate state data to the new mapping,
cleans projects whose cwd does not exist anymore or which are disabled
Caution! This does not account for projects with multiple associated directories/sessions!
Checks the first session's cwd/enabled state only!

**Parameters:**
  * **opts**? [`finni.auto.MigrateProjectsOpts`](<#finni.auto.MigrateProjectsOpts>)\
    Options for migration. You need to pass `{dry_run = false}`
    for this function to have an effect.

    Table fields:

    * **dry_run**? `boolean`\
      Don't execute the migration, only show what would have happened.
      Defaults to true, meaning you need to explicitly set this to `false` to have an effect.
    * **old_root**? `string`\
      If the value of `autosession.dir` has changed, the old value.
      Defaults to `autosession.dir`.

**Returns:** **migration_result** `table<("broken"|"missing"|"skipped"|"migrated"...),table[]>`

</details>

<a id="finni.auto.info()"></a>
<details>
  <summary>

#### info(`opts`)

  </summary>

Return information about the currently active session.
Includes autosession information, if it is an autosession.

**Parameters:**
  * **opts**? `{ with_snapshot: boolean? }`

    Table fields:

    * **with_snapshot**? `boolean`

**Returns:** **active_info**? [`finni.auto.ActiveAutosessionInfo`](<#finni.auto.ActiveAutosessionInfo>)\
Information about the active session, even if not an autosession.
Always includes snapshot configuration, session meta config and
whether it is an autosession. For autosessions, also includes
autosession config.

</details>


<a id="finni-extensions"></a>
## 🧩 Extensions

<a id="finni-extensions-built-in"></a>
### Built-in
* **quickfix**:

  Persist all quickfix lists, currently active list, active position in list and quickfix window.

* **colorscheme**:

  Persist color scheme.

* [**dap**](https://github.com/mfussenegger/nvim-dap):

  Persist nvim-dap breakpoints.

* [**neogit**](https://github.com/NeogitOrg/neogit):

  Persist Neogit status and commit views.

* [**oil**](https://github.com/stevearc/oil.nvim):

  Persist Oil windows.

  Note: Customized from the one embedded in `oil.nvim` to correctly restore view.

<a id="finni-extensions-external"></a>
### External
Here are some examples of external extensions:

* [**aerial.nvim**](https://github.com/stevearc/aerial.nvim):

  Note: For Resession, which is compatible with Finni.

* [**overseer.nvim**](https://github.com/stevearc/overseer.nvim):

  Note: For Resession, which is compatible with Finni.

<a id="finni-faq"></a>
## ❓ FAQ
**Q: Why another session plugin?**

A1: All the other plugins (with the exception of `resession.nvim`)
    use `:mksession` under the hood
A2: Resession cannot be bent enough via its interface to support everything
    Finni does. Its API is difficult to build another plugin on top of
    (e.g. cannot get session table without Resession saving it to a file
    first).

**Q: Why don't you want to use `:mksession`?**

A: While it's amazing that this feature is built-in to vim, and it does an
   impressively good job for most situations, it is very difficult to
   customize. If `'sessionoptions'` covers your use case, then you're
   golden. If you want anything else, you're out of luck.

**Q: Why `Finni`?**

A: One might assume the name of this plugin is a word play on the French
   "c'est fini" or a contraction of "fin" (French: end) and either "nie"
   (German: never) or even the "Ni!" by the "Knights Who Say 'Ni!'",
   for some reason.

   But one would be mistaken.

   This plugin is dedicated to one of the loveliest creatures that ever
   walked our Earth, my little kind-hearted and trustful to a fault
   sweetie Finni. ❤️

   You lived a long life (for a hamster...) and were the best boy
   until the end. I will miss you, your curiosity and your unwavering
   will dearly, my little Finni.

   Like your namesake plugin allows Neovim sessions to, may your memory
   live on forever.

<a id="finni-type-reference"></a>
## Type Reference


<a id="finni.auto.ActiveAutosessionInfo"></a>
### `finni.auto.ActiveAutosessionInfo` (Class)

**Fields:**

* **session_file** `string`\
  Path to the session file
* **state_dir** `string`\
  Path to the directory holding session-associated data
* **context_dir** `string`\
  Directory for shared state between all sessions in the same context
  (`dir` for manual sessions, project dir for autosessions)
* **autosave_enabled** `boolean`\
  When this session is attached, automatically save it in intervals. Defaults to false.
* **autosave_interval** `integer`\
  Seconds between autosaves of this session, if enabled. Defaults to 60.
* **name** `string`\
  Name of the session
* **tab_scoped** `boolean`\
  Whether the session is tab-scoped
* **is_autosession** `boolean`\
  Whether this is an autosession or a manual one
* **autosave_notify**? `boolean`\
  Trigger a notification when autosaving this session. Defaults to true.
* **on_attach**? [`finni.core.Session.AttachHook`](<#finni.core.Session.AttachHook>)\
  A function that's called when attaching to this session. No global default.
* **on_detach**? [`finni.core.Session.DetachHook`](<#finni.core.Session.DetachHook>)\
  A function that's called when detaching from this session. No global default.
* **meta**? `table`\
  External data remembered in association with this session. Useful to build on top of the core API.
* **options**? `string[]`\
  Save and restore these Neovim (global|buffer|tab|window) options.
* **buf_filter**? [`finni.BufFilter`](<#finni.BufFilter>)\
  Function that decides whether a buffer should be included in a snapshot.
* **tab_buf_filter**? [`finni.TabBufFilter`](<#finni.TabBufFilter>)\
  Function that decides whether a buffer should be included in a tab-scoped snapshot.
  `buf_filter` is called first, this is to refine acceptable buffers only.
* **modified**? `(boolean|"auto")`\
  Save/load modified buffers and their undo history.
  If set to `auto` (default), does not save, but still restores modified buffers.
* **jumps**? `boolean`\
  Save/load window-specific jumplists, including current position
  (yes, for **all windows**, not just the active one like with ShaDa).
  If set to `auto` (default), does not save, but still restores saved jumplists.
* **changelist**? `boolean`\
  Save/load buffer-specific changelist (all buffers) and
  changelist position (visible buffers only).

  **Important**: Enabling this causes **buffer-local marks to be cleared** during restoration.
  Consider tracking `local_marks` in addition to this.
* **global_marks**? `boolean`\
  Save/load global marks (A-Z, not 0-9 currently).

  _Only in global sessions._
* **local_marks**? `boolean`\
  Save/load buffer-specific (local) marks.

  **Note**: Enable this if you track the `changelist`.
* **search_history**? `(integer|boolean)`\
  Maximum number of search history items to persist. Defaults to false.
  If set to `true`, maps to the `'history'` option.

  _Only in global sessions._
* **command_history**? `(integer|boolean)`\
  Maximum number of command history items to persist. Defaults to false.
  If set to `true`, maps to the `'history'` option.

  _Only in global sessions._
* **input_history**? `(integer|boolean)`\
  Maximum number of input history items to persist. Defaults to false.
  If set to `true`, maps to the `'history'` option.

  _Only in global sessions._
* **expr_history**? `boolean`\
  Persist expression history. Defaults to false.
  **Note**: Cannot set limit (currently), no direct support by neovim.

  _Only in global sessions._
* **debug_history**? `boolean`\
  Persist debug history. Defaults to false.
  **Note**: Cannot set limit (currently), no direct support by neovim.

  _Only in global sessions._
* **tabid**? `(`[`finni.core.TabID`](<#finni.core.TabID>)`|true)`\
  Tab number the session is attached to, if any. Can be `true`, which indicates it's a
  tab-scoped session that has not been restored yet - although not when requesting via the API
* **autosession_config**? [`finni.auto.AutosessionContext`](<#finni.auto.AutosessionContext>)\
  When this is an autosession, the internal configuration that was rendered.

  Table fields:

  * **project** [`finni.auto.AutosessionConfig.ProjectInfo`](<#finni.auto.AutosessionConfig.ProjectInfo>)
  * **root** `string`\
    The top level directory for this session (workspace root).
    Usually equals the project root, but can be different when git worktrees are used.
  * **name** `string`\
    The name of the session
  * **config** [`finni.auto.LoadOpts`](<#finni.auto.LoadOpts>)\
    Session-specific load/autosave options.
  * **cwd** `string`\
    The effective working directory that was determined when loading this auto-session
* **autosession_data**? [`finni.core.Snapshot`](<#finni.core.Snapshot>)\
  The most recent snapshotted state of this named autosession

  Table fields:

  * **buffers** [`finni.core.Snapshot.BufData`](<#finni.core.Snapshot.BufData>)`[]`\
    Buffer-specific data like name, buffer options, local marks, changelist
  * **tabs** [`finni.core.Snapshot.TabData`](<#finni.core.Snapshot.TabData>)`[]`\
    Tab-specific and window layout data, including tab cwd and window-specific jumplists
  * **tab_scoped** `boolean`\
    Whether this snapshot was derived from a single tab
  * **global** [`finni.core.Snapshot.GlobalData`](<#finni.core.Snapshot.GlobalData>)\
    Global snapshot data like process CWD, global options and global marks
  * **modified**? `table<`[`finni.core.BufUUID`](<#finni.core.BufUUID>)`,true?>`\
    List of buffers (identified by internal UUID) whose unsaved modifications
    were backed up in the snapshot
  * **buflist** `string[]`\
    List of named buffers that are referenced somewhere in this snapshot.
    Used to reduce repetition of buffer paths in save file, especially lists of named marks
    (jumplist, quickfix and location lists).

<a id="finni.auto.AutosessionConfig.ProjectInfo"></a>
### `finni.auto.AutosessionConfig.ProjectInfo` (Class)

**Fields:**

* **data_dir** `string`\
  The path of the directory that is used to save autosession data related to this project.
* **name** `string`\
  The name of the project
* **repo**? [`finni.auto.AutosessionSpec.GitInfo`](<#finni.auto.AutosessionSpec.GitInfo>)\
  When the project is defined as a git repository, meta info

  Table fields:

  * **commongitdir** `string`\
    The common git dir, usually equal to gitdir, unless the worktree is not the default workdir
    (e.g. in worktree checkuots of bare repos).
    Then it's the actual repo root and gitdir is <git_common_dir>/worktrees/<worktree_name>
  * **gitdir** `string`\
    The repository (or worktree) data path
  * **toplevel** `string`\
    The path of the checked out worktree
  * **branch**? `string`\
    The branch the worktree has checked out
  * **default_branch**? `string`\
    The name of the default branch

<a id="finni.auto.AutosessionContext"></a>
### `finni.auto.AutosessionContext` (Class)

**Fields:**

* **project** [`finni.auto.AutosessionConfig.ProjectInfo`](<#finni.auto.AutosessionConfig.ProjectInfo>)

  Table fields:

  * **data_dir** `string`\
    The path of the directory that is used to save autosession data related to this project.
  * **name** `string`\
    The name of the project
  * **repo**? [`finni.auto.AutosessionSpec.GitInfo`](<#finni.auto.AutosessionSpec.GitInfo>)\
    When the project is defined as a git repository, meta info
* **root** `string`\
  The top level directory for this session (workspace root).
  Usually equals the project root, but can be different when git worktrees are used.
* **name** `string`\
  The name of the session
* **config** [`finni.auto.LoadOpts`](<#finni.auto.LoadOpts>)\
  Session-specific load/autosave options.

  Table fields:

  * **autosave_enabled**? `boolean`\
    When this session is attached, automatically save it in intervals. Defaults to false.
  * **autosave_interval**? `integer`\
    Seconds between autosaves of this session, if enabled. Defaults to 60.
  * **autosave_notify**? `boolean`\
    Trigger a notification when autosaving this session. Defaults to true.
  * **on_attach**? [`finni.core.Session.AttachHook`](<#finni.core.Session.AttachHook>)\
    A function that's called when attaching to this session. No global default.
  * **on_detach**? [`finni.core.Session.DetachHook`](<#finni.core.Session.DetachHook>)\
    A function that's called when detaching from this session. No global default.
  * **options**? `string[]`\
    Save and restore these Neovim (global|buffer|tab|window) options.
  * **buf_filter**? [`finni.BufFilter`](<#finni.BufFilter>)\
    Function that decides whether a buffer should be included in a snapshot.
  * **tab_buf_filter**? [`finni.TabBufFilter`](<#finni.TabBufFilter>)\
    Function that decides whether a buffer should be included in a tab-scoped snapshot.
    `buf_filter` is called first, this is to refine acceptable buffers only.
  * **modified**? `(boolean|"auto")`\
    Save/load modified buffers and their undo history.
    If set to `auto` (default), does not save, but still restores modified buffers.
  * **jumps**? `boolean`\
    Save/load window-specific jumplists, including current position
    (yes, for **all windows**, not just the active one like with ShaDa).
    If set to `auto` (default), does not save, but still restores saved jumplists.
  * **changelist**? `boolean`\
    Save/load buffer-specific changelist (all buffers) and
    changelist position (visible buffers only).

    **Important**: Enabling this causes **buffer-local marks to be cleared** during restoration.
    Consider tracking `local_marks` in addition to this.
  * **global_marks**? `boolean`\
    Save/load global marks (A-Z, not 0-9 currently).

    _Only in global sessions._
  * **local_marks**? `boolean`\
    Save/load buffer-specific (local) marks.

    **Note**: Enable this if you track the `changelist`.
  * **search_history**? `(integer|boolean)`\
    Maximum number of search history items to persist. Defaults to false.
    If set to `true`, maps to the `'history'` option.

    _Only in global sessions._
  * **command_history**? `(integer|boolean)`\
    Maximum number of command history items to persist. Defaults to false.
    If set to `true`, maps to the `'history'` option.

    _Only in global sessions._
  * **input_history**? `(integer|boolean)`\
    Maximum number of input history items to persist. Defaults to false.
    If set to `true`, maps to the `'history'` option.

    _Only in global sessions._
  * **expr_history**? `boolean`\
    Persist expression history. Defaults to false.
    **Note**: Cannot set limit (currently), no direct support by neovim.

    _Only in global sessions._
  * **debug_history**? `boolean`\
    Persist debug history. Defaults to false.
    **Note**: Cannot set limit (currently), no direct support by neovim.

    _Only in global sessions._
  * **meta**? `table`\
    External data remembered in association with this session. Useful to build on top of the core API.
  * **attach**? `boolean`\
    Attach to/stay attached to session after operation
  * **save**? `boolean`\
    Save/override autosave config for affected sessions before the operation
  * **reset**? `(boolean|"auto")`\
    When detaching a session in the process, unload associated resources/reset
    everything during the operation when restoring a snapshot.
    `auto` resets only for global sessions.
  * **silence_errors**? `boolean`\
    Don't error during this operation
* **cwd** `string`\
  The effective working directory that was determined when loading this auto-session

<a id="finni.auto.AutosessionSpec.GitInfo"></a>
### `finni.auto.AutosessionSpec.GitInfo` (Class)

Information about a Git repository that is associated with a project.

**Fields:**

* **commongitdir** `string`\
  The common git dir, usually equal to gitdir, unless the worktree is not the default workdir
  (e.g. in worktree checkuots of bare repos).
  Then it's the actual repo root and gitdir is <git_common_dir>/worktrees/<worktree_name>
* **gitdir** `string`\
  The repository (or worktree) data path
* **toplevel** `string`\
  The path of the checked out worktree
* **branch**? `string`\
  The branch the worktree has checked out
* **default_branch**? `string`\
  The name of the default branch

<a id="finni.auto.EnabledHook"></a>
### `finni.auto.EnabledHook` (Alias)

**Type:** `fun(meta: { cwd: string, project_name: string, session_name: string, workspace: string }) -> boolean`

Function that decides whether an autosession should be processed further.
Receives output of WorkspaceHook, ProjectNameHook and SessionNameHook.


<a id="finni.auto.ListOpts"></a>
### `finni.auto.ListOpts` (Class)

Options for listing autosessions in a project.
`cwd`, `project_dir` and `project_name` are different ways of referencing
a project and only one of them is respected.

**Fields:**

* **cwd**? `string`\
  Path to a directory associated with the project to list
* **project_dir**? `string`\
  Path to the project session dir
* **project_name**? `string`\
  Name of the project

<a id="finni.auto.ListProjectOpts"></a>
### `finni.auto.ListProjectOpts` (Class)

**Fields:**

* **with_sessions**? `boolean`\
  Additionally list all known sessions for each listed project. Defaults to false.

<a id="finni.auto.LoadOpts"></a>
### `finni.auto.LoadOpts` (Alias)

**Type:** `(`[`finni.core.Session.InitOptsWithMeta`](<#finni.core.Session.InitOptsWithMeta>)` & `[`finni.SideEffects.Attach`](<#finni.SideEffects.Attach>)` & `[`finni.SideEffects.Save`](<#finni.SideEffects.Save>)` & `[`finni.SideEffects.ResetAuto`](<#finni.SideEffects.ResetAuto>)` & `[`finni.SideEffects.SilenceErrors`](<#finni.SideEffects.SilenceErrors>)` & `[`finni.core.PassthroughOpts`](<#finni.core.PassthroughOpts>)`)`

API options for `auto.load`

**Fields:**

* **autosave_enabled**? `boolean`\
  When this session is attached, automatically save it in intervals. Defaults to false.
* **autosave_interval**? `integer`\
  Seconds between autosaves of this session, if enabled. Defaults to 60.
* **autosave_notify**? `boolean`\
  Trigger a notification when autosaving this session. Defaults to true.
* **on_attach**? [`finni.core.Session.AttachHook`](<#finni.core.Session.AttachHook>)\
  A function that's called when attaching to this session. No global default.
* **on_detach**? [`finni.core.Session.DetachHook`](<#finni.core.Session.DetachHook>)\
  A function that's called when detaching from this session. No global default.
* **options**? `string[]`\
  Save and restore these Neovim (global|buffer|tab|window) options.
* **buf_filter**? [`finni.BufFilter`](<#finni.BufFilter>)\
  Function that decides whether a buffer should be included in a snapshot.
* **tab_buf_filter**? [`finni.TabBufFilter`](<#finni.TabBufFilter>)\
  Function that decides whether a buffer should be included in a tab-scoped snapshot.
  `buf_filter` is called first, this is to refine acceptable buffers only.
* **modified**? `(boolean|"auto")`\
  Save/load modified buffers and their undo history.
  If set to `auto` (default), does not save, but still restores modified buffers.
* **jumps**? `boolean`\
  Save/load window-specific jumplists, including current position
  (yes, for **all windows**, not just the active one like with ShaDa).
  If set to `auto` (default), does not save, but still restores saved jumplists.
* **changelist**? `boolean`\
  Save/load buffer-specific changelist (all buffers) and
  changelist position (visible buffers only).

  **Important**: Enabling this causes **buffer-local marks to be cleared** during restoration.
  Consider tracking `local_marks` in addition to this.
* **global_marks**? `boolean`\
  Save/load global marks (A-Z, not 0-9 currently).

  _Only in global sessions._
* **local_marks**? `boolean`\
  Save/load buffer-specific (local) marks.

  **Note**: Enable this if you track the `changelist`.
* **search_history**? `(integer|boolean)`\
  Maximum number of search history items to persist. Defaults to false.
  If set to `true`, maps to the `'history'` option.

  _Only in global sessions._
* **command_history**? `(integer|boolean)`\
  Maximum number of command history items to persist. Defaults to false.
  If set to `true`, maps to the `'history'` option.

  _Only in global sessions._
* **input_history**? `(integer|boolean)`\
  Maximum number of input history items to persist. Defaults to false.
  If set to `true`, maps to the `'history'` option.

  _Only in global sessions._
* **expr_history**? `boolean`\
  Persist expression history. Defaults to false.
  **Note**: Cannot set limit (currently), no direct support by neovim.

  _Only in global sessions._
* **debug_history**? `boolean`\
  Persist debug history. Defaults to false.
  **Note**: Cannot set limit (currently), no direct support by neovim.

  _Only in global sessions._
* **meta**? `table`\
  External data remembered in association with this session. Useful to build on top of the core API.
* **attach**? `boolean`\
  Attach to/stay attached to session after operation
* **save**? `boolean`\
  Save/override autosave config for affected sessions before the operation
* **reset**? `(boolean|"auto")`\
  When detaching a session in the process, unload associated resources/reset
  everything during the operation when restoring a snapshot.
  `auto` resets only for global sessions.
* **silence_errors**? `boolean`\
  Don't error during this operation


<a id="finni.auto.LoadOptsHook"></a>
### `finni.auto.LoadOptsHook` (Alias)

**Type:** `fun(meta: { cwd: string, project_name: string, session_name: string, workspace: string }) -> auto.LoadOpts?`

Function that can return autosession-specific load option overrides.
Receives output of WorkspaceHook, ProjectNameHook and SessionNameHook.


<a id="finni.auto.MigrateProjectsOpts"></a>
### `finni.auto.MigrateProjectsOpts` (Class)

**Fields:**

* **dry_run**? `boolean`\
  Don't execute the migration, only show what would have happened.
  Defaults to true, meaning you need to explicitly set this to `false` to have an effect.
* **old_root**? `string`\
  If the value of `autosession.dir` has changed, the old value.
  Defaults to `autosession.dir`.

<a id="finni.auto.ProjectNameHook"></a>
### `finni.auto.ProjectNameHook` (Alias)

**Type:** `fun(workspace: string, git_info: auto.AutosessionSpec.GitInfo?) -> string`

Function that derives the project name from output of WorkspaceHook.


<a id="finni.auto.ResetOpts"></a>
### `finni.auto.ResetOpts` (Class)

API options for `auto.reset`

**Fields:**

* **silence_errors**? `boolean`\
  Don't error during this operation
* **reset**? `boolean`\
  When detaching a session in the process, unload associated resources/reset
  everything during the operation when restoring a snapshot.
* **notify**? `boolean`\
  Notify on success
* **cwd**? `(string|true)`\
  Path to a directory associated with the session to reset
  instead of current one. Set this to `true` to use nvim's current global CWD.
* **reload**? `boolean`\
  Attempt to restart a new autosession after reset. Defaults to true.

<a id="finni.auto.ResetProjectOpts"></a>
### `finni.auto.ResetProjectOpts` (Class)

**Fields:**

* **notify**? `boolean`\
  Notify on success
* **name**? `string`\
  Specify the project to reset. If unspecified, resets active project, if available.
* **force**? `boolean`\
  Force recursive deletion of project dir outside of configured root

<a id="finni.auto.SaveOpts"></a>
### `finni.auto.SaveOpts` (Alias)

**Type:** `(`[`finni.SideEffects.Attach`](<#finni.SideEffects.Attach>)` & `[`finni.SideEffects.Notify`](<#finni.SideEffects.Notify>)` & `[`finni.SideEffects.Reset`](<#finni.SideEffects.Reset>)`)`

API options for `auto.save`

**Fields:**

* **attach**? `boolean`\
  Attach to/stay attached to session after operation
* **notify**? `boolean`\
  Notify on success
* **reset**? `boolean`\
  When detaching a session in the process, unload associated resources/reset
  everything during the operation when restoring a snapshot.


<a id="finni.auto.SessionNameHook"></a>
### `finni.auto.SessionNameHook` (Alias)

**Type:** `fun(meta: { cwd: string, git_info: auto.AutosessionSpec.GitInfo?, project_name: string, workspace: string }) -> string`

Function that derives the session name from output of WorkspaceHook and ProjectNameHook.


<a id="finni.auto.SpecHook"></a>
### `finni.auto.SpecHook` (Alias)

**Type:** `fun(cwd: string) -> auto.AutosessionSpec?`

Function that derives autosession configuration from a path.
The default implementation calls into all other autosession hooks
that can be overridden in the config.


<a id="finni.auto.WorkspaceHook"></a>
### `finni.auto.WorkspaceHook` (Alias)

**Type:** `fun(cwd: string) -> (string,boolean)`

Function that derives workspace root and git-tracked status from a path.


<a id="finni.BufFilter"></a>
### `finni.BufFilter` (Alias)

**Type:** `fun(bufnr: integer, opts: `[`finni.core.snapshot.CreateOpts`](<#finni.core.snapshot.CreateOpts>)`) -> boolean`

Function that decides whether a buffer should be included in a snapshot.


<a id="finni.core.ActiveSession"></a>
### `finni.core.ActiveSession` (Class)

An active (attached) session.

**Fields:**

* **session_file** `string`\
  Path to the session file
* **state_dir** `string`\
  Path to the directory holding session-associated data
* **context_dir** `string`\
  Directory for shared state between all sessions in the same context
  (`dir` for manual sessions, project dir for autosessions)
* **autosave_enabled** `boolean`\
  Autosave this attached session in intervals and when detaching
* **autosave_interval** `integer`\
  Seconds between autosaves of this session, if enabled.
* **name** `string`
* **tab_scoped** `boolean`
* **autosave_notify**? `boolean`\
  Trigger a notification when autosaving this session. Defaults to true.
* **on_attach**? [`finni.core.Session.AttachHook`](<#finni.core.Session.AttachHook>)\
  A function that's called when attaching to this session. No global default.
* **on_detach**? [`finni.core.Session.DetachHook`](<#finni.core.Session.DetachHook>)\
  A function that's called when detaching from this session. No global default.
* **meta**? `table`\
  External data remembered in association with this session. Useful to build on top of the core API.
* **options**? `string[]`\
  Save and restore these Neovim (global|buffer|tab|window) options.
* **buf_filter**? [`finni.BufFilter`](<#finni.BufFilter>)\
  Function that decides whether a buffer should be included in a snapshot.
* **tab_buf_filter**? [`finni.TabBufFilter`](<#finni.TabBufFilter>)\
  Function that decides whether a buffer should be included in a tab-scoped snapshot.
  `buf_filter` is called first, this is to refine acceptable buffers only.
* **modified**? `(boolean|"auto")`\
  Save/load modified buffers and their undo history.
  If set to `auto` (default), does not save, but still restores modified buffers.
* **jumps**? `boolean`\
  Save/load window-specific jumplists, including current position
  (yes, for **all windows**, not just the active one like with ShaDa).
  If set to `auto` (default), does not save, but still restores saved jumplists.
* **changelist**? `boolean`\
  Save/load buffer-specific changelist (all buffers) and
  changelist position (visible buffers only).

  **Important**: Enabling this causes **buffer-local marks to be cleared** during restoration.
  Consider tracking `local_marks` in addition to this.
* **global_marks**? `boolean`\
  Save/load global marks (A-Z, not 0-9 currently).

  _Only in global sessions._
* **local_marks**? `boolean`\
  Save/load buffer-specific (local) marks.

  **Note**: Enable this if you track the `changelist`.
* **search_history**? `(integer|boolean)`\
  Maximum number of search history items to persist. Defaults to false.
  If set to `true`, maps to the `'history'` option.

  _Only in global sessions._
* **command_history**? `(integer|boolean)`\
  Maximum number of command history items to persist. Defaults to false.
  If set to `true`, maps to the `'history'` option.

  _Only in global sessions._
* **input_history**? `(integer|boolean)`\
  Maximum number of input history items to persist. Defaults to false.
  If set to `true`, maps to the `'history'` option.

  _Only in global sessions._
* **expr_history**? `boolean`\
  Persist expression history. Defaults to false.
  **Note**: Cannot set limit (currently), no direct support by neovim.

  _Only in global sessions._
* **debug_history**? `boolean`\
  Persist debug history. Defaults to false.
  **Note**: Cannot set limit (currently), no direct support by neovim.

  _Only in global sessions._
* **tabid**? [`finni.core.TabID`](<#finni.core.TabID>)
<a id="finni.core.ActiveSession.new()"></a>
<details>
  <summary>

#### new(`name`, `session_file`, `state_dir`, `context_dir`, `opts`, `tabid`, `needs_restore`)

  </summary>

**Parameters:**
  * **name** `string`

  * **session_file** `string`

  * **state_dir** `string`

  * **context_dir** `string`

  * **opts** [`finni.core.Session.InitOptsWithMeta`](<#finni.core.Session.InitOptsWithMeta>)

  * **tabid** `true`

  * **needs_restore** `true`


**Returns:** [`finni.core.PendingSession`](<#finni.core.PendingSession>)`<`[`finni.core.Session.TabTarget`](<#finni.core.Session.TabTarget>)`>`

</details>

<a id="finni.core.ActiveSession.from_snapshot()"></a>
<details>
  <summary>

#### from_snapshot(`name`, `session_file`, `state_dir`, `context_dir`, `opts`)

  </summary>

Create a new session by loading a snapshot, which you need to restore explicitly.

**Parameters:**
  * **name** `string`

  * **session_file** `string`

  * **state_dir** `string`

  * **context_dir** `string`

  * **opts** `(`[`finni.core.Session.InitOptsWithMeta`](<#finni.core.Session.InitOptsWithMeta>)` & `[`finni.SideEffects.SilenceErrors`](<#finni.SideEffects.SilenceErrors>)`)`

    Table fields:

    * **autosave_enabled**? `boolean`\
      When this session is attached, automatically save it in intervals. Defaults to false.
    * **autosave_interval**? `integer`\
      Seconds between autosaves of this session, if enabled. Defaults to 60.
    * **autosave_notify**? `boolean`\
      Trigger a notification when autosaving this session. Defaults to true.
    * **on_attach**? [`finni.core.Session.AttachHook`](<#finni.core.Session.AttachHook>)\
      A function that's called when attaching to this session. No global default.
    * **on_detach**? [`finni.core.Session.DetachHook`](<#finni.core.Session.DetachHook>)\
      A function that's called when detaching from this session. No global default.
    * **options**? `string[]`\
      Save and restore these Neovim (global|buffer|tab|window) options.
    * **buf_filter**? [`finni.BufFilter`](<#finni.BufFilter>)\
      Function that decides whether a buffer should be included in a snapshot.
    * **tab_buf_filter**? [`finni.TabBufFilter`](<#finni.TabBufFilter>)\
      Function that decides whether a buffer should be included in a tab-scoped snapshot.
      `buf_filter` is called first, this is to refine acceptable buffers only.
    * **modified**? `(boolean|"auto")`\
      Save/load modified buffers and their undo history.
      If set to `auto` (default), does not save, but still restores modified buffers.
    * **jumps**? `boolean`\
      Save/load window-specific jumplists, including current position
      (yes, for **all windows**, not just the active one like with ShaDa).
      If set to `auto` (default), does not save, but still restores saved jumplists.
    * **changelist**? `boolean`\
      Save/load buffer-specific changelist (all buffers) and
      changelist position (visible buffers only).

      **Important**: Enabling this causes **buffer-local marks to be cleared** during restoration.
      Consider tracking `local_marks` in addition to this.
    * **global_marks**? `boolean`\
      Save/load global marks (A-Z, not 0-9 currently).

      _Only in global sessions._
    * **local_marks**? `boolean`\
      Save/load buffer-specific (local) marks.

      **Note**: Enable this if you track the `changelist`.
    * **search_history**? `(integer|boolean)`\
      Maximum number of search history items to persist. Defaults to false.
      If set to `true`, maps to the `'history'` option.

      _Only in global sessions._
    * **command_history**? `(integer|boolean)`\
      Maximum number of command history items to persist. Defaults to false.
      If set to `true`, maps to the `'history'` option.

      _Only in global sessions._
    * **input_history**? `(integer|boolean)`\
      Maximum number of input history items to persist. Defaults to false.
      If set to `true`, maps to the `'history'` option.

      _Only in global sessions._
    * **expr_history**? `boolean`\
      Persist expression history. Defaults to false.
      **Note**: Cannot set limit (currently), no direct support by neovim.

      _Only in global sessions._
    * **debug_history**? `boolean`\
      Persist debug history. Defaults to false.
      **Note**: Cannot set limit (currently), no direct support by neovim.

      _Only in global sessions._
    * **meta**? `table`\
      External data remembered in association with this session. Useful to build on top of the core API.
    * **silence_errors**? `boolean`\
      Don't error during this operation

**Returns:**
  * **loaded_session**? [`finni.core.PendingSession`](<#finni.core.PendingSession>)\
    Session object, if the snapshot could be loaded

  * **snapshot**? [`finni.core.Snapshot`](<#finni.core.Snapshot>)\
    Snapshot data, if it could be loaded

</details>

<a id="finni.core.ActiveSession:add_hook()"></a>
<details>
  <summary>

#### ActiveSession:add_hook(`event`, `hook`)

  </summary>

**Parameters:**
  * **event** `"detach"`

  * **hook** [`finni.core.Session.DetachHook`](<#finni.core.Session.DetachHook>)


**Returns:** `self`

</details>

<a id="finni.core.ActiveSession:update()"></a>
<details>
  <summary>

#### ActiveSession:update(`opts`)

  </summary>

Update modifiable options without attaching/detaching a session

**Parameters:**
  * **opts** [`finni.core.Session.InitOptsWithMeta`](<#finni.core.Session.InitOptsWithMeta>)


**Returns:** **modified** `boolean`\
Indicates whether any config modifications occurred

</details>

<a id="finni.core.ActiveSession:restore()"></a>
<details>
  <summary>

#### ActiveSession:restore(`opts`, `snapshot`)

  </summary>

Restore a snapshot from disk or memory
It seems emmylua does not pick up this override and infers IdleSession<T> instead.

**Parameters:**
  * **opts**? `(`[`finni.core.Session.RestoreOpts`](<#finni.core.Session.RestoreOpts>)` & `[`finni.core.PassthroughOpts`](<#finni.core.PassthroughOpts>)`)`

    Table fields:

    * **reset**? `boolean`\
      When detaching a session in the process, unload associated resources/reset
      everything during the operation when restoring a snapshot.
    * **silence_errors**? `boolean`\
      Don't error during this operation
  * **snapshot**? [`finni.core.Snapshot`](<#finni.core.Snapshot>)\
    Snapshot to restore. If unspecified, loads from file.

    Table fields:

    * **buffers** [`finni.core.Snapshot.BufData`](<#finni.core.Snapshot.BufData>)`[]`\
      Buffer-specific data like name, buffer options, local marks, changelist
    * **tabs** [`finni.core.Snapshot.TabData`](<#finni.core.Snapshot.TabData>)`[]`\
      Tab-specific and window layout data, including tab cwd and window-specific jumplists
    * **tab_scoped** `boolean`\
      Whether this snapshot was derived from a single tab
    * **global** [`finni.core.Snapshot.GlobalData`](<#finni.core.Snapshot.GlobalData>)\
      Global snapshot data like process CWD, global options and global marks
    * **modified**? `table<`[`finni.core.BufUUID`](<#finni.core.BufUUID>)`,true?>`\
      List of buffers (identified by internal UUID) whose unsaved modifications
      were backed up in the snapshot
    * **buflist** `string[]`\
      List of named buffers that are referenced somewhere in this snapshot.
      Used to reduce repetition of buffer paths in save file, especially lists of named marks
      (jumplist, quickfix and location lists).

**Returns:**
  * **self** [`finni.core.ActiveSession`](<#finni.core.ActiveSession>)\
    Same object.

  * **success** `boolean`\
    Whether restoration was successful. Only sensible when `silence_errors` is true.

</details>

<a id="finni.core.ActiveSession:is_attached()"></a>
<details>
  <summary>

#### ActiveSession:is_attached()

  </summary>

Check whether this session is attached correctly.
Note: It must be the same instance that `:attach()` was called on, not a copy.

**Returns:** `TypeGuard<`[`finni.core.ActiveSession`](<#finni.core.ActiveSession>)`>`

</details>

<a id="finni.core.ActiveSession:opts()"></a>
<details>
  <summary>

#### ActiveSession:opts()

  </summary>

Turn the session object into opts for snapshot restore/save operations

**Returns:** `(`[`finni.core.Session.Init.Paths`](<#finni.core.Session.Init.Paths>)` & `[`finni.core.Session.Init.Autosave`](<#finni.core.Session.Init.Autosave>)` & `[`finni.core.Session.Init.Meta`](<#finni.core.Session.Init.Meta>)` & `[`finni.core.snapshot.CreateOpts`](<#finni.core.snapshot.CreateOpts>)`)`

</details>

<a id="finni.core.ActiveSession:info()"></a>
<details>
  <summary>

#### ActiveSession:info()

  </summary>

Get information about this session

**Returns:** [`finni.core.ActiveSessionInfo`](<#finni.core.ActiveSessionInfo>)

</details>

<a id="finni.core.ActiveSession:delete()"></a>
<details>
  <summary>

#### ActiveSession:delete(`opts`)

  </summary>

Delete a saved session

**Parameters:**
  * **opts**? `(`[`finni.SideEffects.Notify`](<#finni.SideEffects.Notify>)` & `[`finni.SideEffects.SilenceErrors`](<#finni.SideEffects.SilenceErrors>)`)`

    Table fields:

    * **notify**? `boolean`\
      Notify on success
    * **silence_errors**? `boolean`\
      Don't error during this operation

</details>

<a id="finni.core.ActiveSession:attach()"></a>
<details>
  <summary>

#### ActiveSession:attach()

  </summary>

Attach this session. If it was loaded from a snapshot file, you must ensure you restore
the snapshot (`:restore()`) before calling this method.
It's fine to attach an already attached session.

**Returns:** [`finni.core.ActiveSession`](<#finni.core.ActiveSession>)

</details>

<a id="finni.core.ActiveSession:save()"></a>
<details>
  <summary>

#### ActiveSession:save(`opts`)

  </summary>

Save this session following its configured configuration.
Note: Any save configuration must be applied via `Session.update(opts)` before
callig this method since all session-specific options that might be contained
in `opts` are overridden with ones configured for the session.

**Parameters:**
  * **opts** `unknown`\
    Success notification setting plus options that need to be passed through to pre_save/post_save hooks.


**Returns:** **success** `boolean`

</details>

<a id="finni.core.ActiveSession:autosave()"></a>
<details>
  <summary>

#### ActiveSession:autosave(`opts`, `force`)

  </summary>

**Parameters:**
  * **opts**? `(`[`finni.SideEffects.Notify`](<#finni.SideEffects.Notify>)` & `[`finni.core.PassthroughOpts`](<#finni.core.PassthroughOpts>)`)`

    Table fields:

    * **notify**? `boolean`\
      Notify on success
  * **force**? `boolean`\
    Force snapshot to be saved, regardless of autosave config

</details>

<a id="finni.core.ActiveSession:detach()"></a>
<details>
  <summary>

#### ActiveSession:detach(`reason`, `opts`)

  </summary>

Detach from this session. Ensure the session is attached before trying to detach,
otherwise you'll receive an error.
Hint: If you are sure the session should be attached, but still receive an error,
ensure that you call `detach()` on the specific session instance you called `:attach()` on before, not a copy.
@param self ActiveSession<T>

**Parameters:**
  * **reason** `(`[`finni.core.Session.DetachReasonBuiltin`](<#finni.core.Session.DetachReasonBuiltin>)`|string)`\
    A reason for detaching, also passed to detach hooks.
    Only inbuilt reasons influence behavior by default.

  * **opts** `(`[`finni.core.Session.DetachOpts`](<#finni.core.Session.DetachOpts>)` & `[`finni.core.PassthroughOpts`](<#finni.core.PassthroughOpts>)`)`\
    Influence side effects. `reset` removes all associated resources.
    `save` overrides autosave behavior.

    Table fields:

    * **reset**? `boolean`\
      When detaching a session in the process, unload associated resources/reset
      everything during the operation when restoring a snapshot.
    * **save**? `boolean`\
      Save/override autosave config for affected sessions before the operation

**Returns:** **idle_session** [`finni.core.IdleSession`](<#finni.core.IdleSession>)\
Same data table, but now representing an idle session again.

</details>

<a id="finni.core.ActiveSession:forget()"></a>
<details>
  <summary>

#### ActiveSession:forget(`self`)

  </summary>

Mark a **tab** session as invalid (i.e. remembered as attached, but its tab is gone).
Removes associated resources, skips autosave.

**Parameters:**
  * **self** [`finni.core.ActiveSession`](<#finni.core.ActiveSession>)`<`[`finni.core.Session.TabTarget`](<#finni.core.Session.TabTarget>)`>`\
    Active **tab** session to forget about. Errors if attempted with global sessions.

    Table fields:

    * **session_file** `string`\
      Path to the session file
    * **state_dir** `string`\
      Path to the directory holding session-associated data
    * **context_dir** `string`\
      Directory for shared state between all sessions in the same context
      (`dir` for manual sessions, project dir for autosessions)
    * **autosave_enabled** `boolean`\
      Autosave this attached session in intervals and when detaching
    * **autosave_interval** `integer`\
      Seconds between autosaves of this session, if enabled.
    * **autosave_notify**? `boolean`\
      Trigger a notification when autosaving this session. Defaults to true.
    * **on_attach**? [`finni.core.Session.AttachHook`](<#finni.core.Session.AttachHook>)\
      A function that's called when attaching to this session. No global default.
    * **on_detach**? [`finni.core.Session.DetachHook`](<#finni.core.Session.DetachHook>)\
      A function that's called when detaching from this session. No global default.
    * **meta**? `table`\
      External data remembered in association with this session. Useful to build on top of the core API.
    * **options**? `string[]`\
      Save and restore these Neovim (global|buffer|tab|window) options.
    * **buf_filter**? [`finni.BufFilter`](<#finni.BufFilter>)\
      Function that decides whether a buffer should be included in a snapshot.
    * **tab_buf_filter**? [`finni.TabBufFilter`](<#finni.TabBufFilter>)\
      Function that decides whether a buffer should be included in a tab-scoped snapshot.
      `buf_filter` is called first, this is to refine acceptable buffers only.
    * **modified**? `(boolean|"auto")`\
      Save/load modified buffers and their undo history.
      If set to `auto` (default), does not save, but still restores modified buffers.
    * **jumps**? `boolean`\
      Save/load window-specific jumplists, including current position
      (yes, for **all windows**, not just the active one like with ShaDa).
      If set to `auto` (default), does not save, but still restores saved jumplists.
    * **changelist**? `boolean`\
      Save/load buffer-specific changelist (all buffers) and
      changelist position (visible buffers only).

      **Important**: Enabling this causes **buffer-local marks to be cleared** during restoration.
      Consider tracking `local_marks` in addition to this.
    * **global_marks**? `boolean`\
      Save/load global marks (A-Z, not 0-9 currently).

      _Only in global sessions._
    * **local_marks**? `boolean`\
      Save/load buffer-specific (local) marks.

      **Note**: Enable this if you track the `changelist`.
    * **search_history**? `(integer|boolean)`\
      Maximum number of search history items to persist. Defaults to false.
      If set to `true`, maps to the `'history'` option.

      _Only in global sessions._
    * **command_history**? `(integer|boolean)`\
      Maximum number of command history items to persist. Defaults to false.
      If set to `true`, maps to the `'history'` option.

      _Only in global sessions._
    * **input_history**? `(integer|boolean)`\
      Maximum number of input history items to persist. Defaults to false.
      If set to `true`, maps to the `'history'` option.

      _Only in global sessions._
    * **expr_history**? `boolean`\
      Persist expression history. Defaults to false.
      **Note**: Cannot set limit (currently), no direct support by neovim.

      _Only in global sessions._
    * **debug_history**? `boolean`\
      Persist debug history. Defaults to false.
      **Note**: Cannot set limit (currently), no direct support by neovim.

      _Only in global sessions._
    * **tab_scoped** `boolean`
    * **tabid**? [`finni.core.TabID`](<#finni.core.TabID>)
    * **name** `string`
    * **_on_attach** [`finni.core.Session.AttachHook`](<#finni.core.Session.AttachHook>)`[]`
    * **_on_detach** [`finni.core.Session.DetachHook`](<#finni.core.Session.DetachHook>)`[]`
    * **_aug** `integer`\
      Neovim augroup for this session
    * **_timer**? `uv.uv_timer_t`\
      Autosave timer, if enabled
    * **_setup_autosave** `fun(self: `[`finni.core.ActiveSession`](<#finni.core.ActiveSession>)`<`[`finni.core.Session.TabTarget`](<#finni.core.Session.TabTarget>)`>)`

**Returns:** **idle_session** [`finni.core.IdleSession`](<#finni.core.IdleSession>)`<`[`finni.core.Session.TabTarget`](<#finni.core.Session.TabTarget>)`>`

</details>


<a id="finni.core.ActiveSessionInfo"></a>
### `finni.core.ActiveSessionInfo` (Class)

Represents the complete internal state of a session

**Fields:**

* **session_file** `string`\
  Path to the session file
* **state_dir** `string`\
  Path to the directory holding session-associated data
* **context_dir** `string`\
  Directory for shared state between all sessions in the same context
  (`dir` for manual sessions, project dir for autosessions)
* **autosave_enabled** `boolean`\
  When this session is attached, automatically save it in intervals. Defaults to false.
* **autosave_interval** `integer`\
  Seconds between autosaves of this session, if enabled. Defaults to 60.
* **name** `string`\
  Name of the session
* **tab_scoped** `boolean`\
  Whether the session is tab-scoped
* **autosave_notify**? `boolean`\
  Trigger a notification when autosaving this session. Defaults to true.
* **on_attach**? [`finni.core.Session.AttachHook`](<#finni.core.Session.AttachHook>)\
  A function that's called when attaching to this session. No global default.
* **on_detach**? [`finni.core.Session.DetachHook`](<#finni.core.Session.DetachHook>)\
  A function that's called when detaching from this session. No global default.
* **meta**? `table`\
  External data remembered in association with this session. Useful to build on top of the core API.
* **options**? `string[]`\
  Save and restore these Neovim (global|buffer|tab|window) options.
* **buf_filter**? [`finni.BufFilter`](<#finni.BufFilter>)\
  Function that decides whether a buffer should be included in a snapshot.
* **tab_buf_filter**? [`finni.TabBufFilter`](<#finni.TabBufFilter>)\
  Function that decides whether a buffer should be included in a tab-scoped snapshot.
  `buf_filter` is called first, this is to refine acceptable buffers only.
* **modified**? `(boolean|"auto")`\
  Save/load modified buffers and their undo history.
  If set to `auto` (default), does not save, but still restores modified buffers.
* **jumps**? `boolean`\
  Save/load window-specific jumplists, including current position
  (yes, for **all windows**, not just the active one like with ShaDa).
  If set to `auto` (default), does not save, but still restores saved jumplists.
* **changelist**? `boolean`\
  Save/load buffer-specific changelist (all buffers) and
  changelist position (visible buffers only).

  **Important**: Enabling this causes **buffer-local marks to be cleared** during restoration.
  Consider tracking `local_marks` in addition to this.
* **global_marks**? `boolean`\
  Save/load global marks (A-Z, not 0-9 currently).

  _Only in global sessions._
* **local_marks**? `boolean`\
  Save/load buffer-specific (local) marks.

  **Note**: Enable this if you track the `changelist`.
* **search_history**? `(integer|boolean)`\
  Maximum number of search history items to persist. Defaults to false.
  If set to `true`, maps to the `'history'` option.

  _Only in global sessions._
* **command_history**? `(integer|boolean)`\
  Maximum number of command history items to persist. Defaults to false.
  If set to `true`, maps to the `'history'` option.

  _Only in global sessions._
* **input_history**? `(integer|boolean)`\
  Maximum number of input history items to persist. Defaults to false.
  If set to `true`, maps to the `'history'` option.

  _Only in global sessions._
* **expr_history**? `boolean`\
  Persist expression history. Defaults to false.
  **Note**: Cannot set limit (currently), no direct support by neovim.

  _Only in global sessions._
* **debug_history**? `boolean`\
  Persist debug history. Defaults to false.
  **Note**: Cannot set limit (currently), no direct support by neovim.

  _Only in global sessions._
* **tabid**? `(`[`finni.core.TabID`](<#finni.core.TabID>)`|true)`\
  Tab number the session is attached to, if any. Can be `true`, which indicates it's a
  tab-scoped session that has not been restored yet - although not when requesting via the API

<a id="finni.core.AnonymousMark"></a>
### `finni.core.AnonymousMark` (Class)

**Fields:**

* **[1]** `integer`\
  Line number
* **[2]** `integer`\
  Column number

<a id="finni.core.BufUUID"></a>
### `finni.core.BufUUID` (Alias)

**Type:** `string`

An internal UUID that is used to keep track of buffers between snapshot restorations.


<a id="finni.core.FileMark"></a>
### `finni.core.FileMark` (Class)

**Fields:**

* **[1]** `sub<string,"">`\
  Absolute path to file this mark references
* **[2]** `integer`\
  Line number
* **[3]** `integer`\
  Column number

<a id="finni.core.IdleSession"></a>
### `finni.core.IdleSession` (Class)

A general session config that can be attached, turning it into an active session.

**Fields:**

* **session_file** `string`\
  Path to the session file
* **state_dir** `string`\
  Path to the directory holding session-associated data
* **context_dir** `string`\
  Directory for shared state between all sessions in the same context
  (`dir` for manual sessions, project dir for autosessions)
* **autosave_enabled** `boolean`\
  When this session is attached, automatically save it in intervals. Defaults to false.
* **autosave_interval** `integer`\
  Seconds between autosaves of this session, if enabled. Defaults to 60.
* **name** `string`
* **tab_scoped** `boolean`
* **autosave_notify**? `boolean`\
  Trigger a notification when autosaving this session. Defaults to true.
* **on_attach**? [`finni.core.Session.AttachHook`](<#finni.core.Session.AttachHook>)\
  A function that's called when attaching to this session. No global default.
* **on_detach**? [`finni.core.Session.DetachHook`](<#finni.core.Session.DetachHook>)\
  A function that's called when detaching from this session. No global default.
* **meta**? `table`\
  External data remembered in association with this session. Useful to build on top of the core API.
* **options**? `string[]`\
  Save and restore these Neovim (global|buffer|tab|window) options.
* **buf_filter**? [`finni.BufFilter`](<#finni.BufFilter>)\
  Function that decides whether a buffer should be included in a snapshot.
* **tab_buf_filter**? [`finni.TabBufFilter`](<#finni.TabBufFilter>)\
  Function that decides whether a buffer should be included in a tab-scoped snapshot.
  `buf_filter` is called first, this is to refine acceptable buffers only.
* **modified**? `(boolean|"auto")`\
  Save/load modified buffers and their undo history.
  If set to `auto` (default), does not save, but still restores modified buffers.
* **jumps**? `boolean`\
  Save/load window-specific jumplists, including current position
  (yes, for **all windows**, not just the active one like with ShaDa).
  If set to `auto` (default), does not save, but still restores saved jumplists.
* **changelist**? `boolean`\
  Save/load buffer-specific changelist (all buffers) and
  changelist position (visible buffers only).

  **Important**: Enabling this causes **buffer-local marks to be cleared** during restoration.
  Consider tracking `local_marks` in addition to this.
* **global_marks**? `boolean`\
  Save/load global marks (A-Z, not 0-9 currently).

  _Only in global sessions._
* **local_marks**? `boolean`\
  Save/load buffer-specific (local) marks.

  **Note**: Enable this if you track the `changelist`.
* **search_history**? `(integer|boolean)`\
  Maximum number of search history items to persist. Defaults to false.
  If set to `true`, maps to the `'history'` option.

  _Only in global sessions._
* **command_history**? `(integer|boolean)`\
  Maximum number of command history items to persist. Defaults to false.
  If set to `true`, maps to the `'history'` option.

  _Only in global sessions._
* **input_history**? `(integer|boolean)`\
  Maximum number of input history items to persist. Defaults to false.
  If set to `true`, maps to the `'history'` option.

  _Only in global sessions._
* **expr_history**? `boolean`\
  Persist expression history. Defaults to false.
  **Note**: Cannot set limit (currently), no direct support by neovim.

  _Only in global sessions._
* **debug_history**? `boolean`\
  Persist debug history. Defaults to false.
  **Note**: Cannot set limit (currently), no direct support by neovim.

  _Only in global sessions._
* **tabid**? [`finni.core.TabID`](<#finni.core.TabID>)
<a id="finni.core.IdleSession.new()"></a>
<details>
  <summary>

#### new(`name`, `session_file`, `state_dir`, `context_dir`, `opts`, `tabid`, `needs_restore`)

  </summary>

**Parameters:**
  * **name** `string`

  * **session_file** `string`

  * **state_dir** `string`

  * **context_dir** `string`

  * **opts** [`finni.core.Session.InitOptsWithMeta`](<#finni.core.Session.InitOptsWithMeta>)

  * **tabid** `true`

  * **needs_restore** `true`


**Returns:** [`finni.core.PendingSession`](<#finni.core.PendingSession>)`<`[`finni.core.Session.TabTarget`](<#finni.core.Session.TabTarget>)`>`

</details>

<a id="finni.core.IdleSession.from_snapshot()"></a>
<details>
  <summary>

#### from_snapshot(`name`, `session_file`, `state_dir`, `context_dir`, `opts`)

  </summary>

Create a new session by loading a snapshot, which you need to restore explicitly.

**Parameters:**
  * **name** `string`

  * **session_file** `string`

  * **state_dir** `string`

  * **context_dir** `string`

  * **opts** `(`[`finni.core.Session.InitOptsWithMeta`](<#finni.core.Session.InitOptsWithMeta>)` & `[`finni.SideEffects.SilenceErrors`](<#finni.SideEffects.SilenceErrors>)`)`

    Table fields:

    * **autosave_enabled**? `boolean`\
      When this session is attached, automatically save it in intervals. Defaults to false.
    * **autosave_interval**? `integer`\
      Seconds between autosaves of this session, if enabled. Defaults to 60.
    * **autosave_notify**? `boolean`\
      Trigger a notification when autosaving this session. Defaults to true.
    * **on_attach**? [`finni.core.Session.AttachHook`](<#finni.core.Session.AttachHook>)\
      A function that's called when attaching to this session. No global default.
    * **on_detach**? [`finni.core.Session.DetachHook`](<#finni.core.Session.DetachHook>)\
      A function that's called when detaching from this session. No global default.
    * **options**? `string[]`\
      Save and restore these Neovim (global|buffer|tab|window) options.
    * **buf_filter**? [`finni.BufFilter`](<#finni.BufFilter>)\
      Function that decides whether a buffer should be included in a snapshot.
    * **tab_buf_filter**? [`finni.TabBufFilter`](<#finni.TabBufFilter>)\
      Function that decides whether a buffer should be included in a tab-scoped snapshot.
      `buf_filter` is called first, this is to refine acceptable buffers only.
    * **modified**? `(boolean|"auto")`\
      Save/load modified buffers and their undo history.
      If set to `auto` (default), does not save, but still restores modified buffers.
    * **jumps**? `boolean`\
      Save/load window-specific jumplists, including current position
      (yes, for **all windows**, not just the active one like with ShaDa).
      If set to `auto` (default), does not save, but still restores saved jumplists.
    * **changelist**? `boolean`\
      Save/load buffer-specific changelist (all buffers) and
      changelist position (visible buffers only).

      **Important**: Enabling this causes **buffer-local marks to be cleared** during restoration.
      Consider tracking `local_marks` in addition to this.
    * **global_marks**? `boolean`\
      Save/load global marks (A-Z, not 0-9 currently).

      _Only in global sessions._
    * **local_marks**? `boolean`\
      Save/load buffer-specific (local) marks.

      **Note**: Enable this if you track the `changelist`.
    * **search_history**? `(integer|boolean)`\
      Maximum number of search history items to persist. Defaults to false.
      If set to `true`, maps to the `'history'` option.

      _Only in global sessions._
    * **command_history**? `(integer|boolean)`\
      Maximum number of command history items to persist. Defaults to false.
      If set to `true`, maps to the `'history'` option.

      _Only in global sessions._
    * **input_history**? `(integer|boolean)`\
      Maximum number of input history items to persist. Defaults to false.
      If set to `true`, maps to the `'history'` option.

      _Only in global sessions._
    * **expr_history**? `boolean`\
      Persist expression history. Defaults to false.
      **Note**: Cannot set limit (currently), no direct support by neovim.

      _Only in global sessions._
    * **debug_history**? `boolean`\
      Persist debug history. Defaults to false.
      **Note**: Cannot set limit (currently), no direct support by neovim.

      _Only in global sessions._
    * **meta**? `table`\
      External data remembered in association with this session. Useful to build on top of the core API.
    * **silence_errors**? `boolean`\
      Don't error during this operation

**Returns:**
  * **loaded_session**? [`finni.core.PendingSession`](<#finni.core.PendingSession>)\
    Session object, if the snapshot could be loaded

  * **snapshot**? [`finni.core.Snapshot`](<#finni.core.Snapshot>)\
    Snapshot data, if it could be loaded

</details>

<a id="finni.core.IdleSession:add_hook()"></a>
<details>
  <summary>

#### IdleSession:add_hook(`event`, `hook`)

  </summary>

**Parameters:**
  * **event** `"detach"`

  * **hook** [`finni.core.Session.DetachHook`](<#finni.core.Session.DetachHook>)


**Returns:** `self`

</details>

<a id="finni.core.IdleSession:update()"></a>
<details>
  <summary>

#### IdleSession:update(`opts`)

  </summary>

Update modifiable options without attaching/detaching a session

**Parameters:**
  * **opts** [`finni.core.Session.InitOptsWithMeta`](<#finni.core.Session.InitOptsWithMeta>)


**Returns:** **modified** `boolean`\
Indicates whether any config modifications occurred

</details>

<a id="finni.core.IdleSession:restore()"></a>
<details>
  <summary>

#### IdleSession:restore(`opts`, `snapshot`)

  </summary>

Restore a snapshot from disk or memory

**Parameters:**
  * **opts**? `(`[`finni.core.Session.RestoreOpts`](<#finni.core.Session.RestoreOpts>)` & `[`finni.core.PassthroughOpts`](<#finni.core.PassthroughOpts>)`)`

    Table fields:

    * **reset**? `boolean`\
      When detaching a session in the process, unload associated resources/reset
      everything during the operation when restoring a snapshot.
    * **silence_errors**? `boolean`\
      Don't error during this operation
  * **snapshot**? [`finni.core.Snapshot`](<#finni.core.Snapshot>)\
    Snapshot data to restore. If unspecified, loads from file.

    Table fields:

    * **buffers** [`finni.core.Snapshot.BufData`](<#finni.core.Snapshot.BufData>)`[]`\
      Buffer-specific data like name, buffer options, local marks, changelist
    * **tabs** [`finni.core.Snapshot.TabData`](<#finni.core.Snapshot.TabData>)`[]`\
      Tab-specific and window layout data, including tab cwd and window-specific jumplists
    * **tab_scoped** `boolean`\
      Whether this snapshot was derived from a single tab
    * **global** [`finni.core.Snapshot.GlobalData`](<#finni.core.Snapshot.GlobalData>)\
      Global snapshot data like process CWD, global options and global marks
    * **modified**? `table<`[`finni.core.BufUUID`](<#finni.core.BufUUID>)`,true?>`\
      List of buffers (identified by internal UUID) whose unsaved modifications
      were backed up in the snapshot
    * **buflist** `string[]`\
      List of named buffers that are referenced somewhere in this snapshot.
      Used to reduce repetition of buffer paths in save file, especially lists of named marks
      (jumplist, quickfix and location lists).

**Returns:**
  * **self** [`finni.core.IdleSession`](<#finni.core.IdleSession>)\
    The object itself, but now attachable

  * **success** `boolean`\
    Whether restoration was successful. Only sensible when `silence_errors` is true.

</details>

<a id="finni.core.IdleSession:is_attached()"></a>
<details>
  <summary>

#### IdleSession:is_attached()

  </summary>

Check whether this session is attached correctly.
Note: It must be the same instance that `:attach()` was called on, not a copy.

**Returns:** `TypeGuard<`[`finni.core.ActiveSession`](<#finni.core.ActiveSession>)`>`

</details>

<a id="finni.core.IdleSession:opts()"></a>
<details>
  <summary>

#### IdleSession:opts()

  </summary>

Turn the session object into opts for snapshot restore/save operations

**Returns:** `(`[`finni.core.Session.Init.Paths`](<#finni.core.Session.Init.Paths>)` & `[`finni.core.Session.Init.Autosave`](<#finni.core.Session.Init.Autosave>)` & `[`finni.core.Session.Init.Meta`](<#finni.core.Session.Init.Meta>)` & `[`finni.core.snapshot.CreateOpts`](<#finni.core.snapshot.CreateOpts>)`)`

</details>

<a id="finni.core.IdleSession:info()"></a>
<details>
  <summary>

#### IdleSession:info()

  </summary>

Get information about this session

**Returns:** [`finni.core.ActiveSessionInfo`](<#finni.core.ActiveSessionInfo>)

</details>

<a id="finni.core.IdleSession:delete()"></a>
<details>
  <summary>

#### IdleSession:delete(`opts`)

  </summary>

Delete a saved session

**Parameters:**
  * **opts**? `(`[`finni.SideEffects.Notify`](<#finni.SideEffects.Notify>)` & `[`finni.SideEffects.SilenceErrors`](<#finni.SideEffects.SilenceErrors>)`)`

    Table fields:

    * **notify**? `boolean`\
      Notify on success
    * **silence_errors**? `boolean`\
      Don't error during this operation

</details>

<a id="finni.core.IdleSession:attach()"></a>
<details>
  <summary>

#### IdleSession:attach()

  </summary>

Attach this session. If it was loaded from a snapshot file, you must ensure you restore
the snapshot (`:restore()`) before calling this method.
It's fine to attach an already attached session.

**Returns:** [`finni.core.ActiveSession`](<#finni.core.ActiveSession>)

</details>

<a id="finni.core.IdleSession:save()"></a>
<details>
  <summary>

#### IdleSession:save(`opts`)

  </summary>

Save this session following its configured configuration.
Note: Any save configuration must be applied via `Session.update(opts)` before
callig this method since all session-specific options that might be contained
in `opts` are overridden with ones configured for the session.

**Parameters:**
  * **opts** `unknown`\
    Success notification setting plus options that need to be passed through to pre_save/post_save hooks.


**Returns:** **success** `boolean`

</details>


<a id="finni.core.layout.WinInfo"></a>
### `finni.core.layout.WinInfo` (Class)

Window-specific snapshot data

**Fields:**

* **bufname** `string`\
  The name of the buffer that's displayed in the window.
* **bufuuid** [`finni.core.BufUUID`](<#finni.core.BufUUID>)\
  The buffer's UUID to track it over multiple sessions.
* **current** `boolean`\
  Whether the window was the active one when saved.
* **view** `vim.fn.winsaveview.ret`\
  Cursor position in file, relative position of file in window, curswant and other state
* **width** `integer`\
  Width of the window in number of columns.
* **height** `integer`\
  Height of the window in number of rows.
* **options** `table<string,any>`\
  Window-scoped options.
* **old_winid** [`finni.core.WinID`](<#finni.core.WinID>)\
  Window ID when snapshot was saved. Used to keep track of individual windows, especially loclist window restoration.
* **extension_data** `any`\
  If the window is supported by an extension, the data it needs to remember.
* **cursor**? [`finni.core.AnonymousMark`](<#finni.core.AnonymousMark>)\
  (row, col) tuple of the cursor position, mark-like => (1, 0)-indexed. Deprecated in favor of view.

  Table fields:

  * **[1]** `integer`\
    Line number
  * **[2]** `integer`\
    Column number
* **cwd**? `string`\
  If a local working directory was set for the window, its path.
* **extension**? `string`\
  If the window is supported by an extension, the name of the extension.
* **jumps**? `(`[`finni.core.layout.WinInfo.JumplistEntry`](<#finni.core.layout.WinInfo.JumplistEntry>)`[],integer)`\
  Window-local jumplist, number of steps from last entry to currently active one
* **alt**? `integer`\
  Index of the alternate file for this window in `buflist`, if any
* **loclist_win**? [`finni.core.WinID`](<#finni.core.WinID>)\
  Present for loclist windows. Window ID of the associated window, the one that opens selections (`filewinid`).
* **loclists**? `(`[`finni.core.Snapshot.QFList`](<#finni.core.Snapshot.QFList>)`[],integer)`\
  Location list stack and position of currently active one.

<a id="finni.core.layout.WinInfo.JumplistEntry"></a>
### `finni.core.layout.WinInfo.JumplistEntry` (Class)

**Fields:**

* **[1]** `integer`\
  Index of absolute path to file this mark references in `buflist`
* **[2]** `integer`\
  Line number
* **[3]** `integer`\
  Column number

<a id="finni.core.layout.WinLayout"></a>
### `finni.core.layout.WinLayout` (Alias)

**Type:** `(`[`finni.core.layout.WinLayoutLeaf`](<#finni.core.layout.WinLayoutLeaf>)`|`[`finni.core.layout.WinLayoutBranch`](<#finni.core.layout.WinLayoutBranch>)`)`


<a id="finni.core.layout.WinLayoutBranch"></a>
### `finni.core.layout.WinLayoutBranch` (Class)

**Fields:**

* **[1]** `("row"|"col")`\
  Node type
* **[2]** `(`[`finni.core.layout.WinLayoutLeaf`](<#finni.core.layout.WinLayoutLeaf>)`|`[`finni.core.layout.WinLayoutBranch`](<#finni.core.layout.WinLayoutBranch>)`)[]`\
  children

<a id="finni.core.layout.WinLayoutLeaf"></a>
### `finni.core.layout.WinLayoutLeaf` (Class)

**Fields:**

* **[1]** `"leaf"`\
  Node type
* **[2]** [`finni.core.layout.WinInfo`](<#finni.core.layout.WinInfo>)\
  Saved window info

  Table fields:

  * **bufname** `string`\
    The name of the buffer that's displayed in the window.
  * **bufuuid** [`finni.core.BufUUID`](<#finni.core.BufUUID>)\
    The buffer's UUID to track it over multiple sessions.
  * **current** `boolean`\
    Whether the window was the active one when saved.
  * **cursor**? [`finni.core.AnonymousMark`](<#finni.core.AnonymousMark>)\
    (row, col) tuple of the cursor position, mark-like => (1, 0)-indexed. Deprecated in favor of view.
  * **view** `vim.fn.winsaveview.ret`\
    Cursor position in file, relative position of file in window, curswant and other state
  * **width** `integer`\
    Width of the window in number of columns.
  * **height** `integer`\
    Height of the window in number of rows.
  * **options** `table<string,any>`\
    Window-scoped options.
  * **old_winid** [`finni.core.WinID`](<#finni.core.WinID>)\
    Window ID when snapshot was saved. Used to keep track of individual windows, especially loclist window restoration.
  * **cwd**? `string`\
    If a local working directory was set for the window, its path.
  * **extension_data** `any`\
    If the window is supported by an extension, the data it needs to remember.
  * **extension**? `string`\
    If the window is supported by an extension, the name of the extension.
  * **jumps**? `(`[`finni.core.layout.WinInfo.JumplistEntry`](<#finni.core.layout.WinInfo.JumplistEntry>)`[],integer)`\
    Window-local jumplist, number of steps from last entry to currently active one
  * **alt**? `integer`\
    Index of the alternate file for this window in `buflist`, if any
  * **loclist_win**? [`finni.core.WinID`](<#finni.core.WinID>)\
    Present for loclist windows. Window ID of the associated window, the one that opens selections (`filewinid`).
  * **loclists**? `(`[`finni.core.Snapshot.QFList`](<#finni.core.Snapshot.QFList>)`[],integer)`\
    Location list stack and position of currently active one.

<a id="finni.core.PassthroughOpts"></a>
### `finni.core.PassthroughOpts` (Alias)

**Type:** `table`

Indicates that any unhandled opts are also passed through to custom hooks.


<a id="finni.core.PendingSession"></a>
### `finni.core.PendingSession` (Class)

Represents a session that has been loaded from a snapshot and needs
to be applied still before being able to attach it.

**Fields:**

* **session_file** `string`\
  Path to the session file
* **state_dir** `string`\
  Path to the directory holding session-associated data
* **context_dir** `string`\
  Directory for shared state between all sessions in the same context
  (`dir` for manual sessions, project dir for autosessions)
* **autosave_enabled** `boolean`\
  When this session is attached, automatically save it in intervals. Defaults to false.
* **autosave_interval** `integer`\
  Seconds between autosaves of this session, if enabled. Defaults to 60.
* **name** `string`
* **tab_scoped** `boolean`
* **needs_restore** `true`\
  Indicates this session has been loaded from a snapshot, but not restored yet.
  This session object cannot be attached yet, it needs to be restored first.
* **autosave_notify**? `boolean`\
  Trigger a notification when autosaving this session. Defaults to true.
* **on_attach**? [`finni.core.Session.AttachHook`](<#finni.core.Session.AttachHook>)\
  A function that's called when attaching to this session. No global default.
* **on_detach**? [`finni.core.Session.DetachHook`](<#finni.core.Session.DetachHook>)\
  A function that's called when detaching from this session. No global default.
* **meta**? `table`\
  External data remembered in association with this session. Useful to build on top of the core API.
* **options**? `string[]`\
  Save and restore these Neovim (global|buffer|tab|window) options.
* **buf_filter**? [`finni.BufFilter`](<#finni.BufFilter>)\
  Function that decides whether a buffer should be included in a snapshot.
* **tab_buf_filter**? [`finni.TabBufFilter`](<#finni.TabBufFilter>)\
  Function that decides whether a buffer should be included in a tab-scoped snapshot.
  `buf_filter` is called first, this is to refine acceptable buffers only.
* **modified**? `(boolean|"auto")`\
  Save/load modified buffers and their undo history.
  If set to `auto` (default), does not save, but still restores modified buffers.
* **jumps**? `boolean`\
  Save/load window-specific jumplists, including current position
  (yes, for **all windows**, not just the active one like with ShaDa).
  If set to `auto` (default), does not save, but still restores saved jumplists.
* **changelist**? `boolean`\
  Save/load buffer-specific changelist (all buffers) and
  changelist position (visible buffers only).

  **Important**: Enabling this causes **buffer-local marks to be cleared** during restoration.
  Consider tracking `local_marks` in addition to this.
* **global_marks**? `boolean`\
  Save/load global marks (A-Z, not 0-9 currently).

  _Only in global sessions._
* **local_marks**? `boolean`\
  Save/load buffer-specific (local) marks.

  **Note**: Enable this if you track the `changelist`.
* **search_history**? `(integer|boolean)`\
  Maximum number of search history items to persist. Defaults to false.
  If set to `true`, maps to the `'history'` option.

  _Only in global sessions._
* **command_history**? `(integer|boolean)`\
  Maximum number of command history items to persist. Defaults to false.
  If set to `true`, maps to the `'history'` option.

  _Only in global sessions._
* **input_history**? `(integer|boolean)`\
  Maximum number of input history items to persist. Defaults to false.
  If set to `true`, maps to the `'history'` option.

  _Only in global sessions._
* **expr_history**? `boolean`\
  Persist expression history. Defaults to false.
  **Note**: Cannot set limit (currently), no direct support by neovim.

  _Only in global sessions._
* **debug_history**? `boolean`\
  Persist debug history. Defaults to false.
  **Note**: Cannot set limit (currently), no direct support by neovim.

  _Only in global sessions._
* **tabid**? [`finni.core.TabID`](<#finni.core.TabID>)
<a id="finni.core.PendingSession.new()"></a>
<details>
  <summary>

#### new(`name`, `session_file`, `state_dir`, `context_dir`, `opts`, `tabid`, `needs_restore`)

  </summary>

**Parameters:**
  * **name** `string`

  * **session_file** `string`

  * **state_dir** `string`

  * **context_dir** `string`

  * **opts** [`finni.core.Session.InitOptsWithMeta`](<#finni.core.Session.InitOptsWithMeta>)

  * **tabid** `true`

  * **needs_restore** `true`


**Returns:** [`finni.core.PendingSession`](<#finni.core.PendingSession>)`<`[`finni.core.Session.TabTarget`](<#finni.core.Session.TabTarget>)`>`

</details>

<a id="finni.core.PendingSession.from_snapshot()"></a>
<details>
  <summary>

#### from_snapshot(`name`, `session_file`, `state_dir`, `context_dir`, `opts`)

  </summary>

Create a new session by loading a snapshot, which you need to restore explicitly.

**Parameters:**
  * **name** `string`

  * **session_file** `string`

  * **state_dir** `string`

  * **context_dir** `string`

  * **opts** `(`[`finni.core.Session.InitOptsWithMeta`](<#finni.core.Session.InitOptsWithMeta>)` & `[`finni.SideEffects.SilenceErrors`](<#finni.SideEffects.SilenceErrors>)`)`

    Table fields:

    * **autosave_enabled**? `boolean`\
      When this session is attached, automatically save it in intervals. Defaults to false.
    * **autosave_interval**? `integer`\
      Seconds between autosaves of this session, if enabled. Defaults to 60.
    * **autosave_notify**? `boolean`\
      Trigger a notification when autosaving this session. Defaults to true.
    * **on_attach**? [`finni.core.Session.AttachHook`](<#finni.core.Session.AttachHook>)\
      A function that's called when attaching to this session. No global default.
    * **on_detach**? [`finni.core.Session.DetachHook`](<#finni.core.Session.DetachHook>)\
      A function that's called when detaching from this session. No global default.
    * **options**? `string[]`\
      Save and restore these Neovim (global|buffer|tab|window) options.
    * **buf_filter**? [`finni.BufFilter`](<#finni.BufFilter>)\
      Function that decides whether a buffer should be included in a snapshot.
    * **tab_buf_filter**? [`finni.TabBufFilter`](<#finni.TabBufFilter>)\
      Function that decides whether a buffer should be included in a tab-scoped snapshot.
      `buf_filter` is called first, this is to refine acceptable buffers only.
    * **modified**? `(boolean|"auto")`\
      Save/load modified buffers and their undo history.
      If set to `auto` (default), does not save, but still restores modified buffers.
    * **jumps**? `boolean`\
      Save/load window-specific jumplists, including current position
      (yes, for **all windows**, not just the active one like with ShaDa).
      If set to `auto` (default), does not save, but still restores saved jumplists.
    * **changelist**? `boolean`\
      Save/load buffer-specific changelist (all buffers) and
      changelist position (visible buffers only).

      **Important**: Enabling this causes **buffer-local marks to be cleared** during restoration.
      Consider tracking `local_marks` in addition to this.
    * **global_marks**? `boolean`\
      Save/load global marks (A-Z, not 0-9 currently).

      _Only in global sessions._
    * **local_marks**? `boolean`\
      Save/load buffer-specific (local) marks.

      **Note**: Enable this if you track the `changelist`.
    * **search_history**? `(integer|boolean)`\
      Maximum number of search history items to persist. Defaults to false.
      If set to `true`, maps to the `'history'` option.

      _Only in global sessions._
    * **command_history**? `(integer|boolean)`\
      Maximum number of command history items to persist. Defaults to false.
      If set to `true`, maps to the `'history'` option.

      _Only in global sessions._
    * **input_history**? `(integer|boolean)`\
      Maximum number of input history items to persist. Defaults to false.
      If set to `true`, maps to the `'history'` option.

      _Only in global sessions._
    * **expr_history**? `boolean`\
      Persist expression history. Defaults to false.
      **Note**: Cannot set limit (currently), no direct support by neovim.

      _Only in global sessions._
    * **debug_history**? `boolean`\
      Persist debug history. Defaults to false.
      **Note**: Cannot set limit (currently), no direct support by neovim.

      _Only in global sessions._
    * **meta**? `table`\
      External data remembered in association with this session. Useful to build on top of the core API.
    * **silence_errors**? `boolean`\
      Don't error during this operation

**Returns:**
  * **loaded_session**? [`finni.core.PendingSession`](<#finni.core.PendingSession>)\
    Session object, if the snapshot could be loaded

  * **snapshot**? [`finni.core.Snapshot`](<#finni.core.Snapshot>)\
    Snapshot data, if it could be loaded

</details>

<a id="finni.core.PendingSession:add_hook()"></a>
<details>
  <summary>

#### PendingSession:add_hook(`event`, `hook`)

  </summary>

**Parameters:**
  * **event** `"detach"`

  * **hook** [`finni.core.Session.DetachHook`](<#finni.core.Session.DetachHook>)


**Returns:** `self`

</details>

<a id="finni.core.PendingSession:update()"></a>
<details>
  <summary>

#### PendingSession:update(`opts`)

  </summary>

Update modifiable options without attaching/detaching a session

**Parameters:**
  * **opts** [`finni.core.Session.InitOptsWithMeta`](<#finni.core.Session.InitOptsWithMeta>)


**Returns:** **modified** `boolean`\
Indicates whether any config modifications occurred

</details>

<a id="finni.core.PendingSession:restore()"></a>
<details>
  <summary>

#### PendingSession:restore(`opts`, `snapshot`)

  </summary>

Restore a snapshot from disk or memory

**Parameters:**
  * **opts**? `(`[`finni.core.Session.RestoreOpts`](<#finni.core.Session.RestoreOpts>)` & `[`finni.core.PassthroughOpts`](<#finni.core.PassthroughOpts>)`)`

    Table fields:

    * **reset**? `boolean`\
      When detaching a session in the process, unload associated resources/reset
      everything during the operation when restoring a snapshot.
    * **silence_errors**? `boolean`\
      Don't error during this operation
  * **snapshot**? [`finni.core.Snapshot`](<#finni.core.Snapshot>)\
    Snapshot data to restore. If unspecified, loads from file.

    Table fields:

    * **buffers** [`finni.core.Snapshot.BufData`](<#finni.core.Snapshot.BufData>)`[]`\
      Buffer-specific data like name, buffer options, local marks, changelist
    * **tabs** [`finni.core.Snapshot.TabData`](<#finni.core.Snapshot.TabData>)`[]`\
      Tab-specific and window layout data, including tab cwd and window-specific jumplists
    * **tab_scoped** `boolean`\
      Whether this snapshot was derived from a single tab
    * **global** [`finni.core.Snapshot.GlobalData`](<#finni.core.Snapshot.GlobalData>)\
      Global snapshot data like process CWD, global options and global marks
    * **modified**? `table<`[`finni.core.BufUUID`](<#finni.core.BufUUID>)`,true?>`\
      List of buffers (identified by internal UUID) whose unsaved modifications
      were backed up in the snapshot
    * **buflist** `string[]`\
      List of named buffers that are referenced somewhere in this snapshot.
      Used to reduce repetition of buffer paths in save file, especially lists of named marks
      (jumplist, quickfix and location lists).

**Returns:**
  * **self** [`finni.core.IdleSession`](<#finni.core.IdleSession>)\
    The object itself, but now attachable

  * **success** `boolean`\
    Whether restoration was successful. Only sensible when `silence_errors` is true.

</details>

<a id="finni.core.PendingSession:is_attached()"></a>
<details>
  <summary>

#### PendingSession:is_attached()

  </summary>

Check whether this session is attached correctly.
Note: It must be the same instance that `:attach()` was called on, not a copy.

**Returns:** `TypeGuard<`[`finni.core.ActiveSession`](<#finni.core.ActiveSession>)`>`

</details>

<a id="finni.core.PendingSession:opts()"></a>
<details>
  <summary>

#### PendingSession:opts()

  </summary>

Turn the session object into opts for snapshot restore/save operations

**Returns:** `(`[`finni.core.Session.Init.Paths`](<#finni.core.Session.Init.Paths>)` & `[`finni.core.Session.Init.Autosave`](<#finni.core.Session.Init.Autosave>)` & `[`finni.core.Session.Init.Meta`](<#finni.core.Session.Init.Meta>)` & `[`finni.core.snapshot.CreateOpts`](<#finni.core.snapshot.CreateOpts>)`)`

</details>

<a id="finni.core.PendingSession:info()"></a>
<details>
  <summary>

#### PendingSession:info()

  </summary>

Get information about this session

**Returns:** [`finni.core.ActiveSessionInfo`](<#finni.core.ActiveSessionInfo>)

</details>

<a id="finni.core.PendingSession:delete()"></a>
<details>
  <summary>

#### PendingSession:delete(`opts`)

  </summary>

Delete a saved session

**Parameters:**
  * **opts**? `(`[`finni.SideEffects.Notify`](<#finni.SideEffects.Notify>)` & `[`finni.SideEffects.SilenceErrors`](<#finni.SideEffects.SilenceErrors>)`)`

    Table fields:

    * **notify**? `boolean`\
      Notify on success
    * **silence_errors**? `boolean`\
      Don't error during this operation

</details>


<a id="finni.core.Session.AttachHook"></a>
### `finni.core.Session.AttachHook` (Alias)

**Type:** `fun(session: `[`finni.core.IdleSession`](<#finni.core.IdleSession>)`)`

Attach hooks can inspect the session.
Modifying it in-place should work, but it's not officially supported.


<a id="finni.core.Session.DetachHook"></a>
### `finni.core.Session.DetachHook` (Alias)

**Type:** `(fun(session: `[`finni.core.ActiveSession`](<#finni.core.ActiveSession>)`, reason: (`[`finni.core.Session.DetachReasonBuiltin`](<#finni.core.Session.DetachReasonBuiltin>)`|string), opts: (`[`finni.core.Session.DetachOpts`](<#finni.core.Session.DetachOpts>)` & `[`finni.core.PassthroughOpts`](<#finni.core.PassthroughOpts>)`)) -> (`[`finni.core.Session.DetachOpts`](<#finni.core.Session.DetachOpts>)` & `[`finni.core.PassthroughOpts`](<#finni.core.PassthroughOpts>)`))?`

Detach hooks can modify detach opts in place or return new ones.
They can inspect the session. Modifying it in-place should work, but it's not officially supported.


<a id="finni.core.Session.DetachOpts"></a>
### `finni.core.Session.DetachOpts` (Alias)

**Type:** `(`[`finni.SideEffects.Reset`](<#finni.SideEffects.Reset>)` & `[`finni.SideEffects.Save`](<#finni.SideEffects.Save>)`)`

Options for detaching sessions

**Fields:**

* **reset**? `boolean`\
  When detaching a session in the process, unload associated resources/reset
  everything during the operation when restoring a snapshot.
* **save**? `boolean`\
  Save/override autosave config for affected sessions before the operation


<a id="finni.core.Session.DetachReasonBuiltin"></a>
### `finni.core.Session.DetachReasonBuiltin` (Alias)

**Type:** `("delete"|"load"|"quit"|"request"|"save"|"tab_closed")`

Detach reasons are passed to avoid unintended side effects during operations. They are passed to
detach hooks as well. These are the ones built in to the core session handling.


<a id="finni.core.Session.Init.Autosave"></a>
### `finni.core.Session.Init.Autosave` (Class)

**Fields:**

* **autosave_enabled**? `boolean`\
  When this session is attached, automatically save it in intervals. Defaults to false.
* **autosave_interval**? `integer`\
  Seconds between autosaves of this session, if enabled. Defaults to 60.
* **autosave_notify**? `boolean`\
  Trigger a notification when autosaving this session. Defaults to true.

<a id="finni.core.Session.Init.Hooks"></a>
### `finni.core.Session.Init.Hooks` (Class)

**Fields:**

* **on_attach**? [`finni.core.Session.AttachHook`](<#finni.core.Session.AttachHook>)\
  A function that's called when attaching to this session. No global default.
* **on_detach**? [`finni.core.Session.DetachHook`](<#finni.core.Session.DetachHook>)\
  A function that's called when detaching from this session. No global default.

<a id="finni.core.Session.Init.Meta"></a>
### `finni.core.Session.Init.Meta` (Class)

**Fields:**

* **meta**? `table`\
  External data remembered in association with this session. Useful to build on top of the core API.

<a id="finni.core.Session.Init.Paths"></a>
### `finni.core.Session.Init.Paths` (Class)

**Fields:**

* **session_file** `string`\
  Path to the session file
* **state_dir** `string`\
  Path to the directory holding session-associated data
* **context_dir** `string`\
  Directory for shared state between all sessions in the same context
  (`dir` for manual sessions, project dir for autosessions)

<a id="finni.core.Session.InitOpts"></a>
### `finni.core.Session.InitOpts` (Alias)

**Type:** `(`[`finni.core.Session.Init.Autosave`](<#finni.core.Session.Init.Autosave>)` & `[`finni.core.Session.Init.Hooks`](<#finni.core.Session.Init.Hooks>)` & `[`finni.core.snapshot.CreateOpts`](<#finni.core.snapshot.CreateOpts>)`)`

Options to influence how an attached session is handled.

**Fields:**

* **autosave_enabled**? `boolean`\
  When this session is attached, automatically save it in intervals. Defaults to false.
* **autosave_interval**? `integer`\
  Seconds between autosaves of this session, if enabled. Defaults to 60.
* **autosave_notify**? `boolean`\
  Trigger a notification when autosaving this session. Defaults to true.
* **on_attach**? [`finni.core.Session.AttachHook`](<#finni.core.Session.AttachHook>)\
  A function that's called when attaching to this session. No global default.
* **on_detach**? [`finni.core.Session.DetachHook`](<#finni.core.Session.DetachHook>)\
  A function that's called when detaching from this session. No global default.
* **options**? `string[]`\
  Save and restore these Neovim (global|buffer|tab|window) options.
* **buf_filter**? [`finni.BufFilter`](<#finni.BufFilter>)\
  Function that decides whether a buffer should be included in a snapshot.
* **tab_buf_filter**? [`finni.TabBufFilter`](<#finni.TabBufFilter>)\
  Function that decides whether a buffer should be included in a tab-scoped snapshot.
  `buf_filter` is called first, this is to refine acceptable buffers only.
* **modified**? `(boolean|"auto")`\
  Save/load modified buffers and their undo history.
  If set to `auto` (default), does not save, but still restores modified buffers.
* **jumps**? `boolean`\
  Save/load window-specific jumplists, including current position
  (yes, for **all windows**, not just the active one like with ShaDa).
  If set to `auto` (default), does not save, but still restores saved jumplists.
* **changelist**? `boolean`\
  Save/load buffer-specific changelist (all buffers) and
  changelist position (visible buffers only).

  **Important**: Enabling this causes **buffer-local marks to be cleared** during restoration.
  Consider tracking `local_marks` in addition to this.
* **global_marks**? `boolean`\
  Save/load global marks (A-Z, not 0-9 currently).

  _Only in global sessions._
* **local_marks**? `boolean`\
  Save/load buffer-specific (local) marks.

  **Note**: Enable this if you track the `changelist`.
* **search_history**? `(integer|boolean)`\
  Maximum number of search history items to persist. Defaults to false.
  If set to `true`, maps to the `'history'` option.

  _Only in global sessions._
* **command_history**? `(integer|boolean)`\
  Maximum number of command history items to persist. Defaults to false.
  If set to `true`, maps to the `'history'` option.

  _Only in global sessions._
* **input_history**? `(integer|boolean)`\
  Maximum number of input history items to persist. Defaults to false.
  If set to `true`, maps to the `'history'` option.

  _Only in global sessions._
* **expr_history**? `boolean`\
  Persist expression history. Defaults to false.
  **Note**: Cannot set limit (currently), no direct support by neovim.

  _Only in global sessions._
* **debug_history**? `boolean`\
  Persist debug history. Defaults to false.
  **Note**: Cannot set limit (currently), no direct support by neovim.

  _Only in global sessions._


<a id="finni.core.Session.InitOptsWithMeta"></a>
### `finni.core.Session.InitOptsWithMeta` (Alias)

**Type:** `(`[`finni.core.Session.InitOpts`](<#finni.core.Session.InitOpts>)` & `[`finni.core.Session.Init.Meta`](<#finni.core.Session.Init.Meta>)`)`

Options to influence how an attached session is handled plus `meta` field, which can only be populated by passing
it to the session constructor and is useful for custom session handling.

**Fields:**

* **autosave_enabled**? `boolean`\
  When this session is attached, automatically save it in intervals. Defaults to false.
* **autosave_interval**? `integer`\
  Seconds between autosaves of this session, if enabled. Defaults to 60.
* **autosave_notify**? `boolean`\
  Trigger a notification when autosaving this session. Defaults to true.
* **on_attach**? [`finni.core.Session.AttachHook`](<#finni.core.Session.AttachHook>)\
  A function that's called when attaching to this session. No global default.
* **on_detach**? [`finni.core.Session.DetachHook`](<#finni.core.Session.DetachHook>)\
  A function that's called when detaching from this session. No global default.
* **options**? `string[]`\
  Save and restore these Neovim (global|buffer|tab|window) options.
* **buf_filter**? [`finni.BufFilter`](<#finni.BufFilter>)\
  Function that decides whether a buffer should be included in a snapshot.
* **tab_buf_filter**? [`finni.TabBufFilter`](<#finni.TabBufFilter>)\
  Function that decides whether a buffer should be included in a tab-scoped snapshot.
  `buf_filter` is called first, this is to refine acceptable buffers only.
* **modified**? `(boolean|"auto")`\
  Save/load modified buffers and their undo history.
  If set to `auto` (default), does not save, but still restores modified buffers.
* **jumps**? `boolean`\
  Save/load window-specific jumplists, including current position
  (yes, for **all windows**, not just the active one like with ShaDa).
  If set to `auto` (default), does not save, but still restores saved jumplists.
* **changelist**? `boolean`\
  Save/load buffer-specific changelist (all buffers) and
  changelist position (visible buffers only).

  **Important**: Enabling this causes **buffer-local marks to be cleared** during restoration.
  Consider tracking `local_marks` in addition to this.
* **global_marks**? `boolean`\
  Save/load global marks (A-Z, not 0-9 currently).

  _Only in global sessions._
* **local_marks**? `boolean`\
  Save/load buffer-specific (local) marks.

  **Note**: Enable this if you track the `changelist`.
* **search_history**? `(integer|boolean)`\
  Maximum number of search history items to persist. Defaults to false.
  If set to `true`, maps to the `'history'` option.

  _Only in global sessions._
* **command_history**? `(integer|boolean)`\
  Maximum number of command history items to persist. Defaults to false.
  If set to `true`, maps to the `'history'` option.

  _Only in global sessions._
* **input_history**? `(integer|boolean)`\
  Maximum number of input history items to persist. Defaults to false.
  If set to `true`, maps to the `'history'` option.

  _Only in global sessions._
* **expr_history**? `boolean`\
  Persist expression history. Defaults to false.
  **Note**: Cannot set limit (currently), no direct support by neovim.

  _Only in global sessions._
* **debug_history**? `boolean`\
  Persist debug history. Defaults to false.
  **Note**: Cannot set limit (currently), no direct support by neovim.

  _Only in global sessions._
* **meta**? `table`\
  External data remembered in association with this session. Useful to build on top of the core API.


<a id="finni.core.Session.RestoreOpts"></a>
### `finni.core.Session.RestoreOpts` (Alias)

**Type:** `(`[`finni.SideEffects.Reset`](<#finni.SideEffects.Reset>)` & `[`finni.SideEffects.SilenceErrors`](<#finni.SideEffects.SilenceErrors>)`)`

Options for basic snapshot restoration (different from session loading!).
Note that `reset` here does not handle detaching other active sessions,
it really resets everything if set to true. If set to false, opens a new tab.
Handle with care!

**Fields:**

* **reset**? `boolean`\
  When detaching a session in the process, unload associated resources/reset
  everything during the operation when restoring a snapshot.
* **silence_errors**? `boolean`\
  Don't error during this operation


<a id="finni.core.Session.TabTarget"></a>
### `finni.core.Session.TabTarget` (Class)

The associated session is tab-scoped to this specific tab

**Fields:**

* **tab_scoped** `true`
* **tabid** [`finni.core.TabID`](<#finni.core.TabID>)

<a id="finni.core.Snapshot"></a>
### `finni.core.Snapshot` (Class)

A snapshot of nvim's state.

**Fields:**

* **buffers** [`finni.core.Snapshot.BufData`](<#finni.core.Snapshot.BufData>)`[]`\
  Buffer-specific data like name, buffer options, local marks, changelist

  Table fields:

  * **name** `string`\
    Name of the buffer, usually its path.
    Can be empty when unsaved modifications are backed up.
  * **loaded** `boolean`\
    Whether the buffer was loaded.
  * **options** `table<string,any>`\
    Buffer-specific nvim options.
  * **last_pos** [`finni.core.AnonymousMark`](<#finni.core.AnonymousMark>)\
    Position of the cursor when this buffer was last shown in a window (`"` mark).
    Only updated once a buffer becomes invisible.
    Visible buffer cursors are backed up in the window layout data.
  * **uuid** `string`\
    A buffer-specific UUID intended to track it between sessions. Required to save/restore unnamed buffers.
  * **in_win** `boolean`\
    Whether the buffer is visible in at least one window.
  * **changelist**? `(`[`finni.core.Snapshot.BufData.ChangelistItem`](<#finni.core.Snapshot.BufData.ChangelistItem>)`[],integer)`\
    Changelist and changelist position (backwards from most recent entry) for this buffer.
    Position is always `0` when invisible buffers are saved.
  * **marks**? `table<string,`[`finni.core.AnonymousMark`](<#finni.core.AnonymousMark>)`?>`\
    Saved buffer-local marks, if enabled
  * **bt**? `("acwrite"|"help"|"nofile"|"nowrite"|"quickfix"|"terminal"...)`\
    `buftype` option of buffer. Unset if empty (`""`).
* **tabs** [`finni.core.Snapshot.TabData`](<#finni.core.Snapshot.TabData>)`[]`\
  Tab-specific and window layout data, including tab cwd and window-specific jumplists

  Table fields:

  * **options** `table<string,any>`\
    Tab-specific nvim options. Currently only `cmdheight`.
  * **wins** [`finni.core.layout.WinLayout`](<#finni.core.layout.WinLayout>)\
    Window layout enriched with window-specific snapshot data
  * **cwd**? `string`\
    Tab-local cwd, if different from the global one or a tab-scoped snapshot
  * **current**? `boolean`
* **tab_scoped** `boolean`\
  Whether this snapshot was derived from a single tab
* **global** [`finni.core.Snapshot.GlobalData`](<#finni.core.Snapshot.GlobalData>)\
  Global snapshot data like process CWD, global options and global marks

  Table fields:

  * **cwd** `string`\
    Nvim's global cwd.
  * **height** `integer`\
    `vim.o.lines` - `vim.o.cmdheight`
  * **width** `integer`\
    `vim.o.columns`
  * **options** `table<string,any>`\
    Global nvim options
  * **marks**? `table<string,`[`finni.core.FileMark`](<#finni.core.FileMark>)`?>`\
    Saved global marks, if enabled
  * **search_history** `boolean`\
    Whether search history was saved in session-associated ShaDa file.
    If enabled, corresponding history in nvim process should be cleared before loading.
  * **command_history** `boolean`\
    Whether command history was saved in session-associated ShaDa file.
    If enabled, corresponding history in nvim process should be cleared before loading.
  * **input_history** `boolean`\
    Whether input history was saved in session-associated ShaDa file.
    If enabled, corresponding history in nvim process should be cleared before loading.
  * **expr_history** `boolean`\
    Whether expression history was saved in session-associated ShaDa file.
    If enabled, corresponding history in nvim process should be cleared before loading.
  * **debug_history** `boolean`\
    Whether debug history was saved in session-associated ShaDa file.
    If enabled, corresponding history in nvim process should be cleared before loading.
* **buflist** `string[]`\
  List of named buffers that are referenced somewhere in this snapshot.
  Used to reduce repetition of buffer paths in save file, especially lists of named marks
  (jumplist, quickfix and location lists).
* **modified**? `table<`[`finni.core.BufUUID`](<#finni.core.BufUUID>)`,true?>`\
  List of buffers (identified by internal UUID) whose unsaved modifications
  were backed up in the snapshot

<a id="finni.core.Snapshot.BufData"></a>
### `finni.core.Snapshot.BufData` (Class)

Buffer-specific snapshot data like path, loaded state, options and last cursor position.

**Fields:**

* **name** `string`\
  Name of the buffer, usually its path.
  Can be empty when unsaved modifications are backed up.
* **loaded** `boolean`\
  Whether the buffer was loaded.
* **options** `table<string,any>`\
  Buffer-specific nvim options.
* **last_pos** [`finni.core.AnonymousMark`](<#finni.core.AnonymousMark>)\
  Position of the cursor when this buffer was last shown in a window (`"` mark).
  Only updated once a buffer becomes invisible.
  Visible buffer cursors are backed up in the window layout data.

  Table fields:

  * **[1]** `integer`\
    Line number
  * **[2]** `integer`\
    Column number
* **uuid** `string`\
  A buffer-specific UUID intended to track it between sessions. Required to save/restore unnamed buffers.
* **in_win** `boolean`\
  Whether the buffer is visible in at least one window.
* **changelist**? `(`[`finni.core.Snapshot.BufData.ChangelistItem`](<#finni.core.Snapshot.BufData.ChangelistItem>)`[],integer)`\
  Changelist and changelist position (backwards from most recent entry) for this buffer.
  Position is always `0` when invisible buffers are saved.
* **marks**? `table<string,`[`finni.core.AnonymousMark`](<#finni.core.AnonymousMark>)`?>`\
  Saved buffer-local marks, if enabled
* **bt**? `("acwrite"|"help"|"nofile"|"nowrite"|"quickfix"|"terminal"...)`\
  `buftype` option of buffer. Unset if empty (`""`).

<a id="finni.core.Snapshot.BufData.ChangelistItem"></a>
### `finni.core.Snapshot.BufData.ChangelistItem` (Class)

**Fields:**

* **[1]** `integer`\
  Line number
* **[2]** `integer`\
  Column number

<a id="finni.core.snapshot.CreateOpts"></a>
### `finni.core.snapshot.CreateOpts` (Class)

Options to influence which data is included in a snapshot.

**Fields:**

* **options**? `string[]`\
  Save and restore these Neovim (global|buffer|tab|window) options.
* **buf_filter**? [`finni.BufFilter`](<#finni.BufFilter>)\
  Function that decides whether a buffer should be included in a snapshot.
* **tab_buf_filter**? [`finni.TabBufFilter`](<#finni.TabBufFilter>)\
  Function that decides whether a buffer should be included in a tab-scoped snapshot.
  `buf_filter` is called first, this is to refine acceptable buffers only.
* **modified**? `(boolean|"auto")`\
  Save/load modified buffers and their undo history.
  If set to `auto` (default), does not save, but still restores modified buffers.
* **jumps**? `boolean`\
  Save/load window-specific jumplists, including current position
  (yes, for **all windows**, not just the active one like with ShaDa).
  If set to `auto` (default), does not save, but still restores saved jumplists.
* **changelist**? `boolean`\
  Save/load buffer-specific changelist (all buffers) and
  changelist position (visible buffers only).

  **Important**: Enabling this causes **buffer-local marks to be cleared** during restoration.
  Consider tracking `local_marks` in addition to this.
* **global_marks**? `boolean`\
  Save/load global marks (A-Z, not 0-9 currently).

  _Only in global sessions._
* **local_marks**? `boolean`\
  Save/load buffer-specific (local) marks.

  **Note**: Enable this if you track the `changelist`.
* **search_history**? `(integer|boolean)`\
  Maximum number of search history items to persist. Defaults to false.
  If set to `true`, maps to the `'history'` option.

  _Only in global sessions._
* **command_history**? `(integer|boolean)`\
  Maximum number of command history items to persist. Defaults to false.
  If set to `true`, maps to the `'history'` option.

  _Only in global sessions._
* **input_history**? `(integer|boolean)`\
  Maximum number of input history items to persist. Defaults to false.
  If set to `true`, maps to the `'history'` option.

  _Only in global sessions._
* **expr_history**? `boolean`\
  Persist expression history. Defaults to false.
  **Note**: Cannot set limit (currently), no direct support by neovim.

  _Only in global sessions._
* **debug_history**? `boolean`\
  Persist debug history. Defaults to false.
  **Note**: Cannot set limit (currently), no direct support by neovim.

  _Only in global sessions._

<a id="finni.core.Snapshot.GlobalData"></a>
### `finni.core.Snapshot.GlobalData` (Class)

Global snapshot data like cwd, height/width and global options.

**Fields:**

* **cwd** `string`\
  Nvim's global cwd.
* **height** `integer`\
  `vim.o.lines` - `vim.o.cmdheight`
* **width** `integer`\
  `vim.o.columns`
* **options** `table<string,any>`\
  Global nvim options
* **search_history** `boolean`\
  Whether search history was saved in session-associated ShaDa file.
  If enabled, corresponding history in nvim process should be cleared before loading.
* **command_history** `boolean`\
  Whether command history was saved in session-associated ShaDa file.
  If enabled, corresponding history in nvim process should be cleared before loading.
* **input_history** `boolean`\
  Whether input history was saved in session-associated ShaDa file.
  If enabled, corresponding history in nvim process should be cleared before loading.
* **expr_history** `boolean`\
  Whether expression history was saved in session-associated ShaDa file.
  If enabled, corresponding history in nvim process should be cleared before loading.
* **debug_history** `boolean`\
  Whether debug history was saved in session-associated ShaDa file.
  If enabled, corresponding history in nvim process should be cleared before loading.
* **marks**? `table<string,`[`finni.core.FileMark`](<#finni.core.FileMark>)`?>`\
  Saved global marks, if enabled

<a id="finni.core.Snapshot.QFList"></a>
### `finni.core.Snapshot.QFList` (Class)

Represents a quickfix/location list

**Fields:**

* **idx** `integer`\
  Current position in list
* **title** `string`\
  Title of list
* **context** `any`\
  Arbitrary context for this list, may be used by plugins
* **quickfixtextfunc** `string`\
  Function to customize the displayed text
* **items** [`finni.core.Snapshot.QFListItem`](<#finni.core.Snapshot.QFListItem>)`[]`\
  Items in the list

  Table fields:

  * **filename**? `integer`\
    Index of path of the file this entry points to in `buflist`
  * **module** `string`\
    Module name (?)
  * **lnum** `integer`\
    Referenced line in the file, 1-indexed
  * **end_lnum**? `integer`\
    For multiline items, last referenced line
  * **col** `integer`\
    Referenced column in the line of the file, also 1-indexed
  * **end_col**? `integer`\
    For ranged items, last referenced column number
  * **vcol** `boolean`\
    Whether `col` is visual index or byte index
  * **nr** `integer`\
    Item index in the list
  * **pattern** `string`\
    Search pattern used to locate the item
  * **text** `string`\
    Item description
  * **type** `string`\
    Type of the item (?)
  * **valid** `boolean`\
    Whether error message was recognized (?)
* **efm**? `string`\
  Error format string to use for parsing lines

<a id="finni.core.Snapshot.TabData"></a>
### `finni.core.Snapshot.TabData` (Class)

Tab-specific (options, cwd) and window layout snapshot data.

**Fields:**

* **options** `table<string,any>`\
  Tab-specific nvim options. Currently only `cmdheight`.
* **wins** [`finni.core.layout.WinLayout`](<#finni.core.layout.WinLayout>)\
  Window layout enriched with window-specific snapshot data
* **cwd**? `string`\
  Tab-local cwd, if different from the global one or a tab-scoped snapshot
* **current**? `boolean`

<a id="finni.core.TabID"></a>
### `finni.core.TabID` (Alias)

**Type:** `integer`

Nvim tab ID


<a id="finni.core.WinID"></a>
### `finni.core.WinID` (Alias)

**Type:** `integer`

Nvim window ID


<a id="finni.log.Level"></a>
### `finni.log.Level` (Alias)

**Type:** `("TRACE"|"DEBUG"|"INFO"|"WARN"|"ERROR"|"OFF")`

Log level name in uppercase, for internal references and log output


<a id="finni.log.Line"></a>
### `finni.log.Line` (Class)

Log call information passed to `handler`

**Fields:**

* **level** [`finni.log.Level`](<#finni.log.Level>)\
  Name of log level, uppercase
* **message** `string`\
  Final, formatted log message
* **timestamp** `integer`\
  UNIX timestamp of log message
* **hrtime** `number`\
  High-resolution time of log message (`[ns]`, arbitrary anchor)
* **src_path** `string`\
  Absolute path to the file the log call originated from
* **src_line** `integer`\
  Line in `src_path` the log call originated from

<a id="finni.pickers.PickerRawOverrides"></a>
### `finni.pickers.PickerRawOverrides` (Class)

**Fields:**

* **default** `table`\
  Override any (picker plugin-specific) options passed to all picker types.
* **manual** `table`\
  Override any (picker plugin-specific) options passed to the manual session picker.
* **auto** `table`\
  Override any (picker plugin-specific) options passed to the autosession picker.
* **auto_all** `table`\
  Override any (picker plugin-specific) options passed to the global autosession picker.
* **project** `table`\
  Override any (picker plugin-specific) options passed to the project autosession picker.

<a id="finni.session.DeleteOpts"></a>
### `finni.session.DeleteOpts` (Alias)

**Type:** `(`[`finni.session.DirParam`](<#finni.session.DirParam>)` & `[`finni.SideEffects.Notify`](<#finni.SideEffects.Notify>)` & `[`finni.SideEffects.Reset`](<#finni.SideEffects.Reset>)` & `[`finni.SideEffects.SilenceErrors`](<#finni.SideEffects.SilenceErrors>)`)`

API options for `session.delete`

**Fields:**

* **dir**? `string`\
  Name of session directory (overrides config.dir)
* **notify**? `boolean`\
  Notify on success
* **reset**? `boolean`\
  When detaching a session in the process, unload associated resources/reset
  everything during the operation when restoring a snapshot.
* **silence_errors**? `boolean`\
  Don't error during this operation


<a id="finni.session.DirParam"></a>
### `finni.session.DirParam` (Class)

**Fields:**

* **dir**? `string`\
  Name of session directory (overrides config.dir)

<a id="finni.session.LoadOpts"></a>
### `finni.session.LoadOpts` (Alias)

**Type:** `(`[`finni.session.DirParam`](<#finni.session.DirParam>)` & `[`finni.core.Session.InitOptsWithMeta`](<#finni.core.Session.InitOptsWithMeta>)` & `[`finni.SideEffects.Attach`](<#finni.SideEffects.Attach>)` & `[`finni.SideEffects.ResetAuto`](<#finni.SideEffects.ResetAuto>)` & `[`finni.SideEffects.Save`](<#finni.SideEffects.Save>)` & `[`finni.SideEffects.SilenceErrors`](<#finni.SideEffects.SilenceErrors>)`)`

API options for `session.load`

**Fields:**

* **dir**? `string`\
  Name of session directory (overrides config.dir)
* **autosave_enabled**? `boolean`\
  When this session is attached, automatically save it in intervals. Defaults to false.
* **autosave_interval**? `integer`\
  Seconds between autosaves of this session, if enabled. Defaults to 60.
* **autosave_notify**? `boolean`\
  Trigger a notification when autosaving this session. Defaults to true.
* **on_attach**? [`finni.core.Session.AttachHook`](<#finni.core.Session.AttachHook>)\
  A function that's called when attaching to this session. No global default.
* **on_detach**? [`finni.core.Session.DetachHook`](<#finni.core.Session.DetachHook>)\
  A function that's called when detaching from this session. No global default.
* **options**? `string[]`\
  Save and restore these Neovim (global|buffer|tab|window) options.
* **buf_filter**? [`finni.BufFilter`](<#finni.BufFilter>)\
  Function that decides whether a buffer should be included in a snapshot.
* **tab_buf_filter**? [`finni.TabBufFilter`](<#finni.TabBufFilter>)\
  Function that decides whether a buffer should be included in a tab-scoped snapshot.
  `buf_filter` is called first, this is to refine acceptable buffers only.
* **modified**? `(boolean|"auto")`\
  Save/load modified buffers and their undo history.
  If set to `auto` (default), does not save, but still restores modified buffers.
* **jumps**? `boolean`\
  Save/load window-specific jumplists, including current position
  (yes, for **all windows**, not just the active one like with ShaDa).
  If set to `auto` (default), does not save, but still restores saved jumplists.
* **changelist**? `boolean`\
  Save/load buffer-specific changelist (all buffers) and
  changelist position (visible buffers only).

  **Important**: Enabling this causes **buffer-local marks to be cleared** during restoration.
  Consider tracking `local_marks` in addition to this.
* **global_marks**? `boolean`\
  Save/load global marks (A-Z, not 0-9 currently).

  _Only in global sessions._
* **local_marks**? `boolean`\
  Save/load buffer-specific (local) marks.

  **Note**: Enable this if you track the `changelist`.
* **search_history**? `(integer|boolean)`\
  Maximum number of search history items to persist. Defaults to false.
  If set to `true`, maps to the `'history'` option.

  _Only in global sessions._
* **command_history**? `(integer|boolean)`\
  Maximum number of command history items to persist. Defaults to false.
  If set to `true`, maps to the `'history'` option.

  _Only in global sessions._
* **input_history**? `(integer|boolean)`\
  Maximum number of input history items to persist. Defaults to false.
  If set to `true`, maps to the `'history'` option.

  _Only in global sessions._
* **expr_history**? `boolean`\
  Persist expression history. Defaults to false.
  **Note**: Cannot set limit (currently), no direct support by neovim.

  _Only in global sessions._
* **debug_history**? `boolean`\
  Persist debug history. Defaults to false.
  **Note**: Cannot set limit (currently), no direct support by neovim.

  _Only in global sessions._
* **meta**? `table`\
  External data remembered in association with this session. Useful to build on top of the core API.
* **attach**? `boolean`\
  Attach to/stay attached to session after operation
* **reset**? `(boolean|"auto")`\
  When detaching a session in the process, unload associated resources/reset
  everything during the operation when restoring a snapshot.
  `auto` resets only for global sessions.
* **save**? `boolean`\
  Save/override autosave config for affected sessions before the operation
* **silence_errors**? `boolean`\
  Don't error during this operation


<a id="finni.session.SaveOpts"></a>
### `finni.session.SaveOpts` (Alias)

**Type:** `(`[`finni.session.DirParam`](<#finni.session.DirParam>)` & `[`finni.core.Session.InitOptsWithMeta`](<#finni.core.Session.InitOptsWithMeta>)` & `[`finni.SideEffects.Attach`](<#finni.SideEffects.Attach>)` & `[`finni.SideEffects.Notify`](<#finni.SideEffects.Notify>)` & `[`finni.SideEffects.Reset`](<#finni.SideEffects.Reset>)`)`

API options for `session.save`

**Fields:**

* **dir**? `string`\
  Name of session directory (overrides config.dir)
* **autosave_enabled**? `boolean`\
  When this session is attached, automatically save it in intervals. Defaults to false.
* **autosave_interval**? `integer`\
  Seconds between autosaves of this session, if enabled. Defaults to 60.
* **autosave_notify**? `boolean`\
  Trigger a notification when autosaving this session. Defaults to true.
* **on_attach**? [`finni.core.Session.AttachHook`](<#finni.core.Session.AttachHook>)\
  A function that's called when attaching to this session. No global default.
* **on_detach**? [`finni.core.Session.DetachHook`](<#finni.core.Session.DetachHook>)\
  A function that's called when detaching from this session. No global default.
* **options**? `string[]`\
  Save and restore these Neovim (global|buffer|tab|window) options.
* **buf_filter**? [`finni.BufFilter`](<#finni.BufFilter>)\
  Function that decides whether a buffer should be included in a snapshot.
* **tab_buf_filter**? [`finni.TabBufFilter`](<#finni.TabBufFilter>)\
  Function that decides whether a buffer should be included in a tab-scoped snapshot.
  `buf_filter` is called first, this is to refine acceptable buffers only.
* **modified**? `(boolean|"auto")`\
  Save/load modified buffers and their undo history.
  If set to `auto` (default), does not save, but still restores modified buffers.
* **jumps**? `boolean`\
  Save/load window-specific jumplists, including current position
  (yes, for **all windows**, not just the active one like with ShaDa).
  If set to `auto` (default), does not save, but still restores saved jumplists.
* **changelist**? `boolean`\
  Save/load buffer-specific changelist (all buffers) and
  changelist position (visible buffers only).

  **Important**: Enabling this causes **buffer-local marks to be cleared** during restoration.
  Consider tracking `local_marks` in addition to this.
* **global_marks**? `boolean`\
  Save/load global marks (A-Z, not 0-9 currently).

  _Only in global sessions._
* **local_marks**? `boolean`\
  Save/load buffer-specific (local) marks.

  **Note**: Enable this if you track the `changelist`.
* **search_history**? `(integer|boolean)`\
  Maximum number of search history items to persist. Defaults to false.
  If set to `true`, maps to the `'history'` option.

  _Only in global sessions._
* **command_history**? `(integer|boolean)`\
  Maximum number of command history items to persist. Defaults to false.
  If set to `true`, maps to the `'history'` option.

  _Only in global sessions._
* **input_history**? `(integer|boolean)`\
  Maximum number of input history items to persist. Defaults to false.
  If set to `true`, maps to the `'history'` option.

  _Only in global sessions._
* **expr_history**? `boolean`\
  Persist expression history. Defaults to false.
  **Note**: Cannot set limit (currently), no direct support by neovim.

  _Only in global sessions._
* **debug_history**? `boolean`\
  Persist debug history. Defaults to false.
  **Note**: Cannot set limit (currently), no direct support by neovim.

  _Only in global sessions._
* **meta**? `table`\
  External data remembered in association with this session. Useful to build on top of the core API.
* **attach**? `boolean`\
  Attach to/stay attached to session after operation
* **notify**? `boolean`\
  Notify on success
* **reset**? `boolean`\
  When detaching a session in the process, unload associated resources/reset
  everything during the operation when restoring a snapshot.


<a id="finni.SideEffects.Attach"></a>
### `finni.SideEffects.Attach` (Class)

**Fields:**

* **attach**? `boolean`\
  Attach to/stay attached to session after operation

<a id="finni.SideEffects.Notify"></a>
### `finni.SideEffects.Notify` (Class)

**Fields:**

* **notify**? `boolean`\
  Notify on success

<a id="finni.SideEffects.Reset"></a>
### `finni.SideEffects.Reset` (Class)

**Fields:**

* **reset**? `boolean`\
  When detaching a session in the process, unload associated resources/reset
  everything during the operation when restoring a snapshot.

<a id="finni.SideEffects.ResetAuto"></a>
### `finni.SideEffects.ResetAuto` (Class)

**Fields:**

* **reset**? `(boolean|"auto")`\
  When detaching a session in the process, unload associated resources/reset
  everything during the operation when restoring a snapshot.
  `auto` resets only for global sessions.

<a id="finni.SideEffects.Save"></a>
### `finni.SideEffects.Save` (Class)

**Fields:**

* **save**? `boolean`\
  Save/override autosave config for affected sessions before the operation

<a id="finni.SideEffects.SilenceErrors"></a>
### `finni.SideEffects.SilenceErrors` (Class)

**Fields:**

* **silence_errors**? `boolean`\
  Don't error during this operation

<a id="finni.TabBufFilter"></a>
### `finni.TabBufFilter` (Alias)

**Type:** `fun(tabpage: integer, bufnr: integer, opts: `[`finni.core.snapshot.CreateOpts`](<#finni.core.snapshot.CreateOpts>)`) -> boolean`

Function that decides whether a buffer should be included in a tab-scoped snapshot.
BufFilter is called first, this is to refine acceptable buffers only.


<a id="finni.UserConfig.autosession"></a>
### `finni.UserConfig.autosession` (Class)

Configure autosession behavior and contents

**Fields:**

* **config**? [`finni.core.Session.InitOpts`](<#finni.core.Session.InitOpts>)\
  Save/load configuration for autosessions.
  Definitions in here override the defaults in `session`.

  Table fields:

  * **autosave_enabled**? `boolean`\
    When this session is attached, automatically save it in intervals. Defaults to false.
  * **autosave_interval**? `integer`\
    Seconds between autosaves of this session, if enabled. Defaults to 60.
  * **autosave_notify**? `boolean`\
    Trigger a notification when autosaving this session. Defaults to true.
  * **on_attach**? [`finni.core.Session.AttachHook`](<#finni.core.Session.AttachHook>)\
    A function that's called when attaching to this session. No global default.
  * **on_detach**? [`finni.core.Session.DetachHook`](<#finni.core.Session.DetachHook>)\
    A function that's called when detaching from this session. No global default.
  * **options**? `string[]`\
    Save and restore these Neovim (global|buffer|tab|window) options.
  * **buf_filter**? [`finni.BufFilter`](<#finni.BufFilter>)\
    Function that decides whether a buffer should be included in a snapshot.
  * **tab_buf_filter**? [`finni.TabBufFilter`](<#finni.TabBufFilter>)\
    Function that decides whether a buffer should be included in a tab-scoped snapshot.
    `buf_filter` is called first, this is to refine acceptable buffers only.
  * **modified**? `(boolean|"auto")`\
    Save/load modified buffers and their undo history.
    If set to `auto` (default), does not save, but still restores modified buffers.
  * **jumps**? `boolean`\
    Save/load window-specific jumplists, including current position
    (yes, for **all windows**, not just the active one like with ShaDa).
    If set to `auto` (default), does not save, but still restores saved jumplists.
  * **changelist**? `boolean`\
    Save/load buffer-specific changelist (all buffers) and
    changelist position (visible buffers only).

    **Important**: Enabling this causes **buffer-local marks to be cleared** during restoration.
    Consider tracking `local_marks` in addition to this.
  * **global_marks**? `boolean`\
    Save/load global marks (A-Z, not 0-9 currently).

    _Only in global sessions._
  * **local_marks**? `boolean`\
    Save/load buffer-specific (local) marks.

    **Note**: Enable this if you track the `changelist`.
  * **search_history**? `(integer|boolean)`\
    Maximum number of search history items to persist. Defaults to false.
    If set to `true`, maps to the `'history'` option.

    _Only in global sessions._
  * **command_history**? `(integer|boolean)`\
    Maximum number of command history items to persist. Defaults to false.
    If set to `true`, maps to the `'history'` option.

    _Only in global sessions._
  * **input_history**? `(integer|boolean)`\
    Maximum number of input history items to persist. Defaults to false.
    If set to `true`, maps to the `'history'` option.

    _Only in global sessions._
  * **expr_history**? `boolean`\
    Persist expression history. Defaults to false.
    **Note**: Cannot set limit (currently), no direct support by neovim.

    _Only in global sessions._
  * **debug_history**? `boolean`\
    Persist debug history. Defaults to false.
    **Note**: Cannot set limit (currently), no direct support by neovim.

    _Only in global sessions._
* **dir**? `string`\
  Name of the directory to store autosession projects in.
  Interpreted relative to `$XDG_STATE_HOME/$NVIM_APPNAME`.
  Defaults to `finni`.
* **spec**? [`finni.auto.SpecHook`](<#finni.auto.SpecHook>)\
  This function implements the logic that derives the autosession spec from a path,
  usually the current working directory. If it returns an autosession spec, Finni
  automatically switches to the session's workspace root and tries to restore an
  existing matching session (matched by project name + session name).
  If it returns nothing, it's interpreted as "no autosession should be active".

  It is called during various points in Finni's lifecycle:
  1. Neovim startup (if startup autosessions are enabled)
  2. When Neovim changes its global working directory
  3. When a git branch is switched (if you have installed gitsigns.nvim)

  If the return value does not match the current state, the currently active
  session (if any) is saved + closed and the new session (if any) restored.

  The default implementation calls `workspace`, `project_name`, `session_name`,
  `enabled` and `load_opts` to piece together the specification.
  By overriding this config field, you can implement a custom logic.
  Mind that the other hooks have no effect then (unless you call them manually).
* **workspace**? [`finni.auto.WorkspaceHook`](<#finni.auto.WorkspaceHook>)\
  Receive the effective nvim cwd, return workspace root and whether it is git-tracked.
* **project_name**? [`finni.auto.ProjectNameHook`](<#finni.auto.ProjectNameHook>)\
  Receive the workspace root dir and whether it's git-tracked, return the project-specific session directory name.
* **session_name**? [`finni.auto.SessionNameHook`](<#finni.auto.SessionNameHook>)\
  Receive the effective nvim cwd, the workspace root, the project name and workspace repo git info and generate a session name.
* **enabled**? [`finni.auto.EnabledHook`](<#finni.auto.EnabledHook>)\
  Receive the effective nvim cwd, the workspace root and project name and decide
  whether an autosession with this configuration should be active.
* **load_opts**? [`finni.auto.LoadOptsHook`](<#finni.auto.LoadOptsHook>)\
  Influence how an autosession is loaded/persisted, e.g. load the session without attaching it or disable modified persistence.
  Merged on top of the default autosession configuration for this specific autosession only.

<a id="finni.UserConfig.load"></a>
### `finni.UserConfig.load` (Class)

Configure session list information detail and sort order

**Fields:**

* **detail**? `boolean`\
  Show more detail about the sessions when selecting one to load.
  Disable if it causes lag.
* **order**? `("modification_time"|"creation_time"|"filename")`\
  Session list order

<a id="finni.UserConfig.log"></a>
### `finni.UserConfig.log` (Class)

Configure plugin logging

**Fields:**

* **level**? `("trace"|"debug"|"info"|"warn"|"error"|"off")`\
  Minimum level to log at. Defaults to `warn`.
* **notify_level**? `("trace"|"debug"|"info"|"warn"|"error"|"off")`\
  Minimum level to use `vim.notify` for. Defaults to `warn`.
* **notify_opts**? `table`\
  Options to pass to `vim.notify`. Defaults to `{ title = "Finni" }`
* **format**? `string`\
  Log line format string. Note that this works like Python's f-strings.
  Defaults to `[%(level)s %(dtime)s] %(message)s%(src_sep)s[%(src_path)s:%(src_line)s]`.
  Available parameters:
  * `level` Uppercase level name
  * `message` Log message
  * `dtime` Formatted date/time string
  * `hrtime` Time in `[ns]` without absolute anchor
  * `src_path` Path to the file that called the log function
  * `src_line` Line in `src_path` that called the log function
  * `src_sep` Whitespace between log line and source of call, 2 tabs for single line, newline + tab for multiline log messages
* **notify_format**? `string`\
  Same as `format`, but for `vim.notify` message display. Defaults to `%(message)s`.
* **time_format**? `string`\
  `strftime` format string used for rendering time of call. Defaults to `%Y-%m-%d %H:%M:%S`
* **handler**? `fun(line: `[`finni.log.Line`](<#finni.log.Line>)`)`

<a id="finni.UserConfig.session"></a>
### `finni.UserConfig.session` (Class)

Configure default session behavior and contents, affects both manual and autosessions.

**Fields:**

* **autosave_enabled**? `boolean`\
  When this session is attached, automatically save it in intervals. Defaults to false.
* **autosave_interval**? `integer`\
  Seconds between autosaves of this session, if enabled. Defaults to 60.
* **autosave_notify**? `boolean`\
  Trigger a notification when autosaving this session. Defaults to true.
* **on_attach**? [`finni.core.Session.AttachHook`](<#finni.core.Session.AttachHook>)\
  A function that's called when attaching to this session. No global default.
* **on_detach**? [`finni.core.Session.DetachHook`](<#finni.core.Session.DetachHook>)\
  A function that's called when detaching from this session. No global default.
* **options**? `string[]`\
  Save and restore these Neovim (global|buffer|tab|window) options.
* **buf_filter**? [`finni.BufFilter`](<#finni.BufFilter>)\
  Function that decides whether a buffer should be included in a snapshot.
* **tab_buf_filter**? [`finni.TabBufFilter`](<#finni.TabBufFilter>)\
  Function that decides whether a buffer should be included in a tab-scoped snapshot.
  `buf_filter` is called first, this is to refine acceptable buffers only.
* **modified**? `(boolean|"auto")`\
  Save/load modified buffers and their undo history.
  If set to `auto` (default), does not save, but still restores modified buffers.
* **jumps**? `boolean`\
  Save/load window-specific jumplists, including current position
  (yes, for **all windows**, not just the active one like with ShaDa).
  If set to `auto` (default), does not save, but still restores saved jumplists.
* **changelist**? `boolean`\
  Save/load buffer-specific changelist (all buffers) and
  changelist position (visible buffers only).

  **Important**: Enabling this causes **buffer-local marks to be cleared** during restoration.
  Consider tracking `local_marks` in addition to this.
* **global_marks**? `boolean`\
  Save/load global marks (A-Z, not 0-9 currently).

  _Only in global sessions._
* **local_marks**? `boolean`\
  Save/load buffer-specific (local) marks.

  **Note**: Enable this if you track the `changelist`.
* **search_history**? `(integer|boolean)`\
  Maximum number of search history items to persist. Defaults to false.
  If set to `true`, maps to the `'history'` option.

  _Only in global sessions._
* **command_history**? `(integer|boolean)`\
  Maximum number of command history items to persist. Defaults to false.
  If set to `true`, maps to the `'history'` option.

  _Only in global sessions._
* **input_history**? `(integer|boolean)`\
  Maximum number of input history items to persist. Defaults to false.
  If set to `true`, maps to the `'history'` option.

  _Only in global sessions._
* **expr_history**? `boolean`\
  Persist expression history. Defaults to false.
  **Note**: Cannot set limit (currently), no direct support by neovim.

  _Only in global sessions._
* **debug_history**? `boolean`\
  Persist debug history. Defaults to false.
  **Note**: Cannot set limit (currently), no direct support by neovim.

  _Only in global sessions._
* **dir**? `string`\
  Name of the directory to store regular sessions in.
  Interpreted relative to `$XDG_STATE_HOME/$NVIM_APPNAME`.
