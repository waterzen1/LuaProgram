--保存所有类的表，key是类，value是类的虚表，即类的函数
local _class = {}

local DefaultClassMethod = {
	static = {
		IsSubClassOf = function(self, other)
			assert(_class[other] and type(other) == "table", "type " .. type(other) .. ": " .. tostring(other) .. " not a class")
			for _, super in ipairs(self.supers) do
				if super == other then return true end
				if super:IsSubClassOf(other) then return true end
			end
			return false
		end
	},
	ToString = function(self)
		return string.format("Object: %p", self) .. ", instance of: " .. tostring(self._ctype)
	end,
	IsInstanceOf = function(self, c)
		assert(_class[c] and type(c) == "table", "type " .. type(c) .. ": " .. tostring(c) .. " not a class")
		if self._ctype == c then return true end
		return self._ctype:IsSubClassOf(c)
	end
}

local function LoadDefaultClassMethod(class_type)
	for k, v in pairs(DefaultClassMethod) do
		if "static" ~= k then
			_class[class_type][k] = v
		end
	end

	for k, v in pairs(DefaultClassMethod.static) do
		class_type[k] = v
	end
end

-- 创建类
-- name: 类名
-- ...: 父类
function Class(name, ...)
	assert(type(name) == "string", "class name must be a string")
	local class_type={}
	class_type.Construct = false	--类构造函数
	class_type.Destruct = false		--类构造函数
	class_type.supers = {...}		--父类
	class_type._name = name			--类名
	-- 类的虚表，用于存储类的函数，里面的函数可以被子类重载或继承
	local vtbl = {}
	_class[class_type] = vtbl
	LoadDefaultClassMethod(class_type)
	-- 类实例对象的元表
	-- 元表的__index指向类的虚表，用于查找类的函数，类实例对象可调用的函数在vtbl中
	-- 元表的__gc用于析构类实例对象，Destruct为析构函数，先析构子类，再析构父类
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
			if obj.ToString then
				return obj:ToString()
			else
				return string.format("Object: %p", obj)
			end
		end,
	}
	-- 创建类实例对象
	-- ...: 构造函数参数
	-- 构造函数会先构造父类，再构造子类
	-- _ctype: 类类型
	-- _constructed/_destructed: 构造/析构函数是否被调用标记，key是类，value是是否被调用，防止菱形继承导致父类构造/析构函数被重复调用
	function class_type:New(...)
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
	-- 类的元表
	-- 元表的__newindex：每当类定义新函数的时候，将函数保存在类的虚表vtbl中
	setmetatable(class_type, {
		__newindex = function(t, k, v)
			vtbl[k] = v
		end,
		__tostring = function(c)
			return "Class " .. c._name
		end,
	})
	-- 类的虚表vtbl的元表
	-- 元表的__index：用于实现类的继承，当一个函数在类中查找不到的时候，就去父类的虚表中查找
	-- 如果在父类中查找到函数，就将函数保存在类的虚表vtbl中，下次查找的时候就直接从vtbl中查找，避免每次都要去父类的虚表中查找
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
	-- Construct,Destruct,supers,_name,New,DefaultClassMethod/static对类可见，vtbl对类实例对象可见
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

Base1 = Class("Base1")
 
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

print("---------------------Test-----------------------")
test = Test:New(1)
test:PrintX()
test:Hello()
print("---------------------Test1-----------------------")
test1 = Test1:New(1, 2)
test1:PrintX()
test1:PrintY()
test1:Hello()
print("---------------------Test2-----------------------")
test2 = Test2:New(1, 2, 3)

function Base:PrintX()
	print("Base PrintX2: ", self.x)
end
print("---------------------Reload-----------------------")
Test.PrintX = nil
test:PrintX()
test1:PrintX()
print("---------------------Tostring-----------------------")
print(Test)
print(test2)
print("---------------------IsSubClassOf-----------------------")
print(Test:IsSubClassOf(Base))
print(Test:IsSubClassOf(Base1))
print(Test1:IsSubClassOf(Base))
print(Test1:IsSubClassOf(Base1))
print(Test2:IsSubClassOf(Test))
print(Test2:IsSubClassOf(Test1))
print(Test2:IsSubClassOf(Base))
print(Test2:IsSubClassOf(Base1))
print("--------------------IsInstanceOf------------------------")
print(test:IsInstanceOf(Test))
print(test:IsInstanceOf(Base))
print(test:IsInstanceOf(Base1))
print(test1:IsInstanceOf(Base1))
print(test2:IsInstanceOf(Test2))
print(test2:IsInstanceOf(Base))
print(test2:IsInstanceOf(Base1))
print("--------------------Destruct------------------------")