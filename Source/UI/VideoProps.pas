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
unit VideoProps;

interface

uses
  Windows, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls, DShowHlp, VCL2Model, VideoProcessor;

type
  TfrVideoProps = class(TForm)
    btVideoDec: TButton;
    gbColors: TGroupBox;
    btResetBCS: TButton;
    gbGeometry: TGroupBox;
    gbAR: TGroupBox;
    rb1: TRadioButton;
    rb2: TRadioButton;
    rb3: TRadioButton;
    cbAR: TCheckBox;
    rb4: TRadioButton;
    gbCo: TGroupBox;
    tbCo: TTrackBar;
    gbBr: TGroupBox;
    tbBr: TTrackBar;
    gbSa: TGroupBox;
    tbSa: TTrackBar;
    gbZoom: TGroupBox;
    tbZy: TTrackBar;
    imZoom: TImage;
    tbZx: TTrackBar;
    btResetZoom: TButton;
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    Timer1: TTimer;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    GroupBox1: TGroupBox;
    cbVFlip: TCheckBox;
    gbEffect: TGroupBox;
    tbEffect: TTrackBar;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    procedure FormActivate(Sender: TObject);
    procedure tbBrChange(Sender: TObject);
    procedure btResetBCSClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure cbARClick(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure cbVFlipClick(Sender: TObject);
    procedure tbEffectChange(Sender: TObject);
  private
    V2M:TVCL2Model;
    UpdateLock:Boolean;

    procedure UpdateSliders;
    procedure DrawZoomImage;
    procedure OnGeometry;
    function TransposeRect(SrcR,FromR,ToR:TRect):TRect;
    procedure SetLang;
    function Str2Point(Str:String):TPoint;
  public
  end;

var
  frVideoProps: TfrVideoProps;

implementation

{$R *.dfm}

uses
  LACore, MainUnit, VideoPropsModel;

procedure TfrVideoProps.UpdateSliders;
var
  B,C,S:LongInt;
  Title,VDec:String;
begin
  B:=50;C:=50;S:=50;
  Title:=' '+MS('Video.Color')+' ';

  if Assigned(DSH) then begin
    DSH.GetBCS(B,C,S,True);
    VDec:=DSH.VideoControlName;
    Title:=Title+'('+VDec+') ';
    cbVFlip.Enabled:=SameText(VDec,'VideoProc');
    tbEffect.Enabled:=cbVFlip.Enabled;
  end;

  gbColors.Caption:=Title;

  tbBr.Position:=B;
  tbCo.Position:=C;
  tbSa.Position:=S;

  if (frMain.VideoModel=NIL) then Exit;

  if UpdateLock then Exit;
  UpdateLock:=TRUE;
  with frMain.VideoModel do begin
    cbAR.Checked:=not(IsFreeProps);

    rb1.Enabled:=cbAR.Checked;
    rb2.Enabled:=cbAR.Checked;
    rb3.Enabled:=cbAR.Checked;
    rb4.Enabled:=cbAR.Checked;

    rb1.Checked:=(Ratio.X=0) and (Ratio.Y=0);
    rb4.Checked:=(Ratio.X>0) and (Ratio.Y>0);
    rb2.Checked:=(Ratio.X=4) and (Ratio.Y=3);
    rb3.Checked:=(Ratio.X=16) and (Ratio.Y=9);
  end;
  UpdateLock:=FALSE;
end;

procedure TfrVideoProps.FormActivate(Sender: TObject);
begin
  UpdateSliders;
  OnGeometry;
  SetLang;
  rb4.Caption:=INI.Str['Video.AspectRatioCustom'];
end;

procedure TfrVideoProps.tbBrChange(Sender: TObject);
begin
  if Assigned(DSH) then
    DSH.SetBCS(tbBr.Position,tbCo.Position,tbSa.Position);
  tbBr.Hint:=IntToStr(tbBr.Position)+'%';
  tbCo.Hint:=IntToStr(tbCo.Position)+'%';
  tbSa.Hint:=IntToStr(tbSa.Position)+'%';
end;

procedure TfrVideoProps.btResetBCSClick(Sender: TObject);
begin
  tbBr.Position:=50;
  tbCo.Position:=50;
  tbSa.Position:=50;
end;

procedure TfrVideoProps.FormCreate(Sender: TObject);
begin
  V2M:=TVCL2Model.Create(Core.MdlMgr);
  with V2M do begin
    CurModel:='App.VideoProps';

    Link('Decoder',btVideoDec);

    Link('ZoomX',tbZx);
    Link('ZoomY',tbZy);
    Link('ZoomReset',btResetZoom);
  end;
  Core.MdlMgr.Attach('App.VideoProps.Geometry',OnGeometry);
  gbZoom.DoubleBuffered:=TRUE;
end;

procedure TfrVideoProps.FormDestroy(Sender: TObject);
begin
  Core.MdlMgr.Detach('App.VideoProps.Geometry',OnGeometry);
  V2M.Free;
end;

procedure TfrVideoProps.DrawZoomImage;
var
  ScrR,AppR,WndR,VisR,ImgR,BndR,ViR:TRect;
  BW,BH,Delta:LongInt;
  Squeeze:Double;
begin
  ImgR:=Rect(0,0,imZoom.Width,imZoom.Height);

  with imZoom.Canvas do begin
    Brush.Color:=Color;
    FillRect(Rect(0,0,ImgR.Right,ImgR.Bottom));
  end;

  ViR:=frMain.MappedRect;

  ScrR:=Rect(0,0,Screen.Width,Screen.Height);
  GetWindowRect(frMain.Handle,AppR);
  WndR:=frMain.GetVideoRect;

  OffsetRect(ScrR,-WndR.Left,-WndR.Top);
  OffsetRect(AppR,-WndR.Left,-WndR.Top);
  OffsetRect(WndR,-WndR.Left,-WndR.Top);

  UnionRect(BndR,ScrR,AppR);
  UnionRect(BndR,BndR,ViR);
  BW:=BndR.Right-BndR.Left;
  BH:=BndR.Bottom-BndR.Top;

  Squeeze:=(BW/BH)/(4/3);
  if (Squeeze<1) then begin
    Delta:=Round(BW/Squeeze)-BW;
    Dec(BndR.Left,Delta div 2);
    Inc(BndR.Right,Delta div 2);
  end else begin
    Delta:=Round(BH*Squeeze)-BH;
    Dec(BndR.Top,Delta div 2);
    Inc(BndR.Bottom,Delta div 2);
  end;

  IntersectRect(VisR,WndR,ViR);

  with imZoom.Canvas do begin
    Brush.Color:=clDkGray;
    FillRect(TransposeRect(ScrR,BndR,ImgR));

    Brush.Color:=clRed;
    FillRect(TransposeRect(ViR,BndR,ImgR));

    Brush.Color:=clBlue;
    FillRect(TransposeRect(AppR,BndR,ImgR));

    Brush.Color:=clBlack;
    FillRect(TransposeRect(WndR,BndR,ImgR));

    Pen.Color:=clBlack;
    Brush.Color:=clLime;
    Rectangle(TransposeRect(VisR,BndR,ImgR));
  end;
end;

procedure TfrVideoProps.OnGeometry;
var
  S:String;
  ZX,ZY:LongInt;
begin
  DrawZoomImage;
  ZX:=Core.MdlMgr.GetSInt32('App.VideoProps.ZoomX');
  ZY:=Core.MdlMgr.GetSInt32('App.VideoProps.ZoomY');
  S:=Format('%d%% x %d%%',[ZX,ZY]);
  gbZoom.Caption:=' '+MS('Video.Zoom')+': '+S+' ';
  Core.Info(S);
end;

function TfrVideoProps.TransposeRect;
var
  Zx,Zy:Double;
begin
  Zx:=(ToR.Right-ToR.Left)/(FromR.Right-FromR.Left);
  Zy:=(ToR.Bottom-ToR.Top)/(FromR.Bottom-FromR.Top);

  Result.Left:=ToR.Left+Round(Zx*(SrcR.Left-FromR.Left));
  Result.Top:=ToR.Top+Round(Zy*(SrcR.Top-FromR.Top));
  Result.Right:=Result.Left+Round(Zx*(SrcR.Right-SrcR.Left));
  Result.Bottom:=Result.Top+Round(Zy*(SrcR.Bottom-SrcR.Top));
end;

procedure TfrVideoProps.Timer1Timer(Sender: TObject);
begin
  if Visible then begin
    DrawZoomImage;
    UpdateSliders;
  end;
end;

procedure TfrVideoProps.cbARClick(Sender: TObject);
begin
  if UpdateLock then Exit;
  UpdateLock:=TRUE;
  if cbAR.Checked then begin
    frMain.VideoModel.Ratio:=Point(0,0);
    if rb1.Checked then
      frMain.VideoModel.Ratio:=Point(0,0);
    if rb2.Checked then
      frMain.VideoModel.Ratio:=Point(4,3);
    if rb3.Checked then
      frMain.VideoModel.Ratio:=Point(16,9);
    if rb4.Checked then begin
      frMain.VideoModel.Ratio:=Str2Point(rb4.Caption);
    end;
  end else begin
    frMain.VideoModel.Ratio:=Point(-1,-1);
  end;
  UpdateLock:=FALSE;
  UpdateSliders;
  frMain.VideoModel.GeometryChanged;
end;

procedure TfrVideoProps.SetLang;
begin
  Caption:=MS('Command.300');
  gbBr.Caption:=' '+MS('OSD.Brightness')+' ';
  gbCo.Caption:=' '+MS('OSD.Contrast')+' ';
  gbSa.Caption:=' '+MS('OSD.Saturation')+' ';

  gbColors.Caption:=' '+MS('Video.Color')+' ';
  gbGeometry.Caption:=' '+MS('Video.Geometry')+' ';
  cbAR.Caption:=MS('Video.FixedAspectRatio');
  btVideoDec.Caption:=MS('Video.VideoDecoder');
  rb1.Caption:=MS('Video.AsIs');
end;

procedure TfrVideoProps.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key=VK_ESCAPE) then Close;
end;

