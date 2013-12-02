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

unit dspDynamicAmplify;

interface

uses
  Classes, Windows, Math, dspConst, dspUtils;

type
  TDynamicAmplify = class
  protected
    fLastAmp : Single;
    fAmpWait : integer;
    fAmpWaitPos : integer;
    fReleaseTime : Cardinal;
    fAttackTime : Cardinal;
    fEnabled : Boolean;
    fSampleSize : Cardinal;
    fMaxAmplification : Cardinal;
    procedure DoDSP(Buffer: Pointer; Size, Samplerate: Integer; Bits: Byte; Channels: Byte; Float: Boolean);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Process(Buffer: Pointer; Size, Samplerate: Integer; Bits: Byte; Channels: Byte; Float: Boolean);

    function get_Enabled(out aEnabled: BOOL): HRESULT; stdcall;
    function set_Enabled(aEnabled: BOOL): HRESULT; stdcall;
    function get_AttackTime(out aAttackTime: Cardinal): HRESULT; stdcall;
    function set_AttackTime(aAttackTime: Cardinal): HRESULT; stdcall;
    function get_ReleaseTime(out aReleaseTime: Cardinal): HRESULT; stdcall;
    function set_ReleaseTime(aReleaseTime: Cardinal): HRESULT; stdcall;
    function get_MaxAmplification(out aMaxAmplification: Cardinal): HRESULT; stdcall;
    function set_MaxAmplification(aMaxAmplification: Cardinal): HRESULT; stdcall;
    function get_CurrentAmplification(out aCurrentAmplification: Single): HRESULT; stdcall;
  published
    property Enabled: Boolean read fEnabled write fEnabled;
    property SampleSize: Cardinal read fSampleSize write fSampleSize;
    property AttackTime: Cardinal read fAttackTime write fAttackTime;
    property ReleaseTime: Cardinal read fReleaseTime write fReleaseTime;
    property MaxAmplification: Cardinal read fMaxAmplification write fMaxAmplification;
    property CurrentAmplification: Single read fLastAmp;
  end;

implementation

constructor TDynamicAmplify.Create;
begin
  fLastAmp := 1.0;
  fAttackTime := 1000;
  fReleaseTime := 3000;
  fMaxAmplification := 10000;
  fEnabled := False;
  fSampleSize := DefaultSampleSize;
end;

destructor TDynamicAmplify.Destroy;
begin
  inherited Destroy;
end;

procedure TDynamicAmplify.Process(Buffer : Pointer; Size, Samplerate : Integer; Bits : Byte; Channels : Byte; Float : Boolean);
var
  SplitBuffer : PChar;
  SizeLeft : integer;
  SplitSize : integer;
  CurrentSize : integer;
begin
  if not fEnabled then Exit;
  if fSampleSize = 0 then
  begin
    DoDSP(Buffer,Size,Samplerate,Bits,Channels,Float);
  end else
  begin
    SplitBuffer := Buffer;
    SplitSize := fSampleSize * (Bits div 8) * Channels;
    SizeLeft := Size;
    while SizeLeft > 0 do
    begin
      if SizeLeft > SplitSize then CurrentSize := SplitSize
                              else CurrentSize := SizeLeft;
      DoDSP(@SplitBuffer[Size - SizeLeft],CurrentSize,Samplerate,Bits,Channels,Float);
      dec(SizeLeft,SplitSize);
    end;
  end;
end;

procedure TDynamicAmplify.DoDSP(Buffer: Pointer; Size, Samplerate: Integer; Bits: Byte; Channels: Byte; Float: Boolean);
var
  Buf8  : PByteArray;
  Buf16 : PSmallIntArray;
  Buf24  : PInteger24Array;
  Buf32 : PFloatArray;
  Buf32i : PIntegerArray;
  NumSamples : integer;
  i,c : integer;
  LoudestSample : integer;
  LoudestSample64 : Int64;
  AmpFactor,
  AmpFactorS : Single;
  tmp : integer;
  sLastAmp : Single;
  SmoothAmp : Single;
