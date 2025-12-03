local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Encontrar sua base
local plotName
local plots = workspace:FindFirstChild("Plots")
if plots then
    for _, plot in ipairs(plots:GetChildren()) do
        local yourBase = plot:FindFirstChild("YourBase", true)
        if yourBase and yourBase.Enabled then
            plotName = plot.Name
            break
        end
    end
end

-- Configurações de raridade (todas amarelas)
local RaritySettings = {
    ["Legendary"] = {
        Color = Color3.new(1, 1, 0), -- Amarelo
        Size = UDim2.new(0, 150, 0, 50)
    },
    ["Mythic"] = {
        Color = Color3.new(1, 1, 0), -- Amarelo
        Size = UDim2.new(0, 150, 0, 50)
    },
    ["Brainrot God"] = {
        Color = Color3.new(1, 1, 0), -- Amarelo
        Size = UDim2.new(0, 180, 0, 60)
    },
    ["Secret"] = {
        Color = Color3.new(1, 1, 0), -- Amarelo
        Size = UDim2.new(0, 200, 0, 70)
    }
}

-- Configurações de mutação
local MutationSettings = {
    ["Gold"] = {
        Color = Color3.fromRGB(255, 215, 0), -- Dourado
        Size = UDim2.new(0, 120, 0, 30)
    },
    ["Diamond"] = {
        Color = Color3.fromRGB(0, 191, 255), -- Azul
        Size = UDim2.new(0, 120, 0, 30)
    },
    ["Rainbow"] = {
        Color = Color3.fromRGB(255, 192, 203), -- Rosa
        Size = UDim2.new(0, 120, 0, 30)
    },
    ["Bloodrot"] = {
        Color = Color3.fromRGB(139, 0, 0), -- Vermelho escuro
        Size = UDim2.new(0, 120, 0, 30)
    }
}

-- Lista de amigos (ESP verde)
local friendList = {
    "mariaeduarda9997",
    "FinishSayan21",
    "Itz_yuteo",
    "FreeJiboia",
    "overclockgames2000"
}

-- ESP ativo
local activeESP = {}
local espInstances = {}

-- Função para formatar valor
local function formatValue(value)
    if value >= 1000000 then
        return string.format("%.1fM", value / 1000000)
    elseif value >= 1000 then
        return string.format("%.1fK", value / 1000)
    else
        return tostring(value)
    end
end

