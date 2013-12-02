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

unit DAMdl;

interface

uses
  SysUtils, DShowHlp;

type
  TDAModel=class(TObject)
  private
    fEnabled: Boolean;
    fMaxAmplify: Cardinal;
    function GetEnabled: Boolean;
    procedure SetEnabled(const Value: Boolean);
    function GetMaxAmp: Cardinal;
    procedure SetMaxAmp(const Value: Cardinal);
  public
    constructor Create(DSH:TDirectShowHelper);
    property DAEnabled: Boolean read GetEnabled write SetEnabled;
    property MaxAmp: Cardinal read GetMaxAmp write SetMaxAmp;
  end;

implementation

uses
  LACore;

constructor TDAModel.Create;
begin
  inherited Create;
  fEnabled := Core.Prefs.ReadBool('Sound.Normalization.Enabled');
  fMaxAmplify := Core.Prefs.ReadInteger('Sound.Normalization.MaxAmp');
  DSH.SetDAEnabled(fEnabled);
  DSH.SetDAMaxAmplify(fMaxAmplify*1000);
end;

function TDAModel.GetEnabled: Boolean;
begin
  Result:=Core.Prefs.ReadBool('Sound.Normalization.Enabled');
end;

procedure TDAModel.SetEnabled(const Value: Boolean);
begin
  fEnabled:=Value;
  Core.Prefs.WriteBool('Sound.Normalization.Enabled',fEnabled);
  DSH.SetDAEnabled(fEnabled);
end;

function TDAModel.GetMaxAmp: Cardinal;
begin
  Result:=Core.Prefs.ReadInteger('Sound.Normalization.MaxAmp');
end;

procedure TDAModel.SetMaxAmp(const Value: Cardinal);
begin
  fMaxAmplify:=Value;
  Core.Prefs.WriteInteger('Sound.Normalization.MaxAmp',fMaxAmplify);
  DSH.SetDAMaxAmplify(fMaxAmplify*1000);
end;

initialization

finalization

end.
 