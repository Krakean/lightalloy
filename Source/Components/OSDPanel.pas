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

unit OSDPanel;

interface

uses
  Windows, Controls, Classes, SysUtils, Graphics, Forms, GdipApi, GdipObj;

type
  TVAlign = (vaTop,vaBottom,vaTopLeft,vaTopRight,vaBottomLeft,vaBottomRight);
  TPanelType = (ptInfo,ptSubtitles);

  TOSDPanel = class(TCustomControl)
  private
    FText:String;
    WndRgn:HRGN;

    procedure SetText(Value:String);

    procedure ResetRegion;
    procedure AddRoundRegion(OfsX,OfsY,SzX,SzY,RndSz:LongInt); register;
    procedure ApplyRegion;
    procedure PaintGDIP;
  protected
    procedure Paint; override;
  public
    vDBorderCol: TGPColor;
    vDInnerCol: TGPColor;
    vDCQ: CompositingQuality;
    vDSM: SmoothingMode;

    DPen: TGPPen;
    Layout: TGPRect;
    Drawer: TGPGraphics;
    DBrush: TGPSolidBrush;
    DFntFam: TGPFontFamily;
    DPath: TGPGraphicsPath;
    DFntFmt: TGPStringFormat;
    DRG:TGPRegion;

    VAlign:TVAlign;
    PanelType:TPanelType;

    constructor Create(AOwner:TComponent); override;
    destructor Destroy; override;

    procedure AlignSelf(PC:TControl;YPos:LongInt);

    property Text:String read FText write SetText;
    property Font;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnDblClick;
  end;

implementation

uses
  MainUnit, LACore;

{ TOSDPanel }

procedure TOSDPanel.AddRoundRegion;
var
  LineRgn:HRGN;
begin
  LineRgn:=CreateRoundRectRgn(OfsX,OfsY,OfsX+SzX,OfsY+SzY,RndSz,RndSz);
  CombineRgn(WndRgn,WndRgn,LineRgn,RGN_OR);
  DeleteObject(LineRgn);
end;

procedure TOSDPanel.AlignSelf;
begin
  if (YPos<0) then begin
    if (VAlign in [vaTopLeft,vaTop,vaTopRight]) then begin
      SetBounds(PC.Left,PC.Top+1,PC.Width,PC.Height);
    end else begin
      SetBounds(PC.Left,PC.Height-Height-1,PC.Width,Height);
    end;
  end else begin
  end;
end;

procedure TOSDPanel.ApplyRegion;
begin
  SetWindowRgn(Handle,WndRgn,TRUE);
end;

constructor TOSDPanel.Create;
begin
  inherited Create(AOwner);
  DoubleBuffered:=TRUE;
  VAlign:=vaBottom;
end;

destructor TOSDPanel.Destroy;
begin
  inherited Destroy;
end;

procedure TOSDPanel.Paint;
begin
  PaintGDIP;
end;

procedure TOSDPanel.PaintGDIP;
var
  Bounds:TRect;
  OfsX,OfsY:LongInt;
  Lines,Line:String;
  l, H:LongInt;
  FC:TColor;
  SC:TColor;
  Sz:TPoint;
  IsColor: Boolean;
  Rgn:HRGN;
  Style:Integer;
  Size: TGPRect;

  procedure GDIDrawText(Line:String);
  begin
    Layout.X:=OfsX;
    Layout.Y:=OfsY;

    DPath.Reset;
    DPath.AddString(Line, Length(Line), DFntFam, Style, Font.Size+5, Layout, DFntFmt);

    Drawer.DrawPath(DPen, DPath);
    Drawer.FillPath(DBrush, DPath);

    DPath.Reset;
    Layout.X:=OfsX+1;
    Layout.Y:=OfsY;
    DPath.AddString(Line, Length(Line), DFntFam, Style, Font.Size+5, Layout, DFntFmt);
    DRG.Union(DPath);

    DPath.Reset;
    Layout.X:=OfsX-1;
    Layout.Y:=OfsY;
    DPath.AddString(Line, Length(Line), DFntFam, Style, Font.Size+5, Layout, DFntFmt);
    DRG.Union(DPath);

    DPath.Reset;
    Layout.X:=OfsX;
    Layout.Y:=OfsY+1;
    DPath.AddString(Line, Length(Line), DFntFam, Style, Font.Size+5, Layout, DFntFmt);
    DRG.Union(DPath);

    DPath.Reset;
    Layout.X:=OfsX;
    Layout.Y:=OfsY-1;
    DPath.AddString(Line, Length(Line), DFntFam, Style, Font.Size+5, Layout, DFntFmt);
    DRG.Union(DPath);

    RGN:= DRG.GetHRGN(Drawer);
    CombineRgn(WndRgn,WndRgn,RGN,2);
    DeleteObject(Rgn);
  end;
