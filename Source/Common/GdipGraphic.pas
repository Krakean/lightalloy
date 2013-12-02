unit GdipGraphic;

interface

uses      classes,
  Windows, ActiveX;

const WINGDIPDLL = 'gdiplus.dll';

type
  Status = (
    Ok,
    GenericError,
    InvalidParameter,
    OutOfMemory,
    ObjectBusy,
    InsufficientBuffer,
    NotImplemented,
    Win32Error,
    WrongState,
    Aborted,
    FileNotFound,
    ValueOverflow,
    AccessDenied,
    UnknownImageFormat,
    FontFamilyNotFound,
    FontStyleNotFound,
    NotTrueTypeFont,
    UnsupportedGdiplusVersion,
    GdiplusNotInitialized,
    PropertyNotFound,
    PropertyNotSupported
  );

  TStatus = Status;
  GpStatus          = TStatus;

  ImageCodecInfo = packed record
    Clsid             : TGUID;
    FormatID          : TGUID;
    CodecName         : PWCHAR;
    DllName           : PWCHAR;
    FormatDescription : PWCHAR;
    FilenameExtension : PWCHAR;
    MimeType          : PWCHAR;
    Flags             : DWORD;
    Version           : DWORD;
    SigCount          : DWORD;
    SigSize           : DWORD;
    SigPattern        : PBYTE;
    SigMask           : PBYTE;
  end;

  TImageCodecInfo = ImageCodecInfo;
  PImageCodecInfo = ^TImageCodecInfo;
  GpImage = Pointer;
  DebugEventLevel = (
    DebugEventLevelFatal,
    DebugEventLevelWarning
  );

  DebugEventProc = procedure(level: DebugEventLevel; message: PChar); stdcall;
  GdiplusStartupInput = packed record
    GdiplusVersion          : Cardinal;       // Must be 1
    DebugEventCallback      : DebugEventProc; // Ignored on free builds
    SuppressBackgroundThread: BOOL;           // FALSE unless you're prepared to call
                                              // the hook/unhook functions properly
    SuppressExternalCodecs  : BOOL;           // FALSE unless you want GDI+ only to use
  end;                                        // its internal image codecs.
  TGdiplusStartupInput = GdiplusStartupInput;
  PGdiplusStartupInput = ^TGdiplusStartupInput;
  NotificationHookProc = function(out token: ULONG): Status; stdcall;
  NotificationUnhookProc = procedure(token: ULONG); stdcall;
  GdiplusStartupOutput = packed record
    NotificationHook  : NotificationHookProc;
    NotificationUnhook: NotificationUnhookProc;
  end;
  TGdiplusStartupOutput = GdiplusStartupOutput;
  PGdiplusStartupOutput = ^TGdiplusStartupOutput;
  EncoderParameterValueType = Integer;
  TEncoderParameterValueType = EncoderParameterValueType;
  EncoderParameter = packed record
    Guid           : TGUID;   // GUID of the parameter
    NumberOfValues : ULONG;   // Number of the parameter values
    Type_          : ULONG;   // Value type, like ValueTypeLONG  etc.
    Value          : Pointer; // A pointer to the parameter values
  end;
  TEncoderParameter = EncoderParameter;
  PEncoderParameter = ^TEncoderParameter;
  EncoderParameters = packed record
    Count     : UINT;               // Number of parameters in this structure
    Parameter : array[0..0] of TEncoderParameter;  // Parameter values
  end;
  TEncoderParameters = EncoderParameters;
  PEncoderParameters = ^TEncoderParameters;
  function GdipGetImageEncodersSize(out numEncoders: UINT; out size: UINT): GPSTATUS; stdcall;
  function GdipGetImageEncoders(numEncoders: UINT; size: UINT; encoders: PIMAGECODECINFO): GPSTATUS; stdcall;
  function GdiplusStartup(out token: ULONG; input: PGdiplusStartupInput; output: PGdiplusStartupOutput): Status; stdcall;
  procedure GdiplusShutdown(token: ULONG); stdcall;
  function GdipLoadImageFromFile(filename: PWCHAR; out image: GPIMAGE): GPSTATUS; stdcall;
  function GdipLoadImageFromStream(Stream: IStream; out image: GPIMAGE): GPSTATUS; stdcall;
  function GdipSaveImageToStream(image: GpImage; stream: IStream; clsidEncoder: PGUID; encoderParams: PEncoderParameters): GpStatus; stdcall;
  function GdipSaveImageToFile(image: GPIMAGE; filename: PWCHAR; clsidEncoder: PGUID; encoderParams: PENCODERPARAMETERS): GPSTATUS; stdcall;

  function GetImageEncodersSize(out numEncoders, size: UINT): TStatus;
  function GetImageEncoders(numEncoders, size: UINT; encoders: PImageCodecInfo): TStatus;
  function GetEncoderClsid(format: String; out pClsid: TGUID): integer;

