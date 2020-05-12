--region *.lua
--Date
--此文件由[BabeLua]插件自动生成
local CardSprite = class("CardSprite", cc.Sprite)

local CardData = {
    --斥候
    { name = "chihou", damage = 8, blood = 20, recovery = 0 , move = 3, range = 1, coin = 0, coin_type = 1},

    --步兵
    { name = "bubing", damage = 6, blood = 28, recovery = 0 , move = 2, range = 1, coin = 0, coin_type = 1 },

    --骑兵
    { name = "qibing", damage = 9, blood = 25, recovery = 0 , move = 4, range = 1, coin = 0, coin_type = 1 },

    --盾兵
    { name = "dunbing", damage = 5, blood = 30, recovery = 0 , move = 2, range = 1, coin = 0, coin_type = 1 },

    --枪兵
    { name = "qingbing", damage = 10, blood = 18, recovery = 0, move = 3, range = 1, coin = 0, coin_type = 1 },

    --军医
    { name = "junyi", damage = 0, blood = 18, recovery = 8 , move = 3, range = 1, coin = 3, coin_type = 2 },

    --突袭兵
    { name = "tuxibing", damage = 12, blood = 16, recovery = 0 , move = 3, range = 1, coin = 6, coin_type = 2 },

    --斧兵
    { name = "fubing", damage = 7, blood = 28, recovery = 0, move = 3, range = 1, coin = 500, coin_type = 1 },

    --弓箭手
    { name = "gongshou", damage = 10, blood = 22, recovery = 0, move = 3, range = 2, coin = 500, coin_type = 1 },

    --投枪手
    { name = "touqiangshou", damage = 12, blood = 20, recovery = 0, move = 3, range = 3, coin = 500, coin_type = 1 },

    --力士
    { name = "lishi", damage = 14, blood = 25, recovery = 0, move = 3, range = 1, coin = 12, coin_type = 2 },

    --治疗师
    { name = "zhiliaoshi", damage = 0, blood = 30, recovery = 12 , move = 2, range = 1, coin = 800, coin_type = 1 },

    --投石车
    { name = "toushiche", damage = 9, blood = 32, recovery = 0 , move = 3, range = 3, coin = 1000, coin_type = 1 },

    --火炮
    { name = "huopao", damage = 18, blood = 20, recovery = 0, move = 3, range = 3, coin = 18, coin_type = 2 },

    --弓弩车
    { name = "gongnuche", damage = 18, blood = 38, recovery = 0, move = 3, range = 3, coin = 1500, coin_type = 1 },

    --副将
    { name = "fujiang", damage = 16, blood = 30, recovery = 0 , move = 4, range = 1, coin = 1500, coin_type = 1 },

    --军师
    { name = "junshi", damage = 20, blood = 42, recovery = 0 , move = 2, range = 1, coin = 1800, coin_type = 1 },

    --将军
    { name = "jiangjun", damage = 18, blood = 48, recovery = 0 , move = 2, range = 1, coin = 24, coin_type = 2 },
}

--关卡数据
local LevelData = {
    {1, 2, 3, 4, 5},
    {2, 3, 4, 5, 7},
    {3, 4, 6, 7, 8},
    {4, 5, 6, 7, 8},
    {3, 6, 7, 8, 9},
    {7, 9, 10, 11, 12},
    {7, 8, 9, 10, 11},
    {6, 8, 9, 10, 12},
    {8, 9, 10, 11, 13},
    {5, 6, 7, 8, 10},
    {4, 7, 8, 9, 10},
    {9, 10, 12, 13, 14},
    {6, 8, 9, 10, 11},
    {7, 9, 10, 11, 12},
    {8, 10, 11, 12, 13},
    {9, 10, 11, 12, 13},
    {10, 11, 12, 13, 14},
    {13, 14, 15, 16, 17},
    {9, 10, 13, 14, 15},
    {8, 11, 12, 13, 14},
    {7, 11, 12, 14, 15},
    {10, 12, 13, 14, 16},
    {11, 12, 13, 14, 15},
    {14, 15, 16, 17, 18}
}

