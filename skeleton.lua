-- Skeleton ESP Library
local WAIT = task.wait
local TBINSERT = table.insert
local TBREMOVE = table.remove
local V2 = Vector2.new
local ROUND = math.round

local RS = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local To2D = Camera.WorldToViewportPoint

local Library = {}
Library.__index = Library

-- Create a new line
function Library:NewLine(info)
    local l = Drawing.new("Line")
    l.Visible = info.Visible or false
    l.Color = info.Color or Color3.fromRGB(255,255,255)
    l.Transparency = info.Transparency or 1
    l.Thickness = info.Thickness or 1
    return l
end

-- Vector2 rounding
function Library:Smoothen(v)
    return V2(ROUND(v.X), ROUND(v.Y))
end

-- Skeleton object
local Skeleton = {
    Removed = false,
    Player = nil,
    Visible = false,
    Lines = {},
    Color = Color3.fromRGB(255,255,255),
    Alpha = 1,
    Thickness = 1,
    DoSubsteps = true
}
Skeleton.__index = Skeleton

-- Update structure of skeleton
function Skeleton:UpdateStructure()
    if not self.Player.Character then return end
    self:RemoveLines()

    for _, part in next, self.Player.Character:GetChildren() do
        if not part:IsA("BasePart") then continue end
        for _, link in next, part:GetChildren() do
            if not link:IsA("Motor6D") then continue end

            TBINSERT(self.Lines, {
                Library:NewLine({
                    Visible = self.Visible,
                    Color = self.Color,
                    Transparency = self.Alpha,
                    Thickness = self.Thickness
                }),
                Library:NewLine({
                    Visible = self.Visible,
                    Color = self.Color,
                    Transparency = self.Alpha,
                    Thickness = self.Thickness
                }),
                part.Name,
                link.Name
            })
        end
    end
end

-- Set visibility
function Skeleton:SetVisible(State)
    self.Visible = State
    for _,l in pairs(self.Lines) do
        l[1].Visible = State
        l[2].Visible = State
    end
end

-- Set color
function Skeleton:SetColor(Color)
    self.Color = Color
    for _,l in pairs(self.Lines) do
        l[1].Color = Color
        l[2].Color = Color
    end
end

-- Set alpha
function Skeleton:SetAlpha(Alpha)
    self.Alpha = Alpha
    for _,l in pairs(self.Lines) do
        l[1].Transparency = Alpha
        l[2].Transparency = Alpha
    end
end

-- Set thickness
function Skeleton:SetThickness(Thickness)
    self.Thickness = Thickness
    for _,l in pairs(self.Lines) do
        l[1].Thickness = Thickness
        l[2].Thickness = Thickness
    end
end

-- Remove all lines
function Skeleton:RemoveLines()
    for _,l in pairs(self.Lines) do
        l[1]:Remove()
        l[2]:Remove()
    end
    self.Lines = {}
end

-- Remove skeleton completely
function Skeleton:Remove()
    self.Removed = true
    self:RemoveLines()
end

-- Update skeleton positions
function Skeleton:Update()
    if self.Removed or not self.Player.Character then
        self:SetVisible(false)
        return
    end

    local Character = self.Player.Character
    local update = false

    for _, l in pairs(self.Lines) do
        local part = Character:FindFirstChild(l[3])
        local link = part and part:FindFirstChild(l[4])
        if not (part and link and link.Part0 and link.Part1) then
            l[1].Visible = false
            l[2].Visible = false
            update = true
            continue
        end

        local part0 = link.Part0
        local part1 = link.Part1

        local part0p, v1 = To2D(Camera, part0.Position)
        local part1p, v2 = To2D(Camera, part1.Position)

        if v1 and v2 then
            l[1].From = V2(part0p.X, part0p.Y)
            l[1].To = V2(part1p.X, part1p.Y)
            l[1].Visible = self.Visible
        else
            l[1].Visible = false
        end

        l[2].Visible = false
    end

    if update or #self.Lines == 0 then
        self:UpdateStructure()
    end
end

-- Toggle drawing (can be called by UI)
function Skeleton:Toggle()
    self:SetVisible(not self.Visible)
    if self.Visible then
        self:UpdateStructure()
        local conn; conn = RS.Heartbeat:Connect(function()
            if not self.Visible then
                self:SetVisible(false)
                conn:Disconnect()
                return
            end
            self:Update()
        end)
    end
end

-- Create a new skeleton for a player
function Library:NewSkeleton(Player, Visible, Color, Alpha, Thickness, DoSubsteps)
    local s = setmetatable({}, Skeleton)
    s.Player = Player
    s.Bind = Player.UserId
    if DoSubsteps ~= nil then s.DoSubsteps = DoSubsteps end
    if Color then s:SetColor(Color) end
    if Alpha then s:SetAlpha(Alpha) end
    if Thickness then s:SetThickness(Thickness) end
    if Visible then s:Toggle() end -- Only toggle if explicitly requested
    return s
end

return Library
