local CardSprite = require "app.majia.CardSprite"
local GameLayer = class("GameLayer", function()
    return cc.Scene:create() end)

local USERSELF = 1
local USERCOMPUTER = 2

local ZHENG = 2
local FAN = 1

GameLayer.gameType = 1

function GameLayer:ctor()
    math.randomseed( os.time())
    self:loadResource()

    if MainScene.isOpenMusic then
        PLAY_BACKGROUND_MUSIC("game_bg")--播放音乐
    end
end

-- 初始化数据
function GameLayer:reSetData()
    -- 棋盘
    self.Maps = {}

    -- 玩家卡牌
    self.userCards = {{},{}}

    -- 棋盘上的牌
    self.battCards = {{},{}}

    -- 当前操作玩家
    self.currentPlayer = USERSELF

    --当前玩家处理了几张牌
    self.dealCardCount = 5

    --功能按钮初始位置
    self.initPos = {-12, 76}
    self.initPosY = 76

    --是否在播放动画
    self.isAnimTime = false

    --是否开始PK
    self.isPK = false

    --当前选中的牌
    self.curCard = nil
    --当前选中牌可攻击的牌
    self.curRange = {}
    --初始牌的位置
    self.initCardPos = {{},{}}

    --棋盘上的道具
    self.props = {}

    --回合计数
    self.roundCount = 0

    self.propData = CardSprite:getPropData()
end

