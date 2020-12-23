screenWidth, screenHeight = guiGetScreenSize()
scale = screenHeight / 1080
font = 'arial'
isCCTV = false
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
    for oX = (outline * -1), outline do
      for oY = (outline * -1), outline do
        dxDrawText (text, oX, oY, right + oX, bottom + oY, tocolor(0, 0, 0, 255), scaleT, font, alignX, alignY, clip, wordBreak, postGUI, colorCoded, subPixelPositioning, fRotation, fRotationCenterX, fRotationCenterY)
      end
    end
    dxDrawText (text, 0, 0, right, bottom, color, scaleT, font, alignX, alignY, clip, wordBreak, postGUI, colorCoded, subPixelPositioning, fRotation, fRotationCenterX, fRotationCenterY)
		dxSetRenderTarget()
	end

	self.setText = function(v)
		text = v
		self.update()
	end

	self.setColor = function(v)
		color = v
		self.update()
	end

	self.update()

	return self
end

textW, textH = scale * 350, scale * 25
textX = screenWidth - textW - scale * 15

textY = textH + scale * 15
camY = textY + scale * 15
locationY = textY + scale * 30

dxElements = {
  dxCreateFramedText('CCTV', textX, textY, textW, textH, 0xFFFFFFFF, 1, 'default-bold', 'right', 'center', false, false, false, scale * 2),
  dxCreateFramedText('KAMERA:', textX, camY, textW, textH, 0xFFFFFFFF, 1, font, 'right', 'center', false, false, false, scale * 2),
  dxCreateFramedText('LOKASYON:', textX, locationY, textW, textH, 0xFFFFFFFF, 1, font, 'right', 'center', false, false, false, scale * 2),
}

-- **************************************************************************

function render()
  for i, element in ipairs(dxElements) do
    element.draw()
  end
end

updateLocationTimer = nil;

function updateLocation()
  dxElements[2].setText(string.format('KAMERA:  %s', currentCamInt))
  dxElements[3].setText(string.format('LOKASYON:  %s', getZoneName(currentCamX, currentCamY, currentCamZ)))
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
  local item = cctvPositions[cctvNumber]

  currentCamX, currentCamY, currentCamZ = item[1], item[2], item[3];
  currentCamInt = cctvNumber;
  lastint = getElementInterior(localPlayer)
  lastdim = getElementDimension(localPlayer)

  setCameraMatrix(item[1], item[2], item[3], item[4], item[5], item[6])
  triggerServerEvent("Property",localPlayer, item[7], item[8])
end

function openCCTV(cctvNumber)
  setCCTV(cctvNumber)

  if not isCCTV then
    setElementFrozen(localPlayer, true)
    addEventHandler('onClientRender', root, render)
    updateLocationTimer = setTimer(updateLocation, 200, 0)
    bindKeys(true)
    isCCTV = true;
  end
end

function closeCCTV(_)
  removeEventHandler('onClientRender', root, render)
  if isTimer(updateLocationTimer) then
    killTimer(updateLocationTimer)
  end

  setElementFrozen(localPlayer, false)

  currentCamInt = 0;
  currentCamX, currentCamY, currentCamZ = 0, 0, 0;
  setCameraTarget(localPlayer)
  triggerServerEvent("lastProperty",localPlayer, lastint, lastdim)
  bindKeys(false)
  isCCTV = false
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
