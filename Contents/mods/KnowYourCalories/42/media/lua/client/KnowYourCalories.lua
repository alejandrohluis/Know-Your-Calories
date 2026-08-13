--   ********************
--   * KnowYourCalories *
--   ********************
-- + Developer: Dios Pato
-- + Date of Creation: 17/05/2024
-- **********************************

require ('XpSystem/ISUI/ISCharacterScreen')
-------------------------------------------------------------------------------
local lcl = {}

-- drawText(text, positionX, positionY, r ,g ,b , alpha, font)
lcl.getText           = getText
lcl.getTexture        = getTexture
lcl.cookingPerk       = Perks.Cooking
lcl.nutritionist1     = CharacterTrait.NUTRITIONIST
lcl.nutritionist2     = CharacterTrait.NUTRITIONIST2
-------------------------------------------------------------------------------

-------- Shared variables and functions --------
local rounding = 0
local textManager = getTextManager()
local needNutritionist = false
local sandboxCaloriesLevel = 10
local sandboxProteinsLevel = 10
local sandboxOthersLevel = 10
local isBarDescriptionEnabled = false
local small_font = UIFont.Small
local backgroundDisabled = false

local function toStringNutrientValue(nutrientValue)
    return string.format(round(nutrientValue, rounding))
end

local function setupLocalVars()
    rounding = -SandboxVars.KnowYourCalories.Rounding + 1
    textManager = getTextManager()
    needNutritionist = SandboxVars.KnowYourCalories.NeedNutritionist
    sandboxCaloriesLevel = SandboxVars.KnowYourCalories.NeedCookingLevelForCalories
    sandboxProteinsLevel = SandboxVars.KnowYourCalories.NeedCookingLevelForProteins
    sandboxOthersLevel = SandboxVars.KnowYourCalories.NeedCookingLevelForOthers
    isBarDescriptionEnabled = SandboxVars.KnowYourCalories.ProgressBarDescription
    -- disables background for a better design compatibility with the mod Neat Rocco's UI
    -- might improve it later since the quantity option look weird floating 
    if NR_CharInfoPanel ~= nil then
        backgroundDisabled = true
    end
end

local nutritionTypes = {
    CALORIE = 0,
    PROTEIN = 1,
    CARBS = 2,
    LIPIDS = 3
}

local nutrientNames = {
    [nutritionTypes.CALORIE] = "UI_Calories",
    [nutritionTypes.PROTEIN] = "UI_Proteins",
    [nutritionTypes.CARBS]   = "UI_Carbohydrates",
    [nutritionTypes.LIPIDS]  = "UI_Lipids",
}

local nutritionValueGetters = {
    [nutritionTypes.CALORIE] = function(playerNutrition) return playerNutrition:getCalories() end,
    [nutritionTypes.PROTEIN] = function(playerNutrition) return playerNutrition:getProteins() end,
    [nutritionTypes.CARBS]   = function(playerNutrition) return playerNutrition:getCarbohydrates() end,
    [nutritionTypes.LIPIDS]  = function(playerNutrition) return playerNutrition:getLipids() end,
}

-------------------------------------------------------------------------------
ISNutritionDisplayPanel = ISPanel:derive("IS_KYC_NutritionDisplayPanel")


function ISNutritionDisplayPanel:new(width, height, player)
    local o = {}
    o = ISPanel:new(0, 0, width, height)
    setmetatable(o, self)
    self.__index = self

    if backgroundDisabled then
        o:noBackground()
    end
	o.anchorBottom = true
	o.anchorRight = true
	o.anchorTop = false
    o.anchorLeft = false
    o.player = player
    o.hasNutritionist = false
    o.updatePerk = function() o:perkUpdate() end
    o.updateTrait = function() o:traitUpdate() end
    return o
end

function ISNutritionDisplayPanel:addEvents()
    Events.LevelPerk.Add(self.updatePerk)
    Events.OnPlayerUpdate.Add(self.updateTrait)
