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
// xx.xx.07  1.0   VtX  Created                                              //
///////////////////////////////////////////////////////////////////////////////

unit EQMdl;

interface

uses
  SysUtils, DShowHlp, DSPConst;

type
  TEQModel=class(TObject)
  private
    fEnabled: Boolean;
    function GetPreAmp: Integer;
    procedure SetPreAmp(Value: Integer);
    function GetBandVal(Index: Byte): Integer;
    procedure SetBandVal(Index: Byte; const Value: Integer);
  public
    constructor Create(DSH:TDirectShowHelper);

    procedure UpdateBands;
    procedure ResetBands;
    property EQPreAmp: Integer read GetPreAmp write SetPreAmp;
    property EQBands[Index: Byte]: Integer read GetBandVal write SetBandVal;
    property EQEnabled: Boolean read fEnabled write fEnabled;
  end;

implementation

uses
  LACore;

{ EQWModel }

constructor TEQModel.Create;
begin
  inherited Create;
  fEnabled := Core.Prefs.ReadBool('Sound.Equalizer.Enabled');
end;

function TEQModel.GetBandVal;
begin
  Result:=0;
  if (Index < MAX_EQ_BANDS) then
    Result:=Core.Prefs.ReadInteger('Sound.Equalizer.Band'+IntToStr(Index));
end;

procedure TEQModel.SetBandVal;
begin
  if (Index < MAX_EQ_BANDS) then
  begin
    Core.Prefs.WriteInteger('Sound.Equalizer.Band'+IntToStr(Index),Value);
    DSH.SetEQBand(Index, -Trunc(Core.Prefs.ReadInteger('Sound.Equalizer.Band'+IntToStr(Index)))/10);
  end;
end;

function TEQModel.GetPreAmp: Integer;
begin
  Result:=Core.Prefs.ReadInteger('Sound.Equalizer.Amplify');
end;

procedure TEQModel.SetPreAmp(Value: Integer);
begin
  Core.Prefs.WriteInteger('Sound.Equalizer.Amplify',Value);
  DSH.SetEQPreAmp(-Trunc(Core.Prefs.ReadInteger('Sound.Equalizer.Amplify'))/10);
end;

procedure TEQModel.ResetBands;
var
  i: Byte;
begin
  for i:=0 to MAX_EQ_BANDS-1 do begin
    SetBandVal(i,0);
  end;
  SetPreAmp(0);
end;

procedure TEQModel.UpdateBands;
var
  i: Byte;
begin
  for i:=0 to MAX_EQ_BANDS-1 do begin
    SetBandVal(i,Core.Prefs.ReadInteger('Sound.Equalizer.Band'+IntToStr(i)));
  end;
  SetPreAmp(Core.Prefs.ReadInteger('Sound.Equalizer.Amplify'));
end;

initialization

finalization

end.
 