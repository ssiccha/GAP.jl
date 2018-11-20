## Converters

## Default
gap_to_julia(::Type{GAPInputType},x::GAPInputType, recusive_dict = nothing) = x
gap_to_julia(::Type{Any},         x::GAPInputType, recusive_dict = nothing) = gap_to_julia(x)
gap_to_julia(::Type{Any},         x::Any         , recusive_dict = nothing) = x

## Integers
gap_to_julia(::Type{Int128} ,x::Int64, recusive_dict = nothing) = trunc(Int128 ,x)
gap_to_julia(::Type{Int64}  ,x::Int64, recusive_dict = nothing) = x
gap_to_julia(::Type{Int32}  ,x::Int64, recusive_dict = nothing) = trunc(Int32  ,x)
gap_to_julia(::Type{Int16}  ,x::Int64, recusive_dict = nothing) = trunc(Int16  ,x)
gap_to_julia(::Type{Int8}   ,x::Int64, recusive_dict = nothing) = trunc(Int8   ,x)

## Unsigned Integers
gap_to_julia(::Type{UInt128},x::Int64, recusive_dict = nothing) = trunc(UInt128,x)
gap_to_julia(::Type{UInt64} ,x::Int64, recusive_dict = nothing) = trunc(UInt64 ,x)
gap_to_julia(::Type{UInt32} ,x::Int64, recusive_dict = nothing) = trunc(UInt32 ,x)
gap_to_julia(::Type{UInt16} ,x::Int64, recusive_dict = nothing) = trunc(UInt16 ,x)
gap_to_julia(::Type{UInt8}  ,x::Int64, recusive_dict = nothing) = trunc(UInt8  ,x)

## BigInts
gap_to_julia(::Type{BigInt}, x::Int64, recusive_dict = nothing) = BigInt( x )

function gap_to_julia(::Type{BigInt}, x::MPtr, recusive_dict = nothing)
    ## Check for correct type
    if ! Globals.IsInt(x)
        throw(ArgumentError("GAP object is not a large integer"))
    end
    ## get size of GAP BigInt (in limbs), multiply
    ## by 64 to get bits
    size_limbs = ccall(:GAP_SizeInt,Cint,(MPtr,),x)
    size = abs(size_limbs * sizeof(UInt) * 8)
    ## allocate new GMP
    new_bigint = Base.GMP.MPZ.realloc2(size)
    new_bigint.size = size_limbs
    ## Get limb address ptr
    addr = ccall(:GAP_AddrInt,Ptr{UInt},(MPtr,),x)
    ## Copy limbs
    unsafe_copyto!( new_bigint.d, addr, abs(size_limbs) )
    return new_bigint
end

## Rationals
function gap_to_julia(::Type{Rational{T}}, x::Int64, recusive_dict = nothing) where T <: Integer
    numerator = gap_to_julia(T,x)
    return numerator // T(1)
end

function gap_to_julia(::Type{Rational{T}}, x::MPtr, recusive_dict = nothing) where T <: Integer
    if Globals.IsInt(x)
        return gap_to_julia(T,x) // T(1)
    end
    if ! Globals.IsRat(x)
        throw(ArgumentError("obj is not a rational"))
    end
    numer = Globals.NumeratorRat(x)
    denom = Globals.DenominatorRat(x)
    return gap_to_julia(T,numer) // gap_to_julia(T,denom)
end

## Floats
function gap_to_julia( ::Type{Float64}, obj::MPtr, recusive_dict = nothing)
    if ! Globals.IsFloat(obj)
        throw(ArgumentError("<obj> is not a MacFloat"))
    end
    return ValueMacFloat(obj)
end

gap_to_julia( ::Type{Float32}, obj::MPtr, recusive_dict = nothing) = Float32(gap_to_julia(Float64,obj))
gap_to_julia( ::Type{Float16}, obj::MPtr, recusive_dict = nothing) = Float16(gap_to_julia(Float64,obj))
gap_to_julia( ::Type{BigFloat}, obj::MPtr, recusive_dict = nothing) = BigFloat(gap_to_julia(Float64,obj))

