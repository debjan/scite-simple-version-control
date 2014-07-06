Simple Version Control for SciTE
===

Lua script, as SciTE extension that allows simple version control on local files.  
Supported versioning system are Git and Mercurial.  
Supported Operating System is Windows.  

Requirements
---
Except obvious requirements (SciTE and versioning system) script requires `spawner.dll` (can be found i.e. in [scite-debug archive](http://files.luaforge.net/releases/scitedebug/scitedebug/0.9.1) as `spawner-ex.dll`) which takes care of "silent" command execution (no popup windows).

Installation
---
Script can be installed by executing from Lua startup script:

`dofile("C:\\<path-to>\\SciTE_VC.lua") `

or by copying the script in `scite_lua` folder, in case of using `extman.lua`.

Settings
---
Setting the script is provided by editing `setting` table inside the script:
``` lua
setting = {                             
    Hg = "hg.exe",                      
    Git = "c:/Program Files (x86)/Git/bin/git.exe",  							
    TortoiseHg = "thg.exe",
    TortoiseGit = "TortoiseGitProc.exe",
    spawner_path = "lua/spawner.dll",   
    allow_destroy = true,               
    tortoise = false,                   
    dialog = true,                      
    command_number = 30,                
}
```

|Property|Value|
|-------|-----|
|Hg|Path to `hg.exe` (if available and not in %PATH%)|
|Git|Path to `git.exe` (if available and not in %PATH%)|
|TortoiseHg|Path to `thg.exe`, if using Tortoise is enabled|
|TortoiseGit|Path to `TortoiseGitProc.exe`, if using Tortoise is enabled|
|spawner_path|Path to `spawner.dll`|
|allow_destroy|Option to make destroy command available|
|tortoise|Option to run through Tortoise GUI dialogs instead console|
|dialog|Option to use SciTE strip wrapper dialog for commit massage (overrides existing)|
|command_number|SciTE command number free slot |


Walkthrough
---
While editing file, version control can be initialized by selecting __Version Control__ context menu:

![](http://i.imgur.com/xdKVlWs.png)

After clicking on it, calltip pops with available versioning system initializers:

![](http://i.imgur.com/v5JmGhf.png)

By clicking on one of available initializers, edited file is automatically added to a versioning system and committed with __init__ message.

Depending on edited file status, Version Control context menu, will provide appropriate commands. For example, if we make some edits and save the file, then we'll have these commands available:

![](http://i.imgur.com/EFf2wL6.png)

Because the file status is __[M]odified__.

Regardless of versioning system used, workflow is identical with either Git or Mercurial.

If we select __Commit__ command and __dialog__ value in `setting` table is set to `true`, we are offered to supply commit message in strip dialog:

![](http://i.imgur.com/Egjqsqa.png)

While if __dialog__ option is set to `false`, Notepad will open with temporary file for commit message as set by versioning system. And of course if Tortoise is used, then all communication will be through Tortoise GUI dialogs instead SciTE output pane.

If option __allow_destroy__ is set to `true`, additional command will be available that can delete project index folder (`.git` or `.hg`) thus destroying versioning project irreversibly.

![](http://i.imgur.com/bOwXyCU.png)
