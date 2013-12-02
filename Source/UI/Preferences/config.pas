unit Config;

interface

uses
  Windows, SysUtils, Classes, Controls, Forms, Graphics, ComCtrls,
  StdCtrls, Buttons, ExtCtrls, ImgList, Module,
  ConfigPage, CfgPgFileTypes, CfgPgGlobalKeys, CfgPgDirectShow, CfgPgWinAMP,
  CfgPgAviSynth, CfgPgWinLIRC, CfgPgInterface, CfgPgMouse, CfgPgEvents,
  CfgPgVideo, CfgPgSound, CfgPgSystem, CfgPgOSD, CfgPgKeyboard, CfgPgPlayList;

type
  TfrConfig = class(TForm)
    btOk: TButton;
    btCancel: TButton;
    tvCategory: TTreeView;
    Panel1: TPanel;
    lbPage: TLabel;
    pnModuleForm: TPanel;
    ilCats: TImageList;
    imPage: TImage;
    ConfigPageAlwayOnTop: TTimer;
    tmrDisableGlobalKeys: TTimer;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);

    procedure btOkClick(Sender: TObject);
    procedure btCancelClick(Sender: TObject);
    procedure tvCategoryChange(Sender: TObject; Node: TTreeNode);
    procedure FormPaint(Sender: TObject);
    procedure OnTimer(Sender: TObject);
    procedure GlobKeysOnTmr(Sender: TObject);
  public
    ModuleForm:TForm;
    SelMod:TModule;
    HintNfo: THintInfo;

    CfgPageIndex:LongInt;
    CfgPages:array [0..19] of TConfigPageForm;

    NeedMediaReload:Boolean;

    procedure TuneLang;

    procedure AttachPage(Index:LongInt);
    procedure DetachPage;
    procedure ApplyPageChanges;
    procedure DestroyPages;
    procedure SwitchCfgTopPos(ActiveWnd: THandle; DisableTimer: Boolean);
    procedure OnShowHint(var HintStr:string; var CanShow:Boolean; var HintInfo:THintInfo);    
  end;

var
  frConfig: TfrConfig;

implementation

uses
  MainUnit, LACore, OtherGlobalVars;

var
  HintsVisible: Boolean = false;

{$R *.DFM}

procedure TfrConfig.btOkClick(Sender: TObject);
begin
  ApplyPageChanges;
  Core.SavePrefs(FALSE);
  Close;
end;

procedure TfrConfig.btCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TfrConfig.tvCategoryChange;
var
  l:LongInt;
  BMP:TBitmap;
begin
  DetachPage;

  l:=tvCategory.Selected.Index;
  lbPage.Caption:=tvCategory.Selected.Text;

  BMP:=TBitmap.Create;
  BMP.Width:=24;
  BMP.Height:=22;
  BMP.PixelFormat:=pf32bit;
  with BMP.Canvas do begin
    Brush.Color:=clblack;
    FillRect(Rect(0,0,24,22));
  end;
  ilCats.GetBitmap(l,BMP);
  imPage.Picture.Bitmap.PixelFormat:=pf32bit;
  imPage.Picture.Bitmap.Canvas.Draw(0,0,BMP);
  BMP.Free;

  Repaint;

  AttachPage(l);
  Core.Prefs.WriteInteger('Config.ActivePage',tvCategory.Selected.Index);
end;

procedure TfrConfig.FormCreate(Sender: TObject);
var
  l:LongInt;
begin
  TuneLang;
//  HintsVisible := False;

  ShowScrollBar(tvCategory.Handle,SB_BOTH,FALSE);
  try
    l:=Core.Prefs.ReadInteger('Config.ActivePage');
    tvCategory.Selected:=tvCategory.Items[l];
  except
    tvCategory.Selected:=tvCategory.Items[0];
  end;

  if (frMain.HoverButtons[hiCapStayOnTop].Down) then
    ConfigPageAlwayOnTop.Enabled := True;
//    TopPosition(frConfig.Handle, True);
//    frConfig.FormStyle := fsStayOnTop;

  Application.OnShowHint := OnShowHint;
end;