## Chars
function gap_to_julia( ::Type{Cuchar}, obj::MPtr, recusive_dict = nothing)
    if ! Globals.IsChar( obj )
        throw(ArgumentError("argument is not a character object"))
    end
    return trunc( Cuchar, Globals.INT_CHAR(obj ) )
end

## Strings and symbols
function gap_to_julia(::Type{AbstractString},obj::MPtr, recusive_dict = nothing)
    if ! Globals.IsStringRep(obj)
        throw(ArgumentError("<obj> is not a string"))
    end
    return CSTR_STRING(obj)
end
gap_to_julia(::Type{Symbol},obj::MPtr, recusive_dict = nothing) = Symbol(gap_to_julia(AbstractString,obj))

## Arrays
function gap_to_julia( ::Type{Array{GAPObj,1}}, obj :: MPtr , recursive_dict = IdDict() )
    if ! Globals.IsList( obj )
        throw(ArgumentError("<obj> is not a list"))
    end
    len_list = length(obj)
    new_array = Array{Any,1}( undef, len_list)
    for i in 1:len_list
        current_obj = obj[i]
        if haskey(recursive_dict,current_obj)
            new_array[ i ] = recursive_dict[current_obj]
        else
            new_array[ i ] = current_obj
            recursive_dict[ current_obj ] = new_array[ i ]
        end
    end
    return new_array
end

function gap_to_julia( ::Type{Array{T,1}}, obj :: MPtr, recursive_dict = IdDict() ) where T
    if ! Globals.IsList( obj )
        throw(ArgumentError("<obj> is not a list"))
    end
    len_list = length(obj)
    new_array = Array{T,1}( undef, len_list)
    for i in 1:len_list
        current_obj = obj[ i ]
        if haskey(recursive_dict,current_obj)
            new_array[ i ] = recursive_dict[current_obj]
        else
            new_array[ i ] = gap_to_julia(T,current_obj,recursive_dict)
            recursive_dict[ current_obj ] = new_array[ i ]
        end
    end
    return new_array
end

## Tuples
function gap_to_julia( ::Type{T}, obj::MPtr, recursive_dict = IdDict() ) where T <: Tuple
    if ! Globals.IsList(obj)
        throw(ArgumentError("<obj> is not a list"))
    end
    list_translated = gap_to_julia(Array{GAPObj,1},obj)
    parameters = T.parameters
    list = Array{Any,1}(undef,length(parameters))
    for i in 1:length(parameters)
        list[i] = gap_to_julia(parameters[i],list_translated[i])
    end
    return T(list)
end

## Dictionaries
function gap_to_julia( ::Type{Dict{Symbol,T}}, obj :: MPtr, recursive_dict = IdDict() ) where T
    if ! Globals.IsRecord( obj )
        throw(ArgumentError("first argument is not a record"))
    end
    names = Globals.RecNames( obj )
    names_list = gap_to_julia(Array{Symbol,1},names)
    dict = Dict{Symbol,T}()
    for i in names_list
        current_obj = getproperty(obj,i)
        if haskey(recursive_dict,current_obj)
            dict[ i ] = recursive_dict[current_obj]
        else
            translated_obj = gap_to_julia(T,current_obj,recursive_dict)
            dict[ i ] = translated_obj
            recursive_dict[ current_obj ] = translated_obj
        end
    end
    return dict
end

## TODO: BitArray <-> blist; ranges; ...

## Generic conversions

gap_to_julia(x::Any)  = x

function gap_to_julia(x::MPtr)
    if Globals.IsInt(x)
        return gap_to_julia(BigInt,x)
    elseif Globals.IsRat(x)
        return gap_to_julia(Rational{BigInt},x)
    elseif Globals.IsFloat(x)
        return gap_to_julia(Float64,x)
    elseif Globals.IsChar(x)
        return gap_to_julia(Cuchar,x)
    elseif Globals.IsString(x)
        return gap_to_julia(AbstractString,x)
    elseif Globals.IsList(x)
        return gap_to_julia(Array{Any,1},x)
    elseif Globals.IsRecord(x)
        return gap_to_julia(Dict{Symbol,Any},x)
    end
    return x
end