///////////////////////////////////////////////////////////////////////////////
// Light Alloy                           Copyright(c) 2006-2013, Vortex Team //
//---------------------------------------------------------------------------//
// Filename                                                                  //
// Description.                                                              //
// ---------------                                                           //
// Author : Dmitry «Vortex» Koteroff                                         //
// E-mail : vortex@light-alloy.ru                                            //
// WWW    : http://light-alloy.ru                                            //
//---------------------------------------------------------------------------//
//   Date    Ver   Who  Comment                                              //
// --------  ---   ---  -------                                              //
// xx.xx.12  1.0   VtX  Created                                              //
///////////////////////////////////////////////////////////////////////////////

unit AudioFilter;

interface

uses
  Windows, SysUtils, Classes, ActiveX, MMSystem, DirectShow9, BaseClass,
  DSUtils, dspConst, dspUtils, Math;

type
  TAudioFilter = class; forward = TAudioFilter;

  TAudioFilterInputPin = class(TBCTransformInputPin)
  public
    fOwner: TAudioFilter;
    FLock: TBCCritSec;
  public
    Blocked: Boolean;
    constructor Create(ObjName: string; Owner: TAudioFilter; out hr: HRESULT;
      Name: WideString; aBlocked: Boolean; Lock: TBCCritSec);
    function Receive(pSample: IMediaSample): HRESULT; override;
  end;

  TAudioFilter = class(TBCTransformFilter, IAMStreamSelect, IDSPVisualIntf)
  private
    fPinList: TList;
    fActivePin: TAudioFilterInputPin;
    fLastMediaType: TDSAudioStream;
    fStream: TDSAudioStream;
    fEOS: Boolean;
    fFlushing: Boolean;
    fPlaying: Boolean;
    fVisBufferSwap: integer;
    fVisBuffer: PAnsiChar;
    fVisBufferCount: integer;
    fVisBufferStartTime: TReferenceTime;
    fVisBufferMaxBytes: integer;
    fVisBufferDivider: Double;
    fVisModBytes: integer;
    fBuffer: TVisualBuffer;
  public
    constructor Create(ObjName: string; unk: IUnKnown; const clsid: TGUID);
    destructor Destroy; override;
    { Проверяем подходит ли нам входной тип даных }
    function CheckInputType(mtIn: PAMMediaType): HRESULT; override;
    { Проверяем можем или не трансформить от входа к выходу }
    function CheckTransform(mtIn, mtOut: PAMMediaType): HRESULT; override;
    { Один из пинов удачно подключился }
    function CompleteConnect(direction: TPinDirection;
      ReceivePin: IPin): HRESULT; override;
    { Тип данных на выходе }
    function GetMediaType(Position: integer; out MediaType: PAMMediaType): HRESULT; override;
    { Количество пинов нашего фильтра }
    function GetPinCount: integer; override;
    { Пины нашего фильтра }
    function GetPin(n: integer): TBCBasePin; override;
    { Определяем размер буфера для обработки }
    function DecideBufferSize(Alloc: IMemAllocator;
      propInputRequest: PAllocatorProperties): HRESULT; override;
    { Обрабатываем данные }
    function Transform(msIn, msOut: IMediaSample): HRESULT; override;
    { Копируем данные со входа на выход }
    function Copy(Source, Dest: IMediaSample): HRESULT;
    { Сброс, вызывается вначале и при перемотке либо паузе }
    function BeginFlush: HRESULT; override;
    function EndFlush: HRESULT; override;
    { Реагируем на запуск, остановку и приостановку фильтра }
    function Stop: HRESULT; override;
    function Pause: HRESULT; override;
    function Run(tStart: TReferenceTime): HRESULT; override;
    function EndOfStream: HRESULT; override;
    { Получение одного из входных пинов по индексу }
    function GetPinByIndex(index: integer): TAudioFilterInputPin;

    procedure AllocateVisBuffer;
    procedure ApplyVisual(Buffer: Pointer; Length: integer);
    function GetBufferAtTimeStamp(Time: REFERENCE_TIME;
      out Bytes: integer): PAnsiChar;
    function ProcessVisualData(Buffer: Pointer; Size: integer; Bits: Byte;
      Channels: Byte; Float: Boolean): PVisualBuffer;
    function get_VisualData(out VisualBuffer: PVisualBuffer; out Size: integer): HRESULT; stdcall;

    { IAMStreamSelect methods }
    function Count(out pcStreams: DWORD): HRESULT; stdcall;
    function Info(lIndex: Longint; out ppmt: PAMMediaType; out pdwFlags: DWORD;
      out plcid: LCID; out pdwGroup: DWORD; out ppszName: PWCHAR;
      out ppObject: IUnKnown; out ppUnk: IUnKnown): HRESULT; stdcall;
    function Enable(lIndex: Longint; dwFlags: DWORD): HRESULT; stdcall;

    { Override me }
    procedure ProcessPCMData(Buffer: Pointer; Stream: PDSAudioStream); virtual;
      abstract;
    procedure Flush; virtual; abstract;
    procedure MediaTypeChanged(Stream: PDSAudioStream); virtual; abstract;
  end;