procedure StreamToBitmapStream(InputStream: TMemoryStream; var OutPutStream: TMemoryStream);

implementation

type
  TExternStream = class(TStream)
  protected
    FSource : IStream;
    procedure SetSize(const NewSize: Int64); override;
  public
    constructor Create(Source : IStream);
    destructor Destroy; override;
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
  end;

function GdipGetImageEncodersSize; external WINGDIPDLL name 'GdipGetImageEncodersSize';
function GdipGetImageEncoders; external WINGDIPDLL name 'GdipGetImageEncoders';
function GdiplusStartup; external WINGDIPDLL name 'GdiplusStartup';
procedure GdiplusShutdown; external WINGDIPDLL name 'GdiplusShutdown';
function GdipLoadImageFromFile; external WINGDIPDLL name 'GdipLoadImageFromFile';
function GdipLoadImageFromStream; external WINGDIPDLL name 'GdipLoadImageFromStream';
function GdipSaveImageToFile; external WINGDIPDLL name 'GdipSaveImageToFile';
function GdipSaveImageToStream; external WINGDIPDLL name 'GdipSaveImageToStream';

{ TExternStream }

constructor TExternStream.Create(Source: IStream);
begin
  inherited Create;
  FSource := Source;
end;

destructor TExternStream.Destroy;
begin
  FSource := nil;
  inherited;
end;

function TExternStream.Read(var Buffer; Count: Integer): Longint;
begin
  if FSource.Read(@Buffer, Count, @Result) <> S_OK
  then
    Result := 0;
end;

function TExternStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  FSource.Seek(Offset, byte(Origin), Result);
end;

procedure TExternStream.SetSize(const NewSize: Int64);
begin
  FSource.SetSize(NewSize);
end;

function TExternStream.Write(const Buffer; Count: Integer): Longint;
begin
  if FSource.Write(@Buffer, Count, @Result) <> S_OK
  then
    Result := 0;
end;


function GetImageEncodersSize(out numEncoders, size: UINT): TStatus;
begin
  result := GdipGetImageEncodersSize(numEncoders, size);
end;

function GetImageEncoders(numEncoders, size: UINT; encoders: PImageCodecInfo): TStatus;
begin
  result := GdipGetImageEncoders(numEncoders, size, encoders);
end;

function GetEncoderClsid(format: String; out pClsid: TGUID): integer;
var
  num, size, j: UINT;
  ImageCodecInfo: PImageCodecInfo;
type
  ArrIMgInf = array of TImageCodecInfo;
begin
  num  := 0; // number of image encoders
  size := 0; // size of the image encoder array in bytes
  result := -1;
  GetImageEncodersSize(num, size);
  if (size = 0) then exit;
  GetMem(ImageCodecInfo, size);
  if(ImageCodecInfo = nil) then exit;
  GetImageEncoders(num, size, ImageCodecInfo);
  for j := 0 to num - 1 do
  begin
    if( ArrIMgInf(ImageCodecInfo)[j].MimeType = format) then
    begin
      pClsid := ArrIMgInf(ImageCodecInfo)[j].Clsid;
      result := j;  // Success
    end;
  end;
  FreeMem(ImageCodecInfo, size);
end;

procedure StreamToBitmapStream(InputStream: TMemoryStream; var OutPutStream: TMemoryStream);
var
  imgFile          : GPIMAGE;
  aptr             : IStream;
  encoderClsid     : TGUID;
  aOut : TExternStream;
  input: TGdiplusStartupInput;
  token: dword;
  ss:tstatus;
  np: int64;
begin
  InputStream.Seek(0, soFromBeginning);
  aptr    := TStreamAdapter.Create(InputStream, soReference) as IStream;
  imgFile := nil;
  FillChar(input, SizeOf(input), 0);
  input.GdiplusVersion := 1;
  GdiplusStartup(token, @input, nil);
  GdipLoadImageFromStream(aptr, imgFile);
  GetEncoderClsid('image/bmp', encoderClsid);
  aptr.SetSize(0);
  ss:=GdipSaveImageToStream(imgFile, aptr, @encoderClsid, nil);
  if ss<>Ok then Exit;
  aptr.Seek(0,soFromBeginning,np);
  aOut := TExternStream.Create(aptr);
  aOut.Seek(0,soFromBeginning);
  OutPutStream.CopyFrom(aOut,aOut.Size);
  GdiplusShutdown(token);
  aptr := nil;
end;

end.