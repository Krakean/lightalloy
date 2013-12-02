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
unit OpenURLDialog;

interface

uses
  Windows, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TfrOpenURL = class(TForm)
    cbbURL: TComboBox;
    btnOk: TButton;
    btnCancel: TButton;
    procedure btnOkClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure cbbURLKeyPress(Sender: TObject; var Key: Char);
  private
  public
  end;

var
  frOpenURL: TfrOpenURL;

implementation

uses LACore, Clipbrd;

{$R *.dfm}

procedure TfrOpenURL.btnOkClick(Sender: TObject);
var
  i:Integer;
begin
  i:=Core.PlayList.Entries.Count;
  if (Pos(':/',cbbURL.Text)<>0) and (Pos('m3u',LowerCase(cbbURL.Text))=0) then
    Core.PlayList.AddEntry(cbbURL.Text)
  else
  if (Pos(':/',cbbURL.Text)<>0) and (Pos('m3u',LowerCase(cbbURL.Text))<>0) then
    Core.PlayList.AddFromM3U(cbbURL.Text);
  frOpenURL.Close;
  if i>-1 then
    Core.PlayList.PlayEntry(i,0);
end;

procedure TfrOpenURL.btnCancelClick(Sender: TObject);
begin
  frOpenURL.Close;
end;

procedure TfrOpenURL.FormShow(Sender: TObject);
var
  Data: THandle;
  TextPtr: PChar;
  Link: string;
begin
  cbbURL.SetFocus;

  ClipBoard.Open;
  try
    Data := Clipboard.GetAsHandle(CF_TEXT);
    TextPtr := GlobalLock(Data);
    Link:=StrPas(TextPtr);
    GlobalUnlock(Data);
  finally
    Clipboard.Close;
  end;

  if ((Link[1]='h') and (Link[2]='t') and (Link[3]='t') and (Link[4]='p'))
    or ((Link[1]='m') and (Link[2]='m') and (Link[3]='s'))
  then
    cbbURL.Text:=Link;
end;

procedure TfrOpenURL.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #27 then Key:=#0;
end;

procedure TfrOpenURL.cbbURLKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #27) then
  begin
    Key:=#0;
    btnCancelClick(Sender);
  end;
  if (Key = #13) then
  begin
    Key:=#0;
    btnOkClick(Sender);
  end;
end;

end.
