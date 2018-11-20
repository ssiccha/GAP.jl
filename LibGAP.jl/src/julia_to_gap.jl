## Converters

## Default
julia_to_gap(x::GAPInputType, ::Val{Recursive}=Val(false), recursion_dict = nothing) where Recursive = x


## Integers
julia_to_gap(x::Int128, ::Val{Recursive}=Val(false), recursion_dict = nothing) where Recursive = MakeObjInt(BigInt(x)) # FIXME: inefficient hack
#julia_to_gap(x::Int64)  = x
julia_to_gap(x::Int32, ::Val{Recursive}=Val(false), recursion_dict = nothing) where Recursive = Int64(x)
julia_to_gap(x::Int16, ::Val{Recursive}=Val(false), recursion_dict = nothing) where Recursive = Int64(x)
julia_to_gap(x::Int8, ::Val{Recursive}=Val(false), recursion_dict = nothing) where Recursive = Int64(x)

## Unsigned Integers
julia_to_gap(x::UInt128, ::Val{Recursive}=Val(false), recursion_dict = nothing) where Recursive = MakeObjInt(BigInt(x)) # FIXME: inefficient hack
julia_to_gap(x::UInt64, ::Val{Recursive}=Val(false), recursion_dict = nothing) where Recursive = MakeObjInt(BigInt(x)) # FIXME: inefficient hack
julia_to_gap(x::UInt32, ::Val{Recursive}=Val(false), recursion_dict = nothing) where Recursive = Int64(x)
julia_to_gap(x::UInt16, ::Val{Recursive}=Val(false), recursion_dict = nothing) where Recursive = Int64(x)
julia_to_gap(x::UInt8, ::Val{Recursive}=Val(false), recursion_dict = nothing) where Recursive  = Int64(x)

## BigInts
julia_to_gap(x::BigInt, ::Val{Recursive}=Val(false), recursion_dict = nothing) where Recursive = MakeObjInt(x)

## Rationals
function julia_to_gap(x::Rational{T}, ::Val{Recursive}=Val(false), recursion_dict = nothing) where Recursive where T <: Integer
    denom_julia = denominator(x)
    numer_julia = numerator(x)
    if denom_julia == 0
        if numer_julia >= 0
            return GAP.Globals.infinity
        else
            return -GAP.Globals.infinity
        end
    end
    numer = julia_to_gap(numer_julia)
    denom = julia_to_gap(denom_julia)
    return Globals.QUO(numer,denom)
end

## Floats
julia_to_gap(x::Float64, ::Val{Recursive}=Val(false), recursion_dict = nothing) where Recursive = NEW_MACFLOAT(x)
julia_to_gap(x::Float32, ::Val{Recursive}=Val(false), recursion_dict = nothing) where Recursive = NEW_MACFLOAT(Float64(x))
julia_to_gap(x::Float32, ::Val{Recursive}=Val(false), recursion_dict = nothing) where Recursive = NEW_MACFLOAT(Float64(x))
julia_to_gap(x::Float16, ::Val{Recursive}=Val(false), recursion_dict = nothing) where Recursive = NEW_MACFLOAT(Float64(x))

## Chars
julia_to_gap(x::Char, ::Val{Recursive}=Val(false), recursion_dict = nothing) where Recursive = CharWithValue(Cuchar(x)) 

## Strings and symbols
julia_to_gap(x::AbstractString, ::Val{Recursive}=Val(false), recursion_dict = nothing) where Recursive = MakeString(x)
julia_to_gap(x::Symbol, ::Val{Recursive}=Val(false), recursion_dict = nothing) where Recursive = MakeString(string(x))

## Arrays
function julia_to_gap(obj::Array{T,1}, recursive::Val{Recursive}=Val(false), recursion_dict = IdDict()) where Recursive where T
    len = length(obj)
    ret_val = NewPlist(len)
    for i in 1:len
        current_obj = obj[i]
        if haskey(recursion_dict,current_obj)
            ret_val[i] = recursion_dict[current_obj]
        else
            if Recursive
                current_converted = julia_to_gap(current_obj,recursive,recursion_dict)
            else
                current_converted = current_obj
            end
            recursion_dict[current_obj] = current_converted
            ret_val[i] = current_converted
        end
    end
    return ret_val
end

## Tuples
function julia_to_gap(obj::Tuple, recursive::Val{Recursive}=Val(false), recursion_dict = IdDict()) where Recursive
    size = length(obj)
    array = Array{Any,1}(undef,size)
    for i in 1:size
        array[i] = obj[i]
    end
    return julia_to_gap(array, recursive, recursion_dict)
end

## Dictionaries
function julia_to_gap(obj::Dict{T,S}, recursive::Val{Recursive}=Val(false), recursion_dict = IdDict()) where Recursive where S where T <: Union{Symbol,AbstractString}
    nr_entries = obj.count
    keys = Array{T,1}(undef,nr_entries)
    entries = Array{S,1}(undef,nr_entries)
    i = 1
    for (x,y) in obj
        keys[i] = x
        entries[i] = y
        i += 1
    end
    return GAP.Globals.CreateRecFromKeyValuePairList(julia_to_gap(keys),julia_to_gap(entries, recursive, recursion_dict))
end


## TODO: BitArray <-> blist; ranges; ...