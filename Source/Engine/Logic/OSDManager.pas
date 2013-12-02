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
unit OSDManager;

interface

uses
  Windows, Classes, SysUtils, VideoProcessor, YVOSD, YVImage, Graphics,
  OSDPainter, Controls, OSDPanel;

type
  TOSDManager = class(TObject)
  private
    InfoCounter:LongInt;
    InfoOSD,Sub1OSD,Sub2OSD:TFixedOSD;
    YVIC:TYVImageCreator;
    OSDPnt:TOSDPainter;
    FInfoStr,FSub1Str,FSub2Str:String;
    VP:PVideoProcProps;
    FontCtl:TOSDPanel;

    function CreateOSDBitmap(Msg:String):TBitmap;
    procedure UpdateInfoOSD(Msg:String);
    procedure UpdateOSD(var OSD:TFixedOSD;Msg:String;YPos:LongInt);
    procedure UpdateVPArray(VP:PVideoProcProps);

    procedure SetInfoStr(const Value: String);
    procedure SetSub1Str(const Value: String);
    procedure SetSub2Str(const Value: String);

    function IsVP:Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Tick;
    procedure Info(Msg:String);

    property InfoStr:String read FInfoStr write SetInfoStr;
    property Sub1Str:String read FSub1Str write SetSub1Str;
    property Sub2Str:String read FSub2Str write SetSub2Str;
  end;

implementation

uses
  LACore, MainUnit, DShowHlp, OtherGlobalVars;

constructor TOSDManager.Create;
begin
  inherited Create;
  YVIC:=TYVImageCreator.Create;
  OSDPnt:=TOSDPainter.Create;
end;

function TOSDManager.CreateOSDBitmap(Msg: String): TBitmap;
var
  Lines,Line:String;
  l:LongInt;
  SaveFS:TFontStyles;
  Sz:TPoint;
  OfsX,OfsY:LongInt;
  BMP:TBitmap;
