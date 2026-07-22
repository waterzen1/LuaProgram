
local _class={}

function Class(name, ...)
	assert(type(name) == "string", "class name must be a string")
	local class_type={}
	class_type.Construct = false
	class_type.Destruct = false
	class_type.supers = {...}
	class_type._name = name

	local vtbl = {}
	_class[class_type] = vtbl

	local obj_mt = {
		__index = _class[class_type],
		__gc = function(obj)
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
		end,
		__tostring = function(obj)
			return "[object] ctype: " .. obj._ctype._name
		end,
	}

	class_type.New = function(...)
		local obj = {_ctype = class_type, _constructed = {}, _destructed = {}}
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
		setmetatable(obj, obj_mt)
		return obj
	end

	setmetatable(class_type, {
		__newindex = function(t, k, v)
			vtbl[k]=v
		end,
		__tostring = function(c)
			return "[class] type: " .. c._name
		end,
	})

	if class_type.supers then
		setmetatable(vtbl, {__index =
			function(t, k)
				for _, super in ipairs(class_type.supers) do
					local ret = _class[super][k]
					if ret then
						vtbl[k] = ret
						return ret
					end
				end
			end
		})
	end

	return class_type
end

Base = Class("Base")
 
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


Base1=Class("Base1")
 
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

Test = Class("Test", Base)
 
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

Test1 = Class("Test1", Test, Base1)

function Test1:Construct(...)
	print("Test1 Construct")
end

function Test1:Destruct()
	print("Test1 Destruct")
end

Test2 = Class("Test2", Test, Test1)

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

print(Test)
print(test2)