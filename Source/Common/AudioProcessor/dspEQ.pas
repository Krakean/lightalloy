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

unit dspEQ;

interface

uses
  Classes, Windows, Math, dspConst, dspUtils;


type
  TEQ = class
  private
    { Активен ли эквалайзер или нет }
    fEnabled: Boolean;
    { Коэфициэнт предусиления }
    fPreAmp: Single;
    { Частота, прирост и ширина каждой из полос }
    fFrequency: array[0..MAX_EQ_BANDS -1] of Single;
    fGainDB: array[0..MAX_EQ_BANDS -1] of Single;
    fBandwidth: array[0..MAX_EQ_BANDS -1] of Single;
    { Значения отвечающие за перенастройку эквалайзера в случае изменения
     входных данных }
    fNeedCoeff: Boolean;
    fNeedAmp: Boolean;
    fChannels: integer;
    fSampleRate: integer;
    { Наперед просчитаные коэфициенты для каждой из полос }
    fAlpha: array[0..MAX_EQ_BANDS -1] of Double;
    a1: array[0..MAX_EQ_BANDS -1] of Double;
    a2: array[0..MAX_EQ_BANDS -1] of Double;
    b1: array[0..MAX_EQ_BANDS -1] of Double;
    b2: array[0..MAX_EQ_BANDS -1] of Double;
    b0: array[0..MAX_EQ_BANDS -1] of Double;
    { Прошлые и позапрошлые значения входных и выходных сигналов }
    x0: array[0..MAX_EQ_BANDS -1, 0..MaxChannels -1] of Double;
    x1: array[0..MAX_EQ_BANDS -1, 0..MaxChannels -1] of Double;
    y0: array[0..MAX_EQ_BANDS -1, 0..MaxChannels -1] of Double;
    y1: array[0..MAX_EQ_BANDS -1, 0..MaxChannels -1] of Double;
    function GetPreAmp: Single;
    procedure SetPreAmp(Value: Single);
    function GetGainDB(ABand: integer): Single;
    procedure SetGainDB(ABand: integer; AValue: Single);
    procedure CalcAmplitude;
    procedure CalcCoefficients;
    procedure DoDSP(Buffer : Pointer; Size, Samplerate : Integer; Bits : Byte; Channels : Byte; Float : Boolean);
  public
    constructor Create;
    destructor Destroy; override;
    { Для обработки аудио данных }
    procedure Process(Buffer : Pointer; Size, Samplerate : Integer; Bits : Byte; Channels : Byte; Float : Boolean);
    { Для сброса в начале воспроизведения и при перемотке или паузе }
    procedure Flush;
    { Предусиление сигнала (от -20.0 ДБ до +20.0 ДБ) }
    property PreAmp: Single read GetPreAmp write SetPreAmp;
    { Приросты для каждой полосы (от -20.0 ДБ до +20.0 ДБ) }
    property GainDB[Band: integer]: Single read GetGainDB write SetGainDB;
    { Активен ли эквалайзер }
    property Enabled : Boolean read fEnabled write fEnabled;
  end;

implementation

{ TEQ }

constructor TEQ.Create;
var
  i: integer;
begin
  fEnabled := False;

  fPreAmp := 1.0;
  for i := 0 to MAX_EQ_BANDS -1 do
  begin
    fFrequency[i] := EQFreq[i];
    fBandwidth[i] := EQBandWidth[i];
    fGainDB[i] := 0.0;
  end;

  fNeedAmp := False;
  fNeedCoeff := True;
  fSampleRate := 0;
  fChannels := 0;
end;

destructor TEQ.Destroy;
begin
  inherited Destroy;
end;

procedure TEQ.CalcCoefficients;
var
  omega: Double;
  freq: Double;
  i: integer;
begin
  for i := 0 to MAX_EQ_BANDS -1 do
  begin
    if Round(fFrequency[i] * 2) >= Round(fSamplerate)
      then freq := 0
      else freq := fFrequency[i];

    omega := (2 * PI * freq) / fSamplerate;
    fAlpha[i] := 2 * sin(omega) / fBandwidth[i];
    b0[i] := -2 * cos(omega);
  end;

  CalcAmplitude;
end;

procedure TEQ.CalcAmplitude;
var
  amp: Double;
  i: integer;
begin
  for i := 0 to MAX_EQ_BANDS -1 do
  begin
    amp := power(10, fGainDB[i] / 40.0);
    b1[i] := 1 + (fAlpha[i] * amp);
    b2[i] := 1 - (fAlpha[i] * amp);
    a1[i] := 1 / (1 + (fAlpha[i] / amp));
    a2[i] := 1 - (fAlpha[i] / amp);
  end;
end;

procedure TEQ.Flush;
begin
  FillChar(x0, sizeof(x0), 0);
  FillChar(x1, sizeof(x1), 0);
  FillChar(y0, sizeof(y0), 0);
  FillChar(y1, sizeof(y1), 0);
end;

procedure TEQ.Process(Buffer : Pointer; Size, Samplerate : Integer; Bits : Byte; Channels : Byte; Float : Boolean);
begin
  if not fEnabled then Exit;

  if Channels > MaxChannels then Channels := MaxChannels;

  if fNeedCoeff or (fSampleRate <> Samplerate) or (fChannels <> Channels) then
  begin
    fNeedCoeff := False;
    fSampleRate := Samplerate;
    fChannels := Channels;
    CalcCoefficients;
    Flush;
  end;

  if (fNeedAmp) then
  begin
    CalcAmplitude;
    fNeedAmp := False;
  end;

  DoDSP(Buffer,Size,Samplerate,Bits,Channels,Float);
