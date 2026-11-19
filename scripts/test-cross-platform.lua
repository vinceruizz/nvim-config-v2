local installer = dofile('scripts/install.lua')
local uv = vim.uv
local root = vim.fn.tempname()
vim.fn.mkdir(root, 'p')
local count = 0
local function test(name, fn)
 fn(); count=count+1; print('PASS: '..name)
end
local ok, err = xpcall(function()
 test('OS/architecture dispatch', function()
  for _, case in ipairs({{'Darwin','arm64','macos','arm64'}, {'Linux','x86_64','linux','x64'}, {'Windows_NT','AMD64','windows','x64'}, {'Windows_NT','ARM64','windows','arm64'}}) do
   local os,arch=installer.platform(case[1],case[2]); assert(os==case[3] and arch==case[4])
  end
  assert(not pcall(installer.platform,'FreeBSD','x86_64'))
 end)
 local source = root .. '/source'
 vim.fn.mkdir(source .. '/lua/config', 'p'); vim.fn.mkdir(source .. '/scripts', 'p'); vim.fn.mkdir(source .. '/colors', 'p')
 for _, name in ipairs({'init.lua','lazy-lock.json','install.sh','install.ps1','README.md','DEBUGGING.md','lua/config/file.lua','scripts/install.lua','colors/forest-cartridge.lua'}) do
  vim.fn.writefile({'source ' .. name}, source .. '/' .. name)
 end
 vim.fn.writefile({'do not deploy'}, source .. '/.private')
 local target = root .. '/config with spaces'
 test('config copy and exclusion', function()
  installer.deploy(source,target)
  assert(vim.fn.readfile(target..'/init.lua')[1]=='source init.lua')
  assert(not uv.fs_stat(target..'/.private'))
  assert(uv.fs_stat(target..'/colors/forest-cartridge.lua'))
 end)
 test('existing config backup', function()
  vim.fn.writefile({'keep'},target..'/custom')
  local backup=installer.deploy(source,target)
  assert(vim.fn.readfile(backup..'/custom')[1]=='keep')
 end)
 test('nested target and ancestor rejection', function()
  assert(not pcall(installer.deploy,source,source..'/child'))
  assert(not pcall(installer.deploy,source,root))
 end)
 test('rollback', function()
  local rollback=root..'/rollback'
  vim.fn.mkdir(rollback,'p');vim.fn.writefile({'original'},rollback..'/keep')
  local rename=uv.fs_rename
  uv.fs_rename=function(from,to)
   if from:find('.install-',1,true) then return nil,'injected failure' end
   return rename(from,to)
  end
  local deployed=pcall(installer.deploy,source,rollback)
  uv.fs_rename=rename
  assert(not deployed)
  assert(vim.fn.readfile(rollback..'/keep')[1]=='original')
 end)
 test('in-place snapshot', function()
  local snapshot=installer.deploy(source,source)
  assert(vim.fn.readfile(snapshot..'/.private')[1]=='do not deploy')
 end)
 test('dry run never runs commands', function()
  local command=installer.run_command
  installer.run_command=function() error('must not run') end
  installer.install({dry_run=true})
  installer.run_command=command
 end)
 test('Windows cmd wrapper quoting', function()
  local system=vim.system
  local captured
  vim.system=function(cmd) captured=cmd; return {wait=function() return {code=0,stdout=''} end} end
  installer.run_command({[[C:\Users\A B\npm.cmd]], 'install', [[a'b]]},true)
  vim.system=system
  assert(captured[1]=='powershell.exe')
  assert(captured[#captured]:find("'a''b'",1,true))
 end)
 print('PASS: '..count..' installer checks')
end,debug.traceback)
vim.fn.delete(root,'rf')
if not ok then print(err) end
vim.cmd(ok and 'qa!' or 'cquit')
