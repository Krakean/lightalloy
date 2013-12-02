unit CfgPgOSD;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ConfigPage, Buttons, ExtCtrls, StdCtrls, ComCtrls, Menus;

type
  TCPOSD = class(TConfigPageForm)
    PageControl: TPageControl;
    gbInfo: TTabSheet;
    gbSubs: TTabSheet;
    pnInfoPreview: TPanel;
    shpInfoFont: TShape;
    gbInfoPos: TGroupBox;
    rbOSDPos0: TRadioButton;
    rbOSDPos1: TRadioButton;
    rbOSDPos2: TRadioButton;
    rbOSDPos4: TRadioButton;
    rbOSDPos3: TRadioButton;
    rbOSDPos5: TRadioButton;
    pnSubPreview: TPanel;
    shpSubsFont: TShape;
    rgMicroDVDFPS: TRadioGroup;
    gbSubDir: TGroupBox;
    edSubDir: TEdit;
    bbSubDir: TBitBtn;
    cbSubDir: TCheckBox;
    edMicroDVDFPS: TEdit;
    lbInfoStr: TTabSheet;
    mmInfoStr: TMemo;
    InfoFill: TButton;
    mmInfoDef: TButton;
    mmInfoClear: TButton;
    pmInfoFill: TPopupMenu;
    General: TMenuItem;
    ARTIST: TMenuItem;
    TITLE: TMenuItem;
    ALBUM: TMenuItem;
    YEAR: TMenuItem;
    GENRE: TMenuItem;
    ENCODER: TMenuItem;
    FORMAT: TMenuItem;
    FILENAME: TMenuItem;
    CODECS: TMenuItem;
    DURATION: TMenuItem;
    REMAINS: TMenuItem;
    POSITION: TMenuItem;
    TIME: TMenuItem;
    SIZE: TMenuItem;
    COUNT: TMenuItem;
    CURRENT: TMenuItem;
    Video: TMenuItem;
    VIDEOCODECDESC: TMenuItem;
    VIDEOCODEC: TMenuItem;
    VIDEODURATIONTEXT: TMenuItem;
    VIDEODURATION: TMenuItem;
    VIDEOWIDTH: TMenuItem;
    VIDEOHEIGHT: TMenuItem;
    VIDEOASPECTRATIO: TMenuItem;
    VIDEOFPS: TMenuItem;
    VIDEOBITRATE: TMenuItem;
    Audio: TMenuItem;
    AUDIOCODECDESC: TMenuItem;
    AUDIOCODEC: TMenuItem;
    AUDIODURATIONTEXT: TMenuItem;
    AUDIODURATION: TMenuItem;
    AUDIOBITRATE: TMenuItem;
    AUDIOFORMAT: TMenuItem;
    AUDIOSTREAMSCOUNT: TMenuItem;
    gbOSDType: TGroupBox;
    rbOSDOver: TRadioButton;
    rbOSDWith: TRadioButton;
    gbBackground: TGroupBox;
    gbAddition: TGroupBox;
    cbSubAutoload: TCheckBox;
    cbShowSize: TCheckBox;
    cbOSDInfoShow: TCheckBox;
    edInfoDur: TEdit;
    udInfoDur: TUpDown;
    Label2: TLabel;
    Shape4: TShape;
    Shape5: TShape;
    Shape3: TShape;
    shpInfoBG: TShape;
    cbAlertMsg: TCheckBox;
    cbbBG: TComboBox;
    shpSubsShadow: TShape;
    cbUseSkinColors: TCheckBox;
    cbPauseTime: TCheckBox;
    cbDurationSeek: TCheckBox;
    procedure cbSubDirClick(Sender: TObject);
    procedure bbSubDirClick(Sender: TObject);
    procedure bbInfoColorClick(Sender: TObject);
    procedure bbSubColorClick(Sender: TObject);
    procedure mmInfoClearClick(Sender: TObject);
    procedure InfoFillClick(Sender: TObject);
    procedure mmInfoDefClick(Sender: TObject);
    procedure shpInfoFontMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure shpInfoBGMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure shpSubsFontMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure shpSubsShadowMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure pnInfoPreviewClick(Sender: TObject);
    procedure pnSubPreviewClick(Sender: TObject);
    procedure MenuItemClick(Sender: TObject);
    procedure InfoFillMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  private
  public
    procedure ReadPrefs; override;
    procedure UpdateLang; override;
    procedure ApplyChanges; override;
  end;