implementation

{ TAudioFilterInputPin }

constructor TAudioFilterInputPin.Create(ObjName: string; Owner: TAudioFilter;
  out hr: HRESULT; Name: WideString; aBlocked: Boolean; Lock: TBCCritSec);
begin
  fOwner := Owner;
  Blocked := aBlocked;
  FLock := Lock;
  inherited Create(ObjName, Owner, hr, Name);
end;

function TAudioFilterInputPin.Receive(pSample: IMediaSample): HRESULT;
begin
  FLock.Lock;
  try
    if Blocked then
      Result := E_FAIL
    else
      Result := inherited Receive(pSample);
  finally
    FLock.UnLock;
  end;
end;

{ TAudioFilter }

constructor TAudioFilter.Create(ObjName: string; unk: IUnKnown;
  const clsid: TGUID);
begin
  inherited Create(ObjName, unk, clsid);

  fActivePin := nil;
  fPinList := TList.Create;

  fFlushing := False;
  fVisBufferCount := 0;
  fVisBufferStartTime := 0;
end;

destructor TAudioFilter.Destroy;
var
  i: integer;
begin
  for i := 1 to fPinList.Count - 1 do
    TAudioFilterInputPin(fPinList.Items[i]).Free;
  fPinList.Free;

  FreeMemory(fVisBuffer);
  inherited Destroy;
end;

function TAudioFilter.CheckInputType(mtIn: PAMMediaType): HRESULT;
begin
  if not IsEqualGUID(mtIn^.majortype, MEDIATYPE_Audio) then
  begin
    Result := VFW_E_INVALIDMEDIATYPE;
    Exit;
  end;

  if (not IsEqualGUID(mtIn^.subtype, MEDIASUBTYPE_PCM)) and
    (not IsEqualGUID(mtIn^.subtype, MEDIASUBTYPE_IEEE_FLOAT)) then
  begin
    Result := VFW_E_INVALIDSUBTYPE;
    Exit;
  end;

  if not IsEqualGUID(mtIn^.formattype, FORMAT_WaveFormatEx) then
  begin
    Result := VFW_E_TYPE_NOT_ACCEPTED;
    Exit;
  end;

  fStream.Frequency := PWaveFormatEx(mtIn^.pbFormat)^.nSamplesPerSec;
  fStream.Channels := PWaveFormatEx(mtIn^.pbFormat)^.nChannels;
  fStream.Bits := PWaveFormatEx(mtIn^.pbFormat)^.wBitsPerSample;

  if (fStream.Bits <> 32) and (fStream.Bits <> 24) and (fStream.Bits <> 16) and
    (fStream.Bits <> 8) then
  begin
    Result := VFW_E_TYPE_NOT_ACCEPTED;
    Exit;
  end;

  fStream.Float := IsEqualGUID(mtIn^.subtype, MEDIASUBTYPE_IEEE_FLOAT) or
    (PWaveFormatEx(mtIn^.pbFormat)^.wFormatTag = WAVE_FORMAT_IEEE_FLOAT) or
    ((PWaveFormatExtensible(mtIn^.pbFormat)^.Format.wFormatTag =
        WAVE_FORMAT_EXTENSIBLE) and IsEqualGUID(PWaveFormatExtensible
        (mtIn^.pbFormat)^.SubFormat, KSDATAFORMAT_SUBTYPE_IEEE_FLOAT));

  fStream.SPDIF := (PWaveFormatEx(mtIn^.pbFormat)^.wFormatTag =
      WAVE_FORMAT_DOLBY_AC3_SPDIF) or
    (PWaveFormatEx(mtIn^.pbFormat)
      ^.wFormatTag = WAVE_FORMAT_DOLBY_AC3);
  fStream.DTS := (PWaveFormatEx(mtIn^.pbFormat)^.wFormatTag = WAVE_FORMAT_DTS)
    or (PWaveFormatEx(mtIn^.pbFormat)^.wFormatTag = WAVE_FORMAT_DVD_DTS);

  if not CompareMem(@fLastMediaType, @fStream, SizeOf(TDSAudioStream)) then
    MediaTypeChanged(@fStream);
  fLastMediaType := fStream;

  Result := S_OK;
