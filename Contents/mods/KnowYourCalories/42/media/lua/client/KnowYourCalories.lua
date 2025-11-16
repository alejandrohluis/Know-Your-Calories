--   ********************
--   * KnowYourCalories *
--   ********************
-- + Developer: Dios Pato
-- + Date of Creation: 17/05/2024
-- + Date of Modification: 2/02/2025
--************************************

require ('XpSystem/ISUI/ISCharacterScreen')
-------------------------------------------------------------------------------
local lcl = {}

lcl.player_base       = __classmetatables[IsoPlayer.class].__index
lcl.player_character  = __classmetatables[IsoGameCharacter.class].__index

lcl.tm_base           = __classmetatables[TextManager.class].__index
lcl.tm_MeasureStringX = lcl.tm_base.MeasureStringX

lcl.getPlayer         = getPlayer
lcl.getText           = getText
lcl.drawRect          = drawRect
-------------------------------------------------------------------------------
local KnowYourCalories_IsSetup = false

local function KnowYourCalories_Setup()
    if not KnowYourCalories_IsSetup then
        KnowYourCalories_IsSetup = true
        local charScreen_render = ISCharacterScreen.render
        function ISCharacterScreen:render()
            local result = charScreen_render(self)
            if SandboxVars.KnowYourCalories.UseProgressBar then
                self:render_KYC_DisplayCalorieBar()
            else
                self:render_KYC_DisplayCalorieNumber()
            end
            return result
        end
    end
end

function ISCharacterScreen:render_KYC_NutrientBarDescription(barPositionX, barPositionY, nutrient, nutrientValue)
    local mouseX = self:getMouseX()
    local mouseY = self:getMouseY()
    -- checking for OR is easier or equal than checking for AND
    if !((mouseX < barPositionX or mouseX > barPositionX + 10) or (mouseY < barPositionY or mouseY > barPositionY + 100)) then
        local nutrientName = getText("UI_"..nutrient)
        local nameWidth = getTextManager():MeasureStringX(UIFont.Small, nutrientName)
        local nutrientHeight = getTextManager():getFontHeight(UIFont.Small)
        if not SandboxVars.KnowYourCalories.ProgressBarDescription then nutrientHeight = nutrientHeight / 2.25 end
        local descriptionPositionX = self.width - nameWidth - 15
        local descriptionPositionZ = self.height - 110 - nutrientHeight * 2.25
        self:drawRect(descriptionPositionX, descriptionPositionZ, nameWidth + 10, nutrientHeight * 2.25, 1.0, 0.4, 0.4, 0.4)
        self:drawRect(descriptionPositionX + 1, descriptionPositionZ + 1, nameWidth + 8, nutrientHeight * 2.25 - 2, 0.8, 0.0, 0.0, 0.0)
        self:drawText(nutrientName, descriptionPositionX + 5, descriptionPositionZ, 1, 1, 1, 1, UIFont.Small)
        if SandboxVars.KnowYourCalories.ProgressBarDescription then
            self:drawText(nutrientValue, descriptionPositionX + 5, descriptionPositionZ + nutrientHeight, 1, 1, 1, 0.5, UIFont.Small)
        end
    end
end

function ISCharacterScreen:render_KYC_DisplayCalorieNumber()
    local player = self.char or lcl.getPlayer()
    local hasNutritionist = SandboxVars.KnowYourCalories.NeedNutritionist and (player:HasTrait("Nutritionist") or player:HasTrait("Nutritionist2"))
    local lowestCookingLevelNeeded = math.min(SandboxVars.KnowYourCalories.NeedCookingLevelForCalories,math.min(SandboxVars.KnowYourCalories.NeedCookingLevelForProteins,SandboxVars.KnowYourCalories.NeedCookingLevelForOthers))
    if player:getPerkLevel(Perks.Cooking) >= lowestCookingLevelNeeded or hasNutritionist then
        local textManager = getTextManager()
        local FONT_HGT_SMALL = textManager:getFontHeight(UIFont.Small)

        -- this measures and compares 3 different texts, then uses the longest one, 
        -- ensuring that it is well positioned with all languages supported by the mod
        local textWidth1 = lcl.tm_MeasureStringX(textManager, UIFont.Small, lcl.getText("IGUI_char_Favourite_Weapon"))
        local textWidth2 = lcl.tm_MeasureStringX(textManager, UIFont.Small, lcl.getText("IGUI_char_Zombies_Killed"))
        local textWidth3 = lcl.tm_MeasureStringX(textManager, UIFont.Small, lcl.getText("IGUI_char_Survived_For"))
        local nutritionX = 20 + math.max(textWidth1,math.max(textWidth2,textWidth3))
        
        local windowHeight = self.height
        local clock = UIManager.getClock()
        if not (instanceof(self.char, 'IsoPlayer') and clock and clock:isDateVisible()) then
            windowHeight = windowHeight - FONT_HGT_SMALL - 6
        end
        local nutritionZ = windowHeight - 10
        local rounding = -SandboxVars.KnowYourCalories.Rounding + 1
        if player:getPerkLevel(Perks.Cooking) >= SandboxVars.KnowYourCalories.NeedCookingLevelForCalories or hasNutritionist then
            local calories = string.format(round(player:getNutrition():getCalories(), rounding))
            self:drawTextRight(getText("UI_Calories"), nutritionX, nutritionZ, 1, 1, 1, 1, UIFont.Small)
            self:drawText(calories, nutritionX + 10, nutritionZ, 1, 1, 1, 0.5, UIFont.Small)
            windowHeight = windowHeight + FONT_HGT_SMALL + 6
            nutritionZ = windowHeight - 10
        end
        if player:getPerkLevel(Perks.Cooking) >= SandboxVars.KnowYourCalories.NeedCookingLevelForProteins or hasNutritionist then
            local proteins = string.format(round(player:getNutrition():getProteins(), rounding))
            self:drawTextRight(getText("UI_Proteins"), nutritionX, nutritionZ, 1, 1, 1, 1, UIFont.Small)
            self:drawText(proteins, nutritionX + 10, nutritionZ, 1, 1, 1, 0.5, UIFont.Small)
            windowHeight = windowHeight + FONT_HGT_SMALL + 6
            nutritionZ = windowHeight - 10
        end
        if player:getPerkLevel(Perks.Cooking) >= SandboxVars.KnowYourCalories.NeedCookingLevelForOthers or hasNutritionist then
            local fats = string.format(round(player:getNutrition():getLipids(), rounding))
            self:drawTextRight(getText("UI_Fats"), nutritionX, nutritionZ, 1, 1, 1, 1, UIFont.Small)
            self:drawText(fats, nutritionX + 10, nutritionZ, 1, 1, 1, 0.5, UIFont.Small)
            windowHeight = windowHeight + FONT_HGT_SMALL + 6
            nutritionZ = windowHeight - 10
            local carbs = string.format(round(player:getNutrition():getCarbohydrates(), rounding))
            self:drawTextRight(getText("UI_Carbohydrates"), nutritionX, nutritionZ, 1, 1, 1, 1, UIFont.Small)
            self:drawText(carbs, nutritionX + 10, nutritionZ, 1, 1, 1, 0.5, UIFont.Small)
            windowHeight = windowHeight + FONT_HGT_SMALL + 6
            nutritionZ = windowHeight - 10
        end
        windowHeight = windowHeight + 10
        self:setHeightAndParentHeight(windowHeight)
    end
