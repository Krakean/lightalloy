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
unit GlobalKeys;

interface

uses
  Windows, Classes, Messages, SysUtils, CmdC, XMLPrefs, Module;

type
  TSysHotKey = record
    A:ATOM;
    Action:LongInt;
  end;

  TGlobalKeys = class(TModule)
  private
    SysHotKeys:array of TSysHotKey;
    HotKeyWnd:HWND;

    procedure ExtractKeyMods(Key:String;var KeyMod:DWORD;var GenKey:DWORD);
    procedure WndProc(var Message:TMessage);

    procedure SetSystemHotKey(AKey:String; ACmd:Word);
    procedure FreeSystemKeys;
    procedure Execute(Action:LongInt);
  public
    constructor Create(AId:String;APrefs:TXMLPrefs); override;
    destructor Destroy; override;
  end;

implementation

uses
  LACore, CmdExec, OtherGlobalVars, XML;

constructor TGlobalKeys.Create;
var
  l: integer;
  XN, XNP: TXMLNode;
begin
  inherited Create(AId,APrefs);
  HotKeyWnd:=Classes.AllocateHWnd(WndProc);
  XNP := Core.XTree.Root.Node('GlobalKeys');
  for l:=0 to Length(XNP.Nodes)-1 do
  begin
    XN := XNP.Nodes[l];
    if SameText(XN.Tag, 'Keys') then begin
      SetSystemHotKey(XN.Attr('Key'), Center.ExtractCmdNum(XN.Attr('Command')));
      if Core.Prefs.ReadBool('Modules.GlobalKeys.AltMode') then
        if (XN.Attr('MMKey')<>'') and Core.Prefs.ReadBool('Modules.GlobalKeys.MMKeys') then
          SetSystemHotKey(XN.Attr('MMKey'), Center.ExtractCmdNum(XN.Attr('Command')));
    end;
  end;
end;

destructor TGlobalKeys.Destroy;
begin
  Classes.DeAllocateHWnd(HotKeyWnd);
  FreeSystemKeys;
  inherited Destroy;
end;

procedure TGlobalKeys.Execute;
begin
  if not DisableGlobalKeys then begin
    ExecuteLACommand(Action);
  end;
end;

procedure TGlobalKeys.ExtractKeyMods;
var
  l:LongInt;
begin
  KeyMod:=0;

  if SameText('Ctrl+',Copy(Key,1,5)) then begin
    KeyMod:=KeyMod or MOD_CONTROL;
    Key:=Copy(Key,6,Length(Key)-5);
  end;
  if SameText('Alt+',Copy(Key,1,4)) then begin
    KeyMod:=KeyMod or MOD_ALT;
    Key:=Copy(Key,5,Length(Key)-4);
  end;
  if SameText('Shift+',Copy(Key,1,6)) then begin
    KeyMod:=KeyMod or MOD_SHIFT;
    Key:=Copy(Key,7,Length(Key)-6);
  end;

  GenKey:=0;
  for l:=0 to 255 do
    if (Center.VirtualKeyName(l,[])=Key) then
      GenKey:=l;
end;

procedure TGlobalKeys.FreeSystemKeys;
var
  l:LongInt;
begin
  for l:=0 to Length(SysHotKeys)-1 do begin
    UnregisterHotKey(HotKeyWnd,SysHotKeys[l].A);
    GlobalDeleteAtom(SysHotKeys[l].A);
  end;
  SetLength(SysHotKeys,0);
end;

procedure TGlobalKeys.SetSystemHotKey;
var
  Len:LongInt;
  KeyMods,GenKey:DWORD;
  HotKey:TSysHotKey;
begin
  HotKey.A:=GlobalAddAtom(PChar(AKey));
  HotKey.Action:=ACmd;

  ExtractKeyMods(AKey,KeyMods,GenKey);
  RegisterHotKey(HotKeyWnd,HotKey.A,KeyMods,GenKey);

  Len:=Length(SysHotKeys);
  SetLength(SysHotKeys,Len+1);
  SysHotKeys[Len]:=HotKey;
end;

procedure TGlobalKeys.WndProc;
var
  l:LongInt;
begin
  if (Message.Msg=WM_HOTKEY) then
  begin
    for l:=0 to Length(SysHotKeys)-1 do
      if (Message.wParam=SysHotKeys[l].A) then
        Execute(SysHotKeys[l].Action);
  end
  else
    with Message do
      Result:=DefWindowProc(HotKeyWnd,Msg,wParam,lParam);
end;

end.
