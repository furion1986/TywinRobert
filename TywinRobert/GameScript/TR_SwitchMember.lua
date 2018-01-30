-- UI_3D Asset Animate and Attachment
-- Author: Furion
--Special thanks to Gedemon for Timer instructions and sample code
-- DateCreated: 8/9/2017 10:31:43 PM
--------------------------------------------------------------
include( "InstanceManager" );
include( "SupportFunctions" );
include( "Civ6Common" );

print("Loaded")
local g_Timer = 0;
local g_Pause = 0.1;
local switchUnit = nil;
local runUpdateUnitAtt = nil;

----------Timer Controlled Functions----------
function UpdateUnitAttachment()
    local iMemberCount = SimUnitSystem.GetVisMemberCount(switchUnit);
	--print(tostring(switchUnit).." Member Count: "..iMemberCount);
	--Get all units in same tile
	local unitX = switchUnit:GetX();
	local unitY = switchUnit:GetY();
	local unitList:table = Units.GetUnitsInPlotLayerID(unitX, unitY, MapLayers.ANY);		
	--Loop through members of Undead Unit
	if iMemberCount > 0 then		
		for j = 0, iMemberCount - 1, 1 do
			--print("Checking Member #"..tostring(j))
			local unitVisArtState = SimUnitSystem.GetVisMemberArtState(switchUnit, j);
			local hasSquire = false;
			if unitList ~= nil then
				--print("Plot has units...");
				for i, tUnit in ipairs(unitList) do
					local tUnitInfo:table = GameInfo.Units[tUnit:GetUnitType()];
					if tUnitInfo.UnitType == "UNIT_SQUIRE" then
						--print("Squire detected...");
						hasSquire = true;
						--break;
					end
				end
			end
			--print("hasSquire = "..tostring(hasSquire));
			--End looping through units in same plot
			if (unitVisArtState ~= nil) then
				for k, att in ipairs(unitVisArtState.Attachments) do
					local attName = att.Name;
					--print(attName);
					if ((attName == "Warrior_ArmorA") or (attName == "Swordsman_ArmorA")) and (hasSquire == true) then
						--print("Swapping to Horse...".."attachment ID: "..k.." Current Attachment Name: "..attName);
						SimUnitSystem.ChangeVisMemberArtAttachment(switchUnit, j, k-1, 1);
					elseif ((attName == "WarriorRider_ArmorA") or (attName == "SwordsmanRider_ArmorA")) and (hasSquire == false) then
						--print("Swapping to No Horse...".."attachment ID: "..k.." Current Attachment Name: "..attName);						
						SimUnitSystem.ChangeVisMemberArtAttachment(switchUnit, j, k-1, -1);
					elseif ((attName == "Warrior_ArmorA") or (attName == "Swordsman_ArmorA")) and (hasSquire == false) then
					end
					if (attName == "FullHorseArmorA") and (hasSquire == false) then
						--print("Swapping to No Horse...".."attachment ID: "..k.." Current Attachment Name: "..attName);						
						SimUnitSystem.ChangeVisMemberArtAttachment(switchUnit, j, k-1, -1);
					elseif (attName == "NoHorse") and (hasSquire == true) then
						--print("Swapping to Horse...".."attachment ID: "..k.." Current Attachment Name: "..attName);					
						SimUnitSystem.ChangeVisMemberArtAttachment(switchUnit, j, k-1, 1);
					elseif (attName == "FullHorseArmorA") and (hasSquire == true) then
					end
				end
			end
			--End looping through members
		end
		--Unit has member
	end
	--End of function
end

