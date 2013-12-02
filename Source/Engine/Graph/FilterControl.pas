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
unit FilterControl;

interface

uses
  Windows, Classes, Controls, Graphics, DirectShow9;

type
  TFilterControl = class(TCustomControl)
  private
    FFilter:IBaseFilter;

    procedure Clear;
  protected
    procedure Paint; override;
    procedure PaintBG;
    procedure PaintPins;

    procedure Click; override;
  public
    Title:String;
    ConnectedFilters:array of IBaseFilter;
    OnFocus:TNotifyEvent;

    constructor Create(AOwner:TComponent); override;
    destructor Destroy; override;

    procedure AttachToFilter(AFilter:IBaseFilter);

    function InputPinsCount:LongInt;
    function OutputPinsCount:LongInt;
    procedure EnumConnectedFilters;
    procedure ClearConnectedFiltersList;

    property BaseFilter:IBaseFilter read FFilter;
    property OnDblClick; 
  end;

implementation

uses
  LACore;

procedure TFilterControl.AttachToFilter;
begin
  FFilter:=AFilter;

  Title:=Core.DSH.GetFilterName(AFilter);
end;

procedure TFilterControl.Clear;
begin
  FFilter:=NIL;
end;

procedure TFilterControl.ClearConnectedFiltersList;
var
  l:LongInt;
begin
  for l:=0 to Length(ConnectedFilters)-1 do
    ConnectedFilters[l]:=NIL;
  SetLength(ConnectedFilters,0);
end;

procedure TFilterControl.Click;
begin
  inherited Click;
  SetFocus;
  if Assigned(OnFocus) then OnFocus(Self);
end;

constructor TFilterControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width:=180;
  Height:=40;

//  DoubleBuffered:=TRUE;
end;

destructor TFilterControl.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TFilterControl.EnumConnectedFilters;
var
  Pins:IEnumPins;
  Pin,CPin:IPin;
  Fetched:cardinal;
  PDir:TPINDIRECTION;
  PInfo:TPININFO;
  Len:LongInt;
begin
  FFilter.EnumPins(Pins);
  Pins.Reset;
  while (Pins.Next(1,Pin,@Fetched)=S_OK) do begin
    Pin.QueryDirection(PDir);
    if (PDir=PINDIR_OUTPUT) then begin
      if SUCCEEDED(Pin.ConnectedTo(CPin)) then begin
        CPin.QueryPinInfo(PInfo);
        if (Assigned(PInfo.pFilter)) then begin
          Len:=Length(ConnectedFilters);
          SetLength(ConnectedFilters,Len+1);
          ConnectedFilters[Len]:=PInfo.pFilter;
        end;
        PInfo.pFilter:=NIL;
        CPin:=NIL;
      end;
    end;
    Pin:=NIL;
  end;
  Pins:=NIL;
end;

function TFilterControl.InputPinsCount: LongInt;
var
  Pins:IEnumPins;
  Pin:IPin;
  Fetched:cardinal;
  PDir:TPINDIRECTION;
begin
  Result:=0;

  FFilter.EnumPins(Pins);
  Pins.Reset;
  while (Pins.Next(1,Pin,@Fetched)=S_OK) do begin
    Pin.QueryDirection(PDir);
    if (PDir=PINDIR_INPUT) then Inc(Result);
    Pin:=NIL;
  end;
  Pins:=NIL;
end;

function TFilterControl.OutputPinsCount: LongInt;
var
  Pins:IEnumPins;
  Pin:IPin;
  Fetched:cardinal;
  PDir:TPINDIRECTION;
begin
  Result:=0;

  FFilter.EnumPins(Pins);
  Pins.Reset;
  while (Pins.Next(1,Pin,@Fetched)=S_OK) do begin
    Pin.QueryDirection(PDir);
    if (PDir=PINDIR_OUTPUT) then Inc(Result);
    Pin:=NIL;
  end;
  Pins:=NIL;
end;

procedure TFilterControl.Paint;
begin
  PaintBG;
  PaintPins;
end;

procedure TFilterControl.PaintBG;
var
  x,y,IC,OC:LongInt;
begin
  with Canvas do begin
    IC:=InputPinsCount;
    OC:=OutputPinsCount;

    Brush.Color:=$DDDDDD;
    if ((IC=0) and (OC>0)) then Brush.Color:=$B1E6B1; // Source
    if ((IC=1) and (OC=1)) then Brush.Color:=$F0F0A2; // Processor
    if ((IC>0) and (OC=0)) then Brush.Color:=$B8B8FF; // Renderer
    if ((IC=1) and (OC>1)) then Brush.Color:=$ADECEC; // Splitter
    if ((IC>1) and (OC=1)) then Brush.Color:=$F9B8E1; // Joiner

    FillRect(Rect(0,0,Width,Height));

    Brush.Style:=bsClear;

    if Focused then begin
      Pen.Color:=clWhite;
      Rectangle(0,0,Width,Height);
      Rectangle(1,1,Width-1,Height-1);
    end
    else begin
      Pen.Color:=$787878;
      Rectangle(0,0,Width,Height);
    end;

    Font.Name:='Tahoma';
    Font.Size:=8;
    Font.Color:=clBlack;

    x:=(Width-TextWidth(Title)) div 2;
    y:=(Height-TextHeight(Title)) div 2;

    TextOut(x,y,Title);
  end;
end;

procedure TFilterControl.PaintPins;
var
  Cnt,l,dx,x:LongInt;
begin
  with Canvas do begin
    Pen.Color:=$8E8E8E;

    Cnt:=InputPinsCount;
    dx:=Width div (1+Cnt);
    for l:=0 to Cnt-1 do begin
      x:=dx*(l+1);
      Brush.Color:=clBlue;
      Brush.Style:=bsSolid;
      Ellipse(x-5,-5,x+5,5);
    end;

    Cnt:=OutputPinsCount;
    dx:=Width div (1+Cnt);
    for l:=0 to Cnt-1 do begin
      x:=dx*(l+1);
      Brush.Color:=clRed;
      Brush.Style:=bsSolid;
      Ellipse(x-5,Height-5,x+5,Height+5);
    end;
  end;
end;

end.
