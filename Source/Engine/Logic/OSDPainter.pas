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
unit OSDPainter;

interface

uses
  Windows, Classes, Graphics, Forms, SysUtils;

type
  TOSDPainter = class(TObject)
  public
    TmpBmp:TBitmap;
    CurFS:TFontStyles;
    BgColor:TColor;

    constructor Create;
    destructor Destroy; override;

    function DrawTextLine(Line:String;AFont:TFont):TPoint;
    function CreateLineBitmap(Line:String;AFont:TFont):TBitmap;
  end;

implementation

{ TOSDPainter }

constructor TOSDPainter.Create;
begin
  inherited Create;
  TmpBmp:=TBitmap.Create;
  TmpBmp.Width:=Screen.Width;
  TmpBmp.Height:=200;
  TmpBmp.PixelFormat:=pfDevice;
  TmpBmp.Canvas.Brush.Color:=$040004;
end;

function TOSDPainter.CreateLineBitmap;
var
  Sz:TPoint;
  R:TRect;
begin
  Sz:=DrawTextLine(Line,AFont);

  Result:=TBitmap.Create;
  Result.Width:=Sz.X;
  Result.Height:=Sz.Y;
  Result.PixelFormat:=pfDevice;

  R:=Rect(0,0,Sz.X,Sz.Y);
  Result.Canvas.CopyRect(R,TmpBmp.Canvas,R);
end;

destructor TOSDPainter.Destroy;
begin
  TmpBmp.Free;
  inherited Destroy;
end;

function TOSDPainter.DrawTextLine;
var
  BMP:TBitmap;
  TC:TColor;
  Part,Ln:String;
  X:LongInt;

  procedure Flush;
  begin
    if (Part='') then Exit;
    with BMP.Canvas do begin
      Font.Style:=CurFS;
      TextOut(X,0,Part);
      Inc(X,TextWidth(Part));
      Part:='';
    end;
  end;
begin
  TC:=$040004;//TmpBmp.Canvas.Brush.Color;

  BMP:=TmpBmp;

  X:=0;
  with BMP.Canvas do begin
    Brush.Color:=TC;
    Brush.Style:=bsSolid;
    FillRect(Rect(0,0,BMP.Width,BMP.Height));

    Font.Assign(AFont);
    Brush.Style:=bsClear;

    Part:='';
    Ln:=Line;
    while (Ln<>'') do begin
      if SameText(Copy(Ln,1,3),'<B>') then begin
        Flush;
        CurFS:=CurFS+[fsBold];
        Ln:=Copy(Ln,4,1024);
        Continue;
      end;
      if SameText(Copy(Ln,1,4),'</B>') then begin
        Flush;
        CurFS:=CurFS-[fsBold];
        Ln:=Copy(Ln,5,1024);
        Continue;
      end;
      if SameText(Copy(Ln,1,3),'<I>') then begin
        Flush;
        CurFS:=CurFS+[fsItalic];
        Ln:=Copy(Ln,4,1024);
        Continue;
      end;
      if SameText(Copy(Ln,1,4),'</I>') then begin
        Flush;
        CurFS:=CurFS-[fsItalic];
        Ln:=Copy(Ln,5,1024);
        Continue;
      end;
      if SameText(Copy(Ln,1,3),'<U>') then begin
        Flush;
        CurFS:=CurFS+[fsUnderline];
        Ln:=Copy(Ln,4,1024);
        Continue;
      end;
      if SameText(Copy(Ln,1,4),'</U>') then begin
        Flush;
        CurFS:=CurFS-[fsUnderline];
        Ln:=Copy(Ln,5,1024);
        Continue;
      end;
      Part:=Part+Ln[1];
      Ln:=Copy(Ln,2,1024);
    end;
    Flush;
  end;

  Result:=Point(X,BMP.Canvas.TextHeight(Line));
end;

end.
