-- 设置表的默认值
local key = {}
local mt = {__index = function(t) return t[key] end}
function SetDefault(t, d)
	t[key] = d
	setmetatable(t, mt)
end

-- 跟踪表的访问
local key = {}
local proxy = {}
local mt = {
	__index = function(_, k)
		print("*access to element " .. tostring(k))
		return proxy[key][k]
	end,

	__newindex = function(_, k, v)
		print("*update of element " .. tostring(k) .. " to " .. tostring(v))
		proxy[key][k] = v
	end,

	__pairs = function()
		return function(_, k)
			local next_key, next_value = next(proxy[key], k)
			if next_key ~= nil then
				print("*traversing element " .. tostring(next_key))
			end
			return next_key, next_value
		end
	end,

	__len = function() return #proxy[key] end,
}
function Trace(t)
	proxy[key] = t
	setmetatable(proxy, mt)
	return proxy
end

t = {}
t = Trace(t)
t[1] = 1
t[2] = 2
print(t[1])
print(t[2])

for k, v in pairs(t) do
	print(k, v)
end

-- 只读表
function ReadOnly(t)
	local proxy = {}
	local mt = {__index = t, __newindex = function(t, k, v) error("attempt to update a read-only table", 2) end}
	setmetatable(proxy, mt)
	return proxy
end

days = ReadOnly({"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"})
print(days[1])
days[1] = "Monday"