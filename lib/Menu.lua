MENU_CLASS = Class()

function MENU_CLASS:__init(path, CreateUIFunc)
	self.otml, self.ui_info = CreateUIFunc()
	self.panel = setupUI(self.otml)
	self.instance = SETTINGS_CLASS(path, self:GetDefaultSettings())
    self.settings = self.instance.settings
	self:SetUICallbacks()
end

function MENU_CLASS:GetDefaultSettings()
	local default_settings = {}
	for k, v in pairs(self.ui_info) do
		if k ~= 'callbacks' then
			for __id, __value in pairs(v) do
				if default_settings[__id] == nil then
					default_settings[__id] = __value
				end
			end
		end
	end
	return default_settings
end

function MENU_CLASS:SetUICallbacks()
	local cb = self.ui_info.callbacks or {}
	for __id, __value in pairs(self.ui_info.switch) do
		local child = self.panel:recursiveGetChildById(__id)
		child:setOn(self.settings[__id])
		child.onClick = function(widget)
			self.settings[__id] = not self.settings[__id]
			widget:setOn(self.settings[__id])
            self.instance:Save()
			if cb[__id] then cb[__id](self.settings[__id]) end
		end
	end
	for __id, __value in pairs(self.ui_info.textedit) do
		local child = self.panel:recursiveGetChildById(__id)
		child:setText(self.settings[__id])
		child.onTextChange = function(widget, text)
			local value = nil
			if type(self.settings[__id]) == "number" then
				value = tonumber(string.match(text, "%d+"))
			end
			self.settings[__id] = value or text
            self.instance:Save()
			if cb[__id] then cb[__id](self.settings[__id]) end
		end
	end
end

function MENU_CLASS:Read()
	self.instance:Read()
end

function MENU_CLASS:Save()
	self.instance:Save()
end