//-----------------------------------------------------------------------------
// File: ddutil.pas
//
// Desc: Routines for loading bitmap and palettes from resources
//
//
// Copyright (c) 1995-1999 Microsoft Corporation. All rights reserved.
//-----------------------------------------------------------------------------
// Conversion: Rolf Meyerhoff, meyerhoff@earthling.net
//-----------------------------------------------------------------------------
unit ddutil;

interface

//-----------------------------------------------------------------------------
// Include files
//-----------------------------------------------------------------------------
uses
  Windows, DirectDraw;

function DDLoadBitmap(pdd : IDirectDraw7; szBitmap : PChar; dx, dy : Integer) : IDirectDrawSurface7;
function DDReLoadBitmap(pdds : IDirectDrawSurface7; szBitmap : PChar) : HRESULT;
function DDCopyBitmap(pdds : IDirectDrawSurface7; hbm : HBITMAP; x, y, dx, dy : Integer) : HRESULT;
function DDLoadPalette(pdd : IDirectDraw7; szBitmap : PChar) : IDirectDrawPalette;
function DDColorMatch(pdds : IDirectDrawSurface7; rgb : COLORREF) : DWORD;
function DDSetColorKey(pdds : IDirectDrawSurface7; rgb : COLORREF) : HRESULT;

type
  PRGBQUAD =  ^RGBQUAD;
  PDWORD = ^DWORD;

implementation

//-----------------------------------------------------------------------------
// Name: DDLoadBitmap()
// Desc: Create a DirectDrawSurface from a bitmap resource.
//-----------------------------------------------------------------------------
function DDLoadBitmap(pdd : IDirectDraw7; szBitmap : PChar; dx, dy : Integer) : IDirectDrawSurface7;
var
  hbm : HBITMAP;
  bm : BITMAP;
  ddsd : TDDSurfaceDesc2;
  pdds : IDirectDrawSurface7;
begin
  //
  //  Try to load the bitmap as a resource, if that fails, try it as a file
  //
  hbm := LoadImage(GetModuleHandle(nil), szBitmap, IMAGE_BITMAP, dx, dy, LR_CREATEDIBSECTION);
  if hbm = 0 then
    begin
      hbm := LoadImage(0, szBitmap, IMAGE_BITMAP, dx, dy, LR_LOADFROMFILE or LR_CREATEDIBSECTION);
    end;
  if hbm = 0 then
    begin
      Result := nil;
      Exit;
    end;
  //
  // Get size of the bitmap
  //
  GetObject(hbm, SizeOf(bm), @bm);
  //
  // Create a DirectDrawSurface for this bitmap
  //
  FillChar(ddsd, SizeOf(ddsd), 0);
  ddsd.dwSize := SizeOf(ddsd);
  ddsd.dwFlags := DDSD_CAPS or DDSD_HEIGHT or DDSD_WIDTH;
  ddsd.ddsCaps.dwCaps := DDSCAPS_OFFSCREENPLAIN;
  ddsd.dwWidth := bm.bmWidth;
  ddsd.dwHeight := bm.bmHeight;
  if pdd.CreateSurface(ddsd, pdds, nil) <> DD_OK then
    begin
      Result := nil;
      Exit;
    end;
  DDCopyBitmap(pdds, hbm, 0, 0, 0, 0);
  DeleteObject(hbm);
  Result := pdds;
end;

//-----------------------------------------------------------------------------
// Name: DDReLoadBitmap()
// Desc: Load a bitmap from a file or resource into a directdraw surface.
//       normaly used to re-load a surface after a restore.
//-----------------------------------------------------------------------------
function DDReLoadBitmap(pdds : IDirectDrawSurface7; szBitmap : PChar) : HRESULT;
var
  hbm : HBITMAP;
  hr : HRESULT;
begin
  //
  //  Try to load the bitmap as a resource, if that fails, try it as a file
  //
  hbm := LoadImage(GetModuleHandle(nil), szBitmap, IMAGE_BITMAP, 0, 0, LR_CREATEDIBSECTION);
  if hbm = 0 then
    begin
      hbm := LoadImage(0, szBitmap, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_CREATEDIBSECTION);
    end;
  if hbm = 0 then
    begin
      OutputDebugString('handle is null');
      Result := E_FAIL;
      Exit;
    end;
  hr := DDCopyBitmap(pdds, hbm, 0, 0, 0, 0);
  if hr <> DD_OK then
    begin
      OutputDebugString('ddcopybitmap failed');
      Result := hr;
      Exit;
    end;
  DeleteObject(hbm);
  Result := hr;
