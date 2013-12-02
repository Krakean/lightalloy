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

unit SysHlp;

interface

{$WARN SYMBOL_PLATFORM OFF}

uses
  Windows, Classes, Registry, SysUtils, ShlObj, ActiveX, Forms, Messages;

const
  HNS:Int64 = 10000000;
  
type
  TSystemHelper = class(TObject)
  private
    fOS: Integer;
    IsMonitorOff:Boolean;
  public
    function DX:Integer;
    function OS:Integer;
    function IsExpirienceFamily:Boolean;
    function IsVistaFamily:Boolean;
    function IsNT:Boolean;
    function WinDir:String;
    function WinSysDir:String;
    procedure Hibernate;
    procedure PowerOff;
    function GetLongFileName(FileName:String):String;
    function SelectFolder(InitFolder:String):String;

    function FormatHNS(Fmt:String;Time:Int64):String;

    function GetPersonalAppDataFolder:String;
    function GetCommonAppDataFolder:String;
    function GetMyDocsFolder:String;
    function GetTempFolder:String;
    procedure ProcessMsgs;
    procedure SwitchMonitor(Flag:Boolean);
    procedure ToggleMonitorPower;
    procedure PopupWindow(hWnd:THandle);
    procedure Run(Exe,Params:String;ShowParam:DWORD);

    function IsFileExists(FileName:String):Boolean;
    function PointToStr(P:TPoint):String;
    function StrToPoint(S:String):TPoint;

    function IntsToStr(Delimiter:Char;const Args:array of LongInt):String;
    function IntParam(Str:String;Index:LongInt):LongInt;
  end;

implementation

{ TSystemHelper }

uses Config;

function TSystemHelper.IntsToStr;
var
  l:LongInt;
begin
  Result:='';
  for l:=1 to Length(Args) do begin
    if (l<>1) then Result:=Result+Delimiter;
    Result:=Result+IntToStr(Args[l-1]);
  end;
end;

function TSystemHelper.DX;
var
  R:TRegistry;
  Ver:String;
  Maj,Min:longint;
begin
  Result:=-1;
  R:=TRegistry.Create;
  try
    R.RootKey:=HKEY_LOCAL_MACHINE;
    if R.OpenKeyReadOnly('\Software\Microsoft\DirectX') then begin
      Ver:=R.ReadString('Version');
      Maj:=StrToInt(Copy(Ver,1,1));
      Min:=StrToInt(Copy(Ver,3,2));
      Result:=Min;
    end;
  finally
    R.Free;
  end;
end;

function TSystemHelper.OS: Integer;
var
  OsVersionInfo:TOSVERSIONINFO;
begin
  if fOS=0 then begin
    OSVersionInfo.dwOSVersionInfoSize:=SizeOf(OSVersionInfo);
    GetVersionEx(OSVersionInfo);
    fOS:=OSVersionInfo.dwMajorVersion;
    Result:=fOS;
  end
  else
    Result:=fOS;
end;

function TSystemHelper.FormatHNS;
var                           // '{H}:{M}:{S}.{MS}
  h,m,s,ms:LongInt;
begin
  Time:=Time div (HNS div 1000);
  ms:=Time mod 1000;

  Time:=Time div 1000;
  s:=Time mod 60;

  Time:=Time div 60;
  m:=Time mod 60;

  h:=Time div 60;

  Result:=Fmt;
  Result:=StringReplace(Result,'{H}',Format('%d',[h]),[rfReplaceAll]);
  Result:=StringReplace(Result,'{M}',Format('%.2d',[m]),[rfReplaceAll]);
  Result:=StringReplace(Result,'{m}',Format('%.d',[m]),[rfReplaceAll]);
  Result:=StringReplace(Result,'{S}',Format('%.2d',[s]),[rfReplaceAll]);
  Result:=StringReplace(Result,'{MS}',Format('%.3d',[ms]),[rfReplaceAll]);
end;

const
  CSIDL_COMMON_APPDATA = $0023;

function TSystemHelper.GetCommonAppDataFolder: String;
var
  SHMalloc:IMalloc;
  Buf:array[0..MAX_PATH-1] of Char;
  ppidl:PItemIDList;
begin
  Result:=''; // SHGetSpecialFolderPath
  if FAILED(SHGetMalloc(SHMalloc)) then Exit;

  SHGetSpecialFolderLocation(0,CSIDL_COMMON_APPDATA,ppidl);
  if Assigned(ppidl) then begin
    if SHGetPathFromIDList(ppidl,@Buf) then begin
      Result:=IncludeTrailingPathDelimiter(Buf);
    end;
    SHMalloc.Free(ppidl);
  end;
  SHMalloc:=NIL;
end;

function TSystemHelper.GetLongFileName;
var
  SR:TSearchRec;
begin
  Result:=ExpandFileName(FileName);
  if (FindFirst(FileName,faAnyFile,SR)=0) then
    Result:=ExtractFilePath(Result)+SR.FindData.cFileName;
  FindClose(SR);
end;

function TSystemHelper.GetMyDocsFolder;
var
  PIDL:PItemIDList;
  Path:LPSTR;
