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
unit ModList;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, CheckLst, Module, XMLPrefs;

type
  TModuleList = class(TModule)
  private
  protected
    function CreatePrefsForm:TForm; override;
  public
    procedure ApplyChanges; override;
  end;

  TModListForm = class(TForm)
    clbMods: TCheckListBox;
  private
  public
    Module:TModuleList;

    procedure Init(AModule:TModuleList);
  end;

implementation

{$R *.dfm}

uses
  LACore, ModMgr;

procedure TModuleList.ApplyChanges;
var
  CLB:TCheckListBox;
  l:LongInt;
begin
  inherited ApplyChanges;
  if Assigned(PrefsForm) then begin
    CLB:=(PrefsForm as TModListForm).clbMods;
    for l:=0 to CLB.Count-1 do
      Core.Prefs.WriteBool('Modules.'+CLB.Items[l]+'.enabled',CLB.Checked[l]);
  end;
end;

function TModuleList.CreatePrefsForm;
begin
  Result:=TModListForm.Create(NIL);
  (Result as TModListForm).Init(Self);
end;

{ TModListForm }

procedure TModListForm.Init;
var
  SL:TStringList;
  l:LongInt;
begin
  Module:=AModule;

  SL:=Core.ModMgr.GetAvailModules;
  clbMods.Clear;
  for l:=0 to SL.Count-1 do begin
    clbMods.Items.Add(SL[l]);
    clbMods.Checked[l]:=Core.Prefs.ReadBool('Modules.'+SL[l]+'.enabled');
  end;
  SL.Free;
end;

end.
