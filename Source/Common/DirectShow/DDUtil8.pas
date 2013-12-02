//-----------------------------------------------------------------------------
// File: ddutil.cpp
//
// Desc: Routines for loading bitmap and palettes from resources
//
// Copyright (C) 1998-1999 Microsoft Corporation. All Rights Reserved.
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// File: ddutil.cpp
//
// Desc: DirectDraw framewark classes. Feel free to use this class as a
//       starting point for adding extra functionality.
//
//
// Copyright (c) 1995-1999 Microsoft Corporation. All rights reserved.
//-----------------------------------------------------------------------------

unit DDUtil8;

interface

uses
  Windows, DirectDraw;

//-----------------------------------------------------------------------------
// Flags for the CDisplay and CSurface methods
//-----------------------------------------------------------------------------
const
  DSURFACELOCK_READ  = 0;
  DSURFACELOCK_WRITE = 0;

procedure SAFE_RELEASE( p : IDIRECTDRAWSURFACE7);

//-----------------------------------------------------------------------------
// Name: class CDisplay
// Desc: Class to handle all DDraw aspects of a display, including creation of
//       front and back buffers, creating offscreen surfaces and palettes,
//       and blitting surface and displaying bitmaps.
//-----------------------------------------------------------------------------
type
   CSurface = class;
   CDisplay = class
   protected
    m_pDD                : IDIRECTDRAW7;
    m_pddsFrontBuffer    : IDIRECTDRAWSURFACE7 ;
    m_pddsBackBuffer     : IDIRECTDRAWSURFACE7;
    m_pddsBackBufferLeft : IDIRECTDRAWSURFACE7; // For stereo modes

    m_hWnd               : HWND;
    m_rcWindow           : TRECT;
    m_bWindowed          : BOOL;
    m_bStereo            : BOOL;

    constructor Create;
   public
    destructor Destroy; override;
    // Access functions
    function GetHWnd        : HWND;                   { return m_hWnd; }
    function GetDirectDraw  : IDIRECTDRAW7;           { return m_pDD; }
    function GetFrontBuffer : IDIRECTDRAWSURFACE7;    { return m_pddsFrontBuffer; }
    function GetBackBuffer  : IDIRECTDRAWSURFACE7;    { return m_pddsBackBuffer; }
    function GetBackBufferLEft : IDIRECTDRAWSURFACE7; { return m_pddsBackBufferLeft; }

    // Status functions
    function IsWindowed : BOOL;              { return m_bWindowed; }
    function IsStereo   : BOOL;              { return m_bStereo; }

    // Creation/destruction methods
    function CreateFullScreenDisplay ( const hWnd : HWND;
                                      const dwWidth, dwHeight, dwBPP : DWORD ) : HRESULT;
    function CreateWindowedDisplay ( const hWnd : HWND; const dwWidth, dwHeight : DWORD ) : HRESULT;
    function InitClipper : HRESULT;
    function UpdateBounds : HRESULT;
    function DestroyObjects : HRESULT; virtual;

    // Methods to create child objects
    function CreateSurface( out ppSurface : CSurface;
                            const dwWidth, dwHeight : DWORD ) : HRESULT;
    function CreateSurfaceFromBitmap( out ppSurface : CSurface;
                                      const strBMP : PCHAR;
                                      const dwDesiredWidth, dwDesiredHeight : DWORD ) : HRESULT;
    function CreateSurfaceFromText( out ppSurface : CSurface;
                                    hFont : HFONT; const strText : PCHAR;
				    const crBackground, crForeground : COLORREF ) : HRESULT;
    function CreatePaletteFromBitmap( out ppPalette : IDIRECTDRAWPALETTE; const strBMP : PCHAR ) : HRESULT;

    // Display methods
    function Clear( const dwColor : DWORD {= 0L} ) : HRESULT;
    function ColorKeyBlt( const x, y : DWORD; const pdds : IDIRECTDRAWSURFACE7;
                          const prc : PRECT  {= NULL} ) : HRESULT;
    function Blt( const x, y : DWORD; const pdds : IDIRECTDRAWSURFACE7;
		  const prc : PRECT; const dwFlags : DWORD {=0} ) : HRESULT; overload;
    function Blt( const x, y : DWORD; const pSurface : CSurface; const prc : PRECT  {= NULL} ) : HRESULT; overload;
    function ShowBitmap( const hbm : HBITMAP; const pPalette : IDIRECTDRAWPALETTE {=NULL} ) : HRESULT;
    function SetPalette( const pPalette : IDIRECTDRAWPALETTE ) : HRESULT;
    function Present : HRESULT;
  end;

