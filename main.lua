-- ########################################
-- BOILERPLATE
-- ########################################

local mod = RegisterMod("Vazkii's Item Pack", 1);
local testing = false;

local itemClosedEye = Isaac.GetItemIdByName("Eye of the Subconscious");
local itemRemoteControl = Isaac.GetItemIdByName("Remote Control");
local itemBleedingEdgeTech = Isaac.GetItemIdByName("Bleeding Edge Tech");
local itemPlasticWorm = Isaac.GetItemIdByName("Action Worm");

-- ########################################
-- TESTING
-- ########################################

local debug = {};
local itemTestButton = nil;
local debuggingItem = nil;

function useTestItem()
	local player = Isaac.GetPlayer(0);
	local pos = Isaac.GetFreeNearPosition(player.Position, 1) + Vector(0, 16);

	Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, debuggingItem, pos, Vector(0, 0), player);
end

function debugDisplay()
	for i=1, #debug do
		Isaac.RenderText(debug[i], 80, 30 + i * 10, 255, 255, 255, 255);
	end
end

if testing then
	itemTestButton = Isaac.GetItemIdByName("Testing Button");
	debuggingItem = itemPlasticWorm;

	mod:AddCallback(ModCallbacks.MC_USE_ITEM, useTestItem, itemTestButton);
	mod:AddCallback(ModCallbacks.MC_POST_RENDER, debugDisplay);
end

-- ########################################
-- EYE OF THE SUBCONSCIOUS
-- ########################################

function updateClosedEye()
	local player = Isaac.GetPlayer(0);

	if player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) or (not player:CanShoot()) then
		return;
	end

	local cd = player.MaxFireDelay * 2;
	if player:HasCollectible(itemClosedEye) then
		local entities = filter(Isaac.GetRoomEntities(), function(e)
			return e:IsVulnerableEnemy();
		end);

		local closest = nil;
		local dist = 10000;

		for i = 1, #entities do
			local e = entities[i];
			player.FireDelay = cd + 1;
			local diff = e.Position - player.Position;
			if diff:Length() < dist then
				closest = e;
				dist = diff:Length();
			end	
		end

		if closest ~= nil and tickCheck(cd) then
			local diff = closest.Position - player.Position;
			diff = diff * (10 * player.ShotSpeed / diff:Length());
			
			if player:HasCollectible(CollectibleType.COLLECTIBLE_TECHNOLOGY) or player:HasCollectible(itemBleedingEdgeTech) then
				player:FireTechLaser(player.Position, 0, diff, true, false);
			elseif player:HasCollectible(CollectibleType.COLLECTIBLE_TECH_X) then
				player:FireTechXLaser(player.Position, diff, 1);
			else 
				player:FireTear(player.Position, diff, false, true, false);
			end
		end
	end
end

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, updateClosedEye);

-- ########################################
-- REMOTE CONTROL
-- ########################################

local hasRemoteControl = true;

function updateRemoteControl()
	local player = Isaac.GetPlayer(0);

	local hadRemoteControl = hasRemoteControl;
	hasRemoteControl = player:HasCollectible(itemRemoteControl);

	if hasRemoteControl then
		if (not hadRemoteControl) then
			player:AddBombs(5);
		end

		local entities = filter(Isaac.GetRoomEntities(), function(e)
			return e.Type == EntityType.ENTITY_BOMBDROP;
		end);

		local joystick = player:GetShootingJoystick() * player.MoveSpeed;

		for i = 1, #entities do
			local e = entities[i];
			e:AddVelocity(joystick);
		end
	end	
end

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, updateRemoteControl);

-- ########################################
-- BLEEDING EDGE TECH
-- ########################################

local familiars = {
	FamiliarVariant.ABEL,
	FamiliarVariant.BBF,
	FamiliarVariant.BLUEBABYS_ONLY_FRIEND,
	FamiliarVariant.CAINS_OTHER_EYE,
	FamiliarVariant.DEAD_BIRD,
	FamiliarVariant.EVES_BIRD_FOOT,
	FamiliarVariant.GB_BUG,
	FamiliarVariant.GEMINI,
	FamiliarVariant.GUPPYS_HAIRBALL,
	FamiliarVariant.HUSHY,
	FamiliarVariant.KING_BABY,
	FamiliarVariant.LEECH,
	FamiliarVariant.MULTIDIMENSIONAL_BABY,
	FamiliarVariant.OBSESSED_FAN,
	FamiliarVariant.PAPA_FLY,
	FamiliarVariant.PEEPER,
	FamiliarVariant.PUNCHING_BAG,
	FamiliarVariant.ROBO_BABY_2,
	FamiliarVariant.SCISSORS,
	FamiliarVariant.SISSY_LONGLEGS,
	FamiliarVariant.SMART_FLY,
	FamiliarVariant.SPIDER_MOD,
	FamiliarVariant.SUCCUBUS
};

local tech2Item = nil;
local hasBleedingEdgeTech = true;

