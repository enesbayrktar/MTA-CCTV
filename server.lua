loggedIn = 'player.logged' -- loggedIn data
cctv = 'player.can.cctv' -- cctv data, if player has that he can be use /cctv
debugmode = true -- debugmode, if true then everyone access to /cctv command
events = { 'cctv.positions.get', 'cctv.handle.cmd' }
positions = {
  -- Positions taken from https://github.com/bekiroj/mtasa-resources/blob/main/mtasa-owl-cctv/main.lua
  -- ex: { positionX, positionY, positionZ, lookAtX, lookAtY, lookAtZ, roll, fov }
  { 1929.7922363281, -1738.6701660156, 23.292699813843, 1930.1812744141, -1739.5089111328, 22.911764144897 },
  { 2104.4860839844, -1819.6783447266, 17.845899581909, 2104, -1818.8521728516, 17.560821533203 },
  { 1503.8500976563, -1620.4155273438, 34.390701293945, 1504.2943115234, -1621.2131347656, 33.98250579834 },
  { 1332.1098632813, -1367.7768554688, 20.461099624634, 1331.3596191406, -1368.3088378906, 20.068439483643 },
  { 1181.0299072266, -1341.9682617188, 17.987600326538, 1181.1824951172, -1341.0618896484, 17.593641281128 },
  { 1836.3731689453, -1318.5660400391, 20.100700378418, 1836.8768310547, -1319.3624267578, 19.765930175781 },
  { 2234.0607910156, -1635.8319091797, 20.857799530029, 2234.1801757813, -1636.7800292969, 20.563255310059 }
}

-- **************************************************************************

for i, event in ipairs(events) do
  addEvent(event, true)
end

addEventHandler('cctv.positions.get', resourceRoot, function()
    if not client then
      return
    end
    return triggerLatentClientEvent(client, 'cctv.positions.set', 5000, false, client, positions)
  end
)

-- **************************************************************************

local function openCCTV(playerSource, cctvNumber)
  setElementData(playerSource, 'cctv.state', true)
  return triggerClientEvent(playerSource, 'cctv.player.set', playerSource, true, cctvNumber)
end

local function closeCCTV(playerSource, cctvNumber)
  setElementData(playerSource, 'cctv.state', false)
  return triggerClientEvent(playerSource, 'cctv.player.set', playerSource, false, cctvNumber)
end

local cctvActions = {
  [false] = openCCTV,
  [true] = closeCCTV
}

local function handleCCTV(playerSource, commandName, cctvNumber)
  if not playerSource or getPedOccupiedVehicle(playerSource) then
    return
  end -- serverside validation cause we dont trust client
  local cctvMax = #positions
  cctvNumber = tonumber(cctvNumber) or 0

  if cctvNumber > cctvMax or type(cctvNumber) == 'string' then
    return outputChatBox(string.format('KULLANIM: /%s <1-%s>', commandName, cctvMax), playerSource, 255, 168, 0, false)
  end
  if getElementData(playerSource, loggedIn) and getElementData(playerSource, cctv) and not debugmode or debugmode then
    if cctvNumber > 0 then
      return cctvActions[false](playerSource, cctvNumber)
    end
    if cctvNumber == 0 then
      if getElementData(playerSource, 'cctv.state') == true then
        return cctvActions[true](playerSource, 0)
      end
    end
  end
end

addEventHandler('cctv.handle.cmd', resourceRoot, function()
    if not client then
      return
    end
    addCommandHandler('cctv', handleCCTV, false, false)
  end
)

-- **************************************************************************

local function removeCCTV(player)
  return setElementData(player, 'cctv.state', false)
end

addEventHandler('onResourceStop', resourceRoot, function()
    for i, player in ipairs(getElementsByType'player') do
      removeCCTV(player)
    end
  end
)

addEventHandler('onPlayerQuit', root, function()
    return removeCCTV(source)
  end
)
