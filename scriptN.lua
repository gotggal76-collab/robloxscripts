local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid", 5)
local rootPart = character:WaitForChild("HumanoidRootPart", 5)

-- Настраиваемые значения
local walkSpeed = 50 -- Скорость (стандарт: 16)
local damageMultiplier = 10 -- Множитель урона
local pushForce = 100 -- Сила отталкивания (например, 50, 100, 200)
local highlightSafeColor = Color3.fromRGB(0, 255, 0) -- Безопасные плитки
local highlightDangerColor = Color3.fromRGB(255, 0, 0) -- Опасные плитки
local playerGlowColor = Color3.fromRGB(255, 255, 0) -- Свечение игроков
local noclipEnabled = false -- Noclip
local killAuraRange = 20 -- Радиус Kill Aura
local killAuraEnabled = true -- Kill Aura (вкл/выкл)
local autoWinGlass = false -- Auto Win для Glass Bridge
local autoDalgona = false -- Auto для Dalgona (скип мини-игры)
local guiVisible = true -- Состояние GUI

-- Автоматическое поддержание скорости
local function setWalkSpeed(speed)
if humanoid then
pcall(function()
humanoid.WalkSpeed = speed
print("Скорость установлена на: " .. speed)
end)
if humanoid.WalkSpeed ~= speed then
local existingVelocity = rootPart:FindFirstChild("SpeedVelocity")
if existingVelocity then existingVelocity:Destroy() end
local bodyVelocity = Instance.new("BodyVelocity")
bodyVelocity.Name = "SpeedVelocity"
bodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
bodyVelocity.Velocity = Vector3.new(0, 0, 0)
bodyVelocity.Parent = rootPart
print("Обход скорости через BodyVelocity")
end
else
print("Ошибка: Humanoid не найден")
end
end

spawn(function()
while true do
if humanoid then
pcall(function()
if humanoid.WalkSpeed ~= walkSpeed then
humanoid.WalkSpeed = walkSpeed
end
end)
end
wait(0.1)
end
end)

setWalkSpeed(walkSpeed)

-- Glass Vision с улучшенным поиском (исправлено для поиска вложенных объектов)
local function highlightSafeTiles()
local workspace = game:GetService("Workspace")
local possibleBridgeNames = {"GlassBridge", "Bridge", "GlassTiles", "GlassPath", "InkBridge", "GlassPlatform"}
local glassBridge = nil

-- Улучшенный поиск: через GetDescendants Workspace
for _, obj in pairs(workspace:GetDescendants()) do
if table.find(possibleBridgeNames, obj.Name) then
glassBridge = obj
print("Найден Glass Bridge: " .. obj.Name .. " (вложенный поиск)")
break
end
end

if glassBridge then
for _, tile in pairs(glassBridge:GetDescendants()) do
if tile:IsA("BasePart") then
local highlight = Instance.new("Highlight")
highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
highlight.FillTransparency = 0.5
highlight.OutlineTransparency = 0
highlight.Parent = tile
if tile.Transparency == 0 or tile.Name:lower():find("safe") or tile:GetAttribute("Safe") or tile.BrickColor.Name == "Bright green" then -- Исправлено: добавлена проверка цвета или атрибута
highlight.FillColor = highlightSafeColor
print("Безопасная плитка: " .. tile.Name)
else
highlight.FillColor = highlightDangerColor
print("Опасная плитка: " .. tile.Name)
end
end
end
print("Glass Vision активирован!")
if autoWinGlass then
local endPart = glassBridge:FindFirstChild("EndPart") or glassBridge:GetChildren()[1]
if endPart then
pcall(function()
rootPart.CFrame = CFrame.new(endPart.Position + Vector3.new(0, 5, 0))
print("Auto Win: Телепортация на конец Glass Bridge!")
end)
else
print("EndPart не найден")
end
end
else
print("Glass Bridge не найден - попробуйте перезапустить мини-игру")
end
end

-- Увеличение урона и Kill Aura с отталкиванием
local function increaseDamage()
local tool = character:FindFirstChildOfClass("Tool") or player.Backpack:FindFirstChildOfClass("Tool")
if tool then
tool:SetAttribute("DamageBoost", damageMultiplier)
local damageValue = tool:FindFirstChild("DamageMultiplier") or Instance.new("NumberValue")
damageValue.Name = "DamageMultiplier"
damageValue.Value = damageMultiplier
damageValue.Parent = tool
print("Урон x" .. damageMultiplier .. " для: " .. tool.Name)
else
humanoid.MaxHealth = humanoid.MaxHealth * 2
humanoid.Health = humanoid.MaxHealth
print("Увеличено здоровье!")
end

