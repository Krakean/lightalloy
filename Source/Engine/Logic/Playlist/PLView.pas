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
unit PLView;

interface

uses
  Windows, Classes, SysUtils, ComCtrls, Graphics, Controls, Forms;

type
  TPlayListView = class(TListView)
  private
    FindKey:String;

    procedure OnPlayListChange;
    procedure OnViewData(Sender:TObject;Item:TListItem);
    procedure SwapSelection(l1,l2:LongInt);
  protected
    procedure Resize; override;
    procedure DblClick; override;
  public
    constructor Create(AOwner:TComponent); override;
    destructor Destroy; override;

    procedure InvertSelection;
    procedure SelectionUp;
    procedure SelectionDown;
    procedure RemoveSelected;
    procedure GetCurrentSelectedItem;

    procedure FindFirst(Key:String);
    procedure FindNext;
    function GetNextSelected:Integer;

    procedure Invalidate; override;
  end;

implementation

uses
  LACore, PlayList, SysHlp;

constructor TPlayListView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  ViewStyle:=vsReport;
  BorderStyle:=bsNone;
  RowSelect:=TRUE;
  HideSelection:=FALSE;

  with Columns.Add do begin
    Caption:='No';
  end;
  with Columns.Add do begin
    Caption:='Title';
  end;
  with Columns.Add do begin
    Caption:='Time';
  end;

  OwnerData:=TRUE;
  OnData:=OnViewData;

  MultiSelect:=TRUE;
  ColumnClick:=FALSE;
  ReadOnly:=TRUE;
  GridLines:=TRUE;

  DoubleBuffered:=TRUE;
  Resize;

  Core.MdlMgr.AttachWithState('PlayList',OnPlayListChange);
end;

procedure TPlayListView.DblClick;
begin
  inherited DblClick;
  Core.PlayList.PlayEntry(ItemFocused.Index,-1);
end;

destructor TPlayListView.Destroy;
begin
  Core.MdlMgr.DetachWithState('PlayList',OnPlayListChange);
  inherited Destroy;
end;

procedure TPlayListView.FindFirst(Key: String);
begin
  ClearSelection;
  
  FindKey:=ANSIUpperCase(Key);
  FindNext;

  Invalidate;
end;

procedure TPlayListView.FindNext;
var
  l:LongInt;
  S:String;
  PE:TPlayEntry;
begin
  ClearSelection;

  for l:=0 to Core.PlayList.Entries.Count-1 do begin
    PE:=Core.PlayList.Entries[l];
    S:=ANSIUpperCase(PE.Title);
    if (Pos(FindKey,S)>0) then begin
      Items[l].Selected:=TRUE;
    end;
  end;

  Invalidate;
end;

function TPlayListView.GetNextSelected;
var
  N: Integer;
begin
  Result:=-1;
  for n:=0 to Core.PlayList.Entries.Count-1 do begin
    if Items[n].Selected then begin
      Items[n].Selected := false;
      Result:=n;
      break;
    end;
  end;
end;

procedure TPlayListView.Invalidate;
begin
  if (Items.Count<>Core.PlayList.Entries.Count) then
    Items.Count:=Core.PlayList.Entries.Count;
  inherited Invalidate;
end;

procedure TPlayListView.InvertSelection;
var
  l:LongInt;
begin
  for l:=0 to Items.Count-1 do
    Items[l].Selected:=not(Items[l].Selected);
end;

procedure TPlayListView.OnPlayListChange;
begin
  Invalidate;
end;

procedure TPlayListView.OnViewData;
var
  PE:TPlayEntry;
  S:String;
begin
  if (Item.Index>(Core.PlayList.Entries.Count-1)) then Exit;
  PE:=Core.PlayList.Entries[Item.Index];

  S:='';
  if (Item.Index=Core.PlayList.PlayPos) then S:='>';

  Item.Caption:=Format('%.3d.'+S,[Item.Index+1]);
  Item.SubItems.Add(PE.Title);

  S:=' --:--';
  if (PE.Duration>=0) then begin
    S:=' '+Core.SysHlp.FormatHNS('{H}:{M}:{S}',PE.Duration);
    if (PE.Duration<60*60*HNS) then
      S:=' '+Core.SysHlp.FormatHNS('{M}:{S}',PE.Duration);
    if (PE.Duration<10*60*HNS) then
      S:=' '+Core.SysHlp.FormatHNS('{m}:{S}',PE.Duration);
  end;
  Item.SubItems.Add(S);
end;

procedure TPlayListView.RemoveSelected;
var
  l,Idx:LongInt;
begin
  Idx:=0;
  Core.PlayList.UpdateBegin;
  for l:=0 to Items.Count-1 do begin
    if Items[l].Selected then begin
      Core.PlayList.DeleteEntry(Idx);
    end else begin
      Inc(Idx);
    end;
  end;
  Core.PlayList.UpdateEnd;
  ClearSelection;
  Invalidate;
end;

procedure TPlayListView.Resize;
begin
  inherited Resize;
  Columns[0].Width:=40;
  Columns[2].Width:=50;
  Columns[1].Width:=Width-Columns[0].Width-Columns[2].Width-18;
end;

procedure TPlayListView.SelectionDown;
var
  l:LongInt;
begin
  if (Items[Items.Count-1].Selected) then Exit;

  for l:=Items.Count-1 downto 1 do begin
    if (Items[l-1].Selected) then begin
      Core.PlayList.SwapEntries(l,l-1);
      SwapSelection(l,l-1);
    end;
  end;
  Invalidate;
end;

procedure TPlayListView.SelectionUp;
var
  l:LongInt;
begin
  if (Items[0].Selected) then Exit;

  for l:=0 to Items.Count-2 do begin
    if (Items[l+1].Selected) then begin
      Core.PlayList.SwapEntries(l,l+1);
      SwapSelection(l,l+1);
    end;
  end;
  Invalidate;
end;

procedure TPLayListView.GetCurrentSelectedItem;
begin
end;

procedure TPlayListView.SwapSelection(l1, l2: Integer);
var
  B:Boolean;
begin
  B:=Items[l1].Selected;
  Items[l1].Selected:=Items[l2].Selected;
  Items[l2].Selected:=B;
end;

end.
