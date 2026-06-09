function randomString()
	local length = math.random(10, 20)
	local array = {}
	for i = 1, length do
		array[i] = string.char(math.random(32, 126))
	end
	return table.concat(array)
end

local buttonholder = nil
local frameholder = nil

function CreateGui(parent, name, nameColor, size, bgColor, bgTransparency, draggable, val)
	local a = Instance.new("ScreenGui")
	a.ResetOnSpawn = false
	a.Parent = parent
	a.Name = randomString()
	a.DisplayOrder = 999
	
	local outer = Instance.new("Frame")
	outer.Parent = a
	outer.Name = randomString()
	outer.BackgroundTransparency = bgTransparency
	outer.BackgroundColor3 = bgColor
	outer.Size = size or UDim2.new(0, 420, 0, 270)
	outer.Active = draggable or false
	outer.Draggable = draggable or false

	local b = Instance.new("Frame")
	b.Parent = outer
	b.Name = randomString()
	b.Size = size - UDim2.new(0, 20, 0, 20) or UDim2.new(0, 400, 0, 250)
	b.BackgroundColor3 = bgColor or Color3.fromRGB(0, 0, 0)
	b.BackgroundTransparency = 1
	b.Position = UDim2.new(0, 10, 0, 10)

	local baseSize = size or UDim2.new(0, 400, 0, 250)

	local c = Instance.new("Frame")
	c.Name = randomString()
	c.Parent = b
	c.BackgroundColor3 = bgColor or Color3.fromRGB(0, 0, 0)
	c.BackgroundTransparency = 1
	c.Active = false
	c.Draggable = false
	c.Position = UDim2.new(0, 0, 0, 0)

	if val then
		-- Horizontal button alignment
		c.Size = UDim2.new(baseSize.X.Scale, baseSize.X.Offset - 20, 0, 50)
	else
		-- Vertical button alignment
		c.Size = UDim2.new(0, 130, baseSize.Y.Scale, baseSize.Y.Offset - 20)
	end
	
	local logotext = Instance.new("TextLabel")
	logotext.Parent = c
	logotext.Name = randomString()
	logotext.BackgroundTransparency = 1
	logotext.TextColor3 = nameColor
	logotext.Position = UDim2.new(0, 0, 0, 0)
	
	if val then
		logotext.Size = UDim2.new(c.Size.X.Scale, c.Size.X.Offset, c.Size.Y.Scale, 20)
	else
		logotext.Size = UDim2.new(c.Size.X.Scale, c.Size.X.Offset, c.Size.Y.Scale, 25)
	end
	
	logotext.Text = name
	logotext.Font = Enum.Font.SourceSansBold
	logotext.TextSize = 20
	
	local d = Instance.new("Frame")
	d.Parent = c
	d.Name = randomString()
	
	if val then
		d.Position = UDim2.new(0, 0, 0, logotext.Size.Y.Offset + 15)
	else
		d.Position = UDim2.new(0, 0, 0, 35)
	end
	
	d.Size = c.Size - UDim2.new(0, 0, 0, 35)
	d.BackgroundTransparency = 1
	
	buttonholder = d

	local e = Instance.new("UIGridLayout")
	e.Parent = d
	e.Name = randomString()

	if val then
		-- Horizontal alignment
		e.FillDirection = Enum.FillDirection.Horizontal
		e.CellSize = UDim2.new(0, 100, 0, 30)
		e.VerticalAlignment = Enum.VerticalAlignment.Center
	else
		-- Vertical alignment
		e.FillDirection = Enum.FillDirection.Vertical
		e.CellSize = UDim2.new(1, 0, 0, 30) -- Full-width buttons
	end

	e.CellPadding = UDim2.new(0, 5, 0, 5)
	e.SortOrder = Enum.SortOrder.LayoutOrder
	e.HorizontalAlignment = Enum.HorizontalAlignment.Center
	
	local f = Instance.new("Frame")
	f.Parent = b
	f.Name = randomString()
	f.BackgroundTransparency = 1
	f.BackgroundColor3 = bgColor

	if val then
		f.Position = UDim2.new(0, 0, 0, c.Size.Y.Offset + c.Size.Y.Scale * b.AbsoluteSize.Y + 20)
		f.Size = UDim2.new(b.Size.X.Scale, b.Size.X.Offset, b.Size.Y.Scale, b.Size.Y.Offset - c.Size.Y.Offset - 20)
	else
		f.Position = UDim2.new(c.Size.X.Scale, c.Size.X.Offset + 10, 0, 0)
		f.Size = UDim2.new(b.Size.X.Scale, b.Size.X.Offset - c.Size.X.Offset - 10, b.Size.Y.Scale, b.Size.Y.Offset)
	end
	
	frameholder = f
	
	return a