spawn(function()
while true do
if killAuraEnabled then
for _, p in pairs(Players:GetPlayers()) do
if p ~= player and p.Character and p.Character.Humanoid and p.Character.HumanoidRootPart then
local distance = (p.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
if distance <= killAuraRange then
pcall(function()
-- Нанесение урона
p.Character.Humanoid:TakeDamage(50 * damageMultiplier)
print("Kill Aura: Урон " .. p.Name)
-- Отталкивание
local direction = (p.Character.HumanoidRootPart.Position - rootPart.Position).Unit
local pushVelocity = Instance.new("BodyVelocity")
pushVelocity.Name = "PushVelocity"
pushVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
pushVelocity.Velocity = direction * pushForce
pushVelocity.Parent = p.Character.HumanoidRootPart
game:GetService("Debris"):AddItem(pushVelocity, 0.2)
print("Kill Aura: Отталкивание " .. p.Name .. " с силой " .. pushForce)
end)
end
end
end
end
wait(0.5)
end
end)
end

-- Автоматическое поддержание урона
spawn(function()
while true do
if character then
local tool = character:FindFirstChildOfClass("Tool") or player.Backpack:FindFirstChildOfClass("Tool")
if tool and not tool:FindFirstChild("DamageMultiplier") then
increaseDamage()
end
if humanoid and humanoid.MaxHealth < 100 * damageMultiplier then
humanoid.MaxHealth = humanoid.MaxHealth * 2
humanoid.Health = humanoid.MaxHealth
end
end
wait(0.5)
end
end)

-- Noclip
local function toggleNoclip()
spawn(function()
while noclipEnabled and character do
for _, part in pairs(character:GetDescendants()) do
if part:IsA("BasePart") then
part.CanCollide = false
end
end
wait(0.1)
end
for _, part in pairs(character:GetDescendants()) do
if part:IsA("BasePart") then
part.CanCollide = true
end
end
end)
print("Noclip: " .. (noclipEnabled and "Вкл" or "Выкл"))
end

-- Свечение игроков
local function addPlayerGlow()
for _, p in pairs(Players:GetPlayers()) do
if p.Character and p ~= player then
local highlight = Instance.new("Highlight")
highlight.FillColor = playerGlowColor
highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
highlight.FillTransparency = 0.5
highlight.OutlineTransparency = 0
highlight.Parent = p.Character
print("Свечение для: " .. p.Name)
end
end
end

-- Auto Dalgona (скип мини-игры)
local function autoDalgonaSkip()
spawn(function()
while autoDalgona do
local dalgona = game:GetService("Workspace"):FindFirstChild("Dalgona", true) or game:GetService("Workspace"):FindFirstChild("CookieGame", true)
if dalgona then
-- Авто-вырезание: симулируем успех через изменение свойств или телепортацию
pcall(function()
dalgona:Destroy() -- Удаляем объект (клиентски, для скипа)
rootPart.CFrame = rootPart.CFrame + Vector3.new(0, 5, 0) -- Лёгкая телепортация для "прохождения"
print("Auto Dalgona: Скип мини-игры!")
end)
end
wait(0.5)
end
end)
print("Auto Dalgona: " .. (autoDalgona and "Вкл" or "Выкл"))
end

-- GUI без Jump Rope, справа сверху
local function createGUI()
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = player.PlayerGui
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 300, 0, 340)
Frame.Position = UDim2.new(1, -300, 0, 0) -- Справа сверху
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.Parent = ScreenGui
Frame.Visible = guiVisible

local SpeedText = Instance.new("TextBox")
SpeedText.Size = UDim2.new(0, 100, 0, 30)
SpeedText.Position = UDim2.new(0.1, 0, 0.05, 0)
SpeedText.Text = tostring(walkSpeed)
SpeedText.Parent = Frame

local SpeedButton = Instance.new("TextButton")
SpeedButton.Size = UDim2.new(0, 100, 0, 30)
SpeedButton.Position = UDim2.new(0.6, 0, 0.05, 0)
SpeedButton.Text = "Set Speed"
SpeedButton.Parent = Frame
SpeedButton.MouseButton1Click:Connect(function()
local newSpeed = tonumber(SpeedText.Text)
if newSpeed then
walkSpeed = newSpeed
setWalkSpeed(newSpeed)
print("Скорость изменена на: " .. newSpeed)
else
print("Ошибка: Введите число для скорости")
end
end)

local DamageText = Instance.new("TextBox")
DamageText.Size = UDim2.new(0, 100, 0, 30)
DamageText.Position = UDim2.new(0.1, 0, 0.15, 0)
DamageText.Text = tostring(damageMultiplier)
DamageText.Parent = Frame

local DamageButton = Instance.new("TextButton")
DamageButton.Size = UDim2.new(0, 100, 0, 30)
DamageButton.Position = UDim2.new(0.6, 0, 0.15, 0)
DamageButton.Text = "Set Damage"
DamageButton.Parent = Frame
DamageButton.MouseButton1Click:Connect(function()
local newDamage = tonumber(DamageText.Text)
if newDamage then
damageMultiplier = newDamage
increaseDamage()
print("Урон x" .. newDamage)
else
print("Ошибка: Введите число для урона")
end
end)

