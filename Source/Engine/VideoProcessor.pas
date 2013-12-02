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
unit VideoProcessor;

interface

uses
    Windows, ActiveX, SysUtils, Math,

    BaseClass, DirectShow9, DSUtils, Filterbase, YVImage, YVOSD;

const
  CLSID_VideoProcessor: TGUID = '{B695DE60-57F8-11D7-B33C-525405F661BB}';
  IID_VideoProcessor: TGUID = '{B695DE60-57F8-11D7-B33C-525405F661BB}';

type
  TVPEffect = (efNone, efBlur, efSoften, efSoftenX, efSharpenX,
    efSharpen, efEdge, efContour);

  PYUV2Word = ^TYUV2Word;
  TYUV2Word = record
   case Byte of
   0: (Wrd  :Word);
   1: (Y    :Byte;
       UorV :Byte);
  end;

  PYUV2DWord = ^TYUV2DWord;
  TYUV2DWord = record
   case Byte of
   0:(DW:DWORD);
   1:(Crdnl:Cardinal);
   2:(Int :Integer);
   3:(Y  :Byte;
      U  :Byte;
      Y2 :Byte;
      V  :Byte);
  end;

  PVideoProcProps = ^TVideoProcProps;
  TVideoProcProps = record
    Br, Co, Sa, Cr, Cb: Integer; // -100..100
    VFlip: Boolean; //Vertical Flip
    HFlip: Boolean; //Horizontal Flip
    RestrictYUY2: Boolean;
    RestrictYV12: Boolean;
    Effect: TVPEffect; //slow
    ZoomX, ZoomY: Integer;
    IsConnected: Boolean;
    OSD: TYVOSD;
    Update: Boolean;
  end;

  IVideoProcessor = interface
    ['{B695DE60-57F8-11D7-B33C-525405F661BB}']
    function GetProps(out Props: PVideoProcProps): HRESULT;
    function UpdateBCS: HRESULT;
  end;

  TVPMatrix = array[-1..1, -1..1] of Integer;

  TVideoProcessor = class(TBCTransformFilter, IVideoProcessor)
  private
    CurVidFormat_In   :TVideoInfoHeader; // Holds the current video format (input)
    CurVidFormat_Out  :TVideoInfoHeader; // Holds the current video format (output)

    pBackBuff         :PByte;

    Colorspace: (cpYUY2,cpYV12);

    inPicWidth,inPicHeight   :Integer;
    outPicWidth,outPicHeight :Integer;

    InStride, OutStride      :Integer;
    InTopDelta, OutTopDelta  :Integer;

    FLock              :TBCCritSec;
    palY, palU, palV  :array[0..255] of Byte;
    ProcessBCS        :Boolean;
    Mask              :TVPMatrix;
    MatrixN           :Integer;
    VideoProps        :TVideoProcProps;

    function IsSupportedFormat(const pMediaType : PAMMediaType) : BOOLEAN;

    function TransformInPlaceYUY2(const pSource, pDest : IMediaSample) : HRESULT;
    function TransformInPlaceYV12(const pSource, pDest : IMediaSample) : HRESULT;
  public
    constructor Create(ObjectName: string; unk: IInterface; const clsid: TGUID);
    destructor Destroy; override;

    // Check income filter info
    function CheckConnect(direct: TPinDirection; Pin: IPin): HRESULT; override;
    function BreakConnect(direct: TPinDirection): HRESULT; override;
    // accept a media type of input stream
    function CheckInputType(mtIn: PAMMediaType): HRESULT; override;
    // get output pin media type
    function GetMediaType(iPosition : INTEGER; out pMediaType : PAMMediaType) : HRESULT; override;
    // check a transform can be done between these formats
    function CheckTransform(mtIn, mtOut: PAMMediaType): HRESULT; override;
    // This is called when we actually have to provide out own allocator.
    function DecideBufferSize(pAlloc: IMemAllocator; pProperties: PALLOCATORPROPERTIES): HRESULT; override;

    function SetMediaType(direction: TPinDirection; pmt: PAMMediaType): HRESULT; override;

    function Transform(pIn, pOut: IMediaSample): HRESULT; override;

    function GetProps(out Props: PVideoProcProps): HRESULT;
    function UpdateBCS: HRESULT;
  end;


implementation

uses
  AxCtrls;

const
  //Effect's Matrix
  mBlur          :TVPMatrix = ( ( 1,  1,  1), ( 1, 1,  1), ( 1,  1,  1) );
  mSoften        :TVPMatrix = ( ( 1,  1,  1), ( 1, 2,  1), ( 1,  1,  1) );
  mGauss         :TVPMatrix = ( ( 1,  2,  1), ( 2, 4,  2), ( 1,  2,  1) );
  mLiteSharpness :TVPMatrix = ( (-1, -1, -1), (-1, 16,-1), (-1, -1, -1) );
  mSharpness     :TVPMatrix = ( (-1, -1, -1), (-1, 14,-1), (-1, -1, -1) );
  mEdge          :TVPMatrix = ( (-1, -1, -1), (-1, 12,-1), (-1, -1, -1) );
  mContour       :TVPMatrix = ( (-1, -1, -1), (-1, 11,-1), (-1, -1, -1) );

