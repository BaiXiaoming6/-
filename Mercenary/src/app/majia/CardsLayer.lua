--region *.lua
--Date
--此文件由[BabeLua]插件自动生成
local CardSprite = require "app.majia.CardSprite"
CardsLayer = class("CardsLayer",function()
    return cc.Layer:create()
end)

local plistName = "majia/images/game_ui.plist"

function CardsLayer:ctor()
    if not cc.SpriteFrameCache:getInstance():isSpriteFramesWithFileLoaded(plistName) then
        cc.SpriteFrameCache:getInstance():addSpriteFrames(plistName)
    end

    self.loadNode = cc.CSLoader:createNode("majia/CardsLayer.csb")
    self.loadNode:setContentSize(cc.size(display.size.height, display.size.width))
    ccui.Helper:doLayout(self.loadNode)
    self:addChild(self.loadNode, 0)
    self.layer = self.loadNode:getChildByName("Layer_cards")
    self.card_up = self.layer:getChildByName("card_clone_1")
    self.card_down = self.layer:getChildByName("card_clone_2")

    local tips = self.layer:getChildByName("tips")

    local btn_close = self.layer:getChildByName("btn_back")
    btn_close:addTouchEventListener(function(sender , event)
        if event == 2 then
            if MainScene.isOpenEffect then
                AudioEngine.playEffect("majia/sound/click.mp3")
            end
            if #self.userCard < 4 then
                tips:setVisible(true)
                performWithDelay(self,function()
                    tips:setVisible(false)
                end, 1)
                return
            end
            cc.UserDefault:getInstance():setStringForKey("userCard", self:toStringM(self.userCard))
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
    self.userCard = self:toTableM(userCard)

    local cardList = self.layer:getChildByName("list_card")

    self.cardTab_up = {}
    for i=1,cardCount do
        local card = self.card_up:clone()
        card:loadTextures("card_2_" .. i .. ".png", "card_2_" .. i .. ".png", "card_2_" .. i .. ".png", UI_TEX_TYPE_PLIST)
        cardList:addChild(card)
        table.insert(self.cardTab_up, card)

        card:addTouchEventListener(function(sender , event)
            if event == 2 then
                if MainScene.isOpenEffect then
                    AudioEngine.playEffect("majia/sound/click.mp3")
                end
                if #self.userCard >= 5 then
                    return
                end
                local mask = card:getChildByName("mask")
                mask:setVisible(true)
                for j=1,5 do
                    if self.posCount[j] == 0 then
                        self:createCard(j, true, i)
                        break
                    end
                end
            end
        end)
    end

    self.posCount = {1,1,1,1,1}
    if #self.userCard == 4 then
        self.posCount[5] = 0
    end
    self.cardPos = {}
    for i=1,5 do
        local pos = self.layer:getChildByName("card_" .. i)
        table.insert(self.cardPos, pos)
    end
    for i=1,#self.userCard do
        local mask = self.cardTab_up[self.userCard[i]]:getChildByName("mask")
        mask:setVisible(true)
        self:createCard(i)
    end
end

-- 创建一张牌
function CardsLayer:createCard(index, isPush, index2)
    self.posCount[index] = 1
    local pos = self.cardPos[index]
    local card = self.card_down:clone()
    if isPush then
        card:loadTextures("card_2_" .. index2 .. ".png", "card_2_" .. index2 .. ".png", "card_2_" .. index2 .. ".png", UI_TEX_TYPE_PLIST)
        card:setTag(index2)
        for i=1,#self.userCard do
            if self.userCard[i] == nil then
                table.remove(self.userCard, i)
            end
        end
        table.insert(self.userCard, index2)
        table.sort(self.userCard, function(a, b) return a < b end)
    else
        card:loadTextures("card_2_" .. self.userCard[index] .. ".png", "card_2_" .. self.userCard[index] .. ".png", "card_2_" .. self.userCard[index] .. ".png", UI_TEX_TYPE_PLIST)
        card:setTag(self.userCard[index])
    end

    self.layer:addChild(card)
    card:setPosition(cc.p(pos:getPositionX(), pos:getPositionY()))
    local btn_cancel = card:getChildByName("mask"):getChildByName("btn_cancel")
    btn_cancel:setTag(index)
    btn_cancel:addTouchEventListener(function(sender , event)
        if event == 2 then
            if MainScene.isOpenEffect then
                AudioEngine.playEffect("majia/sound/click.mp3")
            end
            local tag = card:getTag()
            card:removeFromParent()

            for i=1,#self.cardTab_up do
                if tag == i then
                    local mask = self.cardTab_up[i]:getChildByName("mask")
                    mask:setVisible(false)
                end
            end
            for i=1,5 do
               if self.userCard[i] == tag then
                    table.remove(self.userCard, i)
               end
            end
            self.posCount[index] = 0
        end
    end)
end

-- 读取
function CardsLayer:toTableM(str)
    local temp = {}
    for w in string.gmatch(str, "%d+") do
        temp[#temp + 1] = tonumber(w)
    end
    return temp
end

-- 存储
function CardsLayer:toStringM(table)
    local str = ""
    for i = 1, #table do
        str = str .. tostring(table[i]) .. "."
    end
    return str
end

return CardsLayer