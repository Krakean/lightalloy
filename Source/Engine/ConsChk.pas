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

unit ConsChk;

interface

uses
  Windows, Classes, CRC32, SysUtils, MainUnit, CmdC;

type
  TConsistencyChecker = class(TObject)
  private
    Sums:array of DWORD;
    FS:TFileStream;
    ResCRC:DWORD;
  public
    Idx:LongInt;

    constructor Create;
    destructor Destroy; override;

    procedure Tick;
    procedure Load(Index:Longint);
  end;

implementation

uses
  LACore;

constructor TConsistencyChecker.Create;
begin
  inherited Create;
  FS:=TFileStream.Create(Core.ExeName,fmOpenRead or fmShareDenyWrite);
  Idx:=0;
  SetLength(Sums,(FS.Size+4095) div 4096);
  ResCRC:=DWORD(@Core);
end;

destructor TConsistencyChecker.Destroy;
begin
  FS.Free;
  inherited Destroy;
end;

procedure TConsistencyChecker.Load(Index: Integer);
var
  Cnt:LongInt;
  MS:TMemoryStream;
  CRC32:TCRC32;
  Sz:LongInt;
begin
  Cnt:=Length(Sums) div 8;
  if (Index=7) then Cnt:=Cnt*2;

  while (Cnt>0) and (Idx<Length(Sums)) do begin
    Sz:=FS.Size-FS.Position;
    if (Sz>4096) then Sz:=4096;

    MS:=TMemoryStream.Create;
    MS.CopyFrom(FS,Sz);

    CRC32:=TCRC32.Create;
    CRC32.UpdateWithStream(MS);
    Sums[Idx]:=CRC32.Result;
    CRC32.Free;

    MS.Free;
    Dec(Cnt);
    Inc(Idx);
  end;

  if (FS.Position=FS.Size) then Idx:=999;
end;

procedure TConsistencyChecker.Tick;
var
  CRC32:TCRC32;
begin
  case Idx of
    999:begin
      CRC32:=TCRC32.Create;
      CRC32.UpdateWithBuffer(@Sums[0],Length(Sums)*4);
      ResCRC:=CRC32.Result;
      CRC32.Free;

      Inc(Idx);
    end;
    1000:begin
      PostMessage(frMain.Handle,WM_LACMD,Idx+1,ResCRC);
    end;
  end;
end;

end.