end

function ISNutritionDisplayPanel:removeEvents()
    Events.LevelPerk.Remove(self.updatePerk)
    Events.OnPlayerUpdate.Remove(self.updateTrait)
end

function ISNutritionDisplayPanel:close()
    self:removeEvents()
    ISPanel.close(self)
end

function ISNutritionDisplayPanel:updateInfo()
    if not self.player then
        return
    end
    local isNutritionist = needNutritionist and self.hasNutritionist
    local nutrientsUnlocked = 0
    self.caloriesInfo:hide()
    self.proteinsInfo:hide()
    self.lipidsInfo:hide()
    self.carbohydratesInfo:hide()
    if isNutritionist or self.cookingLevel >= sandboxCaloriesLevel then
        self.caloriesInfo:show(nutrientsUnlocked)
        nutrientsUnlocked = nutrientsUnlocked + 1
    end
    if isNutritionist or self.cookingLevel >= sandboxProteinsLevel then
        self.proteinsInfo:show(nutrientsUnlocked)
        nutrientsUnlocked = nutrientsUnlocked + 1
    end
    if isNutritionist or self.cookingLevel >= sandboxOthersLevel then
        self.lipidsInfo:show(nutrientsUnlocked)
        nutrientsUnlocked = nutrientsUnlocked + 1

        self.carbohydratesInfo:show(nutrientsUnlocked)
        nutrientsUnlocked = nutrientsUnlocked + 1
    end

    local anyNutrientUnlocked = nutrientsUnlocked > 0
    self:setVisible(anyNutrientUnlocked)
end

function ISNutritionDisplayPanel:perkUpdate()
    if not self.player then return end

    -- only runs the heavy updateInfo function if the last state changed
    self.previousCookingLevel = self.player:getPerkLevel(lcl.cookingPerk)
    if self.previousCookingLevel ~= self.cookingLevel then
        self.cookingLevel = self.previousCookingLevel
        self:updateInfo()
    end
end

function ISNutritionDisplayPanel:traitUpdate()
    if not self.player then return end

    -- only runs the heavy updateInfo function if the last state changed
    self.lastNutritionistState = self.player:hasTrait(lcl.nutritionist1) or self.player:hasTrait(lcl.nutritionist2)
    if self.lastNutritionistState ~= self.hasNutritionist then
        self.hasNutritionist = self.lastNutritionistState
        self:updateInfo()
    end
end

function ISNutritionDisplayPanel:updatePosition()
    if not self.parent then return end
    self:setX(self.parent:getWidth() - self:getWidth())
    self:setY(self.parent:getHeight() - self:getHeight())
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------

-------- QUANTITY -------- DISPLAY NUTRIENT QUANTITY PANEL --------
ISNutritionQuantityPanel = ISNutritionDisplayPanel:derive("IS_KYC_NutritionQuantityPanel")

function ISNutritionQuantityPanel:new(player)
    local o = {}
    local spacing = 5
    self.nutrientNameMaxWidth = math.max(
        textManager:MeasureStringX(small_font, lcl.getText("UI_Calories")),
        textManager:MeasureStringX(small_font, lcl.getText("UI_Proteins")),
        textManager:MeasureStringX(small_font, lcl.getText("UI_Lipids")),
        textManager:MeasureStringX(small_font, lcl.getText("UI_Carbohydrates"))
    )
    local panelWidth = self.nutrientNameMaxWidth + 50
    local amountOfNutrients = 4
    local panelHeight = textManager:getFontHeight(small_font) * (amountOfNutrients - 1) + amountOfNutrients * spacing

    o = ISNutritionDisplayPanel:new(panelWidth, panelHeight, player)
    setmetatable(o,self)
    self.__index = self
    return o
end

