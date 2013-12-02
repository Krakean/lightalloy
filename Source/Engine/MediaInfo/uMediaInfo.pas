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
unit uMediaInfo;

interface

uses
  Windows, Classes, DirectShow9, SysUtils, ActiveX, MMSystem,
  CachedFile, stMappedStream, DXTypes, DSUtils, MultiLog;

type
  TVideoStream = packed record
    Duration:TREFERENCETIME;
    Width,Height:Longint;
    FrameRate:Double;
    BitRate:Longint;
    Codec:DWORD;
    KeyFrames:array of DWORD;
  end;

  TAudioStream = packed record
    Duration:TREFERENCETIME;
    Frequency:Longint;
    Channels:Longint;
    BitRate:Longint;
    Codec:WORD;
  end;

  TSubtitleStream = packed record
    Format: string;
    Lang: string;
  end;

  TUnknownStream = packed record
    Duration:TREFERENCETIME;
    StreamType:string;
  end;

  TFileInfo = packed record
    FileName,FileFormat:string;
    FileSize:Int64;
    Duration:TREFERENCETIME;
    Title,
    Artist,
    Album,
    Year,
    Genre,
    Encoder:string;
    VStreams:array of TVideoStream;
    AStreams:array of TAudioStream;
    SStreams:array of TSubtitleStream;
    UStreams:array of TUnknownStream;
    Comments:array of string;
  end;

  SUBTITLEINFO = packed record
    Offset: DWORD;
    Lang: array [0..3] of Char;
    TrackName: array [0..255] of WideChar;
  end;

  TMediaInfo = class(TObject)
  private
    FFileName:string;
    FMap:TCachedFile;
    FStrm:TMappedStream;

    FAPICStart:Cardinal;
    FAPICSize:Cardinal;

    function AspectRatio(aW,aH:Longint):string;
    function SplitTime(Time:TREFERENCETIME):string;
    function SplitTimeText(Time:TREFERENCETIME):string;
    function SplitNumber(Number:Int64;Spacer:Char):string;
    function AUDCodec(Tag:WORD):string;
    function BigFileSize(FN: String): Int64;
    function FourCC(FCC:Longint):string;
    function StrToDWORD(Str:string):DWORD;
    procedure AddComment(Name,Value:string);

    procedure DetectArtist;
    procedure SetDuration;
    procedure SetVideoBitrate;

    function ProcessAVI:Boolean;
    function ProcessIFO:Boolean;
    function ProcessMP3:Boolean;
    function ProcessAAC:Boolean;
    function ProcessAC3:Boolean;
    function ProcessAPE:Boolean;
    function ProcessCDA:Boolean;
    function ProcessFLA:Boolean;
    function ProcessMPC:Boolean;
    function ProcessOGG:Boolean;
    function ProcessWAV:Boolean;
    function ProcessWMA:Boolean;
    function ProcessWVP:Boolean;
    function ProcessTAG:Boolean;

    function UseFastInfo:Boolean;
    function UseMediaDet:Boolean;
  public
    FInfo:TFileInfo;

    constructor Create(CFile:TCachedFile); overload;
    constructor Create(StreamName:String); overload;
    destructor Destroy; override;

    procedure Reset;

    function GetFileFormat:string;
    function GetStreamFormat:string;
    procedure RetreiveInfo;

    function ProduceOverview:String;
    function ReplaceTAGs(Source:string):string;
    function ExtractCover(var RawData: TMemoryStream):string;
    function CodecInfo:String;
    function CodecSummary:String;
    function FormatInfo(FmtStr:String):String;
    property FileName:String read FFileName;
  end;

implementation

uses
  // Core.
  LACore, DShowHlp, FourCC, OtherGLobalVars,
  FilterLib, FilterBase, stFile, stAVITag, HttpDownload,

  // Audio Tools Library
  atlMPEGaudio, atlID3v1, atlID3v2, atlAACfile, atlAC3, atlAPEtag, atlCDAtrack,
  atlFLACfile, atlMusepack, atlMonkey, atlOggVorbis, atlWAVfile, atlWMAfile,
  atlWAVPackfile;

const
  MEDIATYPE_Subtitle: TGUID = '{E487EB08-6B26-4BE9-9DD3-993434D313FD}';
  MEDIASUBTYPE_UTF8: TGUID = '{87C0B230-03A8-4fdf-8010-B27A5848200D}';
  MEDIASUBTYPE_SSA: TGUID = '{3020560F-255A-4ddc-806E-6C5CC6DCD70A}';
  MEDIASUBTYPE_ASS: TGUID = '{326444F7-686F-47ff-A4B2-C8C96307B4C2}';
  MEDIASUBTYPE_USF: TGUID = '{B753B29A-0A96-45be-985F-68351D9CAB90}';
  MEDIASUBTYPE_VOBSUB: TGUID = '{F7239E31-9599-4e43-8DD5-FBAF75CF37F1}';

var
  // AAC.
  aacBitRateTypeID: Byte;

function TMediaInfo.AUDCodec(Tag:WORD): String;
begin
  Result := AFourCCDesc(Tag);
end;

procedure TMediaInfo.AddComment;
var
  Index:LongInt;
begin
  Index:=Length(FInfo.Comments);
  SetLength(FInfo.Comments,Index+1);
  if (Name='') then
    FInfo.Comments[Index]:=MS('Info.Comment')+': '+Value
  else
    FInfo.Comments[Index]:=Name+': '+Value;
end;

procedure TMediaInfo.SetVideoBitrate;
var
  l: Byte;
  VideoStreamsLength: Longint;
  AudioStreamsLength: Longint;
  CW: DWORD;
begin
  if FInfo.VStreams[0].BitRate > 0 then Exit;
  CW := Get8087CW;
  Set8087CW($133f);
  AudioStreamsLength := 0;
  if (FInfo.AStreams<>nil) then
    for l:=0 to Length(FInfo.AStreams)-1 do begin
      with FInfo.AStreams[l] do begin
        if (BitRate > 0) and (Duration > 0) then
          AudioStreamsLength := AudioStreamsLength + (Round((BitRate * Round(Duration/10000000)) / 8));
      end;
    end;
  VideoStreamsLength := Round(FInfo.FileSize / 1005) - AudioStreamsLength;
  FInfo.VStreams[0].BitRate := Round((VideoStreamsLength*8) / Round(FInfo.Duration/10000000));
  Set8087CW(CW);
end;

function TMediaInfo.AspectRatio;
var
  W,H,l:longint;
begin
  Result:='N/A';
  if (aW=0) or (aH=0) then Exit;
  W:=aW;
  H:=aH;
  for l:=2 to 1023 do
    while (((W mod l)=0) and ((H mod l)=0)) do begin
      W:=W div l;
      H:=H div l;
    end;
  Result:=Format('%d:%d',[W,H]);
end;

procedure TMediaInfo.DetectArtist;
var
  s: String;
  m: String;
  a, p: Word;
begin
  // Try for artist first.
  p := 0;
  s := ExtractFileName(FInfo.FileName);

  // Save all before a last ' - '.
  for a := Length(s) downto 1 do
    if s[a] = ' - ' then
      begin
        p := a;
        break;
      end;
  m := Copy(s, 1, p-1);
  FInfo.Artist := m;
  m := ''; s := '';
  // Try again for title now.
  p := 0;
  s := ExtractFileName(FInfo.FileName);
  // Save all after a last '-'.
  for a := Length(s) downto 1 do
    if s[a] = ' - ' then
      begin
        p := a;
        break;
      end;
  m := Copy(s, p + 1, MaxInt);

  // Final preparation. Drop the all after last dot and dot itself. It's our title.
  FInfo.Title := Copy(m, 1, Length(m)-Length(ExtractFileExt(m)));
end;

function TMediaInfo.BigFileSize;
var
  hf:THandle;
  LE:Cardinal;
begin
  Log('+TMediaInfo.BigFileSize');
  Result:=0;
  if IsURL then begin
    Log('-TMediaInfo.BigFileSize: not available for URL');
    Exit;
  end;
  SetLastError(0);
  hf:=CreateFile(PChar(FN),GENERIC_READ,FILE_SHARE_READ or FILE_SHARE_WRITE,
    NIL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0);
  if (hf<>INVALID_HANDLE_VALUE) then begin
    Int64Rec(Result).Lo:=GetFileSize(hf,@Int64Rec(Result).Hi);
    LE:=GetLastError;
    if ((Int64Rec(Result).Lo=$FFFFFFFF) and (LE<>NO_ERROR)) then begin
      Result:=0;
      Log(Format('!LastError=%.8x',[LE]));
    end;
    CloseHandle(hf);
  end else begin
    LogLE('!CreateFile');
  end;
  Log(Format('-TMediaInfo.BigFileSize(%d)',[Result]));
end;

function TMediaInfo.FourCC;
var
  l:LongInt;
begin
  if (FCC=0) then
    Result:='0x00000000'
  else begin
    SetLength(Result,4);
    Move(FCC,Result[1],4);
    Result:=Result;
  end;
  for l:=1 to Length(Result) do
    if (Result[l]<' ') then
      Result[l]:='?';
end;

function TMediaInfo.ProcessAVI;
begin
  Result:=FALSE;

  with vtAVITag.Create(FInfo.FileName) do
  if (TagAvailable) then begin
    if Trim(Title) <> '' then
      FInfo.Title  := Title;
    if (Director <> '') then
      AddComment('Director', Director);
    if (Copyright <> '') then
      AddComment('Copyright', Copyright);
    if (Product <> '') then
      AddComment('Product', Product);
    if (CreationDate <> '') then
      AddComment('CreationDate', CreationDate);
    if (Genre <> '') then
      AddComment('Genre', Genre);
    if (Subject <> '') then
      AddComment('Subject', Subject);
    if (Keywords <> '') then
      AddComment('Keywords', Keywords);
    if (Comment <> '') then
      AddComment('Comment', Comment);
    if (Writer <> '') then
      AddComment('Writer', Writer);
    if (Producer <> '') then
      AddComment('Producer', Producer);
    if (Editor <> '') then
      AddComment('Editor', Editor);
    if (Composer <> '') then
      AddComment('Composer', Composer);
    if (ProductionStudio <> '') then
      AddComment('ProductionStudio', ProductionStudio);
    if (Distributor <> '') then
      AddComment('Distributor', Distributor);
    if (Country <> '') then
      AddComment('Country', Country);
    if (Language <> '') then
      AddComment('Language', Language);
    if (Rating <> '') then
      AddComment('Rating', Rating);
    if (Starring <> '') then
      AddComment('Starring', Starring);
    if (Software <> '') then
      AddComment('Software', Software);
    if (Encoder <> '') then
      AddComment('Encoderer', Encoder);
    if (InternetAddress <> '') then
      AddComment('URL', InternetAddress);
    if (Resolution <> '') then
      AddComment('Resolution', Resolution);
  end;
end;

function TMediaInfo.ProcessIFO: Boolean;
begin
  Result := True;
  AddComment('Format:',FFourCCDesc('IFO'));
end;

function TMediaInfo.ProcessMP3;
var
  Index  : LongInt;
  laMPEG : TMPEGaudio;
begin
  Result := True;

  Index := Length(FInfo.AStreams);
  SetLength(FInfo.AStreams,Index+1);
  laMPEG := TMPEGAudio.Create;
  laMPEG.ReadFromFile(FInfo.FileName);
  with FInfo.AStreams[Index] do
  begin
    if (Pos('Layer III', laMPEG.Layer) <> 0) then
      Codec   := $0055
    else
      Codec   := $0050;

    Duration  := Trunc(laMPEG.Duration);
    Duration  := Duration * 10000000; // MSecs to RefTime.

    BitRate   := laMPEG.BitRate;
    Frequency := laMPEG.SampleRate;
    Channels  := laMPEG.Frame.ModeID;

    FInfo.Title := '';
    FInfo.Artist := '';

    with laMPEG.ID3v1 do begin
      ReadFromFile(FInfo.FileName);
      try
        if (Exists) then begin
          FInfo.Title := Title;
          FInfo.Artist := Artist;
          FInfo.Album := Album;
          FInfo.Year := Year;
          FInfo.Genre := Genre;
          AddComment('ID3v1 Version', '1.' + IntToStr(VersionID));
        end
      finally
      end;
    end;

    with laMPEG.ID3v2 do begin
      ReadFromFile(FInfo.FileName);
      try
        if (Exists) then begin
          FInfo.Title := Title;
          FInfo.Artist := Artist;
          FInfo.Album := Album;
          FInfo.Year := Year;
          FInfo.Genre := Genre;
          FAPICStart := APICStart;
          FAPICSize := APICSize;
          AddComment('ID3v2 Version', '2.' + IntToStr(VersionID));
        end;
      finally
      end;
    end;
    FInfo.Encoder:=laMPEG.Encoder;
    if laMPEG.Encoder<>'' then
      AddComment('MPEG Encoder', laMPEG.Encoder);
  end;

  laMPEG.Free;