constructor TVideoProcessor.Create(ObjectName: string; unk: IInterface; const clsid: TGUID);
begin
  inherited Create(ObjectName, unk, clsid);

  FLock := TBCCritSec.Create;

  ProcessBCS  := False;
  pBackBuff   := nil;

  FillChar(VideoProps, SizeOf(TVideoProcProps),0);
  VideoProps.RestrictYUY2 := False;
  VideoProps.RestrictYV12 := False;
  VideoProps.OSD := TYVOSD.Create;

  //FBufferRequest  := 1;
end;

destructor TVideoProcessor.Destroy;
begin
  if Assigned(FLock) then
    FLock.Free;
  if pBackBuff<>nil then begin
    CoTaskMemFree(pBackBuff);
    pBackBuff := nil;
  end;
  inherited;
end;

function TVideoProcessor.IsSupportedFormat(const pMediaType : PAMMediaType) : BOOLEAN;
  function AllowConnect(const bmiHeader:TBitmapInfoHeader; const AvgTimePerFrame:Int64; biBitCount:Word; const FCC_S:String):Boolean;
  begin
    Result := (bmiHeader.biBitCount=biBitCount) and (bmiHeader.biCompression=FCC(FCC_S))
              //and (PVideoInfoHeader(pMediaType.pbFormat).bmiHeader.biSizeImage=GetDIBLineSize(biBitCount, biWidth) * biHeight * biPlanes;)
  end;
begin
  Result := False;
  if (IsEqualGUID(pMediaType.majortype, MEDIATYPE_Video)) and (pMediaType.pbFormat<>nil) then
  begin
    if (IsEqualGUID(pMediaType.subtype, MEDIASUBTYPE_YUY2)) and not VideoProps.RestrictYUY2 then begin
      if IsEqualGUID(pMediaType.formattype,FORMAT_VideoInfo) and (pMediaType.cbFormat>=SizeOf(TVideoInfoHeader)) then begin
         Result := AllowConnect(PVideoInfoHeader(pMediaType.pbFormat).bmiHeader,
                         PVideoInfoHeader(pMediaType.pbFormat).AvgTimePerFrame,
                         16, 'YUY2') ;
      end else
      if IsEqualGUID(pMediaType.formattype,FORMAT_VideoInfo2) and (pMediaType.cbFormat>=SizeOf(TVideoInfoHeader2)) then begin
         Result := AllowConnect(PVideoInfoHeader2(pMediaType.pbFormat).bmiHeader,
                         PVideoInfoHeader2(pMediaType.pbFormat).AvgTimePerFrame,
                         16, 'YUY2') ;
      end;
    end else
    if (IsEqualGUID(pMediaType.subtype, MEDIASUBTYPE_YV12)) and not VideoProps.RestrictYV12 then begin
      if IsEqualGUID(pMediaType.formattype,FORMAT_VideoInfo)
            and (pMediaType.cbFormat>=SizeOf(TVideoInfoHeader))
            //не работаем с поверхностями не кратными 4рем (например 354х290)
            and ( (PVideoInfoHeader(pMediaType.pbFormat).bmiHeader.biWidth mod 4)=0 )
      then begin
           Result := AllowConnect(PVideoInfoHeader(pMediaType.pbFormat).bmiHeader,
                         PVideoInfoHeader(pMediaType.pbFormat).AvgTimePerFrame,
                         12, 'YV12') ;
      end
      else
      if IsEqualGUID(pMediaType.formattype,FORMAT_VideoInfo2)
            and (pMediaType.cbFormat>=SizeOf(TVideoInfoHeader2))
            and ( (PVideoInfoHeader2(pMediaType.pbFormat).bmiHeader.biWidth mod 4)=0 )
      then begin
           Result := AllowConnect(PVideoInfoHeader2(pMediaType.pbFormat).bmiHeader,
                         PVideoInfoHeader2(pMediaType.pbFormat).AvgTimePerFrame,
                         12, 'YV12') ;
      end;
    end;
  end;
end;

function TVideoProcessor.CheckInputType(mtIn: PAMMediaType): HRESULT;
begin
  // Can we transform this type
  if IsSupportedFormat(mtIn) then
    Result := S_OK
  else
    Result := VFW_E_TYPE_NOT_ACCEPTED;
end;

