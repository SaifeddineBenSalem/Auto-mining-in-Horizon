script_name("StartDJob")
script_description("Automated mining route with on-foot running.")
script_version_number("1")
script_version("1.4")
script_authors("StartDJob")
script_dependencies("None")

local ARRIVAL_THRESHOLD = 1.5
local MINE_WAIT_MS = 12000
local STUCK_MOVE_MIN = 0.08
local STUCK_TICKS = 60
local CAMERA_TURN_STEP = 0.04
local CAMERA_YAW_OFFSET = 0.04253
local RUN_ANGLE_LIMIT = 0.30

local KEY_FORWARD_BACK = 1
local KEY_JUMP = 14
local KEY_SPRINT = 16

local ROUTE = {
	{x = 2747.5422, y = -2077.5195, z = 13.2797, mine = true},
	{x = 2785.6809, y = -2060.8982, z = 11.8509},
	{x = 2787.5459, y = -2069.8757, z = 11.7665},
	{x = 2794.3298, y = -2071.0779, z = 11.5810},
	{x = 2786.2874, y = -2070.1436, z = 11.7928},
	{x = 2785.2290, y = -2063.8965, z = 11.8567},
	{x = 2747.8608, y = -2077.3699, z = 12.9241},
}

local jobRunning = false
local stopRequested = false
local keysHeld = false

local nav = {
	active = false,
	tx = 0.0,
	ty = 0.0,
	tz = 0.0,
}

function main()
	repeat wait(0) until isSampAvailable()
	wait(2000)
	sampAddChatMessage("[StartDJob] {FFFFFF}Loaded - use {FF9E00}/startdjob {FFFFFF}| stop with {FF9E00}/stopdjob", 0xFF9E00)
	sampRegisterChatCommand("startdjob", startdjob)
	sampRegisterChatCommand("stopdjob", stopdjob)
	while true do
		wait(0)
		local shouldDrive = nav.active and jobRunning and not stopRequested and isPlayerReady()
		if shouldDrive then
			driveMovement(nav.tx, nav.ty, nav.tz)
			keysHeld = true
		elseif keysHeld then
			releaseMovementKeys()
			keysHeld = false
		end
	end
end

function startdjob()
	if jobRunning then
		sampAddChatMessage("[StartDJob] {FFFFFF}Already running. Use {FF9E00}/stopdjob", 0xFF9E00)
		return
	end

	jobRunning = true
	stopRequested = false
	sampAddChatMessage("[StartDJob] {FFFFFF}Mining route started.", 0xFF9E00)
	lua_thread.create(djobWorker)
end

function stopdjob()
	stopRequested = true
	jobRunning = false
	nav.active = false
	if keysHeld then
		releaseMovementKeys()
		keysHeld = false
	end
	sampAddChatMessage("[StartDJob] {FFFFFF}Mining route stopped.", 0xFF9E00)
end

function djobWorker()
	while jobRunning and not stopRequested do
		if not isPlayerReady() then
			nav.active = false
			wait(500)
		else
			for i = 1, #ROUTE do
				if not jobRunning or stopRequested then break end

				while not isPlayerReady() and jobRunning and not stopRequested do
					nav.active = false
					wait(500)
				end
				if not jobRunning or stopRequested then break end

				local point = ROUTE[i]
				if not runToPosition(point.x, point.y, point.z) then
					break
				end

				if point.mine then
					nav.active = false
					wait(100)
					sendMineCommand()
					wait(MINE_WAIT_MS)
				end
			end
		end
	end

	nav.active = false
	jobRunning = false
	stopRequested = false
end

function isPlayerReady()
	if not isSampLoaded() then return false end
	if not isSampAvailable() then return false end
	if not doesCharExist(PLAYER_PED) then return false end
	if isCharDead(PLAYER_PED) then return false end
	if not isCharOnFoot(PLAYER_PED) then return false end
	return true
end