end;

procedure TEQ.DoDSP(Buffer : Pointer; Size, Samplerate : Integer; Bits : Byte; Channels : Byte; Float : Boolean);
var
  Buf8: PByte;
  Buf16: PSmallInt;
  Buf24: P24BitSample;
  Buf32: PSingle;
  Buf32i: PInteger;
  c,i,n: integer;
  NumSamples : integer;
  so, si: Single;
begin
  NumSamples := Size div Channels div (Bits div 8);

  case Bits of
    8:
    begin
      for c := 0 to Channels -1 do
      begin
        Buf8 := PByte(@PByteArray(Buffer)[c]);
        for i := 0 to NumSamples -1 do
        begin
          si := ((Buf8^ - 128) / 128) * fPreAmp;

          for n := 0 to MAX_EQ_BANDS -1 do
          begin
            so := (b1[n]*si + b0[n]*x0[n,c] + b2[n]*x1[n,c] - b0[n]*y0[n,c] - a2[n]*y1[n,c]) * a1[n];

            x1[n,c] := x0[n,c];
            x0[n,c] := si;
            y1[n,c] := y0[n,c];
            y0[n,c] := so;

            si := so;
          end;

          Buf8^ := Clip_8(Round(so * 128)) + 128;
          inc(Buf8, Channels);
        end;
      end;
    end;
    16:
    begin
      for c := 0 to Channels -1 do
      begin
        Buf16 := PSmallInt(@PSmallIntArray(Buffer)[c]);
        for i := 0 to NumSamples -1 do
        begin
          si := (Buf16^ / 32768) * fPreAmp;

          for n := 0 to MAX_EQ_BANDS -1 do
          begin
            so := (b1[n]*si + b0[n]*x0[n,c] + b2[n]*x1[n,c] - b0[n]*y0[n,c] - a2[n]*y1[n,c]) * a1[n];

            x1[n,c] := x0[n,c];
            x0[n,c] := si;
            y1[n,c] := y0[n,c];
            y0[n,c] := so;

            si := so;
          end;

          Buf16^ := Clip_16(Round(so * 32768));
          inc(Buf16, Channels);
        end;
      end;
    end;
    24:
    begin
      for c := 0 to Channels -1 do
      begin
        Buf24 := P24BitSample(@PInteger24Array(Buffer)[c]);
        for i := 0 to NumSamples -1 do
        begin
          si := (Cvt24BitTo32(Buf24^) / 8388608) * fPreAmp;

          for n := 0 to MAX_EQ_BANDS -1 do
          begin
            so := (b1[n]*si + b0[n]*x0[n,c] + b2[n]*x1[n,c] - b0[n]*y0[n,c] - a2[n]*y1[n,c]) * a1[n];

            x1[n,c] := x0[n,c];
            x0[n,c] := si;
            y1[n,c] := y0[n,c];
            y0[n,c] := so;

            si := so;
          end;

          Buf24^ := Cvt32BitTo24(Clip_24(Round(so * 8388608)));
          inc(Buf24, Channels);
        end;
      end;
    end;
    32:
    begin
      if Float then
      begin
        for c := 0 to Channels -1 do
        begin
          Buf32 := PSingle(@PFloatArray(Buffer)[c]);
          for i := 0 to NumSamples -1 do
          begin
            si := Buf32^ * fPreAmp;

            for n := 0 to MAX_EQ_BANDS -1 do
            begin
              so := (b1[n]*si + b0[n]*x0[n,c] + b2[n]*x1[n,c] - b0[n]*y0[n,c] - a2[n]*y1[n,c]) * a1[n];

              x1[n,c] := x0[n,c];
              x0[n,c] := si;
              y1[n,c] := y0[n,c];
              y0[n,c] := so;

              si := so;
            end;

            Buf32^ := Clip_32F(so);
            inc(Buf32, Channels);
          end;
        end;
      end else
      begin
        for c := 0 to Channels -1 do
        begin
          Buf32i := PInteger(@PIntegerArray(Buffer)[c]);
          for i := 0 to NumSamples -1 do
          begin
            si := (Buf32i^ / 2147483648) * fPreAmp;

            for n := 0 to MAX_EQ_BANDS -1 do
            begin
              so := (b1[n]*si + b0[n]*x0[n,c] + b2[n]*x1[n,c] - b0[n]*y0[n,c] - a2[n]*y1[n,c]) * a1[n];

              x1[n,c] := x0[n,c];
              x0[n,c] := si;
              y1[n,c] := y0[n,c];
              y0[n,c] := so;

              si := so;
            end;

            Buf32i^ := Clip_32(Round(so * 2147483648));
            inc(Buf32i, Channels);
          end;
        end;
      end;
    end;
  end;
end;

function TEQ.GetPreAmp: Single;
begin
  Result := Log10(fPreAmp) * 40.0;
end;

procedure TEQ.SetPreAmp(Value: Single);
begin
  fPreAmp := Power(10.0, Value / 40.0);
end;

function TEQ.GetGainDB(ABand: integer): Single;
begin
  Result := fGainDB[ABand];
end;

procedure TEQ.SetGainDB(ABand: integer; AValue: Single);
begin
  fGainDB[ABand] := AValue;
  fNeedAmp := True;
end;

end.
