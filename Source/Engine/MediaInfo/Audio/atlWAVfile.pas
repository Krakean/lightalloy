{ *************************************************************************** }
{                                                                             }
{ Audio Tools Library                                                         }
{ Class TWAVfile - for manipulating with WAV files                            }
{                                                                             }
{ http://mac.sourceforge.net/atl/                                             }
{ e-mail: macteam@users.sourceforge.net                                       }
{                                                                             }
{ Copyright (c) 2000-2002 by Jurgen Faul                                      }
{ Copyright (c) 2003-2005 by The MAC Team                                     }
{                                                                             }
{ Version 1.43 (27 August 2004) by Gambit                                     }
{   - added procedures: TrimFromEnd, TrimFromBeginning and FindSilence        }
{   - removed WriteNewLength procedure (replaced with TrimFromEnd)            }
{   - fixed some FormatSize/HeaderSize/SampleNumber related bugs              }
{                                                                             }
{ Version 1.32 (05 June 2004) by Gambit                                       }
{   - WriteNewLength now properly truncates the file                          }
{                                                                             }
{ Version 1.31 (April 2004) by Gambit                                         }
{   - Added Ratio property                                                    }
{                                                                             }
{ Version 1.3 (22 February 2004) by Gambit                                    }
{   - SampleNumber is now read correctly                                      }
{   - added procedure to change the duration (SampleNumber and FileSize)      }
{     of the wav file (can be used for example to trim off the encoder        }
{     padding from decoded mp3 files)                                         }
{                                                                             }
{ Version 1.2 (14 January 2002)                                               }
{   - Fixed bug with calculating of duration                                  }
{   - Some class properties added/changed                                     }
{                                                                             }
{ Version 1.1 (9 October 2001)                                                }
{   - Fixed bug with WAV header detection                                     }
{                                                                             }
{ Version 1.0 (31 July 2001)                                                  }
{   - Info: channel mode, sample rate, bits per sample, file size, duration   }
{                                                                             }
{ This library is free software; you can redistribute it and/or               }
{ modify it under the terms of the GNU Lesser General Public                  }
{ License as published by the Free Software Foundation; either                }
{ version 2.1 of the License, or (at your option) any later version.          }
{                                                                             }
{ This library is distributed in the hope that it will be useful,             }
{ but WITHOUT ANY WARRANTY; without even the implied warranty of              }
{ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU           }
{ Lesser General Public License for more details.                             }
{                                                                             }
{ You should have received a copy of the GNU Lesser General Public            }
{ License along with this library; if not, write to the Free Software         }
{ Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA   }
{                                                                             }
{ *************************************************************************** }


unit atlWAVfile;

interface

uses
  Classes, SysUtils;

const
  { Format type names }
  WAV_FORMAT_UNKNOWN = 'Unknown';
  WAV_FORMAT_PCM = 'Windows PCM';
  WAV_FORMAT_ADPCM = 'Microsoft ADPCM';
  WAV_FORMAT_ALAW = 'A-LAW';
  WAV_FORMAT_MULAW = 'MU-LAW';
  WAV_FORMAT_DVI_IMA_ADPCM = 'DVI/IMA ADPCM';
  WAV_FORMAT_MP3 = 'MPEG Layer III';

  { Used with ChannelModeID property }
  WAV_CM_MONO = 1;                                      { Index for mono mode }
  WAV_CM_STEREO = 2;                                  { Index for stereo mode }

  { Channel mode names }
  WAV_MODE: array [0..2] of string = ('Unknown', 'Mono', 'Stereo');

type
  { Class TWAVfile }
  TWAVfile = class(TObject)
    private
      { Private declarations }
      FValid: Boolean;
      FFormatSize: Cardinal;
      FFormatID: Word;
      FChannelNumber: Byte;
      FSampleRate: Cardinal;
      FBytesPerSecond: Cardinal;
      FBlockAlign: Word;
      FBitsPerSample: Byte;
      FSampleNumber: Cardinal;
      FHeaderSize: Cardinal;
      FFileSize: Cardinal;
      FFileName: String;
      FAmountTrimBegin: Cardinal;
      FAmountTrimEnd: Cardinal;
      procedure FResetData;
      function FGetFormat: string;
      function FGetChannelMode: string;
      function FGetDuration: Double;
      function FGetRatio: Double;
    public
      { Public declarations }
      constructor Create;                                     { Create object }
      function ReadFromFile(const FileName: string): Boolean;   { Load header }
      property Valid: Boolean read FValid;             { True if header valid }
      property FormatSize: Cardinal read FFormatSize;
      property FormatID: Word read FFormatID;              { Format type code }
      property Format: string read FGetFormat;             { Format type name }
      property ChannelNumber: Byte read FChannelNumber;  { Number of channels }
      property ChannelMode: string read FGetChannelMode;  { Channel mode name }
      property SampleRate: Cardinal read FSampleRate;      { Sample rate (hz) }
      property BytesPerSecond: Cardinal read FBytesPerSecond;  { Bytes/second }
      property BlockAlign: Word read FBlockAlign;           { Block alignment }
      property BitsPerSample: Byte read FBitsPerSample;         { Bits/sample }
      property HeaderSize: Cardinal read FHeaderSize;   { Header size (bytes) }
      property FileSize: Cardinal read FFileSize;         { File size (bytes) }
      property Duration: Double read FGetDuration;       { Duration (seconds) }
      property SampleNumber: Cardinal read FSampleNumber;
      procedure TrimFromBeginning(const Samples: Cardinal);
      procedure TrimFromEnd(const Samples: Cardinal);
      procedure FindSilence(const FromBeginning, FromEnd: Boolean);
      property Ratio: Double read FGetRatio;          { Compression ratio (%) }
      property AmountTrimBegin: Cardinal read FAmountTrimBegin;
      property AmountTrimEnd: Cardinal read FAmountTrimEnd;
  end;

implementation

const
  DATA_CHUNK = 'data';                                        { Data chunk ID }

type
  { WAV file header data }
  WAVRecord = record
    { RIFF file header }
    RIFFHeader: array [1..4] of Char;                        { Must be "RIFF" }
    FileSize: Integer;                           { Must be "RealFileSize - 8" }
    WAVEHeader: array [1..4] of Char;                        { Must be "WAVE" }
    { Format information }
    FormatHeader: array [1..4] of Char;                      { Must be "fmt " }
    FormatSize: Cardinal;                                        { Format size }
    FormatID: Word;                                        { Format type code }
    ChannelNumber: Word;                                 { Number of channels }
    SampleRate: Integer;                                   { Sample rate (hz) }
    BytesPerSecond: Integer;                                   { Bytes/second }
    BlockAlign: Word;                                       { Block alignment }
    BitsPerSample: Word;                                        { Bits/sample }
    DataHeader: array [1..4] of Char;                         { Can be "data" }
    SampleNumber: Cardinal;                     { Number of samples (optional) }
  end;

{ ********************* Auxiliary functions & procedures ******************** }

function ReadWAV(const FileName: string; var WAVData: WAVRecord): Boolean;
var
  SourceFile: file;
begin
  try
    Result := true;
    { Set read-access and open file }
    AssignFile(SourceFile, FileName);
    FileMode := 0;
    Reset(SourceFile, 1);
    { Read header }
    BlockRead(SourceFile, WAVData, 36);

    { Read number of samples }
    if FileSize(SourceFile) > (WAVData.FormatSize + 24) then
    begin
      Seek(SourceFile, WAVData.FormatSize + 24);
      BlockRead(SourceFile, WAVData.SampleNumber, 4);
    end;

    CloseFile(SourceFile);
  except
    { Error }
    Result := false;
  end;
end;

{ --------------------------------------------------------------------------- }

function HeaderIsValid(const WAVData: WAVRecord): Boolean;
begin
  Result := true;
  { Header validation }
  if WAVData.RIFFHeader <> 'RIFF' then Result := false;
  if WAVData.WAVEHeader <> 'WAVE' then Result := false;
  if WAVData.FormatHeader <> 'fmt ' then Result := false;
  if (WAVData.ChannelNumber <> WAV_CM_MONO) and
    (WAVData.ChannelNumber <> WAV_CM_STEREO) then Result := false;
end;

{ ********************** Private functions & procedures ********************* }

procedure TWAVfile.FResetData;
begin
  { Reset all data }
  FValid := false;
  FFormatSize := 0;
  FFormatID := 0;
  FChannelNumber := 0;
  FSampleRate := 0;
  FBytesPerSecond := 0;
  FBlockAlign := 0;
  FBitsPerSample := 0;
  FSampleNumber := 0;
  FHeaderSize := 0;
  FFileSize := 0;
  FFileName := '';
  FAmountTrimBegin := 0;
  FAmountTrimEnd := 0;
end;

{ --------------------------------------------------------------------------- }

function TWAVfile.FGetFormat: string;
begin
  { Get format type name }
  case FFormatID of
    1: Result := WAV_FORMAT_PCM;
    2: Result := WAV_FORMAT_ADPCM;
    6: Result := WAV_FORMAT_ALAW;
    7: Result := WAV_FORMAT_MULAW;
    17: Result := WAV_FORMAT_DVI_IMA_ADPCM;
    85: Result := WAV_FORMAT_MP3;
  else
    Result := '';
  end;
end;

{ --------------------------------------------------------------------------- }

function TWAVfile.FGetChannelMode: string;
begin
  { Get channel mode name }
  Result := WAV_MODE[FChannelNumber];
end;

{ --------------------------------------------------------------------------- }

function TWAVfile.FGetDuration: Double;
begin
  { Get duration }
  Result := 0;
  if FValid then
  begin
    if (FSampleNumber = 0) and (FBytesPerSecond > 0) then
      Result := (FFileSize - FHeaderSize) / FBytesPerSecond;
    if (FSampleNumber > 0) and (FSampleRate > 0) then
      Result := FSampleNumber / FSampleRate;
  end;
end;

{ ********************** Public functions & procedures ********************** }

constructor TWAVfile.Create;
begin
  { Create object }
  inherited;
  FResetData;
end;

{ --------------------------------------------------------------------------- }

function TWAVfile.ReadFromFile(const FileName: string): Boolean;
var
  WAVData: WAVRecord;
begin
  { Reset and load header data from file to variable }
  FResetData;
  FillChar(WAVData, SizeOf(WAVData), 0);
  Result := ReadWAV(FileName, WAVData);
  { Process data if loaded and header valid }
  if (Result) and (HeaderIsValid(WAVData)) then
  begin
    FValid := true;
    { Fill properties with header data }
    FFormatSize := WAVData.FormatSize;
    FFormatID := WAVData.FormatID;
    FChannelNumber := WAVData.ChannelNumber;
    FSampleRate := WAVData.SampleRate;
    FBytesPerSecond := WAVData.BytesPerSecond;
    FBlockAlign := WAVData.BlockAlign;
    FBitsPerSample := WAVData.BitsPerSample;
    FSampleNumber := WAVData.SampleNumber div FBlockAlign;
    if WAVData.DataHeader = DATA_CHUNK then FHeaderSize := 44
    else FHeaderSize := WAVData.FormatSize + 28;
    FFileSize := WAVData.FileSize + 8;
    if FHeaderSize > FFileSize then FHeaderSize := FFileSize;
    FFileName := FileName;
  end;
end;

{ --------------------------------------------------------------------------- }

function TWAVfile.FGetRatio: Double;
begin
  { Get compression ratio }
  if FValid then
    if FSampleNumber = 0 then
      Result := FFileSize / ((FFileSize - FHeaderSize) / FBytesPerSecond * FSampleRate * (FChannelNumber * FBitsPerSample / 8) + 44) * 100
    else
      Result := FFileSize / (FSampleNumber * (FChannelNumber * FBitsPerSample / 8) + 44) * 100
  else
    Result := 0;
end;

{ --------------------------------------------------------------------------- }

procedure TWAVfile.TrimFromBeginning(const Samples: Cardinal);
var
  SourceFile: file;
  NewData, NewSamples, EraseOldData, NewFormatSize : Cardinal;
begin
  try
    // blah, blah... should be self explanatory what happens here...
    AssignFile(SourceFile, FFileName);
    FileMode := fmOpenWrite;
    Reset(SourceFile, 1);

    Seek(SourceFile, 16);
    NewFormatSize := (Samples * FBlockAlign) + FFormatSize;
    BlockWrite(SourceFile, NewFormatSize, SizeOf(NewFormatSize));

    Seek(SourceFile, FHeaderSize - 8);
    EraseOldData := 0;
    BlockWrite(SourceFile, EraseOldData, SizeOf(EraseOldData));

    Seek(SourceFile, FHeaderSize + (Samples * FBlockAlign) - 8);
    NewData := 1635017060;   // 'data'
    BlockWrite(SourceFile, NewData, SizeOf(NewData));
    NewSamples := (FSampleNumber - Samples) * FBlockAlign;
    BlockWrite(SourceFile, NewSamples, SizeOf(NewSamples));

    FFormatSize := NewFormatSize;
    FSampleNumber := FSampleNumber - Samples;
    FHeaderSize := FFormatSize + 28;

    CloseFile(SourceFile);
  except
    { Error }
  end;
end;

{ --------------------------------------------------------------------------- }

procedure TWAVfile.TrimFromEnd(const Samples: Cardinal);
var
  SourceFile: file;
  NewSamples, NewSize : Cardinal;
begin
  try
    AssignFile(SourceFile, FFileName);
    FileMode := fmOpenWrite;
    Reset(SourceFile, 1);

    Seek(SourceFile, 4);

    NewSamples := (FSampleNumber - Samples) * FBlockAlign;
    NewSize := NewSamples + FHeaderSize - 8;

    BlockWrite(SourceFile, NewSize, SizeOf(NewSize));

    Seek(SourceFile, FHeaderSize - 4);
    BlockWrite(SourceFile, NewSamples, SizeOf(NewSamples));

    Seek(SourceFile, NewSamples + FHeaderSize);
    Truncate(SourceFile);

    FSampleNumber := FSampleNumber - Samples;
    FFileSize := NewSamples + FHeaderSize;

    CloseFile(SourceFile);
  except
    { Error }
  end;
end;

{ --------------------------------------------------------------------------- }

procedure TWAVfile.FindSilence(const FromBeginning, FromEnd: Boolean);
var
  SourceFile: file;
  ReadSample : Integer;
  AmountBegin, AmountEnd : Cardinal;
begin
  try
    AssignFile(SourceFile, FFileName);
    FileMode := fmOpenRead;
    Reset(SourceFile, 1);

    if FromBeginning then
    begin
      AmountBegin := 0;
      ReadSample := 0;
      Seek(SourceFile, FHeaderSize);
      // this assumes 16bit stereo
      repeat
        BlockRead(SourceFile, ReadSample, SizeOf(ReadSample));
        if ReadSample = 0 then
          Inc(AmountBegin);
      until (ReadSample <> 0) or (Eof(SourceFile));
      FAmountTrimBegin := AmountBegin;
    end;

    if FromEnd then
    begin
      AmountEnd := 0;
      ReadSample := 0;
      repeat
        // this assumes 16bit stereo
        Seek(SourceFile, FFileSize - ((AmountEnd + 1) * 4));
        BlockRead(SourceFile, ReadSample, SizeOf(ReadSample));
        if ReadSample = 0 then
          Inc(AmountEnd);
      until ReadSample <> 0;
      FAmountTrimEnd := AmountEnd;
    end;

    CloseFile(SourceFile);
  except
    { Error }
  end;
end;

{ --------------------------------------------------------------------------- }

end.