-- 读取
function GameLayer:toTableM(str)
    local temp = {}
    for w in string.gmatch(str, "%d+") do
        temp[#temp + 1] = tonumber(w)
    end

    return temp
end

-- 加载资源
function GameLayer:loadResource()
    -- 初始化数据
    self:reSetData()

    -- 加载卡牌纹理
    cc.SpriteFrameCache:getInstance():addSpriteFrames("majia/images/game_ui.plist")

    -- 加载纹理
    cc.SpriteFrameCache:getInstance():addSpriteFrames("majia/images/game/gold.plist")
    cc.SpriteFrameCache:getInstance():addSpriteFrames("majia/images/game/attck.plist")
    cc.SpriteFrameCache:getInstance():addSpriteFrames("majia/images/game/borken_ui.plist")

    -- 加载游戏
    self.loadNode = cc.CSLoader:createNode("majia/PlayScene.csb")
    self.loadNode:setContentSize(cc.size(display.size.height, display.size.width))
    ccui.Helper:doLayout(self.loadNode)
    self:addChild(self.loadNode, 0)

    self.layer = self.loadNode:getChildByName("Panel_ui")
    local scX = display.width/self.layer:getContentSize().width
    local scY = display.height/self.layer:getContentSize().height
    self.loadNode:setScaleX(scX)
    self.loadNode:setScaleY(scY)

    self.endLayer = self.loadNode:getChildByName("Panel_end")

    self.text_round = self.layer:getChildByName("text_round")

    self.card_clone = self.loadNode:getChildByName("card_clone")
    self.prop_clone = self.loadNode:getChildByName("prop_clone")

    -- 关闭
    local btn_close = self.layer:getChildByName("Button_close")
    btn_close:addTouchEventListener(function(sender , event)
        if event == 2 then
            if MainScene.isOpenEffect then
                AudioEngine.playEffect("majia/sound/click.mp3")
            end
            self:onExit()
            local GameScene = require "app.majia.MainScene"
            local miniGameScene = GameScene:create()
            local ts = cc.TransitionFlipY:create(0.5, miniGameScene)
            cc.Director:getInstance():replaceScene(ts)
        end
    end)

    -- 回合结束
    self.btn_end = self.layer:getChildByName("Button_end")
    self.btn_end:addTouchEventListener(function(sender , event)
        if event == 2 then
            self.dealCardCount = 0
            --开始人机回合
            self:dealRound(USERCOMPUTER)
            self.btn_end:setVisible(false)
            for i=1,#self.Maps do
                self.Maps[i].move:setVisible(false)
                self.Maps[i].damage:setVisible(false)
                self.Maps[i].can_place = false
            end
            if MainScene.isOpenEffect then
                AudioEngine.playEffect("majia/sound/click.mp3")
            end
        end
    end)
    self.btn_end:setVisible(false)

    self.guessLayer = self.loadNode:getChildByName("Panel_guess")
    self.coinback_90 = self.guessLayer:getChildByName("Coinback_90")

    -- 正面
    Button_obcerse = self.guessLayer:getChildByName("Button_obcerse")
    Button_obcerse:addTouchEventListener(function(sender , event)
        if event == 2 then
            if MainScene.isOpenEffect then
                AudioEngine.playEffect("majia/sound/click.mp3")
            end
            self:guessFirstAnimation(ZHENG)
            Button_bcak:setVisible(false)
            Button_obcerse:setVisible(false)
            self.coinback_90:setVisible(false)
        end
    end)

    -- 反面
    Button_bcak = self.guessLayer:getChildByName("Button_bcak")
    Button_bcak:addTouchEventListener(function(sender , event)
        if event == 2 then
            if MainScene.isOpenEffect then
                AudioEngine.playEffect("majia/sound/click.mp3")
            end
            self:guessFirstAnimation(FAN)
            Button_bcak:setVisible(false)
            Button_obcerse:setVisible(false)
            self.coinback_90:setVisible(false)
        end
    end)

    -- 退出
    local btn_quit = self.endLayer:getChildByName("btn_quit")
    btn_quit:addTouchEventListener(function(sender , event)
        if event == 2 then
            if MainScene.isOpenEffect then
                AudioEngine.playEffect("majia/sound/click.mp3")
            end
            self:onExit()
            local GameScene = require "app.majia.MainScene"
            local miniGameScene = GameScene:create()
            local ts = cc.TransitionFlipY:create(0.5, miniGameScene)
            cc.Director:getInstance():replaceScene(ts)
        end
    end)

     -- 寻找对手
    self.btn_find = self.endLayer:getChildByName("btn_find")
    self.btn_find:addTouchEventListener(function(sender , event)
        if event == 2 then
            if MainScene.isOpenEffect then
                AudioEngine.playEffect("majia/sound/click.mp3")
            end
            local gamePlayScene = require("app.majia.GameLayer")
            local scene = gamePlayScene.create()
            local ts = cc.TransitionFlipX:create(0.5, scene)
            cc.Director:getInstance():replaceScene(ts)
        end
    end)

------------------------------------------------------------------------------------------------------------------
    -- 加载棋盘
    self.Maps = self:createMapTexture()

    -- 玩家
    self.userCards[USERSELF] = {}
    local cardTemp = {}
    cardTemp[USERSELF] = self:toTableM(cc.UserDefault:getInstance():getStringForKey("userCard"))
    if GameLayer.gameType == 1 then
        self:gameTypeOne()
    else
        self:gameTypeTwo()
    end
    for i = 1, #cardTemp[USERSELF] do
        local card = CardSprite:createCard(cardTemp[USERSELF][i], self.card_clone)
        local Pos = cc.p(self.Maps[self.initCardPos[USERSELF][i]].bg:getPositionX(), self.Maps[self.initCardPos[USERSELF][i]].bg:getPositionY())
        card.sp:setPosition(Pos)
        card.sp:addTo(self.layer)
        card.id = cardTemp[USERSELF][i]
        card.idx = self.initCardPos[USERSELF][i]
        card.sp:setVisible(false)
        card.isDeal = false
        card.isMove = false
         --待机
        card.btn_wait:addTouchEventListener(function(sender , event)
            if event == 2 then
                if MainScene.isOpenEffect then
                    AudioEngine.playEffect("majia/sound/click.mp3")
                end
                for j=1,#self.Maps do
                    self.Maps[j].move:setVisible(false)
                end
                card.btn_wait:setVisible(false)
                card.btn_attack:setVisible(false)
                card.box:loadTexture("majia/images/game/avatar_mask.png")
                card.isDeal = true
                self.dealCardCount = self.dealCardCount - 1
                if self.dealCardCount <= 0 then
                    --开始人机回合
                    self:dealRound(USERCOMPUTER)
                end
            end
        end)
        --攻击
        card.btn_attack:addTouchEventListener(function(sender , event)
            if event == 2 then
                if MainScene.isOpenEffect then
                    AudioEngine.playEffect("majia/sound/click.mp3")
                end
                card.btn_wait:setVisible(false)
                card.btn_attack:setVisible(false)
                --self.battCards[USERSELF][i].isDeal = true
                -- self.dealCardCount = self.dealCardCount - 1
                -- if self.dealCardCount <= 0 then
                --     --开始人机回合
                --     self:dealRound(USERCOMPUTER)
                -- end
                --显示攻击区域
                local card_pos = cc.p(card.sp:getPositionX(),card.sp:getPositionY() )
                local m_range = self:attackRange(card_pos, card.range)
                for k=1,#m_range do
                    self.Maps[m_range[k]].damage:setVisible(true)
                end
                for j=1,#self.Maps do
                    self.Maps[j].move:setVisible(false)
                end
                if #m_range >0 then
                    self:getAttackTarget(card, m_range)
                end
            end
        end)
        table.insert(self.battCards[USERSELF], card)
    end
    self.dealCardCount = #self.battCards[USERSELF]

    --机器人
    self.userCards[USERCOMPUTER] = {}
    cardTemp[USERCOMPUTER] = self:createRobot()
    for i = 1, #cardTemp[USERCOMPUTER] do
        local card = CardSprite:createCard(cardTemp[USERCOMPUTER][i], self.card_clone)
        local Pos = cc.p(self.Maps[self.initCardPos[USERCOMPUTER][i]].bg:getPositionX(), self.Maps[self.initCardPos[USERCOMPUTER][i]].bg:getPositionY())
        card.sp:setPosition(cc.p(Pos))
        card.sp:addTo(self.layer)
        card.id = cardTemp[USERCOMPUTER][i]
        card.idx = self.initCardPos[USERCOMPUTER][i]
        card.sp:setVisible(false)
        card.box:loadTexture("card_3_box_2.png", UI_TEX_TYPE_PLIST)
        table.insert(self.battCards[USERCOMPUTER], card)
    end

    --增加监听
    self:addEventListener()
end

--区分游戏模式
function GameLayer:gameTypeOne()
    local usercard = self:toTableM(cc.UserDefault:getInstance():getStringForKey("userCard"))
    for i=1,5 do
        if #usercard >= i then
            table.insert(self.initCardPos[USERSELF], (6-i) * 14 + 1)
        end
        table.insert(self.initCardPos[USERCOMPUTER], (7 - i) * 14)
    end

    for i=1,#usercard do
        performWithDelay(self,function()
            self:dealCards(self.initCardPos[USERSELF][i], USERSELF, i)
        end, i * 0.8)
    end

    performWithDelay(self,function()
        for i=1,5 do
            performWithDelay(self,function()
                self:dealCards(self.initCardPos[USERCOMPUTER][i], USERCOMPUTER, i)
            end, (i - 1) * 0.8)
        end
    end, 5)
    performWithDelay(self,function()
        self:dealRound(USERSELF)
        self.isPK = true
    end, 9)
end
function GameLayer:gameTypeTwo()
    local usercard = {}
    for i=1,5 do
        while true do
            local idx = math.random(1, 18)
            local isHave = false
            for j=1,#usercard do
                if usercard[j] == idx then
                    isHave = true
                end
            end
            if not isHave then
                table.insert(usercard, idx)
                break
            end
        end
    end
    -- local usercard = self:toTableM(cc.UserDefault:getInstance():getStringForKey("userCard"))
    local posTab = self:randomPos()
    for i=1,#posTab do
        if #usercard < i then
            table.insert(self.initCardPos[USERSELF], posTab[i])
        else
            table.insert(self.initCardPos[USERCOMPUTER], posTab[i])
        end
    end

    for i=1,#usercard do
        performWithDelay(self,function()
            self:dealCards(self.initCardPos[USERSELF][i], USERSELF, i)
        end, i * 0.8)
    end

    performWithDelay(self,function()
        for i=1,5 do
            performWithDelay(self,function()
                self:dealCards(self.initCardPos[USERCOMPUTER][i], USERCOMPUTER, i)
            end, (i - 1) * 0.8)
        end
    end, 5)

    performWithDelay(self,function()
        self.guessLayer:setVisible(true)
        self.coinback_90:setVisible(true)
    end, 9)
end

-- 创建地图
function GameLayer:createMapTexture()
    local pos = { x = 54, y = 110 }
    local Tmp = {}
    for i = 1, 7 do
        for j = 1, 14 do
            local sp = {}
            local posX = pos.x + (j - 1) * 79
            local posY = pos.y + (i - 1) * 79
            local spr_mps = cc.Sprite:createWithSpriteFrameName("bg_chip.png")
            spr_mps:setPosition(cc.p(posX, posY))
            spr_mps:addTo(self.layer)
            sp.bg = spr_mps
            local spr_mask = cc.Sprite:create("majia/images/game/mapMask.png")
            spr_mask:setPosition(cc.p(55,55))
            spr_mask:setAnchorPoint(cc.p(0.5,0.5))
            --spr_mask:setVisible(true)
            spr_mask:setVisible(false)
            spr_mask:addTo(spr_mps)
            sp.mask = spr_mask
            local spr_damage = cc.Sprite:createWithSpriteFrameName("redMask.png")
            spr_damage:setPosition(cc.p(39,41))
            spr_damage:setAnchorPoint(cc.p(0.5,0.5))
            spr_damage:setVisible(false)
            spr_damage:addTo(spr_mps)
            spr_damage:setScale(0.8)
            sp.damage = spr_damage

            local spr_move = cc.Sprite:createWithSpriteFrameName("blueMask.png")
            spr_move:setPosition(cc.p(39,41))
            spr_move:setAnchorPoint(cc.p(0.5,0.5))
            spr_move:setVisible(false)
            spr_move:addTo(spr_mps)
            spr_move:setScale(0.8)
            sp.move = spr_move
            -- 是否可以放置
            sp.can_place = false
            -- 是否存在道具
            sp.can_prop = false
            sp.idx = (i - 1) * 10 + j
            if j == 1 then
                spr_mask:setVisible(false)
            end
            table.insert(Tmp, sp)
        end
    end
    return Tmp
end

-- 开启监听
function GameLayer:addEventListener()
    local layerColor = CCLayerColor:create(ccc4(0,0,0,0),display.width, display.height)
    layerColor:setPosition(cc.p(0,0))
    layerColor:setAnchorPoint(cc.p(0,0))
    self.layer:addChild(layerColor)

    local currentCard = {}
    local mapTag = 1
    local isMove = false

    local function onTouchBegan( touch, event )
        currentCard = {}
        isMove = false
        if self.currentPlayer ~= USERSELF then return false end
        if self.isAnimTime then return false end
        if not self.isPK then return false end
        for i = 1, #self.Maps do
            local pos = touch:getLocation()
            local sender = self.Maps[i].bg
            pos = sender:convertToNodeSpace(pos)
            local rec = cc.rect(0, 0, sender:getContentSize().width, sender:getContentSize().height)
            if cc.rectContainsPoint(rec, pos) then
                mapTag = i
            end
        end
        --dump(self.curCard,"---------self.curCard")
        if self.curCard then
            local attackTar = 0
            for i=1,#self.curRange do
                local pos = touch:getLocation()
                local sender = self.Maps[self.curRange[i]].bg
                pos = sender:convertToNodeSpace(pos)
                local rec = cc.rect(0, 0, sender:getContentSize().width, sender:getContentSize().height)
                if cc.rectContainsPoint(rec, pos) then
                    attackTar = self.curRange[i]
                end
            end

            --攻击牌
            if self.curCard.recovery == 0 then
                --点击敌方卡牌进行攻击
                if attackTar ~= 0 then
                    for i=1,#self.battCards[USERCOMPUTER] do
                        if self.battCards[USERCOMPUTER][i].idx == attackTar then
                            local atk = self.curCard.damage
                            local hp = tonumber(self.battCards[USERCOMPUTER][i].text_hp:getString())
                            hp = hp - atk
                            self.battCards[USERCOMPUTER][i].text_hp:setString(hp)
                            self:attackAnimation(self.battCards[USERCOMPUTER][i])
                            for k=1,#self.curRange do
                                self.Maps[self.curRange[k]].damage:setVisible(false)
                            end
                            if hp <= 0 then
                                self.battCards[USERCOMPUTER][i].sp:removeFromParent()
                                table.remove(self.battCards[USERCOMPUTER], i)
                                self.Maps[attackTar].mask:setVisible(false)
                                self.Maps[attackTar].can_prop = false
                            end
                            local isOver = self:isOver()
                            if isOver then
                                self:doOver()
                                return
                            end
                            self.curCard.isDeal = true
                            self.curCard.box:loadTexture("majia/images/game/avatar_mask.png")
                            self.dealCardCount = self.dealCardCount - 1
                            if self.dealCardCount <= 0 then
                                --开始人机回合
                                self:dealRound(USERCOMPUTER)
                            end
                            self.curCard = nil
                            break
                        end
                    end

                    --攻击道具
                    for i=1,#self.props do
                        if self.props[i].idx == attackTar then
                            self.curCard.isDeal = true
                            self.curCard.box:loadTexture("majia/images/game/avatar_mask.png")
                            self.dealCardCount = self.dealCardCount - 1

                            local isHouse = false

                            local atk = self.curCard.damage
                            local hp = tonumber(self.props[i].text_hp:getString())
                            hp = hp - atk
                            self.props[i].text_hp:setString(hp)
                            self:attackAnimation(self.props[i])
                            for k=1,#self.curRange do
                                self.Maps[self.curRange[k]].damage:setVisible(false)
                            end
                            if hp <= 0 then
                                --使用道具
                                if self.props[i].id == 1 or self.props[i].id == 3 or self.props[i].id == 5 then       --绷带    药水    医疗箱
                                    self.curCard.text_hp:setString(tonumber(self.curCard.text_hp:getString() + self.propData[self.props[i].id].num))
                                elseif self.props[i].id == 2 or self.props[i].id == 4 or self.props[i].id == 6 then   --磨刀石  锻造锤  兴奋剂
                                    self.curCard.damage = self.curCard.damage + self.propData[self.props[i].id].num
                                    self.curCard.text_att:setString(tonumber(self.curCard.text_att:getString() + self.propData[self.props[i].id].num))
                                elseif self.props[i].id == 7 then   --战马
                                    self.curCard.isDeal = false
                                    self.curCard.box:loadTexture("card_3_box_1.png", UI_TEX_TYPE_PLIST)
                                    self.dealCardCount = self.dealCardCount + 1
                                    isHouse = true
                                end
                                self.props[i].sp:removeFromParent()
                                table.remove(self.props, i)
                                self.Maps[attackTar].mask:setVisible(false)
                            end
                            if self.dealCardCount <= 0 then
                                --开始人机回合
                                self:dealRound(USERCOMPUTER)
                            end
                            -- if not isHouse then
                            self.curCard = nil
                            -- else
                            --     return
                            -- end
                            break
                        end
                    end
                end
            else
                -- 加血牌
                if attackTar ~= 0 then
                    for i=1,#self.battCards[USERSELF] do
                        if self.battCards[USERSELF][i].idx == attackTar then
                            local atk = self.curCard.recovery
                            local hp = tonumber(self.battCards[USERSELF][i].text_hp:getString())
                            local oldHp = hp
                            hp = hp + atk
                            local data = CardSprite:getSpriteD(self.battCards[USERSELF][i].id)
                            if hp > data.blood then
                                hp = data.blood
                            end
                            self.battCards[USERSELF][i].text_hp:setString(hp)
                            self:upDataBloodAdd(self.battCards[USERSELF][i].sp, hp - oldHp)
                            for k=1,#self.curRange do
                                self.Maps[self.curRange[k]].damage:setVisible(false)
                            end
                            
                            self.dealCardCount = self.dealCardCount - 1
                            self.curCard.isDeal = true
                            self.curCard.isMove = true
                            self.curCard = nil
                            return
                        end
                    end
                end
            end
        end

        -- 移动棋盘上的卡牌
        for i = 1, #self.battCards[USERSELF] do
            self.battCards[USERSELF][i].btn_wait:setVisible(false)
            self.battCards[USERSELF][i].btn_attack:setVisible(false)
            self.battCards[USERSELF][i].sp:setLocalZOrder(1)
        end
        for i = 1, #self.battCards[USERSELF] do
            local pos = touch:getLocation()
            local sender = self.battCards[USERSELF][i].sp
            pos = sender:convertToNodeSpace(pos)
            local rec = cc.rect(0, 0, sender:getContentSize().width, sender:getContentSize().height)
            if cc.rectContainsPoint(rec, pos) then
                --此卡牌是否处理过
                if self.battCards[USERSELF][i].isDeal then
                    return false
                end
                currentCard.ID = i
                currentCard.lZO = self.battCards[USERSELF][i].sp:getLocalZOrder()
                currentCard.Pos = cc.p(self.battCards[USERSELF][i].sp:getPositionX(),self.battCards[USERSELF][i].sp:getPositionY())
                currentCard.isNew = false
                currentCard.idx = self.battCards[USERSELF][i].idx
                currentCard.move = self.battCards[USERSELF][i].move
                currentCard.card = self.battCards[USERSELF][i]
                currentCard.card.sp:setLocalZOrder(100)
                self:checkAttack(currentCard, mapTag)
                if self.battCards[USERSELF][i].isMove then
                    return false
                end
                self:setPlaceRange(currentCard.Pos, currentCard.move, currentCard.idx)
                return true
            end
        end
        return false
    end

    local function onTouchMoved(touch, event)
        local pos  = touch:getLocation()
        --获取移动的距离
        local distance = cc.pGetDistance(pos,currentCard.Pos)
        if distance >= 20 then
            isMove = true
        end
        currentCard.card.sp:setPosition(cc.p(touch:getLocation().x, touch:getLocation().y))
        currentCard.card.btn_wait:setPositionX(self.initPos[1])
        currentCard.card.btn_attack:setPositionX(self.initPos[2])
        currentCard.card.btn_wait:setVisible(false)
        currentCard.card.btn_attack:setVisible(false)
        if touch:getLocation().y > 200 then
            CardSprite:setSprite(currentCard.card)
        else
            CardSprite:setSpriteD(currentCard.card)
        end
    end

    local function onTouchEnded( touch, event )
        for i = 1, #self.Maps do
            local pos = touch:getLocation()
            local sender = self.Maps[i].bg
            pos = sender:convertToNodeSpace(pos)
            local rec = cc.rect(0, 0, sender:getContentSize().width, sender:getContentSize().height)
            if cc.rectContainsPoint(rec, pos) and self.Maps[i].can_place and not self.Maps[i].can_prop then
                if self.Maps[i].mask:isVisible() then break end
                self.Maps[i].can_place = false
                self.Maps[i].can_prop = true
                self.Maps[currentCard.idx].can_prop = false
                -- 来自棋盘移动
                if currentCard.isNew == false then
                    --self.Maps[currentCard.idx].can_place = true
                    self.battCards[USERSELF][currentCard.ID].idx = i
                    self:setPlaceMapUI(currentCard.card,self.Maps[i])
                end
                for j=1,#self.Maps do
                    self.Maps[j].move:setVisible(false)
                end
                self.Maps[mapTag].mask:setVisible(false)
                self.Maps[i].mask:setVisible(true)
                if isMove then
                    self.battCards[USERSELF][currentCard.ID].isMove = true
                end
                currentCard.card.sp:setLocalZOrder(currentCard.lZO)
                self:checkAttack(currentCard, i)
                if MainScene.isOpenEffect then
                    AudioEngine.playEffect("majia/sound/flip.mp3")
                end
                return
            end
        end
        if currentCard.isNew then
             CardSprite:setSpriteD(currentCard.card)
        else
            CardSprite:setSprite(currentCard.card)
        end
        currentCard.card.sp:setPosition(currentCard.Pos)
        currentCard.card.sp:setLocalZOrder(100)
        if isMove then
            currentCard.card.btn_wait:setVisible(false)
            currentCard.card.btn_attack:setVisible(false)
            for i=1,#self.Maps do
                self.Maps[i].move:setVisible(false)
            end
            currentCard.card.sp:setLocalZOrder(currentCard.lZO)
        end
        currentCard = {}
        isMove = false
    end

    local listener1 = cc.EventListenerTouchOneByOne:create()  --创建一个单点事件监听
    listener1:setSwallowTouches(true)  --是否向下传递
    listener1:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    listener1:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
    listener1:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
    local eventDispatcher = layerColor:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener1, layerColor) --分发监听事件
