local IDs_OF_MAIN_BP_CHILDS = {
    --[[2870, --grey backpack
    2854, --backpack
    2869, --blue backpack
    2871, --yellow backpack
    2865, --green backpack
    2868, --purple backpack]]
}

local function IsMainContainer(container)
    local items = {}
    for slot, item in ipairs(container:getItems()) do
        items[item:getId()] = true
    end
    for i, id in ipairs(IDs_OF_MAIN_BP_CHILDS) do
        if items[id] == nil then
            return false
        end
    end
    return true
end

macro(2000, function()
    if now < TELEPORT_ITEM_TIMER + 1000 then
        return
    end
    local tokens = player:getItemsCount(6526)
    if tokens > 1000 then print('~~~~~~~~~ use 1000 tokens ~~~~~~~~~') return g_game.use(findItem(6526)) end
end)

macro(200, function()
    if now < TELEPORT_ITEM_TIMER + 1000 then
        return
    end
    local IsOpened = {}
    local OpenedContainers = {}

    local containers = g_game.getContainers()

    for _, container in pairs(containers) do
        local item = container:getContainerItem()
        local id = item:getId()
        IsOpened[id] = true
        OpenedContainers[id] = container
    end

    local function TryOpenEQContainerByGivenSlot(slot)
        local SlotPurseItem = player:getInventoryItem(slot)
        if SlotPurseItem == nil then
            return true
        end
        local SlotPurseItemID = SlotPurseItem:getId()
        if SlotPurseItemID <= 0 then
            return true
        end
        if not IsOpened[SlotPurseItemID] then
            g_game.open(SlotPurseItem)
            return true
        end
        IsOpened[slot] = true
        OpenedContainers[slot] = OpenedContainers[SlotPurseItemID]
        return false
    end

    if TryOpenEQContainerByGivenSlot(SlotBack) then
        return
    end

    local MainChilds = {}
    for slot, item in ipairs(OpenedContainers[SlotBack]:getItems()) do
        if item:isContainer() then
            local id = item:getId()
            if not IsOpened[id] then
                g_game.open(item)
                return
            end
            MainChilds[id] = OpenedContainers[id]
        end
    end

    local MainContainerItems = {}
    if IsMainContainer(OpenedContainers[SlotBack]) then
        MainContainerItems = OpenedContainers[SlotBack]:getItems()
    else
        for id, container in pairs(MainChilds) do
            if IsMainContainer(container) then
                MainContainerItems = container:getItems()
                break
            end
        end
    end

    if #MainContainerItems == 0 then
        return
    end

    for slot, item in ipairs(MainContainerItems) do
        if item:isContainer() then
            local id = item:getId()
            if not IsOpened[id] then
                g_game.open(item)
                return
            end
        end
    end
end)
