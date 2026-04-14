--!strict

export type function joinTable(t1: type, t2: type)
	if not t1:is'table' then return t2 end
	if not t2:is'table' then return t1 end
	
	for k, v in t2:properties() do
		t1:setproperty(k, v.write or v.read)
	end
	
	return t1
end

export type function packTableIntersection(t: type)
	if not t:is'intersection' then return t end
	
	local components = t:components()
	local result = types.newtable()
	
	for i, comp in components do
		if not comp:is'table' then continue end
		
		for k, v in comp:properties() do
			result:setproperty(k, v.write)
		end
	end
	
	return result
end

export type function setproperty(t: type, key: type, value: type)
	if t:is('intersection') then
		local components = t:components()

		local sometablecomp: type
		local target: type

		for i, comp in components do
			if not comp:is'table' then continue end
			sometablecomp = comp

			if comp:readproperty(key) then 
				target = comp; break 
			end
		end

		if not target then 
			if not sometablecomp then return t end
			target = sometablecomp 
		end

		target:setproperty(key, value)

		return types.intersectionof(unpack(components))
	end

	t:setproperty(key, value)

	return t
end

export type function find(t: type, key: type)
	if not (t:is'table' or t:is'intersection') then
		return types.any
	end

	assert(key:is'singleton')

	if t:is('intersection') then
		local components = t:components()
		local target: type

		for i, comp in components do
			if not comp:is'table' then continue end
			local read = comp:readproperty(key)

			if read then return read end
		end

		return types.any
	end

	return t:readproperty(key) or types.any
end

export type function getReturningElement(fn: type, 
	index: type)
	
	local index = tonumber(index:value())
	
	if not index then return types.any end
	
	local returns = fn:returns()
	if not returns.head then return types.any end
	
	return returns.head[index]
end

export type function moveParams(src: type, 
	i: type, j: type, t: type, to: type)
	
	if not src:is'function' then return src end

	local i = tonumber(i:value()) or 1
	local t = tonumber(t:value()) or 1
	local j = tonumber(j:value())

	local srcParams = src:parameters()
	if not srcParams.head then return to end
	
	local head = table.move(srcParams.head, 
		i, j or #srcParams.head, t, to:parameters().head or {})

	to:setparameters(head, srcParams.tail)

	return to
end

return nil
