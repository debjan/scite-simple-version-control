setting = {                             
    Hg = "hg.exe",                      -- Path to `hg.exe` (if available and not in %PATH%)
    Git = "c:/Program Files (x86)/Git/bin/git.exe",  -- Path to `git.exe` (if available and not in %PATH%)
    TortoiseHg = "thg.exe",             -- Path to `thg.exe`, if using Tortoise is enabled
    TortoiseGit = "TortoiseGitProc.exe",-- Path to `TortoiseGitProc.exe`, if using Tortoise is enabled
    spawner_path = "lua/spawner.dll",   -- Path to `spawner.dll`
    allow_destroy = true,               -- Option to make destroy command available
    tortoise = false,                   -- Option to run through Tortoise GUI dialogs instead console
    dialog = true,                      -- Option to use SciTE strip wrapper dialog for commit massage (overrides OnStrip())
    command_number = 30,                -- Free SciTE command number slot
}

local fn, err
fn, err = package.loadlib(setting.spawner_path, 'luaopen_spawner')
if fn then fn() else print('spawner.dll: ' .. err) end

session = {['control']={}, ['status']={}, ['stamp']={}}

cn = setting.command_number
local context = props["user.context.menu"]
local vc_context = ("||%s|11%s|"):format("Version Control", cn)
if not context:find(vc_context) then
    props["user.context.menu"] = context..vc_context
    props["command." .. cn .. ".*"] = "scite_vc"
    props["command.mode." .. cn .. ".*"] = "subsystem:lua"
end

if not session['ver'] and spawner then
    local ver = spawner.popen("ver"):read("*a"):gsub("\n", "")
    local v = (string.find(ver, "Version"))+8
    session['ver'] = tonumber(ver:sub(v, v))
end

if setting.dialog then
    function OnStrip(control, change)
        if change == 1 and control == 2 then
            local msg = scite.StripValue(1)
            local vcs, cmd; vcs, cmd = scite.StripValue(0):match("(%w+):(%w+)")
            if msg:len() > 0 then
                print(spawner.popen(("cd %q & %q %s %q -m %q && echo %s"):format(props['FileDir'], setting[vcs], VC.arg[vcs][cmd][1], props['FileNameExt'], msg, msg)):read("*a"))
                VC.update_status()
            end
            scite.StripShow("")
        end
    end
end

