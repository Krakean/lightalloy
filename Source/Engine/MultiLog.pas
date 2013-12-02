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

unit MultiLog;

interface

{=== Special Characters ===}
{ + Enter Proc             }
{ - Exit Proc              }
{ = Data      (Blue)       }
{ ? Warning   (Purple)     }
{ ! Error     (Red)        }
{==========================}

procedure Log(Msg:String);
procedure LogHR(Msg:string;hR:HRESULT);
procedure LogLE(Msg:string);
procedure LogHeap(Init:Boolean);
function GetLogHistory:String;

implementation

uses
  Windows, SysUtils, Forms, Classes, CPUCaps, OtherGlobalVars;

const
  HistoryCount = 5;

var
  LogLock:TRTLCriticalSection;
  LogEnabled:Boolean = FALSE;
  LogFileName:string;
  offset: string;
  History:array [0..HistoryCount-1] of String = ('','','','','');
//  MainThread:DWORD;

//------------------------------------------------------------------------------
function Iff(const Condition: Boolean; const TruePart, FalsePart: String): String;
begin
  if Condition then
    Result := TruePart
  else
    Result := FalsePart;
end;

function GetLogHistory;
var
  l:LongInt;
begin
  Result:=History[0];
  for l:=1 to (HistoryCount-2) do
    Result:=Result+#13#10+History[l];
end;

procedure UpdateHistory(Msg:String);
var
  l:LongInt;
begin
  for l:=1 to (HistoryCount-1) do
    History[l-1]:=History[l];
  History[HistoryCount-1]:=Msg;
end;

var
  MicroFreq,MicroVOfs:Int64;
