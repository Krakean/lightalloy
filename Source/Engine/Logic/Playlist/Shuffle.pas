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

unit Shuffle;

// -----------------------------------------------------------------------------

interface

uses
   Classes, SysUtils;

type

  sfShuffle = class
  private
    { Private declarations }
    IList:    array of integer;
    VirtList: array of integer;
    LastRange: integer;

  public
    { Public declarations }
    Excluded: array of boolean;
    ECurrent: integer;

    constructor Create(Number: Integer);
    destructor Destroy; override;

    procedure Change(Range: Integer);
    procedure Shape(Range:Integer);
    function Next(Range: Integer): Integer;
    function Prev(Range: Integer): Integer;
  end;

// -----------------------------------------------------------------------------

implementation

// -----------------------------------------------------------------------------

constructor sfShuffle.Create(Number: Integer);
begin
  SetLength(IList,Number+1);
  SetLength(VirtList,Number+1);
  SetLength(Excluded,Number+1);
  ECurrent := -1;
  LastRange := Number;
  Shape(Number);
end;

// -----------------------------------------------------------------------------

destructor sfShuffle.Destroy;
begin
  inherited;
end;

// -----------------------------------------------------------------------------

procedure sfShuffle.Change(Range: integer);
begin
  SetLength(IList,Range+1);
  SetLength(VirtList,Range+1);
  SetLength(Excluded,Range+1);
  ECurrent := 0;
  LastRange := Range;
  Shape(Range);
end;

// -----------------------------------------------------------------------------

procedure sfShuffle.Shape(Range: integer);
var i, r, k: integer;

 procedure EFilter(Cap: integer);
  var i: integer;
  begin
    k:=0;
    for i:=0 to Cap do begin
      if Excluded[i]=false then begin
        IList[k] := i;
        inc(k);
      end;
    end;
  end;
begin
  Randomize;

  for i:=0 to Range do begin
    IList[i]:= -1;
    VirtList[i]:=  -1;
    Excluded[i]:=false;
  end;

  for i:=0 to Range-1 do  begin
    EFilter(Range-1);
    r:=Random(k);
    VirtList[i]:=IList[r];
    Excluded[IList[r]]:=true;
  end;
end;

// -----------------------------------------------------------------------------

function sfShuffle.Next(Range: Integer): Integer;
begin
  try
    inc(ECurrent);
  except
    on EInvalidPointer do begin
      ECurrent := 0;
      LastRange := Range;
      Change(Range);
    end;
  end;

  if (ECurrent > Range-1)or(LastRange <> Range) then begin
    ECurrent := 0;
    LastRange := Range;
    Change(Range);
  end;

  Result:=VirtList[ECurrent];
end;

// -----------------------------------------------------------------------------

function sfShuffle.Prev(Range: Integer): Integer;
begin
  dec(ECurrent);
  if (ECurrent < 0)or(LastRange <> Range) then begin
    ECurrent := 0;
    LastRange := Range;
    Change(Range);
  end;

  Result := VirtList[ECurrent];
end;

end.