end;

//-----------------------------------------------------------------------------
// Name: DDCopyBitmap()
// Desc: Draw a bitmap into a DirectDrawSurface
//-----------------------------------------------------------------------------
function DDCopyBitmap(pdds : IDirectDrawSurface7; hbm : HBITMAP; x, y, dx, dy : Integer) : HRESULT;
var
 hdcImage : HDC;
 h_dc : HDC;
 bm : BITMAP;
 ddsd : TDDSurfaceDesc2;
 hr : HRESULT;
begin
  if (hbm = 0) or (pdds = nil) then
    begin
      Result := E_FAIL;
      Exit;
    end;
  //
  // Make sure this surface is restored.
  //
  pdds._Restore;
  //
  // Select bitmap into a memoryDC so we can use it.
  //
  hdcImage := CreateCompatibleDC(0);
  if hdcImage = 0 then
    begin
      OutputDebugString('createcompatible dc failed');
    end;
  SelectObject(hdcImage, hbm);
  //
  // Get size of the bitmap
  //
  GetObject(hbm, sizeof(bm), @bm);
  if dx = 0 then                      // Use the passed size, unless zero
    begin
      dx := bm.bmWidth;
    end;
  if dy = 0 then
    begin
      dy := bm.bmHeight;
    end;
  //
  // Get size of surface.
  //
  ddsd.dwSize := SizeOf(ddsd);
  ddsd.dwFlags := DDSD_HEIGHT or DDSD_WIDTH;
  pdds.GetSurfaceDesc(ddsd);

  hr := pdds.GetDC(h_dc);
  if hr = DD_OK then
    begin
      StretchBlt(h_dc, 0, 0, ddsd.dwWidth, ddsd.dwHeight, hdcImage, x, y, dx, dy, SRCCOPY);
      pdds.ReleaseDC(h_dc);
    end;
  DeleteDC(hdcImage);
  Result := hr;
end;

//-----------------------------------------------------------------------------
// Name: DDLoadPalette()
// Desc: Create a DirectDraw palette object from a bitmap resource
//       if the resource does not exist or NULL is passed create a
//       default 332 palette.
//-----------------------------------------------------------------------------
function DDLoadPalette(pdd : IDirectDraw7; szBitmap : PChar) : IDirectDrawPalette;
var
  ddpal : IDirectDrawPalette;
  i : Integer;
  n : Integer;
  fh : Integer;
  h : HRSRC;
  lpbi : ^BITMAPINFOHEADER;
  ape : array[0..255] of PALETTEENTRY;
  prgb : PRGBQUAD;
  bf : BITMAPFILEHEADER;
  bi : BITMAPINFOHEADER;
  r : Byte;