//  MicroTimeOfs:TDateTime;
//  MicroCoeff:Double;
{
function GetMicroTime:string;
var
  microTime:Int64;
  sec: integer;
begin
  {if (MicroFreq=0) then begin
    Result:=Round(Now*100000000);
  end else begin
    QueryPerformanceCounter(V);
    Result:=Round((MicroTimeOfs+(V-MicroVOfs)/MicroCoeff)*100000000);
  end;

  if (MicroFreq=0) then begin
    Result:='MicroFreq=0';
  end else
  begin
    QueryPerformanceCounter(microTime);
    microTime:= microTime -  MicroVOfs;
    sec:= microTime div MicroFreq;
   // if (sec div 60) > 0
      result:=  IntToStr(sec div 60) +':' ;
    result:= result + IntToStr(sec mod 60)+','+IntToStr(microTime mod MicroFreq);
  end;
end;
 }
const
  Hexes:array [0..15] of Char= '0123456789ABCDEF';

{procedure HexToPChar(Val:Int64;Cnt:LongInt;PC:PChar);
var
  l:LongInt;
begin
  Inc(PC,Cnt);

  for l:=1 to Cnt do begin
    Dec(PC);
    PC^:=Hexes[Val and $0F];
    Val:=Val shr 4;
  end;
end;
}

procedure LogTimeHeader(hf:LongInt);
var
  Counter: Int64;
  sec: real;
  Str: string;
begin
//  str:= inttostr(GetCurrentProcessID)+':';
//  str:= str+inttostr(GetCurrentThreadID)+':';
  if (MicroFreq=0) then begin
    str:='{MicroFreq=0}';
  end else
  begin
    QueryPerformanceCounter(Counter);
    Counter:= (Counter -  MicroVOfs);
    sec:= Counter / MicroFreq;
    str:=Format('[%.3d:%.2d,%.4d]',[trunc(sec / 60), (trunc(sec) mod 6), trunc(Frac(sec)*10000)]);
  end;
  FileWrite(hf,Str[1],Length(Str));
end;

procedure LogDebugInf();  // вывод состояний всех необходимых переменных
var
  hf:LongInt;
  Str: TStringList;
begin
  if not LogEnabled then exit;
  EnterCriticalSection(LogLock);
  Str := TStringList.Create;
  try
    hf:=FileOpen(LogFileName,fmOpenWrite or fmShareDenyNone);
    if (hf>=0) then begin
      FileSeek(hf,0,2);
      LogTimeHeader(hf);
      str.Add('===Begin Debug Inf===');
      // ниже список всех переменных что нам записать в лог надо
      str.Add('');
      

      str.Add('===End Debug Inf===');
      FileWrite(hf,Str.text[1],Length(Str.Text));
      FileClose(hf);
    end;
  finally
    Str.Free;
    LeaveCriticalSection(LogLock);
  end;
end;


procedure Log;
var
  hf:LongInt;
  Str:string;
begin
  if (not LogEnabled) or NoLogging then Exit;
  //EnterCriticalSection(LogLock);
  try
    //UpdateHistory(Msg);
    hf:=FileOpen(LogFileName,fmOpenWrite or fmShareDenyNone);
    if (hf>=0) then begin
      FileSeek(hf,0,2);
      //Str:=Format('%.8x:%.8x:%x:',[GetCurrentProcessID,GetCurrentThreadID,GetMicroTime]);
      //Msg:=StringReplace(Msg,#13#10,#13#10+Str,[rfReplaceall]);
      LogTimeHeader(hf);
      // if (GetCurrentThreadID=MainThread) then MainThread:=0;
      if (Length(msg) > 1) then
      begin
        if msg[1] = '-' then
          Delete(offset,1,3);
        Str:=offset+Msg + #13#10;
        if msg[1] = '+' then
          offset:= offset + '   ';
      end
      else
        Str := offset + #13#10;
      FileWrite(hf,Str[1],Length(Str));
      FileClose(hf);
    end;
  finally
    LeaveCriticalSection(LogLock);
  end;
end;

function GetCPUSpeed:LongInt;
const
  DelayTime = 20;
var
  TimerHi:DWORD;
  TimerLo:DWORD;
  PriorityClass:Integer;
  Priority:Integer;
begin
  PriorityClass := GetPriorityClass(GetCurrentProcess);
  Priority := GetThreadPriority(GetCurrentThread);
  SetPriorityClass(GetCurrentProcess, REALTIME_PRIORITY_CLASS);
  SetThreadPriority(GetCurrentThread, THREAD_PRIORITY_TIME_CRITICAL);
  Sleep(10);
  asm
    DW 310Fh // rdtsc
    MOV TimerLo, EAX
    MOV TimerHi, EDX
  end;
  Sleep(DelayTime);
  asm
    DW 310Fh // rdtsc
    SUB EAX, TimerLo
    SBB EDX, TimerHi
    MOV TimerLo, EAX
    MOV TimerHi, EDX
  end;
  SetThreadPriority(GetCurrentThread, Priority);
  SetPriorityClass(GetCurrentProcess, PriorityClass);
  Result:=TimerLo div (1000*DelayTime);
end;


procedure LogSysInfo;
var
  OV:TOSVersionInfo;
  Build:DWORD;
  s:String;
  Path:array [0..MAX_PATH-1] of Char;
  SI:TSystemInfo;
  MS:TMemoryStatus;
  W, H, C, F : Integer;
  DC         : THandle;

  function IsVer(PlatfID,Maj,Min:DWORD):Boolean;
  begin
    Result:=(OV.dwPlatformID=PlatfID) and
            (OV.dwMajorVersion=Maj) and
            (OV.dwMinorVersion=Min);
  end;
begin
  Log('+SysInfo');

  // Detect current resolution.
  DC := GetDC(Application.Handle);
  try
     W := GetDeviceCaps(DC, HORZRES);
     H := GetDeviceCaps(DC, VERTRES);
     C := GetDeviceCaps(DC, BITSPIXEL);
     F := GetDeviceCaps(DC, VREFRESH);
  finally
     ReleaseDC(Application.Handle, DC);
  end;

  GetSystemInfo(SI);
  Log(Format(' CPU x%d, %d MHz; Caps: %s %s %s %s %s %s',[SI.dwNumberOfProcessors, GetCPUSpeed,
     Iff(stCPUCaps.hasMMX, 'MMX', ''), Iff(stCPUCaps.hasMMX2, ' MMX2', ''), Iff(stCPUCaps.hasSSE, ' SSE', ''),
       Iff(stCPUCaps.hasSSE2, ' SSE2', ''), Iff(stCPUCaps.hasSSE3, ' SSE3', ''), Iff(stCPUCaps.has64, ' 64', '')]));

  GlobalMemoryStatus(MS);
  Log(' RAM '+IntToStr(MS.dwTotalPhys div (1024*1024))+' Mb');

  OV.dwOSVersionInfoSize:=SizeOf(OV);
  if (GetVersionEx(OV)) then begin
    s:='';
    if IsVer(VER_PLATFORM_WIN32_WINDOWS,4,10) then s:='98';
    if IsVer(VER_PLATFORM_WIN32_WINDOWS,4,90) then s:='ME';
    if IsVer(VER_PLATFORM_WIN32_NT,4,0) then s:='NT';
    if IsVer(VER_PLATFORM_WIN32_NT,5,0) then s:='2K';
    if IsVer(VER_PLATFORM_WIN32_NT,5,1) then s:='XP';

    Build:=OV.dwBuildNumber;
    if (OV.dwPlatformID<>VER_PLATFORM_WIN32_NT) then Build:=Build and $FFFF;

    Log(Format(' Windows %s %s (%d.%d build %d)',
      [s,OV.szCSDversion,OV.dwMajorVersion,OV.dwMinorVersion,Build]));
  end;
  GetWindowsDirectory(Path, MAX_PATH);
  Log(' WinDir='+Path);

  Log(Format(' MicroFreq = %d',[MicroFreq]));

  Log(' Screen Resolution: ' + Format('%dx%dx%d, %dHz', [W, H, C, F]));
  Log(' Monitor count: ' + IntToStr(Screen.MonitorCount)); 

  Log('-SysInfo');
end;

var
  HeapC,HeapS:LongInt;
  Initialized:Boolean;

procedure LogHeap(Init:Boolean);
begin
  if Init then begin
    HeapC:=AllocMemCount;
    HeapS:=AllocMemSize;
  end else begin
    if Initialized then
      Log(Format('Memory Leak Guard - Count:%d Size:%d',[AllocMemCount-HeapC,AllocMemSize-HeapS]));
  end;
  Initialized:=Init;
end;

procedure LogLE;
var
  Len:Integer;
  Buffer:array [0..255] of Char;
  LE:DWORD;
  s:string;
begin
  LE:=GetLastError;
  Len:=FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM or FORMAT_MESSAGE_ARGUMENT_ARRAY,
    NIL,LE,0,Buffer,SizeOf(Buffer),NIL);
  while (Len>0) and (Buffer[Len-1] in [#0..#32,'.']) do Dec(Len);
  SetString(s,Buffer,Len);
  LogHR(Msg+' LE:['+s+']',LE);
end;

procedure LogHR;
var
  Res:String;
begin
  if (not LogEnabled) or NoLogging then Exit;
  Res:=Format('0x%.8x',[hR]);
  case hR of
    HRESULT($00000000):Res:='S_OK';
    HRESULT($00000001):Res:='S_FALSE';
    HRESULT($80004001):Res:='E_NOTIMPL';
    HRESULT($80004002):Res:='E_NOINTERFACE';
    HRESULT($80004003):Res:='E_POINTER';
    HRESULT($80004005):Res:='E_FAIL';
    HRESULT($8000FFFF):Res:='E_UNEXPECTED';

    HRESULT($80040154):Res:='REGDB_E_CLASSNOTREG';

    HRESULT($80040200):Res:='VFW_E_INVALIDMEDIATYPE';
    HRESULT($80040201):Res:='VFW_E_INVALIDSUBTYPE';
    HRESULT($80040202):Res:='VFW_E_NEED_OWNER';
    HRESULT($80040203):Res:='VFW_E_ENUM_OUT_OF_SYNC';
    HRESULT($80040204):Res:='VFW_E_ALREADY_CONNECTED';
    HRESULT($80040205):Res:='VFW_E_FILTER_ACTIVE';
    HRESULT($80040206):Res:='VFW_E_NO_TYPES';
    HRESULT($80040207):Res:='VFW_E_NO_ACCEPTABLE_TYPES';
    HRESULT($80040208):Res:='VFW_E_INVALID_DIRECTION';
    HRESULT($80040209):Res:='VFW_E_NOT_CONNECTED';
    HRESULT($8004020A):Res:='VFW_E_NO_ALLOCATOR';
    HRESULT($8004020B):Res:='VFW_E_RUNTIME_ERROR';
    HRESULT($8004020C):Res:='VFW_E_BUFFER_NOTSET';
    HRESULT($8004020D):Res:='VFW_E_BUFFER_OVERFLOW';
    HRESULT($8004020E):Res:='VFW_E_BADALIGN';
    HRESULT($8004020F):Res:='VFW_E_ALREADY_COMMITTED';

    HRESULT($80040210):Res:='VFW_E_BUFFERS_OUTSTANDING';
    HRESULT($80040211):Res:='VFW_E_NOT_COMMITTED';
    HRESULT($80040212):Res:='VFW_E_SIZENOTSET';
    HRESULT($80040213):Res:='VFW_E_NO_CLOCK';
    HRESULT($80040214):Res:='VFW_E_NO_SINK';
    HRESULT($80040215):Res:='VFW_E_NO_INTERFACE';
    HRESULT($80040216):Res:='VFW_E_NOT_FOUND';
    HRESULT($80040217):Res:='VFW_E_CANNOT_CONNECT';
    HRESULT($80040218):Res:='VFW_E_CANNOT_RENDER';
    HRESULT($80040219):Res:='VFW_E_CHANGING_FORMAT';
    HRESULT($8004021A):Res:='VFW_E_NO_COLOR_KEY_SET';
    HRESULT($8004021B):Res:='VFW_E_NOT_OVERLAY_CONNECTION';
    HRESULT($8004021C):Res:='VFW_E_NOT_SAMPLE_CONNECTION';
    HRESULT($8004021D):Res:='VFW_E_PALETTE_SET';
    HRESULT($8004021E):Res:='VFW_E_COLOR_KEY_SET';
    HRESULT($8004021F):Res:='VFW_E_NO_COLOR_KEY_FOUND';

    HRESULT($80040220):Res:='VFW_E_NO_PALETTE_AVAILABLE';
    HRESULT($80040221):Res:='VFW_E_NO_DISPLAY_PALETTE';
    HRESULT($80040222):Res:='VFW_E_TOO_MANY_COLORS';
    HRESULT($80040223):Res:='VFW_E_STATE_CHANGED';
    HRESULT($80040224):Res:='VFW_E_NOT_STOPPED';
    HRESULT($80040225):Res:='VFW_E_NOT_PAUSED';
    HRESULT($80040226):Res:='VFW_E_NOT_RUNNING';
    HRESULT($80040227):Res:='VFW_E_WRONG_STATE';
    HRESULT($80040228):Res:='VFW_E_START_TIME_AFTER_END';
    HRESULT($80040229):Res:='VFW_E_INVALID_RECT';
    HRESULT($8004022A):Res:='VFW_E_TYPE_NOT_ACCEPTED';
    HRESULT($8004022B):Res:='VFW_E_TYPE_NOT_ACCEPTED';
    HRESULT($8004022C):Res:='VFW_E_SAMPLE_REJECTED';

    HRESULT($80070005):Res:='E_ACCESSDENIED';
    HRESULT($80070006):Res:='E_HANDLE';
    HRESULT($8007000E):Res:='E_OUTOFMEMORY';
    HRESULT($80070020):Res:='?_FILEBUSY';
    HRESULT($80070057):Res:='E_INVALIDARG';
  end;
  Log(Msg+'('+Res+')');
end;

var
  hf:LongInt;
  Buf:array [0..MAX_PATH-1] of Char;

initialization
begin
  InitializeCriticalSection(LogLock);
  GetModuleFileName(hInstance,Buf,MAX_PATH);
  LogFileName := ExtractFileName(Buf);
  LogFileName := ExtractFileDir(Application.ExeName) + '\LA.log';

  hf:=FileOpen(LogFileName,fmOpenWrite or fmShareDenyNone);
  if (hf>=0) then
  begin
    OtherGlobalVars.LogEnabled := True;    
    FileSeek(hf,0,0);
    SetEndOfFile(hf);
    FileClose(hf);

    MicroFreq:=0;
    if (QueryPerformanceFrequency(MicroFreq)=FALSE) then MicroFreq:=0;
    if (MicroFreq<1000) then MicroFreq:=0;
    if (MicroFreq>0) then
    begin
      QueryPerformanceCounter(MicroVOfs);
  //    MicroTimeOfs:=Now;
  //    MicroCoeff:=24*60*60*MicroFreq;
    end;

//    MainThread:=GetCurrentThreadID;

    LogEnabled:=TRUE;
    Log('= Session Start =');
    LogSysInfo;
    LogHeap(TRUE);
  end;
end;

finalization
begin
  if LogEnabled then begin
    LogHeap(FALSE);
    Log('= Session End =');
    LogEnabled:=FALSE;
  end;
  DeleteCriticalSection(LogLock);
end;

end.

