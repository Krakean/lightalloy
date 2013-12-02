unit CfgPgVideo;

interface

uses
  Windows, SysUtils, Variants, Classes, Graphics, Controls, Forms, Registry,
  Dialogs, ConfigPage, StdCtrls, ComCtrls, Menus;

type
  TCPVideo = class(TConfigPageForm)
    cbForceOverlay: TCheckBox;
    cbVideoProcessor: TCheckBox;
    lbAspectRatioCustom: TLabel;
    edAspectRatio: TEdit;
    gbSeek: TGroupBox;
    lbKeySeek: TLabel;
    lbKeyJump: TLabel;
    edKeySeek: TEdit;
    cbKeyFrameSeek: TCheckBox;
    edKeyJump: TEdit;
    gbFullScreen: TGroupBox;
    cbFullScrMode: TCheckBox;
    btScrMode: TButton;
    pmScrModes: TPopupMenu;
    Resolutin1: TMenuItem;
    gbSpeedCgange: TGroupBox;
    Label1: TLabel;
    tbSpeed: TTrackBar;
    Label2: TLabel;
    lbSpeed: TLabel;
    lbSpeedChange: TLabel;
    gbSSDir: TGroupBox;
    edScrShDir: TEdit;
    btScrShDir: TButton;
    rbBMP: TRadioButton;
    rbJPG: TRadioButton;
    cbStayOnTopInFullScreenMode: TCheckBox;
    cbCreateRelatedDirectoryName: TCheckBox;
    cbAspectRatio: TComboBox;
    cbAspectRatioForced: TCheckBox;
    gbAspectRatio: TGroupBox;
    cbOnTopWhilePlay: TCheckBox;
    cbbVideoRenderer: TComboBox;
    lblRenderer: TLabel;
    cbHardwareVideoProcessing: TCheckBox;
    procedure cbFullScrModeClick(Sender: TObject);
    procedure tbSpeedChange(Sender: TObject);
    procedure btScrModeClick(Sender: TObject);
    procedure btScrShDirClick(Sender: TObject);
    procedure cbAspectRatioForcedClick(Sender: TObject);
  private
    ScrWidth,ScrHeight,ScrDepth:LongInt;
    RIndex: Byte;
    procedure FillRenderers;
  public
    procedure ReadPrefs; override;
    procedure UpdateLang; override;
    procedure ApplyChanges; override;

    procedure EnumerateScrModes;
    procedure OnScrModeSelect(Sender:TObject);
    procedure SortScrModes;
  end;

implementation

{$R *.dfm}

uses
  LACore, Config, FilterBase;

var
  ScrMode:array of record
    Width,Height,Depth:longint;
  end;

procedure TCPVideo.ApplyChanges;
var
  i: Byte;
begin
  with Core.Prefs do begin
    WriteInteger('Video.SpeedPlayRate',tbSpeed.Position);

    WriteBool('Video.CreateRelatedDirectoryName', cbCreateRelatedDirectoryName.Checked);
    WriteBool('Video.StayOnTopInFullScreenMode', cbStayOnTopInFullScreenMode.Checked);
    WriteBool('Video.ChangeResolution',cbFullScrMode.Checked);
    WriteInteger('Video.ChangeResolution.Width',ScrWidth);
    WriteInteger('Video.ChangeResolution.Height',ScrHeight);
    WriteInteger('Video.ChangeResolution.Depth',ScrDepth);
    WriteBool('Video.ForceOverlay',cbForceOverlay.Checked);
    WriteString('Video.AspectRatioCustom',edAspectRatio.Text);

    WriteBool('Seek.KeyFrameSeek',cbKeyFrameSeek.Checked);
    WriteString('Seek.KeySeek',edKeySeek.Text);
    WriteString('Seek.KeyJump',edKeyJump.Text);

    WriteString('App.ScreenShotDir',edScrShDir.Text);
    WriteInteger('Video.AspectRatio',cbAspectRatio.ItemIndex);
    WriteBool('Video.AspectRatioForced',cbAspectRatioForced.Checked);
    WriteBool('Video.OnTopWhilePlay',cbOnTopWhilePlay.Checked);
  end;

  if (INI.Bool['Video.VideoProcessor']<>cbVideoProcessor.Checked)
    or (INI.Bool['Video.HardwareProcessing']<>cbHardwareVideoProcessing.Checked)
  then begin
    INI.Bool['Video.VideoProcessor']:=cbVideoProcessor.Checked;
    INI.Bool['Video.HardwareProcessing']:=cbHardwareVideoProcessing.Checked;
    NeedReloadMedia:=TRUE;
  end;

  if (RIndex<>cbbVideoRenderer.ItemIndex) then begin
    for i:=0 to VideoRenderersCount do begin
      if VideoRenderers[i].NAME = cbbVideoRenderer.Items[cbbVideoRenderer.ItemIndex] then
        Core.Prefs.WriteInteger('Video.VideoRenderer',i);
    end;

    INI.Bool['Video.VideoProcessor']:=cbVideoProcessor.Checked;
    NeedReloadMedia:=TRUE;
  end;

  INI.Bool['App.ScreenShotJPEG']:=rbJPG.Checked;
