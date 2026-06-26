-- ==========================================================
-- MOCTA NATIVE OPENER (MANUAL UNLIMITED BURST)
-- Build: UI Button, Auto-Equip, Drain Until Empty
-- ==========================================================

local success, errorMessage = pcall(function()
    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    -- Config Default
    local TargetToolName = "Block Cup"

    local Window = Rayfield:CreateWindow({
        Name = "Mocta Manual Opener", 
        LoadingTitle = "Memuat Mode Pembantaian...", 
        ConfigurationSaving = { Enabled = false }, 
        Theme = "DarkBlue"
    })

    local TabAction = Window:CreateTab("💣 Action Center", 4483362458)
    
    TabAction:CreateParagraph({
        Title = "⚠️ PERINGATAN UNLIMITED BURST", 
        Content = "Begitu tombol ditekan, bot akan terus mencari, memegang, dan mengeklik item sampai STOK DI TAS BENAR-BENAR HABIS (0)."
    })

    TabAction:CreateInput({
        Name = "Nama Item Target:",
        PlaceholderText = "Contoh: Block Cup",
        CurrentValue = "Block Cup",
        RemoveTextAfterFocusLost = false,
        Callback = function(Text)
            TargetToolName = Text
            Rayfield:Notify({Title = "Target Diperbarui", Content = "Mengunci target ke: " .. TargetToolName, Duration = 2})
        end
    })

    TabAction:CreateButton({
        Name = "🚀 EKSEKUSI UNLIMITED BURST",
        Callback = function()
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            local backpack = LocalPlayer:FindFirstChild("Backpack")
            
            if not char or not humanoid or not backpack then
                Rayfield:Notify({Title = "Error", Content = "Karakter atau Tas tidak ditemukan!", Duration = 3})
                return
            end

            -- Pengecekan awal sebelum masuk loop
            local initialCheck = char:FindFirstChild(TargetToolName) or backpack:FindFirstChild(TargetToolName)
            if not initialCheck then
                Rayfield:Notify({Title = "Gagal", Content = "Item '" .. TargetToolName .. "' tidak ada di tas.", Duration = 3})
                return
            end

            Rayfield:Notify({Title = "ACTION!", Content = "Memulai pembantaian stok " .. TargetToolName .. "...", Duration = 3})

            -- Masukkan ke task.spawn agar UI tidak macet saat looping berjalan
            task.spawn(function()
                local activeTool = char:FindFirstChild(TargetToolName) or backpack:FindFirstChild(TargetToolName)
                local clickCount = 0
                
                -- Selama barang masih ada, hajar terus!
                while activeTool do
                    -- Pastikan barang ada di tangan (Equipped)
                    if activeTool.Parent ~= char then
                        humanoid:EquipTool(activeTool)
                        task.wait(0.1) -- Jeda animasi equip
                    end
                    
                    -- Spam klik
                    activeTool:Activate()
                    clickCount = clickCount + 1
                    task.wait(0.1) -- Jeda aman agar tidak nge-freeze
                    
                    -- Cek apakah barang sudah hancur/terpakai
                    if not activeTool or not activeTool.Parent or activeTool.Parent == workspace then
                        -- Jika hilang, sapu ulang tas untuk mencari sisa stok
                        activeTool = char:FindFirstChild(TargetToolName) or backpack:FindFirstChild(TargetToolName)
                    end
                end
                
                Rayfield:Notify({Title = "Habis Terkuras!", Content = "Eksekusi selesai. Total klik: " .. clickCount .. "x.", Duration = 5})
                print("[MOCTA] Pembantaian selesai. Total " .. TargetToolName .. " yang dieksekusi: " .. clickCount)
            end)
        end
    })

end)

if not success then
    warn("MOCTA MANUAL OPENER ERROR: " .. tostring(errorMessage))
end
