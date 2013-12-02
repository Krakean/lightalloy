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

unit HoverBt;

interface

uses
  Windows, Controls, Graphics, ExtCtrls, Classes, Messages, SysUtils, Forms;

const
  WM_MOUSELEAVE = $02A3;

type
  THoverButton = class(TCustomControl)
  private
    procedure OnMouseLeave(var Message:TMessage); message WM_MOUSELEAVE;
    procedure SetHovered(const Value: boolean);
    procedure SetDown(const Value: boolean);
    procedure SetFEnabled(const Value: boolean);
    procedure SetPressed(const Value: boolean);
  protected
    procedure Paint; override;
  public
    OrgX:LongInt;
    OrgImg:TImage;
    FHovered:boolean;
    FEnabled:boolean;
    FPressed:boolean;
    FDown:boolean;
    Command:longint;
    bmpBG:TBitmap;

    constructor Create(AOwner:TComponent); override;
    procedure MouseDown(Button:TMouseButton;Shift:TShiftState;X,Y:Integer);override;
    procedure MouseMove(Shift:TShiftState;X,Y:Integer); override;
    procedure MouseUp(Button:TMouseButton;Shift:TShiftState;X,Y:Integer);override;
    property Hovered:boolean read FHovered write SetHovered;
    property Enabled:boolean read FEnabled write SetFEnabled;
    property Down:boolean read FDown write SetDown;
    property Pressed:boolean read FPressed write SetPressed;
  end;

implementation

uses MainUnit, LACore;

var
  DLLUser32:HMODULE;
  TrackMouseEventProc:function (var EventTrack: TTrackMouseEvent): BOOL; stdcall;

{ THoverButton }

constructor THoverButton.Create;
begin
  inherited Create(AOwner);
  DoubleBuffered:=TRUE;
  FHovered:=FALSE;
  FEnabled:=TRUE;
  FDown:=FALSE;
  ParentColor:=TRUE;
end;

procedure THoverButton.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited;
  if (Button<>mbLeft) then Exit;
  if FEnabled then
    Pressed:=TRUE;
  ReleaseCapture;
end;

procedure THoverButton.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited;
  if (Button<>mbLeft) then Exit;
  if (FEnabled and FPressed) then begin
    Pressed:=FALSE;
    PostMessage(frMain.Handle,WM_LACMD,Ord(Command),0);
  end;
end;

procedure THoverButton.MouseMove;
var
  TME:TTRACKMOUSEEVENT;
begin
  inherited MouseMove(Shift,X,Y);
  with TME do begin
    cbSize:=SizeOf(TME);
    dwFlags:=TME_LEAVE;
    hwndTrack:=Handle;
    dwHoverTime:=400;
  end;
  if (Assigned(TrackMouseEventProc)) then begin
    TrackMouseEventProc(TME);
    Hovered:=TRUE;
  end;
end;

procedure THoverButton.OnMouseLeave;
begin
  Hovered:=FALSE;
  Pressed:=FALSE;
end;

procedure THoverButton.Paint;
var
  ViewMode:longint;
begin
  if Assigned(bmpBG) then begin
    Canvas.Draw(0,-1,bmpBG);
    Canvas.Draw(1,-1,bmpBG);
  end;

  ViewMode:=Ord(FDown or Pressed)*3;
  if not(FEnabled) then
    Inc(ViewMode,2)
  else
    Inc(ViewMode,Ord(FHovered));
  frMain.DrawSkinRect(Canvas,Rect(OrgX,ViewMode*Height,Width,Height),0,0);
end;

procedure THoverButton.SetDown;
begin
  if (FDown<>Value) then begin
    FDown:=Value;
    Invalidate;
  end;
end;

procedure THoverButton.SetFEnabled;
begin
  if (FEnabled<>Value) then begin
    FEnabled:=Value;
    Invalidate;
  end;
end;

procedure THoverButton.SetHovered;
begin
  if (FHovered<>Value) then begin
    FHovered:=Value;
    Invalidate;
  end;
end;

procedure THoverButton.SetPressed;
begin
  if (FPressed<>Value) then begin
    FPressed:=Value;
    Invalidate;
  end;
end;

initialization
begin
  DLLUser32:=LoadLibrary('USER32.DLL');
  TrackMouseEventProc:=GetProcAddress(DLLUser32,'TrackMouseEvent');
end;

finalization
begin
  if (DLLUser32<>0) then FreeLibrary(DLLUser32);
end;

end.
