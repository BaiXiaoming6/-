require "app.majia.ShopLayer"
require "app.majia.CardsLayer"
require "app.majia.BigLevelLayer"
require "app.majia.LevelLayer"
MainScene = class("MainScene", function()
    return cc.Scene:create()
end)

MainScene.isOpenMusic = false
MainScene.isOpenEffect = false

function MainScene:ctor()
   -- 入场卡组
   self.userCard = {"qiangbing", "dunbing", "qibing", "zhongjiabing"}
end

function MainScene:onExit( )

end

function MainScene:create()
    local layer = MainScene.new()
    layer:init()
    return layer
end

--返回该类名称
function MainScene:getClassName()
    return "MainScene"
end

function MainScene:init()
    -- 是否是第一次登陆
    if not cc.UserDefault:getInstance():getBoolForKey("noviceguidance", false) then
        cc.UserDefault:getInstance():setIntegerForKey("myMoney", 0)
        cc.UserDefault:getInstance():setIntegerForKey("cardCount", 5)
        cc.UserDefault:getInstance():setStringForKey("userCard", '1,2,3,4,5')
        cc.UserDefault:getInstance():setBoolForKey("noviceguidance", true)
        cc.UserDefault:getInstance():setIntegerForKey("levelCount", 0)
        cc.UserDefault:getInstance():setIntegerForKey("biglevelCount", 1)
    end

    self.loadNode = cc.CSLoader:createNode("majia/MainScene.csb")
    self.loadNode:setContentSize(cc.size(display.size.height, display.size.width))
    ccui.Helper:doLayout(self.loadNode)
    self:addChild(self.loadNode, 0)

    local layer =  self.loadNode:getChildByName("Panel_main")
    local scX = display.width/layer:getContentSize().width
    local scY = display.height/layer:getContentSize().height
    layer:setScaleX(scX)
    layer:setScaleY(scY)

    local layer_rule = self.loadNode:getChildByName("Panel_rule")
    layer_rule:setScaleX(scX)
    layer_rule:setScaleY(scY)

    local btn_music = layer:getChildByName("Button_music")
    local btn_effect = layer:getChildByName("Button_effect")
    PLAY_BACKGROUND_MUSIC("main_bg")--播放音乐
    local isMusic = cc.UserDefault:getInstance():getBoolForKey("isOpenMusic" , true)
    MainScene.isOpenMusic = isMusic
    MainScene.isOpenEffect = cc.UserDefault:getInstance():getBoolForKey("isOpenEffect" , true)
    if not isMusic then
        cc.SimpleAudioEngine:getInstance():pauseMusic()
    else
        cc.SimpleAudioEngine:getInstance():resumeMusic()
    end
    btn_music:setBright(isMusic)
    btn_effect:setBright(MainScene.isOpenEffect)

    -- 玩家金钱
    local money = cc.UserDefault:getInstance():getIntegerForKey("myMoney")
    local txt = layer:getChildByName("Text_diamond")
    txt:setString(money)

    -- 规则
    local btn_rule = layer:getChildByName("Button_rule")
    btn_rule:addTouchEventListener(function(sender , event)
        if event == 2 then
            if MainScene.isOpenEffect then
                AudioEngine.playEffect("majia/sound/click.mp3")
            end
            layer_rule:setVisible(true)
        end
    end)


    -- 开始游戏 征战模式
    local btn_play_1 = layer:getChildByName("Button_play_1")
    btn_play_1:addTouchEventListener(function(sender , event)
        if event == 2 then
            if MainScene.isOpenEffect then
                AudioEngine.playEffect("majia/sound/click.mp3")
            end
            self.loadNode:addChild(BigLevelLayer:create(), 99)
        end
    end)

    -- 开始游戏 角斗场模式
    local btn_play_2 = layer:getChildByName("Button_play_2")
    btn_play_2:addTouchEventListener(function(sender , event)
        if event == 2 then
            if MainScene.isOpenEffect then
                AudioEngine.playEffect("majia/sound/click.mp3")
            end
            local gamePlayScene = require("app.majia.GameLayer")
            gamePlayScene.gameType = 2
            local scene = gamePlayScene.create()
            local ts = cc.TransitionFlipX:create(0.5, scene)
            cc.Director:getInstance():replaceScene(ts)
        end
    end)


    --商店
    local btn_shop = layer:getChildByName("Button_Shop")
    btn_shop:addTouchEventListener(function(sender , event)
        if event == 2 then
            if MainScene.isOpenEffect then
                AudioEngine.playEffect("majia/sound/click.mp3")
            end
            self.loadNode:addChild(ShopLayer:create(), 99)
        end
    end)

    --卡组
    local btn_cards = layer:getChildByName("Button_Cards")
    btn_cards:addTouchEventListener(function(sender , event)
        if event == 2 then
            if MainScene.isOpenEffect then
                AudioEngine.playEffect("majia/sound/click.mp3")
            end
            self.loadNode:addChild(CardsLayer:create(), 99)
        end
    end)

    --音乐
    btn_music:addTouchEventListener(function(sender , evnet) 
        if evnet==2 then
            btn_music:setBright(not MainScene.isOpenMusic)
            if MainScene.isOpenMusic then
                MainScene.isOpenMusic = false
                cc.UserDefault:getInstance():setBoolForKey("isOpenMusic" , MainScene.isOpenMusic)
                cc.SimpleAudioEngine:getInstance():pauseMusic()
            else
                MainScene.isOpenMusic = true
                cc.UserDefault:getInstance():setBoolForKey("isOpenMusic" , MainScene.isOpenMusic)
                cc.SimpleAudioEngine:getInstance():resumeMusic()
            end
        end
    end)
    --音效
    btn_effect:addTouchEventListener(function(sender , evnet)
        if evnet==2 then
            btn_effect:setBright(not MainScene.isOpenEffect)
            if MainScene.isOpenEffect then
                MainScene.isOpenEffect = false
                cc.UserDefault:getInstance():setBoolForKey("isOpenEffect" , MainScene.isOpenEffect)
            else
                MainScene.isOpenEffect = true
                cc.UserDefault:getInstance():setBoolForKey("isOpenEffect" , MainScene.isOpenEffect) 
            end
        end
    end)

    local rule_bg = layer_rule:getChildByName("bg")
    local count = 1
    local btn_next = layer_rule:getChildByName("btn_next")

    --关闭
    local btn_close = layer_rule:getChildByName("btn_back")
    btn_close:addTouchEventListener(function(sender , event)
        if event == 2 then
            if MainScene.isOpenEffect then
                AudioEngine.playEffect("majia/sound/click.mp3")
            end
            layer_rule:setVisible(false)
            count = 1
            rule_bg:loadTexture("majia/images/bg_rule_1.png")
            btn_next:loadTextures("btn_next_2.png","","btn_next_2.png", UI_TEX_TYPE_PLIST)
        end
    end)

    btn_next:addTouchEventListener(function(sender , evnet) 
        if evnet==2 then
            if MainScene.isOpenEffect then
                PLAY_SOUND_CLICK()
            end
            if count == 1 then
                rule_bg:loadTexture("majia/images/bg_rule_2.png")
                btn_next:loadTextures("btn_exit_4.png","","btn_exit_4.png", UI_TEX_TYPE_PLIST)
                count = count + 1
            else
                rule_bg:loadTexture("majia/images/bg_rule_1.png")
                btn_next:loadTextures("btn_next_2.png","","btn_next_2.png", UI_TEX_TYPE_PLIST)
                count = count - 1
            end
        end
    end)
end


return MainScene
