local __PartyInvite = Class()

function __PartyInvite:__init()
    self.state = 1
    self.think = {}
    for name, i in pairs(FRIENDS) do
        local _name = name
        table.insert(self.think, function()
            local friend = GetPlayerByName(_name)
            if friend == nil then
                self.state = self.state + 1 -- move next, invite only visible players
                return
            end
            if friend:isPartyMember() or friend:getShield() == 2 then
                self.state = self.state + 1
                return
            end
            g_game.partyInvite(friend:getId())
        end)
    end
    table.insert(self.think, function()
        if player:isPartySharedExperienceActive() then
            self.state = self.state + 1
            return
        end
        g_game.partyShareExperience(not player:isPartySharedExperienceActive())
    end)
    self:OnTick()
end

function __PartyInvite:OnTick()
    if self.state > #self.think then
        return
    end
    SafeCall(self.think[self.state], "InviteToParty")
    schedule(250, function()
        self:OnTick()
    end)
end

local __PartyJoin = Class()

function __PartyJoin:__init(leader_name)
    self.state = 1
    self.think = {}
    self.leader_name = leader_name
    table.insert(self.think, function()
        local leader = GetPlayerByName(self.leader_name)
        if leader == nil then
            self.state = self.state + 1 -- move next, no leader on screen
            return
        end
        if player:isPartyMember() then
            self.state = self.state + 1
            return
        end
        g_game.partyJoin(leader:getId())
    end)
    self:OnTick()
end

function __PartyJoin:OnTick()
    if self.state > #self.think then
        return
    end
    SafeCall(self.think[self.state], "JoinToParty")
    schedule(250, function()
        self:OnTick()
    end)
end

setDefaultTab('Main')
UI.Label('')
invite_friends_to_party_button = addButton('invite_friends_to_party', 'Invite Friends To Party', function(widget)
    __PartyInvite()
end)
UI.Separator()

--[[onTextMessage(function(mode, text)
    if mode == 20 and text:find(" has invited you") then
        local name = text:sub(1, text:find(' has invited you', 1, true) - 1)
        --local name = regexMatch(text, "([a-z A-Z-]*) has invited you")[1][2]
        if name and IsFriend(name) then
            __PartyJoin(name)
        end
    end
end)]]

local party_bttn_timer = 0
macro(1000, function()
    local friends_count, friends_around_player, party_friends_around_player, party_leader = FriendsInRange(5)
    if party_leader and player ~= party_leader and not player:isPartyMember() then
        local localPlayerShield = player:getShield()
        local creatureShield = party_leader:getShield()
        if localPlayerShield == ShieldNone or localPlayerShield == ShieldWhiteBlue then
            if creatureShield == ShieldWhiteYellow then
                print('~~~~~~~~~ joining party:) ~~~~~~~~~')
                g_game.partyJoin(party_leader:getId())
            end
        end
    end
    if friends_around_player == friends_count and now > party_bttn_timer + 5000 and party_friends_around_player < friends_around_player then
        local can = false
        if party_friends_around_player == 0 then
            if VOCATION == 1 then can = true end
        elseif player:isPartyMember() and player:isPartyLeader() then
            can = true
        end
        if can then
            invite_friends_to_party_button.onClick()
            print('invite_friends_to_party_button.onClick()')
            party_bttn_timer = now
        end
    end
end)