--道具数据          type 1 恢复生命 2 增加攻击力 3 再移动一次
local PropData = {
    {name = "bengdai", blood = 18, type = 1, num = 6},
    {name = "modaoshi", blood = 25, type = 2, num = 2},
    {name = "yaoshui", blood = 25, type = 1, num = 8},
    {name = "duanzaochui", blood = 30, type = 2, num = 3},
    {name = "yiliaoxiang", blood = 30, type = 1, num = 10},
    {name = "xingfenji", blood = 40, type = 2, num = 5},
    {name = "zhanma", blood = 4, type = 3, num = 1},
}

function CardSprite:ctor()

end

function CardSprite:createCard(idx, target)
    local card = {}
    card.sp = target:clone()
    card.sp:loadTexture("card_3_".. idx ..".png", UI_TEX_TYPE_PLIST)
    card.text_hp = card.sp:getChildByName("text_hp")
    card.text_hp:setString(CardData[idx].blood)
    card.text_hp:setPosition(cc.p(24, card.sp:getContentSize().height / 2 - 22 ))
    card.text_att = card.sp:getChildByName("text_att")
    card.text_att:setString(CardData[idx].damage)
    card.text_att:setPosition(cc.p(47, card.sp:getContentSize().height / 2 - 22 ))
    if CardData[idx].damage == 0 then
        card.text_att:setString(CardData[idx].recovery)
    end
    card.damage = CardData[idx].damage
    card.blood = CardData[idx].blood
    card.recovery = CardData[idx].recovery
    card.name = CardData[idx].name
    card.range = CardData[idx].range
    card.move = CardData[idx].move
    card.btn_wait = card.sp:getChildByName("btn_wait")
    card.btn_attack = card.sp:getChildByName("btn_attack")
    card.box = card.sp:getChildByName("box")
    return card
end

-- 放置棋盘上
function CardSprite:setSprite(card)
    card.sp:loadTexture("card_3_".. card.id ..".png", UI_TEX_TYPE_PLIST)
end

-- 返回手牌
function CardSprite:setSpriteD(card)
    card.sp:loadTexture("card_3_".. card.id ..".png", UI_TEX_TYPE_PLIST)
end

-- 获取卡牌信息
function CardSprite:getSpriteD(tag)
    local card = {}
    card.coin = CardData[tag].coin
    card.idx = tag
    card.coin_type = CardData[tag].coin_type
    card.blood = CardData[tag].blood
    return card
end

-- 商店卡牌预制体
function CardSprite:createShopCard(idx)

    local card = {}
    card.sp = cc.Sprite:createWithSpriteFrameName("C".. CardData[idx].name ..".png")
    card.frame = cc.Sprite:createWithSpriteFrameName("chios.png")
    card.frame:setPosition(cc.p(61, 82))
    card.frame:setAnchorPoint(cc.p(0.5, 0.5))
    card.frame:addTo(card.sp)
    card.maks = cc.Sprite:createWithSpriteFrameName("shopMaks.png")
   -- card.maks:setScale(1.1)
    card.maks:setAnchorPoint(ccp(0.5,0.5))
    card.maks:setPosition(cc.p(60, 78))
    card.maks:addTo(card.sp)
    local money = cc.Sprite:createWithSpriteFrameName("money.png")
    money:setAnchorPoint(ccp(0.5,0.5))
    money:setPosition(cc.p(40, 78))
    money:addTo(card.maks)
    local txt = cc.Label:createWithTTF(CardData[idx].coin, "majia/font/font.ttf", 20)
    txt:setAnchorPoint(ccp(0.5,0.5))
    txt:setPosition(cc.p(72, 78))
    txt:addTo(card.maks)
    card.coin = CardData[idx].coin
    card.idx = idx
    return card

end

-- 返回手牌
function CardSprite:getLevelData()
    return LevelData
end

-- 返回道具
function CardSprite:getPropData()
    return PropData
end

return CardSprite;
--endregion