//-----------------------------------------------------------------------------
// Name: class CSurface
// Desc: Class to handle aspects of a DirectDrawSurface.
//-----------------------------------------------------------------------------
   CSurface = class
    m_pdds           : IDIRECTDRAWSURFACE7;
    m_ddsd           : TDDSURFACEDESC2;
    m_bColorKeyed    : BOOL;
   public
    function GetDDrawSurface : IDIRECTDRAWSURFACE7; { return m_pdds; }
    function IsColorKeyed : BOOL;                   { return m_bColorKeyed; }

    function DrawBitmap( const hBMP : HBITMAP; const dwBMPOriginX, {= 0} dwBMPOriginY : DWORD; {= 0}
		         dwBMPWidth, {= 0} dwBMPHeight : DWORD {= 0} ) : HRESULT; overload;
    function DrawBitmap( const strBMP : PCHAR; const dwDesiredWidth, dwDesiredHeight : DWORD ) : HRESULT; overload;
    function DrawText( hFont : HFONT; const strText : PCHAR; const dwOriginX, dwOriginY : DWORD;
	               const crBackground, crForeground : COLORREF) : HRESULT;

    function SetColorKey( const dwColorKey : DWORD ) : HRESULT;
    function ConvertGDIColor( const dwGDIColor : COLORREF ) : DWORD;
    function GetBitMaskInfo( dwBitMask : DWORD; var pdwShift, pdwBits : DWORD) : HRESULT;

    function Create( const pDD : IDIRECTDRAW7; const pddsd : TDDSURFACEDESC2 ) : HRESULT; overload;
    function Create( const pdds : IDIRECTDRAWSURFACE7 ) : HRESULT; overload;
    destructor Destroy; override;
  end;

implementation

procedure SAFE_RELEASE( p : IDIRECTDRAWSURFACE7);
begin
  if Assigned ( p ) then begin
     p._Release;
     p := nil;
  end;
end;

function GetWindowStyle (wnd : HWND) : DWORD;
begin
  Result := GetWindowLong(wnd, GWL_STYLE);
end;

function GetWindowExStyle (wnd : HWND) : DWORD;
begin
  Result := GetWindowLong(wnd, GWL_EXSTYLE)
end;

function CDisplay.GetHWnd        : HWND;
begin
  Result := m_hWnd;
end;

function CDisplay.GetDirectDraw  : IDIRECTDRAW7;
begin
  Result := m_pDD;
end;

function CDisplay.GetFrontBuffer : IDIRECTDRAWSURFACE7;
begin
  Result := m_pddsFrontBuffer;
end;

function CDisplay.GetBackBuffer  : IDIRECTDRAWSURFACE7;
begin
  Result := m_pddsBackBuffer;
end;

function CDisplay.GetBackBufferLEft : IDIRECTDRAWSURFACE7;
begin
  Result := m_pddsBackBufferLeft;
end;

function CDisplay.IsWindowed : BOOL;
begin
  Result := m_bWindowed;
end;

function CDisplay.IsStereo   : BOOL;
begin
  Result := m_bStereo;
end;

//-----------------------------------------------------------------------------
// Name: CDisplay()
// Desc:
//-----------------------------------------------------------------------------
constructor CDisplay.Create;
begin
    inherited;
    m_pDD                := nil;
    m_pddsFrontBuffer    := nil;
    m_pddsBackBuffer     := nil;
    m_pddsBackBufferLeft := nil;
end;

//-----------------------------------------------------------------------------
// Name: ~CDisplay()
// Desc:
//-----------------------------------------------------------------------------
destructor CDisplay.Destroy;
begin
    DestroyObjects;
    inherited;
end;

//-----------------------------------------------------------------------------
// Name: DestroyObjects()
// Desc:
//-----------------------------------------------------------------------------
function CDisplay.DestroyObjects : HRESULT;
begin
    SAFE_RELEASE( m_pddsBackBufferLeft );
    SAFE_RELEASE( m_pddsBackBuffer );
    SAFE_RELEASE( m_pddsFrontBuffer );

    if Assigned ( m_pDD ) then
        m_pDD.SetCooperativeLevel( m_hWnd, DDSCL_NORMAL );

    if Assigned ( m_pDD ) then begin
       m_pDD._Release;
       m_pDD := nil;
    end;

    Result := S_OK;
end;

//-----------------------------------------------------------------------------
// Name: CreateFullScreenDisplay()
// Desc:
//-----------------------------------------------------------------------------
function CDisplay.CreateFullScreenDisplay ( const hWnd : HWND;
                                            const dwWidth, dwHeight, dwBPP : DWORD) : HRESULT;
var
    hr : HRESULT;
    ddsd : TDDSURFACEDESC2;
    ddscaps : TDDSCAPS2;
begin
    // Cleanup anything from a previous call
    DestroyObjects;

    // DDraw stuff begins here
    hr := DirectDrawCreateEx( nil, m_pDD, IID_IDirectDraw7, nil );
    if( FAILED( hr ) ) then begin
        Result := E_FAIL;
        Exit;
    end;

    // Set cooperative level
    hr := m_pDD.SetCooperativeLevel( hWnd, DDSCL_EXCLUSIVE or DDSCL_FULLSCREEN );
    if( FAILED(hr) ) then begin
        Result := E_FAIL;
        Exit;
    end;

    // Set the display mode
    if( FAILED( m_pDD.SetDisplayMode( dwWidth, dwHeight, dwBPP, 0, 0 ) ) )
        then begin
        Result := E_FAIL;
        Exit;
    end;

    // Create primary surface (with backbuffer attached)
    ZeroMemory( @ddsd, sizeof( ddsd ) );
    ddsd.dwSize            := sizeof( ddsd );
    ddsd.dwFlags           := DDSD_CAPS or DDSD_BACKBUFFERCOUNT;
    ddsd.ddsCaps.dwCaps    := DDSCAPS_PRIMARYSURFACE or DDSCAPS_FLIP or
                             DDSCAPS_COMPLEX or DDSCAPS_3DDEVICE;
    ddsd.dwBackBufferCount := 1;

    hr := m_pDD.CreateSurface( ddsd, m_pddsFrontBuffer, nil );
    if( FAILED( hr ) ) then begin
        Result := E_FAIL;
        Exit;
    end;

    // Get a pointer to the back buffer
    ZeroMemory( @ddscaps, sizeof( ddscaps ) );
    ddscaps.dwCaps := DDSCAPS_BACKBUFFER;

    hr := m_pddsFrontBuffer.GetAttachedSurface( ddscaps, m_pddsBackBuffer );
    if ( FAILED( hr ) ) then begin
        Result := E_FAIL;
        Exit;
    end;

    m_pddsBackBuffer._AddRef;

    m_hWnd      := hWnd;
    m_bWindowed := FALSE;
    UpdateBounds;

    Result := S_OK;