end

--发牌
function GameLayer:dealCards(scend, type, idx)
    if not cc.SpriteFrameCache:getInstance():isSpriteFramesWithFileLoaded("majia/images/game/borken_ui.plist") then
        cc.SpriteFrameCache:getInstance():addSpriteFrames("majia/images/game/borken_ui.plist")
    end
    self.Maps[scend].mask:setVisible(true)
    self.Maps[scend].can_prop = true
    local Pos = cc.p(self.Maps[scend].bg:getPositionX(), self.Maps[scend].bg:getPositionY())
    local spriteFrame = cc.SpriteFrameCache:getInstance()

    local spriteTest = cc.Sprite:createWithSpriteFrameName("broken_1.png")
    spriteTest:setAnchorPoint( 0.5, 0.5 )
    spriteTest:setPosition( Pos )
    self.loadNode:addChild( spriteTest )

    local animation = cc.Animation:create()
    for i=1, 4 do
        local blinkFrame = spriteFrame:getSpriteFrame("broken_" .. i .. ".png")
        animation:addSpriteFrame( blinkFrame )
    end

    animation:setDelayPerUnit( 0.1 )--设置每帧的播放间隔
    animation:setRestoreOriginalFrame( false )--设置播放完成后是否回归最初状态
    animation:setLoops(1)
    local action = cc.Animate:create(animation)
    local action2 = cc.CallFunc:create(function()
        spriteTest:removeFromParent()
        local index
        if type == 1 then
            index = 6 - (scend - 1) / 14
        else
            index = 7 - scend / 14
        end
        local card = self.battCards[type][idx]
        if card then
            card.sp:setVisible(true)
            card.sp:setScale(0.3)
            local act = cc.ScaleTo:create(0.1, 1)
            card.sp:runAction(cc.Sequence:create(act))
        end
    end)
    spriteTest:runAction(cc.Sequence:create(action, action2))
    spriteTest:setScale(0.7)
    if MainScene.isOpenEffect then
        AudioEngine.playEffect("majia/sound/wall_broken.mp3")
    end
