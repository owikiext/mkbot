WIDGETS = {}

function ClickButton(id)
    if WIDGETS[id] then
        WIDGETS[id].click()
    else
        print('Widget.lua -> ' .. id .. ' button not exists!')
    end
end

function DynamicWidget(type, id, name, cb)
    if type == 'button' then
        if WIDGETS[id] == nil then
            WIDGETS[id] = {widget=addButton(id, name, cb),click=cb}
        else
            print('Widget.lua -> ' .. id .. ' already exists!')
        end
        return WIDGETS[id].widget
    end
    if type == 'textedit' then
        return
    end
end