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
unit Alert;

interface

uses
  Windows, Variants, Classes, Graphics, Controls, Forms, ShellAPI,
  Dialogs, StdCtrls, ExtCtrls, Buttons;

type
  TfrAlert = class(TForm)
    bbOk: TBitBtn;
    imSign: TImage;
    lblText: TLabel;
    lblLink: TLabel;
    procedure OnClick(Sender: TObject);
    procedure OnKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure lblLinkClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
  public
    FShowLink: Boolean;
    procedure SetText(Txt:String);
  end;

implementation

uses
  OtherGlobalVars, LACore;

{$R *.dfm}

{ TfrAlert }

procedure TfrAlert.SetText(Txt: String);
begin
  lblText.Caption:=Txt;
  Width:=80+lblText.Width;
  Height:=120+lblText.Height;
  if FShowLink then
    Width:=60+lblLink.Width;
end;

procedure TfrAlert.OnClick(Sender: TObject);
begin
  if NeedAppReload then
    Core.OnAppExit;
end;

procedure TfrAlert.OnKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then Close;
end;

procedure TfrAlert.lblLinkClick(Sender: TObject);
begin
  ShellExecute(0,NIL,'http://www.light-alloy.ru',NIL,NIL,SW_MAXIMIZE);
end;

procedure TfrAlert.FormShow(Sender: TObject);
begin
  lblLink.Visible:=FShowLink;
end;

end.