function TVideoProcessor.GetMediaType(iPosition : INTEGER; out pMediaType : PAMMediaType) : HRESULT;
begin
  // Is the input pin connected
  if not FInput.IsConnected then begin Result := E_UNEXPECTED; Exit; end;

  // This should never happen
  if iPosition < 0 then begin Result := E_INVALIDARG; Exit; end;

  // Do we have more items to offer
  if iPosition > 0 then begin Result := VFW_S_NO_MORE_ITEMS; Exit; end;

  //CopyMediaType(pMediaType, FInput.CurrentMediaType.MediaType);
  //Result := S_OK;

  Result := FInput.ConnectionMediaType(pMediaType^);
  if IsEqualGUID(pMediaType^.formattype,FORMAT_VideoInfo2) then begin
    if (pMediaType^.pbFormat<>nil) and (pMediaType^.cbFormat>=SizeOf(TVideoInfoHeader2)) then begin
      CoTaskMemFree(pMediaType^.pbFormat);
      pMediaType^.cbFormat := 0;
      pMediaType^.pbFormat := nil;
    end;
    pMediaType^.formattype := FORMAT_VideoInfo;
    pMediaType^.cbFormat   := SizeOf(TVideoInfoHeader);
    pMediaType^.pbFormat   := CoTaskMemAlloc(pMediaType^.cbFormat);
    if (pMediaType^.pbFormat = nil) then
      pMediaType^.cbFormat := 0
    else
      CopyMemory(pMediaType^.pbFormat, @CurVidFormat_In, pMediaType^.cbFormat);
  end;
end;

function TVideoProcessor.CheckTransform(mtIn, mtOut: PAMMediaType): HRESULT;
begin
  Result := VFW_E_TYPE_NOT_ACCEPTED;

  if (not IsSupportedFormat(mtOut)) {or (not IsValidYUY2(mtIn))} then Exit;

  if (mtIn.pbFormat<>nil) then begin
    if IsEqualGUID(mtIn.formattype,FORMAT_VideoInfo) and (mtIn.cbFormat>=SizeOf(TVideoInfoHeader)) then begin
      if ( (PVideoInfoHeader(mtIn.pbFormat).bmiHeader.biWidth <= PVideoInfoHeader(mtOut.pbFormat).bmiHeader.biWidth)
           and( Abs(PVideoInfoHeader(mtIn.pbFormat).bmiHeader.biHeight) = Abs(PVideoInfoHeader(mtOut.pbFormat).bmiHeader.biHeight))
         ) then
           Result := S_OK;
    end else
    if IsEqualGUID(mtIn.formattype,FORMAT_VideoInfo2) and (mtIn.cbFormat>=SizeOf(TVideoInfoHeader2)) then begin
      if ( (PVideoInfoHeader2(mtIn.pbFormat).bmiHeader.biWidth <= PVideoInfoHeader(mtOut.pbFormat).bmiHeader.biWidth)
           and( Abs(PVideoInfoHeader2(mtIn.pbFormat).bmiHeader.biHeight) = Abs(PVideoInfoHeader(mtOut.pbFormat).bmiHeader.biHeight))
         ) then
           Result := S_OK;
    end;
  end;
  if Succeeded(Result) then VideoProps.IsConnected:=True;
end;

function TVideoProcessor.DecideBufferSize(pAlloc: IMemAllocator; pProperties: PALLOCATORPROPERTIES): HRESULT;
var
  Actual: TALLOCATORPROPERTIES;
  IntupAlloc: IMemAllocator;
  IntupAllocProps: TAllocatorProperties;
begin
  Result := E_UNEXPECTED;
  // Is the input pin connected
  if not FInput.IsConnected then Exit;

  // Our strategy here is to use the upstream allocator as the guideline, but
  // also defer to the downstream filter's request when it's compatible with us.
  Result := FInput.GetAllocator(IntupAlloc);
  if Failed(Result) then Exit;

  Result := IntupAlloc.GetProperties(IntupAllocProps);
  if Failed(Result) then Exit;
  //IntupAlloc := nil;
  // Buffer alignment should be non-zero [zero alignment makes no sense!]
  if pProperties.cbAlign=0 then
     pProperties.cbAlign := 1;
  if pProperties.cBuffers=0 then
     pProperties.cBuffers := 1;

  pProperties.cBuffers := Max(pProperties.cBuffers, IntupAllocProps.cBuffers);
  pProperties.cbBuffer := Max(pProperties.cbBuffer,IntupAllocProps.cbBuffer);

  // Ask the allocator to reserve us some sample memory, NOTE the function
  // can succeed (that is return NOERROR) but still not have allocated the
  // memory that we requested, so we must check we got whatever we wanted
  Result := pAlloc.SetProperties(pProperties^,Actual);
  if Failed(Result) then Exit;

  if (pProperties.cBuffers > Actual.cBuffers) or
     (IntupAllocProps.cbBuffer > Actual.cbBuffer) then
  begin
    Result := S_FALSE;
    Exit;
  end;

  Result := S_OK;