end;

function TMediaInfo.ProcessAAC: Boolean;
var
  Index : LongInt;
  laAAC : TAACfile;
begin
  Result := True;

  Index:=Length(FInfo.AStreams);
  SetLength(FInfo.AStreams,Index+1);
  laAAC := TAACfile.Create;
  laAAC.ReadFromFile(FInfo.FileName);
  with FInfo.AStreams[Index] do
  begin
    Codec := $00FF;
    Duration := Trunc(laAAC.Duration * 10000000);

    BitRate   := laAAC.BitRate;
    Frequency := laAAC.SampleRate;
    Channels  := laAAC.Channels;

    // Unknown, VBR, CBR?
    aacBitRateTypeID := laAAC.BitRateTypeID;

    FInfo.Title := '';
    FInfo.Artist := '';
    if (laAAC.ID3v1.Exists) then
    begin
      FInfo.Title := laAAC.ID3v1.Title;
      FInfo.Artist := laAAC.ID3v1.Artist;
      FInfo.Album := laAAC.ID3v1.Album;
      FInfo.Year := laAAC.ID3v1.Year;
      FInfo.Genre := laAAC.ID3v1.Genre;
      AddComment('ID3v1 Version', '1.' + IntToStr(laAAC.ID3v1.VersionID));
    end;

    if (laAAC.ID3v2.Exists) then
    begin
      FInfo.Title := laAAC.ID3v2.Title;
      FInfo.Artist := laAAC.ID3v2.Artist;
      FInfo.Album := laAAC.ID3v2.Album;
      FInfo.Year := laAAC.ID3v2.Year;
      FInfo.Genre := laAAC.ID3v2.Genre;
      FAPICStart := laAAC.ID3v2.APICStart;
      FAPICSize := laAAC.ID3v2.APICSize;
      AddComment('ID3v2 Version', '2.' + IntToStr(laAAC.ID3v2.VersionID));
    end;

    if (laAAC.APETag.Exists) then
    begin
      FInfo.Title := laAAC.APETag.SeekField('Title');
      FInfo.Artist := laAAC.APETag.SeekField('Artist');
      FInfo.Album := laAAC.APETag.SeekField('Album');
      FInfo.Year := laAAC.APETag.SeekField('Year');
      FInfo.Genre := laAAC.APETag.SeekField('Genre');
      AddComment('APE Tag', IntToStr(laAAC.APEtag.Version));
    end;

    AddComment('MPEG Version', laAAC.MPEGVersion);
    AddComment('AAC Profile', laAAC.Profile);
  end;

  laAAC.Free;
end;

function TMediaInfo.ProcessAC3: Boolean;
var
  Index : LongInt;
  laAC3 : TAC3;
begin
  Result := True;

  Index:=Length(FInfo.AStreams);
  SetLength(FInfo.AStreams,Index+1);
  laAC3 := TAC3.Create;
  laAC3.ReadFromFile(FInfo.FileName);
  with FInfo.AStreams[Index] do
  begin
    Codec := $2000;
    Duration := Round(laAC3.Duration * 10000000);

    BitRate   := laAC3.BitRate;
    Frequency := laAC3.SampleRate;
    Channels  := laAC3.Channels;

    FInfo.Title := '';
    FInfo.Artist := '';
    FInfo.Album := '';
    FInfo.Year := '';
    FInfo.Genre := '';    
  end;
  laAC3.Free;
end;

function TMediaInfo.ProcessAPE: Boolean;
var
  Index : LongInt;
  laMNK : TMonkey;
  tempS : ShortString;
begin
  Result := True;

  Index := Length(FInfo.AStreams);
  SetLength(FInfo.AStreams, Index + 1);
  laMNK := TMonkey.Create;
  laMNK.ReadFromFile(FInfo.FileName);
  with FInfo.AStreams[Index] do
  begin
    Codec := $AEEF;
    Duration :=  Trunc(laMNK.Duration * 10000000);

    BitRate   := Trunc(laMNK.BitRate / 1000000);
    Frequency := laMNK.SampleRate;
    Channels  := laMNK.Channels;

    if (laMNK.ID3v1.Exists) then
    begin
      FInfo.Title := laMNK.ID3v1.Title;
      FInfo.Artist := laMNK.ID3v1.Artist;
      FInfo.Album := laMNK.ID3v1.Album;
      FInfo.Year := laMNK.ID3v1.Year;
      FInfo.Genre := laMNK.ID3v1.Genre;
      AddComment('ID3v1 Version', '1.' + IntToStr(laMNK.ID3v1.VersionID));
    end;

    if (laMNK.ID3v2.Exists) then
    begin
      FInfo.Title := laMNK.ID3v2.Title;
      FInfo.Artist := laMNK.ID3v2.Artist;
      FInfo.Album := laMNK.ID3v2.Album;
      FInfo.Year := laMNK.ID3v2.Year;
      FInfo.Genre := laMNK.ID3v2.Genre;
      FAPICStart := laMNK.ID3v2.APICStart;
      FAPICSize := laMNK.ID3v2.APICSize;
      AddComment('ID3v1 Version', '2.' + IntToStr(laMNK.ID3v2.VersionID));
    end;

    if (laMNK.APEtag.Exists) then
    begin
      FInfo.Title := laMNK.APETag.SeekField('Title');
      FInfo.Artist := laMNK.APETag.SeekField('Artist');
      FInfo.Album := laMNK.APETag.SeekField('Album');
      FInfo.Year := laMNK.APETag.SeekField('Year');
      FInfo.Genre := laMNK.APETag.SeekField('Genre');
      AddComment('APE Tag', IntToStr(laMNK.APEtag.Version));
    end;

    AddComment('Bits Per Sample', IntToStr(laMNK.Bits));
    AddComment('Compression Ratio', FormatFloat('0.00', laMNK.Ratio) + '% - ' + laMNK.CompressionModeStr);
    if (laMNK.Version <> 0) then
    begin
      tempS := IntToStr(laMNK.Version);
      Delete(tempS, Length(tempS), 1);
      Insert('.', tempS, 2);
      AddComment('APE File version', tempS);
    end;
  end;
end;

function TMediaInfo.ProcessCDA: Boolean;
var
  Index : LongInt;
  laCDA: TCDAtrack;
  laFile: vtFile;
  Time  : Double;
  Data : array[1..4] of Byte;
begin
  Result := True;
  Index := Length(FInfo.AStreams);
  SetLength(FInfo.AStreams, Index + 1);
  laCDA := TCDAtrack.Create;
  laCDA.ReadFromFile(FInfo.FileName);
  if laCDA.Valid then begin
    FInfo.Title := laCDA.Title;
    FInfo.Artist := laCDA.Artist;
    FInfo.Album := laCDA.Album;
    FInfo.Duration := Trunc(laCDA.Duration);
  end;
  laCDA.Free;

  laFile := vtFile.Create(FInfo.FileName, fmOpenRead or fmShareDenyWrite);
  laFile.Seek($28);
  laFile.Read(Data,4);
  Time:= Round((Data[3]*60)+Data[2])*10000000;
  FInfo.Duration:=Trunc(Time);
  laFile.Free;
  with FInfo.AStreams[Index] do
  begin
    Duration  := FInfo.Duration;
    Codec     := $0001;
    BitRate   := 1411;
    Frequency := 44100;
    Channels  := 2;
  end;
end;

function TMediaInfo.ProcessFLA: Boolean;
var
  Index : LongInt;
  laFLAC: TFLACfile;
begin
  Result := True;

  Index:=Length(FInfo.AStreams);
  SetLength(FInfo.AStreams,Index+1);
  laFLAC := TFLACfile.Create;
  laFLAC.ReadFromFile(FInfo.FileName);
  with FInfo.AStreams[Index] do
  begin
    Codec := $F1AC;
    Duration := Trunc(laFLAC.Duration * 10000000);

    BitRate   := laFLAC.BitRate;
    Frequency := laFLAC.SampleRate;
    Channels  := laFLAC.Channels;

    if (laFLAC.Exists) then
    begin
      FInfo.Title := laFLAC.Title;
      FInfo.Artist := laFLAC.Artist;
      FInfo.Album := laFLAC.Album;
      FInfo.Year := laFLAC.Year;
      FInfo.Genre := laFLAC.Genre;
    end;

    AddComment('Bits per sample', IntToStr(laFLAC.BitsPerSample));
    FInfo.Encoder:=laFLAC.Encoder;    
    if laFLAC.Encoder<>'' then
      AddComment('FLAC Encoder', laFLAC.Encoder);
  end;
  laFLAC.Free;
end;

function TMediaInfo.ProcessMPC: Boolean;
var
  Index : LongInt;
  laMPC : TMPEGplus;
begin
  Result := True;

  Index:=Length(FInfo.AStreams);
  SetLength(FInfo.AStreams,Index+1);
  laMPC := TMPEGplus.Create;
  laMPC.ReadFromFile(FInfo.FileName);
  with FInfo.AStreams[Index] do
  begin
    Codec := $EACC; // Mus(E) P(a)(C)(C).
    Duration := Round(laMPC.Duration * 10000000);

    BitRate   := laMPC.BitRate;
    Frequency := laMPC.SampleRate;
    Channels  := laMPC.ChannelModeID;

    with laMPC.ID3v1 do begin
      ReadFromFile(FInfo.FileName);
      try
        if (Exists) then begin
          FInfo.Title := Title;
          FInfo.Artist := Artist;
          FInfo.Album := Album;
          FInfo.Year := Year;
          FInfo.Genre := Genre;
          AddComment('ID3v1 Version', '1.' + IntToStr(VersionID));
        end
      finally
      end;
    end;

    with laMPC.ID3v2 do begin
      ReadFromFile(FInfo.FileName);
      try
        if (Exists) then begin
          FInfo.Title := Title;
          FInfo.Artist := Artist;
          FInfo.Album := Album;
          FInfo.Year := Year;
          FInfo.Genre := Genre;
          FAPICStart := APICStart;
          FAPICSize := APICSize;
          AddComment('ID3v2 Version', '2.' + IntToStr(VersionID));
        end;
      finally
      end;
    end;

    if laMPC.APEtag.Exists then
    begin
      FInfo.Title := laMPC.APEtag.SeekField('Title');
      FInfo.Artist := laMPC.APEtag.SeekField('Artist');
      FInfo.Album := laMPC.APEtag.SeekField('Album');
      FInfo.Year := laMPC.APEtag.SeekField('Year');
      FInfo.Genre := laMPC.APEtag.SeekField('Genre');
      AddComment('APE Tag', '+');
    end;

    AddComment('MPC Version', IntToStr(laMPC.StreamVersion));
    AddComment('MPC Profile', laMPC.Profile);
    FInfo.Encoder:=laMPC.Encoder;
    if laMPC.Encoder<>'' then
      AddComment('MPC Encoder', laMPC.Encoder);
  end;
  laMPC.Free;
end;

function TMediaInfo.ProcessOGG: Boolean;
var
  Index : LongInt;
  laOGG : TOggVorbis;
begin
  Result := True;

  Index:=Length(FInfo.AStreams);
  SetLength(FInfo.AStreams,Index+1);
  laOGG := TOggVorbis.Create;
  laOGG.ReadFromFile(FInfo.FileName);
  with FInfo.AStreams[Index] do
  begin
    Codec := $674F;

    Duration := Round(laOGG.Duration);
    Duration := Duration * 10000; // MSecs to RefTime.

    BitRate   := laOGG.BitRateNominal;
    Frequency := laOGG.SampleRate;
    Channels  := laOGG.ChannelModeID;

    try
      if laOGG.Valid then begin
        FInfo.Title := laOGG.Title;
        FInfo.Artist := laOGG.Artist;
        FInfo.Album := laOGG.Album;
        FInfo.Year := laOGG.Date;
        FInfo.Genre := laOGG.Genre;
        AddComment('OGG Tag', '+');
        if laOGG.ID3v2 then AddComment('ID3v2', '+');
      end
    finally
    end;
    FInfo.Encoder:=laOGG.Encoder;
    if laOGG.Encoder<>'' then
      AddComment('OGG Encoder', laOGG.Encoder);

    if (Duration=0) or not laOGG.Valid then   Result := False;
  end;
  laOGG.Free;
