--[[
  Copyright (c) 2013 David Young dayoung@goliathdesigns.com

  This software is provided 'as-is', without any express or implied
  warranty. In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

   1. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software
   in a product, an acknowledgment in the product documentation would be
   appreciated but is not required.

   2. Altered source versions must be plainly marked as such, and must not be
   misrepresented as being the original software.

   3. This notice may not be removed or altered from any source
   distribution.
]]

require "DebugUtilities"
require "SandboxUtilities"
require "SoldierTactics"
require "GUI"

local _drawNavMesh;
local _drawInfluence;
local _ui;

local agents = {};

local function _CreateSandboxText(sandbox)
    local ui = Sandbox.CreateUIComponent(sandbox, 1);
    local width = Sandbox.GetScreenWidth(sandbox);
    local height = Sandbox.GetScreenHeight(sandbox);
    local uiWidth = 300;
    local uiHeight = 180;
    
    UI.SetPosition(ui, width - uiWidth - 20, height - uiHeight - 35);
    UI.SetDimensions(ui, uiWidth, uiHeight);
    UI.SetTextMargin(ui, 10, 10);
    GUI_SetGradientColor(ui);

    UI.SetMarkupText(
        ui,
        GUI.MarkupColor.White .. GUI.Markup.SmallMono ..
        "W/A/S/D: to move" .. GUI.MarkupNewline ..
        "Hold Shift: to accelerate movement" .. GUI.MarkupNewline ..
        "Hold RMB: to look" .. GUI.MarkupNewline ..
        GUI.MarkupNewline ..
        "F1: to reset the camera" .. GUI.MarkupNewline ..
        "F2: toggle the menu" .. GUI.MarkupNewline ..
        "F3: toggle the navigation mesh" .. GUI.MarkupNewline ..
        "F4: toggle the influence map" .. GUI.MarkupNewline ..
        "F5: toggle performance information" .. GUI.MarkupNewline ..
        "F6: toggle camera information" .. GUI.MarkupNewline ..
        "F7: toggle physics debug");

    return ui;
end

function Sandbox_Cleanup(sandbox)
end

function Sandbox_HandleEvent(sandbox, event)
    GUI_HandleEvent(sandbox, event);
    
    if (event.source == "keyboard" and event.pressed) then
        if (event.key == "f1_key") then
            Sandbox.SetCameraPosition(sandbox, Vector.new(-30, 18, -17));
            Sandbox.SetCameraOrientation(sandbox, Vector.new(-146, -40, -157));
        elseif (event.key == "f2_key" ) then
            UI.SetVisible(_ui, not UI.IsVisible(_ui));
        elseif (event.key == "f3_key") then
            _drawNavMesh = not _drawNavMesh;
            Sandbox.SetDebugNavigationMesh(sandbox, "default", _drawNavMesh);
        elseif (event.key == "f4_key") then
            _drawInfluence = not _drawInfluence;
            Sandbox.SetDrawInfluenceMap(sandbox, _drawInfluence);
        end
    end
end

function Sandbox_Initialize(sandbox)
    -- Setup the demo UI menu.
    GUI_CreateUI(sandbox);
    _ui = _CreateSandboxText(sandbox);

    -- Initialize the camera position to focus on the soldier.
    Sandbox.SetCameraPosition(sandbox, Vector.new(-30, 18, -17));
    Sandbox.SetCameraOrientation(sandbox, Vector.new(-146, -40, -157));

    -- Create the sandbox level, handles creating geometry, skybox, and lighting.
    SandboxUtilities_CreateLevel(sandbox);

    -- Override the default navigation mesh config generation, prevent 
    local navMeshConfig = {
        MinimumRegionArea = 250,
        WalkableRadius = 0.4,
        WalkableClimbHeight = 0.2,
        WalkableSlopeAngle = 45 };

    _drawNavMesh = false;
    Sandbox.CreateNavigationMesh(sandbox, "default", navMeshConfig);
    Sandbox.SetDebugNavigationMesh(sandbox, "default", false);

    -- Create agents and randomly place them on the navmesh.
    for i=1, 6 do
        local agent = Sandbox.CreateAgent(sandbox, "IndirectSoldierAgent.lua");

        local foundPosition = false;
        local position;

        while (not foundPosition) do
            position = Sandbox.RandomPoint(sandbox, "default");
            foundPosition = true;
            
            for key, value in pairs(agents) do
                if (Vector.DistanceSquared(position, value:GetPosition()) < 725) then
                    foundPosition = false;
                end
            end
        end

        position.y = position.y + agent:GetHeight() / 2.0;
        agent:SetPosition(position);
        agent:SetTarget(agent:GetPosition());

        table.insert(agents, agent);
    end
    
    _drawInfluence = true;
    SoldierTactics_InitializeTactics(sandbox);
end

function Sandbox_Update(sandbox, deltaTimeInMillis)
    -- Update the default UI.
    GUI_UpdateUI(sandbox);

    SoldierTactics_UpdateTactics(sandbox, deltaTimeInMillis);
    
    if (_drawInfluence) then
        SoldierTactics_DrawInfluenceMap(sandbox, 1);
    end
end