end;

// Helper Function
procedure GetVideoInfoParameters(const pvih: PVideoInfoHeader; // Pointer to the format header.
                                 bYUV : Boolean;               // Is this a YUV format? (true = YUV, false = RGB) 
                                 var dwWidth: Integer;         // Returns the width in pixels. 
                                 var dwHeight: Integer;        // Returns the height in pixels. 
                                 var StrideInBytes: Integer;   // Add this to a row to get the new row down.
                                 var TopDelta: Integer);       // Returns the delta of first byte in the
                                                               // top row of pixels.
var 
  lStride: Integer; 
begin
  //  For 'normal' formats, biWidth is in pixels.
  //  Expand to bytes and round up to a multiple of 4.
  if (pvih.bmiHeader.biBitCount <> 0) and (0 = (7 and pvih.bmiHeader.biBitCount)) then
  begin
    lStride:= (pvih.bmiHeader.biWidth * (pvih.bmiHeader.biBitCount div 8) + 3) and not 3;
  end
  else
  begin
    lStride:= pvih.bmiHeader.biWidth;
  end;
  //  If rcTarget is empty, use the whole image.
  if IsRectEmpty(pvih.rcTarget) then
  begin
    dwWidth:= pvih.bmiHeader.biWidth;
    dwHeight:= Abs(pvih.bmiHeader.biHeight);
    if (pvih.bmiHeader.biHeight < 0) or bYUV then  // Top-down bitmap.
    begin
      StrideInBytes:= lStride;
      TopDelta := 0;
    end
    else 
    begin  // Bottom-up bitmap. 
      StrideInBytes:= -lStride; // Stride goes "up".
      TopDelta := (lStride * (dwHeight-1));// Bottom row is first.
    end;
  end
  else  // rcTarget is NOT empty. Use a sub-rectangle in the image. 
  begin 
    dwWidth:= pvih.rcTarget.Right - pvih.rcTarget.Left; 
    dwHeight:= pvih.rcTarget.Bottom - pvih.rcTarget.Top; 
    if (pvih.bmiHeader.biHeight < 0) or bYUV then  // Top-down bitmap. 
    begin 
        // Same stride as above, but first pixel is modified down 
        // and over by the target rectangle. 
      StrideInBytes:= lStride; 
      TopDelta := (lStride * pvih.rcTarget.Top);
      inc(TopDelta, (pvih.bmiHeader.biBitCount * pvih.rcTarget.Left) div 8);
    end 
    else 
    begin  // Bottom-up bitmap. 
      StrideInBytes:= -lStride; 
      TopDelta:= (lStride * (pvih.bmiHeader.biHeight - pvih.rcTarget.Top - 1));
      inc(TopDelta, (pvih.bmiHeader.biBitCount * pvih.rcTarget.Left) div 8);
    end; 
  end; 
end;

function TVideoProcessor.SetMediaType;
begin
  Result := VFW_E_TYPE_NOT_ACCEPTED;
  if Assigned(pmt) then
  if (pmt^.cbFormat>=SizeOf(TVideoInfoHeader))and(pmt^.pbFormat<>nil) then begin
    if direction=PINDIR_INPUT then begin
      // WARNING! In general you cannot just copy a VIDEOINFOHEADER
      // struct, because the BITMAPINFOHEADER member may be followed by
      // random amounts of palette entries or color masks. (See VIDEOINFO
      // structure in the DShow SDK docs.) Here it's OK because we just
      // want the information that's in the VIDEOINFOHEADER stuct itself.

      if IsEqualGUID(pmt^.subtype, MEDIASUBTYPE_YUY2) then
        Colorspace:= cpYUY2
      else
        Colorspace := cpYV12;

      if IsEqualGUID(pmt^.formattype,FORMAT_VideoInfo) then
        CopyMemory(@CurVidFormat_In, pmt^.pbFormat,SizeOf(TVideoInfoHeader))
      else begin
        if IsEqualGUID(pmt^.formattype,FORMAT_VideoInfo2) and (pmt^.cbFormat>=SizeOf(TVideoInfoHeader2)) then begin
          CurVidFormat_In.rcSource        := PVideoInfoHeader2(pmt^.pbFormat)^.rcSource;
          CurVidFormat_In.rcTarget        := PVideoInfoHeader2(pmt^.pbFormat)^.rcTarget;
          CurVidFormat_In.dwBitRate       := PVideoInfoHeader2(pmt^.pbFormat)^.dwBitRate;
          CurVidFormat_In.dwBitErrorRate  := PVideoInfoHeader2(pmt^.pbFormat)^.dwBitErrorRate;
          CurVidFormat_In.AvgTimePerFrame := PVideoInfoHeader2(pmt^.pbFormat)^.AvgTimePerFrame;
          CurVidFormat_In.bmiHeader       := PVideoInfoHeader2(pmt^.pbFormat)^.bmiHeader;
        end;
      end;
      GetVideoInfoParameters(@CurVidFormat_In,True,inPicWidth,inPicHeight,InStride,InTopDelta);
      if pBackBuff<>nil then begin
        CoTaskMemFree(pBackBuff);
        pBackBuff := nil;
      end;

    end else begin
       if (direction=PINDIR_OUTPUT)and(IsEqualGUID(pmt^.formattype,FORMAT_VideoInfo)) then begin
          CopyMemory(@CurVidFormat_Out, pmt^.pbFormat,SizeOf(TVideoInfoHeader));
          GetVideoInfoParameters(@CurVidFormat_Out, True, outPicWidth, outPicHeight, OutStride, OutTopDelta);
       end;
    end;
    Result := S_OK;
  end;