end;

function TMediaInfo.ProcessWMA: Boolean;
var
  Index : LongInt;
  laWMA : TWMAFile;
begin
  Result := True;

  Index:=Length(FInfo.AStreams);
  SetLength(FInfo.AStreams,Index+1);
  laWMA := TWMAfile.Create;
  laWMA.ReadFromFile(FInfo.FileName);
  with FInfo.AStreams[Index] do
  begin
    Codec := $0160;
    Duration := Trunc(laWMA.Duration);
    Duration := Duration * 10000000; // MSecs to RefTime.

    BitRate   := laWMA.BitRate;
    Frequency := laWMA.SampleRate;
    Channels  := laWMA.ChannelModeID;

    try
      if laWMA.Valid then
      begin
        FInfo.Title := laWMA.Title;
        FInfo.Artist := laWMA.Artist;
        FInfo.Album := laWMA.Album;
        FInfo.Year := laWMA.Year;
        FInfo.Genre := laWMA.Genre;
        AddComment('WMA Tag', '+');
      end;
    finally
    end;
  end;
  laWMA.Free;
end;

function TMediaInfo.ProcessWVP: Boolean;
var
  Index : LongInt;
  laWVPK : TWAVPackfile;
begin
  Result := True;

  Index:=Length(FInfo.AStreams);
  SetLength(FInfo.AStreams,Index+1);
  laWVPK := TWAVPackfile.Create;
  laWVPK.ReadFromFile(FInfo.FileName);
  with FInfo.AStreams[Index] do
  begin
    Codec := $5756;
    Duration := Trunc(laWVPK.Duration);
    Duration := Duration * 10000000; // MSecs to RefTime.

    BitRate   := Trunc(laWVPK.Bitrate);
    Frequency := laWVPK.SampleRate;
    Channels  := laWVPK.Channels;

    try
      if laWVPK.APEtag.Exists then
      begin
        FInfo.Title := laWVPK.APEtag.SeekField('Title');
        FInfo.Artist := laWVPK.APEtag.SeekField('Artist');
        FInfo.Album := laWVPK.APEtag.SeekField('Album');
        FInfo.Year := laWVPK.APEtag.SeekField('Year');
        FInfo.Genre := laWVPK.APEtag.SeekField('Genre');
        AddComment('APE Tag', '+');
      end;
    finally
    end;
    if laWVPK.Encoder<>'' then
      AddComment('WAVEPACK Encoder', laWVPK.Encoder);
  end;
  laWVPK.Free;
end;

function TMediaInfo.ProcessWAV: Boolean;
var
  Index : LongInt;
  laWAV : TWAVfile;
begin
  Result := True;

  Index := Length(FInfo.AStreams);
  SetLength(FInfo.AStreams, Index + 1);
  laWAV := TWAVfile.Create;
  laWAV.ReadFromFile(FInfo.FileName);
  with FInfo.AStreams[Index] do
  begin
    if (laWAV.Valid) then
    begin
      if laWAV.FormatID = 1 then
       Codec := $0001
      else if laWAV.FormatID = 2 then
       Codec := $0002
      else if laWAV.FormatID = 6 then
       Codec := $0006
      else if laWAV.FormatID = 7 then
       Codec := $0007
      else if laWAV.FormatID = 17 then
       Codec := $0017
      else if laWAV.FormatID = 85 then
       Codec := $0055; // mp3, ага.

      Duration  := Round(laWAV.Duration * 10000000);
      BitRate   := Round(laWAV.BytesPerSecond / 1000);
      Frequency := laWAV.SampleRate;
      Channels  := laWAV.ChannelNumber;

      if (laWAV.BitsPerSample <> 0) then
       AddComment('Bits per sample', IntToStr(laWAV.BitsPerSample));
    end;
  end;
  laWAV.Free;
end;

function TMediaInfo.ProcessTag: Boolean;
begin
  Result := True;
  FInfo.Title := DSH.MetaTags.Title;
  FInfo.FileFormat := 'Stream';
  AddComment('Site', DSH.MetaTags.SURL);
  AddComment('Server', DSH.MetaTags.SName);
  AddComment('Genre', DSH.MetaTags.Genre);
  AddComment('Bitrate', DSH.MetaTags.Bitrate+MS('Info.KBitPerSec'));
end;

function TMediaInfo.ProduceOverview;
 function BytesToStr(const i64Size: Int64): string;
 const
   i64GB = 1024 * 1024 * 1024;
   i64MB = 1024 * 1024;
   i64KB = 1024;
 begin
   if i64Size div i64GB > 0 then
     Result := Format('%.2f GB', [i64Size / i64GB])
   else if i64Size div i64MB > 0 then
     Result := Format('%.2f MB', [i64Size / i64MB])
   else if i64Size div i64KB > 0 then
     Result := Format('%.2f KB', [i64Size / i64KB])
   else
     Result := IntToStr(i64Size) + ' Byte(s)';
 end;
var
  l:longint;
  FOverview:String;
