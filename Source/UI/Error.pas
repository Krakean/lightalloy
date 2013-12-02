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
unit Error;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, Buttons, Registry, MultiLog;

type
  TfrError = class(TForm)
    imSign: TImage;
    mmDescr: TMemo;
    lbTitle: TLabel;
    sbCopy: TSpeedButton;
    btHalt: TButton;
    procedure sbCopyClick(Sender: TObject);
    procedure btHaltClick(Sender: TObject);
  public
    procedure ShowError(Msg:string);
    function SysInfo:string;
  end;

var
  frError: TfrError;

implementation

uses
  LACore;

{$R *.DFM}

procedure TfrError.sbCopyClick(Sender: TObject);
begin
  mmDescr.SelectAll;
  mmDescr.CopyToClipboard;
  mmDescr.SelLength:=0;
end;

procedure TfrError.btHaltClick(Sender: TObject);
begin
  Halt;
end;

procedure TfrError.ShowError;
begin
  Caption:=MS('Error.AppError');
  lbTitle.Caption:=MS('Error.BugReport');
  mmDescr.Clear;
  mmDescr.Lines.Add('Light Alloy '+Core.AppVersion);
  mmDescr.Lines.Add(Msg);
  mmDescr.Lines.Add(GetLogHistory);
  mmDescr.Lines.Add(SysInfo);
  ShowModal;
end;

function TfrError.SysInfo;
var
  sver,s:string;
  R:TRegistry;
  OsVersionInfo:TOSVERSIONINFO;
  WinDir:array [0..MAX_PATH-1] of Char;

  function IsVer(PlatfID,Maj,Min:DWORD):boolean;
  begin
    Result:=(OSVersionInfo.dwPlatformID=PlatfID) and
            (OSVersionInfo.dwMajorVersion=Maj) and
            (OSVersionInfo.dwMinorVersion=Min);
  end;
begin
  Result:='';
  OSVersionInfo.dwOSVersionInfoSize:=SizeOf(OSVersionInfo);
  if GetVersionEx(OSVersionInfo) then
    begin
    s:=IntToStr(OSVersionInfo.dwPlatformID);
    if (OSVersionInfo.dwPlatformID=VER_PLATFORM_WIN32s) then s:='WIN32s';
    if (OSVersionInfo.dwPlatformID=VER_PLATFORM_WIN32_WINDOWS) then s:='9x';
    if (OSVersionInfo.dwPlatformID=VER_PLATFORM_WIN32_NT) then s:='NT';

    sver:='';
    if IsVer(VER_PLATFORM_WIN32_WINDOWS,4,10) then sver:='98';
    if IsVer(VER_PLATFORM_WIN32_WINDOWS,4,90) then sver:='ME';
    if IsVer(VER_PLATFORM_WIN32_NT,4,0) then sver:='NT';
    if IsVer(VER_PLATFORM_WIN32_NT,5,0) then sver:='2K';
    if IsVer(VER_PLATFORM_WIN32_NT,5,1) then sver:='XP';

    Result:=Result+Format('Windows %s [%s] %d.%d build %.8x (%s) ',
      [sver,s,OSVersionInfo.dwMajorVersion,
              OSVersionInfo.dwMinorVersion,
              OSVersionInfo.dwBuildNumber,
              OSVersionInfo.szCSDversion]);
    end;
  R:=TRegistry.Create;
  try
    R.RootKey:=HKEY_LOCAL_MACHINE;
    if R.OpenKeyReadOnly('\Software\Microsoft\DirectX') then
      Result:=Result+#13#10+'DirectX '+R.ReadString('Version');
  except
  end;
  R.Free;

  GetWindowsDirectory(WinDir,MAX_PATH);
  Result:=Result+#13#10+'WinDir: '+WinDir;
end;

end.

