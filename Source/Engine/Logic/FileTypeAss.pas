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
unit FileTypeAss;

interface

uses
  Windows, Classes, Registry, ShlObj, SysUtils;

type
  TFileTypeAction = packed record
    Code:String;
    Title:String;
    Command:String;
  end;

  TFileTypeMenu = packed record
    DefaultAction:String;
    Actions:array of TFileTypeAction;
  end;

  TFileTypeAssociator = class(TObject)
  private
    R:TRegistry;
    Path:String;
    AppId:String;

    procedure SetMonikerKey;
    procedure BackupAndSet(NewValue:String);
    procedure RestoreValue;
  public
    Ext:String;

    constructor Create(AId:String);
    destructor Destroy; override;

    procedure SetIcon(IconPath:String);
    procedure SetDescription(Description:String);
    procedure SetMenu(AMenu:TFileTypeMenu);
    function GetDefaultCommand:String;

    procedure Rollback;

    procedure UpdateExplorerIconCache;
  end;

  TDVDAssociator = class(TObject)
  public
    AppId:String;

    function GetAutoRunApp:String;
    procedure SetAutoRunApp(Icon,Cmd:String);
    procedure Rollback;
  end;

  TCDAssociator = class(TObject)
  end;

implementation

{ TFileTypeAssociator }

procedure TFileTypeAssociator.BackupAndSet;
var
  Value:String;
begin
  Value:=R.ReadString('');
  if not(SameText(Value,NewValue)) then begin
    R.WriteString(AppID+'.Backup',Value);
    R.WriteString('',NewValue);
  end;
end;

constructor TFileTypeAssociator.Create;
begin
  inherited Create;
  AppId:=AId;
  Ext:='DAT';
end;

destructor TFileTypeAssociator.Destroy;
begin
  inherited Destroy;
end;

function TFileTypeAssociator.GetDefaultCommand;
var
  ExtMoniker,Path,DefAct:String;
begin
  Result:='';

  R := TRegistry.Create;
  try
    R.RootKey:=HKEY_CLASSES_ROOT;
    R.OpenKeyReadOnly('\.'+Ext);
    ExtMoniker:=R.ReadString('');

    Path:='\'+ExtMoniker+'\Shell';
    R.OpenKeyReadOnly(Path);
    DefAct:=R.ReadString('');

    Path:=Path+'\'+DefAct;
    R.OpenKeyReadOnly(Path);
    if not(R.KeyExists('DropTarget'))
    and not(R.ValueExists('LegacyDisable')) then begin
      Path:=Path+'\Command';
      if R.OpenKey(Path,false) then
        Result := R.ReadString('');
    end;
  finally
    R.CloseKey;
    R.Free;
  end;
end;

procedure TFileTypeAssociator.RestoreValue;
var
  Id,Value:String;
begin
  Id:=AppID+'.Backup';
  if R.ValueExists(Id) then begin
    Value:=R.ReadString(Id);
    R.WriteString('',Value);
    R.DeleteValue(Id);
  end;
end;

procedure TFileTypeAssociator.Rollback;
var
  ExtMoniker,Key:String;
  Keys:TStringList;
  l:LongInt;
begin
  R:=TRegistry.Create;
  try
    R.RootKey:=HKEY_CLASSES_ROOT;

// --- remove moniker ---------------
    Path:='\.'+Ext;
    R.OpenKey(Path,TRUE);
    ExtMoniker:=R.ReadString('');
    RestoreValue;
    R.CloseKey;

    if not(SameText(ExtMoniker,Ext+'file')) then
    exit;//  raise Exception.Create(ExtMoniker+'@'+Ext+'file');   // íàôèãà òóò ýòîò ýêñåïøí? õç õç õç

    Path:='\'+ExtMoniker;
// --- remove description ---------------
    R.OpenKey(Path,TRUE);
    RestoreValue;
    R.CloseKey;
// --- remove icon ---------------
    R.OpenKey(Path+'\DefaultIcon',TRUE);
    RestoreValue;
    R.CloseKey;