procedure TfrVideoProps.cbVFlipClick(Sender: TObject);
var
  PVP:PVideoProcProps;
begin
  PVP:=DSH.GetVideoProcProps;
  if Assigned(PVP) then
    PVP^.VFlip:=cbVFlip.Checked;
end;

procedure TfrVideoProps.tbEffectChange(Sender: TObject);
var
  PVP:PVideoProcProps;
begin
  PVP:=DSH.GetVideoProcProps;
  if Assigned(PVP) then begin
    case tbEffect.Position of
      0:PVP^.Effect:=efBlur;
      1:PVP^.Effect:=efSoften;
      2:PVP^.Effect:=efSoftenX;
      3:PVP^.Effect:=efNone;
      4:PVP^.Effect:=efSharpenX;
      5:PVP^.Effect:=efSharpen;
      6:PVP^.Effect:=efEdge;
      7:PVP^.Effect:=efContour;
    end;
    PVP^.Update:=True;
  end;
end;

function TfrVideoProps.Str2Point;
var
  l:LongInt;
  S:String;
begin
  Result:=Point(1,1);

  l:=Pos(':',Str);
  try
    S:=Copy(Str,1,l-1);
    Result.X:=StrToInt(Trim(S));
  except
  end;
  try
    S:=Copy(Str,l+1,255);
    Result.Y:=StrToInt(Trim(S));
  except
  end;
end;

end.
