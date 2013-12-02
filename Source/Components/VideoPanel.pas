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

unit VideoPanel;

interface

uses
  Windows, Classes, Controls, ExtCtrls, Messages, Graphics, SysUtils,
  OtherGlobalVars;

type
  TInternalPanel = class(TPanel)
  protected
    procedure Paint; override;
  public
  end;

  TVideoPanel = class(TPanel)
  private
    PanelColor:TColor;
    IsDefaultLogo:Boolean;
    procedure OnEraseBG(var Msg:TMessage); message WM_ERASEBKGND;
  protected
    procedure Paint; override;
  public
    InternalPanel:TInternalPanel;
    bmpLogo:TBitmap;
    Pic:TBitmap;
    R: TRect;
    bmpSkinLogo:TBitmap;
    ShowLogo:Boolean;

    procedure LoadDefaultLogo;
    procedure SetLogo(BMP:TBitmap);
    procedure SetLogoImage(Img:TImage);
    procedure SetLogoScale;
    procedure UpdateColors;

    constructor Create(AOwner:TComponent); override;
    destructor Destroy; override;
  end;

implementation

uses
  MainUnit, LACore;

constructor TVideoPanel.Create;
begin
  inherited Create(AOwner);
  ParentBackground:=FALSE;
  DoubleBuffered:=FALSE;
  BevelOuter:=bvNone;

  PanelColor:=clBlack;

  InternalPanel:=TInternalPanel.Create(Self);
  InternalPanel.Visible:=FALSE;
  InternalPanel.Color:=clBlack;
  InternalPanel.Parent:=Self;
  InternalPanel.BevelOuter:=bvNone;
  InternalPanel.Width:=0;
  InternalPanel.Height:=0;
  InternalPanel.ParentBackground:=FALSE;
  InternalPanel.DoubleBuffered:=FALSE;

  bmpLogo:=TBitmap.Create;
  Pic:=TBitmap.Create;
  bmpLogo.PixelFormat:=pf32bit;
  ShowLogo:=False;
  IsDefaultLogo:=False;
end;

destructor TVideoPanel.Destroy;
begin
  if Assigned(bmpSkinLogo) then
    bmpSkinLogo.Free;
  bmpLogo.Free;
  Pic.Free;

  inherited Destroy;
end;

procedure TVideoPanel.LoadDefaultLogo;
var
  BMP:TBitmap;
  OldH:THandle;
  S:String;
  OK:Boolean;
begin
  OK:=FALSE;
  BMP:=TBitmap.Create;
  IsDefaultLogo:=True;

  {S:=Core.ExePath+'Logo.bmp';
  if (FileExists(S)) then begin
    try
      BMP.LoadFromFile(S);
      OK:=TRUE;
      SetLogo(BMP);
    except
    end;
  end;}

  if (not(OK) and Assigned(bmpSkinLogo)) then begin
    SetLogo(bmpSkinLogo);
    OK:=TRUE;
  end;

  if not(OK) then begin
    S:='LogoDefault';
    OldH:=BMP.Handle;
    BMP.Handle:=LoadBitmap(hInstance,PChar(S));
    SetLogo(BMP);
    BMP.Handle:=OldH;
  end;

  BMP.Free;
end;

procedure TVideoPanel.OnEraseBG(var Msg: TMessage);
begin
  Msg.Result:=1;
end;

procedure TVideoPanel.Paint;
var
  x1,y1,x2,y2:LongInt;
begin
  with Canvas do begin
    if ShowLogo then begin
      x1:=(Width-bmpLogo.Width) div 2;
      y1:=(Height-bmpLogo.Height) div 2;
      x2:=x1+bmpLogo.Width;
      y2:=y1+bmpLogo.Height;

      Brush.Color:=PanelColor;
      FillRect(Rect(0,0,Width,y1));
      FillRect(Rect(0,y2,Width,Height));

      FillRect(Rect(0,y1,x1,y2));
      FillRect(Rect(x2,y1,Width,y2));

      Draw(x1,y1,bmpLogo);
    end
    else
      inherited;
  end;
end;

procedure TVideoPanel.SetLogo(BMP: TBitmap);
begin
  bmpLogo.Width:=BMP.Width;
  bmpLogo.Height:=BMP.Height;
  bmpLogo.Canvas.Draw(0,0,BMP);
  Invalidate;
end;

procedure TVideoPanel.SetLogoImage(Img: TImage);
begin
  // Proportional
  Pic.Assign(Img.Picture.Graphic);
  R := Pic.Canvas.ClipRect;
  SetLogoScale;
  IsDefaultLogo:=False;
  Invalidate;
end;

procedure TVideoPanel.SetLogoScale;
var Scale: Double;
    dy: integer;
begin
  if FullScreenMode then dy:=99 else dy:=0;

  if ((R.Right > Width) or (R.Bottom > Height)) and
    not(Core.Prefs.ReadBool('OnOpen.CoverResize'))then
  begin
    scale := (Height+dy) / R.Bottom;
      if (dy=0) then
        if  ((R.Bottom/R.Right)<(height/width)) then
          scale := Width / R.Right;

    bmpLogo.Width :=trunc( R.Right * scale );
    bmpLogo.Height:=trunc( R.Bottom * scale );
    bmpLogo.Canvas.StretchDraw(bmpLogo.Canvas.ClipRect , Pic );
  end
  else begin
    bmpLogo.Height:=R.Bottom;
    bmpLogo.Width:=R.Right;
    bmpLogo.Canvas.Draw(0,0,Pic);
  end;

  Invalidate;
end;

procedure TInternalPanel.Paint;
begin
//  inherited;
  if (frMain.State=stPlay) or (frMain.State=stSpeedPlay) then
    Self.DoubleBuffered:=True
  else
    Self.DoubleBuffered:=False;
  frMain.RepaintVideo;
end;

procedure TVideoPanel.UpdateColors;
begin
  if ModernSkinEngine then
    try
      PanelColor:=Core.OptiBld.GetImage('Color.OSD').Canvas.Pixels[0,4];
    except
      PanelColor:=clBlack;
    end
  else
  if IsDefaultLogo then
    PanelColor:=clBlack
  else
    PanelColor:=frMain.imSkin.Canvas.Pixels[761,107];
end;

end.
