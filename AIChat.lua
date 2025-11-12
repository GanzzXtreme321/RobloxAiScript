-- AI Chat Bot for Roblox - Complete Script
local Delta = loadstring(game:HttpGet("https://raw.githubusercontent.com/deltaidk/delta/main/src.lua"))()
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local Config = {
    APIKey = "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",
    MaxLimit = 20,
    Cooldown = 25,
    AutoRespondMention = true,
    AutoRespondQuestion = true,
    AutoRespondGreeting = true,
    RespondToAll = false
}

local ChatHistory = {}
local MessageCount = 0
local LastReset = os.time()
local LastChat = 0
local IsCooldown = false

local function ResetLimit()
    local currentTime = os.time()
    if currentTime - LastReset >= 3600 then
        MessageCount = 0
        LastReset = currentTime
    end
end

local function CheckLimit()
    ResetLimit()
    return MessageCount < Config.MaxLimit
end

local function SendToChatGPT(message)
    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. Config.APIKey
    }
    
    local payload = {
        model = "gpt-3.5-turbo",
        messages = {
            {
                role = "system", 
                content = "You are a friendly Roblox player. Respond briefly in 1-2 sentences. Use the same language as the user's question. If they speak Indonesian, respond in Indonesian. If they speak English, respond in English. Keep it casual and game-appropriate."
            },
            {
                role = "user",
                content = message
            }
        },
        max_tokens = 70,
        temperature = 0.7
    }
    
    local success, response = pcall(function()
        local result = HttpService:PostAsync(
            "https://api.openai.com/v1/chat/completions",
            HttpService:JSONEncode(payload),
            headers
        )
        return result
    end)
    
    if success then
        local data = HttpService:JSONDecode(response)
        if data.choices and data.choices[1] then
            return data.choices[1].message.content
        else
            return "Error: Invalid response from AI"
        end
    else
        return "Error: Failed to connect to AI service"
    end
end

local function AutoChat(message)
    if IsCooldown then
        Delta:Notify("Cooldown", "Please wait " .. (Config.Cooldown - (os.time() - LastChat)) .. " seconds")
        return
    end
    
    if not CheckLimit() then
        Delta:Notify("Limit Reached", "Chat limit reached for this hour")
        return
    end
    
    Delta:Notify("AI Thinking", "Processing message...")
    
    local response = SendToChatGPT(message)
    
    if response and not string.find(response, "Error") then
        MessageCount = MessageCount + 1
        LastChat = os.time()
        
        IsCooldown = true
        delay(Config.Cooldown, function()
            IsCooldown = false
        end)
        
        table.insert(ChatHistory, {
            Time = os.time(),
            Message = message,
            Response = response
        })
        
        game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(response, "All")
        
        Delta:Notify("AI Response", "Message sent successfully!")
    else
        Delta:Notify("AI Error", response)
    end
end

local function SetupAutoRespond()
    local function ProcessChat(sender, message)
        if sender == LocalPlayer then return end
        
        local msg = string.lower(message)
        local playerName = string.lower(LocalPlayer.Name)
        
        local shouldRespond = false
        local context = ""
        
        if Config.AutoRespondMention and string.find(msg, playerName) then
            shouldRespond = true
            context = "Player " .. sender.Name .. " mentioned your name. They said: " .. message .. ". Give a friendly response."
        end
        
        if Config.AutoRespondQuestion and (string.find(msg, "?") or string.find(msg, "how to") or string.find(msg, "where is") or string.find(msg, "what is")) then
            shouldRespond = true
            context = "Player " .. sender.Name .. " asked a question: " .. message .. ". Provide a helpful answer."
        end
        
        if Config.AutoRespondGreeting and (string.find(msg, "hello") or string.find(msg, "hi ") or string.find(msg, "hey") or string.find(msg, "halo") or string.find(msg, "hai")) then
            shouldRespond = true
            context = "Player " .. sender.Name .. " said greeting: " .. message .. ". Give a friendly greeting response."
        end
        
        if Config.RespondToAll then
            shouldRespond = true
            context = "Player " .. sender.Name .. " said: " .. message .. ". Respond naturally as a fellow player."
        end
        
        if shouldRespond and CheckLimit() and not IsCooldown then
            AutoChat(context)
        end
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            player.Chatted:Connect(function(message)
                ProcessChat(player, message)
            end)
        end
    end
    
    Players.PlayerAdded:Connect(function(player)
        player.Chatted:Connect(function(message)
            ProcessChat(player, message)
        end)
    end)
end

local Window = Delta:Window("AI Chat Bot", "Smart Auto Respond", Enum.KeyCode.RightControl)

local MainTab = Window:Tab("Main Chat", "rbxassetid://123456789")
MainTab:Textbox("Manual Chat", "Type message for AI", true, function(text)
    if text and text ~= "" then
        AutoChat(text)
    end
end)

MainTab:Button("Test English", "Test English response", function()
    AutoChat("Hello! Introduce yourself as an AI assistant in this game")
end)

MainTab:Button("Test Indonesian", "Test Indonesian response", function()
    AutoChat("Halo! Perkenalkan dirimu sebagai asisten AI di game ini")
end)

local limitLabel = MainTab:Label("Limit: " .. MessageCount .. "/" .. Config.MaxLimit)

local AutoTab = Window:Tab("Auto Respond", "rbxassetid://123456789")
AutoTab:Toggle("When Mentioned", "Respond when name is mentioned", true, function(state)
    Config.AutoRespondMention = state
end)
AutoTab:Toggle("When Question", "Respond to questions", true, function(state)
    Config.AutoRespondQuestion = state
end)
AutoTab:Toggle("When Greeting", "Respond to greetings", true, function(state)
    Config.AutoRespondGreeting = state
end)
AutoTab:Toggle("Respond All", "Respond to all chats (USE CAREFULLY)", false, function(state)
    Config.RespondToAll = state
    if state then
        Delta:Notify("Warning", "Respond All enabled - may be considered spam!")
    end
end)

local SettingsTab = Window:Tab("Settings", "rbxassetid://123456789")
SettingsTab:Slider("Max Limit", "Max chats per hour", 10, 50, 20, false, function(value)
    Config.MaxLimit = value
end)
SettingsTab:Slider("Cooldown", "Cooldown between chats (seconds)", 15, 60, 25, true, function(value)
    Config.Cooldown = value
end)
SettingsTab:Button("Reset Limit", "Reset limit manually", function()
    MessageCount = 0
    Delta:Notify("Success", "Limit reset successfully!")
end)

local InfoTab = Window:Tab("Info", "rbxassetid://123456789")
InfoTab:Label("AI Chat Bot v2.0")
InfoTab:Label("Multi-language Support")
InfoTab:Label("Remaining: " .. (Config.MaxLimit - MessageCount) .. " chats")

while true do
    wait(30)
    ResetLimit()
    limitLabel:Refresh("Limit: " .. MessageCount .. "/" .. Config.MaxLimit)
    InfoTab:RefreshLabel("Remaining: " .. (Config.MaxLimit - MessageCount) .. " chats")
end

SetupAutoRespond()
Delta:Notify("AI Chat Ready", "System activated successfully! Press RightControl to open menu.")