end;

procedure TCPVideo.EnumerateScrModes;
var
  Mode,l:longint;
  R:TRect;
  MI:TMenuItem;
  DevMode:TDeviceMode;

  function InList:boolean;
  var
    l:LongInt;
  begin
    Result:=FALSE;
    for l:=0 to Length(ScrMode)-1 do
      if (ScrMode[l].Width=longint(DevMode.dmPelsWidth))
      and (ScrMode[l].Height=longint(DevMode.dmPelsHeight))
      and (ScrMode[l].Depth=longint(DevMode.dmBitsPerPel)) then
        Result:=TRUE;
  end;
begin
  Mode:=0;
  l:=0;
  SetLength(ScrMode,0);
  while EnumDisplaySettings(NIL,Mode,DevMode) do begin
    if not(InList) then begin
      SetLength(ScrMode,l+1);
      ScrMode[l].Width:=DevMode.dmPelsWidth;
      ScrMode[l].Height:=DevMode.dmPelsHeight;
      ScrMode[l].Depth:=DevMode.dmBitsPerPel;
      Inc(l);
    end;
    Inc(Mode);
  end;

  SortScrModes;

  pmScrModes.Items.Clear;
  for l:=0 to Length(ScrMode)-1 do begin
    MI:=TMenuItem.Create(pmScrModes);
    if (l>0) and (ScrMode[l].Depth<>ScrMode[l-1].Depth) then
      MI.Break:=mbBarBreak;
    with ScrMode[l] do begin
      MI.Caption:=Format('%d x %d, %d Bits',[Width,Height,Depth]);
      if (Core.Prefs.ReadInteger('Video.FullScr.Resol.Width')=Width)
      and (Core.Prefs.ReadInteger('Video.FullScr.Resol.Height')=Height)
      and (Core.Prefs.ReadInteger('Video.FullScr.Resol.Depth')=Depth) then
        MI.Checked:=TRUE;
    end;
    MI.OnClick:=OnScrModeSelect;
    pmScrModes.Items.Add(MI);
  end;

  GetWindowRect(btScrMode.Handle,R);
  pmScrModes.Popup(R.Right,R.Top);
end;

procedure TCPVideo.OnScrModeSelect(Sender: TObject);
var
  MI:TMenuItem;
begin
  MI:=Sender as TMenuItem;
  with ScrMode[MI.MenuIndex] do begin
    ScrWidth:=Width;
    ScrHeight:=Height;
    ScrDepth:=Depth;
  end;
  btScrMode.Caption:=Format('%d x %d, %d Bits',[ScrWidth,ScrHeight,ScrDepth]);
end;

procedure TCPVideo.ReadPrefs;
begin
  FillRenderers;
  with Core.Prefs do begin
    tbSpeed.Position:=ReadInteger('Video.SpeedPlayRate');

    cbCreateRelatedDirectoryName.Checked := ReadBool('Video.CreateRelatedDirectoryName');
    cbStayOnTopInFullScreenMode.Checked := ReadBool('Video.StayOnTopInFullScreenMode');
    cbFullScrMode.Checked:=ReadBool('Video.ChangeResolution');
    ScrWidth:=ReadInteger('Video.ChangeResolution.Width');
    ScrHeight:=ReadInteger('Video.ChangeResolution.Height');
    ScrDepth:=ReadInteger('Video.ChangeResolution.Depth');
    btScrMode.Caption:=Format('%d x %d, %d Bits',[ScrWidth,ScrHeight,ScrDepth]);

    cbForceOverlay.Checked:=ReadBool('Video.ForceOverlay');
    cbVideoProcessor.Checked:=ReadBool('Video.VideoProcessor');
    cbHardwareVideoProcessing.Checked:=ReadBool('Video.HardwareProcessing');

    edAspectRatio.Text:=ReadString('Video.AspectRatioCustom');

    cbKeyFrameSeek.Checked:=ReadBool('Seek.KeyFrameSeek');
    edKeySeek.Text:=ReadString('Seek.KeySeek');
    edKeyJump.Text:=ReadString('Seek.KeyJump');

    edScrShDir.Text:=ReadString('App.ScreenShotDir');

    rbBMP.Checked:=TRUE;
    cbAspectRatio.ItemIndex := ReadInteger('Video.AspectRatio');
    cbAspectRatioForced.Checked := ReadBool('Video.AspectRatioForced');
    cbOnTopWhilePlay.Checked := ReadBool('Video.OnTopWhilePlay');

    if Core.Prefs.Bool['App.ScreenShotJPEG'] then rbJPG.Checked:=TRUE;
  end;
end;

