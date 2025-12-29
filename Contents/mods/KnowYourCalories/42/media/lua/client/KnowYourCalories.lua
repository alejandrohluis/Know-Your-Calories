--   ********************
--   * KnowYourCalories *
--   ********************
-- + Developer: Dios Pato
-- + Date of Creation: 17/05/2024
-- + Date of Modification: 26/11/2025
-- **********************************

require ('XpSystem/ISUI/ISCharacterScreen')
-------------------------------------------------------------------------------
local lcl = {}

lcl.player_base       = __classmetatables[IsoPlayer.class].__index
lcl.player_character  = __classmetatables[IsoGameCharacter.class].__index

lcl.tm_base           = __classmetatables[TextManager.class].__index
lcl.tm_MeasureStringX = lcl.tm_base.MeasureStringX

lcl.getPlayer         = getPlayer
lcl.getText           = getText
lcl.getTexture        = getTexture
lcl.drawRect          = drawRect
-- drawText(text, positionX, positionY, r ,g ,b , alpha, font)
-- drawRect(positionX, positionY, width, height, alpha, r, g, b)
-------------------------------------------------------------------------------

-------- Shared variables and functions --------

local KnowYourCalories_IsSetup = false

local rounding = 0
local textManager = getTextManager()
local needNutritionist = false
local sandboxCaloriesLevel = 10
local sandboxProteinsLevel = 10
local sandboxOthersLevel = 10
local lowestCookingLevelNeeded = 10
local isBarDescriptionEnabled = false
local small_font = UIFont.Small

local nutritionX = 0
local nutritionZ = 0
local windowHeight = 0
local spacing = 0

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
    lowestCookingLevelNeeded = math.min(sandboxCaloriesLevel, (math.min(sandboxProteinsLevel, sandboxOthersLevel) ) )
    if SandboxVars.KnowYourCalories.UseProgressBar then
        isBarDescriptionEnabled = SandboxVars.KnowYourCalories.ProgressBarDescription
        spacing = 15
    else
        spacing = textManager:getFontHeight(small_font) + 6
    end
end

-------------------------------------------------------------------------------

-------- Display Nutrient Numbers --------

function ISCharacterScreen:render_KYC_drawNutrientNumber(nutrientType, nutrientValue)
    local nutrientText = "UI_"..nutrientType
    local nutrientAmount = toStringNutrientValue(nutrientValue)

    self:drawTextRight(lcl.getText(nutrientText), nutritionX, nutritionZ, 1, 1, 1, 1, small_font)
    self:drawText(nutrientAmount, nutritionX + 10, nutritionZ, 1, 1, 1, 0.5, small_font)
    windowHeight = windowHeight + spacing
    nutritionZ = windowHeight - 10
end

function ISCharacterScreen:render_KYC_DisplayNutrientNumbers()
    local player = self.char or lcl.getPlayer()
    local cookingLevel = player:getPerkLevel(Perks.Cooking)
    local isNutritionist = needNutritionist and (player:HasTrait(CharacterTrait.NUTRITIONIST) or player:HasTrait(CharacterTrait.NUTRITIONIST2))
    if isNutritionist or cookingLevel > lowestCookingLevelNeeded then
        -- this measures and compares 3 different texts, then uses the longest one, 
        -- ensuring that it is well positioned with all languages supported by the mod
        local textWidth1 = lcl.tm_MeasureStringX(textManager, small_font, lcl.getText("IGUI_char_Favourite_Weapon"))
        local textWidth2 = lcl.tm_MeasureStringX(textManager, small_font, lcl.getText("IGUI_char_Zombies_Killed"))
        local textWidth3 = lcl.tm_MeasureStringX(textManager, small_font, lcl.getText("IGUI_char_Survived_For"))
        nutritionX = 20 + math.max(textWidth1,math.max(textWidth2,textWidth3))

        windowHeight = self.height

        local clock = UIManager.getClock()
        if not (instanceof(self.char, 'IsoPlayer') and clock and clock:isDateVisible()) then
            windowHeight = windowHeight - spacing
        end
        nutritionZ = windowHeight - 10
        if isNutritionist or cookingLevel > sandboxCaloriesLevel then
            local calories = player:getNutrition():getCalories()
            self:render_KYC_drawNutrientNumber("Calories", calories)
        end
        if isNutritionist or cookingLevel > sandboxProteinsLevel then
            local proteins = player:getNutrition():getProteins()
            self:render_KYC_drawNutrientNumber("Proteins", proteins)
        end
        if isNutritionist or cookingLevel > sandboxOthersLevel then
            local fats = player:getNutrition():getLipids()
            self:render_KYC_drawNutrientNumber("Lipids", fats)
            local carbs = player:getNutrition():getCarbohydrates()
            self:render_KYC_drawNutrientNumber("Carbohydrates", carbs)
        end
        self:setHeightAndParentHeight(windowHeight)
    end
end

-------------------------------------------------------------------------------

-------- Display Nutrient Bars --------