end

-- 猜先手
function GameLayer:guessFirstAnimation(num)
    local number = math.random(1, 2)
    if num == number then
        self.currentPlayer = USERSELF
    else
        self.currentPlayer = USERCOMPUTER
    end

    local filename = {"obcerse.png", "Coinback.png"}
    local spriteFrame = cc.SpriteFrameCache:getInstance()
    spriteFrame:addSpriteFrames("majia/images/game/gold.plist" )

    local spriteTest = cc.Sprite:createWithSpriteFrameName("00000.png")
    spriteTest:setAnchorPoint( 0.5, 0.5 )
    spriteTest:setPosition( cc.p( 600, display.cy ) )
    self.loadNode:addChild( spriteTest )

    local animation = cc.Animation:create()
    for i=1, 24 do
        local blinkFrame = spriteFrame:getSpriteFrame( string.format( "000%02d.png", i ) )
        animation:addSpriteFrame( blinkFrame )
    end
    animation:addSpriteFrame(spriteFrame:getSpriteFrame(filename[number]))
    animation:setDelayPerUnit( 0.05 )--设置每帧的播放间隔
    animation:setRestoreOriginalFrame( false )--设置播放完成后是否回归最初状态
    animation:setLoops(1)
    local action = cc.Animate:create(animation)
    spriteTest:runAction(cc.Sequence:create( cc.Repeat:create( action, 1 ), cc.DelayTime:create(2),cc.CallFunc:create(function()
        spriteTest:removeFromParent()
        self.guessLayer:setVisible(false)
        self:dealRound(self.currentPlayer)
        self.isPK = true
    end)) )