function updateBleedingEdgeTech()
	local player = Isaac.GetPlayer(0);

	local hadBleedingEdgeTech = hasBleedingEdgeTech;
	hasBleedingEdgeTech = player:HasCollectible(itemBleedingEdgeTech);

	local cd = player.MaxFireDelay * 4;
	if hasBleedingEdgeTech then
		local entities = filter(Isaac.GetRoomEntities(), function(e)
			return e.Type == EntityType.ENTITY_FAMILIAR and inArray(familiars, e.Variant);
		end);

		if #entities > 0 then
			player.FireDelay = cd + 1;
			local joystick = player:GetShootingJoystick();
						
			if tickCheck(cd) and joystick:LengthSquared() > 0 then
				for i = 1, #entities do
					local e = entities[i];
					local diff = e.Position - player.Position;

					player:FireTechLaser(player.Position, 0, diff, false, false);
				end
			end
		end
	end
end

function bleedingEdgeTechPlayerInitHack(paramPlayer)
	tech2Item = getItem(CollectibleType.COLLECTIBLE_TECHNOLOGY, tech2Item);
end

function bleedingEdgeTechPostRenderHack()
	if tech2Item ~= nil then
		local player = Isaac.GetPlayer(0);

		if player:HasCollectible(itemBleedingEdgeTech) then
			player:AddCostume(tech2Item, false);
		end
	end
end

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, updateBleedingEdgeTech);
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, bleedingEdgeTechPlayerInitHack);
mod:AddCallback(ModCallbacks.MC_POST_RENDER, bleedingEdgeTechPostRenderHack);

-- ########################################
-- ACTION WORM
-- ########################################

local plasticWormTicks = 0;
local plasticWormX = 0;
local plasticWormY = 0;

local plasticWormMovement = {};
local plasticWormTracked = {};
local hasPlasticWorm = false;

function usePlasticWorm()
	local player = Isaac.GetPlayer(0);

	plasticWormX = player.Position.X;
	plasticWormY = player.Position.Y;
	plasticWormTicks = 50;
	plasticWormMovement = {};
	plasticWormTracked = {};
end

function updatePlasticWorm()
	local player = Isaac.GetPlayer(0);
	local active = player:GetActiveItem();

	local hadPlasticWorm = hasPlasticWorm;
	hasPlasticWorm = active == itemPlasticWorm;

	local rangeBonus = 20;
	if hadPlasticWorm and (not hasPlasticWorm) then
		player.TearHeight = player.TearHeight + rangeBonus;
	elseif hasPlasticWorm and (not hadPlasticWorm) then
		player.TearHeight = player.TearHeight - rangeBonus;
	end

	if plasticWormTicks > 0 then
		local joystick = player:GetShootingJoystick() * player.ShotSpeed * 10;

		plasticWormX = plasticWormX + joystick.X;
		plasticWormY = plasticWormY + joystick.Y;
		plasticWormTicks = plasticWormTicks - 1;
		player.FireDelay = 1;

		local pos = Vector(plasticWormX, plasticWormY);
		Game():SpawnParticles(pos, 88, 1, 0, Color(1, 1, 1, 1, 1, 1, 1), 0);
		plasticWormMovement[#plasticWormMovement + 1] = pos;
	end

	if hasPlasticWorm and #plasticWormMovement > 0 then
		local entities = filter(Isaac.GetRoomEntities(), function(e)
			return e.Type == EntityType.ENTITY_TEAR;
		end);

		for i = 1, #entities do
			local e = entities[i];
			local inArray = false;

			for k, v in pairs(plasticWormTracked) do
				if v.EntityData == e:GetData() then
					inArray = true;
					
					local ticks = v.Ticks;
					v.Ticks = ticks + 1;
					ticks = ticks + 2;
					if ticks < #plasticWormMovement then
						local diff = plasticWormMovement[ticks] - plasticWormMovement[ticks - 1];
						diff = rotateVector(diff, v.Direction);

						e.Velocity = diff;
					end
				end
			end

			if (not inArray) then
				local track = {};
				track["Ticks"] = 0;
				track["EntityData"] = e:GetData();
				track["Direction"] = player:GetFireDirection();

				plasticWormTracked[#plasticWormTracked + 1] = track;
			end
		end
	end
end

function initPlasticWorm()
	plasticWormMovement = {};
	plasticWormTracked = {};
	hasPlasticWorm = false;
end

mod:AddCallback(ModCallbacks.MC_USE_ITEM, usePlasticWorm, itemPlasticWorm);
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, updatePlasticWorm);
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, initPlasticWorm);

-- ########################################
-- HELPERS
-- ########################################

function tickCheck(cd) 
	return Isaac:GetFrameCount() % cd == 0;
end

function filter(arr, pred)
	local newArr = {};

	for i = 1, #arr do
		local val = arr[i];
		if pred(val) then
			newArr[#newArr + 1] = val;
		end
	end

	return newArr;
end

function inArray(arr, obj)
    for k, v in ipairs(arr) do
        if v == obj then
            return true;
        end
    end

    return false;
end

function getItem(collectible, currItem)
	if currItem ~= nil then
		return currItem;
	end

	local player = Isaac.GetPlayer(0);

	player:GetEffects():AddCollectibleEffect(collectible, true);
	local effect = player:GetEffects():GetCollectibleEffect(collectible);
	return effect.Item;
end

function rotateVector(vec, dir)
	if dir == Direction.UP then
		return vec * -1;
	elseif dir == Direction.RIGHT then
		local tempX = vec.X;
		vec.X = vec.Y;
		vec.Y = -tempX;
	elseif dir == Direction.LEFT then
		return rotateVector(vec, Direction.RIGHT) * -1;
	end

	return vec;
end