--region *.lua
--Date
--此文件由[BabeLua]插件自动生成
local CardSprite = require "app.majia.CardSprite"
ShopLayer = class("ShopLayer",function()
    return cc.Layer:create()
end)

ShopLayer.pos = { x = 200, y = 530}

local plistName = "majia/images/game_ui.plist"

function ShopLayer:ctor()
    if not cc.SpriteFrameCache:getInstance():isSpriteFramesWithFileLoaded(plistName) then
        cc.SpriteFrameCache:getInstance():addSpriteFrames(plistName)
    end

    self.loadNode = cc.CSLoader:createNode("majia/ShopLayer.csb")
    self.loadNode:setContentSize(cc.size(display.size.height, display.size.width))
    ccui.Helper:doLayout(self.loadNode)
    self:addChild(self.loadNode, 0)

    local layer = self.loadNode:getChildByName("Layer_shop")
    self.tips = layer:getChildByName("tips")

    -- 玩家金钱
    local money = cc.UserDefault:getInstance():getIntegerForKey("myMoney")
    self.txt = layer:getChildByName("Text_honor")
    self.txt:setString(money)

    local btn_close = layer:getChildByName("btn_back")
    btn_close:addTouchEventListener(function(sender , event)
        if event == 2 then
            if MainScene.isOpenEffect then
                AudioEngine.playEffect("majia/sound/click.mp3")
            end
            self:removeFromParent()
        end
    end)

    local userCard = cc.UserDefault:getInstance():getStringForKey("userCard")
    local cardCount = cc.UserDefault:getInstance():getIntegerForKey("cardCount")
    if cardCount < 1 then
        cardCount = 5
        userCard = self:toTableM('01.02.03.04.05')
        cc.UserDefault:getInstance():setIntegerForKey("cardCount", 5)
        cc.UserDefault:getInstance():setStringForKey("userCard", self:toStringM(userCard))
    end
    --userCard = self:toTableM(userCard)

    self.cardTab = {}
    for i=1,18 do
        local card = layer:getChildByName("card_" .. i)
        card:addTouchEventListener(function(sender , event)
            if event == 2 then
                if MainScene.isOpenEffect then
                    AudioEngine.playEffect("majia/sound/click.mp3")
                end
                local cardCount = cc.UserDefault:getInstance():getIntegerForKey("cardCount")
                if i <= cardCount then
                    return
                end
                self:doBuy(i)
            end
        end)
        --card:getChildByName("mask"):setVisible(true)
        card:getChildByName("btn"):setOpacity(0)
        card:getChildByName("btn"):setEnabled(false)
        table.insert(self.cardTab, card)
    end
    for i=1,cardCount do
        -- self.cardTab[i]:getChildByName("mask"):setVisible(false)
        -- self.cardTab[i]:getChildByName("btn"):setEnabled(true)
        self.cardTab[i]:getChildByName("btn"):setOpacity(255)
    end
end

-- 购买
function ShopLayer:doBuy(tag)
    local money = cc.UserDefault:getInstance():getIntegerForKey("myMoney")
    local levelCount = cc.UserDefault:getInstance():getIntegerForKey("levelCount")
    local data = CardSprite:getSpriteD(tag)
    local coin = data.coin
    local coin_type = data.coin_type
    local idx = data.idx
    local cardCount = cc.UserDefault:getInstance():getIntegerForKey("cardCount")
    local isbuy = true
    if coin_type == 1 then
        if money < coin then
            isbuy = false
        end
    else
        if levelCount < coin then
            isbuy = false
        end
    end
    if not isbuy then
        self.tips:setVisible(true)
        if coin_type == 1 then
            self.tips:getChildByName("lbl_tips"):setString("Not enough coins")
        else
            self.tips:getChildByName("lbl_tips"):setString("Not enough passes")
        end
        performWithDelay(self,function()
            self.tips:setVisible(false)
        end, 1)
        return
    elseif idx ~= cardCount + 1 then
        self.tips:setVisible(true)
        self.tips:getChildByName("lbl_tips"):setString("Unlock the last one")
        performWithDelay(self,function()
            self.tips:setVisible(false)
        end, 1)
        return
    else
        if coin_type == 1 then
            money = money - coin
            self.txt:setString(money)
            cc.UserDefault:getInstance():setIntegerForKey("myMoney", money)
        end
        cardCount = cardCount + 1
        cc.UserDefault:getInstance():setIntegerForKey("cardCount", cardCount)
        --self.cardTab[tag]:getChildByName("mask"):setVisible(true)
        self.cardTab[tag]:getChildByName("btn"):setOpacity(255)
    end
end

-- 读取
function ShopLayer:toTableM(str)
    local temp = {}
    for w in string.gmatch(str, "%d+") do
        temp[#temp + 1] = tonumber(w)
    end
    return temp
end

-- 存储
function ShopLayer:toStringM(table)

    local str = ""
    for i = 1, #table do
        str = str .. tostring(table[i]) .. "."
    end

    return str
end

return ShopLayer



--endregion