VC = {
    arg = {
        Hg = {
            Log    = {"log -G -v", "log "},
            Diff   = {"diff", "vdiff "},
            Add    = {"add ", "add "},
            Commit = {"commit", "commit "},
            Revert = {"revert", "revert "},
            Remove = {"forget", "remove "},
            Status = {"status -A", "status "},
            Root   = "root",
            Code   = "status -A"
        },
        Git = {
            Log    = {"log --graph", "/command:log /path:"},
            Diff   = {"diff", "/command:diff /path:"},
            Add    = {"add", "/command:add /path:"},
            Commit = {"commit", "/command:commit /path:"},
            Revert = {"checkout", "/command:revert /path:"},
            Remove = {"rm --cached", "/command:remove /path:"},
            Status = {"status -u", "/command:repostatus /path:"},
            Root   = "rev-parse --show-toplevel",
            Code   = "status --porcelain -u"
        }
    },
    init = function()
        ctrl = session.control
        ctrl.hg = ctrl.hg or VC.check_path(setting['Hg'])
        ctrl.git = ctrl.git or VC.check_path(setting['Git'])
        if ctrl[props['FilePath']] then
            VC.userlist(ctrl[props['FilePath']])
        elseif ctrl.hg and VC.project("Hg"):sub(1,1) ~= 'a' then
            ctrl[props['FilePath']] = "Hg"; VC.userlist("Hg")
        elseif ctrl.git and VC.project("Git"):sub(1,1) ~= 'f' then
            ctrl[props['FilePath']] = "Git"; VC.userlist("Git")
        else
            if ctrl.hg and ctrl.git then
                if scite_UserListShow then scite_UserListShow(VC.token("Hg:Init Git:Init"), 1, VC.init_repo)
                else
                    OnUserListSelection = function(n, l) return VC.init_repo(l) end
                    editor:UserListShow(3, "Hg:Init Git:Init")
                end
            elseif ctrl.hg then VC.userlist("Hg")
            elseif ctrl.git then VC.userlist("Git")
            end
        end
    end,
    project = function(s)
        return spawner.popen(('cd %q & %q %s %q'):format(props['FileDir'], setting[s], VC.arg[s]['Code'], props['FileNameExt'])):read('*a') .. 'C'
    end,
    check_path = function(f)
        if VC.exist(f) then return true
        else return spawner.popen('for %f in (' .. f .. ') do @if "%~$PATH:f"=="" (echo false) else (echo true)'):read('*a'):gsub('\n', '') end
    end,
    exist = function(f)
        return spawner.popen(('if exist %q (echo true) else (echo false)'):format(f)):read('*a'):gsub('\n', '') ~= 'true'
    end,
    token = function(s)
        local l = {}
        for v in string.gmatch(s, "%S+") do l[#l+1] = v end
        return l
    end,
    commands = function(idx)
        local str_list = ''
        local cmds = {"Add", "Commit", "Diff", "Log", "Revert", "Remove", "Status", "Destroy"}
        for i, v in ipairs(idx) do str_list = str_list .. ' ' .. cmds[v] end
        return str_list:sub(2)
    end,
    update_status = function()
        session.status[props['FilePath']] = (VC.project(ctrl[props['FilePath']]):gsub(' ','')):sub(1,1)
        if session.status[props['FilePath']]:gsub("f", "a") == "a" then session.status[props['FilePath']], ctrl[props['FilePath']] = nil end
    end,
    userlist = function(s)
        if session['ver'] > 5 then
            local dt = spawner.popen('forfiles /p '..props['FileDir']..' /m '..props['FileNameExt']..' /c "cmd /c echo @fdate @ftime"'):read('*a'):gsub('\n', '')
            if session.stamp[props['FilePath']] ~= dt then VC.update_status() end
            session.stamp[props['FilePath']] = dt
        else VC.update_status() end
        local code = session.status[props['FilePath']]
        if code == '?' then idx = {1}; if setting.allow_destroy then idx[#idx+1] = 8 end
        elseif code == 'M' then idx = {2,3,4,5,7}
        elseif code == 'C' or code == " " then idx = {4,6,7}; if setting.allow_destroy then idx[#idx+1] = 8 end
        elseif code == 'A' then idx = {2,3,4,5,7}
        elseif code == 'R' or code == 'D' then idx = {2,4,5,7}
        else idx = {7} end
        if scite_UserListShow then scite_UserListShow(VC.token(((VC.commands(idx)):gsub('(%w+)', s .. ':%1'))), 1, VC.ctrl_repo)
        else 
            OnUserListSelection = function(n, l) return VC.ctrl_repo(l) end
            editor:UserListShow(3, ((VC.commands(idx)):gsub('(%w+)', s .. ':%1')))
        end
    end,
    init_repo = function(c)
        ctrl[props['FilePath']] = c:gsub(":Init", "")
        local exe = setting[c:gsub(":Init", "")]
        print(spawner.popen(("cd %q & %q init && %q add %q && %q commit -m init"):format(props['FileDir'], exe, exe, props['FilePath'], exe)):read("*a"))
        VC.ctrl_repo('Status')
        VC.update_status()
    end,
    ctrl_repo = function(c)
        local vcs, cmd; vcs, cmd = ctrl[props['FilePath']], c:gsub("(%a+:)", "")
        if c == vcs .. ":Destroy" then
            local project_root = spawner.popen(('cd %q & %q %s'):format(props['FileDir'], setting[vcs], VC.arg[vcs]['Root'])):read('*a'):gsub('\n', '') .. '/.' .. vcs:lower()
            spawner.popen(('if exist %q rd /s /q %q'):format(project_root, project_root))
        else
            if setting.tortoise and VC.check_path(setting["Tortoise" .. vcs]) then
                spawner.popen(("cd %q & %q %s%q"):format(props['FileDir'], setting["Tortoise" .. vcs], VC.arg[vcs][cmd][2], props['FileNameExt']))
            else
                scite.MenuCommand(IDM_CLEAROUTPUT)
                if c == vcs .. ":Commit" and setting.dialog then VC.dialog(c) else
                print(spawner.popen(("cd %q & %q %s %q"):format(props['FileDir'], setting[vcs], VC.arg[vcs][cmd][1], props['FileNameExt'])):read("*a")) end
            end
        end
        VC.update_status()
    end,
    dialog = function(s)
        scite.StripShow("!'" .. s .. "'[]((OK))(Cancel)")
    end
}
scite_vc = VC.init