end;

//-----------------------------------------------------------------------------
// Name: CreateWindowedDisplay()
// Desc:
//-----------------------------------------------------------------------------
function CDisplay.CreateWindowedDisplay ( const hWnd : HWND; const dwWidth, dwHeight : DWORD) : HRESULT;
var
    hr : HRESULT;
    rcWork : TRECT;
    rc : TRECT;
    dwStyle : DWORD;
    menu : HMENU;
    pcClipper : IDIRECTDRAWCLIPPER;
    ddsd : TDDSURFACEDESC2;    
begin
    // Cleanup anything from a previous call
    DestroyObjects();

    // DDraw stuff begins here
    hr := DirectDrawCreateEx( nil, m_pDD, IID_IDirectDraw7, nil );
    if ( FAILED( hr ) ) then begin
        Result := E_FAIL;
        Exit;
    end;

    // Set cooperative level
    hr := m_pDD.SetCooperativeLevel( hWnd, DDSCL_NORMAL );
    if( FAILED(hr) ) then begin
        Result := E_FAIL;
        Exit;
    end;

    // If we are still a WS_POPUP window we should convert to a normal app
    // window so we look like a windows app.
    dwStyle := GetWindowStyle ( hWnd );
    dwStyle := dwStyle and WS_POPUP;
    dwStyle := dwStyle or WS_OVERLAPPED or WS_CAPTION or WS_THICKFRAME or WS_MINIMIZEBOX;
    SetWindowLong( hWnd, GWL_STYLE, dwStyle );

    // Aet window size
    SetRect( rc, 0, 0, dwWidth, dwHeight );

    Menu := GetMenu(hWnd);

    AdjustWindowRectEx( rc, GetWindowStyle(hWnd), (Menu <> 0),
                        GetWindowExStyle(hWnd) );

    SetWindowPos( hWnd, NULL, 0, 0, rc.right-rc.left, rc.bottom-rc.top,
                  SWP_NOMOVE or SWP_NOZORDER or SWP_NOACTIVATE );

    SetWindowPos( hWnd, HWND_NOTOPMOST, 0, 0, 0, 0,
                  SWP_NOSIZE or SWP_NOMOVE or SWP_NOACTIVATE );

    //  Make sure our window does not hang outside of the work area
    SystemParametersInfo( SPI_GETWORKAREA, 0, @rcWork, 0 );
    GetWindowRect( hWnd, rc );
    if( rc.left < rcWork.left ) then rc.left := rcWork.left;
    if( rc.top  < rcWork.top )  then rc.top  := rcWork.top;
    SetWindowPos( hWnd, NULL, rc.left, rc.top, 0, 0,
                  SWP_NOSIZE or SWP_NOZORDER or SWP_NOACTIVATE );

    // Create the primary surface
    ZeroMemory( @ddsd, sizeof( ddsd ) );
    ddsd.dwSize         := sizeof( ddsd );
    ddsd.dwFlags        := DDSD_CAPS;
    ddsd.ddsCaps.dwCaps := DDSCAPS_PRIMARYSURFACE;

    if( FAILED( m_pDD.CreateSurface( ddsd, m_pddsFrontBuffer, nil ) ) ) then begin
        Result := E_FAIL;
        Exit;
    end;

    // Create the backbuffer surface
    ddsd.dwFlags        := DDSD_CAPS or DDSD_WIDTH or DDSD_HEIGHT;
    ddsd.ddsCaps.dwCaps := DDSCAPS_OFFSCREENPLAIN or DDSCAPS_3DDEVICE;
    ddsd.dwWidth        := dwWidth;
    ddsd.dwHeight       := dwHeight;

    hr := m_pDD.CreateSurface( ddsd, m_pddsBackBuffer, nil );
    if( FAILED( hr ) ) then begin
        Result := E_FAIL;
        Exit;
    end;

    hr := m_pDD.CreateClipper( 0, pcClipper, nil );
    if( FAILED( hr ) ) then begin
        Result := E_FAIL;
        Exit;
    end;

    hr := pcClipper.SetHWnd( 0, hWnd );
    if( FAILED( hr ) ) then begin
        pcClipper._Release;
        Result := E_FAIL;
        Exit;
    end;

    hr := m_pddsFrontBuffer.SetClipper( pcClipper );
    if( FAILED( hr ) ) then begin
        pcClipper._Release;
        Result := E_FAIL;
        Exit;
    end;

    // Done with clipper
    pcClipper._Release;

    m_hWnd      := hWnd;
    m_bWindowed := TRUE;
    UpdateBounds;

    Result := S_OK;