begin
  Result:='';

  Path:=StrAlloc(MAX_PATH);
  if (SHGetSpecialFolderLocation(0,CSIDL_PERSONAL,PIDL)=NOERROR) then
    if SHGetPathFromIDList(PIDL,Path) then
      Result:=Path;
  StrDispose(Path);

  Result:=SysUtils.IncludeTrailingBackslash(Result);
end;

function TSystemHelper.GetPersonalAppDataFolder: String;
var
  SHMalloc:IMalloc;
  Buf:array[0..MAX_PATH-1] of Char;
  ppidl:PItemIDList;
begin
  Result:='';
  if FAILED(SHGetMalloc(SHMalloc)) then Exit;

  SHGetSpecialFolderLocation(0,CSIDL_APPDATA,ppidl);
  if Assigned(ppidl) then begin
    if SHGetPathFromIDList(ppidl,@Buf) then begin
      Result:=IncludeTrailingPathDelimiter(Buf);
    end;
    SHMalloc.Free(ppidl);
  end;
  SHMalloc:=NIL;
end;

function TSystemHelper.GetTempFolder;
var
  Path:array [0..MAX_PATH-1] of Char;
begin
  GetTempPath(MAX_PATH,Path);
  Result:=IncludeTrailingPathDelimiter(Path);
end;

procedure TSystemHelper.Hibernate;
var
  handle,ph:THandle;
  pid:DWORD;
  luid:TLargeInteger;
  dummy,priv:TOKEN_PRIVILEGES;
begin
  if (IsNT) then begin
    pid:=GetCurrentProcessId;
    ph:=OpenProcess(PROCESS_ALL_ACCESS,FALSE,pid);
    if OpenProcessToken(ph,TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY,handle) then
      if LookupPrivilegeValue(NIL,'SeShutdownPrivilege',luid) then begin
        priv.PrivilegeCount:=1;
        priv.Privileges[0].Attributes:=SE_PRIVILEGE_ENABLED;
        priv.Privileges[0].Luid:=luid;
        AdjustTokenPrivileges(handle,FALSE,priv,SizeOf(priv),dummy,pid);
      end;
  end;
  SetSystemPowerState(FALSE,FALSE);
end;

function TSystemHelper.IsFileExists(FileName: String): Boolean;
var
  hf:THandle;
begin
  Result:=FALSE;

  hf:=CreateFile(PChar(FileName),GENERIC_READ,
     FILE_SHARE_READ or FILE_SHARE_WRITE,
     NIL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0);
     
  if (hf<>INVALID_HANDLE_VALUE) then begin
    Result:=TRUE;
    CloseHandle(hf);
  end;
end;

function TSystemHelper.IsExpirienceFamily;
begin
  Result:=(OS=5);
end;

function TSystemHelper.IsVistaFamily;
begin
  Result:=(OS=6);
end;

function TSystemHelper.IsNT: Boolean;
var
  OsVersionInfo:TOSVERSIONINFO;
begin
  OSVersionInfo.dwOSVersionInfoSize:=SizeOf(OSVersionInfo);
  GetVersionEx(OSVersionInfo);
  Result:=(OSVersionInfo.dwPlatformId=VER_PLATFORM_WIN32_NT);
end;

function TSystemHelper.PointToStr(P: TPoint): String;
begin
  Result:=Format('%d,%d',[P.X,P.Y]);
end;

procedure TSystemHelper.PopupWindow(hWnd: THandle);
var
  hCurrWnd:THandle;
  iMyTID,iCurrTID:LongInt;
begin
  hCurrWnd:=GetForegroundWindow;
  iMyTID:=GetCurrentThreadId;
  iCurrTID:=GetWindowThreadProcessId(hCurrWnd,NIL);

  AttachThreadInput(iMyTID,iCurrTID,TRUE);
  SetForegroundWindow(hWnd);
  AttachThreadInput(iMyTID,iCurrTID,FALSE);
end;

procedure TSystemHelper.PowerOff;
var
  handle,ph:THandle;
  pid:DWORD;
  luid:TLargeInteger;
  dummy,priv:TOKEN_PRIVILEGES;
begin
  if (IsNT) then begin
    pid:=GetCurrentProcessId;
    ph:=OpenProcess(PROCESS_ALL_ACCESS,FALSE,pid);
    if OpenProcessToken(ph,TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY,handle) then
      if LookupPrivilegeValue(NIL,'SeShutdownPrivilege',luid) then begin
        priv.PrivilegeCount:=1;
        priv.Privileges[0].Attributes:=SE_PRIVILEGE_ENABLED;
        priv.Privileges[0].Luid:=luid;
        AdjustTokenPrivileges(handle,FALSE,priv,SizeOf(priv),dummy,pid);
      end;
  end;
//  ExitWindowsEx(EWX_SHUTDOWN or EWX_POWEROFF,0);
//  Sleep(10*1000);
  ExitWindowsEx(EWX_SHUTDOWN or EWX_POWEROFF or EWX_FORCE,0);
end;

var
  XDir:String;