end

function CreateSection(text, textColor, bgColor, bgTransparency, position, size, cornerRadiusVal, cornerRadius)
	local a = Instance.new("TextButton")
	a.Parent = buttonholder
	a.Name = randomString()
	a.Text = text
	a.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
	a.Position = position or UDim2.new(0, 0, 0, 0)
	a.Size = size or UDim2.new(0, 100, 0, 30)
	a.BackgroundColor3 = bgColor or Color3.fromRGB(0, 0, 0)
	a.BackgroundTransparency = bgTransparency or 0
	a.BorderSizePixel = 0
	a.TextSize = 16
	a.Font = Enum.Font.SourceSansBold

	if cornerRadiusVal then
		local b = Instance.new("UICorner")
		b.Parent = a
		b.Name = randomString()
		b.CornerRadius = cornerRadius
	end

	local c = Instance.new("Frame")
	c.Parent = frameholder
	c.Name = randomString()
		
	local abc = frameholder.Size

	c.Size = abc
	c.Position = UDim2.new(0, 0, 0, 0)
	c.BackgroundColor3 = frameholder.BackgroundColor3
	c.BackgroundTransparency = 1
	c.Visible = false
	
	local d = Instance.new("UIGridLayout")
	d.Parent = c
	d.CellSize = UDim2.new(c.Size.X.Scale, c.Size.X.Offset, c.Size.Y.Scale, 30)
	d.CellPadding = UDim2.new(0, 5, 0, 5)
	d.SortOrder = Enum.SortOrder.LayoutOrder
	d.Name = randomString()
	
	a.MouseButton1Click:Connect(function()
		for _, v in pairs(frameholder:GetChildren()) do
			if v.ClassName == "Frame" then
				v.Visible = false
			end
		end
		c.Visible = not c.Visible
	end)
	
	return c
end

function CreateFrameSection(parent, text, textColor)
	local a = Instance.new("TextLabel")
	a.Parent = parent
	a.Text = text
	a.TextColor3 = textColor
	a.Size = UDim2.new(parent.Size.X.Scale, parent.Size.X.Offset, parent.Size.Y.Scale, 20)
	a.BackgroundTransparency = 1
	a.Font = Enum.Font.SourceSansBold
	a.TextSize = 16
	a.Name = randomString()
end

function CreateFrameButton(parent, text, textColor, bgColor, callback)
	local a = Instance.new("TextButton")
	a.Parent = parent
	a.Size = UDim2.new(parent.Size.X.Scale, parent.Size.X.Offset, 0, 30)
	a.Text = ""
	a.BackgroundTransparency = 0
	a.BackgroundColor3 = bgColor
	a.Font = Enum.Font.SourceSans
	a.TextColor3 = Color3.fromRGB(255, 255, 255)
	a.TextSize = 14
	a.BorderSizePixel = 0
	a.AutoButtonColor = false
	a.Name = randomString()

	local b = Instance.new("TextLabel")
	b.Parent = a
	b.Name = randomString()
	b.Text = text
	b.TextColor3 = textColor
	b.Font = Enum.Font.SourceSansBold
	b.Position = UDim2.new(0, 10, 0, 0)
	b.Size = UDim2.new(1, -20, 1, 0)
	b.BackgroundTransparency = 1
	b.TextSize = 16
	b.TextXAlignment = Enum.TextXAlignment.Left

	a.MouseButton1Click:Connect(function()
		if callback and typeof(callback) == "function" then
			callback()
		end
	end)
