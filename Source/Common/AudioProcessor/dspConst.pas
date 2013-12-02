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

unit dspConst;

interface

uses
  Windows;

const
  // Max Channels
  MaxChannels = 10;
  // Max EQ Bands
  MAX_EQ_BANDS = 10;
  // EQ Bands
  EQFreq: array[0..MAX_EQ_BANDS -1] of Single =
       (32, 64, 128, 250, 500, 1000, 2000, 4000, 8000, 16000);

  // EQ Bandwidths
  EQBandWidth: array[0..MAX_EQ_BANDS -1] of Single =
      (12, 12, 12, 12, 12, 12, 12, 12, 12, 12);

  DefaultSampleSize = 8192;

  MaxVisualSamples = 8192;

  WAVE_FORMAT_IEEE_FLOAT = $0003;
  WAVE_FORMAT_DOLBY_AC3_SPDIF = $0092;
  WAVE_FORMAT_DOLBY_AC3 = $2000;
  WAVE_FORMAT_DTS = $8;
  WAVE_FORMAT_DVD_DTS = $2001;

type
  { Record that stores Information about an Audiostream. }
  PDSAudioStream = ^TDSAudioStream;
  TDSAudioStream = record
    Size, Frequency, Channels, Bits: integer;
    Float: BOOL;
    SPDIF: BOOL;
    DTS: BOOL;
  end;

  { Used by TDCFFT to setup the FFT Size. }
  TFFTSize = (
    fts2, fts4, fts8, fts16, fts32, fts64, fts128, fts256,
    fts512, fts1024, fts2048, fts4096, fts8192
  );

  PComplex = ^TComplex;
  TComplex = record
    re,
    im : Single;
  end;
  PComplexArray = ^TComplexArray;
  TComplexArray = array[0..8191] of TComplex;

  T24BitSample = record
    a0: Byte;
    a1: Byte;
    a2: ShortInt;
  end;
  P24BitSample = ^T24BitSample;
  PWORDArray = ^TWORDArray;
  TWORDArray = array [0..255] of WORD;
  PByteArray = ^TByteArray;
  TByteArray = array [0..255] of Byte;
  PSmallIntArray = ^TSmallIntArray;
  TSmallIntArray = array [0..255] of SmallInt;
  PInteger24Array = ^TInteger24Array;
  TInteger24Array = array[0..255] of T24BitSample;
  PIntegerArray = ^TIntegerArray;
  TIntegerArray = array[0..255] of integer;
  PFloatArray = ^TFloatArray;
  TFloatArray = array [0..255] of Single;
  PDoubleArray = ^TDoubleArray;
  TDoubleArray = array [0..255] of Double;

  TPass = array[0..2] of array[0..MaxChannels -1] of Single;

  { Used internal by the TDCWaveform and TDCSpectrum Class. Pointer to TVisualBuffer. }
  PVisualBuffer = ^TVisualBuffer;
  { Used internal by the TDCWaveform and TDCSpectrum Class. MaxVisualSamples(8192) * (MaxChannels(10)-1) Array of integer. }
  TVisualBuffer = array[0..MaxVisualSamples -1] of Integer;
  { Used internal by the TDCWaveform and TDCSpectrum Class to Send an Event that the Visual Buffer has been Processed. }
  TDCVisualNotifyEvent = procedure(Sender : TObject; Data : PVisualBuffer; MinY, MaxY, NumSamples, Channels : integer) of object;

  IDSPVisualIntf = interface(IUnknown)
  ['{42959911-A7CE-4B8E-BBC0-4E89E8DBB25C}']
    function get_VisualData(out VisualBuffer: PVisualBuffer; out Size: integer): HRESULT; stdcall;
  end;

  IAudioProcessor = interface(IDSPVisualIntf)
  ['{4F985C0A-683A-488A-988B-4A7EBEDAD888}']
    function get_EQEnabled(out Enabled: BOOL): HRESULT; stdcall;
    function set_EQEnabled(Enabled: BOOL): HRESULT; stdcall;
    function get_EQPreAmp(out Amp: Single): HRESULT; stdcall;
    function set_EQPreAmp(Amp: Single): HRESULT; stdcall;
    function get_EQGainDB(Band: integer; out Value: Single): HRESULT; stdcall;
    function set_EQGainDB(Band: integer; Value: Single): HRESULT; stdcall;
    function get_DAEnabled(out Enabled: BOOL): HRESULT; stdcall;
    function set_DAEnabled(Enabled: BOOL): HRESULT; stdcall;
    function get_DAMaxAmp(out Value: Cardinal): HRESULT; stdcall;
    function set_DAMaxAmp(Value: Cardinal): HRESULT; stdcall;
    function IsConnected: BOOL; stdcall;
  end;

implementation

end.
