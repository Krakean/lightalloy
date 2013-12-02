unit CfgPgInterface;

interface

uses
  Windows, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ConfigPage, StdCtrls, ComCtrls, ExtCtrls, ColorSpace;

type
  TCPInterface = class(TConfigPageForm)
    gbLang: TGroupBox;
    lbLang: TListBox;
    gbCaption: TGroupBox;
    cbCaptionNoFullScr: TCheckBox;
    cbCaptionWnd: TCheckBox;
    gbSkin: TGroupBox;
    lbSkin: TListBox;
    gbWindow: TGroupBox;
    cbStickyWindow: TCheckBox;
    cbShowHints: TCheckBox;
    cbMinimizeToTray: TCheckBox;
    cbMultiInstance: TCheckBox;
    cbReversePlayTime: TCheckBox;
    cbDoNotAcrossWorkArea: TCheckBox;
    cbHideLogo: TCheckBox;
    gbAlbumCover: TGroupBox;
    cbCoverResize: TCheckBox;
    cbCoverCenter: TCheckBox;
    imHue: TImage;
    tbSkinHue: TTrackBar;
    cbSkinRandom: TCheckBox;
    cbbCPanelMode: TComboBox;
    cbSaveSize: TCheckBox;
    cbLargeFont: TCheckBox;
    cbAllowCovers: TCheckBox;
    procedure lbSkinClick(Sender: TObject);    
    procedure FormDestroy(Sender: TObject);
    procedure tbHueChange(Sender: TObject);
    procedure cbSkinRandomClick(Sender: TObject);
  private
    procedure FillLangs;
    procedure FillSkins;

    procedure ApplyLang;
    procedure ApplySkin;
    procedure ReloadSkin;
    procedure DrawHue;
  public
    procedure ReadPrefs; override;
    procedure UpdateLang; override;
    procedure ApplyChanges; override;
  end;

implementation

{$R *.dfm}

uses
  LACore, MainUnit;

procedure TCPInterface.ApplyChanges;
begin
  INI.Int['FrontEnd.Skin.Hue']:=tbSkinHue.Position;
  ApplyLang;
  ApplySkin;

  with Core.Prefs do begin
    WriteBool('FrontEnd.AlwaysWindowCaption',cbCaptionWnd.Checked);
    WriteBool('FrontEnd.NeverFullScrCaption',cbCaptionNoFullScr.Checked);
    WriteInteger('FrontEnd.RememberPanelsState',cbbCPanelMode.ItemIndex);
    WriteBool('FrontEnd.SaveWindowSize',cbSaveSize.Checked);
    WriteBool('FrontEnd.Sticky',cbStickyWindow.Checked);
    WriteBool('FrontEnd.ShowHints',cbShowHints.Checked);
    WriteBool('FrontEnd.MultiInstance',cbMultiInstance.Checked);
    WriteBool('FrontEnd.MinimizeToTray',cbMinimizeToTray.Checked);
    WriteBool('FrontEnd.ReversePlayTime',cbReversePlayTime.Checked);
    WriteBool('FrontEnd.DoNotAcrossWorkArea', cbDoNotAcrossWorkArea.Checked);
    WriteBool('FrontEnd.HideLogo', cbHideLogo.Checked);
    WriteBool('FrontEnd.LargeFontTimeLine', cbLargeFont.Checked);
    WriteBool('FrontEnd.AllowCovers', cbAllowCovers.Checked);
    WriteBool('OnOpen.CoverResize', cbCoverResize.Checked);
    WriteBool('OnOpen.CoverCenter', cbCoverCenter.Checked);
    WriteBool('FrontEnd.Skin.Random', cbSkinRandom.Checked);
  end;

  frMain.ShowHint:=cbShowHints.Checked;
  frMain.OnReloadAppPrefs;
end;

procedure TCPInterface.ApplyLang;
var
  NewLang:String;
begin
  NewLang:=lbLang.Items[lbLang.ItemIndex];
  if (Core.Prefs.ReadString('FrontEnd.Language')<>NewLang) then begin
    Core.Prefs.WriteString('FrontEnd.Language',NewLang);
    Core.ReloadLang;
  end;
end;

procedure TCPInterface.ApplySkin;
var
  NewSkin:String;
begin
  NewSkin:=lbSkin.Items[lbSkin.ItemIndex];
  if (Core.Prefs.ReadString('FrontEnd.Skin')<>NewSkin) then begin
    Core.Prefs.WriteString('FrontEnd.Skin',NewSkin);
    Core.ReloadSkin;
  end;
