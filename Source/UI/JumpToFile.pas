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
// 11.11.07  1.0   VtX  Created                                              //
///////////////////////////////////////////////////////////////////////////////
unit JumpToFile;

// -----------------------------------------------------------------------------

interface

uses
  Windows, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TfrJumpToFile = class(TForm)
    GroupBox1: TGroupBox;
    edtSearch: TEdit;
    lstFiles: TListBox;
    btnClose: TButton;
    btnJump: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnCloseOnClick(Sender: TObject);
    procedure TakeDat(Control: TWinControl; Index: Integer; var Data: String);
    procedure edtSearchChange(Sender: TObject);
    procedure JumpToOnClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure lstFilesOnDblClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure edtSearchKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure lstFilesOnKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure edtSearchKeyPress(Sender: TObject; var Key: Char);
  private
    FItemIndex: TStringList;
  public
  end;

var
  frJumpToFile: TfrJumpToFile;

implementation

{$R *.dfm}

uses
  LACore, PlayList;

var
  edtSearchFirstKeyBuffer: Word;
  RlstFiles, PlstDat: TStringList;

procedure TfrJumpToFile.FormCreate(Sender: TObject);
var
  i: Cardinal;
  Sep: ShortString;
  Member: TPlayEntry;
  E: TPlayEntry;
begin
  frJumpToFile.Caption := MS('Command.265');
  btnClose.Caption := MS('Common.Cancel');
  btnJump.Caption := MS('Command.101');

  edtSearchFirstKeyBuffer := 0;
  FItemIndex := TStringList.Create;
  RlstFiles := TStringList.Create;
  PlstDat := TStringList.Create;

  if Core.PlayList.Entries.Count > 0 then begin
    PlstDat.BeginUpdate;
    RlstFiles.BeginUpdate;
    FItemIndex.BeginUpdate;
    Sep:=Core.Prefs.ReadString('PlayList.Separator');
    try
      for i := 0 to Core.PlayList.Entries.Count - 1 do begin
        E := Core.PlayList.Entries[i];
        Member := PlayList.TPlayEntry.Create;
        Member.Title := E.Title;
        PlstDat.Add(Member.Title);
        RlstFiles.Add(Member.Title);
        FItemIndex.Add(IntToStr(i));
      end;
    finally
      lstFiles.Count := FItemIndex.Count;
      PlstDat.EndUpdate;
      RlstFiles.EndUpdate;
      FItemIndex.EndUpdate;
    end;
  end;
end;

procedure TfrJumpToFile.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caFree;
  FItemIndex.Free;
  RlstFiles.Free;
  PlstDat.Free;
  frJumpToFile := NIL;
end;

procedure TfrJumpToFile.btnCloseOnClick(Sender: TObject);
begin
  Close;
end;

procedure TfrJumpToFile.TakeDat(Control: TWinControl; Index: Integer;
  var Data: String);
begin
  try
    if RlstFiles = nil then Exit;
    if RlstFiles.Count = 0 then Exit;
    Data := RlstFiles.Strings[index];
  except
  end;
end;

procedure TfrJumpToFile.edtSearchChange(Sender: TObject);
var
  i: Cardinal;
  s: String;

  function LowCaseRu(h: string): string;
  var i: Cardinal;
  begin
    for i:=1 to length(h) do begin
      case ord(h[i]) of
        65..90   : h[i]:=chr(ord(h[i])+32);
        192..223 : h[i]:=chr(ord(h[i])+32);
        168      : h[i]:=chr(184);
      else
        h[i]:=h[i];
      end;
    end;
    Result:=h;
  end;

begin
  lstFiles.Clear;
  RlstFiles.Clear;
  FItemIndex.Clear;

  if PlstDat.Count > 0 then
  begin
    RlstFiles.BeginUpdate;
    FItemIndex.BeginUpdate;
    try
      s := LowCaseRu(edtSearch.Text);
      if s <> '' then begin
        for i := 0 to PlstDat.Count - 1 do begin
          if Pos(s, LowCaseRu(PlstDat[i])) > 0 then begin
            RlstFiles.Add(PlstDat[i]);
            FItemIndex.Add(IntToStr(i));
          end;
        end;
      end else
        RlstFiles.AddStrings(PlstDat);
    finally
      lstFiles.Count := RlstFiles.Count;
      RlstFiles.EndUpdate;
      FItemIndex.EndUpdate;
    end;
  end;
end;

procedure TfrJumpToFile.JumpToOnClick(Sender: TObject);
begin
  if (lstFiles.Items.Count > 0) and (lstFiles.ItemIndex > -1) then
  begin
    if Core.PlayList.Entries.Count > 0 then
    begin
      Core.PlayList.PlayEntry(StrToInt(FItemIndex[lstFiles.ItemIndex]), -1);
      btnCloseOnClick(Sender);
    end;
  end;
end;

procedure TfrJumpToFile.lstFilesOnDblClick(Sender: TObject);
begin
  btnJump.Click;
end;

procedure TfrJumpToFile.FormShow(Sender: TObject);
begin
  edtSearch.SetFocus;
end;

Procedure TfrJumpToFile.edtSearchKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_DOWN) then
  begin
    lstFiles.ItemIndex := 0;
    lstFiles.SetFocus;
  end;
  if (Key = VK_UP) then
  begin
    lstFiles.ItemIndex := lstFiles.Items.Count - 1;
    lstFiles.SetFocus;
  end;
end;

procedure TfrJumpToFile.lstFilesOnKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  KeyStr : ShortString;
begin
  if (Key = VK_ESCAPE) then
    btnCloseOnClick(Sender)
  else if (Key = VK_RETURN) then
    lstFilesOnDblClick(Sender)
  else if (Key <> VK_ESCAPE) and (Key <> VK_RETURN)
    and (Key <> VK_UP) and (KEY <> VK_DOWN)
    and (Key <> VK_PRIOR) and (Key <> VK_NEXT) then
  begin
    edtSearch.SetFocus;
    case Key of
      12          : KeyStr := '5';
      192         : KeyStr := '~';
      187         : KeyStr := '+';
      189         : KeyStr := '-';
      220         : KeyStr := '\';
      191         : KeyStr := '/';
      188         : KeyStr := ',';
      190         : KeyStr := '.';
      186         : KeyStr := ';';
      222         : KeyStr := '''';
      219         : KeyStr := '[';
      221         : KeyStr := ']';
      VK_MULTIPLY : KeyStr := '*';
      VK_ADD      : KeyStr := '+';
      VK_SUBTRACT : KeyStr := '-';
      VK_DECIMAL  : KeyStr := '.';
      VK_DIVIDE   : KeyStr := '/';
    else
      if (Char(Key) in ['0'..'9', 'A'..'Z']) then
        KeyStr := Chr(Key)
    end;
    edtSearch.Text := edtSearch.Text + KeyStr;
  end;
end;

procedure TfrJumpToFile.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #27 then Key:=#0;
end;

procedure TfrJumpToFile.edtSearchKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #27) then
  begin
    Key:=#0;
    btnCloseOnClick(Sender);
  end;
  if (Key = #13) then
  begin
    Key:=#0;
    lstFiles.ItemIndex := 0;
    lstFilesOnDblClick(Sender);
  end;
end;

end.