end;

function TVideoProcessor.Transform(pIn, pOut : IMediaSample) : HRESULT;
var
  pOutMediaType : PAMMediaType;
  TimeStart, TimeEnd : TReferenceTime;
  MediaStart, MediaEnd : INT64;
  hr : HRESULT;
begin
  if VideoProps.Update then UpdateBCS;

  // Note: The filter has already set the sample properties on pOut,
  // (see CTransformFilter::InitializeOutputSample).
  // You can override the timestamps if you need - but not in our case.

  // The filter already locked m_csReceive so we're OK.

  // Look for format changes from the video renderer.
  if pOut.GetMediaType(pOutMediaType)=S_OK then begin
    FOutput.SetMediaType(pOutMediaType);
    DeleteMediaType(pOutMediaType);
  end;

  // Process Image
  if ColorSpace = cpYUY2 then
    Result := TransformInPlaceYUY2(pIn, pOut)
  else
    Result := TransformInPlaceYV12(pIn, pOut);
  if (Failed(Result)) then Exit;

  // Copy the sample times
  if (pIn.GetTime(TimeStart, TimeEnd) = NOERROR) then
    pOut.SetTime(@TimeStart, @TimeEnd);

  if (pIn.GetMediaTime(MediaStart,MediaEnd) = NOERROR) then
    pOut.SetMediaTime(@MediaStart,@MediaEnd);

  // Copy the preroll property
  hr := pIn.IsPreroll;
  if hr in [S_OK, S_FALSE] then
    pOut.SetPreroll(hr = S_OK)
  else begin
    Result := E_UNEXPECTED;
    Exit;
  end;

  // Copy the Sync point property
  hr := pIn.IsSyncPoint;
  if hr in [S_OK, S_FALSE] then
    pOut.SetSyncPoint(hr = S_OK)
  else begin
    Result := E_UNEXPECTED;
    Exit;
  end;

  // Copy the discontinuity property
  hr := pIn.IsDiscontinuity;
  if hr in [S_OK, S_FALSE] then
    pOut.SetDiscontinuity(hr = S_OK)
  else begin
    Result := E_UNEXPECTED;
    Exit;
  end;

  pOut.SetActualDataLength(CurVidFormat_Out.bmiHeader.biSizeImage);
end;

function TVideoProcessor.TransformInPlaceYUY2;
var
  //pSourceBuffer, pDestBuffer :PBYTE;
  pSourceFP, pDestFP: PBYTE;
  pInY, pOutY: PByte;
  InStrd: Integer;
  y,x: Cardinal;
  pixels2: TYUV2DWord;
  tmpB: Byte;

  //Effect Matrix (3x3):
  C00, C10, C20,
  C01, C11, C21,
  C02, C12, C22 :PByte;
  C : Integer;
