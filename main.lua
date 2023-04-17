VOCATION = 0
VOCATION_POWER = 0
local vocations =
{
    ['knight'] = {1, 1},
    ['elite knight'] = {1,2},
    ['barbarian'] = {1,3},
    ['ninja'] = {1,4},
    ['druid'] = {2,1},
    ['elder druid'] = {2,2},
    ['holy priest'] = {2,3},
    ['elementalist'] = {2,4},
    ['sorcerer'] = {3,1},
    ['master sorcerer'] = {3,2},
    ['dark wizard'] = {3,3},
    ['illusionist'] = {3,4},
    ['paladin'] = {4,1},
    ['royal paladin'] = {4,2},
    ['nobelman'] = {4,3},
    ['elf'] = {4,4},
}
TELEPORT_ITEM_TIMER = -1000

ShieldNone = 0
ShieldWhiteYellow = 1
ShieldWhiteBlue = 2
ShieldBlue = 3
ShieldYellow = 4
ShieldBlueSharedExp = 5
ShieldYellowSharedExp = 6
ShieldBlueNoSharedExpBlink = 7
ShieldYellowNoSharedExpBlink = 8
ShieldBlueNoSharedExp = 9
ShieldYellowNoSharedExp = 10
ShieldGray = 11

onTextMessage(function(mode, text)
	if mode == 20 and VOCATION == 0 then
        local lines = {}
        for line in text:gmatch("(.-)\n") do
            table.insert(lines, line)
        end
        if #lines == 0 then
            return
        end
        local textLower = lines[1]:lower()
		if textLower:find("you see yourself. you are") then
            local voc_name = textLower:match("you are a ([%w%s]+)%.")
            if voc_name == nil then
                voc_name = textLower:match("you are an ([%w%s]+)%.")
            end
            print(textLower)
            print(voc_name)
            if voc_name and vocations[voc_name] then
                VOCATION = vocations[voc_name][1]
                VOCATION_POWER = vocations[voc_name][2]
            end
		end
        return
	end
end)

g_game.look(player)

local function OnLoad()

    dofile('lib/GetDirectionFromPos.lua')
    dofile('lib/GetPosFromDir.lua')
    dofile('lib/SafeCall.lua')
    dofile('lib/PosToID.lua')
    dofile('lib/Class.lua')
    dofile('lib/AsyncTask.lua')
    dofile('lib/FileManager.lua')
    dofile('lib/UI.lua')
    dofile('lib/Widget.lua')
    dofile('lib/Settings.lua')
    dofile('lib/Menu.lua')
    dofile('lib/ObjectManager.lua')
    dofile('lib/Spell.lua')

    dofile('src/Container.lua')
    dofile('src/AutoLoot.lua')
    dofile('src/Walker.lua')
    dofile('src/FollowBot.lua')
    dofile('src/Invite.lua')
    --dofile('src/hp.lua')
    dofile('src/Attris.lua')
    dofile('src/SpellBot.lua')
    dofile('src/AutoTask.lua')
end

local __loader__
__loader__ = function()
    local pos = player and player:getPosition() or { x = 0, y = 0, z = 0 }
    local name = (pos and pos.x and pos.x > 0) and player:getName() or ""
    if VOCATION > 0 and name and #name > 0 then
        --if modules.game_console and modules.game_console.onBackslashMessage and modules.game_textmessage and modules.game_textmessage.displayDebugMessage then
        --  onBackslashMessage = modules.game_console.onBackslashMessage
        --  modules.game_console.clearBackslashMessageCbs()
        --  sendMessage = modules.game_console.sendMessage
        --  printMessage = modules.game_textmessage.displayDebugMessage
        OnLoad()
        print("voc:", VOCATION, VOCATION_POWER, "now:", now, "pos:", PosToID(pos))
        return
        --end
    end
    g_game.look(player)
    
    schedule(100, __loader__)
end
__loader__()