implementation

{$R *.dfm}

uses
  LACore, MainUnit, OtherGlobalVars, Config;

procedure TCPOSD.ApplyChanges;
begin
  with Core.Prefs do begin
    Bool['OSD.WithVideo']:=rbOSDWith.Checked;

    Bool['OSD.BG.IsColor']:=cbbBG.ItemIndex=1;
    Int['OSD.BG.Color']:=shpInfoBG.Brush.Color;

    Bool['OSD.Info.Show']:=cbOSDInfoShow.Checked;
    Text['OSD.InfoStr']:=mmInfoStr.Text;
    Int['OSD.Info.Duration']:=udInfoDur.Position;
    Bool['OSD.Info.AlertMsg']:=cbAlertMsg.Checked;
    Bool['OSD.Info.UseSkinColors']:=cbUseSkinColors.Checked;
    Bool['OSD.ShowPositionOnPause']:=cbPauseTime.Checked;
    Bool['OSD.ShowTotalTimeOnSeek']:=cbDurationSeek.Checked;

    Int['OSD.Info.Pos']:=0;
    if rbOSDPos1.Checked then Int['OSD.Info.Pos']:=1;
    if rbOSDPos2.Checked then Int['OSD.Info.Pos']:=2;
    if rbOSDPos3.Checked then Int['OSD.Info.Pos']:=3;
    if rbOSDPos4.Checked then Int['OSD.Info.Pos']:=4;
    if rbOSDPos5.Checked then Int['OSD.Info.Pos']:=5;

    WriteBool('Subtitles.AutoLoad',cbSubAutoload.Checked);
    Bool['Subtitles.UseFolder']:=cbSubDir.Checked;
    Str['Subtitles.Folder']:=edSubDir.Text;

    WriteInteger('Subtitles.SetMicroDVDFPS',rgMicroDVDFPS.ItemIndex);
    WriteString('Subtitles.MicroDVDFPS',edMicroDVDFPS.Text);

    WriteString('Subtitles.Text',pnSubPreview.Caption);
    WriteString('Subtitles.Font',pnSubPreview.Font.Name);
    WriteBool('Subtitles.Bold',(fsBold in pnSubPreview.Font.Style));
    WriteInteger('Subtitles.Size',pnSubPreview.Font.Size);
    WriteInteger('Subtitles.Charset',pnSubPreview.Font.Charset);
    WriteInteger('Subtitles.Color',pnSubPreview.Font.Color);
    WriteInteger('Subtitles.ShadowColor',shpSubsShadow.Brush.Color);
    WriteBool('OSD.ShowSize',cbShowSize.Checked);
    WriteString('OSD.Info.Font.Family',pnInfoPreview.Font.Name);
    WriteBool('OSD.Info.Font.Bold',(fsBold in pnInfoPreview.Font.Style));
    WriteInteger('OSD.Info.Font.Size',pnInfoPreview.Font.Size);
    WriteInteger('OSD.Info.Font.Charset',pnInfoPreview.Font.Charset);
    WriteInteger('OSD.Info.Font.Color',pnInfoPreview.Font.Color);
    frMain.UpdateSubFont;
  end;
end;

