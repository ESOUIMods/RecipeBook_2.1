--Addon : RecipeBook
--Version : 2.0b
--Author : ahostbr
--[[THX:
BadVolt(MobileBank)-Without His Code This Addon Wouldnt Have Been Possible.
SousChef(wobin)-Basics Recipe Handling.
GuildStoreSearcher/GuildStore Addon(xevoran) - General Help With The Alpha UI.
Harven(HarvensAddons)-Tooltips
Credits and massive respect to all addon devs!
& of course :
All who have made feature requests and comments on the addons ESOUI page.
]]--


--setup main variable holder
RB = {}
local RBToolTipArray = {}
--version info
RB.version="2.0b"
RB.AddonName = "RecipeBook"



	


--setup array to hold guild names and character names
RB.dataDefaultItems = {
	Guilds={},
	Chars={},
	SaveVars={
	["tooltips"]=true,
	["multichar"]=true,
	choosenrecipenamefont = {
		["f"] = "ZoFontBookPaperTitle"
	},
	chooseningredientfont = {
		["f"] = "ZoFontBookPaper"
	},
	ingredientcolor = {
		["r"] = 0.156863,
		["g"] = 0.074510,
		["b"] = 0.019608,
		["a"] = 0.950820                 
	},
	charsbuttoncolor = {
		["r"] = 0,
		["g"] = 0,
		["b"] = 0,
		["a"] = 1
	}
	}
}


--Grab Guild Names
for i=1,GetNumGuilds() do
	RB.dataDefaultItems.Guilds[i]=
		{
			[GetGuildName(i)]={

			}
		}
end 

--Default UI position from top left pixel
RB.dataDefaultParams = {
	RBUI_Menu = {10,10},
	RBUI_Container = {227,122}
}

--setup various var's
RB.GuildNames = {}
RBEventHandlers = {}


RB.UI_Movable=false
RB.AddonReady=false
RB.TempData={}
RB.GCountOnUpdateTimer=0
RB.GuildBankIdToPrepare=1
RB.Debug=false
RB.PreviousButtonClicked=nil
RB.LastButtonClicked=nil
RB.CharsName=nil

RB.SortRQClickedCnt = 1
RB.SortPRClickedCnt = 1
RB.SortQRClickedCnt = 1
RB.SortNameClickedCnt = 1
RB.CheckmarkIconPath = [[/esoui/art/loot/loot_finesseitem.dds]]


RB.LastClickedCharName = ""

RB.AllCharBVT = {}
RB.TrackList = {}
RB.SDDI = ""
RB.DFShwncnt = 0
RB.loadingDD = false

RB.NoteArray={}

RB.MenuClickStatus = false

RB.RecipeBookActive=true

RB.IngredientColorPickerClicked = false
RB.TooltipAddedByKnown = false

function GetItemID(link)
	return tonumber(string.match(string.match(link, "%d+:"), "%d+"))
end--GetItemID

function RB_PopTooltip(linkvar,line)
  local tooltip = PopupTooltip
  tooltip:ClearAnchors()
  tooltip:ClearLines()
  tooltip:SetLink(linkvar)
  tooltip:AddLine(line)

  
  
  tooltip:SetHidden(false)

end

function debug(text)--debugging
	if RB.Debug then
		d(text)
	end
end

--harven
function RBToolTipArray:AddRecipeInredients(recipeListIndex, recipeIndex, recipeType)
	if not recipeType then
		recipeType = GetRecipeListInfo(recipeListIndex)
	end
	local known, recipeName, numIngredients, provisionerLevel = GetRecipeInfo(recipeListIndex, recipeIndex)
	if known then
		for k=1,numIngredients do
			local name, _, requiredQuantity, sellPrice, quality = GetRecipeIngredientItemInfo(recipeListIndex, recipeIndex, k)
			name = zo_strformat("<<1>>", name)
			if not RBToolTipArray.ingredients[name] then
				RBToolTipArray.ingredients[name] = { quality=quality, recipes = {} }
			end
			local result = GetRecipeResultItemLink( recipeListIndex, recipeIndex, LINK_STYLE_DEFAULT)
			local recipeInfo = { recipeType=recipeType, recipeName=recipeName, provisionerLevel=provisionerLevel, result=result }
			table.insert(RBToolTipArray.ingredients[name].recipes, recipeInfo)
		end
	end
end

function RBToolTipArray:BuildIngredientsList()
	if (RB.AddonName ~= "RecipeBook" ) then return end
	local numLists = GetNumRecipeLists()
		for i=1,numLists do
			local recipeType, numRecipes = GetRecipeListInfo(i)
			for j=1,numRecipes do
				RBToolTipArray:AddRecipeInredients(i, j, recipeType)
			end
		end
	
	if RB.CharsName ~= nil then
			if RB.AddonReady== false then
				for i=1,#RB.CharsName do
				local LoadingCharName=RB.CharsName[i]
				RB.TMPRBTTABVT=RB.items.Chars[LoadingCharName]
						table.insert(RB.AllCharBVT,RB.TMPRBTTABVT)
				end
			end	
			
	end
end

function RBToolTipArray:AddProvisioningTooltipInfo(control, name)
if control == nil or name == nil then return end
if (RB.AddonName ~= "RecipeBook" ) then return end
RBToolTipArray:BuildIngredientsList()
if RB.AllCharBVT == nil then d("Recipebook Error, AllCharBVT is Nil Please Report to ahostbr on ESOUI")return end

if RB.items.SaveVars.tooltips == false then return end
RBTMPTTRA = {}

	local found = false
	local dontprntinfoonce = false
		
		local r,g,b = ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB()
		for charIndex=1,#RB.AllCharBVT do

		local dontprntknwnonce = false
			for charRecipesIndex=1,#RB.AllCharBVT[charIndex] do	
				if RB.items.SaveVars.multichar == true then--STARTMULTICHAR_TRUE
					
					local RBPName = zo_strformat(SI_TOOLTIP_ITEM_NAME, RB.AllCharBVT[charIndex][charRecipesIndex].link)	
					
						for IngIndex =1, #RB.AllCharBVT[charIndex][charRecipesIndex].ingredients do
							
							
							if string.lower(RB.AllCharBVT[charIndex][charRecipesIndex].ingredients[IngIndex].ingredientname)== string.lower(name) then
							found = true
								if dontprntknwnonce == false then
									dontprntknwnonce = true
									if RB.AllCharBVT[charIndex][charRecipesIndex].charname ~= nil then
										if Ingredient_IDs[GetItemID(RB.AllCharBVT[charIndex][charRecipesIndex].ingredients[IngIndex].ingredient)] then
												if dontprntinfoonce == false then
												dontprntinfoonce = true
												control:AddVerticalPadding(5)
												RB.TooltipAddedByKnown = true
													control:AddLine(Ingredient_IDs[GetItemID(RB.AllCharBVT[charIndex][charRecipesIndex].ingredients[IngIndex].ingredient)].tooltip, "ZoFontGame", 1, 1, 1, CENTER, MODIFY_TEXT_TYPE_UPPERCASE, LEFT, false)
												control:AddVerticalPadding(5)	
												end
										end
									control:AddLine("-=Recipes Known By : "..RB.AllCharBVT[charIndex][charRecipesIndex].charname.."=-", "ZoFontGameBold", 1, 1, 1, CENTER, MODIFY_TEXT_TYPE_UPPERCASE, LEFT, false)		
									else
										d("***RecipeBook***")
										d("RecipeBook Error, Please Logout and Delete Your") 
										d("Settings File In The Saved Variables Folder And Try Again.")
										d("Or Possibly Just A /reloadui")
									end
								end
								
									if (RB.AllCharBVT ~= nil) and (RBPName ~= nil) and found ~= false then
										if RB.AllCharBVT[charIndex][charRecipesIndex].tracked == false then
											
												
												control:AddLine("[ "..RBPName.."-RQ : ".. RB.AllCharBVT[charIndex][charRecipesIndex].recipequality.." PR : "..RB.AllCharBVT[charIndex][charRecipesIndex].provisionerLevelReq.." QR : "..RB.AllCharBVT[charIndex][charRecipesIndex].qualityReq.." ]")	
											
										elseif RB.AllCharBVT[charIndex][charRecipesIndex].tracked == true then
									
												
												control:AddLine("|c00FFFF[ "..RBPName.."-RQ : ".. RB.AllCharBVT[charIndex][charRecipesIndex].recipequality.." PR : "..RB.AllCharBVT[charIndex][charRecipesIndex].provisionerLevelReq.." QR : "..RB.AllCharBVT[charIndex][charRecipesIndex].qualityReq.." ]")	
											
										end	
										
									else
										d("***RecipeBook***")
										d("RecipeBook Error, Please Logout and Delete Your") 
										d("Settings File In The Saved Variables Folder And Try Again.")
										d("Or Possibly Just A /reloadui")
									end
									
							end
			
			
						end
				--multichar false
				elseif RB.items.SaveVars.multichar == false and RB.AllCharBVT[charIndex][charRecipesIndex].charname == GetUnitName("player") then
			
						local RBPName = zo_strformat(SI_TOOLTIP_ITEM_NAME, RB.AllCharBVT[charIndex][charRecipesIndex].link)	
							
								for IngIndex =1, #RB.AllCharBVT[charIndex][charRecipesIndex].ingredients do
									
									if string.lower(RB.AllCharBVT[charIndex][charRecipesIndex].ingredients[IngIndex].ingredientname)== string.lower(name) then
									found = true
										if dontprntknwnonce == false then
											dontprntknwnonce = true
											if RB.AllCharBVT[charIndex][charRecipesIndex].charname ~= nil then
												if Ingredient_IDs[GetItemID(RB.AllCharBVT[charIndex][charRecipesIndex].ingredients[IngIndex].ingredient)] then
														control:AddVerticalPadding(5)
														RB.TooltipAddedByKnown = true
														control:AddLine(Ingredient_IDs[GetItemID(RB.AllCharBVT[charIndex][charRecipesIndex].ingredients[IngIndex].ingredient)].tooltip, "ZoFontGame", 1, 1, 1, CENTER, MODIFY_TEXT_TYPE_UPPERCASE, LEFT, false)
														control:AddVerticalPadding(5)
												end
												control:AddLine("-=Recipes Known By : "..RB.AllCharBVT[charIndex][charRecipesIndex].charname.."=-", "ZoFontGameBold", 1, 1, 1, CENTER, MODIFY_TEXT_TYPE_UPPERCASE, LEFT, false)		
											else
												d("***RecipeBook***")
												d("RecipeBook Error, Please Logout and Delete Your") 
												d("Settings File In The Saved Variables Folder And Try Again.")
												d("Or Possibly Just A /reloadui")
											end
										end
										
											if (RB.AllCharBVT ~= nil) and (RBPName ~= nil) and found ~= false then
												if RB.AllCharBVT[charIndex][charRecipesIndex].tracked == false then
													
														
														control:AddLine("[ "..RBPName.."-RQ : ".. RB.AllCharBVT[charIndex][charRecipesIndex].recipequality.." PR : "..RB.AllCharBVT[charIndex][charRecipesIndex].provisionerLevelReq.." QR : "..RB.AllCharBVT[charIndex][charRecipesIndex].qualityReq.." ]")	
													
												elseif RB.AllCharBVT[charIndex][charRecipesIndex].tracked == true then
											
														
														control:AddLine("|c00FFFF[ "..RBPName.."-RQ : ".. RB.AllCharBVT[charIndex][charRecipesIndex].recipequality.." PR : "..RB.AllCharBVT[charIndex][charRecipesIndex].provisionerLevelReq.." QR : "..RB.AllCharBVT[charIndex][charRecipesIndex].qualityReq.." ]")	
													
												end	
												
											else
												d("***RecipeBook***")
												d("RecipeBook Error, Please Logout and Delete Your") 
												d("Settings File In The Saved Variables Folder And Try Again.")
												d("Or Possibly Just A /reloadui")
											end
									end
								end
								
				end--endmulticharcheck
				
			end
			
		end
		if found == true then
		control:AddVerticalPadding(15)
		control:AddLine("|cFFA500Tooltips By RecipeBook")	
		end

end

