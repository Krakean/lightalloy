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
unit FilterBox;

interface

uses
  Windows, Classes, Controls, Graphics,

  DirectShow9, FilterControl;

type
  TFilterBox = class(TCustomControl)
  private
    FGraph:IFilterGraph;
    FltCtls:array of TFilterControl;
    Selected:TFilterControl;

    procedure CreateFilters;
    procedure ArrangeFilters;
    procedure OnChangeFocus(Sender:TObject);
  protected
    procedure Paint; override;
  public
    OnSelectFilter:TNotifyEvent;
    OnFilterDblClick:TNotifyEvent;

    constructor Create(AOwner:TComponent); override;
    destructor Destroy; override;

    procedure Clear;
    procedure EnumGraph(Graph:IFilterGraph);
    function GetFocusedFilter:IBaseFilter;
  end;

implementation

uses
  LACore;

procedure TFilterBox.ArrangeFilters;
var
  Cnt,SrcIdx,l,FW,FH,k,j,x,y:LongInt;
  Flt:TFilterControl;
  Lvl:array of LongInt;
  HasConnect:Boolean;
  CurLvl:LongInt;
  S:String;
begin
  Cnt:=Length(FltCtls);
  if (Cnt=0) then Exit;

  FW:=FltCtls[0].Width; FH:=FltCtls[0].Height;

  for l:=0 to Cnt-1 do begin
    FltCtls[l].Left:=10;
    FltCtls[l].Top:=10+l*(FH+20);
  end;

  SrcIdx:=-1;
  for l:=0 to Cnt-1 do begin
    if (FltCtls[l].InputPinsCount=0) then
      SrcIdx:=l;
  end;

  if (SrcIdx<0) then Exit;

  SetLength(Lvl,Cnt);
  for l:=0 to Cnt-1 do Lvl[l]:=99;

  Lvl[SrcIdx]:=0;
  CurLvl:=0;
  repeat
    HasConnect:=FALSE;
    for l:=0 to Cnt-1 do begin
      if (Lvl[l]=CurLvl) then begin
        Flt:=FltCtls[l];
        Flt.EnumConnectedFilters;
        for k:=0 to Length(Flt.ConnectedFilters)-1 do begin
          S:=Core.DSH.GetFilterName(Flt.ConnectedFilters[k]);
          for j:=0 to Cnt-1 do begin
            if (S=FltCtls[j].Title) then begin
              Lvl[j]:=CurLvl+1;
              HasConnect:=TRUE;
            end;
          end;
        end;
        Flt.ClearConnectedFiltersList;
      end;
    end;
    Inc(CurLvl);
  until not(HasConnect);

  y:=10;
  for CurLvl:=0 to 19 do begin
    x:=10;
    for l:=0 to Cnt-1 do begin
      if (Lvl[l]=CurLvl) then begin
        Flt:=FltCtls[l];
        Flt.SetBounds(x,y,FW,FH);
        Inc(x,FW+10);
      end;
    end;
    if (CurLvl=0) then begin
      for l:=0 to Cnt-1 do begin
        if (Lvl[l]=99) then begin
          Flt:=FltCtls[l];
          Flt.SetBounds(x,y,FW,FH);
          Inc(x,FW+10);
        end;
      end;
    end;
    Inc(Y,FH+14);
  end;
end;

procedure TFilterBox.Clear;
var
  l:LongInt;
begin
  FGraph:=NIL;
  for l:=0 to Length(FltCtls)-1 do
    FltCtls[l].Free;
  SetLength(FltCtls,0);
end;

constructor TFilterBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Color:=clSilver;
//  DoubleBuffered:=TRUE;
end;

procedure TFilterBox.CreateFilters;
var
  FEnum:IEnumFilters;
  Filter:IBaseFilter;
  Fetched,Len:longint;
  FltCtl:TFilterControl;
begin
  Core.DSH.Graph.EnumFilters(FEnum);
  while (FEnum.Next(1,Filter,@Fetched)=S_OK) do begin
    FltCtl:=TFilterControl.Create(Self);
    with FltCtl do begin
      Parent:=Self;
      AttachToFilter(Filter);
      OnFocus:=OnChangeFocus;
      OnDblClick:=OnFilterDblClick;
    end;

    Len:=Length(FltCtls);
    SetLength(FltCtls,Len+1);
    FltCtls[Len]:=FltCtl;

    Filter:=NIL;
  end;
end;

destructor TFilterBox.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TFilterBox.EnumGraph(Graph: IFilterGraph);
begin
  Clear;

  FGraph:=Graph;

  CreateFilters;
  ArrangeFilters;
end;

function TFilterBox.GetFocusedFilter: IBaseFilter;
var
  l:LongInt;
begin
  Result:=NIL;
  if (FGraph=NIL) then Exit;

  for l:=0 to Length(FltCtls)-1 do
    if FltCtls[l].Focused then Result:=FltCtls[l].BaseFilter;

  if (Result=NIL) then
    Result:=Selected.BaseFilter;
end;

procedure TFilterBox.OnChangeFocus(Sender: TObject);
begin
  Selected:=Sender as TFilterControl;
  if Assigned(OnSelectFilter) then OnSelectFilter(Self);
  Invalidate;
end;

procedure TFilterBox.Paint;
var
  l,k,j,Cnt,dx:LongInt;
  SrcFlt,DstFlt:TFilterControl;
  S:String;
begin
  inherited Paint;

  with Canvas do begin
    Pen.Color:=$787878;
    Pen.Width:=2;
  end;

  for l:=0 to Length(FltCtls)-1 do begin
    SrcFlt:=FltCtls[l];
    SrcFlt.EnumConnectedFilters;
    Cnt:=Length(SrcFlt.ConnectedFilters);
    dx:=SrcFlt.Width div (Cnt+1);
    for k:=0 to Length(SrcFlt.ConnectedFilters)-1 do begin
      S:=Core.DSH.GetFilterName(SrcFlt.ConnectedFilters[k]);
      for j:=0 to Length(FltCtls)-1 do begin
        DstFlt:=FltCtls[j];
        if (S=DstFlt.Title) then begin
          Canvas.MoveTo(SrcFlt.Left+SrcFlt.Width-dx*(k+1),SrcFlt.Top+SrcFlt.Height);
          Canvas.LineTo(DstFlt.Left+(DstFlt.Width div 2),DstFlt.Top);
        end;
      end;
    end;
    SrcFlt.ClearConnectedFiltersList;
  end;
end;

end.
