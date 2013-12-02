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
unit CPUUsage;

interface

uses
  Windows, SysUtils, Classes, CPUMeter;

(*
constructor TThread.Create(CreateSuspended: Boolean);
  FHandle := BeginThread(nil, 0, @ThreadProc, Pointer(Self), CREATE_SUSPENDED, FThreadID);
function BeginThread(SecurityAttributes: Pointer; StackSize: LongWord;
  IsMultiThread := TRUE;
*)

type
  TCPUThread = class(TThread)
  public
    TargetWnd:HWND;
    Value:LongInt;

    constructor Create(Target:HWND);
    procedure Execute; override;
  end;

  TCPU = class
  private
    FThread:TCPUThread;
  public
    constructor Create(Target:HWND);
    destructor Destroy; override;

    function Usage:LongInt;
  end;

implementation

constructor TCPU.Create;
begin
  inherited Create;
  FThread:=TCPUThread.Create(Target);
  FThread.FreeOnTerminate:=FALSE;
end;

destructor TCPU.Destroy;
begin
  FThread.Terminate;
  FThread.WaitFor;
  FreeAndNIL(FThread);
  inherited Destroy;
end;

constructor TCPUThread.Create;
begin
  TargetWnd:=Target;
  inherited Create(FALSE);
end;

procedure TCPUThread.Execute;
var
  CPU:TCPUMeter;
begin
  CPU:=TCPUMeter.Create;
  repeat
    Sleep(300);
    Value:=CPU.Usage;
  until Terminated;
  CPU.Free;
end;

function TCPU.Usage: LongInt;
begin
  Result:=FThread.Value;
end;

end.