end;

function TAudioFilter.CheckTransform(mtIn, mtOut: PAMMediaType): HRESULT;
begin
  if not IsEqualGUID(mtIn^.majortype, MEDIATYPE_Audio) then
  begin
    Result := VFW_E_INVALIDMEDIATYPE;
    Exit;
  end;

  if (not IsEqualGUID(mtIn^.subtype, MEDIASUBTYPE_PCM)) and
    (not IsEqualGUID(mtIn^.subtype, MEDIASUBTYPE_DOLBY_AC3_SPDIF)) and
    (not IsEqualGUID(mtIn^.subtype, MEDIASUBTYPE_IEEE_FLOAT)) then
  begin
    Result := VFW_E_INVALIDSUBTYPE;
    Exit;
  end;

  if not IsEqualGUID(mtIn^.formattype, FORMAT_WaveFormatEx) then
  begin
    Result := VFW_E_TYPE_NOT_ACCEPTED;
    Exit;
  end;

  Result := S_OK;
end;

function TAudioFilter.CompleteConnect(direction: TPinDirection;
  ReceivePin: IPin): HRESULT;
var
  i: integer;
  addpin: Boolean;
  hr: HRESULT;
begin
  Result := NOERROR;
  FcsFilter.Lock;
  try
    if (direction = PINDIR_INPUT) then
    begin
      addpin := True;
      for i := 0 to fPinList.Count - 1 do
      begin
        if not TAudioFilterInputPin(fPinList.Items[i]).IsConnected then
        begin
          addpin := False;
          break;
        end;
      end;
      if addpin then
        fPinList.Add(TAudioFilterInputPin.Create('Input Pin', Self, hr,
            'Input', True, FcsReceive));
    end;

    if (direction = PINDIR_OUTPUT)
      and FInput.IsConnected and FOutput.IsConnected then
    begin
      AllocateVisBuffer;
    end;
  finally
    FcsFilter.UnLock;
  end;
end;

function TAudioFilter.GetMediaType(Position: integer;
  out MediaType: PAMMediaType): HRESULT;
var
  i: integer;
begin
  FcsFilter.Lock;
  try
    if not Assigned(@MediaType) or not Assigned(MediaType) then
    begin
      Result := E_POINTER;
      Exit;
    end;

    if not Input.IsConnected then
    begin
      Result := E_UNEXPECTED;
      Exit;
    end;

    if Position < 0 then
    begin
      Result := E_INVALIDARG;
      Exit;
    end;

    if Position > 0 then
    begin
      Result := VFW_S_NO_MORE_ITEMS;
      Exit;
    end;

    for i := 0 to fPinList.Count - 1 do
    begin
      if not TAudioFilterInputPin(fPinList.Items[i]).Blocked then
      begin
        TAudioFilterInputPin(fPinList.Items[i]).ConnectionMediaType(MediaType^);
        Result := S_OK;
        Exit;
      end;
    end;

    Result := E_UNEXPECTED;
  finally
    FcsFilter.UnLock;
  end;
end;

function TAudioFilter.GetPinCount: integer;
begin
  Result := fPinList.Count + 1;
end;

function TAudioFilter.GetPin(n: integer): TBCBasePin;
var
  hr: HRESULT;
begin
  hr := S_OK;

  if (FInput = nil) then
  begin
    FInput := TAudioFilterInputPin.Create('Input Pin', Self, hr, 'Input',
      False, FcsReceive);
    fPinList.Add(FInput);
    ASSERT(SUCCEEDED(hr));
  end;

  if ((FInput <> nil) and (FOutput = nil)) then
  begin
    FOutput := TBCTransformOutputPin.Create('Output Pin', Self, hr, 'Output');
    ASSERT(SUCCEEDED(hr));
    if (FOutput = nil) then
    begin
      FInput.Free;
      FInput := nil;
    end;
  end;

  case n of
    0:
      Result := FInput;
    1:
      Result := FOutput;
  else
    begin
      if (fPinList.Count = 1) or (n > fPinList.Count) then
        Result := nil
      else
        Result := fPinList.Items[n - 1];
    end;
  end;
