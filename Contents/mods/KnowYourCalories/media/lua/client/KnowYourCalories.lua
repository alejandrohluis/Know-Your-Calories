--   ********************
--   * KnowYourCalories *
--   ********************
-- + Developer: Dios Pato
-- + Date of Creation: 17/05/2024
-- + Date of Modification: 27/12/2024
--************************************

require ('XpSystem/ISUI/ISCharacterScreen')
-------------------------------------------------------------------------------
local lcl = {}

lcl.player_base       = __classmetatables[IsoPlayer.class].__index
lcl.player_character  = __classmetatables[IsoGameCharacter.class].__index

lcl.tm_base           = __classmetatables[TextManager.class].__index
lcl.tm_MeasureStringX = lcl.tm_base.MeasureStringX
lcl.tm_MeasureStringY = lcl.tm_base.MeasureStringY

lcl.getPlayer         = getPlayer
lcl.getText           = getText
-------------------------------------------------------------------------------
local KnowYourCalories_IsSetup = false

local function KnowYourCalories_Setup()
    if not KnowYourCalories_IsSetup then
        KnowYourCalories_IsSetup = true
        local charScreen_render = ISCharacterScreen.render
        function ISCharacterScreen:render()
            local result = charScreen_render(self)
            -- if SandboxVars.KnowYourCalories.UseProgressBar then
                -- self:render_DisplayCalorieBar()
            -- else
                self:render_DisplayCalorieNumber()
            -- end
            return result
        end

    end
end

function ISCharacterScreen:render_DisplayCalorieNumber()
    local player = self.char or lcl.getPlayer()
    if player:getPerkLevel(Perks.Cooking) >= SandboxVars.KnowYourCalories.NeedCookingLevel or
    (SandboxVars.KnowYourCalories.NeedNutritionist and (player:HasTrait("Nutritionist") or player:HasTrait("Nutritionist2"))) then
        local calories = string.format(round(player:getNutrition():getCalories(), -SandboxVars.KnowYourCalories.CalorieNumberShown + 1))
        local textManager = getTextManager()
        local textHeight = textManager:getFontFromEnum(UIFont.Small):getLineHeight()
        local textWid1 = lcl.tm_MeasureStringX(textManager, UIFont.Small, lcl.getText("IGUI_char_Favourite_Weapon"))
        local textWid2 = lcl.tm_MeasureStringX(textManager, UIFont.Small, lcl.getText("IGUI_char_Zombies_Killed"))
        local textWid3 = lcl.tm_MeasureStringX(textManager, UIFont.Small, lcl.getText("IGUI_char_Survived_For"))
        local calorieX = 20 + math.max(textWid1,math.max(textWid2,textWid3))
        -- this measures and compares 3 different texts, then uses the longest one, ensuring that it is well positioned with all languages supported by the mod
        local windowHeight = self.height + textHeight
        if not (UIManager.getClock() and UIManager.getClock():isDateVisible()) then
            windowHeight = windowHeight - textHeight
        end
        local calorieZ
        if getCore():getOptionFontSize() < 3 then
            calorieZ = windowHeight - 5 * getCore():getOptionFontSize() - 19
        else
            calorieZ = windowHeight - 6 * (getCore():getOptionFontSize()-5) - 45
        end
        self:drawTextRight(lcl.getText("UI_Calorie"), calorieX, calorieZ, 1, 1, 1, 1, UIFont.Small)
        self:drawText(calories, calorieX + 10, calorieZ, 1, 1, 1, 0.5, UIFont.Small)
        self:setHeightAndParentHeight(windowHeight)
    end
end

Events.OnGameStart.Add(KnowYourCalories_Setup)
-------------------------------------------------------------------------------