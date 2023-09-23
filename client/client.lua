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

------------ ✨ Performance ✨ --------------------
local GetCurrentResourceName = GetCurrentResourceName
local CreateThread = CreateThread
local RegisterDui = RegisterDui
local IsControlJustPressed = IsControlJustPressed
local resourceName = GetCurrentResourceName()
-----------------------------------------------------

local DuiStorage = {}

CreateThread(function()
  local dui = RegisterDui({
    url = "https://www.google.com", -- for viewing normal webpages (Even ones that cant be iframed)
    --url = ("nui://%s/%s"):format(resourceName, "html/index.html"), -- For viewing your own UI

    -- for a list of existing render targets, see: https://wiki.rage.mp/index.php?title=Render_Targets
    model = "ex_prop_monitor_01_ex", -- the model to render to
    target = "prop_ex_computer_screen", -- the texture to render to.
    res = {x = 1448, y = 724}, -- clostest to 720p, this should be kept to a 2:1 aspect ratio
    renderDistance = 20.0 -- the distance for rendering the Dui
  })

  local coords = vector3(-1556.0435, -574.7726, 108.5272) -- define where the position of the object is.
  dui.point = lib.points.new({ -- create an ox_lib point for handling enter/leave
    coords = coords,
    distance = 20.0,
  })

  -- On Player Enter
  function dui.point:onEnter()
    dui:RegisterRt() -- register the render target as usable
    dui:Create() -- Create the Dui Object
    dui:Draw(true, false) -- Draw the Dui Object
  end
  
  -- On Player Exit
  function dui.point:onExit()
    dui:Draw(false, false) -- stop drawing the Dui
    dui:Destroy() -- Remove the Dui, and clear the render target
  end

  -- Add On Ox_target zone to allow interaction
  exports.ox_target:addSphereZone({
    coords = coords,
    radius = 7.0,
    options = {
      {
        label = "Use Computer",
        icon = "fas fa-desktop",
        onSelect = function()
          dui:toggleFocus() -- tooggles input
        end
      }
    }
  })


  -- IMPORTATNT: remove the Dui on resource Stop
  AddEventHandler("onResourceStop", function(name)
    if name ~= resourceName then return end
    dui:Destroy()
  end)
  DuiStorage[1] = dui -- store the dui for later use,
end)

-- example on how to change the Dui url
---@param args table -- args[1] being the URL to change to
---@return nil
RegisterCommand("changeurl", function(_, args)
  DuiStorage[1]:SetUrl(args[1])
end, false)

-- example on how to send Key Data from Nui to Dui
---@param data table -- the data from the the Nui browser
---@return nil
RegisterNuiCallback("sendKey", function(data, cb)
  cb({})
  if data.key == "Tab" then -- allow exiting of the Dui
    DuiStorage[1]:toggleFocus()
    return
  end
  --[[-- Disabled for now, pending GH-PR-2195 (https://github.com/citizenfx/fivem/pull/2195)
  if data.type == "down" then 
    SendDuiKeyDown(DuiStorage[1].object, data.key) -- tell Dui the key was Pressed.
  else
    SendDuiKeyUp(DuiStorage[1].object, data.key) -- Tell Dui the Key Was Released
  end]]
end)

RegisterCommand("gotoComputer", function(source, args, raw)
  SetEntityCoords(PlayerPedId(), -1556.0435, -574.7726, 108.5272)
end)