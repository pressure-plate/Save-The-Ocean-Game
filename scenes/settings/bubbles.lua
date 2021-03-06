local composer = require( "composer" )
local scene = composer.newScene()


-- initialize variables -------------------------------------------------------
local windowMod = require( "scenes.libs.window" )
local tabulatorMod = require( "scenes.libs.tabulator" )
local savedata = require( "scenes.libs.savedata" ) -- load the save data module
local bgMenuMod = require( "scenes.menu.background" ) -- required to reload the home background
local audioMod = require( "scenes.libs.audio" ) -- load lib to do audio changes on the game

local itemsDir = "assets/submarine/bubble/"

--[[
    This table represents the available item that can be used in game
        
    - internalId: how will be saved in the save file
    - dir: the relative path to the file
    - price: how much the user have to pay to unlock the item
    - defaut: the item will be added automatically to the user owned items
    - selected: the item used in game on the first load of te game 
        selected item must be also default or can't apply! 
        if no selected is provided it will automatically fallback on the first item of the table
]]--
itemsData = {
    {inernalId='SoapBubble', dir='1.png', price=1, default=true, selected=true},
    {inernalId='CleanBubble', dir='2.png', price=300},
    {inernalId='VioletBubble', dir='3.png', price=830},
}

local parent 
local group


-- to hide the current overlay
local function hideScene()
    composer.hideOverlay( "fade", composer.getVariable( "windowFadingClosingTime" ) )
end


-- set the background var once is selected
-- check also if is avaiable, and its price
local function onBubbleSelection( event )

    if event.target.alpha ~= 1 then

        -- try to pay
        if savedata.pay( itemsData[event.target.itemId].price) then

            -- update the user owned data
            local ownedData = savedata.getGamedata( "submarineBubblesOwned" )
            
            -- set the submarine just buyed
            ownedData[itemsData[event.target.itemId].inernalId] = true 
            savedata.setGamedata( "submarineBubblesOwned", ownedData )

            -- display the object as owned
            event.target.alpha = 1
            tabulatorMod.removeItemTextOver( event.target.itemId )

            -- update the money value on the parent scene
            parent:updateMoneyView()

            -- play sound to coumicate succes with the transaction
            audio.play( audioMod.paySound );

        else
            -- play audio to communicate that the user don't have enough money to buy the item
            audio.play( audioMod.noMoneySound );
        end
    
    -- concatenate actions with else if, so the user have to click again to select the item
    -- select the item, if the operation goes well, do actions
    elseif tabulatorMod.highlightItem( event.target.itemId ) then
        audio.play( audioMod.buttonSelectSound )
        savedata.setGamedata( "submarineBubbleSkin", event.target.itemId )
    end

end


-- generate the items table to display the items
local function builditems()
    local itemsOwned = savedata.getGamedata( "submarineBubblesOwned" )
    local items = {}

    for count, el in pairs ( itemsData ) do
        
        -- set the base data of the item
        local item = { 
            dir=itemsDir .. el.dir, 
            scaleFactor=2,
        }
        
        -- if the user don't own the item set the price to buy it
        if not itemsOwned[el.inernalId] then

            -- check if the item is a default one
            -- the default value is used to set in the itemsOwned the default items on the first load of the game
            -- if it is a default item then save it in the user itemsOwned
            if el.default then

                -- update the user owned data with the default item
                itemsOwned[el.inernalId] = true
                savedata.setGamedata( "submarineBubblesOwned", itemsOwned )

                -- set the item as selected in game
                if el.selected then savedata.setGamedata( "submarineBubbleSkin", count ) end

            else
                item["label"] = el.price .. '$' -- set the price to show over the item
                item['alpha'] = 0.5 -- edit opacity to emphasize that the item is disabled
            end

        end

        table.insert( items, item ) -- append to the table the built item

    end

    return items
end


function scene:show( event )
    parent = event.parent  -- Reference to the parent scene object
end


function scene:create( event )

    local sceneGroup = self.view

    group = display.newGroup() -- display group for background
    sceneGroup:insert( group )

    local windowsOptions = {
        onExitCallback = hideScene,
        windowTitle = "Bubbles"
    }

    -- load the window in the background
    windowMod.init( group, windowsOptions )

    -- options
    local tabulatorOptions = {
        items = builditems(),
        colCount = 3,
        rowCount = 2,
        tableOriginX = display.contentCenterX - display.contentWidth/4,
        tableOriginY = display.contentCenterY - display.contentHeight/4.9,
        tableReplicaDistanceFactorX = 2.8,
        onTapCallback = onBubbleSelection,
    }
    -- create the table based on the global configuration
    -- load the items in the table to display them with the builted pproprieties
    tabulatorMod.init ( group, tabulatorOptions )
    tabulatorMod.highlightItem(savedata.getGamedata( "submarineBubbleSkin" ), true) -- highlight without play sond (on load)
end


scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )

return scene
