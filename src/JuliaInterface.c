/*
 * JuliaInterface: Test interface to julia
 */

#include "src/compiled.h"          /* GAP headers */
#include <julia.h>

#undef PACKAGE_BUGREPORT
#undef PACKAGE_NAME
#undef PACKAGE_STRING
#undef PACKAGE_TARNAME
#undef PACKAGE_URL
#undef PACKAGE_VERSION
#include "pkgconfig.h"

Obj TheTypeJuliaFunction;
Obj TheTypeJuliaObject;

jl_function_t* julia_array_pop;
jl_function_t* julia_array_push;
jl_function_t* julia_array_setindex;
jl_value_t* GAP_MEMORY_STORAGE_INTS;
jl_value_t* GAP_MEMORY_STORAGE;

jl_value_t* get_next_julia_position(){
    jl_value_t* position_jl = jl_call1( julia_array_pop, GAP_MEMORY_STORAGE_INTS );
    int position = jl_unbox_int64( position_jl );
    if(jl_unbox_int64(jl_eval_string("length(GAP_MEMORY_STORAGE_INTS)"))==0){
        jl_call2( julia_array_push, GAP_MEMORY_STORAGE, jl_box_int64( 0 ) );
        jl_value_t* new_position_jl = jl_box_int64( position + 1 );
        jl_call2( julia_array_push, GAP_MEMORY_STORAGE_INTS, new_position_jl );
    }
    return position_jl;
}

void SET_JULIA_FUNC(Obj o, jl_function_t* f) {
    ADDR_OBJ(o)[0] = (Obj)f;
}

void SET_JULIA_OBJ(Obj o, jl_value_t* p) {
    ADDR_OBJ(o)[0] = (Obj)p;
}

jl_function_t* GET_JULIA_FUNC(Obj o) {
    return (jl_function_t*)(ADDR_OBJ(o)[0]);
}


jl_value_t* GET_JULIA_OBJ(Obj o) {
    return (jl_value_t*)(ADDR_OBJ(o)[0]);
}

Obj JuliaFunctionTypeFunc(Obj o)
{
    return TheTypeJuliaFunction;
}

Obj JuliaObjectTypeFunc(Obj o)
{
    return TheTypeJuliaObject;
}

#define IS_JULIA_FUNC(o) (TNUM_OBJ(o) == T_JULIA_FUNC)
#define IS_JULIA_OBJ(o) (TNUM_OBJ(o) == T_JULIA_OBJ)

UInt T_JULIA_FUNC = 0;
UInt T_JULIA_OBJ = 0;

Obj NewJuliaFunc(jl_function_t* C)
{
    Obj o;
    o = NewBag(T_JULIA_FUNC, 1 * sizeof(Obj));
    SET_JULIA_FUNC(o, C);
    return o;
}

Obj NewJuliaObj(jl_value_t* C)
{
    Obj o;
    o = NewBag(T_JULIA_OBJ, 2 * sizeof(Obj));
    SET_JULIA_OBJ(o, C);
    jl_value_t* input_position_jl = get_next_julia_position();
    ADDR_OBJ(o)[1] = (Obj)input_position_jl;
    jl_call3( julia_array_setindex, GAP_MEMORY_STORAGE, C, input_position_jl );
    return o;
}

void JuliaObjFreeFunc( Obj val )
{
    jl_value_t* list_number = (jl_value_t*)(ADDR_OBJ(val)[1]);
    jl_call3( julia_array_setindex, GAP_MEMORY_STORAGE, jl_box_int64( 0 ), list_number );
    jl_call2( julia_array_push, GAP_MEMORY_STORAGE_INTS, list_number );
}

Obj JuliaFunction( Obj self, Obj string )
{
    
    return NewJuliaFunc( jl_get_function(jl_base_module, CSTR_STRING( string ) ) );
    
}

Obj JuliaCallFunc0Arg( Obj self, Obj func )
{
    return NewJuliaObj( jl_call0( GET_JULIA_FUNC( func ) ) );
}

