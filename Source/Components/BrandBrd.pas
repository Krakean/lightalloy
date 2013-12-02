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

unit BrandBrd;

interface

uses
  Windows, Classes, Forms, ExtCtrls, Controls, Graphics, Messages,
  OtherGlobalVars;
  
type
  PRGB32 = ^TRGB32;
  TRGB32 = packed record
    B,G,R,A:Byte;
  end;

  TBrandBorder = class(TObject)
  private
    Holder:TWinControl;
    FForm:TForm;
    bmpOrg,bmpAct,bmpInact:TBitmap;
    Split:TRect;
    CapH:LongInt;

    procedure GroupChilds;
    procedure LoadImage(BMP:TBitmap);
    procedure Colorize(out BMP:TBitmap;C:TColor);

    procedure OnFormPaint(Sender:TObject);
  public
    Active:Boolean;
    Caption:String;

    constructor Create(AForm:TForm);
    destructor Destroy; override;

    procedure NCHitTest(var Msg:TMessage);

    procedure SetImage(BMP:TBitmap;ASplit:TRect;H:LongInt);
    procedure SetDefaultImage;
    procedure SetColors(clA,clI:TColor);
    procedure SetBorder(Flag:Boolean);
    procedure DrawBorderImages(out bmpA,bmpI:TBitmap);
  end;

implementation

uses
  MainUnit;

procedure TBrandBorder.Colorize(out BMP: TBitmap; C: TColor);
var
  x,y,l,R,G,B:LongInt;
  p:PRGB32;
  AC:array [0..255] of TRGB32;
begin
  BMP.PixelFormat := pf32bit;

  R := GetRValue(C);
  G := GetGValue(C);
  B := GetBValue(C);

  for l:=0 to 255 do begin
    AC[l].R := R * l div 255;
    AC[l].G := G * l div 255;
    AC[l].B := B * l div 255;
    AC[l].A := 0;
  end;

  // Разукрашиваем бордюр.
  for y:=0 to BMP.Height-1 do
  begin
    p := BMP.ScanLine[y];
    for x:=0 to BMP.Width-1 do begin
      p^ := AC[(p.R + p.G + p.B) div 3];
      Inc(p);
    end;
  end;
end;

constructor TBrandBorder.Create;
begin
  inherited Create;
  FForm:=AForm;
  GroupChilds;

  bmpAct:=TBitmap.Create;
  bmpAct.PixelFormat:=pf32bit;
  bmpInact:=TBitmap.Create;
  bmpInact.PixelFormat:=pf32bit;
  bmpOrg:=TBitmap.Create;
  bmpOrg.PixelFormat:=pf32bit;

  SetDefaultImage;
  FForm.OnPaint:=OnFormPaint;
  Active:=TRUE;
end;

destructor TBrandBorder.Destroy;
begin
  FForm.OnPaint:=NIL;
  bmpAct.Free;
  bmpInact.Free;
  bmpOrg.Free;
  inherited Destroy;
end;

procedure TBrandBorder.DrawBorderImages;
begin
  bmpA.Width:=bmpAct.Width-10;
  bmpA.Height:=25-5;
  // Красим "внутренную" часть верхнего бордюра - заголовок.
  bmpA.Canvas.Draw(-5,-5,bmpAct);

  bmpI.Width:=bmpA.Width;
  bmpI.Height:=bmpA.Height;
  bmpI.Canvas.Draw(-5,-5,bmpInact); // -5, -5
end;

procedure TBrandBorder.GroupChilds;
var
  P:TPanel;
  l:LongInt;
  C:TControl;
begin
  P:=TPanel.Create(FForm);
  P.BevelOuter:=bvNone;

  for l:=0 to FForm.ComponentCount-1 do begin
    if (FForm.Components[l] is TControl) then begin
      C:=FForm.Components[l] as TControl;
      if (C.Parent=FForm) then
        C.Parent:=P;
    end;
  end;

  P.Parent:=FForm;
  P.Anchors:=[akLeft,akTop,akRight,akBottom];
  P.SetBounds({5}5,{5}5,FForm.Width-{10}10,FForm.Height-{10}10);
  P.DoubleBuffered:=TRUE;

  FForm.Color:=$996633;
  P.Color:=$000000;

  Holder:=P;
end;

procedure TBrandBorder.LoadImage;
begin
  bmpOrg.Width:=BMP.Width;
  bmpOrg.Height:=BMP.Height;
  bmpOrg.Canvas.Draw(0,0,BMP);

  bmpAct.Assign(bmpOrg);
  bmpInact.Assign(bmpOrg);
end;

procedure TBrandBorder.NCHitTest;
var
  X,Y:LongInt;
  IsR,IsL,IsT,IsB:Boolean;
