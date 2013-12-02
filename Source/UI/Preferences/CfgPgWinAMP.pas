unit CfgPgWinAMP;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ConfigPage, StdCtrls, uWinAMP;

type
  TCPWinAMP = class(TConfigPageForm)
    cbEmulWinAMP: TCheckBox;
    lblGplugins: TLabel;
    lbWAPlug: TListBox;
    procedure lbWAPlugDblClick(Sender: TObject);
  private
  public
    procedure ReadPrefs; override;
    procedure UpdateLang; override;
    procedure ApplyChanges; override;
  end;

implementation

uses
  LACore;

{$R *.dfm}

procedure TCPWinAMP.ApplyChanges;
begin
  Core.Prefs.WriteBool('WinAMP.Emulate',cbEmulWinAMP.Checked);
end;

procedure TCPWinAMP.lbWAPlugDblClick(Sender: TObject);
begin
  WinAMP.GeneralConfig(lbWAPlug.ItemIndex);
  BringToFront;
end;

procedure TCPWinAMP.ReadPrefs;
begin
  with Core.Prefs do begin
    WinAMP.FillGeneralPluginList(lbWAPlug.Items);
    cbEmulWinAMP.Checked:=ReadBool('WinAMP.Emulate');
  end;  
end;

procedure TCPWinAMP.UpdateLang;
begin
  cbEmulWinAMP.Caption:=MS('Config.WinAMP.Emulate');
end;

end.