begin
  FOverview:=MS('Info.Location')+': '+FInfo.FileName+#13#10;
  FOverview:=MS('Info.FileName')+': '+FInfo.FileName+#13#10;
  FOverview:=FOverview+MS('Info.FileFormat')+': '+FInfo.FileFormat+ ' (' + FFourCCDesc(FInfo.FileFormat) + ')' + #13#10;
  FOverview:=FOverview+MS('Info.FileSize')+': '+BytesToStr(FInfo.FileSize)+#13#10;
  FOverview:=FOverview+MS('Info.Duration')+': '+ReplaceTags('%VideoDurationText% (%VideoDuration%)')+#13#10;

  if (FInfo.Title <> '') or (FInfo.Artist <> '') then
    FOverview:=FOverview+#13#10;
  if (FInfo.Artist <> '') then
    FOverview:=FOverview+MS('Info.Artist')+': '+FInfo.Artist+#13#10;
  if (FInfo.Title <> '') then
    FOverview:=FOverview+MS('Info.Title')+': '+FInfo.Title+#13#10;
  if (FInfo.Album <> '') then
    FOverview:=FOverview+MS('Info.Album')+': '+FInfo.Album+#13#10;
  if (FInfo.Year <> '') then
    FOverview:=FOverview+MS('Info.Year')+': '+FInfo.Year+#13#10;
  if (FInfo.Genre <> '') then
    FOverview:=FOverview+MS('Info.Genre')+': '+FInfo.Genre+#13#10;


  for l:=0 to Length(FInfo.VStreams)-1 do begin
    with FInfo.VStreams[l] do begin
      FOverview:=FOverview+#13#10;
      FOverview:=FOverview+MS('Info.Stream')+': '+MS('Info.TypeVideo')+#13#10;
      FOverview:=FOverview+MS('Info.Duration')+': '+SplitTimeText(Duration)+
                 ' ('+SplitTime(Duration)+')'+#13#10;
      FOverview:=FOverview+MS('Info.Codec')+' FourCC: '+FourCC(Codec)+ ' (' + VFourCCDesc(FourCC(Codec)) + ')' + #13#10;
      FOverview:=FOverview+Format(MS('Info.VideoSize')+': %d x %d (%s)'#13#10,
        [Width,Height,AspectRatio(Width,Height)]);
      FOverview:=FOverview+Format(MS('Info.FrameRate')+': %1.3f '+MS('Info.Hz')+#13#10,[FrameRate]);
      SetVideoBitrate;
      FOverview:=FOverview+Format(MS('Info.BitRate')+': %d '+MS('Info.KBitPerSec')+#13#10,[FInfo.VStreams[l].BitRate]);
    end;
  end;

  for l:=0 to Length(FInfo.AStreams)-1 do begin
    with FInfo.AStreams[l] do
    begin
      FOverview:=FOverview+#13#10;
      FOverview:=FOverview+MS('Info.Stream')+': '+MS('Info.TypeAudio')+#13#10;
      FOverview:=FOverview+MS('Info.Duration')+': '+SplitTimeText(Duration)+
                 ' ('+SplitTime(Duration)+')'+#13#10;
      FOverview:=FOverview+Format(MS('Info.Codec')+': 0x%.4x (%s)'#13#10,[Codec,AUDCodec(Codec)]);
      FOverview:=FOverview+Format(MS('Info.Format')+': %d '+MS('Info.Hz')+', ',[Frequency]);

      // FLAC & Wav family.
      if (Codec = $F1AC) or ((Codec = $0001) or (Codec = $0002) or (Codec = $0006) or (Codec = $5756)
        or (Codec = $0007) or (Codec = $0017) or ((Codec = $0055) and (FInfo.FileFormat = 'WAV'))) then
      begin
        case Channels of
          0 : FOverview := FOverview + 'unknown, ';
          1 : FOverview := FOverview + 'Mono, ';
          2 : FOverview := FOverview + 'Stereo, ';
        else
          FOverview := FOverview + 'multichannel sound (' + IntToStr(Channels) + '), '; // У Flac'a, однако, с самооценкой всё намана.
        end;
      end
      // MPC.
      else if (Codec = $EACC) then
      begin
        case Channels of
          0: FOverview := FOVerview + 'Unknown, ';
          1: FOverview := FOverview + 'Stereo, ';
          2: FOverview := FOverview + 'Joint Stereo, ';
        end;
      end
      // У OGG и WMA иной распорядок каналов.
      else if (Codec = $0000) or ((Codec = $0160) or (Codec = $0161)) then
      begin
        case Channels of
          0: FOverview := FOverview + 'Unknown, ';
          1: FOverview := FOverview + 'Mono, ';
          2: FOverview := FOverview + 'Stereo, ';
        end;
      end
      // AAC.
      else if (Codec = $00FF) then
      begin
        case Channels of
          0: FOverview := FOverview + 'Unknown, ';
          1: FOverview := FOverview + 'Mono, ';
          2: FOverview := FOverview + 'Stereo, ';
        else
          FOverview:=FOverview+IntToStr(Channels)+' '+MS('Info.Channels')+', ';
        end;
      end
      // AC3.
      else if (Codec = $2000) then
      begin
        case Channels of
          1 : FOverview := FOverview + 'Mono, ';
          2 : FOverview := FOverview + 'Stereo, ';
          3 : FOverview := FOverview + '2.1, ';
          4 : FOverview := FOverview + 'Quad, ';
          5 : FOverview := FOVerview + 'Surround, ';
        else
          FOverview:=FOverview+IntToStr(Channels)+' '+MS('Info.Channels')+', ';
        end;
      end
      else
      begin
        case Channels of
          0: FOverview := FOverview+'Stereo, ';
          1: FOverview := FOverview+'Joint Stereo, ';
          2: FOverview := FOverview+'Dual Channel, ';
          3: FOverview := FOverview+'Mono, ';
          4: FOverview := FOverview+'Unknown, ';
        else
          FOverview:=FOverview+IntToStr(Channels)+' '+MS('Info.Channels')+', ';
        end;
      end;

      // AAC
      if (Codec = $00FF) then
      begin
        if (aacBitRateTypeID = 2) then
          FOverview:=FOverview+IntToStr(Round(BitRate / 1000))+' '+MS('Info.KBitPerSec') + ' VBR'+#13#10
        else if (aacBitRateTypeID = 1) then
          FOverview:=FOverview+IntToStr(Round(BitRate / 1000))+' '+MS('Info.KBitPerSec') + ' CBR'+#13#10
        // Unknown
        else
          FOverview:=FOverview+IntToStr(BitRate)+' '+MS('Info.KBitPerSec')+#13#10;
      end
      else
        FOverview:=FOverview+IntToStr(BitRate)+' '+MS('Info.KBitPerSec')+#13#10;
    end;
  end;

  for l:=0 to Length(FInfo.SStreams)-1 do begin
    with FInfo.SStreams[l] do begin
      FOverview:=FOverview+#13#10;
      FOverview:=FOverview+MS('Info.Stream')+': '+MS('Info.TypeText')+#13#10;
      FOverview:=FOverview+MS('Info.Format')
      + ': ' + '#' + IntToStr(l+1) + ' ' + Format + ' ('+ UpperCase(Lang) +')' + #13#10;
    end;
  end;

  for l:=0 to Length(FInfo.UStreams)-1 do begin
    FOverview:=FOverview+#13#10;
    FOverview:=FOverview+MS('Info.Stream')+': '+FInfo.UStreams[l].StreamType+#13#10;
  end;

  if (Length(FInfo.Comments)>0) then begin
    FOverview:=FOverview+#13#10;
    for l:=0 to Length(FInfo.Comments)-1 do
    FOverview:=FOverview+FInfo.Comments[l]+#13#10;
  end;

  Result:=FOverview;
end;

function TMediaInfo.ReplaceTAGs;
 function BytesToStr(const i64Size: Int64): string;
 const
   i64GB = 1024 * 1024 * 1024;
   i64MB = 1024 * 1024;
   i64KB = 1024;
 begin
   if i64Size div i64GB > 0 then
     Result := Format('%.2f GB', [i64Size / i64GB])
   else if i64Size div i64MB > 0 then
     Result := Format('%.2f MB', [i64Size / i64MB])
   else if i64Size div i64KB > 0 then
     Result := Format('%.2f KB', [i64Size / i64KB])
   else
     Result := IntToStr(i64Size) + ' Byte(s)';
 end;
var
  Value:string;
  FSz:Int64;
begin
  Log('+TMediaInfo.ReplaceTAGs');
  Result := Source;

  Value:=ExtractFileName(FFileName); // BJ.AVI
  Result:=StringReplace(Result,'%FileName%',Value,[rfReplaceAll,rfIgnoreCase]);

  Value:=ExpandFileName(FFileName); // C:\Program Files\LA.exe
  Result:=StringReplace(Result,'%FullPath%',Value,[rfReplaceAll,rfIgnoreCase]);

  Value := 'N/A';
  FSz:=BigFileSize(FFileName);
  TotalSize:=TotalSize + FSz;
  Value:=BytesToStr(FSz);
  Result:=StringReplace(Result,'%Size%', Value, [rfReplaceAll, rfIgnoreCase]);

  Value:=FInfo.Artist;
  Result:=StringReplace(Result,'%Artist%',Value,[rfReplaceAll,rfIgnoreCase]);

  Value:=FInfo.Title;
  Result:=StringReplace(Result,'%Title%',Value,[rfReplaceAll,rfIgnoreCase]);

  Value:=FInfo.Album;
  Result:=StringReplace(Result,'%Album%',Value,[rfReplaceAll,rfIgnoreCase]);

  Value:=FInfo.Year;
  Result:=StringReplace(Result,'%Year%',Value,[rfReplaceAll,rfIgnoreCase]);

  Value:=FInfo.Genre;
  Result:=StringReplace(Result,'%Genre%',Value,[rfReplaceAll,rfIgnoreCase]);

  Value:=FInfo.Encoder;
  Result:=StringReplace(Result,'%Encoder%',Value,[rfReplaceAll,rfIgnoreCase]);

  Value:=FInfo.FileFormat; // DIVX, MPEG, ASF, WAV
  Result:=StringReplace(Result,'%FileFormat%',Value,[rfReplaceAll,rfIgnoreCase]);

  Value:='N/A';
  if (Length(FInfo.VStreams)>0) then
    Value:=IntToStr(FInfo.VStreams[0].Width); // 640x480
  Result:=StringReplace(Result,'%VideoWidth%',Value,[rfReplaceAll,rfIgnoreCase]);

  Value:='N/A';
  if (Length(FInfo.VStreams)>0) then
    Value:=IntToStr(FInfo.VStreams[0].Height); // 640x480
  Result:=StringReplace(Result,'%VideoHeight%',Value,[rfReplaceAll,rfIgnoreCase]);

  Value:='N/A';
  if (Length(FInfo.VStreams)>0) then
    Value:=AspectRatio(FInfo.VStreams[0].Width,FInfo.VStreams[0].Height); // 4:3
  Result:=StringReplace(Result,'%VideoAspectRatio%',Value,[rfReplaceAll,rfIgnoreCase]);

  Value:='N/A';
  if (Length(FInfo.VStreams)>0) then
    Value:=FourCC(FInfo.VStreams[0].Codec); // DIVX, MP43
  Result:=StringReplace(Result,'%VideoCodec%',Value,[rfReplaceAll,rfIgnoreCase]);

  Value:='N/A';
  if (Length(FInfo.VStreams)>0) then
    Value:=VFourCCDesc(FourCC(FInfo.VStreams[0].Codec)); // DIVX, MP43
  Result:=StringReplace(Result,'%VideoCodecDesc%',Value,[rfReplaceAll,rfIgnoreCase]);

  Value:='N/A'; // 120 Kbit/sec
  if (Length(FInfo.VStreams)>0) then begin
    SetVideoBitrate;
    Value:=IntToStr(FInfo.VStreams[0].BitRate)+' '+MS('Info.KBitPerSec');
  end;
  Result:=StringReplace(Result,'%VideoBitRate%',Value,[rfReplaceAll,rfIgnoreCase]);

  Value:='N/A'; // FrameSize/VideoRate
  Result:=StringReplace(Result,'%VideoQuality%',Value,[rfReplaceAll,rfIgnoreCase]);

  Value:=SplitTimeText(FInfo.Duration); // 3 мин 23 сек
  Result:=StringReplace(Result,'%VideoDurationText%',Value,[rfReplaceAll,rfIgnoreCase]);

  Value:=SplitTime(FInfo.Duration); // 3:23.032
  TotalDuration := TotalDuration + FInfo.Duration;
  Result:=StringReplace(Result,'%VideoDuration%',Value,[rfReplaceAll,rfIgnoreCase]);

  Value := 'N/A';
  if (Length(FInfo.VStreams) > 0) then
    Value:=Format('%1.2f '+MS('Info.Hz'),[FInfo.VStreams[0].FrameRate]); // 25,000 Hz
  Result:=StringReplace(Result,'%VideoFPS%',Value,[rfReplaceAll,rfIgnoreCase]);

  Value := 'N/A';
  if (Length(FInfo.AStreams) > 0) then
    Value := SplitTimeText(FInfo.AStreams[0].Duration); // 3 мин 30 сек.
  Result:=StringReplace(Result,'%AudioDurationText%',Value,[rfReplaceAll,rfIgnoreCase]);

  Value := 'N/A';
  if (Length(FInfo.AStreams) > 0) then
    Value := SplitTime(FInfo.AStreams[0].Duration); // 0:03:30.199
  Result := StringReplace(Result, '%AudioDuration%', Value, [rfReplaceAll, rfIgnoreCase]);

  Value := IntToStr(Length(FInfo.AStreams));
  Result := StringReplace(Result, '%AudioStreamsCount%', Value, [rfReplaceAll, rfIgnoreCase]);

  Value:='N/A';
  if (Length(FInfo.AStreams)>0) then
  begin
    with FInfo.AStreams[0] do
    begin
      Value:=Format('%d '+MS('Info.Hz')+', ',[Frequency]);

      // FLAC & Wav family.
      if (Codec = $F1AC) or ((Codec = $0001) or (Codec = $0002) or (Codec = $0006)
        or (Codec = $0007) or (Codec = $0017) or ((Codec = $0055) and (FInfo.FileFormat = 'WAV'))) then
      begin
        case Channels of
          0 : Value := Value + 'Unknown ';
          1 : Value := Value + 'Mono ';
          2 : Value := Value + 'Stereo ';
        else
          Value := Value + 'Multichannel (' + IntToStr(Channels) + ') '; // У Flac'a, однако, с самооценкой всё намана.
        end;
      end
      // MPC.
      else if (Codec = $EACC) then
      begin
        case Channels of
          0: Value := Value + 'Unknown ';
          1: Value := Value + 'Stereo ';
          2: Value := Value + 'Joint Stereo ';
        end;
      end
      // У OGG и WMA иной распорядок каналов.
      else if (Codec = $0000) or ((Codec = $0160) or (Codec = $0161)) then
      begin
        case Channels of
          0: Value := Value + 'Unknown ';
          1: Value := Value + 'Mono ';
          2: Value := Value + 'Stereo ';
        end;
      end
      // AAC.
      else if (Codec = $00FF) then
      begin
        case Channels of
          0: Value := Value + 'Unknown ';
          1: Value := Value + 'Mono ';
          2: Value := Value + 'Stereo ';
        else
          Value := Value+IntToStr(Channels)+' '+MS('Info.Channels')+' ';
        end;
      end
      // AC3.
      else if (Codec = $2000) then
      begin
        case Channels of
          1 : Value := Value + 'Mono ';
          2 : Value := Value + 'Stereo ';
          3 : Value := Value + '2.1 ';
          4 : Value := Value + 'Quad ';
          5 : Value := Value + 'Surround ';
        else
          Value := Value + IntToStr(Channels)+' '+MS('Info.Channels')+' ';
        end;
      end
      else
      begin
        case Channels of
          0: Value := Value+'Stereo ';
          1: Value := Value+'Joint Stereo ';
          2: Value := Value+'Dual Channel ';
          3: Value := Value+'Mono ';
          4: Value := Value+'Unknown ';
        else
          Value := Value + IntToStr(Channels)+' '+MS('Info.Channels')+' ';
        end;
      end;

      // AAC
      if (Codec = $00FF) then
      begin
        if (aacBitRateTypeID = 2) then
          Value := Value + IntToStr(Round(BitRate / 1000))+' '+MS('Info.KBitPerSec') + ' VBR'
        else if (aacBitRateTypeID = 1) then
          Value := Value + IntToStr(Round(BitRate / 1000))+' '+MS('Info.KBitPerSec') + ' CBR'
        // Unknown
        else
          Value := Value+IntToStr(BitRate)+' '+MS('Info.KBitPerSec');
      end
      else
        Value := Value + IntToStr(BitRate)+' '+MS('Info.KBitPerSec');
    end;
  end;  // 44100/Stereo
  Result:=StringReplace(Result,'%AudioFormat%',Value,[rfReplaceAll,rfIgnoreCase]);

  Value:='N/A';
  if (Length(FInfo.AStreams)>0) then
    Value:=IntToStr(FInfo.AStreams[0].Codec);  // MPEG-3,VoxWare
  Result:=StringReplace(Result,'%AudioCodec%',Value,[rfReplaceAll,rfIgnoreCase]);

  Value:='N/A';
  if (Length(FInfo.AStreams)>0) then
    Value:=AUDCodec(FInfo.AStreams[0].Codec);  // MPEG-3,VoxWare
  Result:=StringReplace(Result,'%AudioCodecDesc%',Value,[rfReplaceAll,rfIgnoreCase]);

  Value:='N/A';  // 100Kbit/sec ,VBR
  if (Length(FInfo.AStreams)>0) then
    Value:=IntToStr(FInfo.AStreams[0].BitRate)+' '+MS('Info.KBitPerSec');
  Result:=StringReplace(Result,'%AudioBitRate%',Value,[rfReplaceAll,rfIgnoreCase]);

  if (FInfo.VStreams <> nil) and (FInfo.AStreams <> nil) then
    Value := 'V+A'
  else if (FInfo.VStreams = nil) and (FInfo.AStreams <> nil) then
    Value := 'A'
  else if (FInfo.VStreams <> nil) and (FInfo.AStreams = nil) then
    Value := 'V-A'
  else
    Value := 'Unknown';
  Result := StringReplace(Result, '%MediaType%', Value, [rfReplaceAll, rfIgnoreCase]);

  Log('-TMediaInfo.ReplaceTAGs');
end;

function TMediaInfo.ExtractCover;
var
  ImageBuf:Pointer;
  FS:TFileStream;
  Header:array of Byte;
  Offset:Cardinal;
  i: Cardinal;
begin
  Result:='';
  if (RawData = nil) or (FAPICSize = 0) then Exit;

  GetMem(ImageBuf,FAPICSize);
  FS:=TFileStream.Create(FInfo.FileName, fmOpenRead or fmShareDenyNone);
  FS.Seek(FAPICStart,soFromBeginning);
  FS.ReadBuffer(ImageBuf^,FAPICSize);
  FS.Seek(FAPICStart,soFromBeginning);

  Offset:=0;
  SetLength(Header,48);
  Move(ImageBuf,Header,SizeOf(Header));
  for i:=0 to 48 do begin
    if ((Header[i]=$FF) and (Header[i+1]=$D8)) then begin
      Offset:=i;
      Result:='JPG';
      Break;
    end;
    if ((Header[i]=$42) and (Header[i+1]=$4D)) then begin
      Offset:=i;
      Result:='BMP';
      Break;
    end;
    if ((Header[i]=$89) and (Header[i+1]=$50)) then begin
      Offset:=i;
      Result:='PNG';
      Break;
    end;
  end;

  FS.Seek(FAPICStart+Offset,soFromBeginning);
  RawData.Size:=FAPICSize-Offset;
  RawData.CopyFrom(FS,FAPICSize-Offset);
  RawData.Seek(0,soFromBeginning);

  FS.Free;
end;

function TMediaInfo.GetFileFormat;
var
  laMPEG: TMPEGaudio;
  Offset: Cardinal;
begin
  Log('+GetFileFormat');
  Result:='Unknown';
  if not FileExists(FMap.FileName) then begin
    Log('-GetFileFormat: File not found');
    Exit;
  end;

  Offset:=0;
  // if FourCC = ID3
  if (FMap.GetWORD(0)=$4449) and  (FMap.GetBYTE(2)=$33)then begin
    Offset :=
      FMap.GetByte($6) * $200000 +
      FMap.GetByte($7) * $4000 +
      FMap.GetByte($8) * $80 +
      FMap.GetByte($9) + 10;
      if FMap.GetByte($5) and $10 = $10 then Inc(Offset, 10);
      if FInfo.FileSize < Offset then Offset:=0;
  end;

  // 1
  if (FMap.GetDWORD($00)=$46464952) and
     (FMap.GetDWORD($18)=$68697661)
  then
    Result:='AVI';
  // 2
  if (FMap.GetDWORD(0)=StrToDWORD('RIFF')) and
     (FMap.GetDWORD(8)=StrToDWORD('WAVE'))
  then
    Result:='WAV';
  // 3
  if (FMap.GetDWORD(0)=StrToDWORD('FORM')) and
     (FMap.GetDWORD(8)=StrToDWORD('AIFF'))
  then
    Result:='AIFF';
  // 4
  if (FMap.GetDWORD(0)=StrToDWORD('FORM')) and
     (FMap.GetDWORD(8)=StrToDWORD('AIFC'))
  then
    Result:='AIFC';
  // 5
  if (FMap.GetDWORD(0)=$BA010000) and (FMap.GetDWORD($C)=$BB010000) or
     (FMap.GetDWORD(0)=$B3010000) and (FMap.GetDWORD($C)=$B8010000)
  then
    Result:='MPG1';
  // 6
  if (FMap.GetDWORD(0)=$BA010000) and (FMap.GetBYTE($D)=$F8) and
     (FMap.GetBYTE($E)=$00)
  then
    Result:='MPG2';
  // 7
  if (FMap.GetBYTE(3)=$00) and (FMap.GetBYTE(5)=$AF) then
    Result:='FLIC';
  // 8
  if (FMap.GetDWORD(0)=StrToDWORD('RIFF')) and
     (FMap.GetDWORD(8)=StrToDWORD('CDXA'))
  then
    Result:='CDXA';
  // 9
  if (FMap.GetDWORD(4)=$70797466) then
    Result:='MP4';
  // 10
  if (FMap.GetDWORD($4)=StrToDWORD('moov')) or
     (FMap.GetDWORD($4)=StrToDWORD('mdat')) or
     (FMap.GetDWORD($4)=StrToDWORD('pnot')) or
     (FMap.GetDWORD($4)=StrToDWORD('skip')) or
     (FMap.GetDWORD($4)=StrToDWORD('wide')) or
     (FMap.GetDWORD($4)=StrToDWORD('mdat'))
  then
    Result:='QT';
  // 11
  if (FMap.GetDWORD(0)=$75B22630) or (FMap.GetDWORD(0)=$D6E229D1) then
    Result:='ASF';
  // 12
  if ((FMap.GetDWORD($08)=$7274616D) and (FMap.GetDWORD($0C)=$616B736F)) or
     ((FMap.GetDWORD($18)=$7274616D) and (FMap.GetDWORD($1C)=$616B736F)) or
     ((FMap.GetDWORD($20)=$7274616D) and (FMap.GetDWORD($24)=$616B736F))
  then
    Result:='MKV';
  // 13
  if (FMap.GetDWORD(0+Offset)=$5367674F) and
     (FMap.GetDWORD($1D)<>$65646976)
  then
    Result:='OGG';
  // 14
  if (FMap.GetDWORD(0)=$5367674F) and
     (FMap.GetDWORD($1D)=$65646976)
  then
    Result:='OGM';
  // 15
  if (FMap.GetDWORD(0)=$65747845) and
     (FMap.GetDWORD(4)=$6465646E)
  then
    Result:='XM';
  // 16
  if (FMap.GetDWORD($2C)=$4D524353) then
    Result:='S3M';
  // 17
  if (FMap.GetWORD(0)=$770B) then
    Result:='AC3';
  // 18
  if (FMap.GetDWORD(0)=$6468544D) then
    Result:='MIDI';
  // 19
  if (FMap.GetDWORD(0+Offset)=$072B504D) then
    Result:='MPC';
  // 20
  if (FMap.GetDWORD(0)=$01564C46) then
    Result:='FLV';
  // 21
  if (FMap.GetDWORD(0+Offset)=$4050F1FF) then
    Result:='AAC';
  // 22
  if (FMap.GetDWORD(0)=$03336165) then
    Result:='AT3';
  // 23
  if (FMap.GetDWORD(0+Offset)=$43614C66) then
    Result:='FLAC';
  // 24
  if (FMap.GetDWORD(0+Offset)=$2043414D) then
    Result:='APE';
  // 25
  if (FMap.GetDWORD(0)=$4D504D49) then
    Result:='IT';
  // 26
  if (FMap.GetDWORD(8)=$41444443) then
    Result:='CDA';
  // 27
  if (FMap.GetDWORD(8)=$11B00000) then
    Result:='MTS';
  // 28
  if (FMap.GetDWORD(0)=$464D522E) then
    Result:='RLMD';
  // 29
  if (FMap.GetBYTE(0)=$47) and (FMap.GetBYTE($BC)=$47) then
    Result:='TS';
  // 30
  if (FMap.GetDWORD(0)=$646E732E) then
    Result:='AU';
  // 31
  if (FMap.GetDWORD(0)=$56445644) then
    Result:='IFO';
  // 32
  if (FMap.GetDWORD(0)=$A3DF451A) and (FMap.GetDWORD(4)=$00000001) then
    Result:='WEBM';
  // 33
  if (FMap.GetDWORD(0)=$6B707677) then
    Result:='WVPK';
  // 34
  if (FMap.GetDWORD(0)=$4A424F4D) or (FMap.GetDWORD(0)=$58444E49) then
    Result:='BDMV';
  // 35
  if (FMap.GetDWORD(0)=$534C504D) then
    Result:='MPLS';
  // 36
  if (FMap.GetWORD(0+Offset)=$FAFF) or (FMap.GetWORD(0+Offset)=$FBFF) or
     (FMap.GetWORD(0+Offset)=$FCFF) or (FMap.GetWORD(0+Offset)=$FDFF) or
     (FMap.GetWORD(0+Offset)=$FEFF) or (FMap.GetWORD(0+Offset)=$FFFF) or
     (FMap.GetWORD(0+Offset)=$F2FF) or (FMap.GetWORD(0+Offset)=$F3FF)
  then
    Result:='MP3';
  // 37
  if (FMap.GetDWORD($438)=$2E4B2E4D) then
    Result:='MOD';

  if (Result='Unknown') then begin
    laMPEG:= TMPEGaudio.Create;
    laMPEG.ReadFromFile(FMap.FileName);
    if laMPEG.Valid then Result:='MP3';
    laMPEG.Free;
  end;

  Log('-GetFileFormat: '+Result);
end;

function TMediaInfo.GetStreamFormat;
var
  Offset: Cardinal;
begin
  Log('+GetStreamFormat');
  Result:='Unknown';
  if (FStrm=NIL) then begin
    Log('-GetStreamFormat: NULL stream!');
    Exit;
  end;

  Offset:=0;
  // if FourCC = ID3
  if (FStrm.GetWORD(0)=$4449) and  (FStrm.GetBYTE(2)=$33)then begin
    Offset :=
      FStrm.GetByte($6) * $200000 +
      FStrm.GetByte($7) * $4000 +
      FStrm.GetByte($8) * $80 +
      FStrm.GetByte($9) + 10;
      if FStrm.GetByte($5) and $10 = $10 then Inc(Offset, 10);
      if FStrm.Size < Offset then Offset:=0;
  end;

  // 1
  if (FStrm.GetDWORD($00)=$46464952) and
     (FStrm.GetDWORD($18)=$68697661)
  then
    Result:='AVI';
  // 2
  if (FStrm.GetDWORD(0)=StrToDWORD('RIFF')) and
     (FStrm.GetDWORD(8)=StrToDWORD('WAVE'))
  then
    Result:='WAV';
  // 3
  if (FStrm.GetDWORD(0)=StrToDWORD('FORM')) and
     (FStrm.GetDWORD(8)=StrToDWORD('AIFF'))
  then
    Result:='AIFF';
  // 4
  if (FStrm.GetDWORD(0)=StrToDWORD('FORM')) and
     (FStrm.GetDWORD(8)=StrToDWORD('AIFC'))
  then
    Result:='AIFC';
  // 5
  if (FStrm.GetDWORD(0)=$BA010000) and (FStrm.GetDWORD($C)=$BB010000) or
     (FStrm.GetDWORD(0)=$B3010000) and (FStrm.GetDWORD($C)=$B8010000)
  then
    Result:='MPG1';
  // 6
  if (FStrm.GetDWORD(0)=$BA010000) and (FStrm.GetBYTE($D)=$F8) and
     (FStrm.GetBYTE($E)=$00)
  then
    Result:='MPG2';
  // 7
  if (FStrm.GetBYTE(3)=$00) and (FStrm.GetBYTE(5)=$AF) then
    Result:='FLIC';
  // 8
  if (FStrm.GetDWORD(0)=StrToDWORD('RIFF')) and
     (FStrm.GetDWORD(8)=StrToDWORD('CDXA'))
  then
    Result:='CDXA';
  // 9
  if (FStrm.GetDWORD(4)=$70797466) then
    Result:='MP4';
  // 10
  if (FStrm.GetDWORD($4)=StrToDWORD('moov')) or
     (FStrm.GetDWORD($4)=StrToDWORD('mdat')) or
     (FStrm.GetDWORD($4)=StrToDWORD('pnot')) or
     (FStrm.GetDWORD($4)=StrToDWORD('skip')) or
     (FStrm.GetDWORD($4)=StrToDWORD('wide')) or
     (FStrm.GetDWORD($4)=StrToDWORD('mdat'))
  then
    Result:='QT';
  // 11
  if (FStrm.GetDWORD(0)=$75B22630) or (FStrm.GetDWORD(0)=$D6E229D1) then
    Result:='ASF';
  // 12
  if ((FStrm.GetDWORD($08)=$7274616D) and (FStrm.GetDWORD($0C)=$616B736F)) or
     ((FStrm.GetDWORD($18)=$7274616D) and (FStrm.GetDWORD($1C)=$616B736F)) or
     ((FStrm.GetDWORD($20)=$7274616D) and (FStrm.GetDWORD($24)=$616B736F))
  then
    Result:='MKV';
  // 13
  if (FStrm.GetDWORD(0+Offset)=$5367674F) and
     (FStrm.GetDWORD($1D)<>$65646976)
  then
    Result:='OGG';
  // 14
  if (FStrm.GetDWORD(0)=$5367674F) and
     (FStrm.GetDWORD($1D)=$65646976)
  then
    Result:='OGM';
  // 15
  if (FStrm.GetDWORD(0)=$65747845) and
     (FStrm.GetDWORD(4)=$6465646E)
  then
    Result:='XM';
  // 16
  if (FStrm.GetDWORD($2C)=$4D524353) then
    Result:='S3M';
  // 17
  if (FStrm.GetWORD(0)=$770B) then
    Result:='AC3';
  // 18
  if (FStrm.GetDWORD(0)=$6468544D) then
    Result:='MIDI';
  // 19
  if (FStrm.GetDWORD(0+Offset)=$072B504D) then
    Result:='MPC';
  // 20
  if (FStrm.GetDWORD(0)=$01564C46) then
    Result:='FLV';
  // 21
  if (FStrm.GetDWORD(0+Offset)=$4050F1FF) then
    Result:='AAC';
  // 22
  if (FStrm.GetDWORD(0)=$03336165) then
    Result:='AT3';
  // 23
  if (FStrm.GetDWORD(0+Offset)=$43614C66) then
    Result:='FLAC';
  // 24
  if (FStrm.GetDWORD(0+Offset)=$2043414D) then
    Result:='APE';
  // 25
  if (FStrm.GetDWORD(0)=$4D504D49) then
    Result:='IT';
  // 26
  if (FStrm.GetDWORD(8)=$41444443) then
    Result:='CDA';
  // 27
  if (FStrm.GetDWORD(8)=$11B00000) then
    Result:='MTS';
  // 28
  if (FStrm.GetDWORD(0)=$464D522E) then
    Result:='RLMD';
  // 29
  if (FStrm.GetBYTE(0)=$47) and (FStrm.GetBYTE($BC)=$47) then
    Result:='TS';
  // 30
  if (FStrm.GetDWORD(0)=$646E732E) then
    Result:='AU';
  // 31
  if (FStrm.GetDWORD(0)=$56445644) then
    Result:='IFO';
  // 32
  if (FStrm.GetDWORD(0)=$A3DF451A) and (FStrm.GetDWORD(4)=$00000001) then
    Result:='WEBM';
  // 33
  if (FStrm.GetDWORD(0)=$6B707677) then
    Result:='WVPK';
  // 34
  if (FStrm.GetDWORD(0)=$4A424F4D) or (FStrm.GetDWORD(0)=$58444E49) then
    Result:='BDMV';
  // 35
  if (FStrm.GetDWORD(0)=$534C504D) then
    Result:='MPLS';
  // 36
  if (FStrm.GetWORD(0+Offset)=$FAFF) or (FStrm.GetWORD(0+Offset)=$FBFF) or
     (FStrm.GetWORD(0+Offset)=$FCFF) or (FStrm.GetWORD(0+Offset)=$FDFF) or
     (FStrm.GetWORD(0+Offset)=$FEFF) or (FStrm.GetWORD(0+Offset)=$FFFF) or
     (FStrm.GetWORD(0+Offset)=$F2FF) or (FStrm.GetWORD(0+Offset)=$F3FF)
  then
    Result:='MP3';
  // 37
  if (FStrm.GetDWORD($438)=$2E4B2E4D) then
    Result:='MOD';

  Log('-GetStreamFormat: '+Result);
end;

procedure TMediaInfo.RetreiveInfo;
var
  Done:Boolean;
begin
  Log('+TMediaInfo.RetreiveInfo');
  Reset;
  Done:=FALSE;

  FInfo.FileName:=FFileName;
  FInfo.FileSize:=BigFileSize(FFileName);

  if IsURL then begin
    if IsShoutCast then
      if Core.PlayList.Entries.Items[Core.PlayList.PlayPos].FileName=FInfo.FileName then
        ProcessTag;
    FInfo.FileFormat:=GetStreamFormat;
    Exit;
  end;

  FInfo.FileFormat:=GetFileFormat;

  if (FInfo.FileFormat = 'AVI') then Done := ProcessAVI;
  if (FInfo.FileFormat = 'IFO') then Done := ProcessIFO;
  if (FInfo.FileFormat = 'MP3') then Done := ProcessMP3;
  if (FInfo.FileFormat = 'AAC') then Done := ProcessAAC;
  if (FInfo.FileFormat = 'AC3') then Done := ProcessAC3;
  if (FInfo.FileFormat = 'APE') then Done := ProcessAPE;
  if (FInfo.FileFormat = 'CDA') then Done := ProcessCDA;
  if (FInfo.FileFormat = 'FLAC')then Done := ProcessFLA;
  if (FInfo.FileFormat = 'MPC') then Done := ProcessMPC;
  if (FInfo.FileFormat = 'OGG') then Done := ProcessOGG;
  if (FInfo.FileFormat = 'OGM') then Done := ProcessOGG;
  if (FInfo.FileFormat = 'WAV') then Done := ProcessWAV;
  if (FInfo.FileFormat = 'WMA') then Done := ProcessWMA;
  if (FInfo.FileFormat = 'WVPK')then Done := ProcessWVP;  

  if not(Done) then DetectArtist;
  if not(Done) then Done := UseFastInfo;
  if not(Done) then Done := UseMediaDet;
  if not(Done) then AddComment('','Not identified');

  SetDuration;

  Log('-TMediaInfo.RetreiveInfo');
end;

procedure TMediaInfo.SetDuration;
var
  l:longint;
begin
  for l:=0 to Length(FInfo.VStreams)-1 do
    if (FInfo.VStreams[l].Duration>FInfo.Duration) then
      FINfo.Duration:=FInfo.VStreams[l].Duration;

  for l:=0 to Length(FInfo.AStreams)-1 do
    if (FInfo.AStreams[l].Duration>FInfo.Duration) then
      FINfo.Duration:=FInfo.AStreams[l].Duration;

  for l:=0 to Length(FInfo.UStreams)-1 do
    if (FInfo.UStreams[l].Duration>FInfo.Duration) then
      FINfo.Duration:=FInfo.UStreams[l].Duration;
end;

function TMediaInfo.SplitNumber;
var
  l:Int64;
begin
  Result:='';
  l:=Number;
  while (l>0) do begin
    if (l>999) then
      Result:=Spacer+Format('%.3d',[l mod 1000])+Result
    else
      Result:=IntToStr(l)+Result;
    l:=l div 1000;
  end;
end;

function TMediaInfo.SplitTimeText;
var
  DTime:Double;
begin
  DTime:=Time/10000000;
  Result:='';
  if (DTime>3600) then
    Result:=Result+IntToStr(Trunc(DTime) div 3600)+' '+MS('Info.Hour')+' ';
  if (DTime>60) then
    Result:=Result+IntToStr((Trunc(DTime) div 60) mod 60)+' '+MS('Info.Min')+' ';
  Result:=Result+Format('%d '+MS('Info.Sec'),[Trunc(DTime) mod 60]);
end;

function TMediaInfo.SplitTime;
var
  DTime:Double;
begin
  DTime:=Time/10000000;
  Result:=Format('%d:%.2d:%.2d.%.3d',
     [Trunc(DTime) div 3600,
     (Trunc(DTime) div 60) mod 60,
      Trunc(DTime) mod 60,
      Trunc(DTime*1000) mod 1000]);
end;

function TMediaInfo.StrToDWORD;
begin
  Move(Str[1],Result,4);
end;

function TMediaInfo.UseFastInfo: Boolean;
var
  MediaDur: Int64;
  MediaSeeking: IMediaSeeking;
  StrSel: IAMStreamSelect;
  Builder: IGraphBuilder;
  Source, FRdr: IBaseFilter;
  FileSource: IFileSourceFilter;
  Fetched, MTFetched: Longint;
  Pins: IEnumPins;
  Pin, InPin: IPin;
  EMT: IEnumMediaTypes;
  MT: PAMMEDIATYPE;
  FLib: TFilterLibrary;
  FInf: TFilterInf;
  HR: HRESULT;
  Accepted: Boolean;
  FirstAudio: Boolean;
  FirstSubs: Boolean;
  SwitcherFound: Boolean;
  AIndex,SIndex: LongInt;
  TotalStreamsCount: Cardinal;
  Idx: Cardinal;
  PossibleCodec: Word;
  CW: Word;

  Flags, LCID, Group: Cardinal;
  Name: PWideChar;
  Obj1, Obj2: IUnknown;

  SI: ^SUBTITLEINFO;
begin
  CW:=Get8087CW;
  Set8087CW($133f);
  Log('+TMediaInfo.UseFastInfo('+FFileName+')');
  Result:=False;
  AIndex:=0; SIndex:=0;
  PossibleCodec:=$0000;
  hR:=0;

  if (FInfo.FileFormat='Unknown') then begin
    Log('-TMediaInfo.UseFastInfo:Faltered');
    Exit;
  end;

  CoCreateInstance(CLSID_FilterGraph,NIL,CLSCTX_INPROC,IID_IGraphBuilder,Builder);
  if Builder = NIL then begin
    Log('-TMediaInfo.UseFastInfo:Faltered');
    Exit;
  end;

  // Строим source-цепь по формату.
  FLib:=TFilterLibrary.Create(Core.ExePath);
  Source:=FLib.CreateFilter('format='+FInfo.FileFormat,FInf);
  if (Source<>NIL) then begin
    Builder.AddFilter(Source as IBaseFilter, 'src');
    Source.QueryInterface(IID_IFileSourceFilter,FileSource);
    if FileSource<>NIL then
      hR:=FileSource.Load(PWideChar(WideString(FileName)),NIL);
    if not SUCCEEDED(hR) or (FileSource=NIL) then begin
      FRdr:=DSH.CreateFilter(CLSID_AsyncReader);
      Builder.AddFilter(FRdr,'rdr');
      (FRdr as IFileSourceFilter).Load(PWideChar(WideString(FileName)),NIL);
      Pin:=DSH.GetPin(FRdr,PINDIR_OUTPUT);
      InPin:=DSH.GetPin(Source,PINDIR_INPUT);
      hR:=Builder.ConnectDirect(Pin,InPin,NIL);
      if not SUCCEEDED(hR) then Builder.RemoveFilter(FRdr);
    end;
    Result:=SUCCEEDED(hR);
  end;

  // Получаем общую длительность.
  Builder.QueryInterface(IID_IMediaSeeking,MediaSeeking);
  if Assigned(MediaSeeking) then
  begin
    MediaDur:=0;
    MediaSeeking.GetDuration(MediaDur);
  end;

  // Ищем StreamSwitcher в сплиттере.
  if Result then begin
    if Source.QueryInterface(IID_IAMStreamSelect, StrSel) = S_OK then begin
      SwitcherFound:=True;
      StrSel.Count(TotalStreamsCount);
    end;
  end
  else
    SwitcherFound:=False;

  // Берем информацию с выходных пинов сплиттера.
  try
    if Result then begin
      if SUCCEEDED(Source.EnumPins(Pins)) then begin
        Pins.Reset;
        while (Pins.Next(1,Pin,@Fetched)=S_OK) do begin
          Pin.EnumMediaTypes(EMT);
          EMT.Reset;
          Accepted:=False;
          while (EMT.Next(1,MT,@MTFetched)=S_OK) do begin
            // Обрабатываем видеострим.
            if IsEqualGUID(MT.MajorType,MEDIATYPE_VIDEO) then begin
              SetLength(FInfo.VStreams,1);
              with FInfo.VStreams[0] do begin
                Duration:=MediaDur;
                if IsEqualGUID(MT.FormatType,FORMAT_VideoInfo)
                  or IsEqualGUID(MT.FormatType,FORMAT_MPEGVideo)
                then begin
                  Width:=TVIDEOINFOHEADER(MT.pbFormat^).bmiHeader.biWidth;
                  Height:=TVIDEOINFOHEADER(MT.pbFormat^).bmiHeader.biHeight;
                  Codec:=MT.SubType.D1;
                  BitRate:=TVideoInfoHeader(MT.pbFormat^).dwBitRate div 1000;
                  FrameRate:=TVideoInfoHeader(MT.pbFormat^).AvgTimePerFrame / 16000;
                end else
                if IsEqualGUID(MT.FormatType,FORMAT_VideoInfo2)
                  or IsEqualGUID(MT.FormatType,FORMAT_MPEG2_VIDEO)
                then begin
                  Width:=TVIDEOINFOHEADER2(MT.pbFormat^).bmiHeader.biWidth;
                  Height:=TVIDEOINFOHEADER2(MT.pbFormat^).bmiHeader.biHeight;
                  Codec:=MT.SubType.D1;
                  BitRate:=TVideoInfoHeader2(MT.pbFormat^).dwBitRate div 1000;
                  FrameRate:=TVideoInfoHeader2(MT.pbFormat^).AvgTimePerFrame / 16000;
                end;
                if IsEqualGUID(MT.SubType,MEDIASUBTYPE_MPEG1Payload) then
                  Codec:=$3147504d;
                if IsEqualGUID(MT.SubType,MEDIASUBTYPE_MPEG2_VIDEO) then
                  Codec:=$3247504d;
                if IsEqualGUID(MT.SubType,KSDATAFORMAT_SUBTYPE_MPEG2_VIDEO) then
                  Codec:=$3247504d;
              end;
            end;

            // Обрабатываем аудиострим.
            if IsEqualGUID(MT.MajorType,MEDIATYPE_Audio)
              or IsEqualGUID(MT.MajorType,MEDIATYPE_AnalogAudio)
              or IsEqualGUID(MT.MajorType,KSDATAFORMAT_TYPE_AUDIO)
            then begin
              if not Accepted then begin
                AIndex:=Length(FInfo.AStreams);
                SetLength(FInfo.AStreams,AIndex+1);
                Accepted:=True;
              end;

              with FInfo.AStreams[AIndex] do begin
                Duration:=MediaDur;
                if IsEqualGUID(MT.FormatType,FORMAT_WaveFormatEx)
                  or IsEqualGUID(MT.FormatType,MEDIASUBTYPE_MPEG2_AUDIO)
                then with TWAVEFORMATEX(MT.pbFormat^) do begin
                    if (Codec=$0) or (AFourCCDesc(wFormatTag)<>'Unknown') then
                      Codec:=wFormatTag;
                    Channels:=nChannels;
                    Frequency:=nSamplesPerSec;
                    if ((nAvgBytesPerSec*8) <= 0) then
                      BitRate:=nAvgBytesPerSec*8
                    else
                      BitRate:=((nAvgBytesPerSec*8) div 1000);
                  end;
                if IsEqualGUID(MT.SubType,MEDIASUBTYPE_DOLBY_AC3) then
                  Codec:=$2000;
                if IsEqualGUID(MT.SubType,MEDIASUBTYPE_Vorbis) then
                  Codec:=$674F;
                if IsEqualGUID(MT.SubType,MEDIASUBTYPE_Vorbis2) then
                  Codec:=$6750;
              end;
            end;

            // Обрабатываем субтитры.
            if IsEqualGUID(MT.MajorType,MEDIATYPE_Subtitle) then begin
              if not Accepted then begin
                SIndex:=Length(FInfo.SStreams);
                SetLength(FInfo.SStreams,SIndex+1);
                Accepted:=True;
              end;

              with FInfo.SStreams[SIndex] do begin
                Format:='';
                Lang:='';
                if IsEqualGUID(MT.SubType,GUID_NULL) then
                  Format:='S_TEXT/ASCII'
                else if IsEqualGUID(MT.SubType,MEDIASUBTYPE_UTF8) then begin
                  Format:='S_TEXT/UTF8';
                  SI:=MT.pbFormat;
                  Lang:=SI.Lang[0]+SI.Lang[1]+SI.Lang[2];
                end
                else if IsEqualGUID(MT.SubType,MEDIASUBTYPE_SSA) then
                  Format:='S_TEXT/SSA'
                else if IsEqualGUID(MT.SubType,MEDIASUBTYPE_ASS) then
                  Format:='S_TEXT/ASS'
                else if IsEqualGUID(MT.SubType,MEDIASUBTYPE_USF) then
                  Format:='S_TEXT/USF'
                else if IsEqualGUID(MT.SubType,MEDIASUBTYPE_VOBSUB) then
                  Format:='S_VOBSUB'
                else SetLength(FInfo.SStreams,SIndex);
              end;
            end;
            DSH.FreeMediaType(MT^);
          end;
          EMT:=NIL;
          Pin:=NIL;
        end;

        // По StreamSwitcher'у..
        if SwitcherFound then begin
          if Length(FInfo.AStreams) > 0 then
            PossibleCodec:=FInfo.AStreams[0].Codec;
          SetLength(FInfo.AStreams,0);
          FirstAudio:=True;

          SetLength(FInfo.SStreams,0);
          FirstSubs:=True;

          Idx:=0;
          while Idx < TotalStreamsCount do begin
            StrSel.Enable(Idx, AMSTREAMSELECTENABLE_ENABLE);
            if StrSel.Info(Idx, MT, Flags, LCID, Group, Name, Obj1, Obj2) = S_OK then begin
              // Аудио.
              if IsEqualGUID(MT^.majortype, MEDIATYPE_Audio) or
                IsEqualGUID(MT^.majortype, MEDIATYPE_AnalogAudio)or
                IsEqualGUID(MT^.majortype, KSDATAFORMAT_TYPE_AUDIO)
              then begin
                if FirstAudio then begin
                  FirstAudio:=False;
                  Continue
                end
                else begin
                  AIndex:=Length(FInfo.AStreams);
                  SetLength(FInfo.AStreams,AIndex+1);
                end;

                with FInfo.AStreams[AIndex] do begin
                  Duration:=MediaDur;
                  if IsEqualGUID(MT.FormatType,FORMAT_WaveFormatEx)
                    or IsEqualGUID(MT.FormatType,MEDIASUBTYPE_MPEG2_AUDIO)
                  then with TWAVEFORMATEX(MT.pbFormat^) do begin
                      if (Codec=$0) or (AFourCCDesc(wFormatTag)<>'Unknown') then
                        Codec:=wFormatTag;
                      if (AFourCCDesc(Codec)='Unknown') then
                        Codec:=PossibleCodec;
                      Channels:=nChannels;
                      Frequency:=nSamplesPerSec;
                      if ((nAvgBytesPerSec*8) <= 0) then
                        BitRate:=nAvgBytesPerSec*8
                      else
                        BitRate:=((nAvgBytesPerSec*8) div 1000);
                  end;
                  if IsEqualGUID(MT.SubType,MEDIASUBTYPE_DOLBY_AC3) then
                    Codec:=$2000;
                  if IsEqualGUID(MT.SubType,MEDIASUBTYPE_Vorbis) then
                    Codec:=$674F;
                  if IsEqualGUID(MT.SubType,MEDIASUBTYPE_Vorbis2) then
                    Codec:=$6750;
                end;
              end;

              // Сабы.
              if IsEqualGUID(MT.MajorType,MEDIATYPE_Subtitle) then begin
                if FirstSubs then begin
                  FirstSubs:=False;
                  Continue
                end
                else begin
                  SIndex:=Length(FInfo.SStreams);
                  SetLength(FInfo.SStreams,SIndex+1);
                end;

                with FInfo.SStreams[SIndex] do begin
                  Format:='';
                  Lang:='';
                  if IsEqualGUID(MT.SubType,GUID_NULL) then
                    Format:='S_TEXT/ASCII'
                  else if IsEqualGUID(MT.SubType,MEDIASUBTYPE_UTF8) then begin
                    Format:='S_TEXT/UTF8';
                    SI:=MT.pbFormat;
                    Lang:=SI.Lang[0]+SI.Lang[1]+SI.Lang[2];
                  end
                  else if IsEqualGUID(MT.SubType,MEDIASUBTYPE_SSA) then
                    Format:='S_TEXT/SSA'
                  else if IsEqualGUID(MT.SubType,MEDIASUBTYPE_ASS) then
                    Format:='S_TEXT/ASS'
                  else if IsEqualGUID(MT.SubType,MEDIASUBTYPE_USF) then
                    Format:='S_TEXT/USF'
                  else if IsEqualGUID(MT.SubType,MEDIASUBTYPE_VOBSUB) then
                    Format:='S_VOBSUB'
                  else SetLength(FInfo.SStreams,SIndex);
                end;
              end;
            end;
            DSH.FreeMediaType(MT^);
            Inc(Idx);
          end;
          StrSel := nil;
        end;
        Pins:=NIL;
      end;
    end;
  except
  end;

  if Result then begin
    if FRdr<>NIL then begin
      InPin:=NIL;
      Builder.RemoveFilter(FRdr);
    end;
    Builder.RemoveFilter(Source);
    AddComment('','Used FastInfo');
    Log('FastInfo:SUCCEEDED');
  end
  else
    Log('FastInfo:FAILED');

  MediaSeeking:=NIL;
  FileSource:=NIL;
  Pin:=NIL;
  Source:=NIL;
  Builder:=NIL;
  Log('-TMediaInfo.UseFastInfo');
  Set8087CW(CW);  
end;

function TMediaInfo.UseMediaDet;
var
  MediaDet:IMediaDet;
  Streams,l:longint;
  guid:TGUID;
  Len:Double;
  AM:TAMMEDIATYPE;
  Index:longint;
begin
  Log('+TMediaInfo.UseMediaDet('+FFileName+')');
  Result:=FALSE;

  if FAILED(CoCreateInstance(CLSID_MediaDet,NIL,CLSCTX_INPROC,IID_IMediaDet,MediaDet)) then begin
    Log('-TMediaInfo.UseMediaDet:Faltered');
    Exit;
  end;

  Result:=TRUE;
  AddComment('','Used MediaDet');

  if SUCCEEDED(MediaDet.put_FileName(FFileName)) then begin
    if SUCCEEDED(MediaDet.get_OutputStreams(Streams)) then begin
      for l:=0 to (Streams-1) do begin
        if SUCCEEDED(MediaDet.put_CurrentStream(l)) then begin
          if FAILED(MediaDet.get_StreamLength(Len)) then
            Len:=0;
          if SUCCEEDED(MediaDet.get_StreamType(guid)) then begin
            if SUCCEEDED(MediaDet.get_StreamMediaType(AM)) then begin
              if IsEqualGUID(guid,KSDATAFORMAT_TYPE_VIDEO) then begin
                Index:=Length(FInfo.VStreams);
                SetLength(FInfo.VStreams,Index+1);
                with FInfo.VStreams[Index] do begin
                  if Len<>0 then Duration:=Round(Len*10000000);
                  if IsEqualGUID(AM.FormatType,FORMAT_VideoInfo) then begin
                    Width:=TVIDEOINFOHEADER(AM.pbFormat^).bmiHeader.biWidth;
                    Height:=TVIDEOINFOHEADER(AM.pbFormat^).bmiHeader.biHeight;
                    Codec:=AM.SubType.D1;
                  end;
                  if SUCCEEDED(MediaDet.get_FrameRate(Len)) then
                    FrameRate:=Len;
                end;
              end else
              if IsEqualGUID(guid,KSDATAFORMAT_TYPE_AUDIO) then begin
                Index:=Length(FInfo.AStreams);
                SetLength(FInfo.AStreams,Index+1);
                with FInfo.AStreams[Index] do begin
                  if Len<>0 then Duration:=Round(Len*10000000);
                  if IsEqualGUID(AM.FormatType,FORMAT_WaveFormatEx) then
                    with TWAVEFORMATEX(AM.pbFormat^) do
                    begin
                      Codec:=wFormatTag;
                      Channels:=nChannels;
                      Frequency:=nSamplesPerSec;
                      if ((nAvgBytesPerSec*8) <= 0) then
                        BitRate:=nAvgBytesPerSec*8
                      else
                        BitRate:=((nAvgBytesPerSec*8) div 1000);
                    end;
                end;
              end else begin
                Index:=Length(FInfo.UStreams);
                SetLength(FInfo.UStreams,Index+1);
                with FInfo.UStreams[Index] do begin
                  Duration:=Round(Len*10000000);
                  StreamType:=GUIDToString(guid);
                end;
              end;
              FreeMediaType(@AM);
            end;
          end;
        end;
      end;
    end;
  end;
  MediaDet:=NIL;
  Log('-TMediaInfo.UseMediaDet');
end;

constructor TMediaInfo.Create(CFile:TCachedFile);
begin
  Log('+TMediaInfo.Create(CFile:TCachedFile)');
  inherited Create;
  FMap:=TCachedFile(CFile);
  FFileName:=FMap.FileName;
  FAPICStart:=0;
  FAPICSize:=0;
  Log('-TMediaInfo.Create');
end;

constructor TMediaInfo.Create(StreamName:String);
begin
  Log('+TMediaInfo.Create(StreamName:String)');
  inherited Create;
  FFileName:=StreamName;
  FStrm:=TMappedStream.Create;
  if FileExists(StreamName) then
    FStrm.LoadFromFile(StreamName)
  else
  if Pos(':/',StreamName)<>0 then
    inetDL(StreamName,TStream(FStrm),4096);
  Log('-TMediaInfo.Create');
end;

destructor TMediaInfo.Destroy;
begin
  Log('+TMediaInfo.Destroy');
  FMap:=NIL;
  inherited Destroy;
  Log('-TMediaInfo.Destroy');
end;

function TMediaInfo.CodecInfo;
var
  S:String;
  l:LongInt;
begin
  Result:=FInfo.Artist+' - '+FInfo.Title+#13#10;
  Result:=Result+FInfo.FileFormat+': (';

  S:='';
  if (Length(FInfo.VStreams)>0) then
    S:=FourCC(FInfo.VStreams[0].Codec);

  for l:=0 to Length(FInfo.AStreams)-1 do begin
    if (S<>'') then S:=S+' + ';
    S:=S+Format('%.4x',[FInfo.AStreams[l].Codec]);
  end;

  Result:=Result+S+')';
end;

procedure TMediaInfo.Reset;
begin
  FInfo.FileName:='';
  FInfo.FileFormat:='N/A';
  FInfo.FileSize:=0;
  FInfo.Duration:=0;
  FInfo.Artist:='';
  FInfo.Title:='';
  FInfo.Album:='';
  FInfo.Year:='';
  FInfo.Genre:='';
  FInfo.Encoder:='';
  SetLength(FInfo.VStreams,0);
  SetLength(FInfo.AStreams,0);
  SetLength(FInfo.UStreams,0);
  SetLength(FInfo.Comments,0);
end;

// Теги для OSD.
function TMediaInfo.FormatInfo;
 function BytesToStr(const i64Size: Int64): string;
 const
   i64GB = 1024 * 1024 * 1024;
   i64MB = 1024 * 1024;
   i64KB = 1024;
 begin
   if i64Size div i64GB > 0 then
     Result := Format('%.2f GB', [i64Size / i64GB])
   else if i64Size div i64MB > 0 then
     Result := Format('%.2f MB', [i64Size / i64MB])
   else if i64Size div i64KB > 0 then
     Result := Format('%.2f KB', [i64Size / i64KB])
   else
     Result := IntToStr(i64Size) + ' Byte(s)';
 end;
var
  V:String;
begin
  Result:=FmtStr;

  V:='';
  if (Length(FInfo.VStreams)>0) then
    V:=AspectRatio(FInfo.VStreams[0].Width,FInfo.VStreams[0].Height); // 4:3
  Result:=StringReplace(Result,'{VideoAspectRatio}',V,[rfReplaceAll,rfIgnoreCase]);

  V:='';
  if (Length(FInfo.VStreams)>0) then
    V:=VFourCCDesc(FourCC(FInfo.VStreams[0].Codec));
  Result:=StringReplace(Result,'{VideoCodecDesc}',V,[rfReplaceAll,rfIgnoreCase]);

  V:='';
  if (Length(FInfo.VStreams)>0) then
    V:=FourCC(FInfo.VStreams[0].Codec); // DIVX, MP43
  Result:=StringReplace(Result,'{VideoCodec}',V,[rfReplaceAll,rfIgnoreCase]);

  V:=SplitTimeText(FInfo.Duration); // 3 мин 23 сек
  Result:=StringReplace(Result,'{VideoDurationText}',V,[rfReplaceAll,rfIgnoreCase]);

  V:=SplitTime(FInfo.Duration); // 3:23.032
  Result:=StringReplace(Result,'{VideoDuration}',V,[rfReplaceAll,rfIgnoreCase]);

  V:='';
  if (Length(FInfo.AStreams)>0) then
  begin
    with FInfo.AStreams[0] do
    begin
      V:=Format('%d '+MS('Info.Hz')+', ',[Frequency]);

      // FLAC & Wav family.
      if (Codec = $F1AC) or ((Codec = $0001) or (Codec = $0002) or (Codec = $0006)
        or (Codec = $0007) or (Codec = $0017) or ((Codec = $0055) and (FInfo.FileFormat = 'WAV'))) then
      begin
        case Channels of
          0 : V := V + 'Unknown ';
          1 : V := V + 'Mono ';
          2 : V := V + 'Stereo ';
        else
          V := V + 'Multichannel (' + IntToStr(Channels) + ')';
        end;
      end
      // MPC.
      else if (Codec = $EACC) then
      begin
        case Channels of
          0: V := V + 'Unknown ';
          1: V := V + 'Stereo ';
          2: V := V + 'Joint Stereo ';
        end;
      end
      // У OGG и WMA иной распорядок каналов.
      else if (Codec = $0000) or ((Codec = $0160) or (Codec = $0161)) then
      begin
        case Channels of
          0: V := V + 'Unknown ';
          1: V := V + 'Mono ';
          2: V := V + 'Stereo ';
        end;
      end
      // AAC.
      else if (Codec = $00FF) then
      begin
        case Channels of
          0: V := V + 'Unknown ';
          1: V := V + 'Mono ';
          2: V := V + 'Stereo ';
        else
          V := V + IntToStr(Channels)+' '+MS('Info.Channels')+', ';
        end;
      end
      // AC3.
      else if (Codec = $2000) then
      begin
        case Channels of
          1 : V := V + 'Mono ';
          2 : V := V + 'Stereo ';
          3 : V := V + '2.1 ';
          4 : V := V + 'Quad ';
          5 : V := V + 'Surround ';
        else
          V := V + IntToStr(Channels)+' '+MS('Info.Channels')+', ';
        end;
      end
      else
      begin
        case Channels of
          0: V := V + 'Stereo, ';
          1: V := V + 'Joint Stereo, ';
          2: V := V + 'Dual Channel, ';
          3: V := V + 'Mono, ';
          4: V := V + 'Unknown, ';
        else
          V := V + IntToStr(Channels)+' '+MS('Info.Channels')+', ';
        end;
      end;
    end;
  end;  // 44100/Stereo
  Result:=StringReplace(Result,'{AudioFormat}',V,[rfReplaceAll,rfIgnoreCase]);

  V := '';
  if (Length(FInfo.VStreams) > 0) then
    V:=Format('%1.2f '+MS('Info.Hz'),[FInfo.VStreams[0].FrameRate]); // 25,000 Hz
  Result:=StringReplace(Result,'{VideoFPS}',V,[rfReplaceAll,rfIgnoreCase]);

  V := '';
  if (Length(FInfo.VStreams) > 0) then begin
    SetVideoBitrate;
    V:=IntToStr(FInfo.VStreams[0].BitRate)+' '+MS('Info.KBitPerSec');
  end;
  Result:=StringReplace(Result,'{VideoBitrate}',V,[rfReplaceAll,rfIgnoreCase]);


  V := '';
  if (Length(FInfo.AStreams) > 0) then
    V := SplitTimeText(FInfo.AStreams[0].Duration); // 3 мин 30 сек.
  Result:=StringReplace(Result,'{AudioDurationText}',V,[rfReplaceAll,rfIgnoreCase]);

  V := '';
  if (Length(FInfo.AStreams) > 0) then
    V := SplitTime(FInfo.AStreams[0].Duration); // 0:03:30.199
  Result := StringReplace(Result, '{AudioDuration}', V, [rfReplaceAll, rfIgnoreCase]);

  V := '';
  V := IntToStr(Length(FInfo.AStreams));
  Result := StringReplace(Result, '{AudioStreamsCount}', V, [rfReplaceAll, rfIgnoreCase]);


  // VideoWidth.
  V := '';
  if (Length(FInfo.VStreams)>0) then
    V := IntToStr(FInfo.VStreams[0].Width); // 640x480
  Result := StringReplace(Result,'{VIDEOWIDTH}',V,[rfReplaceAll,rfIgnoreCase]);

  // VideoHeight.
  V := '';
  if (Length(FInfo.VStreams)>0) then
    V := IntToStr(FInfo.VStreams[0].Height); // 640x480
  Result := StringReplace(Result,'{VIDEOHEIGHT}',V,[rfReplaceAll,rfIgnoreCase]);

  // MPEG-3, VoxWare
  V:='';
  if (Length(FInfo.AStreams)>0) then
    V:=IntToStr(FInfo.AStreams[0].Codec);
  Result:=StringReplace(Result,'{AUDIOCODEC}',V,[rfReplaceAll,rfIgnoreCase]);

  V:='';
  if (Length(FInfo.AStreams)>0) then
    V:=AUDCodec(FInfo.AStreams[0].Codec);
  Result:=StringReplace(Result,'{AUDIOCODECDESC}',V,[rfReplaceAll,rfIgnoreCase]);

  // 100Kbit/sec, VBR
  V:='N/A';
  if (Length(FInfo.AStreams)>0) then
  begin
    // AAC
    if (FInfo.AStreams[0].Codec = $00FF) then
    begin
      if (aacBitRateTypeID = 2) then
        V := V + IntToStr(Round(FInfo.AStreams[0].BitRate / 1000)) +' ' + MS('Info.KBitPerSec') + ' VBR'
      else if (aacBitRateTypeID = 1) then
        V := V + IntToStr(Round(FInfo.AStreams[0].BitRate / 1000)) + ' ' + MS('Info.KBitPerSec') + ' CBR'
      // Unknown
      else
        V := V + IntToStr(FInfo.AStreams[0].BitRate) + ' ' + MS('Info.KBitPerSec');
    end
    else
      V := IntToStr(FInfo.AStreams[0].BitRate)+' '+MS('Info.KBitPerSec');
  end;
  Result:=StringReplace(Result,'{AUDIOBITRATE}',V,[rfReplaceAll,rfIgnoreCase]);


  // Artist.
  V:=FInfo.Artist;
  Result:=StringReplace(Result,'{ARTIST}',V,[rfReplaceAll,rfIgnoreCase]);

  // Title.
  V:=FInfo.Title;
  Result:=StringReplace(Result,'{TITLE}',V,[rfReplaceAll,rfIgnoreCase]);

  // Album.
  V:=FInfo.Album;
  Result:=StringReplace(Result,'{ALBUM}',V,[rfReplaceAll,rfIgnoreCase]);

  // Year.
  V:=FInfo.Year;
  Result:=StringReplace(Result,'{YEAR}',V,[rfReplaceAll,rfIgnoreCase]);

  // Genre.
  V:=FInfo.Genre;
  Result:=StringReplace(Result,'{GENRE}',V,[rfReplaceAll,rfIgnoreCase]);

  // Encoder.
  V:=FInfo.Encoder;
  Result:=StringReplace(Result,'{ENCODER}',V,[rfReplaceAll,rfIgnoreCase]);

  // Format.
  V:=FInfo.FileFormat;
  Result:=StringReplace(Result,'{FORMAT}',V,[rfReplaceAll,rfIgnoreCase]);

  // Codecs.
  V:=CodecSummary;
  Result:=StringReplace(Result,'{CODECS}',V,[rfReplaceAll,rfIgnoreCase]);

  // Duration.
  V:=Core.SysHlp.FormatHNS('{H}:{M}:{S}',FInfo.Duration); // 0:23:23
  Result:=StringReplace(Result,'{DURATION}',V,[rfReplaceAll,rfIgnoreCase]);

  // Size.
  V:=BytesToStr(FInfo.FileSize);//IntToStr(FInfo.FileSize div (1024*1024))+' Mb'; // 25 Mb
  Result:=StringReplace(Result,'{SIZE}',V,[rfReplaceAll,rfIgnoreCase]);

  // Count.
  V:=inttostr(Core.PlayList.Entries.Count);
  Result:=StringReplace(Result,'{COUNT}', V,[rfReplaceAll,rfIgnoreCase]);

  // Current.
  V:=inttostr(Core.PlayList.PlayPos+1);
  Result:=StringReplace(Result,'{CURRENT}',V,[rfReplaceAll,rfIgnoreCase]);
end;

function TMediaInfo.CodecSummary: String;
var
  S:String;
  l:LongInt;
begin
  Result:='';

  S:='';
  if (Length(FInfo.VStreams)>0) then
    S:=FourCC(FInfo.VStreams[0].Codec) + ' (' + VFourCCDesc(FourCC(FInfo.VStreams[0].Codec)) + ')';

  for l:=0 to Length(FInfo.AStreams)-1 do begin
    if (S<>'') then S:=S+' + ';
    S:=S+Format('%.4x',[FInfo.AStreams[l].Codec]) + ' (' + AUDCodec(FInfo.AStreams[l].Codec) + ')';
  end;

  Result:=S;
end;

end.