begin
  X:=Msg.LParamLo-FForm.Left;
  Y:=Msg.LParamHi-FForm.Top;

  IsL:=(X<5); // 5
  IsT:=(Y<5); // 5
  IsB:=(Y>(FForm.Height-6)); // 6
  IsR:=(X>(FForm.Width-6)); // 6

  Msg.Result:=HTCLIENT;
  if IsL then Msg.Result:=HTLEFT;
  if IsT then Msg.Result:=HTTOP;
  if IsR then Msg.Result:=HTRIGHT;
  if IsB then Msg.Result:=HTBOTTOM;

  if (Msg.Result<>HTCLIENT) then begin
    IsL:=(X<15); // 15
    IsT:=(Y<15); // 15
    IsB:=(Y>(FForm.Height-16)); // 16
    IsR:=(X>(FForm.Width-16));  // 16

    if (IsL and IsT) then Msg.Result:=HTTOPLEFT;
    if (IsR and IsT) then Msg.Result:=HTTOPRIGHT;
    if (IsL and IsB) then Msg.Result:=HTBOTTOMLEFT;
    if (IsR and IsB) then Msg.Result:=HTBOTTOMRIGHT;
  end;
end;

procedure TBrandBorder.OnFormPaint(Sender: TObject);
var
  SR,DR:TRect;
  SP,DP:array [0..4] of TPoint;
  x,y:LongInt;
//  S:String;
//  MaxWidth:LongInt;
begin
  if (Holder.Left=0) then Exit;

  SP[0]:=Point(0,0); // 0,0
  SP[1]:=Point(5,5); // 5,5
  SP[2]:=Point(5,24); // 5,24
  SP[3]:=Point(bmpAct.Width-5,bmpAct.Height-5); // -5, -5
  SP[4]:=Point(bmpAct.Width,bmpAct.Height);

  DP[0]:=Point(0,0); // 0,0
  DP[1]:=Point(5,5); // 5,5
  DP[2]:=Point(5,24); // 5,24
  DP[3]:=Point(FForm.Width-5,FForm.Height-5); // -5, -5
  DP[4]:=Point(FForm.Width,FForm.Height);

  with FForm.Canvas do begin
    for y:=0 to 3 do // 0..3
      for x:=0 to 3 do // 0..3
        if ((x=0) or (y=0) or (x=3) or (y=3)) then begin // 0 = 0; 3 = 3
          SR:=Rect(SP[x].X,SP[y].y,SP[x+1].x,SP[y+1].y);
          DR:=Rect(DP[x].X,DP[y].y,DP[x+1].x,DP[y+1].y);

          if Active then
            CopyRect(DR,bmpAct.Canvas,SR)
          else
            CopyRect(DR,bmpInAct.Canvas,SR)
        end;