procedure TCPOSD.ReadPrefs;
begin
  with Core.Prefs do begin
    rbOSDOver.Checked:=TRUE;
    rbOSDWith.Checked:=Bool['OSD.WithVideo'];

    cbbBG.ItemIndex:=int['OSD.BG.IsColor'];
    shpInfoBG.Brush.Color:=Int['OSD.BG.Color'];

    cbOSDInfoShow.Checked:=ReadBool('OSD.Info.Show');
    mmInfoStr.Text:=Text['OSD.InfoStr'];
    udInfoDur.Position:=Core.Prefs.Int['OSD.Info.Duration'];
    cbAlertMsg.Checked:=ReadBool('OSD.Info.AlertMsg');
    cbUseSkinColors.Checked:=ReadBool('OSD.Info.UseSkinColors');
    cbPauseTime.Checked:=ReadBool('OSD.ShowPositionOnPause');
    cbDurationSeek.Checked:=ReadBool('OSD.ShowTotalTimeOnSeek');

    rbOSDPos0.Checked:=TRUE;
    rbOSDPos1.Checked:=(Int['OSD.Info.Pos']=1);
    rbOSDPos2.Checked:=(Int['OSD.Info.Pos']=2);
    rbOSDPos3.Checked:=(Int['OSD.Info.Pos']=3);
    rbOSDPos4.Checked:=(Int['OSD.Info.Pos']=4);
    rbOSDPos5.Checked:=(Int['OSD.Info.Pos']=5);

    cbSubAutoload.Checked:=ReadBool('Subtitles.AutoLoad');
    cbShowSize.Checked:=ReadBool('OSD.ShowSize');
    cbSubDir.Checked:=ReadBool('Subtitles.UseFolder');
    edSubDir.Text:=Str['Subtitles.Folder'];

    rgMicroDVDFPS.ItemIndex:=ReadInteger('Subtitles.SetMicroDVDFPS');
    edMicroDVDFPS.Text:=ReadString('Subtitles.MicroDVDFPS');

    pnSubPreview.Font.Name:=ReadString('Subtitles.Font');
    pnSubPreview.Font.Size:=ReadInteger('Subtitles.Size');
    pnSubPreview.Font.Charset:=ReadInteger('Subtitles.Charset');
    pnSubPreview.Font.Color:=ReadInteger('Subtitles.Color');
    pnSubPreview.Font.Style:=[];
    shpSubsFont.Brush.Color:=ReadInteger('Subtitles.Color');
    shpSubsShadow.Brush.Color:=ReadInteger('Subtitles.ShadowColor');
    if ReadBool('Subtitles.Bold') then
      pnSubPreview.Font.Style:=[fsBold];

    pnInfoPreview.Font.Name:=ReadString('OSD.Info.Font.Family');
    pnInfoPreview.Font.Size:=ReadInteger('OSD.Info.Font.Size');
    pnInfoPreview.Font.Charset:=ReadInteger('OSD.Info.Font.Charset');
    pnInfoPreview.Font.Color:=ReadInteger('OSD.Info.Font.Color');
    pnInfoPreview.Font.Style:=[];
    shpInfoFont.Brush.Color:=ReadInteger('OSD.Info.Font.Color');
    if ReadBool('OSD.Info.Font..Bold') then
      pnInfoPreview.Font.Style:=[fsBold];
  end;
end;

procedure TCPOSD.UpdateLang;
begin
  gbOSDType.Caption:=' '+MS('Config.OSD.Type')+' ';
  rbOSDOver.Caption:=MS('Config.OSD.Type.Over');
  rbOSDWith.Caption:=MS('Config.OSD.Type.With');

  gbBackground.Caption:=' '+MS('Config.OSD.BG')+' ';
  cbbBG.Items[0]:=MS('Config.OSD.BG.Transparent');
  cbbBG.Items[1]:=MS('Config.OSD.BG.Color');

  gbInfo.Caption:=' '+MS('Config.OSD.Info')+' ';
  gbAddition.Caption:=' '+MS('Config.OSD.Info.Addition')+' ';
  cbOSDInfoShow.Caption:=MS('Config.OSD.Show');
  cbAlertMsg.Caption:=MS('Config.OSD.Info.AlertMsg');
  cbUseSkinColors.Caption:=MS('Config.OSD.Info.UseSkinColors');
  cbPauseTime.Caption:=MS('Config.OSD.Info.ShowPositionOnPause');
  cbDurationSeek.Caption:=MS('Config.OSD.Info.ShowTotalTimeOnSeek');

  gbInfoPos.Caption:=' '+MS('Config.OSD.Info.Position')+' ';
//  bbInfoColor.Caption:=MS('Config.Color');
//  bbInfoFont.Caption:=MS('Config.Font');
  lbInfoStr.Caption:=MS('Config.OSD.Info.Text');

  gbSubs.Caption:=' '+MS('Config.OSD.Subs')+' ';
  gbSubDir.Caption:=' '+MS('Config.OSD.Subs.Dir')+' ';
  cbSubAutoload.Caption:=MS('Config.Subs.Autoload');
  cbShowSize.Caption:=MS('Config.OSD.ShowSize');
  Label2.Caption:=MS('Config.OSD.TimeName');