begin
  LoudestSample := 0;
  LoudestSample64 := 0;
  NumSamples := Size div (Bits div 8);
  AmpFactorS := fMaxAmplification / 1000;
  AmpFactor := 1.0;
  fAmpWait := Round((Samplerate * Channels * (Bits div 8) * Int64(fReleaseTime)) / 1000);

  Buf32 := nil;
  Buf16 := nil;
  Buf24 := nil;
  Buf32i := nil;
  Buf8 := nil;

  case Bits of
    8:
    begin
      Buf8 := PByteArray(Buffer);
      for i := 0 to (NumSamples) -1 do
        // Check for the Loudest Sample in this Chunk
        if abs(Buf8^[i] - 128) > LoudestSample then LoudestSample := abs(Buf8^[i] - 128);
      AmpFactor := 128 / LoudestSample;
    end;
    16:
    begin
      Buf16 := PSmallIntArray(Buffer);
      for i := 0 to (NumSamples) -1 do
        // Check for the Loudest Sample in this Chunk
        if abs(Buf16^[i]) > LoudestSample then LoudestSample := abs(Buf16^[i]);
      AmpFactor := 32768 / LoudestSample;
    end;
    24:
    begin
      Buf24 := PInteger24Array(Buffer);
      for i := 0 to (NumSamples) -1 do
        // Check for the Loudest Sample in this Chunk
        if abs(Cvt24BitTo32(Buf24^[i])) > LoudestSample then LoudestSample := abs(Cvt24BitTo32(Buf24^[i]));
      AmpFactor := 8388608 / LoudestSample;
    end;
    32:
    begin
      if Float then
      begin
        Buf32 := PFloatArray(Buffer);
        for i := 0 to (NumSamples) -1 do
        begin
          // Check for the Loudest Sample in this Chunk
          tmp := Round(abs(Buf32^[i]) * 32767);
          if tmp > LoudestSample then LoudestSample := tmp;
        end;
        AmpFactor := 32768 / LoudestSample;
      end else
      begin
        Buf32i := PIntegerArray(Buffer);
        for i := 0 to (NumSamples) -1 do
          // Check for the Loudest Sample in this Chunk
          if abs(Buf32i^[i]) > LoudestSample64 then LoudestSample64 := abs(Buf32i^[i]);
        AmpFactor := 2147483648 / LoudestSample64;
      end;
    end;
  end;

  sLastAmp := fLastAmp;
  if AmpFactor > AmpFactorS then AmpFactor := AmpFactorS;

  if AmpFactor < fLastAmp then
  begin
    fAmpWaitPos := 0;
    fLastAmp := AmpFactor;
  end else
  begin
    if fAmpWaitPos <= fAmpWait then
    begin
      inc(fAmpWaitPos,Size);
      AmpFactor := fLastAmp;
    end else
    begin
      fLastAmp := fLastAmp + ((Size * (fAttackTime / 1000) / Samplerate / Channels / (Bits div 8)));
      AmpFactor := fLastAmp;
      if AmpFactor > AmpFactorS then
      begin
        AmpFactor := AmpFactorS;
        fLastAmp := AmpFactor;
      end;
    end;
  end;

  NumSamples := NumSamples div Channels;
  case Bits of
    8:
    begin
      for c := 0 to Channels -1 do
      begin
        SmoothAmp := (sLastAmp - AmpFactor) / NumSamples;
        for i := 0 to (NumSamples -1) do Buf8^[i * Channels + c] := Clip_8(Trunc((Buf8^[i * Channels + c] - 128) * (sLastAmp - (SmoothAmp * i)))) + 128;
      end;
    end;
    16:
    begin
      for c := 0 to Channels -1 do
      begin
        SmoothAmp := (sLastAmp - AmpFactor) / NumSamples;
        for i := 0 to (NumSamples -1) do Buf16^[i * Channels + c] := Clip_16(Trunc(Buf16^[i * Channels + c] * (sLastAmp - (SmoothAmp * i))));
      end;
    end;
    24:
    begin
      for c := 0 to Channels -1 do
      begin
        SmoothAmp := (sLastAmp - AmpFactor) / NumSamples;
        for i := 0 to (NumSamples -1) do Buf24^[i * Channels + c] := Cvt32BitTo24(Clip_24(Trunc(Cvt24BitTo32(Buf24^[i * Channels + c]) * (sLastAmp - (SmoothAmp * i)))));
      end;
    end;
    32:
    begin
      if Float then
      begin
        for c := 0 to Channels -1 do
        begin
          SmoothAmp := (sLastAmp - AmpFactor) / NumSamples;
          for i := 0 to (NumSamples -1) do Buf32^[i * Channels + c] := Buf32^[i * Channels + c] * (sLastAmp - (SmoothAmp * i));
        end;
      end else
      begin
        for c := 0 to Channels -1 do
        begin
          SmoothAmp := (sLastAmp - AmpFactor) / NumSamples;
          for i := 0 to (NumSamples -1) do Buf32i^[i * Channels + c] := Clip_32(Trunc(Int64(Buf32i^[i * Channels + c]) * (sLastAmp - (SmoothAmp * i))));
        end;
      end;
    end;
  end;
end;
(*** IDCDynamicAmplify ********************************************************)
function TDynamicAmplify.get_Enabled(out aEnabled: BOOL): HRESULT; stdcall;
begin
  Result := S_OK;
  aEnabled := fEnabled;
end;

function TDynamicAmplify.set_Enabled(aEnabled: BOOL): HRESULT; stdcall;
begin
  Result := S_OK;
  fEnabled := aEnabled;
end;

function TDynamicAmplify.get_AttackTime(out aAttackTime: Cardinal): HRESULT; stdcall;
begin
  Result := S_OK;
  aAttackTime := fAttackTime;
end;

function TDynamicAmplify.set_AttackTime(aAttackTime: Cardinal): HRESULT; stdcall;
begin
  Result := S_OK;
  fAttackTime := aAttackTime;
end;

function TDynamicAmplify.get_ReleaseTime(out aReleaseTime: Cardinal): HRESULT; stdcall;
begin
  Result := S_OK;
  aReleaseTime := fReleaseTime;
end;

function TDynamicAmplify.set_ReleaseTime(aReleaseTime: Cardinal): HRESULT; stdcall;
begin
  Result := S_OK;
  fReleaseTime := aReleaseTime;
end;

function TDynamicAmplify.get_MaxAmplification(out aMaxAmplification: Cardinal): HRESULT; stdcall;
begin
  Result := S_OK;
  aMaxAmplification := fMaxAmplification;
end;

function TDynamicAmplify.set_MaxAmplification(aMaxAmplification: Cardinal): HRESULT; stdcall;
begin
  Result := S_OK;
  fMaxAmplification := aMaxAmplification;
end;

function TDynamicAmplify.get_CurrentAmplification(out aCurrentAmplification: Single): HRESULT; stdcall;
begin
  Result := S_OK;
  aCurrentAmplification := fLastAmp;
end;

end.