begin
  if (inPicWidth<>outPicWidth)or(Abs(inPicHeight)<>Abs(outPicHeight)) then
  begin
    Result := S_FALSE;
    Exit;
  end;

  pSource.GetPointer(pSourceFP);
  pDest.GetPointer(pDestFP);

  VideoProps.OSD.DrawAll(pSourceFP,inPicWidth,inPicheight);

  Inc(pSourceFP,InTopDelta);
  Inc(pDestFP,OutTopDelta);

  InStrd := InStride;

  // Можно повысить производительность копированием сразу всего буфера (ес-ли InStrd=OutStride)

  //Process Effect:
  if VideoProps.Effect <> efNone then begin
    if pBackBuff=nil then
       pBackBuff := CoTaskMemAlloc( (InStride * inPicHeight) ); //1 pixel = 2 Bytes
    if pBackBuff<>nil then begin
       Move(pSourceFP^,pBackBuff^, (InStride * inPicHeight) );
       pInY  := PByte(Integer(pBackBuff)+InStride);
       pOutY := PByte(Integer(pSourceFP)+InStride);
       for y := 1 to inPicHeight-2 do begin
           for x := 0 to inPicWidth-1 do begin
               C11 := PByte(Cardinal(pInY)+(x*2)); //CurrY (в YUY2 Y-составляющая расположена через один байт)
               C10 := PByte(Integer(C11)-InStride);
               C12 := PByte(Integer(C11)+InStride);

               if x=0 then begin //если начало строки, т.е. первый пиксель в строке
                  C00 := C10;
                  C01 := C11;
                  C02 := C12;
               end else begin
                  C00 := PByte(Cardinal(Pointer(C10))-2);
                  C01 := PByte(Cardinal(Pointer(C11))-2);
                  C02 := PByte(Cardinal(Pointer(C12))-2);
               end;

               if Integer(x)=(inPicWidth-1) then begin //если конец строки, т.е. последний пиксель в строке
                  C20 := C10;
                  C21 := C11;
                  C22 := C12;
               end else begin
                  C20 := PByte(Cardinal(Pointer(C10))+2);
                  C21 := PByte(Cardinal(Pointer(C11))+2);
                  C22 := PByte(Cardinal(Pointer(C12))+2);
               end;

               C:= (Mask[-1,-1]*C00^ + Mask[0,-1]*C01^ + Mask[1,-1]*C02^ +
                    Mask[-1, 0]*C10^ + Mask[0, 0]*C11^ + Mask[1, 0]*C12^ +
                    Mask[-1, 1]*C20^ + Mask[0, 1]*C21^ + Mask[1, 1]*C22^
                   ) div MatrixN;

               if C < 0 then PByte( Cardinal(pOutY)+(x*2) )^ := 0 else
               if C > 255 then PByte( Cardinal(pOutY)+(x*2) )^ := 255 else
                  PByte( Cardinal(pOutY)+(x*2))^ := C;

           end;
         pInY  := PByte(Integer(pInY)+InStrd);
         pOutY := PByte(Integer(pOutY)+InStrd);
       end;
    end;
  end;

  //Process BCS, HFlip, VFlip:
  if VideoProps.VFlip then begin
    pSourceFP := PByte(Integer(pSourceFP)+InStrd*(inPicHeight-1));
    InStrd := -InStrd;
  end;

  for y := 0 to inPicHeight-1 do begin
     if (VideoProps.HFlip)or(VideoProps.VFlip)or (ProcessBCS) or (VideoProps.Effect <> efNone) then begin
        //yNotEnd := Integer(y)<inPicHeight-1;
        for x := 0 to (inPicWidth div 2)-1 do begin
        try
           if ((VideoProps.HFlip) and (not VideoProps.VFlip))or((not VideoProps.HFlip) and (VideoProps.VFlip)) then begin
              pixels2.DW :=  PDWord( Cardinal(pSourceFP)+( ((Cardinal(inPicWidth) div 2)-x-1) shl 2 ) )^;
              //Flip Y pixels:
              tmpB := pixels2.Y;
              pixels2.Y  := pixels2.Y2;
              pixels2.Y2 := tmpB;
           end else begin
              pixels2.DW := PDWord( Cardinal(pSourceFP)+(x shl 2) )^; // x shl 2 = x*4
           end;

           if ProcessBCS then begin
              pixels2.Y  := palY[pixels2.Y];
              pixels2.U  := palU[pixels2.U];
              pixels2.Y2 := palY[pixels2.Y2];
              pixels2.V  := palV[pixels2.V];
           end;
           //
           //pixels2.U := $70; //
           //pixels2.V := $90; // эффект "Старый фильм"

           PDWord( Cardinal(pDestFP)+(x shl 2) )^ := pixels2.DW;
        except Result := S_FALSE; Exit; end;
        end;
     end else
      Move(pSourceFP^,pDestFP^,inPicWidth shl 1); // Size valid _only_ for YUY2!

    pSourceFP := PByte(Integer(pSourceFP)+InStrd);
    pDestFP   := PByte(Integer(pDestFP)+OutStride);
  end;

  Result := S_OK;
end;

function TVideoProcessor.TransformInPlaceYV12;
var
  pSourceFP, pDestFP: PByte;
  pInY, pOutY,
  pInV,pOutV,
  pInU,pOutU: PByte;
  tmpB, tmpB2: Byte;
  InStrd: Integer;
  x, y: Cardinal;
  //Effect Matrix (3x3):
  C00, C10, C20,
  C01, C11, C21,
  C02, C12, C22 :PByte;
  C : Integer;