end;

function TAudioFilter.DecideBufferSize(Alloc: IMemAllocator;
  propInputRequest: PAllocatorProperties): HRESULT;
var
  hr: HRESULT;
  Actual: TAllocatorProperties;
  max_buffer_size: integer;
begin
  if not Input.IsConnected then
  begin
    Result := E_UNEXPECTED;
    Exit;
  end;

  ASSERT(Alloc <> nil);
  ASSERT(propInputRequest <> nil);
  max_buffer_size := 352800 * fStream.Channels * (fStream.Bits div 8);
  propInputRequest.cBuffers := 1;
  propInputRequest.cbBuffer := max_buffer_size;

  ASSERT(propInputRequest.cbBuffer = max_buffer_size);
  ZeroMemory(@Actual, SizeOf(TAllocatorProperties));
  hr := Alloc.SetProperties(propInputRequest^, Actual);
  if hr <> S_OK then
  begin
    Result := hr;
    Exit;
  end;

  ASSERT(Actual.cBuffers > 0);

  if ((propInputRequest.cBuffers > Actual.cBuffers) or
      (propInputRequest.cbBuffer > Actual.cbBuffer)) then
  begin
    Result := E_FAIL;
    Exit;
  end;

  Result := S_OK;
end;

function TAudioFilter.Transform(msIn, msOut: IMediaSample): HRESULT;
var
  pSrc: PByte;
  mt: PAMMediaType;
  mi,mo : TReferenceTime;
begin
  FcsFilter.Lock;
  try
    Copy(msIn, msOut);

    // Dynamic MediaType change (eg. AC3 Filter)
    if msOut.GetMediaType(mt) = S_OK then
    begin
      Result := CheckInputType(mt);
      DeleteMediaType(mt);
      if Result <> S_OK then
        Exit;
    end;

    // Fixing VisBufferStartTime if needed.
    msOut.GetTime(mi,mo);
    if (fVisBufferStartTime > mi) then
      fVisBufferStartTime := mi;

    if not fStream.SPDIF and not fStream.DTS then
    begin
      msOut.GetPointer(pSrc);
      fStream.Size := msOut.GetActualDataLength;

      ProcessPCMData(pSrc, @fStream);

      ApplyVisual(pSrc, fStream.Size);
    end;
  finally
    FcsFilter.UnLock;
    Result := S_OK;
  end;
end;

function TAudioFilter.Copy(Source, Dest: IMediaSample): HRESULT;
var
  SourceBuffer, DestBuffer: PByte;
  TimeStart, TimeEnd: TReferenceTime;
  MediaStart, MediaEnd: int64;
  MediaType: PAMMediaType;
begin
  if Source.GetTime(TimeStart, TimeEnd) = S_OK then
    Dest.SetTime(@TimeStart, @TimeEnd);
  if Source.GetMediaTime(MediaStart, MediaEnd) = S_OK then
    Dest.SetMediaTime(@MediaStart, @MediaEnd);
  if Source.IsDiscontinuity = S_OK then
    Dest.SetDiscontinuity(True);
  if Source.IsPreroll = S_OK then
    Dest.SetPreroll(True);
  Source.GetPointer(SourceBuffer);
  Dest.GetPointer(DestBuffer);
  CopyMemory(DestBuffer, SourceBuffer, Source.GetActualDataLength);
  Dest.SetActualDataLength(Source.GetActualDataLength);
  if (Source.GetMediaType(MediaType) = S_OK) and Assigned(MediaType) then
  begin
    Dest.SetMediaType(MediaType);
    DeleteMediaType(MediaType);
  end;
  Result := S_OK;
end;

function TAudioFilter.BeginFlush: HRESULT;
begin
  Flush;
  fFlushing := True;
  fVisBufferCount := 0;
  fVisBufferStartTime := 0;
  Result := inherited BeginFlush;
end;

function TAudioFilter.EndFlush: HRESULT;
begin
  fFlushing := False;
  Result := inherited EndFlush;
end;

function TAudioFilter.Stop: HRESULT;
begin
  fPlaying := False;
  fVisBufferCount := 0;
  Result := inherited Stop;
end;

function TAudioFilter.Pause: HRESULT;
begin
  fPlaying := False;
  Result := inherited Pause;
end;

