(*)
 [------------------------------------------------------------------------------
 [  DirectSound 8.1 Additions by Tim Baumgarten
 [  DirectSound 8.0 Delphi Adaptation by Ivo Steinmann
 [  DirectSound 7.0 Delphi Adaptation by Erik Unger
 [------------------------------------------------------------------------------
 [  Files    : dsound.h
 [             piece of ksmedia.h
 [  Modified : 01-Dec-2001
 [  E-Mail   : isteinmann@bluewin.ch
 [  Download : http://www.crazyentertainment.net
 [  Download : http://www.delphi-jedi.org/DelphiGraphics/
 [------------------------------------------------------------------------------
(*)

(*)
 [------------------------------------------------------------------------------
 [ History :
 [----------
 [  1-Dec-2001 (Tim Baumgarten) : Added DX8.1 functionality
 [------------------------------------------------------------------------------
 [  6-Aug-2001 (Tim Baumgarten) : Corrected in IDirectSoundBuffer :
 [                                "GetCurrentPosition(lpdwCapturePosition,
 [                                 lpdwReadPosition : PDWORD)" to
 [                                "GetCurrentPosition(lpdwPlayPosition,
 [                                 lpdwReadPosition : PDWORD)"
 [------------------------------------------------------------------------------
 [  6-May-2001 (Ivo Steinmann)  : Changed "SetFormat(const lpcfxFormat: TWaveFormatEx)"
 [                                to "SetFormat(lpcfxFormat: PWaveFormatEx)"
 [------------------------------------------------------------------------------
 [ 25-Mar-2001 (Tim Baumgarten) : Changed "lpDSCFXDesc : TDSCEffectDesc" to
 [                                "lpDSCFXDesc : PDSCEffectDesc" in TDSCBufferDesc_DX8
 [------------------------------------------------------------------------------
 * 26-Nov-2000 (Tim Baumgarten) : Returncodes are now typecasted with HResult
 [------------------------------------------------------------------------------
(*)

unit DirectSound8;

{$MINENUMSIZE 4}
{$ALIGN ON}

//{$DEFINE DIRECTX6}
//{$DEFINE DIRECTX7}
{.$DEFINE DIRECTX8}

{$IFNDEF DIRECTX6}
  {$IFNDEF DIRECTX7}
    {$IFNDEF DIRECTX8}
       {$DEFINE DX81}
    {$ENDIF}
  {$ENDIF}
{$ENDIF}         

interface

uses
  Windows,
  MMSystem,
  DirectXGraphics;

var
  DSoundDLL : HMODULE;

(*==========================================================================;
 * Library : dsound.h
 ***************************************************************************)

//
// Forward declarations for interfaces.
// 'struct' not 'class' per the way DECLARE_INTERFACE_ is defined
//
type
  IDirectSound = interface;
  IDirectSoundBuffer = interface;
  IDirectSound3DListener = interface;
  IDirectSound3DBuffer = interface;
  IDirectSoundCapture = interface;
  IDirectSoundCaptureBuffer = interface;
  IDirectSoundNotify = interface;
  IKsPropertySet = interface;

// DirectSound 8.0 Interfaces
  IDirectSound8 = interface;
  IDirectSoundBuffer8 = interface;
  IDirectSoundCaptureBuffer8 = interface;
  IDirectSoundCaptureFXAec8 = interface;
  IDirectSoundCaptureFXNoiseSuppress8 = interface;
  IDirectSoundFullDuplex8 = interface;
  IDirectSoundFXGargle8 = interface;
  IDirectSoundFXChorus8 = interface;
  IDirectSoundFXFlanger8 = interface;
  IDirectSoundFXEcho8 = interface;
  IDirectSoundFXDistortion8 = interface;
  IDirectSoundFXCompressor8 = interface;
  IDirectSoundFXParamEq8 = interface;
  IDirectSoundFXWavesReverb8 = interface;
  IDirectSoundFXI3DL2Reverb8 = interface;


//
// Structures
//

  TD3DValue = single;

  PDS3DBuffer = ^TDS3DBuffer;
  TDS3DBuffer = packed record
    dwSize             : DWORD;
    vPosition          : TD3DVector;
    vVelocity          : TD3DVector;
    dwInsideConeAngle  : DWORD;
    dwOutsideConeAngle : DWORD;
    vConeOrientation   : TD3DVector;
    lConeOutsideVolume : LongInt;
    flMinDistance      : TD3DValue;
    flMaxDistance      : TD3DValue;
    dwMode             : DWORD;
  end;
  TCDS3DBuffer = ^TDS3DBuffer;

  PDS3DListener = ^TDS3DListener;
  TDS3DListener = packed record
    dwSize           : DWORD;
    vPosition        : TD3DVector;
    vVelocity        : TD3DVector;
    vOrientFront     : TD3DVector;
    vOrientTop       : TD3DVector;
    flDistanceFactor : TD3DValue;
    flRolloffFactor  : TD3DValue;
    flDopplerFactor  : TD3DValue;
  end;
  PCDS3DListener = ^TDS3DListener;

  PDSBCaps = ^TDSBCaps;
  TDSBCaps = packed record
    dwSize               : DWORD;
    dwFlags              : DWORD;
    dwBufferBytes        : DWORD;
    dwUnlockTransferRate : DWORD;
    dwPlayCpuOverhead    : DWORD;
  end;
  PCDSBCaps = ^TDSBCaps;

  PDSBPositionNotify = ^TDSBPositionNotify;
  TDSBPositionNotify = packed record
    dwOffset     : DWORD;
    hEventNotify : THandle;
  end;
  PCDSBPositionNotify = ^TDSBPositionNotify;

  TDSBufferDesc_DX6 = packed record
    dwSize        : DWORD;
    dwFlags       : DWORD;
    dwBufferBytes : DWORD;
    dwReserved    : DWORD;
    lpwfxFormat   : PWaveFormatEx;
  end;

  TDSBufferDesc1 = TDSBufferDesc_DX6;
  PDSBufferDesc1 = ^TDSBufferDesc1;
  PCDSBufferDesc1 = PDSBufferDesc1;

  TDSBufferDesc_DX7 = packed record
    dwSize          : DWORD;
    dwFlags         : DWORD;
    dwBufferBytes   : DWORD;
    dwReserved      : DWORD;
    lpwfxFormat     : PWaveFormatEx;
    guid3DAlgorithm : TGUID;
  end;

  TDSBufferDesc_DX8 = packed record
    dwSize          : DWORD;
    dwFlags         : DWORD;
    dwBufferBytes   : DWORD;
    dwReserved      : DWORD;
    lpwfxFormat     : PWaveFormatEx;
    guid3DAlgorithm : TGUID;
  end;

{$IFDEF DIRECTX6}
  TDSBufferDesc = TDSBufferDesc_DX6;
{$ELSE}
  {$IFDEF DIRECTX7}
    TDSBufferDesc = TDSBufferDesc_DX7;
  {$ELSE}
    TDSBufferDesc = TDSBufferDesc_DX8;
  {$ENDIF}
{$ENDIF}

  PDSBufferDesc = ^TDSBufferDesc;
  PCDSBufferDesc = PDSBufferDesc;

  PDSCaps = ^TDSCaps;
  TDSCaps = packed record
    dwSize                        : DWORD;
    dwFlags                       : DWORD;
    dwMinSecondarySampleRate      : DWORD;
    dwMaxSecondarySampleRate      : DWORD;
    dwPrimaryBuffers              : DWORD;
    dwMaxHwMixingAllBuffers       : DWORD;
    dwMaxHwMixingStaticBuffers    : DWORD;
    dwMaxHwMixingStreamingBuffers : DWORD;
    dwFreeHwMixingAllBuffers      : DWORD;
    dwFreeHwMixingStaticBuffers   : DWORD;
    dwFreeHwMixingStreamingBuffers: DWORD;
    dwMaxHw3DAllBuffers           : DWORD;
    dwMaxHw3DStaticBuffers        : DWORD;
    dwMaxHw3DStreamingBuffers     : DWORD;
    dwFreeHw3DAllBuffers          : DWORD;
    dwFreeHw3DStaticBuffers       : DWORD;
    dwFreeHw3DStreamingBuffers    : DWORD;
    dwTotalHwMemBytes             : DWORD;
    dwFreeHwMemBytes              : DWORD;
    dwMaxContigFreeHwMemBytes     : DWORD;
    dwUnlockTransferRateHwBuffers : DWORD;
    dwPlayCpuOverheadSwBuffers    : DWORD;
    dwReserved1                   : DWORD;
    dwReserved2                   : DWORD;
  end;
  PCDSCaps = ^TDSCaps;

  PDSCBCaps = ^TDSCBCaps;
  TDSCBCaps = packed record
    dwSize        : DWORD;
    dwFlags       : DWORD;
    dwBufferBytes : DWORD;
    dwReserved    : DWORD;
  end;
  PCDSCBCaps = ^TDSCBCaps;

  PDSCEffectDesc = ^TDSCEffectDesc;
  TDSCEffectDesc = packed record
    dwSize            : DWORD;
    dwFlags           : DWORD;
    guidDSCFXClass    : TGUID;
    guidDSCFXInstance : TGUID;
    dwReserved1       : DWORD;
    dwReserved2       : DWORD;
  end;
  TCDSCEffectDesc = PDSCEffectDesc;

  TDSCBufferDesc_DX7 = packed record
    dwSize        : DWORD;
    dwFlags       : DWORD;
    dwBufferBytes : DWORD;
    dwReserved    : DWORD;
    lpwfxFormat   : PWaveFormatEx;
  end;
  TDSCBufferDesc_DX6 = TDSCBufferDesc_DX7;

  TDSCBufferDesc_DX8 = packed record
    dwSize        : DWORD;
    dwFlags       : DWORD;
    dwBufferBytes : DWORD;
    dwReserved    : DWORD;
    lpwfxFormat   : PWaveFormatEx;
    dwFXCount     : DWORD;
    lpDSCFXDesc   : PDSCEffectDesc;
  end;

{$IFDEF DIRECTX6}
  TDSCBufferDesc = TDSCBufferDesc_DX6;
{$ELSE}
  {$IFDEF DIRECTX7}
    TDSCBufferDesc = TDSCBufferDesc_DX7;
  {$ELSE}
    TDSCBufferDesc = TDSCBufferDesc_DX8;
  {$ENDIF}
{$ENDIF}

  PDSCBufferDesc = ^TDSCBufferDesc;
  PCDSCBufferDesc = ^TDSCBufferDesc;

  PDSCCaps = ^TDSCCaps;
  TDSCCaps = packed record
    dwSize     : DWORD;
    dwFlags    : DWORD;
    dwFormats  : DWORD;
    dwChannels : DWORD;
  end;
  PCDSCCaps = ^TDSCCaps;

  PDSCFXAec = ^TDSCFXAec;
{$IFNDEF DX81}
  TDSCFXAec = packed record
    fEnable : BOOL;
    fReset  : BOOL;
  end;
{$ELSE}
  TDSCFXAec = packed record
    fEnable    : BOOL;
    fNoiseFill : BOOL;
    dwMode     : LongWord;
  end;
{$ENDIF}
  PCDSCFXAec = ^TDSCFXAec;

  PDSCFXNoiseSuppress = ^TDSCFXNoiseSuppress;
  TDSCFXNoiseSuppress = packed record
    fEnable : BOOL;
{$IFNDEF DX81}
    fReset  : BOOL;
{$ENDIF}    
  end;
  PCDSCFXNoiseSuppress = ^TDSCFXNoiseSuppress;

  PDSEffectDesc = ^TDSEffectDesc;
  TDSEffectDesc = packed record
    dwSize        : DWORD;
    dwFlags       : DWORD;
    guidDSFXClass : TGUID;
    dwReserved1   : DWORD;
    dwReserved2   : DWORD;
  end;
  PCDSEffectDesc = ^TDSEffectDesc;

  PDSFXI3DL2Reverb = ^TDSFXI3DL2Reverb;
  TDSFXI3DL2Reverb = packed record
    lRoom               : Longint;    // [-10000, 0]      default: -1000 mB
    lRoomHF             : Longint;    // [-10000, 0]      default: 0 mB
    flRoomRolloffFactor : single;     // [0.0, 10.0]      default: 0.0
    flDecayTime         : single;     // [0.1, 20.0]      default: 1.49s
    flDecayHFRatio      : single;     // [0.1, 2.0]       default: 0.83
    lReflections        : Longint;    // [-10000, 1000]   default: -2602 mB
    flReflectionsDelay  : single;     // [0.0, 0.3]       default: 0.007 s
    lReverb             : Longint;    // [-10000, 2000]   default: 200 mB
    flReverbDelay       : single;     // [0.0, 0.1]       default: 0.011 s
    flDiffusion         : single;     // [0.0, 100.0]     default: 100.0 %
    flDensity           : single;     // [0.0, 100.0]     default: 100.0 %
    flHFReference       : single;     // [20.0, 20000.0]  default: 5000.0 Hz
  end;
  PCDSFXI3DL2Reverb = ^TDSFXI3DL2Reverb;

  PDSFXChorus = ^TDSFXChorus;
  TDSFXChorus = packed record
    fWetDryMix : single;
    fDepth     : single;
    fFeedback  : single;
    fFrequency : single;
    lWaveform  : Longint;          // LFO shape; DSFXCHORUS_WAVE_xxx
    fDelay     : single;
    lPhase     : Longint;
  end;
  PCDSFXChorus = ^TDSFXChorus;

  PDSFXCompressor = ^TDSFXCompressor;
  TDSFXCompressor = packed record
    fGain      : single;
    fAttack    : single;
    fRelease   : single;
    fThreshold : single;
    fRatio     : single;
    fPredelay  : single;
  end;
  PCDSFXCompressor = ^TDSFXCompressor;

  PDSFXDistortion = ^TDSFXDistortion;
  TDSFXDistortion = packed record
    fGain                  : single;
    fEdge                  : single;
    fPostEQCenterFrequency : single;
    fPostEQBandwidth       : single;
    fPreLowpassCutoff      : single;
  end;
  PCDSFXDistortion = ^TDSFXDistortion;

  PDSFXEcho = ^TDSFXEcho;
  TDSFXEcho = packed record
    fWetDryMix  : single;
    fFeedback   : single;
    fLeftDelay  : single;
    fRightDelay : single;
    lPanDelay   : Longint;
  end;
  PCDSFXEcho = ^TDSFXEcho;

  PDSFXFlanger = ^TDSFXFlanger;
  TDSFXFlanger = packed record
    fWetDryMix : single;
    fDepth     : single;
    fFeedback  : single;
    fFrequency : single;
    lWaveform  : Longint;
    fDelay     : single;
    lPhase     : Longint;
  end;
  PCDSFXFlanger = ^TDSFXFlanger;

  PDSFXGargle = ^TDSFXGargle;
  TDSFXGargle = packed record
    dwRateHz    : DWORD;            // Rate of modulation in hz
    dwWaveShape : DWORD;            // DSFXGARGLE_WAVE_xxx
  end;
  PCDSFXGargle = ^TDSFXGargle;

  PDSFXParamEq = ^TDSFXParamEq;
  TDSFXParamEq = packed record
    fCenter    : single;
    fBandwidth : single;
    fGain      : single;
  end;
  PCDSFXParamEq = ^TDSFXParamEq;

  PDSFXWavesReverb = ^TDSFXWavesReverb;
  TDSFXWavesReverb = packed record
    fInGain          : single;       // [-96.0,0.0]            default: 0.0 dB
    fReverbMix       : single;       // [-96.0,0.0]            default: 0.0 db
    fReverbTime      : single;       // [0.001,3000.0]         default: 1000.0 ms
    fHighFreqRTRatio : single;       // [0.001,0.999]          default: 0.001
  end;
  PCDSFXWavesReverb = ^TDSFXWavesReverb;

  TDSFXI3DL2EnvironmentPreset = (
    DSFX_I3DL2_ENVIRONMENT_PRESET_DEFAULT,
    DSFX_I3DL2_ENVIRONMENT_PRESET_GENERIC,
    DSFX_I3DL2_ENVIRONMENT_PRESET_PADDEDCELL,
    DSFX_I3DL2_ENVIRONMENT_PRESET_ROOM,
    DSFX_I3DL2_ENVIRONMENT_PRESET_BATHROOM,
    DSFX_I3DL2_ENVIRONMENT_PRESET_LIVINGROOM,
    DSFX_I3DL2_ENVIRONMENT_PRESET_STONEROOM,
    DSFX_I3DL2_ENVIRONMENT_PRESET_AUDITORIUM,
    DSFX_I3DL2_ENVIRONMENT_PRESET_CONCERTHALL,
    DSFX_I3DL2_ENVIRONMENT_PRESET_CAVE,
    DSFX_I3DL2_ENVIRONMENT_PRESET_ARENA,
    DSFX_I3DL2_ENVIRONMENT_PRESET_HANGAR,
    DSFX_I3DL2_ENVIRONMENT_PRESET_CARPETEDHALLWAY,
    DSFX_I3DL2_ENVIRONMENT_PRESET_HALLWAY,
    DSFX_I3DL2_ENVIRONMENT_PRESET_STONECORRIDOR,
    DSFX_I3DL2_ENVIRONMENT_PRESET_ALLEY,
    DSFX_I3DL2_ENVIRONMENT_PRESET_FOREST,
    DSFX_I3DL2_ENVIRONMENT_PRESET_CITY,
    DSFX_I3DL2_ENVIRONMENT_PRESET_MOUNTAINS,
    DSFX_I3DL2_ENVIRONMENT_PRESET_QUARRY,
    DSFX_I3DL2_ENVIRONMENT_PRESET_PLAIN,
    DSFX_I3DL2_ENVIRONMENT_PRESET_PARKINGLOT,
    DSFX_I3DL2_ENVIRONMENT_PRESET_SEWERPIPE,
    DSFX_I3DL2_ENVIRONMENT_PRESET_UNDERWATER,
    DSFX_I3DL2_ENVIRONMENT_PRESET_SMALLROOM,
    DSFX_I3DL2_ENVIRONMENT_PRESET_MEDIUMROOM,
    DSFX_I3DL2_ENVIRONMENT_PRESET_LARGEROOM,
    DSFX_I3DL2_ENVIRONMENT_PRESET_MEDIUMHALL,
    DSFX_I3DL2_ENVIRONMENT_PRESET_LARGEHALL,
    DSFX_I3DL2_ENVIRONMENT_PRESET_PLATE
  );

  TDSFXI3DL2MaterialPreset = (
    DSFX_I3DL2_MATERIAL_PRESET_SINGLEWINDOW,
    DSFX_I3DL2_MATERIAL_PRESET_DOUBLEWINDOW,
    DSFX_I3DL2_MATERIAL_PRESET_THINDOOR,
    DSFX_I3DL2_MATERIAL_PRESET_THICKDOOR,
    DSFX_I3DL2_MATERIAL_PRESET_WOODWALL,
    DSFX_I3DL2_MATERIAL_PRESET_BRICKWALL,
    DSFX_I3DL2_MATERIAL_PRESET_STONEWALL,
    DSFX_I3DL2_MATERIAL_PRESET_CURTAIN
  );

//
// DirectSound API
//
  TDSEnumCallbackW = function (lpGuid: PGUID; lpstrDescription: PWideChar;
      lpstrModule: PWideChar; lpContext: Pointer) : BOOL; stdcall;
  TDSEnumCallbackA = function (lpGuid: PGUID; lpstrDescription: PAnsiChar;
      lpstrModule: PAnsiChar; lpContext: Pointer) : BOOL; stdcall;
{$IFDEF UNICODE}
  TDSEnumCallback = TDSEnumCallbackW;
{$ELSE}
  TDSEnumCallback = TDSEnumCallbackA;
{$ENDIF}

//
// IDirectSound
//
  PIDirectSound = ^IDirectSound;
  IDirectSound = interface (IUnknown)
    ['{279AFA83-4981-11CE-A521-0020AF0BE560}']
    // IDirectSound methods
    function CreateSoundBuffer(const lpDSBufferDesc: TDSBufferDesc;
        out lpIDirectSoundBuffer: IDirectSoundBuffer;
        pUnkOuter: IUnknown) : HResult; stdcall;
    function GetCaps(var lpDSCaps: TDSCaps) : HResult; stdcall;
    function DuplicateSoundBuffer(lpDsbOriginal: IDirectSoundBuffer;
        out lpDsbDuplicate: IDirectSoundBuffer) : HResult; stdcall;
    function SetCooperativeLevel(hwnd: HWND; dwLevel: DWORD) : HResult; stdcall;
    function Compact: HResult; stdcall;
    function GetSpeakerConfig(var lpdwSpeakerConfig: DWORD) : HResult; stdcall;
    function SetSpeakerConfig(dwSpeakerConfig: DWORD) : HResult; stdcall;
    function Initialize(lpGuid: PGUID) : HResult; stdcall;
  end;

//
// IDirectSound8
//
  IDirectSound8 = interface (IDirectSound)
    ['{C50A7E93-F395-4834-9EF6-7FA99DE50966}']
    // IDirectSound8 methods
    function VerifyCertification(out pdwCertified: DWORD): HResult; stdcall;
  end;

//
// IDirectSoundBuffer
//
  IDirectSoundBuffer = interface (IUnknown)
    ['{279AFA85-4981-11CE-A521-0020AF0BE560}']
    // IDirectSoundBuffer methods
    function GetCaps(var lpDSCaps: TDSBCaps) : HResult; stdcall;
    function GetCurrentPosition
        (lpdwPlayPosition, lpdwReadPosition : PDWORD) : HResult; stdcall;
    function GetFormat(lpwfxFormat: PWaveFormatEx; dwSizeAllocated: DWORD;
        lpdwSizeWritten: PDWORD) : HResult; stdcall;
    function GetVolume(var lplVolume: integer) : HResult; stdcall;
    function GetPan(var lplPan: integer) : HResult; stdcall;
    function GetFrequency(var lpdwFrequency: DWORD) : HResult; stdcall;
    function GetStatus(var lpdwStatus: DWORD) : HResult; stdcall;
    function Initialize(lpDirectSound: IDirectSound;
        const lpcDSBufferDesc: TDSBufferDesc) : HResult; stdcall;
    function Lock(dwWriteCursor, dwWriteBytes: DWORD;
        var lplpvAudioPtr1: Pointer; var lpdwAudioBytes1: DWORD;
        var lplpvAudioPtr2: Pointer; var lpdwAudioBytes2: DWORD;
        dwFlags: DWORD) : HResult; stdcall;
    function Play(dwReserved1,dwReserved2,dwFlags: DWORD) : HResult; stdcall;
    function SetCurrentPosition(dwPosition: DWORD) : HResult; stdcall;
    function SetFormat(lpcfxFormat: PWaveFormatEx) : HResult; stdcall;
    function SetVolume(lVolume: integer) : HResult; stdcall;
    function SetPan(lPan: integer) : HResult; stdcall;
    function SetFrequency(dwFrequency: DWORD) : HResult; stdcall;
    function Stop: HResult; stdcall;
    function Unlock(lpvAudioPtr1: Pointer; dwAudioBytes1: DWORD;
        lpvAudioPtr2: Pointer; dwAudioBytes2: DWORD) : HResult; stdcall;
    function Restore: HResult; stdcall;
  end;

//
// IDirectSoundBuffer8
//
  IDirectSoundBuffer8 = interface (IDirectSoundBuffer)
    ['{6825a449-7524-4d82-920f-50e36ab3ab1e}']
    // IDirectSoundBuffer8 methods
    function SetFX(dwEffectsCount: DWORD; pDSFXDesc: PDSEffectDesc;
        pdwResultCodes: PDWORD): HResult; stdcall;
    function AcquireResources(dwFlags, dwEffectsCount: DWORD;
        pdwResultCodes: PDWORD): HResult; stdcall;
    function GetObjectInPath(const rguidObject: TGUID; dwIndex: DWORD;
        const rguidInterface: TGUID; out ppObject): HResult; stdcall;
  end;

//
// IDirectSound3DListener
//
  IDirectSound3DListener = interface (IUnknown)
    ['{279AFA84-4981-11CE-A521-0020AF0BE560}']
    // IDirectSound3DListener methods
    function GetAllParameters(var lpListener: TDS3DListener) : HResult; stdcall;
    function GetDistanceFactor(var lpflDistanceFactor: TD3DValue) : HResult; stdcall;
    function GetDopplerFactor(var lpflDopplerFactor: TD3DValue) : HResult; stdcall;
    function GetOrientation
        (var lpvOrientFront, lpvOrientTop: TD3DVector) : HResult; stdcall;
    function GetPosition(var lpvPosition: TD3DVector) : HResult; stdcall;
    function GetRolloffFactor(var lpflRolloffFactor: TD3DValue) : HResult; stdcall;
    function GetVelocity(var lpvVelocity: TD3DVector) : HResult; stdcall;
    function SetAllParameters
        (const lpcListener: TDS3DListener; dwApply: DWORD) : HResult; stdcall;
    function SetDistanceFactor
        (flDistanceFactor: TD3DValue; dwApply: DWORD) : HResult; stdcall;
    function SetDopplerFactor
        (flDopplerFactor: TD3DValue; dwApply: DWORD) : HResult; stdcall;
    function SetOrientation(xFront, yFront, zFront, xTop, yTop, zTop: TD3DValue;
        dwApply: DWORD) : HResult; stdcall;
    function SetPosition(x, y, z: TD3DValue; dwApply: DWORD) : HResult; stdcall;
    function SetRolloffFactor
        (flRolloffFactor: TD3DValue; dwApply: DWORD) : HResult; stdcall;
    function SetVelocity(x, y, z: TD3DValue; dwApply: DWORD) : HResult; stdcall;
    function CommitDeferredSettings: HResult; stdcall;
  end;

//
// IDirectSound3DListener8
//
  IDirectSound3DListener8 = IDirectSound3DListener;

//
// IDirectSound3DBuffer
//
  IDirectSound3DBuffer = interface (IUnknown)
    ['{279AFA86-4981-11CE-A521-0020AF0BE560}']
    // IDirectSoundBuffer3D methods
    function GetAllParameters(var lpDs3dBuffer: TDS3DBuffer) : HResult; stdcall;
    function GetConeAngles
        (var lpdwInsideConeAngle, lpdwOutsideConeAngle: DWORD) : HResult; stdcall;
    function GetConeOrientation(var lpvOrientation: TD3DVector) : HResult; stdcall;
    function GetConeOutsideVolume(var lplConeOutsideVolume: integer) : HResult; stdcall;
    function GetMaxDistance(var lpflMaxDistance: TD3DValue) : HResult; stdcall;
    function GetMinDistance(var lpflMinDistance: TD3DValue) : HResult; stdcall;
    function GetMode(var lpdwMode: DWORD) : HResult; stdcall;
    function GetPosition(var lpvPosition: TD3DVector) : HResult; stdcall;
    function GetVelocity(var lpvVelocity: TD3DVector) : HResult; stdcall;
    function SetAllParameters
        (const lpcDs3dBuffer: TDS3DBuffer; dwApply: DWORD) : HResult; stdcall;
    function SetConeAngles
        (dwInsideConeAngle, dwOutsideConeAngle, dwApply: DWORD) : HResult; stdcall;
    function SetConeOrientation(x, y, z: TD3DValue; dwApply: DWORD) : HResult; stdcall;
    function SetConeOutsideVolume
        (lConeOutsideVolume: LongInt; dwApply: DWORD) : HResult; stdcall;
    function SetMaxDistance(flMaxDistance: TD3DValue; dwApply: DWORD) : HResult; stdcall;
    function SetMinDistance(flMinDistance: TD3DValue; dwApply: DWORD) : HResult; stdcall;
    function SetMode(dwMode: DWORD; dwApply: DWORD) : HResult; stdcall;
    function SetPosition(x, y, z: TD3DValue; dwApply: DWORD) : HResult; stdcall;
    function SetVelocity(x, y, z: TD3DValue; dwApply: DWORD) : HResult; stdcall;
  end;

//
// IDirectSound3DBuffer8
//
  IDirectSound3DBuffer8 = IDirectSound3DBuffer;

//
// IDirectSoundCapture
//
  IDirectSoundCapture = interface (IUnknown)
    ['{b0210781-89cd-11d0-af08-00a0c925cd16}']
    // IDirectSoundCapture methods
    function CreateCaptureBuffer(const lpDSCBufferDesc: TDSCBufferDesc;
        var lplpDirectSoundCaptureBuffer: IDirectSoundCaptureBuffer;
        pUnkOuter: IUnknown) : HResult; stdcall;
    function GetCaps(var lpdwCaps: TDSCCaps) : HResult; stdcall;
    function Initialize(lpGuid: PGUID) : HResult; stdcall;
  end;

//
// IDirectSoundCapture8
//
  IDirectSoundCapture8 = IDirectSoundCapture;

//
// IDirectSoundCaptureBuffer
//
  IDirectSoundCaptureBuffer = interface (IUnknown)
    ['{b0210782-89cd-11d0-af08-00a0c925cd16}']
    // IDirectSoundCaptureBuffer methods
    function GetCaps(var lpdwCaps: TDSCBCaps) : HResult; stdcall;
    function GetCurrentPosition
        (lpdwCapturePosition, lpdwReadPosition: PDWORD) : HResult; stdcall;
    function GetFormat(lpwfxFormat: PWaveFormatEx; dwSizeAllocated: DWORD;
        lpdwSizeWritten : PDWORD) : HResult; stdcall;
    function GetStatus(var lpdwStatus: DWORD) : HResult; stdcall;
    function Initialize(lpDirectSoundCapture: IDirectSoundCapture;
        const lpcDSBufferDesc: TDSCBufferDesc) : HResult; stdcall;
    function Lock(dwReadCursor, dwReadBytes: DWORD;
        var lplpvAudioPtr1: Pointer; var lpdwAudioBytes1: DWORD;
        var lplpvAudioPtr2: Pointer; var lpdwAudioBytes2: DWORD;
        dwFlags: DWORD) : HResult; stdcall;
    function Start(dwFlags: DWORD) : HResult; stdcall;
    function Stop: HResult; stdcall;
    function Unlock(lpvAudioPtr1: Pointer; dwAudioBytes1: DWORD;
        lpvAudioPtr2: Pointer; dwAudioBytes2: DWORD) : HResult; stdcall;
  end;

//
// IDirectSoundCaptureBuffer8
//
  IDirectSoundCaptureBuffer8 = interface (IDirectSoundCaptureBuffer)
    ['{00990df4-0dbb-4872-833e-6d303e80aeb6}']
    // IDirectSoundCaptureBuffer8 methods
    function GetObjectInPath(const rguidObject: TGUID; dwIndex: DWORD;
        const rguidInterface: TGUID; out ppObject): HResult; stdcall;
    function GetFXStatus(dwFXCount: DWORD; pdwFXStatus: PDWORD): HResult; stdcall;
  end;

//
// IDirectSoundCaptureFXAec8
//
{$IFNDEF DX81}
  IDirectSoundCaptureFXAec8 = interface (IUnknown)
    ['{174D3EB9-6696-4FAC-A46C-A0AC7BC9E20F}']
    // IDirectSoundCaptureFXAec8 methods
    function SetAllParameters(const pDscFxAec: TDSCFXAec): HResult; stdcall;
    function GetAllParameters(out pDscFxAec: TDSCFXAec): HResult; stdcall;
  end;
{$ELSE}
  IDirectSoundCaptureFXAec8 = interface (IUnknown)
    ['{AD74143D-903D-4AB7-8066-28D363036D65}']
    // IDirectSoundCaptureFXAec8 methods
    function SetAllParameters(const pDscFxAec : TDSCFXAec): HResult; stdcall;
    function GetAllParameters(out pDscFxAec : TDSCFXAec) : HResult; stdcall;
    function GetStatus(out pdwStatus : LongWord) : HResult; stdcall;
    function Reset : HResult; stdcall;
  end;
{$ENDIF}
//
// IDirectSoundCaptureFXNoiseSuppress8
//
  IDirectSoundCaptureFXNoiseSuppress8 = interface (IUnknown)
    ['{ED311E41-FBAE-4175-9625-CD0854F693CA}']
    // IDirectSoundCaptureFXNoiseSuppress8 methods
    function SetAllParameters(const pcDscFxNoiseSuppress : TDSCFXNoiseSuppress) : HResult; stdcall;
    function GetAllParameters(out pDscFxNoiseSuppress : TDSCFXNoiseSuppress) : HResult; stdcall;
{$IFDEF DX81}
    function Reset : HResult; stdcall;
{$ENDIF}
  end;

//
// IDirectSoundFullDuplex8
//
  IDirectSoundFullDuplex8 = interface (IUnknown)
    ['{edcb4c7a-daab-4216-a42e-6c50596ddc1d}']
    // IDirectSoundFullDuplex methods
    function Initialize(pCaptureGuid, pRenderGuid: PGUID; lpDscBufferDesc: PCDSCBufferDesc;
        lpDsBufferDesc: PCDSBufferDesc; hWnd: hWnd; dwLevel: DWORD;
        out lplpDirectSoundCaptureBuffer8: IDirectSoundCaptureBuffer8;
        out lplpDirectSoundBuffer8: IDirectSoundBuffer8): HResult; stdcall;
  end;

//
// IDirectSoundFXGargle8
//
  IDirectSoundFXGargle8 = interface (IUnknown)
    ['{d616f352-d622-11ce-aac5-0020af0b99a3}']
    function SetAllParameters(const pcDsFxGargle: TDSFXGargle): HResult; stdcall;
    function GetAllParameters(out pDsFxGargle: TDSFXGargle): HResult; stdcall;
  end;

//
// IDirectSoundFXChorus8
//
  IDirectSoundFXChorus8 = interface (IUnknown)
    ['{880842e3-145f-43e6-a934-a71806e50547}']
    function SetAllParameters(const pcDsFxChorus: TDSFXChorus): HResult; stdcall;
    function GetAllParameters(out pDsFxChorus: TDSFXChorus): HResult; stdcall;
  end;

//
// IDirectSoundFXFlanger8
//
  IDirectSoundFXFlanger8 = interface (IUnknown)
    ['{903e9878-2c92-4072-9b2c-ea68f5396783}']
    function SetAllParameters(const pcDsFxFlanger: TDSFXFlanger): HResult; stdcall;
    function GetAllParameters(out pDsFxFlanger: TDSFXFlanger): HResult; stdcall;
  end;

//
// IDirectSoundFXEcho8
//
  IDirectSoundFXEcho8 = interface (IUnknown)
    ['{8bd28edf-50db-4e92-a2bd-445488d1ed42}']
    function SetAllParameters(const pcDsFxEcho: TDSFXEcho): HResult; stdcall;
    function GetAllParameters(out pDsFxEcho: TDSFXEcho): HResult; stdcall;
  end;

//
// IDirectSoundFXDistortion8
//
  IDirectSoundFXDistortion8 = interface (IUnknown)
    ['{8ecf4326-455f-4d8b-bda9-8d5d3e9e3e0b}']
    function SetAllParameters(const pcDsFxDistortion: TDSFXDistortion): HResult; stdcall;
    function GetAllParameters(out pDsFxDistortion: TDSFXDistortion): HResult; stdcall;
  end;

//
// IDirectSoundFXCompressor8
//
  IDirectSoundFXCompressor8 = interface (IUnknown)
    ['{4bbd1154-62f6-4e2c-a15c-d3b6c417f7a0}']
    function SetAllParameters(const pcDsFxCompressor: TDSFXCompressor): HResult; stdcall;
    function GetAllParameters(out pDsFxCompressor: TDSFXCompressor): HResult; stdcall;
  end;

//
// IDirectSoundFXParamEq8
//
  IDirectSoundFXParamEq8 = interface (IUnknown)
    ['{c03ca9fe-fe90-4204-8078-82334cd177da}']
    function SetAllParameters(const pcDsFxParamEq: TDSFXParamEq): HResult; stdcall;
    function GetAllParameters(out pDsFxParamEq: TDSFXParamEq): HResult; stdcall;
  end;

//
// IDirectSoundFXI3DL2Reverb8
//
  IDirectSoundFXI3DL2Reverb8 = interface (IUnknown)
    ['{4b166a6a-0d66-43f3-80e3-ee6280dee1a4}']
    function SetAllParameters(const pcDsFxI3DL2Reverb: TDSFXI3DL2Reverb): HResult; stdcall;
    function GetAllParameters(out pDsFxI3DL2Reverb: TDSFXI3DL2Reverb): HResult; stdcall;
    function SetPreset(dwPreset: DWORD): HResult; stdcall;
    function GetPreset(out dwPreset: DWORD): HResult; stdcall;
    function SetQuality(lQuality: Longint): HResult; stdcall;
    function GetQuality(out plQuality: Longint): HResult; stdcall;
  end;

//
// IDirectSoundFXWavesReverb8
//
  IDirectSoundFXWavesReverb8 = interface (IUnknown)
    ['{46858c3a-0dc6-45e3-b760-d4eef16cb325}']
    function SetAllParameters(const pcDsFxWavesReverb: TDSFXWavesReverb): HResult; stdcall;
    function GetAllParameters(out pDsFxWavesReverb: TDSFXWavesReverb): HResult; stdcall;
  end;

//
// IDirectSoundNotify
//
  IDirectSoundNotify = interface (IUnknown)
    ['{b0210783-89cd-11d0-af08-00a0c925cd16}']
    // IDirectSoundNotify methods
    function SetNotificationPositions(cPositionNotifies: DWORD;
        lpcPositionNotifies: PDSBPositionNotify) : HResult; stdcall;
  end;

//
// IDirectSoundNotify8
//
  IDirectSoundNotify8 = IDirectSoundNotify;

//
// IKsPropertySet
//
  IKsPropertySet = interface (IUnknown)
    ['{31efac30-515c-11d0-a9aa-00aa0061be93}']
    // IKsPropertySet methods
    function Get(const rguidPropSet: TGUID; ulId: DWORD; pInstanceData: pointer;
        ulInstanceLength: DWORD; pPropertyData: pointer; ulDataLength: DWORD;
        var pulBytesReturned: DWORD) : HResult; stdcall;
    // Warning: The following method is defined as Set() in DirectX
    //          which is a reserved word in Delphi!
    function SetProperty(const rguidPropSet: TGUID; ulId: DWORD;
        pInstanceData: pointer; ulInstanceLength: DWORD;
        pPropertyData: pointer; pulDataLength: DWORD) : HResult; stdcall;
    function QuerySupport(const rguidPropSet: TGUID; ulId: DWORD;
        var pulTypeSupport: DWORD) : HResult; stdcall;
  end;


const
  KSPROPERTY_SUPPORT_GET                      = $00000001;
  KSPROPERTY_SUPPORT_SET                      = $00000002;

  DSFXR_PRESENT                               = 0;
  DSFXR_LOCHARDWARE                           = 1;
  DSFXR_LOCSOFTWARE                           = 2;
  DSFXR_UNALLOCATED                           = 3;
  DSFXR_FAILED                                = 4;
  DSFXR_UNKNOWN                               = 5;
  DSFXR_SENDLOOP                              = 6;

  DSFXGARGLE_WAVE_TRIANGLE                    = 0;
  DSFXGARGLE_WAVE_SQUARE                      = 1;
  DSFXGARGLE_RATEHZ_MIN                       = 1;
  DSFXGARGLE_RATEHZ_MAX                       = 1000;

  DSFXCHORUS_WAVE_TRIANGLE                    = 0;
  DSFXCHORUS_WAVE_SIN                         = 1;

  DSFXCHORUS_WETDRYMIX_MIN                    = 0.0;
  DSFXCHORUS_WETDRYMIX_MAX                    = 100.0;
  DSFXCHORUS_DEPTH_MIN                        = 0.0;
  DSFXCHORUS_DEPTH_MAX                        = 100.0;
  DSFXCHORUS_FEEDBACK_MIN                     = -99.0;
  DSFXCHORUS_FEEDBACK_MAX                     = 99.0;
  DSFXCHORUS_FREQUENCY_MIN                    = 0.0;
  DSFXCHORUS_FREQUENCY_MAX                    = 10.0;
  DSFXCHORUS_DELAY_MIN                        = 0.0;
  DSFXCHORUS_DELAY_MAX                        = 20.0;
  DSFXCHORUS_PHASE_MIN                        = 0;
  DSFXCHORUS_PHASE_MAX                        = 4;

  DSFXCHORUS_PHASE_NEG_180                    = 0;
  DSFXCHORUS_PHASE_NEG_90                     = 1;
  DSFXCHORUS_PHASE_ZERO                       = 2;
  DSFXCHORUS_PHASE_90                         = 3;
  DSFXCHORUS_PHASE_180                        = 4;

  DSFXFLANGER_WAVE_TRIANGLE                   = 0;
  DSFXFLANGER_WAVE_SIN                        = 1;

  DSFXFLANGER_WETDRYMIX_MIN                   = 0.0;
  DSFXFLANGER_WETDRYMIX_MAX                   = 100.0;
  DSFXFLANGER_FREQUENCY_MIN                   = 0.0;
  DSFXFLANGER_FREQUENCY_MAX                   = 10.0;
  DSFXFLANGER_DEPTH_MIN                       = 0.0;
  DSFXFLANGER_DEPTH_MAX                       = 100.0;
  DSFXFLANGER_PHASE_MIN                       = 0;
  DSFXFLANGER_PHASE_MAX                       = 4;
  DSFXFLANGER_FEEDBACK_MIN                    = -99.0;
  DSFXFLANGER_FEEDBACK_MAX                    = 99.0;
  DSFXFLANGER_DELAY_MIN                       = 0.0;
  DSFXFLANGER_DELAY_MAX                       = 4.0;

  DSFXFLANGER_PHASE_NEG_180                   = 0;
  DSFXFLANGER_PHASE_NEG_90                    = 1;
  DSFXFLANGER_PHASE_ZERO                      = 2;
  DSFXFLANGER_PHASE_90                        = 3;
  DSFXFLANGER_PHASE_180                       = 4;

  DSFXECHO_WETDRYMIX_MIN                      = 0.0;
  DSFXECHO_WETDRYMIX_MAX                      = 100.0;
  DSFXECHO_FEEDBACK_MIN                       = 0.0;
  DSFXECHO_FEEDBACK_MAX                       = 100.0;
  DSFXECHO_LEFTDELAY_MIN                      = 1.0;
  DSFXECHO_LEFTDELAY_MAX                      = 2000.0;
  DSFXECHO_RIGHTDELAY_MIN                     = 1.0;
  DSFXECHO_RIGHTDELAY_MAX                     = 2000.0;
  DSFXECHO_PANDELAY_MIN                       = 0;
  DSFXECHO_PANDELAY_MAX                       = 1;

  DSFXDISTORTION_GAIN_MIN                     = -60.0;
  DSFXDISTORTION_GAIN_MAX                     = 0.0;
  DSFXDISTORTION_EDGE_MIN                     = 0.0;
  DSFXDISTORTION_EDGE_MAX                     = 100.0;
  DSFXDISTORTION_POSTEQCENTERFREQUENCY_MIN    = 100.0;
  DSFXDISTORTION_POSTEQCENTERFREQUENCY_MAX    = 8000.0;
  DSFXDISTORTION_POSTEQBANDWIDTH_MIN          = 100.0;
  DSFXDISTORTION_POSTEQBANDWIDTH_MAX          = 8000.0;
  DSFXDISTORTION_PRELOWPASSCUTOFF_MIN         = 100.0;
  DSFXDISTORTION_PRELOWPASSCUTOFF_MAX         = 8000.0;

  DSFXCOMPRESSOR_GAIN_MIN                     = -60.0;
  DSFXCOMPRESSOR_GAIN_MAX                     = 60.0;
  DSFXCOMPRESSOR_ATTACK_MIN                   = 0.01;
  DSFXCOMPRESSOR_ATTACK_MAX                   = 500.0;
  DSFXCOMPRESSOR_RELEASE_MIN                  = 50.0;
  DSFXCOMPRESSOR_RELEASE_MAX                  = 3000.0;
  DSFXCOMPRESSOR_THRESHOLD_MIN                = -60.0;
  DSFXCOMPRESSOR_THRESHOLD_MAX                = 0.0;
  DSFXCOMPRESSOR_RATIO_MIN                    = 1.0;
  DSFXCOMPRESSOR_RATIO_MAX                    = 100.0;
  DSFXCOMPRESSOR_PREDELAY_MIN                 = 0.0;
  DSFXCOMPRESSOR_PREDELAY_MAX                 = 4.0;

  DSFXPARAMEQ_CENTER_MIN                      = 80.0;
  DSFXPARAMEQ_CENTER_MAX                      = 16000.0;
  DSFXPARAMEQ_BANDWIDTH_MIN                   = 1.0;
  DSFXPARAMEQ_BANDWIDTH_MAX                   = 36.0;
  DSFXPARAMEQ_GAIN_MIN                        = -15.0;
  DSFXPARAMEQ_GAIN_MAX                        = 15.0;

  DSFX_I3DL2REVERB_ROOM_MIN                   = (-10000);
  DSFX_I3DL2REVERB_ROOM_MAX                   = 0;
  DSFX_I3DL2REVERB_ROOM_DEFAULT               = (-1000);

  DSFX_I3DL2REVERB_ROOMHF_MIN                 = (-10000);
  DSFX_I3DL2REVERB_ROOMHF_MAX                 = 0;
  DSFX_I3DL2REVERB_ROOMHF_DEFAULT             = (-100);

  DSFX_I3DL2REVERB_ROOMROLLOFFFACTOR_MIN      = 0.0;
  DSFX_I3DL2REVERB_ROOMROLLOFFFACTOR_MAX      = 10.0;
  DSFX_I3DL2REVERB_ROOMROLLOFFFACTOR_DEFAULT  = 0.0;

  DSFX_I3DL2REVERB_DECAYTIME_MIN              = 0.1;
  DSFX_I3DL2REVERB_DECAYTIME_MAX              = 20.0;
  DSFX_I3DL2REVERB_DECAYTIME_DEFAULT          = 1.49;

  DSFX_I3DL2REVERB_DECAYHFRATIO_MIN           = 0.1;
  DSFX_I3DL2REVERB_DECAYHFRATIO_MAX           = 2.0;
  DSFX_I3DL2REVERB_DECAYHFRATIO_DEFAULT       = 0.83;

  DSFX_I3DL2REVERB_REFLECTIONS_MIN            = (-10000);
  DSFX_I3DL2REVERB_REFLECTIONS_MAX            = 1000;
  DSFX_I3DL2REVERB_REFLECTIONS_DEFAULT        = (-2602);

  DSFX_I3DL2REVERB_REFLECTIONSDELAY_MIN       = 0.0;
  DSFX_I3DL2REVERB_REFLECTIONSDELAY_MAX       = 0.3;
  DSFX_I3DL2REVERB_REFLECTIONSDELAY_DEFAULT   = 0.007;

  DSFX_I3DL2REVERB_REVERB_MIN                 = (-10000);
  DSFX_I3DL2REVERB_REVERB_MAX                 = 2000;
  DSFX_I3DL2REVERB_REVERB_DEFAULT             = (200);

  DSFX_I3DL2REVERB_REVERBDELAY_MIN            = 0.0;
  DSFX_I3DL2REVERB_REVERBDELAY_MAX            = 0.1;
  DSFX_I3DL2REVERB_REVERBDELAY_DEFAULT        = 0.011;
                                                    
  DSFX_I3DL2REVERB_DIFFUSION_MIN              = 0.0;
  DSFX_I3DL2REVERB_DIFFUSION_MAX              = 100.0;
  DSFX_I3DL2REVERB_DIFFUSION_DEFAULT          = 100.0;

  DSFX_I3DL2REVERB_DENSITY_MIN                = 0.0;
  DSFX_I3DL2REVERB_DENSITY_MAX                = 100.0;
  DSFX_I3DL2REVERB_DENSITY_DEFAULT            = 100.0;

  DSFX_I3DL2REVERB_HFREFERENCE_MIN            = 20.0;
  DSFX_I3DL2REVERB_HFREFERENCE_MAX            = 20000.0;
  DSFX_I3DL2REVERB_HFREFERENCE_DEFAULT        = 5000.0;

  DSFX_I3DL2REVERB_QUALITY_MIN                = 0;
  DSFX_I3DL2REVERB_QUALITY_MAX                = 3;
  DSFX_I3DL2REVERB_QUALITY_DEFAULT            = 2;

  DSFX_WAVESREVERB_INGAIN_MIN                 = -96.0;
  DSFX_WAVESREVERB_INGAIN_MAX                 = 0.0;
  DSFX_WAVESREVERB_INGAIN_DEFAULT             = 0.0;
  DSFX_WAVESREVERB_REVERBMIX_MIN              = -96.0;
  DSFX_WAVESREVERB_REVERBMIX_MAX              = 0.0;
  DSFX_WAVESREVERB_REVERBMIX_DEFAULT          = 0.0;
  DSFX_WAVESREVERB_REVERBTIME_MIN             = 0.001;
  DSFX_WAVESREVERB_REVERBTIME_MAX             = 3000.0;
  DSFX_WAVESREVERB_REVERBTIME_DEFAULT         = 1000.0;
  DSFX_WAVESREVERB_HIGHFREQRTRATIO_MIN        = 0.001;
  DSFX_WAVESREVERB_HIGHFREQRTRATIO_MAX        = 0.999;
  DSFX_WAVESREVERB_HIGHFREQRTRATIO_DEFAULT    = 0.001;

//
// GUID's for all the objects
//
type
  IID_IDirectSound = IDirectSound;
  IID_IDirectSoundBuffer = IDirectSoundBuffer;
  IID_IDirectSound3DListener = IDirectSound3DListener;
  IID_IDirectSound3DBuffer = IDirectSound3DBuffer;
  IID_IDirectSoundCapture = IDirectSoundCapture;
  IID_IDirectSoundCaptureBuffer = IDirectSoundCaptureBuffer;
  IID_IDirectSoundNotify = IDirectSoundNotify;
  IID_IKsPropertySet = IKsPropertySet;

  // DirectSound 8.0
  IID_IDirectSound8 = IDirectSound8;
  IID_IDirectSoundBuffer8 = IDirectSoundBuffer8;
  IID_IDirectSound3DListener8 = IDirectSound3DListener8;
  IID_IDirectSound3DBuffer8 = IDirectSound3DBuffer8;
  IID_IDirectSoundCapture8 = IDirectSoundCapture8;
  IID_IDirectSoundCaptureBuffer8 = IDirectSoundCaptureBuffer8;
  IID_IDirectSoundNotify8 = IDirectSoundNotify8;
  IID_IDirectSoundCaptureFXAec8 = IDirectSoundCaptureFXAec8;
  IID_IDirectSoundCaptureFXNoiseSuppress8 = IDirectSoundCaptureFXNoiseSuppress8;
  IID_IDirectSoundFullDuplex8 = IDirectSoundFullDuplex8;
  IID_IDirectSoundFXGargle8 = IDirectSoundFXGargle8;
  IID_IDirectSoundFXChorus8 = IDirectSoundFXChorus8;
  IID_IDirectSoundFXFlanger8 = IDirectSoundFXFlanger8;
  IID_IDirectSoundFXEcho8 = IDirectSoundFXEcho8;
  IID_IDirectSoundFXDistortion8 = IDirectSoundFXDistortion8;
  IID_IDirectSoundFXCompressor8 = IDirectSoundFXCompressor8;
  IID_IDirectSoundFXParamEq8 = IDirectSoundFXParamEq8;
  IID_IDirectSoundFXWavesReverb8 = IDirectSoundFXWavesReverb8;
  IID_IDirectSoundFXI3DL2Reverb8 = IDirectSoundFXI3DL2Reverb8;

const
  CLSID_DirectSound            : TGUID = '{47D4D946-62E8-11CF-93BC-444553540000}';
  CLSID_DirectSound8           : TGUID = '{3901CC3F-84B5-4FA4-BA35-AA8172B8A09B}';
  CLSID_DirectSoundCapture     : TGUID = '{B0210780-89CD-11D0-AF08-00A0C925CD16}';
  CLSID_DirectSoundCapture8    : TGUID = '{E4BCAC13-7F99-4908-9A8E-74E3BF24B6E1}';
  CLSID_DirectSoundFullDuplex  : TGUID = '{FEA4300C-7959-4147-B26A-2377B9E7A91D}';
  DSDEVID_DefaultPlayback      : TGUID = '{DEF00000-9C6D-47ED-AAF1-4DDA8F2B5C03}';
  DSDEVID_DefaultCapture       : TGUID = '{DEF00001-9C6D-47ED-AAF1-4DDA8F2B5C03}';
  DSDEVID_DefaultVoicePlayback : TGUID = '{DEF00002-9C6D-47ED-AAF1-4DDA8F2B5C03}';
  DSDEVID_DefaultVoiceCapture  : TGUID = '{DEF00003-9C6D-47ED-AAF1-4DDA8F2B5C03}';

//
// Creation Routines
//
var
    DirectSoundCreate : function ( lpGuid: PGUID; out ppDS: IDirectSound;
        pUnkOuter: IUnknown) : HResult; stdcall;

    DirectSoundEnumerateW : function (lpDSEnumCallback: TDSEnumCallbackW;
        lpContext: Pointer) : HResult; stdcall;
    DirectSoundEnumerateA : function (lpDSEnumCallback: TDSEnumCallbackA;
        lpContext: Pointer) : HResult; stdcall;
    DirectSoundEnumerate : function (lpDSEnumCallback: TDSEnumCallback;
        lpContext: Pointer) : HResult; stdcall;

    DirectSoundCaptureCreate : function (lpGUID: PGUID;
        out lplpDSC: IDirectSoundCapture;
        pUnkOuter: IUnknown) : HResult; stdcall;

    DirectSoundCaptureEnumerateW : function (lpDSEnumCallback: TDSEnumCallbackW;
        lpContext: Pointer) : HResult; stdcall;
    DirectSoundCaptureEnumerateA : function (lpDSEnumCallback: TDSEnumCallbackA;
        lpContext: Pointer) : HResult; stdcall;
    DirectSoundCaptureEnumerate : function(lpDSEnumCallback: TDSEnumCallback;
        lpContext: Pointer) : HResult; stdcall;

// DirectX 8.0
    DirectSoundCreate8 : function( pcGuidDevice: PGUID; out ppDS8: IDirectSound8;
        pUnkOuter: IUnknown) : HResult; stdcall;
    DirectSoundCaptureCreate8 : function( pcGuidDevice: PGUID;
        out ppDSC8: IDirectSoundCapture8;
        pUnkOuter: IUnknown) : HResult; stdcall;
    DirectSoundFullDuplexCreate8 : function (pcGuidCaptureDevice, pcGuidRenderDevice: PGUID;
        const pcDSCBufferDesc: TDSCBufferDesc; const pcDSBufferDesc: TDSBufferDesc;
        hWnd: hWnd; dwLevel: DWORD;
        out ppDSFD: IDirectSoundFullDuplex8;
        out ppDSCBuffer8: IDirectSoundCaptureBuffer8;
        out ppDSBuffer8: IDirectSoundBuffer8; pUnkOuter: IUnknown): HResult; stdcall;
    GetDeviceID: function( pGuidSrc, pGuidDest: PGUID): HResult; stdcall;

//
// Return Values
//
const
  FLT_MIN = 1.175494351E-38;
  FLT_MAX = 3.402823466E+38;

  _FACDS = $878;
  MAKE_DSHRESULT_ = HResult($88780000);

// The function completed successfully
  DS_OK                          = S_OK;

// The call succeeded, but we had to substitute the 3D algorithm
  DS_NO_VIRTUALIZATION           = MAKE_DSHRESULT_ + 10;

// The call succeeded, but not all of the optional effects were obtained.
  DS_INCOMPLETE                  = MAKE_DSHRESULT_ + 20;

// The call failed because resources (such as a priority level)
// were already being used by another caller
  DSERR_ALLOCATED                 = MAKE_DSHRESULT_ + 10;

// The control (vol, pan, etc.) requested by the caller is not available
  DSERR_CONTROLUNAVAIL            = MAKE_DSHRESULT_ + 30;

// An invalid parameter was passed to the returning function
  DSERR_INVALIDPARAM              = E_INVALIDARG;

// This call is not valid for the current state of this object
  DSERR_INVALIDCALL               = MAKE_DSHRESULT_ + 50;

// An undetermined error occurred inside the DirectSound subsystem
  DSERR_GENERIC                   = E_FAIL;

// The caller does not have the priority level required for the function to
// succeed
  DSERR_PRIOLEVELNEEDED           = MAKE_DSHRESULT_ + 70;

// Not enough free memory is available to complete the operation
  DSERR_OUTOFMEMORY               = E_OUTOFMEMORY;

// The specified WAVE format is not supported
  DSERR_BADFORMAT                 = MAKE_DSHRESULT_ + 100;

// The function called is not supported at this time
  DSERR_UNSUPPORTED               = E_NOTIMPL;

// No sound driver is available for use
  DSERR_NODRIVER                  = MAKE_DSHRESULT_ + 120;

// This object is already initialized
  DSERR_ALREADYINITIALIZED        = MAKE_DSHRESULT_ + 130;

// This object does not support aggregation
  DSERR_NOAGGREGATION             = CLASS_E_NOAGGREGATION;

// The buffer memory has been lost, and must be restored
  DSERR_BUFFERLOST                = MAKE_DSHRESULT_ + 150;

// Another app has a higher priority level, preventing this call from
// succeeding
  DSERR_OTHERAPPHASPRIO           = MAKE_DSHRESULT_ + 160;

// This object has not been initialized
  DSERR_UNINITIALIZED             = MAKE_DSHRESULT_ + 170;

// The requested COM interface is not available
  DSERR_NOINTERFACE               = E_NOINTERFACE;

// Access is denied
  DSERR_ACCESSDENIED              = E_ACCESSDENIED;

// Tried to create a DSBCAPS_CTRLFX buffer shorter than DSBSIZE_FX_MIN milliseconds
  DSERR_BUFFERTOOSMALL            = MAKE_DSHRESULT_ + 180;

// Attempt to use DirectSound 8 functionality on an older DirectSound object
  DSERR_DS8_REQUIRED              = MAKE_DSHRESULT_ + 190;

// A circular loop of send effects was detected
  DSERR_SENDLOOP                  = MAKE_DSHRESULT_ + 200;

// The GUID specified in an audiopath file does not match a valid MIXIN buffer
  DSERR_BADSENDBUFFERGUID         = MAKE_DSHRESULT_ + 210;

// The object requested was not found (numerically equal to DMUS_E_NOT_FOUND)
  DSERR_OBJECTNOTFOUND            = MAKE_DSHRESULT_ + 4449;

// The effects requested could not be found on the system, or they were found
// but in the wrong order, or in the wrong hardware/software locations.
  DSERR_FXUNAVAILABLE             = MAKE_DSHRESULT_ + 220;

//
// Flags
//

  DSCAPS_PRIMARYMONO            = $00000001;
  DSCAPS_PRIMARYSTEREO          = $00000002;
  DSCAPS_PRIMARY8BIT            = $00000004;
  DSCAPS_PRIMARY16BIT           = $00000008;
  DSCAPS_CONTINUOUSRATE         = $00000010;
  DSCAPS_EMULDRIVER             = $00000020;
  DSCAPS_CERTIFIED              = $00000040;
  DSCAPS_SECONDARYMONO          = $00000100;
  DSCAPS_SECONDARYSTEREO        = $00000200;
  DSCAPS_SECONDARY8BIT          = $00000400;
  DSCAPS_SECONDARY16BIT         = $00000800;

  DSSCL_NORMAL                  = $00000001;
  DSSCL_PRIORITY                = $00000002;
  DSSCL_EXCLUSIVE               = $00000003;
  DSSCL_WRITEPRIMARY            = $00000004;

{IFDEF DX81}
  DSSPEAKER_DIRECTOUT           = $00000000;
{ENDIF}
  DSSPEAKER_HEADPHONE           = $00000001;
  DSSPEAKER_MONO                = $00000002;
  DSSPEAKER_QUAD                = $00000003;
  DSSPEAKER_STEREO              = $00000004;
  DSSPEAKER_SURROUND            = $00000005;
  DSSPEAKER_5POINT1             = $00000006;
{IFDEF DX81}
  DSSPEAKER_7POINT1             = $00000007;
{ENDIF}
  DSSPEAKER_GEOMETRY_MIN        = $00000005;  //   5 degrees
  DSSPEAKER_GEOMETRY_NARROW     = $0000000A;  //  10 degrees
  DSSPEAKER_GEOMETRY_WIDE       = $00000014;  //  20 degrees
  DSSPEAKER_GEOMETRY_MAX        = $000000B4;  // 180 degrees

function DSSPEAKER_COMBINED(c, g: variant) : DWORD;
function DSSPEAKER_CONFIG(a: variant) : byte;
function DSSPEAKER_GEOMETRY(a: variant) : byte;

const
  DSBCAPS_PRIMARYBUFFER         = $00000001;
  DSBCAPS_STATIC                = $00000002;
  DSBCAPS_LOCHARDWARE           = $00000004;
  DSBCAPS_LOCSOFTWARE           = $00000008;
  DSBCAPS_CTRL3D                = $00000010;
  DSBCAPS_CTRLFREQUENCY         = $00000020;
  DSBCAPS_CTRLPAN               = $00000040;
  DSBCAPS_CTRLVOLUME            = $00000080;
  DSBCAPS_CTRLPOSITIONNOTIFY    = $00000100;
  DSBCAPS_CTRLFX                = $00000200;
  DSBCAPS_STICKYFOCUS           = $00004000;
  DSBCAPS_GLOBALFOCUS           = $00008000;
  DSBCAPS_GETCURRENTPOSITION2   = $00010000;
  DSBCAPS_MUTE3DATMAXDISTANCE   = $00020000;
  DSBCAPS_LOCDEFER              = $00040000;
  DSBCAPS_CTRLDEFAULT           = $000000E0;
  DSBCAPS_CTRLALL               = $000001F0;


  DSBPLAY_LOOPING               = $00000001;
  DSBPLAY_LOCHARDWARE           = $00000002;
  DSBPLAY_LOCSOFTWARE           = $00000004;
  DSBPLAY_TERMINATEBY_TIME      = $00000008;
  DSBPLAY_TERMINATEBY_DISTANCE  = $000000010;
  DSBPLAY_TERMINATEBY_PRIORITY  = $000000020;

  DSBSTATUS_PLAYING             = $00000001;
  DSBSTATUS_BUFFERLOST          = $00000002;
  DSBSTATUS_LOOPING             = $00000004;
  DSBSTATUS_LOCHARDWARE         = $00000008;
  DSBSTATUS_LOCSOFTWARE         = $00000010;
  DSBSTATUS_TERMINATED          = $00000020;

  DSBLOCK_FROMWRITECURSOR       = $00000001;
  DSBLOCK_ENTIREBUFFER          = $00000002;

  DSBFREQUENCY_MIN              = 100;
  DSBFREQUENCY_MAX              = 100000;
  DSBFREQUENCY_ORIGINAL         = 0;

  DSBPAN_LEFT                   = -10000;
  DSBPAN_CENTER                 = 0;
  DSBPAN_RIGHT                  = 10000;

  DSBVOLUME_MIN                 = -10000;
  DSBVOLUME_MAX                 = 0;

  DSBSIZE_MIN                   = 4;
  DSBSIZE_MAX                   = $0FFFFFFF;
  DSBSIZE_FX_MIN                = 150;  // NOTE: Milliseconds, not bytes

  DS3DMODE_NORMAL               = $00000000;
  DS3DMODE_HEADRELATIVE         = $00000001;
  DS3DMODE_DISABLE              = $00000002;

  DS3D_IMMEDIATE                = $00000000;
  DS3D_DEFERRED                 = $00000001;

  DS3D_MINDISTANCEFACTOR        = FLT_MIN;
  DS3D_MAXDISTANCEFACTOR        = FLT_MAX;
  DS3D_DEFAULTDISTANCEFACTOR    = 1.0;

  DS3D_MINROLLOFFFACTOR         = 0.0;
  DS3D_MAXROLLOFFFACTOR         = 10.0;
  DS3D_DEFAULTROLLOFFFACTOR     = 1.0;

  DS3D_MINDOPPLERFACTOR         = 0.0;
  DS3D_MAXDOPPLERFACTOR         = 10.0;
  DS3D_DEFAULTDOPPLERFACTOR     = 1.0;

  DS3D_DEFAULTMINDISTANCE       = 1.0;
  DS3D_DEFAULTMAXDISTANCE       = 1000000000.0;

  DS3D_MINCONEANGLE             = 0;
  DS3D_MAXCONEANGLE             = 360;
  DS3D_DEFAULTCONEANGLE         = 360;

  DS3D_DEFAULTCONEOUTSIDEVOLUME = DSBVOLUME_MAX;

// IDirectSoundCapture attributes

  DSCCAPS_EMULDRIVER            = DSCAPS_EMULDRIVER;
  DSCCAPS_CERTIFIED             = DSCAPS_CERTIFIED;

// IDirectSoundCaptureBuffer attributes

  DSCBCAPS_WAVEMAPPED           = $80000000;

{$IFNDEF DIRECTX7}
{$IFNDEF DIRECTX6}
  DSCBCAPS_CTRLFX               = $00000200;
{$ENDIF}
{$ENDIF}


  DSCBLOCK_ENTIREBUFFER         = $00000001;

  DSCBSTATUS_CAPTURING          = $00000001;
  DSCBSTATUS_LOOPING            = $00000002;

  DSCBSTART_LOOPING             = $00000001;

  DSBPN_OFFSETSTOP              = $FFFFFFFF;

  DS_CERTIFIED                  = $00000000;
  DS_UNCERTIFIED                = $00000001;

{$IFNDEF DX81}
// Dsound SYSTEM resource constants
// Matches the KSAUDIO_CPU_RESOURCES_xxx_HOST_CPU values defined
// in ksmedia.h.
  DS_SYSTEM_RESOURCES_NO_HOST_RESOURCES  = $00000000;
  DS_SYSTEM_RESOURCES_ALL_HOST_RESOURCES = $7FFFFFFF;
  DS_SYSTEM_RESOURCES_UNDEFINED          = $80000000;
{$ENDIF}
  DSFX_LOCHARDWARE              = $00000001;
  DSFX_LOCSOFTWARE              = $00000002;

  DSCFX_LOCHARDWARE             = $00000001;
  DSCFX_LOCSOFTWARE             = $00000002;

  DSCFXR_LOCHARDWARE            = $00000010;
  DSCFXR_LOCSOFTWARE            = $00000020;
{$IFNDEF DX81}
  DSCFXR_UNALLOCATED            = $00000040;
  DSCFXR_FAILED                 = $00000080;
  DSCFXR_UNKNOWN                = $00000100;
{$ENDIF}

{$IFDEF DX81}
// These match the AEC_MODE_* constants in the DDK's ksmedia.h file
  DSCFX_AEC_MODE_PASS_THROUGH                     = 0;
  DSCFX_AEC_MODE_HALF_DUPLEX                      = 1;
  DSCFX_AEC_MODE_FULL_DUPLEX                      = 2;

// These match the AEC_STATUS_* constants in ksmedia.h
  DSCFX_AEC_STATUS_HISTORY_UNINITIALIZED          = 0;
  DSCFX_AEC_STATUS_HISTORY_CONTINUOUSLY_CONVERGED = 1;
  DSCFX_AEC_STATUS_HISTORY_PREVIOUSLY_DIVERGED    = 2;
  DSCFX_AEC_STATUS_CURRENTLY_CONVERGED            = 8;
{$ENDIF}

//
// I3DL2 Material Presets
//

{
  I3DL2_MATERIAL_PRESET_SINGLEWINDOW    = -2800,0.71;
  I3DL2_MATERIAL_PRESET_DOUBLEWINDOW    = -5000,0.40;
  I3DL2_MATERIAL_PRESET_THINDOOR        = -1800,0.66;
  I3DL2_MATERIAL_PRESET_THICKDOOR       = -4400,0.64;
  I3DL2_MATERIAL_PRESET_WOODWALL        = -4000,0.50;
  I3DL2_MATERIAL_PRESET_BRICKWALL       = -5000,0.60;
  I3DL2_MATERIAL_PRESET_STONEWALL       = -6000,0.68;
  I3DL2_MATERIAL_PRESET_CURTAIN         = -1200,0.15;
}
//
// I3DL2 Reverberation Presets Values
//

  I3DL2_ENVIRONMENT_PRESET_DEFAULT        : TDSFXI3DL2Reverb = (lRoom:-1000; lRoomHF: -100; flRoomRolloffFactor: 0.0; flDecayTime: 1.49; flDecayHFRatio: 0.83; lReflections: -2602; flReflectionsDelay: 0.007; lReverb:  200; flReverbDelay: 0.011; flDiffusion: 100.0; flDensity: 100.0; flHFReference: 5000.0);
  I3DL2_ENVIRONMENT_PRESET_GENERIC        : TDSFXI3DL2Reverb = (lRoom:-1000; lRoomHF: -100; flRoomRolloffFactor: 0.0; flDecayTime: 1.49; flDecayHFRatio: 0.83; lReflections: -2602; flReflectionsDelay: 0.007; lReverb:  200; flReverbDelay: 0.011; flDiffusion: 100.0; flDensity: 100.0; flHFReference: 5000.0);
  I3DL2_ENVIRONMENT_PRESET_PADDEDCELL     : TDSFXI3DL2Reverb = (lRoom:-1000; lRoomHF:-6000; flRoomRolloffFactor: 0.0; flDecayTime: 0.17; flDecayHFRatio: 0.10; lReflections: -1204; flReflectionsDelay: 0.001; lReverb:  207; flReverbDelay: 0.002; flDiffusion: 100.0; flDensity: 100.0; flHFReference: 5000.0);
  I3DL2_ENVIRONMENT_PRESET_ROOM           : TDSFXI3DL2Reverb = (lRoom:-1000; lRoomHF: -454; flRoomRolloffFactor: 0.0; flDecayTime: 0.40; flDecayHFRatio: 0.83; lReflections: -1646; flReflectionsDelay: 0.002; lReverb:   53; flReverbDelay: 0.003; flDiffusion: 100.0; flDensity: 100.0; flHFReference: 5000.0);
  I3DL2_ENVIRONMENT_PRESET_BATHROOM       : TDSFXI3DL2Reverb = (lRoom:-1000; lRoomHF:-1200; flRoomRolloffFactor: 0.0; flDecayTime: 1.49; flDecayHFRatio: 0.54; lReflections:  -370; flReflectionsDelay: 0.007; lReverb: 1030; flReverbDelay: 0.011; flDiffusion: 100.0; flDensity:  60.0; flHFReference: 5000.0);
  I3DL2_ENVIRONMENT_PRESET_LIVINGROOM     : TDSFXI3DL2Reverb = (lRoom:-1000; lRoomHF:-6000; flRoomRolloffFactor: 0.0; flDecayTime: 0.50; flDecayHFRatio: 0.10; lReflections: -1376; flReflectionsDelay: 0.003; lReverb:-1104; flReverbDelay: 0.004; flDiffusion: 100.0; flDensity: 100.0; flHFReference: 5000.0);
  I3DL2_ENVIRONMENT_PRESET_STONEROOM      : TDSFXI3DL2Reverb = (lRoom:-1000; lRoomHF: -300; flRoomRolloffFactor: 0.0; flDecayTime: 2.31; flDecayHFRatio: 0.64; lReflections:  -711; flReflectionsDelay: 0.012; lReverb:   83; flReverbDelay: 0.017; flDiffusion: 100.0; flDensity: 100.0; flHFReference: 5000.0);
  I3DL2_ENVIRONMENT_PRESET_AUDITORIUM     : TDSFXI3DL2Reverb = (lRoom:-1000; lRoomHF: -476; flRoomRolloffFactor: 0.0; flDecayTime: 4.32; flDecayHFRatio: 0.59; lReflections:  -789; flReflectionsDelay: 0.020; lReverb: -289; flReverbDelay: 0.030; flDiffusion: 100.0; flDensity: 100.0; flHFReference: 5000.0);
  I3DL2_ENVIRONMENT_PRESET_CONCERTHALL    : TDSFXI3DL2Reverb = (lRoom:-1000; lRoomHF: -500; flRoomRolloffFactor: 0.0; flDecayTime: 3.92; flDecayHFRatio: 0.70; lReflections: -1230; flReflectionsDelay: 0.020; lReverb:   -2; flReverbDelay: 0.029; flDiffusion: 100.0; flDensity: 100.0; flHFReference: 5000.0);
  I3DL2_ENVIRONMENT_PRESET_CAVE           : TDSFXI3DL2Reverb = (lRoom:-1000; lRoomHF:    0; flRoomRolloffFactor: 0.0; flDecayTime: 2.91; flDecayHFRatio: 1.30; lReflections:  -602; flReflectionsDelay: 0.015; lReverb: -302; flReverbDelay: 0.022; flDiffusion: 100.0; flDensity: 100.0; flHFReference: 5000.0);
  I3DL2_ENVIRONMENT_PRESET_ARENA          : TDSFXI3DL2Reverb = (lRoom:-1000; lRoomHF: -698; flRoomRolloffFactor: 0.0; flDecayTime: 7.24; flDecayHFRatio: 0.33; lReflections: -1166; flReflectionsDelay: 0.020; lReverb:   16; flReverbDelay: 0.030; flDiffusion: 100.0; flDensity: 100.0; flHFReference: 5000.0);
  I3DL2_ENVIRONMENT_PRESET_HANGAR         : TDSFXI3DL2Reverb = (lRoom:-1000; lRoomHF:-1000; flRoomRolloffFactor: 0.0; flDecayTime:10.05; flDecayHFRatio: 0.23; lReflections:  -602; flReflectionsDelay: 0.020; lReverb:  198; flReverbDelay: 0.030; flDiffusion: 100.0; flDensity: 100.0; flHFReference: 5000.0);
  I3DL2_ENVIRONMENT_PRESET_CARPETEDHALLWAY: TDSFXI3DL2Reverb = (lRoom:-1000; lRoomHF:-4000; flRoomRolloffFactor: 0.0; flDecayTime: 0.30; flDecayHFRatio: 0.10; lReflections: -1831; flReflectionsDelay: 0.002; lReverb:-1630; flReverbDelay: 0.030; flDiffusion: 100.0; flDensity: 100.0; flHFReference: 5000.0);
  I3DL2_ENVIRONMENT_PRESET_HALLWAY        : TDSFXI3DL2Reverb = (lRoom:-1000; lRoomHF: -300; flRoomRolloffFactor: 0.0; flDecayTime: 1.49; flDecayHFRatio: 0.59; lReflections: -1219; flReflectionsDelay: 0.007; lReverb:  441; flReverbDelay: 0.011; flDiffusion: 100.0; flDensity: 100.0; flHFReference: 5000.0);
  I3DL2_ENVIRONMENT_PRESET_STONECORRIDOR  : TDSFXI3DL2Reverb = (lRoom:-1000; lRoomHF: -237; flRoomRolloffFactor: 0.0; flDecayTime: 2.70; flDecayHFRatio: 0.79; lReflections: -1214; flReflectionsDelay: 0.013; lReverb:  395; flReverbDelay: 0.020; flDiffusion: 100.0; flDensity: 100.0; flHFReference: 5000.0);
  I3DL2_ENVIRONMENT_PRESET_ALLEY          : TDSFXI3DL2Reverb = (lRoom:-1000; lRoomHF: -270; flRoomRolloffFactor: 0.0; flDecayTime: 1.49; flDecayHFRatio: 0.86; lReflections: -1204; flReflectionsDelay: 0.007; lReverb:   -4; flReverbDelay: 0.011; flDiffusion: 100.0; flDensity: 100.0; flHFReference: 5000.0);
  I3DL2_ENVIRONMENT_PRESET_FOREST         : TDSFXI3DL2Reverb = (lRoom:-1000; lRoomHF:-3300; flRoomRolloffFactor: 0.0; flDecayTime: 1.49; flDecayHFRatio: 0.54; lReflections: -2560; flReflectionsDelay: 0.162; lReverb: -613; flReverbDelay: 0.088; flDiffusion:  79.0; flDensity: 100.0; flHFReference: 5000.0);
  I3DL2_ENVIRONMENT_PRESET_CITY           : TDSFXI3DL2Reverb = (lRoom:-1000; lRoomHF: -800; flRoomRolloffFactor: 0.0; flDecayTime: 1.49; flDecayHFRatio: 0.67; lReflections: -2273; flReflectionsDelay: 0.007; lReverb:-2217; flReverbDelay: 0.011; flDiffusion:  50.0; flDensity: 100.0; flHFReference: 5000.0);
  I3DL2_ENVIRONMENT_PRESET_MOUNTAINS      : TDSFXI3DL2Reverb = (lRoom:-1000; lRoomHF:-2500; flRoomRolloffFactor: 0.0; flDecayTime: 1.49; flDecayHFRatio: 0.21; lReflections: -2780; flReflectionsDelay: 0.300; lReverb:-2014; flReverbDelay: 0.100; flDiffusion:  27.0; flDensity: 100.0; flHFReference: 5000.0);
  I3DL2_ENVIRONMENT_PRESET_QUARRY         : TDSFXI3DL2Reverb = (lRoom:-1000; lRoomHF:-1000; flRoomRolloffFactor: 0.0; flDecayTime: 1.49; flDecayHFRatio: 0.83; lReflections:-10000; flReflectionsDelay: 0.061; lReverb:  500; flReverbDelay: 0.025; flDiffusion: 100.0; flDensity: 100.0; flHFReference: 5000.0);
  I3DL2_ENVIRONMENT_PRESET_PLAIN          : TDSFXI3DL2Reverb = (lRoom:-1000; lRoomHF:-2000; flRoomRolloffFactor: 0.0; flDecayTime: 1.49; flDecayHFRatio: 0.50; lReflections: -2466; flReflectionsDelay: 0.179; lReverb:-2514; flReverbDelay: 0.100; flDiffusion:  21.0; flDensity: 100.0; flHFReference: 5000.0);
  I3DL2_ENVIRONMENT_PRESET_PARKINGLOT     : TDSFXI3DL2Reverb = (lRoom:-1000; lRoomHF:    0; flRoomRolloffFactor: 0.0; flDecayTime: 1.65; flDecayHFRatio: 1.50; lReflections: -1363; flReflectionsDelay: 0.008; lReverb:-1153; flReverbDelay: 0.012; flDiffusion: 100.0; flDensity: 100.0; flHFReference: 5000.0);
  I3DL2_ENVIRONMENT_PRESET_SEWERPIPE      : TDSFXI3DL2Reverb = (lRoom:-1000; lRoomHF:-1000; flRoomRolloffFactor: 0.0; flDecayTime: 2.81; flDecayHFRatio: 0.14; lReflections:   429; flReflectionsDelay: 0.014; lReverb:  648; flReverbDelay: 0.021; flDiffusion:  80.0; flDensity:  60.0; flHFReference: 5000.0);
  I3DL2_ENVIRONMENT_PRESET_UNDERWATER     : TDSFXI3DL2Reverb = (lRoom:-1000; lRoomHF:-4000; flRoomRolloffFactor: 0.0; flDecayTime: 1.49; flDecayHFRatio: 0.10; lReflections:  -449; flReflectionsDelay: 0.007; lReverb: 1700; flReverbDelay: 0.011; flDiffusion: 100.0; flDensity: 100.0; flHFReference: 5000.0);

//
// Examples simulating 'musical' reverb presets
//
// Name       Decay time   Description
// Small Room    1.1s      A small size room with a length of 5m or so.
// Medium Room   1.3s      A medium size room with a length of 10m or so.
// Large Room    1.5s      A large size room suitable for live performances.
// Medium Hall   1.8s      A medium size concert hall.
// Large Hall    1.8s      A large size concert hall suitable for a full orchestra.
// Plate         1.3s      A plate reverb simulation.
//

  I3DL2_ENVIRONMENT_PRESET_SMALLROOM      : TDSFXI3DL2Reverb = (lRoom:-1000; lRoomHF: -600; flRoomRolloffFactor: 0.0; flDecayTime: 1.10; flDecayHFRatio: 0.83; lReflections:  -400; flReflectionsDelay: 0.005; lReverb:  500; flReverbDelay: 0.010; flDiffusion: 100.0; flDensity: 100.0; flHFReference: 5000.0);
  I3DL2_ENVIRONMENT_PRESET_MEDIUMROOM     : TDSFXI3DL2Reverb = (lRoom:-1000; lRoomHF: -600; flRoomRolloffFactor: 0.0; flDecayTime: 1.30; flDecayHFRatio: 0.83; lReflections: -1000; flReflectionsDelay: 0.010; lReverb: -200; flReverbDelay: 0.020; flDiffusion: 100.0; flDensity: 100.0; flHFReference: 5000.0);
  I3DL2_ENVIRONMENT_PRESET_LARGEROOM      : TDSFXI3DL2Reverb = (lRoom:-1000; lRoomHF: -600; flRoomRolloffFactor: 0.0; flDecayTime: 1.50; flDecayHFRatio: 0.83; lReflections: -1600; flReflectionsDelay: 0.020; lReverb:-1000; flReverbDelay: 0.040; flDiffusion: 100.0; flDensity: 100.0; flHFReference: 5000.0);
  I3DL2_ENVIRONMENT_PRESET_MEDIUMHALL     : TDSFXI3DL2Reverb = (lRoom:-1000; lRoomHF: -600; flRoomRolloffFactor: 0.0; flDecayTime: 1.80; flDecayHFRatio: 0.70; lReflections: -1300; flReflectionsDelay: 0.015; lReverb: -800; flReverbDelay: 0.030; flDiffusion: 100.0; flDensity: 100.0; flHFReference: 5000.0);
  I3DL2_ENVIRONMENT_PRESET_LARGEHALL      : TDSFXI3DL2Reverb = (lRoom:-1000; lRoomHF: -600; flRoomRolloffFactor: 0.0; flDecayTime: 1.80; flDecayHFRatio: 0.70; lReflections: -2000; flReflectionsDelay: 0.030; lReverb:-1400; flReverbDelay: 0.060; flDiffusion: 100.0; flDensity: 100.0; flHFReference: 5000.0);
  I3DL2_ENVIRONMENT_PRESET_PLATE          : TDSFXI3DL2Reverb = (lRoom:-1000; lRoomHF: -200; flRoomRolloffFactor: 0.0; flDecayTime: 1.30; flDecayHFRatio: 0.90; lReflections:     0; flReflectionsDelay: 0.002; lReverb:    0; flReverbDelay: 0.010; flDiffusion: 100.0; flDensity:  75.0; flHFReference: 5000.0);


//
// DirectSound3D Algorithms
//

const
// Default DirectSound3D algorithm {00000000-0000-0000-0000-000000000000}
  DS3DALG_DEFAULT                : TGUID = '{00000000-0000-0000-0000-000000000000}';

// No virtualization {C241333F-1C1B-11d2-94F5-00C04FC28ACA}
  DS3DALG_NO_VIRTUALIZATION      : TGUID = '{C241333F-1C1B-11d2-94F5-00C04FC28ACA}';

// High-quality HRTF algorithm {C2413340-1C1B-11d2-94F5-00C04FC28ACA}
  DS3DALG_HRTF_FULL              : TGUID = '{C2413340-1C1B-11d2-94F5-00C04FC28ACA}';

// Lower-quality HRTF algorithm {C2413342-1C1B-11d2-94F5-00C04FC28ACA}
  DS3DALG_HRTF_LIGHT             : TGUID = '{C2413342-1C1B-11d2-94F5-00C04FC28ACA}';

// Special GUID meaning "select all objects" for use in GetObjectInPath()
  GUID_All_Objects               : TGUID = '{aa114de5-c262-4169-a1c8-23d698cc73b5}';

//
// DirectSound Internal Effect Algorithms
//
  GUID_DSFX_STANDARD_GARGLE      : TGUID = '{DAFD8210-5711-4B91-9FE3-F75B7AE279BF}';
  GUID_DSFX_STANDARD_CHORUS      : TGUID = '{EFE6629C-81F7-4281-BD91-C9D604A95AF6}';
  GUID_DSFX_STANDARD_FLANGER     : TGUID = '{EFCA3D92-DFD8-4672-A603-7420894BAD98}';
  GUID_DSFX_STANDARD_ECHO        : TGUID = '{EF3E932C-D40B-4F51-8CCF-3F98F1B29D5D}';
  GUID_DSFX_STANDARD_DISTORTION  : TGUID = '{EF114C90-CD1D-484E-96E5-09CFAF912A21}';
  GUID_DSFX_STANDARD_COMPRESSOR  : TGUID = '{EF011F79-4000-406D-87AF-BFFB3FC39D57}';
  GUID_DSFX_STANDARD_PARAMEQ     : TGUID = '{120CED89-3BF4-4173-A132-3CB406CF3231}';
  GUID_DSFX_STANDARD_I3DL2REVERB : TGUID = '{EF985E71-D5C7-42D4-BA4D-2D073E2E96F4}';
  GUID_DSFX_WAVES_REVERB         : TGUID = '{87FC0268-9A55-4360-95AA-004A1D9DE26C}';

//
// DirectSound Capture Effect Algorithms
//
  GUID_DSCFX_CLASS_AEC           : TGUID = '{BF963D80-C559-11D0-8A2B-00A0C9255AC1}';
  GUID_DSCFX_MS_AEC              : TGUID = '{CDEBB919-379A-488a-8765-F53CFD36DE40}';
  GUID_DSCFX_SYSTEM_AEC          : TGUID = '{1C22C56D-9879-4f5b-A389-27996DDC2810}';
  GUID_DSCFX_CLASS_NS            : TGUID = '{E07F903F-62FD-4e60-8CDD-DEA7236665B5}';
  GUID_DSCFX_MS_NS               : TGUID = '{11C5C73B-66E9-4ba1-A0BA-E814C6EED92D}';
  GUID_DSCFX_SYSTEM_NS           : TGUID = '{5AB0882E-7274-4516-877D-4EEE99BA4FD0}';


(*==========================================================================;
 * Library : ksmedia.h
 ***************************************************************************)

  // Speaker Positions:
  SPEAKER_FRONT_LEFT              = $1;
  SPEAKER_FRONT_RIGHT             = $2;
  SPEAKER_FRONT_CENTER            = $4;
  SPEAKER_LOW_FREQUENCY           = $8;
  SPEAKER_BACK_LEFT               = $10;
  SPEAKER_BACK_RIGHT              = $20;
  SPEAKER_FRONT_LEFT_OF_CENTER    = $40;
  SPEAKER_FRONT_RIGHT_OF_CENTER   = $80;
  SPEAKER_BACK_CENTER             = $100;
  SPEAKER_SIDE_LEFT               = $200;
  SPEAKER_SIDE_RIGHT              = $400;
  SPEAKER_TOP_CENTER              = $800;
  SPEAKER_TOP_FRONT_LEFT          = $1000;
  SPEAKER_TOP_FRONT_CENTER        = $2000;
  SPEAKER_TOP_FRONT_RIGHT         = $4000;
  SPEAKER_TOP_BACK_LEFT           = $8000;
  SPEAKER_TOP_BACK_CENTER         = $10000;
  SPEAKER_TOP_BACK_RIGHT          = $20000;

  // Bit mask locations reserved for future use
  SPEAKER_RESERVED                = $7FFC0000;

  // Used to specify that any possible permutation of speaker configurations
  SPEAKER_ALL                     = $80000000;

  WAVE_FORMAT_EXTENSIBLE          = $FFFE;

  KSDATAFORMAT_SUBTYPE_ANALOG         : TGUID = '{6dba3190-67bd-11cf-a0f7-0020afd156e4}';
  KSDATAFORMAT_SUBTYPE_PCM            : TGUID = '{00000001-0000-0010-8000-00aa00389b71}';
  KSDATAFORMAT_SUBTYPE_IEEE_FLOAT     : TGUID = '{00000003-0000-0010-8000-00aa00389b71}';
  KSDATAFORMAT_SUBTYPE_DRM            : TGUID = '{00000009-0000-0010-8000-00aa00389b71}';
  KSDATAFORMAT_SUBTYPE_ALAW           : TGUID = '{00000006-0000-0010-8000-00aa00389b71}';
  KSDATAFORMAT_SUBTYPE_MULAW          : TGUID = '{00000007-0000-0010-8000-00aa00389b71}';
  KSDATAFORMAT_SUBTYPE_ADPCM          : TGUID = '{00000002-0000-0010-8000-00aa00389b71}';
  KSDATAFORMAT_SUBTYPE_MPEG           : TGUID = '{00000050-0000-0010-8000-00aa00389b71}';
  KSDATAFORMAT_SPECIFIER_VC_ID        : TGUID = '{AD98D184-AAC3-11D0-A41C-00A0C9223196}';
  KSDATAFORMAT_SPECIFIER_WAVEFORMATEX : TGUID = '{05589f81-c356-11ce-bf01-00aa0055595a}';
  KSDATAFORMAT_SPECIFIER_DSOUND       : TGUID = '{518590a2-a184-11d0-8522-00c04fd9baf3}';

type
  PWaveFormatExtensible = ^TWaveFormatExtensible;
  TWaveFormatExtensible = packed record
    Format: TWaveFormatEx;
    case byte of
      0: (wValidBitsPerSample : WORD;   // bits of precision
          dwChannelMask       : DWORD;  // which channels are present in stream
          SubFormat           : TGUID);
      1: (wSamplesPerBlock    : WORD);  // valid if wBitsPerSample = 0
      2: (wReserved           : WORD);  // If neither applies, set to zero.
  end;

function DSErrorString(Value: HResult) : string;

implementation

uses DXCommon;

function DSSPEAKER_COMBINED(c, g: variant) : DWORD;
begin
  Result := byte(c) or (byte(g) shl 16)
end;

function DSSPEAKER_CONFIG(a: variant) : byte;
begin
  Result := byte(a);
end;

function DSSPEAKER_GEOMETRY(a: variant) : byte;
begin
  Result := byte(a shr 16 and $FF);
end;

function DSErrorString(Value: HResult) : string;
begin
  case Value of
    HResult(DS_OK)                    : Result := 'The request completed successfully.';
    HResult(DSERR_ALLOCATED)          : Result := 'The request failed because resources, such as a priority level, were already in use by another caller.';
    HResult(DSERR_ALREADYINITIALIZED) : Result := 'The object is already initialized.';
    HResult(DSERR_ACCESSDENIED)       : Result := 'Access is denied.';
    HResult(DSERR_BADFORMAT)          : Result := 'The specified wave format is not supported.';
    HResult(DSERR_BADSENDBUFFERGUID)  : Result := 'The GUID specified in an audiopath file does not match a valid MIXIN buffer.';
    HResult(DSERR_BUFFERLOST)         : Result := 'The buffer memory has been lost and must be restored.';
    HResult(DSERR_BUFFERTOOSMALL)     : Result := 'Tried to create a DSBCAPS_CTRLFX buffer shorter than DSBSIZE_FX_MIN milliseconds.';
    HResult(DSERR_CONTROLUNAVAIL)     : Result := 'The control (volume, pan, and so forth) requested by the caller is not available.';
    HResult(DSERR_DS8_REQUIRED)       : Result := 'Attempt to use DirectSound 8 functionality on an older DirectSound object.';
    HResult(DSERR_GENERIC)            : Result := 'An undetermined error occurred inside the DirectSound subsystem.';
    HResult(DSERR_INVALIDCALL)        : Result := 'This function is not valid for the current state of this object.';
    HResult(DSERR_INVALIDPARAM)       : Result := 'An invalid parameter was passed to the returning function.';
    HResult(DSERR_NOAGGREGATION)      : Result := 'The object does not support aggregation.';
    HResult(DSERR_NODRIVER)           : Result := 'No sound driver is available for use.';
    HResult(DSERR_NOINTERFACE)        : Result := 'The requested COM interface is not available.';
    HResult(DSERR_OBJECTNOTFOUND)     : Result := 'The object requested was not found (numerically equal to DMUS_E_NOT_FOUND).';
{IFDEF DX81}
    HResult(DSERR_FXUNAVAILABLE)      : Result := 'The effects requested could not be found on the system, or they were found but in the wrong order, or in the wrong hardware/software locations.';
{ENDIF}
    HResult(DSERR_OTHERAPPHASPRIO)    : Result := 'Another application has a higher priority level, preventing this call from succeeding.';
    HResult(DSERR_OUTOFMEMORY)        : Result := 'The DirectSound subsystem could not allocate sufficient memory to complete the caller´s request.';
    HResult(DSERR_PRIOLEVELNEEDED)    : Result := 'The caller does not have the priority level required for the function to succeed.';
    HResult(DSERR_SENDLOOP)           : Result := 'A circular loop of send effects was detected.';
    HResult(DSERR_UNINITIALIZED)      : Result := 'The IDirectSound::Initialize method has not been called or has not been called successfully before other methods were called.';
    HResult(DSERR_UNSUPPORTED)        : Result := 'The function called is not supported at this time.';
    else                                Result := UnrecognizedError;
  end;
end;

initialization
begin
  if not IsNTandDelphiRunning then
  begin
    DSoundDLL := LoadLibrary('DSound.dll');
    DirectSoundCreate := GetProcAddress(DSoundDLL,'DirectSoundCreate');
    DirectSoundCreate8 := GetProcAddress(DSoundDLL,'DirectSoundCreate8');
    DirectSoundFullDuplexCreate8 := GetProcAddress(DSoundDLL,'DirectSoundFullDuplexCreate8');
    GetDeviceID := GetProcAddress(DSoundDLL,'GetDeviceID');

    DirectSoundEnumerateW := GetProcAddress(DSoundDLL,'DirectSoundEnumerateW');
    DirectSoundEnumerateA := GetProcAddress(DSoundDLL,'DirectSoundEnumerateA');
  {$IFDEF UNICODE}
    DirectSoundEnumerate := DirectSoundEnumerateW;
  {$ELSE}
    DirectSoundEnumerate := DirectSoundEnumerateA;
  {$ENDIF}

    DirectSoundCaptureCreate := GetProcAddress(DSoundDLL,'DirectSoundCaptureCreate');
    DirectSoundCaptureCreate8 := GetProcAddress(DSoundDLL,'DirectSoundCaptureCreate8');

    DirectSoundCaptureEnumerateW := GetProcAddress(DSoundDLL,'DirectSoundCaptureEnumerateW');
    DirectSoundCaptureEnumerateA := GetProcAddress(DSoundDLL,'DirectSoundCaptureEnumerateA');
  {$IFDEF UNICODE}
    DirectSoundCaptureEnumerate := DirectSoundCaptureEnumerateW;
  {$ELSE}
    DirectSoundCaptureEnumerate := DirectSoundCaptureEnumerateA;
  {$ENDIF}
  end;
end;

finalization
begin
  if DSoundDLL <> 0 then FreeLibrary(DSoundDLL);
end;

end.
