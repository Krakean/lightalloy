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

unit FocusLA;

interface

var
  DivxSMExeFound: Boolean;
  AppInTrayNow: Boolean;

procedure FocusApp;
procedure CreateWin9xProcessList;
procedure CreateWinNTProcessList;
procedure GetProcessList;

implementation

uses PSApi, tlhelp32, Forms, Windows, Classes, SysUtils;

// Возвращает фокус приложению.
procedure FocusApp;
var
  hWnd, hCurWnd, dwThreadID, dwCurThreadID: THandle;      
  OldTimeOut: Cardinal;      
  AResult: Boolean;      
begin      
    hWnd := Application.Handle; 
    SystemParametersInfo(SPI_GETFOREGROUNDLOCKTIMEOUT, 0, @OldTimeOut, 0);      
    SystemParametersInfo(SPI_SETFOREGROUNDLOCKTIMEOUT, 0, Pointer(0), 0);      
    SetWindowPos(hWnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE); 
    hCurWnd := GetForegroundWindow;      
    AResult := False;      
    while not AResult do      
    begin      
      dwThreadID := GetCurrentThreadId;      
      dwCurThreadID := GetWindowThreadProcessId(hCurWnd); 
      AttachThreadInput(dwThreadID, dwCurThreadID, True); 
      AResult := SetForegroundWindow(hWnd); 
      AttachThreadInput(dwThreadID, dwCurThreadID, False);      
    end; 
    SetWindowPos(hWnd, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE); 
    SystemParametersInfo(SPI_SETFOREGROUNDLOCKTIMEOUT, 0, Pointer(OldTimeOut), 0); 
end;

procedure CreateWin9xProcessList;
var
  hSnapShot: Thandle;
  ProcInfo: TProcessEntry32;
  found: integer;
begin
  hSnapShot := CreateToolHelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if (hSnapShot <> THandle(-1)) then 
  begin
    ProcInfo.dwSize := SizeOf(ProcInfo); 
    if (Process32First(hSnapshot, ProcInfo)) then 
    begin 
      while (Process32Next(hSnapShot, ProcInfo)) do
      begin
        found := pos('divxsm.exe', LowerCase(procinfo.szexefile));
        if found > 0 then
        begin
          DivxSMExeFound := True;
          Break;
        end;
      end;
    end;
    CloseHandle(hSnapShot); 
  end; 
end; 

procedure CreateWinNTProcessList;
var 
  PIDArray: array [0..1023] of DWORD; 
  cb: DWORD; 
  I: word; 
  hMod: HMODULE; 
  hProcess: THandle; 
  ModuleName: array [0..300] of Char;

  found: integer; 
begin 
  EnumProcesses(@PIDArray, SizeOf(PIDArray), cb); 
 
  for I := 0 to  (cb div SizeOf(DWORD))-1 do
  begin 
    hProcess := OpenProcess(PROCESS_QUERY_INFORMATION or 
      PROCESS_VM_READ, 
      False, 
      PIDArray[I]); 
    if (hProcess <> 0) then 
    begin 
      EnumProcessModules(hProcess, @hMod, SizeOf(hMod), cb); 
      GetModuleFilenameEx(hProcess, hMod, ModuleName, SizeOf(ModuleName));
      found := pos('divxsm.exe', LowerCase(ModuleName));
      if found > 0 then
      begin
        DivxSMExeFound := True;

        break;
      end;
      CloseHandle(hProcess);
    end;
  end;
end;

procedure GetProcessList;
var
  ovi: TOSVersionInfo;
begin
  ovi.dwOSVersionInfoSize := SizeOf(TOSVersionInfo);
  GetVersionEx(ovi);
  case ovi.dwPlatformId of
    VER_PLATFORM_WIN32_WINDOWS: CreateWin9xProcessList;
    VER_PLATFORM_WIN32_NT: CreateWinNTProcessList;   
  end
end;

end.