-- Função para encontrar valor do brainrot
local function findBrainrotValue(parentModel, rarityParent)
    local highestValue = 0
    local valueSource = "N/A"
    local perSecondValue = 0
    local perSecondSource = "N/A"
    
    -- DEBUG: Buscar em TODOS os descendentes do parentModel
    print("🔍 DEBUG - Buscando valores em TODOS os descendentes do parentModel:")
    for _, descendant in pairs(parentModel:GetDescendants()) do
        if descendant:IsA("IntValue") or descendant:IsA("NumberValue") or descendant:IsA("StringValue") then
            print("   ", descendant.Name, "=", descendant.Value, "Tipo:", descendant.ClassName, "Caminho:", descendant:GetFullName())
            local propValue = tonumber(descendant.Value) or 0
            if propValue > highestValue then
                highestValue = propValue
                valueSource = descendant.Name .. " (parentModel)"
            end
        elseif descendant:IsA("TextLabel") then
            -- Tentar extrair valor de TextLabel com padrões específicos
            local text = descendant.Text
            if text and text ~= "" then
                -- Padrões específicos para valores por segundo
                local patterns = {
                    -- "$5K/s" -> 5000
                    {"%$([0-9%.]+)K/s", function(match) return tonumber(match) * 1000 end},
                    -- "$1.5M/s" -> 1500000
                    {"%$([0-9%.]+)M/s", function(match) return tonumber(match) * 1000000 end},
                    -- "$38/s" -> 38
                    {"%$([0-9%.]+)/s", function(match) return tonumber(match) end},
                    -- "$5K" -> 5000 (sem /s)
                    {"%$([0-9%.]+)K", function(match) return tonumber(match) * 1000 end},
                    -- "$1M" -> 1000000 (sem /s)
                    {"%$([0-9%.]+)M", function(match) return tonumber(match) * 1000000 end},
                    -- "$38" -> 38 (sem /s)
                    {"%$([0-9%.]+)", function(match) return tonumber(match) end}
                }
                
                for i, pattern in pairs(patterns) do
                    local match = text:match(pattern[1])
                    if match then
                        local extractedValue = pattern[2](match)
                        if extractedValue and extractedValue > 0 then
                            print("   ", descendant.Name, "=", text, "Valor extraído:", extractedValue, "Caminho:", descendant:GetFullName())
                            
                            -- Priorizar valores por segundo (primeiros 3 padrões)
                            if i <= 3 then
                                if extractedValue > perSecondValue then
                                    perSecondValue = extractedValue
                                    perSecondSource = descendant.Name .. " (TextLabel - parentModel)"
                                end
                            else
                                if extractedValue > highestValue then
                                    highestValue = extractedValue
                                    valueSource = descendant.Name .. " (TextLabel - parentModel)"
                                end
                            end
                            break -- Usar apenas o primeiro padrão que der match
                        end
                    end
                end
            end
        end
    end
    
    -- DEBUG: Buscar em TODOS os descendentes do rarityParent
    if rarityParent then
        print("🔍 DEBUG - Buscando valores em TODOS os descendentes do rarityParent:")
        for _, descendant in pairs(rarityParent:GetDescendants()) do
            if descendant:IsA("IntValue") or descendant:IsA("NumberValue") or descendant:IsA("StringValue") then
                print("   ", descendant.Name, "=", descendant.Value, "Tipo:", descendant.ClassName, "Caminho:", descendant:GetFullName())
                local propValue = tonumber(descendant.Value) or 0
                if propValue > highestValue then
                    highestValue = propValue
                    valueSource = descendant.Name .. " (rarityParent)"
                end
            elseif descendant:IsA("TextLabel") then
                -- Tentar extrair valor de TextLabel com padrões específicos
                local text = descendant.Text
                if text and text ~= "" then
                    -- Padrões específicos para valores por segundo
                    local patterns = {
                        -- "$5K/s" -> 5000
                        {"%$([0-9%.]+)K/s", function(match) return tonumber(match) * 1000 end},
                        -- "$1.5M/s" -> 1500000
                        {"%$([0-9%.]+)M/s", function(match) return tonumber(match) * 1000000 end},
                        -- "$38/s" -> 38
                        {"%$([0-9%.]+)/s", function(match) return tonumber(match) end},
                        -- "$5K" -> 5000 (sem /s)
                        {"%$([0-9%.]+)K", function(match) return tonumber(match) * 1000 end},
                        -- "$1M" -> 1000000 (sem /s)
                        {"%$([0-9%.]+)M", function(match) return tonumber(match) * 1000000 end},
                        -- "$38" -> 38 (sem /s)
                        {"%$([0-9%.]+)", function(match) return tonumber(match) end}
                    }
                    
                    for i, pattern in pairs(patterns) do
                        local match = text:match(pattern[1])
                        if match then
                            local extractedValue = pattern[2](match)
                            if extractedValue and extractedValue > 0 then
                                print("   ", descendant.Name, "=", text, "Valor extraído:", extractedValue, "Caminho:", descendant:GetFullName())
                                
                                -- Priorizar valores por segundo (primeiros 3 padrões)
                                if i <= 3 then
                                    if extractedValue > perSecondValue then
                                        perSecondValue = extractedValue
                                        perSecondSource = descendant.Name .. " (TextLabel - rarityParent)"
                                    end
                                else
                                    if extractedValue > highestValue then
                                        highestValue = extractedValue
                                        valueSource = descendant.Name .. " (TextLabel - rarityParent)"
                                    end
                                end
                                break -- Usar apenas o primeiro padrão que der match
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Buscar por propriedades específicas de valor
    local valueProps = {"PerSecond", "Rate", "Value", "Money", "Price", "Worth", "BrainrotPerSecond", "BrainrotRate", "PerSecondValue", "MoneyPerSecond", "RateValue", "Brainrot", "BrainrotValue", "BrainrotWorth", "BrainrotMoney", "BrainrotPrice"}
    
    -- Buscar no parentModel
    for _, propName in pairs(valueProps) do
        for _, descendant in pairs(parentModel:GetDescendants()) do
            if descendant.Name == propName and (descendant:IsA("IntValue") or descendant:IsA("NumberValue") or descendant:IsA("StringValue")) then
                local propValue = tonumber(descendant.Value) or 0
                if propValue > highestValue then
                    highestValue = propValue
                    valueSource = propName .. " (parentModel)"
                    print("💰 VALOR ENCONTRADO:", propName, "=", propValue, "Caminho:", descendant:GetFullName())
                end
            end
        end
    end
    
    -- Buscar no rarityParent
    if rarityParent then
        for _, propName in pairs(valueProps) do
            for _, descendant in pairs(rarityParent:GetDescendants()) do
                if descendant.Name == propName and (descendant:IsA("IntValue") or descendant:IsA("NumberValue") or descendant:IsA("StringValue")) then
                    local propValue = tonumber(descendant.Value) or 0
                    if propValue > highestValue then
                        highestValue = propValue
                        valueSource = propName .. " (rarityParent)"
                        print("💰 VALOR ENCONTRADO:", propName, "=", propValue, "Caminho:", descendant:GetFullName())
                    end
                end
            end
        end
    end
    
    -- Priorizar valor por segundo sobre valor total
    local finalValue = perSecondValue > 0 and perSecondValue or highestValue
    local finalSource = perSecondValue > 0 and perSecondSource or valueSource
    
    if finalValue > 0 then
        print("✅ VALOR FINAL ENCONTRADO:", formatValue(finalValue), "Fonte:", finalSource)
        if perSecondValue > 0 then
            print("💰 Valor por segundo:", formatValue(perSecondValue))
        end
        if highestValue > 0 and highestValue ~= perSecondValue then
            print("💎 Valor total:", formatValue(highestValue))
        end
    else
        print("❌ NENHUM VALOR ENCONTRADO!")
    end
    
    return finalValue, finalSource
