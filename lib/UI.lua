importStyle([[
ListItem < UIWidget
  background-color: alpha
  text-offset: 3 1
  focusable: true
  height: 16
  font: verdana-11px-rounded
  text-align: left

  $focus:
    background-color: #00000055

  Button
    id: remove
    !text: tr('X')
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    width: 14
    height: 14
    margin-right: 15
    text-align: center
    text-offset: 0 1
    tooltip: Remove item from the list.

NormalListItem < UIWidget
  background-color: alpha
  text-offset: 3 1
  focusable: true
  height: 16
  font: verdana-11px-rounded
  text-align: left

  $focus:
    background-color: #00000055
]]
)

function GetTextListOTML(id, name, bttn_name, height, color, logoHeight, extraSpaces, defaultText, textEditId)
  extraSpaces = extraSpaces or ""
  logoHeight = logoHeight or 50
  defaultText = defaultText or ""
  textEditId = textEditId or "name"
  local otml = [[
Panel
  height: ]] .. height + 25 .. "\n" .. [[
  layout:
    type: verticalBox
  Panel
    id: Logo]] .. id .. "\n" .. [[
    height: ]] .. logoHeight .. "\n" .. [[
    Label
      id: Text
      text-align: center
      color: ]] .. color .. "\n" .. [[
      font: terminus-14px-bold
      !text: tr(']] .. name .. "')" .. "\n" .. [[
      anchors.bottom: parent.bottom
      anchors.horizontalCenter: parent.horizontalCenter
  Panel
    id: ]] .. id .. "\n" .. [[
    height: ]] .. height .. "\n"

  otml = otml .. [[

    TextList
      id: list
      height: ]] .. height - 48 .. "\n" .. [[
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      vertical-scrollbar: scrollbar

    VerticalScrollBar
      id: scrollbar
      anchors.top: list.top
      anchors.bottom: list.bottom
      anchors.right: list.right
      step: 14
      pixels-scroll: true

    BotTextEdit
      id: ]] .. textEditId .. "\n" .. [[
      !text: tr(']] .. defaultText .. "')" .. "\n" .. [[
      anchors.top: list.bottom
      anchors.left: parent.left
      anchors.right: parent.right

    BotButton
      id: add
      text: ]] .. bttn_name .. "\n" .. [[
      anchors.top: prev.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      font: verdana-11px-rounded
]]
  local result = ""
  for line in otml:gmatch("([^\n]*)\n?") do
    result = result .. extraSpaces .. line .. "\n"
  end
  -- print(result)
  return result
end

function GetWalkerListOTML(id, name, height, color, logoHeight, extraSpaces)
  extraSpaces = extraSpaces or ""
  logoHeight = logoHeight or 50
  --    background-color: red
  local otml = [[
Panel
  height: ]] .. height + 25 .. "\n" .. [[
  layout:
    type: verticalBox
  Panel
    id: Logo]] .. id .. "\n" .. [[
    height: ]] .. logoHeight .. "\n" .. [[
    Label
      id: Text
      text-align: center
      color: ]] .. color .. "\n" .. [[
      font: terminus-14px-bold
      !text: tr(']] .. name .. "')" .. "\n" .. [[
      anchors.bottom: parent.bottom
      anchors.horizontalCenter: parent.horizontalCenter
  Panel
    id: ]] .. id .. "\n" .. [[
    height: ]] .. height .. "\n"

  otml = otml .. [[

    TextList
      id: list
      height: 150
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      vertical-scrollbar: scrollbar

    VerticalScrollBar
      id: scrollbar
      anchors.top: list.top
      anchors.bottom: list.bottom
      anchors.right: list.right
      step: 14
      pixels-scroll: true

    BotTextEdit
      id: file_name
      !text: tr('filename.json')
      anchors.top: list.bottom
      anchors.left: parent.left
      anchors.right: parent.right

    BotButton
      id: save
      text: Save
      anchors.top: prev.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      font: verdana-11px-rounded

    BotButton
      id: add_wpt
      text: Add Waypoint
      anchors.top: prev.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      font: verdana-11px-rounded

    BotButton
      id: add_dir
      text: Add Direction
      anchors.top: prev.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      font: verdana-11px-rounded
]]
  local result = ""
  for line in otml:gmatch("([^\n]*)\n?") do
    result = result .. extraSpaces .. line .. "\n"
  end
  -- print(result)
  return result
end

function GetFileListOTML(id, name, height, color, logoHeight, extraSpaces)
  extraSpaces = extraSpaces or ""
  logoHeight = logoHeight or 50
  --    background-color: red
  local otml = [[
Panel
  height: ]] .. height + 25 .. "\n" .. [[
  layout:
    type: verticalBox
  Panel
    id: Logo]] .. id .. "\n" .. [[
    height: ]] .. logoHeight .. "\n" .. [[
    Label
      id: Text
      text-align: center
      color: ]] .. color .. "\n" .. [[
      font: terminus-14px-bold
      !text: tr(']] .. name .. "')" .. "\n" .. [[
      anchors.bottom: parent.bottom
      anchors.horizontalCenter: parent.horizontalCenter
  Panel
    id: ]] .. id .. "\n" .. [[
    height: ]] .. height .. "\n"

  otml = otml .. [[

    TextList
      id: list
      height: 200
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      vertical-scrollbar: scrollbar

    VerticalScrollBar
      id: scrollbar
      anchors.top: list.top
      anchors.bottom: list.bottom
      anchors.right: list.right
      step: 14
      pixels-scroll: true

    BotButton
      id: load
      text: Load
      anchors.top: prev.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      font: verdana-11px-rounded
]]
  local result = ""
  for line in otml:gmatch("([^\n]*)\n?") do
    result = result .. extraSpaces .. line .. "\n"
  end
  -- print(result)
  return result
end

function GetLurePanelOTML()
  return [[
Panel
  id: lurePanel
  height: 70

  BotLabel
    id: minLabel
    text-align: right
    font: verdana-11px-rounded
    !text: tr('Lure Min:')
    anchors.top: parent.top
    anchors.left: parent.left

  BotTextEdit
    id: minTextEdit
    text: 3
    anchors.top: prev.top
    anchors.right: parent.right

  BotLabel
    id: maxLabel
    text-align: right
    font: verdana-11px-rounded
    !text: tr('Lure Max:')
    anchors.top: minLabel.bottom
    anchors.left: minLabel.left
    margin-top: 10

  BotTextEdit
    id: maxTextEdit
    text: 3
    anchors.top: prev.top
    anchors.right: parent.right

  BotLabel
    id: delayLabel
    text-align: right
    font: verdana-11px-rounded
    !text: tr('Lure Delay:')
    anchors.top: maxLabel.bottom
    anchors.left: maxLabel.left
    margin-top: 10

  BotTextEdit
    id: delayTextEdit
    text: 300
    anchors.top: prev.top
    anchors.right: parent.right
]]
end