Obj JuliaCallFunc1Arg( Obj self, Obj func, Obj arg )
{
    return NewJuliaObj( jl_call1( GET_JULIA_FUNC( func ), GET_JULIA_OBJ( arg ) ) );
}

Obj JuliaCallFunc2Arg( Obj self, Obj func, Obj arg1, Obj arg2 )
{
    return NewJuliaObj( jl_call2( GET_JULIA_FUNC( func ), GET_JULIA_OBJ( arg1 ), GET_JULIA_OBJ( arg2 ) ) );
}

Obj JuliaCallFunc3Arg( Obj self, Obj func, Obj arg1, Obj arg2, Obj arg3 )
{
    return NewJuliaObj( jl_call3( GET_JULIA_FUNC( func ), GET_JULIA_OBJ( arg1 ), GET_JULIA_OBJ( arg2 ), GET_JULIA_OBJ( arg3 ) ) );
}

Obj JuliaEvalString( Obj self, Obj string )
{
    jl_value_t* result = jl_eval_string( CSTR_STRING( string ) );
    if(!jl_is_nothing(result)){
      return NewJuliaObj( result );
    }
    return 0;
}

Obj JuliaUnbox_internal( jl_value_t* julia_obj )
{   
    size_t i;

    // small int
    if(jl_typeis(julia_obj, jl_int64_type)){
        return INTOBJ_INT( jl_unbox_int64( julia_obj ) );
    }
    if(jl_typeis(julia_obj, jl_int32_type)){
        return INTOBJ_INT( jl_unbox_int32( julia_obj ) );
    }
    if(jl_typeis(julia_obj, jl_int16_type)){
        return INTOBJ_INT( jl_unbox_int16( julia_obj ) );
    }
    if(jl_typeis(julia_obj, jl_int8_type)){
        return INTOBJ_INT( jl_unbox_int8( julia_obj ) );
    }
    if(jl_typeis(julia_obj, jl_uint64_type)){
        return INTOBJ_INT( jl_unbox_uint64( julia_obj ) );
    }
    if(jl_typeis(julia_obj, jl_uint32_type)){
        return INTOBJ_INT( jl_unbox_uint32( julia_obj ) );
    }
    if(jl_typeis(julia_obj, jl_uint16_type)){
        return INTOBJ_INT( jl_unbox_uint16( julia_obj ) );
    }
    if(jl_typeis(julia_obj, jl_uint8_type)){
        return INTOBJ_INT( jl_unbox_uint8( julia_obj ) );
    }
    
    // float
    else if(jl_typeis(julia_obj, jl_float64_type)){
        return NEW_MACFLOAT( jl_unbox_float64( julia_obj ) );
    }
    else if(jl_typeis(julia_obj, jl_float32_type)){
        return NEW_MACFLOAT( jl_unbox_float32( julia_obj ) );
    }
    
    // string
    else if(jl_typeis(julia_obj, jl_string_type)){
        Obj return_string;
        C_NEW_STRING( return_string, jl_string_len( julia_obj ), jl_string_data( julia_obj ) );
        return return_string;
    }
    
    // bool
    else if(jl_typeis(julia_obj, jl_bool_type)){
        if(jl_unbox_bool(julia_obj)==0){
            return False;
        }
        else{
            return True;
        }
    }
    
    // array (1-dim)
    else if(jl_is_array(julia_obj)){
        Obj current_element;
        jl_array_t* array_ptr = (jl_array_t*)julia_obj;
        size_t len = jl_array_len(array_ptr);
        Obj return_list = NEW_PLIST( T_PLIST, len );
        SET_LEN_PLIST( return_list, len );
        for(i=0;i<len;i++){
            jl_value_t* current_jl_element = jl_arrayref( array_ptr, i );
            current_element = JuliaUnbox_internal( current_jl_element );
            SET_ELM_PLIST( return_list, i+1, current_element );
            CHANGED_BAG( return_list );
        }
        return return_list;
    }
    
    return Fail;
}

