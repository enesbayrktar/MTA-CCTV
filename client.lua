screenWidth, screenHeight = guiGetScreenSize()
scale = screenHeight / 1080
font = 'arial'
isCCTV = false
dump = {false, false}
cctvPositions = {}
currentCamX, currentCamY, currentCamZ, currentCamInt = 0, 0, 0, 0
events = { 'cctv.positions.set', 'cctv.player.set' }

-- **************************************************************************

guiSetInputMode('no_binds_when_editing')

for i, event in ipairs(events) do
  addEvent(event, true)
end

addEventHandler('onClientResourceStart', resourceRoot, function()
    return triggerServerEvent('cctv.positions.get', resourceRoot)
  end
)

addEventHandler('cctv.positions.set', localPlayer, function(positions)
    cctvPositions = positions
    return triggerServerEvent('cctv.handle.cmd', resourceRoot)
  end
)

-- **************************************************************************

function dxCreateFramedText(text, left, top, right, bottom, color, scaleT, font, alignX, alignY, clip, wordBreak, postGUI, outline)
	local self = {}
	local rt = dxCreateRenderTarget(right, bottom, true)

	self.draw = function()
		dxDrawImage(left, top, right, bottom, rt)
	end

	self.update = function()
		dxSetRenderTarget(rt, true)
    dxDrawText (text, 0, 0, right, bottom, color, scaleT, font, alignX, alignY, clip, wordBreak, postGUI, colorCoded, subPixelPositioning, fRotation, fRotationCenterX, fRotationCenterY)
		dxSetRenderTarget()
	end

	self.setText = function(v)
		text = v
		self.update()
  end

  self.getText = function()
    return text
  end

	self.setColor = function(v)
		color = v
		self.update()
	end

	self.update()

	return self
end

textW, textH = scale * 350, scale * 20
textX, textY = screenWidth - textW, 0

dxElements = {
  dxCreateFramedText('', textX, textY, textW, textH, 0xFFFFFFFF, 1, 'default-bold', 'right', 'center', false, false, false, scale * 1),
}

-- **************************************************************************

function render()
  width = dxGetTextWidth(dxElements[1].getText(), 1, 'default-bold')
  dxDrawRectangle(screenWidth - width, textY, width, textH, 0xFF000000)
  for i, element in ipairs(dxElements) do
    element.draw()
  end
end

updateLocationTimer = nil;

function updateLocation()
  dxElements[1].setText(string.format('CCTV   KAMERA:  %s   LOKASYON:  %s', currentCamInt, getZoneName(currentCamX, currentCamY, currentCamZ)))
end

-- **************************************************************************

function nextCamera()
  if not (currentCamInt + 1 > #cctvPositions) then
    return setCCTV(currentCamInt + 1)
  end
end

function prevCamera()
  if not (currentCamInt - 1 < 1) then
    return setCCTV(currentCamInt - 1)
  end
end

function bind()
  bindKey('arrow_l', 'down', prevCamera)
  bindKey('arrow_r', 'down', nextCamera)
end

function unbind()
  unbindKey('arrow_l', 'down')
  unbindKey('arrow_r', 'down')
end

keys = {
  [true] = bind,
  [false] = unbind
}

function bindKeys(state)
  return keys[state]()
end

-- **************************************************************************

function setCCTV(cctvNumber)
  if cctvNumber > 0 then
    local item = cctvPositions[cctvNumber]

    currentCamX, currentCamY, currentCamZ = item[1], item[2], item[3];
    currentCamInt = cctvNumber;

    setCameraMatrix(item[1], item[2], item[3], item[4], item[5], item[6])
  end
end

function openCCTV(cctvNumber)
  setCCTV(cctvNumber)

  if not isCCTV then
    dump[1] = getElementDimension(localPlayer)
    dump[2] = getElementInterior(localPlayer)
    setElementFrozen(localPlayer, true)
    addEventHandler('onClientRender', root, render)
    updateLocationTimer = setTimer(updateLocation, 200, 0)
    bindKeys(true)
    isCCTV = true;
  end
end

function closeCCTV(_)
  setElementDimension(localPlayer, dump[1])
  setElementInterior(localPlayer, dump[2])
  removeEventHandler('onClientRender', root, render)
  if isTimer(updateLocationTimer) then
    killTimer(updateLocationTimer)
  end

  setElementFrozen(localPlayer, false)

  currentCamInt = 0;
  currentCamX, currentCamY, currentCamZ = 0, 0, 0;

  setCameraTarget(localPlayer)
  bindKeys(false)
  isCCTV = false
  dump = {false, false}
end

-- **************************************************************************

local actions = {
  [true] = openCCTV,
  [false] = closeCCTV
}

addEventHandler('cctv.player.set', localPlayer, function(state, cctvNumber)
    return actions[state](cctvNumber)
  end
)