end;

procedure TCPInterface.FillLangs;
var
  SR:TSearchRec;
  l,Found:LongInt;
begin
  lbLang.Items.Clear;
  lbLang.Items.Add('Russian');
  lbLang.Items.Add('English');
  Found:=FindFirst(ExtractFilePath(Application.ExeName)+'Langs\*.txt',faAnyFile,SR);
  while (Found=0) do begin
    lbLang.Items.Add(ChangeFileExt(SR.Name,''));
    Found:=FindNext(SR);
  end;
  FindClose(SR);

  lbLang.ItemIndex:=0;
  for l:=0 to (lbLang.Items.Count-1) do
    if (lbLang.Items[l]=Core.Prefs.ReadString('FrontEnd.Language')) then
      lbLang.ItemIndex:=l;
end;

procedure TCPInterface.FillSkins;
var
  SR:TSearchRec;
  l,Found:LongInt;
  Ext,SkinDir:String;
begin
  lbSkin.Items.Clear;
  lbSkin.Items.Add(' <GI> ');
  lbSkin.Items.Add(' <XP.Blue> ');  
  SkinDir:=ExtractFilePath(Application.ExeName)+'Skins\';
  Found:=FindFirst(SkinDir+'*.*',faAnyFile,SR);
  while (Found=0) do begin
    if ((SR.Attr and faDirectory)>0) then begin
      if ((SR.Name<>'.') and (SR.Name<>'..')) then begin
        if (FileExists(SkinDir+SR.Name+'\interface.xml')) then
          lbSkin.Items.Add(SR.Name);
      end;
    end else begin
      Ext:=ExtractFileExt(SR.Name);
      if SameText(Ext,'.BMP') then
        lbSkin.Items.Add(ChangeFileExt(SR.Name,''));
{    if SameText(Ext,'.ZIP') then
      lbSkin.Items.Add(SR.Name);
    }if SameText(Ext,'.LAS') then
      lbSkin.Items.Add(SR.Name);{
    if SameText(Ext,'.LSZ') then
      lbSkin.Items.Add(SR.Name);}
    end;
    Found:=FindNext(SR);
  end;
  FindClose(SR);

  lbSkin.ItemIndex:=0;
  for l:=0 to (lbSkin.Items.Count-1) do
    if (lbSkin.Items[l]=Core.Prefs.ReadString('FrontEnd.Skin')) then
      lbSkin.ItemIndex:=l;
end;

procedure TCPInterface.ReadPrefs;
begin
  FillLangs;
  FillSkins;
  DrawHue;
  with Core.Prefs do begin
    cbCaptionWnd.Checked:=ReadBool('FrontEnd.AlwaysWindowCaption');
    cbCaptionNoFullScr.Checked:=Core.Prefs.ReadBool('FrontEnd.NeverFullScrCaption');
    cbbCPanelMode.ItemIndex:=ReadInteger('FrontEnd.RememberPanelsState');
    cbSaveSize.Checked:=ReadBool('FrontEnd.SaveWindowSize');
    cbStickyWindow.Checked:=ReadBool('FrontEnd.Sticky');
    cbShowHints.Checked:=ReadBool('FrontEnd.ShowHints');
    cbMultiInstance.Checked:=ReadBool('FrontEnd.MultiInstance');
    cbMinimizeToTray.Checked:=ReadBool('FrontEnd.MinimizeToTray');
    cbReversePlayTime.Checked:=ReadBool('FrontEnd.ReversePlayTime');
    cbDoNotAcrossWorkArea.Checked := ReadBool('FrontEnd.DoNotAcrossWorkArea');
    cbHideLogo.Checked := ReadBool('FrontEnd.HideLogo');
    cbLargeFont.Checked := ReadBool('FrontEnd.LargeFontTimeLine');
    cbAllowCovers.Checked := ReadBool('FrontEnd.AllowCovers');
    cbCoverResize.Checked := ReadBool('OnOpen.CoverResize');
    cbCoverCenter.Checked := ReadBool('OnOpen.CoverCenter');
    tbSkinHue.Position := ReadInteger('FrontEnd.Skin.Hue');
    cbSkinRandom.Checked := ReadBool('FrontEnd.Skin.Random');
  end;
end;