Obj JuliaUnbox( Obj self, Obj obj ){
    
    jl_value_t* julia_obj = GET_JULIA_OBJ( obj );
    
    return JuliaUnbox_internal( julia_obj );
    
}

jl_value_t* JuliaBox_internal( Obj obj )
{   
    size_t i;

    //integer, small and large
    if(IS_INTOBJ(obj)){
        return jl_box_int64( INT_INTOBJ( obj ) );
        // TODO: BIGINT
    }
    
    //float
    else if(IS_MACFLOAT(obj)){
        return jl_box_float64( VAL_MACFLOAT( obj ) );
    }
    
    //string
    else if(IS_STRING(obj)){
        return jl_cstr_to_string( CSTR_STRING( obj ) );
    }
    
    //bool
    else if(obj == True){
        return jl_box_bool( 1 );
    }
    else if(obj == False){
        return jl_box_bool( 0 );
    }
    
    //perm
    else if(TNUM_OBJ(obj) == T_PERM2){
        jl_value_t* array_type = jl_apply_array_type((jl_value_t*)jl_uint16_type,1);
        jl_array_t* new_perm_array = jl_alloc_array_1d(array_type, DEG_PERM2(obj));
        UInt2* perm_array = ADDR_PERM2(obj);
        for(i=0;i<DEG_PERM2(obj);i++){
            jl_arrayset(new_perm_array, jl_box_uint16( perm_array[ i ] ), i );
        }
        return (jl_value_t*)(new_perm_array);
    }
    
    else if(TNUM_OBJ(obj) == T_PERM4){
        jl_value_t* array_type = jl_apply_array_type((jl_value_t*)jl_uint32_type,1);
        jl_array_t* new_perm_array = jl_alloc_array_1d(array_type, DEG_PERM4(obj));
        UInt4* perm_array = ADDR_PERM4(obj);
        for(i=0;i<DEG_PERM4(obj);i++){
            jl_arrayset(new_perm_array, jl_box_uint32( perm_array[ i ] ), i );
        }
        return (jl_value_t*)(new_perm_array);
    }
    
    // plist
    else if(IS_PLIST(obj)){
        size_t len = LEN_PLIST(obj);
        jl_value_t* array_type = jl_apply_array_type((jl_value_t*)jl_any_type,1);
        jl_array_t* new_array = jl_alloc_array_1d(array_type, len);
        for(i=0;i<len;i++){
            jl_arrayset(new_array,JuliaBox_internal(ELM_PLIST(obj,i+1)),i);
        }
        return (jl_value_t*)(new_array);
    }
    
    return 0;
}

Obj JuliaSetVal( Obj self, Obj name, Obj julia_val )
{
    jl_value_t* julia_obj=GET_JULIA_OBJ( julia_val );
    jl_sym_t* julia_symbol = jl_symbol( CSTR_STRING( name ) );
    jl_set_global( jl_main_module, julia_symbol, julia_obj );
    return 0;
}

Obj JuliaBox( Obj self, Obj obj )
{
    jl_value_t* julia_ptr = JuliaBox_internal( obj );
    if( julia_ptr == 0)
        return Fail;
    return NewJuliaObj( julia_ptr );
    
}


// Obj JuliaCallFuncXArg( Obj self, Obj func, Obj args )
// {
//     int32_t len = LEN_PLIST( args );
//     jl_value_t** arg_pointer;
//     JL_GC_PUSHARGS(arg_pointer, len);
//     Obj current_element;
//     for(int32_t i=0;i<len;i++){
//         current_element = ELM_PLIST( args, i + 1 );
//         arg_pointer[ i ] = JuliaBox_internal(current_element);
//     }
//     jl_value_t * return_val = jl_call( GET_JULIA_FUNC( func ), arg_pointer, len );
//     JL_GC_POP();
//     return NewJuliaObj( return_val );
// }