end

-- Função para verificar se o brainrot está em estado de fusing
local function isBrainrotFusing(parentModel, rarityParent)
    -- Verificar se há indicadores de fusing no modelo
    for _, descendant in pairs(parentModel:GetDescendants()) do
        if descendant:IsA("TextLabel") then
            local text = descendant.Text
            if text then
                -- Verificar por texto "FUSING" ou similar (mais padrões)
                local upperText = text:upper()
                if upperText:find("FUSING") or upperText:find("FUSION") or 
                   upperText:find("FUS") or upperText:find("MERGING") or
                   upperText:find("COMBINING") or upperText:find("PROCESSING") then
                    print("🔍 FUSING detectado em TextLabel:", text, "Caminho:", descendant:GetFullName())
                    return true, text
                end
            end
        elseif descendant:IsA("StringValue") or descendant:IsA("IntValue") or descendant:IsA("NumberValue") then
            local value = tostring(descendant.Value)
            local upperValue = value:upper()
            if upperValue:find("FUSING") or upperValue:find("FUSION") or 
               upperValue:find("FUS") or upperValue:find("MERGING") or
               upperValue:find("COMBINING") or upperValue:find("PROCESSING") then
                print("🔍 FUSING detectado em Value:", value, "Caminho:", descendant:GetFullName())
                return true, value
            end
        end
    end
    
    -- Verificar também no rarityParent
    if rarityParent then
        for _, descendant in pairs(rarityParent:GetDescendants()) do
            if descendant:IsA("TextLabel") then
                local text = descendant.Text
                if text then
                    local upperText = text:upper()
                    if upperText:find("FUSING") or upperText:find("FUSION") or 
                       upperText:find("FUS") or upperText:find("MERGING") or
                       upperText:find("COMBINING") or upperText:find("PROCESSING") then
                        print("🔍 FUSING detectado em TextLabel:", text, "Caminho:", descendant:GetFullName())
                        return true, text
                    end
                end
            elseif descendant:IsA("StringValue") or descendant:IsA("IntValue") or descendant:IsA("NumberValue") then
                local value = tostring(descendant.Value)
                local upperValue = value:upper()
                if upperValue:find("FUSING") or upperValue:find("FUSION") or 
                   upperValue:find("FUS") or upperValue:find("MERGING") or
                   upperValue:find("COMBINING") or upperValue:find("PROCESSING") then
                    print("🔍 FUSING detectado em Value:", value, "Caminho:", descendant:GetFullName())
                    return true, value
                end
            end
        end
    end
    
    -- Verificar também no workspace para banners de fusing
    local workspaceChildren = workspace:GetDescendants()
    for _, obj in pairs(workspaceChildren) do
        if obj:IsA("TextLabel") and obj.Text then
            local upperText = obj.Text:upper()
            if upperText:find("FUSING") or upperText:find("FUSION") then
                -- Verificar se este banner está próximo ao brainrot
                if parentModel and obj.Parent and obj.Parent:IsA("BasePart") then
                    local distance = (obj.Parent.Position - parentModel.Position).Magnitude
                    if distance < 50 then -- Dentro de 50 studs
                        print("🔍 FUSING detectado em Banner próximo:", obj.Text, "Distância:", distance)
                        return true, obj.Text
                    end
                end
            end
        end
    end
    
    return false, nil
