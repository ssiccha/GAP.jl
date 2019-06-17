import Base: convert, getindex, setindex!, length, show

const Obj = Union{MPtr,FFE,Int64,Bool,Nothing}

function Base.show( io::IO, obj::Union{MPtr,FFE} )
    str = Globals.String( obj )
    stri = CSTR_STRING( str )
    print(io,"GAP: $stri")
end

function Base.string( obj::Union{MPtr,FFE} )
    str = Globals.String( obj )
    return CSTR_STRING( str )
end

## implement indexing interface
Base.getindex(x::MPtr, i::Int64) = Globals.ELM_LIST(x, i)
Base.setindex!(x::MPtr, v::Any, i::Int64 ) = Globals.ASS_LIST( x, i, v )
Base.length(x::MPtr) = Globals.Length(x)
Base.firstindex(x::MPtr) = 1
Base.lastindex(x::MPtr) = Globals.Length(x)

# matrix
Base.getindex(x::MPtr, i::Int64, j::Int64) = Globals.ELM_LIST(x, i, j)
Base.setindex!(x::MPtr, v::Any, i::Int64, j::Int64) = Globals.ASS_LIST(x, i, j, v)

# records
RNamObj(f::Union{Symbol,Int64,AbstractString}) = Globals.RNamObj(MakeString(string(f)))
# note: we don't use Union{Symbol,Int64,AbstractString} below to avoid
# ambiguity between these methods and method `getproperty(x, f::Symbol)`
# from Julia's Base module
Base.getproperty(x::MPtr, f::Symbol) = Globals.ELM_REC(x, RNamObj(f))
Base.getproperty(x::MPtr, f::Union{AbstractString,Int64}) = Globals.ELM_REC(x, RNamObj(f))
Base.setproperty!(x::MPtr, f::Symbol, v) = Globals.ASS_REC(x, RNamObj(f), v)
Base.setproperty!(x::MPtr, f::Union{AbstractString,Int64}, v) = Globals.ASS_REC(x, RNamObj(f), v)

#
Base.zero(x::Union{MPtr,FFE}) = Globals.ZERO(x)
Base.one(x::Union{MPtr,FFE}) = Globals.ONE(x)
Base.:-(x::Union{MPtr,FFE}) = Globals.AINV(x)

#
typecombinations = ((:MPtr,:MPtr),
                    (:FFE,:FFE),
                    (:MPtr,:FFE),
                    (:FFE,:MPtr),
                    (:MPtr,:Int64),
                    (:Int64,:MPtr),
                    (:FFE,:Int64),
                    (:Int64,:FFE),
                    (:MPtr,:Bool),
                    (:Bool,:MPtr),
                    (:FFE,:Bool),
                    (:Bool,:FFE))
function_combinations = ((:+,:SUM),
                         (:-,:DIFF),
                         (:*,:PROD),
                         (:/,:QUO),
                         (:\,:LQUO),
                         (:^,:POW),
                         (:mod,:MOD),
                         (:<,:LT),
                         (:(==),:EQ))

for (left, right) in typecombinations
    for (funcJ, funcC) in function_combinations
        @eval begin
            Base.$(funcJ)(x::$left,y::$right) = Globals.$(funcC)(x,y)
        end
    end
end


"""
    LoadPackageAndExposeGlobals(package::String, mod::String; all_globals::Bool = false)
    LoadPackageAndExposeGlobals(package::String, mod::Module = Main; all_globals::Bool = false)

`LoadPackageAndExposeGlobals` loads `package` into GAP via `LoadPackage`,
and stores all newly defined GAP globals as globals in the module `mod`. If `mod` is
a string, the function creates a new module, if `mod` is a Module, it uses `mod` directly.

The function is intended to be used for creating mock modules for GAP packages.
If you load the package `CAP` via

    LoadPackageAndExposeGlobals( "CAP", "CAP" )

you can use CAP commands via

    CAP.PreCompose( a, b )

"""
function LoadPackageAndExposeGlobals(package::String, mod::String; all_globals::Bool = false)
    mod_sym = Symbol(mod)
    Base.MainInclude.eval(:(
        module $(mod_sym)
            import GAP
        end
    ))
    ## Adds the new module to the Main module, so it is directly accessible in the julia REPL
    mod_mod = Base.MainInclude.eval(:(Main.$(mod_sym)))

    ## We need to call `invokelatest` as the module `mod_mod` was only created during the
    ## call of this function in a different module, so its world age is higher than the
    ## function calls world age.
    Base.invokelatest(LoadPackageAndExposeGlobals, package, mod_mod; all_globals = all_globals)
end

function LoadPackageAndExposeGlobals(package::String, mod::Module; all_globals::Bool = false)
    current_gvar_list = nothing
    if !all_globals
        current_gvar_list = Globals.ShallowCopy(Globals.NamesGVars())
    end
    load_package = EvalString("LoadPackage(\"$package\")")
    if load_package == Globals.fail
        error("cannot load package $package")
    end
    new_gvar_list = nothing
    if all_globals
        new_gvar_list = Globals.NamesGVars()
    else
        new_gvar_list = Globals.Difference(Globals.NamesGVars(),current_gvar_list)
    end
    new_symbols = gap_to_julia(Array{Symbol,1},new_gvar_list)
    for sym in new_symbols
        try
            mod.eval(:(
                $(sym)=GAP.Globals.$(sym)
            ))
        catch
        end
    end
end

export LoadPackageAndExposeGlobals

function Display(x::MPtr)
    ## FIXME: Get rid of this horrible hack
    ##        once GAP offers a consistent
    ##        DisplayString function
    local_var = "julia_gap_display_tmp"
    AssignGlobalVariable(local_var,x)
    xx = EvalStringEx("Display($local_var);")[1]
    if xx[1] == true
        println(GAP.gap_to_julia(AbstractString, xx[5]))
    else
        error("variable was not correctly evaluated")
    end
end