// --- remove menu ---------------
    R.OpenKey(Path+'\Shell',TRUE);
    RestoreValue;

    Keys:=TStringList.Create;
    R.GetKeyNames(Keys);
    R.CloseKey;
    for l:=0 to Keys.Count-1 do begin
      Key:=Keys[l];
      R.OpenKey(Path+'\Shell\'+Key,TRUE);
      if (R.ReadString(AppID+'.Delete')='Delete') then begin
        R.CloseKey;
        R.DeleteKey(Path+'\Shell\'+Key);
      end else begin
        RestoreValue;

        if R.ValueExists(AppID+'.Backup.LegacyDisable') then
          R.RenameValue(AppID+'.Backup.LegacyDisable','LegacyDisable');

        if R.KeyExists(AppID+'.Backup.DropTarget') then
          R.MoveKey(AppID+'.Backup.DropTarget','DropTarget',TRUE);

        if R.KeyExists(AppID+'.Backup.ddeexec') then
          R.MoveKey(AppID+'.Backup.ddeexec','ddeexec',TRUE);

        R.CloseKey;
        R.OpenKey(Path+'\Shell\'+Key+'\Command',TRUE);
        RestoreValue;
        R.CloseKey;
      end;
    end;
    Keys.Free;
  except
  end;
  R.Free;
end;

procedure TFileTypeAssociator.SetDescription(Description: String);
begin
  R:=TRegistry.Create;
  try
    SetMonikerKey;

    if not(R.OpenKey(Path,TRUE)) then
      raise Exception.Create('');
    BackupAndSet(Description);
    R.CloseKey;
  except
  end;
  R.Free;
end;

procedure TFileTypeAssociator.SetIcon;
begin
  R:=TRegistry.Create;
  try
    SetMonikerKey;

    if not(R.OpenKey(Path+'\DefaultIcon',TRUE)) then
      raise Exception.Create('');
    BackupAndSet(IconPath);
    R.CloseKey;
  except
  end;
  R.Free;
end;

procedure TFileTypeAssociator.SetMenu;
var
  l:LongInt;
  A:TFileTypeAction;
  Exists:Boolean;
begin
  R:=TRegistry.Create;
  try
    SetMonikerKey;

    if not(R.OpenKey(Path+'\Shell',TRUE)) then
      raise Exception.Create('');
    BackupAndSet(AMenu.DefaultAction);

    for l:=0 to Length(AMenu.Actions)-1 do begin
      A:=AMenu.Actions[l];
      Exists:=R.KeyExists(Path+'\Shell\'+A.Code);
      R.OpenKey(Path+'\Shell\'+A.Code,TRUE);
      if not(Exists) then
        R.WriteString(AppID+'.Delete','Delete');

      if (A.Title<>'') then
        BackupAndSet(A.Title);

      if R.ValueExists('LegacyDisable') then begin
        R.RenameValue('LegacyDisable',AppID+'.Backup.LegacyDisable');
      end;

      if R.KeyExists('DropTarget') then begin
        if R.KeyExists(AppID+'.Backup.DropTarget') then
          R.DeleteKey(AppID+'.Backup.DropTarget');
        R.MoveKey('DropTarget',AppID+'.Backup.DropTarget',TRUE);
      end;

      if R.KeyExists('ddeexec') then begin
        if R.KeyExists(AppID+'.Backup.ddeexec') then
          R.DeleteKey(AppID+'.Backup.ddeexec');
        R.MoveKey('ddeexec',AppID+'.Backup.ddeexec',TRUE);
      end;

      R.OpenKey(Path+'\Shell\'+A.Code+'\Command',TRUE);
      BackupAndSet(A.Command);
    end;
  except
  end;
  R.Free;
end;

procedure TFileTypeAssociator.SetMonikerKey;
var
  ExtMoniker:String;
begin
  R.RootKey:=HKEY_CLASSES_ROOT;

  Path:='\.'+Ext;
  if not(R.OpenKey(Path,TRUE)) then
    raise Exception.Create('');

  BackupAndSet(Ext+'file');
  ExtMoniker:=R.ReadString('');
  R.CloseKey;

  Path:='\'+ExtMoniker;
end;

procedure TFileTypeAssociator.UpdateExplorerIconCache;
begin
  SHChangeNotify(SHCNE_ASSOCCHANGED,SHCNF_IDLIST,NIL,NIL);
end;

{ TDVDAssociator }

function TDVDAssociator.GetAutoRunApp;
var
  Path:string;
  R:TRegistry;
begin
  Result:='';

  R:=TRegistry.Create;
  try
    R.RootKey:=HKEY_CLASSES_ROOT;
    Path:='\DVD\Shell';
    R.OpenKeyReadOnly(Path);
    Path:=Path+'\'+R.ReadString('')+'\Command';
    R.OpenKeyReadOnly(Path);
    Result:=R.ReadString('');
  except
  end;
  R.Free;
end;

procedure TDVDAssociator.Rollback;
var
  R:TRegistry;
begin
  R:=TRegistry.Create;
  try
    R.RootKey:=HKEY_CLASSES_ROOT;

    R.OpenKey('\DVD',TRUE);
    R.WriteString('','Digital Video Disc');

    R.OpenKey('\DVD\DefaultIcon',TRUE);
    R.WriteString('',R.ReadString('LA.Backup'));

    R.OpenKey('\DVD\Shell',TRUE);
    R.WriteString('',R.ReadString('LA.Backup'));

    R.OpenKey('\DVD\Shell\Play\Command',TRUE);
    R.WriteString('',R.ReadString('LA.Backup'));
  except
  end;
  R.Free;
end;

procedure TDVDAssociator.SetAutoRunApp;
var
  R:TRegistry;
begin
  R:=TRegistry.Create;
  try
    R.RootKey:=HKEY_CLASSES_ROOT;

    R.OpenKey('\DVD',TRUE);
    R.WriteString('','Digital Video Disc');
    R.OpenKey('\DVD\DefaultIcon',TRUE);
    R.WriteString(AppId+'.Backup',R.ReadString(''));
    R.WriteString('',Icon);

    R.OpenKey('\DVD\Shell',TRUE);
    R.WriteString(AppId+'.Backup',R.ReadString(''));
    R.WriteString('','Play');

    R.OpenKey('\DVD\Shell\Play',TRUE);
    R.WriteString('','Play');
    R.OpenKey('\DVD\Shell\Play\Command',TRUE);
    R.WriteString(AppId+'.Backup',R.ReadString(''));
    R.WriteString('',Cmd);
  except
  end;
  R.Free;
end;

end.