end

--攻击动画
function GameLayer:attackAnimation(scend)
    if not cc.SpriteFrameCache:getInstance():isSpriteFramesWithFileLoaded("majia/images/game/attck.plist") then
        cc.SpriteFrameCache:getInstance():addSpriteFrames("majia/images/game/attck.plist")
    end
    local Pos = cc.p(self.Maps[scend.idx].bg:getPositionX(), self.Maps[scend.idx].bg:getPositionY())
    local spriteFrame = cc.SpriteFrameCache:getInstance()
    local spriteTest = cc.Sprite:createWithSpriteFrameName("1.png")
    spriteTest:setAnchorPoint( 0.5, 0.5 )
    spriteTest:setPosition( Pos )
    self.loadNode:addChild( spriteTest )

    local animation = cc.Animation:create()
    for i=1, 4 do
        local blinkFrame = spriteFrame:getSpriteFrame( string.format( "%d.png", i ) )
        animation:addSpriteFrame( blinkFrame )
    end

    animation:setDelayPerUnit( 0.1 )--设置每帧的播放间隔
    animation:setRestoreOriginalFrame( false )--设置播放完成后是否回归最初状态
    animation:setLoops(1)
    local action = cc.Animate:create(animation)
    spriteTest:setScale(0.6)

    if self.currentPlayer == USERCOMPUTER then
        spriteTest:setFlipX(true)
    end
    spriteTest:runAction(cc.Sequence:create(
    cc.Repeat:create( action, 1 ), cc.DelayTime:create(0.3),cc.CallFunc:create(function()
        spriteTest:removeFromParent()
    end)) )
    if MainScene.isOpenEffect then
        AudioEngine.playEffect("majia/sound/attack.mp3")
    end
end

-- 放置置棋盘
function GameLayer:setPlaceMapUI(scend, map)
    if self.currentPlayer == USERSELF then
        scend.sp:setPosition(cc.p(map.bg:getPositionX(), map.bg:getPositionY()))
    else
        scend.sp:runAction(cc.MoveTo:create(0.2, cc.p(map.bg:getPositionX(), map.bg:getPositionY())))
    end

    map.can_place = false
    return true
end

-- 回血
function GameLayer:upDataBloodAdd(target, recovery)
    local txt = cc.Label:createWithTTF("+"..recovery, "majia/font/font.ttf", 24)
    txt:setPosition(cc.p(50, 43))
    txt:addTo(target)
    txt:setColor(cc.c3b(0x00, 0xF9, 0x00))
    txt:runAction(cc.Sequence:create(
        cc.MoveTo:create(0.5, cc.p(txt:getPositionX(), 55)),
        cc.CallFunc:create(function()
        txt:removeFromParent()
        end)
    ))
    if MainScene.isOpenEffect then
        AudioEngine.playEffect("majia/sound/life_recovery.mp3")
    end
end

-- 计算可放置范围
function GameLayer:setPlaceRange(pos, moveCount, val)
    if pos == nil or moveCount == nil then
        return
    end
    for i=1,#self.Maps do
        self.Maps[i].move:setVisible(false)
        self.Maps[i].damage:setVisible(false)
        self.Maps[i].can_place = false
    end

    for i = 1, #self.Maps do
        local pos = pos
        local sender = self.Maps[i].bg
        pos = sender:convertToNodeSpace(pos)
        local rec = cc.rect(0, 0, sender:getContentSize().width, sender:getContentSize().height)
        if cc.rectContainsPoint(rec, pos) then
            local numTop = i + moveCount * 14
            local count = 0
            for j = 1,  moveCount * 2 + 1, 2 do
                for k = 1, j do
                    local int = math.floor((numTop + count) / 14) * 14 + 1
                    if (numTop + count) % 14 == 0 then
                        int = int - 14
                    end
                    if (numTop + k - 1) >= int and (numTop + k - 1) <= (int + 13) then
                        -- 正尖头
                        if int <= 98 and int > 0 then
                            --除去自身位置
                            if numTop + k - 1 ~= val then
                                self.Maps[numTop + k - 1].move:setVisible(true)
                                self.Maps[numTop + k - 1].can_place = true
                            end
                        end
                        -- 反尖头
                        if (numTop + k - 1) - (moveCount - count) * 28 > 0 then
                            --除去自身位置
                            if numTop + k - 1 ~= val then
                                self.Maps[(numTop + k - 1) - (moveCount - count) * 28].move:setVisible(true)
                                self.Maps[(numTop + k - 1) - (moveCount - count) * 28].can_place = true
                            end
                        end
                    end
                end
                count = count + 1
                numTop = numTop - 15
            end
        end
    end