//  sbSubFont.Caption:=MS('Config.Font');
//  bbSubColor.Caption:=MS('Config.Color');

  rgMicroDVDFPS.Caption:=' '+MS('Config.Subs.MicroDVDFPS')+' ';
  rgMicroDVDFPS.Items[0]:=MS('Config.Subs.MicroDVDFPS.AsMovie');
  rgMicroDVDFPS.Items[1]:=MS('Config.Subs.MicroDVDFPS.Custom');
  if Core.Prefs.ReadString('FrontEnd.Language') <> 'Russian' then
  begin
    pmInfoFill.Items[0].Caption := MS('Config.OSD.PopUp.General');
    pmInfoFill.Items[0].Items[0].Caption := MS('Config.OSD.PopUp.General.Artist');
    pmInfoFill.Items[0].Items[1].Caption := MS('Config.OSD.PopUp.General.Title');
    pmInfoFill.Items[0].Items[2].Caption := MS('Config.OSD.PopUp.General.Album');
    pmInfoFill.Items[0].Items[3].Caption := MS('Config.OSD.PopUp.General.Year');
    pmInfoFill.Items[0].Items[4].Caption := MS('Config.OSD.PopUp.General.Encoder');
    pmInfoFill.Items[0].Items[5].Caption := MS('Config.OSD.PopUp.General.Genre');
    pmInfoFill.Items[0].Items[6].Caption := MS('Config.OSD.PopUp.General.Format');
    pmInfoFill.Items[0].Items[7].Caption := MS('Config.OSD.PopUp.General.Filename');
    pmInfoFill.Items[0].Items[8].Caption := MS('Config.OSD.PopUp.General.Codecs');
    pmInfoFill.Items[0].Items[9].Caption := MS('Config.OSD.PopUp.General.Duration');
    pmInfoFill.Items[0].Items[10].Caption := MS('Config.OSD.PopUp.General.Remains');
    pmInfoFill.Items[0].Items[11].Caption := MS('Config.OSD.PopUp.General.Position');
    pmInfoFill.Items[0].Items[12].Caption := MS('Config.OSD.PopUp.General.Time');
    pmInfoFill.Items[0].Items[13].Caption := MS('Config.OSD.PopUp.General.Size');
    pmInfoFill.Items[0].Items[14].Caption := MS('Config.OSD.PopUp.General.Count');
    pmInfoFill.Items[0].Items[15].Caption := MS('Config.OSD.PopUp.General.Current');

    pmInfoFill.Items[1].Caption := MS('Config.OSD.PopUp.Video');
    pmInfoFill.Items[1].Items[0].Caption := MS('Config.OSD.PopUp.Video.VideoCodecDesc');
    pmInfoFill.Items[1].Items[1].Caption := MS('Config.OSD.PopUp.Video.VideoCodec');
    pmInfoFill.Items[1].Items[2].Caption := MS('Config.OSD.PopUp.Video.VideoDurationText');
    pmInfoFill.Items[1].Items[3].Caption := MS('Config.OSD.PopUp.Video.VideoDuration');
    pmInfoFill.Items[1].Items[4].Caption := MS('Config.OSD.PopUp.Video.VideoWidth');
    pmInfoFill.Items[1].Items[5].Caption := MS('Config.OSD.PopUp.Video.VideoHeight');
    pmInfoFill.Items[1].Items[6].Caption := MS('Config.OSD.PopUp.Video.VideoAspectRatio');
    pmInfoFill.Items[1].Items[7].Caption := MS('Config.OSD.PopUp.Video.VideoFPs');

    pmInfoFill.Items[2].Caption := MS('Config.OSD.PopUp.Audio');
    pmInfoFill.Items[2].Items[0].Caption := MS('Config.OSD.PopUp.Audio.AudioCodecDesc');
    pmInfoFill.Items[2].Items[1].Caption := MS('Config.OSD.PopUp.Audio.AudioCodec');
    pmInfoFill.Items[2].Items[2].Caption := MS('Config.OSD.PopUp.Audio.AudioDurationText');
    pmInfoFill.Items[2].Items[3].Caption := MS('Config.OSD.PopUp.Audio.AudioDuration');
    pmInfoFill.Items[2].Items[4].Caption := MS('Config.OSD.PopUp.Audio.AudioBitrate');
    pmInfoFill.Items[2].Items[5].Caption := MS('Config.OSD.PopUp.Audio.AudioFormat');
    pmInfoFill.Items[2].Items[6].Caption := MS('Config.OSD.PopUp.Audio.AudioStreamsCount');
  end;