end

function ISCharacterScreen:render_KYC_DisplayCalorieBar()
    local player = self.char or lcl.getPlayer()
    local hasNutritionist = SandboxVars.KnowYourCalories.NeedNutritionist and (player:HasTrait("Nutritionist") or player:HasTrait("Nutritionist2"))
    local lowestCookingLevelNeeded = math.min(SandboxVars.KnowYourCalories.NeedCookingLevelForCalories,math.min(SandboxVars.KnowYourCalories.NeedCookingLevelForProteins,SandboxVars.KnowYourCalories.NeedCookingLevelForOthers))
    if player:getPerkLevel(Perks.Cooking) >= lowestCookingLevelNeeded or hasNutritionist then
        local nutritionX = self.width - 15
        local nutritionZ = self.height - 105
        local backgroundTexture = getTexture("media/textures/background.png")
        local rounding = -SandboxVars.KnowYourCalories.Rounding + 1
        if player:getPerkLevel(Perks.Cooking) >= SandboxVars.KnowYourCalories.NeedCookingLevelForOthers or hasNutritionist then
            local fats = string.format(round(player:getNutrition():getLipids(), rounding))
            local fatsPercentage = (fats+500)/15.0
            local fatsTexture = getTexture("media/textures/nutrients.png")
            self:drawTexture(backgroundTexture, nutritionX, nutritionZ, 0.8, 1, 1, 1)
            self:drawTextureScaled(fatsTexture, nutritionX, nutritionZ, 10, fatsPercentage, 0.6, 1, 0.94, 0.7)
            self:render_KYC_NutrientBarDescription(nutritionX, nutritionZ, "Fats", fats)
            nutritionX = nutritionX - 15
            local carbs = string.format(round(player:getNutrition():getCarbohydrates(), rounding))
            local carbsPercentage = (carbs+500)/15.0
            local carbsTexture = getTexture("media/textures/nutrients.png")
            self:drawTexture(backgroundTexture, nutritionX, nutritionZ, 0.8, 1, 1, 1)
            self:drawTextureScaled(carbsTexture, nutritionX, nutritionZ, 10, carbsPercentage, 0.6, 0.55, 1, 0.68)
            self:render_KYC_NutrientBarDescription(nutritionX, nutritionZ, "Carbohydrates", carbs)
            nutritionX = nutritionX - 15
        end
        if player:getPerkLevel(Perks.Cooking) >= SandboxVars.KnowYourCalories.NeedCookingLevelForProteins or hasNutritionist then
            local proteins = string.format(round(player:getNutrition():getProteins(), rounding))
            local proteinsPercentage = (proteins+500)/15.0
            local proteinsTexture = getTexture("media/textures/nutrients.png")
            self:drawTexture(backgroundTexture, nutritionX, nutritionZ, 0.8, 1, 1, 1)
            self:drawTextureScaled(proteinsTexture, nutritionX, nutritionZ+1, 10, proteinsPercentage, 0.6, 1, 0.42, 0.33)
            self:render_KYC_NutrientBarDescription(nutritionX, nutritionZ, "Proteins", proteins)
            nutritionX = nutritionX - 15
        end
        if player:getPerkLevel(Perks.Cooking) >= SandboxVars.KnowYourCalories.NeedCookingLevelForCalories or hasNutritionist then
            local calories = string.format(round(player:getNutrition():getCalories(), rounding))
            local caloriesPercentage = (calories+2200)/59.0
            local caloriesTexture = getTexture("media/textures/nutrients.png")
            self:drawTexture(backgroundTexture, nutritionX, nutritionZ, 0.8, 1, 1, 1)
            self:drawTextureScaled(caloriesTexture, nutritionX, nutritionZ, 10, caloriesPercentage, 0.6, 0.9, 1, 0.2)
            self:render_KYC_NutrientBarDescription(nutritionX, nutritionZ, "Calories", calories)
        end
    end
end

Events.OnGameStart.Add(KnowYourCalories_Setup)
-------------------------------------------------------------------------------