function ISNutritionQuantityPanel:createChildren()
    self.caloriesInfo = ISNutritionQuantity:new(nutritionTypes.CALORIE, self.player, self.nutrientNameMaxWidth)
	self.caloriesInfo:initialise()
    self:addChild(self.caloriesInfo)

    self.proteinsInfo = ISNutritionQuantity:new(nutritionTypes.PROTEIN, self.player, self.nutrientNameMaxWidth)
	self.proteinsInfo:initialise()
    self:addChild(self.proteinsInfo)

    self.carbohydratesInfo = ISNutritionQuantity:new(nutritionTypes.CARBS, self.player, self.nutrientNameMaxWidth)
	self.carbohydratesInfo:initialise()
    self:addChild(self.carbohydratesInfo)

    self.lipidsInfo = ISNutritionQuantity:new(nutritionTypes.LIPIDS, self.player, self.nutrientNameMaxWidth)
	self.lipidsInfo:initialise()
    self:addChild(self.lipidsInfo)

    self:traitUpdate()
    self:perkUpdate()
end

-------- QUANTITY -------- DISPLAY ONE NUTRIENT QUANTITY --------
ISNutritionQuantity = ISPanel:derive("IS_KYC_NutritionQuantity")

function ISNutritionQuantity:new(nutritionType, player, nutrientMaxWidth)
    local o = {}
    local width = nutrientMaxWidth + 40
    o = ISPanel:new(5, 5, width, textManager:getFontHeight(small_font))
    setmetatable(o, self)
    self.__index = self

    o:noBackground()
    o.player = player
    o.nutrientMaxWidth = nutrientMaxWidth
    o.nutritionType = nutritionType
    o.nutrientName = lcl.getText(nutrientNames[nutritionType])
    o.nutrientUpdate = function() o:updateNutrients() end
    return o
end

function ISNutritionQuantity:initialise()
    ISPanel.initialise(self)
    self:updateNutrients()

    self.nameWidth = textManager:MeasureStringX(small_font, self.nutrientName)
    self:hide()
end

function ISNutritionQuantity:updateNutrients()
    local nutrition = self.player:getNutrition()
    self.nutrientQuantity = nutritionValueGetters[self.nutritionType](nutrition)
end

function ISNutritionQuantity:render()
    self:drawTextRight(self.nutrientName, self.nutrientMaxWidth, 0, 1, 1, 1, 1, small_font)
    self:drawText(toStringNutrientValue(self.nutrientQuantity), self.nutrientMaxWidth + 10, 0, 1, 1, 1, 0.5, small_font)
end

function ISNutritionQuantity:updatePosition(index)
    self:setY(index * self:getHeight())
end

function ISNutritionQuantity:addEvents()
    Events.OnPlayerUpdate.Add(self.nutrientUpdate)
end

function ISNutritionQuantity:removeEvents()
    Events.OnPlayerUpdate.Remove(self.nutrientUpdate)
end

function ISNutritionQuantity:hide()
    if self:getIsVisible() then
        self:removeEvents()
        self:setVisible(false)
    end
end

function ISNutritionQuantity:show(index)
    self:updatePosition(index)
    if not self:getIsVisible() then
        self:addEvents()
        self:setVisible(true)
    end
end

--------   BAR   -------- NUTRITION BAR DESCRIPTION  --------
ISNutritionBarDescription = ISPanel:derive("IS_KYC_NutritionBarDescription")

function ISNutritionBarDescription:new()
    local o = {}
    o = ISPanel:new(0,0,20,20)
    setmetatable(o,self)
    self.__index = self

    -- o.nutrientText = lcl.getText("UI_"..nutritionType)
    o.nutrientName = ""
    return o
end

function ISNutritionBarDescription:initialise()
    ISPanel.initialise(self)
    self:updateText()
end

