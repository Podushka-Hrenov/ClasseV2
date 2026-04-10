--!strict

local Types = require(script.Types)

type Meta<D, E> = setmetatable<D, {
	read extends: (E & AbstractClasse)?,
	read attrs: index<Types.find<E, 'meta'>, 'attrs'> & Types.getReturningElement<
		index<D, 'construct'>, '1'>,
	read meta: index<Types.find<E, 'meta'>, 'meta'> & D
}>

export type BaseMeta = Meta<{
	construct: (...any) -> any,
	init: ((...any) -> ...any)?,
	
	[any]: any
}, nil>

type AbstractClasse = setmetatable<{
	read new: (...any) -> ...any
}, {
	read childs: {AbstractClasse},
	read parent: AbstractClasse?,
	read overrides: {[string]: true},
	read initChain: {(...any) -> ...any}?,
	read metadata: {
		__index: {[any]: any}
	},
	read meta: {}
}>

type Classe<M> = setmetatable<{
	read new: index<M, 'construct'>
}, {
	read childs: {AbstractClasse},
	read parent: index<getmetatable<M>, 'extends'>?,
	read overrides: {[string]: true},
	read initChain: {(...any) -> ...any}?,
	read metadata: {
		__index: setmetatable<M, nil>
	},
	read meta: M
}>

export type Self<M> = index<getmetatable<M>, 'attrs'>
	& index<getmetatable<M>, 'meta'>

local Classe, __meta = {}, {}

function __meta.__newindex(self: AbstractClasse, 
	key: any, value: any)
	
	local data = getmetatable(self)
	
	if value == nil and data.parent then
		value = getmetatable(data.parent).metadata.__index[key]
		data.overrides[key] = nil
	else
		data.overrides[key] = true
	end
	
	data.metadata.__index[key] = value

	for i, child in data.childs do
		local childData = getmetatable(child)
		
		if childData.overrides[key] then continue end
		childData.metadata.__index[key] = value
	end
end

function Classe.build<M>(meta: M & BaseMeta): Classe<M>
	
	local constructor = meta.construct
	local parent: AbstractClasse? = getmetatable(
		meta :: BaseMeta).extends
	
	local parentData = parent and getmetatable(parent)
	
	local data = {
		parent = parent,
		childs = {},
		overrides = {},
		constructor = constructor,
		__newindex = __meta.__newindex
	}
	
	local initChain: {(...any) -> ...any}? = nil
	
	if parentData then
		for k, v in parentData.metadata.__index do
			if meta[k] == nil then meta[k] = v
				continue 
			end 
			data.overrides[k] = true
		end
		
		if meta.init then
			initChain = if parentData.initChain then 
				table.clone(parentData.initChain)
			else {}
		
			table.insert(initChain, meta.init)
			table.freeze(initChain)
		else
			initChain = parentData.initChain
		end
	else
		initChain = if meta.init then 
			table.freeze{meta.init} 
		else nil 
	end
	
	data.initChain = initChain
	
	local metadata = {__index = {}}
	
	for index: any, data: any in pairs(meta) do
		if type(index) == 'string' and
			index:find('^__') then

			continue
		end

		metadata.__index[index] = data
	end
	
	local initChainLen = initChain and #initChain or 0
	
	local self = {new = function(...: any)
		local obj = {}; constructor(obj, ...)
		setmetatable(obj, meta)

		for i = 1, initChainLen do
			initChain[i](obj)
		end

		return obj
	end}
	
	return setmetatable(self, table.freeze(data)) :: Classe<M>
end

function Classe.meta<M, E>(meta: M & {}, 
	extends: (E & AbstractClasse)?): Meta<M, E>
	
	return setmetatable(meta, table.freeze{
		extends = extends,
		
	}) :: Meta<M, E>
end

return table.freeze(Classe)