function RBToolTipArray:AddHeaderLineInfo(control, name, line)
	if RBToolTipArray[name] then
		r,g,b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, RBToolTipArray[name].tier+1)
		control:AddHeaderLine("("..GetRecipeListInfo(RBToolTipArray[name].recipeListIndex)..")", "ZoFontGameBold", line, TOOLTIP_HEADER_SIDE_RIGHT, r, g, b)
	end
end

local function RBToolTipArray_RecipeLearned(eventType, recipeListIndex, recipeIndex)
	RBToolTipArray:AddRecipeInredients(recipeListIndex, recipeIndex)
end

local function RBToolTipArray_AddProvisioningTooltipInfo(control, name)
	return RBToolTipArray:AddProvisioningTooltipInfo(control, name)
end

local function RBToolTipArray_AddHeaderLineInfo(control, name, line)
return RBToolTipArray:AddHeaderLineInfo(control, name, line)
end

function RB.AddTooltipLineForProvisioningMaterial(control, itemId)
    if Ingredient_IDs[itemId] then
        local text = Ingredient_IDs[itemId].tooltip
            if text == "For extra flavor in |c5B90F6blue|r and |cAA00FFpurple|r recipes" then
                text = "Tier 2 Ingredient"
            elseif text == "For extra flavor in |cAA00FFpurple|r recipes" then
                text = "Tier 3 Ingredient"
            end
    
        RB.AddTooltipLine(control, text)
    end
end

function RB.GetItemIdFromBagAndSlot(bagId, slotIndex)
    local itemLink = GetItemLink(bagId, slotIndex)
    local itemId = select(4, ZO_LinkHandler_ParseLink(itemLink))
    return tonumber(itemId)
end

function RB.AddTooltipLine(control, tooltipLine)
if RB.items.SaveVars.tooltips == false then return end

	if RB.TooltipAddedByKnown == false then
	    control:AddVerticalPadding(20)
		control:AddLine(tooltipLine, "ZoFontGame", 1, 1, 1, CENTER, MODIFY_TEXT_TYPE_UPPERCASE, LEFT, false)
		 control:AddVerticalPadding(5)
		control:AddLine("|cFFA500Tooltips By RecipeBook")	
	elseif RB.TooltipAddedByKnown==true then
		RB.TooltipAddedByKnown = false
	end
end