local PushText = Instance.new("TextBox")
PushText.Size = UDim2.new(0, 100, 0, 30)
PushText.Position = UDim2.new(0.1, 0, 0.25, 0)
PushText.Text = tostring(pushForce)
PushText.Parent = Frame

local PushButton = Instance.new("TextButton")
PushButton.Size = UDim2.new(0, 100, 0, 30)
PushButton.Position = UDim2.new(0.6, 0, 0.25, 0)
PushButton.Text = "Set Push Force"
PushButton.Parent = Frame
PushButton.MouseButton1Click:Connect(function()
local newPush = tonumber(PushText.Text)
if newPush then
pushForce = newPush
increaseDamage()
print("Сила отталкивания: " .. newPush)
else
print("Ошибка: Введите число для силы отталкивания")
end
end)

local KillAuraButton = Instance.new("TextButton")
KillAuraButton.Size = UDim2.new(0, 200, 0, 30)
KillAuraButton.Position = UDim2.new(0.1, 0, 0.35, 0)
KillAuraButton.Text = "Toggle Kill Aura"
KillAuraButton.Parent = Frame
KillAuraButton.MouseButton1Click:Connect(function()
killAuraEnabled = not killAuraEnabled
increaseDamage()
print("Kill Aura: " .. (killAuraEnabled and "Вкл" or "Выкл"))
end)

local NoclipButton = Instance.new("TextButton")
NoclipButton.Size = UDim2.new(0, 200, 0, 30)
NoclipButton.Position = UDim2.new(0.1, 0, 0.45, 0)
NoclipButton.Text = "Toggle Noclip"
NoclipButton.Parent = Frame
NoclipButton.MouseButton1Click:Connect(function()
noclipEnabled = not noclipEnabled
toggleNoclip()
end)

local AutoWinButton = Instance.new("TextButton")
AutoWinButton.Size = UDim2.new(0, 200, 0, 30)
AutoWinButton.Position = UDim2.new(0.1, 0, 0.55, 0)
AutoWinButton.Text = "Toggle Auto Win Glass"
AutoWinButton.Parent = Frame
AutoWinButton.MouseButton1Click:Connect(function()
autoWinGlass = not autoWinGlass
highlightSafeTiles()
print("Auto Win Glass: " .. (autoWinGlass and "Вкл" or "Выкл"))
end)

local DalgonaButton = Instance.new("TextButton")
DalgonaButton.Size = UDim2.new(0, 200, 0, 30)
DalgonaButton.Position = UDim2.new(0.1, 0, 0.65, 0)
DalgonaButton.Text = "Toggle Auto Dalgona"
DalgonaButton.Parent = Frame
DalgonaButton.MouseButton1Click:Connect(function()
autoDalgona = not autoDalgona
autoDalgonaSkip()
print("Auto Dalgona: " .. (autoDalgona and "Вкл" or "Выкл"))
end)

local RespawnButton = Instance.new("TextButton")
RespawnButton.Size = UDim2.new(0, 200, 0, 30)
RespawnButton.Position = UDim2.new(0.1, 0, 0.75, 0)
RespawnButton.Text = "Respawn"
RespawnButton.Parent = Frame
RespawnButton.MouseButton1Click:Connect(function()
if humanoid then
humanoid.Health = 0 -- Смерть для возрождения
print("Respawn: Персонаж возрождается")
else
print("Ошибка: Humanoid не найден для respawn")
end
end)

local HideButton = Instance.new("TextButton")
HideButton.Size = UDim2.new(0, 200, 0, 30)
HideButton.Position = UDim2.new(0.1, 0, 0.85, 0)
HideButton.Text = "Hide/Show GUI"
HideButton.Parent = Frame
HideButton.MouseButton1Click:Connect(function()
guiVisible = not guiVisible
Frame.Visible = guiVisible
print("GUI: " .. (guiVisible and "Показан" or "Скрыт"))
end)

-- Горячая клавиша H для скрытия/показа (на ПК)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
if not gameProcessed and input.KeyCode == Enum.KeyCode.H then
guiVisible = not guiVisible
Frame.Visible = guiVisible
print("GUI: " .. (guiVisible and "Показан" or "Скрыт") .. " (клавиша H)")
end
end)
end

-- Запуск функций
highlightSafeTiles()
increaseDamage()
addPlayerGlow()
toggleNoclip()
autoDalgonaSkip()
createGUI()

-- Обновление при возрождении
player.CharacterAdded:Connect(function(newCharacter)
character = newCharacter
humanoid = character:WaitForChild("Humanoid", 5)
rootPart = character:WaitForChild("HumanoidRootPart", 5)
setWalkSpeed(walkSpeed)
increaseDamage()
addPlayerGlow()
toggleNoclip()
autoDalgonaSkip()
end)

print("Скрипт активирован: Glass Vision, Auto Speed " .. walkSpeed .. ", Auto Damage x" .. damageMultiplier .. ", Push Force " .. pushForce .. ", Toggle Kill Aura, Noclip, Auto Win, Auto Dalgona, Respawn, GUI с Hide/Show!")