end

-- Cache para otimização
local lastUpdateTime = 0
local UPDATE_INTERVAL = 5 -- Atualizar apenas a cada 5 segundos
local currentTop3 = {} -- Cache dos top 3 atuais
local rgbAnimationActive = false -- Controle da animação RGB

-- Função para atualizar ESP de brainrots (SIMPLES E FUNCIONAL - apenas os 3 mais caros)
local function updateBrainrotESP()
    local currentTime = tick()
    
    -- Só atualiza se passou o intervalo mínimo
    if currentTime - lastUpdateTime < UPDATE_INTERVAL then
        return
    end
    
    lastUpdateTime = currentTime
    local allBrainrots = {}
    
    -- Coletar todos os brainrots válidos (volta para método original que funciona)
    for _, plot in pairs(workspace.Plots:GetChildren()) do
        if plot.Name ~= plotName then -- Não mostrar na própria base
            for _, child in pairs(plot:GetDescendants()) do
                if child.Name == "Rarity" and child:IsA("TextLabel") and RaritySettings[child.Text] then
                    local parentModel = child.Parent.Parent
                    
                    -- Verificar se o brainrot está em estado de fusing
                    local isFusing, fusingText = isBrainrotFusing(parentModel, child.Parent)
                    if isFusing then
                        continue -- Pular este brainrot
                    end
                    
                    if activeESP[child.Text] then
                        -- Encontrar valor do brainrot
                        local value, valueProp = findBrainrotValue(parentModel, child.Parent)
                        local displayName = child.Parent.DisplayName.Text
                        
                        if value > 0 then
                            table.insert(allBrainrots, {
                                model = parentModel,
                                rarity = child.Text,
                                name = displayName,
                                value = value
                            })
                        end
                    end
                end
            end
        end
    end
    
    -- Ordenar por valor (maior para menor)
    table.sort(allBrainrots, function(a, b) return a.value > b.value end)
    
    -- Verificar se os top 3 mudaram (evitar recriar desnecessariamente)
    local top3Changed = false
    local newTop3 = {}
    local topCount = math.min(3, #allBrainrots)
    
    for i = 1, topCount do
        local brainrot = allBrainrots[i]
        newTop3[i] = {
            model = brainrot.model,
            rarity = brainrot.rarity,
            name = brainrot.name,
            value = brainrot.value
        }
        
        -- Verificar se mudou
        if not currentTop3[i] or 
           currentTop3[i].model ~= brainrot.model or 
           currentTop3[i].value ~= brainrot.value then
            top3Changed = true
        end
    end
    
    -- Só recriar se mudou
    if top3Changed then
        -- Remover ESPs antigos
        for _, plot in pairs(workspace.Plots:GetChildren()) do
            for _, child in pairs(plot:GetDescendants()) do
                if child.Name:find("BrainrotESP_") then
                    child:Destroy()
                end
            end
        end
        
        -- Criar novos ESPs apenas para os 3 mais caros
        for i = 1, topCount do
            local brainrot = newTop3[i]
            local settings = RaritySettings[brainrot.rarity]
            local valueText = formatValue(brainrot.value) .. "/s"
            
            -- Criar BillboardGui
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "BrainrotESP_" .. i
            billboard.Size = settings.Size
            billboard.StudsOffset = Vector3.new(0, 5, 0)
            billboard.AlwaysOnTop = true
            billboard.Adornee = brainrot.model
            
            -- Label para nome e ranking (RGB se for #1, senão amarelo)
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Name = "NameLabel"
            nameLabel.Text = "#" .. i .. " " .. brainrot.name
            nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
            nameLabel.Position = UDim2.new(0, 0, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.TextScaled = true
            nameLabel.TextColor3 = i == 1 and Color3.fromRGB(255, 0, 255) or Color3.fromRGB(255, 255, 0) -- RGB para #1, amarelo para outros
            nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
            nameLabel.TextStrokeTransparency = 0.2
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextXAlignment = Enum.TextXAlignment.Center
            nameLabel.TextYAlignment = Enum.TextYAlignment.Center
            
            -- Label para raridade (RGB se for #1, senão amarelo)
            local rarityLabel = Instance.new("TextLabel")
            rarityLabel.Name = "RarityLabel"
            rarityLabel.Text = brainrot.rarity
            rarityLabel.Size = UDim2.new(1, 0, 0.3, 0)
            rarityLabel.Position = UDim2.new(0, 0, 0.4, 0)
            rarityLabel.BackgroundTransparency = 1
            rarityLabel.TextScaled = true
            rarityLabel.TextColor3 = i == 1 and Color3.fromRGB(255, 0, 255) or Color3.fromRGB(255, 255, 0) -- RGB para #1, amarelo para outros
            rarityLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
            rarityLabel.TextStrokeTransparency = 0.2
            rarityLabel.Font = Enum.Font.GothamBold
            rarityLabel.TextXAlignment = Enum.TextXAlignment.Center
            rarityLabel.TextYAlignment = Enum.TextYAlignment.Center
            
            -- Label para dinheiro (sempre verde)
            local moneyLabel = Instance.new("TextLabel")
            moneyLabel.Name = "MoneyLabel"
            moneyLabel.Text = "💰 " .. valueText
            moneyLabel.Size = UDim2.new(1, 0, 0.3, 0)
            moneyLabel.Position = UDim2.new(0, 0, 0.7, 0)
            moneyLabel.BackgroundTransparency = 1
            moneyLabel.TextScaled = true
            moneyLabel.TextColor3 = Color3.fromRGB(0, 255, 0) -- Sempre verde
            moneyLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
            moneyLabel.TextStrokeTransparency = 0.2
            moneyLabel.Font = Enum.Font.GothamBold
            moneyLabel.TextXAlignment = Enum.TextXAlignment.Center
            moneyLabel.TextYAlignment = Enum.TextYAlignment.Center
            
            nameLabel.Parent = billboard
            rarityLabel.Parent = billboard
            moneyLabel.Parent = billboard
            billboard.Parent = brainrot.model
            
            -- Adicionar efeito RGB animado para o #1 (otimizado)
            if i == 1 and not rgbAnimationActive then
                rgbAnimationActive = true
                task.spawn(function()
                    while billboard.Parent and rgbAnimationActive do
                        local time = tick()
                        local r = math.sin(time * 1.5) * 0.5 + 0.5
                        local g = math.sin(time * 1.5 + 2) * 0.5 + 0.5
                        local b = math.sin(time * 1.5 + 4) * 0.5 + 0.5
                        
                        nameLabel.TextColor3 = Color3.new(r, g, b)
                        rarityLabel.TextColor3 = Color3.new(r, g, b)
                        
                        task.wait(0.2) -- Mais lento para reduzir lag
                    end
                    rgbAnimationActive = false
                end)
            end
        end
        
        -- Atualizar cache
        currentTop3 = newTop3
        print("🔄 ESP atualizado - Top 3 brainrots recriados")
    end
end

-- Função para limpar todos os ESPs
local function clearAllESP()
    for _, plot in pairs(workspace.Plots:GetChildren()) do
        for _, child in pairs(plot:GetDescendants()) do
            if child.Name:find("_ESP") then
                child:Destroy()
            end
        end
    end
    print("🧹 Todos os ESPs foram limpos")
end

-- Função para alternar ESP específico
local function toggleBrainrotESP(rarity, enable)
    activeESP[rarity] = enable
    print("🎛️ ESP", rarity, enable and "ATIVADO" or "DESATIVADO")
end

-- ===============================================
-- INICIALIZAÇÃO
-- ===============================================

-- Aguardar carregamento
wait(2)

-- Ativar todos os ESPs por padrão
for rarity, _ in pairs(RaritySettings) do
    activeESP[rarity] = true
end

-- Função de teste para verificar se o ESP está funcionando
local function testESP()
    print("🧪 TESTE ESP - Verificando se há brainrots...")
    local foundBrainrots = 0
    local fusingBrainrots = 0
    
    for _, plot in pairs(workspace.Plots:GetChildren()) do
        if plot.Name ~= plotName then
            for _, child in pairs(plot:GetDescendants()) do
                if child.Name == "Rarity" and child:IsA("TextLabel") and RaritySettings[child.Text] then
                    local parentModel = child.Parent.Parent
                    local isFusing, fusingText = isBrainrotFusing(parentModel, child.Parent)
                    
                    if isFusing then
                        fusingBrainrots = fusingBrainrots + 1
                        print("⚠️ Brainrot em FUSING:", child.Parent.DisplayName.Text, "Estado:", fusingText)
                    else
                        foundBrainrots = foundBrainrots + 1
                        print("🧠 Brainrot disponível:", child.Parent.DisplayName.Text, "Raridade:", child.Text)
                    end
                end
            end
        end
    end
    
    print("📊 Total de brainrots disponíveis:", foundBrainrots)
    print("⚠️ Total de brainrots em FUSING:", fusingBrainrots)
    return foundBrainrots > 0
end

-- Função para verificar se um player é amigo
local function isFriend(playerName)
    for _, friendName in pairs(friendList) do
        if playerName == friendName then
            return true
        end
    end
    return false
end

-- ESP de Players (do espanalize)
local function updatePlayerESP()
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer and player.Character then
            local character = player.Character
            local humanoid = character:FindFirstChild("Humanoid")
            local head = character:FindFirstChild("Head")
            
            if humanoid and head then
                -- Verificar se é amigo ou inimigo
                local isPlayerFriend = isFriend(player.Name)
                local highlightColor = isPlayerFriend and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0) -- Verde para amigos, vermelho para inimigos
                
                -- Criar ou atualizar highlight para o corpo todo
                local highlight = character:FindFirstChild("ESP_Highlight")
                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Name = "ESP_Highlight"
                    highlight.Parent = character
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    highlight.FillTransparency = 0.3
                    highlight.OutlineTransparency = 0
                end
                highlight.FillColor = highlightColor -- Atualizar cor baseado em amigo/inimigo
                
                -- Mostrar nome do jogador (menor e na frente)
                local billboard = head:FindFirstChild("ESP_Billboard")
                if not billboard then
                    billboard = Instance.new("BillboardGui")
                    billboard.Name = "ESP_Billboard"
                    billboard.Parent = head
                    billboard.Size = UDim2.new(0, 100, 0, 25)
                    billboard.StudsOffset = Vector3.new(0, 2, 0)
                    billboard.AlwaysOnTop = true -- Na frente
                    
                    local textLabel = Instance.new("TextLabel")
                    textLabel.Parent = billboard
                    textLabel.Size = UDim2.new(1, 0, 1, 0)
                    textLabel.BackgroundTransparency = 1
                    textLabel.Text = player.Name
                    textLabel.TextStrokeTransparency = 0.2
                    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                    textLabel.TextScaled = true
                    textLabel.Font = Enum.Font.GothamBold -- Fonte mais legível
                end
                
                -- Atualizar cor do texto baseado em amigo/inimigo
                local textLabel = billboard:FindFirstChild("TextLabel")
                if textLabel then
                    textLabel.TextColor3 = isPlayerFriend and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 255, 255) -- Verde para amigos, branco para inimigos
                end
            end
        end
    end
end

-- Loop principal otimizado
task.spawn(function()
    while true do
        if next(activeESP) ~= nil then
            updateBrainrotESP()
        end
        updatePlayerESP() -- Adicionar ESP de players
        task.wait(2) -- Aumentado para 2 segundos para reduzir lag
    end
end)

-- Função de debug para mostrar todos os textos próximos aos brainrots
local function debugBrainrotTexts()
    print("🔍 DEBUG - Mostrando TODOS os textos próximos aos brainrots...")
    
    for _, plot in pairs(workspace.Plots:GetChildren()) do
        if plot.Name ~= plotName then
            for _, child in pairs(plot:GetDescendants()) do
                if child.Name == "Rarity" and child:IsA("TextLabel") and RaritySettings[child.Text] then
                    local parentModel = child.Parent.Parent
                    local displayName = child.Parent.DisplayName.Text
                    
                    print("🧠 BRAINROT:", displayName, "Raridade:", child.Text)
                    print("   📍 Posição:", parentModel.Position)
                    
                    -- Mostrar todos os textos próximos (dentro de 100 studs)
                    for _, obj in pairs(workspace:GetDescendants()) do
                        if obj:IsA("TextLabel") and obj.Text and obj.Text ~= "" then
                            if obj.Parent and obj.Parent:IsA("BasePart") and obj.Parent.Position then
                                local distance = (obj.Parent.Position - parentModel.Position).Magnitude
                                if distance < 100 then
                                    print("   📝 Texto próximo:", obj.Text, "Distância:", math.floor(distance), "Caminho:", obj:GetFullName())
                                end
                            end
                        end
                    end
                    print("")
                end
            end
        end
    end
end

-- Comandos globais
_G.toggleBrainrotESP = toggleBrainrotESP
_G.clearAllESP = clearAllESP
_G.updateBrainrotESP = updateBrainrotESP
_G.testESP = testESP
_G.debugBrainrotTexts = debugBrainrotTexts

print("🧠 BRAINROT ESP ATIVADO!")
print("🎯 Mostrando brainrots por raridade:")
print("   🟡 Legendary (Amarelo)")
print("   🔴 Mythic (Vermelho)")
print("   🟣 Brainrot God (Roxo)")
print("   ⚫ Secret (Preto)")
print("")
print("✨ Mutações:")
print("   🥇 Gold (Dourado)")
print("   💎 Diamond (Azul)")
print("   🌈 Rainbow (Rosa)")
print("   🩸 Bloodrot (Vermelho escuro)")
print("")
print("💡 Comandos:")
print("   _G.toggleBrainrotESP('Legendary', true/false)")
print("   _G.clearAllESP()")
print("   _G.updateBrainrotESP()")
print("   _G.testESP() - Testar se há brainrots")
print("   _G.debugBrainrotTexts() - Debug: mostrar todos os textos próximos")
print("")
print("🔍 Procurando brainrots...")

-- Executar teste inicial
wait(1)
testESP()