end;

procedure TCPOSD.cbSubDirClick(Sender: TObject);
begin
  edSubDir.Enabled:=cbSubDir.Checked;
  bbSubDir.Enabled:=cbSubDir.Checked;
end;

procedure TCPOSD.bbSubDirClick(Sender: TObject);
var
  S:String;
begin
  S:=Core.SysHlp.SelectFolder(edSubDir.Text);
  if (S<>'') then
  begin
    edSubDir.Text:=S;
    if frConfig.ConfigPageAlwayOnTop.Enabled then frConfig.SwitchCfgTopPos(Application.Handle, False);    
  end;
end;

procedure TCPOSD.bbInfoColorClick(Sender: TObject);
var
  CD:TColorDialog;
begin
  CD:=TColorDialog.Create(Self);
  if frConfig.ConfigPageAlwayOnTop.Enabled then frConfig.SwitchCfgTopPos(CD.Handle, True);  
  CD.Color:=pnInfoPreview.Font.Color;
  if CD.Execute then begin
    pnInfoPreview.Font.Color:=CD.Color;
  end;
  if frConfig.ConfigPageAlwayOnTop.Enabled then frConfig.SwitchCfgTopPos(CD.Handle, False);  
  CD.Free;
end;

procedure TCPOSD.bbSubColorClick(Sender: TObject);
var
  CD:TColorDialog;
begin
  CD:=TColorDialog.Create(Self);
  if frConfig.ConfigPageAlwayOnTop.Enabled then frConfig.SwitchCfgTopPos(CD.Handle, True);  
  CD.Color:=pnSubPreview.Font.Color;
  if CD.Execute then begin
    pnSubPreview.Font.Color:=CD.Color;
  end;
  if frConfig.ConfigPageAlwayOnTop.Enabled then frConfig.SwitchCfgTopPos(CD.Handle, False);  
  CD.Free;
end;

procedure TCPOSD.mmInfoClearClick(Sender: TObject);
begin
  mmInfoStr.Clear;
end;

procedure TCPOSD.InfoFillClick(Sender: TObject);
begin
//mmInfoStr.Text:='{ARTIST}, {TITLE}, {FORMAT}, {CODECS}, {POSITION},'#13#10+
//                '{DURATION}, {REMAINS}, {TIME}, {SIZE}, {FILENAME}, {VIDEOASPECTRATIO}, '#13#10+
//                '{VIDEOCODECDESC}, {VIDEOCODEC}, {VIDEODURATIONTEXT}, {VIDEODURATION}, {AUDIOFORMAT}, '#13#10+
//                '{VIDEOFPS}, {AUDIODURATIONTEXT}, {AUDIODURATION}, {AUDIOSTREAMSCOUNT}, '#13#10+
//                '{VIDEOWIDTH}, {VIDEOHEIGHT}, {AUDIOCODEC}, {AUDIOCODECDESC}, {AUDIOBITRATE}';
end;

procedure TCPOSD.mmInfoDefClick(Sender: TObject);
begin
  mmInfoStr.Clear;
  mmInfoStr.Text:='{ARTIST} - {TITLE}';
end;

procedure TCPOSD.shpInfoFontMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  CD:TColorDialog;
begin
  CD:=TColorDialog.Create(Self);
  if frConfig.ConfigPageAlwayOnTop.Enabled then frConfig.SwitchCfgTopPos(CD.Handle, True);
  CD.Color:=pnInfoPreview.Font.Color;
  if CD.Execute then begin
    pnInfoPreview.Font.Color:=CD.Color;
    shpInfoFont.Brush.Color:=CD.Color;
  end;
  if frConfig.ConfigPageAlwayOnTop.Enabled then frConfig.SwitchCfgTopPos(CD.Handle, False);  
  CD.Free;