function RTOnUnitSelectionChanged(playerID, unitId, locationX, locationY, locationZ, isSelected, isEditable)
	print("Unit Selection Triggered!");
	if (isSelected) then
		local pPlayer = Players[playerID];
		local pPlayerConfig = PlayerConfigurations[playerID];
		local sCiv = pPlayerConfig:GetCivilizationTypeName();
		print(sCiv);
		if not sCiv == "CIVILIZATION_THE_STORMLANDS" then return; end
		local pUnit = pPlayer:GetUnits():FindID(unitId);
		local unitInfo = GameInfo.Units[pUnit:GetUnitType()];
		print(unitInfo.UnitType);
		if (unitInfo.UnitType == "UNIT_WARRIOR" or unitInfo.UnitType == "UNIT_SWORDSMAN") then
			switchUnit = pUnit;
			print("Start switching members: "..tostring(switchUnit));
			runUpdateUnitAtt = coroutine.create(function () 
				for i = 0, 7, 1 do
					UpdateUnitAttachment();
					--print("requesting pause in script for ", g_Pause, " seconds at time = ".. tostring( Automation.GetTime() ));
					g_Timer = Automation.GetTime();
					coroutine.yield();
					-- after g_Pause seconds, the script will start again from here
					--print("resuming script at time = ".. tostring( Automation.GetTime() ));  
				end
				StopScriptWithPause();
				switchUnit = nil;
			end)
			LaunchScriptWithPause();
			coroutine.resume(runUpdateUnitAtt);
		end
	end
end

function RTSetUnitAttachments(playerID, unitID)
	print("Added to Map Triggered!");
	local pPlayer = Players[playerID];
	local pPlayerConfig = PlayerConfigurations[playerID];
	local sCiv = pPlayerConfig:GetCivilizationTypeName();
	print(sCiv);
	if not sCiv == "CIVILIZATION_THE_STORMLANDS" then return; end
	local unit = UnitManager.GetUnit(playerID, unitID);
	if unit then
		local unitType = GameInfo.Units[unit:GetUnitType()];
		print(unitType.UnitType);
		--Check if unit type is Warrior or Swordsman
		if unitType.UnitType == "UNIT_WARRIOR" or unitType.UnitType == "UNIT_SWORDSMAN" then
			LaunchScriptWithPause();
			switchUnit = unit;
			print("Start switching members: "..tostring(switchUnit));
			runUpdateUnitAtt = coroutine.create(function () 
				for i = 0, 7, 1 do
					UpdateUnitAttachment();
					--print("requesting pause in script for ", g_Pause, " seconds at time = ".. tostring( Automation.GetTime() ));
					g_Timer = Automation.GetTime();
					coroutine.yield();
					-- after g_Pause seconds, the script will start again from here
					--print("resuming script at time = ".. tostring( Automation.GetTime() ));  
				end
				StopScriptWithPause();
				switchUnit = nil;
			end)
			LaunchScriptWithPause();			
			coroutine.resume(runUpdateUnitAtt);
		end
		--Done updating Unit members
	end
	--unit isn't nil
end

function RTOnEnterFormation(playerID1, unitID1, playerID2, unitID2)
	print("Enter into formation Triggered!");
	local pPlayer = Players[playerID1];
	local pPlayerConfig = PlayerConfigurations[playerID1];
	local sCiv = pPlayerConfig:GetCivilizationTypeName();
	print(sCiv);
	if not sCiv == "CIVILIZATION_THE_STORMLANDS" then return; end
	if (pPlayer ~= nil) then
		local pUnit1 = pPlayer:GetUnits():FindID(unitID1);
		local pUnit2 = pPlayer:GetUnits():FindID(unitID2);
		if (pUnit1 ~= nil) and (pUnit2 ~= nil) then
			local unitType1 = GameInfo.Units[pUnit1:GetUnitType()];
			local unitType2 = GameInfo.Units[pUnit2:GetUnitType()];
			print(unitType1.UnitType);
			print(unitType2.UnitType);
			--Check if unit type is Warrior or Swordsman
			if unitType1.UnitType == "UNIT_WARRIOR" or unitType1.UnitType == "UNIT_SWORDSMAN" then
				Events.GameCoreEventPublishComplete.Add( CheckTimer );
				switchUnit = pUnit1;
				print("Start switching members: "..tostring(switchUnit));
				runUpdateUnitAtt = coroutine.create(function () 
					for i = 0, 7, 1 do
						UpdateUnitAttachment();
						--print("requesting pause in script for ", g_Pause, " seconds at time = ".. tostring( Automation.GetTime() ));
						g_Timer = Automation.GetTime();
						coroutine.yield();
						-- after g_Pause seconds, the script will start again from here
						--print("resuming script at time = ".. tostring( Automation.GetTime() ));  
					end
					StopScriptWithPause();
					switchUnit = nil;
				end)
				LaunchScriptWithPause();			
				coroutine.resume(runUpdateUnitAtt);			
			end
			if unitType2.UnitType == "UNIT_WARRIOR" or unitType2.UnitType == "UNIT_SWORDSMAN" then
				switchUnit = pUnit2;
				print("Start switching members: "..tostring(switchUnit));
				runUpdateUnitAtt = coroutine.create(function () 
					for i = 0, 7, 1 do
						UpdateUnitAttachment();
						--print("requesting pause in script for ", g_Pause, " seconds at time = ".. tostring( Automation.GetTime() ));
						g_Timer = Automation.GetTime();
						coroutine.yield();
						-- after g_Pause seconds, the script will start again from here
						--print("resuming script at time = ".. tostring( Automation.GetTime() ));  
					end
					StopScriptWithPause();
					switchUnit = nil;
				end)
				LaunchScriptWithPause();
				coroutine.resume(runUpdateUnitAtt);				
			end
		end
	end