function runToPosition(tx, ty, tz)
	nav.tx, nav.ty, nav.tz = tx, ty, tz
	nav.active = true

	local lastX, lastY = nil, nil
	local stuckTicks = 0

	while jobRunning and not stopRequested do
		if not isPlayerReady() then
			nav.active = false
			wait(500)
			if jobRunning and not stopRequested then
				nav.active = true
			end
		else
			local okPos, px, py, pz = pcall(getCharCoordinates, PLAYER_PED)
			if okPos and px ~= nil and py ~= nil then
				if getDistanceBetweenCoords2d(px, py, tx, ty) <= ARRIVAL_THRESHOLD then
					nav.active = false
					return true
				end

				if lastX ~= nil then
					if getDistanceBetweenCoords2d(px, py, lastX, lastY) < STUCK_MOVE_MIN then
						stuckTicks = stuckTicks + 1
					else
						stuckTicks = 0
					end
				end
				lastX, lastY = px, py

				if stuckTicks >= STUCK_TICKS then
					nav.active = false
					wait(100)
					doStuckRecovery()
					stuckTicks = 0
					if jobRunning and not stopRequested then
						nav.active = true
					end
				end
			end
			wait(50)
		end
	end

	nav.active = false
	return false
end

function getCameraYawPitch()
	local ok, yaw, pitch = pcall(function()
		return representIntAsFloat(readMemory(0xB6F258, 4, false)),
			representIntAsFloat(readMemory(0xB6F248, 4, false))
	end)
	if not ok or yaw == nil or pitch == nil then
		return nil, nil
	end
	return yaw, pitch
end

function normalizeAngleRad(a)
	while a > math.pi do a = a - (2 * math.pi) end
	while a < -math.pi do a = a + (2 * math.pi) end
	return a
end

function steerCameraToward(tx, ty, tz)
	local okPos, px, py, pz = pcall(getCharCoordinates, PLAYER_PED)
	if not okPos or px == nil then return 999 end

	local dx = tx - px
	local dy = ty - py
	if (dx * dx + dy * dy) < 0.09 then return 0 end

	local yaw, pitch = getCameraYawPitch()
	if yaw == nil then return 999 end

	local targetYaw = math.atan2(dy, dx) + CAMERA_YAW_OFFSET
	local diff = normalizeAngleRad(targetYaw - yaw)

	if math.abs(diff) > 0.03 then
		local step = diff
		if step > CAMERA_TURN_STEP then step = CAMERA_TURN_STEP end
		if step < -CAMERA_TURN_STEP then step = -CAMERA_TURN_STEP end
		pcall(setCameraPositionUnfixed, pitch, yaw + step)
	end

	return math.abs(diff)
end

-- Turn camera first, then run straight. No strafe keys (they caused circles).
function driveMovement(tx, ty, tz)
	local angleError = steerCameraToward(tx, ty, tz)

	setGameKeyState(KEY_FORWARD_BACK, 0)
	setGameKeyState(KEY_SPRINT, 0)

	if angleError <= RUN_ANGLE_LIMIT then
		setGameKeyState(KEY_FORWARD_BACK, 128)
		setGameKeyState(KEY_SPRINT, 255)
	end
end

function doStuckRecovery()
	if keysHeld then
		releaseMovementKeys()
		keysHeld = false
	end
	wait(100)
	setGameKeyState(KEY_JUMP, 255)
	wait(200)
	setGameKeyState(KEY_JUMP, 0)
	wait(100)
	setGameKeyState(KEY_FORWARD_BACK, -128)
	wait(300)
	setGameKeyState(KEY_FORWARD_BACK, 0)
	wait(100)
end

function releaseMovementKeys()
	setGameKeyState(KEY_FORWARD_BACK, 0)
	setGameKeyState(KEY_SPRINT, 0)
	setGameKeyState(KEY_JUMP, 0)
end

function sendMineCommand()
	wait(300)
	if sampIsDialogActive() then
		wait(1000)
	end
	sampSendChat("/mine")
	wait(300)
end