function ISCharacterScreen:render_KYC_NutrientBarName(nutrientType, nutrientValue)
    local mouseX = self:getMouseX()
    local mouseY = self:getMouseY()
    -- checking for OR is faster or equal than checking for AND
    if not ((mouseX < nutritionX or mouseX > nutritionX + 10) or (mouseY < nutritionZ or mouseY > nutritionZ + 100)) then
        local nutrientText = lcl.getText("UI_"..nutrientType)
        local nameWidth = textManager:MeasureStringX(small_font, nutrientText)
        local nameHeight = textManager:getFontHeight(small_font) * 2.25
        if not isBarDescriptionEnabled then nameHeight = nameHeight / 2.25 end
        local boxPositionX = self.width - nameWidth - 15
        local boxPositionZ = self.height - 110 - nameHeight
        -- background border
        self:drawRect(boxPositionX, boxPositionZ, nameWidth + 10, nameHeight, 1.0, 0.4, 0.4, 0.4)
        -- background
        self:drawRect(boxPositionX + 1, boxPositionZ + 1, nameWidth + 8, nameHeight - 2, 0.8, 0.0, 0.0, 0.0)
        -- text
        self:drawText(nutrientText, boxPositionX + 5, boxPositionZ, 1, 1, 1, 1, small_font)
        if isBarDescriptionEnabled then
            nameHeight = nameHeight / 2.25
            local nutrientAmount = toStringNutrientValue(nutrientValue)
            -- description
            self:drawText(nutrientAmount, boxPositionX + 5, boxPositionZ + nameHeight, 1, 1, 1, 0.5, small_font)
        end
    end
end

local function getNutrientPercentage(nutrientType, nutrientAmount)
    -- formula:
    --        ( nutrientAmount + average(nutrientMin,nutrientMax) )
    -- 100 * -------------------------------------------------------
    --              sum(nutrientMin, nutrientMax)

    -- values are already simplified to avoid unnecessary calculations
    if nutrientType == "Calories" then
        return (nutrientAmount + 2200) / 59.0
    end
    return (nutrientAmount+500)/15.0
end

function ISCharacterScreen:render_KYC_drawNutrientBar(nutrientType, nutrientValue, backgroundTexture, nutrientsTexture, argb)
    local nutrientPercentage = getNutrientPercentage(nutrientType, nutrientValue)
    self:drawTexture(backgroundTexture, nutritionX, nutritionZ, 0.8, 1, 1, 1)
    self:drawTextureScaled(nutrientsTexture, nutritionX, nutritionZ, 10, nutrientPercentage, argb[1], argb[2], argb[3], argb[4])
    self:render_KYC_NutrientBarName(nutrientType, nutrientValue)
    nutritionX = nutritionX - spacing
end

function ISCharacterScreen:render_KYC_DisplayNutrientBars()
    local player = self.char or lcl.getPlayer()
    local cookingLevel = player:getPerkLevel(Perks.Cooking)
    local isNutritionist = needNutritionist and (player:hasTrait(CharacterTrait.NUTRITIONIST) or player:hasTrait(CharacterTrait.NUTRITIONIST2))
    if isNutritionist or cookingLevel > lowestCookingLevelNeeded then
        nutritionX = self.width - spacing
        nutritionZ = self.height - 105
        local backgroundTexture = lcl.getTexture("media/textures/background.png")
        local nutrientsTexture = lcl.getTexture("media/textures/nutrients.png")
        if isNutritionist or cookingLevel > sandboxOthersLevel then
            local lipids = player:getNutrition():getLipids()
            self:render_KYC_drawNutrientBar("Lipids", lipids, backgroundTexture, nutrientsTexture, {0.6, 1, 0.94, 0.7})

            local carbs = player:getNutrition():getCarbohydrates()
            self:render_KYC_drawNutrientBar("Carbohydrates", carbs, backgroundTexture, nutrientsTexture, {0.6, 0.55, 1, 0.68})
        end
        if isNutritionist or cookingLevel > sandboxProteinsLevel then
            local proteins = player:getNutrition():getProteins()
            self:render_KYC_drawNutrientBar("Proteins", proteins, backgroundTexture, nutrientsTexture, {0.6, 1, 0.42, 0.33})
        end
        if isNutritionist or cookingLevel > sandboxCaloriesLevel then
            local calories = player:getNutrition():getCalories()
            self:render_KYC_drawNutrientBar("Calories", calories, backgroundTexture, nutrientsTexture, {0.6, 0.9, 1, 0.2})
        end
    end
end

-------------------------------------------------------------------------------

-------- SETUP  --------

local function KnowYourCalories_Setup()
    if KnowYourCalories_IsSetup then
        return
    end
    KnowYourCalories_IsSetup = true

    setupLocalVars()
    local charScreen_render = ISCharacterScreen.render
    function ISCharacterScreen:render()
        local result = charScreen_render(self)
        if SandboxVars.KnowYourCalories.UseProgressBar then
            self:render_KYC_DisplayNutrientBars()
        else
            self:render_KYC_DisplayNutrientNumbers()
        end
        return result
    end
end

Events.OnGameStart.Add(KnowYourCalories_Setup)
-------------------------------------------------------------------------------