end;

//-----------------------------------------------------------------------------
// Name:
// Desc:
//-----------------------------------------------------------------------------
function CDisplay.CreateSurface( out ppSurface : CSurface;
                                 const dwWidth, dwHeight : DWORD ) : HRESULT;
var
    hr : HRESULT;
    ddsd : TDDSURFACEDESC2;
begin
    ppSurface := nil;
    
    if ( nil = m_pDD ) then begin
        Result := E_POINTER;
        Exit;
    end;

    ZeroMemory( @ddsd, sizeof( ddsd ) );
    ddsd.dwSize         := sizeof( ddsd );
    ddsd.dwFlags        := DDSD_CAPS or DDSD_WIDTH or DDSD_HEIGHT;
    ddsd.ddsCaps.dwCaps := DDSCAPS_OFFSCREENPLAIN;
    ddsd.dwWidth        := dwWidth;
    ddsd.dwHeight       := dwHeight;

    ppSurface := CSurface.Create;

    hr := ppSurface.Create( m_pDD, ddsd ) ;
    if( FAILED( hr ) ) then begin
        ppSurface.Free;
        Result := hr;
        Exit;
    end;

    Result := S_OK;
end;

//-----------------------------------------------------------------------------
// Name: CDisplay::CreateSurfaceFromBitmap()
// Desc: Create a DirectDrawSurface from a bitmap resource or bitmap file.
//       Use MAKEINTRESOURCE() to pass a constant into strBMP.
//-----------------------------------------------------------------------------
function CDisplay.CreateSurfaceFromBitmap( out ppSurface : CSurface; const strBMP : PCHAR;
                                      const dwDesiredWidth, dwDesiredHeight : DWORD ) : HRESULT;

var
    hr : HRESULT;
    hBMP : HBITMAP;
    bmp : BITMAP;
    ddsd : TDDSURFACEDESC2;
begin
    ppSurface := nil;

    if( ( m_pDD = nil ) or ( strBMP = nil ) ) then begin
        Result := E_INVALIDARG;
        Exit;
    end;

    //  Try to load the bitmap as a resource, if that fails, try it as a file
    hBMP := LoadImage( GetModuleHandle(nil), strBMP,
                                IMAGE_BITMAP, dwDesiredWidth, dwDesiredHeight,
                                LR_CREATEDIBSECTION );
    if( hBMP = 0 ) then begin
        hBMP := LoadImage( 0, strBMP,
                           IMAGE_BITMAP, dwDesiredWidth, dwDesiredHeight,
                           LR_LOADFROMFILE or LR_CREATEDIBSECTION );
        if( hBMP = 0 ) then begin
            Result := E_FAIL;
            Exit;
        end;
    end;

    // Get size of the bitmap
    GetObject( hBMP, sizeof(bmp), @bmp );

    // Create a DirectDrawSurface for this bitmap
    ZeroMemory( @ddsd, sizeof(ddsd) );
    ddsd.dwSize         := sizeof(ddsd);
    ddsd.dwFlags        := DDSD_CAPS or DDSD_HEIGHT or DDSD_WIDTH;
    ddsd.ddsCaps.dwCaps := DDSCAPS_OFFSCREENPLAIN;
    ddsd.dwWidth        := bmp.bmWidth;
    ddsd.dwHeight       := bmp.bmHeight;

    ppSurface := CSurface.Create;
    hr := ppSurface.Create( m_pDD, ddsd );
    if( FAILED( hr ) ) then begin
        ppSurface.Free;
        Result := hr;
        Exit;
    end;

    // Draw the bitmap on this surface
    hr := ppSurface.DrawBitmap( hBMP, 0, 0, 0, 0 );
    if( FAILED( hr ) ) then begin
        DeleteObject( hBMP );
        Result := hr;
        Exit;
    end;

    DeleteObject( hBMP );

    Result := S_OK;
end;

//-----------------------------------------------------------------------------
// Name: CDisplay::CreateSurfaceFromText()
// Desc: Creates a DirectDrawSurface from a text string using hFont or the default
//       GDI font if hFont is NULL.
//-----------------------------------------------------------------------------
function CDisplay.CreateSurfaceFromText( out ppSurface : CSurface; hFont : HFONT;
	                           const strText : PCHAR;
				   const crBackground, crForeground : COLORREF ) : HRESULT;
var
    DC : HDC;
    hr : HRESULT;
    ddsd : TDDSURFACEDESC2;
    sizeText : SIZE;
begin
    ppSurface := nil;

    if( ( m_pDD = nil ) or ( strText = nil ) ) then begin
        Result := E_INVALIDARG;
        Exit;
    end;

    DC := GetDC( GetHWnd );

    if( hFont <> 0 ) then SelectObject( DC, hFont );

    GetTextExtentPoint32( DC, strText, length (strText), sizeText );
    ReleaseDC( 0, DC );

    // Create a DirectDrawSurface for this bitmap
    ZeroMemory( @ddsd, sizeof(ddsd) );
    ddsd.dwSize         := sizeof(ddsd);
    ddsd.dwFlags        := DDSD_CAPS or DDSD_HEIGHT or DDSD_WIDTH;
    ddsd.ddsCaps.dwCaps := DDSCAPS_OFFSCREENPLAIN;
    ddsd.dwWidth        := sizeText.cx;
    ddsd.dwHeight       := sizeText.cy;

    ppSurface := CSurface.Create;
    hr := ppSurface.Create( m_pDD, ddsd );
    if( FAILED( hr ) ) then begin
        ppSurface.Free;
        Result := hr;
        Exit;
    end;

    hr := ppSurface.DrawText( hFont, strText, 0, 0,
                             crBackground, crForeground );

    if( FAILED( hr ) ) then begin
        Result := hr;
        Exit;
    end;

    Result := S_OK;
