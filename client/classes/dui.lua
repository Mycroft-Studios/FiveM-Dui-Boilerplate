--[[FiveM Dui Boilerplate

 Copyright 2023 [Mycroft Studios](https://github.com/Mycroft-Studios)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software
and associated documentation files (the “Software”), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.]]

------------------- ✨ Performance ✨ ---------------------
local setmetatable = setmetatable
local joaat= joaat
local CreateRuntimeTxd = CreateRuntimeTxd
local IsNamedRendertargetRegistered = IsNamedRendertargetRegistered
local RegisterNamedRendertarget = RegisterNamedRendertarget
local IsNamedRendertargetLinked = IsNamedRendertargetLinked
local LinkNamedRendertarget = LinkNamedRendertarget
local GetNamedRendertargetRenderId = GetNamedRendertargetRenderId
local CreateRuntimeTextureFromDuiHandle = CreateRuntimeTextureFromDuiHandle
local SetDuiUrl = SetDuiUrl
local PlayerPedId = PlayerPedId
local GetEntityCoords = GetEntityCoords
local GetClosestObjectOfType = GetClosestObjectOfType
local DoesEntityExist = DoesEntityExist
local CreateDui = CreateDui
local GetDuiHandle = GetDuiHandle
local DrawSprite = DrawSprite
local SetTextRenderId = SetTextRenderId
local SetScriptGfxDrawOrder = SetScriptGfxDrawOrder
local DisableAllControlActions = DisableAllControlActions
local GetDisabledControlNormal = GetDisabledControlNormal
local RequestStreamedTextureDict = RequestStreamedTextureDict
local Wait = Wait
local IsDisabledControlJustPressed = IsDisabledControlJustPressed
local IsDisabledControlJustReleased = IsDisabledControlJustReleased
local math = math
local SendDuiMouseWheel = SendDuiMouseWheel
local SendDuiMouseUp = SendDuiMouseUp
local SendDuiMouseWheel = SendDuiMouseWheel
local SendDuiMouseMove = SendDuiMouseMove
local SendDuiMessage = SendDuiMessage
local ClearFocus = ClearFocus
local SetNuiFocus = SetNuiFocus
------------------------------------------------------------

DuiClass = {
    __index = DuiClass
}

-- request textureDict for the cursor
RequestStreamedTextureDict( "desktop_pc", false)

---@param data dui
---@return dui
function RegisterDui(data)
    -- initialise the class
    ---@class dui
    ---@field rt table Contains all Render Target Info
    ---@field model string The render target Model
    ---@field target table The render target texture
    ---@field res table The browser resolution {x=int, y=int}
    ---@field renderDistance number the distance for rendering the Dui
    ---@field url string The URL of the DUI browser
    ---@field draw boolean Should the browser be drawing
    ---@field object number Entity Handle of the clostest Rendered Object
    ---@field handle string DUI browser handle
    
    local dui = setmetatable({}, DuiClass)
    dui.rt = {
        model = data.model or "",
        modelHash = joaat(data.model),
        target = data.target or "",
        res = data.res,
    }
    dui.renderDistance = data.renderDistance or 15.0
    dui.url = data.url
    dui.draw = false
    dui.object = 0
    dui.handle = ""
    dui.controls = false
    dui.txt = nil
    dui.lastCursorX, dui.lastCursorY = 0,0
    dui.txd = CreateRuntimeTxd(dui.rt.model)
    dui.isInteracting = false
    dui.metadata = {}

    -- Registers the Model to the Render Target
    function dui:RegisterRt()
        if not IsNamedRendertargetRegistered(self.rt.target) then
            RegisterNamedRendertarget(self.rt.target, false)
            if not IsNamedRendertargetLinked(self.rt.modelHash) then
                LinkNamedRendertarget(self.rt.modelHash)
            end
            self.rt.handle = GetNamedRendertargetRenderId(self.rt.target)
        end
    end

    -- Navigates the DUI browser to a different URL.
    function dui:SetUrl(url)
        self.url = url
        SetDuiUrl(self.object, self.url)
    end

    -- Gets the clostest Object that it is rendering upon
    function dui:GetClosestRender()
        local ped = PlayerPedId()
        local pedCoords = GetEntityCoords(ped)
        local object = GetClosestObjectOfType(pedCoords.x, pedCoords.y, pedCoords.z, self.renderDistance, self.rt.modelHash, false, false, false)
        if object then
            return object
        end
        return nil
    end

    -- Creates the Dui Browser and its Texture
    ---@return nil
    function dui:Create()
        self.object = CreateDui(self.url, self.rt.res.x or 1920, self.rt.res.y or 1080)
        self.handle = GetDuiHandle(self.object)
        if not self.txt then
            self.txt = CreateRuntimeTextureFromDuiHandle(self.txd, "dui", self.handle)
        end
    end

    -- Draw the Dui Browser
    ---@param draw boolean Set whether the DUI should be drawing or not
    ---@param thisFrame boolean Set whether the DUI should be drawn for 1 frame
    ---@return nil
    function dui:Draw(draw, thisFrame)
        self.draw = draw
        if thisFrame then
            SetTextRenderId(self.rt.handle) -- set render ID to the render target
            SetScriptGfxDrawOrder(4)
            SetScriptGfxDrawBehindPausemenu(true) -- allow it to draw behind pause menu
            DrawSprite(self.rt.model, "dui", 0.5, 0.5, 0.5, 0.5, 0.0, 255, 255, 255, 1.0)
            SetTextRenderId(GetDefaultScriptRendertargetRenderId()) -- Reset Render ID
            self.nearestRender = self:GetClosestRender() -- make sure to get the clostest render
        else
            CreateThread(function()
                while self.draw do
                    local sleep = true
                    if self.nearestRender then -- make sure there is a render object nearby
                       -- only draw the DUI, if the client can see it
                       if IsEntityOnScreen(self.nearestRender) and not IsEntityOccluded(self.nearestRender) then 
                            sleep = false
                            SetTextRenderId(self.rt.handle) -- set render ID to the render target
                            SetScriptGfxDrawOrder(4)
                            SetScriptGfxDrawBehindPausemenu(true) -- allow it to draw behind pause menu
                            DrawSprite(self.rt.model, "dui", 0.5, 0.5, 1.0, 1.0, 0.0, 255, 255, 255, 1.0) -- draw Dui Sprite
                            -- process controls if interacting with the Dui
                            if self.controls then
                                self:ProcessControls()
                            end
                            SetTextRenderId(1) -- Reset Render ID (1 is default)
                       end
                   end
                    Wait(sleep and 500 or 0)
                end
            end)
            -- Thread to get the clostest render Object
            -- Seperate so that when drawing, we arent running it every tick
            CreateThread(function()
                while self.draw do
                    self.nearestRender = self:GetClosestRender()
                    Wait(500)
                end
            end)
        end
    end

    ---@param action string The action you wish to target
    ---@param messageData any The data you wish to send along with this action
    function dui:SendMessage(action, messageData)
        SendDuiMessage(self.object, json.encode({
            action = action,
            data = messageData
        }))
    end

    function dui:Destroy()
        if self.object then
            DestroyDui(self.object)
            self.object = nil
        end
        if IsNamedRendertargetRegistered(self.rt.target) then
            ReleaseNamedRendertarget(self.rt.target)
        end
        self.controls = false
    end
 
    local function GetCursor() -- This might break for people with weird resolutions? Im really not sure.
        local sx, sy = 1280, 1024
        local cx, cy = GetNuiCursorPosition()
        local cx, cy = (cx / sx) + 0.008, (cy / sy) + 0.027
        return cx, cy
    end

    function dui:ProcessControls()
        DisableAllControlActions(0)
        DisableAllControlActions(1)
        DisableAllControlActions(2)
        DisableAllControlActions(3)
        
        local cursorX, cursorY = GetCursor()
        if cursorX ~= dui.lastCursorX or cursorY ~= dui.lastCursorY then
            dui.lastCursorX = cursorX 
            dui.lastCursorY = cursorY
            local duiX, duiY = math.floor(cursorX * self.rt.res.x + 0.5), math.floor(cursorY * self.rt.res.y + 0.5)
            SendDuiMouseMove(self.object, duiX, duiY)
        end
        DrawSprite("desktop_pc", "arrow", cursorX, cursorY, 0.05/4.5, 0.035, 0, 255, 255, 255, 255)
        local mousekeys = {left = 24, right = 25}
        for k,v in pairs(mousekeys) do
            if IsDisabledControlJustPressed(0, v) then
                SendDuiMouseDown(self.object, tostring(k))
            end
            if IsDisabledControlJustReleased(0, v) then
                SendDuiMouseUp(self.object, tostring(k))
            end
        end
        if (IsDisabledControlJustPressed(3, 180)) then -- SCROLL DOWN
            SendDuiMouseWheel(self.object, -150, 0.0)
        end
        if (IsDisabledControlJustPressed(3, 181)) then -- SCROLL UP
            SendDuiMouseWheel(self.object, 150, 0.0)
        end
    end

    function dui:toggleFocus()
        if not self.isInteracting then
            local object = self.nearestRender
            SetNuiFocus(true, false)
            if not object or object < 1 then return end
            SetFocusEntity(object)
            self:SetControlEnabled(true)
        else
            SetNuiFocus(false, false)
            ClearFocus()
            self:SetControlEnabled(false)
       end
       self.isInteracting = not self.isInteracting
    end

    function dui:SetControlEnabled(toggle)
        self.controls = toggle
    end

    return dui
end