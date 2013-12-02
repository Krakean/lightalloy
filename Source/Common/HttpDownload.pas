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

unit HttpDownload;

// -----------------------------------------------------------------------------

interface

uses
  Classes;

function inetDL(Url:string; var Stream: TStream; FixedLen:Cardinal = 0):Boolean;

// -----------------------------------------------------------------------------

implementation

// -----------------------------------------------------------------------------

uses
  // VCL
  Windows, SysUtils, WinInet,
  // Core
  LACore, OtherGlobalVars;

// -----------------------------------------------------------------------------
  
function GetHTTPSession: HInternet;
var
  AgentName : String;
begin
  AgentName := 'Light Alloy';

  Result := InternetOpen(PChar(AgentName), INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
end;

// -----------------------------------------------------------------------------

procedure CloseHTTPHandle(var Handle: HInternet);
begin
  WinInet.InternetCloseHandle(Handle);
end;

// -----------------------------------------------------------------------------

function GetHttpUrl(Url: String; hSession: HInternet): HInternet;
begin
  Result := InternetOpenURL(hSession, PChar(URL), nil, 0, INTERNET_FLAG_PRAGMA_NOCACHE or INTERNET_FLAG_RELOAD, 0);
end;

// -----------------------------------------------------------------------------

function GetHTTP_Size(URL:HINTERNET): DWORD;
var
  _len   : DWORD;
  _idx   : DWORD;
  dwcode : DWORD;
begin
  _idx:=0;
  _len:=4;
  dwcode:=0;
  if HttpQueryInfo(URL, HTTP_QUERY_CONTENT_LENGTH or HTTP_QUERY_FLAG_NUMBER,
    @dwcode, _len, _idx)
  then
    Result := dwcode
  else
    Result:=0;
end;

// -----------------------------------------------------------------------------

function HTTPDownloadUrlToStream(URL: HINTERNET; Stream: TStream; srcUrl:
  string = ''; FixedLen:Cardinal = 0): Boolean;
const BufferSize=1024;
var
  Buffer:array[1..BufferSize] of Byte;
  BufferLen:DWORD;
  LoadedBytes:DWORD;
  sz:DWORD;
  CW:DWORD;
  Cnt:Integer;
begin
  CW := Get8087CW;
  Set8087CW($133f);
  Result:=False;
  LoadedBytes:=0;
  DownloadProgress:=0;
  Cnt:=0;

  if not Assigned(URL) then Exit;
  sz := GetHTTP_Size(URL);
  if sz = 0 then Exit;
  if Trim(srcUrl) = '' then srcUrl:='...';

  try
    repeat
      // Only for filters downloading, not for autoupdate.xml / filterbase.xml
      if IsDownloading then
        Core.Info('Download '+DownloadFilter+#13#10+MS('Info.Dowloading')+
        ': '+DownloadFilename+' ['+IntToStr(DownloadProgress)+'%]');

      if Cnt>0 then
        Dec(Cnt)
      else begin
        Cnt:=60;
        Core.SysHlp.ProcessMsgs;
      end;

      if InternetReadFile(URL, @Buffer, SizeOf(Buffer), BufferLen) then begin
        Stream.WriteBuffer(Buffer, BufferLen);
        LoadedBytes:=LoadedBytes + BufferLen;
        DownloadProgress:=Trunc(100 / sz  *LoadedBytes);
      end;
    until (BufferLen = 0) or ((FixedLen>0) and (LoadedBytes>=FixedLen));
    if (LoadedBytes = sz) or ((FixedLen>0) and (LoadedBytes>0)) then
      Result:=True;
  finally
    DownloadProgress:=0;
  end;
  Set8087CW(CW);
end;

// -----------------------------------------------------------------------------

function inetDL(Url:string; var Stream: TStream; FixedLen:Cardinal = 0): Boolean;
var
  hSession,
  hUrl : HINTERNET;
begin
  Result := False;

  hSession := GetHTTPSession;
  if Assigned(hSession) then
  begin
    hUrl := GetHttpUrl(Url, hSession);
    if Assigned(hUrl) then
    begin
      Result := HTTPDownloadUrlToStream(hUrl, Stream, Url, FixedLen);
      if Result then
        SessionFails := False;
      CloseHTTPHandle(hUrl);
    end
    else begin
      SessionFails := True;
    end;
    CloseHTTPHandle(hSession);
  end;
end;

// -----------------------------------------------------------------------------
end.