procedure TCPVideo.SortScrModes;
var
  i,j:longint;
  function ModeStr(l:longint):string;
  begin
    Result:=Format('%.4d%.4d%.4d',[ScrMode[l].Depth,ScrMode[l].Width,ScrMode[l].Height]);
  end;

  procedure Swap;
  var
    a:array [0..11] of Byte;
  begin
    Move(ScrMode[i],a,12);
    Move(ScrMode[j],ScrMode[i],12);
    Move(a,ScrMode[j],12);
  end;
begin
  for i:=0 to Length(ScrMode)-2 do
    for j:=i to Length(ScrMode)-1 do
      if (ModeStr(i)<ModeStr(j)) then
        Swap;
end;

procedure TCPVideo.UpdateLang;
begin
  lbSpeedChange.Caption:=MS('Config.SpeedChange');
  cbForceOverlay.Caption:=MS('Config.ForceOverlay');
  cbVideoProcessor.Caption:=MS('Config.VideoProcessor');
  cbHardwareVideoProcessing.Caption:=MS('Config.HardwareProcessing');  
  lblRenderer.Caption:=MS('Config.VideoRenderer');
  cbVideoProcessor.Caption:=MS('Config.VideoProcessor');
  cbOnTopWhilePlay.Caption:=MS('Config.OnTopWhilePlay');
  gbFullScreen.Caption:=' '+MS('Config.FullScreen')+' ';
  cbStayOnTopInFullScreenMode.Caption:=MS('Config.FullScreen.StayOnTop');
  cbFullScrMode.Caption:=MS('Config.FullScrMode');

  gbSeek.Caption:=' '+MS('Config.Seek')+' ';
  lbKeySeek.Caption:=MS('Config.Seek.Keys');
  lbKeyJump.Caption:=MS('Config.Seek.Jump');
  cbKeyFrameSeek.Caption:=MS('Config.Seek.KeyFrame');

  gbSSDir.Caption:=' '+MS('Config.ScreenShotDir')+' ';
  cbCreateRelatedDirectoryName.Caption:=MS('Config.ScreenShotDir.CreateRelatedDirectoryName');

  gbAspectRatio.Caption :=' '+MS('Config.Video.AspectRatio')+' ';
  cbAspectRatioForced.Caption := MS('Config.Video.AspectRatioForced');
  cbAspectRatio.Items[0] := MS('Command.305');
  cbAspectRatio.Items[1] := MS('Command.306');
  cbAspectRatio.Items[2] := MS('Command.307');
  cbAspectRatio.Items[3] := MS('Command.308');
  cbAspectRatio.Items[4] := MS('Command.309');
  cbAspectRatio.Items[5] := MS('Command.310');
  cbAspectRatio.Items[6] := MS('Command.311');
  lbAspectRatioCustom.Caption:=MS('Config.AspectRatioCustom');
end;

procedure TCPVideo.cbFullScrModeClick(Sender: TObject);
begin
  btScrMode.Enabled:=cbFullScrMode.Checked;
end;

procedure TCPVideo.tbSpeedChange(Sender: TObject);
begin
  lbSpeed.Caption:=Format('x%1.1f',[tbSpeed.Position/10]);
end;

procedure TCPVideo.btScrModeClick(Sender: TObject);
begin
  EnumerateScrModes;
end;

procedure TCPVideo.btScrShDirClick(Sender: TObject);
var
  S:String;
begin
  S:=Core.SysHlp.SelectFolder(edScrShDir.Text);
  if (S<>'') then
  begin
    edScrShDir.Text:=S;
    if frConfig.ConfigPageAlwayOnTop.Enabled then frConfig.SwitchCfgTopPos(Application.Handle, False);
  end;
end;

procedure TCPVideo.cbAspectRatioForcedClick(Sender: TObject);
begin
  inherited;
  if cbAspectRatioForced.Checked then
    cbAspectRatio.Enabled := Sender = cbAspectRatioForced
  else
  cbAspectRatio.Enabled := false;
end;

procedure TCPVideo.FillRenderers;
var
  R: TRegistry;
  i: Byte;
begin
  R:=TRegistry.Create;
  try
    R.RootKey:=HKEY_LOCAL_MACHINE;
    for i:=0 to FilterBase.VideoRenderersCount do
      if R.KeyExists('\SOFTWARE\Classes\CLSID\'+
        GUIDToString(Videorenderers[i].CLSID))
      then begin
        cbbVideoRenderer.Items.Add(Videorenderers[i].NAME);
        if i = Core.Prefs.ReadInteger('Video.VideoRenderer') then
          cbbVideoRenderer.ItemIndex:=cbbVideoRenderer.Items.Count-1;
      end;
    if (cbbVideoRenderer.ItemIndex<0) then
      cbbVideoRenderer.ItemIndex:=0;
    RIndex:=cbbVideoRenderer.ItemIndex;
  finally
    R.Free;
  end;
end;

end.
