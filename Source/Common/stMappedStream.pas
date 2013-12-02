///////////////////////////////////////////////////////////////////////////////
// Light Alloy                           Copyright(c) 2006-2013, Vortex Team //
//---------------------------------------------------------------------------//
// Filename                                                                  //
// Description.                                                              //
// ---------------                                                           //
// Author : Flash                                                            //
// E-mail : flash.afs@gmail.com                                              //
// WWW    : http://light-alloy.ru                                            //
//---------------------------------------------------------------------------//
//   Date    Ver   Who  Comment                                              //
// --------  ---   ---  -------                                              //
// xx.xx.07  1.0   VtX  Created                                              //
///////////////////////////////////////////////////////////////////////////////

unit stMappedStream;

// -----------------------------------------------------------------------------

interface

uses
  Classes, Windows;

type
  TMappedStream = class(TMemoryStream)
  private
  public
    function GetByte(Pos: System.Int64): Byte;
    function GetWord(Pos: System.Int64): Word;
    function GetDWORD(Pos: System.Int64): DWORD;
  end;

// -----------------------------------------------------------------------------

implementation

// -----------------------------------------------------------------------------

{ TMappedStream }

function TMappedStream.GetByte(Pos: Int64): Byte;
begin
  Result:=0;
  Self.Seek(Pos,soBeginning);
  Self.Read(Result,SizeOf(Byte));
end;

function TMappedStream.GetWord(Pos: Int64): Word;
begin
  Result:=0;
  Self.Seek(Pos,soBeginning);
  Self.Read(Result,SizeOf(Word));
end;

function TMappedStream.GetDWORD(Pos: Int64): DWORD;
begin
  Result:=0;
  Self.Seek(Pos,soBeginning);
  Self.Read(Result,SizeOf(DWORD));
end;

initialization

finalization

end.