end

-- 随机位置
function GameLayer:randomPos()
    local idxTable = {}
    local usercard = self:toTableM(cc.UserDefault:getInstance():getStringForKey("userCard"))
    local len = #usercard + 5
    for i=1,len do
        while true do
            local idx = math.random(1, 7 * 14)
            local isHave = false
            for j=1,#idxTable do
                if idxTable[j] == idx then
                    isHave = true
                end
            end
            if not isHave then
                table.insert(idxTable, idx)
                break
            end
        end
    end
    return idxTable
end
-- --------------------------------------------------------------机器人操作---------------------------------------------
-- 创建机器人卡牌
function GameLayer:createRobot()
    if GameLayer.gameType == 2 then
        local idxTable = {}
        for i=1,5 do
            while true do
                local idx = math.random(1, 18)
                local isHave = false
                for j=1,#idxTable do
                    if idxTable[j] == idx then
                        isHave = true
                    end
                end
                if not isHave then
                    table.insert(idxTable, idx)
                    break
                end
            end
        end
        return idxTable
    else
        local levelCount = cc.UserDefault:getInstance():getIntegerForKey("levelCount") + 1
        local idxTable = CardSprite:getLevelData()
        return idxTable[levelCount]
    end
end

--机器人处理卡牌
function GameLayer:robotDeal(idx)
    local card = self.battCards[USERCOMPUTER][idx]
    local pos = cc.p(card.sp:getPositionX(),card.sp:getPositionY())
    local attRange = card.range
    local moveRange = card.move
    local m_range_att = self:attackRange(pos, attRange)

    --计算牌的攻击范围
    local m_attack = {}
    local types = card.recovery == 0 and 1 or 2
    local checkFunc = function ()
        for i=1,#m_range_att do
            for j=1,#self.battCards[types] do
                local my_idx = self.battCards[types][j].idx
                if m_range_att[i] == my_idx then
                    table.insert(m_attack, my_idx)
                end
            end
        end
    end
    checkFunc()

    local val = 1
    while val <= #m_attack do
        if m_attack[val] == card.idx then
            table.remove(m_attack, val)
        else
            val = val + 1
        end
    end

    local attackFunc = function ()
        local rand_tar = m_attack[math.random(1, #m_attack)]
        if card.recovery == 0 then
            for i=1,#self.battCards[USERSELF] do
                if self.battCards[USERSELF][i].idx == rand_tar then
                    local atk = card.damage
                    local hp = tonumber(self.battCards[USERSELF][i].text_hp:getString())
                    hp = hp - atk
                    self.battCards[USERSELF][i].text_hp:setString(hp)
                    self:attackAnimation(self.battCards[USERSELF][i])
                    if hp <= 0 then
                        self.battCards[USERSELF][i].sp:removeFromParent()
                        self.Maps[self.battCards[USERSELF][i].idx].mask:setVisible(false)
                        self.Maps[self.battCards[USERSELF][i].idx].can_place = false
                        self.Maps[self.battCards[USERSELF][i].idx].can_prop = false
                        table.remove(self.battCards[USERSELF], i)
                    end
                    break
                end
            end
            local isOver = self:isOver()
            if isOver then
                performWithDelay(self,function()
                    self:doOver()
                end, 1)
                return
            end
        else
            for i=1,#self.battCards[USERCOMPUTER] do
                if self.battCards[USERCOMPUTER][i].idx == rand_tar then
                    local atk = card.recovery
                    local hp = tonumber(self.battCards[USERCOMPUTER][i].text_hp:getString())
                    local oldHp = hp
                    hp = hp + atk
                    local data = CardSprite:getSpriteD(self.battCards[USERCOMPUTER][i].id)
                    if hp > data.blood then
                        hp = data.blood
                    end
                    self.battCards[USERCOMPUTER][i].text_hp:setString(hp)
                    self:upDataBloodAdd(self.battCards[USERCOMPUTER][i].sp, hp - oldHp)
                end
            end
        end

        if idx < #self.battCards[USERCOMPUTER] then
            performWithDelay(self,function()
                self:robotDeal(idx + 1)
            end, 1)
            card.box:loadTexture("majia/images/game/avatar_mask.png")
        else
            --玩家回合
            self:dealRound(USERSELF)
        end
    end

    --攻击范围内是否有牌
    if #m_attack > 0 then
        --有牌
        attackFunc()
    else
        --无牌
        --是否待机
        local isStand = self:robotIsStand()
        if not isStand then
            --计算牌的可移动范围
            local m_range_move = self:moveRange(pos, moveRange)
            --从范围中筛选掉己方卡牌和敌方卡牌的位置    包括道具的位置
            for i=1,#self.battCards[USERCOMPUTER] do
                local len = #m_range_move
                for j=1,len do
                    if m_range_move[j] == self.battCards[USERCOMPUTER][i].idx then
                        table.remove(m_range_move, j)
                    end
                end
                len = #m_range_move
                for j=1,len do
                    if m_range_move[j] == self.battCards[USERCOMPUTER][i].idx then
                        table.remove(m_range_move, j)
                    end
                end
            end
            for i=1,#self.battCards[USERSELF] do
                local len = #m_range_move
                for j=1,len do
                    if m_range_move[j] == self.battCards[USERSELF][i].idx then
                        table.remove(m_range_move, j)
                    end
                end
                len = #m_range_move
                for j=1,len do
                    if m_range_move[j] == self.battCards[USERSELF][i].idx then
                        table.remove(m_range_move, j)
                    end
                end
            end
            for i=1,#self.props do
                local len = #m_range_move
                for j=1,len do
                    if m_range_move[j] == self.props[i].idx then
                        table.remove(m_range_move, j)
                    end
                end
                len = #m_range_move
                for j=1,len do
                    if m_range_move[j] == self.props[i].idx then
                        table.remove(m_range_move, j)
                    end
                end
            end
            --随机出一个位置进行移动
            self.Maps[card.idx].mask:setVisible(false)
            self.Maps[card.idx].can_prop = false
            local movetoPos = m_range_move[math.random(1, #m_range_move)]
            card.idx = movetoPos
            self:robotMoveCard(card, movetoPos)
            --移动结束后再次判断攻击范围内是否有牌
            m_attack = {}
            local newPos = cc.p(self.Maps[movetoPos].bg:getPositionX(),self.Maps[movetoPos].bg:getPositionY())
            m_range_att = self:attackRange(newPos, attRange)
            checkFunc()
            if #m_attack > 0 then
                --有牌  攻击
                performWithDelay(self,function()
                    attackFunc()
                end, 1)
                card.box:loadTexture("majia/images/game/avatar_mask.png")
            else
                --无牌  待机
                performWithDelay(self,function()
                    self:playAnim("TipsNode", card.sp, 0.5)
                end, 0.5)
                if idx < #self.battCards[USERCOMPUTER] then
                    performWithDelay(self,function()
                        self:robotDeal(idx + 1)
                    end, 2)
                    card.box:loadTexture("majia/images/game/avatar_mask.png")
                else
                    --玩家回合
                    self:dealRound(USERSELF)
                end
            end
        else
            self:playAnim("TipsNode", card.sp, 0.5)
            card.box:loadTexture("majia/images/game/avatar_mask.png")
            --进行下一张牌处理
            if idx < #self.battCards[USERCOMPUTER] then
                performWithDelay(self,function()
                    self:robotDeal(idx + 1)
                end, 2)
            else
                --玩家回合
                self:dealRound(USERSELF)
            end
        end
    end
end

--机器人是否待机
function GameLayer:robotIsStand()
    local rand = math.random(1, 10) / 10
    --百分之三十概率待机   百分之七十移动
    if rand > 0.7 then
        return true
    else
        return false
    end
end


--机器人移动卡牌
function GameLayer:robotMoveCard(card, idx)
    local oldZorder = card.sp:getLocalZOrder()
    card.sp:setLocalZOrder(100)
    local pos = cc.p(self.Maps[idx].bg:getPositionX(),self.Maps[idx].bg:getPositionY())
    local action1 = cc.MoveTo:create(0.3, pos)
    local action2 = cc.CallFunc:create(function ()
        card.sp:setLocalZOrder(oldZorder)
        self.Maps[idx].mask:setVisible(true)
    end)
    card.sp:runAction(cc.Sequence:create(action1, action2))
    card.idx = idx
end

-- --------------------------------------------------------------机器人操作---------------------------------------------
--检测攻击并微调按钮
function GameLayer:checkAttack(target, idx)
    target.card.btn_wait:setVisible(true)
    target.card.btn_attack:setVisible(true)
    --功能按钮位置微调
    if idx % 14 == 1 then
        target.card.btn_wait:setPositionX(self.initPos[1] + 40)
        target.card.btn_attack:setPositionX(self.initPos[2] + 40)
    elseif idx % 14 == 0 then
        target.card.btn_wait:setPositionX(self.initPos[1] - 40)
        target.card.btn_attack:setPositionX(self.initPos[2] - 40)
    else
        target.card.btn_wait:setPositionX(self.initPos[1])
        target.card.btn_attack:setPositionX(self.initPos[2])
    end
    if idx > 84 then
        target.card.btn_wait:setPositionY(self.initPosY - 50)
        target.card.btn_wait:setLocalZOrder(1)
        target.card.btn_attack:setPositionY(self.initPosY - 50)
        target.card.btn_attack:setLocalZOrder(1)
    else
        target.card.btn_wait:setPositionY(self.initPosY)
        target.card.btn_attack:setPositionY(self.initPosY)
    end
    --攻击牌则判断攻击范围内是否有敌方卡牌  加血牌则判断攻击范围内是否有己方卡牌
    local pos = cc.p(target.card.sp:getPositionX(), target.card.sp:getPositionY())
    local m_range = self:attackRange(pos, target.card.range)
    local m_attack = {}
    local types = target.card.recovery == 0 and 2 or 1
    for k=1,#m_range do
        for j=1,#self.battCards[types] do
            local enemy_idx = self.battCards[types][j].idx
            if m_range[k] == enemy_idx then
                table.insert(m_attack, enemy_idx)
            end
        end
    end

    --增加范围内道具判断
    for k=1,#m_range do
        for i=1,#self.props do
            local prop_idx = self.props[i].idx
            if m_range[k] == prop_idx then
                table.insert(m_attack, prop_idx)
            end
        end
    end

    if #m_attack == 0 then
        target.card.btn_attack:setEnabled(false)
    else
        target.card.btn_attack:setEnabled(true)
    end
end

--回合判定
function GameLayer:dealRound(idx)
    self.currentPlayer = idx
    self.isAnimTime = true
    self.text_round:setVisible(false)
    self.btn_end:setVisible(false)
    if self.currentPlayer == USERSELF then
        --玩家回合
        local func = function ()
            self.dealCardCount = #self.battCards[USERSELF]
            self.text_round:setVisible(true)
            self.btn_end:setVisible(true)
            self.text_round:setString("My Round")
        end
        performWithDelay(self,function()
            self:playAnim("TipsRoundNode", self.layer, 2, func)
        end, 1)
    else
        --人机回合
        local func = function ()
            self:robotDeal(1)
            self.btn_end:setVisible(false)
            self.text_round:setVisible(true)
            self.text_round:setString("Enemy Round")
        end
        performWithDelay(self,function()
            self:playAnim("TipsRoundNode", self.layer, 2, func)
        end, 1)
    end
    self.roundCount = self.roundCount + 1
    if self.roundCount == 5 then
        performWithDelay(self,function()
            self:createProp()
            self.roundCount = 0
        end, 1)
    end

    self:resetCardData()
end

--生成道具
function GameLayer:createProp()
    if not cc.SpriteFrameCache:getInstance():isSpriteFramesWithFileLoaded("majia/images/game_ui.plist") then
        cc.SpriteFrameCache:getInstance():addSpriteFrames("majia/images/game_ui.plist")
    end
    local tab_num = {}
    for i=1,#self.Maps do
        if not self.Maps[i].can_prop then
            table.insert(tab_num, i)
        end
    end
    local num = tab_num[math.random(1, #tab_num)]
    local prop = {}
    local rand = math.random(1, 6)
    local propData = self.propData
    prop.sp = self.prop_clone:clone()
    prop.sp:loadTexture("prop_" .. rand .. ".png", UI_TEX_TYPE_PLIST)
    prop.sp:setPosition(self.Maps[num].bg:getPosition())
    prop.sp:addTo(self.layer)
    prop.text_hp = prop.sp:getChildByName("text_hp")
    prop.text_hp:setString(propData[rand].blood)
    prop.idx = num
    prop.id = rand
    self.Maps[num].can_prop = true

    table.insert(self.props, prop)

    if MainScene.isOpenEffect then
        AudioEngine.playEffect("majia/sound/props_appear.mp3")
    end
end

--获取卡牌攻击范围
function GameLayer:attackRange(pos, range)
    local m_range = {}
    for i = 1, #self.Maps do
        local pos = pos
        local sender = self.Maps[i].bg
        pos = sender:convertToNodeSpace(pos)
        local rec = cc.rect(0, 0, sender:getContentSize().width, sender:getContentSize().height)
        if cc.rectContainsPoint(rec, pos) then
            local numTop = i + range * 14
            local count = 0
            for j = 1,  range * 2 + 1, 2 do
                for k = 1, j do
                    local int = math.floor((numTop + count) / 14) * 14 + 1
                    if (numTop + count) % 14 == 0 then
                        int = int - 14
                    end
                    if (numTop + k - 1) >= int and (numTop + k - 1) <= (int + 13) then
                        -- 正尖头
                        if int <= 98 and int > 0 then
                            table.insert(m_range, numTop + k - 1)
                        end
                        -- 反尖头
                        if (numTop + k - 1) - (range - count) * 28 > 0 then
                            table.insert(m_range, (numTop + k - 1) - (range - count) * 28)
                        end
                    end
                end
                count = count + 1
                numTop = numTop - 15
            end
        end
    end

    --攻击范围3 特殊处理  2-1
    if range == 3 then
        local m_range_1 = self:attackRange(pos, 1)
        local m_range_2 = self:attackRange(pos, 2)
        for i=1, #m_range_2 do
            for j=1, #m_range_1 do
                if m_range_2[i] == m_range_1[j] then
                    table.remove(m_range_2, i)
                end
            end
        end
        return m_range_2
    end

    return m_range
end

--获取卡牌移动范围
function GameLayer:moveRange(pos, range)
    local m_range = {}
    for i = 1, #self.Maps do
        local pos = pos
        local sender = self.Maps[i].bg
        pos = sender:convertToNodeSpace(pos)
        local rec = cc.rect(0, 0, sender:getContentSize().width, sender:getContentSize().height)
        if cc.rectContainsPoint(rec, pos) then
            local numTop = i + range * 14
            local count = 0
            for j = 1,  range * 2 + 1, 2 do
                for k = 1, j do
                    local int = math.floor((numTop + count) / 14) * 14 + 1
                    if (numTop + count) % 14 == 0 then
                        int = int - 14
                    end
                    if (numTop + k - 1) >= int and (numTop + k - 1) <= (int + 13) then
                        -- 正尖头
                        if int <= 98 and int > 0 then
                            table.insert(m_range, numTop + k - 1)
                        end
                        -- 反尖头
                        if (numTop + k - 1) - (range - count) * 28 > 0 then
                            table.insert(m_range, (numTop + k - 1) - (range - count) * 28)
                        end
                    end
                end
                count = count + 1
                numTop = numTop - 15
            end
        end
    end
    return m_range
end

--卡牌获取攻击目标
function GameLayer:getAttackTarget(target, m_range)
    self.curCard = target
    self.curRange = m_range
end

--播放动画
function GameLayer:playAnim(str, target, time, func)
    local node = cc.CSLoader:createNode("majia/" .. str .. ".csb")
    local antAction = cc.CSLoader:createTimeline("majia/" .. str .. ".csb")
    node:runAction(antAction)
    antAction:gotoFrameAndPlay(0,false)
    self.layer:addChild(node,100)
    node:setPosition(cc.p(target:getPositionX(), target:getPositionY()))

    if str == "TipsRoundNode" then
        --local delta = 0.6
        if self.currentPlayer == USERCOMPUTER then
           local text_round = node:getChildByName("text_round")
           text_round:setString("Enemy Round")
           text_round:enableOutline(cc.c4b(255, 0, 0, 255), 2)
           delta = 0
        end
        -- performWithDelay(self,function()
        --     if MainScene.isOpenEffect then
        --         AudioEngine.playEffect("majia/sound/crush.mp3")
        --     end
        -- end, time - delta)
    end
    performWithDelay(self,function()
        node:removeFromParent(true)
        self.isAnimTime = false
        if func then
            func()
        end
    end, time)
end

--每回合结束重置卡牌数据
function GameLayer:resetCardData()
    for i=1,#self.battCards[USERSELF] do
        self.battCards[USERSELF][i].isDeal = false
        self.battCards[USERSELF][i].isMove = false
        self.battCards[USERSELF][i].box:loadTexture("card_3_box_1.png", UI_TEX_TYPE_PLIST)
    end
    for i=1,#self.battCards[USERCOMPUTER] do
        self.battCards[USERCOMPUTER][i].box:loadTexture("card_3_box_2.png", UI_TEX_TYPE_PLIST)
    end
end

--判定对局是否结束
function GameLayer:isOver()
    if #self.battCards[USERSELF] == 0 or #self.battCards[USERCOMPUTER] == 0 then
       return true
    end
    return false
end

--对局结算
function GameLayer:doOver()
    if not cc.SpriteFrameCache:getInstance():isSpriteFramesWithFileLoaded("majia/images/game_ui.plist") then
        cc.SpriteFrameCache:getInstance():addSpriteFrames("majia/images/game_ui.plist")
    end
    self.endLayer:setVisible(true)

    local text_coin = self.endLayer:getChildByName("text_coin")
    if #self.battCards[USERSELF] == 0 then
        local end_bg = self.endLayer:getChildByName("bg")
        end_bg:loadTexture("bg_lose.png", UI_TEX_TYPE_PLIST)
        text_coin:setString(0)
        self.btn_find:loadTextures("btn_end.png","","btn_end.png", UI_TEX_TYPE_PLIST)
        if MainScene.isOpenEffect then
            AudioEngine.playEffect("majia/sound/fail.mp3")
        end
    else
        local coin = 0
        for i=1,#self.battCards[USERSELF] do
            coin = coin + tonumber(self.battCards[USERSELF][i].text_hp:getString())
        end
        text_coin:setString(coin)
        local data_coin = cc.UserDefault:getInstance():getIntegerForKey("myMoney")
        cc.UserDefault:getInstance():setIntegerForKey("myMoney", data_coin + coin)
        if GameLayer.gameType == 1 then
            self.btn_find:loadTextures("btn_next.png","","btn_next.png", UI_TEX_TYPE_PLIST)
            local levelCount = cc.UserDefault:getInstance():getIntegerForKey("levelCount")
            cc.UserDefault:getInstance():setIntegerForKey("levelCount", levelCount+1)
            cc.UserDefault:getInstance():setIntegerForKey("biglevelCount", math.ceil(levelCount+1))
        end
        if MainScene.isOpenEffect then
            AudioEngine.playEffect("majia/sound/success.mp3")
        end
    end
end

function GameLayer:onExit()

end

return GameLayer