end

function RTUnitSimPositionChanged( playerID:number, unitID:number, worldX:number, worldY:number, worldZ:number, bVisible:boolean, isComplete:boolean )
	print("Sim Position Change Triggered!");
	if isComplete then
		local pPlayer = Players[playerID];
		local pPlayerConfig = PlayerConfigurations[playerID];
		local sCiv = pPlayerConfig:GetCivilizationTypeName();
		print(sCiv);
		if not sCiv == "CIVILIZATION_THE_STORMLANDS" then return; end
		local pUnit = pPlayer:GetUnits():FindID(unitID);
		local unitInfo = GameInfo.Units[pUnit:GetUnitType()];
		print(unitInfo.UnitType);
		if (unitInfo.UnitType == "UNIT_WARRIOR" or unitInfo.UnitType == "UNIT_SWORDSMAN") then
			switchUnit = pUnit;
			print("Start switching members: "..tostring(switchUnit));
			runUpdateUnitAtt = coroutine.create(function () 
				for i = 0, 7, 1 do
					UpdateUnitAttachment();
					--print("requesting pause in script for ", g_Pause, " seconds at time = ".. tostring( Automation.GetTime() ));
					g_Timer = Automation.GetTime();
					coroutine.yield();
					-- after g_Pause seconds, the script will start again from here
					--print("resuming script at time = ".. tostring( Automation.GetTime() ));  
				end
				StopScriptWithPause();
				switchUnit = nil;
			end)
			LaunchScriptWithPause();
			coroutine.resume(runUpdateUnitAtt);
		end
	end
end

----------Timer Functions----------
function ChangePause(value) -- Not called anywhere?
    --print("changing pause value to ", value);
    g_Pause = value;
end
function CheckTimer()  
    if Automation.GetTime() >= g_Timer + g_Pause then
        g_Timer = Automation.GetTime();
        coroutine.resume(runUpdateUnitAtt);
    end
end
----------Events----------
function LaunchScriptWithPause()
    Events.GameCoreEventPublishComplete.Add( CheckTimer );
end
function StopScriptWithPause() -- GameCoreEventPublishComplete is called frequently, keep it clean
    Events.GameCoreEventPublishComplete.Remove( CheckTimer );
end

function RTOnShutdown()
	Events.UnitSelectionChanged.Remove(RTOnUnitSelectionChanged);
	Events.UnitEnterFormation.Remove(RTOnEnterFormation);
	Events.UnitExitFormation.Remove(RTOnEnterFormation);
	Events.UnitAddedToMap.Remove(RTSetUnitAttachments);
	Events.UnitSimPositionChanged.Remove(RTUnitSimPositionChanged);
end

function RBSwitchOnLoadScreenClose()
	Events.UnitSelectionChanged.Add(RTOnUnitSelectionChanged);
	Events.UnitEnterFormation.Add(RTOnEnterFormation);
	Events.UnitExitFormation.Add(RTOnEnterFormation);
	Events.UnitAddedToMap.Add(RTSetUnitAttachments);
	Events.UnitSimPositionChanged.Add(RTUnitSimPositionChanged);
end
----------Open/Close Control----------
Events.LoadScreenClose.Add(RBSwitchOnLoadScreenClose);
ContextPtr:SetShutdown(RTOnShutdown);
