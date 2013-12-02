unit CfgPgKeyboard;

interface

uses
  Windows, Classes, Graphics, Controls, Forms,
  ConfigPage, Buttons, Grids, CmdC, Menus, StdCtrls;

type
  TCPKeyboard = class(TConfigPageForm)
    sgCommands: TStringGrid;
    sbClear: TSpeedButton;
    sbClearKeys: TSpeedButton;
    sbDefaultKeys: TSpeedButton;
    pmKeySet: TPopupMenu;
    WindowsMediaPlayer1: TMenuItem;
    BSPlayer1: TMenuItem;
    Sasami1: TMenuItem;
    ZoomPlayer1: TMenuItem;
    bbKeySet: TBitBtn;
    procedure sbClearKeysClick(Sender: TObject);
    procedure sbDefaultKeysClick(Sender: TObject);
    procedure sgCommandsDrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure sbClearClick(Sender: TObject);
    procedure sgCommandsKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure bbKeySetClick(Sender: TObject);
    procedure WindowsMediaPlayer1Click(Sender: TObject);
    procedure BSPlayer1Click(Sender: TObject);
    procedure Sasami1Click(Sender: TObject);
    procedure ZoomPlayer1Click(Sender: TObject);
  private
    procedure FillKeys;
    procedure ApplyKeys;

    function WIRCCB(Msg:String):Boolean;
  public
    procedure ReadPrefs; override;
    procedure UpdateLang; override;
    procedure ApplyChanges; override;
    procedure ESCMessage; override;
    procedure TABMessage; override;
  end;

implementation

{$R *.dfm}

uses
  LACore;

procedure TCPKeyboard.ApplyChanges;
begin
//  with Core.Prefs do begin
//    WriteBool('Commands.MultiKeys',cbMultiKeys.Checked);
//  end;
  ApplyKeys;
  Center.Save;
end;

procedure TCPKeyboard.ApplyKeys;
var
  CmdCat,Row,Cmd,LAC:longint;
begin
  Row:=2;
  for CmdCat:=0 to (LAC_CAT_NUMBER-1) do begin
    sgCommands.Rows[Row-1].Strings[0]:='@'+Center.GetCategoryName(CmdCat);
    Inc(Row);
    for Cmd:=0 to (LAC_CAT_SIZE[CmdCat]-1) do begin
      LAC:=(CmdCat+1)*50+Cmd;
      Center.SetKey(LAC,sgCommands.Rows[Row-1].Strings[1],sgCommands.Rows[Row-1].Strings[2]);
      Inc(Row);
    end;
  end;
end;

procedure TCPKeyboard.FillKeys;
var
  CmdCat,Row,Cmd,LAC:LongInt;
begin
  sgCommands.Cells[1,0]:=MS('Config.Keyboard');
  sgCommands.Cells[2,0]:='WinLIRC';

  sgCommands.ColWidths[0]:=180;//200;//180;
{  sgCommands.ColWidths[1]:=l*2; //  146
  sgCommands.ColWidths[2]:=l;   //  73
}
  sgCommands.ColWidths[1]:= 134;
  sgCommands.ColWidths[2]:= 85;

  Row:=1;
  for CmdCat:=0 to (LAC_CAT_NUMBER-1) do
    Inc(Row,1+LAC_CAT_SIZE[CmdCat]);
  sgCommands.RowCount:=Row;

  Row:=2;
  for CmdCat:=0 to (LAC_CAT_NUMBER-1) do begin
    sgCommands.Rows[Row-1].Strings[0]:='@'+Center.GetCategoryName(CmdCat);
    Inc(Row);
    for Cmd:=0 to (LAC_CAT_SIZE[CmdCat]-1) do
    begin
      LAC:=(CmdCat+1)*50+Cmd;
      sgCommands.Rows[Row-1].Strings[0]:=Center.GetCommandName(LAC);
      sgCommands.Rows[Row-1].Strings[1]:=Center.GetCommandKey(LAC);
      sgCommands.Rows[Row-1].Strings[2]:=Center.GetCommandWMsg(LAC);
      Inc(Row);
    end;
  end;
end;

procedure TCPKeyboard.ReadPrefs;
begin
  FillKeys;
