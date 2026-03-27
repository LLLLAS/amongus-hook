if (not game:IsLoaded()) then
	game.Loaded:Wait();
end;

local Players      = game:GetService('Players');
local LocalPlayer  = Players.LocalPlayer;

if (not LocalPlayer) then
	Players:GetPropertyChangedSignal('LocalPlayer'):Wait();
	LocalPlayer = Players.LocalPlayer;
end;

local selfKicked = false;
local function kickPlayer(reason)
	if (selfKicked) then return; end;
	selfKicked = true;
	LocalPlayer:Kick(`[amongus.hook] {reason}`);
end;

local executor   = identifyexecutor and identifyexecutor() or 'Unknown';
local messagebox = messageboxasync or messagebox;
local request    = request or http_request;
local loadstring = loadstring;

if (type(messagebox) ~= 'function') then
	return kickPlayer(`"messagebox" missing ( {executor} )`);
end;

local function protectedMessagebox(body, title, id)
	local success, output = pcall(messagebox, body, title, id);
	if (success) then return output; end;

	-- Retry with fallback id
	local success2, output2 = pcall(messagebox, body, title, 1);
	if (success2) then return output2; end;

	kickPlayer(`messagebox failed - {body}`);
	task.wait(9e9);
end;

local function protectedLoad(url, ...)
	local success, response = pcall(request, {Url = url; Method = 'GET'});

	if (not success) then
		protectedMessagebox(`protectedLoad failed(1) - request error\n\nurl: {url}`, `amongus.hook [{executor}]`, 48);
		task.wait(9e9);
		return;
	end;

	if (type(response) ~= 'table' or type(response.Body) ~= 'string' or response.StatusCode ~= 200) then
		protectedMessagebox(`protectedLoad failed(2) - bad response\n\nurl: {url}`, `amongus.hook [{executor}]`, 48);
		task.wait(9e9);
		return;
	end;

	local loader = loadstring(response.Body);
	if (not loader) then
		protectedMessagebox(`protectedLoad failed(3) - syntax error\n\nurl: {url}`, `amongus.hook [{executor}]`, 48);
		task.wait(9e9);
		return;
	end;

	return loader(...);
end;

if (type(loadstring) ~= 'function') then
	return protectedMessagebox(`missing alias ( loadstring ) - unsupported executor`, `amongus.hook [{executor}]`, 48);
elseif (type(request) ~= 'function') then
	return protectedMessagebox(`missing alias ( request ) - unsupported executor`, `amongus.hook [{executor}]`, 48);
end;

local placeID        = game.PlaceId;
local GITHUB_REPO    = 'https://raw.githubusercontent.com/mainstreamed/amongus-hook/refs/heads/main/';
local supportedGames = protectedLoad(`{GITHUB_REPO}supportedGames.lua`);

local requiredFields = {placeIDs = 'table'; executors = 'table'; customMessage = 'table'};

local function runOnGame(gameInfo)
	if (type(gameInfo) ~= 'table') then return false; end;

	for key, expectedType in requiredFields do
		if (type(gameInfo[key]) ~= expectedType) then return false; end;
	end;

	-- Check if this game matches our place
	if (not table.find(gameInfo.placeIDs, placeID)) then
		return false;
	end;

	-- Warn if detected
	if (gameInfo.status ~= 'Undetected' and protectedMessagebox(`{gameInfo.gameName} is currently marked as {gameInfo.status}!\n\nAre you sure you want to continue?`, 'amongus.hook', 52) ~= 6) then
		return true;
	end;

	-- Warn if executor has custom message
	if (gameInfo.customMessage[executor] and protectedMessagebox(`Unstable Executor!\n\n{executor} is marked as {gameInfo.customMessage[executor]} for {gameInfo.gameName}\n\nAre you sure you want to continue?`, `amongus.hook [{executor}]`, 52) ~= 6) then
		return true;
	end;

	-- Warn if executor not officially supported
	if (not gameInfo.customMessage[executor] and not table.find(gameInfo.executors, executor) and protectedMessagebox(`Unsupported Executor!\n\n{executor} is not officially supported for {gameInfo.gameName}\nand may have undefined behaviour or result in a ban!\n\nAre you sure you want to continue?`, `amongus.hook [{executor}]`, 52) ~= 6) then
		return true;
	end;

	protectedLoad(`{GITHUB_REPO}{gameInfo.gitPath}/main.lua`);
	return true;
end;

for _, gameInfo in supportedGames do
	if (runOnGame(gameInfo)) then
		return;
	end;
end;

protectedMessagebox(`This game is unsupported!\n\nIf you believe this is incorrect, please create a bug report in our discord! - discord.gg/2jycAcKvdw`, `amongus.hook [{placeID}]`, 48);