begin
  if (inPicWidth<>outPicWidth)or(Abs(inPicHeight)<>Abs(outPicHeight)) then begin
    Result := S_FALSE;
    Exit;
  end;

  pSource.GetPointer(pSourceFP);
  pDest.GetPointer(pDestFP);

  Inc(pSourceFP,InTopDelta);
  Inc(pDestFP,OutTopDelta);

  InStrd := InStride;

  if (VideoProps.HFlip)or(VideoProps.VFlip)or(ProcessBCS)or(VideoProps.Effect <> efNone)or(InStride<>OutStride) then begin
    if VideoProps.Effect <> efNone then begin

       if pBackBuff=nil then
          pBackBuff := CoTaskMemAlloc(InStride * inPicHeight);

       if pBackBuff<>nil then begin
          Move(pSourceFP^,pBackBuff^,InStride*inPicHeight);
          pInY  := PByte(Integer(pBackBuff)+InStride);
          pOutY := PByte(Integer(pSourceFP)+InStride);
          for y := 1 to inPicHeight-2 do begin //Начинаем с первого пикселя второй строки и заканчиваем последним пикселом предпоследней строки
              for x := 0 to inPicWidth-1 do begin
                  C11 := PByte(Cardinal(pInY)+x); //CurrY
                  C10 := PByte(Integer(C11)-InStride);
                  C12 := PByte(Integer(C11)+InStride);
                  if x=0 then begin //если начало строки, т.е. первый пиксель в строке
                     C00 := C10;
                     C01 := C11;
                     C02 := C12;
                  end else begin
                     C00 := PByte(Cardinal(Pointer(C10))-1);
                     C01 := PByte(Cardinal(Pointer(C11))-1);
                     C02 := PByte(Cardinal(Pointer(C12))-1);
                  end;
                  if Integer(x)=(inPicWidth-1) then begin //если конец строки, т.е. последний пиксель в строке
                     C20 := C10;
                     C21 := C11;
                     C22 := C12;
                  end else begin
                     C20 := PByte(Cardinal(Pointer(C10))+1);
                     C21 := PByte(Cardinal(Pointer(C11))+1);
                     C22 := PByte(Cardinal(Pointer(C12))+1);
                  end;

                     C:= (Mask[-1,-1]*C00^ + Mask[0,-1]*C01^ + Mask[1,-1]*C02^ +
                          Mask[-1, 0]*C10^ + Mask[0, 0]*C11^ + Mask[1, 0]*C12^ +
                          Mask[-1, 1]*C20^ + Mask[0, 1]*C21^ + Mask[1, 1]*C22^
                         ) div MatrixN;

                  if C < 0 then PByte( Cardinal(pOutY)+x )^ := 0 else
                       if C > 255 then PByte( Cardinal(pOutY)+x )^ := 255 else
                          PByte( Cardinal(pOutY)+x )^ := C;
              end;
              pOutY := PByte(Integer(pOutY)+InStride);
              pInY  := PByte(Integer(pInY)+InStride);
          end;
       end;
    end;

    // Process BCS, HFlip, VFlip:

    pInY  := PByte(pSourceFP);
    pOutY := PByte(pDestFP);

    if VideoProps.VFlip then begin
       pInY   := PByte(Integer(pInY)+InStrd*(inPicHeight-1));
       InStrd := -InStrd;
    end;

    for y := 0 to inPicHeight-1 do begin
        for x := 0 to inPicWidth-1 do begin
            if ((VideoProps.HFlip) and (not VideoProps.VFlip))or((not VideoProps.HFlip) and (VideoProps.VFlip)) then
               tmpB := PByte( Cardinal(pInY)+(Cardinal(inPicWidth)-x-1) )^
             else
               tmpB :=  PByte(Cardinal(pInY)+x)^;
            if (ProcessBCS) then
               tmpB := palY[tmpB];

            PByte( Cardinal(pOutY)+x )^ := tmpB;

        end;
        pOutY := PByte(Integer(pOutY)+OutStride);
        pInY  := PByte(Integer(pInY)+InStrd);
    end;

    //Copy&Process V and U parts of YV12:
    //добавить +выравнивание до 32х бит
    pInV  := PByte( Integer(pSourceFP)+((InStride)*inPicHeight) );
    pOutV := PByte( Integer(pDestFP)+(OutStride*inPicHeight) );

    pInU  := PByte( Integer(pInV)+( ((InStride)*inPicHeight) div 4 ) );
    pOutU := PByte( Integer(pOutV)+( (OutStride*inPicHeight) div 4 ) );

    if InStrd<0 then begin
       pInV  := PByte( Integer(pInV)+((InStride*(inPicHeight)) div 4)-(InStride div 2) );
       pInU  := PByte( Integer(pInU)+((InStride*(inPicHeight)) div 4)-(InStride div 2) );
    end;

    for y := 0 to (inPicHeight div 2)-1 do begin
        for x := 0 to (inPicWidth div 2)-1 do begin
            if ((VideoProps.HFlip) and (not VideoProps.VFlip))or((not VideoProps.HFlip) and (VideoProps.VFlip)) then begin
               tmpB  := PByte( Cardinal(pInV)+(Cardinal(inPicWidth div 2)-x-1) )^;
               tmpB2 := PByte( Cardinal(pInU)+(Cardinal(inPicWidth div 2)-x-1) )^;
            end else begin
               tmpB  := PByte( Cardinal(pInV)+x )^;
               tmpB2 := PByte( Cardinal(pInU)+x )^;
            end;
            if (ProcessBCS) then begin
               PByte( Cardinal(pOutV)+x )^ := palV[tmpB];
               PByte( Cardinal(pOutU)+x )^ := palU[tmpB2];
            end else begin
               PByte( Cardinal(pOutV)+x )^ := tmpB;
               PByte( Cardinal(pOutU)+x )^ := tmpB2;
            end;
        end;

        pInV  := PByte(Integer(pInV)+(InStrd div 2));
        pOutV := PByte(Integer(pOutV)+(OutStride div 2));
        pInU  := PByte(Integer(pInU)+(InStrd div 2));
        pOutU := PByte(Integer(pOutU)+(OutStride div 2));
    end;
  end else
    Move(pSourceFP^,pDestFP^,
      //Y                         //V                            //U
      //(InStrd*inPicHeight)+(InStrd*inPicHeight) div 4+(InStrd*inPicHeight) div 4
      (InStrd*inPicHeight)+((InStrd*inPicHeight) div 2));

  Result := S_OK;
