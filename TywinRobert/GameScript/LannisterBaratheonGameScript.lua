-- Lannister/Baratheon Traits
-- Author: Furion
-- DateCreated: 6/22/2017 8:37:22 PM
--------------------------------------------------------------
print("Loaded")
--------------------------------------------------------------
-- UTILITY FUNCTIONS
--CivilizationHasTrait
function CivilizationHasTrait(sCiv, sTrait)
	for tRow in GameInfo.CivilizationTraits() do
		if (tRow.CivilizationType == sCiv and tRow.TraitType == sTrait) then
			return true;
		end
	end
	return false;
end

function LeaderHasTrait(sLeader, sTrait)
	for tRow in GameInfo.LeaderTraits() do
		if (tRow.LeaderType == sLeader and tRow.TraitType == sTrait) then return true end
	end
	return false
end
----------Set Civilization Trait to The Westerlands----------
local sHearMeRoar = "TRAIT_CIVILIZATION_HEAR_ME_ROAR";
local sOursIsTheFury = "TRAIT_CIVILIZATION_OURS_IS_THE_FURY";
local sTheUsurper = "TRAIT_THE_USURPER";

----------Random Sellswords Types----------
function Sellswords_Random_Types(playerID, unitID)
	local pPlayer = Players[playerID];

	local unit = UnitManager.GetUnit(playerID, unitID);
	if unit then
		local unitType = GameInfo.Units[unit:GetType()];
		if unitType.UnitType == "UNIT_SELLSWORDS" then
			local unitX = unit:GetX();
			local unitY = unit:GetY();
			UnitManager.Kill(unit, false);
			--math.randomseed( os.time() );
			local UnitNID = math.random(1,3);
			print(UnitNID);
			if (UnitNID == 1) then
				pPlayer:GetUnits():Create(GameInfo.Units["UNIT_SELLSWORDS_SWORDSMAN"].Index, unitX, unitY);
			elseif (UnitNID == 2) then
				pPlayer:GetUnits():Create(GameInfo.Units["UNIT_SELLSWORDS_PIKEMAN"].Index, unitX, unitY);
			else
				pPlayer:GetUnits():Create(GameInfo.Units["UNIT_SELLSWORDS_MARKSMAN"].Index, unitX, unitY);
			end
		end
	end
end
----------Culture Bomb Mine over Resource----------
--local mines = {};
--local mineImprovementId = -1;

function OnImprovementAddedToMap(locX, locY, eImprovementType, eOwner)
	local improvementData:table = GameInfo.Improvements[eImprovementType];
	local plot = Map.GetPlot(locX, locY);
	local plotResourceType = GameInfo.Resources[plot:GetResourceType()];
	local pPlayer = Players[eOwner];
	local pPlayerConfig = PlayerConfigurations[eOwner];
	local sCiv = pPlayerConfig:GetCivilizationTypeName();
	print(sCiv);
	if (not CivilizationHasTrait(sCiv,sHearMeRoar)) then return; end --Test if current player is The Westerlands

	if ((eOwner ~= -1) and (eOwner ~= 63)  and (improvementData.ImprovementType == "IMPROVEMENT_MINE") and (plotResourceType.ResourceType ~= nil)) then
		--mineImprovementId = eImprovementType;
		print ("Mine over resource added to map");
		local tempPlot = nil;
		local ownerCity = Cities.GetPlotPurchaseCity(plot);
		
		for i=0,5,1 do --for every direction
			local plotOnDirection = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), i);
			tempPlot = AddPlotIfNotOwned(plotOnDirection,eOwner,ownerCity);
		end
		print ("Adding mine's plots ended");
	end
end

