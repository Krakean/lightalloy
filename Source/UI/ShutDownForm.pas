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
unit ShutDownForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons;

type
  TfrShutdown = class(TForm)
    Image1: TImage;
    lbShutdown: TLabel;
    btCancel: TButton;
    bbShutdown: TBitBtn;
    Timer: TTimer;
    procedure btCancelClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure bbShutdownClick(Sender: TObject);
  private
    procedure TuneLang;
  public
    Countdown:LongInt;
    
    procedure PowerOff;
  end;

var
  frShutdown: TfrShutdown;

implementation

uses
  MainUnit, LACore, OtherGlobalVars;

var
  Pause: Byte;

{$R *.dfm}

procedure TfrShutdown.PowerOff;
begin
  //Timer.Enabled := False;
  Core.AppLogic.StopActivity;
  Core.SysHlp.PowerOff;
  frMain.Close;
  Close;
end;

procedure TfrShutdown.btCancelClick(Sender: TObject);
begin
  SDDialogCreated := False;
  Close;
end;

procedure TfrShutdown.FormCreate(Sender: TObject);
begin
  Pause:=2;
  Countdown:=Core.Prefs.ReadInteger('FrontEnd.ShutDownTimer');
  TuneLang;
  bbShutdown.SetFocus;
end;

procedure TfrShutdown.TimerTimer(Sender: TObject);
begin
  if (Countdown=0) then
  begin
    Timer.Enabled:=FALSE;
    PowerOff;
  end else
  begin
    Dec(Countdown);
    if Pause>0 then Dec(Pause);
    TuneLang;
    SetWindowPos(Handle,HWND_TOPMOST,0,0,0,0,SWP_NOMOVE or SWP_NOSIZE);
    BringWindowToTop(Handle);
    SetForegroundWindow(Handle);
  end;
end;

procedure TfrShutdown.TuneLang;
begin
  lbShutdown.Caption:=Format(MS('Shutdown.Warning'),[Countdown]);
  bbShutdown.Caption:=MS('Shutdown.Shutdown');
  btCancel.Caption:=MS('Common.Cancel');
end;

procedure TfrShutdown.bbShutdownClick(Sender: TObject);
begin
  if Pause=0 then
    Countdown:=0;
end;

end.