--[[
##Commands##

!online - show online players.
---
!frags - show you how many frags do you have.
---
!info - show your current stats information.
---
!uptime - show the server uptime.
---
!time - show the server current time.
---
!pvp - show server pvp type.
---
!points - show your current premium points balance.
---
!transactions - show your successful transactions.
---
!broadcast - It will send a global message to all players.
---
!token_market - check Token Market page to see all available commands for this command.
---
!gold_market - check Gold Market page to see all available commands for this command.
---
!attrpoints - show your current attribute points and bonuses from them.
---
!dailypoints - show your current daily tasks points, you will gain them from doing daily tasks.
---
!goldpoints - show your current gold points.	
---
!safepvp - enable/disable safe pvp mode. (Safe pvp mode is used to let you attack only skulled players so you won't get a skull if someone next to you without skull)
---
!q - show your money balance which is in your backpack..
---
!bosses - check bosses if alive or killed and shows time left to spawn if killed.
---
!dungeons - check timers of dungeons.
---
!serverinfo - show you server info, exp rate, loot rate, etc.
---
!changesex - change your sex. (male or female), cost: 3 premium days.
---
!dps - show your best damage per second on trainers.
---
!autoloot - check commands for Auto Loot system.
---
!promotion - buy first promotion, cost 2cc.
---
!tasks - check you running tasks and how many you killed.
---
!bp - buy Backpack, cost 1cc.
---
!aol - buy Amulet of Loss, cost 1cc.
---
!elven - buy Elven Amulet, cost 5cc.
---
!ssa - buy Stone Skin Amulet, cost 10cc.
---
!rof - buy Ring of Fire which protects you 60% from fire damage, cost: 10cc.
---
!rop - buy Ring of Physical which protects you 10% from physical damage, cost: 10cc.
---
!dice - buy Dice, cost: 1cc.
---
!food - buy 100 Brown Mushrooms, cost: 1cc.
---
!paw - buy Paw Amulet which gives you 250 hp/mana per second also works as a forever aol, cost: 1 uber token.
---
!star - buy Starlight Amulet which gives you 5 all skills also works as a forever aol, cost: 1 uber token.
---
!balance - show your current bank balance.
---
!hpmana - gives you information about your current health and mana.
---
!bless - buy Blessing, cost: 30 crystal coins. Makes you lose only 1 level no matter what level you are.
---
!autobless - activates the auto blessing system, ex: !autobless on / !autobless off.
---
!magiceffect - enable or disable ingame magic effects, ex: !magiceffect on / !magiceffect off.
---
!distanceeffect - enable or disable ingame distance effects, ex: !distanceeffect on / !distanceeffect off.
---
!spelltext - enable or disable ingame spells text, ex: !spelltext on / !spelltext off.
---
!report - report any bugs or player ingame, ex: !report Bug is here GM, check it please.
---
!spells - show you your spells ingame.
---
!explopoints - show you how many explorer points do you have.
---
!buyhouse - buy house.
---
!sellhouse/alana grav - sell hours, ex: !sellhouse "PlayerName" / alana grav "PlayerName".
---
alana sio - kick someone from your house, ex: alana sio "PlayerName".
---
aleta grav - add someone who can open this house door.
---
aleta sio - add someone who can enter your house but can not open doors.
---
aleta som - add someone to your house with more abilities like using aleta sio, open doors.
---
!leavehouse - leave house.
---
!createguild - create guild ingame, ex: !createguild Noobs.
---
!joinguild - join guild ingame after someone invited you, ex: !joinguild Noobs.
---
/invite - invite someone to your guild, ex: /invite PlayerName. (Only in guild chat)
---
/commands - more commands for guild management. (Only in guild chat)
---
!war - invite another guild to war or accept war from another guild, Please check the Guild Wars page in website, ex: !war invite, guild name, fraglimit / !war invite, guild name, fraglimit,money,time / !war accept, guild name / !war reject, guild name/ !war end, guild name/ !war cancel, guild name. (Only in guild chat)
---
!gbalance - to add money into your guild balance, only guild leaders can use it, ex: !gbalance donate 1234 / !gbalance pick 1234. (Only in guild chat)
---
!guild/!bg - use this command to send a message to all guild members who is online, ex: !guild Hello my people.
---
!go - use this command to change outfit of all your guild members to be like you.
---

]]