begin
  Result:=TBitmap.Create;
  Result.Width:=Core.DSH.VideoWidth;
  Result.Height:=0;
  Result.PixelFormat:=pf24Bit;
  Result.Canvas.Font.Assign(FontCtl.Font);
  Result.Canvas.Brush.Color:=$040004;

  Lines:=Trim(Msg);
  while (Lines<>'') do begin
    l:=Pos(#10,Lines);
    if (l=0) then begin
      Line:=Lines;
      Lines:='';
    end else begin
      Line:=Trim(Copy(Lines,1,l));
      Lines:=Trim(Copy(Lines,l+1,Length(Lines)-l));
    end;

    Line:=' '+Line+' ';

    Result.Canvas.Font.Color:=clBlack;
    SaveFS:=Result.Canvas.Font.Style;
    BMP:=OSDPnt.CreateLineBitmap(Line,Result.Canvas.Font);
    BMP.TransparentColor:=$040004;
    BMP.Transparent:=TRUE;
    Sz:=Point(BMP.Width,BMP.Height);
    Result.Canvas.Font.Style:=SaveFS;

    OfsX:=(Result.Width-Sz.X) div 2;
    if (frMain.pnInfo.VAlign in [vaTopLeft,vaBottomLeft]) then
      OfsX:=5;
    if (frMain.pnInfo.VAlign in [vaTopRight,vaBottomRight]) then
      OfsX:=Result.Width-Sz.X-5;
    OfsY:=Result.Height+2;

    Result.Height:=Result.Height+Sz.Y+4;

    Result.Canvas.Draw(OfsX-1,OfsY-0,Bmp);
    Result.Canvas.Draw(OfsX+1,OfsY-0,Bmp);
    Result.Canvas.Draw(OfsX+0,OfsY+1,Bmp);
    Result.Canvas.Draw(OfsX-0,OfsY-1,Bmp);
    Bmp.Free;

    Result.Canvas.Font.Color:=FontCtl.Font.Color;
    BMP:=OSDPnt.CreateLineBitmap(Line,Result.Canvas.Font);
    BMP.TransparentColor:=$040004;
    BMP.Transparent:=TRUE;
    Sz:=Point(BMP.Width,BMP.Height);
    Result.Canvas.Draw(OfsX,OfsY,Bmp);
    Bmp.Free;
  end;

  Result.Transparent:=TRUE;
  Result.TransparentColor:=$040004;
end;

destructor TOSDManager.Destroy;
begin
  if Assigned(InfoOSD.Img) then
    InfoOSD.Img.Free;
  if Assigned(Sub1OSD.Img) then
    Sub1OSD.Img.Free;
  if Assigned(Sub2OSD.Img) then
    Sub2OSD.Img.Free;
  OSDPnt.Free;
  YVIC.Free;
  inherited Destroy;
end;

procedure TOSDManager.Info(Msg: String);
begin
  if not(INI.Bool['OSD.Info.Show']) then Exit;

  InfoCounter:=10*INI.Int['OSD.Info.Duration'];
  if (InfoCounter=0) then InfoStr:='' else InfoStr:=Msg;
end;

function TOSDManager.IsVP: Boolean;
begin
  VP:=NIL;
  Result:=FALSE;
  if INI.Bool['OSD.WithVideo'] then begin
    VP:=Core.DSH.GetVideoProcProps;
    Result:=(VP<>NIL);
  end;
end;

procedure TOSDManager.SetInfoStr;
begin
  if (FInfoStr<>Value) then begin
    FInfoStr:=Value;

    if IsVP then begin
      frMain.pnInfo.Visible:=FALSE;
      FontCtl:=frMain.pnInfo;
      VP.OSD.UpdateBegin;
      UpdateInfoOSD(FInfoStr);
      UpdateVPArray(VP);
      VP.OSD.UpdateEnd;
    end else begin
      frMain.pnInfo.Text:=FInfoStr;
      frMain.pnInfo.Visible:=(FInfoStr<>'');
    end;
  end;
end;

procedure TOSDManager.SetSub1Str;
begin
  if (FSub1Str<>Value) then begin
    FSub1Str:=Value;

    if IsVP then begin
      frMain.pnSubs1.Visible:=FALSE;
      FontCtl:=frMain.pnSubs1;
      VP.OSD.UpdateBegin;
      UpdateOSD(Sub1OSD,Value,Core.Subs.Sub1.YPos);
      UpdateVPArray(VP);
      VP.OSD.UpdateEnd;
    end else
    begin
      frMain.pnSubs1.Text:= Value;
      frMain.pnSubs1.Visible:=(Value<>'');
    end;
  end;
end;

procedure TOSDManager.SetSub2Str;
begin
  if (FSub2Str<>Value) then begin
    FSub2Str:=Value;

    if IsVP then begin
      frMain.pnSubs2.Visible:=FALSE;
      FontCtl:=frMain.pnSubs2;
      VP.OSD.UpdateBegin;
      UpdateOSD(Sub2OSD,Value,Core.Subs.Sub2.YPos);
      UpdateVPArray(VP);
      VP.OSD.UpdateEnd;
    end else begin
      frMain.pnSubs2.Text:=Value;
      frMain.pnSubs2.Visible:=(Value<>'');
    end;
  end;
end;

procedure TOSDManager.Tick;
var
  Pos:Int64;
begin
  if (InfoCounter>0) then
  begin
    InfoHided := False;
    Dec(InfoCounter);
    if (InfoCounter=0) then
    begin
      InfoHided := True;
      InfoStr:='';
    end;
  end;

  if Assigned(Core.Subs) then begin
    frMain.HoverButtons[hiSubtitles].Down:=not(Core.Subs.IsEmpty);
    if not(Core.Subs.IsEmpty) then begin
      Pos:=0;
      if (Core.Player<>NIL) and (Core.DSH<>NIL) then begin
        try
          Pos:=DSH.Position;
        except
        end;
      end;

      Sub1Str:=Core.Subs.Sub1.GetSubText(Pos);
      Sub2Str:=Core.Subs.Sub2.GetSubText(Pos);
    end else begin
      Sub1Str:='';
      Sub2Str:='';
    end;
  end else begin
    Sub1Str:='';
    Sub2Str:='';
  end;
end;

procedure TOSDManager.UpdateInfoOSD(Msg: String);
var
  BMP:TBitmap;
begin
  if Assigned(InfoOSD.Img) then
    InfoOSD.Img.Free;

  InfoOSD.OfsX:=1;
  InfoOSD.OfsY:=0;

  BMP:=CreateOSDBitmap(Msg);
  InfoOSD.Img:=YVIC.CreateYVImage(BMP);
  BMP.Free;
end;

procedure TOSDManager.UpdateOSD;
var
  BMP:TBitmap;
  Y:LongInt;
begin
  if Assigned(OSD.Img) then
    OSD.Img.Free;

  OSD.OfsX:=1;

  BMP:=CreateOSDBitmap(Msg);
  OSD.Img:=YVIC.CreateYVImage(BMP);

  Y:=100-YPos;
  if (Y<50) then begin
    OSD.OfsY:=(DSH.VideoHeight*Y) div 100;
  end else begin
    OSD.OfsY:=DSH.VideoHeight - BMP.Height - ((DSH.VideoHeight*(100-Y)) div 100);
  end;

  BMP.Free;
end;

procedure TOSDManager.UpdateVPArray;
var
  Len:LongInt;
begin
  Len:=0;
  SetLength(VP.OSD.Arr,3);
  if (FInfoStr<>'') then begin
    VP.OSD.Arr[Len]:=InfoOSD;
    Inc(Len);
  end;
  if (FSub1Str<>'') then begin
    VP.OSD.Arr[Len]:=Sub1OSD;
    Inc(Len);
  end;
  if (FSub2Str<>'') then begin
    VP.OSD.Arr[Len]:=Sub2OSD;
    Inc(Len);
  end;
  SetLength(VP.OSD.Arr,Len);
end;

end.
