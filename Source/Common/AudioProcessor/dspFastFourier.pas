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

unit dspFastFourier;

interface

uses
  Math, Classes, dspConst, SysUtils;

type
  TFFT = class
  private
    fCplx : PComplexArray;
    fFFTSize : TFFTSize;
    procedure SetFFTSize(const Value: TFFTSize);
  public
    constructor Create;
    destructor Destroy; override;
    procedure FFT;
    procedure IFFT;
    property Complex: PComplexArray read fCplx write fCplx;
    procedure Flush;
    property FFTSize: TFFTSize read fFFTSize write SetFFTSize;
  end;

implementation

procedure doFFT(a: PComplexArray; n: Integer; Inverse: Boolean = False);
var
  i, j, k, l, l1: Integer;
  c1, c2, tx, ty, t1, t2, u1, u2, z: Single;
begin
  { Do the bit reversal }
  j := 0;
  for i := 0 to n - 2 do
  begin
    if (i < j) then
    begin
      tx := a[i].re;
      ty := a[i].im;
      a[i].re := a[j].re;
      a[i].im := a[j].im;
      a[j].re := tx;
      a[j].im := ty;
    end;
    k := n div 2;
    while (k <= j) do
    begin
      j := j - k;
      k := k div 2;
    end;
    j := j + k;
  end;

  { Compute the FFT }
  c1 := -1.0;
  c2 := 0.0;
  l1 := 1;
  for l := 0 to Trunc(Log2(n)) - 1 do
  begin
    u1 := 1.0;
    u2 := 0.0;
    for j := 0 to l1 - 1 do
    begin
      i := j;
      while i < n do
      begin
        t1 := u1 * a[i + l1].re - u2 * a[i + l1].im;
        t2 := u1 * a[i + l1].im + u2 * a[i + l1].re;
        a[i + l1].re := a[i].re - t1;
        a[i + l1].im := a[i].im - t2;
        a[i].re := a[i].re + t1;
        a[i].im := a[i].im + t2;
        i := i + l1 * 2;
      end;
      z :=  u1 * c1 - u2 * c2;
      u2 := u1 * c2 + u2 * c1;
      u1 := z;
    end;
    c2 := sqrt((1.0 - c1) / 2.0);
    if not Inverse then
      c2 := -c2;
    c1 := sqrt((1.0 + c1) / 2.0);
    l1 := l1 * 2;
  end;

  { Scaling after forward transform }
  if Inverse then
    for i := 0 to n - 1 do
    begin
      a[i].re := a[i].re / n;
      a[i].im := a[i].im / n;
    end;
end;

{ TFFT }

constructor TFFT.Create;
begin
end;

destructor TFFT.Destroy;
begin
  FreeMemory(fCplx);
  inherited Destroy;
end;

procedure TFFT.SetFFTSize(const Value: TFFTSize);
begin
  fFFTSize := Value;

  if fCplx = nil then
    FreeMemory(fCplx);
  fCplx := AllocMem((1 shl (integer(fFFTSize) + 1)) * SizeOf(TComplex));
end;

procedure TFFT.FFT;
begin
  doFFT(fCplx, 1 shl (integer(fFFTSize) + 1));
end;

procedure TFFT.IFFT;
begin
  doFFT(fCplx, 1 shl (integer(fFFTSize) + 1), True);
end;

procedure TFFT.Flush;
begin
  FillChar(fCplx^, 1 shl (integer(fFFTSize) + 1) * SizeOf(TComplex), 0);
end;

end.