begin
  FC:=Font.Color;
  if ModernSkinEngine and (Core.Prefs.ReadBool('OSD.Info.UseSkinColors'))
    and (PanelType = ptInfo)
  then
    try
      FC:=Core.OptiBld.GetImage('Color.OSD').Canvas.Pixels[0,0];
    except
      FC := clRed;
    end;

  Bounds:=GetClientRect;
  Canvas.Font.Assign(Font);

  ResetRegion;
  if PanelType = ptInfo then begin
    SC:=Core.Prefs.Int['OSD.BG.Color'];
    if ModernSkinEngine and (Core.Prefs.ReadBool('OSD.Info.UseSkinColors')) then
      try
        SC := Core.OptiBld.GetImage('Color.OSD').Canvas.Pixels[0,3];
      except
        SC := clBlue;
      end;
  end
  else
    SC:=Core.Prefs.Int['Subtitles.ShadowColor'];
  IsColor:=Core.Prefs.ReadBool('OSD.BG.IsColor');

  with Canvas do begin
    H:=1;
    Lines:=Trim(FText);

    vDBorderCol:= MakeColor(GetRValue(SC), GetGValue(SC), GetBValue(SC));
    // Set colors
    vDInnerCol:= MakeColor(GetRValue(FC), GetGValue(FC), GetBValue(FC));

    // Create objects
    DPath:=TGPGraphicsPath.Create;
    DPen:=TGPPen.Create(vDBorderCol,1);
    DBrush:=TGPSolidBrush.Create(vDInnerCol);
    DFntFam:=TGPFontFamily.Create(Canvas.Font.Name);
    DRG:=TGPRegion.Create(DPath);
    DFntFmt:=TGPStringFormat.Create;
    Drawer:=TGPGraphics.Create(Canvas.Handle);
    Drawer.Clear(vDBorderCol);

    // Set quality
    vDSM:=SmoothingModeAntiAlias;
    vDCQ:=CompositingQualityHighSpeed;
    Drawer.SetCompositingQuality(vDCQ);
    Drawer.SetSmoothingMode(vdSM);

    while (Lines<>'') do
    begin
      Sz.X:=0;

      // Rows count processing
      l:=Pos(#10,Lines);
      if (l=0) then begin
        Line:=Lines;
        Lines:='';
      end else
      begin
        Line:=Trim(Copy(Lines,1,l));
        Lines:=Trim(Copy(Lines,l+1,Length(Lines)-l));
      end;
      Line:=' '+Line+' ';

      Style:=0;
      if fsBold in Font.Style then Style:=Style or FontStyleBold;
      if fsItalic in Font.Style then Style:=Style or FontStyleItalic;

      Size.X:=0;
      Size.Y:=0;
      Size.Width:=0;
      Size.Height:=0;
      DPath.Reset;
      DPath.AddString(Line, Length(Line), DFntFam, Style, Font.Size+5, Size, DFntFmt);
      DPath.GetBounds(Size);
      Sz.X:=Size.Width+Font.Size+2;
      Sz.Y:=Size.Height+(Font.Size div 4);

      // Align applying
      case VAlign of
        vaTopLeft,vaBottomLeft: OfsX:=5;
        vaTopRight,vaBottomRight:OfsX:=Width-Sz.X-5;
      else
        OfsX:=(Width-Sz.X) div 2;
      end;
      OfsY:=H+2;

      // Draw and set region
      GDIDrawText(Line);

      Inc(Sz.Y,4);
      Inc(H,Sz.Y);

      // Rounded region
      if IsColor then
        AddRoundRegion(OfsX,OfsY-2,Sz.X,Sz.Y,2+(Font.Size));
    end;
  end;

  if (VAlign in [vaTopLeft,vaTop,vaTopRight]) then
    Height:=H
  else
    SetBounds(Left,Top+Height-H,Width,H);

  ApplyRegion;

  DFntFmt.Free;
  DFntFam.Free;
  DRG.Free;
  DBrush.Free;
  DPen.Free;
  DPath.Free;
  Drawer.Free;
end;

procedure TOSDPanel.ResetRegion;
begin
  WndRgn:=CreateRectRgn(0,0,0,0);
end;

procedure TOSDPanel.SetText;
begin
  if (FText<>Value) then begin
    FText:=Value;
    Invalidate;
  end;
end;

end.
