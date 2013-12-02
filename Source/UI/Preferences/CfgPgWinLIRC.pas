unit CfgPgWinLIRC;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ConfigPage, StdCtrls, ExtCtrls, ImgList, Buttons, WinLIRC,
  ComCtrls;

type
  TCPWinLIRC = class(TConfigPageForm)
    cbWIRCEnable: TCheckBox;
    GroupBox1: TGroupBox;
    cbWIRCRepeatDelay: TCheckBox;
    cbWIRCSound: TCheckBox;
    ilState: TImageList;
    Timer: TTimer;
    cbShowUnhandled: TCheckBox;
    gbState: TGroupBox;
    imState: TImage;
    lbState: TLabel;
    GroupBox4: TGroupBox;
    cbAutoLoad: TCheckBox;
    edPath: TEdit;
    btPath: TButton;
    Label1: TLabel;
    BitBtn1: TBitBtn;
    BitBtn3: TBitBtn;
    GroupBox2: TGroupBox;
    Label9: TLabel;
    Label10: TLabel;
    edWIRCsrv: TEdit;
    edWIRCport: TEdit;
    GroupBox5: TGroupBox;
    tbClickVol: TTrackBar;
    cbAutoStop: TCheckBox;
    gbRepeatDelayValue: TGroupBox;
    tbRepeatDelayVal: TTrackBar;
    procedure TimerTimer(Sender: TObject);
    procedure cbWIRCEnableClick(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
    procedure btPathClick(Sender: TObject);
    procedure cbRepeatDelay_OnClick(Sender: TObject);
  private
    CurState:LongInt;
  public
    procedure ReadPrefs; override;
    procedure UpdateLang; override;
    procedure ApplyChanges; override;
  end;

implementation

{$R *.dfm}

uses
  LACore, Config;

procedure TCPWinLIRC.ApplyChanges;
begin
  with Core.Prefs do begin
    WriteBool('Modules.WinLIRC.Enabled',cbWIRCenable.Checked);
    WriteBool('Modules.WinLIRC.AutoLoad',cbAutoLoad.Checked);
    WriteString('Modules.WinLIRC.Server',edWIRCSrv.Text);
    WriteString('Modules.WinLIRC.Port',edWIRCPort.Text);
    WriteBool('Modules.WinLIRC.Sound.Enabled',cbWIRCSound.Checked);
    WriteBool('Modules.WinLIRC.RepeatDelay',cbWIRCRepeatDelay.Checked);
    WriteBool('Modules.WinLIRC.ShowUnhandled',cbShowUnhandled.Checked);
    WriteString('Modules.WinLIRC.Server.Path',edPath.Text);
    Int['Modules.WinLIRC.Sound.Volume']:=tbClickVol.Position;
    Int['Modules.WinLIRC.RepeatDelayValue']:=tbRepeatDelayVal.Position;
    Bool['Modules.WinLIRC.AutoStop']:=cbAutoStop.Checked;
  end;
end;

procedure TCPWinLIRC.ReadPrefs;
begin
  with Core.Prefs do begin
    cbWIRCenable.Checked:=ReadBool('Modules.WinLIRC.Enabled');
    cbAutoLoad.Checked:=ReadBool('Modules.WinLIRC.AutoLoad');
    cbAutoStop.Checked:=ReadBool('Modules.WinLIRC.AutoStop');
    edWIRCSrv.Text:=ReadString('Modules.WinLIRC.Server');
    edWIRCPort.Text:=ReadString('Modules.WinLIRC.Port');
    cbWIRCRepeatDelay.Checked:=ReadBool('Modules.WinLIRC.RepeatDelay');
    cbWIRCSound.Checked:=ReadBool('Modules.WinLIRC.Sound.Enabled');
    cbShowUnhandled.Checked:=ReadBool('Modules.WinLIRC.ShowUnhandled');
    edPath.Text:=ReadString('Modules.WinLIRC.Server.Path');
    tbClickVol.Position:=Int['Modules.WinLIRC.Sound.Volume'];
    tbRepeatDelayVal.Position:=Int['Modules.WinLIRC.RepeatDelayValue'];
  end;
end;

procedure TCPWinLIRC.UpdateLang;
begin
  gbState.Caption:=MS('Config.WIRC.State');
  lbState.Caption:=MS('Config.WIRC.Offline');
  label1.Caption:=MS('Config.WIRC.LabelPath');
  BitBtn1.Caption:=MS('Config.WIRC.Start');
  BitBtn3.Caption:=MS('Command.105');

  GroupBox2.Caption:=MS('Config.WIRC.Parametrs');
  Label9.Caption:=MS('Config.WIRC.Server');
  Label10.Caption:=MS('Config.WIRC.Port');

  GroupBox1.Caption:=MS('Config.WIRC.Options');

  cbWIRCEnable.Caption:=MS('Config.WIRC.Enable');
  cbWIRCRepeatDelay.Caption:=MS('Config.WIRC.Delay');
  cbWIRCSound.Caption:=MS('Config.WIRC.Sound');
  cbAutoLoad.Caption:=MS('Config.WIRC.AutoLoad');
  cbAutoStop.Caption:=MS('Config.WIRC.AutoStop');
  cbShowUnhandled.Caption:=MS('Config.WIRC.ShowUnhandled');

  Groupbox5.Caption:=' '+MS('Config.WIRC.ClickLoudness')+' ';
  gbRepeatDelayValue.Caption:=MS('Config.WIRC.RepeatDelay');

  TimerTimer(NIL);
end;

procedure TCPWinLIRC.TimerTimer(Sender: TObject);
var
  Idx:LongInt;
  S:String;
begin
  Idx:=0;
  S:='Disconnected';
  if Core.Wirc.IsConnecting then begin
    Idx:=1;
    S:='Connecting';
  end;
  if Core.Wirc.IsConnected then begin
    Idx:=2;
    S:='Connected';
  end;

  if (CurState<>Idx) then begin
    ilState.GetBitmap(Idx,imState.Picture.Bitmap);
    imState.Repaint;
    lbState.Caption:=S;
    CurState:=Idx;

  end;
end;

procedure TCPWinLIRC.cbWIRCEnableClick(Sender: TObject);
begin
  Core.Wirc.Active:=cbWIRCEnable.Checked;
end;

procedure TCPWinLIRC.BitBtn1Click(Sender: TObject);
begin
  Core.WIRC.StartServer;
end;

procedure TCPWinLIRC.BitBtn3Click(Sender: TObject);
begin
  Core.WIRC.StopServer;
end;

procedure TCPWinLIRC.btPathClick(Sender: TObject);
var
  OD:TOpenDialog;
begin
  OD:=TOpenDialog.Create(Application);
  if frConfig.ConfigPageAlwayOnTop.Enabled then frConfig.SwitchCfgTopPos(OD.Handle, True);
  OD.Filter:='Exe files (*.exe)|(*.exe)|Any File (*.*)|(*.*)';
  
  OD.InitialDir:=ExtractFilePath(edPath.Text);
  if not(FileExists(edPath.Text)) then
    OD.InitialDir:=Core.ExePath+'WinLIRC';

  OD.FileName:='*.exe';
  if (OD.Execute) then begin
    edPath.Text:=OD.FileName;
  end;
  if frConfig.ConfigPageAlwayOnTop.Enabled then frConfig.SwitchCfgTopPos(OD.Handle, False);  
  OD.Free;
end;

procedure TCPWinLIRC.cbRepeatDelay_OnClick(Sender: TObject);
begin
  inherited;
  // ...
  {if (cbWIRCRepeatDelay.Checked) then
    cbRepeatDelayValue.Enabled := True
  else
    cbRepeatDelayValue.Enabled := False }
    if cbWIRCRepeatDelay.Checked then
tbRepeatDelayVal.Enabled := Sender = cbWIRCRepeatDelay
  else
  tbRepeatDelayVal.Enabled := false;
end;

end.