function AddPlotIfNotOwned(plot:table,eOwner:number,ownerCity) --return plot, if its not owned by city
	if (plot == nil) or (eOwner == -1) then return nil; end
	if (plot:GetOwner() == -1) or (plot:GetOwner() ~= eOwner) then 
		--if plot is not city, nor district, nor world wonder
		local pDistrictType = GameInfo.Districts[plot:GetDistrictType()];
		print(pDistrictType);
		--local pWonderType = GameInfo.Buildings[plot:GetWonderType()];
		if ((plot:IsCity() == false) and (pDistrictType == nil)) then
			print("Owner ID: "..eOwner..", Location: "..plot:GetX().." "..plot:GetY()..", Owner city: "..ownerCity:GetName());
			plot:SetOwner(-1);--switching tile ownership bugs out, so first reset owner of plot
			WorldBuilder.CityManager():SetPlotOwner(plot, ownerCity);
			print("Mine's plot added to city");
		end	 
	end
	return nil;
end

function OnLoadScreenClose()
	Events.ImprovementAddedToMap.Add(OnImprovementAddedToMap);
end
----------Baratheon Grant Walls on founding city----------
function RBOnCityAddedToMap(ownerPlayerID:number, cityID:number)
	local pPlayer = Players[ownerPlayerID];
	local pPlayerConfig = PlayerConfigurations[ownerPlayerID];
	local sCiv = pPlayerConfig:GetCivilizationTypeName();
	print(sCiv);
	if (not CivilizationHasTrait(sCiv,sOursIsTheFury)) then return; end --Test if current player is The Stormlands
	local buildingType = "BUILDING_WALLS";
	local building = GameInfo.Buildings[buildingType];
	local pCity:table = pPlayer:GetCities():FindID(cityID);
	local pOriginalOwner = pCity:GetOriginalOwner();
	print("Original Owner is: "..pOriginalOwner);
	local oPlayerConfig = PlayerConfigurations[pOriginalOwner];
	local oCiv = oPlayerConfig:GetCivilizationTypeName();
	
	if (pCity ~= nil) and (oCiv == "CIVILIZATION_THE_STORMLANDS")then
		local pCityBuildQueue = pCity:GetBuildQueue();
		if (building ~= nil) then
			pCityBuildQueue:CreateIncompleteBuilding(building.Index, 100);
		end
	end
end

