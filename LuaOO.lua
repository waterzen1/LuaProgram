
local _class={}

function Class(super)
	local class_type={}
	class_type.Construct = false
	class_type.Destruct = false
	class_type.super = super

	local obj_mt = {
		__index = class_type,
		__gc = function(o)
			local destroy
			destroy = function(c)
				if c.Destruct then
					c.Destruct(o)
				end
				if c.super then
					destroy(c.super)
				end
			end
			destroy(class_type)
		end
	}

	class_type.New = function(...)
		local obj = {}
		do
			local Create
			Create = function(c, ...)
				if c.super then
					Create(c.super, ...)
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
 
	if super then
		setmetatable(class_type, {__index =
			function(t, k)
				local ret = super[k]
				class_type[k] = ret
				return ret
			end
		})
	end
	
	table.insert(_class, class_type)
	return class_type
end

Base=Class()
 
function Base:Construct(x)
	print("Base Construct")
	self.x=x
end

function Base:Destruct()
	print("Base Destruct")
end
 
function Base:Print()
	print("Base Print: ", self.x)
end
 
function Base:Hello()
	print("Base hello")
end

Test=Class(Base)
 
function Test:Construct()
	print("Test Construct")
	self.y = 0
end

function Test:Destruct()
	print("Test Destruct")
end
 
function Test:Hello()
	print("Test hello")
end

Test1 = Class(Test)

function Test1:Construct()
	print("Test1 Construct")
end

function Test1:Destruct()
	print("Test1 Destruct")
end


test=Test.New(1)
test:Print()
test:Hello()

test1 = Test1.New(1)
test1:Print()
test1:Hello()

function Base:Print()
	print("Base Print2: ", self.x)
end

Test.Print = nil
test:Print()
test1:Print()