typedef Obj (* GVarFunc)(/*arguments*/);

#define GVAR_FUNC_TABLE_ENTRY(srcfile, name, nparam, params) \
  {#name, nparam, \
   params, \
   (GVarFunc)name, \
   srcfile ":Func" #name }

// Table of functions to export
static StructGVarFunc GVarFuncs [] = {
    GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", JuliaFunction, 1, "string" ),
    GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", JuliaCallFunc0Arg, 1, "func" ),
    GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", JuliaCallFunc1Arg, 2, "func,obj" ),
    GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", JuliaCallFunc2Arg, 3, "func,obj1,obj2" ),
    GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", JuliaCallFunc3Arg, 4, "func,obj1,obj2,obj3" ),
//     GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", JuliaCallFuncXArg, 2, "func,arg_list" ),
    GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", JuliaEvalString, 1, "string" ),
    GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", JuliaUnbox, 1, "obj" ),
    GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", JuliaBox, 1, "obj" ),
    GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", JuliaSetVal, 2, "name,val" ),
    

	{ 0 } /* Finish with an empty entry */

};

/******************************************************************************
*F  InitKernel( <module> )  . . . . . . . . initialise kernel data structures
*/
static Int InitKernel( StructInitInfo *module )
{
    /* init filters and functions                                          */
    InitHdlrFuncsFromTable( GVarFuncs );
    
    InitCopyGVar( "TheTypeJuliaFunction", &TheTypeJuliaFunction );
    InitCopyGVar( "TheTypeJuliaObject", &TheTypeJuliaObject );
    
    T_JULIA_FUNC = RegisterPackageTNUM("JuliaFunction", JuliaFunctionTypeFunc );
    T_JULIA_OBJ = RegisterPackageTNUM("JuliaObject", JuliaObjectTypeFunc );
    
    InitMarkFuncBags(T_JULIA_FUNC, &MarkNoSubBags);
    InitMarkFuncBags(T_JULIA_OBJ, &MarkNoSubBags);
    
    InitFreeFuncBag(T_JULIA_OBJ, &JuliaObjFreeFunc );
    
    // Initialize libjulia
//     jl_init(JULIA_LDPATH);
    jl_init();

    // HACK: disable the julia garbage collector for now
//     jl_gc_enable(0);
    
    julia_array_pop = jl_get_function( jl_base_module, "pop!" );
    julia_array_push = jl_get_function( jl_base_module, "push!" );
    julia_array_setindex = jl_get_function( jl_base_module, "setindex!" );
    GAP_MEMORY_STORAGE = jl_eval_string( "GAP_MEMORY_STORAGE = [ ]" );
    GAP_MEMORY_STORAGE_INTS = jl_eval_string( "GAP_MEMORY_STORAGE_INTS = [ 1 ]" );

    /* return success                                                      */
    return 0;
}

/******************************************************************************
*F  InitLibrary( <module> ) . . . . . . .  initialise library data structures
*/
static Int InitLibrary( StructInitInfo *module )
{
    /* init filters and functions */
    InitGVarFuncsFromTable( GVarFuncs );

    /* return success                                                      */
    return 0;
}

/******************************************************************************
*F  InitInfopl()  . . . . . . . . . . . . . . . . . table of init functions
*/
static StructInitInfo module = {
 /* type        = */ MODULE_DYNAMIC,
 /* name        = */ "JuliaInterface",
 /* revision_c  = */ 0,
 /* revision_h  = */ 0,
 /* version     = */ 0,
 /* crc         = */ 0,
 /* initKernel  = */ InitKernel,
 /* initLibrary = */ InitLibrary,
 /* checkInit   = */ 0,
 /* preSave     = */ 0,
 /* postSave    = */ 0,
 /* postRestore = */ 0
};

StructInitInfo *Init__Dynamic( void )
{
    return &module;
}
