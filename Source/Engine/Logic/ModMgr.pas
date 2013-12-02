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
unit ModMgr;

interface

uses
  Windows, Classes, Forms, SysUtils, Module, XMLPrefs, GlobalKeys;

type
  TModuleRec = packed record
    ModCls:TModuleClass;
    Id:String;
    Module:TModule;
  end;

  TModuleManager = class(TObject)
  private
    Prefs:TXMLPrefs;
    Mods:array of TModuleRec;

    procedure Init;
    procedure AddMod(AId:String;AModCls:TModuleClass);
  public
    constructor Create(APrefs:TXMLPrefs);
    destructor Destroy; override;

    procedure Load;
    procedure Update;
    procedure UnLoad;

    function GetAvailModules:TStringList;
    function GetModuleById(AId:String):TModule;

    function IsLoaded(AId:String):Boolean;
    procedure Enable(AId:String;Enabled:Boolean);
  end;

implementation

procedure TModuleManager.Init;
begin
  AddMod('GlobalKeys',TGlobalKeys);
  AddMod('Stub',TModule);
end;

procedure TModuleManager.AddMod;
var
  l:LongInt;
begin
  l:=Length(Mods);
  SetLength(Mods,l+1);
  with Mods[l] do begin
    Id:=AId;
    ModCls:=AModCls;
    Module:=NIL;
  end;
end;

constructor TModuleManager.Create;
begin
  inherited Create;
  Prefs:=APrefs;
  Init;
end;

procedure TModuleManager.Load;
var
  l:LongInt;
  ModId:String;
begin
  for l:=0 to Length(Mods)-1 do begin
    ModId:=Mods[l].Id;
    if Prefs.Bool[ModId+'.enabled'] then
      Mods[l].Module:=Mods[l].ModCls.Create(ModId,Prefs.CreateSubPrefs(ModId));
  end;
end;

procedure TModuleManager.UnLoad;
var
  l:LongInt;
begin
  for l:=0 to Length(Mods)-1 do
    if Assigned(Mods[l].Module) then
      FreeAndNIL(Mods[l].Module);
end;

destructor TModuleManager.Destroy;
begin
  Prefs.Free;
  inherited Destroy;
end;

function TModuleManager.GetModuleById;
var
  l:LongInt;
begin
  Result:=NIL;
  for l:=0 to Length(Mods)-1 do
    if SameText(Mods[l].Id,AId) then
      Result:=Mods[l].Module;
end;

procedure TModuleManager.Update;
var
  l:LongInt;
  ModId:String;
begin
  for l:=0 to Length(Mods)-1 do begin
    ModId:=Mods[l].Id;
    if Prefs.Bool[ModId+'.enabled'] then begin
      if (Mods[l].Module=NIL) then
        Mods[l].Module:=Mods[l].ModCls.Create(ModId,Prefs.CreateSubPrefs(ModId));
    end else begin
      if Assigned(Mods[l].Module) then
        FreeAndNIL(Mods[l].Module);
    end;
  end;
end;

function TModuleManager.GetAvailModules;
var
  l:LongInt;
begin
  Result:=TStringList.Create;
  for l:=0 to Length(Mods)-1 do
    Result.Add(Mods[l].Id);
end;

function TModuleManager.IsLoaded;
begin
  Result:=(GetModuleById(AId)<>NIL);
end;

procedure TModuleManager.Enable;
begin
  Prefs.Bool[AId+'.enabled']:=Enabled;
  Update;
end;

end.
