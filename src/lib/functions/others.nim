#import model
#import definitions
#import fmi2TypesPlatform, fmi2type, fmi2callbackfunctions, modelstate, fmi2eventinfo,
#import logger
import strformat


# https://forum.nim-lang.org/t/7182#45378
# https://forum.nim-lang.org/t/6980#43777mf


##  Creation and destruction of FMU instances and setting debug status
#import ../defs/modelinstance
{.push exportc:"$1",dynlib,cdecl.}


#[ proc fmi2Instantiate2*( instanceName: fmi2String;
                       fmuType: fmi2Type;
                       fmuGUID: fmi2String;
                       fmuResourceLocation: fmi2String;
                       functions: fmi2CallbackFunctions;
                       visible: fmi2Boolean;
                       loggingOn: fmi2Boolean): ModelInstanceRef =
    ##[ 
    (pag.19)
    The function returns a new instance of an FMU or a null pointer when failed.

    An FMU can be instantiated many times (provided capability flag
    canBeInstantiatedOnlyOncePerProcess = false).

    This function must be called successfully before any of the following functions can be called.
    For co-simulation, this function call has to perform all actions of a slave which are necessary
    before a simulation run starts (for example, loading the model file, compilation...).

    Argument instanceName is a unique identifier for the FMU instance. It is used to name the
    instance, for example, in error or information messages generated by one of the fmi2XXX
    functions. It is not allowed to provide a null pointer and this string must be non-empty (in
    other words, must have at least one character that is no white space). [If only one FMU is
    simulated, as instanceName attribute modelName or <ModelExchange/CoSimulation
    modelIdentifier=”..”> from the XML schema fmiModelDescription might be used.]

    Argument fmuType defines the type of the FMU:
     = fmi2ModelExchange: FMU with initialization and events; between events simulation
    of continuous systems is performed with external integrators from the environment
    (see section 3).
     = fmi2CoSimulation: Black box interface for co-simulation (see section 4).

    Argument fmuGUID is used to check that the modelDescription.xml file (see section 2.3) is
    compatible with the C code of the FMU. It is a vendor specific globally unique identifier of the
    XML file (for example, it is a “fingerprint” of the relevant information stored in the XML file). It
    is stored in the XML file as attribute “guid” (see section 0) and has to be passed to the
    fmi2Instantiate function via argument fmuGUID. It must be identical to the one stored
    inside the fmi2Instantiate function; otherwise the C code and the XML file of the FMU
    are not consistent with each other. This argument cannot be null.

    Argument fmuResourceLocation is a URI according to the IETF RFC3986 syntax to
    indicate the location to the “resources” directory of the unzipped FMU archive. The
    following schemes must be understood by the FMU:
    Mandatory: “file” with absolute path (either including or omitting the authority component)
     Optional: “http”, “https”, “ftp”
     Reserved: “fmi2” for FMI for PLM.

    [Example: An FMU is unzipped in directory “C:\temp\MyFMU”, then
    fmuResourceLocation = “file:///C:/temp/MyFMU/resources” or
    “file:/C:/temp/MyFMU/resources”. Function fmi2Instantiate is then able to read all
    needed resources from this directory, for example maps or tables used by the FMU.]
    Argument functions provides callback functions to be used from the FMU functions to
    utilize resources from the environment (see type fmi2CallbackFunctions below).

    Argument visible = fmi2False defines that the interaction with the user should be
    reduced to a minimum (no application window, no plotting, no animation, etc.). In other
    words, the FMU is executed in batch mode. If visible = fmi2True, the FMU is executed
    in interactive mode, and the FMU might require to explicitly acknowledge start of simulation /
    instantiation / initialization (acknowledgment is non-blocking).

    If loggingOn = fmi2True, debug logging is enabled. If loggingOn = fmi2False, debug
    logging is disabled. [The FMU enable/disables LogCategories which are useful for
    debugging according to this argument. Which LogCategories the FMU sets is unspecified.]
    ]##


 ]#