function RB.OnLoad(eventCode, addOnName)--First thing when Games UI is loaded

	if (addOnName ~= "RecipeBook" ) then return end--called for compatiblity preventive mantinance...
	RB.AddonName = addOnName

	--throws all slash commands to the RBcommandHandler
	SLASH_COMMANDS["/rbs"] = RBcommandHandler
	SLASH_COMMANDS["/recipebook"] = RBcommandHandler
	SLASH_COMMANDS["/rcpbk"] = RBcommandHandler
	SLASH_COMMANDS["/rcpb"] = RBcommandHandler
	SLASH_COMMANDS["/rbit"] = RB.ShowIt
	
	--HOOKS for debugging
	EVENT_MANAGER:RegisterForEvent("RecipeBook", EVENT_OPEN_BANK, RB.PL_Opened)
	EVENT_MANAGER:RegisterForEvent("RecipeBook", EVENT_CLOSE_BANK, RB.PL_Closed)
	EVENT_MANAGER:RegisterForEvent("RecipeBook", EVENT_OPEN_GUILD_BANK, RB.GB_Opened)
	EVENT_MANAGER:RegisterForEvent("RecipeBook", EVENT_GUILD_BANK_ITEMS_READY, RB.GB_Ready)


	--Loading/Creating characters saved variables
	RB.items= ZO_SavedVars:NewAccountWide( "RB_SavedVars" , 2, "Items" , RB.dataDefaultItems, nil )
	RB.params= ZO_SavedVars:New( "RB_SavedVars" , 2, "Params" , RB.dataDefaultParams, nil )
	--RB.LAMSAVEDVARS= ZO_SavedVars:New("RB_LAMSAVEDVARS", 1, "Lam", RB.defaultSavedVariables, nil )
	
	
	--Do LAM Settings
	RBBuildLAMSettingsMenu()
	
	--grab char name
	thisCharName=GetUnitName("player")
	
	--by default switch to this char on load, after clicking its switched ...
	RB.LastClickedCharName = thisCharName
	
	--store them in the tracklist table b4 reset
	RB.TrackList = RB.items.Chars[thisCharName]
	RB.NoteArray = RB.items.Chars[thisCharName]
	
	--reset this characters items
	RB.items.Chars[thisCharName]={}

	--reset and then fill list of charcter names
	RB.CharsName={}
	for k,v in pairs(RB.items.Chars) do
		RB.CharsName[#RB.CharsName+1]=k
	end

	--update the loot
	RB.SavePlayerInvent()

	--hook onto the WM to display the UI
	--creates global variable 
	RB_UI = WINDOW_MANAGER:GetControlByName("RBUI")

	--Create the Blank UI
	RB.CreateMenu()
	RB.TrackList = {}
	
	-- Fill the Blank UI
	RB.CreateBank()


	
	
	--tooltip
	RBToolTipArray.ingredients = {}

	RBToolTipArray:BuildIngredientsList()
	
	local SetLootItemOrgFunc = ItemTooltip.SetLootItem
	ItemTooltip.SetLootItem = function(control, lootId,...)
		local _, name = GetLootItemInfo()
		name = zo_strformat("<<1>>", name)
		RBToolTipArray_AddHeaderLineInfo(control, name, 1)
		SetLootItemOrgFunc(control, lootId,...)
		RBToolTipArray_AddProvisioningTooltipInfo(control, name)
	end
	
	local SetBagItemOrgFunc = ItemTooltip.SetBagItem
	ItemTooltip.SetBagItem = function(control, bagId, slotIndex, ...)
		local tradeSkillType = GetItemCraftingInfo(bagId, slotIndex)
		
		local name = zo_strformat("<<1>>", GetItemName(bagId, slotIndex))
		if tradeSkillType == CRAFTING_TYPE_PROVISIONING then
			RBToolTipArray_AddHeaderLineInfo(control, name, 1)
		end
		SetBagItemOrgFunc(control, bagId, slotIndex, ...)
		if tradeSkillType == CRAFTING_TYPE_PROVISIONING then
			RBToolTipArray_AddProvisioningTooltipInfo(control, name)
		end
	end
	
	local InvokeSetBagItemTooltip = ItemTooltip.SetBagItem
    ItemTooltip.SetBagItem = function(control, bagId, slotIndex, ...)
        local tradeSkillType, itemType = GetItemCraftingInfo(bagId, slotIndex)
        InvokeSetBagItemTooltip(control, bagId, slotIndex, ...)
		if tradeSkillType == CRAFTING_TYPE_PROVISIONING then
		
	                RB.AddTooltipLineForProvisioningMaterial(control, RB.GetItemIdFromBagAndSlot(bagId, slotIndex))
		end
	end
	
	
	
	
	
	 
	--confirm load
	RB.AddonReady=true
end

function RB.MenuMinClick()
	if RB.MenuClickStatus == false then
		RB_UI.Menu:SetDimensions(300,15)
		RB_UI.Menu.BG:SetHidden(true)
		for i = 1, 10 do
			_G["RBUI_Menu_Recipe"..i]:SetHidden(true)
		end
		RB.MenuClickStatus = true
	else
		RB_UI.Menu:SetDimensions(550,300)
		RB_UI.Menu.BG:SetHidden(false)
		RB.PrepIT()
		RB.MenuClickStatus = false
	end
end

function RB.MenuCloseClick()
	RBUI_Menu:SetHidden(true)
end

function RB.CreateMenu()--Create ButtonUI

if RB_UI.Menu then return else
	
	RB_UI.Menu=WINDOW_MANAGER:CreateControl("RBUI_Menu",RBUI,CT_CONTROL)
	RB_UI.Menu.BG = WINDOW_MANAGER:CreateControl("RBUI_Menu_BG",RBUI_Menu,CT_BACKDROP)
	RB_UI.Menu.Title = WINDOW_MANAGER:CreateControl("RBUI_Menu_Title",RBUI_Menu,CT_LABEL)
	RB_UI.Menu.Close = WINDOW_MANAGER:CreateControl("RBUI_Menu_Close",RBUI_Menu,CT_BUTTON)
	RB_UI.Menu.Min = WINDOW_MANAGER:CreateControl("RBUI_Menu_Min",RBUI_Menu,CT_BUTTON)
	
	
	
	
	for i = 1, 10 do
	RB_UI.Menu["Recipe"..i] = WINDOW_MANAGER:CreateControl("RBUI_Menu_Recipe"..i,RBUI_Menu,CT_LABEL)
	end
	

	RB_UI.Menu.Close:SetHandler("OnClicked", function(self) 
		
	 RB.MenuCloseClick()
     end )
	 
	RB_UI.Menu.Min:SetHandler("OnClicked", function(self)
	
		RB.MenuMinClick()
    end )

    RBUI_Menu:SetHandler("OnMouseUp" , function(self) RB.MouseUp(self) end)

	--settings menu
	RB_UI.Menu:ClearAnchors()
	RB_UI.Menu:SetAnchor(TOPLEFT,RBUI,TOPLEFT,RB.params.RBUI_Menu[1],RB.params.RBUI_Menu[2])
	RB_UI.Menu:SetDimensions(550,300)
	RB_UI.Menu:SetMouseEnabled(true)
	RB_UI.Menu:SetMovable(true)
	RB_UI.Menu:SetHidden(true)
	
	--background
	RB_UI.Menu.BG:ClearAnchors()
	RB_UI.Menu.BG:SetAnchor(CENTER,RBUI_Menu,CENTER,0,0)
	RB_UI.Menu.BG:SetDimensions(550,300)
	RB_UI.Menu.BG:SetCenterColor(0,0,0,1)
	RB_UI.Menu.BG:SetEdgeColor(0,0,0,0)
	RB_UI.Menu.BG:SetAlpha(0.1)

	--header
	RB_UI.Menu.Title:ClearAnchors()
	RB_UI.Menu.Title:SetAnchor(LEFT,RBUI_Menu,TOPLEFT,0,0)
	RB_UI.Menu.Title:SetFont("ZoFontGameBold" )
	RB_UI.Menu.Title:SetColor(255,255,255,1.5)
	RB_UI.Menu.Title:SetText( "|cff8000Recipe Book Ingredient Tracker|" )
	
	--close
	RB_UI.Menu.Close:ClearAnchors()
	RB_UI.Menu.Close:SetAnchor(RIGHT,RBUI_Menu,TOPRIGHT,0,0)
	RB_UI.Menu.Close:SetFont("ZoFontGameBold" )
	RB_UI.Menu.Close:SetDimensions(25,25)
	RB_UI.Menu.Close:SetText( "|cff8000[X]" )
    RB_UI.Menu.Close:SetNormalFontColor(0.8,0.4,0,1)
	RB_UI.Menu.Close:SetMouseOverFontColor(0,255,255,.7)
   

	--min
	RB_UI.Menu.Min:ClearAnchors()
	RB_UI.Menu.Min:SetAnchor(RIGHT,RBUI_Menu,TOPRIGHT,-25,0)
	RB_UI.Menu.Min:SetFont("ZoFontGameBold" )
	RB_UI.Menu.Min:SetDimensions(25,25)
	RB_UI.Menu.Min:SetText( "|cff8000[-]" )
	RB_UI.Menu.Min:SetMouseOverFontColor(0.8,0.4,0,1)
	RB_UI.Menu.Min:SetMouseOverFontColor(0,255,255,.7)
	
	
	
	
	--recipes
	RB_UI.Menu.Recipe1:ClearAnchors()
	RB_UI.Menu.Recipe1:SetAnchor(LEFT,RBUI_Menu,TOPLEFT,0,50)
	RB_UI.Menu.Recipe1:SetFont("ZoFontGame" )
	RB_UI.Menu.Recipe1:SetColor(255,255,255,1.5)
	RB_UI.Menu.Recipe1:SetText( "|cff8000Recipes" )
	RB_UI.Menu.Recipe1:SetHidden(true)
	
	RB_UI.Menu.Recipe2:ClearAnchors()
	RB_UI.Menu.Recipe2:SetAnchor(LEFT,RBUI_Menu,TOPLEFT,0,75)
	RB_UI.Menu.Recipe2:SetFont("ZoFontGame" )
	RB_UI.Menu.Recipe2:SetColor(255,255,255,1.5)
	RB_UI.Menu.Recipe2:SetText( "|cff8000Recipes" )
	RB_UI.Menu.Recipe2:SetHidden(true)
	
	RB_UI.Menu.Recipe3:ClearAnchors()
	RB_UI.Menu.Recipe3:SetAnchor(LEFT,RBUI_Menu,TOPLEFT,0,100)
	RB_UI.Menu.Recipe3:SetFont("ZoFontGame" )
	RB_UI.Menu.Recipe3:SetColor(255,255,255,1.5)
	RB_UI.Menu.Recipe3:SetText( "|cff8000Recipes" )
	RB_UI.Menu.Recipe3:SetHidden(true)
	
	RB_UI.Menu.Recipe4:ClearAnchors()
	RB_UI.Menu.Recipe4:SetAnchor(LEFT,RBUI_Menu,TOPLEFT,0,125)
	RB_UI.Menu.Recipe4:SetFont("ZoFontGame" )
	RB_UI.Menu.Recipe4:SetColor(255,255,255,1.5)
	RB_UI.Menu.Recipe4:SetText( "|cff8000Recipes" )
	RB_UI.Menu.Recipe4:SetHidden(true)
	
	RB_UI.Menu.Recipe5:ClearAnchors()
	RB_UI.Menu.Recipe5:SetAnchor(LEFT,RBUI_Menu,TOPLEFT,0,150)
	RB_UI.Menu.Recipe5:SetFont("ZoFontGame" )
	RB_UI.Menu.Recipe5:SetColor(255,255,255,1.5)
	RB_UI.Menu.Recipe5:SetText( "|cff8000Recipes" )
	RB_UI.Menu.Recipe5:SetHidden(true)
	
	RB_UI.Menu.Recipe6:ClearAnchors()
	RB_UI.Menu.Recipe6:SetAnchor(LEFT,RBUI_Menu,TOPLEFT,0,175)
	RB_UI.Menu.Recipe6:SetFont("ZoFontGame" )
	RB_UI.Menu.Recipe6:SetColor(255,255,255,1.5)
	RB_UI.Menu.Recipe6:SetText( "|cff8000Recipes" )
	RB_UI.Menu.Recipe6:SetHidden(true)
	
	RB_UI.Menu.Recipe7:ClearAnchors()
	RB_UI.Menu.Recipe7:SetAnchor(LEFT,RBUI_Menu,TOPLEFT,0,200)
	RB_UI.Menu.Recipe7:SetFont("ZoFontGame" )
	RB_UI.Menu.Recipe7:SetColor(255,255,255,1.5)
	RB_UI.Menu.Recipe7:SetText( "|cff8000Recipes" )
	RB_UI.Menu.Recipe7:SetHidden(true)
	
	RB_UI.Menu.Recipe8:ClearAnchors()
	RB_UI.Menu.Recipe8:SetAnchor(LEFT,RBUI_Menu,TOPLEFT,0,225)
	RB_UI.Menu.Recipe8:SetFont("ZoFontGame" )
	RB_UI.Menu.Recipe8:SetColor(255,255,255,1.5)
	RB_UI.Menu.Recipe8:SetText( "|cff8000Recipes" )
	RB_UI.Menu.Recipe8:SetHidden(true)
	
	RB_UI.Menu.Recipe9:ClearAnchors()
	RB_UI.Menu.Recipe9:SetAnchor(LEFT,RBUI_Menu,TOPLEFT,0,250)
	RB_UI.Menu.Recipe9:SetFont("ZoFontGame" )
	RB_UI.Menu.Recipe9:SetColor(255,255,255,1.5)
	RB_UI.Menu.Recipe9:SetText( "|cff8000Recipes" )
	RB_UI.Menu.Recipe9:SetHidden(true)
	
	
	RB_UI.Menu.Recipe10:ClearAnchors()
	RB_UI.Menu.Recipe10:SetAnchor(LEFT,RBUI_Menu,TOPLEFT,0,275)
	RB_UI.Menu.Recipe10:SetFont("ZoFontGame" )
	RB_UI.Menu.Recipe10:SetColor(255,255,255,1.5)
	RB_UI.Menu.Recipe10:SetText( "|cff8000Recipes" )
	RB_UI.Menu.Recipe10:SetHidden(true)

	end
end

function RB.CreateBank()--Create Blank Container 
	local OldAnchor=false

	-- container settings
	RBUI_Container:ClearAnchors()
	RBUI_Container:SetAnchor(TOPLEFT,GuiRoot,TOPLEFT,RB.params.RBUI_Container[1],RB.params.RBUI_Container[2])
	RBUI_Container:SetMovable(true)

	-- do Slider
    RBUI_ContainerSlider:SetValue(4)


    -- Create a button to switch between guild bank names
	local nextXstep=0
    for i=1,#RB.items.Guilds do

    	-- Save the names of the guilds Keys
	    for k, v in pairs(RB.items.Guilds[i]) do
	        RB.GuildNames[#RB.GuildNames+1] = k
	    end

    	local guildname=tostring(RB.GuildNames[i])
    	WINDOW_MANAGER:CreateControl("RBUI_ContainerTitleGuildButton"..i,RBUI_ContainerTitle,CT_BUTTON)
    	_G["RBUI_ContainerTitleGuildButton"..i]:SetParent(RBUI_ContainerTitleGuildButtons)
		_G["RBUI_ContainerTitleGuildButton"..i]:SetFont("ZoFontGame" )
		nextXstep=(RBUI_Container:GetWidth()/#RB.items.Guilds*i)
    	_G["RBUI_ContainerTitleGuildButton"..i]:SetDimensions(RBUI_Container:GetWidth()/#RB.items.Guilds,20)
    	-- Making allowance for the width of the button
		_G["RBUI_ContainerTitleGuildButton"..i]:ClearAnchors()
    	_G["RBUI_ContainerTitleGuildButton"..i]:SetAnchor(TOP,RBUI_Container,TOPLEFT,nextXstep-_G["RBUI_ContainerTitleGuildButton"..i]:GetWidth()/2,40)
    	_G["RBUI_ContainerTitleGuildButton"..i]:SetText("["..guildname.."]")
    	_G["RBUI_ContainerTitleGuildButton"..i]:SetNormalFontColor(0,255,255,.7)
		_G["RBUI_ContainerTitleGuildButton"..i]:SetMouseOverFontColor(0.8,0.4,0,1)

		_G["RBUI_ContainerTitleGuildButton"..i]:SetHandler( "OnClicked" , function(self)
			RB.PrepareBankValues("Guild",i)
			RB.SortPreparedValues()
			RB.FillBank(4)	
		 end)
	end

    -- Create a button to switch between Players
	local nextXstep=0
    for i=1,#RB.CharsName do

    	local charname=tostring(RB.CharsName[i])
    	WINDOW_MANAGER:CreateControl("RBUI_ContainerTitleInventButton"..i,RBUI_ContainerTitle,CT_BUTTON)
    	_G["RBUI_ContainerTitleInventButton"..i]:SetParent(RBUI_ContainerTitleInventButtons)
		_G["RBUI_ContainerTitleInventButton"..i]:SetFont("ZoFontBookPaper" )
		nextXstep=(RBUI_Container:GetWidth()/#RB.CharsName*i)
    	_G["RBUI_ContainerTitleInventButton"..i]:SetDimensions(RBUI_Container:GetWidth()/#RB.CharsName,20)
    	-- Making allowance for the width of the button
		_G["RBUI_ContainerTitleInventButton"..i]:ClearAnchors()
    	_G["RBUI_ContainerTitleInventButton"..i]:SetAnchor(TOP,RBUI_Container,TOPLEFT,nextXstep-_G["RBUI_ContainerTitleInventButton"..i]:GetWidth()/2,40)
		
		
		if RB.items.Chars[charname] ~= nil then
			
    	_G["RBUI_ContainerTitleInventButton"..i]:SetText("["..charname.."(x"..#RB.items.Chars[charname]..")]")
		end
		
		
		
		
		_G["RBUI_ContainerTitleInventButton"..i].LastClickedChar = charname
    	_G["RBUI_ContainerTitleInventButton"..i]:SetNormalFontColor(0,255,255,.7)
		_G["RBUI_ContainerTitleInventButton"..i]:SetMouseOverFontColor(0.8,0.4,0,1)

		_G["RBUI_ContainerTitleInventButton"..i]:SetHandler( "OnClicked" , function(self)
			RB.LastClickedCharName = self.LastClickedChar
			RB.PrepareBankValues("Invent",i)
			RB.PrepIT()
			RB.SortPreparedValues()
			RB.FillBank(4)	
		 end)
	end


    -- Edit the line (created from xml)
	for i = 1, 4 do
	    local dynamicControl = CreateControlFromVirtual("RBUI_Row", RBUI_Container, "RBTemplateRow",i)

	    -- line
	    local fromtop=100
		 _G["RBUI_Row"..i]:ClearAnchors()
	    _G["RBUI_Row"..i]:SetAnchor(TOP,RBUI_Container,TOP,0,fromtop+152*(i-1))


	    -- animation
	    _G["RBUI_Row"..i.."IconTimeline"]=ANIMATION_MANAGER:CreateTimelineFromVirtual("RBUI_IconAnimation",_G["RBUI_Row"..i.."ButtonIcon"])
	    

	end
end

function RB.PrepareBankValues(PrepareType,IdToPrepare)--Adds the handlers to the rows and preps the data for the rows
	RB.GuildBankIdToPrepare=GuildBankIdToPrepare
	RB.BankValueTable={}


	-- if PrepareType=="Bank" then
		-- debug("Preparing Player values")
		-- bagIcon, bagSlots=GetBagInfo(BAG_BANK)
		-- RB.ItemCounter=0
		-- while (RB.ItemCounter < bagSlots) do
			-- if GetItemName(BAG_BANK,RB.ItemCounter)~="" then

				-- --Getting rid of the debris, while maintaining
				-- local name = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemName(BAG_BANK, RB.ItemCounter))
				-- local link = GetItemLink(BAG_BANK,RB.ItemCounter)
				-- clearlink =string.gsub(link, "|h.+|h", "|h"..tostring(name).."|h")

				
				
				-- local stackCount = GetSlotStackSize(BAG_BANK,RB.ItemCounter)
				-- local statValue = GetItemStatValue(BAG_BANK,RB.ItemCounter)
				-- local icon, stack, sellPrice, meetsUsageRequirement, locked, equipType, itemStyle, quality = GetItemInfo(BAG_BANK,RB.ItemCounter)
				-- local ItemType=GetItemType(BAG_BANK,RB.ItemCounter)

				-- RB.BankValueTable[#RB.BankValueTable+1]={
					-- ["link"]=tostring(clearlink),
					-- ["icon"] = tostring(icon),
					-- ["name"]=tostring(name),
					-- ["stackCount"]=stackCount,
					-- ["StatValue"]=statValue,
					-- ["sellPrice"] = sellPrice,
					-- ["quality"] = quality,
					-- ["meetsUsageRequirement"]=meetsUsageRequirement,
					-- ["ItemType"]=ItemType
				-- }
				-- debug(RB.BankValueTable[1])
			-- end
			-- RB.ItemCounter=RB.ItemCounter+1
		-- end
		-- RB.BankValueTable.CurSlots=#RB.BankValueTable
		-- RB.BankValueTable.MaxSlots=bagSlots

		-- RBUI_ContainerTitleInventButtons:SetHidden(true)
		-- RBUI_ContainerTitleGuildButtons:SetHidden(true)
	-- elseif PrepareType=="Invent" then
	
		

		local LoadingCharName=RB.CharsName[IdToPrepare]
		debug(LoadingCharName)

		RB.BankValueTable=RB.items.Chars[LoadingCharName]--loads the created table from SavePlayerInventory to BankValueTable for parsing in FillBank

		RBUI_ContainerTitleInventButtons:SetHidden(false)
		RBUI_ContainerTitleGuildButtons:SetHidden(true)
		
	-- elseif PrepareType=="Guild" then
		-- bagIcon, bagSlots=GetBagInfo(BAG_GUILDBANK)
		-- debug("Preparing Guild values")

	    -- local guildname=tostring(GetGuildName(IdToPrepare))
		-- RB.BankValueTable=RB.items.Guilds[IdToPrepare][guildname]
		
		-- RBUI_ContainerTitleInventButtons:SetHidden(true)
		-- RBUI_ContainerTitleGuildButtons:SetHidden(false)
	-- else
		-- debug("Unknown prepare type: "..tostring(PrepareType))
	-- end

    RBUI_ContainerSlider:SetHandler("OnValueChanged",function(self, value, eventReason)
		RB.FillBank(value)
		
    end)

    for i=1,4 do
		if _G["RBUI_Row"..i] ~= nil then
	        _G["RBUI_Row"..i]:SetHandler("OnMouseWheel" , function(self,delta)
			
		    	local calculatedvalue=RB.CurrentLastValue-delta
		    	if (calculatedvalue>=4) and (calculatedvalue<=#RB.BankValueTable) then
				RB.MouseWheelTracker=calculatedvalue
		    		RB.FillBank(calculatedvalue)
		    		RBUI_ContainerSlider:SetValue(calculatedvalue)
		    	end
		    end )
		end
    end
	
RB.SortPreparedValues()
return RB.BankValueTable
end

function RQSortClick()
		
	function compare(a,b)
			return a["recipequality"]>b["recipequality"]		
	end--magic end???
	
	function compare2(a,b)
			return a["recipequality"]<b["recipequality"]		
	end--magic end???
			local RBtmpBVTRQt = {}
			local RBtmpBVTRQf = {}
				for i=1,#RB.BankValueTable do
					if RB.BankValueTable[i].visible == "true" then
					
						RBtmpBVTRQt[#RBtmpBVTRQt+1] = RB.BankValueTable[i]
					elseif RB.BankValueTable[i].visible == "false" then
						RBtmpBVTRQf[#RBtmpBVTRQf+1] = RB.BankValueTable[i]
					end
				end
				
				if RB.SortRQClickedCnt == 1 then
						RB.SortRQClickedCnt = RB.SortRQClickedCnt +1
						table.sort(RBtmpBVTRQt,compare)
						RB.BankValueTable = RBtmpBVTRQt
						for z=1,#RBtmpBVTRQf do
							table.insert(RB.BankValueTable,RBtmpBVTRQf[z])
						end	
				elseif RB.SortRQClickedCnt == 2 then
						table.sort(RBtmpBVTRQt,compare2)
						RB.BankValueTable = RBtmpBVTRQt
						
							for zz=1,#RBtmpBVTRQf do
								table.insert(RB.BankValueTable,RBtmpBVTRQf[zz])
							end
						RB.SortRQClickedCnt = 1
				end
RB.FillBank(4)
end

function PRSortClick()
		
	function compare(a,b)
			return a["provisionerLevelReq"]>b["provisionerLevelReq"]		
	end--magic end???
	
	function compare2(a,b)
			return a["provisionerLevelReq"]<b["provisionerLevelReq"]		
	end--magic end???

		local RBtmpBVTPRt = {}
			local RBtmpBVTPRf = {}
				for i=1,#RB.BankValueTable do
					if RB.BankValueTable[i].visible == "true" then
					
						RBtmpBVTPRt[#RBtmpBVTPRt+1] = RB.BankValueTable[i]
					elseif RB.BankValueTable[i].visible == "false" then
						RBtmpBVTPRf[#RBtmpBVTPRf+1] = RB.BankValueTable[i]
					end
				end
				
				if RB.SortPRClickedCnt == 1 then
						RB.SortPRClickedCnt = RB.SortPRClickedCnt +1
						table.sort(RBtmpBVTPRt,compare)
						RB.BankValueTable = RBtmpBVTPRt
						for z=1,#RBtmpBVTPRf do
							table.insert(RB.BankValueTable,RBtmpBVTPRf[z])
						end	
				elseif RB.SortPRClickedCnt == 2 then
						table.sort(RBtmpBVTPRt,compare2)
						RB.BankValueTable = RBtmpBVTPRt
						
							for zz=1,#RBtmpBVTPRf do
								table.insert(RB.BankValueTable,RBtmpBVTPRf[zz])
							end
						RB.SortPRClickedCnt = 1
				end
RB.FillBank(4)
end

function QRSortClick()
		
	function compare(a,b)
			return a["qualityReq"]>b["qualityReq"]		
	end--magic end???
	
	function compare2(a,b)
			return a["qualityReq"]<b["qualityReq"]		
	end--magic end???
	
		local RBtmpBVTQRt = {}
			local RBtmpBVTQRf = {}
				for i=1,#RB.BankValueTable do
					if RB.BankValueTable[i].visible == "true" then
					
						RBtmpBVTQRt[#RBtmpBVTQRt+1] = RB.BankValueTable[i]
					elseif RB.BankValueTable[i].visible == "false" then
						RBtmpBVTQRf[#RBtmpBVTQRf+1] = RB.BankValueTable[i]
					end
				end
				
				if RB.SortQRClickedCnt == 1 then
						RB.SortQRClickedCnt = RB.SortQRClickedCnt +1
						table.sort(RBtmpBVTQRt,compare)
						RB.BankValueTable = RBtmpBVTQRt
						for z=1,#RBtmpBVTQRf do
							table.insert(RB.BankValueTable,RBtmpBVTQRf[z])
						end	
				elseif RB.SortQRClickedCnt == 2 then
						table.sort(RBtmpBVTQRt,compare2)
						RB.BankValueTable = RBtmpBVTQRt
						
							for zz=1,#RBtmpBVTQRf do
								table.insert(RB.BankValueTable,RBtmpBVTQRf[zz])
							end
						RB.SortQRClickedCnt = 1
				end
RB.FillBank(4)
end

function NameSortClick()
		
	function compare(a,b)
			return a["name"]>b["name"]		
	end--magic end???
	
	function compare2(a,b)
			return a["name"]<b["name"]		
	end--magic end???
	
	
	
	
	
	
	
		local RBtmpBVTNamet = {}
			local RBtmpBVTNamef = {}
				for i=1,#RB.BankValueTable do
					if RB.BankValueTable[i].visible == "true" then
					
						RBtmpBVTNamet[#RBtmpBVTNamet+1] = RB.BankValueTable[i]
					elseif RB.BankValueTable[i].visible == "false" then
						RBtmpBVTNamef[#RBtmpBVTNamef+1] = RB.BankValueTable[i]
					end
				end
				
				if RB.SortNameClickedCnt == 1 then
						RB.SortNameClickedCnt = RB.SortNameClickedCnt +1
						table.sort(RBtmpBVTNamet,compare)
						RB.BankValueTable = RBtmpBVTNamet
						for z=1,#RBtmpBVTNamef do
							table.insert(RB.BankValueTable,RBtmpBVTNamef[z])
						end	
				elseif RB.SortNameClickedCnt == 2 then
						table.sort(RBtmpBVTNamet,compare2)
						RB.BankValueTable = RBtmpBVTNamet
						
							for zz=1,#RBtmpBVTNamef do
								table.insert(RB.BankValueTable,RBtmpBVTNamef[zz])
							end
						RB.SortNameClickedCnt = 1
				end
RB.FillBank(4)
end

function RB.SortPreparedValues()--sort values by first identifier "name"

	function compare(a,b)
		return a["name"]<b["name"]	
	end

	table.sort(RB.BankValueTable,compare)
end

function RB.FillBank(last)--Main function that goes over the table and fills the row with data

	if last<=1 then debug("last<=1") return end
	    if (RB.BankValueTable==nil) then 
			if RB.IngredientColorPickerClicked == false then
		    	d("No Recipes Avaliable Please Learn Some! Or Possibly Run /reloadui")
			else
			RB.IngredientColorPickerClicked = false
			end	
		    	RBUI_ContainerItemCounter:SetHidden(true)
		    	RBUI_ContainerSlider:SetHidden(true)
		    	RB.HideContainer(true)
			    	for i=1,4 do
			    		_G["RBUI_Row"..i]:SetHidden(true)
			    	end
		    	return
		else
			local texture='/esoui/art/miscellaneous/scrollbox_elevator.dds'
			RBUI_ContainerSlider:SetHidden(false)
	    	RBUI_ContainerSlider:SetMinMax(4,#RB.BankValueTable)
	    	--RBUI_ContainerSlider:SetThumbTexture(texture, texture, texture, 18, (1/#RB.BankValueTable*25000)/3, 0, 0, 1, 1)
			RBUI_ContainerSlider:SetThumbTexture(texture, texture, texture, 18, 35, 0, 0, 1, 1)
	    	for i=1,4 do
	    		_G["RBUI_Row"..i]:SetHidden(false)
	    	end
	    end
    RB.CurrentLastValue=last

    if #RB.BankValueTable<4 then
	
	
	
    	-- Hiding Slider
    	RBUI_ContainerSlider:SetHidden(true)
	    -- Filling comes from the top
	    for i=1,#RB.BankValueTable do
		
			if RB.BankValueTable[i].visible == "true" then 
			_G["RBUI_Row"..i]:SetHidden(false)
		else
			_G["RBUI_Row"..i]:SetHidden(true)
		end
	    	local icon,sellPrice,meetsUsageRequirement,equipType,itemStyle = GetItemLinkInfo(RB.BankValueTable[i].link)
			 
			_G["RBUI_Row"..i].id=i
	    	_G["RBUI_Row"..i].ItemType=RB.BankValueTable[i].ItemType

			local RBcraftcount = {}
			local RBcraftcounttmptotal = 0
			local RBcraftcounttotal = 0
			
			--run the numbers and see how many of this recipe can be made
				for z =1,#RB.BankValueTable[i].ingredients do
				
						RBcraftcounttmptotal = RB.BankValueTable[i].ingredients[z].bankstackcount + RB.BankValueTable[i].ingredients[z].bagstackcount 
							if RBcraftcounttmptotal ~= 0 then
							RBcraftcount[#RBcraftcount+1]={
		 						["int"]=RBcraftcounttmptotal
		 						}
							
							end
				end		
				for zz=1, #RBcraftcount do
					if zz==2 then
						RBcraftcounttotal = math.min(RBcraftcount[1].int,RBcraftcount[2].int)
					elseif zz==3 then
						RBcraftcounttotal = math.min(RBcraftcount[1].int,RBcraftcount[2].int,RBcraftcount[3].int)
					elseif zz==4 then
						RBcraftcounttotal = math.min(RBcraftcount[1].int,RBcraftcount[2].int,RBcraftcount[3].int,RBcraftcount[4].int)
					elseif zz==5 then
						RBcraftcounttotal = math.min(RBcraftcount[1].int,RBcraftcount[2].int,RBcraftcount[3].int,RBcraftcount[4].int,RBcraftcount[5].int)
					end
					if zz >= 2 and zz == #RBcraftcount then
						RBDisplayCraft = true
					end
				end
				
				
				
			if (RB.NoteArray ~= nil) then
				for zzz=1, #RB.NoteArray do
					if RB.NoteArray[zzz].recipenote ~= "BLANKNOTE" and RB.NoteArray[zzz].recipenote ~= "" and string.lower(RB.NoteArray[zzz].link) == string.lower(_G["RBUI_Row"..i.."Name"]:GetText()) then
					
						_G["RBUI_Row"..i].note=RB.NoteArray[zzz].recipenote
						_G["RBUI_Row"..i].comparelink=string.lower(RB.NoteArray[zzz].link)
					elseif RB.NoteArray[zzz].recipenote == "BLANKNOTE" and string.lower(RB.NoteArray[zzz].link) == string.lower(_G["RBUI_Row"..i.."Name"]:GetText()) then
				
						_G["RBUI_Row"..i].note= nil
						_G["RBUI_Row"..i].comparelink=string.lower(RB.NoteArray[zzz].link)
					end
				end
			end
	    	-- Register display tooltips when you hover on the line
		    _G["RBUI_Row"..i]:SetHandler("OnMouseEnter", function(self)
			
		    	-- There may be another anchor. Its parent is important to us
		    	OldAnchor=_G["RBUI_Row"..i.."ButtonIcon"]:GetParent()
		    	ItemTooltip:ClearAnchors()
		    	ItemTooltip:ClearLines()
		    	ItemTooltip:SetAnchor(CENTER,OldAnchor,CENTER,-600,0)
		    	ItemTooltip:SetLink(_G["RBUI_Row"..i.."Name"]:GetText())
				
				if RBDisplayCraft == true and RBcraftcounttotal ~= 0 then
					ItemTooltip:AddVerticalPadding(15)
					ItemTooltip:AddLine("You Can Craft x"..RBcraftcounttotal.." Of This Recipe")
				end
		    	ItemTooltip:SetAlpha(1)
				
				if RBDisplayCraft == true and RBcraftcounttotal ~= 0 then
					ItemTooltip:AddVerticalPadding(15)
					ItemTooltip:AddLine("You Can Craft x"..RBcraftcounttotal.." Of This Recipe")
				end
		
			if (self.note ~= nil) and self.comparelink ==  string.lower(_G["RBUI_Row"..i.."Name"]:GetText()) then
				
					ItemTooltip:AddVerticalPadding(15)
					ItemTooltip:AddLine(self.note)
				
			end
		
				--end run numbers
		    	ItemTooltip:SetHidden(false)
		    	end)

		    _G["RBUI_Row"..i]:SetHandler("OnMouseExit", function(self)
		    	ItemTooltip:ClearAnchors()
		    	ItemTooltip:ClearLines()
		    	ItemTooltip:SetAlpha(0)
		    	ItemTooltip:SetHidden(true)
		    	end)

			_G["RBUI_Row"..i.."ButtonIcon"]:SetTexture(RB.BankValueTable[i].icon)
			
		
			
			_G["RBUI_Row"..i.."ITB"].recipetotrack=i
			_G["RBUI_Row"..i.."ITB"].tracked=RB.BankValueTable[i].tracked
			_G["RBUI_Row"..i.."ITB"].recipename=RB.BankValueTable[i].name
			
			
			

			if RB.BankValueTable[i].tracked == true then
			_G["RBUI_Row"..i.."ITBTexture"]:SetColor(1,0,0,1)--red
			elseif RB.BankValueTable[i].tracked == false then
			_G["RBUI_Row"..i.."ITBTexture"]:SetColor(1,1,1,1) --normal
			end
			
			
	
	
	
	
	
			_G["RBUI_Row"..i.."ITB"]:SetHandler("OnMouseUp", function(self,button)			
			if self.tracked == false then
					self.tracked=true
					_G["RBUI_Row"..i.."ITBTexture"]:SetColor(1,0,0,1)--red
					RB.BankValueTable[self.recipetotrack].tracked = true
					RB.PrepIT()
			elseif self.tracked == true then
			self.tracked=false
					_G["RBUI_Row"..i.."ITBTexture"]:SetColor(1,1,1,1) --normal
					for tlt = 1, #RB.BankValueTable do
						if RB.BankValueTable[tlt].name == self.recipename then
						RB.BankValueTable[self.recipetotrack].tracked = false
							RB.PrepIT()						
						end
						
					end
			end
			end)
			
			
			_G["RBUI_Row"..i.."Name"]:SetFont(RB.items.SaveVars.choosenrecipenamefont.f)
			if RBDisplayCraft == true and RBcraftcounttotal ~= 0 then
			_G["RBUI_Row"..i.."Name"]:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, RB.BankValueTable[i].link).." x"..tostring(RBcraftcounttotal))
			else
			_G["RBUI_Row"..i.."Name"]:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, RB.BankValueTable[i].link))
			end
			
			
			for z = 1, #RB.BankValueTable[i].ingredients do
			

			
			
			--_G["RBUI_Row"..i.."INGREDIENTSBUTTON"..z]:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, RB.BankValueTable[i].ingredients[z].ingredient).."|c00FF00-"..RB.BankValueTable[i].ingredients[z].bankstackcount.."|cFF0000-"..RB.BankValueTable[i].ingredients[z].bagstackcount)
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON"..z]:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, RB.BankValueTable[i].ingredients[z].ingredientname).."-"..RB.BankValueTable[i].ingredients[z].bankstackcount.."-"..RB.BankValueTable[i].ingredients[z].bagstackcount)
					
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON"..z].ingredient=RB.BankValueTable[i].ingredients[z]

			if Ingredient_IDs[GetItemID(RB.BankValueTable[i].ingredients[z].ingredient)] then
				_G["RBUI_Row"..i.."INGREDIENTSBUTTON"..z].TP = Ingredient_IDs[GetItemID(RB.BankValueTable[i].ingredients[z].ingredient)].tooltip
			end
			
			RBtmp_r = RB.items.SaveVars.ingredientcolor.r
			RBtmp_g = RB.items.SaveVars.ingredientcolor.g
			RBtmp_b = RB.items.SaveVars.ingredientcolor.b
			RBtmp_a = RB.items.SaveVars.ingredientcolor.a
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON"..z]:SetNormalFontColor(RBtmp_r,RBtmp_g,RBtmp_b,RBtmp_a)
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON"..z]:SetMouseOverFontColor(0.8,0.4,0,1)
			
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON"..z]:SetFont(RB.items.SaveVars.chooseningredientfont.f)
			
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON"..z]:SetHandler("OnMouseUp", function(self,button)		
			RB_PopTooltip(self.ingredient.ingredient,self.TP)
			end)
		end
		
			if #RB.BankValueTable[i].ingredients<= 2 then
			
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON2"]:SetHidden(false)
			
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON3"]:SetHidden(true)
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON4"]:SetHidden(true)
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON5"]:SetHidden(true)
			elseif #RB.BankValueTable[i].ingredients<=3 then
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON2"]:SetHidden(false)
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON3"]:SetHidden(false)
			
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON4"]:SetHidden(true)
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON5"]:SetHidden(true)
			elseif #RB.BankValueTable[i].ingredients<=4 then
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON2"]:SetHidden(false)
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON3"]:SetHidden(false)
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON4"]:SetHidden(false)
			
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON5"]:SetHidden(true)
			elseif #RB.BankValueTable[i].ingredients<=5 then
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON2"]:SetHidden(false)
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON3"]:SetHidden(false)
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON4"]:SetHidden(false)
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON5"]:SetHidden(false)
			
			end

			
				if RB.BankValueTable[i].recipequality == 1 then
				_G["RBUI_Row"..i.."RecipeQuality"]:SetText("|cFFFFFF"..RB.BankValueTable[i].recipequality)
				elseif RB.BankValueTable[i].recipequality == 2 then
			    _G["RBUI_Row"..i.."RecipeQuality"]:SetText("|c00FF00"..RB.BankValueTable[i].recipequality)
				elseif RB.BankValueTable[i].recipequality == 3 then
				_G["RBUI_Row"..i.."RecipeQuality"]:SetText("|c0000FF"..RB.BankValueTable[i].recipequality)
				elseif RB.BankValueTable[i].recipequality == 4 then
				_G["RBUI_Row"..i.."RecipeQuality"]:SetText("|c800080"..RB.BankValueTable[i].recipequality)
				elseif RB.BankValueTable[i].recipequality == 5 then
				_G["RBUI_Row"..i.."RecipeQuality"]:SetText("|cFFA500"..RB.BankValueTable[i].recipequality)
				else
				_G["RBUI_Row"..i.."RecipeQuality"]:SetText(RB.BankValueTable[last].recipequality)
				end
				
			
			
			
		    if (RB.BankValueTable[i].provisionerLevelReq~=0) then
				_G["RBUI_Row"..i.."StatValue"]:SetText(RB.BankValueTable[i].provisionerLevelReq)
			else
				_G["RBUI_Row"..i.."StatValue"]:SetText("-")
			end
			_G["RBUI_Row"..i.."SellPrice"]:SetText(RB.BankValueTable[i].qualityReq)
			
			
				
			--recipebookaddon
			_G["RBUI_Row"..i]:SetHandler("OnMouseUp", function(self,button) 
		    	if button==2 then 
				for z = 1, #RB.BankValueTable[i].ingredients do
					ZO_ChatWindowTextEntryEditBox:SetText(tostring(ZO_ChatWindowTextEntryEditBox:GetText()).."["..zo_strformat(SI_TOOLTIP_ITEM_NAME, RB.BankValueTable[self.id].ingredients[z].ingredient).."]")
				end


				elseif button==1 then
					ZO_ChatWindowTextEntryEditBox:SetText(tostring(ZO_ChatWindowTextEntryEditBox:GetText()).."["..zo_strformat(SI_TOOLTIP_ITEM_NAME, RB.BankValueTable[self.id].link).."]")

				end
				
	    	end)
			
		end

		-- Hide blank lines
		for i=#RB.BankValueTable+1,4 do
			_G["RBUI_Row"..i]:SetHidden(true)
		end

    else
    	-- show slider
    	RBUI_ContainerSlider:SetHidden(false)
	    -- Filling is below
	    for i=4,1,-1 do
		
		if RB.BankValueTable[last].visible == "false" then 
		_G["RBUI_Row"..i]:SetHidden(true)
		else
		_G["RBUI_Row"..i]:SetHidden(false)
		end
		
		if RB.DFShwncnt <= 4 then
		RBUI_ContainerSlider:SetHidden(true)
		end
		
		
	    	local icon,sellPrice,meetsUsageRequirement,equipType,itemStyle = GetItemLinkInfo(RB.BankValueTable[last].link)
		
	    	_G["RBUI_Row"..i].id=last
	    	_G["RBUI_Row"..i].ItemType=RB.BankValueTable[last].ItemType
			_G["RBUI_Row"..i].ingredients=RB.BankValueTable[last].ingredients
			
			
			
			
			
			local RBcraftcount = {}
			local RBcraftcounttmptotal = 0
			local RBcraftcounttotal = 0
			
			
			--run the numbers and see how many of this recipe can be made
				for z =1,#RB.BankValueTable[last].ingredients do
				
						RBcraftcounttmptotal = RB.BankValueTable[last].ingredients[z].bankstackcount + RB.BankValueTable[last].ingredients[z].bagstackcount 
							--if RBcraftcounttmptotal ~= 0 then
							RBcraftcount[#RBcraftcount+1]={
		 						["int"]=RBcraftcounttmptotal
		 						}
							
							--end
				end		
				for zz=1, #RBcraftcount do
					if zz==2 then
					RBcraftcounttotal = math.min(RBcraftcount[1].int,RBcraftcount[2].int)
					elseif zz==3 then
					RBcraftcounttotal = math.min(RBcraftcount[1].int,RBcraftcount[2].int,RBcraftcount[3].int)
					elseif zz==4 then
					RBcraftcounttotal = math.min(RBcraftcount[1].int,RBcraftcount[2].int,RBcraftcount[3].int,RBcraftcount[4].int)
					elseif zz==5 then
					RBcraftcounttotal = math.min(RBcraftcount[1].int,RBcraftcount[2].int,RBcraftcount[3].int,RBcraftcount[4].int,RBcraftcount[5].int)
					end
					
					
					
					if zz >= 2 and zz == #RBcraftcount and RBcraftcounttotal ~= 0 then
						RBDisplayCraft = true
					end
					
				end
				
			
			
				
			if (RB.NoteArray ~= nil) then
				for zzz=1, #RB.NoteArray do
					if RB.NoteArray[zzz].recipenote ~= "BLANKNOTE" and RB.NoteArray[zzz].recipenote ~= "" and string.lower(RB.NoteArray[zzz].link) == string.lower(_G["RBUI_Row"..i.."Name"]:GetText()) then
					
						_G["RBUI_Row"..i].note=RB.NoteArray[zzz].recipenote
						_G["RBUI_Row"..i].comparelink=string.lower(RB.NoteArray[zzz].link)
					elseif RB.NoteArray[zzz].recipenote == "BLANKNOTE" and string.lower(RB.NoteArray[zzz].link) == string.lower(_G["RBUI_Row"..i.."Name"]:GetText()) then
				
						_G["RBUI_Row"..i].note= nil
						_G["RBUI_Row"..i].comparelink=string.lower(RB.NoteArray[zzz].link)
					end
				end
			end
		    -- Register display tooltips when you hover on the line
		    _G["RBUI_Row"..i]:SetHandler("OnMouseEnter", function(self)
		
		    	-- There may be another anchor. Its parent is important to us
		    	OldAnchor=_G["RBUI_Row"..i.."ButtonIcon"]:GetParent()
		    	ItemTooltip:ClearAnchors()
		    	ItemTooltip:ClearLines()

		    	if _G["RBUI_Row"..i]:GetLeft()>=480 then
				ItemTooltip:ClearAnchors()
		    		ItemTooltip:SetAnchor(CENTER,OldAnchor,CENTER,-480,0)
		    	else
				ItemTooltip:ClearAnchors()
		    		ItemTooltip:SetAnchor(CENTER,OldAnchor,CENTER,500,0)
		    	end
				
			
		    ItemTooltip:SetLink(_G["RBUI_Row"..i.."Name"]:GetText())

		    	
		    	
		    	ItemTooltip:SetAlpha(1)
				
				
				if RBDisplayCraft == true and RBcraftcounttotal ~= 0 then
					ItemTooltip:AddVerticalPadding(15)
					ItemTooltip:AddLine("You Can Craft x"..RBcraftcounttotal.." Of This Recipe")
				end
				
				
				
				
			
			if (self.note ~= nil) and self.comparelink == string.lower(_G["RBUI_Row"..i.."Name"]:GetText()) then
					
					ItemTooltip:AddVerticalPadding(15)
					ItemTooltip:AddLine(self.note)
			end
					
				
				
				
		    	ItemTooltip:SetHidden(false)
		    	_G["RBUI_Row"..i.."Highlight"]:SetAlpha(1)  

		    	_G["RBUI_Row"..i.."IconTimeline"]:PlayFromStart()
		    	end)

		    _G["RBUI_Row"..i]:SetHandler("OnMouseExit", function(self)
		    	ItemTooltip:ClearAnchors()
		    	ItemTooltip:ClearLines()
		    	ItemTooltip:SetAlpha(0)
		    	ItemTooltip:SetHidden(true)
		    	_G["RBUI_Row"..i.."Highlight"]:SetAlpha(0) 

		    	_G["RBUI_Row"..i.."IconTimeline"]:PlayFromEnd()

			    

		    	end)

			_G["RBUI_Row"..i.."ButtonIcon"]:SetTexture(RB.BankValueTable[last].icon)

			
			_G["RBUI_Row"..i.."ITB"].recipetotrack=last
			_G["RBUI_Row"..i.."ITB"].tracked=RB.BankValueTable[last].tracked
			_G["RBUI_Row"..i.."ITB"].recipename=RB.BankValueTable[last].name
			
			
			

			if RB.BankValueTable[last].tracked == true then
			--table.insert(RB.TrackList,RB.BankValueTable[last])
			_G["RBUI_Row"..i.."ITBTexture"]:SetColor(1,0,0,1)--red
			elseif RB.BankValueTable[last].tracked == false then
			_G["RBUI_Row"..i.."ITBTexture"]:SetColor(1,1,1,1) --normal
			end
			
			
	
	
	
	
	
			_G["RBUI_Row"..i.."ITB"]:SetHandler("OnMouseUp", function(self,button)			
			if self.tracked == false then
					self.tracked=true
					_G["RBUI_Row"..i.."ITBTexture"]:SetColor(1,0,0,1)--red
					RB.BankValueTable[self.recipetotrack].tracked = true
					--table.insert(RB.TrackList,RB.BankValueTable[self.recipetotrack])
					RB.PrepIT()
			elseif self.tracked == true then
			self.tracked=false
					_G["RBUI_Row"..i.."ITBTexture"]:SetColor(1,1,1,1) --normal
					for tlt = 1, #RB.BankValueTable do
						if RB.BankValueTable[tlt].name == self.recipename then
						RB.BankValueTable[self.recipetotrack].tracked = false
							RB.PrepIT()						
						end
						
					end
			end
			end)
			
			
			_G["RBUI_Row"..i.."Name"]:SetFont(RB.items.SaveVars.choosenrecipenamefont.f)
			if RBDisplayCraft == true and RBcraftcounttotal ~= 0 then
			_G["RBUI_Row"..i.."Name"]:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, RB.BankValueTable[last].link).." |c00FFFFx"..tostring(RBcraftcounttotal))
			else
			_G["RBUI_Row"..i.."Name"]:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, RB.BankValueTable[last].link))
			end
			
		for z = 1, #RB.BankValueTable[last].ingredients do
		
			tmpingname=tostring(zo_strformat(SI_TOOLTIP_ITEM_NAME, RB.BankValueTable[last].ingredients[z].ingredientname))
			--_G["RBUI_Row"..i.."INGREDIENTSBUTTON"..z]:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, RB.BankValueTable[last].ingredients[z].ingredient).."|c00FF00-"..RB.BankValueTable[last].ingredients[z].bankstackcount.."|cFF0000-"..RB.BankValueTable[last].ingredients[z].bagstackcount)
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON"..z]:SetText(tmpingname.."-"..RB.BankValueTable[last].ingredients[z].bankstackcount.."-"..RB.BankValueTable[last].ingredients[z].bagstackcount)

			_G["RBUI_Row"..i.."INGREDIENTSBUTTON"..z].ingredient=RB.BankValueTable[last].ingredients[z]
			if Ingredient_IDs[GetItemID(RB.BankValueTable[last].ingredients[z].ingredient)] then
				_G["RBUI_Row"..i.."INGREDIENTSBUTTON"..z].TP = Ingredient_IDs[GetItemID(RB.BankValueTable[last].ingredients[z].ingredient)].tooltip
			end
			--ingredientcolor
			
			RBtmp_r = RB.items.SaveVars.ingredientcolor.r
			RBtmp_g = RB.items.SaveVars.ingredientcolor.g
			RBtmp_b = RB.items.SaveVars.ingredientcolor.b
			RBtmp_a = RB.items.SaveVars.ingredientcolor.a
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON"..z]:SetNormalFontColor(RBtmp_r,RBtmp_g,RBtmp_b,RBtmp_a)
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON"..z]:SetMouseOverFontColor(0.8,0.4,0,1)
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON"..z]:SetFont(RB.items.SaveVars.chooseningredientfont.f)
			
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON"..z]:SetHandler("OnMouseUp", function(self,button)		
			RB_PopTooltip(self.ingredient.ingredient,self.TP)
			end)
			
		end
		
		
		
			if #RB.BankValueTable[last].ingredients<= 2 then
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON2"]:SetHidden(false)
			
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON3"]:SetHidden(true)
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON4"]:SetHidden(true)
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON5"]:SetHidden(true)
			elseif #RB.BankValueTable[last].ingredients<=3 then
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON2"]:SetHidden(false)
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON3"]:SetHidden(false)
			
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON4"]:SetHidden(true)
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON5"]:SetHidden(true)
			elseif #RB.BankValueTable[last].ingredients<=4 then
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON2"]:SetHidden(false)
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON3"]:SetHidden(false)
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON4"]:SetHidden(false)
			
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON5"]:SetHidden(true)
			elseif #RB.BankValueTable[last].ingredients<=5 then
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON2"]:SetHidden(false)
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON3"]:SetHidden(false)
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON4"]:SetHidden(false)
			_G["RBUI_Row"..i.."INGREDIENTSBUTTON5"]:SetHidden(false)
			
			end
				
				--set the recipe book text for this row and change its color to match.
		
				if RB.BankValueTable[last].recipequality == 1 then
				_G["RBUI_Row"..i.."RecipeQuality"]:SetText("|cFFFFFF"..RB.BankValueTable[last].recipequality)
				elseif RB.BankValueTable[last].recipequality == 2 then
				_G["RBUI_Row"..i.."RecipeQuality"]:SetText("|c00FF00"..RB.BankValueTable[last].recipequality)
				elseif RB.BankValueTable[last].recipequality == 3 then
				_G["RBUI_Row"..i.."RecipeQuality"]:SetText("|c0000FF"..RB.BankValueTable[last].recipequality)
				elseif RB.BankValueTable[last].recipequality == 4 then
				_G["RBUI_Row"..i.."RecipeQuality"]:SetText("|c800080"..RB.BankValueTable[last].recipequality)
				elseif RB.BankValueTable[last].recipequality == 5 then
				_G["RBUI_Row"..i.."RecipeQuality"]:SetText("|cFFA500"..RB.BankValueTable[last].recipequality)
				else
				_G["RBUI_Row"..i.."RecipeQuality"]:SetText(RB.BankValueTable[last].recipequality)
				end
				
				
		  if (RB.BankValueTable[last].provisionerLevelReq~=0) then
				_G["RBUI_Row"..i.."StatValue"]:SetText(RB.BankValueTable[last].provisionerLevelReq)
			else
				_G["RBUI_Row"..i.."StatValue"]:SetText("-")
			end
			
		_G["RBUI_Row"..i.."SellPrice"]:SetText(RB.BankValueTable[last].qualityReq)

			--recipebookaddon
			_G["RBUI_Row"..i]:SetHandler("OnMouseUp", function(self,button) 
		    	if button==2 then 
					for z = 1, #RB.BankValueTable[self.id].ingredients do
						ZO_ChatWindowTextEntryEditBox:SetText(tostring(ZO_ChatWindowTextEntryEditBox:GetText()).."["..zo_strformat(SI_TOOLTIP_ITEM_NAME, RB.BankValueTable[self.id].ingredients[z].ingredient).."]")
					end
				elseif button==1 then
						ZO_ChatWindowTextEntryEditBox:SetText(tostring(ZO_ChatWindowTextEntryEditBox:GetText()).."["..zo_strformat(SI_TOOLTIP_ITEM_NAME, RB.BankValueTable[self.id].link).."]")
				end
				
	    	end)

			if last<=#RB.BankValueTable and last>1 then
	    		last=last-1
	    	else
	    		last=4
	    	end
		end
		

	end


end

function RB.PL_Opened()--debugging
	debug("Event PL_Opened fired")
end

function RB.PL_Closed()--debugging
	debug("Event PL_Closed fired")
end

function RB.GB_Opened()--debugging
	debug("Event GB_Opened fired")
end

function RB.GB_Ready()--debugging
	debug("Event GB_Ready fired")
	RB.gcount()
end

function RB.ShowIt()
	RB.CreateMenu()
	
for i=1,#RB.CharsName do
	CurCharName=GetUnitName("player")
	if RB.CharsName[i] == CurCharName then
		RB.PrepareBankValues("Invent",i)
	end
end

	RB.PrepIT()
	RBUI_Menu:SetHidden(false)
end

function RBcommandHandler( text )--handler for slash commands
	if text=="eb" then 
	
		--if (RBBEditBox ~= nil) then
			if RBEditBox:IsHidden() == true then
			RBEditBoxBg:SetHidden(false)
				RBEditBox:SetHidden(false)
			else
			RBEditBoxBg:SetHidden(true)
				RBEditBox:SetHidden(true)
			end
			
		--end
		
	else
		RB.DoBoot()
	end
end

function RB.DoBoot()
if RB.escCNT ~= 0 then
RB.escCNT = 0
return
end
	if not SCENE_MANAGER:IsInUIMode() then
        SCENE_MANAGER:SetInUIMode(true)
	end
		
	if (RBUI_Conatiner == nil) then
							
--tradeSkill5Name,tradeSkill5Rank = GetSkillLineInfo(SKILL_TYPE_TRADESKILL, 5)

	RB.params.hidden=false
	

	
		--set save UI postion handler
		RBUI_Container:SetHandler("OnMouseUp" , function(self) RB.MouseUp(self) end)
	
		--not needed lol
		RB.PreviousButtonClicked=RB.LastButtonClicked
		RB.LastButtonClicked="Invent"

		--set the list view to 4
    	RB.CurrentLastValue=4

		    for i=1,#RB.CharsName do
				CurCharName=GetUnitName("player")
				if RB.CharsName[i] == CurCharName then
					RB.PrepareBankValues("Invent",i)
					RB.FillBank(RB.CurrentLastValue)
					RB.HideContainer(false)
				end
			end
			
		if RBEditBox == nil then
			RB.CreateEditBox()
		end
		if (RBUI_Dropdown == nil) then
			RB.RB_DoCreateDropdown()
			RBUI_Dropdown:SetHidden(false)
		else
			RB.RB_DoCreateDropdown()
			if RB.escused == true then--if ESC was used to hide RB then...
					RB.escused = false--Reset
					RB.DoBoot()--Run doboot again
					return--Return after or we do an infinite call loop :)
			end
		end
	end
end

function RB.gcount()--global count for addon update
	RB.GCountOnUpdateTimer=GetGameTimeMilliseconds()
	RB.GCountOnUpdateReady=true
end

function RB.MouseUp(self) -- stores the loaction data of the UI
	local name = self:GetName()
    local left = self:GetLeft()
    local top = self:GetTop()

    if name=="RBUI_Menu" then
    	debug("Menu saved")
    	RB.params.RBUI_Menu={left,top}
    elseif name=="RBUI_Container" then
    	debug("Container saved")
    	RB.params.RBUI_Container={left,top}
    else
    	debug("Unknown window")
    end
end

function RB.SavePlayerInvent()--Called on Load/Close To Fill Backpack Data

	--Start grab item names and stack counts from BAG
	local bagIngredientCheckArray = {}
	
	bagIcon, bagSlots=GetBagInfo(BAG_BACKPACK)
	RB.BagItemCounter=0
	RB.AddedBagItemCounter=0
	while (RB.BagItemCounter < bagSlots) do
	
		if GetItemName(BAG_BACKPACK,RB.BagItemCounter)~="" then

		IngredientbagstackCount = GetSlotStackSize(BAG_BACKPACK,RB.BagItemCounter)
		IngredientNameForBackpack = GetItemName(BAG_BACKPACK, RB.BagItemCounter)
		
		bagIngredientCheckArray[#bagIngredientCheckArray+1]={
				
		["name"]= zo_strformat(SI_TOOLTIP_ITEM_NAME, IngredientNameForBackpack),
		["bagstackcount"]=IngredientbagstackCount
		}
			
			
			RB.AddedBagItemCounter=RB.AddedBagItemCounter+1
	
		end
		
		RB.BagItemCounter=RB.BagItemCounter+1

	end
	--End grab item names and stack counts from BAG
	
	
	--Start grab item names and stack counts from BANK
	local bankIngredientCheckArray = {}
	
	bankIcon,bankSlots=GetBagInfo(BAG_BANK)
	RB.BankItemCounter=0
	RB.AddedBankItemCounter=0
	while (RB.BankItemCounter < bankSlots) do
	
		if GetItemName(BAG_BANK,RB.BankItemCounter)~="" then

		IngredientbankstackCount = GetSlotStackSize(BAG_BANK,RB.BankItemCounter)
		IngredientNameForBank = GetItemName(BAG_BANK, RB.BankItemCounter)
		
		bankIngredientCheckArray[#bankIngredientCheckArray+1]={
				
		["name"]= zo_strformat(SI_TOOLTIP_ITEM_NAME, IngredientNameForBank),
		["bankstackcount"]=IngredientbankstackCount
		}
		
			RB.AddedBankItemCounter=RB.AddedBankItemCounter+1
		
		end
		RB.BankItemCounter=RB.BankItemCounter+1
	end
	--End grab item names and stack counts from BANK
	
	
	

	
	--reset items table
	RB.items.Chars[thisCharName]={}
	
	--get number of recipe lists in the game
	local lists = GetNumRecipeLists()
	--loop those lists
	for listIndex = 1, lists do
		local name, count = GetRecipeListInfo(i)
		for recipeIndex = 1, count do
			if GetRecipeInfo(listIndex, recipeIndex) then--determine if known recipe
			
			--grab the recipes info
			local recipenamefromGRRII,icontexture,stackcount,sellprice,recipequality = GetRecipeResultItemInfo(listIndex,recipeIndex)
			local recipelink = GetRecipeResultItemLink(listIndex, recipeIndex)
			local boolknown, recipename, ingredientCount, provisionerLevelReq, qualityReq = GetRecipeInfo(listIndex, recipeIndex)
			
			clearlink =string.gsub(recipelink, "|h.+|h", "|h"..tostring(recipename).."|h")
			
			
					if boolknown == true then --double check where on a known recipe lol
			
						local RecipeIngrendients={}--create ingredient array
					
						
						for ingredientIndex = 1, ingredientCount do --loop all the ingredients for this recipe
						
						--format the ingredientname
						RB.ingredientname = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetRecipeIngredientItemInfo(listIndex, recipeIndex, ingredientIndex))
						
						--counters
						RB.BagStackCountToAdd = 0
						RB.BankStackCountToAdd = 0
						
						
						for bagingredientcheckindex=1, RB.AddedBagItemCounter do--loop over bag items
							if RB.ingredientname == bagIngredientCheckArray[bagingredientcheckindex].name then--check if on same ingredient
								RB.BagStackCountToAdd = bagIngredientCheckArray[bagingredientcheckindex].bagstackcount --grab the stackcount of the ingredient
							end
						end
						
						for bankingredientcheckindex=1, RB.AddedBankItemCounter do--loop over bank items
							if RB.ingredientname == bankIngredientCheckArray[bankingredientcheckindex].name then--check if on same ingredient
								RB.BankStackCountToAdd = bankIngredientCheckArray[bankingredientcheckindex].bankstackcount--grab the stackcount of the ingredient
							end
						end
						
						
						
						--add ingredient info to recipe table
						RecipeIngrendients[#RecipeIngrendients+1]={
															
							["ingredient"]= GetRecipeIngredientItemLink(listIndex, recipeIndex, ingredientIndex,LINK_STYLE_DEFAULT),
							["ingredientname"]= zo_strformat(SI_TOOLTIP_ITEM_NAME, GetRecipeIngredientItemInfo(listIndex, recipeIndex, ingredientIndex)),
							["bagstackcount"]= RB.BagStackCountToAdd,
							["bankstackcount"]= RB.BankStackCountToAdd
							
						}
							
						end--ends ingredients loop
						
						local thisrecipeistracked = false
						if RB.TrackList ~= nil then
							for zz=1, #RB.TrackList do
								if RB.TrackList[zz].link == tostring(clearlink) and RB.TrackList[zz].tracked == true then	
									thisrecipeistracked = true
									break
								end
							end
						end
						
		local RBrecipetype = GetRecipeListInfo(listIndex)
		local RBrecipetypertnr = "false"
		if RBrecipetype == RB.SDDI then
			RBrecipetypertnr = "true"
		elseif RBrecipetype ~= RB.SDDI and RB.SDDI == "All" then
			RBrecipetypertnr = "true"
		else
			RBrecipetypertnr = "false"
		end
						
						
						
						local thisrecipenote = "BLANKNOTE"
						if (RB.NoteArray ~= nil) then
							for zzz=1, #RB.NoteArray do
								if RB.NoteArray[zzz].link == tostring(clearlink) and RB.NoteArray[zzz].recipenote ~= "BLANKNOTE" then	
									thisrecipenote = RB.NoteArray[zzz].recipenote
									break
								end
							end
						end
						
						
						
			--add to table
			RB.items.Chars[thisCharName][#RB.items.Chars[thisCharName]+1]={
				["link"]=tostring(clearlink),
				["icon"] = icontexture,
				["name"]=zo_strformat(SI_TOOLTIP_ITEM_NAME,recipename),
				["ingredientCount"]=ingredientCount,
				["StatValue"]=statValue,
				["provisionerLevelReq"] = provisionerLevelReq,
				["recipequality"]=recipequality,
				["qualityReq"] = qualityReq,
				["tracked"] = thisrecipeistracked,
				["charname"] = thisCharName,
				["charscount"] = CharsCount,
				["recipetype"] = RBrecipetype,
				["visible"] = RBrecipetypertnr,
				["recipenote"] = thisrecipenote,
				["ingredients"]=RecipeIngrendients
			}
			
					end--end bool known = true
				
				end--ends on known recipe
			
			end--ends all recipes
		
		end--end all recipes lists
	
	
	
	
	
	
end	--end function

function RB.UpdateBVT()

RB.SavePlayerInvent()

for i=1,#RB.CharsName do
	CurCharName=GetUnitName("player")
	if RB.CharsName[i] == CurCharName then
		RB.PrepareBankValues("Invent",i)
	end
end
			
RB.FillBank(4)
end

function RB.PrepIT()
			RB.trka ={}--create tmp array
			for i=1, #RB.BankValueTable do--loop the BVT
				RB.trk = ""--create a tmp string
				if RB.BankValueTable[i].tracked ~= false then--if where on a tracked ingredient
					for z=1, #RB.BankValueTable[i].ingredients do--loop the tracked recipes ingredients
						if z ~= #RB.BankValueTable[i].ingredients then
							RB.trk = zo_strformat(SI_TOOLTIP_ITEM_NAME,RB.trk..RB.BankValueTable[i].ingredients[z].ingredientname).."/"
						else
							RB.trk = zo_strformat(SI_TOOLTIP_ITEM_NAME, RB.trk..RB.BankValueTable[i].ingredients[z].ingredientname)
						end				
					end	
						--throw the new ingredients string into an array 
						RB.trka[#RB.trka+1]={
 						["list"]=RB.trk

 						}
					RB.trk = ""--reset r created string						
				end
			end--endtracklist
			
				if #RB.trka == 0 then--b4 we loop check if 0 then hide line1
					_G["RBUI_Menu_Recipe1"]:SetHidden(true)
				end
			
				for zzz = 1, #RB.trka do--loop the new ingredient array
				
					if zzz == 10 then
						_G["RBUI_Menu_Recipe"..zzz]:SetText(RB.trka[zzz].list)
						_G["RBUI_Menu_Recipe"..zzz]:SetHidden(false)

					end
					if zzz <= 9 then
						_G["RBUI_Menu_Recipe"..zzz]:SetText(RB.trka[zzz].list)
						_G["RBUI_Menu_Recipe"..zzz]:SetHidden(false)--unhide the lines we do have ingredients for
							for t=zzz+1,10 do--hide the lines we dont have ingredients for
								_G["RBUI_Menu_Recipe"..t]:SetHidden(true)
							end
					end
				end

				
 		--reset
		for k,v in pairs(RB.trka) do
			RB.trka[#RB.trka+1]=nil
		end
		
end--endfunction

RB.escCNT = 0
RB.escused = false
function RB.Update(self)--called on LOAD to initialize Blank ButtonUI, but only deals with loading Guild Bank
if (not RB.AddonReady) then return end

	local EscMenuHidden = ZO_GameMenu_InGame:IsHidden()
	local interactHidden = ZO_InteractWindow:IsHidden()

	if (EscMenuHidden == false) then
	RB.escCNT = RB.escCNT + 1
		RBUI_Container:SetHidden(true)
		if (RBUI_Dropdown ~= nil) then
			RBUI_Dropdown:SetHidden(true)
			if RB.escCNT >= 1 and not (RB.escCNT >= 3) then			
				RB.escused = true
				RB.DoBoot()
			end
		end
		--RBUI_Menu:SetHidden(true)
	elseif (interactHidden == false) then
		RBUI_Container:SetHidden(true)
		if (RBUI_Dropdown ~= nil) then
		 RBUI_Dropdown:SetHidden(true)
		end
		
	elseif (RB.params.hidden==false) then
	-- d("ran_parmas_F")
		-- if (RBUI_Dropdown ~= nil) then
			-- RBUI_Dropdown:SetHidden(false)
		-- end
	elseif (RB.params.hidden==true) then
	--	d("ran_parmas_T")
	--	if (RBUI_Dropdown ~= nil) then
	--		 RBUI_Dropdown:SetHidden(true4)
	--	end	 
	end

	--Hack to check inventory after X seconds after the first operation of the opening event
	if RB.GCountOnUpdateReady and (GetGameTimeMilliseconds()-RB.GCountOnUpdateTimer>=3000) then
		RB.GCountOnUpdateReady=false
				if (RB.BankValueTable ~= nil) then
					for z=1, #RB.BankValueTable do
						if RB.BankValueTable[z].recipenote ~= "BLANKNOTE" then
							if (RB.NoteArray == nil) then
								RB.NoteArray={}
							end
							table.insert(RB.NoteArray,	RB.BankValueTable[z])
						end
					end
				end
	end
	
end

function RB.HideContainer(value)
	debug("StartPrevious:"..tostring(RB.PreviousButtonClicked))
	debug("StartLast:"..tostring(RB.LastButtonClicked))
	if RB.PreviousButtonClicked==RB.LastButtonClicked then
		RBUI_Container:SetHidden(true)
		RB.PreviousButtonClicked=nil
		RB.LastButtonClicked=nil
	else
		RBUI_Container:SetHidden(false)
	end
	debug("FinishPrevious:"..tostring(RB.PreviousButtonClicked))
	debug("FinishLast:"..tostring(RB.LastButtonClicked))
end

function RB.RB_CreateDropdown(controlName, text, tooltip, Choices, getFunc, setFunc, owner, parent, defaulttxt)

    local dropdown = WINDOW_MANAGER:CreateControlFromVirtual("RBUI_Dropdown", RBUI_Container, "ZO_Options_Dropdown")
	dropdown:ClearAnchors()
    dropdown:SetAnchor(BOTTOM, RBUI_Container, BOTTOMCENTER, 0, 35)
    dropdown:SetDimensions(190, 50)
    dropdown.controlType = OPTIONS_DROPDOWN
    dropdown.system = SETTING_TYPE_UI
    dropdown.tooltipText = tooltip
    dropdown.valid = Choices
    local dropmenu = ZO_ComboBox_ObjectFromContainer(GetControl(dropdown, "Dropdown"))
    dropdown.dropmenu = dropmenu
    local setText = dropmenu.m_selectedItemText.SetText
    ZO_PreHookHandler(dropmenu.m_selectedItemText, "OnTextChanged", function(self)
            if dropmenu.m_selectedItemData then
                selectedName = dropmenu.m_selectedItemData.name
                setText(self, selectedName)
                --setFunc(selectedName)
				RB.loadingDD = false
				RB.SDDI = selectedName
				RB.DoDisplayFilter()
			else
			RB.loadingDD = true
			dropmenu:SetSelectedItem(defaulttxt)
			RB.SDDI = defaulttxt
			RB.DoDisplayFilter()
				
            end
        end)
    dropdown:SetHandler("OnShow", function()
			--dropmenu:SetSelectedItem(getFunc())
			if RB.SDDI == "" then
			dropmenu:SetSelectedItem(defaulttxt)
			RB.loadingDD = true
			RB.SDDI = defaulttxt
			RB.DoDisplayFilter()
			end
			
        end)

    local function OnItemSelect(_, choiceText, choice)--click functions here
	
	RB.loadingDD = false
        RB.SDDI = choiceText
		RB.DoDisplayFilter()
        PlaySound(SOUNDS.POSITIVE_CLICK)
    end
     
    for i=1,#Choices do  
        local entry = dropmenu:CreateItemEntry(Choices[i], OnItemSelect)  
        dropmenu:AddItem(entry) 
    end


    dropdown:SetHidden(false)
    dropdown:SetMouseEnabled(true)

    --deft
    dropmenu:SetSelectedItem(defaulttxt)
    return dropdown
end

function RB.RB_DoCreateDropdown()
		if(RBUI_Dropdown == nil) then
            local RecipeTypeList = RB.RB_GetList();
            RBUI_Dropdown = RB.RB_CreateDropdown(
                "RBUI_Dropdown",
                "Test", 
                "Select inventory to view",
                RecipeTypeList,
                RB.ShowIt,
                RB.ShowIt,
                "RBUI",
                "RBUI",
				"All"
            )
        else
            RBUI_Dropdown:SetHidden(false)
        end
end

function RB.RB_GetList()
    local RTList = { "All", "Bread and Pies", "Grilled", "Soup and Stew", "Beer", "Spirits", "Wine"}
    return RTList
end

function RB.DoDisplayFilter()
RB.DFShwncnt = 0
if RB.BankValueTable == nil then return end
	for i=1, #RB.BankValueTable do
		if RB.BankValueTable[i].recipetype == RB.SDDI then
			RB.DFShwncnt = RB.DFShwncnt + 1
			RB.BankValueTable[i].visible = "true"
		elseif RB.BankValueTable[i].recipetype ~= RB.SDDI and RB.SDDI == "All" then
			RB.DFShwncnt = RB.DFShwncnt + 1
			RB.BankValueTable[i].visible = "true"
		else
			RB.BankValueTable[i].visible = "false"
		end
	end
	if RB.loadingDD == true then
		RB.loadingDD = false
		RB.FillBank(4)
	elseif RB.loadingDD == false then
		RB.SFDF()
	end
end

function RB.SFDF()


	function compare(a,b)
		return a["visible"]>b["visible"]	
	end

	table.sort(RB.BankValueTable,compare)
	RB.FillBank(4)
end

function RB.CreateEditBox()

	

			local bg = CreateControlFromVirtual("RBEditBoxBg", RBUI_Container, "ZO_EditBackdrop")
			bg:SetParent(RBUI_Container)
			bg:SetDimensions(300,23)
			bg:ClearAnchors()
			bg:SetAnchor(BOTTOM, RBUI_Container, BOTTOMLEFT, 200, 15)
			
			RBEditBox = CreateControlFromVirtual("RBEditBox", bg, "ZO_DefaultEditForBackdrop")
			RBEditBox:SetParent(bg)	
			RBEditBox:SetDimensions(300,23)
			RBEditBox:SetMouseEnabled(true)
			RBEditBox:SetText("Enter Note Eg : Jazbay Brew/Tasty") 
			RBEditBox:SetHandler("OnEnter", function(self)
			
			
			if RBEditBox:GetText() ~= "Enter Note Eg : Jazbay Brew/Tasty" and RBEditBox:GetText() ~= "" then
				local RBTerms = RBEditBox:GetText()
				RB.RBEBMatches = split(RBTerms, "\/")
				local RBdowrite = false
				local RBnotsupported = false
				
				for i=1, #RB.RBEBMatches do
				
					for z=1, #RB.BankValueTable do
					
							if string.lower(RB.RBEBMatches[1]) == string.lower(RB.BankValueTable[z].name) then								
								RBdowrite = true
								RB.BankValueTable[z].recipenote = RB.RBEBMatches[2]
								if (RB.NoteArray == nil) then
									RB.NoteArray={}
								end
								if (string.find(string.lower(RB.BankValueTable[z].name), "shien") ~= nil) then
								RBnotsupported = true
								end
								table.insert(RB.NoteArray,	RB.BankValueTable[z])
							end
							
					end
					
				end
				
				if RBdowrite == true then
					d("***RecipeBook***")
					
					if RBnotsupported == true then
					RBnotsupported = false
					d("Recipes With The Term Shien Are Not Currently Supported!")
					else
					d("Note Set!")
					end
					RB.FillBank(4)
				else
					d("***RecipeBook***")
					d("Error Setting "..RB.RBEBMatches[1].." Recipe Note! Check Spelling.")
				end
				
			end
			
			
			
			

			RBEditBox:LoseFocus() 
			
		 end)
			-- RBEditBox:SetHandler("OnMouseDown", function(self)
			
				-- RBEditBox:TakeFocus()
			-- if RBEditBox:GetText() == "Enter Note Eg : Jazbay Brew/Tasty" then
				-- RBEditBox:SetText("") 
			-- end
			 
			
		 -- end)
		
RBEditBoxBg:SetHidden(false)
RBEditBox:SetHidden(false)
end

function split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end


function RBBuildLAMSettingsMenu()
	
    local LAM = LibStub:GetLibrary("LibAddonMenu-1.0")
    local panelId = LAM:CreateControlPanel("RecipeBookControlPanel", "RecipeBook")
    LAM:AddHeader(panelId,"RecipeBookControlPanelHeader", RB.version.." By ahostbr")

    LAM:AddCheckbox(panelId,
        "RecipeBookTooltipCheckbox",
        "Show Tooltips In Loot/Bank/Bag ?",
        nil,
        function() return RB.items.SaveVars.tooltips end,
        function()
		
			if RB.items.SaveVars.tooltips == true then
			
				RB.items.SaveVars.tooltips = false
			else
				
				RB.items.SaveVars.tooltips = true
			end
			
        end)
		
	LAM:AddCheckbox(panelId,
        "RecipeBookMulticharCheckbox",
        "Show Mult-Char Known Recipes In Tooltips In Loot/Bank/Bag ?",
        "Show Mult-Char Known Recipes In Tooltips In Loot/Bank/Bag ?",
        function() return RB.items.SaveVars.multichar end,
        function()
		
			if RB.items.SaveVars.multichar == true then
			
				RB.items.SaveVars.multichar = false
			else
				
				RB.items.SaveVars.multichar = true
			end
			
        end)	
		
	LAM:AddColorPicker(panelId,
	"RB_IngredientColorPicker",
	"Ingredient Color",
	"Change the Ingredients Color",
	function() return 	RB.items.SaveVars.ingredientcolor.r, RB.items.SaveVars.ingredientcolor.g, RB.items.SaveVars.ingredientcolor.b, RB.items.SaveVars.ingredientcolor.a end,
        function(r,g,b,a)
		
			RB.items.SaveVars.ingredientcolor.r = r
			RB.items.SaveVars.ingredientcolor.g = g 
			RB.items.SaveVars.ingredientcolor.b = b
			RB.items.SaveVars.ingredientcolor.a = a
			RB.IngredientColorPickerClicked = true
			RB.FillBank(4)
			
        end)
			RB.ingredientfonts = {"ZoFontBookLetter",
						"ZoFontBookRubbing",
						"ZoFontBookSkin",
						"ZoFontBookPaper"
			}
			RB.RecipesNameFonts = {"ZoFontBookPaperTitle",
			"ZoFontBookLetter",
			"ZoFontBookRubbing",
			"ZoFontBookScroll",
			"ZoFontBookSkin",
			"ZoFontBookPaper"		
			}					
	LAM:AddDropdown(panelId,
	"RB_IngredientFontDropDown",
	"Ingredients Font",
	"Set the font for ingredients",
	RB.ingredientfonts,
	function() return RB.items.SaveVars.chooseningredientfont.f end,
		function(newFont)
		
		RB.items.SaveVars.chooseningredientfont.f = newFont
		
		RB.FillBank(4)
		end)
		
	LAM:AddDropdown(panelId,
	"RB_RecipeNameFontDropDown",
	"RecipeName Font",
	"Set the font for the recipes name",
	RB.RecipesNameFonts,
	function() return RB.items.SaveVars.choosenrecipenamefont.f end,
		function(newFont)
		
		RB.items.SaveVars.choosenrecipenamefont.f = newFont
		
		RB.FillBank(4)
		end)
end


RBEventHandlers.RecipeQualitySort = DoRecipeQualitySort
--tooltips recipe learned
EVENT_MANAGER:RegisterForEvent("RBToolTipArrayRecipeLearned", EVENT_RECIPE_LEARNED, RBToolTipArray_RecipeLearned)
--recipe learned
EVENT_MANAGER:RegisterForEvent("RecipeBookNewRecipeLearned", EVENT_RECIPE_LEARNED, RB.UpdateBVT)
--Crafting Events
EVENT_MANAGER:RegisterForEvent("RBCraftStatStart", EVENT_CRAFTING_STATION_INTERACT, RB.UpdateBVT)
EVENT_MANAGER:RegisterForEvent("RBCraftStatEnd", EVENT_END_CRAFTING_STATION_INTERACT, RB.UpdateBVT)  
EVENT_MANAGER:RegisterForEvent("RBCraftStart", EVENT_CRAFT_STARTED, RB.UpdateBVT)
EVENT_MANAGER:RegisterForEvent("RBCraftEnd", EVENT_CRAFT_COMPLETED, RB.UpdateBVT)
--Event Loot Updated
EVENT_MANAGER:RegisterForEvent("RecipeBookLootRecieved", EVENT_LOOT_RECEIVED, RB.UpdateBVT)
--Event Item Destroyed
EVENT_MANAGER:RegisterForEvent("RBItemDestoryed", EVENT_INVENTORY_ITEM_DESTROYED, RB.UpdateBVT)
--Event TradeSucceded
EVENT_MANAGER:RegisterForEvent("RBTradeSucceded", EVENT_TRADE_SUCCEEDED, RB.UpdateBVT)
--Addon initialization
EVENT_MANAGER:RegisterForEvent("RecipeBook", EVENT_ADD_ON_LOADED, RB.OnLoad)