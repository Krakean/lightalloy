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
unit WinLIRC;

interface

uses
  Windows, Classes, Registry, Messages, ScktComp, Forms, SysUtils, ExtCtrls,
  FocusLA, CmdC;

type
  TWinIRC = class(TObject)
  private
    csWIRC:TClientSocket;
    Timer:TTimer;
    Counter:Integer;
    Focused:Boolean;
    Thrd:Integer;

    procedure OnConnect(Sender:TObject;Socket:TCustomWinSocket);
    procedure OnError(Sender:TObject;Socket:TCustomWinSocket;ErrorEvent:TErrorEvent;var ErrorCode:Integer);
    procedure OnRead(Sender:TObject;Socket:TCustomWinSocket);
    procedure OnDisconnect(Sender:TObject;Socket:TCustomWinSocket);
    procedure OnTimer(Sender:TObject);
    function GetActive: Boolean;
    procedure SetActive(const Value: Boolean);
  public
    IsConnecting,IsConnected:Boolean;

    constructor Create;
    destructor Destroy; override;

    procedure StartServer;
    procedure StopServer;

    procedure Connect;
    procedure Disconnect;

    property Active:Boolean read GetActive write SetActive;
  end;

implementation

uses
  LACore;

procedure CreateIRCWND;
var
  S:String;
  Wnd:HWND;
  R:TRegistry;
begin
  Wnd:=FindWindow(NIL,'WinLIRC');
  if (Wnd<>0) then Exit;

  S:=Core.Prefs.Str['Modules.WinLIRC.Server.Path'];

  if not(FileExists(S)) then
    S:=ExtractFilePath(Application.ExeName)+'WinLIRC\WinLIRC.exe';

  if not(FileExists(S)) then begin
    try
      R:=TRegistry.Create;
      R.RootKey:=HKEY_LOCAL_MACHINE;
      R.OpenKeyReadOnly('\Software\LIRC\');
      S:=R.ReadString('conf');
      S:=ExtractFilePath(S)+'WinLIRC.exe';
      R.Free;
    except
      S:='';
    end;
  end;

  if FileExists(S) then
    Core.SysHlp.Run(S,'',SW_SHOWNOACTIVATE);
  EndThread(0);
end;

procedure TWinIRC.Connect;
begin
  if (IsConnecting or IsConnected) then Exit;

  IsConnecting:=TRUE;
  csWIRC.Address:=Core.Prefs.ReadString('Modules.WinLIRC.Server');
  csWIRC.Port:=Core.Prefs.ReadInteger('Modules.WinLIRC.Port');
  try
    csWIRC.Open;
  except
  end;
end;

constructor TWinIRC.Create;
begin
  inherited Create;

  csWIRC:=TClientSocket.Create(Application);
  csWIRC.OnConnect:=OnConnect;
  csWIRC.OnError:=OnError;
  csWIRC.OnRead:=OnRead;
  csWIRC.OnDisconnect:=OnDisconnect;

  Counter:=0;
  Focused:=True;

  Timer:=TTimer.Create(NIL);
  Timer.Enabled:=FALSE;
  Timer.Interval:=400;
  Timer.OnTimer:=OnTimer;
end;

destructor TWinIRC.Destroy;
begin
  Active:=FALSE;
  Timer.Free;

  FreeAndNIL(csWIRC);

  inherited Destroy;
end;

procedure TWinIRC.Disconnect;
begin
  csWIRC.Close;
end;

function TWinIRC.GetActive: Boolean;
begin
  Result:=Timer.Enabled;
end;

procedure TWinIRC.OnConnect;
begin
  IsConnecting:=FALSE;
  IsConnected:=TRUE;
  Focused:=False;
  CloseHandle(Thrd);
  FocusApp;
  Core.Info(MS('OSD.WIRC.Connected'));
end;

procedure TWinIRC.OnDisconnect;
begin
  IsConnecting:=FALSE;
  IsConnected:=FALSE;
end;

procedure TWinIRC.OnError;
begin
  IsConnecting:=FALSE;
  IsConnected:=FALSE;
  ErrorCode:=0;
end;

procedure TWinIRC.OnRead;
var
  Msg:string;
  IsRepeat:boolean;

  procedure CutValue;
  var
    l:longint;
  begin
    l:=Pos(' ',Msg);
    if (l<>0) then Msg:=Copy(Msg,l+1,length(Msg)-l);
  end;

  procedure CropValue;
  var
    l:longint;
  begin
    l:=Pos(' ',Msg);
    if (l<>0) then Msg:=Copy(Msg,1,l-1);
  end;
begin
  Msg:=Trim(Socket.ReceiveText);
  CutValue;
  IsRepeat:=(Copy(msg,1,1)[1]='0')and(Copy(msg,2,1)[1] in ['1'..char(Core.Prefs.ReadInteger('Modules.WinLIRC.RepeatDelayValue'))]);
  if (Core.Prefs.ReadBool('Modules.WinLIRC.RepeatDelay') and IsRepeat) then Exit;
  CutValue;
  CropValue;
  Center.ProcessWIRCMessage(Msg);
  if Core.Prefs.ReadBool('Modules.WinLIRC.Sound.Enabled') then Core.SndG.Ding;
end;

procedure TWinIRC.OnTimer(Sender: TObject);
begin
  if (IsConnecting or IsConnected) then begin
    if not Focused then begin
      FocusApp;
      Inc(Counter);
      if Counter = 2 then begin
        Focused:=True;
        Timer.Enabled:=False;
      end;
    end;
  end else begin
    if INI.Bool['Modules.WinLIRC.Enabled'] then
      Connect;
  end;
end;

procedure TWinIRC.SetActive(const Value: Boolean);
begin
  Timer.Enabled:=Value;
//  if (Value=TRUE) then Connect;
  if (Value=FALSE) then Disconnect;
end;

procedure TWinIRC.StartServer;
begin
  Thrd:=BeginThread(nil, 0, @CreateIRCWND, nil, 0, ThI);
end;

procedure TWinIRC.StopServer;
var
  Wnd:HWND;
begin
  Wnd:=FindWindow(NIL,'WinLIRC');
  if (Wnd<>0) then
    PostMessage(Wnd,WM_CLOSE,0,0);
end;

end.