# https://forum.nim-lang.org/t/7496
# NOTA: otra opción sería usar alloc y dealloc.
proc fmi2Instantiate*( instanceName: fmi2String;
                       fmuType: fmi2Type;
                       fmuGUID: fmi2String;
                       fmuResourceLocation: fmi2String;
                       functions: fmi2CallbackFunctions;
                       visible: fmi2Boolean;
                       loggingOn: fmi2Boolean): ModelInstanceRef = #ptr ModelInstance =

    # ignoring arguments: fmuResourceLocation, visible
    echo "Entering fmi2Instantiate"
    if functions.logger.isNil:
        return nil

    if functions.allocateMemory.isNil or 
       functions.freeMemory.isNil:
        functions.logger( functions.componentEnvironment, instanceName, fmi2Error, "error".fmi2String,
                "fmi2Instantiate: Missing callback function.".fmi2String)
        return nil

    if instanceName.cstring.isNil or instanceName.cstring.len == 0:  # 
        functions.logger( functions.componentEnvironment, "?".fmi2String, fmi2Error, "error".fmi2String,
                "fmi2Instantiate: Missing instance name.".fmi2String)
        return nil

    if fmuGUID.cstring.isNil or fmuGUID.cstring.len == 0:
        functions.logger( functions.componentEnvironment, instanceName, fmi2Error, "error".fmi2String,
                  "fmi2Instantiate: Missing GUID.".fmi2String)
        return nil

    if not ($(fmuGUID) == MODEL_GUID): #strcmp(fmuGUID, MODEL_GUID)) {
        functions.logger( functions.componentEnvironment, instanceName, fmi2Error, "error".fmi2String,
                  fmt"fmi2Instantiate: Wrong GUID {$(fmuGUID)}. Expected {MODEL_GUID}.".fmi2String)
        return nil
   
    # Start creating the instance
    var comp = ModelInstanceRef( time: 0, 
                              instanceName: instanceName, 
                              `type`: fmuType, 
                              GUID: fmuGUID )
                             
    if not comp.isNil:
        # set all categories to on or off. fmi2SetDebugLogging should be called to choose specific categories.
        for i in 0 ..< NUMBER_OF_CATEGORIES:
            comp.logCategories[i] = loggingOn


    # if comp.isNil or comp.r.isNil or comp.i.isNil or comp.b.isNil or comp.s.isNil or comp.isPositive.isNil or
    #    comp.instanceName.cstring.isNil or comp.GUID.cstring.isNil:
    #     #functions.logger(functions.componentEnvironment, instanceName, fmi2Error, "error".fmi2String,
    #     #    "fmi2Instantiate: Out of memory.".fmi2String)
    #     echo "WRONG"
    #     return nil
    

    comp.functions = functions

    comp.componentEnvironment = functions.componentEnvironment

    comp.loggingOn = loggingOn

    comp.state = modelInstantiated   # State changed

    setStartValues( comp )    # <------ to be implemented by the includer of this file
    
    comp.isDirtyValues = fmi2True # because we just called setStartValues
    comp.isNewEventIteration = fmi2False

    comp.eventInfo.newDiscreteStatesNeeded = fmi2False
    comp.eventInfo.terminateSimulation = fmi2False
    comp.eventInfo.nominalsOfContinuousStatesChanged = fmi2False
    comp.eventInfo.valuesOfContinuousStatesChanged = fmi2False
    comp.eventInfo.nextEventTimeDefined = fmi2False
    comp.eventInfo.nextEventTime = 0

    # FILTERED_LOG(comp, fmi2OK, LOG_FMI_CALL, "fmi2Instantiate: GUID=%s", fmuGUID)
    echo "ok-4"     # FIXME-----
    filteredLog( comp, fmi2OK, LOG_FMI_CALL, fmt"fmi2Instantiate: GUID={$fmuGUID}".fmi2String, fmuGUID)
    echo "ok-5"     # -----------
    echo comp
    echo "leaving fmi2Instantiate"
    return comp  



#[
In addition to GC_ref and GC_unref you can avoid the garbage collector 
by manually allocating memory with procs like:
  alloc, alloc0, allocShared, allocShared0 or allocCStringArray. 
  
The garbage collector won't try to free them, you need to call their 
respective dealloc pairs (dealloc, deallocShared, deallocCStringArray, etc) 
when you are done with them or they will leak.
]#


#[
if (!comp || !comp->r || !comp->i || !comp->b || !comp->s || !comp->isPositive
    || !comp->instanceName || !comp->GUID) {
    functions->logger(functions->componentEnvironment, instanceName, fmi2Error, "error",
        "fmi2Instantiate: Out of memory.");
    return NULL;
}
]#




#------------



proc setString*(comp:ModelInstanceRef, vr:fmi2ValueReference, value:fmi2String):fmi2Status =
    return fmi2SetString(comp, unsafeAddr(vr), 1, unsafeAddr(value))