function TAudioFilter.Run(tStart: TReferenceTime): HRESULT;
begin
  fPlaying := True;
  fEOS := False;
  Result := inherited Run(tStart);
end;

function TAudioFilter.EndOfStream: HRESULT;
begin
  fEOS := True;
  Result := inherited EndOfStream;
end;

function TAudioFilter.GetPinByIndex(index: integer): TAudioFilterInputPin;
begin
  if (Index < 0) or (index >= fPinList.Count) then
  begin
    Result := nil;
    Exit;
  end;

  Result := fPinList.Items[index];
end;

procedure TAudioFilter.AllocateVisBuffer;
begin
  fVisBufferCount := 0;
  fVisBufferStartTime := 0;

  //if CompareMem(@fLastMediaType,@fStream,SizeOf(TDSAudioStream)) then Exit;
  fLastMediaType := fStream;

  // fVisBufferDivider is needed to convert bytes <> SampleTime
  fVisBufferDivider := 10000000 / fStream.Frequency / fStream.Channels / (fStream.Bits div 8);
  if fVisBuffer <> nil then
  begin
    FreeMemory(fVisBuffer);
    fVisBuffer := nil;
  end;
  // Allocate Memory for Visual Buffering (2 seconds for every Channel) with some extrabytes for swapping
  fVisBufferMaxBytes := fStream.Frequency * fStream.Channels * (fStream.Bits div 8) * 2;
  fVisBufferSwap := fStream.Channels * (fStream.Bits div 8) * 8192;
  fVisBuffer := AllocMem(fVisBufferMaxBytes + fVisBufferSwap);
  fVisModBytes := fStream.Channels * (fStream.Bits div 8);
end;

procedure TAudioFilter.ApplyVisual(Buffer: Pointer; Length: integer);
begin
  if fVisBuffer = nil then
    Exit;

  if (fVisBufferCount > fVisBufferMaxBytes) then
  begin
    fVisBufferStartTime := fVisBufferStartTime + Trunc(fVisBufferCount * fVisBufferDivider);
    fVisBufferCount := 0;
  end;

  Move(Buffer^,fVisBuffer[fVisBufferCount],Length);
  inc(fVisBufferCount,Length);
end;

function TAudioFilter.GetBufferAtTimeStamp(Time: REFERENCE_TIME;
  out Bytes: integer): PAnsiChar;
var
  Position : integer;
begin
  Position := Trunc((Time - fVisBufferStartTime) / fVisBufferDivider);
  Position := Position - (Position mod fVisModBytes);
  if Position < 0 then Inc(Position, fVisBufferMaxBytes);

  // Last check to see if weґre inside the Buffer
  if (Position > fVisBufferMaxBytes) or (Position < 0) then
  begin
    Result := nil;
    Exit;
  end;
  Bytes := fStream.Channels * (fStream.Bits div 8) * 8192;
  Result := @fVisBuffer[Position];
end;

function TAudioFilter.ProcessVisualData(Buffer: Pointer; Size: integer;
  Bits, Channels: Byte; Float: Boolean): PVisualBuffer;
var
  Buf8  : PByteArray;
  Buf16 : PSmallIntArray;
  Buf24 : PInteger24Array;
  Buf32i : PIntegerArray;
  Buf32 : PFloatArray;
  NumSamples : integer;
  i : integer;
begin
  if (Buffer = nil) or (Size = 0) or (Bits = 0) or (Channels = 0) then
  begin
    Result := nil;
    Exit;
  end;

  NumSamples := Size div (Bits div 8) div Channels;
  NumSamples := Min(NumSamples, MaxVisualSamples);
  Channels := Min(Channels, MaxChannels);

  case Bits of
    8:
    begin
      Buf8 := PByteArray(Buffer);
      for i := 0 to NumSamples -1 do
      begin
        fBuffer[i] := (Buf8^[i*Channels + 0] - 128) * 256;
      end;
    end;
    16:
    begin
      Buf16 := PSmallIntArray(Buffer);
      for i := 0 to NumSamples -1 do
      begin
        fBuffer[i] := Buf16^[i*Channels + 0];
      end;
    end;
    24:
    begin
      Buf24 := PInteger24Array(Buffer);
      for i := 0 to NumSamples -1 do
      begin
        fBuffer[i] := Cvt24BitTo32(Buf24^[i*Channels + 0]) div 256;
      end;
    end;
    32:
    begin
      if Float then
      begin
        Buf32 := PFloatArray(Buffer);
        for i := 0 to NumSamples -1 do
        begin
          fBuffer[i] := Round(Buf32^[i*Channels + 0] * 32767);
        end;
      end else
      begin
        Buf32i := PIntegerArray(Buffer);
        for i := 0 to NumSamples -1 do
        begin
          fBuffer[i] := Buf32i^[i*Channels + 0] div 65536;
        end;
      end;
    end;
  end;
  Result := @fBuffer;
