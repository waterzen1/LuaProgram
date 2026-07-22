
--保存所有类的表，key是类，value是类的虚表，即类的函数
local _class={}

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
			return "[object] ctype: " .. obj._ctype._name
		end,
	}
	-- 创建类实例对象
	-- ...: 构造函数参数
	-- 构造函数会先构造父类，再构造子类
	-- _ctype: 类类型
	-- _constructed/_destructed: 构造/析构函数是否被调用标记，key是类，value是是否被调用，防止菱形继承导致父类构造/析构函数被重复调用
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
	-- 类的元表
	-- 元表的__newindex：每当类定义新函数的时候，将函数保存在类的虚表vtbl中
	setmetatable(class_type, {
		__newindex = function(t, k, v)
			vtbl[k] = v
		end,
		__tostring = function(c)
			return "[class] type: " .. c._name
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
	-- Construct/Destruct/supers/_name/New对类可见，vtbl对类实例对象可见
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


test = Test.New(1)
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