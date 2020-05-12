require "app.majia.LevelLayer"

BigLevelLayer = class("BigLevelLayer",function()
    return cc.Layer:create()
end)

local plistName = "majia/images/game_ui.plist"

function BigLevelLayer:ctor()
    if not cc.SpriteFrameCache:getInstance():isSpriteFramesWithFileLoaded(plistName) then
        cc.SpriteFrameCache:getInstance():addSpriteFrames(plistName)
    end

    self.loadNode = cc.CSLoader:createNode("majia/BigLevelLayer.csb")
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

    local levelCount = cc.UserDefault:getInstance():getIntegerForKey("biglevelCount")
    for i=1,3 do
        local btn_level = self.layer:getChildByName("btn_level_" .. i)
        btn_level:addTouchEventListener(function(sender , event)
            if event == 2 then
                if MainScene.isOpenEffect then
                    AudioEngine.playEffect("majia/sound/click.mp3")
                end
                self:gotoPlay(i)
            end
        end)
        if levelCount <= i then
            btn_level:setEnabled(false)
        end
        if i == levelCount then
            btn_level:setEnabled(true)
        end
    end
end

function BigLevelLayer:gotoPlay(num)
    self.loadNode:addChild(LevelLayer:create(num), 99)
end

return BigLevelLayer