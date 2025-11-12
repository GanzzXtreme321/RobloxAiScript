local Delta = loadstring(game:HttpGet("https://raw.githubusercontent.com/deltaidk/delta/main/src.lua"))()
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- Configuration
local Config = {
    APIKey = "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",
    MaxLimit = 25,
    Cooldown = 15,
    AutoRespond = true
}

-- System variables
local MessageCount = 0
local LastChat = 0
local IsCooldown = false

-- Send to ChatGPT function
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
                content = "You are a friendly Roblox player. Keep responses short 1-2 sentences. Be casual and game-appropriate."
            },
            {
                role = "user",
                content = message
            }
        },
        max_tokens = 50,
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
            return "Nice!"
        end
    else
        return "Hey!"
    end
end

-- Auto chat function
local function AutoChat(message)
    if IsCooldown then
        return
    end
    
    if os.time() - LastChat < Config.Cooldown then
        return
    end
    
    local response = SendToChatGPT(message)
    
    if response then
        game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(response, "All")
        LastChat = os.time()
        IsCooldown = true
        delay(Config.Cooldown, function()
            IsCooldown = false
        end)
    end
end

-- Auto respond to all chats
local function SetupAutoRespond()
    local function ProcessChat(sender, message)
        if sender == LocalPlayer then return end
        if not Config.AutoRespond then return end
        
        local context = "Player said: " .. message .. ". Give a short friendly response as a game player."
        AutoChat(context)
    end
    
    -- For existing players
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            player.Chatted:Connect(function(message)
                ProcessChat(player, message)
            end)
        end
    end
    
    -- For new players
    Players.PlayerAdded:Connect(function(player)
        player.Chatted:Connect(function(message)
            ProcessChat(player, message)
        end)
    end)
end

-- Simple UI
local Window = Delta:Window("AI Auto Chat", "Simple AI Respond", Enum.KeyCode.RightControl)

local MainTab = Window:Tab("Main", "rbxassetid://123456789")
MainTab:Toggle("Auto Respond", "Enable/disable auto respond", true, function(state)
    Config.AutoRespond = state
end)

MainTab:Button("Test Chat", "Send test message", function()
    AutoChat("Say hello to everyone in the game!")
end)

MainTab:Label("Cooldown: " .. Config.Cooldown .. "s")

-- Initialize
SetupAutoRespond()
print("AI Auto Chat Activated!")
