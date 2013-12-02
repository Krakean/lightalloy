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

unit OptiText;

interface

uses
  Windows, Classes, Controls, ExtCtrls, Graphics,
  OptiRes, OptiImage, OptiImgUtils, Messages, OptiWrapper,
  OptiUtils, OptiFont;

type
  TOptiText = class(TPanel)
  protected
    procedure Paint; override;
    procedure OnTimer;
    procedure OnHitText(var Msg:TMessage); message WM_NCHITTEST;
  public
    OFnt:TOptiFont;
    Txt,DispTxt:String;
    arBG:TOptiArea;
    BGSplit:TPoint;

    constructor Create(AOwner:TComponent); override;
    destructor Destroy; override;
  end;

  TOptiTextWrapper = class(TOptiWrapper)
  private
    OT:TOptiText;
  public
    procedure Load; override;
  end;

implementation

uses
  LACore;

procedure TOptiTextWrapper.Load;
var
  S:String;
begin
  OT:=TOptiText.Create(ParCtl);
  OT.Parent:=ParCtl;
  Ctl:=OT;

  S:=Node.Attr('font');
  if (S<>'') then;
    OT.OFnt:=ORes.GetFont(S);

  OT.Txt:=Node.Attr('text');

  S:=Node.Attr('bg');
  if (S<>'') then
    OT.arBG:=ORes.GetArea(S);

  S:=Node.Attr('bgsplit');
  if (S<>'') then
    OT.BGSplit:=Str2Point(S);
  
  ApplyBG;
  ApplyPos;
end;

{ TOptiText }

constructor TOptiText.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ParentBackground:=FALSE;
  DoubleBuffered:=TRUE;
  BevelOuter:=bvNone;

  Core.TimerNotifier.Attach(OnTimer);
end;

destructor TOptiText.Destroy;
begin
  Core.TimerNotifier.Detach(OnTimer);
  inherited Destroy;
end;

procedure TOptiText.OnHitText(var Msg: TMessage);
begin
  Msg.Result:=HTTRANSPARENT;
end;

procedure TOptiText.OnTimer;
var
  NewTxt:String;
begin
  NewTxt:=Core.SysText(Txt);
  if (NewTxt<>DispTxt) then begin
    DispTxt:=NewTxt;
    Invalidate;
  end;
end;

procedure TOptiText.Paint;
var
  x:LongInt;
  S:String;
begin
  if Assigned(arBG.BMP) then begin
    OptiImgSplit(arBG,Canvas,ClientRect,BGSplit);
  end else begin
    inherited Paint;
  end;

  if (OFnt=NIL) then begin
    with Canvas do begin
      Font.Name:='Tahoma';
      Font.Style:=[fsBold];
      Font.Size:=8;
      Font.Color:=clWhite;
      Brush.Style:=bsClear;

      S:=DispTxt;
      while (TextWidth(S)>(Width-15)) do S:=Copy(S,1,Length(S)-1);
      x:=(Width-TextWidth(S)) div 2;
      TextOut(x,0,S);
    end;
  end else begin
    OFnt.DrawText(DispTxt,Canvas,ClientRect);
  end;
end;

end.