procedure TCPInterface.UpdateLang;
begin
  gbLang.Caption:=' '+MS('Config.Language')+' ';
  gbSkin.Caption:=' '+MS('Config.Skin')+' ';
  cbSkinRandom.Caption:=MS('Config.SkinRandom');

  gbCaption.Caption:=' '+MS('Config.Caption')+' ';
  cbCaptionNoFullScr.Caption:=MS('Config.Caption.NoFullScr');
  cbCaptionWnd.Caption:=MS('Config.Caption.Window');

  cbbCPanelMode.Items.Clear;
  cbbCPanelMode.Items.Add(MS('Config.Interface.NormalMode'));
  cbbCPanelMode.Items.Add(MS('Config.Interface.Mode1'));
  cbbCPanelMode.Items.Add(MS('Config.Interface.Mode2'));
  cbSaveSize.Caption:=MS('Config.Interface.SaveSize');

  gbWindow.Caption:=' '+MS('Config.Window')+' ';
  cbStickyWindow.Caption:=MS('Config.Window.Sticky');
  cbDoNotAcrossWorkArea.Caption:=MS('Config.Window.DoNotAcrossWorkArea');
  cbShowHints.Caption:=MS('Config.Window.Hints');
  cbMinimizeToTray.Caption:=MS('Config.Window.Tray');
  cbMultiInstance.Caption:=MS('Config.Window.MultiInstance');
  cbReversePlayTime.Caption:=MS('Config.Window.ReversePlayTime');
  cbHideLogo.Caption:=MS('Config.Window.HideLogo');
  cbLargeFont.Caption:=MS('Config.Window.LargeFont');

  gbAlbumCover.Caption:=' '+MS('Config.Interface.AlbumCover')+' ';
  cbAllowCovers.Caption:=MS('Config.Interface.Cover.Allow');
  cbCoverResize.Caption:=MS('Config.Interface.Cover.Resize');
  cbCoverCenter.Caption:=MS('Config.Interface.Cover.Center');
end;

procedure TCPInterface.lbSkinClick(Sender: TObject);
begin
  ReloadSkin;
  DrawHue;
end;

procedure TCPInterface.FormDestroy(Sender: TObject);
var
  OldSkin,NewSkin:String;
begin
  NewSkin:=lbSkin.Items[lbSkin.ItemIndex];
  OldSkin:=Core.Prefs.ReadString('FrontEnd.Skin');

  if (NewSkin<>OldSkin) then Core.ReloadSkin;

  inherited FormDestroy(Sender);
end;

procedure TCPInterface.ReloadSkin;
var
  OldSkin,NewSkin:String;
  OldHue,NewHue:LongInt;
begin
//  if frMain.HoverButtons[hiFullScreen].Down then Exit;

  NewSkin:=lbSkin.Items[lbSkin.ItemIndex];
  OldSkin:=INI.Str['FrontEnd.Skin'];

  NewHue:=tbSkinHue.Position;
  OldHue:=INI.Int['FrontEnd.Skin.Hue'];

  INI.Str['FrontEnd.Skin']:=NewSkin;
  INI.Int['FrontEnd.Skin.Hue']:=NewHue;
  Core.ReloadSkin;
  INI.Str['FrontEnd.Skin']:=OldSkin;
  INI.Int['FrontEnd.Skin.Hue']:=OldHue;

  BringToFront;
end;

procedure TCPInterface.DrawHue;
var
  I: Integer;
  CS: TColorSpace;
begin
  CS := TColorSpace.Create;
  for I := 0 to imHue.Width - 1 do
  begin
    CS.R := GetRValue(frMain.OrgColor);
    CS.G := GetGValue(frMain.OrgColor);
    CS.B := GetBValue(frMain.OrgColor);
    CS.RGB2HSL;
    CS.H := Byte(CS.H + I * 255 div (imHue.Width - 1));
    CS.HSL2RGB;
    imHue.Canvas.Pen.Color := RGB(CS.R, CS.G, CS.B);
    imHue.Canvas.MoveTo(I, 0);
    imHue.Canvas.LineTo(I, imHue.Height);
  end;
  CS.Free;
end;

procedure TCPInterface.tbHueChange(Sender: TObject);
begin
  ReloadSkin;
end;

procedure TCPInterface.cbSkinRandomClick(Sender: TObject);
begin
  inherited;
  lbSkin.Enabled:=not cbSkinRandom.Checked;
end;

end.