end;

//-----------------------------------------------------------------------------
// Name: 
// Desc: 
//-----------------------------------------------------------------------------
function CDisplay.Present : HRESULT;
var
    hr : HRESULT;
begin
    if( (nil = m_pddsFrontBuffer) and ( nil = m_pddsBackBuffer ) ) then begin
        Result := E_POINTER;
        Exit
    end;

    while True do begin
        if( m_bWindowed ) then
            hr := m_pddsFrontBuffer.Blt( @m_rcWindow, m_pddsBackBuffer,
                                         nil, DDBLT_WAIT, nil )
        else
            hr := m_pddsFrontBuffer.Flip( nil, 0 );

        if( hr = DDERR_SURFACELOST ) then begin
            m_pddsFrontBuffer._Restore;
            m_pddsBackBuffer._Restore;
        end;

        if( hr <> DDERR_WASSTILLDRAWING ) then begin
            Result := hr;
            Exit
        end;
    end;
end;

//-----------------------------------------------------------------------------
// Name:
// Desc:
//-----------------------------------------------------------------------------
function CDisplay.ShowBitmap( const hbm : HBITMAP; const pPalette : IDIRECTDRAWPALETTE {=NULL} ) : HRESULT;
var
    backBuffer : CSurface;
begin
    if( ( nil = m_pddsFrontBuffer ) and ( nil = m_pddsBackBuffer ) ) then begin
        Result := E_POINTER;
        Exit
    end;

    // Set the palette before loading the bitmap
    if( pPalette <> nil ) then
        m_pddsFrontBuffer.SetPalette( pPalette );

    backBuffer := CSurface.Create;
    backBuffer.Create( m_pddsBackBuffer );

    if( FAILED( backBuffer.DrawBitmap( hbm, 0, 0, 0, 0 ) ) ) then begin
        Result := E_FAIL;
        Exit
    end;

    Result := Present;
end;

//-----------------------------------------------------------------------------
// Name:
// Desc:
//-----------------------------------------------------------------------------
function CDisplay.ColorKeyBlt( const x, y : DWORD; const pdds : IDIRECTDRAWSURFACE7;
                          const prc : PRECT  {= NULL} ) : HRESULT;
begin
    if( nil = m_pddsBackBuffer ) then begin
        Result := E_POINTER;
        Exit
    end;

    Result := m_pddsBackBuffer.BltFast( x, y, pdds, prc, DDBLTFAST_SRCCOLORKEY );
end;




//-----------------------------------------------------------------------------
// Name:
// Desc:
//-----------------------------------------------------------------------------
function CDisplay.Blt( const x, y : DWORD; const pdds : IDIRECTDRAWSURFACE7;
		  const prc : PRECT; const dwFlags : DWORD {=0} ) : HRESULT;
begin
    if( nil = m_pddsBackBuffer ) then begin
        Result := E_POINTER;
        Exit
    end;

    Result := m_pddsBackBuffer.BltFast( x, y, pdds, prc, dwFlags );
end;

//-----------------------------------------------------------------------------
// Name:
// Desc:
//-----------------------------------------------------------------------------
function CDisplay.Blt( const x, y : DWORD; const pSurface : CSurface; const prc : PRECT  {= NULL} ) : HRESULT;
begin
    if( nil = pSurface ) then begin
        Result := E_INVALIDARG;
        Exit;
    end;

    if( pSurface.IsColorKeyed() )
        then Result := Blt( x, y, pSurface.GetDDrawSurface(), prc, DDBLTFAST_SRCCOLORKEY )
        else Result := Blt( x, y, pSurface.GetDDrawSurface(), prc, 0 );
end;

//-----------------------------------------------------------------------------
// Name:
// Desc:
//-----------------------------------------------------------------------------
function CDisplay.Clear( const dwColor : DWORD {= 0L} ) : HRESULT;
var
    ddbltfx : TDDBLTFX;
begin
    if( nil = m_pddsBackBuffer ) then begin
        Result := E_POINTER;
        Exit
    end;

    // Erase the background
    ZeroMemory( @ddbltfx, sizeof(ddbltfx) );
    ddbltfx.dwSize      := sizeof(ddbltfx);
    ddbltfx.dwFillColor := dwColor;

    Result := m_pddsBackBuffer.Blt( nil, nil, nil, DDBLT_COLORFILL, @ddbltfx );
end;

//-----------------------------------------------------------------------------
// Name:
// Desc:
//-----------------------------------------------------------------------------
function CDisplay.SetPalette( const pPalette : IDIRECTDRAWPALETTE ) : HRESULT;
begin
    if( nil = m_pddsFrontBuffer ) then begin
        Result := E_POINTER;
        Exit
    end;

    Result := m_pddsFrontBuffer.SetPalette( pPalette );
end;

