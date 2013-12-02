unit CfgPgSystem;

interface

uses
  Windows, SysUtils, ShellAPI, Variants, Classes, Graphics, Controls,
  Forms, Dialogs, ConfigPage, ExtCtrls, StdCtrls, Buttons;

type
  TCPSystem = class(TConfigPageForm)
    cbHighPriority: TCheckBox;
    cbCPUUsage: TCheckBox;
    cbMultiUser: TCheckBox;
    rbUserPrefs: TRadioGroup;
    pnExeName: TPanel;
    cbNotifyAboutNewVersion: TCheckBox;
    cbAllowDownloadFilters: TCheckBox;
    procedure cbMultiUserClick(Sender: TObject);
    procedure pnExeNameClick(Sender: TObject);
  private
  public
    procedure ReadPrefs; override;
    procedure UpdateLang; override;
    procedure ApplyChanges; override;
  end;

implementation

{$R *.dfm}

uses
  LACore;

procedure TCPSystem.ApplyChanges;
begin
  if INI.Bool['Plugins.CPUUsage.Enabled'] <> cbCPUUsage.Checked then
    NeedReloadApp := True;

  with Core.Prefs do begin
    WriteBool('Core.HighPriority',cbHighPriority.Checked);
    WriteBool('Plugins.CPUUsage.Enabled',cbCPUUsage.Checked);
    WriteBool('Core.AllowDownloadFilters',cbAllowDownloadFilters.Checked);
    WriteBool('App.IsMultiUser',cbMultiUser.Checked);
    WriteBool('Core.NotifyNewVerAvailable', cbNotifyAboutNewVersion.Checked);
    WriteInteger('App.UserPrefs',rbUserPrefs.ItemIndex);
  end;

  if cbHighPriority.Checked then
    SetPriorityClass(GetCurrentProcess,HIGH_PRIORITY_CLASS)
  else
    SetPriorityClass(GetCurrentProcess,NORMAL_PRIORITY_CLASS);
end;

procedure TCPSystem.ReadPrefs;
begin
  with Core.Prefs do begin
    cbHighPriority.Checked:=ReadBool('Core.HighPriority');
    cbCPUUsage.Checked:=ReadBool('Plugins.CPUUsage.Enabled');
    cbAllowDownloadFilters.Checked:=ReadBool('Core.AllowDownloadFilters');
    cbMultiUser.Checked:=ReadBool('App.IsMultiUser');
    if not(Core.SysHlp.IsNT) then begin
      cbMultiUser.Checked:=FALSE;
      cbMultiUser.Enabled:=FALSE;
    end;
    rbUserPrefs.ItemIndex:=ReadInteger('App.UserPrefs');
    cbNotifyAboutNewVersion.Checked := ReadBool('Core.NotifyNewVerAvailable');

    pnExeName.Caption:=' '+Application.ExeName;
  end;
end;

procedure TCPSystem.UpdateLang;
begin
  cbHighPriority.Caption:=MS('Config.HighPriority');
  cbCPUUsage.Caption:=MS('Config.CPUUsage');
  cbAllowDownloadFilters.Caption:=MS('Config.System.AllowDownloadFilters');
  cbMultiUser.Caption:=MS('Config.MultiUser');
  rbUserPrefs.Caption:=' '+MS('Config.UserPrefs')+' ';
  rbUserPrefs.Items[0]:=MS('Config.UserPrefs.0');
  rbUserPrefs.Items[1]:=MS('Config.UserPrefs.1');

  cbNotifyAboutNewVersion.Caption:=MS('Config.AutoUpdate.NewVersion');
end;

procedure TCPSystem.cbMultiUserClick(Sender: TObject);
begin
  rbUserPrefs.Enabled:=cbMultiUser.Checked;
end;

procedure TCPSystem.pnExeNameClick(Sender: TObject);
var Path: string;
begin
//  inherited;
  Path:=ExtractFilePath(Application.ExeName);
  ShellExecute(0,NIL,PAnsiChar(Path),NIL,NIL,SW_MAXIMIZE);
end;

end.
