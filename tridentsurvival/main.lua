local Players     = game:GetService('Players');
local LocalPlayer = Players.LocalPlayer;

if (not LocalPlayer) then
	Players:GetPropertyChangedSignal('LocalPlayer'):Wait();
	LocalPlayer = Players.LocalPlayer;
end;

local GITHUB_REPO = 'https://raw.githubusercontent.com/mainstreamed/amongus-hook/refs/heads/main/';

local source = game:HttpGet(`{GITHUB_REPO}tridentsurvival/obfuscated.lua`);
if (getgenv and getgenv().DEBUG_AMGHOOK) then
	source = `getgenv().DEBUG_AMGHOOK = true;\n{source}`;
end;

-- Drawing fix for Volcano executor (actor context has no Drawing API)
local drawingActorFix = loadstring(game:HttpGet(`{GITHUB_REPO}assets/trident/actorDrawingFix.lua`))();

source = string.format([==[
	if (not Drawing) then
		%s
	end;

	if (type(getgenv) == 'function' and getgenv().setfflag == nil) then
		getgenv().setfflag = function() end;
	end;

]==], drawingActorFix) .. source;

-- Run on actor if parallel Lua is not on main thread
local fastflag = getfflag and getfflag('DebugRunParallelLuaOnMainThread');
if (fastflag == 'true' or fastflag == 'True' or fastflag == true) then
	loadstring(source)();
	return;
elseif (run_on_actor) then
	local actor = getactors and getactors()[1] or LocalPlayer:FindFirstChildWhichIsA('Actor', true);
	if (actor) then
		return run_on_actor(actor, source);
	end;
end;

loadstring(source)();
