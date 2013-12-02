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
unit FilterCommander;

interface

uses
  SysUtils, Windows, Registry;

type
  TFilterCommander = class(TObject)
  private
  public
    FriendlyName: string;
    Merit: DWORD;
    Company: string;
    ModuleName: string;
    procedure ExamineFilter(CLSID: TGUID);
    function GetCompanyName(ModuleName: string): string;    
  end;

implementation

uses
  FileVersionInfo;

{ TFilterCommander }

procedure TFilterCommander.ExamineFilter(CLSID: TGUID);
var
  R: TRegistry;
  DSize: Integer;
  Buf: array of DWORD;
begin
  FriendlyName:='';
  ModuleName:='';
  Company:='';
  Merit:=0;

  R := TRegistry.Create;
  try
    R.RootKey:=HKEY_LOCAL_MACHINE;
    R.OpenKeyReadOnly('\SOFTWARE\Classes\CLSID\{083863F1-70DE-11D0-BD40-00A0C911CE86}\Instance\'+
    GUIDToString(CLSID));
    FriendlyName:= R.ReadString('FriendlyName');

    DSize:=R.GetDataSize('FilterData');
    if DSize>0 then begin
      SetLength(Buf, DSize);
      R.ReadBinaryData('FilterData',PDword(Buf)^, DSize);
    end;

    if DSize > 4 then 
    Merit:=Buf[1];
    R.CloseKey;

    R.OpenKeyReadOnly('\SOFTWARE\Classes\CLSID\'+GUIDToString(CLSID)+'\InprocServer32');
    ModuleName:=R.ReadString('');

    R.CloseKey;
  finally
    R.CloseKey;
    R.Free;
  end;
  if FileExists(ModuleName) then
    Company:=GetCompanyName(ModuleName);
end;

function TFilterCommander.GetCompanyName(ModuleName: string): string;
var
  FV: TFileVersionInfo;
begin
  FV:=TFileVersionInfo.Create(NIL);
  FV.Filename:=Modulename;
  Result:=FV.CompanyName;
  FV.Free;
end;

initialization

finalization

end.
