
local _class={}

function Class(...)
	local class_type={}
	class_type.Construct = false
	class_type.Destruct = false
	class_type.supers = {...}

	class_type.__index = class_type
	class_type.__gc = function(obj)
		local destroy
		destroy = function(c)
			if obj._destructed[c] then return end
			obj._destructed[c] = true
			if c.Destruct then
				c.Destruct(obj)
			end
			for i = #c.supers, 1, -1 do
				local super = c.supers[i]
				destroy(super)
			end
		end
		destroy(class_type)
	end

	class_type.New = function(...)
		local obj = {_constructed = {}, _destructed = {}}
		do
			local Create
			Create = function(c, ...)
				if obj._constructed[c] then return end
				obj._constructed[c] = true
				for _, super in ipairs(c.supers) do
					Create(super, ...)
				end
				if c.Construct then
					c.Construct(obj, ...)
				end
			end
			Create(class_type, ...)
		end
		setmetatable(obj, class_type)
		return obj
	end
 
	if class_type.supers then
		setmetatable(class_type, {__index =
			function(_, k)
				for _, super in ipairs(class_type.supers) do
					local ret = super[k]
					if ret then
						class_type[k] = ret
						return ret
					end
				end
			end
		})
	end
	
	table.insert(_class, class_type)
	return class_type
end

Base=Class()
 
function Base:Construct(x)
	print("Base Construct")
	self.x = x or 0
end

function Base:Destruct()
	print("Base Destruct")
end
 
function Base:PrintX()
	print("Base PrintX: ", self.x)
end
 
function Base:Hello()
	print("Base hello")
end


Base1=Class()
 
function Base1:Construct(x, y)
	print("Base1 Construct")
	self.y = y or 0
end

function Base1:Destruct()
	print("Base1 Destruct")
end
 
function Base1:PrintY()
	print("Base1 PrintY: ", self.y)
end

Test = Class(Base)
 
function Test:Construct()
	print("Test Construct")
	self.z = 0
end

function Test:Destruct()
	print("Test Destruct")
end
 
function Test:Hello()
	print("Test hello")
end

Test1 = Class(Test, Base1)

function Test1:Construct(...)
	print("Test1 Construct")
end

function Test1:Destruct()
	print("Test1 Destruct")
end

Test2 = Class(Test, Test1)

function Test2:Construct(...)
	print("Test2 Construct")
end

function Test2:Destruct()
	print("Test2 Destruct")
end


test=Test.New(1)
test:PrintX()
test:Hello()

test1 = Test1.New(1, 2)
test1:PrintX()
test1:PrintY()
test1:Hello()

test2 = Test2.New(1, 2, 3)

function Base:PrintX()
	print("Base PrintX2: ", self.x)
end

Test.PrintX = nil
test:PrintX()
test1:PrintX()