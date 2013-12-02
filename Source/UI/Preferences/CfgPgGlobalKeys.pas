unit CfgPgGlobalKeys;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  ConfigPage, StdCtrls, Grids, XML, XMLPrefs, MMkeys;

type
  TCPGlobalKeys = class(TConfigPageForm)
    cbMMKeys: TCheckBox;
    cbEnabled: TCheckBox;
    sgCommands: TStringGrid;
    btnClear: TButton;
    cbAlternative: TCheckBox;
    procedure sgCommandsDrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure OnClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure cbMMKeysClick(Sender: TObject);
  private
    procedure FillKeys;
  public
    procedure OnAppCommand(var Msg:TMessage); message WM_APPCOMMAND;

    procedure WriteKeyData(Key:Word;Shift:TShiftState); override;
    procedure ReadPrefs; override;
    procedure UpdateLang; override;
    procedure ApplyChanges; override;
  end;

implementation

{$R *.dfm}

uses
  LACore, CmdC;

procedure TCPGlobalKeys.FillKeys;
var
  l: LongInt;
  XN, XNP: TXMLNode;
begin
  XNP := Core.XTree.Root.Node('GlobalKeys');
  sgCommands.RowCount:=Length(XNP.Nodes)+1;
  for l:=0 to Length(XNP.Nodes)-1 do
  begin
    XN := XNP.Nodes[l];
    if SameText(XN.Tag, 'Keys') then
      with sgCommands.Rows[l+1] do begin
        Strings[1] := XN.Attr('Key');
        Strings[2] := XN.Attr('MMKey');
      end;
  end;
end;

procedure TCPGlobalKeys.ApplyChanges;
var
  l: integer;
  XN, XNP: TXMLNode;
begin
  XNP := Core.XTree.Root.Node('GlobalKeys');
  for l:=0 to Length(XNP.Nodes)-1 do
  begin
    XN := XNP.Nodes[l];
    if SameText(XN.Tag, 'Keys') then
      with sgCommands.Rows[l+1] do begin
        XN.SetAttr('Key', Strings[1]);
        XN.SetAttr('MMKey', Strings[2]);
      end;
  end;

  // Этот иф нужен чтобы не приходилось перезагружать программу
  // когда меняется клавиша у какой-то глоб кнопки.
  // Всё просто: значение cbEnabled не изменилось,
  //             а посему переинициализировать
  //             GlobalKeys движок не видит нужным,
  //             потому то мы в этом ифе и отключаем
  //             глоб кнопки, т.к. следующая строка
  //             их включит обратно и будет *переинициализация*. (VtX)
  if cbEnabled.Checked then
    Core.ModMgr.Enable('GlobalKeys', False);  
  Core.ModMgr.Enable('GlobalKeys',cbEnabled.Checked);
  Core.Prefs.Bool['Modules.GlobalKeys.MMKeys']:=cbMMkeys.Checked;
  Core.Prefs.Bool['Modules.GlobalKeys.AltMode']:=cbAlternative.Checked;  
end;

procedure TCPGlobalKeys.ReadPrefs;
begin
  cbEnabled.Checked:=Core.ModMgr.IsLoaded('GlobalKeys');
  cbMMkeys.Checked:=Core.Prefs.Bool['Modules.GlobalKeys.MMKeys'];
  cbAlternative.Checked:=Core.Prefs.Bool['Modules.GlobalKeys.AltMode'];

  if cbEnabled.Checked then
    sgCommands.Enabled := True
  else
    sgCommands.Enabled := False;

  FillKeys;
end;

procedure TCPGlobalKeys.UpdateLang;
var
  l: LongInt;
  XN, XNP: TXMLNode;
begin
  cbEnabled.Caption:=MS('Config.GlobalKeys.Enabled');
  cbMMKeys.Caption:=MS('Config.GlobalKeys.MMKeys');
  cbAlternative.Caption:=MS('Config.GlobalKeys.AltMMKeys');  
  btnClear.Caption:=MS('Config.Keyboard.Clear');

  sgCommands.Cells[0,0]:=MS('Config.GlobalKeys.Description'); //Description
  sgCommands.Cells[1,0]:=MS('Config.GlobalKeys.Keys'); //Keys
  sgCommands.Cells[2,0]:=MS('Config.GlobalKeys.MediaKeys'); //MediaKeys

  XNP := Core.XTree.Root.Node('GlobalKeys');
  for l:=0 to Length(XNP.Nodes)-1 do
  begin
    XN := XNP.Nodes[l];
    if SameText(XN.Tag, 'Keys') then
      with sgCommands.Rows[l+1] do
        Strings[0] := Center.GetCommandName(Center.ExtractCmdNum(XN.Attr('Command')));
  end;
end;

procedure TCPGlobalKeys.sgCommandsDrawCell(Sender: TObject; ACol,
  ARow: Integer; Rect: TRect; State: TGridDrawState);
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

procedure TCPGlobalKeys.OnClick(Sender: TObject);
begin
  if cbEnabled.Checked then
    sgCommands.Enabled := True
  else
    sgCommands.Enabled := False;
end;

procedure TCPGlobalKeys.WriteKeyData(Key:Word;Shift:TShiftState);
begin
  inherited;
  if sgCommands.Focused then
  begin
    if (sgCommands.Col=1) and (Copy(sgCommands.Rows[sgCommands.Row][0],1,1)<>'@') and (Key<>0) then
      sgCommands.Rows[sgCommands.Row][1] := Center.VirtualKeyName(Key,Shift);
    if (sgCommands.Col=2) and (Copy(sgCommands.Rows[sgCommands.Row][0],1,1)<>'@')
      and (Key in [$A6..$FE])
    then
      sgCommands.Rows[sgCommands.Row][2] := Center.VirtualKeyName(Key,Shift);
  end;
end;

procedure TCPGlobalKeys.btnClearClick(Sender: TObject);
begin
  inherited;
  sgCommands.Rows[sgCommands.Row][sgCommands.Col] := '';
end;

procedure TCPGlobalKeys.OnAppCommand(var Msg: TMessage);
var
  Cmd: LongInt;
  Shift: TShiftState;
begin
  Cmd:=HIWORD(Msg.lParam) and (FAPPCOMMAND_MASK xor $FFFFFFFF);
  if Cmd in [$01..$34] then begin
    Shift:= [];
    WriteKeyData(CMd+$A5,Shift);
  end;
end;

procedure TCPGlobalKeys.cbMMKeysClick(Sender: TObject);
begin
  inherited;
  if cbMMKeys.Checked then
    cbAlternative.Enabled := Sender = cbMMKeys
  else
  cbAlternative.Enabled := false;
end;

end.
