{*****************************************************************}
{                                                                 }
{            CodeGear Delphi Runtime Library                      }
{            EVR9.pas interface unit                              }
{                                                                 }
{            Copyright (c) 2007 Sebastian Zierer                  }
{            Converted 20 Feb 2007 Sebastian Zierer               }
{            Last modified 19 Apr 2007 Sebastian Zierer           }
{            Version 1.0                                          }
{                                                                 }
{*****************************************************************}

{*****************************************************************}
{                                                                 }
{ The contents of this file are subject to the Mozilla Public     }
{ License Version 1.1 (the "License"). you may not use this file  }
{ except in compliance with the License. You may obtain a copy of }
{ the License at http://www.mozilla.org/MPL/MPL-1.1.html          }
{                                                                 }
{ Software distributed under the License is distributed on an     }
{ "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or  }
{ implied. See the License for the specific language governing    }
{ rights and limitations under the License.                       }
{                                                                 }
{  The original files are:                                        }
{    evr.idl                                                      }
{                                                                 }
{ The original code is: EVR9.pas, released 20 January 2007        }
{                                                                 }
{ The initial developer of the Pascal code is                     }
{ Sebastian Zierer.                                               }
{                                                                 }
{ Portions created by Microsoft are                               }
{ Copyright (C) 1995-2006 Microsoft Corporation.                  }
{                                                                 }
{ Portions created by Sebastian Zierer are                        }
{ Copyright (C) 2007 Sebastian Zierer                             }
{ All Rights Reserved.                                            }
{                                                                 }
{ Contributor(s):                                                 }
{                                                                 }
{ Notes:                                                          }
{                                                                 }
{ Modification history:                                           }
{                                                                 }
{ Known Issues:                                                   }
{                                                                 }
{*****************************************************************}

unit EVR9;

interface

uses
  Windows, ActiveX, DirectShow9;

{$MINENUMSIZE 4}

{$IFNDEF conditionalexpressions}
  {$DEFINE norecprocs}          // Delphi 5 or less
{$ENDIF}

{$IFDEF conditionalexpressions} // Delphi 6+
  {$IF compilerversion < 18}    // Delphi 2005 or less
    {$DEFINE norecprocs}     
  {$IFEND}
{$ENDIF}


//=============================================================================
// Description:
//
//  Service GUID used by IMFGetService::GetService to retrieve interfaces from
//  the renderer or the presenter.
//
const
  SID_IMFVideoProcessor = '{6AB0000C-FECE-4d1f-A2AC-A9573530656E}';
  SID_IMFVideoMixerBitmap = '{814C7B20-0FDB-4eec-AF8F-F957C8F69EDC}';
  SID_IMFStreamSink = '{6ef2a660-47c0-4666-b13d-cbb717f2fa2c}';
  SID_IEVRFilterConfig = '{83E91E85-82C1-4EA7-801D-85DC50B75086}';
  SID_IMFVideoDisplayControl = '{A490B1E4-AB84-4D31-A1B2-181E03B1077A}';
  SID_IMFDesiredSample = '{56C294D0-753E-4260-8D61-A3D8820B1D54}';
  SID_IMFVideoPositionMapper = '{1F6A9F17-E70B-4E24-8AE4-0B2C3BA7A4AE}';
  SID_IMFVideoDeviceID = '{A38D9567-5A9C-4F3C-B293-8EB415B279BA}';
  SID_IMFVideoMixerControl = '{A5C6C53F-C202-4AA5-9695-175BA8C508A5}';
  SID_IMFGetService = '{FA993888-4383-415A-A930-DD472A8CF6F7}';
  SID_IMFVideoRenderer = '{DFDFD197-A9CA-43D8-B341-6AF3503792CD}';
  SID_IMFTrackedSample = '{245BF8E9-0755-40F7-88A5-AE0F18D55E17}';
  SID_IMFTopologyServiceLookup = '{fa993889-4383-415a-a930-dd472a8cf6f7}';
  SID_IMFTopologyServiceLookupClient = '{fa99388a-4383-415a-a930-dd472a8cf6f7}';
  SID_IEVRTrustedVideoPlugin = '{83A4CE40-7710-494b-A893-A472049AF630}';

var
  IID_IMFTrackedSample: TGUID = SID_IMFTrackedSample;
  IID_IMFVideoDisplayControl: TGUID = SID_IMFVideoDisplayControl; // GetService MR_VIDEO_RENDER_SERVICE
  IID_IMFVideoPresenter: TGUID = '{29AFF080-182A-4A5D-AF3B-448F3A6346CB}';
  IID_IMFVideoProcessor: TGUID = SID_IMFVideoProcessor;
  IID_IMFVideoPositionMapper: TGUID = SID_IMFVideoPositionMapper; // GetService MR_VIDEO_RENDER_SERVICE
  IID_IMFDesiredSample: TGUID = SID_IMFDesiredSample;
  IID_IMFVideoMixerControl: TGUID = SID_IMFVideoMixerControl;     // GetService MR_VIDEO_MIXER_SERVICE
  IID_IMFVideoRenderer: TGUID = SID_IMFVideoRenderer;
  IID_IMFVideoDeviceID: TGUID = SID_IMFVideoDeviceID;
  IID_IEVRFilterConfig: TGUID = SID_IEVRFilterConfig;
  IID_IMFTopologyServiceLookup: TGUID = SID_IMFTopologyServiceLookup;
  IID_IMFTopologyServiceLookupClient: TGUID = SID_IMFTopologyServiceLookupClient;
  IID_IEVRTrustedVideoPlugin: TGUID = SID_IEVRTrustedVideoPlugin;

  CLSID_EnhancedVideoRenderer: TGUID = '{FA10746C-9B63-4B6C-BC49-FC300EA5F256}';
  CLSID_MFVideoMixer9: TGUID = '{E474E05A-AB65-4f6A-827C-218B1BAAF31F}';
  CLSID_MFVideoPresenter9: TGUID = '{98455561-5136-4D28-AB08-4CEE40EA2781}';
  CLSID_EVRTearlessWindowPresenter9: TGUID = '{A0A7A57B-59B2-4919-A694-ADD0A526C373}';

  MR_VIDEO_RENDER_SERVICE: TGUID = '{1092A86c-AB1A-459A-A336-831FBC4D11FF}';
  MR_VIDEO_MIXER_SERVICE: TGUID =        '{073cd2fc-6cf4-40b7-8859-e89552c841f8}';
  MR_VIDEO_ACCELERATION_SERVICE: TGUID = '{efef5175-5c7d-4ce2-bbbd-34ff8bca6554}';
  MR_BUFFER_SERVICE: TGUID =             '{a562248c-9ac6-4ffc-9fba-3af8f8ad1a4d}';

  VIDEO_ZOOM_RECT: TGUID = '{7aaa1638-1b7f-4c93-bd89-5b9c9fb6fcf0}';


type
  IMFVideoPositionMapper = interface(IUnknown)
    [SID_IMFVideoPositionMapper]
    function MapOutputCoordinateToInputStream(
      xOut: Single; yOut: Single; dwOutputStreamIndex: DWORD;
      dwInputStreamIndex: DWORD; out pxIn: Single; out pyIn: Single): HResult; stdcall;
  end;

  IMFVideoDeviceID = interface(IUnknown)
    [SID_IMFVideoDeviceID]
    function GetDeviceID(out pDeviceID: TIID): HResult; stdcall;
  end;

const
  MFVideoARMode_None             = $00000000;
  MFVideoARMode_PreservePicture  = $00000001;
  MFVideoARMode_PreservePixel    = $00000002;
  MFVideoARMode_NonLinearStretch = $00000004;
  MFVideoARMode_Mask             = $00000007;

//=============================================================================
// Description:
//
//  The rendering preferences used by the video presenter object.
//
const  // MFVideoRenderPrefs
  // Do not paint color keys (default off)
  MFVideoRenderPrefs_DoNotRenderBorder           = $00000001;
  // Do not clip to monitor that has largest amount of video (default off)
  MFVideoRenderPrefs_DoNotClipToDevice           = $00000002;
  MFVideoRenderPrefs_Mask                        = $00000003;

type
  PMFVideoNormalizedRect = ^TMFVideoNormalizedRect;
  TMFVideoNormalizedRect = record
    left: Single;
    top: Single;
    right: Single;
    bottom: Single;
    {$IFNDEF norecprocs}
    procedure Init(ALeft, ATop, ARight, ABottom: Single);
    {$ENDIF}
  end;

type
  IMFVideoDisplayControl = interface(IUnknown)
    [SID_IMFVideoDisplayControl]
    function GetNativeVideoSize({unique} out pszVideo: TSIZE; {unique} out pszARVideo: TSIZE): HResult; stdcall;
    function GetIdealVideoSize({unique} out pszMin: TSIZE; {unique} out pszMax: TSIZE): HResult; stdcall;
    function SetVideoPosition({unique} pnrcSource: PMFVideoNormalizedRect; {unique} prcDest: PRECT): HResult; stdcall;
    function GetVideoPosition(out pnrcSource: TMFVideoNormalizedRect; out prcDest: TRECT): HResult; stdcall;
    function SetAspectRatioMode(dwAspectRatioMode: DWORD): HResult; stdcall;
    function GetAspectRatioMode(out pdwAspectRatioMode: DWORD): HResult; stdcall;
    function SetVideoWindow(hwndVideo: HWND): HResult; stdcall;
    function GetVideoWindow(out phwndVideo: HWND): HResult; stdcall;
    function RepaintVideo: HResult; stdcall;
    function GetCurrentImage(pBih: PBITMAPINFOHEADER; out lpDib; out pcbDib: DWORD; {unique} pTimeStamp: PInt64): HResult; stdcall;
    function SetBorderColor(Clr: COLORREF): HResult; stdcall;
    function GetBorderColor(out pClr: COLORREF): HResult; stdcall;
    function SetRenderingPrefs(dwRenderFlags: DWORD): HResult; stdcall; // a combination of MFVideoRenderPrefs
    function GetRenderingPrefs(out pdwRenderFlags: DWORD): HResult; stdcall;
    function SetFullscreen(fFullscreen: Boolean): HResult; stdcall;
    function GetFullscreen(out pfFullscreen: Boolean): HResult; stdcall;
  end;

//=============================================================================
// Description:
//
//  The different message types that can be passed to the video presenter via
//  IMFVideoPresenter::ProcessMessage.
//
  TMFVP_MESSAGE_TYPE = (
    // Called by the video renderer when a flush request is received on the
    // reference video stream. In response, the presenter should clear its
    // queue of samples waiting to be presented.
    // ulParam is unused and should be set to zero.
    MFVP_MESSAGE_FLUSH = $00000000,
    // Indicates to the presenter that the current output media type on the
    // mixer has changed. In response, the presenter may now wish to renegotiate
    // the media type of the video mixer.
    // Return Values:
    //  S_OK - successful completion
    //  MF_E_INVALIDMEDIATYPE - The presenter and mixer could not agree on
    //      a media type.
    // ulParam is unused and should be set to zero.
    MFVP_MESSAGE_INVALIDATEMEDIATYPE  = $00000001,
    // Indicates that a sample has been delivered to the video mixer object,
    // and there may now be a sample now available on the mixer's output. In
    // response, the presenter may want to draw frames out of the mixer's
    // output.
    // ulParam is unused and should be set to zero.
    MFVP_MESSAGE_PROCESSINPUTNOTIFY  = $00000002,
    // Called when streaming is about to begin. In
    // response, the presenter should allocate any resources necessary to begin
    // streaming.
    // ulParam is unused and should be set to zero.
    MFVP_MESSAGE_BEGINSTREAMING = $00000003,
    // Called when streaming has completed. In
    // response, the presenter should release any resources that were
    // previously allocated for streaming.
    // ulParam is unused and should be set to zero.
    MFVP_MESSAGE_ENDSTREAMING = $00000004,
    // Indicates that the end of this segment has been reached.
    // When the last frame has been rendered, EC_COMPLETE should be sent
    // on the IMediaEvent interface retrieved from the renderer
    // during IMFTopologyServiceLookupClient::InitServicePointers method.
    // ulParam is unused and should be set to zero.
    MFVP_MESSAGE_ENDOFSTREAM  = $00000005,
    // The presenter should step the number frames indicated by the lower DWORD
    // of ulParam.
    // The first n-1 frames should be skipped and only the nth frame should be
    // shown. Note that this message should only be received while in the pause
    // state or while in the started state when the rate is 0.
    // Otherwise, MF_E_INVALIDREQUEST should be returned.
    // When the nth frame has been shown EC_STEP_COMPLETE
    // should be sent on the IMediaEvent interface.
    // Additionally, if stepping is being done while the rate is set to 0
    // (a.k.a. "scrubbing"), the frame should be displayed immediately when
    // it is received, and EC_SCRUB_TIME should be sent right away after
    // sending EC_STEP_COMPLETE.
    MFVP_MESSAGE_STEP = $00000006,
    // The currently queued step operation should be cancelled. The presenter
    // should remain in the pause state following the cancellation.
    // ulParam is unused and should be set to zero.
    MFVP_MESSAGE_CANCELSTEP = $00000007);

//  IMFVideoPresenter = interface(IMFClockStateSink)
//    ['{29AFF080-182A-4a5d-AF3B-448F3A6346CB}']
//    function ProcessMessage(eMessage: TMFVP_MESSAGE_TYPE; ulParam: ULONG_PTR);
//    function GetCurrentMediaType(out ppMediaType: IMFVideoMediaType);
//  end;

  IMFDesiredSample = interface(IUnknown)
    [SID_IMFDesiredSample]
    function GetDesiredSampleTimeAndDuration(out phnsSampleTime: Int64; out phnsSampleDuration: Int64): HResult; stdcall;
    function SetDesiredSampleTimeAndDuration(hnsSampleTime: Int64; hnsSampleDuration: Int64): HResult; stdcall;
    procedure Clear; stdcall;
  end;

//  IMFTrackedSample = interface(IUnknown)
//    [SID_IMFTrackedSample]
//    function SetAllocator(pSampleAllocator: IMFAsyncCallback; {unique} pUnkState: IUnknown);
//  end;

  IMFVideoMixerControl = interface(IUnknown)
    [SID_IMFVideoMixerControl]
    function SetStreamZOrder(dwStreamID: DWORD; dwZ: DWORD): HResult; stdcall;
    function GetStreamZOrder(dwStreamID: DWORD; out pdwZ: DWORD): HResult; stdcall;
    function SetStreamOutputRect(dwStreamID: DWORD; pnrcOutput: PMFVideoNormalizedRect): HResult; stdcall;
    function GetStreamOutputRect(dwStreamID: DWORD; out pnrcOutput: TMFVideoNormalizedRect): HResult; stdcall;
  end;

//  IMFVideoRenderer = interface(IUnknown)
//    [SID_IMFVideoRenderer]
//    function InitializeRenderer({unique, nil} pVideoMixer: IMFTransform;
//      {unique, nil} pVideoPresenter: IMFVideoPresenter);
//  end;

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

type
  MF_SERVICE_LOOKUP_TYPE = (
    MF_SERVICE_LOOKUP_UPSTREAM,
    MF_SERVICE_LOOKUP_UPSTREAM_DIRECT,
    MF_SERVICE_LOOKUP_DOWNSTREAM,
    MF_SERVICE_LOOKUP_DOWNSTREAM_DIRECT,
    MF_SERVICE_LOOKUP_ALL, // lookup service on any components of the graph
    MF_SERVICE_LOOKUP_GLOBAL); // lookup global objects

  IMFTopologyServiceLookup = interface(IUnknown)
    [SID_IMFTopologyServiceLookup]
    function LookupService(_Type: MF_SERVICE_LOOKUP_TYPE; dwIndex: DWORD;
      const guidService: TIID; {in} const riid: TIID; out ppvObjects; var pnObjects: DWORD): HResult; stdcall;
  end;

  IMFTopologyServiceLookupClient = interface(IUnknown)
    [SID_IMFTopologyServiceLookupClient]
    function InitServicePointers(pLookup: IMFTopologyServiceLookup): HResult; stdcall;
  end;

  IEVRTrustedVideoPlugin = interface(IUnknown)
    [SID_IEVRTrustedVideoPlugin]
    function IsInTrustedVideoMode(out pYes: BOOL): HResult; stdcall;
    function CanConstrict (out pYes: BOOL): HResult; stdcall;
    function SetConstriction(dwKPix: DWORD): HResult; stdcall;
    function DisableImageExport(bDisable: BOOL): HResult; stdcall;
  end;

type
  IEVRFilterConfig = interface(IUnknown)
    [SID_IEVRFilterConfig]
    function SetNumberOfStreams(dwMaxStreams: DWORD): HResult; stdcall;
    function GetNumberOfStreams(out pdwMaxStreams: DWORD): HResult; stdcall;
  end;

  IMFGetService = interface(IUnknown)
    [SID_IMFGetService]
    function GetService(const guidService: TGUID; const IID: TIID; out ppvObject): HResult; stdcall;
  end;

type
  D3DPOOL = DWord;

  TDXVA2_Fixed32 = record
    {$IFNDEF norecprocs}
    procedure Dummy;
    class operator Implicit(Fixed32: TDXVA2_Fixed32): Double;
    class operator Implicit(ADouble: Double): TDXVA2_Fixed32;
    {$ENDIF}
    case Integer of
      0: (Fraction: Word; //USHORT;  (Unsigned SmallInt = Word)
          Value: SHORT);
      1: (ll: LongInt)
  end;

  TDXVA2_VideoProcessorCaps = record
    DeviceCaps: UINT;               // see DXVA2_VPDev_Xxxx
    InputPool: D3DPOOL;
    NumForwardRefSamples: UINT;
    NumBackwardRefSamples: UINT;
    Reserved: UINT;
    DeinterlaceTechnology: UINT;    // see DXVA2_DeinterlaceTech_Xxxx
    ProcAmpControlCaps: UINT;       // see DXVA2_ProcAmp_Xxxx
    VideoProcessorOperations: UINT; // see DXVA2_VideoProcess_Xxxx
    NoiseFilterTechnology: UINT;    // see DXVA2_NoiseFilterTech_Xxxx
    DetailFilterTechnology: UINT;   // see DXVA2_DetailFilterTech_Xxxx
  end;

  TDXVA2_ValueRange = record
    MinValue:     TDXVA2_Fixed32;
    MaxValue:     TDXVA2_Fixed32;
    DefaultValue: TDXVA2_Fixed32;
    StepSize:     TDXVA2_Fixed32;
  end;

  TDXVA2_ProcAmpValues = record
    Brightness: TDXVA2_Fixed32;
    Contrast:   TDXVA2_Fixed32;
    Hue:        TDXVA2_Fixed32;
    Saturation: TDXVA2_Fixed32;
  end;

const
    DXVA2_ProcAmp_None                              = $0000;
    DXVA2_ProcAmp_Brightness                        = $0001;
    DXVA2_ProcAmp_Contrast                          = $0002;
    DXVA2_ProcAmp_Hue                               = $0004;
    DXVA2_ProcAmp_Saturation                        = $0008;
    DXVA2_ProcAmp_Mask                              = $000F;

  DXVA2_VideoProcProgressiveDevice: TGUID = '{5a54a0c9-c7ec-4bd9-8ede-f3c75dc4393b}';
  DXVA2_VideoProcBobDevice        : TGUID = '{335aa36e-7884-43a4-9c91-7f87faf3e37e}';
  DXVA2_VideoProcSoftwareDevice   : TGUID = '{4553d47f-ee7e-4e3f-9475-dbf1376c4810}';


type
  IMFVideoProcessor = interface(IUnknown)
    [SID_IMFVideoProcessor]
    function GetAvailableVideoProcessorModes(var lpdwNumProcessingModes: UINT;
            { [size_is][size_is][out] } out ppVideoProcessingModes {Pointer to Array of GUID}): HResult; stdcall;
    function GetVideoProcessorCaps(lpVideoProcessorMode: PGUID;
      { [out] } out lpVideoProcessorCaps: TDXVA2_VideoProcessorCaps): HResult; stdcall;
    function GetVideoProcessorMode(out lpMode: TGUID): HResult; stdcall;
    function SetVideoProcessorMode(lpMode: PGUID): HResult; stdcall;
    function GetProcAmpRange(dwProperty: DWORD; out pPropRange: TDXVA2_ValueRange): HResult; stdcall;
    function GetProcAmpValues(dwFlags: DWORD; out Values: TDXVA2_ProcAmpValues): HResult; stdcall;
    function SetProcAmpValues(dwFlags: DWORD; {in} const pValues: TDXVA2_ProcAmpValues): HResult; stdcall;
    function GetFilteringRange(dwProperty: DWORD; out pPropRange: TDXVA2_ValueRange): HResult; stdcall;
    function GetFilteringValue(dwProperty: DWORD; out pValue: TDXVA2_Fixed32): HResult; stdcall;
    function SetFilteringValue(dwProperty: DWORD; const pValue: TDXVA2_Fixed32): HResult; stdcall;
    function GetBackgroundColor(out lpClrBkg: COLORREF): HResult; stdcall;
    function SetBackgroundColor(ClrBkg: COLORREF): HResult; stdcall;
  end;

//  TMFVideoAlphaBitmapFlags = (
const
    MFVideoAlphaBitmap_EntireDDS	= $1;
    MFVideoAlphaBitmap_SrcColorKey	= $2;
    MFVideoAlphaBitmap_SrcRect	= $4;
    MFVideoAlphaBitmap_DestRect	= $8;
    MFVideoAlphaBitmap_FilterMode	= $10;
    MFVideoAlphaBitmap_Alpha	= $20;
    MFVideoAlphaBitmap_BitMask	= $3f;

type
  TMFVideoAlphaBitmapParams = record
    dwFlags: DWORD;
    clrSrcKey: COLORREF;
    rcSrc: TRECT;
    nrcDest: TMFVideoNormalizedRect;
    fAlpha: Single;
    dwFilterMode: DWORD;
  end;

  IDirect3DSurface9 = Pointer; // TODO (for now use a pointer to avoid dependencies to DirectX 9 units)

  TMFVideoAlphaBitmap = record
    GetBitmapFromDC: Boolean;
    case Boolean of
      True: (hdc: HDC; params: TMFVideoAlphaBitmapParams);
      False: (pDDS: IDirect3DSurface9; params2: TMFVideoAlphaBitmapParams;);
  end;

  IMFVideoMixerBitmap = interface(IUnknown)
    [SID_IMFVideoMixerBitmap]
    function SetAlphaBitmap(const pBmpParms: TMFVideoAlphaBitmap): HResult; stdcall;
    function ClearAlphaBitmap: HResult; stdcall;
    function UpdateAlphaBitmapParameters(const pBmpParms: TMFVideoAlphaBitmapParams): HResult; stdcall;
    function GetAlphaBitmapParameters(out pBmpParms: TMFVideoAlphaBitmapParams): HResult; stdcall;
  end;

function MFVideoNormalizedRect(const ALeft, ATop, ARight, ABottom: Single): TMFVideoNormalizedRect;

function FloatToFixed(const Float: Double): TDXVA2_Fixed32;
function FixedToFloat(const Fixed: TDXVA2_Fixed32): Double;


implementation

function MFVideoNormalizedRect(const ALeft, ATop, ARight, ABottom: Single): TMFVideoNormalizedRect;
begin
  Result.left := ALeft;
  Result.top := ATop;
  Result.right := ARight;
  Result.bottom := ABottom;
end;

{ TMFVideoNormalizedRect }

{$IFNDEF norecprocs}
procedure TMFVideoNormalizedRect.Init(ALeft, ATop, ARight, ABottom: Single);
begin
  left := ALeft;
  top := ATop;
  right := ARight;
  bottom := ABottom;
end;
{$ENDIF}

{ TDXVA2_Fixed32 }

{$IFNDEF norecprocs}
procedure TDXVA2_Fixed32.Dummy;
begin
  // this is just to make delphi class completion happy
end;

class operator TDXVA2_Fixed32.Implicit(Fixed32: TDXVA2_Fixed32): Double;
begin
  with Fixed32 do
    Result := Value + Fraction / $10000;
end;

class operator TDXVA2_Fixed32.Implicit(ADouble: Double): TDXVA2_Fixed32;
begin
  Result.Fraction := Trunc(Frac(ADouble) * $10000);
  Result.Value := Trunc(ADouble);
end;
{$ENDIF}

function FloatToFixed(const Float: Double): TDXVA2_Fixed32;
begin
  Result.Fraction:=Trunc(Frac(Float)*10000);
  Result.Value:=Trunc(Float);
end;

function FixedToFloat(const Fixed: TDXVA2_Fixed32): Double;
begin
  with Fixed do
    Result := Value + Fraction / $10000;
end;


end.