//-----------------------------------------------------------------------------
// Name:
// Desc:
//-----------------------------------------------------------------------------
function CDisplay.CreatePaletteFromBitmap( out ppPalette : IDIRECTDRAWPALETTE; const strBMP : PCHAR ) : HRESULT;
var
  iColor : DWORD;
  dwColors : DWORD;
  fh : Integer;
  hResource : HRSRC;
  pbi : ^BITMAPINFOHEADER;
  aPalette : array[0..255] of PALETTEENTRY;
  prgb : PRGBQUAD;
  bf : BITMAPFILEHEADER;
  bi : BITMAPINFOHEADER;
  r : Byte;
begin
  ppPalette := nil;

  if ( m_pDD = nil ) or ( strBMP = nil ) then begin
        Result := E_INVALIDARG;
        Exit
  end;

  //  Try to load the bitmap as a resource, if that fails, try it as a file
  hResource := FindResource( 0, strBMP, RT_BITMAP );
  if ( hResource <> 0 ) then begin
      pbi := LockResource ( LoadResource ( 0, hResource ) );
      if pbi = nil then begin
        Result := E_FAIL;
        Exit;
      end;
      Inc ( pbi, pbi^.biSize );
      prgb := PRGBQUAD ( pbi );
      // Figure out how many colors there are
      if ( pbi = nil ) or ( pbi^.biSize < SizeOf ( BITMAPINFOHEADER ) )
        then dwColors := 0
        else if pbi^.biBitCount > 8 then dwColors := 0
        else if pbi^.biClrUsed = 0 then dwColors := 1 shl pbi^.biBitCount
        else dwColors := pbi^.biClrUsed;
      //  A DIB color table has its colors stored BGR not RGB
      //  so flip them around.
      for iColor := 0 to dwColors - 1 do begin
          aPalette[iColor].peRed := prgb^.rgbRed;
          aPalette[iColor].peGreen := prgb^.rgbGreen;
          aPalette[iColor].peBlue := prgb^.rgbBlue;
          aPalette[iColor].peFlags := 0;
          inc(prgb);
      end;
      Result := m_pDD.CreatePalette( DDPCAPS_8BIT, @aPalette[0], ppPalette, nil );
      Exit
  end;

  fh := _lopen ( strBMP, OF_READ );
  if ( strBMP <> nil ) and ( fh <> -1 ) then begin
      _lread ( fh, @bf, SizeOf ( bf ) );
      _lread ( fh, @bi, SizeOf ( bi ) );
      _lread ( fh, @aPalette [0], SizeOf ( aPalette ) );
      _lclose ( fh );
      if bi.biSize <> SizeOf ( BITMAPINFOHEADER ) then dwColors := 0
      else if bi.biBitCount > 8 then dwColors := 0
      else if bi.biClrUsed = 0 then dwColors := 1 shl bi.biBitCount
      else dwColors := bi.biClrUsed;
      //
      //  A DIB color table has its colors stored BGR not RGB
      //  so flip them around.
      //
      for iColor := 0 to dwColors - 1 do begin
        r := aPalette[iColor].peRed;
        aPalette[iColor].peRed := aPalette[iColor].peBlue;
        aPalette[iColor].peBlue := r;
      end;
    end;

    Result := m_pDD.CreatePalette( DDPCAPS_8BIT, @aPalette[0], ppPalette, nil );
end;


//-----------------------------------------------------------------------------
// Name:
// Desc:
//-----------------------------------------------------------------------------
function CDisplay.UpdateBounds : HRESULT;
var
    p : TPOINT;
begin
    if( m_bWindowed ) then begin
        p.X := 0; p.Y := 0;
        ClientToScreen ( m_hWnd, p );
        GetClientRect ( m_hWnd, m_rcWindow );
        OffsetRect ( m_rcWindow, p.X, p.Y );
      end
      else begin
        SetRect( m_rcWindow, 0, 0, GetSystemMetrics(SM_CXSCREEN),
                 GetSystemMetrics(SM_CYSCREEN) );
    end;

    Result := S_OK;
end;

//-----------------------------------------------------------------------------
// Name: CDisplay::InitClipper
// Desc: 
//-----------------------------------------------------------------------------
function CDisplay.InitClipper : HRESULT;
var
    pClipper : IDIRECTDRAWCLIPPER;
    hr : HRESULT;
begin
    // Create a clipper when using GDI to draw on the primary surface
    hr := m_pDD.CreateClipper( 0, pClipper, nil );
    if( FAILED( hr ) ) then begin
        Result := hr;
        Exit;
    end;

    pClipper.SetHWnd( 0, m_hWnd );

    hr := m_pddsFrontBuffer.SetClipper( pClipper );
    if( FAILED( hr ) ) then begin
        Result := hr;
        Exit;
    end;

    // We can release the clipper now since g_pDDSPrimary 
    // now maintains a ref count on the clipper
    if Assigned ( pClipper ) then begin
     pClipper._Release;
     pClipper := nil;
    end;

    Result := S_OK;
end;

//-----------------------------------------------------------------------------
// Name:
// Desc:
//-----------------------------------------------------------------------------
function CSurface.Create( const pdds : IDIRECTDRAWSURFACE7 ) : HRESULT;
begin
    m_pdds := pdds;

    if( m_pdds <> nil ) then begin
        m_pdds._AddRef;

        // Get the DDSURFACEDESC structure for this surface
        m_ddsd.dwSize := sizeof(m_ddsd);
        m_pdds.GetSurfaceDesc( m_ddsd );
    end;

    Result := S_OK;