function ISNutritionBarDescription:updateText()
    self.textWidth = textManager:MeasureStringX(small_font, self.nutrientName)
    self.textHeight = textManager:getFontHeight(small_font)
    self.nameHeight = math.floor(self.textHeight / 4.5)
    if isBarDescriptionEnabled then
        self.amountHeight = self.textHeight
        self.textHeight = math.floor(self.nameHeight * 3) + self.amountHeight
    end
    self:setWidth(self.textWidth + 10)
    self:setHeight(self.textHeight + 10)
end

function ISNutritionBarDescription:showFor(x, y, bar)
    self.barHovered = bar
    self.nutrientName = lcl.getText(nutrientNames[bar.nutritionType])
    self:updateText()
    self:setX(x - self:getWidth())
    self:setY(y - self:getHeight())
    self:show()
end

function ISNutritionBarDescription:show()
    if not self:getIsVisible() then
        self:setVisible(true)
    end
end

function ISNutritionBarDescription:hide()
    if self:getIsVisible() then
        self:setVisible(false)
    end
end

function ISNutritionBarDescription:render()
    -- name
    self:drawText(self.nutrientName, 5, self.nameHeight, 1, 1, 1, 1, small_font)
    -- description
    if isBarDescriptionEnabled then
        local nutrientAmount = toStringNutrientValue(self.barHovered.nutrientValue)
        self:drawText(nutrientAmount, 5, self.amountHeight, 1, 1, 1, 0.5, small_font)
    end
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------

--------   BAR   -------- NUTRITION BARS  --------
ISNutritionBar = ISPanel:derive("IS_KYC_NutritionBar")

function ISNutritionBar:new(nutritionType, player)
    local o = {}
    o = ISPanel:new(5,5,10,100)
    setmetatable(o,self)
    self.__index = self

    o:noBackground()
    o.player = player
    o.nutritionType = nutritionType
    o.nutrientUpdate = function() o:updateNutrients() end
    return o
end

function ISNutritionBar:initialise()
    ISPanel.initialise(self)
    self:updateNutrients()
    self:setTextures()
    self:hide()
end

function ISNutritionBar:addEvents()
    Events.OnPlayerUpdate.Add(self.nutrientUpdate)
end

function ISNutritionBar:removeEvents()
    Events.OnPlayerUpdate.Remove(self.nutrientUpdate)
end

local function getNutrientPercentage(nutrientType, nutrientAmount)
    -- formula:
    --        ( nutrientAmount + average(nutrientMin,nutrientMax) )
    -- 100 * -------------------------------------------------------
    --              sum(nutrientMin, nutrientMax)

    -- values are already simplified to avoid unnecessary calculations
    if nutrientType == nutritionTypes.CALORIE then
        return (nutrientAmount + 2200) / 59.0
    end
    return (nutrientAmount+500)/15.0
end

function ISNutritionBar:updateNutrients()
    local nutrition = self.player:getNutrition()
    self.nutrientValue = nutritionValueGetters[self.nutritionType](nutrition)
    self.nutrientPercentage = getNutrientPercentage(self.nutritionType, self.nutrientValue)
end

function ISNutritionBar:setTextures()
    self.backgroundTexture = lcl.getTexture("media/textures/background.png")
    self.nutrientTexture = lcl.getTexture("media/textures/nutrients.png")
    local nutritionColorError = {1,1,1,1}
    local nutritionColors = {
        [nutritionTypes.CALORIE] = {0.6 , 0.9  , 1    , 0.2  },
        [nutritionTypes.PROTEIN] = {0.6 , 1    , 0.42 , 0.33 },
        [nutritionTypes.CARBS]   = {0.6 , 0.55 , 1    , 0.68 },
        [nutritionTypes.LIPIDS]  = {0.6 , 1    , 0.94 , 0.7  },
    }
    self.nutrientColors = nutritionColors[self.nutritionType] or nutritionColorError
end

function ISNutritionBar:updatePosition(index)
    local margin = 5
    local spacingBarWidth = index * 10
    local spaceBetweenEachBar = 5 * index
    self:setX(margin + spacingBarWidth + spaceBetweenEachBar)
