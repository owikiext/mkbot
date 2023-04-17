onTalk(function(name, level, mode, text, channelId, pos)
    if mode == 8 and channelId == 10 then
        local pattern = "(%d+)%/(%d+)"
        local current_amount, target_amount = text:match(pattern)
        if current_amount and target_amount then
            print(current_amount .. ' / ' .. target_amount)
            if current_amount == target_amount then
                playAlarm()
            end
        end
    end
end)
