--!strict

local Types = require(script.Types)

type func = (...any) -> any
type metaOfClass<C> = index<getmetatable<C & AbstractClasse>, 'meta'>

type Meta<D, E> = setmetatable<D, {
	read extends: (E & AbstractClasse)?,
	
	read self: Types.getReturningElement<
		index<D, 'construct'>, '1'> & D &
		index<metaOfClass<E>, 'self'>,
}>

export type BaseMeta = setmetatable<{
	construct: func,
	init: func
}, {
	read extends: AbstractClasse?,
	read self: {}
}>

export type AbstractClasse = setmetatable<{
	read new: func,
}, {
	read childs: {AbstractClasse},
	read parent: AbstractClasse?,
	read overrides: {[any]: true},
	read initChain: {func}?,
	read metadata: {
		__index: {[any]: any}
	},
	read meta: {[any]: any},
	read constructor: func
}>

export type Classe<M> = setmetatable<{
	read new: Types.moveParams<
		index<M, 'construct'>, '2', nil, 
		'1', () -> Self<M>>
}, {
	read childs: {AbstractClasse},
	read parent: index<getmetatable<M & BaseMeta>, 'extends'>,
	read overrides: {[any]: true},
	read initChain: {func}?,
	read metadata: {
		__index: {[any]: any}
	},
	read meta: getmetatable<M & BaseMeta>,
	read constructor: index<M, 'construct'> & func
}>

export type Self<M> = typeof(setmetatable(
	{} :: index<getmetatable<M>, 'self'>, {}
))

type Super<E> = index<getmetatable<E & any>, 'constructor'>

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
	
	local parentData = if parent then 
		getmetatable(parent) else nil
	
	local data = {
		parent = parent,
		childs = {},
		overrides = {},
		constructor = constructor,
		__newindex = __meta.__newindex
	}
	
	local initChain: {func}? = nil
	
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
	data.metadata = metadata
	meta.construct, meta.init = nil, nil
	
	for index: any, data: any in meta :: BaseMeta do
		if type(index) == 'string' and
			index:find('^__') then

			metadata[index] = data
			continue
		end

		metadata.__index[index] = data
	end
	
	local initChainLen = initChain and #initChain or 0
	
	local self = {new = function(...: any)
		local obj = {}; constructor(obj, ...)
		setmetatable(obj, metadata)

		for i = 1, initChainLen do
			(initChain[i] :: func)(obj)
		end

		return obj
	end}
	
	return setmetatable(self, table.freeze(data)) :: Classe<M>
end

function Classe.meta<M, E>(meta: M & {}, 
	extends: E?): (Meta<M, E>, Super<E>)
	
	local super = if extends then getmetatable(
		extends :: AbstractClasse).constructor else nil
	
	return setmetatable(meta, table.freeze{
		extends = extends,
		
	}) :: Meta<M, E>, super :: Super<E>
end

return table.freeze(Classe)