end

function ISNutritionBar:hide()
    if self:getIsVisible() then
        self:removeEvents()
        self:setVisible(false)
    end
end

function ISNutritionBar:show(index)
    self:updatePosition(index)
    if not self:getIsVisible() then
        self:addEvents()
        self:setVisible(true)
    end
end

function ISNutritionBar:render()
    self:drawTexture(self.backgroundTexture, 0, 0, 0.8, 1, 1, 1)
    local argb = self.nutrientColors
    self:drawTextureScaled(
        self.nutrientTexture, 0, 0, 10, self.nutrientPercentage,
        argb[1], argb[2], argb[3], argb[4]
    )

    if self:isMouseOver() then
        self.parent:showBarDescription(self)
    elseif self.parent.descriptionBox.barHovered == self then
        self.parent:hideBarDescription()
    end
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------

--------   BAR   -------- NUTRITION BAR PANEL  --------
ISNutritionBarsPanel = ISNutritionDisplayPanel:derive("IS_KYC_NutritionBarsPanel")

function ISNutritionBarsPanel:new(player)
    local o = {}
    local spacing = 5
    local amountOfBars = 4
    local barWidth = 10
    local panelWidth = amountOfBars * barWidth + (amountOfBars + 1) * spacing
    local barHeight = 100
    local panelHeight = barHeight + 2 * spacing

    o = ISNutritionDisplayPanel:new(panelWidth, panelHeight, player)
    setmetatable(o, self)
    self.__index = self
    return o
end

function ISNutritionBarsPanel:showBarDescription(bar)
    -- local spacing = 5
    local x = self:getX() + self:getWidth()
    local y = self:getY()
    self.descriptionBox:showFor(x, y, bar)
end

function ISNutritionBarsPanel:hideBarDescription()
    self.descriptionBox:hide()
end

function ISNutritionBarsPanel:createChildren()
    self.caloriesInfo = ISNutritionBar:new(nutritionTypes.CALORIE, self.player)
	self.caloriesInfo:initialise()
    self:addChild(self.caloriesInfo)

    self.proteinsInfo = ISNutritionBar:new(nutritionTypes.PROTEIN, self.player)
	self.proteinsInfo:initialise()
    self:addChild(self.proteinsInfo)

    self.carbohydratesInfo = ISNutritionBar:new(nutritionTypes.CARBS, self.player)
	self.carbohydratesInfo:initialise()
    self:addChild(self.carbohydratesInfo)

    self.lipidsInfo = ISNutritionBar:new(nutritionTypes.LIPIDS, self.player)
	self.lipidsInfo:initialise()
    self:addChild(self.lipidsInfo)

    self:traitUpdate()
    self:perkUpdate()
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------

-------- SETUP  --------

local function kycSetup(classHooked, originalCreateChildren)
    setupLocalVars()

    local PanelStyle = (SandboxVars.KnowYourCalories.UseProgressBar and ISNutritionBarsPanel) or ISNutritionQuantityPanel
    
    originalCreateChildren(classHooked)

    local nutritionPanel = PanelStyle:new(classHooked.charScreen.char)
    nutritionPanel:initialise()
    classHooked.charScreen:addChild(nutritionPanel)
    nutritionPanel:addEvents()
    nutritionPanel:updateInfo()
    nutritionPanel:updatePosition()

    if SandboxVars.KnowYourCalories.UseProgressBar then
        local nutritionDescriptionBox = ISNutritionBarDescription:new()
        nutritionDescriptionBox:initialise()
        classHooked.charScreen:addChild(nutritionDescriptionBox)
        nutritionDescriptionBox:hide()
        nutritionPanel.descriptionBox = nutritionDescriptionBox
    end
end

local originalCreateChildren = ISCharacterInfoWindow.createChildren
function ISCharacterInfoWindow:createChildren()
    kycSetup(self, originalCreateChildren)
end

-------------------------------------------------------------------------------