#-----------
#[
void fmi2FreeInstance(fmi2Component c) {
    ModelInstance *comp = (ModelInstance *)c;
    if (!comp) return;
    if (invalidState(comp, "fmi2FreeInstance", MASK_fmi2FreeInstance))
        return;
    FILTERED_LOG(comp, fmi2OK, LOG_FMI_CALL, "fmi2FreeInstance")

    if (comp->r) comp->functions->freeMemory(comp->r);
    if (comp->i) comp->functions->freeMemory(comp->i);
    if (comp->b) comp->functions->freeMemory(comp->b);
    if (comp->s) {
        int i;
        for (i = 0; i < NUMBER_OF_STRINGS; i++){
            if (comp->s[i]) comp->functions->freeMemory((void *)comp->s[i]);
        }
        comp->functions->freeMemory((void *)comp->s);
    }
    if (comp->isPositive) comp->functions->freeMemory(comp->isPositive);
    if (comp->instanceName) comp->functions->freeMemory((void *)comp->instanceName);
    if (comp->GUID) comp->functions->freeMemory((void *)comp->GUID);
    comp->functions->freeMemory(comp);
}
]#

# https://nim-lang.org/docs/destructors.html
proc fmi2FreeInstance*(comp: ModelInstanceRef) =
    ##[
    Disposes the given instance, unloads the loaded model, and frees all the allocated memory
    and other resources that have been allocated by the functions of the FMU interface. If a null
    pointer is provided for “c”, the function call is ignored (does not have an effect).
    ]##
    echo "ENTERING: fmi2FreeInstance"
    #var comp: ptr ModelInstance = cast[ptr ModelInstance](c)
    #if comp.isNil:
    #    return
    #comp = nil

    #echo comp.GUID
    #echo comp[].GUID
    `=destroy`(comp[])
    GC_fullCollect()


    #if (invalidState(comp, "fmi2FreeInstance", MASK_fmi2FreeInstance)):
    #    return
    #filteredLog(comp, fmi2OK, LOG_FMI_CALL, "fmi2FreeInstance")
    #echo "OKK"
    #comp = nil
    #[
    if not (comp.r.isNil):
       comp.functions.freeMemory(comp.r)
    #if not (comp.i.isNil):
    #   comp.functions.freeMemory(comp.i)
    if not (comp.b.isNil):
       comp.functions.freeMemory(comp.b)
    if not (comp.s.isNil):
        #var i:int
        #for i in 0 ..< NUMBER_OF_STRINGS:
        #    if (comp.s[i]):
        #        comp.functions.freeMemory( comp.s[i] )

        comp.functions.freeMemory( comp.s )
    ]#
    #[
    if (comp.isPositive):
       comp.functions.freeMemory(comp.isPositive)

    if (comp.instanceName):
       comp.functions.freeMemory(comp.instanceName)

    if (comp.GUID):
       comp.functions.freeMemory( comp.GUID )
    ]#
    #comp.functions.freeMemory(unsafeAddr(comp))
    #GC_fullcollect()

proc fmi2SetDebugLogging*( comp:ModelInstanceRef, loggingOn: fmi2Boolean,
                           nCategories: csize_t, categories: pointer):fmi2Status =  #categories: ptr fmi2String
    ##[
    The function controls debug logging that is output via the logger function callback.
    If loggingOn = fmi2True, debug logging is enabled, otherwise it is switched off.
    If loggingOn = fmi2True and nCategories = 0, then all debug messages shall be
    output.
    If loggingOn=fmi2True and nCategories > 0, then only debug messages according to
    the categories argument shall be output. Vector categories has
    nCategories elements. The allowed values of categories are defined by the modeling
    environment that generated the FMU. Depending on the generating modeling environment,
    none, some or all allowed values for categories for this FMU are defined in the
    modelDescription.xml file via element “fmiModelDescription.LogCategories”, see
    section 2.2.4.
    ]##
    #var comp: ptr ModelInstance = cast[ptr ModelInstance](c)
    if invalidState(comp, "fmi2SetDebugLogging", MASK_fmi2SetDebugLogging):
        return fmi2Error
    comp.loggingOn = loggingOn
    filteredLog(comp, fmi2OK, LOG_FMI_CALL, "fmi2SetDebugLogging".fmi2String)

    # reset all categories
    for j in 0 ..< nCategories:
        comp.logCategories[j] = fmi2False

    if nCategories == 0:
        # no category specified, set all categories to have loggingOn value
        for j in 0 ..< nCategories:
            comp.logCategories[j] = loggingOn

    else:
        # set specific categories on
        for i in 0 ..< nCategories:
            discard

            #[ TODO
            var categoryFound: fmi2Boolean  = fmi2False
            for j in 0 ..< nCategories:
                if not (logCategoriesNames[j] == categories[i]):
                    comp.logCategories[j] = loggingOn
                    categoryFound = fmi2True
                    break
            ]#
            #[
            if not categoryFound:
                comp.functions.logger( comp.componentEnvironment, comp.instanceName, fmi2Warning,
                    logCategoriesNames[LOG_ERROR],
                    fmt"logging category '{categories[i]}' is not supported by model" )

            ]#

    return fmi2OK
{.pop.}
