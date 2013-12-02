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
unit Info;

interface

uses
  Windows, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, Grids, Menus;

type
  TfrInfo = class(TForm)
    btOk: TButton;
    sgInfo: TStringGrid;
    sgPopupMenu: TPopupMenu;
    N1: TMenuItem;
    procedure btOkClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure N1Click(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure sgInfoDrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure sgInfoMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    { Private declarations }
  public
    procedure AddRow(Title,Value:string);
    procedure ProcessInfo(aInfo:string);
    { Public declarations }
  end;

var
  frInfo:TfrInfo;
  NeedRepaint: Boolean;  

implementation

{$R *.DFM}

uses
  LACore, Clipbrd;

procedure TfrInfo.btOkClick(Sender: TObject);
begin
  Close;
end;

procedure TfrInfo.AddRow;
begin
  sgInfo.Cells[0,sgInfo.RowCount-1]:=Title;
  sgInfo.Cells[1,sgInfo.RowCount-1]:=Value;
  sgInfo.RowCount:=sgInfo.RowCount+1;
end;

procedure TfrInfo.ProcessInfo;
var
  Info:string;
  function CutLine:string;
  var
    l:longint;
  begin
    l:=Pos(#13#10,Info);
    if (l=0) then begin
      Result:=Info;
      Info:='';
    end else begin
      Result:=Copy(Info,1,l-1);
      Info:=Copy(Info,l+2,Length(Info)-(l+1));
    end;
  end;

  procedure SplitLine(Line:string);
  var
    l:longint;
  begin
    l:=Pos(':',Line);
    if (l=0) then
      AddRow(Line,'')
    else
      AddRow(Copy(Line,1,l-1),Trim(Copy(Line,l+1,Length(Line)-l)));
  end;
begin
  sgInfo.RowCount:=1;

  Info:=aInfo;
  while (Info<>'') do
    SplitLine(CutLine);
  sgInfo.RowCount:=sgInfo.RowCount-1;
end;

procedure TfrInfo.FormCreate(Sender: TObject);
begin
  Caption:=MS('Info.Caption');
  sgInfo.ColWidths[0]:=(sgInfo.Width div 3);
  sgInfo.ColWidths[1]:=sgInfo.Width-sgInfo.ColWidths[0];
  sgInfo.DefaultRowHeight:=Abs(sgInfo.Font.Height)+5;
  NeedRepaint:=TRUE;
end;

procedure TfrInfo.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key=VK_ESCAPE) then Close;
end;

procedure TfrInfo.N1Click(Sender: TObject);
var
  i,j,cl,rt,cr,rb: integer;
  s: String;
  CopySel: Boolean;

  procedure BufferToClipboard(Buffer: WideString);
  var WideBuffer: WideString;
    BuffSize: Cardinal;
    Data: THandle;
    DataPtr: Pointer;
  begin
    if Buffer <> '' then begin
      WideBuffer := Buffer;
      BuffSize := length(Buffer) * SizeOf(WideChar);
      Data := GlobalAlloc(GMEM_MOVEABLE+GMEM_DDESHARE+GMEM_ZEROINIT, BuffSize + 2);
      try
        DataPtr := GlobalLock(Data);
        try
          Move(PWideChar(WideBuffer)^, Pointer(Cardinal(DataPtr))^, BuffSize);
        finally
          GlobalUnlock(Data);
        end;
        Clipboard.SetAsHandle(CF_UNICODETEXT, Data);
      except
        GlobalFree(Data);
        raise;
      end;
    end;
  end;
begin
  CopySel:=true;
  CL:=-1;
  RT:=-1;
  CR:=-1;
  RB:=-1;
  s:='';
  with sgInfo do
  begin
    if CopySel then
    begin
      CL:=Selection.Left;
      CR:=Selection.Right;
      RT:=Selection.Top;
      RB:=Selection.Bottom;
    end;
    if (CL<FixedCols) or (CL>CR) or (CL>=ColCount) then CL:=FixedCols;
    if (CR<FixedCols) or (CL>CR) or (CR>=ColCount) then CR:=ColCount-1;
    if (RT<FixedRows) or (RT>RB) or (RT>=RowCount) then RT:=FixedRows;
    if (RB<FixedCols) or (RT>RB) or (RB>=RowCount) then RB:=RowCount-1;
    for i:=RT to RB do
    begin
      for j:=CL to CR do
      begin
        s:=s+Cells[j,i];
        if j<CR then s:=s+#9;
      end;
     s:=s+#13#10;
    end;
  end;
  BufferToClipboard(s);
end;

procedure TfrInfo.FormResize(Sender: TObject);
begin
  sgInfo.ColWidths[1]:=frInfo.Width-146;
  btOk.Left:=(frInfo.Width div 2)-(btOk.Width div 2);
end;

procedure TfrInfo.sgInfoDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
begin
  if (gdSelected in state) then Exit;

  with sgInfo.Canvas do begin
    if (ACol=1) then
      Brush.Color:=clWhite
    else
      Brush.Color:=$DFDFDF;
    Dec(Rect.Right);
    Dec(Rect.Bottom);

    FillRect(Rect);
    TextOut(Rect.Left+2,Rect.Top,sgInfo.Cells[ACol,ARow]);
  end;
end;

procedure TfrInfo.sgInfoMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbRight then
    mouse_event(MOUSEEVENTF_LEFTDOWN Or MOUSEEVENTF_LEFTUP, 0, 0, 0, 0);
end;

end.