{
    Font.Style:=[fsBold];
    S:=Caption;
    MaxWidth:=FForm.Width-((2+17*2)+(17*3+2))-10;
    if (TextWidth(s)>MaxWidth) then begin
      while (Length(s)>0) and (TextWidth(s+'...')>MaxWidth) do
        s:=Copy(s,1,Length(s)-1);
      if (Length(s)>0) then
        s:=s+'...';
    end;

    Brush.Style:=bsClear;
    Font.Color:=frMain.imSkin.Canvas.Pixels[770,103];
    TextOut(5+2+17+17+1,3+3+1,s);
    Font.Color:=frMain.imSkin.Canvas.Pixels[771,104];
    if Active then
      Font.Color:=frMain.imSkin.Canvas.Pixels[762,104];
    TextOut(5+2+17+17,3+3,s);}
  end;

  /////////////////// Новый вид скинов (PK-69)
  if (bmpAct.Height = 52) and (bmpAct.Width = 29) then
    if frMain.pnControl.Visible = ThemeActive then
    // С панелями
    for y := 3 to 23 do
    begin
      bmpAct.Canvas.Pixels[3,y]:= bmpAct.Canvas.Pixels[4,y];
      bmpAct.Canvas.Pixels[bmpAct.Width-4,y]:=bmpAct.Canvas.Pixels[bmpAct.Width-5,y];

      bmpInAct.Canvas.Pixels[3,y]:= bmpInAct.Canvas.Pixels[4,y];
      bmpInAct.Canvas.Pixels[bmpInAct.Width-4,y]:=bmpInAct.Canvas.Pixels[bmpInAct.Width-5,y];
    end
    else
    // Без панелей
    for y := 3 to 23 do
    begin
      bmpAct.Canvas.Pixels[3,y]:= clBlack;
      bmpAct.Canvas.Pixels[bmpAct.Width-4,y]:=clBlack;

      bmpInAct.Canvas.Pixels[3,y]:= clBlack;
      bmpInAct.Canvas.Pixels[bmpInAct.Width-4,y]:=clBlack;
    end;

  /////////////////// Старый вид скинов (XP.Blue)
  if (bmpAct.Height = 53) and (bmpAct.Width = 24) then
    if frMain.pnControl.Enabled = ThemeActive then
    // С панелями
    begin
      for y := 5 to 23 do
      begin
        bmpAct.Canvas.Pixels[4,y]:= bmpAct.Canvas.Pixels[5,y];
        bmpAct.Canvas.Pixels[bmpAct.Width-5,y]:= bmpAct.Canvas.Pixels[bmpAct.Width-6,y];

        bmpInAct.Canvas.Pixels[4,y]:= bmpInAct.Canvas.Pixels[5,y];
        bmpInAct.Canvas.Pixels[bmpInAct.Width-5,y]:= bmpInAct.Canvas.Pixels[bmpInAct.Width-6,y];
      end;

      for x := 4 to bmpAct.Width-5 do
      begin
        bmpAct.Canvas.Pixels[x,4]:= bmpAct.Canvas.Pixels[x,3];
        bmpInAct.Canvas.Pixels[x,4]:= bmpInAct.Canvas.Pixels[x,3];
      end;

      for x := 1 to bmpAct.Width-2 do
      begin
        bmpAct.Canvas.Pixels[x,1]:= bmpAct.Canvas.Pixels[x,4];
        bmpAct.Canvas.Pixels[x,2]:= bmpAct.Canvas.Pixels[x,4];

        bmpInAct.Canvas.Pixels[x,1]:= bmpInAct.Canvas.Pixels[x,4];
        bmpInAct.Canvas.Pixels[x,2]:= bmpInAct.Canvas.Pixels[x,4];
      end;
    end
    else
    begin
    // Без панелей
      for y := 5 to 23 do
      begin
        bmpAct.Canvas.Pixels[4,y]:= bmpAct.Canvas.Pixels[4,y+20];
        bmpAct.Canvas.Pixels[bmpAct.Width-5,y]:= bmpAct.Canvas.Pixels[bmpAct.Width-5,y+20];

        bmpInAct.Canvas.Pixels[4,y]:= bmpInAct.Canvas.Pixels[4,y+20];
        bmpInAct.Canvas.Pixels[bmpInAct.Width-5,y]:= bmpInAct.Canvas.Pixels[bmpInAct.Width-5,y+20];
      end;

      for x := 4 to bmpAct.Width-5 do
      begin
        bmpAct.Canvas.Pixels[x,4]:= bmpAct.Canvas.Pixels[4,21];
        bmpInAct.Canvas.Pixels[x,4]:= bmpInAct.Canvas.Pixels[4,21];
      end;

      for x := 1 to bmpAct.Width-2 do
      begin
        bmpAct.Canvas.Pixels[x,1]:= bmpAct.Canvas.Pixels[x,bmpAct.Height-2];
        bmpAct.Canvas.Pixels[x,2]:= bmpAct.Canvas.Pixels[x,bmpAct.Height-3];

        bmpInAct.Canvas.Pixels[x,1]:= bmpInAct.Canvas.Pixels[x,bmpInAct.Height-2];
        bmpInAct.Canvas.Pixels[x,2]:= bmpInAct.Canvas.Pixels[x,bmpInAct.Height-3];
      end;

    end;
end;

procedure TBrandBorder.SetBorder;
begin
  if Flag then begin
    Holder.SetBounds(Split.Left,Split.Top,
      FForm.Width-(Split.Left+Split.Right),
      FForm.Height-(Split.Top+Split.Bottom));
  end else begin
    Holder.SetBounds(0,0,FForm.Width,FForm.Height);
  end;
end;

procedure TBrandBorder.SetColors;
begin
  bmpAct.Assign(bmpOrg);
  Colorize(bmpAct,clA);
  FForm.Color:=clA;

  bmpInact.Assign(bmpOrg);
  Colorize(bmpInact,clI);
end;

procedure TBrandBorder.SetDefaultImage;
var
  BMP:TBitmap;
begin
  BMP:=TBitmap.Create;
  BMP.LoadFromResourceName(hInstance,'MainBrd');
  LoadImage(BMP);
  BMP.Free;

  Split:=Rect(5,5,5,5);// 5,5,5,5
  CapH:=19; //19
end;

procedure TBrandBorder.SetImage;
begin
  LoadImage(BMP);
  Split:=ASplit;
  CapH:=H;

  Holder.SetBounds(Split.Left,Split.Top,
    FForm.Width-(Split.Left+Split.Right),
    FForm.Height-(Split.Top+Split.Bottom));
end;

end.
