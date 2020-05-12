LevelLayer = class("LevelLayer",function()
    return cc.Layer:create()
end)

local plistName = "majia/images/game_ui.plist"

function LevelLayer:ctor(num)
    if not cc.SpriteFrameCache:getInstance():isSpriteFramesWithFileLoaded(plistName) then
        cc.SpriteFrameCache:getInstance():addSpriteFrames(plistName)
    end
    self.levelNum = num

    self.loadNode = cc.CSLoader:createNode("majia/LevelLayer.csb")
    self.loadNode:setContentSize(cc.size(display.size.height, display.size.width))
    ccui.Helper:doLayout(self.loadNode)
    self:addChild(self.loadNode, 0)
    self.layer = self.loadNode:getChildByName("Layer_level")


    local btn_close = self.layer:getChildByName("btn_back")
    btn_close:addTouchEventListener(function(sender , event)
        if event == 2 then
            if MainScene.isOpenEffect then
                AudioEngine.playEffect("majia/sound/click.mp3")
            end
            self:removeFromParent()
        end
    end)

    local levelCount = cc.UserDefault:getInstance():getIntegerForKey("levelCount")
    levelCount = math.floor(8 - (self.levelNum * 8 - levelCount))

    for i=1,8 do
        local btn_level = self.layer:getChildByName("layer"):getChildByName("level_" .. i)
        btn_level:addTouchEventListener(function(sender , event)
            if event == 2 then
                if MainScene.isOpenEffect then
                    AudioEngine.playEffect("majia/sound/click.mp3")
                end
                self:gotoPlay()
            end
        end)
        if levelCount < i then
            btn_level:getChildByName("lock"):setVisible(true)
        else
            btn_level:getChildByName("pass"):setVisible(true)
        end
        if i == levelCount + 1 then
            btn_level:getChildByName("lock"):setVisible(false)
        end
    end
end

function LevelLayer:gotoPlay()
    local gamePlayScene = require("app.majia.GameLayer")
    gamePlayScene.gameType = 1
    local scene = gamePlayScene.create()
    local ts = cc.TransitionFlipX:create(0.5, scene)
    cc.Director:getInstance():replaceScene(ts)
end

return LevelLayer