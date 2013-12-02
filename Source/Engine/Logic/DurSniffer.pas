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
unit DurSniffer;

interface

uses
  Windows, SysUtils, Classes, uMediaInfo, CachedFile, ActiveX;

type
  TSnifferThread = class(TThread)
  public
    FileName:String;
    IsRequested:Boolean;
    IsCompleted:Boolean;
    Duration:Int64;

    procedure Execute; override;
  end;

  TDurationSniffer = class
  private
    SnTh:TSnifferThread;
  public
    FileName:String;

    constructor Create;
    destructor Destroy; override;

    procedure Request(FN:String);
    function IsCompleted:Boolean;
    function Duration:Int64;
  end;

implementation



procedure TSnifferThread.Execute;
var
  MI:TMediaInfo;
  CF:TCachedFile;
begin
  CoInitialize(NIL);
  repeat
    Sleep(50);
    if (IsRequested) then begin
      IsCompleted:=FALSE;

      CF:=TCachedFile.Create(FileName);
      MI:=TMediaInfo.Create(CF);
      MI.RetreiveInfo;
      Duration:=MI.FInfo.Duration;
      MI.Free;
      CF.Free;

      IsRequested:=FALSE;
      IsCompleted:=TRUE;
    end;
  until Terminated;
  CoUninitialize;
end;

{ TDurationSniffer }

constructor TDurationSniffer.Create;
begin
  inherited Create;
  SnTh:=TSnifferThread.Create(FALSE);
  SnTh.FreeOnTerminate:=FALSE;
end;

destructor TDurationSniffer.Destroy;
begin
  SnTh.Terminate;
  SnTh.WaitFor;
  SnTh.Free;
  inherited Destroy;
end;

function TDurationSniffer.Duration: Int64;
begin
  Result:=SnTh.Duration;
end;

function TDurationSniffer.IsCompleted: Boolean;
begin
  Result:=SnTh.IsCompleted;
end;

procedure TDurationSniffer.Request(FN: String);
begin
  FileName:=FN;
  SnTh.IsCompleted:=FALSE;
  SnTh.FileName:=FN;
  SnTh.IsRequested:=TRUE;
end;

end.
