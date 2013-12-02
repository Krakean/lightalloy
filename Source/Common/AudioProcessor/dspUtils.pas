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
// xx.xx.12  1.0   VtX  Created                                              //
///////////////////////////////////////////////////////////////////////////////

unit dspUtils;

interface

uses
  dspConst, SysUtils;

  { Clips one integer Sample into one ShortInt. Same as using EnsureRange(), but much faster. }
  function Clip_8(Value: integer): ShortInt;
  { Clips one integer Sample into one SmallInt. Same as using EnsureRange(), but much faster. }
  function Clip_16(Value: Integer): SmallInt;
  { Clips one integer Sample into one 24Bit integer. Same as using EnsureRange(), but much faster. }
  function Clip_24(Value: Integer): Integer;
  { Clips one 64Bit integer Sample into one 32Bit Integer. Same as using EnsureRange(), but much faster. }
  function Clip_32(Value : Int64) : integer;
  { Clips one integer Sample into one WORD. Same as using EnsureRange(), but much faster. }
  function ClipWORD(Value: Integer): WORD;
  { Clips one Single Float Sample into a -1.0..1.0 Range. }
  function Clip_32F(Value : Single) : Single;

  { The Result of FFTSum is the same as when doing sqrt(sqr(real) + sqr(imag)). }
  function FFTSum(real, imag : Single) : Single;

  { This is needed to convert a 24 Bit Sample into a 32 Bit to do DSP on it. }
  function Cvt24BitTo32(Sample : T24BitSample) : integer;
  { This is used to convert a 32 Bit Sample back to 24 Bit. }
  function Cvt32BitTo24(Sample : integer) : T24BitSample;

implementation

function Cvt24BitTo32(Sample : T24BitSample) : integer;
begin
  Result := Sample.a0 + (Sample.a1 shl 8) + (Sample.a2 shl 16);
end;

function Cvt32BitTo24(Sample : integer) : T24BitSample;
begin
  Result.a0 := Sample;
  Result.a1 := Sample shr 8;
  Result.a2 := Sample shr 16;
end;

function Clip_8(Value: integer): ShortInt;
asm
        cmp       eax, 127
        jle       @@Lower
        mov       al, 127
        ret
@@Lower:
        cmp       eax, -128
        jge       @@Finished
        mov       al, -128
@@Finished:
end;

function Clip_16(Value: Integer): SmallInt;
asm
        cmp       eax, 32767
        jle       @@Lower
        mov       ax, 32767
        ret
@@Lower:
        cmp       eax, -32768
        jge       @@Finished
        mov       ax, -32768
@@Finished:
end;

function Clip_24(Value : integer) : integer;
asm
        cmp       eax, 8388607
        jle       @@Lower
        mov       eax, 8388607
        ret
@@Lower:
        cmp       eax, -8388608
        jge       @@Finished
        mov       eax, -8388608
@@Finished:
end;

function Clip_32(Value : Int64) : integer;
begin
  if Value > 2147483647 then Result := 2147483647
  else if Value < -2147483647 then Result := -2147483647
  else Result := integer(Value);
end;

function Clip_32F(Value : Single) : Single;
begin
  if Value > 1.0 then Result := 1.0
  else if Value < -1.0 then Result := -1.0
  else Result := Value;
end;

function ClipWORD(Value: Integer): WORD;
asm
        cmp       eax, 65535
        jle       @@Lower
        mov       eax, 65535
        ret
@@Lower:
        cmp       eax, 0
        jge       @@Finished
        mov       eax, 0
@@Finished:
end;

function FFTSum(real, imag : Single) : Single;
begin
  Result := sqrt(sqr(real) + sqr(imag));
end;

end.