begin
  //
  // Build a 332 palette as the default.
  //
  for i := 0 to 255 do
    begin
      ape[i].peRed := ((i shr 5) and $07) * 255 div 7;
      ape[i].peGreen := ((i shr 2) and $07) * 255 div 7;
      ape[i].peBlue := ((i shr 0) and $03) * 255 div 3;
      ape[i].peFlags := 0;
    end;
  //
  // Get a pointer to the bitmap resource.
  //
  h := FindResource(0, szBitmap, RT_BITMAP);
  if (szBitmap <> nil) and (h <> 0) then
    begin
      lpbi := LockResource(LoadResource(0, h));
      if lpbi = nil then
        OutputDebugString('lock resource failed');
      inc(lpbi, lpbi^.biSize);
      prgb := PRGBQUAD(lpbi);
      if (lpbi = nil) or (lpbi^.biSize < SizeOf(BITMAPINFOHEADER)) then
        n := 0
      else if lpbi^.biBitCount > 8 then
        n := 0
      else if lpbi^.biClrUsed = 0 then
        n := 1 shl lpbi^.biBitCount
      else
        n := lpbi^.biClrUsed;
      //
      //  A DIB color table has its colors stored BGR not RGB
      //  so flip them around.
      //
      for i := 0 to n-1 do
        begin
          ape[i].peRed := prgb^.rgbRed;
          ape[i].peGreen := prgb^.rgbGreen;
          ape[i].peBlue := prgb^.rgbBlue;
          ape[i].peFlags := 0;
          inc(prgb);
        end;
    end
  else
    begin
      fh := _lopen(szBitmap, OF_READ);
      if (szBitmap <> nil) and (fh <> -1) then
        begin
          _lread(fh, @bf, SizeOf(bf));
          _lread(fh, @bi, SizeOf(bi));
          _lread(fh, @ape[0], SizeOf(ape));
          _lclose(fh);
          if bi.biSize <> SizeOf(BITMAPINFOHEADER) then
            n := 0
          else if bi.biBitCount > 8 then
            n := 0
          else if bi.biClrUsed = 0 then
            n := 1 shl bi.biBitCount
          else
            n := bi.biClrUsed;
          //
          //  A DIB color table has its colors stored BGR not RGB
          //  so flip them around.
          //
          for i := 0 to n - 1 do
            begin
            r := ape[i].peRed;
            ape[i].peRed := ape[i].peBlue;
            ape[i].peBlue := r;
            end;
        end;
    end;
  pdd.CreatePalette(DDPCAPS_8BIT, @ape[0], ddpal, nil);
  Result := ddpal;
end;

//-----------------------------------------------------------------------------
// Name: DDColorMatch()
// Desc: Convert a RGB color to a pysical color.
//       We do this by leting GDI SetPixel() do the color matching
//       then we lock the memory and see what it got mapped to.
//-----------------------------------------------------------------------------
function DDColorMatch(pdds : IDirectDrawSurface7; rgb : COLORREF) : DWORD;
var
  rgbT : COLORREF;
  h_dc : HDC;
  dw : DWORD;
  ddsd : TDDSurfaceDesc2;
  hres : HRESULT;
begin
  dw := CLR_INVALID;
  rgbT := 0;
  //
  //  Use GDI SetPixel to color match for us
  //
  if (rgb <> CLR_INVALID) and (pdds.GetDC(h_dc) = DD_OK) then
    begin
      rgbT := GetPixel(h_dc, 0, 0);     // Save current pixel value
      SetPixel(h_dc, 0, 0, rgb);       // Set our value
      pdds.ReleaseDC(h_dc);
    end;
  //
  // Now lock the surface so we can read back the converted color
  //
  ddsd.dwSize := SizeOf(ddsd);
  hres := pdds.Lock(nil, ddsd, 0, 0);
  while hres = DDERR_WASSTILLDRAWING do
    begin
      hres := pdds.Lock(nil, ddsd, 0, 0);
    end;
  if hres = DD_OK then
    begin
      dw := PDWORD(ddsd.lpSurface)^;                 // Get DWORD
      if ddsd.ddpfPixelFormat.dwRGBBitCount < 32 then
        dw := dw and ((1 shl ddsd.ddpfPixelFormat.dwRGBBitCount) - 1);  // Mask it to bpp
      pdds.Unlock(nil);
    end;
  //
  //  Now put the color that was there back.
  //
  if (rgb <> CLR_INVALID) and (pdds.GetDC(h_dc) = DD_OK) then
    begin
      SetPixel(h_dc, 0, 0, rgbT);
      pdds.ReleaseDC(h_dc);
    end;
  Result := dw;
end;

//-----------------------------------------------------------------------------
// Name: DDSetColorKey()
// Desc: Set a color key for a surface, given a RGB.
//       If you pass CLR_INVALID as the color key, the pixel
//       in the upper-left corner will be used.
//-----------------------------------------------------------------------------
function DDSetColorKey(pdds : IDirectDrawSurface7; rgb : COLORREF) : HRESULT;
var
  ddck : TDDColorKey;
begin
  ddck.dwColorSpaceLowValue := DDColorMatch(pdds, rgb);
  ddck.dwColorSpaceHighValue := ddck.dwColorSpaceLowValue;
  Result := pdds.SetColorKey(DDCKEY_SRCBLT, @ddck);
end;

end.