//  with Core.Prefs do begin
//    cbMultiKeys.Checked:=ReadBool('Commands.MultiKeys');
//  end;
end;

procedure TCPKeyboard.UpdateLang;
begin
//  cbMultiKeys.Caption:=MS('Config.Keyboard.MultiSelect');
  sbClear.Caption:=MS('Config.Keyboard.Clear');
  sbClearKeys.Caption:=MS('Config.Keyboard.ClearAll');
  sbDefaultKeys.Caption:=MS('Config.Keyboard.Default');
  bbKeySet.Caption:=MS('Config.Keyboard.Custom');
end;

procedure TCPKeyboard.ESCMessage;
var S: TShiftState;
begin
  if (sgCommands.Col=1) and (Copy(sgCommands.Rows[sgCommands.Row][0],1,1)<>'@') then
    sgCommands.Rows[sgCommands.Row][1]:=Center.VirtualKeyName(VK_ESCAPE,S);
end;

procedure TCPKeyboard.TABMessage;
var S: TShiftState;
begin
  if (sgCommands.Col=1) and (Copy(sgCommands.Rows[sgCommands.Row][0],1,1)<>'@') then
    sgCommands.Rows[sgCommands.Row][1]:=Center.VirtualKeyName(VK_TAB,S);
end;

procedure TCPKeyboard.sbClearKeysClick(Sender: TObject);
begin
  Center.Clear;
  FillKeys;
end;

procedure TCPKeyboard.sbDefaultKeysClick(Sender: TObject);
begin
  Center.SetDefaultKeys;
  FillKeys;
end;

procedure TCPKeyboard.sgCommandsDrawCell;
var
  s:String;
begin
  if (Copy(sgCommands.Rows[ARow][0],1,1)='@') then
    with sgCommands.Canvas do begin
      if (ACol=0) then begin
        s:=sgCommands.Rows[ARow][0];
        Delete(s,1,1);
        Font.Style:=[fsBold];
        TextRect(Rect,Rect.Left+10,Rect.Top+2,'* '+s);
      end else begin
        Brush.Color:=clBtnFace;
        FillRect(Rect);
      end;
    end;
end;

procedure TCPKeyboard.sbClearClick(Sender: TObject);
begin
  sgCommands.Cells[sgCommands.Col,sgCommands.Row]:='';
end;

procedure TCPKeyboard.sgCommandsKeyDown;
begin
  if sgCommands.Focused then
  begin
    if (sgCommands.Col=1) and (Copy(sgCommands.Rows[sgCommands.Row][0],1,1)<>'@') then
      sgCommands.Rows[sgCommands.Row][1]:=Center.VirtualKeyName(Key,Shift);
    Key:=0;
  end
end;

procedure TCPKeyboard.FormCreate(Sender: TObject);
begin
  inherited FormCreate(Sender);
  sgCommands.DefaultRowHeight:=Abs(sgCommands.Font.Height)+5;

  Center.FWIRCCB:=WIRCCB;
end;

function TCPKeyboard.WIRCCB;
begin
  Result:=sgCommands.Focused;
  if not(Result) then Exit;

  with sgCommands do begin
    if (Col=2) and (Copy(Rows[Row][0],1,1)<>'@') then Rows[Row][2]:=Msg;
  end;
end;

procedure TCPKeyboard.FormDestroy(Sender: TObject);
begin
  Center.Load;
  Center.FWIRCCB:=NIL;
  inherited FormDestroy(Sender);
end;

procedure TCPKeyboard.bbKeySetClick(Sender: TObject);
var
  P:TPoint;
begin
  GetCursorPos(P);
  pmKeySet.Popup(P.X,P.Y);
end;

procedure TCPKeyboard.WindowsMediaPlayer1Click(Sender: TObject);
begin
  Center.SetWMPKeys;
  FillKeys;
end;

procedure TCPKeyboard.BSPlayer1Click(Sender: TObject);
begin
  Center.SetBSPlayerKeys;
  FillKeys;
end;

procedure TCPKeyboard.Sasami1Click(Sender: TObject);
begin
  Center.SetSasamiKeys;
  FillKeys;
end;

procedure TCPKeyboard.ZoomPlayer1Click(Sender: TObject);
begin
  Center.SetZoomKeys;
  FillKeys;
end;

end.
