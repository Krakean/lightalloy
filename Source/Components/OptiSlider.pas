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

unit OptiSlider;

interface

uses
  Windows, Classes, Controls, OptiWrapper, ExtCtrls, OptiImage,
  OptiUtils, OptiImgUtils, OptiFont;

type
  TOptiSlider = class(TPanel)
  private
    IsDrag:Boolean;

    procedure TrackSeeker(X:LongInt);
  protected
    Pos:Int64;

    procedure Paint; override;

    procedure OnTimer;
    procedure MouseDown(Button:TMouseButton;Shift:TShiftState;X,Y:Integer); override;
    procedure MouseMove(Shift:TShiftState;X,Y:Integer); override;
    procedure MouseUp(Button:TMouseButton;Shift:TShiftState;X,Y:Integer); override;
  public
    arBG,arBGF,arThumb:TOptiArea;
    BGSplit:TPoint;

    constructor Create(AOwner:TComponent); override;
    destructor Destroy; override;
  end;

  TOptiSliderWrapper = class(TOptiWrapper)
  private
    OS:TOptiSlider;
  public
    procedure Load; override;
  end;

implementation

uses
  LACore;

{ TOptiSlider }

constructor TOptiSlider.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ParentBackground:=FALSE;
  DoubleBuffered:=TRUE;
  BevelOuter:=bvNone;

  Core.TimerNotifier.Attach(OnTimer);
end;

destructor TOptiSlider.Destroy;
begin
  Core.TimerNotifier.Detach(OnTimer);
  inherited Destroy;
end;

procedure TOptiSlider.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited;

  if (Button<>mbLeft) then Exit;
  TrackSeeker(X);
  IsDrag:=TRUE;
end;

procedure TOptiSlider.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if IsDrag then
    TrackSeeker(X);

end;

procedure TOptiSlider.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited;
  IsDrag:=FALSE;

end;

procedure TOptiSlider.OnTimer;
begin
  Invalidate;
end;

procedure TOptiSlider.Paint;
var
  CLR,R:TRect;
  x:LongInt;
begin
//  inherited;
  CLR:=ClientRect;
  // Рисуем черную фон-линию (справа-налево) - сколько можно матать звук.
  OptiImgSplit(arBG,Canvas,CLR,BGSplit);

  Pos:=Core.GetVolume;
  R:=CLR;
  x:=(R.Right-10)*Pos div 100;
  R.Right:=x+5;

  // Рисуем красную фон-линию (слева-направо) - сколько проматали звук.
  if (Pos<>0) then begin
    OptiImgSplit(arBGF,Canvas,R,BGSplit);
  end;

  // Рисуем саму картинку.
  OptiImgDraw(arThumb,Canvas,Point(x,0));
end;

procedure TOptiSlider.TrackSeeker(X: Integer);
var
  Pos:Int64;
  R:TRect;
begin
  R:=ClientRect;
  Pos:=((x-4)*(100)) div (R.Right-10);
  if (Pos<0) then Pos:=0;
  if (Pos>100) then Pos:=100;

  Core.SetVolume(Pos);
  Invalidate;
end;

{ TOptiSliderWrapper }

procedure TOptiSliderWrapper.Load;
var
  S:String;
begin
  OS:=TOptiSlider.Create(ParCtl);
  OS.Parent:=ParCtl;
  Ctl:=OS;
  
  S:=Node.Attr('bg');
  if (S<>'') then
    OS.arBG:=ORes.GetArea(S);
  S:=Node.Attr('bgfill');
  if (S<>'') then
    OS.arBGF:=ORes.GetArea(S);

  S:=Node.Attr('bgsplit');
  if (S<>'') then
    OS.BGSplit:=Str2Point(S);

  S:=Node.Attr('thumb');
  if (S<>'') then
    OS.arThumb:=ORes.GetArea(S);

  ApplyPos;
end;

end.
