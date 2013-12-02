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

unit AudioProcessor;

interface

uses
  Windows, SysUtils, 

  BaseClass, AudioFilter,

  dspConst, dspEQ, dspDynamicAmplify;

const
  CLSID_AudioProcessor: TGUID = '{4F985C0A-683A-488A-988B-4A7EBEDAD888}';
  IID_AudioProcessor: TGUID = '{4F985C0A-683A-488A-988B-4A7EBEDAD888}';

type
  TAudioProcessor = class(TAudioFilter, IAudioProcessor)
  private
    fConnected: Boolean;
    fEQ: TEQ;
    fDA: TDynamicAmplify;
  public
    constructor Create(ObjName: string; unk: IUnKnown; const clsid: TGUID);
    destructor Destroy; override;
    procedure ProcessPCMData(Buffer: Pointer; Stream: PDSAudioStream); override;
    procedure Flush; override;
    procedure MediaTypeChanged(Stream: PDSAudioStream); override;
    // EQ
    function get_EQEnabled(out Enabled: BOOL): HRESULT; stdcall;
    function set_EQEnabled(Enabled: BOOL): HRESULT; stdcall;
    function get_EQPreAmp(out Amp: Single): HRESULT; stdcall;
    function set_EQPreAmp(Amp: Single): HRESULT; stdcall;
    function get_EQGainDB(Band: integer; out Value: Single): HRESULT; stdcall;
    function set_EQGainDB(Band: integer; Value: Single): HRESULT; stdcall;
    // DA
    function get_DAEnabled(out Enabled: BOOL): HRESULT; stdcall;
    function set_DAEnabled(Enabled: BOOL): HRESULT; stdcall;
    function get_DAMaxAmp(out Value: Cardinal): HRESULT; stdcall;
    function set_DAMaxAmp(Value: Cardinal): HRESULT; stdcall;

    function IsConnected: BOOL; stdcall;
  end;

implementation

constructor TAudioProcessor.Create(ObjName: string; unk: IUnknown; const clsid: TGUID);
begin
  inherited Create(ObjName, unk, clsid);
  fEQ := TEQ.Create;
  fDA := TDynamicAmplify.Create;
end;

destructor TAudioProcessor.Destroy;
begin
  fEQ.Free;
  fDA.Free;
  inherited Destroy;
end;

procedure TAudioProcessor.ProcessPCMData(Buffer: Pointer; Stream: PDSAudioStream);
begin
  fEQ.Process(Buffer, Stream.Size, Stream.Frequency, Stream.Bits,
      Stream.Channels, Stream.Float);
  fDA.Process(Buffer, Stream.Size, Stream.Frequency, Stream.Bits,
      Stream.Channels, Stream.Float);
end;

procedure TAudioProcessor.Flush;
begin
  fEQ.Flush;
end;

procedure TAudioProcessor.MediaTypeChanged(Stream: PDSAudioStream);
begin
  Flush;
end;

function TAudioProcessor.get_EQEnabled(out Enabled: BOOL): HRESULT;
begin
  Enabled := fEQ.Enabled;
  Result := S_OK;
end;

function TAudioProcessor.set_EQEnabled(Enabled: BOOL): HRESULT;
begin
  fEQ.Enabled := Enabled;
  Result := S_OK;
end;

function TAudioProcessor.get_EQPreAmp(out Amp: Single): HRESULT;
begin
  Amp := fEQ.PreAmp;
  Result := S_OK;
end;

function TAudioProcessor.set_EQPreAmp(Amp: Single): HRESULT;
begin
  fEQ.PreAmp := Amp;
  Result := S_OK;
end;

function TAudioProcessor.get_EQGainDB(Band: integer; out Value: Single): HRESULT;
begin
  Value := fEQ.GainDB[Band];
  Result := S_OK;
end;

function TAudioProcessor.set_EQGainDB(Band: integer; Value: Single): HRESULT;
begin
  fEQ.GainDB[Band] := Value;
  Result := S_OK;
end;

function TAudioProcessor.IsConnected: BOOL;
begin
  Result := fConnected;
end;

function TAudioProcessor.get_DAEnabled(out Enabled: BOOL): HRESULT;
begin
  Enabled := fDA.Enabled;
  Result := S_OK;
end;

function TAudioProcessor.set_DAEnabled(Enabled: BOOL): HRESULT;
begin
  fDA.Enabled := Enabled;
  Result := S_OK;
end;

function TAudioProcessor.get_DAMaxAmp(out Value: Cardinal): HRESULT;
begin
  fDA.get_MaxAmplification(Value);
  Result := S_OK;
end;

function TAudioProcessor.set_DAMaxAmp(Value: Cardinal): HRESULT;
begin
  fDA.set_MaxAmplification(Value);
  Result := S_OK;
end;

end.

