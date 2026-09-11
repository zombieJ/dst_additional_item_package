local Camera = {}

Camera.MOUSE_MAX_OFFSET = 75
Camera.PITCH_TOP = 18
Camera.PITCH_CENTER = 30
Camera.PITCH_BOTTOM = 42

-- 把角度收敛到相机使用的 0 到 360 度范围。
local function Normalize(angle)
	return (angle % 360 + 360) % 360
end

-- 把整个屏幕宽度线性映射为车后方两侧的第三视角目标偏角。
function Camera.GetMouseTargetOffset(mouseX, screenWidth)
	if type(mouseX) ~= "number" or type(screenWidth) ~= "number" or screenWidth <= 0 then return 0 end
	local halfWidth = screenWidth * 0.5
	local position = math.max(-1, math.min(1, (mouseX - halfWidth) / halfWidth))
	-- FollowCamera 的 heading 正方向与屏幕横向观感相反，因此这里反转偏角符号。
	return -position * Camera.MOUSE_MAX_OFFSET
end

-- 临时叠加鼠标偏角并应用画面，随后恢复原版相机维护的轨道过渡角。
function Camera.ApplyHeadingOffset(camera, offset)
	local baseHeading = camera.heading
	local viewHeading = Normalize(baseHeading + (offset or 0))
	camera.heading = viewHeading
	camera:Apply()
	camera.heading = baseHeading
	return viewHeading, baseHeading
end

-- 把整个屏幕高度线性映射为向上看、居中和向下看的第三视角俯仰角。
function Camera.GetMouseTargetPitch(mouseY, screenHeight)
	if type(mouseY) ~= "number" or type(screenHeight) ~= "number" or screenHeight <= 0 then
		return Camera.PITCH_CENTER
	end
	local ratio = math.max(0, math.min(1, mouseY / screenHeight))
	if ratio <= 0.5 then
		return Camera.PITCH_BOTTOM + (Camera.PITCH_CENTER - Camera.PITCH_BOTTOM) * ratio * 2
	end
	return Camera.PITCH_CENTER + (Camera.PITCH_TOP - Camera.PITCH_CENTER) * (ratio - 0.5) * 2
end

return Camera