procedure TfrConfig.FormDestroy;
begin
  DetachPage;
  DestroyPages;
  HintsVisible := True;
  ConfigPageAlwayOnTop.Enabled := False;
  DisableGlobalKeys := False;
  Application.OnShowHint := frMain.OnShowHint;

  if NeedAppReload then
    Core.Alert(MS('Core.Alert.Restart.String1') + #13#10 + MS('Core.Alert.Restart.String2'));
end;

procedure TfrConfig.TuneLang;
var
  l:LongInt;
begin
  Caption:=MS('Config');

  for l:=0 to tvCategory.Items.Count-1 do
    tvCategory.Items.Item[l].Text:=MS('Config.'+tvCategory.Items.Item[l].Text);

  btCancel.Caption:=MS('Config.Cancel');
end;

procedure TfrConfig.DetachPage;
var
  CfgPg:TConfigPageForm;
begin
  CfgPg:=CfgPages[CfgPageIndex];
  if Assigned(CfgPg) then begin
    CfgPg.Hide;
    CfgPg.Parent:=NIL;
  end;
end;

procedure TfrConfig.DestroyPages;
var
  l:LongInt;
begin
  for l:=0 to 19 do
    if Assigned(CfgPages[l]) then
      FreeAndNIL(CfgPages[l]);
end;

procedure TfrConfig.AttachPage;
var
  CfgPg:TConfigPageForm;
begin
  CfgPg:=CfgPages[Index];
  if (CfgPg=NIL) then begin
    case Index of
      0:CfgPg:=TCPInterface.Create(NIL);
      1:CfgPg:=TCPMouse.Create(NIL);
      2:CfgPg:=TCPPlayList.Create(NIL);
      3:CfgPg:=TCPEvents.Create(NIL);
      4:CfgPg:=TCPVideo.Create(NIL);
      5:CfgPg:=TCPSound.Create(NIL);
      6:CfgPg:=TCPSystem.Create(NIL);
      7:CfgPg:=TCPOSD.Create(NIL);
      8:CfgPg:=TCPFileTypes.Create(NIL);
      9:CfgPg:=TCPKeyboard.Create(NIL);
      10:CfgPg:=TCPWinLIRC.Create(NIL);
      11:CfgPg:=TCPWinAMP.Create(NIL);
      12:CfgPg:=TCPDirectShow.Create(NIL);
      13:CfgPg:=TCPGlobalKeys.Create(NIL);
      14:CfgPg:=TCPAviSynth.Create(NIL);
    end;
    CfgPages[Index]:=CfgPg;
  end;

  with CfgPg do begin
//    DoubleBuffered:=TRUE;
    BorderStyle:=bsNone;
    Align:=alClient;
    Parent:=pnModuleForm;
    Show;
  end;

  CfgPageIndex:=Index;
end;

procedure TfrConfig.ApplyPageChanges;
var
  l:LongInt;
begin
  NeedMediaReload:=FALSE;
  NeedAppReload := FalSE;
  for l:=0 to 19 do
    if Assigned(CfgPages[l]) then begin
      CfgPages[l].ApplyChanges;
      NeedMediaReload:=NeedMediaReload or CfgPages[l].NeedReloadMedia;
      NeedAppReload:=NeedAppReload or CfgPages[l].NeedReloadApp;
    end;
end;

procedure TfrConfig.FormPaint(Sender: TObject);
begin
  ShowScrollBar(tvCategory.Handle,SB_BOTH,FALSE);
end;

procedure TfrConfig.OnTimer(Sender: TObject);
begin
  if not DisableConfigPageTimer then
  begin
    if HintsVisible or (frConfig.CfgPageIndex=1) or (frConfig.CfgPageIndex=7)
      or (frConfig.CfgPageIndex=2) or (frConfig.CfgPageIndex=5) or (frConfig.CfgPageIndex=4) or (frConfig.CfgPageIndex=12) then
      TopPosition(frConfig.Handle, False)
    else
      TopPosition(frConfig.Handle, True)
  end;
end;

procedure TfrConfig.GlobKeysOnTmr(Sender: TObject);
begin
  // ...
  if tvCategory.Selected.Index = 13 then
    DisableGlobalKeys := True
  else
    DisableGlobalKeys := False;
end;

procedure TfrConfig.SwitchCfgTopPos(ActiveWnd: THandle; DisableTimer: Boolean);
begin
  if DisableTimer then
    DisableConfigPageTimer := True
  else
    DisableConfigPageTimer := False;

  TopPosition(frConfig.Handle, False);
  TopPosition(ActiveWnd, True);
end;

procedure TfrConfig.OnShowHint(var HintStr:string; var CanShow:Boolean; var HintInfo:THintInfo);
begin
  HintsVisible := HintInfo.HintControl.Visible;
{
  for l:=0 to Ord(High(THButtonID)) do
    if HintInfo.HintControl=HoverButtons[THButtonID(l)] then begin
      LAC:=HoverButtons[THButtonID(l)].Command;
      HintStr:=Center.GetCommandName(LAC);
      if (Center.GetCommandKey(LAC)<>'') then
        HintStr:=HintStr+' ('+Center.GetCommandKey(LAC)+')';
    end;
  if (HintInfo.HintControl=LoadBar) then
    HintStr:=MS('FrontEnd.CPULoad.Hint');
  if (HintInfo.HintControl=TimeBar) then
    HintStr:=MS('FrontEnd.Time.Hint');
  if (HintInfo.HintControl=PosBar) then
    HintStr:=MS('FrontEnd.Position.Hint');
  if (HintInfo.HintControl=tbVolume) then
    HintStr:=MS('FrontEnd.Volume.Hint');}
end;


end.
