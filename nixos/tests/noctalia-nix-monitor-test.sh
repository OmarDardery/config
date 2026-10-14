#!/usr/bin/env bash
# Execute the patched Luau service and panel with isolated host API fixtures.
set -euo pipefail
plugin=$1
luau=$2
fixture=$(mktemp --suffix=.luau)
trap 'rm -f -- "$fixture"' EXIT
cat > "$fixture" <<'LUA'
local values, files, remoteCalls = {}, {}, {}
local launch = true
local notifications = {}
local tick = 1000
local notifyChecks = false
local config = {
 branch="nixos-26.05", system_stats_check_mode="off",
 update_check_duration_threshold=5, update_check_interval=60,
 generation_check_interval=60, system_stats_check_interval=60,
 panel_card_color="background", panel_card_opacity=100,
 hide_optimize_button=true, hide_clean_button=true,
}
-- Controllable time distinguishes last attempt from last successful check.
os = {time=function() return tick end}
noctalia = {
 setUpdateInterval=function() end, tr=function(key) return key end,
 getConfig=function(key)
  if key == "show_update_check_notification" then return notifyChecks end
  return config[key]
 end,
 state={get=function(k) return values[k] end, set=function(k,v) values[k]=v end, watch=function() end},
 pluginDataDir=function() return "/fixture's data" end,
 commandExists=function() return false end,
 mkdirAll=function() end,
 writeFile=function(p,v) files[p]=v end,
 readFile=function(p) return files[p] end,
 removeFile=function(p) files[p]=nil end,
 string={trim=function(s) return string.match(s,"^%s*(.-)%s*$") end},
 notify=function(s) table.insert(notifications,s) end,
 notifyError=function(s) table.insert(notifications,s) end,
 formatTime=function() return tostring(tick) end,
 runAsync=function(command, callback, timeout)
  if string.find(command,"github.com",1,true) then
   if not launch then return false end
   table.insert(remoteCalls,{command=command, callback=callback, timeout=timeout})
  end
  return true
 end,
}
LUA
cat "$plugin/nix_monitor_service.luau" >> "$fixture"
cat >> "$fixture" <<'LUA'
local serviceUpdate = update
local function finish(result)
 remoteCalls[#remoteCalls].callback(result)
 serviceUpdate()
 assert(values.isRemoteCheckRunning == false)
end
local good = string.rep("a",40) .. "\trefs/heads/nixos-26.05\n"
values.localHash="bbbbbbb"
assert(#remoteCalls == 1)
assert(remoteCalls[1].timeout == 60000)
assert(not remoteCalls[1].command:find("|",1,true))
assert(remoteCalls[1].command:find("'refs/heads/nixos-26.05'",1,true))
finish({exitCode=0, stdout=good})
assert(values.remoteHash == "aaaaaaa" and values.remoteHashFresh)
assert(values.isUpdateAvailable and values.remoteCheckError == "")
local lastSuccess=values.lastRemoteCheckTimeStr
print("PASS: successful exact-ref hash validation")
local failures={
 {exitCode=17, stdout=good}, -- Failure cannot be hidden by plausible output.
 {exitCode=124, stdout=""}, -- Host timeout.
 {exitCode=0, stdout=""},
 {exitCode=0, stdout="not-a-hash\trefs/heads/nixos-26.05"},
 {exitCode=0, stdout="abcdef0\trefs/heads/nixos-26.05"},
 {exitCode=0, stdout=string.rep("c",40).."\trefs/heads/wrong"},
 {exitCode=0, stdout=good..good},
}
for _, result in failures do
 tick += 10
 checkRemoteHash()
 finish(result)
 assert(values.remoteHash == "aaaaaaa" and not values.remoteHashFresh)
 assert(not values.isUpdateAvailable and values.remoteCheckError ~= "")
 assert(values.lastRemoteCheckTimeStr == lastSuccess)
 assert(values.lastRemoteCheckTime == tick)
end
print("PASS: failure, timeout, empty, malformed, short, wrong-ref and multiple results mark stale")
launch=false
checkRemoteHash()
assert(not values.isRemoteCheckRunning and not values.remoteHashFresh)
assert(values.remoteCheckError ~= "" and not values.isUpdateAvailable)
launch=true
notifyChecks=true
checkRemoteHash()
local count=#remoteCalls
checkRemoteHash()
assert(#remoteCalls == count) -- Overlapping checks remain suppressed.
finish({exitCode=1})
assert(#notifications >= 2)
print("PASS: launch refusal, overlap prevention and configured failure notification")
checkRemoteHash()
finish({exitCode=0, stdout=string.rep("B",64).."\trefs/heads/nixos-26.05"})
assert(values.remoteHash == "bbbbbbb" and values.remoteHashFresh)
assert(not values.isUpdateAvailable and values.remoteCheckError == "")
assert(values.lastRemoteCheckTimeStr ~= lastSuccess)
print("PASS: successful retry clears error; equal hashes suppress update status")
-- Panel fixtures retain node labels for user-visible behavior assertions.
local tree
ui={}
for _,name in {"column","row","glyph","label","separator","button","spacer"} do
 ui[name]=function(props,children) return {kind=name, props=props, children=children or {}} end
end
panel={render=function(t) tree=t end}
LUA
cat "$plugin/panel.luau" >> "$fixture"
cat >> "$fixture" <<'LUA'
local function hasText(node,expected)
 if node.props.text and string.find(node.props.text,expected,1,true) then return true end
 for _, child in node.children do if hasText(child,expected) then return true end end
 return false
end
onOpen()
assert(not hasText(tree,"(stale)"))
values.remoteHashFresh=false
values.remoteCheckError="Update check failed. Try again."
onOpen()
assert(hasText(tree,"bbbbbbb (stale)"))
assert(hasText(tree,"Update check failed. Try again."))
print("PASS: panel displays stale hash and failure; fresh hash has no stale label")
LUA
"$luau" "$fixture"