end;

function TAudioFilter.get_VisualData(out VisualBuffer: PVisualBuffer;
  out Size: integer): HRESULT;
var
  StreamPos : TReferenceTime;
  Buffer: Pointer;
begin
  FcsFilter.Lock;
  try
    if fFlushing or (not fPlaying) or
       (StreamTime(StreamPos) <> S_OK) or (fVisBuffer = nil) or fEOS then
    begin
      Size := 0;
      VisualBuffer := nil;
      Result := S_FALSE;
      Exit;
    end;

    Buffer := GetBufferAtTimeStamp(StreamPos,Size);
    if Buffer = nil then
    begin
      Size := 0;
      VisualBuffer := nil;
      Result := S_FALSE;
      Exit;
    end;

    Size := Min(Size, 8192);
    VisualBuffer := ProcessVisualData(Buffer,Size,fStream.Bits,fStream.Channels,False);
    if VisualBuffer = nil then
    begin
      Size := 0;
      VisualBuffer := nil;
      Result := S_FALSE;
      Exit;
    end;

    Result := S_OK;
  finally
    FcsFilter.UnLock;
  end;
end;

function TAudioFilter.Count(out pcStreams: DWORD): HRESULT; stdcall;
begin
  FcsFilter.Lock;
  try
    pcStreams := fPinList.Count - 1;
    Result := S_OK;
  finally
    FcsFilter.UnLock;
  end;
end;

function TAudioFilter.Info(lIndex: Longint; out ppmt: PAMMediaType;
  out pdwFlags: DWORD; out plcid: LCID; out pdwGroup: DWORD;
  out ppszName: PWCHAR; out ppObject: IUnKnown;
  out ppUnk: IUnKnown): HRESULT; stdcall;
var
  pin: TAudioFilterInputPin;
begin
  FcsFilter.Lock;
  try
    if (lIndex < 0) or (lIndex >= fPinList.Count) then
    begin
      Result := S_FALSE;
      Exit;
    end;

    pin := GetPinByIndex(lIndex);

    if Assigned(@ppmt) then
    begin
      ppmt := nil;
      if pin.IsConnected then
        ppmt := CreateMediaType(pin.CurrentMediaType.MediaType);
    end;

    if Assigned(@pdwGroup) then
      pdwGroup := 1;

    if Assigned(@pdwFlags) then
    begin
      if not pin.Blocked then
        pdwFlags := AMSTREAMSELECTINFO_ENABLED or AMSTREAMSELECTINFO_EXCLUSIVE
      else
        pdwFlags := 0;
    end;

    if Assigned(@ppszName) then
    begin
      AMGetWideString(PWCHAR(WideString('Audio Track ' + inttostr(lIndex + 1))
          ), ppszName);
    end;

    Result := S_OK;
  finally
    FcsFilter.UnLock;
  end;
end;

function TAudioFilter.Enable(lIndex: Longint; dwFlags: DWORD): HRESULT; stdcall;
var
  pin: TAudioFilterInputPin;
  i: integer;
  State: TFilterState;
begin
  FcsFilter.Lock;
  try
    Result := S_FALSE;

    if (dwFlags = 0) or BOOL(dwFlags and AMSTREAMSELECTENABLE_ENABLEALL) then
    begin
      Result := E_NOTIMPL;
      Exit;
    end;

    pin := GetPinByIndex(lIndex);

    if not Assigned(pin) or not pin.IsConnected or not pin.Blocked then
      Exit;

    State := FState; (Graph as IMediaControl)
    .Stop;

    for i := 0 to fPinList.Count - 1 do
      TAudioFilterInputPin(fPinList.Items[i]).Blocked := True;

    pin := TAudioFilterInputPin(fPinList.Items[lIndex]);
    pin.Blocked := False;
    fActivePin := pin;

    if State = State_Running then (Graph as IMediaControl)
      .Run;

    Result := S_OK;
  finally
    FcsFilter.UnLock;
  end;
end;

end.