end;

//-----------------------------------------------------------------------------
// Name: 
// Desc: 
//-----------------------------------------------------------------------------
function CSurface.Create( const pDD : IDIRECTDRAW7; const pddsd : TDDSURFACEDESC2 ) : HRESULT;
var
    hr : HRESULT;
begin
    // Create the DDraw surface
    hr := pDD.CreateSurface( pddsd, m_pdds, nil );
    if( FAILED( hr ) ) then begin
        Result := hr;
        Exit
    end;

    // Prepare the DDSURFACEDESC structure
    m_ddsd.dwSize := sizeof( m_ddsd );

    // Get the DDSURFACEDESC structure for this surface
    m_pdds.GetSurfaceDesc( m_ddsd );

    Result := S_OK;
end;

//-----------------------------------------------------------------------------
// Name:
// Desc: 
//-----------------------------------------------------------------------------
destructor CSurface.Destroy;
begin
    SAFE_RELEASE( m_pdds );
    inherited;
end;

//-----------------------------------------------------------------------------
// Name: CSurface::DrawBitmap()
// Desc: Draws a bitmap over an entire DirectDrawSurface, stretching the 
//       bitmap if nessasary
//-----------------------------------------------------------------------------
function CSurface.DrawBitmap( const hBMP : HBITMAP; const dwBMPOriginX, {= 0} dwBMPOriginY : DWORD; {= 0}
		              dwBMPWidth, {= 0} dwBMPHeight : DWORD {= 0} ) : HRESULT;
var
    hDCImage : HDC;
    DC : HDC;
    bmp : BITMAP;
    ddsd : TDDSURFACEDESC2;
    hr : HRESULT;
begin
    if( ( hBMP = 0 ) or ( m_pdds = nil ) ) then begin
        Result := E_INVALIDARG;
        Exit
    end;

    // Make sure this surface is restored.
    hr := m_pdds._Restore;
    if( FAILED( hr ) ) then begin
        Result := hr;
        Exit
    end;

    // Get the surface.description
    ddsd.dwSize  := sizeof( ddsd );
    m_pdds.GetSurfaceDesc( ddsd );

    if( ddsd.ddpfPixelFormat.dwFlags = DDPF_FOURCC ) then begin
        Result := E_NOTIMPL;
        Exit
    end;

    // Select bitmap into a memoryDC so we can use it.
    hDCImage := CreateCompatibleDC( 0 );
    if( 0 = hDCImage ) then begin
        Result := E_FAIL;
        Exit
    end;

    SelectObject( hDCImage, hBMP );

    // Get size of the bitmap
    GetObject( hBMP, sizeof(bmp), @bmp );

    // Use the passed size, unless zero
    if dwBMPWidth  = 0
       then dwBMPWidth  := bmp.bmWidth
       else dwBMPWidth  := dwBMPWidth;
    if dwBMPHeight = 0
       then dwBMPHeight := bmp.bmHeight
       else dwBMPHeight := dwBMPHeight;

    // Stretch the bitmap to cover this surface
    hr := m_pdds.GetDC( DC );
    if( FAILED( hr ) ) then begin
        Result := hr;
        Exit
    end;

    StretchBlt( DC, 0, 0,
                ddsd.dwWidth, ddsd.dwHeight, 
                hDCImage, dwBMPOriginX, dwBMPOriginY,
                dwBMPWidth, dwBMPHeight, SRCCOPY );

    hr := m_pdds.ReleaseDC( DC );
    if( FAILED( hr ) ) then begin
        Result := hr;
        Exit
    end;

    DeleteDC( hDCImage );

    Result := S_OK;
end;

//-----------------------------------------------------------------------------
// Name: CSurface::DrawText()
// Desc: Draws a text string on a DirectDraw surface using hFont or the default
//       GDI font if hFont is NULL.
//-----------------------------------------------------------------------------
function CSurface.DrawText( hFont : HFONT; const strText : PCHAR; const dwOriginX, dwOriginY : DWORD;
	               const crBackground, crForeground : COLORREF) : HRESULT;
var
    DC : HDC;
    hr : HRESULT;
begin
    DC := 0;
    if( ( m_pdds = nil ) or ( strText = nil ) ) then begin
        Result := E_INVALIDARG;
        Exit
    end;

    // Make sure this surface is restored.
    hr := m_pdds._Restore;
    if( FAILED( hr ) ) then begin
        Result := hr;
        Exit
    end;

    hr := m_pdds.GetDC( DC );
    if( FAILED( hr ) ) then begin
        Result := hr;
        Exit
    end;

    // Set the background and foreground color
    SetBkColor( DC, crBackground );
    SetTextColor( DC, crForeground );

    if( hFont <> 0 ) then SelectObject( DC, hFont );

    // Use GDI to draw the text on the surface
    TextOut( DC, dwOriginX, dwOriginY, strText, length(strText) );

    hr := m_pdds.ReleaseDC( DC );
    if( FAILED( hr ) ) then begin
        Result := hr;
        Exit
    end;

    Result := S_OK;
end;