end

function CreateFrameEnableButton(parent, text, textColor, bgColor, callback)
	local a = Instance.new("TextButton")
	a.Parent = parent
	a.Size = UDim2.new(parent.Size.X.Scale, parent.Size.X.Offset, parent.Size.Y.Scale, 30)
	a.Text = ""
	a.BackgroundTransparency = 0
	a.BackgroundColor3 = bgColor
	a.Font = Enum.Font.SourceSans
	a.TextColor3 = Color3.fromRGB(255, 255, 255)
	a.TextSize = 14
	a.BorderSizePixel = 0
	a.AutoButtonColor = false
	a.Name = randomString()
	
	local b = Instance.new("Frame")
	b.Parent = a
	b.Size = UDim2.new(a.Size.X.Scale, 50, a.Size.Y.Scale, 20)
	b.Position = UDim2.new(a.Size.X.Scale, a.Size.X.Offset - 60, 0, 5)
	b.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	b.Name = randomString()
	
	local c = Instance.new("UICorner")
	c.Parent = b
	c.Name = randomString()
	c.CornerRadius = UDim.new(1, 0)
	
	local d = Instance.new("TextLabel")
	d.Parent = a
	d.Name = randomString()
	d.Text = text
	d.TextColor3 = textColor
	d.Font = Enum.Font.SourceSansBold
	d.Position = UDim2.new(0, 10, 0, 0)
	d.Size = UDim2.new(a.Size.X.Scale, a.Size.X.Offset - b.Size.X.Offset - 30, a.Size.Y.Scale, a.Size.Y.Offset)
	d.BackgroundTransparency = 1
	d.TextSize = 16
	d.TextXAlignment = Enum.TextXAlignment.Left
	
	local e = Instance.new("Frame")
	e.Parent = b
	e.Name = randomString()
	e.Size = UDim2.new(b.Size.X.Scale, b.Size.X.Offset / 2, b.Size.Y.Scale, b.Size.Y.Offset)
	e.Position = UDim2.new(0, 0, 0, 0)

	local f = Instance.new("UICorner")
	f.Parent = e
	f.Name = randomString()
	f.CornerRadius = UDim.new(1, 0)
	
	local abc = false
	a.MouseButton1Click:Connect(function()
		abc = not abc
		if abc then
			e:TweenPosition(UDim2.new(1, -e.Size.X.Offset, 0, 0), "Out", "Sine", 0.15, true)
			b.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
		else
			e:TweenPosition(UDim2.new(0, 0, 0, 0), "Out", "Sine", 0.15, true)
			b.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		end
		if callback and typeof(callback) == "function" then
			callback(abc)
		end
	end)
end

function CreateFrameTextBox(parent, placeholderText, textColor, bgColor, bgTransparency, textSize, cornerRadiusVal, cornerRadius)
	local a = Instance.new("TextBox")
	a.Parent = parent
	a.Name = randomString()
	a.PlaceholderText = placeholderText or "Enter text..."
	a.Text = ""
	a.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
	a.BackgroundColor3 = bgColor or Color3.fromRGB(20, 20, 20)
	a.BackgroundTransparency = bgTransparency or 0
	a.TextSize = textSize or 16
	a.Font = Enum.Font.SourceSans
	a.TextXAlignment = Enum.TextXAlignment.Left
	a.ClearTextOnFocus = false
	a.BorderSizePixel = 0
	a.ClipsDescendants = true

	if cornerRadiusVal then
		local b = Instance.new("UICorner")
		b.Name = randomString()
		b.CornerRadius = cornerRadius or UDim.new(0, 6)
		b.Parent = a
	end

	local c = Instance.new("UIPadding")
	c.Name = randomString()
	c.PaddingLeft = UDim.new(0, 10)
	c.Parent = a

	return a
end