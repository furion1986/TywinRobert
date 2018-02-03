-- UI_3D Asset Animate and Attachment
-- Author: Furion
--Special thanks to Gedemon for Timer instructions and sample code
-- DateCreated: 8/9/2017 10:31:43 PM
--------------------------------------------------------------
include( "InstanceManager" );
include( "SupportFunctions" );
include( "Civ6Common" );

print("Loaded")

function RTOnUnitAddedToMap(playerID: number, unitID : number, unitX : number, unitY : number)
	RTRefresh( playerID, unitID, unitX, unitY );
end

function RTOnUnitMoveComplete(playerID: number, unitID : number, unitX : number, unitY : number)
	RTRefresh( playerID, unitID, unitX, unitY );
end

function RTRefresh(playerID:number, unitID:number, worldX:number, worldY:number)
	--Default No Squire Attached
	local pPlayer = Players[playerID];
	local pPlayerConfig = PlayerConfigurations[playerID];
	local sCiv = pPlayerConfig:GetCivilizationTypeName();
	--print(sCiv);
	local playerUnits = pPlayer:GetUnits();
	--Check if the current Civ is Stormlands
	if sCiv == "CIVILIZATION_THE_STORMLANDS" then
		for i, unit in playerUnits:Members() do
			local hasSquire = false;
			local unitInfo = GameInfo.Units[unit:GetUnitType()];
			--print(unitInfo.UnitType);
			local unitX =  unit:GetX();
			local unitY = unit:GetY();
			local unitList:table = Units.GetUnitsInPlotLayerID(unitX, unitY, MapLayers.ANY);
			if unitList ~= nil then
				for i, tUnit in ipairs(unitList) do
					local tUnitInfo:table = GameInfo.Units[tUnit:GetUnitType()];
					if tUnitInfo.UnitType == "UNIT_SQUIRE" then
						hasSquire = true;
					end
				end
			end
			if unitInfo.UnitType == "UNIT_WARRIOR" and hasSquire == true then
				print("Calling Warrior to Mounted");
				local unitPromotions =  unit:GetExperience():GetPromotions();
				local unitExp = unit:GetExperience():GetExperiencePoints();
				local unitMaxMove = unit:GetMaxMoves();
				local unitMove = unit:GetMovesRemaining();
				local deltaMove = unitMaxMove - unitMove;
				LuaEvents.RTWarrior_Mount(playerID,unit,unitExp,unitPromotions,unitX, unitY,deltaMove);
			elseif unitInfo.UnitType == "UNIT_SWORDSMAN" and hasSquire == true then
				print("Calling Swordsman to Mounted");
				local unitPromotions =  unit:GetExperience():GetPromotions();
				local unitExp = unit:GetExperience():GetExperiencePoints();
				local unitMaxMove = unit:GetMaxMoves();
				local unitMove = unit:GetMovesRemaining();
				local deltaMove = unitMaxMove - unitMove;
				LuaEvents.RTSwordsman_Mount(playerID,unit,unitExp,unitPromotions,unitX, unitY,deltaMove);
			elseif unitInfo.UnitType == "UNIT_WARRIOR_MOUNTED" and hasSquire == false then
				print("Calling Warrior to Dismounted");
				local unitPromotions =  unit:GetExperience():GetPromotions();
				local unitExp = unit:GetExperience():GetExperiencePoints();
				local unitMaxMove = unit:GetMaxMoves();
				local unitMove = unit:GetMovesRemaining();
				local deltaMove = unitMaxMove - unitMove;
				LuaEvents.RTWarrior_Dismount(playerID,unit,unitExp,unitPromotions,unitX, unitY,deltaMove);
			elseif unitInfo.UnitType == "UNIT_WARRIOR_MOUNTED" and hasSquire == false then
				print("Calling Swordsman to Dismounted");
				local unitPromotions =  unit:GetExperience():GetPromotions();
				local unitExp = unit:GetExperience():GetExperiencePoints();
				local unitMaxMove = unit:GetMaxMoves();
				local unitMove = unit:GetMovesRemaining();
				local deltaMove = unitMaxMove - unitMove;
				LuaEvents.RTSwordsman_Dismount(playerID,unit,unitExp,unitPromotions,unitX, unitY,deltaMove);
			end
		end
	end
end

function RTOnCUnitPromotions(cUnit,unitPromotions)
	print("Promotion LUA Event Triggered");
	print(cUnit);
	for i, promotion in ipairs(unitPromotions) do
		local tParameters = {};
		tParameters[UnitCommandTypes.PARAM_PROMOTION_TYPE] = promotion;
		UnitManager.RequestCommand( cUnit, UnitCommandTypes.PROMOTE, tParameters );
	end
end

LuaEvents.SetCUnitPromotions.Add(RTOnCUnitPromotions);

----------Events----------
function RTOnShutdown()
Events.UnitMoveComplete.Remove( RTOnUnitMoveComplete );
Events.UnitAddedToMap.Remove( RTOnUnitAddedToMap );
end
function RBSwitchOnLoadScreenClose()
Events.UnitMoveComplete.Add( RTOnUnitMoveComplete );
Events.UnitAddedToMap.Add( RTOnUnitAddedToMap );
end
----------Open/Close Control----------
--Events.LoadScreenClose.Add(RBSwitchOnLoadScreenClose);
ContextPtr:SetShutdown(RTOnShutdown);
