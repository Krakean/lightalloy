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
unit About;

interface

uses
  Windows, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, Buttons, ShellAPI, OptiBuilder;

type
  TfrAbout = class(TForm)
    imLogo: TImage;
    lbHomePage: TLabel;
    bbHelp: TBitBtn;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure lbHomePageClick(Sender: TObject);
    procedure bbHelpClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    MainOW:TOptiWrapper;
  public
    procedure CenterWindowToMouse;
  end;

var
  frsAbout: TfrAbout;  

implementation

{$R *.DFM}

uses LACore;

procedure TfrAbout.FormCreate(Sender: TObject);
begin
  bbHelp.Caption:=MS('About.Help');

  imLogo.Picture.Bitmap.Handle:=LoadBitmap(hInstance,'LogoAbout');

  Caption:=Core.VerInfo.FullName;

  if Assigned(Core.OptiBld) then begin
    MainOW:=Core.OptiBld.BuildControl('WndAbout',Self);
    Width:=MainOW.Ctl.Width+GetSystemMetrics(SM_CXFIXEDFRAME)*2;
    Height:=MainOW.Ctl.Height+GetSystemMetrics(SM_CYFIXEDFRAME)*2+GetSystemMetrics(SM_CYCAPTION);
    with MainOW.Ctl do begin
      Left:=0;
      Top:=0;
      SendToBack;
    end;

    bbHelp.Top:=54;
    bbHelp.Width:=95;
    bbHelp.Left:=MainOW.Ctl.Width-bbHelp.Width-12;

    imLogo.Visible:=FALSE;

    with lbHomePage do begin
      Parent:=MainOW.Ctl;
      Top:=MainOW.Ctl.Height-40;
      Left:=195;
      Font.Color:=clBlue;
      Font.Style:=[fsBold,fsUnderline];
      Visible:=FALSE;
    end;
  end;

  CenterWindowToMouse;
end;

procedure TfrAbout.lbHomePageClick(Sender: TObject);
begin
  ShellExecute(0,NIL,'http://www.light-alloy.ru/',NIL,NIL,SW_MAXIMIZE);
end;

procedure TfrAbout.FormDestroy(Sender: TObject);
begin
  if Assigned(Core.OptiBld) then begin
    MainOW.Ctl.Free;
    FreeAndNIL(MainOW);
  end;
end;

procedure TfrAbout.bbHelpClick(Sender: TObject);
begin
  Core.AppLogic.OnHelp;
  Close;
end;

procedure TfrAbout.CenterWindowToMouse;
var
  P:TPoint;
begin
  GetCursorPos(P);
  Left:=P.X-(Width div 2);
  Top:=P.Y-(Height div 2);
  if (Left<0) then Left:=0;
  if (Top<0) then Top:=0;
end;

procedure TfrAbout.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_ESCAPE) then
    Close;
end;

end.