end;

function TVideoProcessor.CheckConnect(direct: TPinDirection; Pin: IPin): HRESULT;
var
  PinInfo:TPinInfo;
  PinsFilterClassID:TGUID;
begin
  Result:=S_OK;
  if direct=PINDIR_INPUT then begin
    if Pin.QueryPinInfo(PinInfo)=S_OK then begin
      if Assigned(PinInfo.pFilter) then
        if PinInfo.pFilter.GetClassID(PinsFilterClassID)=S_OK then
        begin
          if IsEqualGUID(PinsFilterClassID,VideoDecoders[10].CLSID) then begin
            VideoProps.RestrictYV12:=True;
          end;
          if IsEqualGUID(PinsFilterClassID,AdvancedFilters[0].CLSID)
            or IsEqualGUID(PinsFilterClassID,AdvancedFilters[1].CLSID)
          then
            Result:=E_FAIL;
        end;
     end;
  end
end;

function TVideoProcessor.BreakConnect(direct: TPinDirection): HRESULT;
begin
{  if direct=PINDIR_INPUT then begin
  end;}
  Result := S_OK;
end;

function TVideoProcessor.UpdateBCS: HRESULT;
var
  x:Byte;
  t:Integer;
  ix, iy :Integer;
begin
  FLock.Lock;
  try
     Self.VideoProps := VideoProps;
     if    (VideoProps.Br <> 0)
        or (VideoProps.Co <> 0)
        or (VideoProps.Sa <> 0)
        or (VideoProps.Cr <> 0)
        or (VideoProps.Cb <> 0)
     then begin
        //Calculate Palette
        with VideoProps do begin
          for x := 0 to 255 do begin
            t := (x * (Co+100) - 128 * Co) div 100 + Br;
            if t < 0 then palY[x] := 0 else
              if t > 255 then palY[x] := 255 else
                palY[x] := t;

            t := (x * (Sa+100) - 128 * Sa) div 100 + Cb;
            if t < 0 then palU[x] := 0 else
              if t > 255 then palU[x] := 255 else
                palU[x] := t;

            t := (x * (Sa+100) - 128 * Sa) div 100 + Cr;
            if t < 0 then palV[x] := 0 else
              if t > 255 then palV[x] := 255 else
                palV[x] := t;
          end;
        end;
        ProcessBCS := True;
     end else
        ProcessBCS := False;
     //Effect
     case VideoProps.Effect of
          efBlur:     Mask := mBlur;
          efSoften:   Mask := mSoften;
          efSoftenX:  Mask := mGauss;
          efSharpenX: Mask := mLiteSharpness;
          efSharpen:  Mask := mSharpness;
          efEdge:     Mask := mEdge;
          efContour:  Mask := mContour;
     else
          ZeroMemory(@Mask,SizeOf(TVPMatrix));
     end;
     MatrixN := 0;
    for ix := -1 to 1 do begin
      for iy := -1 to 1 do
        MatrixN := MatrixN + Mask[ix, iy];
    end;
    if MatrixN = 0 then MatrixN := 1;
    Result := S_OK;
  finally
    VideoProps.Update:=False;
    FLock.UnLock;
  end;
end;

function TVideoProcessor.GetProps(out Props: PVideoProcProps): HRESULT;
begin
  FLock.Lock;
  try
    Props := @Self.VideoProps;
    Result := S_OK;
  finally
    FLock.UnLock;
  end;
end;

end.