//-----------------------------------------------------------------------------
// Name: CSurface::ReDrawBitmapOnSurface()
// Desc: Load a bitmap from a file or resource into a DirectDraw surface.
//       normaly used to re-load a surface after a restore.
//-----------------------------------------------------------------------------
function CSurface.DrawBitmap( const strBMP : PCHAR; const dwDesiredWidth, dwDesiredHeight : DWORD ) : HRESULT;
var
    hBMP : HBITMAP;
    hr : HRESULT;
begin
    if( ( m_pdds = nil ) or ( strBMP = nil ) ) then begin
        Result := E_INVALIDARG;
        Exit
    end;

    //  Try to load the bitmap as a resource, if that fails, try it as a file
    hBMP := LoadImage( GetModuleHandle(nil), strBMP,
                                IMAGE_BITMAP, dwDesiredWidth, dwDesiredHeight,
                                LR_CREATEDIBSECTION );
    if( hBMP = 0 ) then begin
        hBMP := LoadImage( 0, strBMP, IMAGE_BITMAP,
                                    dwDesiredWidth, dwDesiredHeight,
                                    LR_LOADFROMFILE or LR_CREATEDIBSECTION );
        if( hBMP = 0 ) then begin
            Result := E_FAIL;
            Exit
        end;
    end;

    // Draw the bitmap on this surface
    hr := DrawBitmap( hBMP, 0, 0, 0, 0 );
    if( FAILED( hr ) ) then begin
        DeleteObject( hBMP );
        Result := hr;
        Exit
    end;

    DeleteObject( hBMP );

    Result := S_OK;
end;

//-----------------------------------------------------------------------------
// Name: 
// Desc:
//-----------------------------------------------------------------------------
function CSurface.SetColorKey( const dwColorKey : DWORD ) : HRESULT;
var
    ddck : TDDCOLORKEY;
begin
    if( nil = m_pdds ) then begin
        Result := E_POINTER;
        Exit
    end;

    m_bColorKeyed := TRUE;

    ddck.dwColorSpaceLowValue  := ConvertGDIColor( dwColorKey );
    ddck.dwColorSpaceHighValue := ConvertGDIColor( dwColorKey );

    Result := m_pdds.SetColorKey( DDCKEY_SRCBLT, @ddck );
end;

//-----------------------------------------------------------------------------
// Name: CSurface::ConvertGDIColor()
// Desc: Converts a GDI color (0x00bbggrr) into the equivalent color on a
//       DirectDrawSurface using its pixel format.
//-----------------------------------------------------------------------------
function CSurface.ConvertGDIColor( const dwGDIColor : COLORREF ) : DWORD;
var
    rgbT : COLORREF;
    dc : HDC;
    dw : DWORD;
    ddsd : TDDSURFACEDESC2;
    hr : HRESULT;
begin
    if( m_pdds = nil ) then begin
	Result := $00000000;
        Exit
    end;

    rgbT := 0;
    dw := CLR_INVALID;
    //  Use GDI SetPixel to color match for us
    hr := m_pdds.GetDC(dc);
    if( ( dwGDIColor <> CLR_INVALID ) and ( hr = DD_OK ) ) then begin
        rgbT := GetPixel(dc, 0, 0);     // Save current pixel value
        SetPixel(dc, 0, 0, dwGDIColor);       // Set our value
        m_pdds.ReleaseDC(dc);
    end;

    // Now lock the surface so we can read back the converted color
    ZeroMemory( @ddsd, sizeof( ddsd ) );
    ddsd.dwSize := sizeof(ddsd);
    hr := m_pdds.Lock( nil, ddsd, DDLOCK_WAIT, 0 );
    if( hr = DD_OK) then begin
        dw := PDWORD(ddsd.lpSurface)^;
        if( ddsd.ddpfPixelFormat.dwRGBBitCount < 32 ) // Mask it to bpp
            then dw := dw and ( ( 1 shl ddsd.ddpfPixelFormat.dwRGBBitCount ) - 1);
        m_pdds.Unlock( nil );
    end;

    //  Now put the color that was there back.
    hr := m_pdds.GetDC( dc );
    if( ( dwGDIColor <> CLR_INVALID ) and ( hr = DD_OK ) ) then begin
        SetPixel( dc, 0, 0, rgbT );
        m_pdds.ReleaseDC( dc );
    end;

    Result := dw;
end;

//-----------------------------------------------------------------------------
// Name: CSurface::GetBitMaskInfo()
// Desc: Returns the number of bits and the shift in the bit mask
//-----------------------------------------------------------------------------
function CSurface.GetBitMaskInfo( dwBitMask : DWORD; var pdwShift, pdwBits : DWORD) : HRESULT;
var
    dwShift : DWORD;
    dwBits : DWORD;
begin
    dwShift := 0;
    dwBits  := 0;

    if( dwBitMask <> 0 ) then begin
        while( ( dwBitMask and 1 ) = 0 ) do begin
            dwShift := dwShift + 1;
            dwBitMask := dwBitMask shr 1;
        end;
    end;

    while( (dwBitMask and 1) <> 0 ) do begin
        dwBits := dwBits + 1;
        dwBitMask := dwBitMask shr 1;
    end;

    pdwShift := dwShift;
    pdwBits  := dwBits;

    Result := S_OK;
end;

function CSurface.GetDDrawSurface : IDIRECTDRAWSURFACE7;
begin
  Result := m_pdds;
end;

function CSurface.IsColorKeyed : BOOL;
begin
  Result := m_bColorKeyed;
end;

end.