end;

procedure TCPOSD.shpSubsFontMouseDown;
var
  CD:TColorDialog;
begin
  CD:=TColorDialog.Create(Self);
  if frConfig.ConfigPageAlwayOnTop.Enabled then frConfig.SwitchCfgTopPos(CD.Handle, True);
  CD.Color:=pnSubPreview.Font.Color;
  if CD.Execute then begin
    pnSubPreview.Font.Color:=CD.Color;
    shpSubsFont.Brush.Color:=CD.Color;
  end;
  if frConfig.ConfigPageAlwayOnTop.Enabled then frConfig.SwitchCfgTopPos(CD.Handle, False);  
  CD.Free;
end;

procedure TCPOSD.pnInfoPreviewClick(Sender: TObject);
var
  FD:TFontDialog;
begin
  FD:=TFontDialog.Create(Self);
  if frConfig.ConfigPageAlwayOnTop.Enabled then frConfig.SwitchCfgTopPos(FD.Handle, True);
  Core.FntHlp.CopyFont(pnInfoPreview.Font,FD.Font);
  if FD.Execute then begin
    Core.FntHlp.CopyFont(FD.Font,pnInfoPreview.Font);
  end;
  if frConfig.ConfigPageAlwayOnTop.Enabled then frConfig.SwitchCfgTopPos(FD.Handle, False);  
  FD.Free;
end;

procedure TCPOSD.pnSubPreviewClick(Sender: TObject);
var
  FD:TFontDialog;
begin
  FD:=TFontDialog.Create(Self);
  if frConfig.ConfigPageAlwayOnTop.Enabled then frConfig.SwitchCfgTopPos(FD.Handle, True);  
  Core.FntHlp.CopyFont(pnSubPreview.Font,FD.Font);
  if FD.Execute then begin
    Core.FntHlp.CopyFont(FD.Font,pnSubPreview.Font);
  end;
  if frConfig.ConfigPageAlwayOnTop.Enabled then frConfig.SwitchCfgTopPos(FD.Handle, False);  
  FD.Free;
end;

procedure TCPOSD.MenuItemClick(Sender: TObject);
begin
  inherited;
  mmInfoStr.SetSelTextBuf(PCHar('{'+ TMenuItem(Sender).Name +'}'));
end;

procedure TCPOSD.InfoFillMouseDown;
var
  Cursor   : TPoint;
  StayOnTop: Boolean;
begin
  inherited;
  StayOnTop := false;
  if (Button=mbLeft) or (Button=mbRight) then begin

    if (frMain.HoverButtons[hiCapStayOnTop].Down) then
    begin
      StayOnTop := DisableConfigPageTimer;
      DisableConfigPageTimer := True;
    end;

    GetCursorPos(Cursor);
    pmInfoFill.Popup(Cursor.X,Cursor.Y);

    if (frMain.HoverButtons[hiCapStayOnTop].Down) then
    DisableConfigPageTimer := StayOnTop;
  end;
end;

procedure TCPOSD.shpInfoBGMouseDown;
var
  CD:TColorDialog;
begin
  CD:=TColorDialog.Create(Self);
  if frConfig.ConfigPageAlwayOnTop.Enabled then frConfig.SwitchCfgTopPos(CD.Handle, True);
  CD.Color:=shpInfoBG.Brush.Color;
  if CD.Execute then begin
    shpInfoBG.Brush.Color:=CD.Color;
  end;
  if frConfig.ConfigPageAlwayOnTop.Enabled then frConfig.SwitchCfgTopPos(CD.Handle, False);
  CD.Free;
end;

procedure TCPOSD.shpSubsShadowMouseDown;
var
  CD:TColorDialog;
begin
  CD:=TColorDialog.Create(Self);
  if frConfig.ConfigPageAlwayOnTop.Enabled then frConfig.SwitchCfgTopPos(CD.Handle, True);
  CD.Color:=shpSubsShadow.Brush.Color;
  if CD.Execute then begin
    shpSubsShadow.Brush.Color:=CD.Color;
  end;
  if frConfig.ConfigPageAlwayOnTop.Enabled then frConfig.SwitchCfgTopPos(CD.Handle, False);
  CD.Free;
end;

end.
