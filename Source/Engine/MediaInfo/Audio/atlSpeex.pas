{ *************************************************************************** }
{                                                                             }
{ Audio Tools Library                                                         }
{ Class TSpeex - for manipulating with Speex file information                 }
{                                                                             }
{ http://mac.sourceforge.net/atl/                                             }
{ e-mail: macteam@users.sourceforge.net                                       }
{                                                                             }
{ Copyright (c) 2000-2002 by Jurgen Faul                                      }
{ Copyright (c) 2003-2005 by The MAC Team                                     }
{                                                                             }
{ Version 1.0 (31 December 2004) by vlads                                     }
{   - modified TOggVorbis class, needs clean up                               }
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

unit atlSpeex;

interface

uses
  Classes, SysUtils, atlVorbisComment;

const
  { Used with ChannelModeID property }
  VORBIS_CM_MONO = 1;                                    { Code for mono mode }
  VORBIS_CM_STEREO = 2;                                { Code for stereo mode }

  { Channel mode names }
  VORBIS_MODE: array [0..2] of string = ('Unknown', 'Mono', 'Stereo');

type
  { Class TOggVorbis }
  TSpeex = class(TObject)
  private
    { Private declarations }
    FFileSize: int64;
    FChannelModeID: Byte;
    FSampleRate: Word;
    FBitRateNominal: Word;
    FSamples: Integer;
    FEncoderVersion: string;

    //Unicode enabled
    vComments: TVorbisComment;
    isSpeex: boolean;
    FKeepEmptyFields: Boolean;

    function GetVendor: string;
    function FGetRatio: Double;
    function FIsValid: Boolean;

    procedure FResetData;

  public
    { Public declarations }
    constructor Create;                                     { Create object }
    destructor Destroy; override;                          { Destroy object }

    property ChannelModeID: Byte read FChannelModeID;   { Channel mode code }
    property BitRateNominal: Word read FBitRateNominal;  { Nominal bit rate }

    property Vendor: string read GetVendor;               { Vendor string }
    property KeepEmptyFields: Boolean read FKeepEmptyFields write FKeepEmptyFields;

    property Ratio: Double read FGetRatio;          { Compression ratio (%) }

    function ReadFromFile(const FileName: WideString): Boolean;

    property Valid: Boolean read FIsValid;             { True if file valid }
    function FileSize: int64;
    function EncoderType: string;
    function EncoderVendor: string;
    function EncoderVersion: string;
    function ChannelMode: string;
    function Duration: Double;
    function BitRate: Word;
    function SampleRate: Word;
    function isEncVBR: Boolean;
  end;

implementation

uses
    Math;
    { Tnt Units }
//    TntSysUtils, TntClasses, TntSystem;

const
  { Ogg page header ID }
  OGG_PAGE_ID = 'OggS';

  { Vorbis parameter frame ID }
  VORBIS_PARAMETERS_ID: string = #1 + 'vorbis';
  SPEEX_PARAMETERS_ID: string = 'Speex   ';

  { Vorbis tag frame ID }
  VORBIS_TAG_ID: string = #3 + 'vorbis';

  { CRC table for checksum calculating }
  CRC_TABLE: array [0..$FF] of Cardinal = (
    $00000000, $04C11DB7, $09823B6E, $0D4326D9, $130476DC, $17C56B6B,
    $1A864DB2, $1E475005, $2608EDB8, $22C9F00F, $2F8AD6D6, $2B4BCB61,
    $350C9B64, $31CD86D3, $3C8EA00A, $384FBDBD, $4C11DB70, $48D0C6C7,
    $4593E01E, $4152FDA9, $5F15ADAC, $5BD4B01B, $569796C2, $52568B75,
    $6A1936C8, $6ED82B7F, $639B0DA6, $675A1011, $791D4014, $7DDC5DA3,
    $709F7B7A, $745E66CD, $9823B6E0, $9CE2AB57, $91A18D8E, $95609039,
    $8B27C03C, $8FE6DD8B, $82A5FB52, $8664E6E5, $BE2B5B58, $BAEA46EF,
    $B7A96036, $B3687D81, $AD2F2D84, $A9EE3033, $A4AD16EA, $A06C0B5D,
    $D4326D90, $D0F37027, $DDB056FE, $D9714B49, $C7361B4C, $C3F706FB,
    $CEB42022, $CA753D95, $F23A8028, $F6FB9D9F, $FBB8BB46, $FF79A6F1,
    $E13EF6F4, $E5FFEB43, $E8BCCD9A, $EC7DD02D, $34867077, $30476DC0,
    $3D044B19, $39C556AE, $278206AB, $23431B1C, $2E003DC5, $2AC12072,
    $128E9DCF, $164F8078, $1B0CA6A1, $1FCDBB16, $018AEB13, $054BF6A4,
    $0808D07D, $0CC9CDCA, $7897AB07, $7C56B6B0, $71159069, $75D48DDE,
    $6B93DDDB, $6F52C06C, $6211E6B5, $66D0FB02, $5E9F46BF, $5A5E5B08,
    $571D7DD1, $53DC6066, $4D9B3063, $495A2DD4, $44190B0D, $40D816BA,
    $ACA5C697, $A864DB20, $A527FDF9, $A1E6E04E, $BFA1B04B, $BB60ADFC,
    $B6238B25, $B2E29692, $8AAD2B2F, $8E6C3698, $832F1041, $87EE0DF6,
    $99A95DF3, $9D684044, $902B669D, $94EA7B2A, $E0B41DE7, $E4750050,
    $E9362689, $EDF73B3E, $F3B06B3B, $F771768C, $FA325055, $FEF34DE2,
    $C6BCF05F, $C27DEDE8, $CF3ECB31, $CBFFD686, $D5B88683, $D1799B34,
    $DC3ABDED, $D8FBA05A, $690CE0EE, $6DCDFD59, $608EDB80, $644FC637,
    $7A089632, $7EC98B85, $738AAD5C, $774BB0EB, $4F040D56, $4BC510E1,
    $46863638, $42472B8F, $5C007B8A, $58C1663D, $558240E4, $51435D53,
    $251D3B9E, $21DC2629, $2C9F00F0, $285E1D47, $36194D42, $32D850F5,
    $3F9B762C, $3B5A6B9B, $0315D626, $07D4CB91, $0A97ED48, $0E56F0FF,
    $1011A0FA, $14D0BD4D, $19939B94, $1D528623, $F12F560E, $F5EE4BB9,
    $F8AD6D60, $FC6C70D7, $E22B20D2, $E6EA3D65, $EBA91BBC, $EF68060B,
    $D727BBB6, $D3E6A601, $DEA580D8, $DA649D6F, $C423CD6A, $C0E2D0DD,
    $CDA1F604, $C960EBB3, $BD3E8D7E, $B9FF90C9, $B4BCB610, $B07DABA7,
    $AE3AFBA2, $AAFBE615, $A7B8C0CC, $A379DD7B, $9B3660C6, $9FF77D71,
    $92B45BA8, $9675461F, $8832161A, $8CF30BAD, $81B02D74, $857130C3,
    $5D8A9099, $594B8D2E, $5408ABF7, $50C9B640, $4E8EE645, $4A4FFBF2,
    $470CDD2B, $43CDC09C, $7B827D21, $7F436096, $7200464F, $76C15BF8,
    $68860BFD, $6C47164A, $61043093, $65C52D24, $119B4BE9, $155A565E,
    $18197087, $1CD86D30, $029F3D35, $065E2082, $0B1D065B, $0FDC1BEC,
    $3793A651, $3352BBE6, $3E119D3F, $3AD08088, $2497D08D, $2056CD3A,
    $2D15EBE3, $29D4F654, $C5A92679, $C1683BCE, $CC2B1D17, $C8EA00A0,
    $D6AD50A5, $D26C4D12, $DF2F6BCB, $DBEE767C, $E3A1CBC1, $E760D676,
    $EA23F0AF, $EEE2ED18, $F0A5BD1D, $F464A0AA, $F9278673, $FDE69BC4,
    $89B8FD09, $8D79E0BE, $803AC667, $84FBDBD0, $9ABC8BD5, $9E7D9662,
    $933EB0BB, $97FFAD0C, $AFB010B1, $AB710D06, $A6322BDF, $A2F33668,
    $BCB4666D, $B8757BDA, $B5365D03, $B1F740B4);

  OggHeaderSize_27 = 27;

type
  { Ogg page header }
  OggHeader = packed record
    {0-3}      ID: array [1..4] of Char;                                 { Always "OggS" }
    {4}        StreamVersion: Byte;                           { Stream structure version }
    {5}        TypeFlag: Byte;                                        { Header type flag }
    {6-13}     AbsolutePosition: Int64;                      { Absolute granule position }
    {14-17}    Serial: Integer;                                   { Stream serial number }
    {18-21}    PageNumber: Integer;                               { Page sequence number }
    {22-25}    Checksum: Integer;                                        { Page checksum }
    {26}       Segments: Byte;                                 { Number of page segments }
    {27, ...}  LacingValues: array [1..$FF] of Byte;     { Lacing values - segment sizes }
  end;

  { Vorbis parameter header }
  VorbisHeader = packed record
    {7}  ID: array [1..7] of Char;                          { Always #1 + "vorbis" }
    {11} BitstreamVersion: array [1..4] of Byte;        { Bitstream version number }
    {12} ChannelMode: Byte;                                   { Number of channels }
    {16} SampleRate: Integer;                                   { Sample rate (hz) }
    {20} BitRateMaximal: Integer;                           { Bit rate upper limit }
    {24} BitRateNominal: Integer;                               { Nominal bit rate }
    {28} BitRateMinimal: Integer;                           { Bit rate lower limit }
    {29} BlockSize: Byte;                   { Coded size for small and long blocks }
    {30} StopFlag: Byte;                                                { Always 1 }
  end;

  SpeexHeader = packed record
    speex_string: array [1..8] of Char;
    speex_version: array [1..20] of Char;
    speex_version_id: Integer;
    header_size: Integer;
    rate: Integer;
    mode: Integer;
    mode_bitstream_version: Integer;
    nb_channels: Integer;
    bitrate: Integer;
    frame_size: Integer;
    vbr: Integer;
    frames_per_packet: Integer;
    extra_headers: Integer;
    reserved1: Integer;
    reserved2: Integer;
  end;

  { File data }
  FileInfo = record
    FPage, SPage, LPage: OggHeader;             { First, second and last page }
    VorbisParameters: VorbisHeader;             { Vorbis parameter header }
    SpeexParameters: SpeexHeader;
    FileSize: Int64;                            { File size (bytes) }
    Samples: Integer;                           { Total number of samples }
    ID3v2Size: Integer;                         { ID3v2 tag size (bytes) }
    SPagePos: Integer;                          { Position of second Ogg page }
    vComments: TVorbisComment;                  { Vorbis tag data }
    TagEndPos: Integer;                         { Tag end position }
    VorbisPages: Integer;
    isOggVorbis: boolean;
    isSpeex: boolean;
  end;

function GetSamples(const Source: TFileStream): Integer;
var
  Index, DataIndex, Iterator: Integer;
  Data: array [0..250] of Char;
  Header: OggHeader;
begin
  { Get total number of samples }
  Result := 0;
  for Index := 1 to 50 do
  begin
    DataIndex := Source.Size - (SizeOf(Data) - 10) * Index - 10;
    Source.Seek(DataIndex, soFromBeginning);
    Source.Read(Data, SizeOf(Data));
    { Get number of PCM samples from last Ogg packet header }
    for Iterator := SizeOf(Data) - 10 downto 0 do
      if Data[Iterator] +
        Data[Iterator + 1] +
        Data[Iterator + 2] +
        Data[Iterator + 3] = OGG_PAGE_ID then
      begin
        Source.Seek(DataIndex + Iterator, soFromBeginning);
        Source.Read(Header, SizeOf(Header));
        Result := Header.AbsolutePosition;
        exit;
      end;
  end;
end;

function GetLacingSize(const Buff : array of Byte; Size : Byte; var Last : Boolean) : Integer;
var
    i : Integer;
begin
    Result := 0; Last := False;
    for  i := 0 to Size - 1 do
    begin
        Result := Result + Buff[i];
        if Buff[i] < $FF then
        begin
            Last := True;
            Break;
        end;
  end;
end;

function GetOggInfo(const FileName: Widestring; var Info: FileInfo; DecodeComments: boolean): Boolean;
var
  Source: TFileStream;
  Data: PChar;
  Last: Boolean;
  Size : Integer;
  VorbisTagID: array [1..7] of Char; { Always #3 + "vorbis" }
  CommentsStream : TMemoryStream;
begin
  { Get info from file }
  Result := false;
  Source := nil;
  CommentsStream := nil;
  Data := nil;
  try
    Source := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
    Info.FileSize := Source.Size;
    { First Page }
    Source.Read(Info.FPage, OggHeaderSize_27{SizeOf(Info.FPage)});
    if Info.FPage.ID <> OGG_PAGE_ID then exit;
    Source.Read(Info.FPage.LacingValues, Info.FPage.Segments);
    Size := GetLacingSize(Info.FPage.LacingValues, Info.FPage.Segments, Last);
    GetMem(Data, Size);
    Source.Read(Data^, Size);
    { Read Vorbis or SPEEX parameter header }
    if AnsiStrLComp(PChar(VORBIS_PARAMETERS_ID), Data, Length(VORBIS_PARAMETERS_ID)) = 0 then
    begin
        Info.isOggVorbis := true;
        Move(Data^, Info.VorbisParameters, SizeOf(Info.VorbisParameters));
    end
    else if AnsiStrLComp(PChar(SPEEX_PARAMETERS_ID), Data, Length(SPEEX_PARAMETERS_ID)) = 0 then
    begin
        Info.isSpeex := true;
        Move(Data^, Info.SpeexParameters, SizeOf(Info.SpeexParameters));
    end
    else
        exit;

    Info.SPagePos := Source.Position;
    { Second Page }
    Source.Read(Info.SPage, OggHeaderSize_27{SizeOf(Info.SPage)});
    Source.Read(Info.SPage.LacingValues, Info.SPage.Segments);
    Size := GetLacingSize(Info.SPage.LacingValues, Info.SPage.Segments, Last);
    // Read all the time to preserv vendor in Vorbis.
    CommentsStream := TMemoryStream.Create;
    CommentsStream.CopyFrom(Source, Size);

    Info.VorbisPages := 1;
    Info.LPage.PageNumber := Info.SPage.PageNumber;
    // may span one or more pages, 10 is just a realistic limit
    while (not Last) and (Info.LPage.PageNumber < 10) do
    begin
        Source.Read(Info.LPage, OggHeaderSize_27{SizeOf(Info.SPage)});
        Source.Read(Info.LPage.LacingValues, Info.LPage.Segments);
        Size := GetLacingSize(Info.LPage.LacingValues, Info.LPage.Segments, Last);
        CommentsStream.CopyFrom(Source, Size);

        Inc(Info.VorbisPages);
    end;
    Info.TagEndPos := Source.Position;
    // (Info.TagEndPos - Info.SPagePos)  is Comment size.


    CommentsStream.Seek(0, soFromBeginning);
    if (Info.isOggVorbis) then
    begin
        CommentsStream.Read(VorbisTagID, SizeOf(VorbisTagID));
        { Read Vorbis tag }
        if (VorbisTagID = VORBIS_TAG_ID) then
            Info.vComments.LoadFromStream(CommentsStream);
    end
    else
        Info.vComments.LoadFromStream(CommentsStream);

        { Get total number of samples }
    if (DecodeComments) then
        Info.Samples := GetSamples(Source);

    Result := true;
  finally
    Source.Free;
    if (CommentsStream <> nil) then CommentsStream.Free;
    FreeMem(Data);
  end;
end;

function BuildTag(const Info: FileInfo): TStream;
var
  //pad_buffer : array [0..1024] of char;
  StopFlag: Byte;
begin
  { Build Vorbis tag }
  Result := TMemoryStream.Create();

  { Write frame ID, vendor info and number of fields }
  if Info.isOggVorbis then
      Result.Write(PChar(VORBIS_TAG_ID)^, Length(VORBIS_TAG_ID));

  Info.vComments.SaveToStream(Result);

  if Info.isOggVorbis then
  begin
    StopFlag := 1;
    Result.Write(StopFlag, 1);
  end;
  // Ogg packets can actually be longer than their corresponding Vorbis packets.
  //FillChar(pad_buffer, sizeof(pad_buffer), 0);
  //Result.Write(pad_buffer, SizeOf(pad_buffer));
end;

procedure SetLacingValues(var Info: FileInfo; const NewTagSize: Integer);
var
  Index, Position, Value: Integer;
  Buffer: array [1..$FF] of Byte;
begin
  { Set new lacing values for the second Ogg page }
  Position := 1;
  Value := 0;
  for Index := Info.SPage.Segments downto 1 do
  begin
    if Info.SPage.LacingValues[Index] < $FF then
    begin
      Position := Index;
      Value := 0;
    end;
    Inc(Value, Info.SPage.LacingValues[Index]);
  end;
  Value := Value + NewTagSize -
    (Info.TagEndPos - Info.SPagePos - Info.SPage.Segments - OggHeaderSize_27);
  { Change lacing values at the beginning }
  for Index := 1 to Value div $FF do Buffer[Index] := $FF;
  Buffer[(Value div $FF) + 1] := Value mod $FF;
  if Position < Info.SPage.Segments then
    for Index := Position + 1 to Info.SPage.Segments do
      Buffer[Index - Position + (Value div $FF) + 1] :=
        Info.SPage.LacingValues[Index];
  Info.SPage.Segments := Info.SPage.Segments - Position + (Value div $FF) + 1;
  for Index := 1 to Info.SPage.Segments do
    Info.SPage.LacingValues[Index] := Buffer[Index];
end;

procedure CalculateCRC(var CRC: Cardinal; var Data; const Size: Cardinal);
var
  Index: Cardinal;
  // vlads Tmp fix
  //Buffer: array [0..SizeOf(Data)] of Byte absolute Data;
  Buffer: ^Byte;
begin
  Buffer := Addr(Data);
  { Calculate CRC through data }
  for Index := 0 to Size - 1 do
  begin
    CRC := (CRC shl 8) xor CRC_TABLE[((CRC shr 24) and $FF) xor Buffer^];
    Inc(Buffer);
  end;
end;

procedure SetCRC(const Destination: TFileStream; Info: FileInfo);
var
  Index: Integer;
  Value: Cardinal;
  Data: array [1..$FF] of Byte;
begin
  { Calculate and set checksum for Vorbis tag }
  Value := 0;
  CalculateCRC(Value, Info.SPage, Info.SPage.Segments + OggHeaderSize_27);
  Destination.Seek(Info.SPagePos + Info.SPage.Segments + OggHeaderSize_27, soFromBeginning);
  for Index := 1 to Info.SPage.Segments do
    if Info.SPage.LacingValues[Index] > 0 then
    begin
      Destination.Read(Data, Info.SPage.LacingValues[Index]);
      CalculateCRC(Value, Data, Info.SPage.LacingValues[Index]);
    end;
  Destination.Seek(Info.SPagePos + 22, soFromBeginning);
  Destination.Write(Value, SizeOf(Value));
end;

function RebuildFile(FileName: Widestring; Tag: TStream; Info: FileInfo): Boolean;
var
  Source, Destination: TFileStream;
  BufferName: WideString;
begin
  { Rebuild the file with the new Vorbis tag }
  Result := false;
  Source := nil;
  Destination := nil;
  if (not FileExists(FileName)) then exit;
  try
    { Create file streams }
    BufferName := FileName + '~';
    Source := TFileStream.Create(FileName, fmOpenRead);
    Destination := TFileStream.Create(BufferName, fmCreate);
    { Copy data blocks, First and Second page }
    Destination.CopyFrom(Source, Info.SPagePos);
    Destination.Write(Info.SPage, OggHeaderSize_27);
    Destination.Write(Info.SPage.LacingValues, Info.SPage.Segments);
    Destination.CopyFrom(Tag, 0);

    { Copy all other data after tag page }
    Source.Seek(Info.TagEndPos, soFromBeginning);
    Destination.CopyFrom(Source, Source.Size - Info.TagEndPos);
    SetCRC(Destination, Info);
    Source.Free;
    Source := nil;
    Destination.Free;
    Destination := nil;
    { Replace old file and delete temporary file }
    if (DeleteFile(FileName)) and (RenameFile(BufferName, FileName)) then
      Result := true
    else
      raise Exception.Create('');
  except
    if Source<> nil then Source.Free;
    if Destination <> nil then  Destination.Free;
    { Access error }
    if FileExists(BufferName) then DeleteFile(BufferName);
  end;
end;

constructor TSpeex.Create;
begin
  { Object constructor }
  vComments := TVorbisComment.Create;
  FResetData;
  inherited;
end;

destructor TSpeex.Destroy;
begin
  { Object destructor }
  vComments.Free;
  inherited;
end;

procedure TSpeex.FResetData;
begin
    { Reset variables }
    FFileSize := 0;
    FChannelModeID := 0;
    FSampleRate := 0;
    FBitRateNominal := 0;
    FSamples := 0;
    isSpeex := false;
    vComments.Clear;
    FEncoderVersion := '';
end;

function TSpeex.ChannelMode: string;
begin
    { Get channel mode name }
    Result := VORBIS_MODE[FChannelModeID];
end;

function TSpeex.FileSize: int64;
begin
    Result := FFileSize;
end;

function TSpeex.Duration: Double;
begin
  { Calculate duration time }
  if FSamples > 0 then
    if FSampleRate > 0 then
      Result := FSamples / FSampleRate
    else
      Result := 0
  else
    if (FBitRateNominal > 0) and (FChannelModeID > 0) then
      Result := FFileSize /
        FBitRateNominal / FChannelModeID / 125 * 2
    else
      Result := 0;
end;

function TSpeex.BitRate: Word;
begin
  { Calculate average bit rate }
  Result := 0;
  if Duration > 0 then
    Result := Round(FFileSize / Duration / 125);
end;

function TSpeex.FIsValid: Boolean;
begin
  { Check for file correctness }
  Result := (FChannelModeID in [VORBIS_CM_MONO, VORBIS_CM_STEREO]) and
    (SampleRate > 0) and (Duration > 0.1) and (BitRate > 0);
end;

function TSpeex.ReadFromFile(const FileName: Widestring): Boolean;
var
  Info: FileInfo;
begin
  { Read data from file }
  Result := false;
  FResetData;
  FillChar(Info, SizeOf(Info), 0);
  Info.vComments := vComments;
  if GetOggInfo(FileName, Info, true) then
  begin
    { Fill variables }
    FFileSize := Info.FileSize;
    if Info.isOggVorbis then
    begin
        FChannelModeID := Info.VorbisParameters.ChannelMode;
        FSampleRate := Info.VorbisParameters.SampleRate;
        FBitRateNominal := Round(Info.VorbisParameters.BitRateNominal / 1000);
    end
    else if Info.isSpeex then
    begin
        FChannelModeID := Info.SpeexParameters.nb_channels;
        FSampleRate := Info.SpeexParameters.rate;
        FEncoderVersion := Trim(Info.SpeexParameters.speex_version);
        isSpeex := true;
    end;

    FSamples := Info.Samples;

    Result := true;
  end;
end;

function TSpeex.EncoderType: string;
begin
    if isSpeex then
        Result := 'Speex'
    else
        Result := 'Ogg Vorbis';
end;

function TSpeex.EncoderVendor: string;
begin
    Result :=  vComments.Vendor;
end;

function TSpeex.EncoderVersion: string;
begin
    if isSpeex then
        Result := FEncoderVersion
    else
        Result := 'NA';
end;

function TSpeex.isEncVBR: Boolean;
begin
    Result := true;
end;

function TSpeex.SampleRate: Word;
begin
    Result :=  FSampleRate;
end;

function TSpeex.GetVendor: string;
begin
    Result := vComments.Vendor;
end;

function TSpeex.FGetRatio: Double;
begin
  { Get compression ratio }
  if FIsValid then
    //Result := FFileSize / (FSamples * FChannelModeID * FBitsPerSample / 8 + 44) * 100
    Result := FFileSize / (FSamples * (FChannelModeID * 16 / 8) + 44) * 100
  else
    Result := 0;
end;

end.
