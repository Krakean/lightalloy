    (*********************************************************************
     *  DSPack 2.3.3                                                     *
     *  DirectShow BaseClass                                             *
     *                                                                   *
     * home page : http://www.progdigy.com                               *
     * email     : hgourvest@progdigy.com                                *
     *                                                                   *
     * date      : 21-02-2003                                            *
     *                                                                   *
     * The contents of this file are used with permission, subject to    *
     * the Mozilla Public License Version 1.1 (the "License"); you may   *
     * not use this file except in compliance with the License. You may  *
     * obtain a copy of the License at                                   *
     * http://www.mozilla.org/MPL/MPL-1.1.html                           *
     *                                                                   *
     * Software distributed under the License is distributed on an       *
     * "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or    *
     * implied. See the License for the specific language governing      *
     * rights and limitations under the License.                         *
     *                                                                   *
     *  Contributor(s)                                                   *
     *    Andriy Nevhasymyy <a.n@email.com>                              *
     *    Milenko Mitrovic  <dcoder@dsp-worx.de>                         *
     *    Michael Andersen  <michael@mechdata.dk>                        *
     *    Martin Offenwanger <coder@dsplayer.de>                         *
     *                                                                   *
     *********************************************************************
     *   This file has been modified from the original as follows:       *
     *     Fixed declaration of IMemInputPin.ReceiveMultiple             *
     *                                                                   *
     *    Sebastian Zierer   <mail1%benjyng@gmx.de>                      *
     *********************************************************************
     *                                                                   *
     *********************************************************************)

{.$DEFINE _DEBUG}      // Debug Log
{.$DEFINE TRACE}      // Trace Criteral Section (DEBUG must be ON)
{.$DEFINE MESSAGE}    // Use OutputDebugString instead of a File (DEBUG must be ON)

{.$DEFINE PERF}       // Show Performace Counter
{.$DEFINE VTRANSPERF} // Show additional TBCVideoTransformFilter Performace Counter (PERF must be ON)

{.$DEFINE WITH_PROPERTY_PAGE} // In case you´re not using Forms for PropertyPages and want
                              // smaller FileSizes, disable this. Disabling this will enable
                              // support for Property Pages from Resource Dialogs.

{$MINENUMSIZE 4}
{$ALIGN ON}
{$RANGECHECKS OFF}

unit BaseClass;

{$IFDEF VER150}
  {$WARN UNSAFE_CODE OFF}
  {$WARN UNSAFE_TYPE OFF}
  {$WARN UNSAFE_CAST OFF}
{$ENDIF}

{$I Jedi.inc}

interface

uses
  Windows, SysUtils, Classes, Math, ActiveX, Messages, DirectShow9,
{$IFDEF WITH_PROPERTY_PAGE}
  Forms,
{$ENDIF}
  ComObj, mmsystem, DSUtils;

const
  OATRUE  = -1;
  OAFALSE = 0;

  DEFAULTCACHE = 10; // Default node object cache size


type
  TBCCritSec = class
  private
    FCritSec : TRTLCriticalSection;
  {$IFDEF _DEBUG}
    FCurrentOwner: Cardinal;
    FLockCount   : Cardinal;
  {$ENDIF}
  public
    constructor Create;
    destructor Destroy; override;
    procedure Lock;
    procedure UnLock;
    function CritCheckIn: boolean;
    function CritCheckOut: boolean;
  end;

  TBCBaseObject = class(TObJect)
  private
    FName: string;
  public
    constructor Create(Name: string);
    destructor Destroy; override;
    class function NewInstance: TObject; override;
    procedure FreeInstance; override;
    class function ObjectsActive: integer;
  end;

  TBCClassFactory = Class;

  TBCUnknown = class(TBCBaseObject, IUnKnown)
  private
    FRefCount: integer;
    FOwner   : Pointer;
  protected
    function IUnknown.QueryInterface = NonDelegatingQueryInterface;
    function IUnknown._AddRef = NonDelegatingAddRef;
    function IUnknown._Release = NonDelegatingRelease;
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
  public
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
    constructor Create(name: string; Unk: IUnknown);
    constructor CreateFromFactory(Factory: TBCClassFactory; const Controller: IUnknown); virtual;
    function NonDelegatingQueryInterface(const IID: TGUID; out Obj): HResult; virtual; stdcall;
    function NonDelegatingAddRef: Integer; virtual; stdcall;
    function NonDelegatingRelease: Integer; virtual; stdcall;
    function GetOwner: IUnKnown;
  end;

  TBCUnknownClass = Class of TBCUnknown;

{$IFDEF WITH_PROPERTY_PAGE}
  TFormPropertyPage = class;
  TFormPropertyPageClass = class of TFormPropertyPage;
{$ELSE}
  TBCBasePropertyPage = class;
  TBCBasePropertyPageClass = class of TBCBasePropertyPage;
{$ENDIF}

  TBCBaseFilter = class;
  TBCBaseFilterClass = class of TBCBaseFilter;

  TBCClassFactory = class(TObject, IUnKnown, IClassFactory)
  private
   FNext     : TBCClassFactory;
   FComClass : TBCUnknownClass;
{$IFDEF WITH_PROPERTY_PAGE}
   FPropClass: TFormPropertyPageClass;
{$ELSE}
   FPropClass: TBCBasePropertyPageClass;
{$ENDIF}
   FName     : String;
   FClassID  : TGUID;
   FCategory : TGUID;
   FMerit    : LongWord;
   FPinCount : Cardinal;
   FPins     : PRegFilterPins;
   function RegisterFilter(FilterMapper: IFilterMapper; Register: Boolean): boolean; overload;
   function RegisterFilter(FilterMapper: IFilterMapper2; Register: Boolean): boolean; overload;
   procedure UpdateRegistry(Register: Boolean); overload;
  protected
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
    function CreateInstance(const UnkOuter: IUnknown; const IID: TGUID;
      out Obj): HResult; stdcall;
    function LockServer(fLock: BOOL): HResult; stdcall;
  public
    constructor CreateFilter(ComClass: TBCUnknownClass; Name: string;
      const ClassID: TGUID; const Category: TGUID; Merit: LongWord;
      PinCount: Cardinal; Pins: PRegFilterPins);
{$IFDEF WITH_PROPERTY_PAGE}
    constructor CreatePropertyPage(ComClass: TFormPropertyPageClass; const ClassID: TGUID);
{$ELSE}
    constructor CreatePropertyPage(ComClass: TBCBasePropertyPageClass; const ClassID: TGUID);
{$ENDIF}
    property Name: String read FName;
    property ClassID: TGUID read FClassID;
  end;



  TBCFilterTemplate = class
  private
    FFactoryList : TBCClassFactory;
    procedure AddObjectFactory(Factory: TBCClassFactory);
  public
    constructor Create;
    destructor Destroy; override;
    function RegisterServer(Register: Boolean): boolean;
    function GetFactoryFromClassID(const CLSID: TGUID): TBCClassFactory;
  end;


  TBCMediaType = object
    MediaType: PAMMediaType;
    function Equal(mt: TBCMediaType): boolean; overload;
    function Equal(mt: PAMMediaType): boolean; overload;
    function MatchesPartial(Partial: PAMMediaType): boolean;
    function IsPartiallySpecified: boolean;
    function IsValid: boolean;
    procedure InitMediaType;
    function FormatLength: Cardinal;
    function Format: Pointer;
  end;


  TBCBasePin = class;

  TBCBaseFilter = class(TBCUnknown, IBaseFilter, IAMovieSetup)
  protected
    FState : TFilterState;     // current state: running, paused
    FClock : IReferenceClock;   // this graph's ref clock
    FStart : TReferenceTime;   // offset from stream time to reference time
    FCLSID : TGUID;             // This filters clsid used for serialization
    FLock  : TBCCritSec;          // Object we use for locking

    FFilterName : WideString;   // Full filter name
    FGraph : IFilterGraph;      // Graph we belong to
    FSink  : IMediaEventSink;   // Called with notify events
    FPinVersion: Integer;       // Current pin version
  public
    constructor Create(Name: string;           // Object description
                       Unk : IUnKnown;         // IUnknown of delegating object
                       Lock: TBCCritSec;       // Object who maintains lock
                       const clsid: TGUID      // The clsid to be used to serialize this filter
                       ); overload;

    constructor Create(Name: string;           // Object description
                       Unk : IUnKnown;         // IUnknown of delegating object
                       Lock: TBCCritSec;       // Object who maintains lock
                       const clsid: TGUID;     // The clsid to be used to serialize this filter
                       out hr: HRESULT         // General OLE return code
                       ); overload;
    constructor CreateFromFactory(Factory: TBCClassFactory; const Controller: IUnknown); override;
    destructor Destroy; override;
    // --- IPersist method ---
    function GetClassID(out classID: TCLSID): HResult; stdcall;
    // --- IMediaFilter methods ---
    // override Stop and Pause so we can activate the pins.
    // Note that Run will call Pause first if activation needed.
    // Override these if you want to activate your filter rather than
    // your pins.
    function Stop: HRESULT; virtual; stdcall;
    function Pause: HRESULT; virtual; stdcall;
    // the start parameter is the difference to be added to the
    // sample's stream time to get the reference time for
    // its presentation
    function Run(tStart: TReferenceTime): HRESULT; virtual; stdcall;
    function GetState(dwMilliSecsTimeout: DWORD; out State: TFilterState): HRESULT; virtual; stdcall;
    function SetSyncSource(pClock: IReferenceClock): HRESULT; stdcall;
    function GetSyncSource(out pClock: IReferenceClock): HRESULT; stdcall;
    // --- helper methods ---
    // return the current stream time - ie find out what
    // stream time should be appearing now
    function StreamTime(out rtStream: TReferenceTime): HRESULT; virtual;
    // Is the filter currently active?
    function IsActive: boolean;
    // Is this filter stopped (without locking)
    function IsStopped: boolean;
    // --- IBaseFilter methods ---
    // pin enumerator
    function EnumPins(out ppEnum: IEnumPins): HRESULT; stdcall;
    // default behaviour of FindPin assumes pin ids are their names
    function FindPin(Id: PWideChar; out Pin: IPin): HRESULT; virtual; stdcall;
    function QueryFilterInfo(out pInfo: TFilterInfo): HRESULT; stdcall;
// milenko start (added virtual to be able to override it in the renderers)
    function JoinFilterGraph(pGraph: IFilterGraph; pName: PWideChar): HRESULT; virtual; stdcall;
// milenko end    
    // return a Vendor information string. Optional - may return E_NOTIMPL.
    // memory returned should be freed using CoTaskMemFree
    // default implementation returns E_NOTIMPL
    function QueryVendorInfo(out pVendorInfo: PWideChar): HRESULT; stdcall;
    // --- helper methods ---
    // send an event notification to the filter graph if we know about it.
    // returns S_OK if delivered, S_FALSE if the filter graph does not sink
    // events, or an error otherwise.
    function NotifyEvent(EventCode, EventParam1, EventParam2: LongInt): HRESULT;
    // return the filter graph we belong to
    function GetFilterGraph: IFilterGraph;
    // Request reconnect
    // pPin is the pin to reconnect
    // pmt is the type to reconnect with - can be NULL
    // Calls ReconnectEx on the filter graph
    function ReconnectPin(Pin: IPin; pmt: PAMMediaType): HRESULT;
    // find out the current pin version (used by enumerators)
    function GetPinVersion: LongInt; virtual;
    procedure IncrementPinVersion;
    // you need to supply these to access the pins from the enumerator
    // and for default Stop and Pause/Run activation.
    function GetPinCount: integer; virtual; abstract;
    function GetPin(n: Integer): TBCBasePin; virtual; abstract;
    // --- IAMovieSetup methods ---
{nev: start 04/16/04 added "virtual"}
    function Register: HRESULT; virtual; stdcall;
    function Unregister: HRESULT; virtual; stdcall;
{nev: end}

    property State: TFilterState read FState;
    property Graph : IFilterGraph read FGraph;
  end;

 { NOTE The implementation of this class calls the CUnknown constructor with
   a NULL outer unknown pointer. This has the effect of making us a self
   contained class, ie any QueryInterface, AddRef or Release calls will be
   routed to the class's NonDelegatingUnknown methods. You will typically
   find that the classes that do this then override one or more of these
   virtual functions to provide more specialised behaviour. A good example
   of this is where a class wants to keep the QueryInterface internal but
   still wants its lifetime controlled by the external object }

  TBCBasePin = class(TBCUnknown, IPin, IQualityControl)
  protected
    FPinName: WideString;
    FConnected             : IPin;             // Pin we have connected to
    Fdir                   : TPinDirection;   // Direction of this pin
    FLock                  : TBCCritSec;       // Object we use for locking
    FRunTimeError          : boolean;          // Run time error generated
    FCanReconnectWhenActive: boolean;          // OK to reconnect when active
    FTryMyTypesFirst       : boolean;          // When connecting enumerate
                                               // this pin's types first
    FFilter                : TBCBaseFilter;    // Filter we were created by
    FQSink                 : IQualityControl;  // Target for Quality messages
    FTypeVersion           : LongInt;          // Holds current type version
    Fmt                    : TAMMediaType;   // Media type of connection

    FStart                 : TReferenceTime;  // time from NewSegment call
    FStop                  : TReferenceTime;  // time from NewSegment
    FRate                  : double;           // rate from NewSegment

    FRef                   : LongInt;
    function GetCurrentMediaType: TBCMediaType;
    function GetAMMediaType: PAMMediaType;
  protected
    procedure DisplayPinInfo(ReceivePin: IPin);
    procedure DisplayTypeInfo(Pin: IPin; pmt: PAMMediaType);

    // used to agree a media type for a pin connection
    // given a specific media type, attempt a connection (includes
    // checking that the type is acceptable to this pin)
    function AttemptConnection(
       ReceivePin: IPin;      // connect to this pin
       pmt       : PAMMediaType // using this type
       ): HRESULT;
    // try all the media types in this enumerator - for each that
    // we accept, try to connect using ReceiveConnection.
    function TryMediaTypes(
               ReceivePin: IPin;           // connect to this pin
               pmt       : PAMMediaType;     // proposed type from Connect
               Enum      : IEnumMediaTypes // try this enumerator
               ): HRESULT;

    // establish a connection with a suitable mediatype. Needs to
    // propose a media type if the pmt pointer is null or partially
    // specified - use TryMediaTypes on both our and then the other pin's
    // enumerator until we find one that works.
    function AgreeMediaType(
               ReceivePin: IPin;      // connect to this pin
               pmt       : PAMMediaType // proposed type from Connect
               ): HRESULT;
    function DisconnectInternal: HRESULT; stdcall;
  public
    function NonDelegatingAddRef: Integer; override; stdcall;
    function NonDelegatingRelease: Integer; override; stdcall;
    constructor Create(
                  ObjectName: string;           // Object description
                  Filter    : TBCBaseFilter;      // Owning filter who knows about pins
                  Lock      : TBCCritSec;         // Object who implements the lock
                  out hr    : HRESULT;          // General OLE return code
                  Name      : WideString;       // Pin name for us
                  dir       : TPinDirection);  // Either PINDIR_INPUT or PINDIR_OUTPUT
    destructor Destroy; override;
    // --- IPin methods ---
    // take lead role in establishing a connection. Media type pointer
    // may be null, or may point to partially-specified mediatype
    // (subtype or format type may be GUID_NULL).
    function Connect(pReceivePin: IPin; const pmt: PAMMediaType): HRESULT; virtual; stdcall;
    // (passive) accept a connection from another pin
    function ReceiveConnection(pConnector: IPin; const pmt: TAMMediaType): HRESULT; virtual; stdcall;
    function Disconnect: HRESULT; virtual; stdcall;
    function ConnectedTo(out pPin: IPin): HRESULT; virtual; stdcall;
    function ConnectionMediaType(out pmt: TAMMediaType): HRESULT; virtual; stdcall;
    function QueryPinInfo(out pInfo: TPinInfo): HRESULT; virtual; stdcall;
    function QueryDirection(out pPinDir: TPinDirection): HRESULT; stdcall;
    function QueryId(out Id: PWideChar): HRESULT; virtual; stdcall;
    // does the pin support this media type
    function QueryAccept(const pmt: TAMMediaType): HRESULT; virtual; stdcall;
    // return an enumerator for this pins preferred media types
    function EnumMediaTypes(out ppEnum: IEnumMediaTypes): HRESULT; virtual; stdcall;
    // return an array of IPin* - the pins that this pin internally connects to
    // All pins put in the array must be AddReffed (but no others)
    // Errors: "Can't say" - FAIL, not enough slots - return S_FALSE
    // Default: return E_NOTIMPL
    // The filter graph will interpret NOT_IMPL as any input pin connects to
    // all visible output pins and vice versa.
    // apPin can be NULL if nPin==0 (not otherwise).
    function QueryInternalConnections(out apPin: IPin; var nPin: ULONG): HRESULT; virtual; stdcall;
    // Called when no more data will be sent
    function EndOfStream: HRESULT; virtual; stdcall;
    function BeginFlush: HRESULT; virtual; stdcall; abstract;
    function EndFlush: HRESULT; virtual; stdcall; abstract;
    // Begin/EndFlush still PURE

    // NewSegment notifies of the start/stop/rate applying to the data
    // about to be received. Default implementation records data and
    // returns S_OK.
    // Override this to pass downstream.
    function NewSegment(tStart, tStop: TReferenceTime; dRate: double): HRESULT; virtual; stdcall;
    // --- IQualityControl methods ---
    function Notify(pSelf: IBaseFilter; q: TQuality): HRESULT; virtual; stdcall;
    function SetSink(piqc: IQualityControl): HRESULT; virtual; stdcall;
    // --- helper methods ---

    // Returns True if the pin is connected. false otherwise.
    function IsConnected: boolean;
    // Return the pin this is connected to (if any)
    property GetConnected: IPin read FConnected;
    // Check if our filter is currently stopped
    function IsStopped: boolean;
    // find out the current type version (used by enumerators)
    function GetMediaTypeVersion: longint; virtual;
    procedure IncrementTypeVersion;
    // switch the pin to active (paused or running) mode
    // not an error to call this if already active
    function Active: HRESULT; virtual;
    // switch the pin to inactive state - may already be inactive
    function Inactive: HRESULT; virtual;
    // Notify of Run() from filter
    function Run(Start: TReferenceTime): HRESULT; virtual;
    // check if the pin can support this specific proposed type and format
    function CheckMediaType(mt: PAMMediaType): HRESULT; virtual; abstract;
    // set the connection to use this format (previously agreed)
    function SetMediaType(mt: PAMMediaType): HRESULT; virtual;
    // check that the connection is ok before verifying it
    // can be overridden eg to check what interfaces will be supported.
    function CheckConnect(Pin: IPin): HRESULT; virtual;
    // Set and release resources required for a connection
    function BreakConnect: HRESULT; virtual;
    function CompleteConnect(ReceivePin: IPin): HRESULT; virtual;
    // returns the preferred formats for a pin
    function GetMediaType(Position: integer; out MediaType: PAMMediaType): HRESULT; virtual;
    // access to NewSegment values
    property CurrentStopTime: TReferenceTime read FStop;
    property CurrentStartTime: TReferenceTime read FStart;
    property CurrentRate: double read FRate;
    //  Access name
    property Name: WideString read FPinName;
    property CanReconnectWhenActive: boolean read FCanReconnectWhenActive write FCanReconnectWhenActive;
    // Media type
    property CurrentMediaType: TBCMediaType read GetCurrentMediaType;
    property AMMediaType: PAMMediaType read GetAMMediaType;
  end;

  TBCEnumPins = class(TInterfacedObject, IEnumPins)
  private
    FPosition: integer;   // Current ordinal position
    FPinCount: integer;   // Number of pins available
    FFilter: TBCBaseFilter; // The filter who owns us
    FVersion: LongInt;    // Pin version information
    // These pointers have not been AddRef'ed and
    // so they should not be dereferenced.  They are
    // merely kept to ID which pins have been enumerated.
    FPinCache: TList;
    { If while we are retrieving a pin for example from the filter an error
      occurs we assume that our internal state is stale with respect to the
      filter (someone may have deleted all the pins). We can check before
      starting whether or not the operation is likely to fail by asking the
      filter what it's current version number is. If the filter has not
      overriden the GetPinVersion method then this will always match }
    function AreWeOutOfSync: boolean;

    (* This method performs the same operations as Reset, except is does not clear
       the cache of pins already enumerated. *)
    function Refresh: HRESULT; stdcall;
  public
    constructor Create(Filter: TBCBaseFilter; EnumPins: TBCEnumPins);
    destructor Destroy; override;

    function Next(cPins: ULONG;  // place this many pins...
      out ppPins: IPin;          // ...in this array of IPin*
      pcFetched: PULONG          // actual count passed returned here
      ): HRESULT; stdcall;
    function Skip(cPins: ULONG): HRESULT; stdcall;
    function Reset: HRESULT; stdcall;
    function Clone(out ppEnum: IEnumPins): HRESULT; stdcall;
  end;

  TBCEnumMediaTypes = class(TInterfacedObject, IEnumMediaTypes)
  private
   FPosition: Cardinal;   // Current ordinal position
   FPin     : TBCBasePin; // The pin who owns us
   FVersion : LongInt;    // Media type version value
   function AreWeOutOfSync: boolean;
  public
    constructor Create(Pin: TBCBasePin; EnumMediaTypes: TBCEnumMediaTypes);
    destructor Destroy; override;
    function Next(cMediaTypes: ULONG; out ppMediaTypes: PAMMediaType;
      pcFetched: PULONG): HRESULT; stdcall;
    function Skip(cMediaTypes: ULONG): HRESULT; stdcall;
    function Reset: HRESULT; stdcall;
    function Clone(out ppEnum: IEnumMediaTypes): HRESULT; stdcall;
  end;


  TBCBaseOutputPin = class(TBCBasePin)
  protected
    FAllocator: IMemAllocator;
    // interface on the downstreaminput pin, set up in CheckConnect when we connect.
    FInputPin : IMemInputPin;
  public
    constructor Create(ObjectName: string; Filter: TBCBaseFilter; Lock: TBCCritSec;
      out hr: HRESULT; const Name: WideString);

    // override CompleteConnect() so we can negotiate an allocator
    function CompleteConnect(ReceivePin: IPin): HRESULT; override;
    // negotiate the allocator and its buffer size/count and other properties
    // Calls DecideBufferSize to set properties
    function DecideAllocator(Pin: IMemInputPin; out Alloc: IMemAllocator): HRESULT; virtual;
    // override this to set the buffer size and count. Return an error
    // if the size/count is not to your liking.
    // The allocator properties passed in are those requested by the
    // input pin - use eg the alignment and prefix members if you have
    // no preference on these.
    function DecideBufferSize(Alloc: IMemAllocator; propInputRequest: PAllocatorProperties): HRESULT; virtual;

    // returns an empty sample buffer from the allocator
    function GetDeliveryBuffer(out Sample: IMediaSample; StartTime: PReferenceTime;
      EndTime: PReferenceTime; Flags: Longword): HRESULT; virtual;

    // deliver a filled-in sample to the connected input pin
    // note - you need to release it after calling this. The receiving
    // pin will addref the sample if it needs to hold it beyond the
    // call.
    function Deliver(Sample: IMediaSample): HRESULT; virtual;

    // override this to control the connection
    function InitAllocator(out Alloc: IMemAllocator): HRESULT; virtual;
    function CheckConnect(Pin: IPin): HRESULT; override;
    function BreakConnect: HRESULT; override;

    // override to call Commit and Decommit
    function Active: HRESULT; override;
    function Inactive: HRESULT; override;

    // we have a default handling of EndOfStream which is to return
    // an error, since this should be called on input pins only
    function EndOfStream: HRESULT; override; stdcall;

    // called from elsewhere in our filter to pass EOS downstream to
    // our connected input pin
    function DeliverEndOfStream: HRESULT; virtual;

    // same for Begin/EndFlush - we handle Begin/EndFlush since it
    // is an error on an output pin, and we have Deliver methods to
    // call the methods on the connected pin
    function BeginFlush: HRESULT; override; stdcall;
    function EndFlush: HRESULT; override; stdcall;
    function DeliverBeginFlush: HRESULT; virtual;
    function DeliverEndFlush: HRESULT; virtual;

    // deliver NewSegment to connected pin - you will need to
    // override this if you queue any data in your output pin.
    function DeliverNewSegment(Start, Stop: TReferenceTime; Rate: double): HRESULT; virtual;
  end;

  TBCBaseInputPin = class(TBCBasePin, IMemInputPin)
  protected
    FAllocator: IMemAllocator;    // Default memory allocator
    // allocator is read-only, so received samples
    // cannot be modified (probably only relevant to in-place
    // transforms
    FReadOnly: boolean;

    //private:  this should really be private... only the MPEG code
    // currently looks at it directly and it should use IsFlushing().
    // in flushing state (between BeginFlush and EndFlush)
    // if True, all Receives are returned with S_FALSE
    FFlushing: boolean;

    // Sample properties - initalized in Receive

    FSampleProps: TAMSample2Properties;

  public

    constructor Create(ObjectName: string; Filter: TBCBaseFilter;
      Lock: TBCCritSec; out hr: HRESULT; Name: WideString);
    destructor Destroy; override;

    // ----------IMemInputPin--------------
    // return the allocator interface that this input pin
    // would like the output pin to use
    function GetAllocator(out ppAllocator: IMemAllocator): HRESULT; virtual; stdcall;
    // tell the input pin which allocator the output pin is actually
    // going to use.
    function NotifyAllocator(pAllocator: IMemAllocator; bReadOnly: BOOL): HRESULT; virtual; stdcall;
    // this method is optional (can return E_NOTIMPL).
    // default implementation returns E_NOTIMPL. Override if you have
    // specific alignment or prefix needs, but could use an upstream
    // allocator
    function GetAllocatorRequirements(out pProps: TAllocatorProperties): HRESULT; virtual; stdcall;
    // do something with this media sample
    function Receive(pSample: IMediaSample): HRESULT; virtual; stdcall;
    // do something with these media samples
    function ReceiveMultiple(pSamples: PIMediaSampleArray; nSamples: Longint;
        out nSamplesProcessed: Longint): HRESULT; virtual; stdcall;
     // See if Receive() blocks
    function ReceiveCanBlock: HRESULT; virtual; stdcall;

    //-----------Helper-------------
    // Default handling for BeginFlush - call at the beginning
    // of your implementation (makes sure that all Receive calls
    // fail). After calling this, you need to free any queued data
    // and then call downstream.
    function BeginFlush: HRESULT; override; stdcall;

    // default handling for EndFlush - call at end of your implementation
    // - before calling this, ensure that there is no queued data and no thread
    // pushing any more without a further receive, then call downstream,
    // then call this method to clear the m_bFlushing flag and re-enable
    // receives
    function EndFlush: HRESULT; override; stdcall;

    // Release the pin's allocator.
    function BreakConnect: HRESULT; override;

    // helper method to check the read-only flag
    property IsReadOnly: boolean read FReadOnly;

    // helper method to see if we are flushing
    property IsFlushing: boolean read FFlushing;

    //  Override this for checking whether it's OK to process samples
    //  Also call this from EndOfStream.
    function CheckStreaming: HRESULT; virtual;

    // Pass a Quality notification on to the appropriate sink
    function PassNotify(const q: TQuality): HRESULT;


    //================================================================================
    // IQualityControl methods (from CBasePin)
    //================================================================================

    function Notify(pSelf: IBaseFilter; q: TQuality): HRESULT; override; stdcall;

    // no need to override:
    // STDMETHODIMP SetSink(IQualityControl * piqc);

    // switch the pin to inactive state - may already be inactive
    function Inactive: HRESULT; override;

    // Return sample properties pointer
    function SampleProps: PAMSample2Properties;
  end;

// milenko start (added TBCDynamicOutputPin conversion)
  TBLOCK_STATE = (NOT_BLOCKED, PENDING, BLOCKED);

  TBCDynamicOutputPin = class(TBCBaseOutputPin, IPinFlowControl)
  public
    constructor Create(ObjectName: WideString; Filter: TBCBaseFilter;
                       Lock: TBCCritSec; out hr: HRESULT; Name: WideString);
    destructor Destroy; override;
    // IUnknown Methods
    function NonDelegatingQueryInterface(const IID: TGUID; out Obj): HResult; override;
    // IPin Methods
    function Disconnect: HRESULT; override; stdcall;
    // IPinFlowControl Methods
    function Block(dwBlockFlags: DWORD; hEvent: THandle): HResult; stdcall;
    //  Set graph config info
    procedure SetConfigInfo(GraphConfig: IGraphConfig; StopEvent: THandle);
    {$IFDEF _DEBUG}
    function Deliver(Sample: IMediaSample): HRESULT; override;
    function DeliverEndOfStream: HRESULT; override;
    function DeliverNewSegment(Start, Stop: TReferenceTime; Rate: double): HRESULT; override;
    {$ENDIF} // _DEBUG
    function DeliverBeginFlush: HRESULT; override;
    function DeliverEndFlush: HRESULT; override;
    function Active: HRESULT; override;
    function Inactive: HRESULT; override;
    function CompleteConnect(ReceivePin: IPin): HRESULT; override;
    function StartUsingOutputPin: HRESULT; virtual;
    procedure StopUsingOutputPin; virtual;
    function StreamingThreadUsingOutputPin: Boolean; virtual;
    function ChangeOutputFormat(const pmt: PAMMediaType; tSegmentStart, tSegmentStop:
                                TreferenceTime; dSegmentRate: Double): HRESULT;
    function ChangeMediaType(const pmt: PAMMEdiaType): HRESULT;
    function DynamicReconnect(const pmt: PAMMediaType): HRESULT;
  protected
    // This lock should be held when the following class members are
    // being used: m_hNotifyCallerPinBlockedEvent, m_BlockState,
    // m_dwBlockCallerThreadID and m_dwNumOutstandingOutputPinUsers.
    FBlockStateLock: TBCCritSec;
    // This event should be signaled when the output pin is
    // not blocked.  This is a manual reset event.  For more
    // information on events, see the documentation for
    // CreateEvent() in the Windows SDK.
    FUnblockOutputPinEvent: THandle;
    // This event will be signaled when block operation succeedes or
    // when the user cancels the block operation.  The block operation
    // can be canceled by calling IPinFlowControl2::Block( 0, NULL )
    // while the block operation is pending.
    FNotifyCallerPinBlockedEvent: THandle;
    // The state of the current block operation.
    FBlockState: TBLOCK_STATE;
    // The ID of the thread which last called IPinFlowControl::Block().
    // For more information on thread IDs, see the documentation for
    // GetCurrentThreadID() in the Windows SDK.
    FBlockCallerThreadID: DWORD;
    // The number of times StartUsingOutputPin() has been sucessfully
    // called and a corresponding call to StopUsingOutputPin() has not
    // been made.  When this variable is greater than 0, the streaming
    // thread is calling IPin::NewSegment(), IPin::EndOfStream(),
    // IMemInputPin::Receive() or IMemInputPin::ReceiveMultiple().  The
    // streaming thread could also be calling: DynamicReconnect(),
    // ChangeMediaType() or ChangeOutputFormat().  The output pin cannot
    // be blocked while the output pin is being used.
    FNumOutstandingOutputPinUsers: DWORD;
    // This event should be set when the IMediaFilter::Stop() is called.
    // This is a manual reset event.  It is also set when the output pin
    // delivers a flush to the connected input pin.
    FStopEvent: THandle;
    FGraphConfig: IGraphConfig;
    // TRUE if the output pin's allocator's samples are read only.
    // Otherwise FALSE.  For more information, see the documentation
    // for IMemInputPin::NotifyAllocator().
    FPinUsesReadOnlyAllocator: Boolean;
    function SynchronousBlockOutputPin: HRESULT;
    function AsynchronousBlockOutputPin(NotifyCallerPinBlockedEvent: THandle): HRESULT;
    function UnblockOutputPin: HRESULT;
    procedure BlockOutputPin;
    procedure ResetBlockState;
    class function WaitEvent(Event: THandle): HRESULT;
  private
    function Initialize: HRESULT;
    function ChangeMediaTypeHelper(const pmt: PAMMediaType): HRESULT;
    {$IFDEF _DEBUG}
    procedure AssertValid;
    {$ENDIF} // _DEBUG
  end;
// milenko end

  TBCTransformOutputPin = class;
  TBCTransformInputPin  = class;

  TBCTransformFilter = class(TBCBaseFilter)
  protected
    FEOSDelivered  : boolean; // have we sent EndOfStream
    FSampleSkipped : boolean; // Did we just skip a frame
    FQualityChanged: boolean; // Have we degraded?
    // critical section protecting filter state.
    FcsFilter: TBCCritSec;
    // critical section stopping state changes (ie Stop) while we're
    // processing a sample.
    //
    // This critical section is held when processing
    // events that occur on the receive thread - Receive() and EndOfStream().
    //
    // If you want to hold both m_csReceive and m_csFilter then grab
    // m_csFilter FIRST - like CTransformFilter::Stop() does.
    FcsReceive: TBCCritSec;
    // these hold our input and output pins
    FInput : TBCTransformInputPin;
    FOutput: TBCTransformOutputPin;
  public
    // map getpin/getpincount for base enum of pins to owner
    // override this to return more specialised pin objects

    function GetPinCount: integer; override;
    function GetPin(n: integer): TBCBasePin; override;
    function FindPin(Id: PWideChar; out ppPin: IPin): HRESULT; override; stdcall;

    // override state changes to allow derived transform filter
    // to control streaming start/stop
    function Stop: HRESULT; override; stdcall;
    function Pause: HRESULT; override; stdcall;

    constructor Create(ObjectName: string; unk: IUnKnown; const clsid: TGUID);
    constructor CreateFromFactory(Factory: TBCClassFactory; const Controller: IUnknown); override;
    destructor Destroy; override;

    // =================================================================
    // ----- override these bits ---------------------------------------
    // =================================================================

    // These must be supplied in a derived class
    function Transform(msIn, msout: IMediaSample): HRESULT; virtual;

    // check if you can support mtIn
    function CheckInputType(mtIn: PAMMediaType): HRESULT; virtual; abstract;

    // check if you can support the transform from this input to this output
    function CheckTransform(mtIn, mtOut: PAMMediaType): HRESULT; virtual; abstract;

    // this goes in the factory template table to create new instances
    // static CCOMObject * CreateInstance(LPUNKNOWN, HRESULT *);

    // call the SetProperties function with appropriate arguments
    function DecideBufferSize(Allocator: IMemAllocator; prop: PAllocatorProperties): HRESULT; virtual; abstract;

    // override to suggest OUTPUT pin media types
    function GetMediaType(Position: integer; out MediaType: PAMMediaType): HRESULT; virtual; abstract;



    // =================================================================
    // ----- Optional Override Methods           -----------------------
    // =================================================================

    // you can also override these if you want to know about streaming
    function StartStreaming: HRESULT; virtual;
    function StopStreaming: HRESULT; virtual;

    // override if you can do anything constructive with quality notifications
    function AlterQuality(const q: TQuality): HRESULT; virtual;

    // override this to know when the media type is actually set
    function SetMediaType(direction: TPinDirection; pmt: PAMMediaType): HRESULT; virtual;

    // chance to grab extra interfaces on connection
    function CheckConnect(dir: TPinDirection; Pin: IPin): HRESULT; virtual;
    function BreakConnect(dir: TPinDirection): HRESULT; virtual;
    function CompleteConnect(direction: TPinDirection; ReceivePin: IPin): HRESULT; virtual;

    // chance to customize the transform process
    function Receive(Sample: IMediaSample): HRESULT; virtual;

    // Standard setup for output sample
    function InitializeOutputSample(Sample: IMediaSample; out OutSample: IMediaSample): HRESULT; virtual;

    // if you override Receive, you may need to override these three too
    function EndOfStream: HRESULT; virtual;
    function BeginFlush: HRESULT; virtual;
    function EndFlush: HRESULT; virtual;
    function NewSegment(Start, Stop: TReferenceTime; Rate: double): HRESULT; virtual;

    property Input: TBCTransformInputPin read FInput write FInput;
    property Output: TBCTransformOutputPin read FOutPut write FOutput;

  end;

  TBCTransformInputPin = class(TBCBaseInputPin)
  private
    FTransformFilter: TBCTransformFilter;
  public
    constructor Create(ObjectName: string; TransformFilter: TBCTransformFilter;
      out hr: HRESULT; Name: WideString);

    destructor Destroy; override;
    function QueryId(out id: PWideChar): HRESULT; override; stdcall;


    // Grab and release extra interfaces if required

    function CheckConnect(Pin: IPin): HRESULT; override;
    function BreakConnect: HRESULT; override;
    function CompleteConnect(ReceivePin: IPin): HRESULT; override;

    // check that we can support this output type
    function CheckMediaType(mtIn: PAMMediaType): HRESULT; override;

    // set the connection media type
    function SetMediaType(mt: PAMMediaType): HRESULT; override;

    // --- IMemInputPin -----

    // here's the next block of data from the stream.
    // AddRef it yourself if you need to hold it beyond the end
    // of this call.
    function Receive(pSample: IMediaSample): HRESULT; override; stdcall;

    // provide EndOfStream that passes straight downstream
    // (there is no queued data)
    function EndOfStream: HRESULT; override; stdcall;

    // passes it to CTransformFilter::BeginFlush
    function BeginFlush: HRESULT; override; stdcall;

    // passes it to CTransformFilter::EndFlush
    function EndFlush: HRESULT; override; stdcall;

    function NewSegment(Start, Stop: TReferenceTime; Rate: double): HRESULT; override; stdcall;

    // Check if it's OK to process samples
    function CheckStreaming: HRESULT; override;
  end;

  TBCTransformOutputPin = class(TBCBaseOutputPin)
  protected
    FTransformFilter: TBCTransformFilter;
    // implement IMediaPosition by passing upstream
    FPosition: IUnknown;
  public
    constructor Create(ObjectName: string; TransformFilter: TBCTransformFilter;
      out hr: HRESULT; Name: WideString);
    destructor Destroy; override;
    // override to expose IMediaPosition
    function NonDelegatingQueryInterface(const IID: TGUID; out Obj): HResult; override;

    // --- TBCBaseOutputPin ------------

    function QueryId(out Id: PWideChar): HRESULT; override; stdcall;
    // Grab and release extra interfaces if required
    function CheckConnect(Pin: IPin): HRESULT; override;
    function BreakConnect: HRESULT; override;
    function CompleteConnect(ReceivePin: IPin): HRESULT; override;

    // check that we can support this output type
    function CheckMediaType(mtOut: PAMMediaType): HRESULT; override;

    // set the connection media type
    function SetMediaType(pmt: PAMMediaType): HRESULT; override;

    // called from CBaseOutputPin during connection to ask for
    // the count and size of buffers we need.
    function DecideBufferSize(Alloc: IMemAllocator; Prop: PAllocatorProperties): HRESULT; override;

    // returns the preferred formats for a pin
    function GetMediaType(Position: integer; out MediaType: PAMMediaType): HRESULT; override;

    // inherited from IQualityControl via CBasePin
    function Notify(Sendr: IBaseFilter; q: TQuality): HRESULT; override; stdcall;
  end;

// milenko start (added TBCVideoTransformFilter conversion)
  TBCVideoTransformFilter = class(TBCTransformFilter)
  public
    constructor Create(Name: WideString; Unk: IUnknown; clsid: TGUID);
    destructor Destroy; override;
    function EndFlush: HRESULT; override;

    // =================================================================
    // ----- override these bits ---------------------------------------
    // =================================================================
    // The following methods are in CTransformFilter which is inherited.
    // They are mentioned here for completeness
    //
    // These MUST be supplied in a derived class
    //
    // NOTE:
    // virtual HRESULT Transform(IMediaSample * pIn, IMediaSample *pOut);
    // virtual HRESULT CheckInputType(const CMediaType* mtIn) PURE;
    // virtual HRESULT CheckTransform
    //     (const CMediaType* mtIn, const CMediaType* mtOut) PURE;
    // static CCOMObject * CreateInstance(LPUNKNOWN, HRESULT *);
    // virtual HRESULT DecideBufferSize
    //     (IMemAllocator * pAllocator, ALLOCATOR_PROPERTIES *pprop) PURE;
    // virtual HRESULT GetMediaType(int iPosition, CMediaType *pMediaType) PURE;
    //
    // These MAY also be overridden
    //
    // virtual HRESULT StopStreaming();
    // virtual HRESULT SetMediaType(PIN_DIRECTION direction,const CMediaType *pmt);
    // virtual HRESULT CheckConnect(PIN_DIRECTION dir,IPin *pPin);
    // virtual HRESULT BreakConnect(PIN_DIRECTION dir);
    // virtual HRESULT CompleteConnect(PIN_DIRECTION direction,IPin *pReceivePin);
    // virtual HRESULT EndOfStream(void);
    // virtual HRESULT BeginFlush(void);
    // virtual HRESULT EndFlush(void);
    // virtual HRESULT NewSegment
    //     (REFERENCE_TIME tStart,REFERENCE_TIME tStop,double dRate);
  {$IFDEF PERF}
    // If you override this - ensure that you register all these ids
    // as well as any of your own,
    procedure RegisterPerfId; virtual;
  {$ENDIF}
  protected
    // =========== QUALITY MANAGEMENT IMPLEMENTATION ========================
    // Frames are assumed to come in three types:
    // Type 1: an AVI key frame or an MPEG I frame.
    //        This frame can be decoded with no history.
    //        Dropping this frame means that no further frame can be decoded
    //        until the next type 1 frame.
    //        Type 1 frames are sync points.
    // Type 2: an AVI non-key frame or an MPEG P frame.
    //        This frame cannot be decoded unless the previous type 1 frame was
    //        decoded and all type 2 frames since have been decoded.
    //        Dropping this frame means that no further frame can be decoded
    //        until the next type 1 frame.
    // Type 3: An MPEG B frame.
    //        This frame cannot be decoded unless the previous type 1 or 2 frame
    //        has been decoded AND the subsequent type 1 or 2 frame has also
    //        been decoded.  (This requires decoding the frames out of sequence).
    //        Dropping this frame affects no other frames.  This implementation
    //        does not allow for these.  All non-sync-point frames are treated
    //        as being type 2.
    //
    // The spacing of frames of type 1 in a file is not guaranteed.  There MUST
    // be a type 1 frame at (well, near) the start of the file in order to start
    // decoding at all.  After that there could be one every half second or so,
    // there could be one at the start of each scene (aka "cut", "shot") or
    // there could be no more at all.
    // If there is only a single type 1 frame then NO FRAMES CAN BE DROPPED
    // without losing all the rest of the movie.  There is no way to tell whether
    // this is the case, so we find that we are in the gambling business.
    // To try to improve the odds, we record the greatest interval between type 1s
    // that we have seen and we bet on things being no worse than this in the
    // future.

    // You can tell if it's a type 1 frame by calling IsSyncPoint().
    // there is no architected way to test for a type 3, so you should override
    // the quality management here if you have B-frames.

    FKeyFramePeriod: integer; // the largest observed interval between type 1 frames
                              // 1 means every frame is type 1, 2 means every other.

    FFramesSinceKeyFrame: integer; // Used to count frames since the last type 1.
                                   // becomes the new m_nKeyFramePeriod if greater.

    FSkipping: Boolean;           // we are skipping to the next type 1 frame

  {$IFDEF PERF}
    FidFrameType: integer;          // MSR id Frame type.  1=Key, 2="non-key"
    FidSkip: integer;               // MSR id skipping
    FidLate: integer;               // MSR id lateness
    FidTimeTillKey: integer;        // MSR id for guessed time till next key frame.
  {$ENDIF}

    FitrLate: integer;          // lateness from last Quality message
                                // (this overflows at 214 secs late).
    FtDecodeStart: integer;     // timeGetTime when decode started.
    FitrAvgDecode: integer;     // Average decode time in reference units.

    FNoSkip: Boolean;            // debug - no skipping.

    // We send an EC_QUALITY_CHANGE notification to the app if we have to degrade.
    // We send one when we start degrading, not one for every frame, this means
    // we track whether we've sent one yet.
    FQualityChanged: Boolean;

    // When non-zero, don't pass anything to renderer until next keyframe
    // If there are few keys, give up and eventually draw something
    FWaitForKey: integer;

    function AbortPlayback(hr: HRESULT): HRESULT;  // if something bad happens
    function ShouldSkipFrame(pIn: IMediaSample): Boolean;
  public
    function StartStreaming: HRESULT; override;
    function Receive(Sample: IMediaSample): HRESULT; override;
    function AlterQuality(const q: TQuality): HRESULT; override;
  end;
// milenko end

  TBCTransInPlaceOutputPin = class;
  TBCTransInPlaceInputPin  = class;

  TBCTransInPlaceFilter = class(TBCTransformFilter)
  public
    // map getpin/getpincount for base enum of pins to owner
    // override this to return more specialised pin objects
    function GetPin(n: integer): TBCBasePin; override;

    //  Set bModifiesData == false if your derived filter does
    //  not modify the data samples (for instance it's just copying
    //  them somewhere else or looking at the timestamps).
    constructor Create(ObjectName: string; unk: IUnKnown; clsid: TGUID;
      out hr: HRESULT; ModifiesData: boolean = True);

    constructor CreateFromFactory(Factory: TBCClassFactory; const Controller: IUnknown); override;

    // The following are defined to avoid undefined pure virtuals.
    // Even if they are never called, they will give linkage warnings/errors

    // We override EnumMediaTypes to bypass the transform class enumerator
    // which would otherwise call this.
    function GetMediaType(Position: integer; out MediaType: PAMMediaType): HRESULT; override;

    // This is called when we actually have to provide out own allocator.
    function DecideBufferSize(Alloc: IMemAllocator; propInputRequest: PAllocatorProperties): HRESULT; override;

    // The functions which call this in CTransform are overridden in this
    // class to call CheckInputType with the assumption that the type
    // does not change.  In Debug builds some calls will be made and
    // we just ensure that they do not assert.
    function CheckTransform(mtIn, mtOut: PAMMediaType): HRESULT; override;

    // =================================================================
    // ----- You may want to override this -----------------------------
    // =================================================================

    function CompleteConnect(dir: TPinDirection; ReceivePin: IPin): HRESULT; override;

    // chance to customize the transform process
    function Receive(Sample: IMediaSample): HRESULT; override;

    // =================================================================
    // ----- You MUST override these -----------------------------------
    // =================================================================

    function Transform(Sample: IMediaSample): HRESULT; reintroduce; virtual; abstract;

    // this goes in the factory template table to create new instances
    // static CCOMObject * CreateInstance(LPUNKNOWN, HRESULT *);

  protected
    FModifiesData: boolean; // Does this filter change the data?
    function Copy(Source: IMediaSample): IMediaSample;

    // these hold our input and output pins
    function InputPin: TBCTransInPlaceInputPin;
    function OutputPin: TBCTransInPlaceOutputPin;

    //  Helper to see if the input and output types match
    function TypesMatch: boolean;

    //  Are the input and output allocators different?
    function UsingDifferentAllocators: boolean;
  end;

  TBCTransInPlaceInputPin = class(TBCTransformInputPin)
  protected
    FTIPFilter: TBCTransInPlaceFilter; // our filter
    FReadOnly : boolean;               // incoming stream is read only
  public
    constructor Create(ObjectName: string; Filter: TBCTransInPlaceFilter;
      out hr: HRESULT; Name: WideString);
    // --- IMemInputPin -----
    // Provide an enumerator for media types by getting one from downstream
    function EnumMediaTypes(out ppEnum: IEnumMediaTypes): HRESULT; override; stdcall;

    // Say whether media type is acceptable.
    function CheckMediaType(pmt: PAMMediaType): HRESULT; override;

    // Return our upstream allocator
    function GetAllocator(out Allocator: IMemAllocator): HRESULT; override; stdcall;

    // get told which allocator the upstream output pin is actually
    // going to use.
    function NotifyAllocator(Allocator: IMemAllocator; ReadOnly: BOOL): HRESULT; override; stdcall;

    // Allow the filter to see what allocator we have
    // N.B. This does NOT AddRef
    function PeekAllocator: IMemAllocator;

    // Pass this on downstream if it ever gets called.
    function GetAllocatorRequirements(out props: TAllocatorProperties): HRESULT; override; stdcall;

    property ReadOnly: Boolean read FReadOnly;
  end;


// ==================================================
// Implements the output pin
// ==================================================

  TBCTransInPlaceOutputPin = class(TBCTransformOutputPin)
  protected
    // m_pFilter points to our CBaseFilter
    FTIPFilter: TBCTransInPlaceFilter;
  public
    constructor Create(ObjectName: string; Filter: TBCTransInPlaceFilter;
      out hr: HRESULT; Name: WideString);

    // --- CBaseOutputPin ------------

    // negotiate the allocator and its buffer size/count
    // Insists on using our own allocator.  (Actually the one upstream of us).
    // We don't override this - instead we just agree the default
    // then let the upstream filter decide for itself on reconnect
    // virtual HRESULT DecideAllocator(IMemInputPin * pPin, IMemAllocator ** pAlloc);

    // Provide a media type enumerator.  Get it from upstream.
    function EnumMediaTypes(out ppEnum: IEnumMediaTypes): HRESULT; override; stdcall;

    // Say whether media type is acceptable.
    function CheckMediaType(pmt: PAMMediaType): HRESULT; override;

    //  This just saves the allocator being used on the output pin
    //  Also called by input pin's GetAllocator()
    procedure SetAllocator(Allocator: IMemAllocator);

    function ConnectedIMemInputPin: IMemInputPin;

    // Allow the filter to see what allocator we have
    // N.B. This does NOT AddRef
    function PeekAllocator: IMemAllocator;
  end;


{$IFDEF WITH_PROPERTY_PAGE}
  TBCBasePropertyPage = class(TBCUnknown, IPropertyPage)
  private
    FObjectSet: boolean;          // SetObject has been called or not.
  protected
    FPageSite: IPropertyPageSite; // Details for our property site
    FDirty: boolean;              // Has anything been changed
    FForm: TFormPropertyPage;
  public
    constructor Create(Name: String; Unk: IUnKnown; Form: TFormPropertyPage);
    destructor  Destroy; override;
    procedure SetPageDirty;

    { IPropertyPage }
    function SetPageSite(const pageSite: IPropertyPageSite): HResult; stdcall;
    function Activate(hwndParent: HWnd; const rc: TRect; bModal: BOOL): HResult; stdcall;
    function Deactivate: HResult; stdcall;
    function GetPageInfo(out pageInfo: TPropPageInfo): HResult; stdcall;
    function SetObjects(cObjects: Longint; pUnkList: PUnknownList): HResult; stdcall;
    function Show(nCmdShow: Integer): HResult; stdcall;
    function Move(const rect: TRect): HResult; stdcall;
    function IsPageDirty: HResult; stdcall;
    function Apply: HResult; stdcall;
    function Help(pszHelpDir: POleStr): HResult; stdcall;
    function TranslateAccelerator(msg: PMsg): HResult; stdcall;
  end;

  TOnConnect = procedure(sender: Tobject; Unknown: IUnknown) of object;

  TFormPropertyPage = class(TForm, IUnKnown, IPropertyPage)
  private
    FPropertyPage: TBCBasePropertyPage;
    procedure MyWndProc(var aMsg: TMessage);
  public
    constructor Create(AOwner: TComponent); override;
  published
    function OnConnect(Unknown: IUnknown): HRESULT; virtual;
    function OnDisconnect: HRESULT; virtual;
    function OnApplyChanges: HRESULT; virtual;
    property PropertyPage   : TBCBasePropertyPage read FPropertyPage implements IUnKnown, IPropertyPage;
  end;
{$ELSE}
  TBCBasePropertyPage = class(TBCUnknown, IPropertyPage)
  private
    FObjectSet: Boolean;         // SetObject has been called or not.
  protected
    FPageSite: IPropertyPageSite; // Details for our property site
    FWindow: THandle;                // Window handle for the page
    FDialog: THandle;                 // Actual dialog window handle
    FDirty: Boolean;              // Has anything been changed
    FTitle: WideString;             // Resource identifier for title
    FDialogID: Integer;            // Dialog resource identifier
  public
    constructor Create(Name: WideString; pUnk: IUnknown; DialogID: Integer; Title: WideString);
    destructor Destroy; override;
    function NonDelegatingQueryInterface(const IID: TGUID; out Obj): HResult; override; stdcall;
    function NonDelegatingAddRef: Integer; override; stdcall;
    function NonDelegatingRelease: Integer; override; stdcall;

    procedure SetPageDirty;

    // override these
    function OnConnect(pUnknown: IUnknown): HRESULT; virtual;
    function OnDisconnect: HRESULT; virtual;
    function OnActivate: HRESULT; virtual;
    function OnDeactivate: HRESULT; virtual;
    function OnApplyChanges: HRESULT; virtual;
    function OnReceiveMessage(hwndDlg: Thandle; uMsg: Cardinal; wParam: WPARAM; lParam: LPARAM): Integer; virtual;
    // IPropertyPage
    function SetPageSite(const pageSite: IPropertyPageSite): HResult; stdcall;
    function Activate(hwndParent: HWnd; const rc: TRect; bModal: BOOL): HResult; stdcall;
    function Deactivate: HResult; stdcall;
    function GetPageInfo(out pageInfo: TPropPageInfo): HResult; stdcall;
    function SetObjects(cObjects: Longint; pUnkList: PUnknownList): HResult; stdcall;
    function Show(nCmdShow: Integer): HResult; stdcall;
    function Move(const rect: TRect): HResult; stdcall;
    function IsPageDirty: HResult; stdcall;
    function Apply: HResult; stdcall;
    function Help(pszHelpDir: POleStr): HResult; stdcall;
    function TranslateAccelerator(msg: PMsg): HResult; stdcall;
  end;
{$ENDIF}

  TBCBaseDispatch = class{IDispatch}
  protected
    FTI: ITypeInfo;
  public
    // IDispatch methods
    function GetTypeInfoCount(out Count: Integer): HResult; stdcall;
    function GetTypeInfo(const iid: TGUID; info: Cardinal; lcid: LCID; out tinfo): HRESULT; stdcall;
    function GetIDsOfNames(const IID: TGUID; Names: Pointer;
      NameCount, LocaleID: Integer; DispIDs: Pointer): HResult; stdcall;
  end;

  TBCMediaControl = class(TBCUnknown, IDispatch)
  public
    FBaseDisp: TBCBaseDispatch;
    constructor Create(name: string; unk: IUnknown);
    destructor Destroy; override;

    // IDispatch methods
    function GetTypeInfoCount(out Count: Integer): HResult; stdcall;
    function GetTypeInfo(Index, LocaleID: Integer; out TypeInfo): HResult; stdcall;
    function GetIDsOfNames(const IID: TGUID; Names: Pointer;
      NameCount, LocaleID: Integer; DispIDs: Pointer): HResult; stdcall;
    function Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer;
      Flags: Word; var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult; stdcall;
  end;

  TBCMediaEvent = class(TBCUnknown, IDisPatch{,IMediaEventEx})
  protected
    FBasedisp: TBCBaseDispatch;
  public
    constructor Create(Name: string; Unk: IUnknown);
    destructor Destroy; override;
    // IDispatch methods
    function GetTypeInfoCount(out Count: Integer): HResult; stdcall;
    function GetTypeInfo(Index, LocaleID: Integer; out TypeInfo): HResult; stdcall;
    function GetIDsOfNames(const IID: TGUID; Names: Pointer;
      NameCount, LocaleID: Integer; DispIDs: Pointer): HResult; stdcall;
    function Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer;
      Flags: Word; var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult; stdcall;
  end;

  TBCMediaPosition = class(TBCUnknown, IDispatch {IMediaPosition})
  protected
    FBaseDisp: TBCBaseDispatch;
  public
    constructor Create(Name: String; Unk: IUnknown); overload;
    constructor Create(Name: String; Unk: IUnknown; out hr: HRESULT); overload;
    destructor Destroy; override;
    // IDispatch methods
    function GetTypeInfoCount(out Count: Integer): HResult; stdcall;
    function GetTypeInfo(Index, LocaleID: Integer; out TypeInfo): HResult; stdcall;
    function GetIDsOfNames(const IID: TGUID; Names: Pointer;
      NameCount, LocaleID: Integer; DispIDs: Pointer): HResult; stdcall;
    function Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer;
      Flags: Word; var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult; stdcall;
  end;


// A utility class that handles IMediaPosition and IMediaSeeking on behalf
// of single-input pin renderers, or transform filters.
//
// Renderers will expose this from the filter; transform filters will
// expose it from the output pin and not the renderer.
//
// Create one of these, giving it your IPin* for your input pin, and delegate
// all IMediaPosition methods to it. It will query the input pin for
// IMediaPosition and respond appropriately.
//
// Call ForceRefresh if the pin connection changes.
//
// This class no longer caches the upstream IMediaPosition or IMediaSeeking
// it acquires it on each method call. This means ForceRefresh is not needed.
// The method is kept for source compatibility and to minimise the changes
// if we need to put it back later for performance reasons.

  TBCPosPassThru = class(TBCMediaPosition, IMediaSeeking)
  protected
    FPin: IPin;
    function GetPeer(out MP: IMediaPosition): HRESULT;
    function GetPeerSeeking(out MS: IMediaSeeking): HRESULT;
  public

    constructor Create(name: String; Unk: IUnknown; out hr: HRESULT; Pin: IPin);
    function ForceRefresh: HRESULT;{return S_OK;}

    // override to return an accurate current position
    function GetMediaTime(out StartTime, EndTime: int64): HRESULT; virtual;

    // IMediaSeeking methods
    function GetCapabilities(out pCapabilities: DWORD): HRESULT; virtual; stdcall;
    function CheckCapabilities(var pCapabilities: DWORD): HRESULT; virtual; stdcall;
    function IsFormatSupported(const pFormat: TGUID): HRESULT; virtual; stdcall;
    function QueryPreferredFormat(out pFormat: TGUID): HRESULT; virtual; stdcall;
    function GetTimeFormat(out pFormat: TGUID): HRESULT; virtual; stdcall;
    function IsUsingTimeFormat(const pFormat: TGUID): HRESULT; virtual; stdcall;
    function SetTimeFormat(const pFormat: TGUID): HRESULT; virtual; stdcall;
    function GetDuration(out pDuration: int64): HRESULT; virtual; stdcall;
    function GetStopPosition(out pStop: int64): HRESULT; virtual; stdcall;
    function GetCurrentPosition(out pCurrent: int64): HRESULT; virtual; stdcall;
    function ConvertTimeFormat(out pTarget: int64; pTargetFormat: PGUID;
               Source: int64; pSourceFormat: PGUID): HRESULT; virtual; stdcall;
    function SetPositions(var pCurrent: int64; dwCurrentFlags: DWORD;
               var pStop: int64; dwStopFlags: DWORD): HRESULT; virtual; stdcall;
    function GetPositions(out pCurrent, pStop: int64): HRESULT; virtual; stdcall;
    function GetAvailable(out pEarliest, pLatest: int64): HRESULT; virtual; stdcall;
    function SetRate(dRate: double): HRESULT; virtual; stdcall;
    function GetRate(out pdRate: double): HRESULT; virtual; stdcall;
    function GetPreroll(out pllPreroll: int64): HRESULT; virtual; stdcall;

    // IMediaPosition properties
    function get_Duration(out plength: TRefTime): HResult; virtual; stdcall;
    function put_CurrentPosition(llTime: TRefTime): HResult; virtual; stdcall;
    function get_CurrentPosition(out pllTime: TRefTime): HResult; virtual; stdcall;
    function get_StopTime(out pllTime: TRefTime): HResult; virtual; stdcall;
    function put_StopTime(llTime: TRefTime): HResult; virtual; stdcall;
    function get_PrerollTime(out pllTime: TRefTime): HResult; virtual; stdcall;
    function put_PrerollTime(llTime: TRefTime): HResult; virtual; stdcall;
    function put_Rate(dRate: double): HResult; virtual; stdcall;
    function get_Rate(out pdRate: double): HResult; virtual; stdcall;
    function CanSeekForward(out pCanSeekForward: Longint): HResult; virtual; stdcall;
    function CanSeekBackward(out pCanSeekBackward: Longint): HResult; virtual; stdcall;
  end;

  TBCRendererPosPassThru = class(TBCPosPassThru)
  protected
    FPositionLock: TBCCritSec; // Locks access to our position
    FStartMedia  : Int64;      // Start media time last seen
    FEndMedia    : Int64;      // And likewise the end media
    FReset       : boolean;    // Have media times been set
  public
    // Used to help with passing media times through graph
    constructor Create(name: String; Unk: IUnknown; out hr: HRESULT; Pin: IPin); reintroduce;
    destructor Destroy; override;

    function RegisterMediaTime(MediaSample: IMediaSample): HRESULT; overload;
    function RegisterMediaTime(StartTime, EndTime: int64): HRESULT; overload;
    function GetMediaTime(out StartTime, EndTime: int64): HRESULT; override;
    function ResetMediaTime: HRESULT;
    function EOS: HRESULT;
  end;

  // wrapper for event objects
  TBCAMEvent = class
  protected
    FEvent: THANDLE;
  public
    constructor Create(ManualReset: boolean = false);
    destructor Destroy; override;
    property Handle: THandle read FEvent;
    procedure SetEv;
    function Wait(Timeout: Cardinal = INFINITE): boolean;
    procedure Reset;
    function Check: boolean;
  end;

  TBCTimeoutEvent = TBCAMEvent;

  // wrapper for event objects that do message processing
  // This adds ONE method to the CAMEvent object to allow sent
  // messages to be processed while waiting
  TBCAMMsgEvent = class(TBCAMEvent)
  public
    // Allow SEND messages to be processed while waiting
    function WaitMsg(Timeout: DWord = INFINITE): boolean;
  end;

  // support for a worker thread
  // simple thread class supports creation of worker thread, synchronization
  // and communication. Can be derived to simplify parameter passing
  TThreadProc = function: DWORD of object;

  TBCAMThread = class
  private
    FEventSend: TBCAMEvent;
    FEventComplete: TBCAMEvent;
    FParam: DWord;
    FReturnVal: DWord;
    FThreadProc: TThreadProc;
  protected
    FThread: THandle;

    // thread will run this function on startup
    // must be supplied by derived class
    function ThreadProc: DWord; virtual;
  public
    FAccessLock: TBCCritSec; // locks access by client threads
    FWorkerLock: TBCCritSec; // locks access to shared objects
    constructor Create;
    destructor Destroy; override;

    // start thread running  - error if already running
    function Create_: boolean;

    // signal the thread, and block for a response
    //
    function CallWorker(Param: DWORD): DWORD;

    // accessor thread calls this when done with thread (having told thread
    // to exit)
    procedure Close;

    // ThreadExists
    // Return True if the thread exists. FALSE otherwise
    function ThreadExists: boolean; // const

    // wait for the next request
    function GetRequest: DWORD;

    // is there a request?
    function CheckRequest(Param: PDWORD): boolean;

    // reply to the request
    procedure Reply(v: DWORD);

    // If you want to do WaitForMultipleObjects you'll need to include
    // this handle in your wait list or you won't be responsive
    function GetRequestHandle: THANDLE;

    // Find out what the request was
    function GetRequestParam: DWORD;

    // call CoInitializeEx (COINIT_DISABLE_OLE1DDE) if
    // available. S_FALSE means it's not available.
    class function CoInitializeHelper: HRESULT;
  end;



  TBCRenderedInputPin = class(TBCBaseInputPin)
  private
    procedure DoCompleteHandling;
  protected
    // Member variables to track state
    FAtEndOfStream    : boolean; // Set by EndOfStream
    FCompleteNotified : boolean; // Set when we notify for EC_COMPLETE
  public
    constructor Create(ObjectName: string; Filter: TBCBaseFilter;
      Lock: TBCCritSec; out hr: HRESULT; Name: WideString);

    // Override methods to track end of stream state
    function EndOfStream: HRESULT; override; stdcall;
    function EndFlush: HRESULT; override; stdcall;

    function Active: HRESULT; override;
    function Run(Start: TReferenceTime): HRESULT; override;
  end;


(* A generic list of pointers to objects.
   No storage management or copying is done on the objects pointed to.
   Objectives: avoid using MFC libraries in ndm kernel mode and
   provide a really useful list type.

   The class is thread safe in that separate threads may add and
   delete items in the list concurrently although the application
   must ensure that constructor and destructor access is suitably
   synchronised. An application can cause deadlock with operations
   which use two lists by simultaneously calling
   list1->Operation(list2) and list2->Operation(list1).  So don't!

   The names must not conflict with MFC classes as an application
   may use both.
   *)


   (* A POSITION represents (in some fashion that's opaque) a cursor
      on the list that can be set to identify any element.  NULL is
      a valid value and several operations regard NULL as the position
      "one step off the end of the list".  (In an n element list there
      are n+1 places to insert and NULL is that "n+1-th" value).
      The POSITION of an element in the list is only invalidated if
      that element is deleted.  Move operations may mean that what
      was a valid POSITION in one list is now a valid POSITION in
      a different list.

      Some operations which at first sight are illegal are allowed as
      harmless no-ops.  For instance RemoveHead is legal on an empty
      list and it returns NULL.  This allows an atomic way to test if
      there is an element there, and if so, get it.  The two operations
      AddTail and RemoveHead thus implement a MONITOR (See Hoare's paper).

      Single element operations return POSITIONs, non-NULL means it worked.
      whole list operations return a BOOL.  True means it all worked.

      This definition is the same as the POSITION type for MFCs, so we must
      avoid defining it twice.
   *)


  Position = Pointer;

{$ifdef _DEBUG}
  TBCNode = class(TBCBaseObject)
{$else}
  TBCNode = class
{$endif}
  private
    FPrev: TBCNode;    // Previous node in the list
    FNext: TBCNode;    // Next node in the list
    FObject: Pointer;  // Pointer to the object
  public
    // Constructor - initialise the object's pointers
{$ifdef _DEBUG}
    constructor Create;
{$endif}
    // Return the previous node before this one
    property Prev: TBCNode read FPrev write FPrev;
    // Return the next node after this one
    property Next: TBCNode read FNext write FNext;
    // Get the pointer to the object for this node */
    property Data: Pointer read FObject write FObject;
  end;

  TBCNodeCache = class
  private
    FCacheSize: Integer;
    FUsed: Integer;
    FHead: TBCNode;
  public
    constructor Create(CacheSize: Integer);
    destructor Destroy; override;
    procedure AddToCache(Node: TBCNode);
    function RemoveFromCache: TBCNode;
  end;



(* A class representing one node in a list.
   Each node knows a pointer to it's adjacent nodes and also a pointer
   to the object that it looks after.
   All of these pointers can be retrieved or set through member functions.
*)
  TBCBaseList = class
{$ifdef _DEBUG}
    (TBCBaseObject)
{$endif}
    (* Making these classes inherit from CBaseObject does nothing
       functionally but it allows us to check there are no memory
       leaks in debug builds.
    *)
  protected
    FFirst: TBCNode; // Pointer to first node in the list
    FLast: TBCNode; // Pointer to the last node in the list
    FCount: LongInt;   // Number of nodes currently in the list
  private
    FCache: TBCNodeCache; // Cache of unused node pointers
  public
    constructor Create(Name: string; Items: Integer = DEFAULTCACHE);
    destructor Destroy; override;
    // Remove all the nodes from self i.e. make the list empty
    procedure RemoveAll;
    // Return a cursor which identifies the first element of self
    function GetHeadPositionI: Position;
    /// Return a cursor which identifies the last element of self
    function GetTailPositionI: Position;
    // Return the number of objects in self
    function GetCountI: Integer;
  protected
    (* Return the pointer to the object at rp,
       Update rp to the next node in self
       but make it nil if it was at the end of self.
       This is a wart retained for backwards compatibility.
       GetPrev is not implemented.
       Use Next, Prev and Get separately.
    *)
    function GetNextI(var rp: Position): Pointer;
    (* Return a pointer to the object at p
       Asking for the object at nil will return nil harmlessly.
    *)
    function GetI(p: Position): Pointer;
  public
    (* return the next / prev position in self
       return NULL when going past the end/start.
       Next(nil) is same as GetHeadPosition()
       Prev(nil) is same as GetTailPosition()
       An n element list therefore behaves like a n+1 element
       cycle with nil at the start/end.

       !!WARNING!! - This handling of nil is DIFFERENT from GetNext.

       Some reasons are:
       1. For a list of n items there are n+1 positions to insert
          These are conveniently encoded as the n POSITIONs and nil.
       2. If you are keeping a list sorted (fairly common) and you
          search forward for an element to insert before and don't
          find it you finish up with nil as the element before which
          to insert.  You then want that nil to be a valid POSITION
          so that you can insert before it and you want that insertion
          point to mean the (n+1)-th one that doesn't have a POSITION.
          (symmetrically if you are working backwards through the list).
       3. It simplifies the algebra which the methods generate.
          e.g. AddBefore(p,x) is identical to AddAfter(Prev(p),x)
          in ALL cases.  All the other arguments probably are reflections
          of the algebraic point.
    *)
    function Next(pos: Position): Position;
    function Prev(pos: Position): Position;

    (* Return the first position in self which holds the given
       pointer.  Return nil if the pointer was not not found.
    *)
  protected
    function FindI(Obj: Pointer): Position;

    (* Remove the first node in self (deletes the pointer to its
       object from the list, does not free the object itself).
       Return the pointer to its object.
       If self was already empty it will harmlessly return nil.
    *)
    function RemoveHeadI: Pointer;

    (* Remove the last node in self (deletes the pointer to its
       object from the list, does not free the object itself).
       Return the pointer to its object.
       If self was already empty it will harmlessly return nil.
    *)
    function RemoveTailI: Pointer;

    (* Remove the node identified by p from the list (deletes the pointer
       to its object from the list, does not free the object itself).
       Asking to Remove the object at nil will harmlessly return nil.
       Return the pointer to the object removed.
    *)
    function RemoveI(pos: Position): Pointer;

    (* Add single object *pObj to become a new last element of the list.
       Return the new tail position, nil if it fails.
       If you are adding a COM objects, you might want AddRef it first.
       Other existing POSITIONs in self are still valid
    *)
    function AddTailI(Obj: Pointer): Position;
  public
    (* Add all the elements in *pList to the tail of self.
       This duplicates all the nodes in *pList (i.e. duplicates
       all its pointers to objects).  It does not duplicate the objects.
       If you are adding a list of pointers to a COM object into the list
       it's a good idea to AddRef them all  it when you AddTail it.
       Return True if it all worked, FALSE if it didn't.
       If it fails some elements may have been added.
       Existing POSITIONs in self are still valid

       If you actually want to MOVE the elements, use MoveToTail instead.
    *)
    function AddTail(List: TBCBaseList): boolean;

    // Mirror images of AddHead:

    (* Add single object to become a new first element of the list.
       Return the new head position, nil if it fails.
       Existing POSITIONs in self are still valid
    *)
  protected
    function AddHeadI(Obj: Pointer): Position;
  public
    (* Add all the elements in *pList to the head of self.
       Same warnings apply as for AddTail.
       Return True if it all worked, FALSE if it didn't.
       If it fails some of the objects may have been added.

       If you actually want to MOVE the elements, use MoveToHead instead.
    *)
    function AddHead(List: TBCBaseList): BOOL;

    (* Add the object *pObj to self after position p in self.
       AddAfter(nil,x) adds x to the start - equivalent to AddHead
       Return the position of the object added, nil if it failed.
       Existing POSITIONs in self are undisturbed, including p.
    *)
  protected
    function AddAfterI(pos: Position; Obj: Pointer): Position;
  public

    (* Add the list *pList to self after position p in self
       AddAfter(nil,x) adds x to the start - equivalent to AddHead
       Return True if it all worked, FALSE if it didn't.
       If it fails, some of the objects may be added
       Existing POSITIONs in self are undisturbed, including p.
    *)
    function AddAfter(p: Position; List: TBCBaseList): BOOL;

    (* Mirror images:
       Add the object *pObj to this-List after position p in self.
       AddBefore(nil,x) adds x to the end - equivalent to AddTail
       Return the position of the new object, nil if it fails
       Existing POSITIONs in self are undisturbed, including p.
    *)
  protected
    function AddBeforeI(pos: Position; Obj: Pointer): Position;
  public
    (* Add the list *pList to self before position p in self
       AddAfter(nil,x) adds x to the start - equivalent to AddHead
       Return True if it all worked, FALSE if it didn't.
       If it fails, some of the objects may be added
       Existing POSITIONs in self are undisturbed, including p.
    *)
    function AddBefore(p: Position; List: TBCBaseList): BOOL;

    (* Note that AddAfter(p,x) is equivalent to AddBefore(Next(p),x)
       even in cases where p is nil or Next(p) is nil.
       Similarly for mirror images etc.
       This may make it easier to argue about programs.
    *)

    (* The following operations do not copy any elements.
       They move existing blocks of elements around by switching pointers.
       They are fairly efficient for long lists as for short lists.
       (Alas, the Count slows things down).

       They split the list into two parts.
       One part remains as the original list, the other part
       is appended to the second list.  There are eight possible
       variations:
       Split the list {after/before} a given element
       keep the {head/tail} portion in the original list
       append the rest to the {head/tail} of the new list.

       Since After is strictly equivalent to Before Next
       we are not in serious need of the Before/After variants.
       That leaves only four.

       If you are processing a list left to right and dumping
       the bits that you have processed into another list as
       you go, the Tail/Tail variant gives the most natural result.
       If you are processing in reverse order, Head/Head is best.

       By using nil positions and empty lists judiciously either
       of the other two can be built up in two operations.

       The definition of nil (see Next/Prev etc) means that
       degenerate cases include
          "move all elements to new list"
          "Split a list into two lists"
          "Concatenate two lists"
          (and quite a few no-ops)

       !!WARNING!! The type checking won't buy you much if you get list
       positions muddled up - e.g. use a POSITION that's in a different
       list and see what a mess you get!
    *)

    (* Split self after position p in self
       Retain as self the tail portion of the original self
       Add the head portion to the tail end of *pList
       Return True if it all worked, FALSE if it didn't.

       e.g.
          foo->MoveToTail(foo->GetHeadPosition(), bar);
              moves one element from the head of foo to the tail of bar
          foo->MoveToTail(nil, bar);
              is a no-op, returns nil
          foo->MoveToTail(foo->GetTailPosition, bar);
              concatenates foo onto the end of bar and empties foo.

       A better, except excessively long name might be
           MoveElementsFromHeadThroughPositionToOtherTail
    *)
    function MoveToTail(pos: Position; List: TBCBaseList): boolean;

    (* Mirror image:
       Split self before position p in self.
       Retain in self the head portion of the original self
       Add the tail portion to the start (i.e. head) of *pList

       e.g.
          foo->MoveToHead(foo->GetTailPosition(), bar);
              moves one element from the tail of foo to the head of bar
          foo->MoveToHead(nil, bar);
              is a no-op, returns nil
          foo->MoveToHead(foo->GetHeadPosition, bar);
              concatenates foo onto the start of bar and empties foo.
    *)
    function MoveToHead(pos: Position; List: TBCBaseList): boolean;

    (* Reverse the order of the [pointers to] objects in self *)
    procedure Reverse;
  end;

// Desc: DirectShow base classes - defines classes to simplify creation of
//       ActiveX source filters that support continuous generation of data.
//       No support is provided for IMediaControl or IMediaPosition.
//
// Derive your source filter from CSource.
// During construction either:
//    Create some CSourceStream objects to manage your pins
//    Provide the user with a means of doing so eg, an IPersistFile interface.
//
// CSource provides:
//    IBaseFilter interface management
//    IMediaFilter interface management, via CBaseFilter
//    Pin counting for CBaseFilter
//
// Derive a class from CSourceStream to manage your output pin types
//  Implement GetMediaType/1 to return the type you support. If you support multiple
//   types then overide GetMediaType/3, CheckMediaType and GetMediaTypeCount.
//  Implement Fillbuffer() to put data into one buffer.
//
// CSourceStream provides:
//    IPin management via CBaseOutputPin
//    Worker thread management

// Override construction to provide a means of creating
// CSourceStream derived objects - ie a way of creating pins.

  TBCSourceStream = class;
  TStreamArray = array of TBCSourceStream;

  TBCSource = class(TBCBaseFilter)
  protected
    FPins: Integer;  // The number of pins on this filter. Updated by CSourceStream
    FStreams: Pointer; // the pins on this filter.
    FStateLock: TBCCritSec;
  public
    constructor Create(const Name: string; unk: IUnknown; const clsid: TGUID; out hr: HRESULT); overload;
    constructor Create(const Name: string; unk: IUnknown; const clsid: TGUID); overload;
    destructor Destroy; override;

    function GetPinCount: Integer; override;
    function GetPin(n: Integer): TBCBasePin; override;

    // -- Utilities --

    property StateLock: TBCCritSec read FStateLock; // provide our critical section
    function AddPin(Stream: TBCSourceStream): HRESULT;
    function RemovePin(Stream: TBCSourceStream): HRESULT;
    function FindPin(Id: PWideChar; out Pin: IPin): HRESULT; override;
    function FindPinNumber(Pin: IPin): Integer;
  end;


//
// CSourceStream
//
// Use this class to manage a stream of data that comes from a
// pin.
// Uses a worker thread to put data on the pin.

  TThreadCommand = (
    CMD_INIT,
    CMD_PAUSE,
    CMD_RUN,
    CMD_STOP,
    CMD_EXIT
  );

  TBCSourceStream = class(TBCBaseOutputPin)
  public
    constructor Create(const ObjectName: string; out hr: HRESULT;
      Filter: TBCSource; const Name: WideString);
    destructor Destroy; override;
  protected
    FThread: TBCAMThread;
    FFilter: TBCSource;	// The parent of this stream


    // *
    // * Data Source
    // *
    // * The following three functions: FillBuffer, OnThreadCreate/Destroy, are
    // * called from within the ThreadProc. They are used in the creation of
    // * the media samples this pin will provide
    // *

    // Override this to provide the worker thread a means
    // of processing a buffer
    function FillBuffer(Samp: IMediaSample): HRESULT; virtual; abstract;

    // Called as the thread is created/destroyed - use to perform
    // jobs such as start/stop streaming mode
    // If OnThreadCreate returns an error the thread will exit.
    function OnThreadCreate: HRESULT; virtual;
    function OnThreadDestroy: HRESULT; virtual;
    function OnThreadStartPlay: HRESULT; virtual;


  public
    // *
    // * Worker Thread
    // *

    function Active: HRESULT; override;    // Starts up the worker thread
    function Inactive: HRESULT; override;  // Exits the worker thread.

    // thread commands
    function Init: HRESULT;
    function Exit_: HRESULT;
    function Run: HRESULT; reintroduce; 
    function Pause: HRESULT;
    function Stop: HRESULT;

    // *
    // * AM_MEDIA_TYPE support
    // *

    // If you support more than one media type then override these 2 functions
    function CheckMediaType(MediaType: PAMMediaType): HRESULT; override;
    function GetMediaType(Position: integer; out MediaType: PAMMediaType): HRESULT; overload; override; // List pos. 0-n
    // If you support only one type then override this fn.
    // This will only be called by the default implementations
    // of CheckMediaType and GetMediaType(int, CMediaType*)
    // You must override this fn. or the above 2!
    function GetMediaType(MediaType: PAMMediaType): HRESULT; reintroduce; overload; virtual;

    function QueryId(out id: PWideChar): HRESULT; override;
  protected
    function GetRequest: TThreadCommand;
    function CheckRequest(var com: TThreadCommand): boolean;

    // override these if you want to add thread commands
    function ThreadProc: DWORD; virtual; // the thread function

    function DoBufferProcessingLoop: HRESULT; virtual; // the loop executed whilst running
  end;

  TBCBaseRenderer = class;
  TBCRendererInputPin = class;

  // This is our input pin class that channels calls to the renderer

  TBCRendererInputPin = class(TBCBaseInputPin)
  protected
    FRenderer: TBCBaseRenderer;

  public
    constructor Create(Renderer: TBCBaseRenderer; out hr: HResult;
      Name: PWideChar);

    // Overriden from the base pin classes
    function BreakConnect: HResult; override;
    function CompleteConnect(ReceivePin: IPin): HResult; override;
    function SetMediaType(MediaType: PAMMediaType): HResult; override;
    function CheckMediaType(MediaType: PAMMediaType): HResult; override;
    function Active: HResult; override;
    function Inactive: HResult; override;

    // Add rendering behaviour to interface functions
    function QueryId(out Id: PWideChar): HResult; override; stdcall;
    function EndOfStream: HResult; override; stdcall;
    function BeginFlush: HResult; override; stdcall;
    function EndFlush: HResult; override; stdcall;
    function Receive(MediaSample: IMediaSample): HResult; override; stdcall;
    function InheritedReceive(MediaSample: IMediaSample): HResult;
      virtual; stdcall;
  end;

  // Main renderer class that handles synchronisation and state changes

  TBCBaseRenderer = class(TBCBaseFilter)
  protected
    // friend class CRendererInputPin;
    //FEndOfStreamTimerCB: TFNTimeCallBack;
    // Media seeking pass by object
    FPosition: TBCRendererPosPassThru;
    //FPosition: IUnknown;
    // Used to signal timer events
    FRenderEvent: TBCAMEvent;
    // Signalled to release worker thread
    FThreadSignal: TBCAMEvent;
    // Signalled when state complete
    FCompleteEvent: TBCAMEvent;
    // Stop us from rendering more data
    FAbort: Boolean;
    // Are we currently streaming
    FIsStreaming: Boolean;
    // Timer advise cookie
    FAdvisedCookie: DWord;
    // Current image media sample
    FMediaSample: IMediaSample;
    // Any more samples in the stream
    FIsEOS: Boolean;
    // Have we delivered an EC_COMPLETE
    FIsEOSDelivered: Boolean;
    // Our renderer input pin object
    FInputPin: TBCRendererInputPin;
    // Critical section for interfaces
    FInterfaceLock: TBCCritSec;
    // Controls access to internals
    FRendererLock: TBCCritSec;
    // QualityControl sink
    FQSink: IQualityControl;
    // Can we signal an EC_REPAINT
    FRepaintStatus: Boolean;
    //  Avoid some deadlocks by tracking filter during stop
    // Inside Receive between PrepareReceive and actually processing the sample
    FInReceive: Boolean;
    // Time when we signal EC_COMPLETE
    FSignalTime: TReferenceTime;
    // Used to signal end of stream
    FEndOfStreamTimer: DWord;
    // This lock protects the creation and of FPosition and FInputPin.
    // It ensures that two threads cannot create either object simultaneously.
    FObjectCreationLock: TBCCritSec;
// Milenko start (must be outside of the class and with stdcall; or it will crash)
//    procedure EndOfStreamTimer(
//      uID: UINT;      // Timer identifier
//      uMsg: UINT;     // Not currently used
//      dwUser: DWord;  // User information
//      dw1: DWord;     // Windows reserved
//      dw2: DWord      // Is also reserved
//    ); stdcall;
// Milenko end

  public
{$IFDEF PERF}
    // Just before we started drawing
    // Set in OnRenderStart, Used in OnRenderEnd
    FRenderStart: TReferenceTime;
    // MSR_id for frame time stamp
    FBaseStamp: Integer;
    // MSR_id for true wait time
    FBaseRenderTime: Integer;
    // MSR_id for time frame is late (int)
    FBaseAccuracy: Integer;
{$ENDIF}

    constructor Create(
      // CLSID for this renderer
      RendererClass: TGUID;
      // Debug ONLY description
      Name: PChar;
      // Aggregated owner object
      Unk: IUnknown;
      // General OLE return code
      hr: HResult);
    destructor Destroy; override;
// milenko start (added as a workaround for the TBCRendererPosPAssThru/FPosition and Renderer destructor)
    function JoinFilterGraph(pGraph: IFilterGraph; pName: PWideChar): HRESULT; override;
// milenko end

    // Overriden to say what interfaces we support and where

    function GetMediaPositionInterface(IID: TGUID; out Obj): HResult;
      virtual;
    function NonDelegatingQueryInterface(const IID: TGUID; out Obj): HResult;
      override; stdcall;

    function SourceThreadCanWait(CanWait: Boolean): HResult; virtual;
{$IFDEF _DEBUG}
    // Debug only dump of the renderer state
    procedure DisplayRendererState;
{$ENDIF}

    function WaitForRenderTime: HResult; virtual;
    function CompleteStateChange(OldState: TFilterState): HResult; virtual;

    // Return internal information about this filter

    property IsEndOfStream: Boolean read FIsEOS;
    property IsEndOfStreamDelivered: Boolean read FIsEOSDelivered;
    property IsStreaming: Boolean read FIsStreaming;

    procedure SetAbortSignal(Abort_: Boolean);
    procedure OnReceiveFirstSample(MediaSample: IMediaSample); virtual;
    property RenderEvent: TBCAMEvent read FRenderEvent;

    // Permit access to the transition state

    procedure Ready;
    procedure NotReady;
    function CheckReady: Boolean;

    function GetPinCount: Integer; override;
    function GetPin(n: integer): TBCBasePin; override;
    function GetRealState: TFilterState;
    procedure SendRepaint;
    procedure SendNotifyWindow(Pin: IPin; Handle: HWND);
    function OnDisplayChange: Boolean;
    procedure SetRepaintStatus(Repaint: Boolean);

    // Override the filter and pin interface functions

    function Stop: HResult; override; stdcall;
    function Pause: HResult; override; stdcall;
    function Run(StartTime: TReferenceTime): HResult; override; stdcall;
    function GetState(MSecs: DWord; out State: TFilterState): HResult;
      override; stdcall;
    function FindPin(id: PWideChar; out Pin: IPin): HResult;
      override; stdcall;

    // These are available for a quality management implementation

    procedure OnRenderStart(MediaSample: IMediaSample); virtual;
    procedure OnRenderEnd(MediaSample: IMediaSample); virtual;
    function OnStartStreaming: HResult; virtual;
    function OnStopStreaming: HResult; virtual;
    procedure OnWaitStart; virtual;
    procedure OnWaitEnd; virtual;
    procedure PrepareRender; virtual;

    // Quality management implementation for scheduling rendering

    function ScheduleSample(MediaSample: IMediaSample): Boolean; virtual;
    function GetSampleTimes(MediaSample: IMediaSample;
      out StartTime: TReferenceTime; out EndTime: TReferenceTime): HResult;
      virtual;

    function ShouldDrawSampleNow(MediaSample: IMediaSample;
      StartTime: TReferenceTime; out EndTime: TReferenceTime): HResult; virtual;

    // Lots of end of stream complexities

    procedure TimerCallback;
    procedure ResetEndOfStreamTimer;
    function NotifyEndOfStream: HResult; virtual;
    function SendEndOfStream: HResult; virtual;
    function ResetEndOfStream: HResult; virtual;
    function EndOfStream: HResult; virtual;

    // Rendering is based around the clock

    procedure SignalTimerFired;
    function CancelNotification: HResult; virtual;
    function ClearPendingSample: HResult; virtual;

    // Called when the filter changes state

    function Active: HResult; virtual;
    function Inactive: HResult; virtual;
    function StartStreaming: HResult; virtual;
    function StopStreaming: HResult; virtual;
    function BeginFlush: HResult; virtual;
    function EndFlush: HResult; virtual;

    // Deal with connections and type changes

    function BreakConnect: HResult; virtual;
    function SetMediaType(MediaType: PAMMediaType): HResult; virtual; 
    function CompleteConnect(ReceivePin: IPin): HResult; virtual;

    // These look after the handling of data samples

    function PrepareReceive(MediaSample: IMediaSample): HResult; virtual;
    function Receive(MediaSample: IMediaSample): HResult; virtual;
    function HaveCurrentSample: Boolean; virtual;
    function GetCurrentSample: IMediaSample; virtual;
    function Render(MediaSample: IMediaSample): HResult; virtual;

    // Derived classes MUST override these
    function DoRenderSample(MediaSample: IMediaSample): HResult;
      virtual; abstract;
    function CheckMediaType(MediaType: PAMMediaType): HResult;
      virtual; abstract;

    // Helper
    procedure WaitForReceiveToComplete;
(*
    // callback
    property EndOfStreamTimerCB: TFNTimeCallBack read FEndOfStreamTimerCB
      write FEndOfStreamTimerCB;
*)
  end;

const
  AVGPERIOD = 4;

type
  // CBaseVideoRenderer is a renderer class (see its ancestor class) and
  // it handles scheduling of media samples so that they are drawn at the
  // correct time by the reference clock.  It implements a degradation
  // strategy.  Possible degradation modes are:
  //    Drop frames here (only useful if the drawing takes significant time)
  //    Signal supplier (upstream) to drop some frame(s) - i.e. one-off skip.
  //    Signal supplier to change the frame rate - i.e. ongoing skipping.
  //    Or any combination of the above.
  // In order to determine what's useful to try we need to know what's going
  // on.  This is done by timing various operations (including the supplier).
  // This timing is done by using timeGetTime as it is accurate enough and
  // usually cheaper than calling the reference clock.  It also tells the
  // truth if there is an audio break and the reference clock stops.
  // We provide a number of public entry points (named OnXxxStart, OnXxxEnd)
  // which the rest of the renderer calls at significant moments.  These do
  // the timing.

  // the number of frames that the sliding averages are averaged over.
  // the rule is (1024*NewObservation + (AVGPERIOD-1) * PreviousAverage)/AVGPERIOD

  // #define DO_MOVING_AVG(avg,obs) (avg = (1024*obs + (AVGPERIOD-1)*avg)/AVGPERIOD)

  // Spot the bug in this macro - I can't. but it doesn't work!

  TBCBaseVideoRenderer = class(
      // Base renderer class
      TBCBaseRenderer,
      // Property page guff
      IQualProp,
      // Allow throttling
      IQualityControl)
  protected

    //******************************************************************
    // State variables to control synchronisation
    //******************************************************************

    // Control of sending Quality messages.  We need to know whether
    // we are in trouble (e.g. frames being dropped) and where the time
    // is being spent.

    // When we drop a frame we play the next one early.
    // The frame after that is likely to wait before drawing and counting this
    // wait as spare time is unfair, so we count it as a zero wait.
    // We therefore need to know whether we are playing frames early or not.

    // The number of consecutive frames drawn at their normal time (not early)
    // -1 means we just dropped a frame.
    FNormal: Integer;

{$IFDEF PERF}
    // Don't drop any frames (debug and I'm not keen on people using it!)
    FDrawLateFrames: Bool;
{$ENDIF}

    // The response to Quality messages says our supplier is handling things.
    // We will allow things to go extra late before dropping frames.
    // We will play very early after he has dropped one.
    FSupplierHandlingQuality: Boolean;

    // Control of scheduling, frame dropping etc.
    // We need to know where the time is being spent so as to tell whether
    // we should be taking action here, signalling supplier or what.
    // The variables are initialised to a mode of NOT dropping frames.
    // They will tell the truth after a few frames.
    // We typically record a start time for an event, later we get the time
    // again and subtract to get the elapsed time, and we average this over
    // a few frames.  The average is used to tell what mode we are in.

    // Although these are reference times (64 bit) they are all DIFFERENCES
    // between times which are small.  An int will go up to 214 secs before
    // overflow.  Avoiding 64 bit multiplications and divisions seems
    // worth while.

    // Audio-video throttling.  If the user has turned up audio quality
    // very high (in principle it could be any other stream, not just audio)
    // then we can receive cries for help via the graph manager.  In this case
    // we put in a wait for some time after rendering each frame.
    FThrottle: Integer;

    // The time taken to render (i.e. BitBlt) frames controls which component
    // needs to degrade.  If the blt is expensive, the renderer degrades.
    // If the blt is cheap it's done anyway and the supplier degrades.

    // Time frames are taking to blt
    FRenderAvg: Integer;
    // Time for last frame blt
    FRenderLast: Integer;
    // Just before we started drawing (mSec) derived from timeGetTime.
    FRenderStart: Integer;

    // When frames are dropped we will play the next frame as early as we can.
    // If it was a false alarm and the machine is fast we slide gently back to
    // normal timing.  To do this, we record the offset showing just how early
    // we really are.  This will normally be negative meaning early or zero.
    FEarliness: Integer;

    // Target provides slow long-term feedback to try to reduce the
    // average sync offset to zero.  Whenever a frame is actually rendered
    // early we add a msec or two, whenever late we take off a few.
    // We add or take off 1/32 of the error time.
    // Eventually we should be hovering around zero.  For a really bad case
    // where we were (say) 300mSec off, it might take 100 odd frames to
    // settle down.  The rate of change of this is intended to be slower
    // than any other mechanism in Quartz, thereby avoiding hunting.
    FTarget: Integer;

    // The proportion of time spent waiting for the right moment to blt
    // controls whether we bother to drop a frame or whether we reckon that
    // we're doing well enough that we can stand a one-frame glitch.

    // Average of last few wait times (actually we just average how early we were).
    // Negative here means LATE.
    FWaitAvg: Integer;

    // The average inter-frame time.
    // This is used to calculate the proportion of the time used by the
    // three operations (supplying us, waiting, rendering)

    // Average inter-frame time
    FFrameAvg: Integer;
    // duration of last frame.
    FDuration: Integer;

{$IFDEF PERF}
    // Performance logging identifiers
    // MSR_id for frame time stamp
    FTimeStamp: Integer;
    // MSR_id for true wait time
    FWaitReal: Integer;
    // MSR_id for wait time recorded
    FWait: Integer;
    // MSR_id for time frame is late (int)
    FFrameAccuracy: Integer;
    // MSR_id for lateness at scheduler
    FSchLateTime: Integer;
    // MSR_id for Quality rate requested
    FQualityRate: Integer;
    // MSR_id for Quality time requested
    FQualityTime: Integer;
    // MSR_id for decision code
    FDecision: Integer;
    // MSR_id for trace style debugging
    FDebug: Integer;
    // MSR_id for timing the notifications per se
    FSendQuality: Integer;
{$ENDIF}
    // original time stamp of frame with no earliness fudges etc.
    FRememberStampforPerf: TReferenceTime;
{$IFDEF PERF}
    // time when previous frame rendered
    FRememberFrameForPerf: TReferenceTime;
{$ENDIF}

    // PROPERTY PAGE
    // This has edit fields that show the user what's happening
    // These member variables hold these counts.

    // cumulative frames dropped IN THE RENDERER
    FFramesDropped: Integer;
    // Frames since streaming started seen BY THE RENDERER
    // (some may be dropped upstream)
    FFramesDrawn: Integer;

    // Next two support average sync offset and standard deviation of sync offset.

    // Sum of accuracies in mSec
    FTotAcc: Int64;
    // Sum of squares of (accuracies in mSec)
    FSumSqAcc: Int64;

    // Next two allow jitter calculation.  Jitter is std deviation of frame time.
    // Time of prev frame (for inter-frame times)
    FLastDraw: TReferenceTime;
    // Sum of squares of (inter-frame time in mSec)
    FSumSqFrameTime: Int64;
    // Sum of inter-frame times in mSec
    FSumFrameTime: Int64;

    // To get performance statistics on frame rate, jitter etc, we need
    // to record the lateness and inter-frame time.  What we actually need are the
    // data above (sum, sum of squares and number of entries for each) but the data
    // is generated just ahead of time and only later do we discover whether the
    // frame was actually drawn or not.  So we have to hang on to the data

    // hold onto frame lateness
    FLate: Integer;
    // hold onto inter-frame time
    FFrame: Integer;
    // if streaming then time streaming started
    // else time of last streaming session
    // used for property page statistics
    FStreamingStart: Integer;

{$IFDEF PERF}
    // timeGetTime*10000+m_llTimeOffset==ref time
    FTimeOffset: Int64;
{$ENDIF}

  public
    constructor Create(
      // CLSID for this renderer
      RenderClass: TGUID;
      // Debug ONLY description
      Name: PChar;
      // Aggregated owner object
      Unk: IUnknown;
      // General OLE return code
      hr: HResult);

    destructor Destroy; override;

    function NonDelegatingQueryInterface(const IID: TGUID; out Obj): HResult;
      override; stdcall;

    // IQualityControl methods - Notify allows audio-video throttling
    function SetSink(QualityControl: IQualityControl): HResult; stdcall;
    function Notify(Filter: IBaseFilter; q: TQuality): HResult; stdcall;

    // These provide a full video quality management implementation

    procedure OnRenderStart(MediaSample: IMediaSample); override;
    procedure OnRenderEnd(MediaSample: IMediaSample); override;
    procedure OnWaitStart; reintroduce;
    procedure OnWaitEnd; reintroduce;
    function OnStartStreaming: HResult; reintroduce;
    function OnStopStreaming: HResult; reintroduce;
    procedure ThrottleWait;

    // Handle the statistics gathering for our quality management

    procedure PreparePerformanceData(Late, Frame: Integer);
    procedure RecordFrameLateness(Late, Frame: Integer); virtual;
    procedure OnDirectRender(MediaSample: IMediaSample); virtual;
    function ResetStreamingTimes: HResult; virtual;
    function ScheduleSample(MediaSample: IMediaSample): Boolean; override;
    function ShouldDrawSampleNow(MediaSample: IMediaSample;
      StartTime: TReferenceTime; out EndTime: TReferenceTime): HResult;
      override;

    function SendQuality(Late, RealStream: TReferenceTime): HResult; virtual;
// milenko start (TBCBaseFilter made virtual, so just add override here)
    function JoinFilterGraph(Graph: IFilterGraph; Name: PWideChar): HResult; override;
// milenko end

    //
    //  Do estimates for standard deviations for per-frame
    //  statistics
    //
    //  *piResult = (llSumSq - iTot * iTot / m_cFramesDrawn - 1) /
    //                            (m_cFramesDrawn - 2)
    //  or 0 if m_cFramesDrawn <= 3
    //
    function GetStdDev(Samples: Integer; out Res: Integer;
      SumSq, Tot: Int64): HResult;

    // IQualProp property page support
    // ??? out <- var   function get_FramesDroppedInRenderer(out pcFrames : Integer) : HResult; stdcall;
    function get_FramesDroppedInRenderer(var FramesDropped: Integer): HResult;
      stdcall;
    function get_FramesDrawn(out FramesDrawn: Integer): HResult; stdcall;
    function get_AvgFrameRate(out AvgFrameRate: Integer): HResult; stdcall;
    function get_Jitter(out Jitter: Integer): HResult; stdcall;
    function get_AvgSyncOffset(out Avg: Integer): HResult; stdcall;
    function get_DevSyncOffset(out Dev: Integer): HResult; stdcall;
  end;

// milenko start (added TBCPullPin)

//
// CPullPin
//
// object supporting pulling data from an IAsyncReader interface.
// Given a start/stop position, calls a pure Receive method with each
// IMediaSample received.
//
// This is essentially for use in a MemInputPin when it finds itself
// connected to an IAsyncReader pin instead of a pushing pin.
//

  TThreadMsg = (
    TM_Pause,       // stop pulling and wait for next message
    TM_Start,       // start pulling
    TM_Exit         // stop and exit
  );

  TBCPullPin = class(TBCAMThread)
  private
    FReader: IAsyncReader;
    FStart: TReferenceTime;
    FStop: TReferenceTime;
    FDuration: TReferenceTime;
    FSync: Boolean;
    FState: TThreadMsg;
    // running pull method (check m_bSync)
    procedure Process;
    // clean up any cancelled i/o after a flush
    procedure CleanupCancelled;
    // suspend thread from pulling, eg during seek
    function PauseThread: HRESULT;
    // start thread pulling - create thread if necy
    function StartThread: HRESULT;
    // stop and close thread
    function StopThread: HRESULT;
    // called from ProcessAsync to queue and collect requests
    function QueueSample(var tCurrent: TReferenceTime; tAlignStop: TReferenceTime; bDiscontinuity: Boolean): HRESULT;
    function CollectAndDeliver(tStart,tStop: TReferenceTime): HRESULT;
    function DeliverSample(pSample: IMediaSample; tStart,tStop: TReferenceTime): HRESULT;
  protected
    FAlloc: IMemAllocator;
    // override pure thread proc from CAMThread
    function ThreadProc: DWord; override;
  public
    constructor Create;
    destructor Destroy; override;
    // returns S_OK if successfully connected to an IAsyncReader interface
    // from this object
    // Optional allocator should be proposed as a preferred allocator if
    // necessary
    // bSync is TRUE if we are to use sync reads instead of the
    // async methods.
    function Connect(pUnk: IUnknown; pAlloc: IMemAllocator; bSync: Boolean): HRESULT;
    // disconnect any connection made in Connect
    function Disconnect: HRESULT;
    // agree an allocator using RequestAllocator - optional
    // props param specifies your requirements (non-zero fields).
    // returns an error code if fail to match requirements.
    // optional IMemAllocator interface is offered as a preferred allocator
    // but no error occurs if it can't be met.
    function DecideAllocator(pAlloc: IMemAllocator; pProps: PAllocatorProperties): HRESULT;
    // set start and stop position. if active, will start immediately at
    // the new position. Default is 0 to duration
    function Seek(tStart, tStop: TReferenceTime): HRESULT;
    // return the total duration
    function Duration(out ptDuration: TReferenceTime): HRESULT;
    // start pulling data
    function Active: HRESULT;
    // stop pulling data
    function Inactive: HRESULT;
    // helper functions
    function AlignDown(ll: Int64; lAlign: LongInt): Int64;
    function AlignUp(ll: Int64; lAlign: LongInt): Int64;
    // GetReader returns the (addrefed) IAsyncReader interface
    // for SyncRead etc
    function GetReader: IAsyncReader;
    // -- pure --
    // override this to handle data arrival
    // return value other than S_OK will stop data
    function Receive(Sample: IMediaSample): HRESULT; virtual; abstract;
    // override this to handle end-of-stream
    function EndOfStream: HRESULT; virtual; abstract;
    // called on runtime errors that will have caused pulling
    // to stop
    // these errors are all returned from the upstream filter, who
    // will have already reported any errors to the filtergraph.
    procedure OnError(hr: HRESULT); virtual; abstract;
    // flush this pin and all downstream
    function BeginFlush: HRESULT; virtual; abstract;
    function EndFlush: HRESULT; virtual; abstract;
  end;
// milenko end

// milenko start (needed to access functions outside. usefull for Filter Development)
function CreateMemoryAllocator(out Allocator: IMemAllocator): HRESULT;
function AMGetWideString(Source: WideString; out Dest: PWideChar): HRESULT;
function CreatePosPassThru(Agg: IUnknown; Renderer: boolean; Pin: IPin; out PassThru: IUnknown): HRESULT; stdcall;
// milenko end

// milenko start reftime implementation
//------------------------------------------------------------------------------
// File: RefTime.h
//
// Desc: DirectShow base classes - defines CRefTime, a class that manages
//       reference times.
//
// Copyright (c) 1992-2002 Microsoft Corporation. All rights reserved.
//------------------------------------------------------------------------------


//
// CRefTime
//
// Manage reference times.
// Shares same data layout as REFERENCE_TIME, but adds some (nonvirtual)
// functions providing simple comparison, conversion and arithmetic.
//
// A reference time (at the moment) is a unit of seconds represented in
// 100ns units as is used in the Win32 FILETIME structure. BUT the time
// a REFERENCE_TIME represents is NOT the time elapsed since 1/1/1601 it
// will either be stream time or reference time depending upon context
//
// This class provides simple arithmetic operations on reference times
//
// keep non-virtual otherwise the data layout will not be the same as
// REFERENCE_TIME


// -----
// note that you are safe to cast a CRefTime* to a REFERENCE_TIME*, but
// you will need to do so explicitly
// -----

type
  TBCRefTime = object
  public
    // *MUST* be the only data member so that this class is exactly
    // equivalent to a REFERENCE_TIME.
    // Also, must be *no virtual functions*
    FTime: TReferenceTime;
    // DCODER: using Create_ as contructor replacement ...
    procedure Create_; overload;
    procedure Create_(msecs: Longint); overload;
    // delphi 5 doesn't like "const rt: TBCRefTime" ???
    function SetTime(var rt: TBCRefTime): TBCRefTime; overload;
    function SetTime(var ll: LONGLONG): TBCRefTime; overload;
    function AddTime(var rt: TBCRefTime): TBCRefTime; overload;
    function SubstractTime(var rt: TBCRefTime): TBCRefTime; overload;
    function Millisecs: Longint;
    function GetUnits: LONGLONG;
  end;
// milenko end;

// milenko start schedule implementation
//------------------------------------------------------------------------------
// File: Schedule.cpp
//
// Desc: DirectShow base classes.
//
// Copyright (c) 1996-2002 Microsoft Corporation.  All rights reserved.
//------------------------------------------------------------------------------

type
  TBCAdvisePacket = class
  public
    FNext        : TBCAdvisePacket;
    FAdviseCookie: DWORD;
    FEventTime   : TReferenceTime; // Time at which event should be set
    FPeriod      : TReferenceTime; // Periodic time
    FNotify      : THandle;        // Handle to event or semephore
    FPeriodic    : Boolean;        // TRUE => Periodic event
    constructor Create; overload;
    constructor Create(Next: TBCAdvisePacket; Time: LONGLONG); overload;
    procedure InsertAfter(Packet: TBCAdvisePacket);
    // That is, is it the node that represents the end of the list
    function IsZ: Boolean;
    function RemoveNext: TBCAdvisePacket;
    procedure DeleteNext;
    function Next: TBCAdvisePacket;
    function Cookie: DWORD;
  end;

  TBCAMSchedule = class(TBCBaseObject)
  private
    // Structure is:
    // head -> elmt1 -> elmt2 -> z -> null
    // So an empty list is:       head -> z -> null
    // Having head & z as links makes insertaion,
    // deletion and shunting much easier.
    FHead,
    FZ          : TBCAdvisePacket; // z is both a tail and a sentry
    FNextCookie : DWORD;     // Strictly increasing
    FAdviseCount: DWORD;    // Number of elements on list
    FSerialize  : TBCCritSec;
    // Event that we should set if the packed added above will be the next to fire.
    FEvent      : THandle;
    // Rather than delete advise packets, we cache them for future use
    FAdviseCache: TBCAdvisePacket;
    FCacheCount : DWORD;
    // AddAdvisePacket: adds the packet, returns the cookie (0 if failed)
    function AddAdvisePacket(Packet: TBCAdvisePacket): DWORD; overload;
    // A Shunt is where we have changed the first element in the
    // list and want it re-evaluating (i.e. repositioned) in
    // the list.
    procedure ShuntHead;
    procedure Delete(Packet: TBCAdvisePacket);// This "Delete" will cache the Link
  public
    // ev is the event we should fire if the advise time needs re-evaluating
    constructor Create(Event: THandle);
    destructor Destroy; override;
    function GetAdviseCount: DWORD;
    function GetNextAdviseTime: TReferenceTime;
    // We need a method for derived classes to add advise packets, we return the cookie
    function AddAdvisePacket(const Time1, Time2: TReferenceTime; h: THandle;
      Periodic: Boolean): DWORD; overload;
    // And a way to cancel
    function Unadvise(AdviseCookie: DWORD): HRESULT;
    // Tell us the time please, and we'll dispatch the expired events.
    // We return the time of the next event.
    // NB: The time returned will be "useless" if you start adding extra Advises.
    // But that's the problem of
    // whoever is using this helper class (typically a clock).
    function Advise(const Time_: TReferenceTime): TReferenceTime;
    // Get the event handle which will be set if advise time requires re-evaluation.
    function GetEvent: THandle;
    procedure DumpLinkedList;
  end;
// milenko end

// milenko start refclock implementation
//------------------------------------------------------------------------------
// File: RefClock.h
//
// Desc: DirectShow base classes - defines the IReferenceClock interface.
//
// Copyright (c) 1992-2002 Microsoft Corporation.  All rights reserved.
//------------------------------------------------------------------------------

(* This class hierarchy will support an IReferenceClock interface so
   that an audio card (or other externally driven clock) can update the
   system wide clock that everyone uses.

   The interface will be pretty thin with probably just one update method
   This interface has not yet been defined.
 *)

(* This abstract base class implements the IReferenceClock
 * interface.  Classes that actually provide clock signals (from
 * whatever source) have to be derived from this class.
 *
 * The abstract class provides implementations for:
 * 	CUnknown support
 *      locking support (CCritSec)
 *	client advise code (creates a thread)
 *
 * Question: what can we do about quality?  Change the timer
 * resolution to lower the system load?  Up the priority of the
 * timer thread to force more responsive signals?
 *
 * During class construction we create a worker thread that is destroyed during
 * destuction.  This thread executes a series of WaitForSingleObject calls,
 * waking up when a command is given to the thread or the next wake up point
 * is reached.  The wakeup points are determined by clients making Advise
 * calls.
 *
 * Each advise call defines a point in time when they wish to be notified.  A
 * periodic advise is a series of these such events.  We maintain a list of
 * advise links and calculate when the nearest event notification is due for.
 * We then call WaitForSingleObject with a timeout equal to this time.  The
 * handle we wait on is used by the class to signal that something has changed
 * and that we must reschedule the next event.  This typically happens when
 * someone comes in and asks for an advise link while we are waiting for an
 * event to timeout.
 *
 * While we are modifying the list of advise requests we
 * are protected from interference through a critical section.  Clients are NOT
 * advised through callbacks.  One shot clients have an event set, while
 * periodic clients have a semaphore released for each event notification.  A
 * semaphore allows a client to be kept up to date with the number of events
 * actually triggered and be assured that they can't miss multiple events being
 * set.
 *
 * Keeping track of advises is taken care of by the CAMSchedule class.
 *)

type
  TBCBaseReferenceClock = class(TBCUnknown, IReferenceClock)
  private
    FLock           : TBCCritSec;
    FAbort          : Boolean;        // Flag used for thread shutdown
    FThread         : THandle;        // Thread handle
    FPrivateTime    : TReferenceTime; // Current best estimate of time
    FPrevSystemTime : DWORD;          // Last vaule we got from timeGetTime
    FLastGotTime    : TReferenceTime; // Last time returned by GetTime
    FNextAdvise     : TReferenceTime; // Time of next advise
    FTimerResolution: DWORD;
  {$IFDEF PERF}
    FGetSystemTime  : integer;
  {$ENDIF}
    function AdviseThread: HRESULT;  // Method in which the advise thread runs
  protected
    FSchedule       : TBCAMSchedule;
  public
    constructor Create(Name: String; Unk: IUnknown; out hr: HRESULT; Sched:
       TBCAMSchedule = nil);
    destructor Destroy; override; // Don't let me be created on the stack!
    function NonDelegatingQueryInterface(const IID: TGUID; out Obj): HResult; override; stdcall;
    // IReferenceClock methods
    // Derived classes must implement GetPrivateTime().  All our GetTime
    // does is call GetPrivateTime and then check so that time does not
    // go backwards.  A return code of S_FALSE implies that the internal
    // clock has gone backwards and GetTime time has halted until internal
    // time has caught up. (Don't know if this will be much use to folk,
    // but it seems odd not to use the return code for something useful.)
    function GetTime(out Time: int64): HResult; stdcall;
    // When this is called, it sets m_rtLastGotTime to the time it returns.
    // Provide standard mechanisms for scheduling events
    // Ask for an async notification that a time has elapsed */
    function AdviseTime(
        BaseTime,                       // base reference time
        StreamTime: int64;    // stream offset time
        Event: THandle;                  // advise via this event
        out AdviseCookie: DWORD        // where your cookie goes
    ): HResult; stdcall;
    // Ask for an asynchronous periodic notification that a time has elapsed
    function AdvisePeriodic(
        const StartTime,                // starting at this time
        PeriodTime: int64;    // time between notifications
        Semaphore: THandle;              // advise via a semaphore
         out AdviseCookie: DWORD       // where your cookie goes
    ): HResult; stdcall;
    (* Cancel a request for notification(s) - if the notification was
     * a one shot timer then this function doesn't need to be called
     * as the advise is automatically cancelled, however it does no
     * harm to explicitly cancel a one-shot advise.  It is REQUIRED that
     * clients call Unadvise to clear a Periodic advise setting.
     *)
    function Unadvise(AdviseCookie: DWORD): HResult; stdcall;
    // Methods for the benefit of derived classes or outer objects
    // GetPrivateTime() is the REAL clock.  GetTime is just a cover for
    // it.  Derived classes will probably override this method but not
    // GetTime() itself.
    // The important point about GetPrivateTime() is it's allowed to go
    // backwards.  Our GetTime() will keep returning the LastGotTime
    // until GetPrivateTime() catches up.
    function GetPrivateTime: TReferenceTime; virtual;
    // Provide a method for correcting drift
    function SetTimeDelta(const TimeDelta: TReferenceTime): HRESULT; stdcall;
    function GetSchedule: TBCAMSchedule;
    // Thread stuff
    // Wakes thread up.  Need to do this if time to next advise needs reevaluating.
    procedure TriggerThread;
  end;
// milenko end

// milenko start sysclock implementation
//------------------------------------------------------------------------------
// File: SysClock.h
//
// Desc: DirectShow base classes - defines a system clock implementation of
//       IReferenceClock.
//
// Copyright (c) 1992-2002 Microsoft Corporation.  All rights reserved.
//------------------------------------------------------------------------------
const
  IID_IPersist : TGUID = '{0000010C-0000-0000-C000-000000000046}';

type
  TBCSystemClock = class(TBCBaseReferenceClock, IAMClockAdjust, IPersist)
  public
    constructor Create(Name: WideString; Unk : IUnknown; out hr : HRESULT);
    function NonDelegatingQueryInterface(const IID: TGUID; out Obj): HResult; override; stdcall;
    // Yield up our class id so that we can be persisted
    // Implement required Ipersist method
    function GetClassID(out classID: TCLSID): HResult; stdcall;
    //  IAMClockAdjust methods
    function SetClockDelta(rtDelta: TReferenceTime): HResult; stdcall;
  end;

//=====================================================================
//=====================================================================
// Memory allocators
//
// the shared memory transport between pins requires the input pin
// to provide a memory allocator that can provide sample objects. A
// sample object supports the IMediaSample interface.
//
// TBCBaseAllocator handles the management of free and busy samples. It
// allocates TBCMediaSample objects. TBCBaseAllocator is an abstract class:
// in particular it has no method of initializing the list of free
// samples. TBCMemAllocator is derived from TBCBaseAllocator and initializes
// the list of samples using memory from the standard IMalloc interface.
//
// If you want your buffers to live in some special area of memory,
// derive your allocator object from TBCBaseAllocator. If you derive your
// IMemInputPin interface object from CBaseMemInputPin, you will get
// TBCMemAllocator-based allocation etc for free and will just need to
// supply the Receive handling, and media type / format negotiation.
//=====================================================================
//=====================================================================


//=====================================================================
//=====================================================================
// Defines TBCMediaSample
//
// an object of this class supports IMediaSample and represents a buffer
// for media data with some associated properties. Releasing it returns
// it to a freelist managed by a TBCBaseAllocator derived object.
//=====================================================================
//=====================================================================

const
  (*  Values for dwFlags - these are used for backward compatiblity
      only now - use AM_SAMPLE_xxx
  *)
  Sample_SyncPoint          =  $01; (* Is this a sync point *)
  Sample_Preroll            =  $02; (* Is this a preroll sample *)
  Sample_Discontinuity      =  $04; (* Set if start of new segment *)
  Sample_TypeChanged        =  $08; (* Has the type changed *)
  Sample_TimeValid          =  $10; (* Set if time is valid *)
  Sample_MediaTimeValid     =  $20; (* Is the media time valid *)
  Sample_TimeDiscontinuity  =  $40; (* Time discontinuity *)
  Sample_StopValid          = $100; (* Stop time valid *)
  Sample_ValidFlags         = $1FF;

  IID_IUnknown: TGUID = '{00000000-0000-0000-C000-000000000046}';

type
  TBCBaseAllocator = class;

  PBCMediaSample = ^TBCMediaSample;
  TBCMediaSample = class(TObject, IInterface, IMediaSample2)
  protected
    //friend class TBCBaseAllocator;


    (* Properties, the media sample class can be a container for a format
       change in which case we take a copy of a type through the SetMediaType
       interface function and then return it when GetMediaType is called. As
       we do no internal processing on it we leave it as a pointer *)

    FFlags: DWORD;         (* Flags for this sample *)
                              (* Type specific flags are packed
                                 into the top word
                               *)
    FTypeSpecificFlags: DWORD; (* Media type specific flags *)
    FBuffer: PBYTE;             (* Pointer to the complete buffer *)
    FActual: integer;           (* Length of data in this sample *)
    FBufferSize: integer;          (* Size of the buffer *)
    FAllocator: TBCBaseAllocator;     (* The allocator who owns us *)
    FNext: TBCMediaSample;            (* Chaining in free list *)
    FStart: TReferenceTime;          (* Start sample time *)
    FEnd: TReferenceTime;            (* End sample time *)
    FMediaStart: LONGLONG;           (* Real media start position *)
    FMediaEnd: integer;              (* A difference to get the end *)
    FMediaType: PAMMEDIATYPE;       (* Media type change data *)
    FStreamId: DWORD;              (* Stream id *)
  public
    FRef: integer;                  (* Reference count *)

    constructor Create(
      pName: WideString;
      pAllocator: TBCBaseAllocator;
      out phr: HRESULT;
      pBuffer: PBYTE = nil;
      _length: integer = 0
    );

    destructor Destroy; override;

    (* Note the media sample does not delegate to its owner *)
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;

    // set the buffer pointer and length. Used by allocators that
    // want variable sized pointers or pointers into already-read data.
    // This is only available through a TBCMediaSample* not an IMediaSample*
    // and so cannot be changed by clients.
    function SetPointer(ptr: PBYTE; cBytes: integer): HRESULT;

    (*** IMediaSample methods ***)
    // Get me a read/write pointer to this buffer's memory.
    function GetPointer(out ppBuffer: PBYTE): HResult; stdcall;
    function GetSize: Longint; stdcall;
    // get the stream time at which this sample should start and finish.
    function GetTime(out pTimeStart, pTimeEnd: TReferenceTime): HResult; stdcall;
    // Set the stream time at which this sample should start and finish.
    function SetTime(
      pTimeStart,       // put time here
      pTimeEnd: PReferenceTime
    ): HResult; stdcall;
    function IsSyncPoint: HResult; stdcall;
    function SetSyncPoint(bIsSyncPoint: BOOL): HResult; stdcall;
    function IsPreroll: HResult; stdcall;
    function SetPreroll(bIsPreroll: BOOL): HResult; stdcall;
    function GetActualDataLength: Longint; stdcall;
    function SetActualDataLength(lLen: Longint): HResult; stdcall;
    // these allow for limited format changes in band
    function GetMediaType(out ppMediaType: PAMMediaType): HResult; stdcall;
    function SetMediaType(pMediaType: PAMMediaType): HResult; stdcall;
    // returns S_OK if there is a discontinuity in the data (this same is
    // not a continuation of the previous stream of data
    // - there has been a seek).
    function IsDiscontinuity: HResult; stdcall;
    // set the discontinuity property - TRUE if this sample is not a
    // continuation, but a new sample after a seek.
    function SetDiscontinuity(bDiscontinuity: BOOL): HResult; stdcall;
    // get the media times for this sample
    function GetMediaTime(out pTimeStart, pTimeEnd: int64): HResult; stdcall;
    // Set the media times for this sample
    function SetMediaTime(pTimeStart, pTimeEnd: Pint64): HResult; stdcall;

    (*** IMediaSample2 methods ***)
    // Set and get properties (IMediaSample2)
    function GetProperties(cbProperties: DWORD; out pbProperties): HResult; stdcall;
    function SetProperties(cbProperties: DWORD; const pbProperties): HResult; stdcall;
  end;


//=====================================================================
//=====================================================================
// Defines TBCBaseAllocator
//
// Abstract base class that manages a list of media samples
//
// This class provides support for getting buffers from the free list,
// including handling of commit and (asynchronous) decommit.
//
// Derive from this class and override the Alloc and Free functions to
// allocate your TBCMediaSample (or derived) objects and add them to the
// free list, preparing them as necessary.
//=====================================================================
//=====================================================================

  (*  Mini list class for the free list *)
  TBCSampleList = class
  protected
    FList: TBCMediaSample;
    FOnList: integer;
  public
    constructor Create;
    {$ifdef _DEBUG}
    destructor Destroy; override;
    {$endif}
    function Head: TBCMediaSample;
    function Next(pSample: TBCMediaSample): TBCMediaSample;
    function GetCount: integer;
    procedure Add(pSample: TBCMediaSample);
    function RemoveHead: TBCMediaSample;
    procedure Remove(pSample: TBCMediaSample);
  end;

  TBCBaseAllocator = class(TBCUnknown, IMemAllocatorCallbackTemp)
  protected
    FAllocatorLock: TBCCritSec;
    FFree: TBCSampleList;        // Free list

    (*  Note to overriders of TBCBaseAllocator.

        We use a lazy signalling mechanism for waiting for samples.
        This means we don't call the OS if no waits occur.

        In order to implement this:

        1. When a new sample is added to m_lFree call NotifySample() which
           calls ReleaseSemaphore on m_hSem with a count of m_lWaiting and
           sets m_lWaiting to 0.
           This must all be done holding the allocator's critical section.

        2. When waiting for a sample call SetWaiting() which increments
           m_lWaiting BEFORE leaving the allocator's critical section.

        3. Actually wait by calling WaitForSingleObject(m_hSem, INFINITE)
           having left the allocator's critical section.  The effect of
           this is to remove 1 from the semaphore's count.  You MUST call
           this once having incremented m_lWaiting.

        The following are then true when the critical section is not held :
            (let nWaiting = number about to wait or waiting)

            (1) if (m_lFree.GetCount() != 0) then (m_lWaiting == 0)
            (2) m_lWaiting + Semaphore count == nWaiting

        We would deadlock if
           nWaiting != 0 &&
           m_lFree.GetCount() != 0 &&
           Semaphore count == 0

           But from (1) if m_lFree.GetCount() != 0 then m_lWaiting == 0 so
           from (2) Semaphore count == nWaiting (which is non-0) so the
           deadlock can't happen.
    *)

    FSem: THANDLE;                // For signalling
    FWaiting: integer;            // Waiting for a free element
    FCount: integer;              // how many buffers we have agreed to provide
    FAllocated: integer;          // how many buffers are currently allocated
    FSize: integer;               // agreed size of each buffer
    FAlignment: integer;          // agreed alignment
    FPrefix: integer;             // agreed prefix (preceeds GetPointer() value)
    FChanged: BOOL;               // Have the buffer requirements changed

    // if true, we are decommitted and can't allocate memory
    FCommitted: BOOL;
    // if true, the decommit has happened, but we haven't called Free yet
    // as there are still outstanding buffers
    FDecommitInProgress: BOOL;

    //  Notification interface
    FNotify: IMemAllocatorNotifyCallbackTemp;

    FEnableReleaseCallback: BOOL;

    (*  Trick to get at protected member in TBCMediaSample *)
    //static TBCMediaSample * &NextSample(TBCMediaSample *pSample)
    class function NextSample(pSample: TBCMediaSample): PBCMediaSample;
    {
        return pSample.m_pNext;
    }

    // called to decommit the memory when the last buffer is freed
    // pure virtual - need to override this
    procedure _Free; virtual; abstract;

    // override to allocate the memory when commit called
    function Alloc: HRESULT; virtual; 

  public
    constructor Create(
      pName: WideString;
      pUnk: IUnknown;
      out phr: HRESULT;
      bEvent: BOOL;
      EnableReleaseCallback: BOOL
    );
    destructor Destroy; override;

    //DECLARE_IUNKNOWN
    function NonDelegatingAddRef: Integer; override; stdcall;
    function NonDelegatingRelease: Integer; override; stdcall;

    // CHB: Implementierung von TBCCritSec...
    procedure Lock;
    procedure UnLock;
    function CritCheckIn: boolean;
    function CritCheckOut: boolean;

    // override this to publicise our interfaces
    //STDMETHODIMP NonDelegatingQueryInterface(REFIID riid, void **ppv);
    function NonDelegatingQueryInterface(const IID: TGUID; out Obj): HResult; override; stdcall;

    (*** IMemAllocator methods ***)
    function SetProperties(
      var pRequest: TAllocatorProperties;
      out pActual: TAllocatorProperties
    ): HResult; virtual; stdcall;
    // return the properties actually being used on this allocator
    function GetProperties(out pProps: TAllocatorProperties): HResult; virtual; stdcall;
    // override Commit to allocate memory. We handle the GetBuffer
    //state changes
    function Commit: HResult; virtual; stdcall;
    // override this to handle the memory freeing. We handle any outstanding
    // GetBuffer calls
    function Decommit: HResult; virtual; stdcall;
    // get container for a sample. Blocking, synchronous call to get the
    // next free buffer (as represented by an IMediaSample interface).
    // on return, the time etc properties will be invalid, but the buffer
    // pointer and size will be correct. The two time parameters are
    // optional and either may be NULL, they may alternatively be set to
    // the start and end times the sample will have attached to it
    // bPrevFramesSkipped is not used (used only by the video renderer's
    // allocator where it affects quality management in direct draw).
    function GetBuffer(out ppBuffer: IMediaSample;
        pStartTime, pEndTime: PReferenceTime; dwFlags: DWORD): HResult; virtual; stdcall;
    // final release of a TBCMediaSample will call this
    function ReleaseBuffer(pBuffer: IMediaSample): HResult; virtual; stdcall;

    // obsolete:: virtual void PutOnFreeList(TBCMediaSample * pSample);

    (*** IMemAllocatorCallbackTemp methods ***)
    function SetNotify(pNotify: IMemAllocatorNotifyCallbackTemp): HResult; virtual; stdcall;
    function GetFreeCount(out plBuffersFree: LongInt): HResult; virtual; stdcall;

    // Notify that a sample is available
    procedure NotifySample;

    // Notify that we're waiting for a sample
    procedure SetWaiting; { m_lWaiting++; }
  end;


//=====================================================================
//=====================================================================
// Defines TBCMemAllocator
//
// this is an allocator based on TBCBaseAllocator that allocates sample
// buffers in main memory (from 'new'). You must call SetProperties
// before calling Commit.
//
// we don't free the memory when going into Decommit state. The simplest
// way to implement this without complicating TBCBaseAllocator is to
// have a Free() function, called to go into decommit state, that does
// nothing and a ReallyFree function called from our destructor that
// actually frees the memory.
//=====================================================================
//=====================================================================

//  Make me one from quartz.dll
//STDAPI CreateMemoryAllocator(IMemAllocator **ppAllocator);

  TBCMemAllocator = class(TBCBaseAllocator)
  protected
    FBuffer: PBYTE;   // combined memory for all buffers

    // override to free the memory when decommit completes
    // - we actually do nothing, and save the memory until deletion.
    procedure _Free; override;

    // called from the destructor (and from Alloc if changing size/count) to
    // actually free up the memory
    procedure ReallyFree;

    // overriden to allocate the memory when commit called
    function Alloc: HRESULT; override;

  public
    (* This goes in the factory template table to create new instances *)
    //static CUnknown *CreateInstance(LPUNKNOWN, HRESULT *);
    class function CreateInstance(const Unk: IUnknown; out hr: HRESULT): TBCUnknown;

    function SetProperties(
      var pRequest: TAllocatorProperties;
      out pActual: TAllocatorProperties
    ): HResult; override; stdcall;

    constructor Create(
      pName: WideString;
      pUnk: IUnknown;
      out phr: HRESULT
    );
    (*{$ifdef UNICODE}
    TBCMemAllocator(CHAR *, LPUNKNOWN, HRESULT * )
    {$endif}(**)
    destructor Destroy; override;

    function InheritedAlloc: HRESULT;
  end;


{$IFDEF _DEBUG}
  procedure DbgLog(obj: TBCBaseObJect; const msg: string); overload;
  procedure DbgLog(const msg: string); overload;
  procedure DbgAssert(const Message, Filename: string; LineNumber: Integer;
    ErrorAddr: Pointer);
{$ENDIF}

  function DllGetClassObject(const CLSID, IID: TGUID; var Obj): HResult; stdcall;
  function DllCanUnloadNow: HResult; stdcall;
  function DllRegisterServer: HResult; stdcall;
  function DllUnregisterServer: HResult; stdcall;

(* milenko start (needed for TBCBaseReferenceClock and TBCVideoTransformFilter ) *)
{$IFDEF PERF}
  procedure MSR_START(Id_: Integer);
  procedure MSR_STOP(Id_: Integer);
  procedure MSR_INTEGER(Id_, i: Integer);
  function MSR_REGISTER(s: String): Integer;
{$ENDIF}
(* milenko end *)

implementation

var
  ObjectCount  : Integer;
  FactoryCount : Integer;
  TemplatesVar : TBCFilterTemplate;
// milenko start (added global variables instead of local constants)
  IsCheckedVersion: Bool = False;
  IsTimeKillSynchronousFlagAvailable: Bool = False;
  MsgId: Cardinal = 0;
// milenko end

{$IFDEF _DEBUG}
 {$IFNDEF MESSAGE}
  DebugFile : TextFile;
 {$ENDIF}
  procedure DbgLog(obj: TBCBaseObJect; const msg: string);
  begin
  {$IFNDEF MESSAGE}
    if (obj = nil) then
      Writeln(DebugFile, TimeToStr(time) +' > '+ msg) else
      Writeln(DebugFile, TimeToStr(time) +' > '+ format('Object: %s, msg: %s.',[obj.FName, msg]));
    Flush(DebugFile);
  {$ELSE}
    if (obj = nil) then OutputDebugString(PChar(TimeToStr(time) +' > '+ msg)) else
      OutputDebugString(PChar(TimeToStr(time) +' > '+ format('Object: %s, msg: %s.',[obj.FName, msg])));
  {$ENDIF}
  end;

  procedure DbgLog(const msg: string); overload;
  begin
  {$IFNDEF MESSAGE}
    Writeln(DebugFile, TimeToStr(time) +' > '+ msg);
    Flush(DebugFile);
  {$ELSE}
    OutputDebugString(PChar(TimeToStr(time) +' > '+ msg));
  {$ENDIF}
  end;

  procedure DbgAssert(const Message, Filename: string; LineNumber: Integer;
    ErrorAddr: Pointer);
  begin
    DbgLog(format('[ASSERT] %s (%s) line: %d, adr: $%x',
      [Message, Filename, LineNumber, Integer(ErrorAddr)]));
  end;
{$ENDIF}

// -----------------------------------------------------------------------------
//  TBCMediaType
// -----------------------------------------------------------------------------

  function TBCMediaType.Equal(mt: TBCMediaType): boolean;
  begin
    result := ((IsEqualGUID(Mediatype.majortype,mt.MediaType.majortype) = True) and
        (IsEqualGUID(Mediatype.subtype,mt.MediaType.subtype) = True) and
        (IsEqualGUID(Mediatype.formattype,mt.MediaType.formattype) = True) and
        (Mediatype.cbFormat = mt.MediaType.cbFormat) and
        ( (Mediatype.cbFormat = 0) or
          (CompareMem(Mediatype.pbFormat, mt.MediaType.pbFormat, Mediatype.cbFormat))));
  end;

  function TBCMediaType.Equal(mt: PAMMediaType): boolean;
  begin
    result := ((IsEqualGUID(Mediatype.majortype,mt.majortype) = True) and
        (IsEqualGUID(Mediatype.subtype,mt.subtype) = True) and
        (IsEqualGUID(Mediatype.formattype,mt.formattype) = True) and
        (Mediatype.cbFormat = mt.cbFormat) and
        ( (Mediatype.cbFormat = 0) or
          (CompareMem(Mediatype.pbFormat, mt.pbFormat, Mediatype.cbFormat))));
  end;

  function TBCMediaType.MatchesPartial(Partial: PAMMediaType): boolean;
  begin
    result := false;
    if (not IsEqualGUID(partial.majortype, GUID_NULL) and
        not IsEqualGUID(MediaType.majortype, partial.majortype)) then exit;

    if (not IsEqualGUID(partial.subtype, GUID_NULL) and
        not IsEqualGUID(MediaType.subtype, partial.subtype)) then exit;

    if not IsEqualGUID(partial.formattype, GUID_NULL) then
    begin
      if not IsEqualGUID(MediaType.formattype, partial.formattype) then exit;
      if (MediaType.cbFormat <> partial.cbFormat) then exit;
      if ((MediaType.cbFormat <> 0) and
          (CompareMem(MediaType.pbFormat, partial.pbFormat, MediaType.cbFormat) <> false)) then exit;
    end;
    result := True;
  end;

  function TBCMediaType.IsPartiallySpecified: boolean;
  begin
    if (IsEqualGUID(Mediatype.majortype, GUID_NULL) or
        IsEqualGUID(Mediatype.formattype, GUID_NULL)) then result := True
                                               else result := false;
  end;

  function TBCMediaType.IsValid: boolean;
  begin
    result := not IsEqualGUID(MediaType.majortype,GUID_NULL);
  end;

  procedure TBCMediaType.InitMediaType;
  begin
    ZeroMemory(MediaType, sizeof(TAMMediaType));
    MediaType.lSampleSize := 1;
    MediaType.bFixedSizeSamples := True;
  end;

  function TBCMediaType.Format: Pointer;
  begin
    Result := MediaType.pbFormat;
  end;

  function TBCMediaType.FormatLength: Cardinal;
  begin
    result := MediaType.cbFormat
  end;


// -----------------------------------------------------------------------------
// milenko start
  function AMGetWideString(Source: WideString; out Dest: PWideChar): HRESULT;
  var NameLen: Cardinal;
  begin
    if not assigned(@Dest) then
    begin
      Result := E_POINTER;
      Exit;
    end;

    nameLen := sizeof(WCHAR) * (length(source)+1);
    Dest := CoTaskMemAlloc(nameLen);
    if (Dest = nil) then
    begin
      Result := E_OUTOFMEMORY;
      Exit;
    end;
    CopyMemory(Dest, PWideChar(Source), nameLen);
    Result := NOERROR;
  end;
{
  function AMGetWideString(Source: WideString; out Dest: PWideChar): HRESULT;
  type TWideCharArray = array of WideChar;
  var NameLen: Cardinal;
  begin
    if Source = '' then
      begin
        dest := nil;
        result := S_OK;
        exit;
      end;
    assert(@dest <> nil);
    nameLen := (length(Source)+1)*2;
    Dest := CoTaskMemAlloc(nameLen);
    if(Dest = nil) then
    begin
      result := E_OUTOFMEMORY;
      exit;
    end;
    CopyMemory(dest, pointer(Source), nameLen-1);
    TWideCharArray(dest)[(nameLen div 2)-1] := #0;
    result := NOERROR;
  end;
  }
// milenko end
// -----------------------------------------------------------------------------


function CreateMemoryAllocator(out Allocator: IMemAllocator): HRESULT;
begin
  result := CoCreateInstance(CLSID_MemoryAllocator, nil, CLSCTX_INPROC_SERVER,
    IID_IMemAllocator, Allocator);
end;

//  Put this one here rather than in ctlutil.cpp to avoid linking
//  anything brought in by ctlutil.cpp
function CreatePosPassThru(Agg: IUnknown; Renderer: boolean; Pin: IPin; out PassThru: IUnknown): HRESULT; stdcall;
var
  UnkSeek: IUnknown;
  APassThru: ISeekingPassThru;
begin
  PassThru := nil;

  result := CoCreateInstance(CLSID_SeekingPassThru, Agg, CLSCTX_INPROC_SERVER,
    IUnknown, UnkSeek);
  if FAILED(result) then exit;

  result := UnkSeek.QueryInterface(IID_ISeekingPassThru, APassThru);
  if FAILED(result) then
    begin
      UnkSeek := nil;
      exit;
    end;

  result := APassThru.Init(Renderer, Pin);
  APassThru := nil;
  if FAILED(result) then
    begin
      UnkSeek := nil;
      exit;
    end;

  PassThru := UnkSeek;
  result := S_OK;
end;

// -----------------------------------------------------------------------------

  function Templates: TBCFilterTemplate;
  begin
    if TemplatesVar = nil then TemplatesVar := TBCFilterTemplate.Create;
    result := TemplatesVar;
  end;

  function DllGetClassObject(const CLSID, IID: TGUID; var Obj): HResult; stdcall;
  var
    Factory: TBCClassFactory;
  begin
    Factory := Templates.GetFactoryFromClassID(CLSID);
    if Factory <> nil then
      if Factory.GetInterface(IID, Obj) then
        Result := S_OK
      else
        Result := E_NOINTERFACE
    else
    begin
      Pointer(Obj) := nil;
      Result := CLASS_E_CLASSNOTAVAILABLE;
    end;
  end;

  function DllCanUnloadNow: HResult; stdcall;
  begin
    if (ObjectCount = 0) and (FactoryCount = 0) then
      result := S_OK else result := S_FALSE;;
  end;

  function DllRegisterServer: HResult; stdcall;
  begin
    if Templates.RegisterServer(True) then result := S_OK else result := E_FAIL;
  end;

  function DllUnregisterServer: HResult; stdcall;
  begin
    if Templates.RegisterServer(false) then result := S_OK else result := E_FAIL;
  end;

{ TBCClassFactory }

constructor TBCClassFactory.CreateFilter(ComClass: TBCUnknownClass; Name: string;
  const ClassID: TGUID; const Category: TGUID; Merit: LongWord;
  PinCount: Cardinal; Pins: PRegFilterPins);
begin
  Templates.AddObjectFactory(Self);
  FComClass := ComClass;
  FName     := Name;
  FClassID  := ClassID;
  FCategory := Category;
  FMerit    := Merit;
  FPinCount := PinCount;
  FPins     := Pins;
end;

{$IFDEF WITH_PROPERTY_PAGE}
constructor TBCClassFactory.CreatePropertyPage(ComClass: TFormPropertyPageClass; const ClassID: TGUID);
begin
  Templates.AddObjectFactory(Self);
  FPropClass := ComClass;
  FClassID   := ClassID;
  FCategory := ClassID;
end;
{$ELSE}
constructor TBCClassFactory.CreatePropertyPage(ComClass: TBCBasePropertyPageClass; const ClassID: TGUID);
begin
  Templates.AddObjectFactory(Self);
  FPropClass := ComClass;
  FClassID   := ClassID;
  FCategory := ClassID;
end;
{$ENDIF}

function TBCClassFactory.CreateInstance(const unkOuter: IUnKnown;
  const iid: TIID; out obj): HResult;
var
  ComObject: TBCUnknown;
{$IFDEF WITH_PROPERTY_PAGE}
  PropObject: TFormPropertyPage;
{$ELSE}
  PropObject: TBCBasePropertyPage;
{$ENDIF}
begin
  if @obj = nil then
  begin
    Result := E_POINTER;
    Exit;
  end;
  Pointer(obj) := nil;
{$IFDEF WITH_PROPERTY_PAGE}
  if FPropClass <> nil then
    begin
      PropObject := TFormPropertyPageClass(FPropClass).Create(nil);
      PropObject.FPropertyPage := TBCBasePropertyPage.Create('',nil, PropObject);
      Result := PropObject.QueryInterface(IID, obj);
    end
  else
{$ELSE}
  if FPropClass <> nil then
    begin
      PropObject := TBCBasePropertyPageClass(FPropClass).CreateFromFactory(Self, unkOuter);
      Result := PropObject.QueryInterface(IID, obj);
      if PropObject.FRefCount = 0 then PropObject.Free;
    end
  else
{$ENDIF}
    begin
      ComObject := TBCUnknownClass(FComClass).CreateFromFactory(self, unkOuter);
      Result := ComObject.QueryInterface(IID, obj);
      if ComObject.FRefCount = 0 then ComObject.Free;
    end;
end;

procedure TBCClassFactory.UpdateRegistry(Register: Boolean);
var
  FileName: array[0..MAX_PATH-1] of Char;
  ClassID, ServerKeyName: String;
begin
  ClassID := GUIDToString(FClassID);
  ServerKeyName := 'CLSID\' + ClassID + '\' + 'InprocServer32';
  if Register then
  begin
    CreateRegKey('CLSID\' + ClassID, '', FName);
    GetModuleFileName(hinstance, FileName, MAX_PATH);
    CreateRegKey(ServerKeyName, '', FileName);
    CreateRegKey(ServerKeyName, 'ThreadingModel', 'Both');
  end else
  begin
    DeleteRegKey(ServerKeyName);
    DeleteRegKey('CLSID\' + ClassID);
  end;
end;

function TBCClassFactory.RegisterFilter(FilterMapper: IFilterMapper; Register: Boolean): boolean;
type
  TDynArrayPins = array of TRegFilterPins;
  TDynArrayPinType = array of TRegPinTypes;
var
  i, j: integer;
  FilterGUID: TGUID;
begin
  result := Succeeded(FilterMapper.UnregisterFilter(FClassID));
  if Register  then
  begin
    result := Succeeded(FilterMapper.RegisterFilter(FClassID, StringToOleStr(FName), FMerit));
    if result then
    begin
      for i := 0 to FPinCount - 1 do
      begin
        if TDynArrayPins(FPins)[i].oFilter = nil then
          FilterGUID := GUID_NULL else
          FilterGUID := TDynArrayPins(FPins)[i].oFilter^;
        result := Succeeded(FilterMapper.RegisterPin(FClassID,
          TDynArrayPins(FPins)[i].strName,
          TDynArrayPins(FPins)[i].bRendered,
          TDynArrayPins(FPins)[i].bOutput,
          TDynArrayPins(FPins)[i].bZero,
          TDynArrayPins(FPins)[i].bMany,
          FilterGUID,
          TDynArrayPins(FPins)[i].strConnectsToPin));
        if result then
        begin
          for j := 0 to TDynArrayPins(FPins)[i].nMediaTypes - 1 do
          begin
            result := Succeeded(FilterMapper.RegisterPinType(FClassID,
                        TDynArrayPins(FPins)[i].strName,
                        TDynArrayPinType(TDynArrayPins(FPins)[i].lpMediaType)[j].clsMajorType^,
                        TDynArrayPinType(TDynArrayPins(FPins)[i].lpMediaType)[j].clsMinorType^));
            if not result then break;
          end;
          if not result then break;
        end;
        if not result then break;
      end;
    end;
  end;
end;

function TBCClassFactory.RegisterFilter(FilterMapper: IFilterMapper2; Register: Boolean): boolean;
var
  RegFilter: TRegFilter2;
begin
  result := Succeeded(FilterMapper.UnregisterFilter(FCategory, nil, FClassID));
// milenko start (bugfix for Windows 98)
// Windows 98 fails when unregistering a Property Page, so the whole
// DLLUnregisterServer function fails without unregistering the Filter.
  if not result and not Register and (FName = '') then Result := True;
// milenko end
  if Register then
  begin
    RegFilter.dwVersion := 1;
    RegFilter.dwMerit   := FMerit;
    RegFilter.cPins     := FPinCount;
    RegFilter.rgPins    := FPins;
    result := Succeeded(FilterMapper.RegisterFilter(FClassID, PWideChar(WideString(FName)),
      nil, @FCategory, nil, RegFilter));
  end;
end;

function TBCClassFactory._AddRef: Integer;
begin
  result := InterlockedIncrement(FactoryCount);
end;

function TBCClassFactory._Release: Integer;
begin
  result := InterlockedDecrement(FactoryCount);
end;

function TBCClassFactory.LockServer(fLock: BOOL): HResult;
begin
  Result := CoLockObjectExternal(Self, fLock, True);
  if flock then InterlockedIncrement(ObjectCount)
           else InterlockedDecrement(ObjectCount);
end;

function TBCClassFactory.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if GetInterface(IID, Obj) then Result := S_OK else Result := E_NOINTERFACE;
end;

{ TBCFilterTemplate }

procedure TBCFilterTemplate.AddObjectFactory(Factory: TBCClassFactory);
begin
  Factory.FNext := FFactoryList;
  FFactoryList := Factory;
end;

constructor TBCFilterTemplate.Create;
begin
  FFactoryList := nil;
end;

destructor TBCFilterTemplate.Destroy;
var AFactory: TBCClassFactory;
begin
  while FFactoryList <> nil do
  begin
    AFactory := FFactoryList;
    FFactoryList := AFactory.FNext;
    AFactory.Free;
  end;
  inherited Destroy;
end;

function TBCFilterTemplate.GetFactoryFromClassID(const CLSID: TGUID): TBCClassFactory;
var AFactory: TBCClassFactory;
begin
  result := nil;
  AFactory := FFactoryList;
  while AFactory <> nil do
  begin
    if IsEqualGUID(CLSID, AFactory.FClassID) then
    begin
      result := AFactory;
      break;
    end;
    AFactory := AFactory.FNext;
  end;
end;

function TBCFilterTemplate.RegisterServer(Register: Boolean): boolean;
var
{$IFDEF _DEBUG}
  Filename: array[0..MAX_PATH-1] of Char;
{$ENDIF}
  FilterMapper : IFilterMapper;
  FilterMapper2: IFilterMapper2;
  Factory: TBCClassFactory;
begin
  result := false;
{$IFDEF _DEBUG}
  GetModuleFileName(hinstance, Filename, Length(Filename));
  DbgLog('TBCFilterTemplate.RegisterServer in ' + Filename);
{$ENDIF}
  CoInitialize(nil);
  try
    if Failed(CoCreateInstance(CLSID_FilterMapper2, nil, CLSCTX_INPROC_SERVER, IFilterMapper2, FilterMapper2)) then
    if Failed(CoCreateInstance(CLSID_FilterMapper, nil, CLSCTX_INPROC_SERVER, IFilterMapper, FilterMapper)) then exit;

    Factory := FFactoryList;
    while Factory <> nil do
    begin
      Factory.UpdateRegistry(false);
        if FilterMapper2 <> nil then
             result := Factory.RegisterFilter(FilterMapper2, Register)
        else result := Factory.RegisterFilter(FilterMapper, Register);
        if not result then break else Factory.UpdateRegistry(register);
      Factory := Factory.FNext;
    end;
    FilterMapper := nil;
    FilterMapper2 := nil;
  finally
    CoFreeUnusedLibraries;
    CoUninitialize;
  end;
end;

{ TBCBaseObject }

constructor TBCBaseObject.Create(Name: string);
begin
{$IFDEF _DEBUG}
  DbgLog('[' + ClassName + ': ' + Name + '] CREATE');
{$ENDIF}
  FName := name;
end;

destructor TBCBaseObject.Destroy;
begin
{$IFDEF _DEBUG}
  DbgLog('[' + ClassName + ': ' + FName + '] FREE');
{$ENDIF}
  inherited;
end;

procedure TBCBaseObject.FreeInstance;
begin
  inherited;
  InterlockedDecrement(ObjectCount);
end;

class function TBCBaseObject.NewInstance: TObject;
begin
  result := inherited NewInstance;
  InterlockedIncrement(ObjectCount);
end;

class function TBCBaseObject.ObjectsActive: integer;
begin
  result := ObjectCount;
end;

{ TBCUnknown }

function TBCUnknown.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if FOwner <> nil then
    Result := IUnknown(FOwner).QueryInterface(IID, Obj)
  else
    Result := NonDelegatingQueryInterface(IID, Obj);
end;

function TBCUnknown._AddRef: Integer;
begin
  if FOwner <> nil then
    Result := IUnknown(FOwner)._AddRef else
    Result := NonDelegatingAddRef;
end;

function TBCUnknown._Release: Integer;
begin
  if FOwner <> nil then
    Result := IUnknown(FOwner)._Release else
    Result := NonDelegatingRelease;
end;

function TBCUnknown.NonDelegatingQueryInterface(const IID: TGUID;
  out Obj): HResult;
begin
  if GetInterface(IID, Obj) then Result := S_OK else Result := E_NOINTERFACE;
end;

function TBCUnknown.NonDelegatingAddRef: Integer;
begin
  Result := InterlockedIncrement(FRefCount);
end;

function TBCUnknown.NonDelegatingRelease: Integer;
begin
  Result := InterlockedDecrement(FRefCount);
  if Result = 0 then Destroy;
end;

function TBCUnknown.GetOwner: IUnKnown;
begin
  result := IUnKnown(FOwner);
end;

constructor TBCUnknown.Create(name: string; Unk: IUnKnown);
begin
  inherited Create(name);
  FOwner := Pointer(Unk);
end;

constructor TBCUnknown.CreateFromFactory(Factory: TBCClassFactory;
  const Controller: IUnKnown);
begin
  Create(Factory.FName, Controller);
end;

{ TBCBaseFilter }

constructor TBCBaseFilter.Create(Name: string; Unk: IUnKnown;
  Lock: TBCCritSec; const clsid: TGUID);
begin
    inherited Create(Name, Unk);
    FLock  := Lock;
    Fclsid := clsid;
    FState := State_Stopped;
    FClock := nil;
    FGraph := nil;
    FSink  := nil;
    FFilterName := '';
    FPinVersion := 1;
    Assert(FLock <> nil, 'Lock = nil !');
end;

constructor TBCBaseFilter.Create(Name: string; Unk: IUnKnown;
  Lock: TBCCritSec; const clsid: TGUID; out hr: HRESULT);
begin
  Create(Name, Unk, Lock, clsid);
  assert(@hr <> nil, 'Unreferenced parameter: hr');
end;

constructor TBCBaseFilter.CreateFromFactory(Factory: TBCClassFactory; const Controller: IUnknown);
begin
  Create(Factory.FName,Controller, TBCCritSec.Create, Factory.FClassID);
end;

destructor TBCBaseFilter.destroy;
begin
  FFilterName := '';
  FClock := nil;
  FLock.Free;
  inherited;
end;

function TBCBaseFilter.EnumPins(out ppEnum: IEnumPins): HRESULT;
begin
  // Create a new ref counted enumerator
  ppEnum := TBCEnumPins.Create(self, nil);
  if ppEnum = nil then result := E_OUTOFMEMORY else result := NOERROR;
end;

function TBCBaseFilter.FindPin(Id: PWideChar; out Pin: IPin): HRESULT;
var
  i: integer;
  APin: TBCBasePin;
begin
  //  We're going to search the pin list so maintain integrity
  FLock.Lock;
  try
    for i := 0 to GetPinCount - 1 do
    begin
      APin := GetPin(i);
      ASSERT(APin <> nil);
      if (APin.FPinName = WideString(Id)) then
      begin
          //  Found one that matches
          //  AddRef() and return it
          Pin := APin;
          result := S_OK;
          exit;
      end;
    end;
    Pin := nil;
    result := VFW_E_NOT_FOUND;
  finally
    FLock.UnLock;
  end;
end;

function TBCBaseFilter.GetClassID(out classID: TCLSID): HResult;
begin
  classID := FCLSID;
  result  := NOERROR;
end;

function TBCBaseFilter.GetFilterGraph: IFilterGraph;
begin
  result := FGRaph;
end;

function TBCBaseFilter.GetPinVersion: LongInt;
begin
  result := FPinVersion;
end;

function TBCBaseFilter.GetState(dwMilliSecsTimeout: DWORD;
  out State: TFilterState): HRESULT;
begin
  State := FState;
  result := S_OK;
end;

function TBCBaseFilter.GetSyncSource(out pClock: IReferenceClock): HRESULT;
begin
  FLock.Lock;
  try
    pClock := FClock;
  finally
    result := NOERROR;
    FLock.UnLock;
  end;
end;

procedure TBCBaseFilter.IncrementPinVersion;
begin
  InterlockedIncrement(FPinVersion)
end;

function TBCBaseFilter.IsActive: boolean;
begin
  FLock.Lock;
  try
    result :=  ((FState = State_Paused) or (FState = State_Running));
  finally
    FLock.UnLock;
  end;
end;

function TBCBaseFilter.IsStopped: boolean;
begin
  result := (FState = State_Stopped);
end;

function TBCBaseFilter.JoinFilterGraph(pGraph: IFilterGraph;
  pName: PWideChar): HRESULT;
begin
  FLock.Lock;
  try
    //Henri: This implementation seem to be stupid but it's the exact conversion ?????
    // NOTE: we no longer hold references on the graph (m_pGraph, m_pSink)
    Pointer(FGraph) := Pointer(pGraph);
    if (FGraph <> nil) then
    begin
      if FAILED(FGraph.QueryInterface(IID_IMediaEventSink, FSink)) then
           ASSERT(FSink = nil)
      else FSink._Release;        // we do NOT keep a reference on it.
    end
    else
    begin
        // if graph pointer is null, then we should
        // also release the IMediaEventSink on the same object - we don't
        // refcount it, so just set it to null
        Pointer(FSink) := nil;
    end;

    FFilterName := '';
    if assigned(pName) then FFilterName := WideString(pName);
    result := NOERROR;
  finally
    FLock.UnLock;
  end;
end;

function TBCBaseFilter.NotifyEvent(EventCode, EventParam1,
  EventParam2: Integer): HRESULT;
var
  Filter : IBaseFilter;
begin
  // Snapshot so we don't have to lock up
  if assigned(FSink) then
  begin
    QueryInterface(IID_IBaseFilter,Filter);
    if (EC_COMPLETE = EventCode) then EventParam2 := LongInt(Filter);
    result := FSink.Notify(EventCode, EventParam1, EventParam2);
    Filter := nil;
  end
  else
    result := E_NOTIMPL;
end;

function TBCBaseFilter.Pause: HRESULT;
var
  c: integer;
  pin: TBCBasePin;
begin
  FLock.Lock;
  try
    if FState = State_Stopped then
    begin
      for c := 0 to GetPinCount - 1 do
      begin
        Pin := GetPin(c);
        // Disconnected pins are not activated - this saves pins
        // worrying about this state themselves
        if Pin.IsConnected then
        begin
          result := Pin.Active;
          if FAILED(result) then exit;
        end;
      end;
    end;
    // notify all pins of the change to active state
    FState := State_Paused;
    result := S_OK;
  finally
    FLock.UnLock;
  end;
end;

function TBCBaseFilter.QueryFilterInfo(out pInfo: TFilterInfo): HRESULT;
var
  len: Integer;
begin
  len := Length(pInfo.achName)-1;
  if (Length(FFilterName) > 0) then
    if (Length(FFilterName) > len) then
    begin
      CopyMemory(@pInfo.achName, PWideChar(FFilterName), len * SizeOf(WCHAR));
      pInfo.achName[len] := #0;
    end
    else
      CopyMemory(@pInfo.achName, PWideChar(FFilterName), (Length(FFilterName)+1) * SizeOf(WCHAR))
  else
    pInfo.achName[0] := #0;
  pInfo.pGraph := FGraph;
  result := NOERROR;
end;

function TBCBaseFilter.QueryVendorInfo(out pVendorInfo: PWideChar): HRESULT;
begin
  result := E_NOTIMPL;
end;

function TBCBaseFilter.ReconnectPin(Pin: IPin; pmt: PAMMediaType): HRESULT;
var Graph2: IFilterGraph2;
begin
  if (FGraph <> nil) then
    begin
      result := FGraph.QueryInterface(IID_IFilterGraph2, Graph2);
      if Succeeded(result) then
        begin
          result := Graph2.ReconnectEx(Pin, pmt);
          Graph2 := nil;
        end
      else
        result := FGraph.Reconnect(Pin);
    end
  else
    result := E_NOINTERFACE;
end;

function TBCBaseFilter.Register: HRESULT;
var
  {$IFDEF _DEBUG}
    Filename: array[0..MAX_PATH-1] of Char;
  {$ENDIF}
  FilterMapper : IFilterMapper;
  FilterMapper2: IFilterMapper2;
  Factory: TBCClassFactory;
  AResult : boolean;
begin
  CoInitialize(nil);
  try
    Aresult := false;
    Result := S_FALSE;
    Factory := Templates.GetFactoryFromClassID(FCLSID);
    if Factory <> nil then
    begin
    {$IFDEF _DEBUG}
      GetModuleFileName(hinstance, Filename, Length(Filename));
      DbgLog(Self,'Register in ' + Filename);
    {$ENDIF}
      if Failed(CoCreateInstance(CLSID_FilterMapper2, nil, CLSCTX_INPROC_SERVER, IFilterMapper2, FilterMapper2)) then
      if Failed(CoCreateInstance(CLSID_FilterMapper, nil, CLSCTX_INPROC_SERVER, IFilterMapper, FilterMapper)) then exit;
      Factory.UpdateRegistry(false);
      if FilterMapper2 <> nil then
           AResult := Factory.RegisterFilter(FilterMapper2, True)
      else AResult := Factory.RegisterFilter(FilterMapper, True);
      if Aresult then Factory.UpdateRegistry(True);
      FilterMapper := nil;
      FilterMapper2 := nil;
    end;
    if AResult then result := S_OK else result := S_False;
  finally
    CoFreeUnusedLibraries;
    CoUninitialize;
  end;
end;

function TBCBaseFilter.Run(tStart: TReferenceTime): HRESULT;
var
  c: integer;
  Pin: TBCBasePin;
begin
  FLock.Lock;
  try
    // remember the stream time offset
    FStart := tStart;
    if FState = State_Stopped then
    begin
      result := Pause;
      if FAILED(result) then exit;
    end;
    // notify all pins of the change to active state
    if (FState <> State_Running) then
    begin
      for c := 0 to GetPinCount - 1 do
      begin
        Pin := GetPin(c);
        // Disconnected pins are not activated - this saves pins
        // worrying about this state themselves
        if Pin.IsConnected then
        begin
          result := Pin.Run(tStart);
          if FAILED(result) then exit;
        end;
      end;
    end;
    FState := State_Running;
    result := S_OK;
  finally
    FLock.UnLock;
  end;
end;

function TBCBaseFilter.SetSyncSource(pClock: IReferenceClock): HRESULT;
begin
  FLock.Lock;
  try
    FClock := pClock;
  finally
    result := NOERROR;
    FLock.UnLock;
  end;
end;

function TBCBaseFilter.Stop: HRESULT;
var
  c: integer;
  Pin: TBCBasePin;
  hr: HResult;
begin
  FLock.Lock;
  try
    result := NOERROR;
    // notify all pins of the state change
    if (FState <> State_Stopped) then
    begin
      for c := 0 to GetPinCount - 1 do
      begin
        Pin := GetPin(c);
        // Disconnected pins are not activated - this saves pins worrying
        // about this state themselves. We ignore the return code to make
        // sure everyone is inactivated regardless. The base input pin
        // class can return an error if it has no allocator but Stop can
        // be used to resync the graph state after something has gone bad
        if Pin.IsConnected then
        begin
          hr := Pin.Inactive;
          if (Failed(hr) and SUCCEEDED(result)) then result := hr;
        end;
      end;
    end;
    FState := State_Stopped;
  finally
    FLock.UnLock;
  end;
end;

function TBCBaseFilter.StreamTime(out rtStream: TReferenceTime): HRESULT;
begin
  // Caller must lock for synchronization
  // We can't grab the filter lock because we want to be able to call
  // this from worker threads without deadlocking
  if FClock = nil then
  begin
    result := VFW_E_NO_CLOCK;
    exit;
  end;
  // get the current reference time
  result := FClock.GetTime(PInt64(@rtStream)^);
  if FAILED(result) then exit;
  // subtract the stream offset to get stream time
  rtStream := rtStream - FStart;
  result := S_OK;
end;

function TBCBaseFilter.Unregister: HRESULT;
var
  {$IFDEF _DEBUG}
    Filename: array[0..MAX_PATH-1] of Char;
  {$ENDIF}
  FilterMapper : IFilterMapper;
  FilterMapper2: IFilterMapper2;
  Factory: TBCClassFactory;
  AResult : boolean;
begin
  CoInitialize(nil);
  try
    Aresult := false;
    Result := S_FALSE;
    Factory := Templates.GetFactoryFromClassID(FCLSID);
    if Factory <> nil then
    begin
    {$IFDEF _DEBUG}
      GetModuleFileName(hinstance, Filename, Length(Filename));
      DbgLog(Self,'Unregister in ' + Filename);
    {$ENDIF}
      if Failed(CoCreateInstance(CLSID_FilterMapper2, nil, CLSCTX_INPROC_SERVER, IFilterMapper2, FilterMapper2)) then
      if Failed(CoCreateInstance(CLSID_FilterMapper, nil, CLSCTX_INPROC_SERVER, IFilterMapper, FilterMapper)) then exit;
      Factory.UpdateRegistry(false);
      if FilterMapper2 <> nil then
           AResult := Factory.RegisterFilter(FilterMapper2, false)
      else AResult := Factory.RegisterFilter(FilterMapper, false);
      if Aresult then Factory.UpdateRegistry(false);
      FilterMapper := nil;
      FilterMapper2 := nil;
    end;
    if AResult then result := S_OK else result := S_False;
  finally
    CoFreeUnusedLibraries;
    CoUninitialize;
  end;
end;

{ TBCEnumPins }

constructor TBCEnumPins.Create(Filter: TBCBaseFilter; EnumPins: TBCEnumPins);
var i: integer;
begin
  FPosition := 0;
  FPinCount := 0;
  FFilter   := Filter;
  FPinCache := TList.Create;

  // We must be owned by a filter derived from CBaseFilter
  ASSERT(FFilter <> nil);

  // Hold a reference count on our filter
  FFilter._AddRef;

  // Are we creating a new enumerator
  if (EnumPins = nil) then
    begin
      FVersion  := FFilter.GetPinVersion;
      FPinCount := FFilter.GetPinCount;
    end
  else
    begin
      ASSERT(FPosition <= FPinCount);
      FPosition := EnumPins.FPosition;
      FPinCount := EnumPins.FPinCount;
      FVersion  := EnumPins.FVersion;
      FPinCache.Clear;
      if EnumPins.FPinCache.Count > 0 then
        for i := 0 to EnumPins.FPinCache.Count - 1 do
          FPinCache.Add(EnumPins.FPinCache.Items[i]);
    end;
end;

destructor TBCEnumPins.Destroy;
begin
  FPinCache.Free;
  FFilter._Release;
  inherited Destroy;
end;

function TBCEnumPins.Clone(out ppEnum: IEnumPins): HRESULT;
begin
  result := NOERROR;
  // Check we are still in sync with the filter
  if AreWeOutOfSync then
    begin
      ppEnum := nil;
      result := VFW_E_ENUM_OUT_OF_SYNC;
    end
  else
  begin
    ppEnum := TBCEnumPins.Create(FFilter, self);
    if ppEnum = nil then result := E_OUTOFMEMORY;
  end;
end;

function TBCEnumPins.Next(cPins: ULONG; out ppPins: IPin;
  pcFetched: PULONG): HRESULT;
type
  TPointerDynArray = array of Pointer;
  TIPinDynArray = array of IPin;
var
  Fetched: cardinal;
  RealPins: integer;
  Pin: TBCBasePin;
begin
    if pcFetched <> nil then
      pcFetched^ := 0
    else
      if (cPins>1) then
      begin
        result := E_INVALIDARG;
        exit;
      end;
    Fetched := 0; // increment as we get each one.

    // Check we are still in sync with the filter
    // If we are out of sync, we should refresh the enumerator.
    // This will reset the position and update the other members, but
    // will not clear cache of pins we have already returned.
    if AreWeOutOfSync then
      Refresh;

    // Calculate the number of available pins
    RealPins := min(FPinCount - FPosition, cPins);
    if RealPins = 0 then
    begin
      result := S_FALSE;
      exit;
    end;

    {  Return each pin interface NOTE GetPin returns CBasePin * not addrefed
       so we must QI for the IPin (which increments its reference count)
       If while we are retrieving a pin from the filter an error occurs we
       assume that our internal state is stale with respect to the filter
       (for example someone has deleted a pin) so we
       return VFW_E_ENUM_OUT_OF_SYNC }

    while RealPins > 0 do
    begin
      // Get the next pin object from the filter */
      inc(FPosition);
      Pin := FFilter.GetPin(FPosition-1);
      if Pin = nil then
      begin
        // If this happend, and it's not the first time through, then we've got a problem,
        // since we should really go back and release the iPins, which we have previously
        // AddRef'ed.
        ASSERT(Fetched = 0);
        result := VFW_E_ENUM_OUT_OF_SYNC;
        exit;
      end;

      // We only want to return this pin, if it is not in our cache
      if FPinCache.IndexOf(Pin) = -1 then
      begin
        // From the object get an IPin interface
        TPointerDynArray(@ppPins)[Fetched] := nil;
        TIPinDynArray(@ppPins)[Fetched] := Pin;
        inc(Fetched);
        FPinCache.Add(Pin);
        dec(RealPins);
      end;
    end;

    if (pcFetched <> nil) then pcFetched^ := Fetched;

    if (cPins = Fetched) then result := NOERROR else result := S_FALSE;
end;

function TBCEnumPins.Skip(cPins: ULONG): HRESULT;
var PinsLeft: Cardinal;
begin
  // Check we are still in sync with the filter
  if AreWeOutOfSync then
  begin
    result := VFW_E_ENUM_OUT_OF_SYNC;
    exit;
  end;

  // Work out how many pins are left to skip over
  // We could position at the end if we are asked to skip too many...
  // ..which would match the base implementation for CEnumMediaTypes::Skip

  PinsLeft := FPinCount - FPosition;
  if (cPins > PinsLeft) then
  begin
    result := S_FALSE;
    exit;
  end;

  inc(FPosition, cPins);
  result := NOERROR;
end;

function TBCEnumPins.Reset: HRESULT;
begin
  FVersion  := FFilter.GetPinVersion;
  FPinCount := FFilter.GetPinCount;
  FPosition := 0;
  FPinCache.Clear;
  result := S_OK;
end;

function TBCEnumPins.Refresh: HRESULT;
begin
  FVersion  := FFilter.GetPinVersion;
  FPinCount := FFilter.GetPinCount;
  Fposition := 0;
  result    := S_OK;
end;

function TBCEnumPins.AreWeOutOfSync: boolean;
begin
  if FFilter.GetPinVersion = FVersion then result:= FALSE else result := True;
end;

{ TBCBasePin }

{ Called by IMediaFilter implementation when the state changes from Stopped
  to either paused or running and in derived classes could do things like
  commit memory and grab hardware resource (the default is to do nothing) }

function TBCBasePin.Active: HRESULT;
begin
  result := NOERROR;
end;

{ This is called to make the connection, including the task of finding
  a media type for the pin connection. pmt is the proposed media type
  from the Connect call: if this is fully specified, we will try that.
  Otherwise we enumerate and try all the input pin's types first and
  if that fails we then enumerate and try all our preferred media types.
  For each media type we check it against pmt (if non-null and partially
  specified) as well as checking that both pins will accept it. }

function TBCBasePin.AgreeMediaType(ReceivePin: IPin; pmt: PAMMediaType): HRESULT;
var
  EnumMT: IEnumMediaTypes;
  hrFailure: HResult;
  i: integer;
begin
  ASSERT(ReceivePin <> nil);

  // if the media type is fully specified then use that
  if ((pmt <> nil) and (not TBCMediaType(pmt).IsPartiallySpecified)) then
  begin
    // if this media type fails, then we must fail the connection
    // since if pmt is nonnull we are only allowed to connect
    // using a type that matches it.
    result := AttemptConnection(ReceivePin, pmt);
    exit;
  end;


  // Try the other pin's enumerator
  hrFailure := VFW_E_NO_ACCEPTABLE_TYPES;
  for i := 0 to 1 do
  begin
    if (i = byte(FTryMyTypesFirst)) then
         result := ReceivePin.EnumMediaTypes(EnumMT)
    else result := EnumMediaTypes(EnumMT);

    if Succeeded(Result) then
    begin
      Assert(EnumMT <> nil);
      result := TryMediaTypes(ReceivePin,pmt,EnumMT);
      EnumMT := nil;
      if Succeeded(result) then
        begin
          result := NOERROR;
          exit;
        end
      else
        begin
          // try to remember specific error codes if there are any
          if ((result <> E_FAIL) and
              (result <> E_INVALIDARG) and
              (result <> VFW_E_TYPE_NOT_ACCEPTED)) then hrFailure := result;
        end;
    end;
  end;
  result := hrFailure;
end;

function TBCBasePin.AttemptConnection(ReceivePin: IPin; pmt: PAMMediaType): HRESULT;
begin

  // The caller should hold the filter lock becasue this function
  // uses m_Connected.  The caller should also hold the filter lock
  // because this function calls SetMediaType(), IsStopped() and
  // CompleteConnect().
  ASSERT(FLock.CritCheckIn);

  // Check that the connection is valid  -- need to do this for every
  // connect attempt since BreakConnect will undo it.
  result := CheckConnect(ReceivePin);
  if FAILED(result) then
  begin
  {$IFDEF _DEBUG}
    DbgLog(self, 'CheckConnect failed');
  {$ENDIF}
    // Since the procedure is already returning an error code, there
    // is nothing else this function can do to report the error.
  {$IFOPT C+}
    Assert(SUCCEEDED(BreakConnect));
  {$ELSE}
    BreakConnect;
  {$ENDIF}

    exit;
  end;

  DisplayTypeInfo(ReceivePin, pmt);

  // Check we will accept this media type

  result := CheckMediaType(pmt);
  if (result = NOERROR) then
    begin
      // Make ourselves look connected otherwise ReceiveConnection
      // may not be able to complete the connection
      FConnected := ReceivePin;
      result := SetMediaType(pmt);
      if Succeeded(result) then
      begin
        // See if the other pin will accept this type */
        result := ReceivePin.ReceiveConnection(self, pmt^);
        if Succeeded(result) then
        begin
          // Complete the connection
          result := CompleteConnect(ReceivePin);
          if Succeeded(result) then exit
          else
            begin
            {$IFDEF _DEBUG}
              DbgLog(self, 'Failed to complete connection');
            {$ENDIF}
              ReceivePin.Disconnect;
            end;
        end;
      end;
    end
  else
    begin
      // we cannot use this media type
      // return a specific media type error if there is one
      // or map a general failure code to something more helpful
      // (in particular S_FALSE gets changed to an error code)
      if (SUCCEEDED(result) or (result = E_FAIL) or (result = E_INVALIDARG)) then
        result := VFW_E_TYPE_NOT_ACCEPTED;
    end;

  // BreakConnect and release any connection here in case CheckMediaType
  // failed, or if we set anything up during a call back during
  // ReceiveConnection.

  // Since the procedure is already returning an error code, there
  // is nothing else this function can do to report the error.
{$IFOPT C+}
  Assert(SUCCEEDED(BreakConnect));
{$ELSE}
  BreakConnect;
{$ENDIF}

  //  If failed then undo our state
  FConnected := nil;
end;

{ This is called when we realise we can't make a connection to the pin and
  must undo anything we did in CheckConnect - override to release QIs done }

function TBCBasePin.BreakConnect: HRESULT;
begin
  result := NOERROR;
end;

{ This is called during Connect() to provide a virtual method that can do
  any specific check needed for connection such as QueryInterface. This
  base class method just checks that the pin directions don't match }

function TBCBasePin.CheckConnect(Pin: IPin): HRESULT;
var pd: TPinDirection;
begin
  // Check that pin directions DONT match
  Pin.QueryDirection(pd);
  ASSERT((pd = PINDIR_OUTPUT) or (pd = PINDIR_INPUT));
  ASSERT((Fdir = PINDIR_OUTPUT) or (Fdir = PINDIR_INPUT));

  // we should allow for non-input and non-output connections?
  if (pd = Fdir) then result := VFW_E_INVALID_DIRECTION
                 else result := NOERROR;
end;

{ Called when we want to complete a connection to another filter. Failing
  this will also fail the connection and disconnect the other pin as well }

function TBCBasePin.CompleteConnect(ReceivePin: IPin): HRESULT;
begin
  result := NOERROR;
end;

 { Asked to connect to a pin. A pin is always attached to an owning filter
   object so we always delegate our locking to that object. We first of all
   retrieve a media type enumerator for the input pin and see if we accept
   any of the formats that it would ideally like, failing that we retrieve
   our enumerator and see if it will accept any of our preferred types }

function TBCBasePin.Connect(pReceivePin: IPin; const pmt: PAMMediaType): HRESULT;
var
  HR: HResult;
begin
  FLock.Lock;
  try
    DisplayPinInfo(pReceivePin);
    // See if we are already connected
    if FConnected <> nil then
    begin
    {$IFDEF _DEBUG}
      DbgLog(self, 'Already connected');
    {$ENDIF}
      result := VFW_E_ALREADY_CONNECTED;
// milenko start
      Exit;
// milenko end
    end;

    // See if the filter is active
    if (not IsStopped) and (not FCanReconnectWhenActive) then
    begin
      result := VFW_E_NOT_STOPPED;
      exit;
    end;

    // Find a mutually agreeable media type -
    // Pass in the template media type. If this is partially specified,
    // each of the enumerated media types will need to be checked against
    // it. If it is non-null and fully specified, we will just try to connect
    // with this.
    Hr := AgreeMediaType(pReceivePin, pmt);
    if Failed(hr) then
    begin
    {$IFDEF _DEBUG}
      DbgLog(self, 'Failed to agree type');
    {$ENDIF}
      // Since the procedure is already returning an error code, there
      // is nothing else this function can do to report the error.
    {$IFOPT C+}
      ASSERT(SUCCEEDED(BreakConnect));
    {$ELSE}
      BreakConnect;
    {$ENDIF}
      result := HR;
      exit;
    end;
  {$IFDEF _DEBUG}
    DbgLog(self, 'Connection succeeded');
  {$ENDIF}
    result := NOERROR;
  finally
    FLock.UnLock;
  end;
end;

// Return an AddRef()'d pointer to the connected pin if there is one

function TBCBasePin.ConnectedTo(out pPin: IPin): HRESULT;
begin
    //  It's pointless to lock here.
    //  The caller should ensure integrity.
    pPin := FConnected;
    if (pPin <> nil) then
         result := S_OK
    else result := VFW_E_NOT_CONNECTED;
end;

function TBCBasePin.ConnectionMediaType(out pmt: TAMMediaType): HRESULT;
begin
  FLock.Lock;
  try
    //  Copy constructor of m_mt allocates the memory
    if IsConnected then
      begin
        CopyMediaType(@pmt,@Fmt);
        result := S_OK;
      end
    else
      begin
        zeromemory(@pmt, SizeOf(TAMMediaType));
        pmt.lSampleSize := 1;
        pmt.bFixedSizeSamples := True;
        result := VFW_E_NOT_CONNECTED;
      end;
  finally

    FLock.UnLock;
  end;
end;

constructor TBCBasePin.Create(ObjectName: string; Filter: TBCBaseFilter;
  Lock: TBCCritSec; out hr: HRESULT; Name: WideString;
  dir: TPinDirection);
begin
  inherited Create(ObjectName, nil);
  FFilter                 := Filter;
  FLock                   := Lock;
  FPinName                := Name;
  FConnected              := nil;
  Fdir                    := dir;
  FRunTimeError           := FALSE;
  FQSink                  := nil;
  FTypeVersion            := 1;
  FStart                  := 0;
  FStop                   := MAX_TIME;
  FCanReconnectWhenActive := false;
  FTryMyTypesFirst        := false;
  FRate                   := 1.0;
  { WARNING - Filter is often not a properly constituted object at
    this state (in particular QueryInterface may not work) - this
    is because its owner is often its containing object and we
    have been called from the containing object's constructor so
    the filter's owner has not yet had its CUnknown constructor
    called.}

  FRef := 0; // debug
  ZeroMemory(@fmt, SizeOf(TAMMediaType));
  ASSERT(Filter <> nil);
  ASSERT(Lock <> nil);
end;

destructor TBCBasePin.destroy;
begin
  //  We don't call disconnect because if the filter is going away
  //  all the pins must have a reference count of zero so they must
  //  have been disconnected anyway - (but check the assumption)
  ASSERT(FConnected = nil);
  FPinName := '';
  Assert(FRef = 0);
  FreeMediaType(@fmt);
  inherited Destroy;
end;

// Called when we want to terminate a pin connection

function TBCBasePin.Disconnect: HRESULT;
begin
  FLock.Lock;
  try
    // See if the filter is active
    if not IsStopped then
         result := VFW_E_NOT_STOPPED
    else result := DisconnectInternal;
  finally
    FLock.UnLock;
  end;
end;

function TBCBasePin.DisconnectInternal: HRESULT;
begin
  ASSERT(FLock.CritCheckIn);
  if (FConnected <> nil) then
    begin
      result := BreakConnect;
      if FAILED(result) then
      begin
        // There is usually a bug in the program if BreakConnect() fails.
      {$IFDEF _DEBUG}
        DbgLog(self, 'WARNING: BreakConnect() failed in CBasePin::Disconnect().');
      {$ENDIF}
        exit;
      end;
      FConnected := nil;
      result := S_OK;
      exit;
    end
  else
    // no connection - not an error
    result := S_FALSE;
end;

procedure TBCBasePin.DisplayPinInfo(ReceivePin: IPin);
{$IFDEF _DEBUG}
const
  BadPin : WideString = 'Bad Pin';
var
  ConnectPinInfo, ReceivePinInfo: TPinInfo;
begin
  if FAILED(QueryPinInfo(ConnectPinInfo)) then
       move(Pointer(BadPin)^, ConnectPinInfo.achName, length(BadPin) * 2 +2)
  else ConnectPinInfo.pFilter := nil;
  if FAILED(ReceivePin.QueryPinInfo(ReceivePinInfo)) then
        move(Pointer(BadPin)^, ReceivePinInfo.achName, length(BadPin) * 2 +2)
   else ReceivePinInfo.pFilter := nil;
  DbgLog(self, 'Trying to connect Pins :');
  DbgLog(self, format('    <%s>', [ConnectPinInfo.achName]));
  DbgLog(self, format('    <%s>', [ReceivePinInfo.achName]));
{$ELSE}
begin
{$ENDIF}
end;

procedure TBCBasePin.DisplayTypeInfo(Pin: IPin; pmt: PAMMediaType);
begin
{$IFDEF _DEBUG}
  DbgLog(self, 'Trying media type:');
  DbgLog(self, '    major type:  '+ GuidToString(pmt.majortype));
  DbgLog(self, '    sub type  :  '+ GuidToString(pmt.subtype));
  DbgLog(self, GetMediaTypeDescription(pmt));  
{$ENDIF}
end;

// Called when no more data will arrive

function TBCBasePin.EndOfStream: HRESULT;
begin
  result := S_OK;
end;

{ This can be called to return an enumerator for the pin's list of preferred
  media types. An input pin is not obliged to have any preferred formats
  although it can do. For example, the window renderer has a preferred type
  which describes a video image that matches the current window size. All
  output pins should expose at least one preferred format otherwise it is
  possible that neither pin has any types and so no connection is possible }

function TBCBasePin.EnumMediaTypes(out ppEnum: IEnumMediaTypes): HRESULT;
begin
  // Create a new ref counted enumerator
  ppEnum := TBCEnumMediaTypes.Create(self, nil);
  if (ppEnum = nil) then result := E_OUTOFMEMORY
                    else result := NOERROR;
end;


{ This is a virtual function that returns a media type corresponding with
  place iPosition in the list. This base class simply returns an error as
  we support no media types by default but derived classes should override }

function TBCBasePin.GetMediaType(Position: integer;
  out MediaType: PAMMediaType): HRESULT;
begin
  result := E_UNEXPECTED;;
end;


{ This is a virtual function that returns the current media type version.
  The base class initialises the media type enumerators with the value 1
  By default we always returns that same value. A Derived class may change
  the list of media types available and after doing so it should increment
  the version either in a method derived from this, or more simply by just
  incrementing the m_TypeVersion base pin variable. The type enumerators
  call this when they want to see if their enumerations are out of date }

function TBCBasePin.GetMediaTypeVersion: longint;
begin
  result := FTypeVersion;
end;

{ Also called by the IMediaFilter implementation when the state changes to
  Stopped at which point you should decommit allocators and free hardware
  resources you grabbed in the Active call (default is also to do nothing) }

function TBCBasePin.Inactive: HRESULT;
begin
  FRunTimeError := FALSE;
  result := NOERROR;
end;

// Increment the cookie representing the current media type version

procedure TBCBasePin.IncrementTypeVersion;
begin
  InterlockedIncrement(FTypeVersion);
end;

function TBCBasePin.IsConnected: boolean;
begin
  result := FConnected <> nil;
end;

function TBCBasePin.IsStopped: boolean;
begin
  result := FFilter.FState = State_Stopped;
end;

// NewSegment notifies of the start/stop/rate applying to the data
// about to be received. Default implementation records data and
// returns S_OK.
// Override this to pass downstream.

function TBCBasePin.NewSegment(tStart, tStop: TReferenceTime;
  dRate: double): HRESULT;
begin
  FStart := tStart;
  FStop  := tStop;
  FRate  := dRate;
  result := S_OK;
end;

function TBCBasePin.NonDelegatingAddRef: Integer;
begin
{$IFOPT C+}
  Result := InterlockedIncrement(FRef);
  ASSERT(Result > 0);
{$ELSE}
  InterlockedIncrement(FRef);
{$ENDIF}
  Result := FFilter._AddRef;
end;

function TBCBasePin.NonDelegatingRelease: Integer;
begin
{$IFOPT C+}
  Result := InterlockedDecrement(FRef);
  ASSERT(Result >= 0);
{$ELSE}
  InterlockedDecrement(FRef);
{$ENDIF}
  Result := FFilter._Release
end;

function TBCBasePin.Notify(pSelf: IBaseFilter; q: TQuality): HRESULT;
begin
  {$IFDEF _DEBUG}
    DbgLog(self, 'IQualityControl::Notify not over-ridden from CBasePin.  (IGNORE is OK)');
  {$ENDIF}
    result := E_NOTIMPL;
end;

{ Does this pin support this media type WARNING this interface function does
  not lock the main object as it is meant to be asynchronous by nature - if
  the media types you support depend on some internal state that is updated
  dynamically then you will need to implement locking in a derived class }

function TBCBasePin.QueryAccept(const pmt: TAMMediaType): HRESULT;
begin
  { The CheckMediaType method is valid to return error codes if the media
    type is horrible, an example might be E_INVALIDARG. What we do here
    is map all the error codes into either S_OK or S_FALSE regardless }
  result := CheckMediaType(@pmt);
  if FAILED(result) then result := S_FALSE;
end;

function TBCBasePin.QueryDirection(out pPinDir: TPinDirection): HRESULT;
begin
  pPinDir := Fdir;
  result  := NOERROR;
end;

function TBCBasePin.QueryId(out Id: PWideChar): HRESULT;
begin
  result := AMGetWideString(FPinName, id);
end;

function TBCBasePin.QueryInternalConnections(out apPin: IPin;
  var nPin: ULONG): HRESULT;
begin
  result := E_NOTIMPL;
end;

// Return information about the filter we are connect to

function TBCBasePin.QueryPinInfo(out pInfo: TPinInfo): HRESULT;
begin
  pInfo.pFilter := FFilter;
  if (FPinName <> '') then
    begin
       move(Pointer(FPinName)^, pInfo.achName, length(FPinName)*2);
       pInfo.achName[length(FPinName)] := #0;
    end
  else pInfo.achName[0] := #0;
  pInfo.dir := Fdir;
  result := NOERROR;
end;

{ Called normally by an output pin on an input pin to try and establish a
  connection. }

function TBCBasePin.ReceiveConnection(pConnector: IPin;
  const pmt: TAMMediaType): HRESULT;
begin
  FLock.Lock;
  try
    // Are we already connected
    if (FConnected <> nil) then
    begin
      result := VFW_E_ALREADY_CONNECTED;
      exit;
    end;

    // See if the filter is active
    if (not IsStopped) and (not FCanReconnectWhenActive) then
    begin
      result := VFW_E_NOT_STOPPED;
      exit;
    end;

    result := CheckConnect(pConnector);
    if FAILED(result) then
    begin
      // Since the procedure is already returning an error code, there
      // is nothing else this function can do to report the error.
    {$IFOPT C+}
      ASSERT(SUCCEEDED(BreakConnect));
    {$ELSE}
      BreakConnect;
    {$ENDIF}
      exit;
    end;

    // Ask derived class if this media type is ok

    //CMediaType * pcmt = (CMediaType*) pmt;
    result := CheckMediaType(@pmt);
    if (result <> NOERROR) then
    begin
      // no -we don't support this media type
      // Since the procedure is already returning an error code, there
      // is nothing else this function can do to report the error.
    {$IFOPT C+}
      ASSERT(SUCCEEDED(BreakConnect));
    {$ELSE}
      BreakConnect;
    {$ENDIF}
      // return a specific media type error if there is one
      // or map a general failure code to something more helpful
      // (in particular S_FALSE gets changed to an error code)
      if (SUCCEEDED(result) or
          (result = E_FAIL) or
          (result = E_INVALIDARG)) then
        result := VFW_E_TYPE_NOT_ACCEPTED;
      exit;
    end;

    // Complete the connection
    FConnected := pConnector;
    result := SetMediaType(@pmt);
    if SUCCEEDED(result) then
    begin
      result := CompleteConnect(pConnector);
      if SUCCEEDED(result) then
      begin
        result := S_OK;
        exit;
      end;
    end;

  {$IFDEF _DEBUG}
    DbgLog(self, 'Failed to set the media type or failed to complete the connection.');
  {$ENDIF}
    FConnected := nil;

    // Since the procedure is already returning an error code, there
    // is nothing else this function can do to report the error.
  {$IFOPT C+}
    ASSERT(SUCCEEDED(BreakConnect));
  {$ELSE}
    BreakConnect;
  {$ENDIF}
  finally
    FLock.UnLock;
  end;
end;

{ Called by IMediaFilter implementation when the state changes from
  to either paused to running and in derived classes could do things like
  commit memory and grab hardware resource (the default is to do nothing) }

function TBCBasePin.Run(Start: TReferenceTime): HRESULT;
begin
  result := NOERROR;
end;


function TBCBasePin.GetCurrentMediaType: TBCMediaType;
begin
  result := TBCMediaType(@FMT);
end;

function TBCBasePin.GetAMMediaType: PAMMediaType;
begin
  result := @FMT;
end;

{ This is called to set the format for a pin connection - CheckMediaType
  will have been called to check the connection format and if it didn't
  return an error code then this (virtual) function will be invoked }

function TBCBasePin.SetMediaType(mt: PAMMediaType): HRESULT;
begin
  FreeMediaType(@Fmt);
  CopyMediaType(@Fmt, mt);
  result := NOERROR;
end;

function TBCBasePin.SetSink(piqc: IQualityControl): HRESULT;
begin
  FLock.Lock;
  try
    FQSink := piqc;
    result := NOERROR;
  finally
    FLock.UnLock;
  end;
end;

{ Given an enumerator we cycle through all the media types it proposes and
  firstly suggest them to our derived pin class and if that succeeds try
  them with the pin in a ReceiveConnection call. This means that if our pin
  proposes a media type we still check in here that we can support it. This
  is deliberate so that in simple cases the enumerator can hold all of the
  media types even if some of them are not really currently available }

function TBCBasePin.TryMediaTypes(ReceivePin: IPin; pmt: PAMMediaType;
  Enum: IEnumMediaTypes): HRESULT;
var
  MediaCount: Cardinal;
  hrFailure : HResult;
  MediaType : PAMMediaType;
begin
  // Reset the current enumerator position
  result := Enum.Reset;
  if Failed(result) then exit;

  MediaCount := 0;

  // attempt to remember a specific error code if there is one
  hrFailure := S_OK;

  while True do
  begin
    { Retrieve the next media type NOTE each time round the loop the
      enumerator interface will allocate another AM_MEDIA_TYPE structure
      If we are successful then we copy it into our output object, if
      not then we must delete the memory allocated before returning }

    result := Enum.Next(1, MediaType, @MediaCount);
    if (result <> S_OK) then
    begin
      if (S_OK = hrFailure) then
        hrFailure := VFW_E_NO_ACCEPTABLE_TYPES;
      result := hrFailure;
      exit;
    end;

    ASSERT(MediaCount = 1);
    ASSERT(MediaType <> nil);
    // check that this matches the partial type (if any)

    if (pmt = nil) or TBCMediaType(MediaType).MatchesPartial(pmt) then
    begin
      result := AttemptConnection(ReceivePin, MediaType);
      // attempt to remember a specific error code
      if FAILED(result)           and
         SUCCEEDED(hrFailure)     and
         (result <> E_FAIL)       and
         (result <> E_INVALIDARG) and
         (result <> VFW_E_TYPE_NOT_ACCEPTED) then hrFailure := result;
    end
    else result := VFW_E_NO_ACCEPTABLE_TYPES;
    DeleteMediaType(MediaType);
    if result = S_OK then exit;
  end;
end;

{ TBCEnumMediaTypes }

{ The media types a filter supports can be quite dynamic so we add to
  the general IEnumXXXX interface the ability to be signaled when they
  change via an event handle the connected filter supplies. Until the
  Reset method is called after the state changes all further calls to
  the enumerator (except Reset) will return E_UNEXPECTED error code. }

function TBCEnumMediaTypes.AreWeOutOfSync: boolean;
begin
  if FPin.GetMediaTypeVersion = FVersion then result := FALSE else result := True;
end;

{ One of an enumerator's basic member functions allows us to create a cloned
  interface that initially has the same state. Since we are taking a snapshot
  of an object (current position and all) we must lock access at the start }

function TBCEnumMediaTypes.Clone(out ppEnum: IEnumMediaTypes): HRESULT;
begin
  result := NOERROR;
  // Check we are still in sync with the pin
  if AreWeOutOfSync then
    begin
      ppEnum := nil;
      result := VFW_E_ENUM_OUT_OF_SYNC;
      exit;
    end
  else
    begin
      ppEnum := TBCEnumMediaTypes.Create(FPin, self);
      if (ppEnum = nil) then result := E_OUTOFMEMORY;
    end;
end;

constructor TBCEnumMediaTypes.Create(Pin: TBCBasePin;
  EnumMediaTypes: TBCEnumMediaTypes);
begin
  FPosition := 0;
  FPin      := Pin;
  {$IFDEF _DEBUG}
    DbgLog('TBCEnumMediaTypes.Create');
  {$ENDIF}

  // We must be owned by a pin derived from CBasePin */
  ASSERT(Pin <> nil);

  // Hold a reference count on our pin
  FPin._AddRef;

  // Are we creating a new enumerator

  if (EnumMediaTypes = nil) then
  begin
    FVersion := FPin.GetMediaTypeVersion;
    exit;
  end;

  FPosition := EnumMediaTypes.FPosition;
  FVersion  := EnumMediaTypes.FVersion;
end;

{ Destructor releases the reference count on our base pin. NOTE since we hold
  a reference count on the pin who created us we know it is safe to release
  it, no access can be made to it afterwards though as we might have just
  caused the last reference count to go and the object to be deleted }

destructor TBCEnumMediaTypes.Destroy;
begin
  {$IFDEF _DEBUG}
    DbgLog('TBCEnumMediaTypes.Destroy');
  {$ENDIF}
  FPin._Release;
  inherited;
end;

{ Enumerate the next pin(s) after the current position. The client using this
   interface passes in a pointer to an array of pointers each of which will
   be filled in with a pointer to a fully initialised media type format
   Return NOERROR if it all works,
          S_FALSE if fewer than cMediaTypes were enumerated.
          VFW_E_ENUM_OUT_OF_SYNC if the enumerator has been broken by
                                 state changes in the filter
   The actual count always correctly reflects the number of types in the array.}

function TBCEnumMediaTypes.Next(cMediaTypes: ULONG;
  out ppMediaTypes: PAMMediaType; pcFetched: PULONG): HRESULT;
type TMTDynArray = array of PAMMediaType;
var
  Fetched: Cardinal;
  cmt: PAMMediaType;
begin
    // Check we are still in sync with the pin
    if AreWeOutOfSync then
      begin
        result := VFW_E_ENUM_OUT_OF_SYNC;
        exit;
      end;

    if (pcFetched <> nil) then
      pcFetched^ := 0           // default unless we succeed
    // now check that the parameter is valid
    else
      if (cMediaTypes > 1) then
        begin     // pcFetched == NULL
          result := E_INVALIDARG;
          exit;
        end;

    Fetched := 0;           // increment as we get each one.

    {  Return each media type by asking the filter for them in turn - If we
       have an error code retured to us while we are retrieving a media type
       we assume that our internal state is stale with respect to the filter
       (for example the window size changing) so we return
       VFW_E_ENUM_OUT_OF_SYNC }

    new(cmt);
    while (cMediaTypes > 0) do
    begin
        TBCMediaType(cmt).InitMediaType;
        inc(FPosition);
        result := FPin.GetMediaType(FPosition-1, cmt);
        if (S_OK <> result) then Break;

        {  We now have a CMediaType object that contains the next media type
           but when we assign it to the array position we CANNOT just assign
           the AM_MEDIA_TYPE structure because as soon as the object goes out of
           scope it will delete the memory we have just copied. The function
           we use is CreateMediaType which allocates a task memory block }

        {   Transfer across the format block manually to save an allocate
            and free on the format block and generally go faster }

        TMTDynArray(@ppMediaTypes)[Fetched] := CoTaskMemAlloc(sizeof(TAMMediaType));
        if TMTDynArray(@ppMediaTypes)[Fetched] = nil then Break;

        {  Do a regular copy }
        //CopyMediaType(TMTDynArray(@ppMediaTypes)[Fetched], cmt);
        Move(cmt^,TMTDynArray(@ppMediaTypes)[Fetched]^,SizeOf(TAMMediaType));

        // Make sure the destructor doesn't free these
        cmt.pbFormat      := nil;
        cmt.cbFormat      := 0;
        Pointer(cmt.pUnk) := nil;

        inc(Fetched);
        dec(cMediaTypes);
    end;
    dispose(cmt);
    if (pcFetched <> nil) then pcFetched^ := Fetched;
    if cMediaTypes = 0 then result := NOERROR else result := S_FALSE;
end;

{ Set the current position back to the start
  Reset has 3 simple steps:
  set position to head of list
  sync enumerator with object being enumerated
  return S_OK }

function TBCEnumMediaTypes.Reset: HRESULT;
begin
  FPosition := 0;
  // Bring the enumerator back into step with the current state.  This
  // may be a noop but ensures that the enumerator will be valid on the
  // next call.
  FVersion := FPin.GetMediaTypeVersion;
  result := NOERROR;
end;

// Skip over one or more entries in the enumerator

function TBCEnumMediaTypes.Skip(cMediaTypes: ULONG): HRESULT;
var cmt: PAMMediaType;
begin
  cmt := nil;
  //  If we're skipping 0 elements we're guaranteed to skip the
  //  correct number of elements
  if (cMediaTypes = 0) then
  begin
    result := S_OK;
    exit;
  end;
  // Check we are still in sync with the pin
  if AreWeOutOfSync then
  begin
    result := VFW_E_ENUM_OUT_OF_SYNC;
    exit;
  end;

  FPosition := FPosition + cMediaTypes;

  // See if we're over the end
  if (S_OK = FPin.GetMediaType(FPosition - 1, cmt)) then result := S_OK else result := S_FALSE;
end;

{ TBCBaseOutputPin }

// Commit the allocator's memory, this is called through IMediaFilter
// which is responsible for locking the object before calling us

function TBCBaseOutputPin.Active: HRESULT;
begin
  if (FAllocator = nil) then
       result := VFW_E_NO_ALLOCATOR
  else result := FAllocator.Commit;
end;

function TBCBaseOutputPin.BeginFlush: HRESULT;
begin
  result := E_UNEXPECTED;
end;

// Overriden from CBasePin
function TBCBaseOutputPin.BreakConnect: HRESULT;
begin
  // Release any allocator we hold
  if (FAllocator <> nil) then
  begin
    // Always decommit the allocator because a downstream filter may or
    // may not decommit the connection's allocator.  A memory leak could
    // occur if the allocator is not decommited when a connection is broken.
    result := FAllocator.Decommit;
    if FAILED(result) then exit;
    FAllocator := nil;
  end;

  // Release any input pin interface we hold
  if (FInputPin <> nil) then FInputPin := nil;
  result := NOERROR;
end;

{ This method is called when the output pin is about to try and connect to
  an input pin. It is at this point that you should try and grab any extra
  interfaces that you need, in this case IMemInputPin. Because this is
  only called if we are not currently connected we do NOT need to call
  BreakConnect. This also makes it easier to derive classes from us as
  BreakConnect is only called when we actually have to break a connection
  (or a partly made connection) and not when we are checking a connection }

function TBCBaseOutputPin.CheckConnect(Pin: IPin): HRESULT;
begin
  result := inherited CheckConnect(Pin);
  if FAILED(result) then exit;

  // get an input pin and an allocator interface
  result := Pin.QueryInterface(IID_IMemInputPin, FInputPin);
  if FAILED(result) then exit;
  result := NOERROR;
end;

// This is called after a media type has been proposed
// Try to complete the connection by agreeing the allocator
function TBCBaseOutputPin.CompleteConnect(ReceivePin: IPin): HRESULT;
begin
  result := DecideAllocator(FInputPin, FAllocator);
end;

constructor TBCBaseOutputPin.Create(ObjectName: string;
  Filter: TBCBaseFilter; Lock: TBCCritSec; out hr: HRESULT;
  const Name: WideString);
begin
  inherited Create(ObjectName, Filter, Lock, hr, Name, PINDIR_OUTPUT);
  FAllocator := nil;
  FInputPin  := nil;
  ASSERT(FFilter <> nil);
end;

{ Decide on an allocator, override this if you want to use your own allocator
  Override DecideBufferSize to call SetProperties. If the input pin fails
  the GetAllocator call then this will construct a CMemAllocator and call
  DecideBufferSize on that, and if that fails then we are completely hosed.
  If the you succeed the DecideBufferSize call, we will notify the input
  pin of the selected allocator. NOTE this is called during Connect() which
  therefore looks after grabbing and locking the object's critical section }

// We query the input pin for its requested properties and pass this to
// DecideBufferSize to allow it to fulfill requests that it is happy
// with (eg most people don't care about alignment and are thus happy to
// use the downstream pin's alignment request).

function TBCBaseOutputPin.DecideAllocator(Pin: IMemInputPin;
  out Alloc: IMemAllocator): HRESULT;
var
  prop: TAllocatorProperties;
begin
  Alloc := nil;

  // get downstream prop request
  // the derived class may modify this in DecideBufferSize, but
  // we assume that he will consistently modify it the same way,
  // so we only get it once
  ZeroMemory(@prop, sizeof(TAllocatorProperties));

  // whatever he returns, we assume prop is either all zeros
  // or he has filled it out.
  Pin.GetAllocatorRequirements(prop);

  // if he doesn't care about alignment, then set it to 1
  if (prop.cbAlign = 0) then prop.cbAlign := 1;

  // Try the allocator provided by the input pin

  result := Pin.GetAllocator(Alloc);
  if SUCCEEDED(result) then
  begin
    result := DecideBufferSize(Alloc, @prop);
    if SUCCEEDED(result) then
    begin
      result := Pin.NotifyAllocator(Alloc, FALSE);
      if SUCCEEDED(result) then
      begin
        result := NOERROR;
        exit;
      end;
    end;
  end;

  // If the GetAllocator failed we may not have an interface

  if (Alloc <> nil) then Alloc := nil;

  // Try the output pin's allocator by the same method

  result := InitAllocator(Alloc);
  if SUCCEEDED(result) then
  begin
    // note - the properties passed here are in the same
    // structure as above and may have been modified by
    // the previous call to DecideBufferSize
    result := DecideBufferSize(Alloc, @prop);
    if SUCCEEDED(result) then
    begin
      result := Pin.NotifyAllocator(Alloc, FALSE);
      if SUCCEEDED(result) then
      begin
        result := NOERROR;
        exit;
      end;
    end;
  end;
  // Likewise we may not have an interface to release
  if (Alloc <> nil) then Alloc := nil;
end;

function TBCBaseOutputPin.DecideBufferSize(Alloc: IMemAllocator;
  propInputRequest: PAllocatorProperties): HRESULT;
begin
  result := S_OK; // ???
end;

{ Deliver a filled-in sample to the connected input pin. NOTE the object must
  have locked itself before calling us otherwise we may get halfway through
  executing this method only to find the filter graph has got in and
  disconnected us from the input pin. If the filter has no worker threads
  then the lock is best applied on Receive(), otherwise it should be done
  when the worker thread is ready to deliver. There is a wee snag to worker
  threads that this shows up. The worker thread must lock the object when
  it is ready to deliver a sample, but it may have to wait until a state
  change has completed, but that may never complete because the state change
  is waiting for the worker thread to complete. The way to handle this is for
  the state change code to grab the critical section, then set an abort event
  for the worker thread, then release the critical section and wait for the
  worker thread to see the event we set and then signal that it has finished
  (with another event). At which point the state change code can complete }

// note (if you've still got any breath left after reading that) that you
// need to release the sample yourself after this call. if the connected
// input pin needs to hold onto the sample beyond the call, it will addref
// the sample itself.

// of course you must release this one and call GetDeliveryBuffer for the
// next. You cannot reuse it directly.

function TBCBaseOutputPin.Deliver(Sample: IMediaSample): HRESULT;
begin
  if (FInputPin = nil) then result := VFW_E_NOT_CONNECTED
                       else result := FInputPin.Receive(Sample);
end;

// call BeginFlush on the connected input pin
function TBCBaseOutputPin.DeliverBeginFlush: HRESULT;
begin
  // remember this is on IPin not IMemInputPin
  if (FConnected = nil) then
       result := VFW_E_NOT_CONNECTED
  else result := FConnected.BeginFlush;
end;

// call EndFlush on the connected input pin
function TBCBaseOutputPin.DeliverEndFlush: HRESULT;
begin
  // remember this is on IPin not IMemInputPin
  if (FConnected = nil) then
       result := VFW_E_NOT_CONNECTED
  else result := FConnected.EndFlush;
end;

// called from elsewhere in our filter to pass EOS downstream to
// our connected input pin

function TBCBaseOutputPin.DeliverEndOfStream: HRESULT;
begin
  // remember this is on IPin not IMemInputPin
  if (FConnected = nil) then
       result := VFW_E_NOT_CONNECTED
  else result := FConnected.EndOfStream;
end;

// deliver NewSegment to connected pin
function TBCBaseOutputPin.DeliverNewSegment(Start, Stop: TReferenceTime;
  Rate: double): HRESULT;
begin
  if (FConnected = nil) then
       result := VFW_E_NOT_CONNECTED
  else result := FConnected.NewSegment(Start, Stop, Rate);
end;

function TBCBaseOutputPin.EndFlush: HRESULT;
begin
  result := E_UNEXPECTED;
end;

// we have a default handling of EndOfStream which is to return
// an error, since this should be called on input pins only
function TBCBaseOutputPin.EndOfStream: HRESULT;
begin
  result := E_UNEXPECTED;
end;

// This returns an empty sample buffer from the allocator WARNING the same
// dangers and restrictions apply here as described below for Deliver()

function TBCBaseOutputPin.GetDeliveryBuffer(out Sample: IMediaSample;
  StartTime, EndTime: PReferenceTime; Flags: Longword): HRESULT;
begin
  if (FAllocator <> nil) then
       result := FAllocator.GetBuffer(Sample, StartTime, EndTime, Flags)
  else result := E_NOINTERFACE;
end;

{ Free up or unprepare allocator's memory, this is called through
  IMediaFilter which is responsible for locking the object first }

function TBCBaseOutputPin.Inactive: HRESULT;
begin
  FRunTimeError := FALSE;
  if (FAllocator = nil) then
       result := VFW_E_NO_ALLOCATOR
  else result := FAllocator.Decommit;
end;

// This is called when the input pin didn't give us a valid allocator
function TBCBaseOutputPin.InitAllocator(out Alloc: IMemAllocator): HRESULT;
begin
  result := CoCreateInstance(CLSID_MemoryAllocator, nil, CLSCTX_INPROC_SERVER,
    IID_IMemAllocator, Alloc);
end;

{ TBCBaseInputPin }

// Default handling for BeginFlush - call at the beginning
// of your implementation (makes sure that all Receive calls
// fail). After calling this, you need to free any queued data
// and then call downstream.

function TBCBaseInputPin.BeginFlush: HRESULT;
begin
    //  BeginFlush is NOT synchronized with streaming but is part of
    //  a control action - hence we synchronize with the filter
  FLock.Lock;
  try
    // if we are already in mid-flush, this is probably a mistake
    // though not harmful - try to pick it up for now so I can think about it
//    ASSERT(not FFlushing);
    // first thing to do is ensure that no further Receive calls succeed
    FFlushing := True;
    // now discard any data and call downstream - must do that
    // in derived classes
    result := S_OK;
  finally
    FLock.UnLock;
  end;

end;

function TBCBaseInputPin.BreakConnect: HRESULT;
begin
  // We don't need our allocator any more
  if (FAllocator <> nil) then
  begin
    // Always decommit the allocator because a downstream filter may or
    // may not decommit the connection's allocator.  A memory leak could
    // occur if the allocator is not decommited when a pin is disconnected.
    result := FAllocator.Decommit;
    if FAILED(result) then exit;
    FAllocator := nil;
  end;
  result := S_OK;
end;

//  Check if it's OK to process data

function TBCBaseInputPin.CheckStreaming: HRESULT;
begin
  //  Shouldn't be able to get any data if we're not connected!
  ASSERT(IsConnected);
  //  Don't process stuff in Stopped state
  if IsStopped then begin result := VFW_E_WRONG_STATE; exit end;
  if FFlushing then begin result := S_FALSE; exit end;
  if FRunTimeError then begin result := VFW_E_RUNTIME_ERROR; exit end;
  result := S_OK;
end;

// Constructor creates a default allocator object

constructor TBCBaseInputPin.Create(ObjectName: string;
  Filter: TBCBaseFilter; Lock: TBCCritSec; out hr: HRESULT;
  Name: WideString);
begin
    inherited create(ObjectName, Filter, Lock, hr, Name, PINDIR_INPUT);
    FAllocator := nil;
    FReadOnly  := false;
    FFlushing  := false;
    ZeroMemory(@FSampleProps, sizeof(FSampleProps));
end;

destructor TBCBaseInputPin.Destroy;
begin
  if FAllocator <> nil then FAllocator := nil;
  inherited;
end;

// default handling for EndFlush - call at end of your implementation
// - before calling this, ensure that there is no queued data and no thread
// pushing any more without a further receive, then call downstream,
// then call this method to clear the m_bFlushing flag and re-enable
// receives

function TBCBaseInputPin.EndFlush: HRESULT;
begin
    //  Endlush is NOT synchronized with streaming but is part of
    //  a control action - hence we synchronize with the filter
  FLock.Lock;
  try
    // almost certainly a mistake if we are not in mid-flush
//    ASSERT(FFlushing);
    // before calling, sync with pushing thread and ensure
    // no more data is going downstream, then call EndFlush on
    // downstream pins.
    // now re-enable Receives
    FFlushing := FALSE;
    // No more errors
    FRunTimeError := FALSE;
    result := S_OK;
  finally
    FLock.UnLock;
  end;
end;

{ Return the allocator interface that this input pin would like the output
   pin to use. NOTE subsequent calls to GetAllocator should all return an
   interface onto the SAME object so we create one object at the start

   Note:
       The allocator is Release()'d on disconnect and replaced on
       NotifyAllocator().

   Override this to provide your own allocator.}
function TBCBaseInputPin.GetAllocator(
  out ppAllocator: IMemAllocator): HRESULT;
begin
  FLock.Lock;
  try
    if (FAllocator = nil) then
    begin
      result := CoCreateInstance(CLSID_MemoryAllocator, nil, CLSCTX_INPROC_SERVER,
        IID_IMemAllocator, FAllocator);
      if FAILED(result) then exit;
    end;
    ASSERT(FAllocator <> nil);
    ppAllocator := FAllocator;
    result := NOERROR;
  finally
    FLock.UnLock;
  end;
end;

// what requirements do we have of the allocator - override if you want
// to support other people's allocators but need a specific alignment
// or prefix.

function TBCBaseInputPin.GetAllocatorRequirements(
  out pProps: TAllocatorProperties): HRESULT;
begin
  result := E_NOTIMPL;
end;

{ Free up or unprepare allocator's memory, this is called through
  IMediaFilter which is responsible for locking the object first. }

function TBCBaseInputPin.Inactive: HRESULT;
begin
  FRunTimeError := FALSE;
  if (FAllocator = nil) then
  begin
    result := VFW_E_NO_ALLOCATOR;
    exit;
  end;
  FFlushing := FALSE;
  result := FAllocator.Decommit;
end;

function TBCBaseInputPin.Notify(pSelf: IBaseFilter; q: TQuality): HRESULT;
begin
{$IFDEF _DEBUG}
  DbgLog(self, 'IQuality.Notify called on an input pin');
{$ENDIF}
  result := NOERROR;
end;

{ Tell the input pin which allocator the output pin is actually going to use
  Override this if you care - NOTE the locking we do both here and also in
  GetAllocator is unnecessary but derived classes that do something useful
  will undoubtedly have to lock the object so this might help remind people }

function TBCBaseInputPin.NotifyAllocator(pAllocator: IMemAllocator;
  bReadOnly: BOOL): HRESULT;
begin
  FLock.Lock;
  try
    FAllocator := pAllocator;
    // the readonly flag indicates whether samples from this allocator should
    // be regarded as readonly - if True, then inplace transforms will not be
    // allowed.
    FReadOnly := bReadOnly;
    result    := NOERROR;
  finally
    FLock.UnLock;
  end;
end;

// Pass on the Quality notification q to
// a. Our QualityControl sink (if we have one) or else
// b. to our upstream filter
// and if that doesn't work, throw it away with a bad return code

function TBCBaseInputPin.PassNotify(const q: TQuality): HRESULT;
var IQC: IQualityControl;
begin
  // We pass the message on, which means that we find the quality sink
  // for our input pin and send it there

{$IFDEF _DEBUG}
  DbgLog(self, 'Passing Quality notification through transform');
{$ENDIF}
  if (FQSink <> nil) then
    begin
      result := FQSink.Notify(FFilter, q);
      exit;
    end
  else
    begin
      // no sink set, so pass it upstream
      result := VFW_E_NOT_FOUND;                   // default
      if (FConnected <> nil) then
      begin
        FConnected.QueryInterface(IID_IQualityControl, IQC);
        if (IQC <> nil) then
        begin
          result := IQC.Notify(FFilter, q);
          IQC := nil;
        end;
      end;
    end;
end;

{ Do something with this media sample - this base class checks to see if the
  format has changed with this media sample and if so checks that the filter
  will accept it, generating a run time error if not. Once we have raised a
  run time error we set a flag so that no more samples will be accepted
  It is important that any filter should override this method and implement
  synchronization so that samples are not processed when the pin is
  disconnected etc. }

function TBCBaseInputPin.Receive(pSample: IMediaSample): HRESULT;
var Sample2: IMediaSample2;
begin
  ASSERT(pSample <> nil);

  result := CheckStreaming;
  if (S_OK <> result) then exit;

  // Check for IMediaSample2
  if SUCCEEDED(pSample.QueryInterface(IID_IMediaSample2, Sample2)) then
    begin
      result := Sample2.GetProperties(sizeof(FSampleProps), FSampleProps);
      Sample2 := nil;
      if FAILED(result) then exit;
    end
  else
    begin
      //  Get the properties the hard way
      FSampleProps.cbData := sizeof(FSampleProps);
      FSampleProps.dwTypeSpecificFlags := 0;
      FSampleProps.dwStreamId          := AM_STREAM_MEDIA;
      FSampleProps.dwSampleFlags       := 0;
      if (S_OK = pSample.IsDiscontinuity) then
          FSampleProps.dwSampleFlags := FSampleProps.dwSampleFlags or AM_SAMPLE_DATADISCONTINUITY;
      if (S_OK = pSample.IsPreroll) then
          FSampleProps.dwSampleFlags := FSampleProps.dwSampleFlags or AM_SAMPLE_PREROLL;
      if (S_OK = pSample.IsSyncPoint) then
          FSampleProps.dwSampleFlags := FSampleProps.dwSampleFlags or AM_SAMPLE_SPLICEPOINT;
      if SUCCEEDED(pSample.GetTime(FSampleProps.tStart, FSampleProps.tStop)) then
          FSampleProps.dwSampleFlags := FSampleProps.dwSampleFlags or AM_SAMPLE_TIMEVALID or AM_SAMPLE_STOPVALID;
      if (S_OK = pSample.GetMediaType(FSampleProps.pMediaType)) then
          FSampleProps.dwSampleFlags := FSampleProps.dwSampleFlags or AM_SAMPLE_TYPECHANGED;
      pSample.GetPointer(PByte(FSampleProps.pbBuffer));
      FSampleProps.lActual := pSample.GetActualDataLength;
      FSampleProps.cbBuffer := pSample.GetSize;
    end;

  // Has the format changed in this sample

  if (not BOOL(FSampleProps.dwSampleFlags and AM_SAMPLE_TYPECHANGED)) then
  begin
    result := NOERROR;
    exit;
  end;

  // Check the derived class accepts this format */
  // This shouldn't fail as the source must call QueryAccept first */

  result := CheckMediaType(FSampleProps.pMediaType);

  if (result = NOERROR) then exit;

  // Raise a runtime error if we fail the media type

  FRunTimeError := True;
  EndOfStream;
  FFilter.NotifyEvent(EC_ERRORABORT,VFW_E_TYPE_NOT_ACCEPTED,0);
  result := VFW_E_INVALIDMEDIATYPE;
end;

// See if Receive() might block

function TBCBaseInputPin.ReceiveCanBlock: HRESULT;
var
  c, Pins, OutputPins: Integer;
  Pin: TBCBasePin;
  pd: TPinDirection;
  Connected: IPin;
  InputPin: IMemInputPin;
begin
  { Ask all the output pins if they block
    If there are no output pin assume we do block. }
  Pins := FFilter.GetPinCount;
  OutputPins := 0;
  for c := 0 to Pins - 1 do
  begin
    Pin := FFilter.GetPin(c);
    result := Pin.QueryDirection(pd);
    if FAILED(result) then exit;
    if (pd = PINDIR_OUTPUT) then
    begin
      result := Pin.ConnectedTo(Connected);
      if SUCCEEDED(result) then
      begin
        assert(Connected <> nil);
        inc(OutputPins);
        result := Connected.QueryInterface(IID_IMemInputPin, InputPin);
        Connected := nil;
        if SUCCEEDED(result) then
          begin
            result := InputPin.ReceiveCanBlock;
            InputPin := nil;
            if (result <> S_FALSE) then
              begin
                result := S_OK;
                exit;
              end;
          end
        else
          begin
            // There's a transport we don't understand here
            result := S_OK;
            exit;
          end;
      end;
    end;
  end;
  if OutputPins = 0 then result := S_OK else result := S_FALSE;
end;

//  Receive multiple samples

function TBCBaseInputPin.ReceiveMultiple(pSamples: PIMediaSampleArray;
  nSamples: Integer; out nSamplesProcessed: Integer): HRESULT;
type
  TMediaSampleDynArray = array of IMediaSample;
begin
  result := S_OK;
  nSamplesProcessed := 0;
  dec(nSamples);
  while (nSamples >= 0) do
  begin
//    result := Receive(TMediaSampleDynArray(@pSamples)[nSamplesProcessed]);
    Result := Receive(pSamples[nSamplesProcessed]); // SZ: otherwise AV in GMF
    //  S_FALSE means don't send any more
    if (result <> S_OK) then break;
    inc(nSamplesProcessed);
    dec(nSamples)
  end;
end;

function TBCBaseInputPin.SampleProps: PAMSample2Properties;
begin
  ASSERT(FSampleProps.cbData <> 0);
  result := @FSampleProps;
end;

// milenko start (added TBCDynamicOutputPin conversion)
{ TBCDynamicOutputPin }
//
// The streaming thread calls IPin::NewSegment(), IPin::EndOfStream(),
// IMemInputPin::Receive() and IMemInputPin::ReceiveMultiple() on the
// connected input pin.  The application thread calls Block().  The
// following class members can only be called by the streaming thread.
//
//    Deliver()
//    DeliverNewSegment()
//    StartUsingOutputPin()
//    StopUsingOutputPin()
//    ChangeOutputFormat()
//    ChangeMediaType()
//    DynamicReconnect()
//
// The following class members can only be called by the application thread.
//
//    Block()
//    SynchronousBlockOutputPin()
//    AsynchronousBlockOutputPin()
//
constructor TBCDynamicOutputPin.Create(ObjectName: WideString; Filter: TBCBaseFilter;
                   Lock: TBCCritSec; out hr: HRESULT; Name: WideString);
begin
  inherited Create(ObjectName,Filter,Lock,hr,Name);
  FStopEvent := 0;
  FGraphConfig := nil;
  FPinUsesReadOnlyAllocator := False;
  FBlockState := NOT_BLOCKED;
  FUnblockOutputPinEvent := 0;
  FNotifyCallerPinBlockedEvent := 0;
  FBlockCallerThreadID := 0;
  FNumOutstandingOutputPinUsers := 0;

  FBlockStateLock := TBCCritSec.Create;

  hr := Initialize;
end;

destructor TBCDynamicOutputPin.Destroy;
begin
  if(FUnblockOutputPinEvent <> 0) then
  begin
    // This call should not fail because we have access to m_hUnblockOutputPinEvent
    // and m_hUnblockOutputPinEvent is a valid event.
  {$IFOPT C+}
    ASSERT(CloseHandle(FUnblockOutputPinEvent));
  {$ELSE}
    CloseHandle(FUnblockOutputPinEvent);
  {$ENDIF}
  end;

  if(FNotifyCallerPinBlockedEvent <> 0) then
  begin
    // This call should not fail because we have access to m_hNotifyCallerPinBlockedEvent
    // and m_hNotifyCallerPinBlockedEvent is a valid event.
  {$IFOPT C+}
    ASSERT(CloseHandle(FNotifyCallerPinBlockedEvent));
  {$ELSE}
    CloseHandle(FNotifyCallerPinBlockedEvent);
  {$ENDIF}
  end;

  if Assigned(FBlockStateLock) then FreeAndNil(FBlockStateLock);

  inherited Destroy;
end;

function TBCDynamicOutputPin.NonDelegatingQueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if IsEqualGUID(IID,IID_IPinFlowControl) then
  begin
    if GetInterface(IID_IPinFlowControl, Obj) then Result := S_OK
                                              else Result := E_NOINTERFACE;
  end else
  begin
    Result := inherited NonDelegatingQueryInterface(IID,Obj);
  end;
end;

function TBCDynamicOutputPin.Disconnect: HRESULT;
begin
  FLock.Lock;
  try
    Result := DisconnectInternal;
  finally
    FLock.Unlock;
  end;
end;

function TBCDynamicOutputPin.Block(dwBlockFlags: DWORD; hEvent: THandle): HResult;
begin
  // Check for illegal flags.
  if BOOL(dwBlockFlags and not AM_PIN_FLOW_CONTROL_BLOCK) then
  begin
    Result := E_INVALIDARG;
    Exit;
  end;

  // Make sure the event is unsignaled.
  if(BOOL(dwBlockFlags and AM_PIN_FLOW_CONTROL_BLOCK) and (hEvent <> 0)) then
  begin
    if not ResetEvent(hEvent) then
    begin
      Result := AmGetLastErrorToHResult;
      Exit
    end;
  end;

  // No flags are set if we are unblocking the output pin.
  if(dwBlockFlags = 0) then
  begin
    // This parameter should be NULL because unblock operations are always synchronous.
    // There is no need to notify the caller when the event is done.
    if(hEvent <> 0) then
    begin
      Result := E_INVALIDARG;
      Exit;
    end;
  end;

  {$IFDEF _DEBUG}
  AssertValid;
  {$ENDIF} // _DEBUG

  if BOOL(dwBlockFlags and AM_PIN_FLOW_CONTROL_BLOCK) then
  begin
    // IPinFlowControl::Block()'s hEvent parameter is NULL if the block is synchronous.
    // If hEvent is not NULL, the block is asynchronous.
    if(hEvent = 0) then Result := SynchronousBlockOutputPin
                   else Result := AsynchronousBlockOutputPin(hEvent);

  end else
  begin
    Result := UnblockOutputPin;
  end;

  {$IFDEF _DEBUG}
  AssertValid;
  {$ENDIF} // _DEBUG

  if(FAILED(Result)) then Exit;

  Result := S_OK;
end;

procedure TBCDynamicOutputPin.SetConfigInfo(GraphConfig: IGraphConfig; StopEvent: THandle);
begin
  // This pointer is not addrefed because filters are not allowed to
  // hold references to the filter graph manager.  See the documentation for
  // IBaseFilter::JoinFilterGraph() in the Direct Show SDK for more information.
  Pointer(FGraphConfig) := Pointer(GraphConfig);
  FStopEvent := StopEvent;
end;

{$IFDEF _DEBUG}
function TBCDynamicOutputPin.Deliver(Sample: IMediaSample): HRESULT;
begin
  // The caller should call StartUsingOutputPin() before calling this
  // method.
  ASSERT(StreamingThreadUsingOutputPin);
  Result := inherited Deliver(Sample);
end;

function TBCDynamicOutputPin.DeliverEndOfStream: HRESULT;
begin
  // The caller should call StartUsingOutputPin() before calling this
  // method.
  ASSERT(StreamingThreadUsingOutputPin);
  Result := inherited DeliverEndOfStream;
end;

function TBCDynamicOutputPin.DeliverNewSegment(Start, Stop: TReferenceTime; Rate: Double): HRESULT;
begin
  // The caller should call StartUsingOutputPin() before calling this
  // method.
  ASSERT(StreamingThreadUsingOutputPin);
  Result := inherited DeliverNewSegment(Start, Stop, Rate);
end;
{$ENDIF}

function TBCDynamicOutputPin.DeliverBeginFlush: HRESULT;
begin
  // If this ASSERT fires, the user may have passed an invalid event handle to SetConfigInfo().
  // The ASSERT can also fire if the event if destroyed and then DeliverBeginFlush() is called.
  // An event handle is invalid if 1) the event does not exist or the user does not have the security
  // permissions to use the event.
{$IFOPT C+}
  ASSERT(SetEvent(FStopEvent));
{$ELSE}
  SetEvent(FStopEvent);
{$ENDIF}
  Result := inherited DeliverBeginFlush;
end;

function TBCDynamicOutputPin.DeliverEndFlush: HRESULT;
begin
  // If this ASSERT fires, the user may have passed an invalid event handle to SetConfigInfo().
  // The ASSERT can also fire if the event if destroyed and then DeliverBeginFlush() is called.
  // An event handle is invalid if 1) the event does not exist or the user does not have the security
  // permissions to use the event.
{$IFOPT C+}
  ASSERT(ResetEvent(FStopEvent));
{$ELSE}
  ResetEvent(FStopEvent);
{$ENDIF}
  Result := inherited DeliverEndFlush;
end;

function TBCDynamicOutputPin.Active: HRESULT;
begin
  // Make sure the user initialized the object by calling SetConfigInfo().
  if(FStopEvent = 0) or (FGraphConfig = nil) then
  begin
    {$IFDEF _DEBUG}
     DbgLog('ERROR: TBCDynamicOutputPin.Active() failed because m_pGraphConfig' +
            ' and m_hStopEvent were not initialized.  Call SetConfigInfo() to initialize them.');
    {$ENDIF} // _DEBUG
    Result := E_FAIL;
    Exit;
  end;

  // If this ASSERT fires, the user may have passed an invalid event handle to SetConfigInfo().
  // The ASSERT can also fire if the event if destroyed and then Active() is called.  An event
  // handle is invalid if 1) the event does not exist or the user does not have the security
  // permissions to use the event.
{$IFOPT C+}
  ASSERT(ResetEvent(FStopEvent));
{$ELSE}
  ResetEvent(FStopEvent);
{$ENDIF}

  Result := inherited Active;
end;

function TBCDynamicOutputPin.Inactive: HRESULT;
begin
  // If this ASSERT fires, the user may have passed an invalid event handle to SetConfigInfo().
  // The ASSERT can also fire if the event if destroyed and then Active() is called.  An event
  // handle is invalid if 1) the event does not exist or the user does not have the security
  // permissions to use the event.
{$IFOPT C+}
  ASSERT(SetEvent(FStopEvent));
{$ELSE}
  SetEvent(FStopEvent);
{$ENDIF}
  Result := inherited Inactive;
end;

function TBCDynamicOutputPin.CompleteConnect(ReceivePin: IPin): HRESULT;
begin
  Result := inherited CompleteConnect(ReceivePin);
  if(SUCCEEDED(Result)) then
  begin
    if (not IsStopped) and (FAllocator <> nil) then
    begin
      Result := FAllocator.Commit;
      ASSERT(Result <> VFW_E_ALREADY_COMMITTED);
    end;
  end;
end;

function TBCDynamicOutputPin.StartUsingOutputPin: HRESULT;
var
  WaitEvents: array[0..1] of THandle;
  NumWaitEvents: DWORD;
  ReturnValue: DWORD;
begin
  // The caller should not hold m_BlockStateLock.  If the caller does,
  // a deadlock could occur.
  ASSERT(FBlockStateLock.CritCheckIn);

  FBlockStateLock.Lock;
  try
    {$IFDEF _DEBUG}
    AssertValid;
    {$ENDIF} // _DEBUG

    // Are we in the middle of a block operation?
    while(BLOCKED = FBlockState) do
    begin
      FBlockStateLock.Unlock;

      // If this ASSERT fires, a deadlock could occur.  The caller should make sure
      // that this thread never acquires the Block State lock more than once.
      ASSERT(FBlockStateLock.CritCheckIn);

      // WaitForMultipleObjects() returns WAIT_OBJECT_0 if the unblock event
      // is fired.  It returns WAIT_OBJECT_0 + 1 if the stop event if fired.
      // See the Windows SDK documentation for more information on
      // WaitForMultipleObjects().

      WaitEvents[0] := FUnblockOutputPinEvent;
      WaitEvents[0] := FStopEvent;

      NumWaitEvents := sizeof(WaitEvents) div sizeof(THANDLE);

      ReturnValue := WaitForMultipleObjects(NumWaitEvents, @WaitEvents, False, INFINITE);

      FBlockStateLock.Lock;

      {$IFDEF _DEBUG}
      AssertValid;
      {$ENDIF} // _DEBUG

      case ReturnValue of
        WAIT_OBJECT_0: break;
        WAIT_OBJECT_0 + 1:
        begin
          Result := VFW_E_STATE_CHANGED;
          Exit;
        end;
        WAIT_FAILED:
        begin
          Result := AmGetLastErrorToHResult;
          Exit;
        end;
        else
        begin
          {$IFDEF _DEBUG}
          DbgLog('An Unexpected case occured in TBCDynamicOutputPin.StartUsingOutputPin().');
          {$ENDIF} // _DEBUG
          Result := E_UNEXPECTED;
          Exit;
        end;
      end;
    end;

    inc(FNumOutstandingOutputPinUsers);

    {$IFDEF _DEBUG}
    AssertValid;
    {$ENDIF} // _DEBUG

    Result := S_OK;
  finally
    FBlockStateLock.Unlock;
  end;
end;

procedure TBCDynamicOutputPin.StopUsingOutputPin;
begin
  FBlockStateLock.Lock;
  try
    {$IFDEF _DEBUG}
    AssertValid;
    {$ENDIF} // _DEBUG

    dec(FNumOutstandingOutputPinUsers);

    if(FNumOutstandingOutputPinUsers = 0) and (NOT_BLOCKED <> FBlockState)
      then BlockOutputPin;

    {$IFDEF _DEBUG}
    AssertValid;
    {$ENDIF} // _DEBUG
  finally
    FBlockStateLock.Unlock;
  end;
end;

function TBCDynamicOutputPin.StreamingThreadUsingOutputPin: Boolean;
begin
  FBlockStateLock.Lock;
  try
    Result := (FNumOutstandingOutputPinUsers > 0);
  finally
    FBlockStateLock.UnLock;
  end;
end;

function TBCDynamicOutputPin.ChangeOutputFormat(const pmt: PAMMEdiaType; tSegmentStart, tSegmentStop:
                            TreferenceTime; dSegmentRate: Double): HRESULT;
begin
  // The caller should call StartUsingOutputPin() before calling this
  // method.
  ASSERT(StreamingThreadUsingOutputPin);

  // Callers should always pass a valid media type to ChangeOutputFormat() .
  ASSERT(pmt <> nil);

  Result := ChangeMediaType(pmt);
  if (FAILED(Result)) then Exit;

  Result :=DeliverNewSegment(tSegmentStart, tSegmentStop, dSegmentRate);
  if(FAILED(Result)) then Exit;

  Result := S_OK;
end;

function TBCDynamicOutputPin.ChangeMediaType(const pmt: PAMMediaType): HRESULT;
var
  pConnection: IPinConnection;
begin
  // The caller should call StartUsingOutputPin() before calling this
  // method.
  ASSERT(StreamingThreadUsingOutputPin);

  // This function assumes the filter graph is running.
  ASSERT(not IsStopped);

  if (not IsConnected) then
  begin
    Result := VFW_E_NOT_CONNECTED;
    Exit;
  end;

  //  First check if the downstream pin will accept a dynamic
  //  format change

  FConnected.QueryInterface(IID_IPinConnection, pConnection);
  if(pConnection <> nil) then
  begin
    if(S_OK = pConnection.DynamicQueryAccept(pmt^)) then
    begin
      Result := ChangeMediaTypeHelper(pmt);
      if(FAILED(Result)) then Exit;
      Result := S_OK;
      Exit;
    end;
  end;

  // Can't do the dynamic connection
  Result := DynamicReconnect(pmt);
end;

// this method has to be called from the thread that is pushing data,
// and it's the caller's responsibility to make sure that the thread
// has no outstand samples because they cannot be delivered after a
// reconnect
//
function TBCDynamicOutputPin.DynamicReconnect(const pmt: PAMMediaType): HRESULT;
begin
  // The caller should call StartUsingOutputPin() before calling this
  // method.
  ASSERT(StreamingThreadUsingOutputPin);

  if(FGraphConfig = nil) or (FStopEvent = 0) then
  begin
    Result := E_FAIL;
    Exit;
  end;

  Result := FGraphConfig.Reconnect(Self,nil,pmt,nil,FStopEvent,
            AM_GRAPH_CONFIG_RECONNECT_CACHE_REMOVED_FILTERS);
end;

function TBCDynamicOutputPin.SynchronousBlockOutputPin: HRESULT;
var
  NotifyCallerPinBlockedEvent: THandle;
begin
  NotifyCallerPinBlockedEvent := CreateEvent(nil,   // The event will have the default security attributes.
                                             False, // This is an automatic reset event.
                                             False, // The event is initially unsignaled.
                                             nil);  // The event is not named.

  // CreateEvent() returns NULL if an error occurs.
  if(NotifyCallerPinBlockedEvent = 0) then
  begin
    Result := AmGetLastErrorToHResult;
    Exit;
  end;

  Result := AsynchronousBlockOutputPin(NotifyCallerPinBlockedEvent);
  if(FAILED(Result)) then
  begin
    // This call should not fail because we have access to hNotifyCallerPinBlockedEvent
    // and hNotifyCallerPinBlockedEvent is a valid event.
  {$IFOPT C+}
    ASSERT(CloseHandle(NotifyCallerPinBlockedEvent));
  {$ELSE}
    CloseHandle(NotifyCallerPinBlockedEvent);
  {$ENDIF}
    Exit;
  end;

  Result := WaitEvent(NotifyCallerPinBlockedEvent);

  // This call should not fail because we have access to hNotifyCallerPinBlockedEvent
  // and hNotifyCallerPinBlockedEvent is a valid event.
{$IFOPT C+}
  ASSERT(CloseHandle(NotifyCallerPinBlockedEvent));
{$ELSE}
  CloseHandle(NotifyCallerPinBlockedEvent);
{$ENDIF}

  if(FAILED(Result)) then Exit;

  Result := S_OK;
end;

function TBCDynamicOutputPin.AsynchronousBlockOutputPin(NotifyCallerPinBlockedEvent: THandle): HRESULT;
var
  Success : Boolean;
begin
  // This function holds the m_BlockStateLock because it uses
  // m_dwBlockCallerThreadID, m_BlockState and
  // m_hNotifyCallerPinBlockedEvent.
  FBlockStateLock.Lock;
  try
    if (NOT_BLOCKED <> FBlockState) then
    begin
      if(FBlockCallerThreadID = GetCurrentThreadId)
        then Result := VFW_E_PIN_ALREADY_BLOCKED_ON_THIS_THREAD
        else Result := VFW_E_PIN_ALREADY_BLOCKED;
      Exit;
    end;

    Success := DuplicateHandle(GetCurrentProcess,
                               NotifyCallerPinBlockedEvent,
                               GetCurrentProcess,
                               @FNotifyCallerPinBlockedEvent,
                               EVENT_MODIFY_STATE,
                               False,
                               0);
    if not Success then
    begin
      Result := AmGetLastErrorToHResult;
      Exit;
    end;

    FBlockState := PENDING;
    FBlockCallerThreadID := GetCurrentThreadId;

    // The output pin cannot be blocked if the streaming thread is
    // calling IPin::NewSegment(), IPin::EndOfStream(), IMemInputPin::Receive()
    // or IMemInputPin::ReceiveMultiple() on the connected input pin.  Also, it
    // cannot be blocked if the streaming thread is calling DynamicReconnect(),
    // ChangeMediaType() or ChangeOutputFormat().

    // The output pin can be immediately blocked.
    if not StreamingThreadUsingOutputPin then BlockOutputPin();
    
    Result := S_OK;
  finally
    FBlockStateLock.Unlock;
  end;
end;

function TBCDynamicOutputPin.UnblockOutputPin: HRESULT;
begin
  // UnblockOutputPin() holds the m_BlockStateLock because it
  // uses m_BlockState, m_dwBlockCallerThreadID and
  // m_hNotifyCallerPinBlockedEvent.
  FBlockStateLock.Lock;
  try
    if (NOT_BLOCKED = FBlockState) then
    begin
      Result := S_FALSE;
      Exit;
    end;

    // This should not fail because we successfully created the event
    // and we have the security permissions to change it's state.
  {$IFOPT C+}
    ASSERT(SetEvent(FUnblockOutputPinEvent));
  {$ELSE}
    SetEvent(FUnblockOutputPinEvent);
  {$ENDIF}

    // Cancel the block operation if it's still pending.
    if (FNotifyCallerPinBlockedEvent <> 0) then
    begin
      // This event should not fail because AsynchronousBlockOutputPin() successfully
      // duplicated this handle and we have the appropriate security permissions.
    {$IFOPT C+}
      ASSERT(SetEvent(FNotifyCallerPinBlockedEvent));
      ASSERT(CloseHandle(FNotifyCallerPinBlockedEvent));
    {$ELSE}
      SetEvent(FNotifyCallerPinBlockedEvent);
      CloseHandle(FNotifyCallerPinBlockedEvent);
    {$ENDIF}
    end;

    FBlockState := NOT_BLOCKED;
    FBlockCallerThreadID := 0;
    FNotifyCallerPinBlockedEvent := 0;

    Result := S_OK;
  finally
    FBlockStateLock.Unlock;
  end;
end;

procedure TBCDynamicOutputPin.BlockOutputPin;
begin
  // The caller should always hold the m_BlockStateLock because this function
  // uses m_BlockState and m_hNotifyCallerPinBlockedEvent.
  ASSERT(FBlockStateLock.CritCheckIn);

  // This function should not be called if the streaming thread is modifying
  // the connection state or it's passing data downstream.
  ASSERT(not StreamingThreadUsingOutputPin);

  // This should not fail because we successfully created the event
  // and we have the security permissions to change it's state.
{$IFOPT C+}
  ASSERT(ResetEvent(FUnblockOutputPinEvent));
{$ELSE}
  ResetEvent(FUnblockOutputPinEvent);
{$ENDIF}

  // This event should not fail because AsynchronousBlockOutputPin() successfully
  // duplicated this handle and we have the appropriate security permissions.
{$IFOPT C+}
  ASSERT(SetEvent(FNotifyCallerPinBlockedEvent));
  ASSERT(CloseHandle(FNotifyCallerPinBlockedEvent));
{$ELSE}
  SetEvent(FNotifyCallerPinBlockedEvent);
  CloseHandle(FNotifyCallerPinBlockedEvent);
{$ENDIF}

  FBlockState := BLOCKED;
  FNotifyCallerPinBlockedEvent := 0;
end;

procedure TBCDynamicOutputPin.ResetBlockState;
begin

end;

class function TBCDynamicOutputPin.WaitEvent(Event: THandle): HRESULT;
var
  ReturnValue: DWORD;
begin
  ReturnValue := WaitForSingleObject(Event, INFINITE);

  case ReturnValue of
    WAIT_OBJECT_0: Result := S_OK;
    WAIT_FAILED  : Result := AmGetLastErrorToHResult;
    else
    begin
      {$IFDEF _DEBUG}
      DbgLog('An Unexpected case occured in TBCDynamicOutputPin::WaitEvent.');
      {$ENDIF}
      Result := E_UNEXPECTED;
    end;
  end;
end;

function TBCDynamicOutputPin.Initialize: HRESULT;
begin
  FUnblockOutputPinEvent := CreateEvent(nil,   // The event will have the default security descriptor.
                                        True,  // This is a manual reset event.
                                        True,  // The event is initially signaled.
                                        nil);  // The event is not named.

  // CreateEvent() returns NULL if an error occurs.
  if (FUnblockOutputPinEvent = 0) then
  begin
    Result := AmGetLastErrorToHResult;
    Exit;
  end;

  //  Set flag to say we can reconnect while streaming.
  CanReconnectWhenActive := True;

  Result := S_OK;
end;

function TBCDynamicOutputPin.ChangeMediaTypeHelper(const pmt: PAMMediaType): HRESULT;
var
  InputPinRequirements: ALLOCATOR_PROPERTIES;
begin
  // The caller should call StartUsingOutputPin() before calling this
  // method.
  ASSERT(StreamingThreadUsingOutputPin);

  Result := FConnected.ReceiveConnection(Self,pmt^);
  if(FAILED(Result)) then Exit;

  Result := SetMediaType(pmt);
  if(FAILED(Result)) then Exit;

  // Does this pin use the local memory transport?
  if(FInputPin <> nil) then
  begin
    // This function assumes that m_pInputPin and m_Connected are
    // two different interfaces to the same object.
    ASSERT(IsEqualObject(FConnected, FInputPin));

    InputPinRequirements.cbAlign := 0;
    InputPinRequirements.cbBuffer := 0;
    InputPinRequirements.cbPrefix := 0;
    InputPinRequirements.cBuffers := 0;

    FInputPin.GetAllocatorRequirements(InputPinRequirements);

    // A zero allignment does not make any sense.
    if(0 = InputPinRequirements.cbAlign)
      then InputPinRequirements.cbAlign := 1;

    Result := FAllocator.Decommit;
    if(FAILED(Result)) then Exit;

    Result := DecideBufferSize(FAllocator, @InputPinRequirements);
    if(FAILED(Result)) then Exit;

    Result := FAllocator.Commit;
    if(FAILED(Result)) then Exit;

    Result := FInputPin.NotifyAllocator(FAllocator, FPinUsesReadOnlyAllocator);
    if(FAILED(Result)) then Exit;
  end;

  Result := S_OK;
end;

{$IFDEF _DEBUG}
procedure TBCDynamicOutputPin.AssertValid;
begin
  // Make sure the object was correctly initialized.

  // This ASSERT only fires if the object failed to initialize
  // and the user ignored the constructor's return code (phr).
  ASSERT(FUnblockOutputPinEvent <> 0);

  // If either of these ASSERTs fire, the user did not correctly call
  // SetConfigInfo().
  ASSERT(FStopEvent <> 0);
  ASSERT(FGraphConfig <> nil);

  // Make sure the block state is consistent.

  FBlockStateLock.Lock;
  try
    // BLOCK_STATE variables only have three legal values: PENDING, BLOCKED and NOT_BLOCKED.
    ASSERT((NOT_BLOCKED = FBlockState) or (PENDING = FBlockState) or (BLOCKED = FBlockState));

    // m_hNotifyCallerPinBlockedEvent is only needed when a block operation cannot complete
    // immediately.
    ASSERT(((FNotifyCallerPinBlockedEvent = 0) and (PENDING <> FBlockState)) or
           ((FNotifyCallerPinBlockedEvent <> 0) and (PENDING = FBlockState)) );

    // m_dwBlockCallerThreadID should always be 0 if the pin is not blocked and
    // the user is not trying to block the pin.
    ASSERT((0 = FBlockCallerThreadID) or (NOT_BLOCKED <> FBlockState));

    // If this ASSERT fires, the streaming thread is using the output pin and the
    // output pin is blocked.
    ASSERT(((0 <> FNumOutstandingOutputPinUsers) and (BLOCKED <> FBlockState)) or
           ((0 = FNumOutstandingOutputPinUsers) and (NOT_BLOCKED <> FBlockState)) or
           ((0 = FNumOutstandingOutputPinUsers) and (NOT_BLOCKED = FBlockState)) );
  finally
    FBlockStateLock.UnLock;
  end;
end;
{$ENDIF}
// milenko end

{ TBCTransformInputPin }

// enter flushing state. Call default handler to block Receives, then
// pass to overridable method in filter

function TBCTransformInputPin.BeginFlush: HRESULT;
begin
  FTransformFilter.FcsFilter.Lock;
  try
    //  Are we actually doing anything?
    ASSERT(FTransformFilter.FOutput <> nil);
    if ((not IsConnected) or (not FTransformFilter.FOutput.IsConnected)) then
      begin
        result := VFW_E_NOT_CONNECTED;
        exit;
      end;
    result := inherited BeginFlush;
    if FAILED(result) then exit;
    result := FTransformFilter.BeginFlush;
  finally
    FTransformFilter.FcsFilter.UnLock;
  end;
end;

// provides derived filter a chance to release it's extra interfaces

function TBCTransformInputPin.BreakConnect: HRESULT;
begin
  ASSERT(IsStopped);
  FTransformFilter.BreakConnect(PINDIR_INPUT);
  result := inherited BreakConnect;
end;

function TBCTransformInputPin.CheckConnect(Pin: IPin): HRESULT;
begin
  result := FTransformFilter.CheckConnect(PINDIR_INPUT, Pin);
  if FAILED(result) then exit;
  result := inherited CheckConnect(Pin);
end;

// check that we can support a given media type

function TBCTransformInputPin.CheckMediaType(
  mtIn: PAMMediaType): HRESULT;
begin
  // Check the input type
  result := FTransformFilter.CheckInputType(mtIn);
  if (S_OK <> result) then exit;
  // if the output pin is still connected, then we have
  // to check the transform not just the input format
  if ((FTransformFilter.FOutput <> nil) and
      (FTransformFilter.FOutput.IsConnected)) then
    begin
      result := FTransformFilter.CheckTransform(mtIn,
          FTransformFilter.FOutput.AMMediaType);
    end;
end;

function TBCTransformInputPin.CheckStreaming: HRESULT;
begin
  ASSERT(FTransformFilter.FOutput <> nil);
  if(not FTransformFilter.FOutput.IsConnected) then
    begin
      result := VFW_E_NOT_CONNECTED;
      exit;
    end
  else
    begin
      //  Shouldn't be able to get any data if we're not connected!
      ASSERT(IsConnected);
      //  we're flushing
      if FFlushing then
        begin
          result := S_FALSE;
          exit;
        end;
      //  Don't process stuff in Stopped state
      if IsStopped then
        begin
          result := VFW_E_WRONG_STATE;
          exit;
        end;
      if FRunTimeError then
        begin
          result := VFW_E_RUNTIME_ERROR;
          exit;
        end;
      result := S_OK;
    end;
end;

function TBCTransformInputPin.CompleteConnect(ReceivePin: IPin): HRESULT;
begin
  result := FTransformFilter.CompleteConnect(PINDIR_INPUT, ReceivePin);
  if FAILED(result) then exit;
  result := inherited CompleteConnect(ReceivePin);
end;

constructor TBCTransformInputPin.Create(ObjectName: string;
  TransformFilter: TBCTransformFilter; out hr: HRESULT; Name: WideString);
begin
  inherited  Create(ObjectName, TransformFilter, TransformFilter.FcsFilter, hr, Name);
{$IFDEF _DEBUG}
  DbgLog(self, 'TBCTransformInputPin.Create');
{$ENDIF}
  FTransformFilter := TransformFilter;
end;

// leave flushing state.
// Pass to overridable method in filter, then call base class
// to unblock receives (finally)

destructor TBCTransformInputPin.destroy;
begin
{$IFDEF _DEBUG}
  DbgLog(self, 'TBCTransformInputPin.destroy');
{$ENDIF}
  inherited;
end;

function TBCTransformInputPin.EndFlush: HRESULT;
begin
  FTransformFilter.FcsFilter.Lock;
  try
    //  Are we actually doing anything?
    ASSERT(FTransformFilter.FOutput <> nil);
    if((not IsConnected) or (not FTransformFilter.FOutput.IsConnected)) then
      begin
        result := VFW_E_NOT_CONNECTED;
        exit;
      end;

    result := FTransformFilter.EndFlush;
    if FAILED(result) then exit;
    result := inherited EndFlush;
  finally
    FTransformFilter.FcsFilter.UnLock;
  end;
end;

// provide EndOfStream that passes straight downstream
// (there is no queued data)

function TBCTransformInputPin.EndOfStream: HRESULT;
begin
  FTransformFilter.FcsReceive.Lock;
  try
    result := CheckStreaming;
    if (S_OK = result) then
      result := FTransformFilter.EndOfStream;
  finally
    FTransformFilter.FcsReceive.UnLock;
  end;
end;

function TBCTransformInputPin.NewSegment(Start, Stop: TReferenceTime;
  Rate: double): HRESULT;
begin
  //  Save the values in the pin
  inherited NewSegment(Start, Stop, Rate);
  result := FTransformFilter.NewSegment(Start, Stop, Rate);
end;

function TBCTransformInputPin.QueryId(out id: PWideChar): HRESULT;
begin
// milenko start (AMGetWideString was bugged, now the second line is not needed)
  Result := AMGetWideString('In', Id);
//  if id <> nil then result := S_OK else result := S_FALSE;
// milenko end
end;

// here's the next block of data from the stream.
// AddRef it yourself if you need to hold it beyond the end
// of this call.

function TBCTransformInputPin.Receive(pSample: IMediaSample): HRESULT;
begin
  FTransformFilter.FcsReceive.Lock;
  try
    ASSERT(pSample <> nil);
    // check all is well with the base class
    result := inherited Receive(pSample);
    if (result = S_OK) then
      result := FTransformFilter.Receive(pSample);
  finally
    FTransformFilter.FcsReceive.Unlock;
  end;
end;

// set the media type for this connection

function TBCTransformInputPin.SetMediaType(mt: PAMMediaType): HRESULT;
begin
  // Set the base class media type (should always succeed)
  result := inherited SetMediaType(mt);
  if FAILED(result) then exit;
  // check the transform can be done (should always succeed)
{$IFOPT C+}
  ASSERT(FTransformFilter.CheckInputType(mt) = S_OK);
{$ELSE}
  FTransformFilter.CheckInputType(mt);
{$ENDIF}
  result := FTransformFilter.SetMediaType(PINDIR_INPUT,mt);
end;

{ TBCCritSec }

constructor TBCCritSec.Create;
begin
  InitializeCriticalSection(FCritSec);
  {$IFDEF _DEBUG}
     FcurrentOwner := 0;
     FlockCount    := 0;
//     {$IFDEF TRACE}
//     FTrace        := True;
//     {$ELSE}
//     FTrace        := FALSE;
//     {$ENDIF}
  {$ENDIF}
end;

function TBCCritSec.CritCheckIn: boolean;
begin
{$IFDEF _DEBUG}
  result := (GetCurrentThreadId = Self.FcurrentOwner);
{$ELSE}
  result := True;
{$ENDIF}
end;

function TBCCritSec.CritCheckOut: boolean;
begin
{$IFDEF _DEBUG}
  result := (GetCurrentThreadId <> Self.FcurrentOwner);
{$ELSE}
  result := false;
{$ENDIF}
end;

destructor TBCCritSec.Destroy;
begin
  DeleteCriticalSection(FCritSec)
end;

procedure TBCCritSec.Lock;
begin
  {$IFDEF _DEBUG}
    if ((FCurrentOwner <> 0)  and (FCurrentOwner <> GetCurrentThreadId)) then
    begin
      // already owned, but not by us
    {$IFDEF TRACE}
      DbgLog(format('Thread %d about to wait for lock %x owned by %d',
        [GetCurrentThreadId, longint(self), FCurrentOwner]));
    {$ENDIF}
    end;
  {$ENDIF}
    EnterCriticalSection(FCritSec);
  {$IFDEF _DEBUG}
    inc(FLockCount);
    if (FLockCount > 0) then
    begin
      // we now own it for the first time.  Set owner information
      FcurrentOwner := GetCurrentThreadId;
    {$IFDEF TRACE}
      DbgLog(format('Thread %d now owns lock %x', [FcurrentOwner, LongInt(self)]));
    {$ENDIF}
    end;
  {$ENDIF}
end;

procedure TBCCritSec.UnLock;
begin
  {$IFDEF _DEBUG}
     dec(FlockCount);
     if(FlockCount = 0) then
     begin
       // about to be unowned
     {$IFDEF TRACE}
       DbgLog(format('Thread %d releasing lock %x', [FcurrentOwner, LongInt(Self)]));
     {$ENDIF}
       FcurrentOwner := 0;
    end;
  {$ENDIF}
  LeaveCriticalSection(FCritSec)
end;

{ TBCTransformFilter }

// Return S_FALSE to mean "pass the note on upstream"
// Return NOERROR (Same as S_OK)
// to mean "I've done something about it, don't pass it on"

function TBCTransformFilter.AlterQuality(const q: TQuality): HRESULT;
begin
  result := S_FALSE;
end;

// enter flush state. Receives already blocked
// must override this if you have queued data or a worker thread

function TBCTransformFilter.BeginFlush: HRESULT;
begin
  result := NOERROR;
  if (FOutput <> nil) then
    // block receives -- done by caller (CBaseInputPin::BeginFlush)
    // discard queued data -- we have no queued data
    // free anyone blocked on receive - not possible in this filter
    // call downstream
    result := FOutput.DeliverBeginFlush;
end;

function TBCTransformFilter.BreakConnect(dir: TPinDirection): HRESULT;
begin
  result := NOERROR;
end;

function TBCTransformFilter.CheckConnect(dir: TPinDirection;
  Pin: IPin): HRESULT;
begin
  result := NOERROR;
end;

function TBCTransformFilter.CompleteConnect(direction: TPinDirection;
  ReceivePin: IPin): HRESULT;
begin
  result := NOERROR;
end;

constructor TBCTransformFilter.Create(ObjectName: string; unk: IUnKnown;
  const clsid: TGUID);
begin
  FcsFilter := TBCCritSec.Create;
  FcsReceive := TBCCritSec.Create;
  inherited Create(ObjectName,Unk,FcsFilter, clsid);
  FInput         := nil;
  FOutput        := nil;
  FEOSDelivered  := FALSE;
  FQualityChanged:= FALSE;
  FSampleSkipped := FALSE;
{$ifdef PERF}
//  RegisterPerfId;
{$endif}
end;

constructor TBCTransformFilter.CreateFromFactory(Factory: TBCClassFactory; const Controller: IUnknown);
begin
  Create(Factory.FName, Controller, Factory.FClassID);
end;

destructor TBCTransformFilter.destroy;
begin
  if FInput <> nil then FInput.Free;
  if FOutput <> nil then FOutput.Free;
{$IFDEF _DEBUG}
  DbgLog(self, 'TBCTransformFilter.destroy');
{$ENDIF}
  FcsReceive.Free;
  inherited;
end;

// leave flush state. must override this if you have queued data
// or a worker thread

function TBCTransformFilter.EndFlush: HRESULT;
begin
  // sync with pushing thread -- we have no worker thread
  // ensure no more data to go downstream -- we have no queued data
  // call EndFlush on downstream pins
  ASSERT(FOutput <> nil);
  result := FOutput.DeliverEndFlush;
  // caller (the input pin's method) will unblock Receives
end;

// EndOfStream received. Default behaviour is to deliver straight
// downstream, since we have no queued data. If you overrode Receive
// and have queue data, then you need to handle this and deliver EOS after
// all queued data is sent

function TBCTransformFilter.EndOfStream: HRESULT;
begin
  result := NOERROR;
  if (FOutput <> nil) then
    result := FOutput.DeliverEndOfStream;
end;

// If Id is In or Out then return the IPin* for that pin
// creating the pin if need be.  Otherwise return NULL with an error.

function TBCTransformFilter.FindPin(Id: PWideChar; out ppPin: IPin): HRESULT;
begin
    if(WideString(Id) = 'In')  then ppPin := GetPin(0) else
    if(WideString(Id) = 'Out') then ppPin := GetPin(1) else
      begin
        ppPin := nil;
        result := VFW_E_NOT_FOUND;
        exit;
      end;

   result := NOERROR;
   if(ppPin = nil) then result := E_OUTOFMEMORY;
end;

// return a non-addrefed CBasePin * for the user to addref if he holds onto it
// for longer than his pointer to us. We create the pins dynamically when they
// are asked for rather than in the constructor. This is because we want to
// give the derived class an oppportunity to return different pin objects

// We return the objects as and when they are needed. If either of these fails
// then we return NULL, the assumption being that the caller will realise the
// whole deal is off and destroy us - which in turn will delete everything.

function TBCTransformFilter.GetPin(n: integer): TBCBasePin;
var hr: HRESULT;
begin
  hr := S_OK;
  // Create an input pin if necessary
  if(FInput = nil) then
  begin
    FInput := TBCTransformInputPin.Create('Transform input pin',
        self,        // Owner filter
        hr,          // Result code
        'XForm In'); // Pin name

    //  Can't fail
    ASSERT(SUCCEEDED(hr));
    if(FInput = nil) then
    begin
      result := nil;
      exit;
    end;
    FOutput := TBCTransformOutputPin.Create('Transform output pin',
        self,           // Owner filter
        hr,             // Result code
        'XForm Out');   // Pin name

    // Can't fail
    ASSERT(SUCCEEDED(hr));
    if(FOutput = nil) then FreeAndNil(FInput);
  end;

  // Return the appropriate pin

  case n of
    0 : result := FInput;
    1 : result := FOutput;
    else
      result := nil;
  end;
end;

function TBCTransformFilter.GetPinCount: integer;
begin
  result := 2;
end;

// Set up our output sample

function TBCTransformFilter.InitializeOutputSample(Sample: IMediaSample;
  out OutSample: IMediaSample): HRESULT;
var
  Props: PAMSample2Properties;
  Flags: DWORD;
  Start, Stop: PReferenceTime;
  OutSample2: IMediaSample2;
  OutProps: TAMSample2Properties;
  MediaStart, MediaEnd: Int64;
begin
  // default - times are the same

  Props := FInput.SampleProps;
  if FSampleSkipped then Flags := AM_GBF_PREVFRAMESKIPPED else Flags := 0;

  // This will prevent the image renderer from switching us to DirectDraw
  // when we can't do it without skipping frames because we're not on a
  // keyframe.  If it really has to switch us, it still will, but then we
  // will have to wait for the next keyframe
  if(not BOOL(Props.dwSampleFlags and AM_SAMPLE_SPLICEPOINT)) then Flags := Flags or AM_GBF_NOTASYNCPOINT;

  ASSERT(FOutput.FAllocator <> nil);
  if  BOOL(Props.dwSampleFlags and AM_SAMPLE_TIMEVALID) then Start := @Props.tStart else Start := nil;
  if  BOOL(Props.dwSampleFlags and AM_SAMPLE_STOPVALID) then Stop := @Props.tStop else Stop := nil;
  result := FOutput.FAllocator.GetBuffer(OutSample, Start, Stop, Flags);
  if FAILED(result) then exit;
  ASSERT(OutSample <> nil);
  if SUCCEEDED(OutSample.QueryInterface(IID_IMediaSample2, OutSample2)) then
    begin
    {$IFOPT C+}
      ASSERT(SUCCEEDED(OutSample2.GetProperties(4*4, OutProps)));
    {$ELSE}
      OutSample2.GetProperties(4*4, OutProps);
    {$ENDIF}
      OutProps.dwTypeSpecificFlags := Props.dwTypeSpecificFlags;
      OutProps.dwSampleFlags := (OutProps.dwSampleFlags and AM_SAMPLE_TYPECHANGED) or
          (Props.dwSampleFlags and (not AM_SAMPLE_TYPECHANGED));

      OutProps.tStart := Props.tStart;
      OutProps.tStop  := Props.tStop;
      OutProps.cbData := (4*4) + (2*8);

      OutSample2.SetProperties((4*4)+(2*8), OutProps);
      if BOOL(Props.dwSampleFlags and AM_SAMPLE_DATADISCONTINUITY) then FSampleSkipped := FALSE;
      OutSample2 := nil;
    end
  else
    begin
      if BOOL(Props.dwSampleFlags and AM_SAMPLE_TIMEVALID) then
        OutSample.SetTime(@Props.tStart, @Props.tStop);
      if BOOL(Props.dwSampleFlags and AM_SAMPLE_SPLICEPOINT) then
        OutSample.SetSyncPoint(True);
      if BOOL(Props.dwSampleFlags and AM_SAMPLE_DATADISCONTINUITY) then
        begin
          OutSample.SetDiscontinuity(True);
          FSampleSkipped := FALSE;
        end;
      // Copy the media times
      if (Sample.GetMediaTime(MediaStart,MediaEnd) = NOERROR) then
        OutSample.SetMediaTime(@MediaStart, @MediaEnd);
    end;
  result := S_OK;
end;

function TBCTransformFilter.NewSegment(Start, Stop: TReferenceTime;
  Rate: double): HRESULT;
begin
  result := S_OK;
  if (FOutput <> nil) then
    result := FOutput.DeliverNewSegment(Start, Stop, Rate);
end;

function TBCTransformFilter.Pause: HRESULT;
begin
  FcsFilter.Lock;
  try
    result := NOERROR;
    if (FState = State_Paused) then
      begin
        // (This space left deliberately blank)
      end
    // If we have no input pin or it isn't yet connected then when we are
    // asked to pause we deliver an end of stream to the downstream filter.
    // This makes sure that it doesn't sit there forever waiting for
    // samples which we cannot ever deliver without an input connection.

    else
      if ((FInput = nil) or (FInput.IsConnected = FALSE)) then
        begin
          if ((FOutput <> nil) and (FEOSDelivered = FALSE)) then
          begin
            FOutput.DeliverEndOfStream;
            FEOSDelivered := True;
          end;
          FState := State_Paused;
        end

    // We may have an input connection but no output connection
    // However, if we have an input pin we do have an output pin

    else
      if (FOutput.IsConnected = FALSE) then
        FState := State_Paused
      else
        begin
          if(FState = State_Stopped) then
          begin
              // allow a class derived from CTransformFilter
              // to know about starting and stopping streaming
              FcsReceive.Lock;
            try
              result := StartStreaming;
            finally
              FcsReceive.UnLock;
            end;
          end;
          if SUCCEEDED(result) then result := inherited Pause;
        end;
    FSampleSkipped := FALSE;
    FQualityChanged := FALSE;
  finally
    FcsFilter.UnLock;
  end;
end;

// override this to customize the transform process

function TBCTransformFilter.Receive(Sample: IMediaSample): HRESULT;
var
  Props: PAMSample2Properties;
  OutSample: IMediaSample;
begin
  //  Check for other streams and pass them on
  Props := FInput.SampleProps;
  if(Props.dwStreamId <> AM_STREAM_MEDIA) then
  begin
    result := FOutput.FInputPin.Receive(Sample);
    exit;
  end;
  // If no output to deliver to then no point sending us data
  ASSERT(FOutput <> nil) ;
  // Set up the output sample
  result := InitializeOutputSample(Sample, OutSample);
  if FAILED(result) then exit;
  result := Transform(Sample, OutSample);
  if FAILED(result) then
    begin
    {$IFDEF _DEBUG}
      DbgLog(self, 'Error from transform');
    {$ENDIF}
      exit;
    end
  else
    begin
      // the Transform() function can return S_FALSE to indicate that the
      // sample should not be delivered; we only deliver the sample if it's
      // really S_OK (same as NOERROR, of course.)
      if (result = NOERROR) then
        begin
          result := FOutput.FInputPin.Receive(OutSample);
          FSampleSkipped := FALSE;   // last thing no longer dropped
        end
      else
        begin
          // S_FALSE returned from Transform is a PRIVATE agreement
          // We should return NOERROR from Receive() in this cause because returning S_FALSE
          // from Receive() means that this is the end of the stream and no more data should
          // be sent.
          if (result = S_FALSE) then
          begin
            //  Release the sample before calling notify to avoid
            //  deadlocks if the sample holds a lock on the system
            //  such as DirectDraw buffers do
            OutSample := nil;
            FSampleSkipped := True;
            if not FQualityChanged then
            begin
              NotifyEvent(EC_QUALITY_CHANGE,0,0);
              FQualityChanged := True;
            end;
            result := NOERROR;
            exit;
          end;
        end;
    end;
  // release the output buffer. If the connected pin still needs it,
  // it will have addrefed it itself.
  OutSample := nil;
end;

function TBCTransformFilter.SetMediaType(direction: TPinDirection;
  pmt: PAMMediaType): HRESULT;
begin
  result := NOERROR;
end;

// override these two functions if you want to inform something
// about entry to or exit from streaming state.

function TBCTransformFilter.StartStreaming: HRESULT;
begin
  result := NOERROR;
end;

// override these so that the derived filter can catch them

function TBCTransformFilter.Stop: HRESULT;
begin
  FcsFilter.Lock;
  try
    if(FState = State_Stopped) then
    begin
      result := NOERROR;
      exit;
    end;
    // Succeed the Stop if we are not completely connected
    ASSERT((FInput = nil) or (FOutput <> nil));
    if((FInput = nil) or (FInput.IsConnected = FALSE) or (FOutput.IsConnected = FALSE)) then
    begin
      FState := State_Stopped;
      FEOSDelivered := FALSE;
      result := NOERROR;
      exit;
    end;
    ASSERT(FInput <> nil);
    ASSERT(FOutput <> nil);
    // decommit the input pin before locking or we can deadlock
    FInput.Inactive;
    // synchronize with Receive calls
    FcsReceive.Lock;
    try
      FOutput.Inactive;
      // allow a class derived from CTransformFilter
      // to know about starting and stopping streaming
      result := StopStreaming;
      if SUCCEEDED(result) then
      begin
        // complete the state transition
        FState := State_Stopped;
        FEOSDelivered := FALSE;
      end;
    finally
      FcsReceive.UnLock;
    end;
  finally
    FcsFilter.UnLock;
  end;
end;

function TBCTransformFilter.StopStreaming: HRESULT;
begin
  result := NOERROR;
end;

function TBCTransformFilter.Transform(msIn, msout: IMediaSample): HRESULT;
begin
{$IFDEF _DEBUG}
  DbgLog(self, 'TBCTransformFilter.Transform should never be called');
{$ENDIF}
  result := E_UNEXPECTED;
end;

{ TBCTransformOutputPin }

// provides derived filter a chance to release it's extra interfaces

function TBCTransformOutputPin.BreakConnect: HRESULT;
begin
  //  Can't disconnect unless stopped
  ASSERT(IsStopped);
  FTransformFilter.BreakConnect(PINDIR_OUTPUT);
  result := inherited BreakConnect;
end;

// provides derived filter a chance to grab extra interfaces

function TBCTransformOutputPin.CheckConnect(Pin: IPin): HRESULT;
begin
  // we should have an input connection first
  ASSERT(FTransformFilter.FInput <> nil);
  if(FTransformFilter.FInput.IsConnected = FALSE) then
    begin
      result := E_UNEXPECTED;
      exit;
    end;

  result := FTransformFilter.CheckConnect(PINDIR_OUTPUT, Pin);
  if FAILED(result) then exit;
  result := inherited CheckConnect(Pin);
end;

// check a given transform - must have selected input type first

function TBCTransformOutputPin.CheckMediaType(
  mtOut: PAMMediaType): HRESULT;
begin
  // must have selected input first
  ASSERT(FTransformFilter.FInput <> nil);
  if(FTransformFilter.FInput.IsConnected = FALSE) then
    begin
      result := E_INVALIDARG;
      exit;
    end;
  result := FTransformFilter.CheckTransform(FTransformFilter.FInput.AMMediaType, mtOut);
end;

// Let derived class know when the output pin is connected

function TBCTransformOutputPin.CompleteConnect(ReceivePin: IPin): HRESULT;
begin
  result := FTransformFilter.CompleteConnect(PINDIR_OUTPUT, ReceivePin);
  if FAILED(result) then exit;
  result := inherited CompleteConnect(ReceivePin);
end;

constructor TBCTransformOutputPin.Create(ObjectName: string;
  TransformFilter: TBCTransformFilter; out hr: HRESULT; Name: WideString);
begin
  inherited create(ObjectName, TransformFilter, TransformFilter.FcsFilter, hr, Name);
  FPosition := nil;
{$IFDEF _DEBUG}
  DbgLog(self, 'TBCTransformOutputPin.Create');
{$ENDIF}
  FTransformFilter := TransformFilter;
end;

function TBCTransformOutputPin.DecideBufferSize(Alloc: IMemAllocator;
  Prop: PAllocatorProperties): HRESULT;
begin
  result := FTransformFilter.DecideBufferSize(Alloc, Prop);
end;

destructor TBCTransformOutputPin.destroy;
begin
{$IFDEF _DEBUG}
  DbgLog(self, 'TBCTransformOutputPin.Destroy');
{$ENDIF}
  FPosition := nil;
  inherited;
end;

function TBCTransformOutputPin.GetMediaType(Position: integer;
  out MediaType: PAMMediaType): HRESULT;
begin
  ASSERT(FTransformFilter.FInput <> nil);
  //  We don't have any media types if our input is not connected
  if(FTransformFilter.FInput.IsConnected) then
    begin
      result := FTransformFilter.GetMediaType(Position, MediaType);
      exit;
    end
  else
    result := VFW_S_NO_MORE_ITEMS;
end;

function TBCTransformOutputPin.NonDelegatingQueryInterface(
  const IID: TGUID; out Obj): HResult;
begin
  if IsEqualGUID(iid, IID_IMediaPosition) or IsEqualGUID(iid, IID_IMediaSeeking) then
    begin
      // we should have an input pin by now
      ASSERT(FTransformFilter.FInput <> nil);
      if (FPosition = nil) then
        begin
          result := CreatePosPassThru(GetOwner, FALSE, FTransformFilter.FInput, FPosition);
          if FAILED(result) then exit;
        end;
      result := FPosition.QueryInterface(iid, obj);
    end
  else
    result := inherited NonDelegatingQueryInterface(iid, obj);
end;

// Override this if you can do something constructive to act on the
// quality message.  Consider passing it upstream as well

// Pass the quality mesage on upstream.

function TBCTransformOutputPin.Notify(Sendr: IBaseFilter; q: TQuality): HRESULT;
begin
  // First see if we want to handle this ourselves
  result := FTransformFilter.AlterQuality(q);
  if (result <> S_FALSE) then exit;
  // S_FALSE means we pass the message on.
  // Find the quality sink for our input pin and send it there
  ASSERT(FTransformFilter.FInput <> nil);
  result := FTransformFilter.FInput.PassNotify(q);
end;

function TBCTransformOutputPin.QueryId(out Id: PWideChar): HRESULT;
begin
  result := AMGetWideString('Out', Id);
end;

// called after we have agreed a media type to actually set it in which case
// we run the CheckTransform function to get the output format type again

function TBCTransformOutputPin.SetMediaType(pmt: PAMMediaType): HRESULT;
begin
  ASSERT(FTransformFilter.FInput <> nil);

  // DCoder: This assertion sucks big time with Demo SampleGrabber Filter with
  // MEDIATYPE_NULL setup, so just disable it (it´s useless anyway ...)
  // ASSERT(not IsEqualGUID(FTransformFilter.FInput.AMMediaType.majortype,GUID_NULL));

  // Set the base class media type (should always succeed)
  result := inherited SetMediaType(pmt);
  if FAILED(result) then exit;
{$ifdef _DEBUG}
  if(FAILED(FTransformFilter.CheckTransform(FTransformFilter.FInput.AMMediaType, pmt))) then
    begin
      DbgLog(self, '*** This filter is accepting an output media type');
      DbgLog(self, '    that it can''t currently transform to.  I hope');
      DbgLog(self, '    it''s smart enough to reconnect its input.');
    end;
{$endif}
  result := FTransformFilter.SetMediaType(PINDIR_OUTPUT,pmt);
end;

// milenko start (added TBCVideoTransformFilter conversion)

{ TBCVideoTransformFilter }

// This class is derived from CTransformFilter, but is specialised to handle
// the requirements of video quality control by frame dropping.
// This is a non-in-place transform, (i.e. it copies the data) such as a decoder.

constructor TBCVideoTransformFilter.Create(Name: WideString; Unk: IUnknown; clsid: TGUID);
begin
  inherited Create(name, Unk, clsid);
  FitrLate := 0;
  FKeyFramePeriod := 0;      // No QM until we see at least 2 key frames
  FFramesSinceKeyFrame := 0;
  FSkipping := False;
  FtDecodeStart := 0;
  FitrAvgDecode := 300000;    // 30mSec - probably allows skipping
  FQualityChanged := False;
{$IFDEF PERF}
  RegisterPerfId();
{$ENDIF} // PERF
end;

destructor TBCVideoTransformFilter.Destroy;
begin
  inherited Destroy;
end;

// Overriden to reset quality management information

function TBCVideoTransformFilter.EndFlush: HRESULT;
begin
  FcsReceive.Lock;
  try
    // Reset our stats
    //
    // Note - we don't want to call derived classes here,
    // we only want to reset our internal variables and this
    // is a convenient way to do it
    StartStreaming;
    Result := inherited EndFlush;
  finally
    FcsReceive.UnLock;
  end;
end;

{$IFDEF PERF}
procedure TBCVideoTransformFilter.RegisterPerfId;
begin
  FidSkip        := MSR_REGISTER('Video Transform Skip frame');
  FidFrameType   := MSR_REGISTER('Video transform frame type');
  FidLate        := MSR_REGISTER('Video Transform Lateness');
  FidTimeTillKey := MSR_REGISTER('Video Transform Estd. time to next key');
//  inherited RegisterPerfId;
end;
{$ENDIF}

function TBCVideoTransformFilter.StartStreaming: HRESULT;
begin
  FitrLate := 0;
  FKeyFramePeriod := 0;       // No QM until we see at least 2 key frames
  FFramesSinceKeyFrame := 0;
  FSkipping := False;
  FtDecodeStart := 0;
  FitrAvgDecode := 300000;     // 30mSec - probably allows skipping
  FQualityChanged := False;
  FSampleSkipped := False;
  Result := NOERROR;
end;

// Reset our quality management state

function TBCVideoTransformFilter.AbortPlayback(hr: HRESULT): HRESULT;
begin
  NotifyEvent(EC_ERRORABORT, hr, 0);
  FOutput.DeliverEndOfStream;
  Result := hr;
end;

// Receive()
//
// Accept a sample from upstream, decide whether to process it
// or drop it.  If we process it then get a buffer from the
// allocator of the downstream connection, transform it into the
// new buffer and deliver it to the downstream filter.
// If we decide not to process it then we do not get a buffer.

// Remember that although this code will notice format changes coming into
// the input pin, it will NOT change its output format if that results
// in the filter needing to make a corresponding output format change.  Your
// derived filter will have to take care of that.  (eg. a palette change if
// the input and output is an 8 bit format).  If the input sample is discarded
// and nothing is sent out for this Receive, please remember to put the format
// change on the first output sample that you actually do send.
// If your filter will produce the same output type even when the input type
// changes, then this base class code will do everything you need.

function TBCVideoTransformFilter.Receive(Sample: IMediaSample): HRESULT;
var
  pmtOut, pmt: PAMMediaType;
  pOutSample: IMediaSample;
{$IFDEF _DEBUG}
  fccOut: TGUID;
	lCompression: LongInt;
	lBitCount: LongInt;
	lStride: LongInt;
  rcS: TRect;
  rcT: TRect;
  rcS1: TRect;
  rcT1: TRect;
{$ENDIF}
begin
  // If the next filter downstream is the video renderer, then it may
  // be able to operate in DirectDraw mode which saves copying the data
  // and gives higher performance.  In that case the buffer which we
  // get from GetDeliveryBuffer will be a DirectDraw buffer, and
  // drawing into this buffer draws directly onto the display surface.
  // This means that any waiting for the correct time to draw occurs
  // during GetDeliveryBuffer, and that once the buffer is given to us
  // the video renderer will count it in its statistics as a frame drawn.
  // This means that any decision to drop the frame must be taken before
  // calling GetDeliveryBuffer.

  ASSERT(FcsReceive.CritCheckIn);
  ASSERT(Sample <> nil);

  // If no output pin to deliver to then no point sending us data
  ASSERT (FOutput <> nil) ;

  // The source filter may dynamically ask us to start transforming from a
  // different media type than the one we're using now.  If we don't, we'll
  // draw garbage. (typically, this is a palette change in the movie,
  // but could be something more sinister like the compression type changing,
  // or even the video size changing)

  Sample.GetMediaType(pmt);
  if (pmt <> nil) and  (pmt.pbFormat <> nil) then
  begin
    // spew some debug output
    ASSERT(not IsEqualGUID(pmt.majortype, GUID_NULL));
  {$IFDEF _DEBUG}
    fccOut := pmt.subtype;
    lCompression := PVideoInfoHeader(pmt.pbFormat).bmiHeader.biCompression;
    lBitCount := PVideoInfoHeader(pmt.pbFormat).bmiHeader.biBitCount;
    lStride := (PVideoInfoHeader(pmt.pbFormat).bmiHeader.biWidth * lBitCount + 7) div 8;
    lStride := (lStride + 3) and not 3;

    rcS1 := PVideoInfoHeader(pmt.pbFormat).rcSource;
    rcT1 := PVideoInfoHeader(pmt.pbFormat).rcTarget;

    DbgLog(Self,'Changing input type on the fly to');
    DbgLog(Self,'FourCC: ' + inttohex(fccOut.D1,8) + ' Compression: ' + inttostr(lCompression) +
           ' BitCount: ' + inttostr(lBitCount));
    DbgLog(Self,'biHeight: ' + inttostr(PVideoInfoHeader(pmt.pbFormat).bmiHeader.biHeight) +
           ' rcDst: (' + inttostr(rcT1.left) + ', ' + inttostr(rcT1.top) + ', ' +
           inttostr(rcT1.right) + ', ' + inttostr(rcT1.bottom) + ')');
    DbgLog(Self,'rcSrc: (' + inttostr(rcS1.left) + ', ' + inttostr(rcS1.top) + ', ' +
           inttostr(rcS1.right) + ', ' + inttostr(rcS1.bottom) + ') Stride' + inttostr(lStride));
  {$ENDIF}

    // now switch to using the new format.  I am assuming that the
    // derived filter will do the right thing when its media type is
    // switched and streaming is restarted.

    StopStreaming();
    CopyMediaType(FInput.AMMediaType,pmt);
    DeleteMediaType(pmt);
    // if this fails, playback will stop, so signal an error
    Result := StartStreaming;
    if (FAILED(Result)) then
    begin
      Result := AbortPlayback(Result);
      Exit;
    end;
  end;

    // Now that we have noticed any format changes on the input sample, it's
    // OK to discard it.

  if ShouldSkipFrame(Sample) then
  begin
  {$IFDEF PERF}
//    MSR_NOTE(m_idSkip);
  {$ENDIF}
    FSampleSkipped := True;
    Result := NOERROR;
    Exit;
  end;

    // Set up the output sample
  Result := InitializeOutputSample(Sample, pOutSample);

  if (FAILED(Result)) then Exit;

  FSampleSkipped := False;

  // The renderer may ask us to on-the-fly to start transforming to a
  // different format.  If we don't obey it, we'll draw garbage

  pOutSample.GetMediaType(pmtOut);
  if (pmtOut <> nil) and (pmtOut.pbFormat <> nil) then
  begin
    // spew some debug output
    ASSERT(not IsEqualGUID(pmtOut.majortype, GUID_NULL));
  {$IFDEF _DEBUG}
    fccOut := pmtOut.subtype;
    lCompression := PVideoInfoHeader(pmtOut.pbFormat).bmiHeader.biCompression;
    lBitCount := PVideoInfoHeader(pmtOut.pbFormat).bmiHeader.biBitCount;
    lStride := (PVideoInfoHeader(pmtOut.pbFormat).bmiHeader.biWidth * lBitCount + 7) div 8;
    lStride := (lStride + 3) and not 3;

    rcS := PVideoInfoHeader(pmtOut.pbFormat).rcSource;
    rcT := PVideoInfoHeader(pmtOut.pbFormat).rcTarget;

    DbgLog(Self,'Changing input type on the fly to');
    DbgLog(Self,'FourCC: ' + inttohex(fccOut.D1,8) + ' Compression: ' + inttostr(lCompression) +
           ' BitCount: ' + inttostr(lBitCount));
    DbgLog(Self,'biHeight: ' + inttostr(PVideoInfoHeader(pmtOut.pbFormat).bmiHeader.biHeight) +
           ' rcDst: (' + inttostr(rcT1.left) + ', ' + inttostr(rcT1.top) + ', ' +
           inttostr(rcT1.right) + ', ' + inttostr(rcT1.bottom) + ')');
    DbgLog(Self,'rcSrc: (' + inttostr(rcS1.left) + ', ' + inttostr(rcS1.top) + ', ' +
           inttostr(rcS1.right) + ', ' + inttostr(rcS1.bottom) + ') Stride' + inttostr(lStride));
  {$ENDIF}

    // now switch to using the new format.  I am assuming that the
    // derived filter will do the right thing when its media type is
    // switched and streaming is restarted.

    StopStreaming();
    CopyMediaType(FOutput.AMMediaType,pmtOut);
    DeleteMediaType(pmtOut);
    Result := StartStreaming;

    if (SUCCEEDED(Result)) then
    begin
      // a new format, means a new empty buffer, so wait for a keyframe
      // before passing anything on to the renderer.
      // !!! a keyframe may never come, so give up after 30 frames
    {$IFDEF _DEBUG}
      DbgLog(Self,'Output format change means we must wait for a keyframe');
    {$ENDIF}
      FWaitForKey := 30;
      // if this fails, playback will stop, so signal an error
    end else
    begin
      //  Must release the sample before calling AbortPlayback
      //  because we might be holding the win16 lock or
      //  ddraw lock
      pOutSample := nil;
      AbortPlayback(Result);
      Exit;
    end;
  end;

  // After a discontinuity, we need to wait for the next key frame
  if (Sample.IsDiscontinuity = S_OK) then
  begin
  {$IFDEF _DEBUG}
    DbgLog(Self,'Non-key discontinuity - wait for keyframe');
  {$ENDIF}
    FWaitForKey := 30;
  end;

  // Start timing the transform (and log it if PERF is defined)

  if (SUCCEEDED(Result)) then
  begin
    FtDecodeStart := timeGetTime;
  {$IFDEF PERF}
//    MSR_START(FidTransform); // not added in conversion
  {$ENDIF}
    // have the derived class transform the data
    Result := Transform(Sample, pOutSample);

    // Stop the clock (and log it if PERF is defined)
  {$IFDEF PERF}
//    MSR_STOP(m_idTransform); // not added in conversion
  {$ENDIF}
    FtDecodeStart := timeGetTime - int64(FtDecodeStart);
    FitrAvgDecode := Round(FtDecodeStart * (10000 / 16) + 15 * (FitrAvgDecode / 16));

    // Maybe we're waiting for a keyframe still?
    if (FWaitForKey > 0) then dec(FWaitForKey);
    if (FWaitForKey > 0) and (Sample.IsSyncPoint = S_OK) then BOOL(FWaitForKey) := False;

    // if so, then we don't want to pass this on to the renderer
    if (FWaitForKey > 0) and (Result = NOERROR) then
    begin
    {$IFDEF _DEBUG}
      DbgLog(Self,'still waiting for a keyframe');
	    Result := S_FALSE;
    {$ENDIF}
    end;
  end;

  if (FAILED(Result)) then
  begin
  {$IFDEF _DEBUG}
    DbgLog(Self,'Error from video transform');
  {$ENDIF}
  end else
  begin
    // the Transform() function can return S_FALSE to indicate that the
    // sample should not be delivered; we only deliver the sample if it's
    // really S_OK (same as NOERROR, of course.)
    // Try not to return S_FALSE to a direct draw buffer (it's wasteful)
    // Try to take the decision earlier - before you get it.

    if (Result = NOERROR) then
    begin
    	Result := FOutput.Deliver(pOutSample);
    end else
    begin
      // S_FALSE returned from Transform is a PRIVATE agreement
      // We should return NOERROR from Receive() in this case because returning S_FALSE
      // from Receive() means that this is the end of the stream and no more data should
      // be sent.
      if (S_FALSE = Result) then
      begin
        //  We must Release() the sample before doing anything
        //  like calling the filter graph because having the
        //  sample means we may have the DirectDraw lock
        //  (== win16 lock on some versions)
        pOutSample := nil;
        FSampleSkipped := True;
        if not FQualityChanged then
        begin
          FQualityChanged := True;
          NotifyEvent(EC_QUALITY_CHANGE,0,0);
        end;
        Result := NOERROR;
        Exit;
      end;
    end;
  end;

  // release the output buffer. If the connected pin still needs it,
  // it will have addrefed it itself.
  pOutSample := nil;
  ASSERT(FcsReceive.CritCheckIn);
end;

function TBCVideoTransformFilter.AlterQuality(const q: TQuality): HRESULT;
begin
  // to reduce the amount of 64 bit arithmetic, m_itrLate is an int.
  // +, -, >, == etc  are not too bad, but * and / are painful.
  if (FitrLate > 300000000) then
  begin
    // Avoid overflow and silliness - more than 30 secs late is already silly
    FitrLate := 300000000;
   end else
   begin
     FitrLate := integer(q.Late);
   end;

  // We ignore the other fields

  // We're actually not very good at handling this.  In non-direct draw mode
  // most of the time can be spent in the renderer which can skip any frame.
  // In that case we'd rather the renderer handled things.
  // Nevertheless we will keep an eye on it and if we really start getting
  // a very long way behind then we will actually skip - but we'll still tell
  // the renderer (or whoever is downstream) that they should handle quality.

  Result := E_FAIL;     // Tell the renderer to do his thing.
end;

function TBCVideoTransformFilter.ShouldSkipFrame(pIn: IMediaSample): Boolean;
var
  Start, StopAt: TReferenceTime;
  itrFrame: integer;
  it: integer;
begin
  Result := pIn.GetTime(Start, StopAt) = S_OK;

  // Don't skip frames with no timestamps
  if not Result then Exit;

  itrFrame := integer(StopAt - Start);  // frame duration

  if(S_OK = pIn.IsSyncPoint) then
  begin
    {$IFDEF PERF}
    MSR_INTEGER(FidFrameType, 1);
    {$ENDIF}
    if (FKeyFramePeriod < FFramesSinceKeyFrame) then
    begin
      // record the max
      FKeyFramePeriod := FFramesSinceKeyFrame;
    end;
    FFramesSinceKeyFrame := 0;
    FSkipping := False;
  end else
  begin
    {$IFDEF PERF}
    MSR_INTEGER(FidFrameType, 2);
    {$ENDIF}
    if (FFramesSinceKeyFrame > FKeyFramePeriod) and (FKeyFramePeriod > 0) then
    begin
      // We haven't seen the key frame yet, but we were clearly being
      // overoptimistic about how frequent they are.
      FKeyFramePeriod := FFramesSinceKeyFrame;
    end;
  end;


  // Whatever we might otherwise decide,
  // if we are taking only a small fraction of the required frame time to decode
  // then any quality problems are actually coming from somewhere else.
  // Could be a net problem at the source for instance.  In this case there's
  // no point in us skipping frames here.
  if (FitrAvgDecode * 4 > itrFrame) then
  begin
    // Don't skip unless we are at least a whole frame late.
    // (We would skip B frames if more than 1/2 frame late, but they're safe).
    if (FitrLate > itrFrame) then
    begin
      // Don't skip unless the anticipated key frame would be no more than
      // 1 frame early.  If the renderer has not been waiting (we *guess*
      // it hasn't because we're late) then it will allow frames to be
      // played early by up to a frame.

      // Let T = Stream time from now to anticipated next key frame
      // = (frame duration) * (KeyFramePeriod - FramesSinceKeyFrame)
      // So we skip if T - Late < one frame  i.e.
      //   (duration) * (freq - FramesSince) - Late < duration
      // or (duration) * (freq - FramesSince - 1) < Late

      // We don't dare skip until we have seen some key frames and have
      // some idea how often they occur and they are reasonably frequent.
      if (FKeyFramePeriod > 0) then
      begin
        // It would be crazy - but we could have a stream with key frames
        // a very long way apart - and if they are further than about
        // 3.5 minutes apart then we could get arithmetic overflow in
        // reference time units.  Therefore we switch to mSec at this point
        it := (itrFrame div 10000) * (FKeyFramePeriod - FFramesSinceKeyFrame - 1);
        {$IFDEF PERF}
        MSR_INTEGER(FidTimeTillKey, it);
        {$ENDIF}

        // For debug - might want to see the details - dump them as scratch pad
        {$IFDEF VTRANSPERF}
        MSR_INTEGER(0, itrFrame);
        MSR_INTEGER(0, FFramesSinceKeyFrame);
        MSR_INTEGER(0, FKeyFramePeriod);
        {$ENDIF}
        if (FitrLate div 10000 > it) then
        begin
          FSkipping := True;
          // Now we are committed.  Once we start skipping, we
          // cannot stop until we hit a key frame.
        end else
        begin
        {$IFDEF VTRANSPERF}
          MSR_INTEGER(0, 777770);  // not near enough to next key
        {$ENDIF}
        end;
      end else
      begin
      {$IFDEF VTRANSPERF}
        MSR_INTEGER(0, 777771);  // Next key not predictable
      {$ENDIF}
      end;
    end else
    begin
    {$IFDEF VTRANSPERF}
      MSR_INTEGER(0, 777772);  // Less than one frame late
      MSR_INTEGER(0, FitrLate);
      MSR_INTEGER(0, itrFrame);
    {$ENDIF}
    end;
  end else
  begin
  {$IFDEF VTRANSPERF}
    MSR_INTEGER(0, 777773);  // Decode time short - not not worth skipping
    MSR_INTEGER(0, FitrAvgDecode);
    MSR_INTEGER(0, itrFrame);
    {$ENDIF}
  end;

  inc(FFramesSinceKeyFrame);

  if FSkipping then
  begin
    // We will count down the lateness as we skip each frame.
    // We re-assess each frame.  The key frame might not arrive when expected.
    // We reset m_itrLate if we get a new Quality message, but actually that's
    // not likely because we're not sending frames on to the Renderer.  In
    // fact if we DID get another one it would mean that there's a long
    // pipe between us and the renderer and we might need an altogether
    // better strategy to avoid hunting!
    FitrLate := FitrLate - itrFrame;
  end;

{$IFDEF PERF}
  MSR_INTEGER(FidLate, integer(FitrLate div 10000)); // Note how late we think we are
{$ENDIF}
  if FSkipping then
  begin
    if not FQualityChanged then
    begin
      FQualityChanged := True;
      NotifyEvent(EC_QUALITY_CHANGE,0,0);
    end;
  end;

  Result := FSkipping;
end;
// milenko end

{ TCTransInPlaceInputPin }

function TBCTransInPlaceInputPin.CheckMediaType(
  pmt: PAMMediaType): HRESULT;
begin
  result := FTIPFilter.CheckInputType(pmt);
  if (result <> S_OK) then exit;
  if FTIPFilter.FOutput.IsConnected then
    result := FTIPFilter.FOutput.GetConnected.QueryAccept(pmt^)
  else
    result := S_OK;
end;

function TBCTransInPlaceInputPin.EnumMediaTypes(
  out ppEnum: IEnumMediaTypes): HRESULT;
begin
  // Can only pass through if connected
  if (not FTIPFilter.FOutput.IsConnected) then
    begin
      result := VFW_E_NOT_CONNECTED;
      exit;
    end;

  result := FTIPFilter.FOutput.GetConnected.EnumMediaTypes(ppEnum);
end;

function TBCTransInPlaceInputPin.GetAllocator(
  out Allocator: IMemAllocator): HRESULT;
begin
  FLock.Lock;
  try
    if FTIPFilter.FOutput.IsConnected then
      begin
        //  Store the allocator we got
        result := FTIPFilter.OutputPin.ConnectedIMemInputPin.GetAllocator(Allocator);
        if SUCCEEDED(result) then
          FTIPFilter.OutputPin.SetAllocator(Allocator);
      end
    else
      begin
        //  Help upstream filter (eg TIP filter which is having to do a copy)
        //  by providing a temp allocator here - we'll never use
        //  this allocator because when our output is connected we'll
        //  reconnect this pin
        result := inherited GetAllocator(Allocator);
      end;
  finally
    FLock.UnLock;
  end;
end;

function TBCTransInPlaceInputPin.GetAllocatorRequirements(
  out props: TAllocatorProperties): HRESULT;
begin
  if FTIPFilter.FOutput.IsConnected then
    result := FTIPFilter.OutputPin.ConnectedIMemInputPin.GetAllocatorRequirements(Props)
  else
    result := E_NOTIMPL;
end;

function TBCTransInPlaceInputPin.NotifyAllocator(Allocator: IMemAllocator;
  ReadOnly: BOOL): HRESULT;
var
  OutputAllocator: IMemAllocator;
  Props, Actual: TAllocatorProperties;
begin
  result := S_OK;
  FLock.Lock;
  try
    FReadOnly := ReadOnly;
    //  If we modify data then don't accept the allocator if it's
    //  the same as the output pin's allocator

    //  If our output is not connected just accept the allocator
    //  We're never going to use this allocator because when our
    //  output pin is connected we'll reconnect this pin
    if not FTIPFilter.OutputPin.IsConnected then
      begin
        result := inherited NotifyAllocator(Allocator, ReadOnly);
        exit;
      end;

    //  If the allocator is read-only and we're modifying data
    //  and the allocator is the same as the output pin's
    //  then reject
    if (FReadOnly and FTIPFilter.FModifiesData) then
      begin
        OutputAllocator := FTIPFilter.OutputPin.PeekAllocator;

        //  Make sure we have an output allocator
        if (OutputAllocator = nil) then
        begin
          result := FTIPFilter.OutputPin.ConnectedIMemInputPin.GetAllocator(OutputAllocator);
          if FAILED(result) then result := CreateMemoryAllocator(OutputAllocator);
          if SUCCEEDED(result) then
            begin
              FTIPFilter.OutputPin.SetAllocator(OutputAllocator);
              OutputAllocator := nil;
            end;
        end;
        if (Allocator = OutputAllocator) then
          begin
            result := E_FAIL;
            exit;
          end
        else
          if SUCCEEDED(result) then
          begin
            //  Must copy so set the allocator properties on the output
            result := Allocator.GetProperties(Props);
            if SUCCEEDED(result) then
               result := OutputAllocator.SetProperties(Props, Actual);
            if SUCCEEDED(result) then
            begin
              if ((Props.cBuffers > Actual.cBuffers)
                  or (Props.cbBuffer > Actual.cbBuffer)
                  or (Props.cbAlign  > Actual.cbAlign)) then
                result :=  E_FAIL;

            end;

            //  Set the allocator on the output pin
            if SUCCEEDED(result) then
              result := FTIPFilter.OutputPin.ConnectedIMemInputPin.NotifyAllocator(OutputAllocator, FALSE);
          end;
      end
    else
      begin
        result := FTIPFilter.OutputPin.ConnectedIMemInputPin.NotifyAllocator(Allocator, ReadOnly);
        if SUCCEEDED(result) then  FTIPFilter.OutputPin.SetAllocator(Allocator);
      end;

    if SUCCEEDED(result) then
    begin
      // It's possible that the old and the new are the same thing.
      // AddRef before release ensures that we don't unload it.
      Allocator._AddRef;
      if (FAllocator <> nil) then FAllocator := nil;
      Pointer(FAllocator) := Pointer(Allocator);    // We have an allocator for the input pin
    end;
  finally
    FLock.UnLock;
  end;
end;

function TBCTransInPlaceInputPin.PeekAllocator: IMemAllocator;
begin
 result := FAllocator;
end;

constructor TBCTransInPlaceInputPin.Create(ObjectName: string;
  Filter: TBCTransInPlaceFilter; out hr: HRESULT; Name: WideString);
begin
  inherited Create(ObjectName, Filter, hr, Name);
  FReadOnly := FALSE;
  FTIPFilter := Filter;
{$IFDEF _DEBUG}
  DbgLog(self, 'TBCTransInPlaceInputPin.Create');
{$ENDIF}
end;

{ TBCTransInPlaceOutputPin }

function TBCTransInPlaceOutputPin.CheckMediaType(
  pmt: PAMMediaType): HRESULT;
begin
  // Don't accept any output pin type changes if we're copying
  // between allocators - it's too late to change the input
  // allocator size.
  if (FTIPFilter.UsingDifferentAllocators and (not FFilter.IsStopped)) then
  begin
    if TBCMediaType(pmt).Equal(@Fmt) then result := S_OK else result := VFW_E_TYPE_NOT_ACCEPTED;
    exit;
  end;

  // Assumes the type does not change.  That's why we're calling
  // CheckINPUTType here on the OUTPUT pin.
  result := FTIPFilter.CheckInputType(pmt);
  if (result <> S_OK) then exit;
  if (FTIPFilter.FInput.IsConnected) then
    result := FTIPFilter.FInput.GetConnected.QueryAccept(pmt^)
  else
    result := S_OK;
end;

function TBCTransInPlaceOutputPin.ConnectedIMemInputPin: IMemInputPin;
begin
  result := FInputPin;
end;

constructor TBCTransInPlaceOutputPin.Create(ObjectName: string;
  Filter: TBCTransInPlaceFilter; out hr: HRESULT; Name: WideString);
begin
  inherited Create(ObjectName, Filter, hr, Name);
  FTIPFilter := Filter;
{$IFDEF _DEBUG}
  DbgLog(self, 'TBCTransInPlaceOutputPin.Create');
{$ENDIF}
end;

function TBCTransInPlaceOutputPin.EnumMediaTypes(
  out ppEnum: IEnumMediaTypes): HRESULT;
begin
  // Can only pass through if connected.
  if not FTIPFilter.FInput.IsConnected then
    result := VFW_E_NOT_CONNECTED
  else
    result := FTIPFilter.FInput.GetConnected.EnumMediaTypes(ppEnum);
end;

function TBCTransInPlaceOutputPin.PeekAllocator: IMemAllocator;
begin
  result := FAllocator;
end;

procedure TBCTransInPlaceOutputPin.SetAllocator(Allocator: IMemAllocator);
begin
    Allocator._AddRef;
    if(FAllocator <> nil) then  FAllocator._Release;
    Pointer(FAllocator) := Pointer(Allocator);
end;

{ TBCTransInPlaceFilter }

function TBCTransInPlaceFilter.CheckTransform(mtIn,
  mtOut: PAMMediaType): HRESULT;
begin
  result := S_OK;
end;

// dir is the direction of our pin.
// pReceivePin is the pin we are connecting to.

function TBCTransInPlaceFilter.CompleteConnect(dir: TPinDirection;
  ReceivePin: IPin): HRESULT;
var
  pmt: PAMMediaType;
begin
  ASSERT(FInput <> nil);
  ASSERT(FOutput <> nil);

  // if we are not part of a graph, then don't indirect the pointer
  // this probably prevents use of the filter without a filtergraph
  if(FGraph = nil) then
  begin
    result := VFW_E_NOT_IN_GRAPH;
    exit;
  end;

  // Always reconnect the input to account for buffering changes
  //
  // Because we don't get to suggest a type on ReceiveConnection
  // we need another way of making sure the right type gets used.
  //
  // One way would be to have our EnumMediaTypes return our output
  // connection type first but more deterministic and simple is to
  // call ReconnectEx passing the type we want to reconnect with
  // via the base class ReconeectPin method.

  if(dir = PINDIR_OUTPUT) then
  begin
    if FInput.IsConnected then
    begin
      result := ReconnectPin(FInput, FOutput.AMMediaType);
      exit;
    end;
    result := NOERROR;
    exit;
  end;

  ASSERT(dir = PINDIR_INPUT);

  // Reconnect output if necessary

  if FOutput.IsConnected then
  begin
    pmt := FInput.CurrentMediaType.MediaType;
    if (not TBCMediaType(pmt).Equal(FOutput.CurrentMediaType.MediaType)) then
    begin
      result := ReconnectPin(FOutput, FInput.CurrentMediaType.MediaType);
      exit;
    end;
  end;
  result := NOERROR;
end;

function TBCTransInPlaceFilter.Copy(Source: IMediaSample): IMediaSample;
var
  Start, Stop: TReferenceTime;
  Time: boolean;
  pStartTime, pEndTime: PReferenceTime;
  TimeStart, TimeEnd: Int64;
  Flags: DWORD;
  Sample2: IMediaSample2;
  props: PAMSample2Properties;
  MediaType: PAMMediaType;
  DataLength: LongInt;
  SourceBuffer, DestBuffer: PByte;
  SourceSize, DestSize: LongInt;
  hr: hresult;
begin
    Time := (Source.GetTime(Start, Stop) = S_OK);
    // this may block for an indeterminate amount of time
    if Time then
      begin
        pStartTime := @Start;
        pEndTime   := @Stop;
      end
    else
      begin
        pStartTime := nil;
        pEndTime   := nil;
      end;
    if FSampleSkipped then Flags := AM_GBF_PREVFRAMESKIPPED else Flags := 0;
    hr := OutputPin.PeekAllocator.GetBuffer(result, pStartTime, pEndTime, Flags);

    if FAILED(hr) then exit;

    ASSERT(result <> nil);
    if(SUCCEEDED(result.QueryInterface(IID_IMediaSample2, Sample2))) then
      begin
        props :=  FInput.SampleProps;
        hr := Sample2.SetProperties(SizeOf(TAMSample2Properties) - (4*2), props^);
        Sample2 := nil;
        if FAILED(hr) then
        begin
          result := nil;
          exit;
        end;
      end
    else
      begin
        if Time then result.SetTime(@Start, @Stop);
        if (Source.IsSyncPoint = S_OK) then result.SetSyncPoint(True);
        if ((Source.IsDiscontinuity = S_OK) or FSampleSkipped) then result.SetDiscontinuity(True);
        if (Source.IsPreroll = S_OK) then result.SetPreroll(True);
        // Copy the media type
        if (Source.GetMediaType(MediaType) = S_OK) then
          begin
            result.SetMediaType(MediaType);
            DeleteMediaType(MediaType);
          end;

      end;

    FSampleSkipped := FALSE;

    // Copy the sample media times
    if (Source.GetMediaTime(TimeStart, TimeEnd) = NOERROR) then
      result.SetMediaTime(@TimeStart,@TimeEnd);

    // Copy the actual data length and the actual data.
    DataLength := Source.GetActualDataLength;

    result.SetActualDataLength(DataLength);

    // Copy the sample data
    SourceSize := Source.GetSize;
    DestSize   := result.GetSize;

    // milenko start get rid of compiler warnings
    if (DestSize < SourceSize) then
    begin
    end;
    // milenko end

    ASSERT(DestSize >= SourceSize, format('DestSize (%d) < SourceSize (%d)',[DestSize, SourceSize]));
    ASSERT(DestSize >= DataLength);

    Source.GetPointer(SourceBuffer);
    result.GetPointer(DestBuffer);
    ASSERT((DestSize = 0) or (SourceBuffer <> nil) and (DestBuffer <> nil));
    CopyMemory(DestBuffer, SourceBuffer, DataLength);
end;

constructor TBCTransInPlaceFilter.Create(ObjectName: string;
  unk: IUnKnown; clsid: TGUID; out hr: HRESULT; ModifiesData: boolean);
begin
  inherited create(ObjectName, Unk, clsid);
  FModifiesData := ModifiesData;
end;

constructor TBCTransInPlaceFilter.CreateFromFactory(Factory: TBCClassFactory;
  const Controller: IUnknown);
begin
  inherited create(FacTory.FName, Controller, FacTory.FClassID);
  FModifiesData := True;
end;

// Tell the output pin's allocator what size buffers we require.
// *pAlloc will be the allocator our output pin is using.

function TBCTransInPlaceFilter.DecideBufferSize(Alloc: IMemAllocator;
  propInputRequest: PAllocatorProperties): HRESULT;
var Request, Actual: TAllocatorProperties;
begin
  // If we are connected upstream, get his views
  if FInput.IsConnected then
    begin
      // Get the input pin allocator, and get its size and count.
      // we don't care about his alignment and prefix.
      result := InputPin.FAllocator.GetProperties(Request);
      //Request.cbBuffer := 230400;
      if FAILED(result) then exit; // Input connected but with a secretive allocator - enough!
    end
  else
    begin
      // We're reduced to blind guessing.  Let's guess one byte and if
      // this isn't enough then when the other pin does get connected
      // we can revise it.
      ZeroMemory(@Request, sizeof(Request));
      Request.cBuffers := 1;
      Request.cbBuffer := 1;
    end;


{$IFDEF _DEBUG}
  DbgLog(self, 'Setting Allocator Requirements');
  DbgLog(self, format('Count %d, Size %d',[Request.cBuffers, Request.cbBuffer]));
{$ENDIF}

  // Pass the allocator requirements to our output side
  // but do a little sanity checking first or we'll just hit
  // asserts in the allocator.

  propInputRequest.cBuffers := Request.cBuffers;
  propInputRequest.cbBuffer := Request.cbBuffer;
  if (propInputRequest.cBuffers <= 0) then propInputRequest.cBuffers := 1;
  if (propInputRequest.cbBuffer <= 0) then propInputRequest.cbBuffer := 1;
  result := Alloc.SetProperties(propInputRequest^, Actual);
  if FAILED(result) then exit;

{$IFDEF _DEBUG}
  DbgLog(self, 'Obtained Allocator Requirements');
  DbgLog(self, format('Count %d, Size %d, Alignment %d', [Actual.cBuffers, Actual.cbBuffer, Actual.cbAlign]));
{$ENDIF}

  // Make sure we got the right alignment and at least the minimum required

  if ((Request.cBuffers > Actual.cBuffers)
      or (Request.cbBuffer > Actual.cbBuffer)
      or (Request.cbAlign  > Actual.cbAlign)) then
    result := E_FAIL
  else
    result := NOERROR;
end;

function TBCTransInPlaceFilter.GetMediaType(Position: integer;
  out MediaType: PAMMediaType): HRESULT;
begin
{$IFDEF _DEBUG}
  DbgLog(self, 'TBCTransInPlaceFilter.GetMediaType should never be called');
{$ENDIF}
  result := E_UNEXPECTED;
end;

// return a non-addrefed CBasePin * for the user to addref if he holds onto it
// for longer than his pointer to us. We create the pins dynamically when they
// are asked for rather than in the constructor. This is because we want to
// give the derived class an oppportunity to return different pin objects

// As soon as any pin is needed we create both (this is different from the
// usual transform filter) because enumerators, allocators etc are passed
// through from one pin to another and it becomes very painful if the other
// pin isn't there.  If we fail to create either pin we ensure we fail both.

function TBCTransInPlaceFilter.GetPin(n: integer): TBCBasePin;
var hr: HRESULT;
begin
  hr := S_OK;
  // Create an input pin if not already done
  if(FInput = nil) then
  begin
    FInput := TBCTransInPlaceInputPin.Create('TransInPlace input pin',
      self,      // Owner filter
      hr,        // Result code
      'Input');  // Pin name

    // Constructor for CTransInPlaceInputPin can't fail
    ASSERT(SUCCEEDED(hr));
  end;

  // Create an output pin if not already done

  if((FInput <> nil) and (FOutput = nil)) then
  begin
    FOutput := TBCTransInPlaceOutputPin.Create('TransInPlace output pin',
      self,      // Owner filter
      hr,        // Result code
      'Output'); // Pin name

    // a failed return code should delete the object
    ASSERT(SUCCEEDED(hr));
      if(FOutput = nil) then
      begin
        FInput.Free;
        FInput := nil;
      end;
  end;

  // Return the appropriate pin

  ASSERT(n in [0,1]);
  case n of
    0: result := FInput;
    1: result := FOutput;
  else
    result := nil;
  end;
end;

function TBCTransInPlaceFilter.InputPin: TBCTransInPlaceInputPin;
begin
  result := TBCTransInPlaceInputPin(FInput);
end;

function TBCTransInPlaceFilter.OutputPin: TBCTransInPlaceOutputPin;
begin
  result := TBCTransInPlaceOutputPin(FOutput);
end;

function TBCTransInPlaceFilter.Receive(Sample: IMediaSample): HRESULT;
var Props: PAMSample2Properties;
begin
  //  Check for other streams and pass them on */
  Props := FInput.SampleProps;
  if (Props.dwStreamId <> AM_STREAM_MEDIA) then
    begin
      result := FOutput.Deliver(Sample);
      exit;
    end;

  if UsingDifferentAllocators then
  begin
    // We have to copy the data.
    Sample := Copy(Sample);
    if (Sample = nil) then
    begin
      result := E_UNEXPECTED;
      exit;
    end;
  end;

  // have the derived class transform the data
  result := Transform(Sample);

  if FAILED(result) then
  begin
  {$IFDEF _DEBUG}
    DbgLog(self, 'Error from TransInPlace');
  {$ENDIF}
    if UsingDifferentAllocators then Sample := nil;
    exit;
  end;

  // the Transform() function can return S_FALSE to indicate that the
  // sample should not be delivered; we only deliver the sample if it's
  // really S_OK (same as NOERROR, of course.)
  if (result = NOERROR) then
    result := FOutput.Deliver(Sample)
  else
    begin
      //  But it would be an error to return this private workaround
      //  to the caller ...
      if (result = S_FALSE) then
      begin
        // S_FALSE returned from Transform is a PRIVATE agreement
        // We should return NOERROR from Receive() in this cause because
        // returning S_FALSE from Receive() means that this is the end
        // of the stream and no more data should be sent.
        FSampleSkipped := True;
        if (not FQualityChanged) then
        begin
          NotifyEvent(EC_QUALITY_CHANGE,0,0);
          FQualityChanged := True;
        end;
        result := NOERROR;
      end;
    end;

  // release the output buffer. If the connected pin still needs it,
  // it will have addrefed it itself.
  if UsingDifferentAllocators then Sample := nil;
end;

function TBCTransInPlaceFilter.TypesMatch: boolean;
var
  pmt: PAMMediaType;
begin
  pmt := InputPin.CurrentMediaType.MediaType;
  result := TBCMediaType(pmt).Equal(OutputPin.CurrentMediaType.MediaType);
end;

function TBCTransInPlaceFilter.UsingDifferentAllocators: boolean;
begin
  result := Pointer(InputPin.FAllocator) <> Pointer(OutputPin.FAllocator);
end;

{ TBCBasePropertyPage }

{$IFDEF WITH_PROPERTY_PAGE}
function TBCBasePropertyPage.Activate(hwndParent: HWnd; const rc: TRect;
  bModal: BOOL): HResult;
begin
  // Return failure if SetObject has not been called.
  if (FObjectSet = FALSE) or (hwndParent = 0) then
    begin
      result := E_UNEXPECTED;
      exit;
    end;

   // FForm := TCustomFormClass(FFormClass).Create(nil);

    if (FForm = nil) then
      begin
        result := E_OUTOFMEMORY;
        exit;
      end;

    FForm.ParentWindow := hwndParent;
    if assigned(FForm.OnActivate) then FForm.OnActivate(FForm);
    Move(rc);
    result := Show(SW_SHOWNORMAL);
end;

function TBCBasePropertyPage.Apply: HResult;
begin
  // In ActiveMovie 1.0 we used to check whether we had been activated or
  // not. This is too constrictive. Apply should be allowed as long as
  // SetObject was called to set an object. So we will no longer check to
  // see if we have been activated (ie., m_hWnd != NULL), but instead
  // make sure that m_bObjectSet is True (ie., SetObject has been called).

  if (FObjectSet = FALSE) or (FPageSite = nil) then
  begin
    result := E_UNEXPECTED;
    exit;
  end;

  if (FDirty = FALSE) then
  begin
    result := NOERROR;
    exit;
  end;

  // Commit derived class changes

  result := FForm.OnApplyChanges;
  if SUCCEEDED(result) then FDirty := FALSE;
end;

function TBCBasePropertyPage.Deactivate: HResult;
var Style: DWORD;
begin
    if (FForm = nil) then
    begin
      result := E_UNEXPECTED;
      exit;
    end;

    // Remove WS_EX_CONTROLPARENT before DestroyWindow call

    Style := GetWindowLong(FForm.Handle, GWL_EXSTYLE);
    Style := Style and (not WS_EX_CONTROLPARENT);

    //  Set m_hwnd to be NULL temporarily so the message handler
    //  for WM_STYLECHANGING doesn't add the WS_EX_CONTROLPARENT
    //  style back in

    SetWindowLong(FForm.Handle, GWL_EXSTYLE, Style);
    if assigned(FForm.OnDeactivate) then FForm.OnDeactivate(FForm);

    // Destroy the dialog window

    //FForm.Free;
    //FForm := nil;
    result := NOERROR;
end;

function TBCBasePropertyPage.GetPageInfo(out pageInfo: TPropPageInfo): HResult;
begin
  pageInfo.cb := sizeof(TPropPageInfo);
  AMGetWideString(FForm.Caption, pageInfo.pszTitle);
  PageInfo.pszDocString := nil;
  PageInfo.pszHelpFile  := nil;
  PageInfo.dwHelpContext:= 0;
  PageInfo.size.cx := FForm.ClientWidth;
  PageInfo.size.cy := FForm.ClientHeight;
  Result := NoError;
end;

function TBCBasePropertyPage.Help(pszHelpDir: POleStr): HResult;
begin
  result := E_NOTIMPL;
end;

function TBCBasePropertyPage.IsPageDirty: HResult;
begin
  if FDirty then result := S_OK else result := S_FALSE;
end;

function TBCBasePropertyPage.Move(const rect: TRect): HResult;
begin
  if (FForm = nil) then
  begin
    result := E_UNEXPECTED;
    exit;
  end;

  MoveWindow(FForm.Handle,             // Property page handle
               Rect.left,              // x coordinate
               Rect.top,               // y coordinate
               Rect.Right - Rect.Left, // Overall window width
               Rect.Bottom - Rect.Top, // And likewise height
               True);                  // Should we repaint it

  result := NOERROR;
end;

function TBCBasePropertyPage.SetObjects(cObjects: Integer;
  pUnkList: PUnknownList): HResult;
begin
  if (cObjects = 1) then
    begin
      if (pUnkList = nil) then
      begin
        result := E_POINTER;
        exit;
      end;
      // Set a flag to say that we have set the Object
      FObjectSet := True ;
      result := FForm.OnConnect(pUnkList^[0]);
      exit;
     end
   else
     if (cObjects = 0) then
     begin
       // Set a flag to say that we have not set the Object for the page
       FObjectSet := FALSE;
       result := FForm.OnDisconnect;
       exit;
     end;

  {$IFDEF _DEBUG}
    DbgLog(self, 'No support for more than one object');
  {$ENDIF}
    result := E_UNEXPECTED;
end;

function TBCBasePropertyPage.SetPageSite(
  const pageSite: IPropertyPageSite): HResult;
begin
  if (pageSite <> nil) then
    begin
      if (FPageSite <> nil) then
      begin
        result := E_UNEXPECTED;
        exit;
      end;
      FPageSite := pageSite;
    end
  else
    begin
      if (FPageSite = nil) then
      begin
        result := E_UNEXPECTED;
        exit;
      end;
      FPageSite := nil;
    end;
  result := NOERROR;
end;

function TBCBasePropertyPage.Show(nCmdShow: Integer): HResult;
begin
  if (FForm = nil) then
  begin
    result := E_UNEXPECTED;
    exit;
  end;

  if ((nCmdShow <> SW_SHOW) and (nCmdShow <> SW_SHOWNORMAL) and (nCmdShow <> SW_HIDE)) then
    begin
      result := E_INVALIDARG;
      exit;
    end;

    if nCmdShow in [SW_SHOW,SW_SHOWNORMAL] then FForm.Show else FForm.Hide;
    InvalidateRect(FForm.Handle, nil, True);
    result := NOERROR;
end;

function TBCBasePropertyPage.TranslateAccelerator(msg: PMsg): HResult;
begin
  result := E_NOTIMPL;
end;

constructor TBCBasePropertyPage.Create(Name: String; Unk: IUnKnown; Form: TFormPropertyPage);
var
  cx, cy: Integer;
begin
  inherited Create(Name, Unk);
  FForm := Form;
  cx := FForm.ClientWidth;
  cy := FForm.ClientHeight;
  FForm.BorderStyle := bsNone;
  FForm.ClientWidth := cx;
  FForm.ClientHeight := cy;
  FPageSite  := nil;
  FObjectSet := false;
  FDirty     := false;
end;

destructor TBCBasePropertyPage.Destroy;
begin
  if FForm <> nil then
    begin
      FForm.Free;
      FForm := nil;
    end;
  inherited;
end;

constructor TFormPropertyPage.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  WindowProc := MyWndProc;
end;

procedure TFormPropertyPage.MyWndProc(var aMsg: TMessage);
var
  lpss : PStyleStruct;
begin
  // we would like the TAB key to move around the tab stops in our property
  // page, but for some reason OleCreatePropertyFrame clears the CONTROLPARENT
  // style behind our back, so we need to switch it back on now behind its
  // back.  Otherwise the tab key will be useless in every page.

  // DCoder: removing CONTROLPARENT is also the reason for non responding
  // PropertyPages when using ShowMessage and TComboBox.
  if (aMsg.Msg = WM_STYLECHANGING) and (aMsg.WParam = GWL_EXSTYLE) then
  begin
    lpss := PStyleStruct(aMsg.LParam);
    lpss.styleNew := lpss.styleNew or WS_EX_CONTROLPARENT;
    aMsg.Result := 0;
    Exit;
  end;
  WndProc(aMsg);
end;

function TFormPropertyPage.OnApplyChanges: HRESULT;
begin
  result := NOERROR;
end;

function TFormPropertyPage.OnConnect(Unknown: IUnKnown): HRESULT;
begin
  result := NOERROR;
end;

function TFormPropertyPage.OnDisconnect: HRESULT;
begin
  result := NOERROR;
end;

procedure TBCBasePropertyPage.SetPageDirty;
begin
  FDirty := True;
  if Assigned(FPageSite) then FPageSite.OnStatusChange(PROPPAGESTATUS_DIRTY);
end;
{$ENDIF}

{ TBCBaseDispatch }

function TBCBaseDispatch.GetIDsOfNames(const IID: TGUID; Names: Pointer;
  NameCount, LocaleID: Integer; DispIDs: Pointer): HResult;
var ti: ITypeInfo;
begin
  // although the IDispatch riid is dead, we use this to pass from
  // the interface implementation class to us the iid we are talking about.
  result := GetTypeInfo(iid, 0, LocaleID, ti);
  if SUCCEEDED(result) then
    result := ti.GetIDsOfNames(Names, NameCount, DispIDs);
end;

function TBCBaseDispatch.GetTypeInfo(const iid: TGUID; info: Cardinal; lcid: LCID;
  out tinfo): HRESULT; stdcall;
var
  tlib : ITypeLib;
begin
  // we only support one type element
  if (info <> 0) then
    begin
      result := TYPE_E_ELEMENTNOTFOUND;
      exit;
    end;

  // always look for neutral
  if (FTI = nil) then
  begin
    result := LoadRegTypeLib(LIBID_QuartzTypeLib, 1, 0, lcid, tlib);
    if FAILED(result) then
    begin
      result := LoadTypeLib('control.tlb', tlib);
      if FAILED(result) then exit;
    end;
    result := tlib.GetTypeInfoOfGuid(iid, Fti);
    tlib := nil;
    if FAILED(result) then exit;
  end;
  ITypeInfo(tinfo) := Fti;
  result := S_OK;
end;

function TBCBaseDispatch.GetTypeInfoCount(out Count: Integer): HResult;
begin
  count := 1;
  result := S_OK;
end;

{ TBCMediaControl }

constructor TBCMediaControl.Create(name: string; unk: IUnknown);
begin
  FBaseDisp := TBCBaseDispatch.Create;
end;

destructor TBCMediaControl.Destroy;
begin
  FBaseDisp.Free;
  inherited;
end;

function TBCMediaControl.GetIDsOfNames(const IID: TGUID; Names: Pointer;
  NameCount, LocaleID: Integer; DispIDs: Pointer): HResult;
begin
  result := FBasedisp.GetIDsOfNames(IID_IMediaControl, Names, NameCount, LocaleID, DispIDs);
end;

function TBCMediaControl.GetTypeInfo(Index, LocaleID: Integer;
  out TypeInfo): HResult;
begin
  result := Fbasedisp.GetTypeInfo(IID_IMediaControl, index, LocaleID, TypeInfo);
end;

function TBCMediaControl.GetTypeInfoCount(out Count: Integer): HResult;
begin
  result := FBaseDisp.GetTypeInfoCount(Count);
end;

function TBCMediaControl.Invoke(DispID: Integer; const IID: TGUID;
  LocaleID: Integer; Flags: Word; var Params; VarResult, ExcepInfo,
  ArgErr: Pointer): HResult;
var ti: ITypeInfo;
begin
  // this parameter is a dead leftover from an earlier interface
  if not IsEqualGUID(GUID_NULL, IID) then
    begin
      result := DISP_E_UNKNOWNINTERFACE;
      exit;
    end;
  result := GetTypeInfo(0, LocaleID, ti);
  if FAILED(result) then exit;
  result := ti.Invoke(Pointer(Integer(Self)), DISPID, Flags, TDispParams(Params),
    VarResult, ExcepInfo, ArgErr);
end;

{ TBCMediaEvent }

constructor TBCMediaEvent.Create(Name: string; Unk: IUnknown);
begin
  inherited Create(name, Unk);
  FBasedisp := TBCBaseDispatch.Create;
end;

destructor TBCMediaEvent.destroy;
begin
  FBasedisp.Free;
  inherited;
end;

function TBCMediaEvent.GetIDsOfNames(const IID: TGUID; Names: Pointer;
  NameCount, LocaleID: Integer; DispIDs: Pointer): HResult;
begin
  result := FBasedisp.GetIDsOfNames(IID_IMediaEvent, Names, NameCount, LocaleID, DispIDs);
end;

function TBCMediaEvent.GetTypeInfo(Index, LocaleID: Integer;
  out TypeInfo): HResult;
begin
  result := Fbasedisp.GetTypeInfo(IID_IMediaEvent, index, LocaleID, TypeInfo);
end;

function TBCMediaEvent.GetTypeInfoCount(out Count: Integer): HResult;
begin
  result := FBaseDisp.GetTypeInfoCount(Count);
end;

function TBCMediaEvent.Invoke(DispID: Integer; const IID: TGUID;
  LocaleID: Integer; Flags: Word; var Params; VarResult, ExcepInfo,
  ArgErr: Pointer): HResult;
var ti: ITypeInfo;
begin
  // this parameter is a dead leftover from an earlier interface
  if not IsEqualGUID(GUID_NULL, IID) then
    begin
      result := DISP_E_UNKNOWNINTERFACE;
      exit;
    end;
  result := GetTypeInfo(0, LocaleID, ti);
  if FAILED(result) then exit;
  result := ti.Invoke(Pointer(Integer(Self)), DISPID, Flags, TDispParams(Params), VarResult, ExcepInfo, ArgErr);
end;

{ TBCMediaPosition }

constructor TBCMediaPosition.Create(Name: String; Unk: IUnknown);
begin
  inherited Create(Name, Unk);
  FBaseDisp := TBCBaseDispatch.Create;
end;

constructor TBCMediaPosition.Create(Name: String; Unk: IUnknown;
  out hr: HRESULT);
begin
  inherited Create(Name, Unk);
  FBaseDisp := TBCBaseDispatch.Create;
end;

destructor TBCMediaPosition.Destroy;
begin
  FBaseDisp.Free;
  inherited;
end;

function TBCMediaPosition.GetIDsOfNames(const IID: TGUID; Names: Pointer;
  NameCount, LocaleID: Integer; DispIDs: Pointer): HResult;
begin
  result := FBasedisp.GetIDsOfNames(IID_IMediaPosition, Names, NameCount, LocaleID, DispIDs);
end;

function TBCMediaPosition.GetTypeInfo(Index, LocaleID: Integer;
  out TypeInfo): HResult;
begin
  result := Fbasedisp.GetTypeInfo(IID_IMediaPosition, index, LocaleID, TypeInfo);
end;

function TBCMediaPosition.GetTypeInfoCount(out Count: Integer): HResult;
begin
  result := Fbasedisp.GetTypeInfoCount(Count);
end;

function TBCMediaPosition.Invoke(DispID: Integer; const IID: TGUID;
  LocaleID: Integer; Flags: Word; var Params; VarResult, ExcepInfo,
  ArgErr: Pointer): HResult;
var ti: ITypeInfo;
begin
  // this parameter is a dead leftover from an earlier interface
  if not IsEqualGUID(GUID_NULL, IID) then
    begin
      result := DISP_E_UNKNOWNINTERFACE;
      exit;
    end;
  result := GetTypeInfo(0, LocaleID, ti);
  if FAILED(result) then exit;
  result := ti.Invoke(Pointer(Integer(Self)), DISPID, Flags, TDispParams(Params), VarResult, ExcepInfo, ArgErr);
end;

{ TBCPosPassThru }

function TBCPosPassThru.CanSeekBackward(
  out pCanSeekBackward: Integer): HResult;
var MP: IMediaPosition;
begin
  result := GetPeer(MP);
  if FAILED(result) then exit;
  result := MP.CanSeekBackward(pCanSeekBackward);
end;

function TBCPosPassThru.CanSeekForward(
  out pCanSeekForward: Integer): HResult;
var MP: IMediaPosition;
begin
  result := GetPeer(MP);
  if FAILED(result) then exit;
  result := MP.CanSeekForward(pCanSeekForward);
end;

function TBCPosPassThru.CheckCapabilities(
  var pCapabilities: DWORD): HRESULT;
var
  MS: IMediaSeeking;
begin
  result := GetPeerSeeking(MS);
  if FAILED(result) then exit;
  result := MS.CheckCapabilities(pCapabilities);
end;

function TBCPosPassThru.ConvertTimeFormat(out pTarget: int64;
  pTargetFormat: PGUID; Source: int64; pSourceFormat: PGUID): HRESULT;
var MS: IMediaSeeking;
begin
  result := GetPeerSeeking(MS);
  if FAILED(result) then exit;
  result := MS.ConvertTimeFormat(pTarget, pTargetFormat, Source, pSourceFormat);
end;

constructor TBCPosPassThru.Create(name: String; Unk: IUnknown;
  out hr: HRESULT; Pin: IPin);
begin
  assert(Pin <> nil);
  inherited Create(Name,Unk);
  FPin := Pin;
end;

function TBCPosPassThru.ForceRefresh: HRESULT;
begin
  result := S_OK;
end;

function TBCPosPassThru.get_CurrentPosition(
  out pllTime: TRefTime): HResult;
var MP: IMediaPosition;
begin
  result := GetPeer(MP);
  if FAILED(result) then exit;
  result := MP.get_CurrentPosition(pllTime);
end;

function TBCPosPassThru.get_Duration(out plength: TRefTime): HResult;
var MP: IMediaPosition;
begin
  result := GetPeer(MP);
  if FAILED(result) then exit;
  result := MP.get_Duration(plength);
end;

function TBCPosPassThru.get_PrerollTime(out pllTime: TRefTime): HResult;
var MP: IMediaPosition;
begin
  result := GetPeer(MP);
  if FAILED(result) then exit;
  result := MP.get_PrerollTime(pllTime);
end;

function TBCPosPassThru.get_Rate(out pdRate: double): HResult;
var MP: IMediaPosition;
begin
  result := GetPeer(MP);
  if FAILED(result) then exit;
  result := MP.get_Rate(pdRate);
end;

function TBCPosPassThru.get_StopTime(out pllTime: TRefTime): HResult;
var MP: IMediaPosition;
begin
  result := GetPeer(MP);
  if FAILED(result) then exit;
  result := MP.get_StopTime(pllTime);
end;

function TBCPosPassThru.GetAvailable(out pEarliest,
  pLatest: int64): HRESULT;
var MS: IMediaSeeking;
begin
  result := GetPeerSeeking(MS);
  if FAILED(result) then exit;
  result := MS.GetAvailable(pEarliest, pLatest);
end;

function TBCPosPassThru.GetCapabilities(out pCapabilities: DWORD): HRESULT;
var MS: IMediaSeeking;
begin
  result := GetPeerSeeking(MS);
  if FAILED(result) then exit;
  result := MS.GetCapabilities(pCapabilities);
end;

function TBCPosPassThru.GetCurrentPosition(out pCurrent: int64): HRESULT;
var
  MS: IMediaSeeking;
  Stop: int64;
begin
  result := GetMediaTime(pCurrent, Stop);
  if SUCCEEDED(result) then
    result := NOERROR
  else
    begin
      result := GetPeerSeeking(MS);
      if FAILED(result) then exit;
      result := MS.GetCurrentPosition(pCurrent)
    end;
end;

function TBCPosPassThru.GetDuration(out pDuration: int64): HRESULT;
var MS: IMediaSeeking;
begin
  result := GetPeerSeeking(MS);
  if FAILED(result) then exit;
  result := MS.GetDuration(pDuration);
end;

function TBCPosPassThru.GetMediaTime(out StartTime,
  EndTime: Int64): HRESULT;
begin
  result := E_FAIL;
end;

// Return the IMediaPosition interface from our peer

function TBCPosPassThru.GetPeer(out MP: IMediaPosition): HRESULT;
var
  Connected: IPin;
begin
  result := FPin.ConnectedTo(Connected);
  if FAILED(result) then
    begin
      result := E_NOTIMPL;
      exit;
    end;

  result := Connected.QueryInterface(IID_IMediaPosition, MP);
  Connected := nil;
  if FAILED(result) then
    begin
      result := E_NOTIMPL;
      exit;
    end;
  result := S_OK;
end;

function TBCPosPassThru.GetPeerSeeking(out MS: IMediaSeeking): HRESULT;
var
  Connected: IPin;
begin
  MS := nil;

  result := FPin.ConnectedTo(Connected);
  if FAILED(result) then
    begin
      result := E_NOTIMPL;
      exit;
    end;

  result := Connected.QueryInterface(IID_IMediaSeeking, MS);
  Connected := nil;
  if FAILED(result) then
    begin
      result := E_NOTIMPL;
      exit;
    end;

  result := S_OK;
end;

function TBCPosPassThru.GetPositions(out pCurrent, pStop: int64): HRESULT;
var MS: IMediaSeeking;
begin
  result := GetPeerSeeking(MS);
  if FAILED(result) then exit;
  result := MS.GetPositions(pCurrent, pStop);
end;

function TBCPosPassThru.GetPreroll(out pllPreroll: int64): HRESULT;
var MS: IMediaSeeking;
begin
  result := GetPeerSeeking(MS);
  if FAILED(result) then exit;
  result := MS.GetPreroll(pllPreroll);
end;

function TBCPosPassThru.GetRate(out pdRate: double): HRESULT;
var MS: IMediaSeeking;
begin
  result := GetPeerSeeking(MS);
  if FAILED(result) then exit;
  result := MS.GetRate(pdRate);
end;

function TBCPosPassThru.GetStopPosition(out pStop: int64): HRESULT;
var MS: IMediaSeeking;
begin
  result := GetPeerSeeking(MS);
  if FAILED(result) then exit;
  result := MS.GetStopPosition(pStop);
end;

function TBCPosPassThru.GetTimeFormat(out pFormat: TGUID): HRESULT;
var MS: IMediaSeeking;
begin
  result := GetPeerSeeking(MS);
  if FAILED(result) then exit;
  result := MS.GetTimeFormat(pFormat);
end;

function TBCPosPassThru.IsFormatSupported(const pFormat: TGUID): HRESULT;
var MS: IMediaSeeking;
begin
  result := GetPeerSeeking(MS);
  if FAILED(result) then exit;
  result := MS.IsFormatSupported(pFormat);
end;

function TBCPosPassThru.IsUsingTimeFormat(const pFormat: TGUID): HRESULT;
var MS: IMediaSeeking;
begin
  result := GetPeerSeeking(MS);
  if FAILED(result) then exit;
  result := MS.IsUsingTimeFormat(pFormat);
end;

function TBCPosPassThru.put_CurrentPosition(llTime: TRefTime): HResult;
var MP: IMediaPosition;
begin
  result := GetPeer(MP);
  if FAILED(result) then exit;
  result := MP.put_CurrentPosition(llTime);
end;

function TBCPosPassThru.put_PrerollTime(llTime: TRefTime): HResult;
var MP: IMediaPosition;
begin
  result := GetPeer(MP);
  if FAILED(result) then exit;
  result := MP.put_PrerollTime(llTime);
end;

function TBCPosPassThru.put_Rate(dRate: double): HResult;
var MP: IMediaPosition;
begin
  if (dRate = 0.0) then
    begin
      result := E_INVALIDARG;
      exit;
    end;

  result := GetPeer(MP);
  if FAILED(result) then exit;
  result := MP.put_Rate(dRate);
end;

function TBCPosPassThru.put_StopTime(llTime: TRefTime): HResult;
var MP: IMediaPosition;
begin
  result := GetPeer(MP);
  if FAILED(result) then exit;
  result := MP.put_StopTime(llTime);
end;

function TBCPosPassThru.QueryPreferredFormat(out pFormat: TGUID): HRESULT;
var MS: IMediaSeeking;
begin
  result := GetPeerSeeking(MS);
  if FAILED(result) then exit;
  result := MS.QueryPreferredFormat(pFormat);
end;

function TBCPosPassThru.SetPositions(var pCurrent: int64;
  dwCurrentFlags: DWORD; var pStop: int64; dwStopFlags: DWORD): HRESULT;
var MS: IMediaSeeking;
begin
  result := GetPeerSeeking(MS);
  if FAILED(result) then exit;
  result := MS.SetPositions(pCurrent, dwCurrentFlags, pStop, dwStopFlags);
end;

function TBCPosPassThru.SetRate(dRate: double): HRESULT;
var MS: IMediaSeeking;
begin
  if (dRate = 0.0) then
    begin
      result := E_INVALIDARG;
      exit;
    end;
  result := GetPeerSeeking(MS);
  if FAILED(result) then exit;
  result := MS.SetRate(dRate);
end;

function TBCPosPassThru.SetTimeFormat(const pFormat: TGUID): HRESULT;
var MS: IMediaSeeking;
begin
  result := GetPeerSeeking(MS);
  if FAILED(result) then exit;
  result := MS.SetTimeFormat(pFormat);
end;

{ TBCRendererPosPassThru }

// Media times (eg current frame, field, sample etc) are passed through the
// filtergraph in media samples. When a renderer gets a sample with media
// times in it, it will call one of the RegisterMediaTime methods we expose
// (one takes an IMediaSample, the other takes the media times direct). We
// store the media times internally and return them in GetCurrentPosition.

constructor TBCRendererPosPassThru.Create(name: String; Unk: IUnknown;
  out hr: HRESULT; Pin: IPin);
begin
    inherited Create(Name,Unk,hr,Pin);
    FStartMedia:= 0;
    FEndMedia  := 0;
    FReset     := True;
    FPositionLock := TBCCritSec.Create;
end;

destructor TBCRendererPosPassThru.destroy;
begin
  FPositionLock.Free;
  inherited;
end;

// Intended to be called by the owing filter during EOS processing so
// that the media times can be adjusted to the stop time.  This ensures
// that the GetCurrentPosition will actully get to the stop position.

function TBCRendererPosPassThru.EOS: HRESULT;
var Stop: int64;
begin
  if FReset then result := E_FAIL
  else
    begin
      result := GetStopPosition(Stop);
      if SUCCEEDED(result) then
        begin
          FPositionLock.Lock;
          try
            FStartMedia := Stop;
            FEndMedia   := Stop;
          finally
            FPositionLock.UnLock;
          end;
        end;
    end;
end;

function TBCRendererPosPassThru.GetMediaTime(out StartTime,
  EndTime: int64): HRESULT;
begin
  FPositionLock.Lock;
  try
    if FReset then
      begin
        result := E_FAIL;
        exit;
      end;
    // We don't have to return the end time
    result := ConvertTimeFormat(StartTime, nil, FStartMedia, @TIME_FORMAT_MEDIA_TIME);
    if SUCCEEDED(result) then
      result := ConvertTimeFormat(EndTime, nil, FEndMedia, @TIME_FORMAT_MEDIA_TIME);
  finally
    FPositionLock.UnLock;
  end;
end;

// Sets the media times the object should report

function TBCRendererPosPassThru.RegisterMediaTime(
  MediaSample: IMediaSample): HRESULT;
var  StartMedia, EndMedia: TReferenceTime;
begin
  ASSERT(assigned(MediaSample));
  FPositionLock.Lock;
  try
    // Get the media times from the sample
    result := MediaSample.GetTime(StartMedia, EndMedia);
    if FAILED(result) then
      begin
        ASSERT(result = VFW_E_SAMPLE_TIME_NOT_SET);
        exit;
      end;
    FStartMedia := StartMedia;
    FEndMedia   := EndMedia;
    FReset      := FALSE;
    result := NOERROR;
  finally
    FPositionLock.Unlock;
  end;
end;

// Sets the media times the object should report

function TBCRendererPosPassThru.RegisterMediaTime(StartTime,
  EndTime: int64): HRESULT;
begin
  FPositionLock.Lock;
  try
    FStartMedia := StartTime;
    FEndMedia   := EndTime;
    FReset      := FALSE;
    result      := NOERROR;
  finally
    FPositionLock.UnLock;
  end;
end;

// Resets the media times we hold

function TBCRendererPosPassThru.ResetMediaTime: HRESULT;
begin
  FPositionLock.Lock;
  try
    FStartMedia := 0;
    FEndMedia   := 0;
    FReset      := True;
    result      := NOERROR;
  finally
    FPositionLock.UnLock;
  end;
end;

{ TBCAMEvent }

function TBCAMEvent.Check: boolean;
begin
  result := Wait(0); 
end;

constructor TBCAMEvent.Create(ManualReset: boolean);
begin
  FEvent := CreateEvent(nil, ManualReset, FALSE, nil);
end;

destructor TBCAMEvent.destroy;
begin
  if FEvent <> 0 then
  begin
  {$IFOPT C+}
    Assert(CloseHandle(FEvent));
  {$ELSE}
    CloseHandle(FEvent);
  {$ENDIF}
  end;
  inherited;
end;

procedure TBCAMEvent.Reset;
begin
  ResetEvent(FEvent);
end;

procedure TBCAMEvent.SetEv;
begin
  SetEvent(FEvent);
end;

function TBCAMEvent.Wait(Timeout: Cardinal): boolean;
begin
  result := (WaitForSingleObject(FEvent, Timeout) = WAIT_OBJECT_0);
end;

{ TBCRenderedInputPin }

function TBCRenderedInputPin.Active: HRESULT;
begin
  FAtEndOfStream := FALSE;
  FCompleteNotified := FALSE;
  result := inherited Active;
end;

constructor TBCRenderedInputPin.Create(ObjectName: string;
  Filter: TBCBaseFilter; Lock: TBCCritSec; out hr: HRESULT;
  Name: WideString);
begin
   inherited Create(ObjectName, Filter, Lock, hr, Name);
   FAtEndOfStream := FALSE;
   FCompleteNotified := FALSE;
end;

procedure TBCRenderedInputPin.DoCompleteHandling;
begin
  ASSERT(FAtEndOfStream);
  if (not FCompleteNotified) then
  begin
    FCompleteNotified := True;
    FFilter.NotifyEvent(EC_COMPLETE, S_OK, Integer(FFilter));
  end;
end;

function TBCRenderedInputPin.EndFlush: HRESULT;
begin
  FLock.Lock;
  try
    // Clean up renderer state
    FAtEndOfStream := FALSE;
    FCompleteNotified := FALSE;
    result := inherited EndFlush;
  finally
    FLock.UnLock;
  end;
end;

function TBCRenderedInputPin.EndOfStream: HRESULT;
var
  fs: TFilterState;
begin
  result := CheckStreaming;
  //  Do EC_COMPLETE handling for rendered pins
  if ((result = S_OK) and (not FAtEndOfStream)) then
  begin
    FAtEndOfStream := True;
  {$IFOPT C+}
    ASSERT(SUCCEEDED(FFilter.GetState(0, fs)));
  {$ELSE}
    FFilter.GetState(0, fs);
  {$ENDIF}
    if (fs = State_Running) then
      DoCompleteHandling;
  end;
end;

function TBCRenderedInputPin.Run(Start: TReferenceTime): HRESULT;
begin
  FCompleteNotified := FALSE;
  if FAtEndOfStream then DoCompleteHandling;
  result := S_OK;
end;

{ TBCAMMsgEvent }

function TBCAMMsgEvent.WaitMsg(Timeout: DWord): boolean;
var
  // wait for the event to be signalled, or for the
  // timeout (in MS) to expire.  allow SENT messages
  // to be processed while we wait
  Wait, StartTime: DWord;
  // set the waiting period.
  WaitTime: Dword;
  Msg: TMsg;
  Elapsed: DWord;
begin
  WaitTime := Timeout;

  // the timeout will eventually run down as we iterate
  // processing messages.  grab the start time so that
  // we can calculate elapsed times.
  if (WaitTime <> INFINITE) then
    StartTime := timeGetTime else
    StartTime := 0; // don't generate compiler hint 

  repeat
    Wait := MsgWaitForMultipleObjects(1, FEvent, FALSE, WaitTime, QS_SENDMESSAGE);
    if (Wait = WAIT_OBJECT_0 + 1) then
    begin

      PeekMessage(Msg, 0, 0, 0, PM_NOREMOVE);

	    // If we have an explicit length of time to wait calculate
	    // the next wake up point - which might be now.
	    // If dwTimeout is INFINITE, it stays INFINITE
	    if (WaitTime <> INFINITE) then
      begin
    		Elapsed := timeGetTime - StartTime;
        if (Elapsed >= Timeout) then
          WaitTime := 0 else // wake up with WAIT_TIMEOUT
    			WaitTime := Timeout - Elapsed;
	    end;
    end
  until (Wait <> WAIT_OBJECT_0 + 1);

  // return True if we woke on the event handle,
  //        FALSE if we timed out.
  result := (Wait = WAIT_OBJECT_0);
end;

{ TBCAMThread }

function TBCAMThread.CallWorker(Param: DWORD): DWORD;
begin
  // lock access to the worker thread for scope of this object
  FAccessLock.Lock;
  try
    if not ThreadExists then
    begin
      Result := DWORD(E_FAIL);
      Exit;
    end;

    // set the parameter
    FParam := Param;

    // signal the worker thread
    FEventSend.SetEv;

    // wait for the completion to be signalled
    FEventComplete.Wait;

    // done - this is the thread's return value
    Result := FReturnVal;
  finally
    FAccessLock.unlock;
  end;
end;

function TBCAMThread.CheckRequest(Param: PDWORD): boolean;
begin
  if not FEventSend.Check then
  begin
    Result := FALSE;
    Exit;
  end else
  begin
    if (Param <> nil) then
      Param^ := FParam;
    Result := True;
  end;
end;

procedure TBCAMThread.Close;
var
  Thread: THandle;
begin
  Thread := InterlockedExchange(Integer(FThread), 0);
  if BOOL(Thread) then
  begin
    WaitForSingleObject(Thread, INFINITE);
    CloseHandle(Thread);
  end;
end;

class function TBCAMThread.CoInitializeHelper: HRESULT;
var
  hr: HRESULT;
  hOle: LongWord;
  CoInitializeEx: function(pvReserved: Pointer; coInit: Longint): HResult; stdcall;
begin
    // call CoInitializeEx and tell OLE not to create a window (this
    // thread probably won't dispatch messages and will hang on
    // broadcast msgs o/w).
    //
    // If CoInitEx is not available, threads that don't call CoCreate
    // aren't affected. Threads that do will have to handle the
    // failure. Perhaps we should fall back to CoInitialize and risk
    // hanging?
    //

    // older versions of ole32.dll don't have CoInitializeEx

    hr := E_FAIL;
    hOle := GetModuleHandle(PChar('ole32.dll'));
    if (hOle <> 0) then
    begin
      CoInitializeEx := GetProcAddress(hOle, 'CoInitializeEx');
      if (@CoInitializeEx <> nil) then
        hr := CoInitializeEx(nil, COINIT_DISABLE_OLE1DDE);
    end else
    begin
    {$IFDEF _DEBUG}
      // caller must load ole32.dll
       DbgLog('couldn''t locate ole32.dll');
    {$ENDIF}
    end;
    result := hr;
end;

constructor TBCAMThread.Create;
begin
  // must be manual-reset for CheckRequest()
  FAccessLock := TBCCritSec.Create;
  FWorkerLock := TBCCritSec.Create;
  FEventSend := TBCAMEvent.Create(True);
  FEventComplete := TBCAMEvent.Create;
  FThread := 0;
  FThreadProc := nil;
end;

// thread initially runs this. param is actually 'this'. function
// just gets this and calls ThreadProc
function InitialAMThreadThreadProc(p: Pointer): DWORD; stdcall;
var
  hrCoInit: HRESULT;
begin
  hrCoInit := TBCAMThread.CoInitializeHelper;
{$IFDEF _DEBUG}
  if(FAILED(hrCoInit)) then
    DbgLog('CoInitializeEx failed.');
{$ENDIF}
  Result := TBCAMThread(p).ThreadProc;
  if(SUCCEEDED(hrCoInit)) then
    CoUninitialize;
end;

function TBCAMThread.Create_: boolean;
var
  threadid: DWORD;
begin
  FAccessLock.Lock;
  try
    if ThreadExists then
    begin
      Result := False;
      Exit;
    end;
    FThread := CreateThread(nil, 0, @InitialAMThreadThreadProc,
      Self, 0, threadid);
    if not BOOL(FThread) then
      Result := FALSE else
      Result := True;
  finally
    FAccessLock.Unlock;
  end;
end;

destructor TBCAMThread.Destroy;
begin
  Close;
  FAccessLock.Free;
  FWorkerLock.Free;
  FEventSend.Free;
  FEventComplete.Free;
  inherited;
end;

function TBCAMThread.GetRequest: DWORD;
begin
  FEventSend.Wait;
  Result := FParam;
end;

function TBCAMThread.GetRequestHandle: THANDLE;
begin
  Result := FEventSend.FEvent
end;

function TBCAMThread.GetRequestParam: DWORD;
begin
  Result := FParam;
end;

procedure TBCAMThread.Reply(v: DWORD);
begin
    FReturnVal := v;

    // The request is now complete so CheckRequest should fail from
    // now on
    //
    // This event should be reset BEFORE we signal the client or
    // the client may Set it before we reset it and we'll then
    // reset it (!)

    FEventSend.Reset;

    // Tell the client we're finished

    FEventComplete.SetEv;
end;

function TBCAMThread.ThreadExists: boolean;
begin
  Result := FThread <> 0;
end;

function TBCAMThread.ThreadProc: DWord;
begin
  if @FThreadProc <> nil then
    Result := FThreadProc else
    Result := 0
end;

{ TBCNode }

{$ifdef _DEBUG}
constructor TBCNode.Create;
begin
  inherited Create('List node');
end;
{$ENDIF}

{ TBCNodeCache }

procedure TBCNodeCache.AddToCache(Node: TBCNode);
begin
  if (FUsed < FCacheSize) then
  begin
    Node.Next := FHead;
    FHead := Node;
    inc(FUsed);
  end else
    Node.Free;
end;

constructor TBCNodeCache.Create(CacheSize: Integer);
begin
  FCacheSize := CacheSize;
  FHead := nil;
  FUsed := 0;
end;

destructor TBCNodeCache.Destroy;
var Node, Current: TBCNode;
begin
  Node := FHead;
  while (Node <> nil) do
  begin
    Current := Node;
    Node := Node.Next;
    Current.Free;
  end;
  inherited;
end;

function TBCNodeCache.RemoveFromCache: TBCNode;
var Node: TBCNode;
begin
  Node := FHead;
  if (Node <> nil) then
  begin
    FHead := Node.Next;
    Dec(FUsed);
    ASSERT(FUsed >= 0);
  end else
    ASSERT(FUsed = 0);
  Result := Node;
end;

{ TBCBaseList }

function TBCBaseList.AddAfter(p: Position; List: TBCBaseList): BOOL;
var pos: Position;
begin
  pos := list.GetHeadPositionI;
  while(pos <> nil) do
  begin
    // p follows along the elements being added
    p := AddAfterI(p, List.GetI(pos));
    if (p = nil) then
    begin
      Result := FALSE;
      Exit;
    end;
    pos := list.Next(pos);
  end;
  Result := True;
end;

(* Add the object after position p
   p is still valid after the operation.
   AddAfter(NULL,x) adds x to the start - same as AddHead
   Return the position of the new object, NULL if it failed
*)
function TBCBaseList.AddAfterI(pos: Position; Obj: Pointer): Position;
var After, Node, Before: TBCNode;
begin
  if (pos = nil) then
    Result := AddHeadI(Obj) else
  begin

    (* As someone else might be furkling with the list -
       Lock the critical section before continuing
    *)
    After := pos;
    ASSERT(After <> nil);
    if (After = FLast) then
      Result := AddTailI(Obj) else
      begin

        // set pnode to point to a new node, preferably from the cache

        Node := FCache.RemoveFromCache;
        if (Node = nil) then
          Node := TBCNode.Create;

        // Check we have a valid object

        if (Node = nil) then
          Result := nil else
          begin

          (* Initialise all the CNode object
             just in case it came from the cache
          *)

          Node.Data := Obj;

          (* It is to be added to the middle of the list - there is a before
             and after node.  Chain it after pAfter, before pBefore.
          *)
          Before := After.Next;
          ASSERT(Before <> nil);

          // chain it in (set four pointers)
          Node.Prev := After;
          Node.Next := Before;
          Before.Prev := Node;
          After.Next := Node;

          inc(FCount);

          Result := Node;
        end;
      end;
    end;
end;

function TBCBaseList.AddBefore(p: Position; List: TBCBaseList): BOOL;
var pos: Position;
begin
  pos := List.GetTailPositionI;
  while (pos <> nil) do
  begin
      // p follows along the elements being added
      p := AddBeforeI(p, List.GetI(pos));
      if (p = nil) then
      begin
        Result := FALSE;
        Exit;
      end;
    pos := list.Prev(pos);
  end;
  Result := True;
end;

(* Mirror images:
   Add the element or list after position p.
   p is still valid after the operation.
   AddBefore(NULL,x) adds x to the end - same as AddTail
*)
function TBCBaseList.AddBeforeI(pos: Position; Obj: Pointer): Position;
var
  Before, Node, After: TBCNode;
begin
  if (pos = nil) then
    Result := AddTailI(Obj) else
    begin
      // set pnode to point to a new node, preferably from the cache

      Before := pos;
      ASSERT(Before <> nil);
      if (Before = FFirst) then
        Result := AddHeadI(Obj) else
        begin
          Node := FCache.RemoveFromCache;
          if (Node = nil) then
            Node := TBCNode.Create;

          // Check we have a valid object */

          if (Node = nil) then
            Result := nil else
            begin
              (* Initialise all the CNode object
                 just in case it came from the cache
              *)

              Node.Data := Obj;

              (* It is to be added to the middle of the list - there is a before
                 and after node.  Chain it after pAfter, before pBefore.
              *)

              After := Before.Prev;
              ASSERT(After <> nil);

              // chain it in (set four pointers)
              Node.Prev := After;
              Node.Next := Before;
              Before.Prev := Node;
              After.Next := Node;

              inc(FCount);

              Result := Node;
            end;
        end;
    end;
end;

(* Add all the elements in *pList to the head of this list.
   Return True if it all worked, FALSE if it didn't.
   If it fails some elements may have been added.
*)
function TBCBaseList.AddHead(List: TBCBaseList): BOOL;
var
  pos: Position;
begin
  (* lock the object before starting then enumerate
     each entry in the source list and add them one by one to
     our list (while still holding the object lock)
     Lock the other list too.

     To avoid reversing the list, traverse it backwards.
  *)

  pos := list.GetTailPositionI;
  while (pos <> nil) do
  begin
    if (nil = AddHeadI(List.GetI(pos))) then
    begin
      Result := FALSE;
      Exit;
    end;
    pos := list.Prev(pos)
  end;

  Result := True;
end;

(* Add this object to the head end of our list
   Return the new head position.
*)
function TBCBaseList.AddHeadI(Obj: Pointer): Position;
var Node: TBCNode;
begin
  (* If there is a node objects in the cache then use
     that otherwise we will have to create a new one *)

  Node := FCache.RemoveFromCache;
  if (Node = nil) then
    Node := TBCNode.Create;

  // Check we have a valid object

  if (Node = nil) then
  begin
    Result := nil;
    Exit;
  end;

  (* Initialise all the CNode object
     just in case it came from the cache
  *)

  Node.Data := Obj;

  // chain it in (set four pointers)
  Node.Prev := nil;
  Node.Next := FFirst;

  if (FFirst = nil) then
    FLast := Node;
    FFirst.Prev := Node;
  FFirst := Node;

  inc(FCount);
  Result := Node;
end;

(* Add all the elements in *pList to the tail of this list.
   Return True if it all worked, FALSE if it didn't.
   If it fails some elements may have been added.
*)
function TBCBaseList.AddTail(List: TBCBaseList): boolean;
var pos: Position;
begin
  (* lock the object before starting then enumerate
     each entry in the source list and add them one by one to
     our list (while still holding the object lock)
     Lock the other list too.
  *)
  Result := false;
  pos := List.GetHeadPositionI;
  while (pos <> nil) do
    if (nil = AddTailI(List.GetNextI(pos))) then
      Exit;
  Result := True;
end;

(* Add this object to the tail end of our list
   Return the new tail position.
*)
function TBCBaseList.AddTailI(Obj: Pointer): Position;
var
  Node: TBCNode;
begin
  // Lock the critical section before continuing

  // ASSERT(pObject);   // NULL pointers in the list are allowed.

  (* If there is a node objects in the cache then use
     that otherwise we will have to create a new one *)

  Node := FCache.RemoveFromCache;
  if (Node = nil) then
    Node := TBCNode.Create;

  // Check we have a valid object

  if Node = nil then // HG: out of memory ???
  begin
    Result := nil;
    Exit;
  end;

  (* Initialise all the CNode object
     just in case it came from the cache
  *)

  Node.Data := Obj;
  Node.Next := nil;
  Node.Prev := FLast;

  if (FLast = nil) then
    FFirst := Node;
    FLast.Next := Node;

  (* Set the new last node pointer and also increment the number
     of list entries, the critical section is unlocked when we
     exit the function
  *)

  FLast := Node;
  inc(FCount);

  Result := Node;
end;

(* Constructor calls a separate initialisation function that
   creates a node cache, optionally creates a lock object
   and optionally creates a signaling object.

   By default we create a locking object, a DEFAULTCACHE sized
   cache but no event object so the list cannot be used in calls
   to WaitForSingleObject
*)
constructor TBCBaseList.Create(Name: string; Items: Integer = DEFAULTCACHE);
begin
{$ifdef _DEBUG}
  inherited Create(Name);
{$endif}
  FFirst := nil;
  FLast  := nil;
  FCount := 0;
  FCache := TBCNodeCache.Create(Items);
end;

(* The destructor enumerates all the node objects in the list and
   in the cache deleting each in turn. We do not do any processing
   on the objects that the list holds (i.e. points to) so if they
   represent interfaces for example the creator of the list should
   ensure that each of them is released before deleting us
*)
destructor TBCBaseList.Destroy;
begin
  RemoveAll;
  FCache.Free;
  inherited;
end;

(* Return the first position in the list which holds the given pointer.
   Return NULL if it's not found.
*)
function TBCBaseList.FindI(Obj: Pointer): Position;
begin
  Result := GetHeadPositionI;
  while (Result <> nil) do
  begin
    if (GetI(Result) = Obj) then Exit;
    Result := Next(Result);
  end;
end;

(* Get the number of objects in the list,
   Get the lock before accessing the count.
   Locking may not be entirely necessary but it has the side effect
   of making sure that all operations are complete before we get it.
   So for example if a list is being added to this list then that
   will have completed in full before we continue rather than seeing
   an intermediate albeit valid state
*)
function TBCBaseList.GetCountI: Integer;
begin
  Result := FCount;
end;

(* Return a position enumerator for the entire list.
   A position enumerator is a pointer to a node object cast to a
   transparent type so all we do is return the head/tail node
   pointer in the list.
   WARNING because the position is a pointer to a node there is
   an implicit assumption for users a the list class that after
   deleting an object from the list that any other position
   enumerators that you have may be invalid (since the node
   may be gone).
*)
function TBCBaseList.GetHeadPositionI: Position;
begin
  result := Position(FFirst);
end;

(* Return the object at p.
   Asking for the object at NULL ASSERTs then returns NULL
   The object is NOT locked.  The list is not being changed
   in any way.  If another thread is busy deleting the object
   then locking would only result in a change from one bad
   behaviour to another.
*)
function TBCBaseList.GetI(p: Position): Pointer;
begin
  if (p = nil) then
    Result := nil else
    Result := TBCNode(p).Data;
end;

(* Return the object at rp, update rp to the next object from
   the list or NULL if you have moved over the last object.
   You may still call this function once we return NULL but
   we will continue to return a NULL position value
*)
function TBCBaseList.GetNextI(var rp: Position): Pointer;
var
  pn: TBCNode;
begin
  // have we reached the end of the list

  if (rp = nil) then
    Result := nil else
  begin
    // Lock the object before continuing
    // Copy the original position then step on

    pn := rp;
    ASSERT(pn <> nil);
    rp := Position(pn.Next);

    // Get the object at the original position from the list

    Result := pn.Data;
  end;
end;

function TBCBaseList.GetTailPositionI: Position;
begin
  Result := Position(FLast);
end;

(* Mirror image of MoveToTail:
   Split self before position p in self.
   Retain in self the head portion of the original self
   Add the tail portion to the start (i.e. head) of *pList
   Return True if it all worked, FALSE if it didn't.

   e.g.
      foo->MoveToHead(foo->GetTailPosition(), bar);
          moves one element from the tail of foo to the head of bar
      foo->MoveToHead(NULL, bar);
          is a no-op
      foo->MoveToHead(foo->GetHeadPosition, bar);
          concatenates foo onto the start of bar and empties foo.
*)
function TBCBaseList.MoveToHead(pos: Position; List: TBCBaseList): boolean;
var
  p: TBCNode;
  m: Integer;
begin
  // See the comments on the algorithm in MoveToTail

  if (pos = nil) then
    Result := True else  // no-op.  Eliminates special cases later.
    begin
      // Make cMove the number of nodes to move
      p := pos;
      m := 0;            // number of nodes to move
      while(p <> nil) do
      begin
        p := p.Next;
        inc(m);
      end;

      // Join the two chains together
      if (List.FFirst <> nil) then
        List.FFirst.Prev := FLast;
      if (FLast <> nil) then
        FLast.Next := List.FFirst;

      // set first and last pointers
      p := pos;

      if (List.FLast = nil) then
        List.FLast := FLast;

      FLast := p.Prev;
      if (FLast = nil) then
        FFirst := nil;
      List.FFirst := p;

      // Break the chain after p to create the new pieces
      if (FLast <> nil) then
        FLast.Next := nil;
      p.Prev := nil;

      // Adjust the counts
      dec(FCount, m);
      inc(List.FCount, m);

      Result := True;
    end;
end;

(* Split self after position p in self
   Retain as self the tail portion of the original self
   Add the head portion to the tail end of *pList
   Return True if it all worked, FALSE if it didn't.

   e.g.
      foo->MoveToTail(foo->GetHeadPosition(), bar);
          moves one element from the head of foo to the tail of bar
      foo->MoveToTail(NULL, bar);
          is a no-op
      foo->MoveToTail(foo->GetTailPosition, bar);
          concatenates foo onto the end of bar and empties foo.

   A better, except excessively long name might be
       MoveElementsFromHeadThroughPositionToOtherTail
*)
function TBCBaseList.MoveToTail(pos: Position; List: TBCBaseList): boolean;
var
  p: TBCNode;
  m: Integer;
begin
  (* Algorithm:
     Note that the elements (including their order) in the concatenation
     of *pList to the head of self is invariant.
     1. Count elements to be moved
     2. Join *pList onto the head of this to make one long chain
     3. Set first/Last pointers in self and *pList
     4. Break the chain at the new place
     5. Adjust counts
     6. Set/Reset any events
  *)

  if (pos = nil) then
    Result := True else  // no-op.  Eliminates special cases later.
    begin

      // Make m the number of nodes to move
      p := pos;
      m := 0;            // number of nodes to move
      while(p <> nil) do
      begin
        p := p.Prev;
        inc(m);
      end;

      // Join the two chains together
      if (List.FLast <> nil) then
        List.FLast.Next := FFirst;
      if (FFirst <> nil) then
        FFirst.Prev := List.FLast;


      // set first and last pointers 
      p := pos;

      if (List.FFirst = nil) then
        List.FFirst := FFirst;
      FFirst := p.Next;
      if (FFirst = nil) then
        FLast := nil;
      List.FLast := p;


      // Break the chain after p to create the new pieces
      if (FFirst <> nil) then
        FFirst.Prev := nil;
      p.Next := nil;


      // Adjust the counts 
      dec(FCount, m);
      inc(List.FCount, m);

      Result := True;
    end;

end;

function TBCBaseList.Next(pos: Position): Position;
begin
  if (pos = nil) then
    Result := Position(FFirst) else
    Result := Position(TBCNode(pos).Next);
end;

function TBCBaseList.Prev(pos: Position): Position;
begin
  if (pos = nil) then
    Result := Position(FLast) else
    Result := Position(TBCNode(pos).Prev);
end;

(* Remove all the nodes from the list but don't do anything
   with the objects that each node looks after (this is the
   responsibility of the creator).
   Aa a last act we reset the signalling event
   (if available) to indicate to clients that the list
   does not have any entries in it.
*)
procedure TBCBaseList.RemoveAll;
var pn, op: TBCNode;
begin
  (* Free up all the CNode objects NOTE we don't bother putting the
     deleted nodes into the cache as this method is only really called
     in serious times of change such as when we are being deleted at
     which point the cache will be deleted anyway *)

  pn := FFirst;
  while (pn <> nil) do
  begin
    op := pn;
    pn := pn.Next;
    op.Free;
  end;

  (* Reset the object count and the list pointers *)

  FCount := 0;
  FFirst := nil;
  FLast  := nil;
end;

(* Remove the first node in the list (deletes the pointer to its object
   from the list, does not free the object itself).
   Return the pointer to its object or NULL if empty
*)
function TBCBaseList.RemoveHeadI: Pointer;
begin
  (* All we do is get the head position and ask for that to be deleted.
     We could special case this since some of the code path checking
     in Remove() is redundant as we know there is no previous
     node for example but it seems to gain little over the
     added complexity
  *)

  Result := RemoveI(FFirst);
end;

(* Remove the pointer to the object in this position from the list.
   Deal with all the chain pointers
   Return a pointer to the object removed from the list.
   The node object that is freed as a result
   of this operation is added to the node cache where
   it can be used again.
   Remove(NULL) is a harmless no-op - but probably is a wart.
*)
function TBCBaseList.RemoveI(pos: Position): Pointer;
var
  Current, Node: TBCNode;
begin
  (* Lock the critical section before continuing *)

  if (pos = nil) then
    Result := nil else
    begin
      Current := pos;
      ASSERT(Current <> nil);
      // Update the previous node

      Node := Current.Prev;
      if (Node = nil) then
        FFirst := Current.Next else
        Node.Next := Current.Next;

      // Update the following node

      Node := Current.Next;
      if (Node = nil) then
        FLast := Current.Prev else
        Node.Prev := Current.Prev;

      // Get the object this node was looking after */
      Result := Current.Data;

      // ASSERT(pObject != NULL);    // NULL pointers in the list are allowed.

      (* Try and add the node object to the cache -
         a NULL return code from the cache means we ran out of room.
         The cache size is fixed by a constructor argument when the
         list is created and defaults to DEFAULTCACHE.
         This means that the cache will have room for this many
         node objects. So if you have a list of media samples
         and you know there will never be more than five active at
         any given time of them for example then override the default
         constructor
      *)

      FCache.AddToCache(Current);

      // If the list is empty then reset the list event

      Dec(FCount);
      ASSERT(FCount >= 0);
    end;
end;

(* Remove the last node in the list (deletes the pointer to its object
   from the list, does not free the object itself).
   Return the pointer to its object or NULL if empty
*)
function TBCBaseList.RemoveTailI: Pointer;
begin
  (* All we do is get the tail position and ask for that to be deleted.
     We could special case this since some of the code path checking
     in Remove() is redundant as we know there is no previous
     node for example but it seems to gain little over the
     added complexity
  *)
  Result := RemoveI(FLast);
end;

(* Reverse the order of the [pointers to] objects in slef *)
procedure TBCBaseList.Reverse;
var p, q: TBCNode;
begin
  (* algorithm:
     The obvious booby trap is that you flip pointers around and lose
     addressability to the node that you are going to process next.
     The easy way to avoid this is do do one chain at a time.

     Run along the forward chain,
     For each node, set the reverse pointer to the one ahead of us.
     The reverse chain is now a copy of the old forward chain, including
     the NULL termination.

     Run along the reverse chain (i.e. old forward chain again)
     For each node set the forward pointer of the node ahead to point back
     to the one we're standing on.
     The first node needs special treatment,
     it's new forward pointer is NULL.
     Finally set the First/Last pointers

  *)

  // Yes we COULD use a traverse, but it would look funny!
  p := FFirst;
  while (p <> nil) do
  begin
    q := p.Next;
    p.Next := p.Prev;
    p.Prev := q;
    p := q;
  end;
  p := FFirst;
  FFirst := FLast;
  FLast := p;
end;

{ TBCSource }

function TBCSource.AddPin(Stream: TBCSourceStream): HRESULT;
begin
  FStateLock.Lock;
  try
    inc(FPins);
    ReallocMem(FStreams, FPins * SizeOf(TBCSourceStream));
    TStreamArray(FStreams)[FPins-1] := Stream;
    Result := S_OK;
  finally
    FStateLock.UnLock;
  end;
end;
// milenko start (delphi 5 doesn't IInterface - changed IInterface to IUnknown)
constructor TBCSource.Create(const Name: string; unk: IUnknown;
// milenko end
  const clsid: TGUID; out hr: HRESULT);
begin
  FStateLock := TBCCritSec.Create;
  // nev: changed 02/17/04
  inherited Create(Name, unk, FStateLock, clsid, hr);
  FPins := 0;
  FStreams := nil;
end;

// milenko start (delphi 5 doesn't IInterface - changed IInterface to IUnknown)
constructor TBCSource.Create(const Name: string; unk: IUnknown;
// milenko end
  const clsid: TGUID);
begin
  FStateLock := TBCCritSec.Create;
  inherited Create(Name, unk, FStateLock, clsid);
  FPins := 0;
  FStreams := nil;
end;

destructor TBCSource.Destroy;
begin
  //  Free our pins and pin array
  while (FPins <> 0) do
    // deleting the pins causes them to be removed from the array...
	  TStreamArray(FStreams)[FPins - 1].Free;
  if Assigned(FStreams) then FreeMem(FStreams);
  ASSERT(FPins = 0);
  inherited;
end;

// Set Pin to the IPin that has the id Id.
// or to nil if the Id cannot be matched.
function TBCSource.FindPin(Id: PWideChar; out Pin: IPin): HRESULT;
var
  i : integer;
  Code : integer;
begin
  // The -1 undoes the +1 in QueryId and ensures that totally invalid
  // strings (for which WstrToInt delivers 0) give a deliver a NULL pin.

  // DCoder (1. Nov 2003)
  // StrToInt throws EConvertError Exceptions if
  // a Filter calls FindPin with a String instead of a Number in ID.
  // To be sure, capture the Error Handling by using Val and call
  // the inherited function if Val fails.
  
  Val(Id,i,Code);
  if Code = 0 then
  begin
    i := i - 1;
    Pin := GetPin(i);
    if (Pin <> nil) then
      Result := NOERROR else
      Result := VFW_E_NOT_FOUND;
  end else Result := inherited FindPin(Id,Pin);
end;

// return the number of the pin with this IPin or -1 if none
function TBCSource.FindPinNumber(Pin: IPin): Integer;
begin
  for Result := 0 to FPins - 1 do
    if (IPin(TStreamArray(FStreams)[Result]) = Pin) then
      Exit;
  Result := -1;
end;

// Return a non-addref'd pointer to pin n
// needed by CBaseFilter
function TBCSource.GetPin(n: Integer): TBCBasePin;
begin
  FStateLock.Lock;
  try
    // n must be in the range 0..m_iPins-1
    // if m_iPins>n  && n>=0 it follows that m_iPins>0
    // which is what used to be checked (i.e. checking that we have a pin)
    if ((n >= 0) and (n < FPins)) then
    begin
      ASSERT(TStreamArray(FStreams)[n] <> nil);
    	Result := TStreamArray(FStreams)[n];
    end else
      Result := nil;
  finally
    FStateLock.UnLock;
  end;
end;

// Returns the number of pins this filter has
function TBCSource.GetPinCount: Integer;
begin
  FStateLock.Lock;
  try
    Result := FPins;
  finally
    FStateLock.UnLock;
  end;
end;

function TBCSource.RemovePin(Stream: TBCSourceStream): HRESULT;
var i, j: Integer;
begin
  for i := 0 to FPins - 1 do
  begin
    if (TStreamArray(FStreams)[i] = Stream) then
    begin
      if (FPins = 1) then
      begin
        FreeMem(FStreams);
        FStreams := nil;
      end else
      begin
        //  no need to reallocate
        j := i + 1;
        while (j < FPins) do
        begin
          TStreamArray(FStreams)[j-1] := TStreamArray(FStreams)[j];
          inc(j);
        end;
      end;
      dec(FPins);
      Result := S_OK;
      Exit;
    end;
  end;
  Result := S_FALSE;
end;

{ TBCSourceStream }

// The pin is active - start up the worker thread
function TBCSourceStream.Active: HRESULT;
begin
  FFilter.FStateLock.Lock;
  try
    if (FFilter.IsActive) then
    begin
      Result := S_FALSE;	// succeeded, but did not allocate resources (they already exist...)
      Exit;
    end;

    // do nothing if not connected - its ok not to connect to
    // all pins of a source filter
    if not IsConnected then
    begin
      Result := NOERROR;
      Exit;
    end;

    Result := inherited Active;
    if FAILED(Result) then
      Exit;

    ASSERT(not FThread.ThreadExists);

    // start the thread
    if not FThread.Create_ then
    begin
      Result := E_FAIL;
      Exit;
    end;

    // Tell thread to initialize. If OnThreadCreate Fails, so does this.
    Result := Init;
    if FAILED(Result) then
      Exit;

    Result := Pause;
  finally
    FFilter.FStateLock.UnLock;
  end;
end;

// Do we support this type? Provides the default support for 1 type.
function TBCSourceStream.CheckMediaType(MediaType: PAMMediaType): HRESULT;
var mt: TAMMediaType;
    pmt: PAMMediaType;
begin
  FFilter.FStateLock.Lock;
  try
    pmt := @mt;
    GetMediaType(pmt);
    if TBCMediaType(pmt).Equal(MediaType) then
      Result := NOERROR else
      Result := E_FAIL;
  finally
    FFilter.FStateLock.UnLock;
  end;
end;

function TBCSourceStream.CheckRequest(var com: TThreadCommand): boolean;
begin
  Result := FThread.CheckRequest(@Com);
end;

// increments the number of pins present on the filter
constructor TBCSourceStream.Create(const ObjectName: string;
  out hr: HRESULT; Filter: TBCSource; const Name: WideString);
begin
  FThread := TBCAMThread.Create;
  FThread.FThreadProc := ThreadProc;
  inherited Create(ObjectName, Filter, Filter.FStateLock,  hr, Name);
  FFilter := Filter;
  hr := FFilter.AddPin(Self);
end;

// Decrements the number of pins on this filter
destructor TBCSourceStream.Destroy;
begin
  FFilter.RemovePin(Self);
  inherited;
  FThread.Free;
end;

// Grabs a buffer and calls the users processing function.
// Overridable, so that different delivery styles can be catered for.
function TBCSourceStream.DoBufferProcessingLoop: HRESULT;
var
  com: TThreadCommand;
  Sample: IMediaSample;
begin

  OnThreadStartPlay;
  repeat
  begin
	  while not CheckRequest(com) do
    begin
	    Result := GetDeliveryBuffer(Sample, nil, nil, 0);
	    if FAILED(result) then
      begin
        Sleep(1);
		    continue;	// go round again. Perhaps the error will go away
			            // or the allocator is decommited & we will be asked to
			            // exit soon.
	    end;

	    // Virtual function user will override.
	    Result := FillBuffer(Sample);

	    if (Result = S_OK) then
      begin
     		Result := Deliver(Sample);
        Sample := nil;
        // downstream filter returns S_FALSE if it wants us to
        // stop or an error if it's reporting an error.
        if (Result <> S_OK) then
        begin
        {$IFDEF _DEBUG}
          DbgLog(format('Deliver() returned %08x; stopping', [Result]));
        {$ENDIF}
          Result := S_OK;
          Exit;
        end;
	    end else
        if (Result = S_FALSE) then
        begin
          // derived class wants us to stop pushing data
          Sample := nil;
		      DeliverEndOfStream;
		      Result := S_OK;
          Exit;
	      end else
        begin
          // derived class encountered an error
          Sample := nil;
          {$IFDEF _DEBUG}
            DbgLog(format('Error %08lX from FillBuffer!!!', [Result]));
          {$ENDIF}
          DeliverEndOfStream;
          FFilter.NotifyEvent(EC_ERRORABORT, Result, 0);
          Exit;
	      end;
        // all paths release the sample
	  end;

    // For all commands sent to us there must be a Reply call!

	  if ((com = CMD_RUN) or (com = CMD_PAUSE)) then
	    FThread.Reply(NOERROR) else
      if (com <> CMD_STOP) then
      begin
	      Fthread.Reply(DWORD(E_UNEXPECTED));
      {$IFDEF _DEBUG}
	      DbgLog('Unexpected command!!!');
      {$ENDIF}
      end
  end until (com = CMD_STOP);
  Result := S_FALSE;
end;

function TBCSourceStream.Exit_: HRESULT;
begin
  Result := FThread.CallWorker(Ord(CMD_EXIT));
end;

function TBCSourceStream.GetMediaType(MediaType: PAMMediaType): HRESULT;
begin
  Result := E_UNEXPECTED;
end;

function TBCSourceStream.GetMediaType(Position: integer;
  out MediaType: PAMMediaType): HRESULT;
begin
  // By default we support only one type
  // Position indexes are 0-n
  FFilter.FStateLock.Lock;
  try
    if (Position = 0) then
      Result := GetMediaType(MediaType)
    else
      if (Position > 0) then
        Result := VFW_S_NO_MORE_ITEMS else
        Result := E_INVALIDARG;
  finally
    FFilter.FStateLock.UnLock;
  end;
end;

function TBCSourceStream.GetRequest: TThreadCommand;
begin
  Result := TThreadCommand(FThread.GetRequest);
end;

// Pin is inactive - shut down the worker thread
// Waits for the worker to exit before returning.
function TBCSourceStream.Inactive: HRESULT;
begin
  FFilter.FStateLock.Lock;
  try

    // do nothing if not connected - its ok not to connect to
    // all pins of a source filter
    if not IsConnected then
    begin
      Result := NOERROR;
      Exit;
    end;

    // !!! need to do this before trying to stop the thread, because
    // we may be stuck waiting for our own allocator!!!

    Result := inherited Inactive;  // call this first to Decommit the allocator
    if FAILED(Result) then
      Exit;

    if FThread.ThreadExists then
    begin
	    Result := Stop;

    	if FAILED(Result) then
        Exit;

	    Result := Exit_;
      if FAILED(Result) then
        Exit;

	    FThread.Close;	// Wait for the thread to exit, then tidy up.
    end;

    Result := NOERROR;
  finally
    FFilter.FStateLock.UnLock;
  end;
end;

function TBCSourceStream.Init: HRESULT;
begin
  Result := FThread.CallWorker(Ord(CMD_INIT));
end;

function TBCSourceStream.OnThreadCreate: HRESULT;
begin
  Result := NOERROR;
end;

function TBCSourceStream.OnThreadDestroy: HRESULT;
begin
  Result := NOERROR;
end;

function TBCSourceStream.OnThreadStartPlay: HRESULT;
begin
  Result := NOERROR;
end;

function TBCSourceStream.Pause: HRESULT;
begin
  Result := FThread.CallWorker(Ord(CMD_PAUSE));
end;

// Set Id to point to a CoTaskMemAlloc'd
function TBCSourceStream.QueryId(out id: PWideChar): HRESULT;
var
  i: Integer;
begin
  // We give the pins id's which are 1,2,...
  // FindPinNumber returns -1 for an invalid pin
  i := 1 + FFilter.FindPinNumber(Self);
  if (i < 1) then
    Result := VFW_E_NOT_FOUND else
    Result := AMGetWideString(IntToStr(i), id);
end;

function TBCSourceStream.Run: HRESULT;
begin
  Result := FThread.CallWorker(Ord(CMD_RUN));
end;

function TBCSourceStream.Stop: HRESULT;
begin
  Result := FThread.CallWorker(Ord(CMD_STOP));
end;

// When this returns the thread exits
// Return codes > 0 indicate an error occured
function TBCSourceStream.ThreadProc: DWORD;
var
  com, cmd: TThreadCommand;
begin
  repeat
	  com := GetRequest;
  	if (com <> CMD_INIT) then
    begin
    {$IFDEF _DEBUG}
	    DbgLog(self, 'Thread expected init command');
    {$ENDIF}
	    FThread.Reply(DWORD(E_UNEXPECTED));
	  end;
  until (com = CMD_INIT);
  {$IFDEF _DEBUG}
    DbgLog(self, 'Worker thread initializing');
  {$ENDIF}

  Result := OnThreadCreate; // perform set up tasks
  if FAILED(Result) then
  begin
  {$IFDEF _DEBUG}
    DbgLog(Self, 'OnThreadCreate failed. Aborting thread.');
  {$ENDIF}
    OnThreadDestroy();
    FThread.Reply(Result);	// send failed return code from OnThreadCreate
    Result := 1;
    Exit;
  end;

  // Initialisation suceeded
  FThread.Reply(NOERROR);

  repeat
    cmd := GetRequest;
    // nev: changed 02/17/04
    // "repeat..until false" ensures, that if cmd = CMD_RUN
    // the next executing block will be CMD_PAUSE handler block.
    // This corresponds to the original C "switch" functionality
    repeat
      case cmd of
        CMD_EXIT, CMD_STOP:
          begin
            FThread.Reply(NOERROR);
            Break;
          end;
        CMD_RUN:
          begin
          {$IFDEF _DEBUG}
            DbgLog(Self, 'CMD_RUN received before a CMD_PAUSE???');
          {$ENDIF}
            // !!! fall through???
            cmd := CMD_PAUSE;
          end;
        CMD_PAUSE:
          begin
            FThread.Reply(NOERROR);
            DoBufferProcessingLoop;
            Break;
          end;
      else
      {$IFDEF _DEBUG}
        DbgLog(self, format('Unknown command %d received!', [Integer(cmd)]));
      {$ENDIF}
        FThread.Reply(DWORD(E_NOTIMPL));
        Break;
      end;
    until False;
  until (cmd = CMD_EXIT);

  Result := OnThreadDestroy;	// tidy up.
  if FAILED(Result) then
  begin
  {$IFDEF _DEBUG}
    DbgLog(self, 'OnThreadDestroy failed. Exiting thread.');
  {$ENDIF}
    Result := 1;
    Exit;
  end;
{$IFDEF _DEBUG}
  DbgLog(Self, 'worker thread exiting');
{$ENDIF}
  Result := 0;
end;

function TimeKillSynchronousFlagAvailable: Boolean;
var
  osverinfo: TOSVERSIONINFO;
begin
  osverinfo.dwOSVersionInfoSize := sizeof(osverinfo);
  if GetVersionEx(osverinfo) then
    // Windows XP's major version is 5 and its' minor version is 1.
    // timeSetEvent() started supporting the TIME_KILL_SYNCHRONOUS flag
    // in Windows XP.
    Result := (osverinfo.dwMajorVersion > 5) or
      ((osverinfo.dwMajorVersion = 5) and (osverinfo.dwMinorVersion >= 1))
  else
    Result := False;
end;

function CompatibleTimeSetEvent(Delay, Resolution: UINT;
  TimeProc: TFNTimeCallBack; User: DWORD; Event: UINT): MMResult;
// milenko start (replaced with global variables)
//const
//{$IFOPT J-}
//{$DEFINE ResetJ}
//{$J+}
//{$ENDIF}
//  IsCheckedVersion: Bool = False;
//  IsTimeKillSynchronousFlagAvailable: Bool = False;
//{$IFDEF ResetJ}
//{$J-}
//{$UNDEF ResetJ}
//{$ENDIF}
const
  TIME_KILL_SYNCHRONOUS = $100;
// Milenko end
var
  Event_: UINT;
begin
  Event_ := Event;
  // ??? TIME_KILL_SYNCHRONOUS flag is defined in MMSystem for XP:
  // need to check that D7 unit for proper compilation flag
// Milenko start (no need for "ifdef xp" in delphi)
// {$IFDEF XP}
  if not IsCheckedVersion then
  begin
    IsTimeKillSynchronousFlagAvailable := TimeKillSynchronousFlagAvailable;
    IsCheckedVersion := true;
  end;

  if IsTimeKillSynchronousFlagAvailable then
    Event_ := Event_ or TIME_KILL_SYNCHRONOUS;
// {$ENDIF}
// Milenko end
  Result := timeSetEvent(Delay, Resolution, TimeProc, User, Event_);
end;

// ??? See Measure.h for Msr_??? definition
// milenko start (only needed with PERF)
{$IFDEF PERF}
type
  TIncidentRec = packed record
    Name: String[255];
  end;
  TIncidentLog = packed record
    Id: Integer;
    Time: TReferenceTime;
    Data: Integer;
    Note: String[10];
  end;

var
  Incidents: array of TIncidentRec;
  IncidentsLog: array of TIncidentLog;
{$ENDIF}
// milenko end
function MSR_REGISTER(s: String): Integer;
// milenko start (only needed with PERF)
{$IFDEF PERF}
var
  k: Integer;
{$ENDIF}
// milenko end
begin
// milenko start (only needed with PERF)
{$IFDEF PERF}
  k := Length(Incidents) + 1;
  SetLength(Incidents, k);
  Incidents[k-1].Name := Copy(s, 0, 255);
  Result := k-1;
{$ELSE}
  Result := 0;
{$ENDIF}
// milenko end
end;

procedure MSR_START(Id_: Integer);
{$IFDEF PERF}
var
  k: Integer;
{$ENDIF}
begin
{$IFDEF PERF}
  Assert((Id_>=0) and (Id_<Length(Incidents)));
  k := Length(IncidentsLog) + 1;
  SetLength(IncidentsLog, k);
  with IncidentsLog[k-1] do
  begin
    Id    := Id_;
    Time  := timeGetTime;
    Data  := 0;
    Note  := Copy('START', 0, 10);
  end;
{$ENDIF}
end;

procedure MSR_STOP(Id_: Integer);
{$IFDEF PERF}
var
  k: Integer;
{$ENDIF}
begin
{$IFDEF PERF}
  Assert((Id_>=0) and (Id_<Length(Incidents)));
  k := Length(IncidentsLog) + 1;
  SetLength(IncidentsLog, k);
  with IncidentsLog[k-1] do
  begin
    Id    := Id_;
    Time  := timeGetTime;
    Data  := 0;
    Note  := Copy('STOP', 0, 10);
  end;
{$ENDIF}
end;

procedure MSR_INTEGER(Id_, i: Integer);
{$IFDEF PERF}
var
  k: Integer;
{$ENDIF}
begin
{$IFDEF PERF}
  Assert((Id_>=0) and (Id_<Length(Incidents)));
  k := Length(IncidentsLog) + 1;
  SetLength(IncidentsLog, k);
  with IncidentsLog[k-1] do
  begin
    Id    := Id_;
    Time  := timeGetTime;
    Data  := i;
    Note  := Copy('START', 0, 10);
  end;
{$ENDIF}
end;

// #define DO_MOVING_AVG(avg,obs) (avg = (1024*obs + (AVGPERIOD-1)*avg)/AVGPERIOD)

procedure DO_MOVING_AVG(var avg, obs: Integer);
begin
  avg := (1024 * obs + (AVGPERIOD - 1) * avg) div AVGPERIOD;
end;

//  Helper function for clamping time differences

function TimeDiff(rt: TReferenceTime): Integer;
begin
  if (rt < -(50 * UNITS)) then
    Result := -(50 * UNITS)
  else
    if (rt > 50 * UNITS) then
      Result := 50 * UNITS
    else
      Result := Integer(rt);
end;

// Implements the CBaseRenderer class

constructor TBCBaseRenderer.Create(RendererClass: TGUID; Name: PChar;
  Unk: IUnknown; hr: HResult);
begin
  FInterfaceLock      := TBCCritSec.Create;
  FRendererLock       := TBCCritSec.Create;
  FObjectCreationLock := TBCCritSec.Create;

  inherited Create(Name, Unk, FInterfaceLock, RendererClass);

  FCompleteEvent    := TBCAMEvent.Create(True);
  FRenderEvent      := TBCAMEvent.Create(True);
  FAbort            := False;
  FPosition         := nil;
  FThreadSignal     := TBCAMEvent.Create(True);
  FIsStreaming      := False;
  FIsEOS            := False;
  FIsEOSDelivered   := False;
  FMediaSample      := nil;
  FAdvisedCookie    := 0;
  FQSink            := nil;
  FInputPin         := nil;
  FRepaintStatus    := True;
  FSignalTime       := 0;
  FInReceive        := False;
  FEndOfStreamTimer := 0;

  Ready;
{$IFDEF PERF}
  FBaseStamp      := MSR_REGISTER('BaseRenderer: sample time stamp');
  FBaseRenderTime := MSR_REGISTER('BaseRenderer: draw time(msec)');
  FBaseAccuracy   := MSR_REGISTER('BaseRenderer: Accuracy(msec)');
{$ENDIF}
end;

// Delete the dynamically allocated IMediaPosition and IMediaSeeking helper
// object. The object is created when somebody queries us. These are standard
// control interfaces for seeking and setting start/stop positions and rates.
// We will probably also have made an input pin based on CRendererInputPin
// that has to be deleted, it's created when an enumerator calls our GetPin

destructor TBCBaseRenderer.Destroy;
begin
  Assert(not FIsStreaming);
  Assert(FEndOfStreamTimer = 0);
  StopStreaming;
  ClearPendingSample;

  // Delete any IMediaPosition implementation

  if Assigned(FPosition) then
    FreeAndNil(FPosition);

  // Delete any input pin created

  if Assigned(FInputPin) then
    FreeAndNil(FInputPin);

  // Release any Quality sink

  Assert(FQSink = nil);

  // Release critical sections objects
  // ??? will be deleted by the parent class destroy FreeAndNil(FInterfaceLock);
  FreeAndNil(FRendererLock);
  FreeAndNil(FObjectCreationLock);

  FreeAndNil(FCompleteEvent);
  FreeAndNil(FRenderEvent);
  FreeAndNil(FThreadSignal);

  inherited Destroy;
end;

// This returns the IMediaPosition and IMediaSeeking interfaces

function TBCBaseRenderer.GetMediaPositionInterface(IID: TGUID;
  out Obj): HResult;
var                                       
  hr: HResult;

begin
  FObjectCreationLock.Lock;
  try
    if Assigned(FPosition) then
    begin
// Milenko start
//      Result := FPosition.QueryInterface(IID, Obj);
      Result := FPosition.NonDelegatingQueryInterface(IID, Obj);
// Milenko end
      Exit;
    end;

    hr := NOERROR;

    // Create implementation of this dynamically since sometimes we may
    // never try and do a seek. The helper object implements a position
    // control interface (IMediaPosition) which in fact simply takes the
    // calls normally from the filter graph and passes them upstream

    //hr := CreatePosPassThru(GetOwner, False, GetPin(0), FPosition);
    FPosition := TBCRendererPosPassThru.Create('Renderer TBCPosPassThru',
      Inherited GetOwner, hr, GetPin(0));
    if (FPosition = nil) then
    begin
      Result := E_OUTOFMEMORY;
      Exit;
    end;
    if (Failed(hr)) then
    begin
      FreeAndNil(FPosition);
      Result := E_NOINTERFACE;
      Exit;
    end;
// milenko start (needed or the class will destroy itself. Disadvantage=Destructor is not called)
// Solution is to keep FPosition alive without adding a Reference Count to it. But how???
    FPosition._AddRef;
// milenko end

    Result := GetMediaPositionInterface(IID, Obj);
  finally
    FObjectCreationLock.UnLock;
  end;
end;

// milenko start (workaround for destructor issue with FPosition)
function TBCBaseRenderer.JoinFilterGraph(pGraph: IFilterGraph;
  pName: PWideChar): HRESULT;
begin
  if (pGraph = nil) and (FPosition <> nil) then
  begin
    FPosition._Release;
    Pointer(FPosition) := nil;
  end;
  Result := inherited JoinFilterGraph(pGraph,pName);
end;
// milenko end

// Overriden to say what interfaces we support and where

function TBCBaseRenderer.NonDelegatingQueryInterface(const IID: TGUID;
  out Obj): HResult;
begin
// Milenko start (removed unnessacery code)
  // Do we have this interface
  if IsEqualGUID(IID, IID_IMediaPosition) or IsEqualGUID(IID, IID_IMediaSeeking)
    then Result := GetMediaPositionInterface(IID,Obj)
    else Result := inherited NonDelegatingQueryInterface(IID, Obj);
// Milenko end
end;

// This is called whenever we change states, we have a manual reset event that
// is signalled whenever we don't won't the source filter thread to wait in us
// (such as in a stopped state) and likewise is not signalled whenever it can
// wait (during paused and running) this function sets or resets the thread
// event. The event is used to stop source filter threads waiting in Receive

function TBCBaseRenderer.SourceThreadCanWait(CanWait: Boolean): HResult;
begin
  if CanWait then
    FThreadSignal.Reset
  else
    FThreadSignal.SetEv;
  Result := NOERROR;
end;

{$IFDEF _DEBUG}
// Dump the current renderer state to the debug terminal. The hardest part of
// the renderer is the window where we unlock everything to wait for a clock
// to signal it is time to draw or for the application to cancel everything
// by stopping the filter. If we get things wrong we can leave the thread in
// WaitForRenderTime with no way for it to ever get out and we will deadlock

procedure TBCBaseRenderer.DisplayRendererState;
var
  bSignalled, bFlushing: Boolean;
  CurrentTime, StartTime, EndTime, Offset, Wait: TReferenceTime;

  function RT_in_Millisecs(rt: TReferenceTime): Int64;
  begin
    Result := rt div 10000;
  end;

begin
  DbgLog(Self, 'Timed out in WaitForRenderTime');

  // No way should this be signalled at this point

  bSignalled := FThreadSignal.Check;

  DbgLog(Self, Format('Signal sanity check %d', [Byte(bSignalled)]));

  // Now output the current renderer state variables

  DbgLog(Self, Format('Filter state %d', [Ord(FState)]));

  DbgLog(Self, Format('Abort flag %d', [Byte(FAbort)]));

  DbgLog(Self, Format('Streaming flag %d', [Byte(FIsStreaming)]));

  DbgLog(Self, Format('Clock advise link %d', [FAdvisedCookie]));

//  DbgLog(Self, Format('Current media sample %x', [FMediaSample]));

  DbgLog(Self, Format('EOS signalled %d', [Byte(FIsEOS)]));

  DbgLog(Self, Format('EOS delivered %d', [Byte(FIsEOSDelivered)]));

  DbgLog(Self, Format('Repaint status %d', [Byte(FRepaintStatus)]));

  // Output the delayed end of stream timer information

  DbgLog(Self, Format('End of stream timer %x', [FEndOfStreamTimer]));

  // ??? convert reftime to str
  //    DbgLog((LOG_TIMING, 1, TEXT("Deliver time %s"),CDisp((LONGLONG)FSignalTime)));
  DbgLog(Self, Format('Deliver time %d', [FSignalTime]));

  // Should never timeout during a flushing state

  bFlushing := FInputPin.IsFlushing;

  DbgLog(Self, Format('Flushing sanity check %d', [Byte(bFlushing)]));

  // Display the time we were told to start at
// ???  DbgLog((LOG_TIMING, 1, TEXT("Last run time %s"),CDisp((LONGLONG)m_tStart.m_time)));
  DbgLog(Self, Format('Last run time %d', [FStart]));

  // Have we got a reference clock
  if (FClock = nil) then
    Exit;

  // Get the current time from the wall clock

  FClock.GetTime(int64(CurrentTime));
  Offset := CurrentTime - FStart;

  // Display the current time from the clock

  DbgLog(Self, Format('Clock time %d', [CurrentTime]));

  DbgLog(Self, Format('Time difference %d ms', [RT_in_Millisecs(Offset)]));

  // Do we have a sample ready to render
  if (FMediaSample = nil) then
    Exit;

  FMediaSample.GetTime(StartTime, EndTime);
  DbgLog(Self, Format('Next sample stream times (Start %d End %d ms)',
    [RT_in_Millisecs(StartTime), RT_in_Millisecs(EndTime)]));
  // Calculate how long it is until it is due for rendering
  Wait := (FStart + StartTime) - CurrentTime;
  DbgLog(Self, Format('Wait required %d ms', [RT_in_Millisecs(Wait)]));
end;
{$ENDIF}

// Wait until the clock sets the timer event or we're otherwise signalled. We
// set an arbitrary timeout for this wait and if it fires then we display the
// current renderer state on the debugger. It will often fire if the filter's
// left paused in an application however it may also fire during stress tests
// if the synchronisation with application seeks and state changes is faulty

const
  RENDER_TIMEOUT = 10000;

function TBCBaseRenderer.WaitForRenderTime: HResult;
var
  WaitObjects: array[0..1] of THandle;

begin
  WaitObjects[0] := FThreadSignal.Handle;
  WaitObjects[1] := FRenderEvent.Handle;

  DWord(Result) := WAIT_TIMEOUT;

  // Wait for either the time to arrive or for us to be stopped

  OnWaitStart;
  while (Result = WAIT_TIMEOUT) do
  begin
    Result := WaitForMultipleObjects(2, @WaitObjects, False, RENDER_TIMEOUT);

{$IFDEF _DEBUG}
  if (Result = WAIT_TIMEOUT) then
    DisplayRendererState;
{$ENDIF}
  end;
  OnWaitEnd;

  // We may have been awoken without the timer firing

  if (Result = WAIT_OBJECT_0) then
  begin
    Result := VFW_E_STATE_CHANGED;
    Exit;
  end;

  SignalTimerFired;
  Result := NOERROR;
end;

// Poll waiting for Receive to complete.  This really matters when
// Receive may set the palette and cause window messages
// The problem is that if we don't really wait for a renderer to
// stop processing we can deadlock waiting for a transform which
// is calling the renderer's Receive() method because the transform's
// Stop method doesn't know to process window messages to unblock
// the renderer's Receive processing

procedure TBCBaseRenderer.WaitForReceiveToComplete;
var
  msg: TMsg;
begin
  repeat
    if Not FInReceive then
      Break;

    //  Receive all interthread sendmessages
    PeekMessage(msg, 0, WM_NULL, WM_NULL, PM_NOREMOVE);

    Sleep(1);
  until False;

  // If the wakebit for QS_POSTMESSAGE is set, the PeekMessage call
  // above just cleared the changebit which will cause some messaging
  // calls to block (waitMessage, MsgWaitFor...) now.
  // Post a dummy message to set the QS_POSTMESSAGE bit again
  
  if (HIWORD(GetQueueStatus(QS_POSTMESSAGE)) and QS_POSTMESSAGE) <> 0 then
    //  Send dummy message
    PostThreadMessage(GetCurrentThreadId, WM_NULL, 0, 0);
end;

// A filter can have four discrete states, namely Stopped, Running, Paused,
// Intermediate. We are in an intermediate state if we are currently trying
// to pause but haven't yet got the first sample (or if we have been flushed
// in paused state and therefore still have to wait for a sample to arrive)

// This class contains an event called FCompleteEvent which is signalled when
// the current state is completed and is not signalled when we are waiting to
// complete the last state transition. As mentioned above the only time we
// use this at the moment is when we wait for a media sample in paused state
// If while we are waiting we receive an end of stream notification from the
// source filter then we know no data is imminent so we can reset the event
// This means that when we transition to paused the source filter must call
// end of stream on us or send us an image otherwise we'll hang indefinately

// Simple internal way of getting the real state

// !!! make property here

function TBCBaseRenderer.GetRealState: TFilterState;
begin
  Result := FState;
end;

// Waits for the HANDLE hObject.  While waiting messages sent
// to windows on our thread by SendMessage will be processed.
// Using this function to do waits and mutual exclusion
// avoids some deadlocks in objects with windows.
// Return codes are the same as for WaitForSingleObject

function WaitDispatchingMessages(Object_: THandle; Wait: DWord;
  Wnd: HWnd = 0; Msg: Cardinal = 0; Event: THandle = 0): DWord;
// milenko start (replaced with global variables)
//const
//{$IFOPT J-}
//{$DEFINE ResetJ}
//{$J+}
//{$ENDIF}
//  MsgId: Cardinal = 0;
//{$IFDEF ResetJ}
//{$J-}
//{$UNDEF ResetJ}
//{$ENDIF}
// milenko end
var
  Peeked: Boolean;
  Res, Start, ThreadPriority: DWord;
  Objects: array[0..1] of THandle;
  Count, TimeOut, WakeMask, Now_, Diff: DWord;
  Msg_: TMsg;

begin
  Peeked := False;
  MsgId := 0;
  Start := 0;
  ThreadPriority := THREAD_PRIORITY_NORMAL;

  Objects[0] := Object_;
  Objects[1] := Event;
  if (Wait <> INFINITE) and (Wait <> 0) then
    Start := GetTickCount;

  repeat
    if (Event <> 0) then
      Count := 2
    else
      Count := 1;

    //  Minimize the chance of actually dispatching any messages
    //  by seeing if we can lock immediately.
    Res := WaitForMultipleObjects(Count, @Objects, False, 0);
    if (Res < WAIT_OBJECT_0 + Count) then
      Break;

    TimeOut := Wait;
    if (TimeOut > 10) then
      TimeOut := 10;

    if (Wnd = 0) then
      WakeMask := QS_SENDMESSAGE
    else
      WakeMask := QS_SENDMESSAGE + QS_POSTMESSAGE;

    Res := MsgWaitForMultipleObjects(Count, Objects, False,
      TimeOut, WakeMask);
    if (Res = WAIT_OBJECT_0 + Count) or
      ((Res = WAIT_TIMEOUT) and (TimeOut <> Wait)) then
    begin
      if (Wnd <> 0) then
        while PeekMessage(Msg_, Wnd, Msg, Msg, PM_REMOVE) do
          DispatchMessage(Msg_);

      // Do this anyway - the previous peek doesn't flush out the
      // messages
      PeekMessage(Msg_, 0, 0, 0, PM_NOREMOVE);

      if (Wait <> INFINITE) and (Wait <> 0) then
      begin
        Now_ := GetTickCount();

        // Working with differences handles wrap-around
        Diff := Now_ - Start;
        if (Diff > Wait) then
          Wait := 0
        else
          Dec(Wait, Diff);
        Start := Now_;
      end;

      if not (Peeked) then
      begin
        //  Raise our priority to prevent our message queue
        //  building up
        ThreadPriority := GetThreadPriority(GetCurrentThread);
        if (ThreadPriority < THREAD_PRIORITY_HIGHEST) then
        begin
          // ??? raising priority requires one more routine....
          SetThreadPriority(GetCurrentThread, THREAD_PRIORITY_HIGHEST);
        end;
        Peeked := True;
      end;
    end
    else
      Break;
  until False;

  if (Peeked) then
  begin
    // ??? setting priority requires one more routine....
    SetThreadPriority(GetCurrentThread, ThreadPriority);
// milenko start (important!)
//    if (HIWORD(GetQueueStatus(QS_POSTMESSAGE)) and QS_POSTMESSAGE) = 0 then
    if (HIWORD(GetQueueStatus(QS_POSTMESSAGE)) and QS_POSTMESSAGE) > 0 then
// milenko end
    begin
      if (MsgId = 0) then
        MsgId := RegisterWindowMessage('AMUnblock')
      else
        //  Remove old ones
        while (PeekMessage(Msg_, (Wnd) - 1, MsgId, MsgId, PM_REMOVE)) do
// milenko start (this is a loop without any further function.
//                it does not call PostThreadMEssage while looping!)
        begin
        end;
// milenko end
      PostThreadMessage(GetCurrentThreadId, MsgId, 0, 0);
    end;
  end;

  Result := Res;
end;

// The renderer doesn't complete the full transition to paused states until
// it has got one media sample to render. If you ask it for its state while
// it's waiting it will return the state along with VFW_S_STATE_INTERMEDIATE

function TBCBaseRenderer.GetState(MSecs: DWord; out State: TFilterState):
  HResult;
begin
  if (WaitDispatchingMessages(FCompleteEvent.Handle, MSecs) = WAIT_TIMEOUT) then
    Result := VFW_S_STATE_INTERMEDIATE
  else
    Result := NOERROR;

  State := FState;
end;

// If we're pausing and we have no samples we don't complete the transition
// to State_Paused and we return S_FALSE. However if the FAborting flag has
// been set then all samples are rejected so there is no point waiting for
// one. If we do have a sample then return NOERROR. We will only ever return
// VFW_S_STATE_INTERMEDIATE from GetState after being paused with no sample
// (calling GetState after either being stopped or Run will NOT return this)

function TBCBaseRenderer.CompleteStateChange(OldState: TFilterState): HResult;
begin
  // Allow us to be paused when disconnected
  if not (FInputPin.IsConnected) or
    // Have we run off the end of stream
  IsEndOfStream or
    // Make sure we get fresh data after being stopped
  (HaveCurrentSample and (OldState <> State_Stopped)) then
  begin
    Ready;
    Result := S_OK;
    Exit;
  end;

  NotReady;
  Result := S_False;
end;

procedure TBCBaseRenderer.SetAbortSignal(Abort_: Boolean);
begin
  FAbort := Abort_;
end;

procedure TBCBaseRenderer.OnReceiveFirstSample(MediaSample: IMediaSample);
begin

end;

procedure TBCBaseRenderer.Ready;
begin
  FCompleteEvent.SetEv
end;

procedure TBCBaseRenderer.NotReady;
begin
  FCompleteEvent.Reset
end;

function TBCBaseRenderer.CheckReady: Boolean;
begin
  Result := FCompleteEvent.Check
end;

// When we stop the filter the things we do are:-

//      Decommit the allocator being used in the connection
//      Release the source filter if it's waiting in Receive
//      Cancel any advise link we set up with the clock
//      Any end of stream signalled is now obsolete so reset
//      Allow us to be stopped when we are not connected

function TBCBaseRenderer.Stop: HResult;
begin
  FInterfaceLock.Lock;
  try
    // Make sure there really is a state change

    if (FState = State_Stopped) then
    begin
      Result := NOERROR;
      Exit;
    end;

    // Is our input pin connected

    if not (FInputPin.IsConnected) then
    begin
{$IFDEF _DEBUG}
      DbgLog(Self, 'Input pin is not connected');
{$ENDIF}
      FState := State_Stopped;
      Result := NOERROR;
      Exit;
    end;

    inherited Stop;

    // If we are going into a stopped state then we must decommit whatever
    // allocator we are using it so that any source filter waiting in the
    // GetBuffer can be released and unlock themselves for a state change

    if Assigned(FInputPin.FAllocator) then
      FInputPin.FAllocator.Decommit;

    // Cancel any scheduled rendering

    SetRepaintStatus(True);
    StopStreaming;
    SourceThreadCanWait(False);
    ResetEndOfStream;
    CancelNotification;

    // There should be no outstanding clock advise
    Assert(CancelNotification = S_FALSE);
  {$IFOPT C+}
    Assert(WAIT_TIMEOUT = WaitForSingleObject(FRenderEvent.Handle, 0));
  {$ELSE}
    WaitForSingleObject(FRenderEvent.Handle, 0);
  {$ENDIF}
    Assert(FEndOfStreamTimer = 0);

    Ready;
    WaitForReceiveToComplete;
    FAbort := False;

    Result := NOERROR;

  finally
    FInterfaceLock.UnLock;
  end;
end;

// When we pause the filter the things we do are:-

//      Commit the allocator being used in the connection
//      Allow a source filter thread to wait in Receive
//      Cancel any clock advise link (we may be running)
//      Possibly complete the state change if we have data
//      Allow us to be paused when we are not connected

function TBCBaseRenderer.Pause: HResult;
var
  OldState: TFilterState;
  hr: HResult;
begin
  FInterfaceLock.Lock;
  try
    OldState := FState;
    Assert(not FInputPin.IsFlushing);

    // Make sure there really is a state change

    if (FState = State_Paused) then
    begin
      Result := CompleteStateChange(State_Paused);
      Exit;
    end;

    // Has our input pin been connected

    if Not FInputPin.IsConnected then
    begin
{$IFDEF _DEBUG}
      DbgLog(Self, 'Input pin is not connected');
{$ENDIF}
      FState := State_Paused;
      Result := CompleteStateChange(State_Paused);
      Exit;
    end;

    // Pause the base filter class

    hr := inherited Pause;
    if Failed(hr) then
    begin
{$IFDEF _DEBUG}
      DbgLog(Self, 'Pause failed');
{$ENDIF}
      Result := hr;
      Exit;
    end;

    // Enable EC_REPAINT events again

    SetRepaintStatus(True);
    StopStreaming;
    SourceThreadCanWait(True);
    CancelNotification;
    ResetEndOfStreamTimer;
    // If we are going into a paused state then we must commit whatever
    // allocator we are using it so that any source filter can call the
    // GetBuffer and expect to get a buffer without returning an error

    if Assigned(FInputPin.FAllocator) then
      FInputPin.FAllocator.Commit;

    // There should be no outstanding advise
    Assert(CancelNotification = S_FALSE);
  {$IFOPT C+}
    Assert(WAIT_TIMEOUT = WaitForSingleObject(FRenderEvent.Handle, 0));
  {$ELSE}
    WaitForSingleObject(FRenderEvent.Handle, 0);
  {$ENDIF}
    Assert(FEndOfStreamTimer = 0);
    Assert(not FInputPin.IsFlushing);

    // When we come out of a stopped state we must clear any image we were
    // holding onto for frame refreshing. Since renderers see state changes
    // first we can reset ourselves ready to accept the source thread data
    // Paused or running after being stopped causes the current position to
    // be reset so we're not interested in passing end of stream signals

    if (OldState = State_Stopped) then
    begin
      FAbort := False;
      ClearPendingSample;
    end;

    Result := CompleteStateChange(OldState);

  finally
    FInterfaceLock.Unlock;
  end;
end;

// When we run the filter the things we do are:-

//      Commit the allocator being used in the connection
//      Allow a source filter thread to wait in Receive
//      Signal the render event just to get us going
//      Start the base class by calling StartStreaming
//      Allow us to be run when we are not connected
//      Signal EC_COMPLETE if we are not connected

function TBCBaseRenderer.Run(StartTime: TReferenceTime): HResult;
var
  OldState: TFilterState;
  hr: HResult;
// milenko start
  Filter: IBaseFilter;
// milenko end
begin
  FInterfaceLock.Lock;
  try
    OldState := FState;

    // Make sure there really is a state change

    if (FState = State_Running) then
    begin
      Result := NOERROR;
      Exit;
    end;

    // Send EC_COMPLETE if we're not connected

    if not FInputPin.IsConnected then
    begin
// milenko start (Delphi 5 compatibility)
      QueryInterface(IID_IBaseFilter,Filter);
      NotifyEvent(EC_COMPLETE, S_OK, Integer(Filter));
      Filter := nil;
// milenko end      
      FState := State_Running;
      Result := NOERROR;
      Exit;
    end;

    Ready;

    // Pause the base filter class

    hr := inherited Run(StartTime);
    if Failed(hr) then
    begin
{$IFDEF _DEBUG}
      DbgLog(Self, 'Run failed');
{$ENDIF}
      Result := hr;
      Exit;
    end;

    // Allow the source thread to wait
    Assert(not FInputPin.IsFlushing);
    SourceThreadCanWait(True);
    SetRepaintStatus(False);

    // There should be no outstanding advise
    Assert(CancelNotification = S_FALSE);
  {$IFOPT C+}
    Assert(WAIT_TIMEOUT = WaitForSingleObject(FRenderEvent.Handle, 0));
  {$ELSE}
    WaitForSingleObject(FRenderEvent.Handle, 0);
  {$ENDIF}
    Assert(FEndOfStreamTimer = 0);
    Assert(not FInputPin.IsFlushing);

    // If we are going into a running state then we must commit whatever
    // allocator we are using it so that any source filter can call the
    // GetBuffer and expect to get a buffer without returning an error

    if Assigned(FInputPin.FAllocator) then
      FInputPin.FAllocator.Commit;

    // When we come out of a stopped state we must clear any image we were
    // holding onto for frame refreshing. Since renderers see state changes
    // first we can reset ourselves ready to accept the source thread data
    // Paused or running after being stopped causes the current position to
    // be reset so we're not interested in passing end of stream signals

    if (OldState = State_Stopped) then
    begin
      FAbort := False;
      ClearPendingSample;
    end;

    Result := StartStreaming;

  finally
    FInterfaceLock.Unlock;
  end;
end;

// Return the number of input pins we support

function TBCBaseRenderer.GetPinCount: Integer;
begin
  Result := 1;
end;

// We only support one input pin and it is numbered zero

function TBCBaseRenderer.GetPin(n: integer): TBCBasePin;
var
  hr: HResult;
begin
  FObjectCreationLock.Lock;
  try
    // Should only ever be called with zero
    Assert(n = 0);

    if (n <> 0) then
    begin
      Result := nil;
      Exit;
    end;

    // Create the input pin if not already done so

    if (FInputPin = nil) then
    begin
      // hr must be initialized to NOERROR because
      // CRendererInputPin's constructor only changes
      // hr's value if an error occurs.
      hr := NOERROR;

      FInputPin := TBCRendererInputPin.Create(Self, hr, 'In');
      if (FInputPin = nil) then
      begin
        Result := nil;
        Exit;
      end;

      if Failed(hr) then
      begin
        FreeAndNil(FInputPin);
        Result := nil;
        Exit;
      end;
    end;

    Result := FInputPin;
  finally
    FObjectCreationLock.UnLock;
  end;
end;

function DumbItDownFor95(const S1, S2: WideString; CmpFlags: Integer): Integer;
var
  a1, a2: string;
begin
  a1 := s1;
  a2 := s2;
  Result := CompareString(LOCALE_USER_DEFAULT, CmpFlags, PChar(a1), Length(a1),
    PChar(a2), Length(a2)) - 2;
end;

function WideCompareText(const S1, S2: WideString): Integer;
begin
  SetLastError(0);
  Result := CompareStringW(LOCALE_USER_DEFAULT, NORM_IGNORECASE, PWideChar(S1),
    Length(S1), PWideChar(S2), Length(S2)) - 2;
  case GetLastError of
    0: ;
    ERROR_CALL_NOT_IMPLEMENTED: Result := DumbItDownFor95(S1, S2, NORM_IGNORECASE);
  end;
end;

// If "In" then return the IPin for our input pin, otherwise NULL and error
function TBCBaseRenderer.FindPin(id: PWideChar; out Pin: IPin): HResult;
begin
// Milenko start
  if (@Pin = nil) then
  begin
    Result := E_POINTER;
    Exit;
  end;
// Milenko end
// milenko start (delphi 5 doesn't know WideCompareText)
  if WideCompareText(id, 'In') = 0 then
// milenko end
  begin
    Pin := GetPin(0);
    Assert(Pin <> nil);
    // ??? Pin.AddRef;
    Result := NOERROR;
  end
  else
  begin
    Pin := nil;
    Result := VFW_E_NOT_FOUND;
  end;
end;

// Called when the input pin receives an EndOfStream notification. If we have
// not got a sample, then notify EC_COMPLETE now. If we have samples, then set
// m_bEOS and check for this on completing samples. If we're waiting to pause
// then complete the transition to paused state by setting the state event

function TBCBaseRenderer.EndOfStream: HResult;
begin
  // Ignore these calls if we are stopped

  if (FState = State_Stopped) then
  begin
    Result := NOERROR;
    Exit;
  end;

  // If we have a sample then wait for it to be rendered

  FIsEOS := True;
  if Assigned(FMediaSample) then
  begin
    Result := NOERROR;
    Exit;
  end;

  // If we are waiting for pause then we are now ready since we cannot now
  // carry on waiting for a sample to arrive since we are being told there
  // won't be any. This sets an event that the GetState function picks up

  Ready;

  // Only signal completion now if we are running otherwise queue it until
  // we do run in StartStreaming. This is used when we seek because a seek
  // causes a pause where early notification of completion is misleading

  if FIsStreaming then
    SendEndOfStream;

  Result := NOERROR;
end;

// When we are told to flush we should release the source thread

function TBCBaseRenderer.BeginFlush: HResult;
begin
  // If paused then report state intermediate until we get some data

  if (FState = State_Paused) then
    NotReady;

  SourceThreadCanWait(False);
  CancelNotification;
  ClearPendingSample;
  //  Wait for Receive to complete
  WaitForReceiveToComplete;

  Result := NOERROR;
end;

// After flushing the source thread can wait in Receive again

function TBCBaseRenderer.EndFlush: HResult;
begin
  // Reset the current sample media time
  if Assigned(FPosition) then
    FPosition.ResetMediaTime;

  // There should be no outstanding advise

  Assert(CancelNotification = S_FALSE);
  SourceThreadCanWait(True);
  Result := NOERROR;
end;

// We can now send EC_REPAINTs if so required

function TBCBaseRenderer.CompleteConnect(ReceivePin: IPin): HResult;
begin
  // The caller should always hold the interface lock because
  // the function uses CBaseFilter::m_State.

  {$IFDEF _DEBUG}
  Assert(FInterfaceLock.CritCheckIn);
  {$ENDIF}

  FAbort := False;

  if (State_Running = GetRealState) then
  begin
    Result := StartStreaming;
    if Failed(Result) then
      Exit;

    SetRepaintStatus(False);
  end
  else
    SetRepaintStatus(True);

  Result := NOERROR;
end;

// Called when we go paused or running

function TBCBaseRenderer.Active: HResult;
begin
  Result := NOERROR;
end;

// Called when we go into a stopped state

function TBCBaseRenderer.Inactive: HResult;
begin
  if Assigned(FPosition) then
    FPosition.ResetMediaTime;

  //  People who derive from this may want to override this behaviour
  //  to keep hold of the sample in some circumstances
  ClearPendingSample;

  Result := NOERROR;
end;

// Tell derived classes about the media type agreed

function TBCBaseRenderer.SetMediaType(MediaType: PAMMediaType): HResult;
begin
  Result := NOERROR;
end;

// When we break the input pin connection we should reset the EOS flags. When
// we are asked for either IMediaPosition or IMediaSeeking we will create a
// CPosPassThru object to handles media time pass through. When we're handed
// samples we store (by calling CPosPassThru::RegisterMediaTime) their media
// times so we can then return a real current position of data being rendered

function TBCBaseRenderer.BreakConnect: HResult;
begin
  // Do we have a quality management sink

  if Assigned(FQSink) then
    FQSink := nil;

  // Check we have a valid connection

  if not FInputPin.IsConnected then
  begin
    Result := S_FALSE;
    Exit;
  end;

  // Check we are stopped before disconnecting
  if (FState <> State_Stopped) and (not FInputPin.CanReconnectWhenActive) then
  begin
    Result := VFW_E_NOT_STOPPED;
    Exit;
  end;

  SetRepaintStatus(False);
  ResetEndOfStream;
  ClearPendingSample;
  FAbort := False;

  if (State_Running = FState) then
    StopStreaming;

  Result := NOERROR;
end;

// Retrieves the sample times for this samples (note the sample times are
// passed in by reference not value). We return S_FALSE to say schedule this
// sample according to the times on the sample. We also return S_OK in
// which case the object should simply render the sample data immediately

function TBCBaseRenderer.GetSampleTimes(MediaSample: IMediaSample;
  out StartTime: TReferenceTime; out EndTime: TReferenceTime): HResult;
begin
  Assert(FAdvisedCookie = 0);
  Assert(Assigned(MediaSample));

  // If the stop time for this sample is before or the same as start time,
  // then just ignore it (release it) and schedule the next one in line
  // Source filters should always fill in the start and end times properly!

  if Succeeded(MediaSample.GetTime(StartTime, EndTime)) then
  begin
    if (EndTime < StartTime) then
    begin
      Result := VFW_E_START_TIME_AFTER_END;
      Exit;
    end;
  end
  else
  begin
    // no time set in the sample... draw it now?
    Result := S_OK;
    Exit;
  end;

  // Can't synchronise without a clock so we return S_OK which tells the
  // caller that the sample should be rendered immediately without going
  // through the overhead of setting a timer advise link with the clock

  if (FClock = nil) then
    Result := S_OK
  else
    Result := ShouldDrawSampleNow(MediaSample, StartTime, EndTime);
end;

// By default all samples are drawn according to their time stamps so we
// return S_FALSE. Returning S_OK means draw immediately, this is used
// by the derived video renderer class in its quality management.

function TBCBaseRenderer.ShouldDrawSampleNow(MediaSample: IMediaSample;
  StartTime: TReferenceTime; out EndTime: TReferenceTime): HResult;
begin
  Result := S_FALSE;
end;

// We must always reset the current advise time to zero after a timer fires
// because there are several possible ways which lead us not to do any more
// scheduling such as the pending image being cleared after state changes

procedure TBCBaseRenderer.SignalTimerFired;
begin
  FAdvisedCookie := 0;
end;

// Cancel any notification currently scheduled. This is called by the owning
// window object when it is told to stop streaming. If there is no timer link
// outstanding then calling this is benign otherwise we go ahead and cancel
// We must always reset the render event as the quality management code can
// signal immediate rendering by setting the event without setting an advise
// link. If we're subsequently stopped and run the first attempt to setup an
// advise link with the reference clock will find the event still signalled

function TBCBaseRenderer.CancelNotification: HResult;
var
  dwAdvisedCookie: DWord;

begin
  Assert((FAdvisedCookie = 0) or Assigned(FClock));
  dwAdvisedCookie := FAdvisedCookie;

  // Have we a live advise link

  if (FAdvisedCookie <> 0) then
  begin
    FClock.Unadvise(FAdvisedCookie);
    SignalTimerFired;
    Assert(FAdvisedCookie = 0);
  end;

  // Clear the event and return our status

  FRenderEvent.Reset;
  if (dwAdvisedCookie <> 0) then
    Result := S_OK
  else
    Result := S_FALSE;
end;

// Responsible for setting up one shot advise links with the clock
// Return FALSE if the sample is to be dropped (not drawn at all)
// Return TRUE if the sample is to be drawn and in this case also
// arrange for m_RenderEvent to be set at the appropriate time

function TBCBaseRenderer.ScheduleSample(MediaSample: IMediaSample): Boolean;
var
  StartSample, EndSample: TReferenceTime;
  hr: HResult;
begin
  // Is someone pulling our leg

  if (MediaSample = nil) then
  begin
    Result := False;
    Exit;
  end;

  // Get the next sample due up for rendering.  If there aren't any ready
  // then GetNextSampleTimes returns an error.  If there is one to be done
  // then it succeeds and yields the sample times. If it is due now then
  // it returns S_OK other if it's to be done when due it returns S_FALSE

  hr := GetSampleTimes(MediaSample, StartSample, EndSample);
  if Failed(hr) then
  begin
    Result := False;
    Exit;
  end;

  // If we don't have a reference clock then we cannot set up the advise
  // time so we simply set the event indicating an image to render. This
  // will cause us to run flat out without any timing or synchronisation

  if (hr = S_OK) then
  begin
  {$IFOPT C+}
    ASSERT(SetEvent(FRenderEvent.Handle));
  {$ELSE}
    SetEvent(FRenderEvent.Handle);
  {$ENDIF}
    Result := True;
    Exit;
  end;

  Assert(FAdvisedCookie = 0);
  Assert(Assigned(FClock));
{$IFOPT C+}
  Assert(Wait_Timeout = WaitForSingleObject(FRenderEvent.Handle, 0));
{$ELSE}
  WaitForSingleObject(FRenderEvent.Handle, 0);
{$ENDIF}

  // We do have a valid reference clock interface so we can ask it to
  // set an event when the image comes due for rendering. We pass in
  // the reference time we were told to start at and also the current
  // stream time which is the offset from the start reference time

  hr := FClock.AdviseTime(
    FStart,               // Start run time
    StartSample,          // Stream time
    FRenderEvent.Handle,  // Render notification
    FAdvisedCookie);      // Advise cookie

  if Succeeded(hr) then
  begin
    Result := True;
    Exit;
  end;

  // We could not schedule the next sample for rendering despite the fact
  // we have a valid sample here. This is a fair indication that either
  // the system clock is wrong or the time stamp for the sample is duff

  Assert(FAdvisedCookie = 0);
  Result := False;
end;

// This is called when a sample comes due for rendering. We pass the sample
// on to the derived class. After rendering we will initialise the timer for
// the next sample, NOTE signal that the last one fired first, if we don't
// do this it thinks there is still one outstanding that hasn't completed

function TBCBaseRenderer.Render(MediaSample: IMediaSample): HResult;
begin
  // If the media sample is NULL then we will have been notified by the
  // clock that another sample is ready but in the mean time someone has
  // stopped us streaming which causes the next sample to be released

  if (MediaSample = nil) then
  begin
    Result := S_FALSE;
    Exit;
  end;

  // If we have stopped streaming then don't render any more samples, the
  // thread that got in and locked us and then reset this flag does not
  // clear the pending sample as we can use it to refresh any output device

  if Not FIsStreaming then
  begin
    Result := S_FALSE;
    Exit;
  end;

  // Time how long the rendering takes

  OnRenderStart(MediaSample);
  DoRenderSample(MediaSample);
  OnRenderEnd(MediaSample);

  Result := NOERROR;
end;

// Checks if there is a sample waiting at the renderer

function TBCBaseRenderer.HaveCurrentSample: Boolean;
begin
  FRendererLock.Lock;
  try
    Result := (FMediaSample <> nil);

  finally
    FRendererLock.UnLock;
  end;
end;

// Returns the current sample waiting at the video renderer. We AddRef the
// sample before returning so that should it come due for rendering the
// person who called this method will hold the remaining reference count
// that will stop the sample being added back onto the allocator free list

function TBCBaseRenderer.GetCurrentSample: IMediaSample;
begin
  FRendererLock.Lock;
  try
    (* ???
        if (m_pMediaSample) {
            m_pMediaSample->AddRef();
    *)
    Result := FMediaSample;
  finally
    FRendererLock.Unlock;
  end;
end;

// Called when the source delivers us a sample. We go through a few checks to
// make sure the sample can be rendered. If we are running (streaming) then we
// have the sample scheduled with the reference clock, if we are not streaming
// then we have received an sample in paused mode so we can complete any state
// transition. On leaving this function everything will be unlocked so an app
// thread may get in and change our state to stopped (for example) in which
// case it will also signal the thread event so that our wait call is stopped

function TBCBaseRenderer.PrepareReceive(MediaSample: IMediaSample): HResult;
var
  hr: HResult;
begin
  FInterfaceLock.Lock;
  try
    FInReceive := True;

    // Check our flushing and filter state

    // This function must hold the interface lock because it calls
    // CBaseInputPin::Receive() and CBaseInputPin::Receive() uses
    // CBasePin::m_bRunTimeError.
// ???     HRESULT hr = m_pInputPin->CBaseInputPin::Receive(MediaSample);

    hr := FInputPin.InheritedReceive(MediaSample);
    if (hr <> NOERROR) then
    begin
      FInReceive := False;
      Result := E_FAIL;
      Exit;
    end;

    // Has the type changed on a media sample. We do all rendering
    // synchronously on the source thread, which has a side effect
    // that only one buffer is ever outstanding. Therefore when we
    // have Receive called we can go ahead and change the format
    // Since the format change can cause a SendMessage we just don't
    // lock
    if Assigned(FInputPin.SampleProps.pMediaType) then
    begin
      hr := FInputPin.SetMediaType(FInputPin.FSampleProps.pMediaType);
      if Failed(hr) then
      begin
        Result := hr;
        FInReceive := False;
        Exit;
      end;
    end;

    FRendererLock.Lock;
    try
      Assert(IsActive);
      Assert(not FInputPin.IsFlushing);
      Assert(FInputPin.IsConnected);
      Assert(FMediaSample = nil);

      // Return an error if we already have a sample waiting for rendering
      // source pins must serialise the Receive calls - we also check that
      // no data is being sent after the source signalled an end of stream

      if (Assigned(FMediaSample) or FIsEOS or FAbort) then
      begin
        Ready;
        FInReceive := False;
        Result := E_UNEXPECTED;
        Exit;
      end;

      // Store the media times from this sample
      if Assigned(FPosition) then
        FPosition.RegisterMediaTime(MediaSample);

      // Schedule the next sample if we are streaming

      if (FIsStreaming and (not ScheduleSample(MediaSample))) then
      begin
      {$IFOPT C+}
        Assert(WAIT_TIMEOUT = WaitForSingleObject(FRenderEvent.Handle, 0));
      {$ELSE}
        WaitForSingleObject(FRenderEvent.Handle, 0);
      {$ENDIF}
        Assert(CancelNotification = S_FALSE);
        FInReceive := False;
        Result := VFW_E_SAMPLE_REJECTED;
        Exit;
      end;

      // Store the sample end time for EC_COMPLETE handling
      FSignalTime := FInputPin.FSampleProps.tStop;

      // BEWARE we sometimes keep the sample even after returning the thread to
      // the source filter such as when we go into a stopped state (we keep it
      // to refresh the device with) so we must AddRef it to keep it safely. If
      // we start flushing the source thread is released and any sample waiting
      // will be released otherwise GetBuffer may never return (see BeginFlush)

      FMediaSample := MediaSample;
      //???      m_pMediaSample->AddRef();

      if not FIsStreaming then
        SetRepaintStatus(True);

      Result := NOERROR;

    finally
      FRendererLock.Unlock;
    end;

  finally
    FInterfaceLock.UnLock;
  end;
end;

// Called by the source filter when we have a sample to render. Under normal
// circumstances we set an advise link with the clock, wait for the time to
// arrive and then render the data using the PURE virtual DoRenderSample that
// the derived class will have overriden. After rendering the sample we may
// also signal EOS if it was the last one sent before EndOfStream was called

function TBCBaseRenderer.Receive(MediaSample: IMediaSample): HResult;
begin
  Assert(Assigned(MediaSample));

  // It may return VFW_E_SAMPLE_REJECTED code to say don't bother

  Result := PrepareReceive(MediaSample);
  Assert(FInReceive = Succeeded(Result));
  if Failed(Result) then
  begin
    if (Result = VFW_E_SAMPLE_REJECTED) then
      Result := NOERROR;
    Exit;
  end;

  // We realize the palette in "PrepareRender()" so we have to give away the
  // filter lock here.
  if (FState = State_Paused) then
  begin
    PrepareRender;

    // no need to use InterlockedExchange
    FInReceive := False;

    // We must hold both these locks
    FInterfaceLock.Lock;
    try
      if (FState = State_Stopped) then
      begin
        Result := NOERROR;
        Exit;
      end;

      FInReceive := True;
      FRendererLock.Lock;
      try
        OnReceiveFirstSample(MediaSample);
      finally
        FRendererLock.UnLock;
      end;
    finally
      FInterfaceLock.UnLock;
    end;

    Ready;
  end;
  // Having set an advise link with the clock we sit and wait. We may be
  // awoken by the clock firing or by a state change. The rendering call
  // will lock the critical section and check we can still render the data

  Result := WaitForRenderTime;
  if Failed(Result) then
  begin
    FInReceive := False;
    Result := NOERROR;
    Exit;
  end;

  PrepareRender;

  //  Set this here and poll it until we work out the locking correctly
  //  It can't be right that the streaming stuff grabs the interface
  //  lock - after all we want to be able to wait for this stuff
  //  to complete
  FInReceive := False;

  // We must hold both these locks
  FInterfaceLock.Lock;
  try
    // since we gave away the filter wide lock, the sate of the filter could
    // have chnaged to Stopped
    if (FState = State_Stopped) then
    begin
      Result := NOERROR;
      Exit;
    end;
    FRendererLock.Lock;
    try
      // Deal with this sample

      Render(FMediaSample);
      ClearPendingSample;
// milenko start (why commented before?)
      SendEndOfStream;
// milenko end
      CancelNotification;
      Result := NOERROR;

    finally
      FRendererLock.UnLock;
    end;
  finally
    FInterfaceLock.UnLock;
  end;
end;

// This is called when we stop or are inactivated to clear the pending sample
// We release the media sample interface so that they can be allocated to the
// source filter again, unless of course we are changing state to inactive in
// which case GetBuffer will return an error. We must also reset the current
// media sample to NULL so that we know we do not currently have an image

function TBCBaseRenderer.ClearPendingSample: HResult;
begin
  FRendererLock.Lock;
  try
    if Assigned(FMediaSample) then
      FMediaSample := nil;
    Result := NOERROR;
  finally
    FRendererLock.Unlock;
  end;
end;

// Used to signal end of stream according to the sample end time
// Milenko start (use this callback outside of the class and with stdcall;)
procedure EndOfStreamTimer(uID, uMsg: UINT;
  dwUser, dw1, dw2: DWord); stdcall;
var
  Renderer: TBCBaseRenderer;
begin
  Renderer := TBCBaseRenderer(dwUser);
  {$IFDEF _DEBUG}
  //NOTE1("EndOfStreamTimer called (%d)",uID);
  DbgLog(Format('EndOfStreamTimer called (%d)', [uID]));
  {$ENDIF}
  Renderer.TimerCallback;
{
???
    CBaseRenderer *pRenderer = (CBaseRenderer * ) dwUser;
    pRenderer->TimerCallback();
}
end;
// Milenko end

//  Do the timer callback work

procedure TBCBaseRenderer.TimerCallback;
begin
  //  Lock for synchronization (but don't hold this lock when calling
  //  timeKillEvent)
  FRendererLock.Lock;
  try
    // See if we should signal end of stream now

    if (FEndOfStreamTimer <> 0) then
    begin
      FEndOfStreamTimer := 0;
// milenko start (why commented before?)
      SendEndOfStream;
// milenko end      
    end;

  finally
    FRendererLock.Unlock;
  end;
end;

// If we are at the end of the stream signal the filter graph but do not set
// the state flag back to FALSE. Once we drop off the end of the stream we
// leave the flag set (until a subsequent ResetEndOfStream). Each sample we
// get delivered will update m_SignalTime to be the last sample's end time.
// We must wait this long before signalling end of stream to the filtergraph

const
  TIMEOUT_DELIVERYWAIT = 50;
  TIMEOUT_RESOLUTION = 10;

function TBCBaseRenderer.SendEndOfStream: HResult;
var
  Signal, CurrentTime: TReferenceTime;
  Delay: Longint;

begin
  {$IFDEF _DEBUG}
  Assert(FRendererLock.CritCheckIn);
  {$ENDIF}
  if ((not FIsEOS) or FIsEOSDelivered or (FEndOfStreamTimer <> 0)) then
  begin
    Result := NOERROR;
    Exit;
  end;

  // If there is no clock then signal immediately
  if (FClock = nil) then
  begin
    Result := NotifyEndOfStream;
    Exit;
  end;

  // How long into the future is the delivery time

  Signal := FStart + FSignalTime;
  FClock.GetTime(int64(CurrentTime));
// Milenko Start (important!)
//  Delay := (Longint(Signal) - CurrentTime) div 10000;
  Delay := LongInt((Signal - CurrentTime) div 10000);
// Milenko end
  // Dump the timing information to the debugger
{$IFDEF _DEBUG}
  DbgLog(Self, Format('Delay until end of stream delivery %d', [Delay]));
  // ???    NOTE1("Current %s",(LPCTSTR)CDisp((LONGLONG)CurrentTime));
  // ???    NOTE1("Signal %s",(LPCTSTR)CDisp((LONGLONG)Signal));
  DbgLog(Self, Format('Current %d', [CurrentTime]));
  DbgLog(Self, Format('Signal %d', [Signal]));
{$ENDIF}

  // Wait for the delivery time to arrive

  if (Delay < TIMEOUT_DELIVERYWAIT) then
  begin
    Result := NotifyEndOfStream;
    Exit;
  end;

  // Signal a timer callback on another worker thread
  FEndOfStreamTimer := CompatibleTimeSetEvent(
    Delay,                            // Period of timer
    TIMEOUT_RESOLUTION,               // Timer resolution
    // ???
// Milenko start (callback is now outside of the class)
    @EndOfStreamTimer,// Callback function
// Milenko end
    Cardinal(Self),                   // Used information
    TIME_ONESHOT);                    // Type of callback

  if (FEndOfStreamTimer = 0) then
  begin
    Result := NotifyEndOfStream;
    Exit;
  end;

  Result := NOERROR;
end;

// Signals EC_COMPLETE to the filtergraph manager

function TBCBaseRenderer.NotifyEndOfStream: HResult;
var
  Filter: IBaseFilter;
begin
  FRendererLock.Lock;
  try
    Assert(not FIsEOSDelivered);
    Assert(FEndOfStreamTimer = 0);

    // Has the filter changed state

    if not FIsStreaming then
    begin
      Assert(FEndOfStreamTimer = 0);
      Result := NOERROR;
      Exit;
    end;

    // Reset the end of stream timer
    FEndOfStreamTimer := 0;

    // If we've been using the IMediaPosition interface, set it's start
    // and end media "times" to the stop position by hand.  This ensures
    // that we actually get to the end, even if the MPEG guestimate has
    // been bad or if the quality management dropped the last few frames

    if Assigned(FPosition) then
      FPosition.EOS;
    FIsEOSDelivered := True;
{$IFDEF _DEBUG}
    DbgLog('Sending EC_COMPLETE...');
{$ENDIF}
    // ??? return NotifyEvent(EC_COMPLETE,S_OK,(LONG_PTR)(IBaseFilter *)this);
// milenko start (Delphi 5 compatibility)
    QueryInterface(IID_IBaseFilter,Filter);
    Result := NotifyEvent(EC_COMPLETE, S_OK, Integer(Filter));
    Filter := nil;
// milenko end
  finally
    FRendererLock.UnLock;
  end;
end;

// Reset the end of stream flag, this is typically called when we transfer to
// stopped states since that resets the current position back to the start so
// we will receive more samples or another EndOfStream if there aren't any. We
// keep two separate flags one to say we have run off the end of the stream
// (this is the m_bEOS flag) and another to say we have delivered EC_COMPLETE
// to the filter graph. We need the latter otherwise we can end up sending an
// EC_COMPLETE every time the source changes state and calls our EndOfStream

function TBCBaseRenderer.ResetEndOfStream: HResult;
begin
  ResetEndOfStreamTimer;
  FRendererLock.Lock;
  try
    FIsEOS          := False;
    FIsEOSDelivered := False;
    FSignalTime     := 0;

    Result := NOERROR;
  finally
    FRendererLock.UnLock;
  end;
end;

// Kills any outstanding end of stream timer

procedure TBCBaseRenderer.ResetEndOfStreamTimer;
begin
  {$IFDEF _DEBUG}
  Assert(FRendererLock.CritCheckOut);
  {$ENDIF}
  if (FEndOfStreamTimer <> 0) then
  begin
    timeKillEvent(FEndOfStreamTimer);
    FEndOfStreamTimer := 0;
  end;
end;

// This is called when we start running so that we can schedule any pending
// image we have with the clock and display any timing information. If we
// don't have any sample but we have queued an EOS flag then we send it. If
// we do have a sample then we wait until that has been rendered before we
// signal the filter graph otherwise we may change state before it's done

function TBCBaseRenderer.StartStreaming: HResult;
begin
  FRendererLock.Lock;
  try
    if FIsStreaming then
    begin
      Result := NOERROR;
      Exit;
    end;

    // Reset the streaming times ready for running

    FIsStreaming := True;

    timeBeginPeriod(1);
    OnStartStreaming;

    // There should be no outstanding advise
  {$IFOPT C+}
    Assert(WAIT_TIMEOUT = WaitForSingleObject(FRenderEvent.Handle, 0));
  {$ELSE}
    WaitForSingleObject(FRenderEvent.Handle, 0);
  {$ENDIF}
    Assert(CancelNotification = S_FALSE);

    // If we have an EOS and no data then deliver it now

    if (FMediaSample = nil) then
    begin
      Result := SendEndOfStream;
      Exit;
    end;

    // Have the data rendered

    Assert(Assigned(FMediaSample));
    if not ScheduleSample(FMediaSample) then
      FRenderEvent.SetEv;

    Result := NOERROR;

  finally
    FRendererLock.UnLock;
  end;
end;

// This is called when we stop streaming so that we can set our internal flag
// indicating we are not now to schedule any more samples arriving. The state
// change methods in the filter implementation take care of cancelling any
// clock advise link we have set up and clearing any pending sample we have

function TBCBaseRenderer.StopStreaming: HResult;
begin
  FRendererLock.Lock;
  try
    FIsEOSDelivered := False;

    if FIsStreaming then
    begin
      FIsStreaming := False;
      OnStopStreaming;
      timeEndPeriod(1);
    end;
    Result := NOERROR;

  finally
    FRendererLock.Unlock;
  end;
end;

// We have a boolean flag that is reset when we have signalled EC_REPAINT to
// the filter graph. We set this when we receive an image so that should any
// conditions arise again we can send another one. By having a flag we ensure
// we don't flood the filter graph with redundant calls. We do not set the
// event when we receive an EndOfStream call since there is no point in us
// sending further EC_REPAINTs. In particular the AutoShowWindow method and
// the DirectDraw object use this method to control the window repainting

procedure TBCBaseRenderer.SetRepaintStatus(Repaint: Boolean);
begin
  FRendererLock.Lock;
  try
    FRepaintStatus := Repaint;
  finally
    FRendererLock.Unlock;
  end;
end;

// Pass the window handle to the upstream filter

procedure TBCBaseRenderer.SendNotifyWindow(Pin: IPin; Handle: HWND);
var
  Sink: IMediaEventSink;
  hr: HResult;
begin
  // Does the pin support IMediaEventSink
  hr := Pin.QueryInterface(IID_IMediaEventSink, Sink);
  if Succeeded(hr) then
  begin
    Sink.Notify(EC_NOTIFY_WINDOW, Handle, 0);
    Sink := nil;
  end;
  NotifyEvent(EC_NOTIFY_WINDOW, Handle, 0);
end;

// Signal an EC_REPAINT to the filter graph. This can be used to have data
// sent to us. For example when a video window is first displayed it may
// not have an image to display, at which point it signals EC_REPAINT. The
// filtergraph will either pause the graph if stopped or if already paused
// it will call put_CurrentPosition of the current position. Setting the
// current position to itself has the stream flushed and the image resent

// ??? #define RLOG(_x_) DbgLog((LOG_TRACE,1,TEXT(_x_)));

procedure TBCBaseRenderer.SendRepaint;
var
  Pin: IPin;
begin
  FRendererLock.Lock;
  try
    Assert(Assigned(FInputPin));

    // We should not send repaint notifications when...
    //    - An end of stream has been notified
    //    - Our input pin is being flushed
    //    - The input pin is not connected
    //    - We have aborted a video playback
    //    - There is a repaint already sent

    if (not FAbort) and
      (FInputPin.IsConnected) and
      (not FInputPin.IsFlushing) and
      (not IsEndOfStream) and
      FRepaintStatus then
    begin
// milenko start (delphi 5 compatibility)
//      Pin := FInputPin as IPin;
      FInputPin.QueryInterface(IID_IPin,Pin);
      NotifyEvent(EC_REPAINT, Integer(Pin), 0);
      Pin := nil;
// milenko end
      SetRepaintStatus(False);
{$IFDEF _DEBUG}
      DbgLog('Sending repaint');
{$ENDIF}
    end;
  finally
    FRendererLock.Unlock;
  end;
end;

// When a video window detects a display change (WM_DISPLAYCHANGE message) it
// can send an EC_DISPLAY_CHANGED event code along with the renderer pin. The
// filtergraph will stop everyone and reconnect our input pin. As we're then
// reconnected we can accept the media type that matches the new display mode
// since we may no longer be able to draw the current image type efficiently

function TBCBaseRenderer.OnDisplayChange: Boolean;
var
  Pin: IPin;
begin
  // Ignore if we are not connected yet
  FRendererLock.Lock;
  try
    if not FInputPin.IsConnected then
    begin
      Result := False;
      Exit;
    end;
{$IFDEF _DEBUG}
    DbgLog('Notification of EC_DISPLAY_CHANGE');
{$ENDIF}

    // Pass our input pin as parameter on the event
// milenko start (Delphi 5 compatibility)
//  Pin := FInputPin as IPin;
    FInputPin.QueryInterface(IID_IPin,Pin);
    // ??? m_pInputPin->AddRef();
    NotifyEvent(EC_DISPLAY_CHANGED, Integer(Pin), 0);
    SetAbortSignal(True);
    ClearPendingSample;
//    FreeAndNil(FInputPin);
    Pin := nil;
// milenko end

    Result := True;
  finally
    FRendererLock.Unlock;
  end;
end;

// Called just before we start drawing.
// Store the current time in m_trRenderStart to allow the rendering time to be
// logged.  Log the time stamp of the sample and how late it is (neg is early)

procedure TBCBaseRenderer.OnRenderStart(MediaSample: IMediaSample);
{$IFDEF PERF}
var
  StartTime, EndTime, StreamTime: TReferenceTime;
{$ENDIF}
begin
{$IFDEF PERF}
  MediaSample.GetTime(StartTime, EndTime);

  MSR_INTEGER(FBaseStamp, Integer(StartTime)); // dump low order 32 bits

  FClock.GetTime(pint64(@FRenderStart)^);
  MSR_INTEGER(0, Integer(FRenderStart));
  StreamTime := FRenderStart - FStart;      // convert reftime to stream time
  MSR_INTEGER(0, Integer(StreamTime));

  MSR_INTEGER(FBaseAccuracy, RefTimeToMiliSec(StreamTime - StartTime)); // dump in mSec
{$ENDIF}
end;

// Called directly after drawing an image.
// calculate the time spent drawing and log it.

procedure TBCBaseRenderer.OnRenderEnd(MediaSample: IMediaSample);
{$IFDEF PERF}
var
  NowTime: TReferenceTime;
  t: Integer;
{$ENDIF}
begin
{$IFDEF PERF}
  FClock.GetTime(int64(NowTime));
  MSR_INTEGER(0, Integer(NowTime));

  t := RefTimeToMiliSec(NowTime - FRenderStart); // convert UNITS->msec
  MSR_INTEGER(FBaseRenderTime, t);
{$ENDIF}
end;

function TBCBaseRenderer.OnStartStreaming: HResult;
begin
  Result := NOERROR;
end;

function TBCBaseRenderer.OnStopStreaming: HResult;
begin
  Result := NOERROR;
end;

procedure TBCBaseRenderer.OnWaitStart;
begin

end;

procedure TBCBaseRenderer.OnWaitEnd;
begin

end;

procedure TBCBaseRenderer.PrepareRender;
begin

end;

// Constructor must be passed the base renderer object

constructor TBCRendererInputPin.Create(Renderer: TBCBaseRenderer;
  out hr: HResult; Name: PWideChar);
begin
  inherited Create('Renderer pin', Renderer, Renderer.FInterfaceLock,
    hr, Name);
  FRenderer := Renderer;
  Assert(Assigned(FRenderer));
end;

// Signals end of data stream on the input pin

function TBCRendererInputPin.EndOfStream: HResult;
begin
  FRenderer.FInterfaceLock.Lock;
  FRenderer.FRendererLock.Lock;
  try
    // Make sure we're streaming ok

    Result := CheckStreaming;
    if (Result <> NOERROR) then
      Exit;

    // Pass it onto the renderer

    Result := FRenderer.EndOfStream;
    if Succeeded(Result) then
      Result := inherited EndOfStream;

  finally
    FRenderer.FRendererLock.UnLock;
    FRenderer.FInterfaceLock.UnLock;
  end;
end;

// Signals start of flushing on the input pin - we do the final reset end of
// stream with the renderer lock unlocked but with the interface lock locked
// We must do this because we call timeKillEvent, our timer callback method
// has to take the renderer lock to serialise our state. Therefore holding a
// renderer lock when calling timeKillEvent could cause a deadlock condition

function TBCRendererInputPin.BeginFlush: HResult;
begin
  FRenderer.FInterfaceLock.Lock;
  try
    FRenderer.FRendererLock.Lock;
    try
      inherited BeginFlush;
      FRenderer.BeginFlush;
    finally
      FRenderer.FRendererLock.UnLock;
    end;
    Result := FRenderer.ResetEndOfStream;
  finally
    FRenderer.FInterfaceLock.UnLock;
  end;
end;

// Signals end of flushing on the input pin

function TBCRendererInputPin.EndFlush: HResult;
begin
  FRenderer.FInterfaceLock.Lock;
  FRenderer.FRendererLock.Lock;
  try
    Result := FRenderer.EndFlush;
    if Succeeded(Result) then
      Result := inherited EndFlush;
  finally
    FRenderer.FRendererLock.UnLock;
    FRenderer.FInterfaceLock.UnLock;
  end;
end;

// Pass the sample straight through to the renderer object

function TBCRendererInputPin.Receive(MediaSample: IMediaSample): HResult;
var
  hr: HResult;
begin
  hr := FRenderer.Receive(MediaSample);
  if Failed(hr) then
  begin
    // A deadlock could occur if the caller holds the renderer lock and
    // attempts to acquire the interface lock.
    {$IFDEF _DEBUG}
    Assert(FRenderer.FRendererLock.CritCheckOut);
    {$ENDIF}
    // The interface lock must be held when the filter is calling
    // IsStopped or IsFlushing.  The interface lock must also
    // be held because the function uses m_bRunTimeError.
    FRenderer.FInterfaceLock.Lock;
    try
      // We do not report errors which occur while the filter is stopping,
      // flushing or if the FAborting flag is set .  Errors are expected to
      // occur during these operations and the streaming thread correctly
      // handles the errors.
      if (not IsStopped) and (not IsFlushing) and
        (not FRenderer.FAbort) and
        (not FRunTimeError) then
      begin
        // EC_ERRORABORT's first parameter is the error which caused
        // the event and its' last parameter is 0.  See the Direct
        // Show SDK documentation for more information.
        FRenderer.NotifyEvent(EC_ERRORABORT, hr, 0);
        FRenderer.FRendererLock.Lock;
        try
          if (FRenderer.IsStreaming and
            (not FRenderer.IsEndOfStreamDelivered)) then
            FRenderer.NotifyEndOfStream;
        finally
          FRenderer.FRendererLock.UnLock;
        end;
        FRunTimeError := True;
      end;
    finally
      FRenderer.FInterfaceLock.UnLock;
    end;
  end;
  Result := hr;
end;

function TBCRendererInputPin.InheritedReceive(MediaSample: IMediaSample): HResult;
begin
  Result := Inherited Receive(MediaSample);
end;

// Called when the input pin is disconnected

function TBCRendererInputPin.BreakConnect: HResult;
begin
  Result := FRenderer.BreakConnect;
  if Succeeded(Result) then
    Result := inherited BreakConnect;
end;

// Called when the input pin is connected

function TBCRendererInputPin.CompleteConnect(ReceivePin: IPin): HResult;
begin
  Result := FRenderer.CompleteConnect(ReceivePin);
  if Succeeded(Result) then
    Result := inherited CompleteConnect(ReceivePin);
end;

// Give the pin id of our one and only pin

function TBCRendererInputPin.QueryId(out Id: PWideChar): HRESULT;
begin
// milenko start (AMGetWideString bugged before, so this call only will do fine now) 
  Result := AMGetWideString('In', Id);
// milenko end
end;

// Will the filter accept this media type

function TBCRendererInputPin.CheckMediaType(MediaType: PAMMediaType): HResult;
begin
  Result := FRenderer.CheckMediaType(MediaType);
end;

// Called when we go paused or running

function TBCRendererInputPin.Active: HResult;
begin
  Result := FRenderer.Active;
end;

// Called when we go into a stopped state

function TBCRendererInputPin.Inactive: HResult;
begin
  // The caller must hold the interface lock because
  // this function uses FRunTimeError.
  {$IFDEF _DEBUG}
  Assert(FRenderer.FInterfaceLock.CritCheckIn);
  {$ENDIF}

  FRunTimeError := False;
  Result := FRenderer.Inactive;
end;

// Tell derived classes about the media type agreed

function TBCRendererInputPin.SetMediaType(MediaType: PAMMediaType): HResult;
begin
  Result := inherited SetMediaType(MediaType);
  if Succeeded(Result) then
    Result := FRenderer.SetMediaType(MediaType);
end;

// We do not keep an event object to use when setting up a timer link with
// the clock but are given a pointer to one by the owning object through the
// SetNotificationObject method - this must be initialised before starting
// We can override the default quality management process to have it always
// draw late frames, this is currently done by having the following registry
// key (actually an INI key) called DrawLateFrames set to 1 (default is 0)

(* ???
const TCHAR AMQUALITY[] = TEXT("ActiveMovie");
const TCHAR DRAWLATEFRAMES[] = TEXT("DrawLateFrames");
*)
resourcestring
  AMQUALITY       = 'ActiveMovie';
  DRAWLATEFRAMES  = 'DrawLateFrames';

constructor TBCBaseVideoRenderer.Create(RenderClass: TGUID; Name: PChar;
  Unk: IUnknown; hr: HResult);
begin
// milenko start (not sure if this is really needed, but looks better)
//  inherited;
  inherited Create(RenderClass,Name,Unk,hr);
// milenko end

  FFramesDropped          := 0;
  FFramesDrawn            := 0;
  FSupplierHandlingQuality:= False;

  ResetStreamingTimes;

{$IFDEF PERF}
  FTimeStamp      := MSR_REGISTER('Frame time stamp');
  FEarliness      := MSR_REGISTER('Earliness fudge');
  FTarget         := MSR_REGISTER('Target(mSec)');
  FSchLateTime    := MSR_REGISTER('mSec late when scheduled');
  FDecision       := MSR_REGISTER('Scheduler decision code');
  FQualityRate    := MSR_REGISTER('Quality rate sent');
  FQualityTime    := MSR_REGISTER('Quality time sent');
  FWaitReal       := MSR_REGISTER('Render wait');
  FWait           := MSR_REGISTER('wait time recorded (msec)');
  FFrameAccuracy  := MSR_REGISTER('Frame accuracy(msecs)');
  FDrawLateFrames := Boolean(GetProfileInt(PChar(AMQUALITY),
    PChar(DRAWLATEFRAMES), Integer(False)));
  FSendQuality    := MSR_REGISTER('Processing Quality message');
  FRenderAvg      := MSR_REGISTER('Render draw time Avg');
  FFrameAvg       := MSR_REGISTER('FrameAvg');
  FWaitAvg        := MSR_REGISTER('WaitAvg');
  FDuration       := MSR_REGISTER('Duration');
  FThrottle       := MSR_REGISTER('Audio - video throttle wait');
  FDebug          := MSR_REGISTER('Debug stuff');
{$ENDIF}
end;

// Destructor is just a placeholder

destructor TBCBaseVideoRenderer.Destroy;
begin
  Assert(FAdvisedCookie = 0);
  // ??? seems should leave it, but...
// milenko start (not really needed...)
//  inherited;
  inherited Destroy;
// milenko end
end;

// The timing functions in this class are called by the window object and by
// the renderer's allocator.
// The windows object calls timing functions as it receives media sample
// images for drawing using GDI.
// The allocator calls timing functions when it starts passing DCI/DirectDraw
// surfaces which are not rendered in the same way; The decompressor writes
// directly to the surface with no separate rendering, so those code paths
// call direct into us.  Since we only ever hand out DCI/DirectDraw surfaces
// when we have allocated one and only one image we know there cannot be any
// conflict between the two.
//
// We use timeGetTime to return the timing counts we use (since it's relative
// performance we are interested in rather than absolute compared to a clock)
// The window object sets the accuracy of the system clock (normally 1ms) by
// calling timeBeginPeriod/timeEndPeriod when it changes streaming states

// Reset all times controlling streaming.
// Set them so that
// 1. Frames will not initially be dropped
// 2. The first frame will definitely be drawn (achieved by saying that there
//    has not ben a frame drawn for a long time).

function TBCBaseVideoRenderer.ResetStreamingTimes: HResult;
begin
  FLastDraw := -1000; // set up as first frame since ages (1 sec) ago
  FStreamingStart := timeGetTime;
  FRenderAvg := 0;
  FFrameAvg := -1; // -1000 fps :=:= "unset"
  FDuration := 0; // 0 - strange value
  FRenderLast := 0;
  FWaitAvg := 0;
  FRenderStart := 0;
  FFramesDrawn := 0;
  FFramesDropped := 0;
  FTotAcc := 0;
  FSumSqAcc := 0;
  FSumSqFrameTime := 0;
  FFrame := 0; // hygiene - not really needed
  FLate := 0; // hygiene - not really needed
  FSumFrameTime := 0;
  FNormal := 0;
  FEarliness := 0;
  FTarget := -300000; // 30mSec early
  FThrottle := 0;
  FRememberStampForPerf := 0;

{$IFDEF PERF}
  FRememberFrameForPerf := 0;
{$ENDIF}
  Result := NOERROR;
end;

// Reset all times controlling streaming. Note that we're now streaming. We
// don't need to set the rendering event to have the source filter released
// as it is done during the Run processing. When we are run we immediately
// release the source filter thread and draw any image waiting (that image
// may already have been drawn once as a poster frame while we were paused)

function TBCBaseVideoRenderer.OnStartStreaming: HResult;
begin
  ResetStreamingTimes;
  Result := NOERROR;
end;

// Called at end of streaming.  Fixes times for property page report

function TBCBaseVideoRenderer.OnStopStreaming: HResult;
begin
// milenko start (better to use int64 instead of integer)
//  FStreamingStart := Integer(timeGetTime) - FStreamingStart;
  FStreamingStart := Int64(timeGetTime) - FStreamingStart;
// milenko end
  Result := NOERROR;
end;

// Called when we start waiting for a rendering event.
// Used to update times spent waiting and not waiting.

procedure TBCBaseVideoRenderer.OnWaitStart;
begin
{$IFDEF PERF}
  MSR_START(FWaitReal);
{$ENDIF}
end;

// Called when we are awoken from the wait in the window OR by our allocator
// when it is hanging around until the next sample is due for rendering on a
// DCI/DirectDraw surface. We add the wait time into our rolling average.
// We grab the interface lock so that we're serialised with the application
// thread going through the run code - which in due course ends up calling
// ResetStreaming times - possibly as we run through this section of code

procedure TBCBaseVideoRenderer.OnWaitEnd;
{$IFDEF PERF}
var
  RealStream, RefTime: TReferenceTime;
  // the real time now expressed as stream time.
  Late, Frame: Integer;
{$ENDIF}
begin
{$IFDEF PERF}
  MSR_STOP(FWaitReal);
  // for a perf build we want to know just exactly how late we REALLY are.
  // even if this means that we have to look at the clock again.
{$IFDEF 0}
  FClock.GetTime(RealStream); // Calling clock here causes W95 deadlock!
{$ELSE}
  // We will be discarding overflows like mad here!
  // This is wrong really because timeGetTime() can wrap but it's
  // only for PERF
  RefTime := timeGetTime * 10000;
  RealStream := RefTime + FTimeOffset;
{$ENDIF}
  Dec(RealStream, FStart); // convert to stream time (this is a reftime)

  if (FRememberStampForPerf = 0) then
    // This is probably the poster frame at the start, and it is not scheduled
    // in the usual way at all.  Just count it.  The rememberstamp gets set
    // in ShouldDrawSampleNow, so this does invalid frame recording until we
    // actually start playing.
    PreparePerformanceData(0, 0)
  else
  begin
    Late := RealStream - FRememberStampForPerf;
    Frame := RefTime - FRememberFrameForPerf;
    PreparePerformanceData(Late, Frame);
  end;
  FRememberFrameForPerf := RefTime;
{$ENDIF}
end;

// Put data on one side that describes the lateness of the current frame.
// We don't yet know whether it will actually be drawn.  In direct draw mode,
// this decision is up to the filter upstream, and it could change its mind.
// The rules say that if it did draw it must call Receive().  One way or
// another we eventually get into either OnRenderStart or OnDirectRender and
// these both call RecordFrameLateness to update the statistics.

procedure TBCBaseVideoRenderer.PreparePerformanceData(Late, Frame: Integer);
begin
  FLate := Late;
  FFrame := Frame;
end;

// update the statistics:
// m_iTotAcc, m_iSumSqAcc, m_iSumSqFrameTime, m_iSumFrameTime, m_cFramesDrawn
// Note that because the properties page reports using these variables,
// 1. We need to be inside a critical section
// 2. They must all be updated together.  Updating the sums here and the count
// elsewhere can result in imaginary jitter (i.e. attempts to find square roots
// of negative numbers) in the property page code.

procedure TBCBaseVideoRenderer.RecordFrameLateness(Late, Frame: Integer);
var
  _Late, _Frame: Integer;
begin
  // Record how timely we are.
  _Late := Late div 10000;

  // Best estimate of moment of appearing on the screen is average of
  // start and end draw times.  Here we have only the end time.  This may
  // tend to show us as spuriously late by up to 1/2 frame rate achieved.
  // Decoder probably monitors draw time.  We don't bother.
{$IFDEF PERF}
  MSR_INTEGER(FFrameAccuracy, _Late);
{$ENDIF}

  // This is a kludge - we can get frames that are very late
  // especially (at start-up) and they invalidate the statistics.
  // So ignore things that are more than 1 sec off.
  if (_Late > 1000) or (_Late < -1000) then
    if (FFramesDrawn <= 1) then
      _Late := 0
    else if (_Late > 0) then
      _Late := 1000
    else
      _Late := -1000;

  // The very first frame often has a invalid time, so don't
  // count it into the statistics.   (???)
  if (FFramesDrawn > 1) then
  begin
    Inc(FTotAcc, _Late);
    Inc(FSumSqAcc, _Late * _Late);
  end;

  // calculate inter-frame time.  Doesn't make sense for first frame
  // second frame suffers from invalid first frame stamp.
  if (FFramesDrawn > 2) then
  begin
    _Frame := Frame div 10000; // convert to mSec else it overflows

    // This is a kludge.  It can overflow anyway (a pause can cause
    // a very long inter-frame time) and it overflows at 2**31/10**7
    // or about 215 seconds i.e. 3min 35sec
    if (_Frame > 1000) or (_Frame < 0) then
      _Frame := 1000;
    Inc(FSumSqFrameTime, _Frame * _Frame);
    Assert(FSumSqFrameTime >= 0);
    Inc(FSumFrameTime, _Frame);
  end;
  Inc(FFramesDrawn);
end;

procedure TBCBaseVideoRenderer.ThrottleWait;
var
  Throttle: Integer;
begin
  if (FThrottle > 0) then
  begin
    Throttle := FThrottle div 10000; // convert to mSec
    MSR_INTEGER(FThrottle, Throttle);
    {$IFDEF _DEBUG}
    DbgLog(Self, Format('Throttle %d ms', [Throttle]));
    {$ENDIF}
    Sleep(Throttle);
  end
  else
    Sleep(0);
end;

// Whenever a frame is rendered it goes though either OnRenderStart
// or OnDirectRender.  Data that are generated during ShouldDrawSample
// are added to the statistics by calling RecordFrameLateness from both
// these two places.

// Called in place of OnRenderStart..OnRenderEnd
// When a DirectDraw image is drawn

procedure TBCBaseVideoRenderer.OnDirectRender(MediaSample: IMediaSample);
begin
  FRenderAvg := 0;
  FRenderLast := 5000000; // If we mode switch, we do NOT want this
  // to inhibit the new average getting going!
  // so we set it to half a second
// MSR_INTEGER(m_idRenderAvg, m_trRenderAvg div 10000);
  RecordFrameLateness(FLate, FFrame);
  ThrottleWait;
end;

// Called just before we start drawing.  All we do is to get the current clock
// time (from the system) and return.  We have to store the start render time
// in a member variable because it isn't used until we complete the drawing
// The rest is just performance logging.

procedure TBCBaseVideoRenderer.OnRenderStart(MediaSample: IMediaSample);
begin
  RecordFrameLateness(FLate, FFrame);
  FRenderStart := timeGetTime;
end;

// Called directly after drawing an image.  We calculate the time spent in the
// drawing code and if this doesn't appear to have any odd looking spikes in
// it then we add it to the current average draw time.  Measurement spikes may
// occur if the drawing thread is interrupted and switched to somewhere else.

procedure TBCBaseVideoRenderer.OnRenderEnd(MediaSample: IMediaSample);
var
  RefTime: Integer;
begin
  // The renderer time can vary erratically if we are interrupted so we do
  // some smoothing to help get more sensible figures out but even that is
  // not enough as figures can go 9,10,9,9,83,9 and we must disregard 83
// milenko start
//  RefTime := (Integer(timeGetTime) - FRenderStart) * 10000;
  RefTime := (Int64(timeGetTime) - FRenderStart) * 10000;
// milenko end
  // convert mSec->UNITS
  if (RefTime < FRenderAvg * 2) or (RefTime < 2 * FRenderLast) then
    // DO_MOVING_AVG(m_trRenderAvg, tr);
    FRenderAvg := (RefTime + (AVGPERIOD - 1) * FRenderAvg) div AVGPERIOD;
  FRenderLast := RefTime;
  ThrottleWait;
end;

function TBCBaseVideoRenderer.SetSink(QualityControl: IQualityControl): HResult;
begin
  FQSink := QualityControl;
  Result := NOERROR;
end;

function TBCBaseVideoRenderer.Notify(Filter: IBaseFilter;
  Q: TQuality): HResult;
begin
  // NOTE:  We are NOT getting any locks here.  We could be called
  // asynchronously and possibly even on a time critical thread of
  // someone else's - so we do the minumum.  We only set one state
  // variable (an integer) and if that happens to be in the middle
  // of another thread reading it they will just get either the new
  // or the old value.  Locking would achieve no more than this.

  // It might be nice to check that we are being called from m_pGraph, but
  // it turns out to be a millisecond or so per throw!

  // This is heuristics, these numbers are aimed at being "what works"
  // rather than anything based on some theory.
  // We use a hyperbola because it's easy to calculate and it includes
  // a panic button asymptote (which we push off just to the left)
  // The throttling fits the following table (roughly)
  // Proportion   Throttle (msec)
  //     >=1000         0
  //        900         3
  //        800         7
  //        700        11
  //        600        17
  //        500        25
  //        400        35
  //        300        50
  //        200        72
  //        125       100
  //        100       112
  //         50       146
  //          0       200

  // (some evidence that we could go for a sharper kink - e.g. no throttling
  // until below the 750 mark - might give fractionally more frames on a
  // P60-ish machine).  The easy way to get these coefficients is to use
  // Renbase.xls follow the instructions therein using excel solver.

  if (q.Proportion >= 1000) then
    FThrottle := 0
  else
    // The DWORD is to make quite sure I get unsigned arithmetic
    // as the constant is between 2**31 and 2**32
    FThrottle := -330000 + (388880000 div (q.Proportion + 167));
  Result := NOERROR;
end;

// Send a message to indicate what our supplier should do about quality.
// Theory:
// What a supplier wants to know is "is the frame I'm working on NOW
// going to be late?".
// F1 is the frame at the supplier (as above)
// Tf1 is the due time for F1
// T1 is the time at that point (NOW!)
// Tr1 is the time that f1 WILL actually be rendered
// L1 is the latency of the graph for frame F1 = Tr1-T1
// D1 (for delay) is how late F1 will be beyond its due time i.e.
// D1 = (Tr1-Tf1) which is what the supplier really wants to know.
// Unfortunately Tr1 is in the future and is unknown, so is L1
//
// We could estimate L1 by its value for a previous frame,
// L0 = Tr0-T0 and work off
// D1' = ((T1+L0)-Tf1) = (T1 + (Tr0-T0) -Tf1)
// Rearranging terms:
// D1' = (T1-T0) + (Tr0-Tf1)
//       adding (Tf0-Tf0) and rearranging again:
//     = (T1-T0) + (Tr0-Tf0) + (Tf0-Tf1)
//     = (T1-T0) - (Tf1-Tf0) + (Tr0-Tf0)
// But (Tr0-Tf0) is just D0 - how late frame zero was, and this is the
// Late field in the quality message that we send.
// The other two terms just state what correction should be applied before
// using the lateness of F0 to predict the lateness of F1.
// (T1-T0) says how much time has actually passed (we have lost this much)
// (Tf1-Tf0) says how much time should have passed if we were keeping pace
// (we have gained this much).
//
// Suppliers should therefore work off:
//    Quality.Late + (T1-T0)  - (Tf1-Tf0)
// and see if this is "acceptably late" or even early (i.e. negative).
// They get T1 and T0 by polling the clock, they get Tf1 and Tf0 from
// the time stamps in the frames.  They get Quality.Late from us.
//

function TBCBaseVideoRenderer.SendQuality(Late,
  RealStream: TReferenceTime): HResult;
var
  q: TQuality;
  hr: HResult;
  QC: IQualityControl;
  OutputPin: IPin;
begin
  // If we are the main user of time, then report this as Flood/Dry.
  // If our suppliers are, then report it as Famine/Glut.
  //
  // We need to take action, but avoid hunting.  Hunting is caused by
  // 1. Taking too much action too soon and overshooting
  // 2. Taking too long to react (so averaging can CAUSE hunting).
  //
  // The reason why we use trLate as well as Wait is to reduce hunting;
  // if the wait time is coming down and about to go into the red, we do
  // NOT want to rely on some average which is only telling is that it used
  // to be OK once.

  q.TimeStamp := RealStream;

  if (FFrameAvg < 0) then
    q.Typ := Famine // guess
    // Is the greater part of the time taken bltting or something else
  else if (FFrameAvg > 2 * FRenderAvg) then
    q.Typ := Famine // mainly other
  else
    q.Typ := Flood; // mainly bltting

  q.Proportion := 1000; // default

  if (FFrameAvg < 0) then
    // leave it alone - we don't know enough
  else if (Late > 0) then
  begin
    // try to catch up over the next second
    // We could be Really, REALLY late, but rendering all the frames
    // anyway, just because it's so cheap.

    q.Proportion := 1000 - (Late div (UNITS div 1000));
    if (q.Proportion < 500) then
      q.Proportion := 500; // don't go daft. (could've been negative!)
  end
// milenko start
  else if (FWaitAvg > 20000) and (Late < -20000) then
  begin
//    if (FWaitAvg > 20000) and (Late < -20000) then
      // Go cautiously faster - aim at 2mSec wait.
    if (FWaitAvg >= FFrameAvg) then
    begin
      // This can happen because of some fudges.
      // The waitAvg is how long we originally planned to wait
      // The frameAvg is more honest.
      // It means that we are spending a LOT of time waiting
      q.Proportion := 2000 // double.
    end else
    begin
      if (FFrameAvg + 20000 > FWaitAvg) then
        q.Proportion := 1000 * (FFrameAvg div (FFrameAvg + 20000 - FWaitAvg))
      else
      // We're apparently spending more than the whole frame time waiting.
      // Assume that the averages are slightly out of kilter, but that we
      // are indeed doing a lot of waiting.  (This leg probably never
      // happens, but the code avoids any potential divide by zero).
      q.Proportion := 2000;
    end;
    if (q.Proportion > 2000) then
      q.Proportion := 2000; // don't go crazy.
  end;
// milenko end

  // Tell the supplier how late frames are when they get rendered
  // That's how late we are now.
  // If we are in directdraw mode then the guy upstream can see the drawing
  // times and we'll just report on the start time.  He can figure out any
  // offset to apply.  If we are in DIB Section mode then we will apply an
  // extra offset which is half of our drawing time.  This is usually small
  // but can sometimes be the dominant effect.  For this we will use the
  // average drawing time rather than the last frame.  If the last frame took
  // a long time to draw and made us late, that's already in the lateness
  // figure.  We should not add it in again unless we expect the next frame
  // to be the same.  We don't, we expect the average to be a better shot.
  // In direct draw mode the RenderAvg will be zero.

  q.Late := Late + FRenderAvg div 2;

{$IFDEF PERF}
  // log what we're doing
  MSR_INTEGER(FQualityRate, q.Proportion);
  MSR_INTEGER(FQualityTime, refTimeToMiliSec(q.Late));
{$ENDIF}
  // A specific sink interface may be set through IPin

  if (FQSink = nil) then
  begin
    // Get our input pin's peer.  We send quality management messages
    // to any nominated receiver of these things (set in the IPin
    // interface), or else to our source filter.

    QC := nil;
    OutputPin := FInputPin.GetConnected;
    Assert(Assigned(OutputPin));

    // And get an AddRef'd quality control interface

    hr := OutputPin.QueryInterface(IID_IQualityControl, QC);
    if Succeeded(hr) then
      FQSink := QC;
  end;
  if Assigned(FQSink) then
    Result := FQSink.Notify(Self, q)
  else
    Result := S_FALSE;
end;

// We are called with a valid IMediaSample image to decide whether this is to
// be drawn or not.  There must be a reference clock in operation.
// Return S_OK if it is to be drawn Now (as soon as possible)
// Return S_FALSE if it is to be drawn when it's due
// Return an error if we want to drop it
// m_nNormal=-1 indicates that we dropped the previous frame and so this
// one should be drawn early.  Respect it and update it.
// Use current stream time plus a number of heuristics (detailed below)
// to make the decision

(* ??? StartTime is changing inside routine:
Inc(StartTime, E); // N.B. earliness is negative
So, maybe it should be declared as var or out?
*)

function TBCBaseVideoRenderer.ShouldDrawSampleNow(MediaSample: IMediaSample;
  StartTime: TReferenceTime; out EndTime: TReferenceTime): HResult;
var
  RealStream: TReferenceTime; // the real time now expressed as stream time.
  RefTime: TReferenceTime;
  TrueLate, Late, Duration, t, WaitAvg, L, Frame, E, Delay
  {$IFNDEF PERF} , Accuracy{$ENDIF}: Integer;
  hr: HResult;
  JustDroppedFrame, Res, PlayASAP: Boolean;
begin
  // Don't call us unless there's a clock interface to synchronise with

  Assert(Assigned(FClock));

{$IFDEF PERF}
  MSR_INTEGER(FTimeStamp, Integer(StartTime shr 32));   // high order 32 bits
  MSR_INTEGER(FTimeStamp, Integer(StartTime));          // low order 32 bits
{$ENDIF}
  // We lose a bit of time depending on the monitor type waiting for the next
  // screen refresh.  On average this might be about 8mSec - so it will be
  // later than we think when the picture appears.  To compensate a bit
  // we bias the media samples by -8mSec i.e. 80000 UNITs.
  // We don't ever make a stream time negative (call it paranoia)
  if (StartTime >= 80000) then
  begin
    Dec(StartTime, 80000);
    Dec(EndTime, 80000); // bias stop to to retain valid frame duration
  end;

  // Cache the time stamp now.  We will want to compare what we did with what
  // we started with (after making the monitor allowance).
  FRememberStampForPerf := StartTime;

  // Get reference times (current and late)
  FClock.GetTime(int64(RealStream));

{$IFDEF PERF}
  // While the reference clock is expensive:
  // Remember the offset from timeGetTime and use that.
  // This overflows all over the place, but when we subtract to get
  // differences the overflows all cancel out.
  FTimeOffset := RealStream - timeGetTime * 10000;
{$ENDIF}
  Dec(RealStream, FStart); // convert to stream time (this is a reftime)

  // We have to wory about two versions of "lateness".  The truth, which we
  // try to work out here and the one measured against m_trTarget which
  // includes long term feedback.  We report statistics against the truth
  // but for operational decisions we work to the target.
  // We use TimeDiff to make sure we get an integer because we
  // may actually be late (or more likely early if there is a big time
  // gap) by a very long time.
  TrueLate := TimeDiff(RealStream - StartTime);
  Late := TrueLate;

{$IFDEF PERF}
  MSR_INTEGER(FSchLateTime, refTimeToMiliSec(TrueLate));
{$ENDIF}

  // Send quality control messages upstream, measured against target
  hr := SendQuality(Late, RealStream);
  // Note: the filter upstream is allowed to this FAIL meaning "you do it".
  FSupplierHandlingQuality := (hr = S_OK);

  // Decision time!  Do we drop, draw when ready or draw immediately?

  Duration := EndTime - StartTime;
  // We need to see if the frame rate of the file has just changed.
  // This would make comparing our previous frame rate with the current
  // frame rate inefficent.  Hang on a moment though.  I've seen files
  // where the frames vary between 33 and 34 mSec so as to average
  // 30fps.  A minor variation like that won't hurt us.
  t := FDuration div 32;
  if (Duration > FDuration + t) or (Duration < FDuration - t) then
  begin
    // There's a major variation.  Reset the average frame rate to
    // exactly the current rate to disable decision 9002 for this frame,
    // and remember the new rate.
    FFrameAvg := Duration;
    FDuration := Duration;
  end;

{$IFDEF PERF}
  MSR_INTEGER(FEarliness, refTimeToMiliSec(FEarliness));
  MSR_INTEGER(FRenderAvg, refTimeToMiliSec(FRenderAvg));
  MSR_INTEGER(FFrameAvg, refTimeToMiliSec(FFrameAvg));
  MSR_INTEGER(FWaitAvg, refTimeToMiliSec(FWaitAvg));
  MSR_INTEGER(FDuration, refTimeToMiliSec(FDuration));

  if (S_OK = MediaSample.IsDiscontinuity) then
    MSR_INTEGER(FDecision, 9000);
{$ENDIF}

  // Control the graceful slide back from slow to fast machine mode.
  // After a frame drop accept an early frame and set the earliness to here
  // If this frame is already later than the earliness then slide it to here
  // otherwise do the standard slide (reduce by about 12% per frame).
  // Note: earliness is normally NEGATIVE
  JustDroppedFrame :=
    (FSupplierHandlingQuality and
    //  Can't use the pin sample properties because we might
    //  not be in Receive when we call this
    (S_OK = MediaSample.IsDiscontinuity) // he just dropped one
    ) or
    (FNormal = -1); // we just dropped one

  // Set m_trEarliness (slide back from slow to fast machine mode)
  if (Late > 0) then
    FEarliness := 0 // we are no longer in fast machine mode at all!
  else if ((Late >= FEarliness) or JustDroppedFrame) then
    FEarliness := Late // Things have slipped of their own accord
  else
    FEarliness := FEarliness - FEarliness div 8; // graceful slide

  // prepare the new wait average - but don't pollute the old one until
  // we have finished with it.
  // We never mix in a negative wait.  This causes us to believe in fast machines
  // slightly more.
  if (Late < 0) then
    L := -Late
  else
    L := 0;
  WaitAvg := (L + FWaitAvg * (AVGPERIOD - 1)) div AVGPERIOD;

  RefTime := RealStream - FLastDraw; // Cd be large - 4 min pause!
  if (RefTime > 10000000) then
    RefTime := 10000000; // 1 second - arbitrarily.
  Frame := RefTime;

  if FSupplierHandlingQuality then
    Res := (Late <= Duration * 4)
  else
    Res := (Late + Late < Duration);
  // We will DRAW this frame IF...
  if (
    // ...the time we are spending drawing is a small fraction of the total
    // observed inter-frame time so that dropping it won't help much.
    (3 * FRenderAvg <= FFrameAvg)

    // ...or our supplier is NOT handling things and the next frame would
    // be less timely than this one or our supplier CLAIMS to be handling
    // things, and is now less than a full FOUR frames late.
    or Res
    // ...or we are on average waiting for over eight milliseconds then
    // this may be just a glitch.  Draw it and we'll hope to catch up.
    or (FWaitAvg > 80000)

    // ...or we haven't drawn an image for over a second.  We will update
    // the display, which stops the video looking hung.
    // Do this regardless of how late this media sample is.
    or ((RealStream - FLastDraw) > UNITS)
    ) then
  begin
    // We are going to play this frame.  We may want to play it early.
    // We will play it early if we think we are in slow machine mode.
    // If we think we are NOT in slow machine mode, we will still play
    // it early by m_trEarliness as this controls the graceful slide back.
    // and in addition we aim at being m_trTarget late rather than "on time".

    PlayASAP := False;

    // we will play it AT ONCE (slow machine mode) if...

    // ...we are playing catch-up
    if (JustDroppedFrame) then
    begin
      PlayASAP := True;
{$IFDEF PERF}
      MSR_INTEGER(FDecision, 9001);
{$ENDIF}
    end
      // ...or if we are running below the true frame rate
      // exact comparisons are glitchy, for these measurements,
      // so add an extra 5% or so
    else if (FFrameAvg > Duration + Duration div 16)

    // It's possible to get into a state where we are losing ground, but
    // are a very long way ahead.  To avoid this or recover from it
    // we refuse to play early by more than 10 frames.
    and (Late > -Duration * 10) then
    begin
      PlayASAP := True;
{$IFDEF PERF}
      MSR_INTEGER(FDecision, 9002);
{$ENDIF}
    end
{$IFDEF 0}
      // ...or if we have been late and are less than one frame early
    else if ((Late + Duration > 0) and
      (FWaitAvg <= 20000) then
      begin
        PlayASAP := True;
{$IFDEF PERF}
        MSR_INTEGER(m_idDecision, 9003);
{$ENDIF}
      end
{$ENDIF}
      ;
      // We will NOT play it at once if we are grossly early.  On very slow frame
      // rate movies - e.g. clock.avi - it is not a good idea to leap ahead just
      // because we got starved (for instance by the net) and dropped one frame
      // some time or other.  If we are more than 900mSec early, then wait.
      if (Late < -9000000) then
        PlayASAP := False;

      if PlayASAP then
      begin
        FNormal := 0;
{$IFDEF PERF}
        MSR_INTEGER(FDecision, 0);
{$ENDIF}
        // When we are here, we are in slow-machine mode.  trLate may well
        // oscillate between negative and positive when the supplier is
        // dropping frames to keep sync.  We should not let that mislead
        // us into thinking that we have as much as zero spare time!
        // We just update with a zero wait.
        FWaitAvg := (FWaitAvg * (AVGPERIOD - 1)) div AVGPERIOD;

        // Assume that we draw it immediately.  Update inter-frame stats
        FFrameAvg := (Frame + FFrameAvg * (AVGPERIOD - 1)) div AVGPERIOD;
{$IFNDEF PERF}
        // If this is NOT a perf build, then report what we know so far
        // without looking at the clock any more.  This assumes that we
        // actually wait for exactly the time we hope to.  It also reports
        // how close we get to the manipulated time stamps that we now have
        // rather than the ones we originally started with.  It will
        // therefore be a little optimistic.  However it's fast.
        PreparePerformanceData(TrueLate, Frame);
{$ENDIF}
        FLastDraw := RealStream;
        if (FEarliness > Late) then
          FEarliness := Late; // if we are actually early, this is neg
        Result := S_OK; // Draw it now
      end
      else
      begin
        Inc(FNormal);
        // Set the average frame rate to EXACTLY the ideal rate.
        // If we are exiting slow-machine mode then we will have caught up
        // and be running ahead, so as we slide back to exact timing we will
        // have a longer than usual gap at this point.  If we record this
        // real gap then we'll think that we're running slow and go back
        // into slow-machine mode and vever get it straight.
        FFrameAvg := Duration;
{$IFDEF PERF}
        MSR_INTEGER(FDecision, 1);
{$ENDIF}

        // Play it early by m_trEarliness and by m_trTarget
        E := FEarliness;
        if (E < -FFrameAvg) then
          E := -FFrameAvg;
        Inc(StartTime, E); // N.B. earliness is negative

        Delay := -TrueLate;
        if (Delay <= 0) then
          Result := S_OK
        else
          Result := S_FALSE; // OK = draw now, FALSE = wait

        FWaitAvg := WaitAvg;

        // Predict when it will actually be drawn and update frame stats

        if (Result = S_FALSE) then // We are going to wait
        begin
          {$IFNDEF PERF}
          Frame := TimeDiff(StartTime - FLastDraw);
          {$ENDIF}
          FLastDraw := StartTime;
        end
        else
          // trFrame is already = trRealStream-m_trLastDraw;
          FLastDraw := RealStream;
{$IFNDEF PERF}
        if (Delay > 0) then
          // Report lateness based on when we intend to play it
          Accuracy := TimeDiff(StartTime - FRememberStampForPerf)
        else
          // Report lateness based on playing it *now*.
          Accuracy := TrueLate; // trRealStream-RememberStampForPerf;
        PreparePerformanceData(Accuracy, Frame);
{$ENDIF}
      end;
      Exit;
  end;

  // We are going to drop this frame!
  // Of course in DirectDraw mode the guy upstream may draw it anyway.

  // This will probably give a large negative wack to the wait avg.
  FWaitAvg := WaitAvg;

{$IFDEF PERF}
  // Respect registry setting - debug only!
  if (FDrawLateFrames) then
  begin
    Result := S_OK; // draw it when it's ready
    // even though it's late.
    Exit;
  end;
{$ENDIF}

  // We are going to drop this frame so draw the next one early
  // n.b. if the supplier is doing direct draw then he may draw it anyway
  // but he's doing something funny to arrive here in that case.
{$IFDEF PERF}
  MSR_INTEGER(FDecision, 2);
{$ENDIF}
  FNormal := -1;
  Result := E_FAIL; // drop it
end;

// NOTE we're called by both the window thread and the source filter thread
// so we have to be protected by a critical section (locked before called)
// Also, when the window thread gets signalled to render an image, it always
// does so regardless of how late it is. All the degradation is done when we
// are scheduling the next sample to be drawn. Hence when we start an advise
// link to draw a sample, that sample's time will always become the last one
// drawn - unless of course we stop streaming in which case we cancel links

function TBCBaseVideoRenderer.ScheduleSample(MediaSample: IMediaSample):
  Boolean;
begin
  // We override ShouldDrawSampleNow to add quality management

  Result := inherited ScheduleSample(MediaSample);
  if not Result then
    Inc(FFramesDropped);

  // m_cFramesDrawn must NOT be updated here.  It has to be updated
  // in RecordFrameLateness at the same time as the other statistics.
end;

// Implementation of IQualProp interface needed to support the property page
// This is how the property page gets the data out of the scheduler. We are
// passed into the constructor the owning object in the COM sense, this will
// either be the video renderer or an external IUnknown if we're aggregated.
// We initialise our CUnknown base class with this interface pointer. Then
// all we have to do is to override NonDelegatingQueryInterface to expose
// our IQualProp interface. The AddRef and Release are handled automatically
// by the base class and will be passed on to the appropriate outer object

function TBCBaseVideoRenderer.get_FramesDroppedInRenderer(var FramesDropped:
  Integer): HResult;
begin
// milenko start
  if not Assigned(@FramesDropped) then
  begin
    Result := E_POINTER;
    Exit;
  end;
// milenko end
  FInterfaceLock.Lock;
  try
    FramesDropped := FFramesDropped;
    Result := NOERROR;
  finally
    FInterfaceLock.UnLock;
  end;
end;

// Set *pcFramesDrawn to the number of frames drawn since
// streaming started.

function TBCBaseVideoRenderer.get_FramesDrawn(out FramesDrawn: Integer):
  HResult;
begin
// milenko start
  if not Assigned(@FramesDrawn) then
  begin
    Result := E_POINTER;
    Exit;
  end;
// milenko end
  FInterfaceLock.Lock;
  try
    FramesDrawn := FFramesDrawn;
    Result := NOERROR;
  finally
    FInterfaceLock.UnLock;
  end;
end;

// Set iAvgFrameRate to the frames per hundred secs since
// streaming started.  0 otherwise.

function TBCBaseVideoRenderer.get_AvgFrameRate(out AvgFrameRate: Integer):
  HResult;
var
  t: Integer;
begin
// milenko start
  if not Assigned(@AvgFrameRate) then
  begin
    Result := E_POINTER;
    Exit;
  end;
// milenko end
  FInterfaceLock.Lock;
  try
    if (FIsStreaming) then
// milenko start
//    t := Integer(timeGetTime) - FStreamingStart
      t := Int64(timeGetTime) - FStreamingStart
// milenko end
    else
      t := FStreamingStart;

    if (t <= 0) then
    begin
      AvgFrameRate := 0;
      Assert(FFramesDrawn = 0);
    end
    else
      // i is frames per hundred seconds
      AvgFrameRate := MulDiv(100000, FFramesDrawn, t);
    Result := NOERROR;
  finally
    FInterfaceLock.UnLock;
  end;
end;

// Set *piAvg to the average sync offset since streaming started
// in mSec.  The sync offset is the time in mSec between when the frame
// should have been drawn and when the frame was actually drawn.

function TBCBaseVideoRenderer.get_AvgSyncOffset(out Avg: Integer): HResult;
begin
// milenko start
  if not Assigned(@Avg) then
  begin
    Result := E_POINTER;
    Exit;
  end;
// milenko end
  FInterfaceLock.Lock;
  try
    if (nil = FClock) then
    begin
      Avg := 0;
      Result := NOERROR;
      Exit;
    end;
    // Note that we didn't gather the stats on the first frame
    // so we use m_cFramesDrawn-1 here
    if (FFramesDrawn <= 1) then
      Avg := 0
    else
      Avg := (FTotAcc div (FFramesDrawn - 1));
    Result := NOERROR;
  finally
    FInterfaceLock.UnLock;
  end;
end;

// To avoid dragging in the maths library - a cheap
// approximate integer square root.
// We do this by getting a starting guess which is between 1
// and 2 times too large, followed by THREE iterations of
// Newton Raphson.  (That will give accuracy to the nearest mSec
// for the range in question - roughly 0..1000)
//
// It would be faster to use a linear interpolation and ONE NR, but
// who cares.  If anyone does - the best linear interpolation is
// to approximates sqrt(x) by
// y = x * (sqrt(2)-1) + 1 - 1/sqrt(2) + 1/(8*(sqrt(2)-1))
// 0r y = x*0.41421 + 0.59467
// This minimises the maximal error in the range in question.
// (error is about +0.008883 and then one NR will give error .0000something
// (Of course these are integers, so you can't just multiply by 0.41421
// you'd have to do some sort of MulDiv).
// Anyone wanna check my maths?  (This is only for a property display!)

function isqrt(x: Integer): Integer;
var
  s: Integer;
begin
  s := 1;
  // Make s an initial guess for sqrt(x)
  if (x > $40000000) then
    s := $8000 // prevent any conceivable closed loop
  else
  begin
    while (s * s < x) do // loop cannot possible go more than 31 times
      s := 2 * s; // normally it goes about 6 times
    // Three NR iterations.
    if (x = 0) then
      s := 0 // Wouldn't it be tragic to divide by zero whenever our
      // accuracy was perfect!
    else
    begin
      s := (s * s + x) div (2 * s);
      if (s >= 0) then
        s := (s * s + x) div (2 * s);
      if (s >= 0) then
        s := (s * s + x) div (2 * s);
    end;
  end;
  Result := s;
end;

//
//  Do estimates for standard deviations for per-frame
//  statistics
//

function TBCBaseVideoRenderer.GetStdDev(Samples: Integer; out Res: Integer;
  SumSq, Tot: Int64): HResult;
var
  x: Int64;
begin
// milenko start
  if not Assigned(@Res) then
  begin
    Result := E_POINTER;
    Exit;
  end;
// milenko end
  FInterfaceLock.Lock;
  try
    if (nil = FClock) then
    begin
      Res := 0;
      Result := NOERROR;
      Exit;
    end;

    // If S is the Sum of the Squares of observations and
    //    T the Total (i.e. sum) of the observations and there were
    //    N observations, then an estimate of the standard deviation is
    //      sqrt( (S - T**2/N) / (N-1) )

    if (Samples <= 1) then
      Res := 0
    else
    begin
      // First frames have invalid stamps, so we get no stats for them
      // So we need 2 frames to get 1 datum, so N is cFramesDrawn-1

      // so we use m_cFramesDrawn-1 here
      // ??? llMilDiv ???
// milenko start (removed the 2 outputdebugstring messages...i added them and
//                they are not needed anymore)
      x := SumSq - llMulDiv(Tot, Tot, Samples, 0);
      x := x div (Samples - 1);
// milenko end
      Assert(x >= 0);
      Res := isqrt(Longint(x));
    end;
    Result := NOERROR;

  finally
    FInterfaceLock.UnLock;
  end;
end;

// Set *piDev to the standard deviation in mSec of the sync offset
// of each frame since streaming started.

function TBCBaseVideoRenderer.get_DevSyncOffset(out Dev: Integer): HResult;
begin
  // First frames have invalid stamps, so we get no stats for them
  // So we need 2 frames to get 1 datum, so N is cFramesDrawn-1
  Result := GetStdDev(FFramesDrawn - 1, Dev, FSumSqAcc, FTotAcc);
end;

// Set *piJitter to the standard deviation in mSec of the inter-frame time
// of frames since streaming started.

function TBCBaseVideoRenderer.get_Jitter(out Jitter: Integer): HResult;
begin
  // First frames have invalid stamps, so we get no stats for them
  // So second frame gives invalid inter-frame time
  // So we need 3 frames to get 1 datum, so N is cFramesDrawn-2
  Result := GetStdDev(FFramesDrawn - 2, Jitter, FSumSqFrameTime, FSumFrameTime);
end;

// Overidden to return our IQualProp interface

function TBCBaseVideoRenderer.NonDelegatingQueryInterface(const IID: TGUID;
  out Obj): HResult;
begin
  // We return IQualProp and delegate everything else

  if IsEqualGUID(IID, IID_IQualProp) then
    if GetInterface(IID_IQualProp, Obj) then
      Result := S_OK
    else
      Result := E_FAIL
  else if IsEqualGUID(IID, IID_IQualityControl) then
    if GetInterface(IID_IQualityControl, Obj) then
      Result := S_OK
    else
      Result := E_FAIL
  else
    Result := inherited NonDelegatingQueryInterface(IID, Obj);
end;

// Override JoinFilterGraph so that, just before leaving
// the graph we can send an EC_WINDOW_DESTROYED event

function TBCBaseVideoRenderer.JoinFilterGraph(Graph: IFilterGraph;
  Name: PWideChar): HResult;
var
  Filter: IBaseFilter;
begin
  // Since we send EC_ACTIVATE, we also need to ensure
  // we send EC_WINDOW_DESTROYED or the resource manager may be
  // holding us as a focus object
  if (Graph = nil) and Assigned(FGraph) then
  begin
    // We were in a graph and now we're not
    // Do this properly in case we are aggregated
    QueryInterface(IID_IBaseFilter, Filter);
    NotifyEvent(EC_WINDOW_DESTROYED, Integer(Filter), 0);
    Filter := nil;
  end;

  Result := inherited JoinFilterGraph(Graph, Name);
end;

// milenko start (added TBCPullPin)
constructor TBCPullPin.Create;
begin
  inherited Create;
  FReader := nil;
  FAlloc := nil;
  FState := TM_Exit;
end;

destructor TBCPullPin.Destroy;
begin
  Disconnect;
end;

procedure TBCPullPin.Process;
var
  Discontinuity: Boolean;
  Actual: TAllocatorProperties;
  hr: HRESULT;
  Start, Stop, Current, AlignStop: TReferenceTime;
  Request: DWORD;
  Sample: IMediaSample;
  StopThis: Int64;
begin
  // is there anything to do?
  if (FStop <= FStart) then
  begin
    EndOfStream;
    Exit;
  end;

  Discontinuity := True;

  // if there is more than one sample at the allocator,
  // then try to queue 2 at once in order to overlap.
  // -- get buffer count and required alignment
  FAlloc.GetProperties(Actual);

  // align the start position downwards
  Start := AlignDown(FStart div UNITS, Actual.cbAlign) * UNITS;
  Current := Start;

  Stop := FStop;
  if (Stop > FDuration) then Stop := FDuration;

  // align the stop position - may be past stop, but that
  // doesn't matter
  AlignStop := AlignUp(Stop div UNITS, Actual.cbAlign) * UNITS;

  if not FSync then
  begin
    //  Break out of the loop either if we get to the end or we're asked
    //  to do something else
    while (Current < AlignStop) do
    begin
      // Break out without calling EndOfStream if we're asked to
      // do something different
	    if CheckRequest(@Request) then Exit;

	    // queue a first sample
	    if (Actual.cBuffers > 1) then
      begin
        hr := QueueSample(Current, AlignStop, True);
        Discontinuity := False;
        if FAILED(hr) then Exit;
	    end;

	    // loop queueing second and waiting for first..
	    while (Current < AlignStop) do
      begin
        hr := QueueSample(Current, AlignStop, Discontinuity);
        Discontinuity := False;
        if FAILED(hr) then Exit;

        hr := CollectAndDeliver(Start, Stop);
        if (S_OK <> hr) then
        begin
          // stop if error, or if downstream filter said
          // to stop.
		      Exit;
        end;
	    end;

	    if (Actual.cBuffers > 1) then
      begin
        hr := CollectAndDeliver(Start, Stop);
        if FAILED(hr) then Exit;
	    end;
	  end;
  end else
  begin
    // sync version of above loop
    while (Current < AlignStop) do
    begin
	    // Break out without calling EndOfStream if we're asked to
	    // do something different
	    if CheckRequest(@Request) then Exit;

	    hr := FAlloc.GetBuffer(Sample, nil, nil, 0);
	    if FAILED(hr) then
      begin
        OnError(hr);
        Exit;
	    end;

      StopThis := Current + (Sample.GetSize * UNITS);
	    if (StopThis > AlignStop) then StopThis := AlignStop;
	    Sample.SetTime(@Current, @StopThis);
	    Current := StopThis;

	    if Discontinuity then
      begin
        Sample.SetDiscontinuity(True);
        Discontinuity := False;
	    end;

	    hr := FReader.SyncReadAligned(Sample);

	    if FAILED(hr) then
      begin
        Sample := nil;
        OnError(hr);
        Exit;
	    end;

	    hr := DeliverSample(Sample, Start, Stop);
	    if (hr <> S_OK) then
      begin
        if FAILED(hr) then OnError(hr);
        Exit;
	    end;
    end;
  end;

  EndOfStream;
end;

procedure TBCPullPin.CleanupCancelled;
var
  Sample: IMediaSample;
  Unused: DWORD;
begin
  while True do
  begin
    FReader.WaitForNext(
			    0,          // no wait
			    Sample,
			    Unused);
    if Assigned(Sample) then Sample := nil
                        else Exit;
  end;
end;

function TBCPullPin.PauseThread: HRESULT;
begin
  FAccessLock.Lock;
  try
    if not ThreadExists then
    begin
      Result := E_UNEXPECTED;
      Exit;
    end;

    // need to flush to ensure the thread is not blocked
    // in WaitForNext
    Result := FReader.BeginFlush;
    if FAILED(Result) then Exit;

    FState := TM_Pause;
    Result := CallWorker(Cardinal(TM_Pause));

    FReader.EndFlush;
  finally
    FAccessLock.UnLock;
  end;
end;

function TBCPullPin.StartThread: HRESULT;
begin
  FAccessLock.Lock;
  try
    if not Assigned(FAlloc) or not Assigned(FReader) then
    begin
      Result := E_UNEXPECTED;
      Exit;
    end;

    if not ThreadExists then
    begin
      // commit allocator
      Result := FAlloc.Commit;
      if FAILED(Result) then Exit;

      // start thread
      if not Create_ then
      begin
        Result := E_FAIL;
        Exit;
      end;
	  end;

    FState := TM_Start;
    Result := HRESULT(CallWorker(DWORD(FState)));
  finally
    FAccessLock.UnLock;
  end;
end;

function TBCPullPin.StopThread: HRESULT;
begin
  FAccessLock.Lock;
  try
    if not ThreadExists then
    begin
      Result := S_FALSE;
      Exit;
    end;

    // need to flush to ensure the thread is not blocked
    // in WaitForNext
    Result := FReader.BeginFlush;
    if FAILED(Result) then Exit;

    FState := TM_Exit;
    Result := CallWorker(Cardinal(TM_Exit));

    FReader.EndFlush;

    // wait for thread to completely exit
    Close;

    // decommit allocator
    if Assigned(FAlloc) then FAlloc.Decommit;
    Result := S_OK;
  finally
    FAccessLock.UnLock;
  end;
end;

function TBCPullPin.QueueSample(var tCurrent: TReferenceTime; tAlignStop: TReferenceTime; bDiscontinuity: Boolean): HRESULT;
var
  Sample: IMediaSample;
  StopThis: Int64;
begin
  Result := FAlloc.GetBuffer(Sample, nil, nil, 0);
  if FAILED(Result) then Exit;

  StopThis := tCurrent + (Sample.GetSize * UNITS);
  if (StopThis > tAlignStop) then StopThis := tAlignStop;

  Sample.SetTime(@tCurrent, @StopThis);
  tCurrent := StopThis;

  Sample.SetDiscontinuity(bDiscontinuity);

  Result := FReader.Request(Sample,0);
  if FAILED(Result) then
  begin
    Sample := nil;
    CleanupCancelled;
    OnError(Result);
  end;
end;

function TBCPullPin.CollectAndDeliver(tStart,tStop: TReferenceTime): HRESULT;
var
  Sample: IMediaSample;
  Unused: DWORD;
begin
  Result := FReader.WaitForNext(INFINITE,Sample,Unused);
  if FAILED(Result) then
  begin
    if Assigned(Sample) then Sample := nil;
	end else
  begin
    Result := DeliverSample(Sample, tStart, tStop);
  end;
  if FAILED(Result) then
  begin
    CleanupCancelled;
    OnError(Result);
  end;
end;

function TBCPullPin.DeliverSample(pSample: IMediaSample; tStart,tStop: TReferenceTime): HRESULT;
var
  t1, t2: TReferenceTime;
begin
  // fix up sample if past actual stop (for sector alignment)
  pSample.GetTime(t1, t2);
  if (t2 > tStop) then t2 := tStop;

  // adjust times to be relative to (aligned) start time
  dec(t1,tStart);
  dec(t2,tStart);
  pSample.SetTime(@t1, @t2);

  Result := Receive(pSample);
  pSample := nil;
end;

function TBCPullPin.ThreadProc: DWord;
var
  cmd: DWORD;
begin
  Result := 1; // ???
  while True do
  begin
    cmd := GetRequest;
	  case TThreadMsg(cmd) of
      TM_Exit:
      begin
        Reply(S_OK);
        Result := 0;
        Exit;
	    end;
      TM_Pause:
      begin
        // we are paused already
        Reply(S_OK);
        break;
      end;
      TM_Start:
      begin
        Reply(S_OK);
        Process;
        break;
      end;
    end;

    // at this point, there should be no outstanding requests on the
    // upstream filter.
    // We should force begin/endflush to ensure that this is true.
    // !!!Note that we may currently be inside a BeginFlush/EndFlush pair
    // on another thread, but the premature EndFlush will do no harm now
    // that we are idle.
    FReader.BeginFlush;
    CleanupCancelled;
    FReader.EndFlush;
  end;
end;

// returns S_OK if successfully connected to an IAsyncReader interface
// from this object
// Optional allocator should be proposed as a preferred allocator if
// necessary
function TBCPullPin.Connect(pUnk: IUnknown; pAlloc: IMemAllocator; bSync: Boolean): HRESULT;
var
  Total, Avail: Int64;
begin
  FAccessLock.Lock;
  try
    if Assigned(FReader) then
    begin
      Result := VFW_E_ALREADY_CONNECTED;
      Exit;
    end;

    Result := pUnk.QueryInterface(IID_IAsyncReader, FReader);
    if FAILED(Result) then Exit;

    Result := DecideAllocator(pAlloc, nil);
    if FAILED(Result) then
    begin
      Disconnect;
      Exit;
    end;

    Result := FReader.Length(Total, Avail);
    if FAILED(Result) then
    begin
      Disconnect;
      Exit;
    end;

    // convert from file position to reference time
    FDuration := Total * UNITS;
    FStop := FDuration;
    FStart := 0;

    FSync := bSync;

    Result := S_OK;
  finally
    FAccessLock.UnLock;
  end;
end;

// disconnect any connection made in Connect
function TBCPullPin.Disconnect: HRESULT;
begin
  FAccessLock.Lock;
  try
    StopThread;

    if Assigned(FReader) then FReader := nil;

    if Assigned(FAlloc) then FAlloc := nil;

    Result := S_OK;
  finally
    FAccessLock.UnLock;
  end;
end;

// agree an allocator using RequestAllocator - optional
// props param specifies your requirements (non-zero fields).
// returns an error code if fail to match requirements.
// optional IMemAllocator interface is offered as a preferred allocator
// but no error occurs if it can't be met.
function TBCPullPin.DecideAllocator(pAlloc: IMemAllocator; pProps: PAllocatorProperties): HRESULT;
var
  pRequest: PAllocatorProperties;
  Request: TAllocatorProperties;
begin
  if (pProps = nil) then
  begin
    Request.cBuffers := 3;
    Request.cbBuffer := 64*1024;
    Request.cbAlign := 0;
    Request.cbPrefix := 0;
    pRequest := @Request;
  end else
  begin
    pRequest := pProps;
  end;
  Result := FReader.RequestAllocator(pAlloc,pRequest,FAlloc);
end;

function TBCPullPin.Seek(tStart, tStop: TReferenceTime): HRESULT;
var
  AtStart: TThreadMsg;
begin
  FAccessLock.Lock;
  try
    AtStart := FState;
    if (AtStart = TM_Start) then
    begin
      BeginFlush;
      PauseThread;
      EndFlush;
    end;

    FStart := tStart;
    FStop := tStop;

    Result := S_OK;
    if (AtStart = TM_Start) then Result := StartThread;
  finally
    FAccessLock.UnLock;
  end;
end;

function TBCPullPin.Duration(out ptDuration: TReferenceTime): HRESULT;
begin
  ptDuration := FDuration;
  Result := S_OK;
end;

// start pulling data
function TBCPullPin.Active: HRESULT;
begin
  ASSERT(not ThreadExists);
  Result := StartThread;
end;

// stop pulling data
function TBCPullPin.Inactive: HRESULT;
begin
  StopThread;
  Result := S_OK;
end;

function TBCPullPin.AlignDown(ll: Int64; lAlign: LongInt): Int64;
begin
	Result := ll and not (lAlign-1);
end;

function TBCPullPin.AlignUp(ll: Int64; lAlign: LongInt): Int64;
begin
	Result := (ll + (lAlign -1)) and not (lAlign -1);
end;

function TBCPullPin.GetReader: IAsyncReader;
begin
	Result := FReader;
end;
// milenko end

// milenko start reftime implementation
procedure TBCRefTime.Create_;
begin
  FTime := 0;
end;

procedure TBCRefTime.Create_(msecs: Longint);
begin
  FTime := MILLISECONDS_TO_100NS_UNITS(msecs);
end;

function TBCRefTime.SetTime(var rt: TBCRefTime): TBCRefTime;
begin
  FTime := rt.FTime;
  Result := Self;
end;

function TBCRefTime.SetTime(var ll: LONGLONG): TBCRefTime;
begin
  FTime := ll;
end;

function TBCRefTime.AddTime(var rt: TBCRefTime): TBCRefTime;
begin
  TReferenceTime(Self) := TReferenceTime(Self) + TReferenceTime(rt);
  Result := Self;
end;

function TBCRefTime.SubstractTime(var rt: TBCRefTime): TBCRefTime;
begin
  TReferenceTime(Self) := TReferenceTime(Self) - TReferenceTime(rt);
  Result := Self;
end;

function TBCRefTime.Millisecs: Longint;
begin
  Result := fTime div (UNITS div MILLISECONDS);
end;

function TBCRefTime.GetUnits: LONGLONG;
begin
  Result := fTime;
end;
// milenko end

// milenko start schedule implementation
constructor TBCAdvisePacket.Create;
begin
  inherited Create;
end;

constructor TBCAdvisePacket.Create(Next: TBCAdvisePacket; Time: LONGLONG);
begin
  inherited Create;
  FNext := Next;
  FEventTime := Time;
end;

procedure TBCAdvisePacket.InsertAfter(Packet: TBCAdvisePacket);
begin
  Packet.FNext := FNext;
  FNext := Packet;
end;

function TBCAdvisePacket.IsZ: Boolean;
begin
  Result := FNext = nil;
end;

function TBCAdvisePacket.RemoveNext: TBCAdvisePacket;
var
  Next,
  NewNext : TBCAdvisePacket;
begin
  Next := FNext;
  NewNext := Next.FNext;
  FNext := NewNext;
  Result := Next;
end;

procedure TBCAdvisePacket.DeleteNext;
begin
  RemoveNext.Free;
end;

function TBCAdvisePacket.Next: TBCAdvisePacket;
begin
  Result := FNext;
  if Result.IsZ then Result := nil;
end;

function TBCAdvisePacket.Cookie: DWORD;
begin
  Result := FAdviseCookie;
end;

constructor TBCAMSchedule.Create(Event: THandle);
begin
  inherited Create('TBCAMSchedule');

  FZ := TBCAdvisePacket.Create(nil,MAX_TIME);
  FHead := TBCAdvisePacket.Create(FZ,0);

  FNextCookie := 0;
  FAdviseCount := 0;
  FAdviseCache := nil;
  FCacheCount := 0;
  FEvent := Event;

  FSerialize := TBCCritSec.Create;

  FZ.FAdviseCookie := 0;
  FHead.FAdviseCookie := FZ.FAdviseCookie;
end;

destructor TBCAMSchedule.Destroy;
var
  p, p_next : TBCAdvisePacket;
begin
  FSerialize.Lock;
  try
    // Delete cache
    p := FAdviseCache;
    while (p <> nil) do
    begin
      p_next := p.FNext;
      FreeAndNil(p);
      p := p_next;
    end;

    ASSERT(FAdviseCount = 0);
    // Better to be safe than sorry
    if (FAdviseCount > 0) then
    begin
      DumpLinkedList;
      while not FHead.FNext.IsZ do
      begin
        FHead.DeleteNext;
        dec(FAdviseCount);
      end;
    end;

    // If, in the debug version, we assert twice, it means, not only
    // did we have left over advises, but we have also let m_dwAdviseCount
    // get out of sync. with the number of advises actually on the list.
    ASSERT(FAdviseCount = 0);
  finally
    FSerialize.Unlock;
  end;
  FreeAndNil(FSerialize);
  inherited Destroy;
end;

function TBCAMSchedule.GetAdviseCount: DWORD;
begin
  // No need to lock, m_dwAdviseCount is 32bits & declared volatile
  // DCODER: No volatile in Delphi -> needs a lock ?
  FSerialize.Lock;
  try
    Result := FAdviseCount;
  finally
    FSerialize.UnLock;
  end;
end;

function TBCAMSchedule.GetNextAdviseTime: TReferenceTime;
begin
  FSerialize.Lock;  // Need to stop the linked list from changing
  try
    Result := FHead.FNext.FEventTime;
  finally
    FSerialize.UnLock;
  end;
end;

function TBCAMSchedule.AddAdvisePacket(const time1, time2: TReferenceTime;
  h: THandle; periodic: Boolean): DWORD;
var
  p : TBCAdvisePacket;
begin
  // Since we use MAX_TIME as a sentry, we can't afford to
  // schedule a notification at MAX_TIME

  ASSERT(time1 < MAX_TIME);
  FSerialize.Lock;
  try
    if Assigned(FAdviseCache) then
    begin
      p := FAdviseCache;
      FAdviseCache := p.FNext;
      dec(FCacheCount);
    end else
    begin
      p := TBCAdvisePacket.Create;
    end;

    if Assigned(p) then
    begin
      p.FEventTime := time1;
      p.FPeriod := time2;
      p.FNotify := h;
      p.FPeriodic := periodic;
      Result := AddAdvisePacket(p);
    end else
    begin
      Result := 0;
    end;
  finally
    FSerialize.UnLock;
  end;
end;

function TBCAMSchedule.Unadvise(AdviseCookie: DWORD): HRESULT;
var
  p_prev, p_n : TBCAdvisePacket;
begin
  Result := S_FALSE;
  p_prev := FHead;

  FSerialize.Lock;
  try
    p_n := p_prev.Next;
    while Assigned(p_n) do // The Next() method returns NULL when it hits z
    begin
      if (p_n.FAdviseCookie = AdviseCookie) then
      begin
        Delete(p_prev.RemoveNext);
        dec(FAdviseCount);
        Result := S_OK;
        // Having found one cookie that matches, there should be no more
        {$IFDEF _DEBUG}
        p_n := p_prev.Next;
        while Assigned(p_n) do
        begin
          ASSERT(p_n.FAdviseCookie <> AdviseCookie);
          p_prev := p_n;
          p_n := p_prev.Next;
        end;
        {$ENDIF}
        break;
      end;
      p_prev := p_n;
      p_n := p_prev.Next;
    end;
  finally
    FSerialize.UnLock;
  end;
end;

function TBCAMSchedule.Advise(const Time_: TReferenceTime): TReferenceTime;
var
  NextTime : TReferenceTime;
  Advise : TBCAdvisePacket;
begin
  {$IFDEF _DEBUG}
    DbgLog(
      Self, 'TBCAMSchedule.Advise( ' +
      inttostr((Time_ div (UNITS div MILLISECONDS))) + ' ms '
    );
  {$ENDIF}

  FSerialize.Lock;
  try
    {$IFDEF _DEBUG}
      DumpLinkedList;
    {$ENDIF}

    //  Note - DON'T cache the difference, it might overflow
    Advise := FHead.FNext;
    NextTime := Advise.FEventTime;
    while ((Time_ >= NextTime) and not Advise.IsZ) do
    begin
      // DCODER: assert raised here
      ASSERT(Advise.FAdviseCookie > 0); // If this is zero, its the head or the tail!!
      ASSERT(Advise.FNotify <> INVALID_HANDLE_VALUE);
      if (Advise.FPeriodic = True) then
      begin
        ReleaseSemaphore(Advise.FNotify,1,nil);
        Advise.FEventTime := Advise.FEventTime + Advise.FPeriod;
        ShuntHead;
      end else
      begin
        ASSERT(Advise.FPeriodic = False);
        SetEvent(Advise.FNotify);
        dec(FAdviseCount);
        Delete(FHead.RemoveNext);
      end;
      Advise := FHead.FNext;
      NextTime := Advise.FEventTime;
    end;
  finally
    FSerialize.UnLock;
  end;
  {$IFDEF _DEBUG}
    DbgLog(
      Self, 'TBCAMSchedule.Advise(Next time stamp: ' +
      inttostr((NextTime div (UNITS div MILLISECONDS))) +
      ' ms, for advise ' + inttostr(Advise.FAdviseCookie)
    );
  {$ENDIF}
  Result := NextTime;
end;

function TBCAMSchedule.GetEvent: THandle;
begin
  Result := FEvent;
end;

procedure TBCAMSchedule.DumpLinkedList;
{$IFDEF _DEBUG}
var
  i : integer;
  p : TBCAdvisePacket;
{$ENDIF}
begin
  {$IFDEF _DEBUG}
  FSerialize.Lock;
  try
    DbgLog(Self,'TBCAMSchedule.DumpLinkedList');
    i := 0;
    p := FHead;
    while True do
    begin
      if p = nil then break;
      DbgLog(
        Self, 'Advise List # ' + inttostr(i) + ', Cookie ' +
        inttostr(p.FAdviseCookie) + ',  RefTime ' +
        inttostr(p.FEventTime div (UNITS div MILLISECONDS))
      );
      inc(i);
      p := p.Next;
    end;
  finally
    FSerialize.Unlock;
  end;
  {$ENDIF}
end;

function TBCAMSchedule.AddAdvisePacket(Packet: TBCAdvisePacket): DWORD;
var
  p_prev, p_n : TBCAdvisePacket;
begin
  ASSERT((Packet.FEventTime >= 0) and (Packet.FEventTime < MAX_TIME));

  {$IFDEF _DEBUG}
  ASSERT(FSerialize.CritCheckIn);
  {$ENDIF}

  p_prev := FHead;
  inc(FNextCookie);
  Packet.FAdviseCookie := FNextCookie;
  Result := Packet.FAdviseCookie;
  // This relies on the fact that z is a sentry with a maximal m_rtEventTime

  while True do
  begin
    p_n := p_prev.FNext;
    if (p_n.FEventTime >= Packet.FEventTime) then break;
    p_prev := p_n;
  end;

  p_prev.InsertAfter(Packet);
  inc(FAdviseCount);

  {$IFDEF _DEBUG}
  DbgLog(
    Self, 'Added advise ' + inttostr(Packet.FAdviseCookie) + ', for thread ' +
    inttostr(GetCurrentThreadId) + ', scheduled at ' +
    inttostr(Packet.FEventTime div (UNITS div MILLISECONDS))
  );
  {$ENDIF}

  // If packet added at the head, then clock needs to re-evaluate wait time.
  if (p_prev = FHead) then SetEvent(FEvent);
end;

procedure TBCAMSchedule.ShuntHead;
var
  p_prev, p_n : TBCAdvisePacket;
  Packet : TBCAdvisePacket;
begin
  p_prev := FHead;
  p_n := nil;

  FSerialize.Lock;
  try
    Packet := FHead.FNext;
    // This will catch both an empty list,
    // and if somehow a MAX_TIME time gets into the list
    // (which would also break this method).
    ASSERT(Packet.FEventTime < MAX_TIME);

    // This relies on the fact that z is a sentry with a maximal m_rtEventTime
    while True do
    begin
      p_n := p_prev.FNext;
      if (p_n.FEventTime >= Packet.FEventTime) then break;
      p_prev := p_n;
    end;

    // If p_prev == pPacket then we're already in the right place
    if (p_prev <> Packet) then
    begin
      FHead.FNext := Packet.FNext;
      p_prev.FNext := Packet;
      p_prev.FNext.FNext := p_n;
    end;

  {$IFDEF _DEBUG}
  DbgLog(
    Self, 'Periodic advise ' + inttostr(Packet.FAdviseCookie) + ', shunted to ' +
    inttostr(Packet.FEventTime div (UNITS div MILLISECONDS))
  );
  {$ENDIF}

  finally
    FSerialize.Unlock;
  end;
end;

procedure TBCAMSchedule.Delete(Packet: TBCAdvisePacket);
const
  CacheMax = 5; // Don't bother caching more than five
begin
  if (FCacheCount >= CacheMax) then FreeAndNil(Packet)
  else
  begin
    FSerialize.Lock;
    try
      Packet.FNext := FAdviseCache;
      FAdviseCache := Packet;
      inc(FCacheCount);
    finally
      FSerialize.Unlock;
    end;
  end;
end;
// milenko end

// milenko start refclock implementation
function AdviseThreadFunction(p: Pointer): DWORD; stdcall;
begin
  Result := TBCBaseReferenceClock(p).AdviseThread;
end;

constructor TBCBaseReferenceClock.Create(Name: String; Unk: IUnknown; out hr: HRESULT;
  Sched: TBCAMSchedule);
var
  tc : TIMECAPS;
  ThreadID : DWORD;
begin
  inherited Create(Name,Unk);
  FLastGotTime := 0;
  FTimerResolution := 0;
  FAbort := False;
  if not Assigned(Sched)
    then FSchedule := TBCAMSchedule.Create(CreateEvent(nil,False,False,nil))
    else FSchedule := Sched;

  ASSERT(fSchedule <> nil);
  if not Assigned(FSchedule) then
  begin
    hr := E_OUTOFMEMORY;
  end else
  begin
    FLock := TBCCritSec.Create;
    // Set up the highest resolution timer we can manage
    if (timeGetDevCaps(@tc, sizeof(tc)) = TIMERR_NOERROR)
      then FTimerResolution := tc.wPeriodMin
      else FTimerResolution := 1;

    timeBeginPeriod(FTimerResolution);

    // Initialise our system times - the derived clock should set the right values 
    FPrevSystemTime := timeGetTime;
    FPrivateTime := (UNITS div MILLISECONDS) * FPrevSystemTime;

    {$IFDEF PERF}
      FGetSystemTime := MSR_REGISTER('TBCBaseReferenceClock.GetTime');
    {$ENDIF}

    if not Assigned(Sched) then
	  begin
	    FThread := CreateThread(nil,                      // Security attributes
				                        0,                      // Initial stack size
				                        @AdviseThreadFunction,  // Thread start address
                                Self,                   // Thread parameter
                                0,                      // Creation flags
                                ThreadID);              // Thread identifier

	    if (FThread > 0) then
      begin
        SetThreadPriority(FThread, THREAD_PRIORITY_TIME_CRITICAL);
	    end else
	    begin
        hr := E_FAIL;
        CloseHandle(FSchedule.GetEvent);
        FreeAndNil(FSchedule);
	    end;
    end;
	end;
end;

destructor TBCBaseReferenceClock.Destroy;
begin
  if (FTimerResolution > 0) then
  begin
    timeEndPeriod(FTimerResolution);
    FTimerResolution := 0;
  end;

  FSchedule.DumpLinkedList;

  if (FThread > 0) then
  begin
    FAbort := True;
    TriggerThread;
    WaitForSingleObject(FThread, INFINITE);
    CloseHandle(FSchedule.GetEvent);
    FreeAndNil(FSchedule);
  end;

  if Assigned(FLock) then FreeAndNil(FLock);

  inherited Destroy;
end;

function TBCBaseReferenceClock.AdviseThread: HRESULT;
var
  dwWait : DWORD;
  rtNow  : TReferenceTime;
  llWait : LONGLONG;
begin
  dwWait := INFINITE;

  // The first thing we do is wait until something interesting happens
  // (meaning a first advise or shutdown).  This prevents us calling
  // GetPrivateTime immediately which is goodness as that is a virtual
  // routine and the derived class may not yet be constructed.  (This
  // thread is created in the base class constructor.)

  while not FAbort do
  begin
    // Wait for an interesting event to happen
    {$IFDEF _DEBUG}
    DbgLog(Self,'AdviseThread Delay: ' + inttostr(dwWait) + ' ms');
    {$ENDIF}

    WaitForSingleObject(FSchedule.GetEvent, dwWait);
    if FAbort then break;

    // There are several reasons why we need to work from the internal
    // time, mainly to do with what happens when time goes backwards.
    // Mainly, it stop us looping madly if an event is just about to
    // expire when the clock goes backward (i.e. GetTime stop for a
    // while).
    rtNow := GetPrivateTime;

    {$IFDEF _DEBUG}
    DbgLog(
      Self,'AdviseThread Woke at = ' + inttostr(RefTimeToMiliSec(rtNow)) + ' ms'
    );
    {$ENDIF}

    // We must add in a millisecond, since this is the resolution of our
    // WaitForSingleObject timer.  Failure to do so will cause us to loop
    // franticly for (approx) 1 a millisecond.
    FNextAdvise := FSchedule.Advise(10000 + rtNow);
    llWait := FNextAdvise - rtNow;

    ASSERT(llWait > 0);

    llWait := RefTimeToMiliSec(llWait);
    // DON'T replace this with a max!! (The type's of these things is VERY important)
    if (llWait > REFERENCE_TIME(HIGH(DWORD))) then dwWait := HIGH(DWORD)
                                              else dwWait := DWORD(llWait)
  end;
  Result := NOERROR;
end;

function TBCBaseReferenceClock.NonDelegatingQueryInterface(const IID: TGUID;
  out Obj): HResult; stdcall;
begin
  if (IsEqualGUID(IID,IID_IReferenceClock)) then
  begin
    if GetInterface(IID,Obj) then Result := S_OK
                             else Result := E_NOINTERFACE;
  end
  else
    Result := inherited NonDelegatingQueryInterface(IID, Obj);
end;

function TBCBaseReferenceClock.GetTime(out Time: int64): HResult; stdcall;
var
  Now_ : TReferenceTime;
begin
  if Assigned(@Time) then
  begin
    FLock.Lock;
    try
      Now_ := GetPrivateTime;
      if (Now_ > FLastGotTime) then
      begin
        FLastGotTime := Now_;
        Result := S_OK;
      end else
      begin
        Result := S_FALSE;
      end;

      Time := FLastGotTime;
    finally
      FLock.UnLock;
    end;
    {$IFDEF PERF}
    MSR_INTEGER(FGetSystemTime, Time div (UNITS div MILLISECONDS));
    {$ENDIF}
  end else Result := E_POINTER;
end;

function TBCBaseReferenceClock.AdviseTime(BaseTime, StreamTime: int64;
  Event: THandle; out AdviseCookie: DWORD): HResult; stdcall;
var
  RefTime : TReferenceTime;
begin
  if @AdviseCookie = nil then
  begin
    Result := E_POINTER;
    Exit;
  end;
  AdviseCookie := 0;

  // Check that the event is not already set
{$IFOPT C+}
  ASSERT(WAIT_TIMEOUT = WaitForSingleObject(Event,0));
{$ELSE}
  WaitForSingleObject(Event,0);
{$ENDIF}

  RefTime := BaseTime + StreamTime;
  if ((RefTime <= 0) or (RefTime = MAX_TIME)) then
  begin
    Result := E_INVALIDARG;
  end else
  begin
    AdviseCookie := FSchedule.AddAdvisePacket(RefTime, 0, Event, False);
    if AdviseCookie > 0 then Result := NOERROR
                        else Result := E_OUTOFMEMORY;
  end;
end;

function TBCBaseReferenceClock.AdvisePeriodic(const StartTime, PeriodTime: int64;
  Semaphore: THandle; out AdviseCookie: DWORD): HResult; stdcall;
begin
  if @AdviseCookie = nil then
  begin
    Result := E_POINTER;
    Exit;
  end;

  AdviseCookie := 0;

  if ((StartTime > 0) and (PeriodTime > 0) and (StartTime <> MAX_TIME)) then
  begin
    AdviseCookie := FSchedule.AddAdvisePacket(StartTime,PeriodTime,Semaphore,True);
    if AdviseCookie > 0 then Result := NOERROR
                        else Result := E_OUTOFMEMORY;
  end
    else Result := E_INVALIDARG;
end;

function TBCBaseReferenceClock.Unadvise(AdviseCookie: DWORD): HResult; stdcall;
begin
  Result := FSchedule.Unadvise(AdviseCookie);
end;

function TBCBaseReferenceClock.GetPrivateTime: TReferenceTime;
var
  Time_ : DWORD;
begin
  FLock.Lock;
  try
    (* If the clock has wrapped then the current time will be less than
     * the last time we were notified so add on the extra milliseconds
     *
     * The time period is long enough so that the likelihood of
     * successive calls spanning the clock cycle is not considered.
     *)

    Time_ := timeGetTime;
    FPrivateTime := FPrivateTime + Int32x32To64(UNITS div MILLISECONDS, DWORD(Time_ - FPrevSystemTime));
    FPrevSystemTime := Time_;
  finally
    FLock.UnLock;
  end;

  Result := FPrivateTime;
end;

function TBCBaseReferenceClock.SetTimeDelta(const TimeDelta: TReferenceTime): HRESULT; stdcall;
{$IFDEF _DEBUG}
var
  llDelta : LONGLONG;
  usDelta : Longint;
  delta : DWORD;
  Severity : integer;
{$ENDIF}
begin
{$IFDEF _DEBUG}
  // Just break if passed an improper time delta value
  if TimeDelta > 0 then llDelta := TimeDelta
                   else llDelta := -TimeDelta;

  if (llDelta > UNITS * 1000) then
  begin
    DbgLog(Self,'Bad Time Delta');
    // DebugBreak;
  end;

  // We're going to calculate a "severity" for the time change. Max -1
  // min 8.  We'll then use this as the debug logging level for a
  // debug log message.
  usDelta := Longint(TimeDelta div 10);      // Delta in micro-secs

  delta := abs(usDelta);            // varying delta

  // Severity == 8 - ceil(log<base 8>(abs( micro-secs delta)))
  Severity := 8;
  while (delta > 0) do
  begin
    delta := delta shr 3;  // div 8
    dec(Severity);
  end;

  // Sev == 0 => > 2 second delta!
  DbgLog(
    Self, 'Sev ' + inttostr(Severity) + ': CSystemClock::SetTimeDelta(' +
    inttostr(usDelta) + ' us) ' + inttostr(RefTimeToMiliSec(FPrivateTime)) +
    ' -> ' + inttostr(RefTimeToMiliSec(TimeDelta + FPrivateTime)) + ' ms'
  );
{$ENDIF}

  FLock.Lock;
  try
    FPrivateTime := FPrivateTime + TimeDelta;
    // If time goes forwards, and we have advises, then we need to
    // trigger the thread so that it can re-evaluate its wait time.
    // Since we don't want the cost of the thread switches if the change
    // is really small, only do it if clock goes forward by more than
    // 0.5 millisecond.  If the time goes backwards, the thread will
    // wake up "early" (relativly speaking) and will re-evaluate at
    // that time.
    if ((TimeDelta > 5000) and (FSchedule.GetAdviseCount > 0)) then TriggerThread;
  finally
    FLock.UnLock;
  end;
  Result := NOERROR;
end;

function TBCBaseReferenceClock.GetSchedule : TBCAMSchedule;
begin
  Result := FSchedule;
end;

procedure TBCBaseReferenceClock.TriggerThread;
begin
{$IFDEF _DEBUG}
  DbgLog(Self,'TriggerThread : ' + inttostr(FSchedule.GetEvent));
{$ENDIF}
  SetEvent(FSchedule.GetEvent);
end;
// milenko end

// milenko start sysclock implementation
constructor TBCSystemClock.Create(Name: WideString; Unk : IUnknown; out hr : HRESULT);
begin
  inherited Create(Name,Unk,hr);
end;

function TBCSystemClock.NonDelegatingQueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if IsEqualGUID(IID,IID_IPersist) then
  begin
    if GetInterface(IID,Obj) then Result := S_OK
                             else Result := E_NOINTERFACE;
  end else
  if IsEqualGUID(IID,IID_IAMClockAdjust) then
  begin
    if GetInterface(IID,Obj) then Result := S_OK
                             else Result := E_NOINTERFACE;
  end
  else Result := inherited NonDelegatingQueryInterface(IID,Obj);
end;

function TBCSystemClock.GetClassID(out classID: TCLSID): HResult; stdcall;
begin
  if not Assigned(@ClassID) then
  begin
    Result := E_POINTER;
    Exit;
  end;
  classID := CLSID_SystemClock;
  Result := NOERROR;
end;

function TBCSystemClock.SetClockDelta(rtDelta: TReferenceTime): HResult; stdcall;
begin
  Result := SetTimeDelta(rtDelta);
end;
// milenko end

{ TBCMediaSample }

//=====================================================================
//=====================================================================
// Memory allocation class, implements TBCMediaSample
//=====================================================================
//=====================================================================


(* NOTE The implementation of this class calls the CUnknown constructor with
   a NULL outer unknown pointer. This has the effect of making us a self
   contained class, ie any QueryInterface, AddRef or Release calls will be
   routed to the class's NonDelegatingUnknown methods. You will typically
   find that the classes that do this then override one or more of these
   virtual functions to provide more specialised behaviour. A good example
   of this is where a class wants to keep the QueryInterface internal but
   still wants it's lifetime controlled by the external object *)

function TBCMediaSample._AddRef: Integer;
begin
  Result := InterlockedIncrement(FRef);
end;

function TBCMediaSample._Release: Integer;
var
  lRef: integer;
  aSample: IMediaSample;
begin
  // Decrement our own private reference count
  if (FRef = 1) then
  begin
    lRef := 0;
    FRef := 0;
  end else
  begin
    lRef := InterlockedDecrement(FRef);
  end;

  ASSERT(lRef >= 0);

  {$IFDEF _DEBUG}
  DbgLog('Unknown ' + inttohex(integer(self), 8) + ' ref-- = ' + inttostr(FRef));
  {$ENDIF}

  // Did we release our final reference count
  if (lRef = 0) then
  begin
    // Free all resources
    if LongBool(FFlags and Sample_TypeChanged)
      then SetMediaType(nil);

    ASSERT(FMediaType = nil);

    FFlags := 0;
    FTypeSpecificFlags := 0;
    FStreamId := AM_STREAM_MEDIA;

    // This may cause us to be deleted
    // Our refcount is reliably 0 thus no-one will mess with us
    QueryInterface(IID_IMediaSample, aSample); // be nice to our D5 friends :)
    FAllocator.ReleaseBuffer(aSample);
    aSample := nil;
  end;

  Result := lRef;
end;

function TBCMediaSample.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if (IsEqualIID(IID, IID_IMediaSample) or IsEqualIID(IID, IID_IMediaSample2) or
      IsEqualIID(IID, IID_IUnknown)) and GetInterface(IID_IMediaSample2, Obj)
    then Result := NOERROR
    else Result := E_NOINTERFACE;
end;

(* The last two parameters have default values of NULL and zero *)

constructor TBCMediaSample.Create(pName: WideString; pAllocator: TBCBaseAllocator;
  out phr: HRESULT; pBuffer: PBYTE; _length: integer);
begin
  inherited Create; //(pName, nil);

  FBuffer := pBuffer;             // Initialise the buffer
  FBufferSize := _length;            // And it's length
  FActual := _length;             // By default, actual = length
  FMediaType := nil;              // No media type change
  FFlags := 0;                   // Nothing set
  FRef := 0;                      // 0 ref count
  FTypeSpecificFlags := 0;       // Type specific flags
  FStreamId := AM_STREAM_MEDIA;  // Stream id
  FAllocator := pAllocator;       // Allocator

  (* We must have an owner and it must also be derived from class
     TBCBaseAllocator BUT we do not hold a reference count on it *)
  ASSERT(pAllocator <> nil);
end;

(* Destructor deletes the media type memory *)
destructor TBCMediaSample.Destroy;
begin
  if (FMediaType <> nil)
    then DeleteMediaType(FMediaType);

  inherited Destroy;
end;

function TBCMediaSample.GetActualDataLength: Longint;
begin
  Result := FActual;
end;

// get the media times (eg bytes) for this sample
function TBCMediaSample.GetMediaTime(out pTimeStart, pTimeEnd: int64): HResult;
begin
  // CHB: Debug only...
  //ValidateReadWritePtr(pTimeStart,sizeof(LONGLONG));
  //ValidateReadWritePtr(pTimeEnd,sizeof(LONGLONG));

  if (not LongBool(FFlags and Sample_MediaTimeValid)) then
  begin
    Result := VFW_E_MEDIA_TIME_NOT_SET;
  end else
  begin
    pTimeStart := FMediaStart;
    pTimeEnd := FMediaStart + FMediaEnd;
    Result := NOERROR;
  end;
end;

(* These allow for limited format changes in band *)
function TBCMediaSample.GetMediaType(out ppMediaType: PAMMediaType): HResult;
begin
  //ValidateReadWritePtr(ppMediaType,sizeof(AM_MEDIA_TYPE *));
  ASSERT(@ppMediaType <> nil);

  (* Do we have a new media type for them *)

  if (not LongBool(FFlags and Sample_TypeChanged)) then
  begin
    ASSERT(FMediaType = nil);
    ppMediaType := nil;
    Result := S_FALSE;
    Exit;
  end;

  ASSERT(FMediaType <> nil);

  (* Create a copy of our media type *)

  ppMediaType := CreateMediaType(FMediaType);
  if (ppMediaType = nil)
    then Result := E_OUTOFMEMORY
    else Result := NOERROR;
end;

// get me a read/write pointer to this buffer's memory. I will actually
// want to use sizeUsed bytes.
function TBCMediaSample.GetPointer(out ppBuffer: PBYTE): HResult;
begin
  //ValidateReadWritePtr(ppBuffer,sizeof(BYTE *));

  // creator must have set pointer either during
  // constructor or by SetPointer
  ASSERT(FBuffer <> nil);

  ppBuffer := FBuffer;
  Result := NOERROR;
end;

// Set and get properties (IMediaSample2)
function TBCMediaSample.GetProperties(cbProperties: DWORD; out pbProperties): HResult;
var
  Props: AM_SAMPLE2_PROPERTIES;
begin
  if (0 <> cbProperties) then
  begin
    if (@pbProperties = nil) then
    begin
      Result := E_POINTER;
      Exit;
    end;
    //  Return generic stuff up to the length
    Props.cbData     := DWORD(min(cbProperties, sizeof(Props)));
    Props.dwSampleFlags := FFlags and (not Sample_MediaTimeValid);
    Props.dwTypeSpecificFlags := FTypeSpecificFlags;
    Props.pbBuffer   := FBuffer;
    Props.cbBuffer   := FBufferSize;
    Props.lActual    := FActual;
    Props.tStart     := FStart;
    Props.tStop      := FEnd;
    Props.dwStreamId := FStreamId;
    if (LongBool(FFlags and AM_SAMPLE_TYPECHANGED))
      then Props.pMediaType := FMediaType
      else Props.pMediaType := nil;

    CopyMemory(@pbProperties, @Props, Props.cbData);
  end;
  Result := S_OK;
end;

// return the size in bytes of this buffer
function TBCMediaSample.GetSize: Longint;
begin
  Result := FBufferSize;
end;

// get the stream time at which this sample should start and finish.
function TBCMediaSample.GetTime(out pTimeStart,
  pTimeEnd: TReferenceTime): HResult;
begin
  //ValidateReadWritePtr(pTimeStart,sizeof(REFERENCE_TIME));
  //ValidateReadWritePtr(pTimeEnd,sizeof(REFERENCE_TIME));

  if (not LongBool(FFlags and Sample_StopValid)) then
  begin
    if (not LongBool(FFlags and Sample_TimeValid)) then
    begin
      Result := VFW_E_SAMPLE_TIME_NOT_SET;
      Exit;
    end else
    begin
      pTimeStart := FStart;

      //  Make sure old stuff works
      pTimeEnd := FStart + 1;
      Result := VFW_S_NO_STOP_TIME;
      Exit;
    end;
  end;

  pTimeStart := FStart;
  pTimeEnd := FEnd;
  Result := NOERROR;
end;

// returns S_OK if there is a discontinuity in the data (this same is
// not a continuation of the previous stream of data
// - there has been a seek).
function TBCMediaSample.IsDiscontinuity: HResult;
begin
  if (LongBool(FFlags and Sample_Discontinuity))
    then Result := S_OK
    else Result := S_FALSE;
end;

function TBCMediaSample.IsPreroll: HResult;
begin
  if (LongBool(FFlags and Sample_Preroll))
    then Result := S_OK
    else Result := S_FALSE;
end;

function TBCMediaSample.IsSyncPoint: HResult;
begin
  if (LongBool(FFlags and Sample_SyncPoint))
    then Result := S_OK
    else Result := S_FALSE;
end;

function TBCMediaSample.SetActualDataLength(lLen: Integer): HResult;
begin
  if (lLen > FBufferSize) then
  begin
    ASSERT(lLen <= GetSize);
    Result := VFW_E_BUFFER_OVERFLOW;
  end else
  begin
    FActual := lLen;
    Result := NOERROR;
  end;
end;

// set the discontinuity property - TRUE if this sample is not a
// continuation, but a new sample after a seek.
function TBCMediaSample.SetDiscontinuity(bDiscontinuity: BOOL): HResult;
begin
  // should be TRUE or FALSE
  if (bDiscontinuity)
    then FFlags := FFlags or Sample_Discontinuity
    else FFlags := FFlags and (not Sample_Discontinuity);
  Result:=S_OK;
end;

// Set the media times for this sample
function TBCMediaSample.SetMediaTime(pTimeStart, pTimeEnd: Pint64): HResult;
begin
  if (pTimeStart = nil) then
  begin
    ASSERT(pTimeEnd = nil);
    FFlags := (FFlags and (not Sample_MediaTimeValid));
  end else
  begin
    //ValidateReadPtr(pTimeStart,sizeof(LONGLONG));
    //ValidateReadPtr(pTimeEnd,sizeof(LONGLONG));
    ASSERT(pTimeEnd <> nil);
    ASSERT(pTimeEnd^ >= pTimeStart^);

    FMediaStart := pTimeStart^;
    FMediaEnd :=integer(pTimeEnd^ - pTimeStart^);
    FFlags := FFlags or Sample_MediaTimeValid;
  end;

  Result := NOERROR;
end;

(* Mark this sample as having a different format type *)
function TBCMediaSample.SetMediaType(pMediaType: PAMMediaType): HResult;
begin
  (* Delete the current media type *)

  if (FMediaType <> nil) then
  begin
    DeleteMediaType(FMediaType);
    FMediaType := nil;
  end;

  (* Mechanism for resetting the format type *)

  if (pMediaType = nil) then
  begin
    FFlags := FFlags and (not Sample_TypeChanged);
    Result := NOERROR;
    Exit;
  end;

  ASSERT(pMediaType <> nil);
  //ValidateReadPtr(pMediaType,sizeof(AM_MEDIA_TYPE));

  //Take a copy of the media type

  FMediaType := CreateMediaType(pMediaType);
  if (FMediaType = nil) then
  begin
    FFlags := FFlags and (not Sample_TypeChanged);
    Result := E_OUTOFMEMORY;
    Exit;
  end;

  FFlags := FFlags or Sample_TypeChanged;
  Result := NOERROR;
end;

// set the buffer pointer and length. Used by allocators that
// want variable sized pointers or pointers into already-read data.
// This is only available through a TBCMediaSample* not an IMediaSample*
// and so cannot be changed by clients.
function TBCMediaSample.SetPointer(ptr: PBYTE; cBytes: integer): HRESULT;
begin
  FBuffer := ptr;            // new buffer area (could be null)
  FBufferSize := cBytes;        // length of buffer
  FActual := cBytes;         // length of data in buffer (assume full)

  Result:=S_OK;
end;

function TBCMediaSample.SetPreroll(bIsPreroll: BOOL): HResult;
begin
  if (bIsPreroll)
    then FFlags := FFlags or Sample_Preroll
    else FFlags := FFlags and (not Sample_Preroll);

  Result:=NOERROR;
end;                    

function TBCMediaSample.SetProperties(cbProperties: DWORD; const pbProperties): HResult;

  function CONTAINS_FIELD(field: Integer; size: Cardinal): Boolean;
  var
    prop: AM_SAMPLE2_PROPERTIES;
  begin
    Result := False;
    case field of
      0: Result := Cardinal(@prop.cbData) - Cardinal(@prop) + SizeOf(prop.cbData) <= size;
      1: Result := Cardinal(@prop.dwTypeSpecificFlags) - Cardinal(@prop) + SizeOf(prop.dwTypeSpecificFlags) <= size;
      2: Result := Cardinal(@prop.dwSampleFlags) - Cardinal(@prop) + SizeOf(prop.dwSampleFlags) <= size;
      3: Result := Cardinal(@prop.lActual) - Cardinal(@prop) + SizeOf(prop.lActual) <= size;
      4: Result := Cardinal(@prop.tStart) - Cardinal(@prop) + SizeOf(prop.tStart) <= size;
      5: Result := Cardinal(@prop.tStop) - Cardinal(@prop) + SizeOf(prop.tStop) <= size;
      6: Result := Cardinal(@prop.dwStreamId) - Cardinal(@prop) + SizeOf(prop.dwStreamId) <= size;
      7: Result := Cardinal(@prop.pMediaType) - Cardinal(@prop) + SizeOf(prop.pMediaType) <= size;
      8: Result := Cardinal(@prop.pbBuffer) - Cardinal(@prop) + SizeOf(prop.pbBuffer) <= size;
      9: Result := Cardinal(@prop.cbBuffer) - Cardinal(@prop) + SizeOf(prop.cbBuffer) <= size;
    end;
  end;

var
  pMediaType: PAMMediaType;
  pProps: AM_SAMPLE2_PROPERTIES;
begin
  // Generic properties
  pMediaType := nil;

  if (CONTAINS_FIELD(0, cbProperties)) then
  begin
    // CheckPointer(pbProperties, E_POINTER);
    pProps := AM_SAMPLE2_PROPERTIES(pbProperties);

    // Don't use more data than is actually there
    if (pProps.cbData < cbProperties)
      then cbProperties := pProps.cbData;

    //  We only handle IMediaSample2
    if ((cbProperties > sizeof(pProps)) or (pProps.cbData > sizeof(pProps))) then
    begin
      Result := E_INVALIDARG;
      Exit;
    end;

    //  Do checks first, the assignments (for backout)
    if (CONTAINS_FIELD(2, cbProperties)) then
    begin
      // Check the flags
      if (LongBool(pProps.dwSampleFlags and (not Sample_ValidFlags or Sample_MediaTimeValid))) then
      begin
        Result := E_INVALIDARG;
        Exit;
      end;

      // Check a flag isn't being set for a property not being provided
      if (LongBool(pProps.dwSampleFlags and AM_SAMPLE_TIMEVALID) and not
          LongBool(FFlags and AM_SAMPLE_TIMEVALID) and not
          CONTAINS_FIELD(5, cbProperties)) then
      begin
        Result := E_INVALIDARG;
        Exit;
      end;
    end;

    // NB - can't SET the pointer or size
    if (CONTAINS_FIELD(8, cbProperties)) then
    begin
      // Check pbBuffer
      if (Assigned(pProps.pbBuffer) and (pProps.pbBuffer <> FBuffer)) then
      begin
        Result := E_INVALIDARG;
        Exit;
      end;
    end;

    if (CONTAINS_FIELD(9, cbProperties)) then
    begin
      // Check cbBuffer
      if ((pProps.cbBuffer <> 0) and (pProps.cbBuffer <> FBufferSize)) then
      begin
        Result := E_INVALIDARG;
        Exit;
      end;
    end;

    if (CONTAINS_FIELD(9, cbProperties) and
        CONTAINS_FIELD(3, cbProperties)) then
    begin
      //  Check lActual
      if (pProps.cbBuffer < pProps.lActual) then
      begin
        Result := E_INVALIDARG;
        Exit;
      end;
    end;

    if (CONTAINS_FIELD(7, cbProperties)) then
    begin
      //  Check pMediaType
      if LongBool(pProps.dwSampleFlags and AM_SAMPLE_TYPECHANGED) then
      begin
        // CheckPointer(pProps->pMediaType, E_POINTER);
        pMediaType := CreateMediaType(pProps.pMediaType);
        if (pMediaType = nil) then
        begin
          Result := E_OUTOFMEMORY;
          Exit;
        end;
      end;
    end;

    // Now do the assignments
    if (CONTAINS_FIELD(6, cbProperties))
        then FStreamId := pProps.dwStreamId;

    if (CONTAINS_FIELD(2, cbProperties)) then
    begin
      // Set the flags
      FFlags := pProps.dwSampleFlags or (FFlags and Sample_MediaTimeValid);
      FTypeSpecificFlags := pProps.dwTypeSpecificFlags;
    end else
    begin
      if (CONTAINS_FIELD(1, cbProperties))
        then FTypeSpecificFlags := pProps.dwTypeSpecificFlags;
    end;

    if (CONTAINS_FIELD(3, cbProperties))
      then FActual := pProps.lActual; // Set lActual

    if (CONTAINS_FIELD(5, cbProperties))
      then FEnd := pProps.tStop; // Set the times

    if (CONTAINS_FIELD(4, cbProperties))
      then FStart := pProps.tStart; // Set the times

    if (CONTAINS_FIELD(7, cbProperties)) then
    begin
      // Set pMediaType
      if LongBool(pProps.dwSampleFlags and AM_SAMPLE_TYPECHANGED) then
      begin
        if (FMediaType <> nil)
          then DeleteMediaType(FMediaType);
        FMediaType := pMediaType;
      end;
    end;

    // Fix up the type changed flag to correctly reflect the current state
    // If, for instance the input contained no type change but the
    // output does then if we don't do this we'd lose the
    // output media type.

    if Assigned(FMediaType)
      then FFlags := FFlags or Sample_TypeChanged
      else FFlags := FFlags and not Sample_TypeChanged;

  end;

  Result := S_OK;
end;

function TBCMediaSample.SetSyncPoint(bIsSyncPoint: BOOL): HResult;
begin
  if (bIsSyncPoint)
    then FFlags := FFlags or Sample_SyncPoint
    else FFlags := FFlags and (not Sample_SyncPoint);
  Result:=NOERROR;
end;

// Set the stream time at which this sample should start and finish.
// NULL pointers means the time is reset
function TBCMediaSample.SetTime(pTimeStart, pTimeEnd: PReferenceTime): HResult;
begin
  if (pTimeStart = nil) then
  begin
    ASSERT(pTimeEnd = nil);
    FFlags := FFlags and (not (Sample_TimeValid or Sample_StopValid));
  end else
  begin
    if (pTimeEnd = nil) then
    begin
      FStart := pTimeStart^;
      FFlags := FFlags or Sample_TimeValid;
      FFlags := FFlags and (not Sample_StopValid);
    end else
    begin
      //ValidateReadPtr(pTimeStart,sizeof(REFERENCE_TIME));
      //ValidateReadPtr(pTimeEnd,sizeof(REFERENCE_TIME));
      ASSERT(pTimeEnd^ >= pTimeStart^);

      FStart := pTimeStart^;
      FEnd := pTimeEnd^;
      FFlags := FFlags or (Sample_TimeValid or Sample_StopValid);
    end;
  end;
  Result := NOERROR;
end;

{ TBCSampleList }

procedure TBCSampleList.Add(pSample: TBCMediaSample);
begin
  ASSERT(pSample <> nil);
  TBCBaseAllocator.NextSample(pSample)^ := FList;
  pointer(FList) := pSample;
  inc(FOnList);
end;

constructor TBCSampleList.Create;
begin
  inherited Create;
  FList := nil;
  FOnList := 0;
end;

{$ifdef _DEBUG}
destructor TBCSampleList.Destroy;
begin
  ASSERT(FOnList = 0);
  inherited Destroy;
end;
{$endif}

function TBCSampleList.GetCount: integer;
begin
  Result := FOnList;
end;

function TBCSampleList.Head: TBCMediaSample;
begin
  pointer(Result) := FList;
end;

function TBCSampleList.Next(pSample: TBCMediaSample): TBCMediaSample;
begin
  if (pSample <> nil)
    then pointer(Result) := pSample.FNext
    else Result := nil;//TBCBaseAllocator.NextSample(pSample)^;
end;

(*  Implement TBCBaseAllocator::TBCSampleList::Remove(pSample)
    Removes pSample from the list
*)
procedure TBCSampleList.Remove(pSample: TBCMediaSample);
var
  pSearch: PBCMediaSample;
begin
  pSearch := @FList;

  while (pSearch^ <> nil) do
  begin
    if (pSearch^ = pSample) then
    begin
      pointer(pSearch) := @pSample.FNext;//TBCBaseAllocator.NextSample(pSample);
      pointer(pSample.FNext) := nil;//TBCBaseAllocator.NextSample(pSample)^:=nil;
      dec(FOnList);
      Exit;
    end;

    pSearch := TBCBaseAllocator.NextSample(pSearch^);
  end;
  //DbgBreak("Couldn't find sample in list");
end;

function TBCSampleList.RemoveHead: TBCMediaSample;
begin
  pointer(Result) := FList;
  if (FList <> nil) then
  begin
    pointer(FList) := FList.FNext;//TBCBaseAllocator.NextSample(m_List)^;
    dec(FOnList);
  end;
end;

{ TBCBaseAllocator }

//=====================================================================
//=====================================================================
// Implements TBCBaseAllocator
//=====================================================================
//=====================================================================


(* Base definition of allocation which checks we are ok to go ahead and do
   the full allocation. We return S_FALSE if the requirements are the same *)
function TBCBaseAllocator.Alloc: HRESULT;
begin
  (* Error if he hasn't set the size yet *)
  if (FCount <= 0) or (FSize <= 0) or (FAlignment <= 0) then
  begin
    Result := VFW_E_SIZENOTSET;
    Exit;
  end;

  (* should never get here while buffers outstanding *)
  ASSERT(FFree.GetCount = FAllocated);

  (* If the requirements haven't changed then don't reallocate *)
  if (not FChanged)
    then Result := S_FALSE
    else Result := NOERROR;
end;

function TBCBaseAllocator.Commit: HResult;
begin
  (* Check we are not decommitted *)
  //CAutoLock cObjectLock(this);
  Lock;
  try

    // cannot need to alloc or re-alloc if we are committed
    if (FCommitted) then
    begin
      Result := NOERROR;
      Exit;
    end;

    (* Allow GetBuffer calls *)

    FCommitted := TRUE;

    // is there a pending decommit ? if so, just cancel it
    if (FDecommitInProgress) then
    begin
      FDecommitInProgress := FALSE;

      // don't call Alloc at this point. He cannot allow SetProperties
      // between Decommit and the last free, so the buffer size cannot have
      // changed. And because some of the buffers are not free yet, he
      // cannot re-alloc anyway.
      Result := NOERROR;
      Exit;
    end;
    {$IFDEF _DEBUG}
    DbgLog('Allocating: ' + inttostr(FCount) + 'x' + inttostr(FSize));
    {$ENDIF}

    // actually need to allocate the samples
    Result := Alloc;
    if (FAILED(Result)) then
    begin
      FCommitted := FALSE;
      Exit;
    end;
    _AddRef;
    Result := NOERROR;
  finally
    UnLock;
  end;
end;

(* Constructor overrides the default settings for the free list to request
   that it be alertable (ie the list can be cast to a handle which can be
   passed to WaitForSingleObject). Both of the allocator lists also ask for
   object locking, the all list matches the object default settings but I
   have included them here just so it is obvious what kind of list it is *)
constructor TBCBaseAllocator.Create(pName: WideString; pUnk: IInterface;
  out phr: HRESULT; bEvent, EnableReleaseCallback: BOOL);
begin
  //CUnknown(pName, pUnk),
  inherited Create(pName, pUnk);

  FAllocatorLock := TBCCritSec.Create;

  FAllocated := 0;
  FChanged := FALSE;
  FCommitted := FALSE;
  FDecommitInProgress := FALSE;
  FSize := 0;
  FCount := 0;
  FAlignment := 0;
  FPrefix := 0;
  FSem := 0;
  FWaiting := 0;
  FEnableReleaseCallback := EnableReleaseCallback;
  FNotify := nil;
  phr := NOERROR;

  FFree := TBCSampleList.Create;

  if (bEvent) then
  begin
    FSem := CreateSemaphore(nil, 0, $7FFFFFFF, nil);
    if (FSem = 0)
      then phr := E_OUTOFMEMORY;
  end;
end;

function TBCBaseAllocator.CritCheckIn: boolean;
begin
  Result := FAllocatorLock.CritCheckIn;
end;

function TBCBaseAllocator.CritCheckOut: boolean;
begin
  Result := FAllocatorLock.CritCheckOut;
end;

function TBCBaseAllocator.Decommit: HResult;
var
  bRelease: BOOL;
begin
  bRelease := FALSE;

  {$IFNDEF COMPILER8_UP}
  Result := E_UNEXPECTED; // Delphi 7 and below -> undefined return value fix ...
  {$ENDIF}

  Lock;
  try
    (* Check we are not already decommitted *)
    //CAutoLock cObjectLock(this);
    if (not FCommitted) then
    begin
      if (not FDecommitInProgress) then
      begin
        Result := NOERROR;
        Exit;
      end;
    end;

    (* No more GetBuffer calls will succeed *)
    FCommitted := FALSE;

    // are any buffers outstanding?
    if (FFree.GetCount < FAllocated) then
    begin
      // please complete the decommit when last buffer is freed
      FDecommitInProgress := TRUE;
    end else
    begin
      FDecommitInProgress := FALSE;

      // need to complete the decommit here as there are no
      // outstanding buffers

      _Free;
      bRelease := TRUE;
    end;

    // Tell anyone waiting that they can go now so we can
    // reject their call
    NotifySample;
  finally
    Unlock;
  end;

  if (bRelease)
    then _Release;

  Result := NOERROR;
end;

destructor TBCBaseAllocator.Destroy;
begin
  // we can't call Decommit here since that would mean a call to a
  // pure virtual in destructor.
  // We must assume that the derived class has gone into decommit state in
  // its destructor.

  ASSERT(not FCommitted);
  if (FSem <> 0)
    then CloseHandle(FSem);

  FNotify := nil;

  FreeAndNil(FFree);
  FreeAndNil(FAllocatorLock);

  inherited Destroy;
end;

// get container for a sample. Blocking, synchronous call to get the
// next free buffer (as represented by an IMediaSample interface).
// on return, the time etc properties will be invalid, but the buffer
// pointer and size will be correct.
function TBCBaseAllocator.GetBuffer(out ppBuffer: IMediaSample; pStartTime,
  pEndTime: PReferenceTime; dwFlags: DWORD): HResult;
var
  pSample: TBCMediaSample;
begin
  //UNREFERENCED_PARAMETER(pStartTime);
  //UNREFERENCED_PARAMETER(pEndTime);
  //UNREFERENCED_PARAMETER(dwFlags);
  //TBCMediaSample *pSample;
  pSample := nil;
  ppBuffer:=nil;
  {$IFNDEF COMPILER8_UP}
  Result := E_UNEXPECTED; // Delphi 7 and below -> undefined return value fix ...
  {$ENDIF}

  while true do
  begin
    // scope for lock
    //CAutoLock cObjectLock(this);
    Lock;
    try
      (* Check we are committed *)
      if (not FCommitted) then
      begin
        Result := VFW_E_NOT_COMMITTED;
        Exit;
      end;
      pointer(pSample) := FFree.RemoveHead;
      if (pSample = nil)
        then SetWaiting;
    finally
      UnLock;
    end;

    (* If we didn't get a sample then wait for the list to signal *)

    if (pSample <> nil)
      then break;

    if (LongBool(dwFlags and AM_GBF_NOWAIT)) then
    begin
      Result := VFW_E_TIMEOUT;
      Exit;
    end;
    ASSERT(FSem <> 0);
    WaitForSingleObject(FSem, INFINITE);
  end;

  (* Addref the buffer up to one. On release
     back to zero instead of being deleted, it will requeue itself by
     calling the ReleaseBuffer member function. NOTE the owner of a
     media sample must always be derived from TBCBaseAllocator *)
  if Assigned(pSample) then
  begin
    ASSERT(pSample.FRef <= 0);
    pSample.QueryInterface(IID_IMediaSample, ppBuffer); // Delphi 5 compatibility
    pSample.FRef := 1;
    pointer(pSample) := nil;
  end;
  Result := NOERROR;
end;

function TBCBaseAllocator.GetFreeCount(out plBuffersFree: Integer): HResult;
begin
  ASSERT(FEnableReleaseCallback);
  //CAutoLock cObjectLock(this);
  Lock;
  try
    plBuffersFree := FCount - FAllocated + FFree.GetCount;
    Result := NOERROR;
  finally
    Unlock;
  end;
end;

function TBCBaseAllocator.GetProperties(
  out pProps: TAllocatorProperties): HResult;
begin
  if (@pProps = nil) then
  begin
    Result := E_POINTER;
    Exit;
  end;
  //ValidateReadWritePtr(pActual,sizeof(ALLOCATOR_PROPERTIES));

  //CAutoLock cObjectLock(this);
  Lock;
  try
    pProps.cbBuffer := FSize;
    pProps.cBuffers := FCount;
    pProps.cbAlign := FAlignment;
    pProps.cbPrefix := FPrefix;

    Result := NOERROR;
  finally
    Unlock;
  end;
end;

procedure TBCBaseAllocator.Lock;
begin
  FAllocatorLock.Lock;
end;

class function TBCBaseAllocator.NextSample(pSample: TBCMediaSample): PBCMediaSample;
begin
  pointer(Result) := @pSample.FNext;
end;

function TBCBaseAllocator.NonDelegatingAddRef: Integer;
begin
  Result := inherited NonDelegatingAddRef;
end;

(* Override this to publicise our interfaces *)
function TBCBaseAllocator.NonDelegatingQueryInterface(const IID: TGUID;
  out Obj): HResult;
begin
  (* Do we know about this interface *)

  if (IsEqualIID(IID, IID_IMemAllocator) or
     FEnableReleaseCallback and IsEqualIID(IID, IID_IMemAllocatorCallbackTemp)) then
  begin
    if (GetInterface(IID_IMemAllocatorCallbackTemp, Obj))
      then Result := NOERROR
      else Result := E_NOINTERFACE;
  end
    else Result := inherited NonDelegatingQueryInterface(IID, Obj);
end;

function TBCBaseAllocator.NonDelegatingRelease: Integer;
begin
  Result := inherited NonDelegatingRelease;
end;

procedure TBCBaseAllocator.NotifySample;
begin
  if (FWaiting <> 0) then
  begin
    ASSERT(FSem <> 0);
    ReleaseSemaphore(FSem, FWaiting, nil);
    FWaiting := 0;
  end;
end;

(* Final release of a TBCMediaSample will call this *)
function TBCBaseAllocator.ReleaseBuffer(pBuffer: IMediaSample): HResult;
var
  bRelease: BOOL;
  l1: integer;
begin
//    CheckPointer(pSample,E_POINTER);
//    ValidateReadPtr(pSample,sizeof(IMediaSample));

  if not (Assigned(@pBuffer)) then
  begin
    Result := E_POINTER;
    Exit;
  end;

  bRelease := False;
  Lock;
  try
    // Put back on the free list
    FFree.Add(TBCMediaSample(pBuffer));
    if (FWaiting <> 0)
      then NotifySample();

    // if there is a pending Decommit, then we need to complete it by
    // calling Free() when the last buffer is placed on the free list

    l1 := FFree.GetCount;
    if (FDecommitInProgress and (l1 = FAllocated)) then
    begin
      _Free;
      FDecommitInProgress := FALSE;
      bRelease := TRUE;
    end;
  finally
    UnLock;
  end;

  if Assigned(FNotify) then
  begin
    ASSERT(FEnableReleaseCallback);
   // Note that this is not synchronized with setting up a notification method.
    FNotify.NotifyRelease;
  end;

  // For each buffer there is one AddRef, made in GetBuffer and released
  // here. This may cause the allocator and all samples to be deleted
  if (bRelease)
    then _Release;

  Result := NOERROR;
end;

function TBCBaseAllocator.SetNotify(
  pNotify: IMemAllocatorNotifyCallbackTemp): HResult;
begin
  ASSERT(FEnableReleaseCallback);

  Lock;
  try
    FNotify := pNotify;
    Result := S_OK;
  finally
    Unlock;
  end;
end;

(* This sets the size and count of the required samples. The memory isn't
   actually allocated until Commit() is called, if memory has already been
   allocated then assuming no samples are outstanding the user may call us
   to change the buffering, the memory will be released in Commit() *)
function TBCBaseAllocator.SetProperties(var pRequest: TAllocatorProperties;
         out pActual: TAllocatorProperties): HResult;
begin
  if (@pRequest = nil) or (@pActual = nil) then
  begin
    Result := E_POINTER;
    Exit;
  end;
  //ValidateReadWritePtr(pActual, sizeof(ALLOCATOR_PROPERTIES));
  //CAutoLock cObjectLock(this);
  Lock;
  try
    ZeroMemory(@pActual, sizeof(ALLOCATOR_PROPERTIES));

    ASSERT(pRequest.cbBuffer > 0);

    (*  Check the alignment requested *)
    if (pRequest.cbAlign <> 1) then
    begin
      {$IFDEF _DEBUG}
      DbgLog('Alignment requested was 0x' + inttohex(pRequest.cbAlign, 8) + ', not 1');
      {$ENDIF}
      Result := VFW_E_BADALIGN;
    end;

    (* Can't do this if already committed, there is an argument that says we
       should not reject the SetProperties call if there are buffers still
       active. However this is called by the source filter, which is the same
       person who is holding the samples. Therefore it is not unreasonable
       for them to free all their samples before changing the requirements *)

    if (FCommitted) then
    begin
      Result := VFW_E_ALREADY_COMMITTED;
      Exit;
    end;

    (* Must be no outstanding buffers *)

    if (FAllocated <> FFree.GetCount) then
    begin
      Result := VFW_E_BUFFERS_OUTSTANDING;
      Exit;
    end;

    (* There isn't any real need to check the parameters as they
       will just be rejected when the user finally calls Commit *)

    FSize := pRequest.cbBuffer;
    pActual.cbBuffer := FSize;

    FCount := pRequest.cBuffers;
    pActual.cBuffers := FCount;

    FAlignment := pRequest.cbAlign;
    pActual.cbAlign := FAlignment;

    FPrefix := pRequest.cbPrefix;
    pActual.cbPrefix := FPrefix;

    FChanged := TRUE;
    Result := NOERROR;
  finally
    Unlock;
  end;
end;

procedure TBCBaseAllocator.SetWaiting;
begin
  inc(FWaiting);
end;

procedure TBCBaseAllocator.UnLock;
begin
  FAllocatorLock.UnLock;
end;

{ TBCMemAllocator }

//=====================================================================
//=====================================================================
// Implements TBCMemAllocator
//=====================================================================
//=====================================================================

procedure TBCMemAllocator._Free;
begin
  Exit;
end;

// override this to allocate our resources when Commit is called.
//
// note that our resources may be already allocated when this is called,
// since we don't free them on Decommit. We will only be called when in
// decommit state with all buffers free.
//
// object locked by caller
function TBCMemAllocator.Alloc: HRESULT;
var
  lAlignedSize,
  lRemainder: integer;
  pNext: PBYTE;
  pSample: TBCMediaSample;
begin
  //CAutoLock lck(this);
  Lock;
  try
    (* Check he has called SetProperties *)
    Result := inherited Alloc;
    if (FAILED(Result))
      then Exit;

    (* If the requirements haven't changed then don't reallocate *)
    if (Result = S_FALSE) then
    begin
      ASSERT(FBuffer <> nil);
      Result := NOERROR;
      Exit;
    end;
    ASSERT(Result = S_OK); // we use this fact in the loop below

    (* Free the old resources *)
    if (FBuffer <> nil)
      then ReallyFree;

    (* Compute the aligned size *)
    lAlignedSize := FSize + FPrefix;
    if (FAlignment > 1) then
    begin
      lRemainder := lAlignedSize mod FAlignment;
      if (lRemainder <> 0)
        then inc(lAlignedSize, (FAlignment - lRemainder));
    end;

    (* Create the contiguous memory block for the samples
       making sure it's properly aligned (64K should be enough!)
    *)
    ASSERT((lAlignedSize mod FAlignment) = 0);

    FBuffer := VirtualAlloc(
      nil,
      FCount * lAlignedSize,
      MEM_COMMIT,
      PAGE_READWRITE
    );

    if (FBuffer = nil) then
    begin
      Result := E_OUTOFMEMORY;
      Exit;
    end;

    pNext := FBuffer;

    ASSERT(FAllocated = 0);

    // Create the new samples - we have allocated m_lSize bytes for each sample
    // plus m_lPrefix bytes per sample as a prefix. We set the pointer to
    // the memory after the prefix - so that GetPointer() will return a pointer
    // to m_lSize bytes.
    //for (; m_lAllocated < m_lCount; m_lAllocated++, pNext += lAlignedSize) {
    while (FAllocated < FCount) do
    begin
      pSample := TBCMediaSample.Create(
        'Default memory media sample',
        self,
        Result,
        PBYTE(integer(pNext) + integer(FPrefix)), // GetPointer() value
        FSize                                     // not including prefix
      );

      ASSERT(SUCCEEDED(Result));
      if (pSample = nil) then
      begin
        Result := E_OUTOFMEMORY;
        exit;
      end;

      // This CANNOT fail
      FFree.Add(pSample);

      inc(FAllocated);
      inc(pNext, lAlignedSize);
    end;

    FChanged := FALSE;
    Result := NOERROR;
  finally
    Unlock;
  end;
end;

constructor TBCMemAllocator.Create(pName: WideString; pUnk: IInterface;
  out phr: HRESULT);
begin
  // TBCBaseAllocator(pName, pUnk, phr, TRUE, TRUE)
  inherited Create(pName, pUnk, phr, true, true);

  FBuffer := nil;
end;

(* This goes in the factory template table to create new instances *)
class function TBCMemAllocator.CreateInstance(const Unk: IInterface;
  out hr: HRESULT): TBCUnknown;
begin
  //CUnknown *pUnkRet = new TBCMemAllocator(NAME("TBCMemAllocator"), pUnk, phr);
  //return pUnkRet;
  Result := TBCMemAllocator.Create('TBCMemAllocator', Unk,  hr);
end;

(* Destructor frees our memory resources *)
destructor TBCMemAllocator.Destroy;
begin
  Decommit;
  ReallyFree;

  inherited Destroy;
end;

// called from the destructor (and from Alloc if changing size/count) to
// actually free up the memory
procedure TBCMemAllocator.ReallyFree;
var
  pSample: TBCMediaSample;
begin
  (* Should never be deleting this unless all buffers are freed *)

  ASSERT(FAllocated = FFree.GetCount);

  (* Free up all the CMediaSamples *)

  while true do
  begin
    pSample := FFree.RemoveHead;
    if (pSample <> nil)
      then FreeAndNil(pSample)
      else break;
  end;

  FAllocated := 0;

  // free the block of buffer memory
  if (FBuffer <> nil) then
  begin
    //EXECUTE_ASSERT(VirtualFree(m_pBuffer, 0, MEM_RELEASE));
    VirtualFree(FBuffer, 0, MEM_RELEASE);
    FBuffer := nil;
  end;
end;

(* This sets the size and count of the required samples. The memory isn't
   actually allocated until Commit() is called, if memory has already been
   allocated then assuming no samples are outstanding the user may call us
   to change the buffering, the memory will be released in Commit() *)
function TBCMemAllocator.SetProperties(var pRequest: TAllocatorProperties;
  out pActual: TAllocatorProperties): HResult;
var
  SysInfo: SYSTEM_INFO;
  lSize,
  lRemainder: integer;
begin
  if (@pActual = nil)
  then begin
    Result := E_POINTER;
    exit;
  end;
  //ValidateReadWritePtr(pActual,sizeof(ALLOCATOR_PROPERTIES));
  //CAutoLock cObjectLock(this);
  Lock;
  try
    ZeroMemory(@pActual, sizeof(ALLOCATOR_PROPERTIES));

    ASSERT(pRequest.cbBuffer > 0);

    GetSystemInfo(SysInfo);

    (*  Check the alignment request is a power of 2 *)
    {$IFDEF _DEBUG}
    if ((-pRequest.cbAlign and pRequest.cbAlign) <> pRequest.cbAlign)
      then DbgLog('Alignment requested 0x' + inttohex(pRequest.cbAlign, 8) + ' not a power of 2!');
    {$ENDIF}

    (*  Check the alignment requested *)
    if (pRequest.cbAlign = 0) or
       ((SysInfo.dwAllocationGranularity and (pRequest.cbAlign - 1)) <> 0) then
    begin
      {$IFDEF _DEBUG}
      DbgLog('Invalid alignment 0x' + inttohex(pRequest.cbAlign, 8) +
             ' requested - granularity = 0x' + inttohex(SysInfo.dwAllocationGranularity, 8));
      {$ENDIF}
      Result := VFW_E_BADALIGN;
      Exit;
    end;

    (* Can't do this if already committed, there is an argument that says we
       should not reject the SetProperties call if there are buffers still
       active. However this is called by the source filter, which is the same
       person who is holding the samples. Therefore it is not unreasonable
       for them to free all their samples before changing the requirements *)

    if (FCommitted) then
    begin
      Result := VFW_E_ALREADY_COMMITTED;
      Exit;
    end;

    (* Must be no outstanding buffers *)

    if (FFree.GetCount < FAllocated) then
    begin
      Result := VFW_E_BUFFERS_OUTSTANDING;
      exit;
    end;

    (* There isn't any real need to check the parameters as they
       will just be rejected when the user finally calls Commit *)

    // round length up to alignment - remember that prefix is included in
    // the alignment
    lSize := pRequest.cbBuffer + pRequest.cbPrefix;
    lRemainder := lSize mod pRequest.cbAlign;
    if (lRemainder <> 0)
      then lSize := lSize - (lRemainder + pRequest.cbAlign);

    FSize := lSize - pRequest.cbPrefix;
    pActual.cbBuffer := FSize;

    FCount := pRequest.cBuffers;
    pActual.cBuffers := FCount;

    FAlignment := pRequest.cbAlign;
    pActual.cbAlign := FAlignment;

    FPrefix := pRequest.cbPrefix;
    pActual.cbPrefix := FPrefix;

    FChanged := TRUE;
    Result := NOERROR;
  finally
    UnLock;
  end;
end;

function TBCMemAllocator.InheritedAlloc: HRESULT;
begin
  Result := inherited Alloc;
end;

{$IFNDEF WITH_PROPERTY_PAGE}
function GetDialogSize(iResourceID: Integer; pDlgProc: Pointer; lParam: LPARAM; out Size: TSize): Boolean;
var
  rc: TRect;
  wnd: THandle;
begin
  // Create a temporary property page
  wnd := CreateDialogParam(HInstance, MAKEINTRESOURCE(iResourceID), GetDesktopWindow(), pDlgProc, lParam);

  if (wnd = 0) then
  begin
    Result := False;
    Exit;
  end;

  GetWindowRect(wnd, rc);
  Size.cx := rc.right - rc.left;
  Size.cy := rc.bottom - rc.top;

  DestroyWindow(wnd);
  Result := True;
end;

function DialogProc(hwndDlg: Thandle; uMsg: Cardinal; wParam: WPARAM; lParam: LPARAM): Integer; stdcall;
var
  PropertyPage: TBCBasePropertyPage;
begin
  case uMsg of
    WM_INITDIALOG:
    begin
      SetWindowLong(hwndDlg, GWL_USERDATA, lParam);
      // This pointer may be NULL when calculating size
      PropertyPage := TBCBasePropertyPage(lParam);
      if (PropertyPage = nil) then
      begin
        Result := LRESULT(1);
        Exit;
      end;
      PropertyPage.FDialog := hwndDlg;
    end;
  end;

  // This pointer may be NULL when calculating size
  PropertyPage := TBCBasePropertyPage(GetWindowLong(hwndDlg, GWL_USERDATA));
  if (PropertyPage = nil) then
  begin
    Result := LRESULT(1);
    Exit;
  end;

  Result := PropertyPage.OnReceiveMessage(hwndDlg, uMsg, wParam, lParam);
end;

constructor TBCBasePropertyPage.Create(Name: WideString; pUnk: IUnknown; DialogID: Integer; Title: WideString);
begin
  inherited Create(Name, pUnk);
  FDialogID := DialogId;
  FTitle := Title;
  FWindow := 0;
  FDialog := 0;
  FPageSite := nil;
  FObjectSet := False;
  FDirty := False;
end;

destructor TBCBasePropertyPage.Destroy;
begin
  inherited Destroy;
end;

function TBCBasePropertyPage.NonDelegatingAddRef: Integer;
begin
  Result := inherited NonDelegatingAddRef;
end;

function TBCBasePropertyPage.NonDelegatingRelease: Integer;
begin
  if (InterlockedDecrement(FRefCount) = 0) then
  begin
    inc(FRefCount);
    SetPageSite(nil);
    SetObjects(0, nil);
    Result := 0;
    Free;
  end else
  begin
    Result := FRefCount;
  end;
end;

function TBCBasePropertyPage.NonDelegatingQueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if IsEqualGUID(IID, IPropertyPage) then
  begin
    if GetInterface(IID, Obj)
      then Result := S_OK
      else Result := E_NOINTERFACE;
  end else
  begin
    Result := inherited NonDelegatingQueryInterface(IID, Obj)
  end;
end;

procedure TBCBasePropertyPage.SetPageDirty;
begin
  FDirty := True;
  if Assigned(FPageSite) then FPageSite.OnStatusChange(PROPPAGESTATUS_DIRTY);
end;

function TBCBasePropertyPage.OnConnect(pUnknown: IUnknown): HRESULT;
begin
  Result := NOERROR;
end;

function TBCBasePropertyPage.OnDisconnect: HRESULT;
begin
  Result := NOERROR;
end;

function TBCBasePropertyPage.OnActivate: HRESULT;
begin
  Result := NOERROR;
end;

function TBCBasePropertyPage.OnDeactivate: HRESULT;
begin
  Result := NOERROR;
end;

function TBCBasePropertyPage.OnApplyChanges: HRESULT;
begin
  Result := NOERROR;
end;

function TBCBasePropertyPage.OnReceiveMessage(hwndDlg: Thandle; uMsg: Cardinal; wParam: WPARAM; lParam: LPARAM): Integer;
var
  PropertyPage: TBCBasePropertyPage;
  lpss: PStyleStruct;
begin
  PropertyPage := TBCBasePropertyPage(GetWindowLong(hwndDlg, GWL_USERDATA));
  if (PropertyPage.FWindow = 0) then
  begin
    Result := 0;
    Exit;
  end;

  case uMsg of
    WM_STYLECHANGING:
    begin
      if (wParam = GWL_EXSTYLE) then
      begin
        lpss := PStyleStruct(lParam);
        lpss.styleNew := lpss.styleNew or WS_EX_CONTROLPARENT;
        Result := 0;
        Exit;
      end;
    end;
  end;

  Result := DefWindowProc(hwndDlg, uMsg, wParam, lParam);
end;

// IPropertyPage
function TBCBasePropertyPage.SetPageSite(const pageSite: IPropertyPageSite): HResult;
begin
  if Assigned(pageSite) then
  begin
    if Assigned(FPageSite) then
    begin
      Result := E_UNEXPECTED;
      Exit;
    end;

    FPageSite := PageSite;
  end else
  begin
    if not Assigned(FPageSite) then
    begin
      Result := E_UNEXPECTED;
      Exit;
    end;

    FPageSite := nil;
  end;
  Result := NOERROR;
end;

function TBCBasePropertyPage.Activate(hwndParent: HWnd; const rc: TRect; bModal: BOOL): HResult;
begin
  if not Assigned(@rc) then
  begin
    Result := E_POINTER;
    Exit;
  end;

  // Return failure if SetObject has not been called.
  if (FObjectSet = False) then
  begin
    Result := E_UNEXPECTED;
    Exit;
  end;

  if (FWindow > 0) then
  begin
    Result := E_UNEXPECTED;
    Exit;
  end;

  FWindow := CreateDialogParam(HInstance, MAKEINTRESOURCE(FDialogID), hwndParent, @DialogProc, LPARAM(Self));
  if (FWindow = 0) then
  begin
    Result := E_OUTOFMEMORY;
    Exit;
  end;

  OnActivate;
  Move(rc);
  Result := Show(SW_SHOWNORMAL);
end;

function TBCBasePropertyPage.Deactivate: HResult;
var
  dwStyle: Cardinal;
  h: THandle;
begin
  if (FWindow = 0) then
  begin
    Result := E_UNEXPECTED;
    Exit;
  end;

  // Remove WS_EX_CONTROLPARENT before DestroyWindow call
  dwStyle := GetWindowLong(FWindow, GWL_EXSTYLE);
  dwStyle := dwStyle and not WS_EX_CONTROLPARENT;

  //  Set m_hwnd to be NULL temporarily so the message handler
  //  for WM_STYLECHANGING doesn't add the WS_EX_CONTROLPARENT
  //  style back in
  h := FWindow;
  FWindow := 0;
  SetWindowLong(h, GWL_EXSTYLE, dwStyle);
  FWindow := h;

  OnDeactivate;

  // Destroy the dialog window

  DestroyWindow(FWindow);
  FWindow := 0;
  Result := NOERROR;
end;

function TBCBasePropertyPage.GetPageInfo(out pageInfo: TPropPageInfo): HResult;
var
  pszTitle: PWideChar;
begin
  if not Assigned(@pageInfo) then
  begin
    Result := E_POINTER;
    Exit;
  end;

  // Allocate dynamic memory for the property page title

  Result := AMGetWideString(FTitle, pszTitle);
  if (FAILED(Result))
    then Exit;

  pageInfo.cb               := sizeof(TPropPageInfo);
  pageInfo.pszTitle         := pszTitle;
  pageInfo.pszDocString     := nil;
  pageInfo.pszHelpFile      := nil;
  pageInfo.dwHelpContext    := 0;

  // Set defaults in case GetDialogSize fails
  pageInfo.size.cx          := 340;
  pageInfo.size.cy          := 150;

  GetDialogSize(FDialogID, @DialogProc, 0, pageInfo.size);
  Result := NOERROR;
end;

function TBCBasePropertyPage.SetObjects(cObjects: Longint; pUnkList: PUnknownList): HResult;
begin
  if (cObjects = 1) then
  begin
    if (pUnkList = nil) then
    begin
      Result := E_POINTER;
      Exit;
    end;

    // Set a flag to say that we have set the Object
    FObjectSet := True;
    Result := OnConnect(pUnkList[0]);
    Exit;
  end else
  if (cObjects = 0) then
  begin
    // Set a flag to say that we have not set the Object for the page
    FObjectSet := False;
    Result := OnDisconnect;
    Exit;
  end;

  Result := E_UNEXPECTED;
end;

function TBCBasePropertyPage.Show(nCmdShow: Integer): HResult;
begin
  // Have we been activated yet

  if (FWindow = 0) then
  begin
    Result := E_UNEXPECTED;
    Exit;
  end;

  // Ignore wrong show flags
  if ((nCmdShow <> SW_SHOW) and (nCmdShow <> SW_SHOWNORMAL) and (nCmdShow <> SW_HIDE)) then
  begin
    Result := E_INVALIDARG;
    Exit;
  end;

  ShowWindow(FWindow, nCmdShow);
  InvalidateRect(FWindow, nil, True);
  Result := NOERROR;
end;

function TBCBasePropertyPage.Move(const rect: TRect): HResult;
begin
  if (@rect = nil) then
  begin
    Result := E_POINTER;
    Exit;
  end;

  if (FWindow = 0) then
  begin
    Result := E_UNEXPECTED;
    Exit;
  end;

  MoveWindow(FWindow, rect.Left, rect.Top, rect.Right - rect.Left, rect.Bottom - rect.Top, True);
  Result := NOERROR;
end;

function TBCBasePropertyPage.IsPageDirty: HResult;
begin
  if FDirty
    then Result := S_OK
    else Result := S_FALSE;
end;

function TBCBasePropertyPage.Apply: HResult;
begin
  // In ActiveMovie 1.0 we used to check whether we had been activated or
  // not. This is too constrictive. Apply should be allowed as long as
  // SetObject was called to set an object. So we will no longer check to
  // see if we have been activated (ie., m_hWnd != NULL), but instead
  // make sure that m_bObjectSet is TRUE (ie., SetObject has been called).

  if (FObjectSet = False) then
  begin
    Result := E_UNEXPECTED;
    Exit;
  end;

  // Must have had a site set
  if not Assigned(FPageSite) then
  begin
    Result := E_UNEXPECTED;
    Exit;
  end;

  // Has anything changed
  if (FDirty = False) then
  begin
    Result := NOERROR;
    Exit;
  end;

  // Commit derived class changes
  Result := OnApplyChanges;
  if (SUCCEEDED(Result))
    then FDirty := False;
end;

function TBCBasePropertyPage.Help(pszHelpDir: POleStr): HResult;
begin
  Result := E_NOTIMPL;
end;

function TBCBasePropertyPage.TranslateAccelerator(msg: PMsg): HResult;
begin
  Result := E_NOTIMPL;
end;
{$ENDIF}

initialization
{$IFDEF _DEBUG}
  {$IFDEF VER130}
    AssertErrorProc := @DbgAssert;
  {$ELSE}
    AssertErrorProc := DbgAssert;
 {$ENDIF}
 {$IFNDEF MESSAGE}
  AssignFile(DebugFile, ParamStr(0) + '.log');
  if FileExists(ParamStr(0) + '.log') then
    Append(DebugFile) else
    Rewrite(DebugFile);
 {$ENDIF}
{$ENDIF}

finalization
begin
  if TemplatesVar <> nil then TemplatesVar.Free;
  TemplatesVar := nil;
{$IFDEF _DEBUG}
 {$IFNDEF MESSAGE}
  Writeln(DebugFile, format('FactoryCount: %d, ObjectCount: %d.',[FactoryCount, ObjectCount]));
  CloseFile(DebugFile);
 {$ELSE}
  OutputDebugString(PChar(format('FactoryCount: %d, ObjectCount: %d.',[FactoryCount, ObjectCount])));
 {$ENDIF}
{$ENDIF}
// milenko start (only needed with PERF)
{$IFDEF PERF}
  SetLength(Incidents, 0);
  SetLength(IncidentsLog, 0);
{$ENDIF}
// milenko end
end;

end.