function BrowseCallbackProc(hWnd:HWND;uMsg:UINT;lParam:LPARAM;lpData:LPARAM):integer; stdcall;
begin
  if (Length(XDir)>3) and (XDir[Length(XDir)]='\') then
    XDir:=Copy(XDir,1,Length(XDir)-1);
  XDir:=XDir+#0#0#0#0;

  Result:=0;
  if (uMsg=BFFM_INITIALIZED) then
    PostMessage(hWnd,BFFM_SETSELECTION,1,LongInt(XDir));
end;

procedure TSystemHelper.Run;
var
  StartupInfo:TStartupInfo;
  ProcessInfo:TProcessInformation;
  WorkDir:String;
begin
  WorkDir:=ExtractFilePath(Exe);

  ZeroMemory(@StartupInfo,SizeOf(StartupInfo));
  with StartupInfo do begin
    cb:=SizeOf(StartupInfo);
//    dwFlags:=STARTF_USESHOWWINDOW;
//    wShowWindow:=ShowParam;
  end;
  ZeroMemory(@ProcessInfo,SizeOf(ProcessInfo));

  CreateProcess(NIL,PChar(Exe+' '+Params),NIL,NIL,FALSE,
    CREATE_NEW_CONSOLE,NIL,PChar(WorkDir),StartupInfo,ProcessInfo);
end;

function TSystemHelper.SelectFolder(InitFolder: String): String;
var
  SHMalloc:IMalloc;
  iidlRoot,iidlFolder:PItemIdList;
  BInfo:TBrowseInfo;
  Buffer:array[0..MAX_PATH-1] of Char;
begin
  Result:='';
  if FAILED(SHGetMalloc(SHMalloc)) then Exit;

  if Assigned(frConfig) then
    if frConfig.ConfigPageAlwayOnTop.Enabled then
      frConfig.SwitchCfgTopPos(Application.Handle, True);

  XDir:=InitFolder;
  SHGetSpecialFolderLocation(Application.Handle,CSIDL_DRIVES,iidlRoot);
  with BInfo do begin
    hwndOwner:=Application.Handle;
    pidlRoot:=iidlRoot;
    pszDisplayName:=@Buffer;
    lpszTitle:='Âûáîð ïàïêè';
    ulFlags:=BIF_RETURNONLYFSDIRS;
    lpfn:=@BrowseCallbackProc;
  end;

  iidlFolder:=SHBrowseForFolder(BInfo);
  if Assigned(iidlFolder) then begin
    if SHGetPathFromIDList(iidlFolder,@Buffer) then
    begin
      Result:=Buffer;
    end;
    SHMalloc.Free(iidlFolder);
  end;
  //if frConfig.ConfigPageAlwayOnTop.Enabled then frConfig.SwitchCfgTopPos(BInfo.hwndOwner, False);
  SHMalloc.Free(iidlRoot);
  SHMalloc:=NIL;
end;

const
  MONITOR_TURNOFF = 2;
  MONITOR_STANDBY = 1;
  MONITOR_BLACK = 0;
  MONITOR_TURNON = -1;

function TSystemHelper.StrToPoint(S: String): TPoint;
var
  l:LongInt;
begin
  Result:=Point(0,0);
  l:=Pos(',',S);
  try
    if (l>0) then begin
      Result.X:=StrToInt(Copy(S,1,l-1));
      Result.Y:=StrToInt(Copy(S,l+1,200));
    end else begin
      Result.X:=StrToInt(S);
    end;
  except
  end;
end;

procedure TSystemHelper.SwitchMonitor(Flag: Boolean);
begin
  if Flag then begin
    SendMessage(HWND_BROADCAST,WM_SYSCOMMAND,SC_MONITORPOWER,MONITOR_TURNON);
  end else begin
    SendMessage(HWND_BROADCAST,WM_SYSCOMMAND,SC_MONITORPOWER,MONITOR_TURNOFF);
  end;
  IsMonitorOff:=not(Flag);
end;

procedure TSystemHelper.ToggleMonitorPower;
var
  l:LongInt;
begin
  for l:=0 to 5 do begin
    Sleep(100);
    Application.ProcessMessages;
  end;
  SwitchMonitor(IsMonitorOff);
end;

function TSystemHelper.WinDir: String;
var
  Path:array [0..MAX_PATH-1] of Char;
begin
  GetWindowsDirectory(Path,MAX_PATH);
  Result:=IncludeTrailingPathDelimiter(Path);
end;

function TSystemHelper.WinSysDir: String;
var
  Path:array [0..MAX_PATH-1] of Char;
begin
  GetSystemDirectory(Path,MAX_PATH);
  Result:=IncludeTrailingPathDelimiter(Path);
end;

function TSystemHelper.IntParam;
var
  Ix,l:LongInt;
begin
  Result:=0;
  Ix:=0;
  for l:=1 to Length(Str) do begin
    if (Str[l] in ['0'..'9']) then begin
      if (Ix=Index) then
        Result:=10*Result+Ord(Str[l])-$30;
    end else begin
      if (Ix=Index) then Break;
      Result:=0;
      Inc(Ix);
    end;
  end;
end;

procedure TSystemHelper.ProcessMsgs;
begin
  Application.ProcessMessages;
end;

end.