function RBOnCityConquered(capturerID, ownerID, cityID, cityX, cityY)
	local availableTechs = {};
	local availableCivics = {};
	--Conquered city Player techs & civics
	local cPlayer = Players[ownerID];
	local cPlayerTechs = cPlayer:GetTechs();
	local cPlayerCulture = cPlayer:GetCulture();
	--Robert techs & civics
	local pPlayer = Players[capturerID];
	local pPlayerTechs = pPlayer:GetTechs();
	local pPlayerCulture = pPlayer:GetCulture();
	
	local pPlayerConfig = PlayerConfigurations[capturerID];
	local sLeader = pPlayerConfig:GetLeaderTypeName();
	if (not LeaderHasTrait(sLeader,sTheUsurper)) then return; end --Test if current player is Robert
	
	--List Tech & Civic
	local techList = GameInfo.Technologies();
	local civicList = GameInfo.Civics();
	
	if cPlayer:IsMajor() then
		--Mark Conquered city owner finished techs and civics
		local techCount:number = 0;
		local civicCount:number = 0;
		for tech in techList do
			if cPlayerTechs:HasTech(tech.Index) and pPlayerTechs:CanResearch(tech.Index) and not pPlayerTechs:HasTech(tech.Index) then
				--table.insert(availableTechs, tech.Index);
				availableTechs[techCount] = tech.Index;
				techCount = techCount + 1;
			end
		end
		print(tostring(techCount).." Tech Available");
		if not pPlayerCulture:HasCivic(0) then
			availableCivics[civicCount] = 0;
			civicCount = civicCount + 1;
		end
		for civic in civicList do
			if cPlayerCulture:HasCivic(civic.Index) and not pPlayerCulture:HasCivic(civic.Index) then
				local prereqTableName = "CivicPrereqs";
				local multiPrereqMatch:number = 1;
				for prereqRow in GameInfo[prereqTableName]() do
					if prereqRow["Civic"] == civic.CivicType then --Means this civic has prereqs
						local boolValidPrereq:number = 1;
						local civicPrerqName = prereqRow["PrereqCivic"];
						for pCivic in civicList do
							--print("{"..pCivic.CivicType.."}".."{"..civicPrerqName.."}");
							if civicPrerqName == "CIVIC_CODE_OF_LAWS" then
								if (pPlayerCulture:HasCivic(0)) then
									boolValidPrereq = boolValidPrereq * 0; --If type matches set 0
								else
									boolValidPrereq = boolValidPrereq * 1;
								end
							end
							if pCivic.CivicType == civicPrerqName then
								if (pPlayerCulture:HasCivic(pCivic.Index)) then
									boolValidPrereq = boolValidPrereq * 0; --If type matches set 0
								else
									boolValidPrereq = boolValidPrereq * 1;
								end
							end
						end
						print("Looking at: "..civic.CivicType.."; Prereq Civ: "..civicPrerqName.."; boolValidPrereq="..tostring(boolValidPrereq));
						if boolValidPrereq == 0 then
							multiPrereqMatch = multiPrereqMatch * 1;
						else
							multiPrereqMatch = multiPrereqMatch * 0;
						end
					end
				end
				--print("multiPrereqMatch="..tostring(multiPrereqMatch));
				if multiPrereqMatch == 1 then
					--table.insert(availableCivics, civic.Index);
					availableCivics[civicCount] = civic.Index;
					civicCount = civicCount + 1;
				end
			end
		end
		print(tostring(civicCount).." Civic Available");
		--Randomly pick tech or civic available to finish
		if techCount > 0 and civicCount > 0 then
			--math.randomseed( os.time() );
			local techOrCivic:number = math.random();
			if techOrCivic < 0.5 then
				--Randomly pick a tech
				local techSeed:number = 0;
				if techCount > 1 then
					--math.randomseed( os.time() );
					techSeed= math.floor(math.random() * techCount +0.5) ;
				else
					techSeed= 0;
				end
				local techIndex:number = availableTechs[techSeed];
				print("Tech Seed = "..tostring(techSeed).." Tech Index = "..tostring(techIndex));
				pPlayerTechs:SetResearchProgress(techIndex, pPlayerTechs:GetResearchCost(techIndex));
			else
				--Randomly pick a civic
				local civicSeed:number = 0;
				if civicCount > 1 then
					--math.randomseed( os.time() );
					civicSeed = math.floor(math.random() * civicCount +0.5) ;
				else
					civicSeed = 0;
				end
				local civicIndex:number = availableCivics[civicSeed];
				print("Civic Seed = "..tostring(civicSeed).." Civic Index = "..tostring(civicIndex));
				pPlayerCulture:SetCulturalProgress(civicIndex, pPlayerCulture:GetCultureCost(civicIndex));	
			end
		elseif techCount > 0 and civicCount == 0 then
			local techSeed:number = 0;
			if techCount > 1 then
				--math.randomseed( os.time() );
				techSeed = math.floor(math.random() * techCount +0.5) ;
			else
				techSeed = 0;
			end
			local techIndex:number = availableTechs[techSeed];
			print("Tech Seed = "..tostring(techSeed).." Tech Index = "..tostring(techIndex));
			pPlayerTechs:SetResearchProgress(techIndex, pPlayerTechs:GetResearchCost(techIndex));
		elseif techCount == 0 and civicCount > 0 then
			local civicSeed:number = 0;
			if civicCount > 1 then
				--math.randomseed( os.time() );
				civicSeed = math.floor(math.random() * civicCount +0.5);
			else
				civicSeed = 0;
			end
			local civicIndex:number = availableCivics[civicSeed];
			print("Civic Seed = "..tostring(civicSeed).." Civic Index = "..tostring(civicIndex));
			pPlayerCulture:SetCulturalProgress(civicIndex, pPlayerCulture:GetCultureCost(civicIndex));	
		else
			return;
		end
	else
		return;
	end
end
----------Events----------
Events.LoadScreenClose.Add(OnLoadScreenClose);
Events.UnitAddedToMap.Add(Sellswords_Random_Types);
Events.CityAddedToMap.Add(RBOnCityAddedToMap);
GameEvents.CityConquered.Add(RBOnCityConquered);