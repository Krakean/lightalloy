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
// xx.xx.06  1.0   VtX  Created                                              //
///////////////////////////////////////////////////////////////////////////////

unit PlayList;

interface

uses
  Windows, Classes, Contnrs, SysUtils, NICE, Player, XML,
  CachedStream, TextStream, MultiLog, CachedFile, Forms;

type
  TBookMark = packed record
    Pos: Int64;
    Title: string;
    Selected: Boolean;
  end;

  TPlayEntry = class(TObject)
  public
    FileName: string;
    Title: string;
    BookMarks: array of TBookMark;
    Duration: Int64;
    Selected: Boolean;
    Playing: Boolean;
    FArtist: String;
    FTitle: String;

    procedure SortBookMarks;
    procedure AddTitledBookMark(APos:Int64;ATitle:String);
    procedure AddBookMark(APos:Int64);
    procedure DeleteBookMark(Index:LongInt);
    function GetCurrentBookMark:Byte;
    function GetBookmarkCount:Byte;
  end;

  TPlayEntryList = class(TObjectList)
  private
    function GetEntry(Idx:Integer):TPlayEntry;
    procedure SetEntry(Idx:Integer;AEntry:TPlayEntry);
  public
    constructor Create;

    function Last:TPlayEntry;

    property Items[Idx:Integer]:TPlayEntry read GetEntry write SetEntry; default;
  end;

  TPlayList = class(TObject)
  private
    procedure Changed;

    function StrToPos(Str:string):Int64;
    function PosToStr(Pos:Int64):string;
    function RelativeName(FileName,Path:String):String;

    procedure StartPlayer;
    procedure OnPlayerDone;

    procedure SetPlayPos(const Pos: integer);
    function GetPlayPos: Integer;
    procedure ResetPlaying;
  public
    Updating:LongInt;

    HasBookMarks:Boolean;
    Entries:TPlayEntryList;
    OnChange:TBlindHandler;
    Player:TPlayer;

    constructor Create;
    destructor Destroy; override;

    procedure UpdateBegin;
    procedure UpdateEnd;

    procedure Clear;
    procedure AddEntry(FileName:string);
    procedure AddList(Files:TStrings);
    procedure AddFolder(Path:String);

    procedure AddFromLAP(FileName:string);
    procedure AddFromM3U(FileName:string);
    procedure AddFromPLS(FileName:string);
    procedure AddFromLST(FileName:string);
    procedure AddFromASX(FileName:string);
    procedure AddFromCUE(FileName:string);

    procedure SaveToLAP(const FileName: string);
    procedure SaveToM3U(const FileName: string);
    procedure SaveToPLS(const FileName: string);

    procedure Play;
    procedure PlayEntry(EntryIndex,BookMarkIndex:Longint);
    procedure Next;
    procedure Prev;
    function GetPlayingTitle:String;
    function GetEntryIndex(FileName: String):LongInt;

    procedure DeleteEntry(Index:LongInt);
    procedure DeleteBookMark(EIndex,BIndex:LongInt);
    procedure SortByTitle;
    procedure SortByFileName;
    procedure SortByFullPath;
    procedure Shuffle;
    procedure VisualShuffle;
    procedure Reverse;
    procedure SwapEntries(EI1,EI2:LongInt);
    procedure SetCurrentBookmark;
    function GetTotalDuration:Int64;

    procedure StopPlayer;
    function IsMediaFile(FileName:String):Boolean;
    function IsPlayListFile(FileName:String):Boolean;
    function IsRepeat:Boolean;
    function IsRepeatOneFile:Boolean;
    function GetBookMarkTitle(BmkPos: Byte):string;

    procedure UpdateDuration(FileName:String;NewDur:Int64);
    property PlayPos: Integer read GetPlayPos write SetPlayPos default -1;
  end;

  procedure AddFile(FileName:string; var PL: TPlayList);
implementation

uses
  LACore, CmdC, OtherGlobalVars, Shuffle, MainUnit, PlayGrid,
  uMediaInfo, MediaCache, SysHlp, HttpDownload;

var
  laShuffle: sfShuffle;

const
  COMPARE_1_LT_2 = -1;
  COMPARE_1_EQ_2 = 0;
  COMPARE_1_GT_2 = 1;

function GetRandomPlayPos(EntriesCount: Integer; NextOrPrev: Boolean = True; ClearHistory: Boolean = False): Integer;
var
  Index: Integer;
begin
  Result := 0;
  Index := 0;
  if (isShuffleActivated) and (EntriesCount > 1) then
  begin
    while True do
    begin
      if (ClearHistory) then
        laShuffle.Change(EntriesCount);
      if Assigned(laShuffle) then
        if NextOrPrev then
          Index := laShuffle.Next(EntriesCount)
        else
          Index := laShuffle.Prev(EntriesCount);
      if (Index < 0) and (Index > -128) then
        Break
      else
        Result := Index;
      Break;
    end;
  end;
end;

function GetMemberDur(FileName: String): Int64;
var
  CFile: TCachedFile;
  MediaInfo: TMediaInfo;
begin
  Result := -1;
  try
    CFile := TCachedFile.Create(FileName);
    MediaInfo := TMediaInfo.Create(CFile);
    MediaInfo.RetreiveInfo;

    Result := MediaInfo.FInfo.Duration;
  finally
    FreeAndNil(MediaInfo);
    FreeAndNil(CFile);
  end;
end;

function GetMemberTitle(FileName: String): String;
var
  CFile: TCachedFile;
  MediaInfo: TMediaInfo;
begin
  Result := '';
  try
    CFile := TCachedFile.Create(FileName);
    MediaInfo := TMediaInfo.Create(CFile);
    MediaInfo.RetreiveInfo;

    Result := MediaInfo.FInfo.Title;
  finally
    FreeAndNil(MediaInfo);
    FreeAndNil(CFile);
  end;
end;

function GetMemberArtist(FileName: String): String;
var
  CFile: TCachedFile;
  MediaInfo: TMediaInfo;
begin
  Result := '';
  try
    CFile := TCachedFile.Create(FileName);
    MediaInfo := TMediaInfo.Create(CFile);
    MediaInfo.RetreiveInfo;

    Result := MediaInfo.FInfo.Artist;
  finally
    FreeAndNil(MediaInfo);
    FreeAndNil(CFile);
  end;
end;

procedure TPlayList.ResetPlaying;
var
  i: Integer;
begin
  for i:= 0 to Entries.Count-1 do
  begin
    TPlayEntry(Entries[i]).Playing:= False;
  end;
end;

procedure TPlayList.SetPlayPos(const Pos: integer);
begin
  if (Pos >= 0) and (Pos < Entries.Count) then
  begin
    ResetPlaying;
    TPlayEntry(Entries[Pos]).Playing:= True;
  end;
end;

function TPlayList.GetPlayPos: Integer;
var
  i: Integer;
begin
  Result:= -1;
  for i:= 0 to Entries.Count-1 do
  begin
    if TPlayEntry(Entries[i]).Playing then
    begin
      Result:= i;
      Exit;
    end;
  end;
end;

procedure TPlayList.AddFromLAP;
var
  S:string;
  E:TPlayEntry;
  FS:TFileStream;
  CS:TCachedStream;
  TS:TTextStream;
begin
  Log('+TPlayList.AddFromLAP');
  UpdateBegin;
  try
    FS:=TFileStream.Create(FileName,fmOpenRead or fmShareDenyNone);
    CS:=TCachedStream.Create(FS,4,16384);
    TS:=TTextStream.Create(CS);
    while not(TS.EOF) do
    begin
      S:=TS.ReadLn;
      S:=Trim(S);
      if (S<>'') then
      begin
        if (Copy(S,1,1)<>'>') then
          AddEntry(S)
        else
        begin
          E:= Entries.Last;
          if Assigned(E) then
          begin
            if (Copy(S,2,1)='N') then
              E.Title:=Copy(S,4,Length(S)-3);
            if (Copy(S,2,1)='B') then
              E.AddTitledBookMark(StrToPos(Copy(S,4,12)),Copy(S,17,Length(S)-16));
          end;
          E:= nil;
        end;
      end;
    end;
    TS.Free;
    CS.Free;
    FS.Free;
  except
  end;
  UpdateEnd;
  Log('-TPlayList.AddFromLAP');
end;

procedure TPlayList.AddList;
var
  l:LongInt;
  Item:String;
begin
  Log('+TPlayList.AddList');
  UpdateBegin;
  for l:=0 to Files.Count-1 do
  begin
    Item:=Core.SysHlp.GetLongFileName(Files.Strings[l]);
    if DirectoryExists(Item) then
    begin
      if (FileExists(Item+'VIDEO_TS\VIDEO_TS.IFO')) then
        AddEntry(Item+'VIDEO_TS\VIDEO_TS.IFO')
      else
        AddFolder(Item)
    end else
    begin
      if UpperCase(ExtractFileExt(Item))='.LAP' then
        AddFromLAP(Item)
      else if UpperCase(ExtractFileExt(Item))='.M3U' then
        AddFromM3U(Item)
      else if UpperCase(ExtractFileExt(Item))='.PLS' then
        AddFromPLS(Item)
      else if UpperCase(ExtractFileExt(Item))='.LST' then
        AddFromLST(Item)
      else if UpperCase(ExtractFileExt(Item))='.ASX' then
        AddFromASX(Item)
      else if UpperCase(ExtractFileExt(Item))='.CUE' then
        AddFromCUE(Item)
      else if (Files.Count=1) then  // если файл один то пробуем и одноименные подгружать если есть и в опциях так
        AddFile(Item, Self)
      else
        AddEntry(Item);
    end;
  end;
  UpdateEnd;
  Log('-TPlayList.AddList');
end;

procedure AddFile(FileName: string; var PL: TPlayList);
var
  SR:TSearchRec;
  Found:LongInt;
  sFileName, TrimmedFileName, Path: String;
  WasAdded: Boolean;

  function IsVideoFile(FileName:String):Boolean;
  var
    Ext,ExtTp:ShortString;
  begin
    Ext:=ExtractFileExt(FileName);
    Delete(Ext,1,1);
    ExtTp:=Core.ExplInt.GetExtType(Ext);
    Result:= (ExtTp='V');
  end;

  function IsAudioFile(FileName:String):Boolean;
  var
    Ext,ExtTp:ShortString;
  begin
    Ext:=ExtractFileExt(FileName);
    Delete(Ext,1,1);
    ExtTp:=Core.ExplInt.GetExtType(Ext);
    Result:= (ExtTp='A');
  end;

  function myTrim(const S: string): string;
  var
    i,j:word;
  begin
    Result := s;
    repeat
      i:=Pos('[',result);
      j:=Pos(']',copy(result,i+1,maxint));
      Delete(Result,i,j+1);
    until (i=0)or(j=0);

    i:= 1;
    while i <= Length(Result) do
    begin
      if (Result[i] = ' ') or
        (Result[i] = '_') or
        (Result[i] = '-')
      then
        delete(Result,i,1);
      inc(i);
    end;
  end;

begin
  if not Core.Prefs.ReadBool('OnOpen.SearchForSimilarFiles')
     or IsAudioFile(FileName)
     or (ExtractFileName(FileName) = 'VIDEO_TS.IFO')
  then begin
    PL.AddEntry(FileName);
    Exit;
  end;

  Path:= ExtractFilePath(FileName);
  Path:=IncludeTrailingPathDelimiter(Path);
  sFileName:= ExtractFileName(FileName);
  TrimmedFileName:= myTrim(sFileName);

  PL.UpdateBegin;
  Found:=FindFirst(Path+'*.*',faAnyFile,SR);
  WasAdded:=False;
  while (Found = 0) do
  begin
    if Path+SR.Name=FileName then begin
      PL.AddEntry(FileName);
      WasAdded:=True;
    end else
    if WasAdded then
      if PL.IsMediaFile(Path+SR.Name) then
        if IsVideoFile(Path+SR.Name) and (Path+SR.Name<>FileName) then
          if Copy(TrimmedFileName, 1, 4) = Copy(myTrim(sr.name), 1, 4)then
            PL.AddEntry(Path+SR.Name);
    Found:=FindNext(SR);
  end;
  FindClose(SR);
  PL.UpdateEnd;
end;

procedure TPlayList.AddEntry;
var
  E:TPlayEntry;
  X:TXMLNode;
  i: integer;
  IsURL: Boolean;
  HasTags : Boolean;
  CFile: TCachedFile;
  MediaInfo: TMediaInfo;

  function AllowedExtTags(FName:String): Boolean;
  var EXT:string;
  begin
    Result:= FALSE;
    EXT:=UpperCase(ExtractFileExt(FName));
    if (ext='.MP1') or
       (ext='.MP2') or
       (ext='.MP3') or
       (ext='.AAC') or
       (ext='.APE') or
       (ext='.FLAC') or
       (ext='.OGG') or
       (ext='.MPC') or
       (ext='.WAV') or
       (ext='.WMA') or
       (ext='.WV')
    then
      Result:=TRUE;
  end;

begin
  Application.ProcessMessages;

  // если файл уже в списке то не добовляем его
  if not Core.Prefs.ReadBool('Playlist.AddDoublet') then
    for i:=0 to Entries.Count-1 do
      if Entries[i].FileName = FileName then exit;

  IsUrl:=(System.Pos(':/',FileName) <> 0);

  E:=TPlayEntry.Create;
  E.Duration := -1;

  // MediaCache не работает с URL путями.
  if not(IsUrl) then begin
    E.FileName := ExpandFileName(FileName);
    X := Core.MediaCache.GetInfo(ExpandFileName(E.FileName));
    if (X<>NIL) then begin
      try
        E.Duration := StrToInt64(X.Attr('dur'));
      except
      end;
    end;
  end else
    E.FileName := FileName;

  if Core.Prefs.ReadBool('PlayList.GetNamesFromFileTags')
    and (AllowedExtTags(E.FileName))
    and not(IsUrl)
  then begin
    HasTags := True;

    File2Hash64K:=Core.MediaCache.GetFile64KHash(E.FileName);
    X2:=Core.MediaSets.GetOrCreateInfo(File2Hash64K);

    if not (X2 = nil) and ((X2.Attr('Artist') <> '') or (X2.Attr('Title') <> '')) then
    begin // Tags from XML
      E.FArtist := X2.Attr('Artist');
      E.FTitle := X2.Attr('Title');
      if (E.FArtist <> '') and (E.FTitle <> '') then
        E.Title := E.FArtist + Separator + E.FTitle
      else if (E.FArtist <> '') then
        E.Title := E.FArtist
      else if (E.FTitle <> '') then
        E.Title := E.FTitle
    end
    else begin // Tags from MediaInfo
      CFile := TCachedFile.Create(E.FileName);
      MediaInfo := TMediaInfo.Create(CFile);
      MediaInfo.RetreiveInfo;
      if (MediaInfo.FInfo.Artist <> '') and (MediaInfo.FInfo.Title <> '') then
        E.Title := MediaInfo.FInfo.Artist + Separator + MediaInfo.FInfo.Title
      else if (MediaInfo.FInfo.Artist <> '') then
        E.Title := MediaInfo.FInfo.Artist
      else if (MediaInfo.FInfo.Title <> '') then
        E.Title := MediaInfo.FInfo.Title
      else begin
        E.Title :=ChangeFileExt(ExtractFileName(E.FileName),'');
        HasTags := False;
      end;
      if (Core.Prefs.ReadBool('PlayList.ShowDuration')) then
      if (E.Duration = -1) then
        E.Duration := MediaInfo.FInfo.Duration;
      if FileExists(E.FileName) then begin
        Core.MediaCache.UpdateMediaCache(MediaInfo.FInfo.Duration,E.FileName);
        if HasTags then
          Core.MediaSets.SaveTags(MediaInfo.FInfo.Artist,MediaInfo.FInfo.Title)
        else
          Core.MediaSets.SaveTags(E.Title,MediaInfo.FInfo.Title);
      end;
      MediaInfo.Free;
      CFile.Free;
    end;
  end
  else
    if not(IsURL) then
      E.Title := ChangeFileExt(ExtractFileName(E.FileName),'')
    else
      E.Title := FileName;

  Entries.Add(E);
  Changed;

  if (Entries.Count = 1) and (PlayPos = INI.Int['Last.PlayListIdx'])  then
    Entries[0].Selected := True;
end;

procedure TPlayList.Changed;
begin
  if (Core.PlayList.Entries.Count = 0) then
    frMain.HoverButtons[hiInfo].Enabled := False
  else
    frMain.HoverButtons[hiInfo].Enabled := True;

  if (Updating>0) then Exit;
  if Assigned(OnChange) then OnChange;
end;

procedure TPlayList.Clear;
begin
  Entries.Clear;
  PlayPos:=-1;
  Core.Prefs.WriteInteger('Last.PlayListIdx',-1);
  frMain.PlayGrid.Clear;
  frMain.PlayGrid.SelIndex:=0;
  Changed;                    
end;

constructor TPlayList.Create;
begin
  inherited Create;
  Entries:=TPlayEntryList.Create;
  PlayPos:=-1;
  Updating:= 0;
  HasBookMarks:=False;
end;

destructor TPlayList.Destroy;
begin
  StopPlayer;
  Entries.Free;
  inherited Destroy;
end;

function TPlayList.PosToStr(Pos: int64): string;
var
  h,m,s,ms:LongInt;
  i:int64;
begin
  i:=pos;
  h:=i div (int64(10000000)*60*60);
  i:=i mod (int64(10000000)*60*60);
  m:=i div (int64(10000000)*60);
  i:=i mod (int64(10000000)*60);
  s:=i div int64(10000000);
  i:=i mod int64(10000000);
  ms:=i div int64(10000);
  Result:=Format('%.2d:%.2d:%.2d.%.3d',[h,m,s,ms]);
end;

procedure TPlayList.SaveToLAP;
var
  ei,bi:LongInt;
  ft:textfile;
  E:TPlayEntry;
  B:TBookMark;
  PlPath,ShFN:String;
begin
  AssignFile(ft,FileName);
{$I-}
  Rewrite(ft);
{$I+}
  if (IOResult<>0) then Exit;

  PlPath:=ExtractFilePath(FileName);

  for ei:=0 to Entries.Count-1 do begin
    E:=Entries[ei];

    ShFN:=RelativeName(E.FileName,PlPath);
    WriteLn(ft,ShFN);
    WriteLn(ft,'>N ' + E.Title);
    for bi:=0 to Length(E.BookMarks)-1 do begin
      B:=E.BookMarks[bi];
      WriteLn (ft,'>B '+PosToStr(B.Pos)+' '+B.Title);
    end;
    WriteLn(ft);
  end;
  CloseFile(ft);
end;

function TPlayList.StrToPos;
var
  h,m,s,ms:LongInt;
begin
  try
    h:=StrToInt(Copy(str,1,2));
    m:=StrToInt(Copy(str,4,2));
    s:=StrToInt(Copy(str,7,2));
    ms:=StrToInt(Copy(str,10,3));
    Result:=Int64(10000)*(((h*60+m)*60+s)*1000+ms);
  except
    Result:=0;
  end;
end;

procedure TPlayList.UpdateBegin;
begin
  Inc(Updating);
end;

procedure TPlayList.UpdateEnd;
begin
  Dec(Updating);
  Changed;
end;

function CompareFullPath(Item1,Item2:Pointer):LongInt;
var
  E1,E2:TPlayEntry;
begin
  E1:=TPlayEntry(Item1);
  E2:=TPlayEntry(Item2);
  Result:=COMPARE_1_EQ_2;
  if (E1.FileName<E2.FileName) then Result:=COMPARE_1_LT_2;
  if (E1.FileName>E2.FileName) then Result:=COMPARE_1_GT_2;
end;

procedure TPlayList.SortByFullPath;
begin
  Entries.Sort(CompareFullPath);
  Changed;
end;

{ TPlayEntryList }

constructor TPlayEntryList.Create;
begin
  inherited Create;
  OwnsObjects:=TRUE;
end;

function TPlayEntryList.GetEntry;
begin
  Result:=TPlayEntry(inherited Items[Idx]);
end;

function TPlayEntryList.Last: TPlayEntry;
begin
  Result:=TPlayEntry(inherited Last);
end;

procedure TPlayEntryList.SetEntry;
begin
  inherited Items[Idx]:=AEntry;
end;

{ TPlayEntry }

procedure TPlayEntry.AddBookMark;
begin
  AddTitledBookMark(APos,'');
end;

procedure TPlayEntry.AddTitledBookMark;
var
  l:LongInt;
begin
  l:=Length(BookMarks);
  SetLength(BookMarks,l+1);
  BookMarks[l].Pos:=APos;
  BookMarks[l].Title:=ATitle;
  SortBookMarks;
end;

procedure TPlayList.Play;
begin
  if (Entries.Count>0) then
  begin
    if (PlayPos<0) then
      PlayPos:=0;
    StartPlayer;
    frMain.PlayGrid.Scrolling;
    HasBookMarks:=(Entries[PlayPos].GetBookmarkCount>0);
    Changed;

    if Core.DSH.HasVideo then
     begin
        if Core.Prefs.ReadBool('Video.AspectRatioForced') then

        case Core.Prefs.ReadInteger('Video.AspectRatio') of
          0:Core.Cmd(LAC_VIDEO_RATIO_ASIS);
          1:Core.Cmd(LAC_VIDEO_RATIO_16_9);
          2:Core.Cmd(LAC_VIDEO_RATIO_4_3);
          3:Core.Cmd(LAC_VIDEO_RATIO_WIDTH);
          4:Core.Cmd(LAC_VIDEO_RATIO_HEIGHT);
          5:Core.Cmd(LAC_VIDEO_RATIO_CUSTOM);
          6:Core.Cmd(LAC_VIDEO_RATIO_FREE);
        end;
     end;
  end;
end;

procedure TPlayList.StartPlayer;
begin
  if IsDownloading then Exit;
  if frMain.Handle = GetActiveWindow then
    frMain.bActive:= True
  else
    frMain.bActive:= False;

  StopPlayer;

  Player:=TPlayer.Create;
  Player.OnComplete:=OnPlayerDone;
  Player.PlayFile(Entries[PlayPos].FileName);

  Entries[PlayPos].Duration:=Core.DSH.Duration;

  with frMain do begin
    HoverButtons[hiPlay].Down:=TRUE;
    HoverButtons[hiStop].Down:=FALSE;
    HoverButtons[hiSpeedPlay].Down:=FALSE;
    State:=stPlay;
    Core.MdlMgr.SetSInt32('App.SuperPlay',1);
  end;
end;

procedure TPlayList.StopPlayer;
begin
  if (Player=NIL) then Exit;
  FreeAndNIL(Player);
  HasBookMarks:=False;
end;

procedure TPlayList.OnPlayerDone;
  function OnPlayerDoneExecute: boolean;
  begin
    Result := false;
    case Core.Prefs.ReadInteger('Playlist.OnPlayListEnd') of
      1: Center.ProcessCommand(LAC_APPLICATION_EXIT);
      2: Center.ProcessCommand(LAC_APPLICATION_POWER_OFF);
    end;
    if SHibernateOnPlayListDone then
      Center.ProcessCommand(LAC_APPLICATION_HIBERNATE);
    if SPlowerOffOnPlayListDone then
      Center.ProcessCommand(LAC_APPLICATION_POWER_OFF);
  end;
begin
  Center.ProcessCommand(LAC_PLAYBACK_STOP);
  if (isShuffleActivated) then
    if (laShuffle.ECurrent+1=Entries.Count) then
      OnPlayerDoneExecute;

  if (PlayPos>=Entries.Count-1) and not(isShuffleActivated) then
  begin
    if not(IsRepeatOneFile) then
    OnPlayerDoneExecute;
    if IsRepeat or IsRepeatOneFile then Next else Exit;
  end
  else
    Next;
end;

procedure TPlayList.Next;
var
  SPlayPos: LongInt;
begin
  SPlayPos:= PlayPos;
  if (Entries.Count>0) then
  begin
    if (isShuffleActivated) then
      SPlayPos := GetRandomPlayPos(Entries.Count, True)
    else
        SPlayPos:= SPlayPos+1;

    if (SPlayPos>=Entries.Count) and (isShuffleActivated = FALSE) then
    begin
      if (IsRepeat) or (IsRepeatOneFile) then
        SPlayPos:=0
      else
        Exit;
    end
    else
    // Обрабатываем *по окончанию воспроизвденеия* в режиме шафла.
    if (isShuffleActivated) then
      if not(IsRepeat) and (laShuffle.ECurrent=Entries.Count) then
        Exit;
    if IsRepeatOneFile and (NextByHotkey = False) then
      Play
    else
      PlayPos:=SPlayPos;
    Play;
  end;
  NextByHotkey := False;
end;

procedure TPlayList.Prev;
begin
  if (Entries.Count > 0) then
  begin
    if (isShuffleActivated) then
      PlayPos := GetRandomPlayPos(Entries.Count, False)
    else
      PlayPos:= PlayPos-1;

    if (PlayPos<0) then
      if IsRepeat then
        PlayPos:=Entries.Count-1
      else
       begin
        PlayPos:=0;
        Exit;
       end;
     Play;
  end;
  NextByHotkey := False;
end;

function TPlayList.GetPlayingTitle;
begin
  Result:='';
  if (PlayPos>=0) and (PlayPos<Entries.Count) then
    Result:=Entries[PlayPos].Title;
end;

function TPlayList.GetEntryIndex(FileName: String): LongInt;
var
  i: LongInt;
begin
  Result:=-1;
  for i:=0 to Entries.Count-1 do begin
    if System.Pos(FileName,Entries[i].FileName)<>0 then begin
      Result:=i;
      Break;
    end
  end;
end;

procedure TPlayList.PlayEntry;
var
  Entry:TPlayEntry;
begin
  if (EntryIndex<0) then Exit;
  if (EntryIndex>=Entries.Count) then Exit;
  PlayPos:=EntryIndex;
  Entry:=Entries[PlayPos];
  if (BookMarkIndex<0) or (frMain.LoadedFileName<>Entry.FileName) then Play;
  if (BookMarkIndex<0) then Exit;
  if (BookMarkIndex>=Length(Entry.BookMarks)) then Exit;

  Player.SeekTo(Entry.BookMarks[BookMarkIndex].Pos);
end;

procedure TPlayList.AddFolder;
var
  SR:TSearchRec;
  Found:LongInt;
begin
  UpdateBegin;
  Path:=IncludeTrailingPathDelimiter(Path);
  Found:=FindFirst(Path+'*.*',faAnyFile,SR);
  while (Found=0) do begin
    if (SR.Attr and faDirectory)>0 then begin
      if ((SR.Name<>'.') and (SR.Name<>'..')) then
        AddFolder(Path+SR.Name+'\');
    end else begin
      if IsMediaFile(Path+SR.Name) then
        AddEntry(Path+SR.Name)
      else if IsPlayListFile(Path+SR.Name) then begin
        if UpperCase(ExtractFileExt(Path+SR.Name))='.LAP' then
          AddFromLAP(Path+SR.Name)
        else if UpperCase(ExtractFileExt(Path+SR.Name))='.M3U' then
          AddFromM3U(Path+SR.Name)
        else if UpperCase(ExtractFileExt(Path+SR.Name))='.PLS' then
          AddFromPLS(Path+SR.Name)
        else if UpperCase(ExtractFileExt(Path+SR.Name))='.LST' then
          AddFromLST(Path+SR.Name)
        else if UpperCase(ExtractFileExt(Path+SR.Name))='.ASX' then
          AddFromASX(Path+SR.Name)
        else if UpperCase(ExtractFileExt(Path+SR.Name))='.CUE' then
          AddFromCUE(Path+SR.Name)
      end;
    end;
    Found:=FindNext(SR);
  end;
  FindClose(SR);
  UpdateEnd;
end;

function TPlayList.IsMediaFile;
var
  Ext,ExtTp:string;
begin
  Ext:=ExtractFileExt(FileName);
  Delete(Ext,1,1);
  ExtTp:=Core.ExplInt.GetExtType(Ext);
  Result:=(ExtTp='A') or (ExtTp='V');
end;

function TPlayList.IsPlayListFile(FileName: String): Boolean;
var
  Ext,ExtTp:string;
begin
  Ext:=ExtractFileExt(FileName);
  Delete(Ext,1,1);
  ExtTp:=Core.ExplInt.GetExtType(Ext);
  Result:=(ExtTp='P');
end;

procedure TPlayList.AddFromM3U(FileName: string);
var
  FS: TFileStream;
  MS: TMemoryStream;
  LS: TStringList;
  i: integer;
  s: string;
  c: char;
  x: byte;
begin
  Log('+TPlayList.AddFromM3U('+FileName+')');

  MS:=TMemoryStream.Create;
  if (Pos(':/',FileName)<>0) and (Pos('m3u',LowerCase(FileName))<>0) then begin
    if inetDL(FileName,TStream(MS)) then
      MS.Seek(0,soFromBeginning)
    else
      MS.Free;
  end;

  if (MS.Size = 0) then begin
    FS:=TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
    if (FS=NIL) then begin
      Log('-TPlayList.AddFromM3U: file opening error!');
      Exit;
    end
    else
      MS.CopyFrom(FS,FS.Size);
    FS.Free;
  end;

  for i:=1 to 8 do begin
    MS.Read(C,1);
    if c=#10 then X:=2 else X:=1;
  end;

  LS := TStringList.Create;
  MS.Seek(0,soFromBeginning);
  LS.LoadFromStream(MS);

  if LS.Count<4 then X:=1;

  if pos('://',LS.Strings[0])<>0 then begin
    for i := 0 to LS.Count - X do
      AddEntry(LS.Strings[i]);
    Exit;
  end;

  if not(LS.Strings[0] = '#EXTM3U') then Exit;

  // Количество итераций зависит от типа переноса.
  UpdateBegin;
  for i := 1 to LS.Count - X do begin
    S := LS.Strings[i];
    try
      if S[1] <> '#' then begin
        AddEntry(S);
        S := LS.Strings[i-1];
        Delete(S, 1, Pos(',',S));
        Entries.Last.Title:=S;
      end;
    except
      Continue;
    end;
  end;
  UpdateEnd;

  MS.Free;
  LS.Free;
  Log('-TPlayList.AddFromM3U('+FileName+')');
end;

procedure TPlayList.AddFromASX(FileName: string);
var
  FS:TFileStream;
  ASX:TXMLTree;
  l:LongInt;
  Entry:TXMLNode;
  HRef:String;
begin
  FS:=TFileStream.Create(FileName,fmOpenRead or fmShareDenyNone);
  ASX:=TXMLTree.Create;
  ASX.LoadFromStream(FS);
  FreeAndNIL(FS);

  UpdateBegin;
  for l:=0 to Length(ASX.Root.Nodes)-1 do begin
    Entry:=ASX.Root.Nodes[l];
    if (UpperCase(Entry.Tag)='ENTRY') then begin
      Entry:=Entry.Node('REF');
      if Assigned(Entry) then begin
        HRef:=Entry.Attr('HREF');
        if (HRef<>'') then
          AddEntry(HRef);
      end;
    end;
  end;
  UpdateEnd;

  FreeAndNIL(ASX);
end;

procedure TPlayList.AddFromLST(FileName: string);
var
  ft:textfile;
  S:string;
begin
  AssignFile(ft,FileName);
  FileMode:=0;
{$I-}
  Reset(ft);
{$I+}
  FileMode:=2;
  if (IOResult<>0) then Exit;

  UpdateBegin;
  while not(Eof(ft)) do begin
    ReadLn(ft,S);
    S:=Trim(S);
    if (S<>'') then
      AddEntry(S);
  end;
  CloseFile(ft);
  UpdateEnd;
end;

procedure TPlayList.AddFromPLS(FileName: string);
var
  ft:textfile;
  S:string;
  l:LongInt;
begin
  AssignFile(ft,FileName);
  FileMode:=0;
{$I-}
  Reset(ft);
{$I+}
  FileMode:=2;
  if (IOResult<>0) then Exit;

  UpdateBegin;
  while not(Eof(ft)) do begin
    ReadLn(ft,S);
    S:=Trim(S);
    if (S<>'') then begin
      if (UpperCase(Copy(S,1,4))='FILE') then begin
        l:=Pos('=',S);
        S:=Copy(S,l+1,Length(S)-l);
        AddEntry(S);
      end else if (UpperCase(Copy(S,1,5))='TITLE') then begin
        l:=Pos('=',S);
        Entries.Last.Title:=Copy(S,l+1,Length(S)-l);
      end;
    end;
  end;
  CloseFile(ft);
  UpdateEnd;
end;

procedure TPlayList.AddFromCUE(FileName: String);
var
  AddedFileName,Prfmr,Title,Ext,S,TrackName,FilePath: String;
  SL,EL: TStringList;

  Position: Int64;
  l,i,j,z : Integer;
  LPFound : Boolean;
  FileAdded : Boolean;
  Separated : Integer;
begin
  Log('+TPlayList.AddFromCUE('+FileName+')');

  SL:=TStringList.Create;
  SL.LoadFromFile(FileName);
  EL:=TStringList.Create;
  EL:=Core.ExplInt.GetMaskList('A');
  FilePath:=ExtractFilePath(FileName);

  Position:=-1;
  Separated:=0;

  for i:=0 to SL.Count-1 do
    if Pos('FILE "',SL[i])<>0 then
      Inc(Separated);

  UpdateBegin;
  for i:=0 to SL.Count-1 do begin
   if (SL[i]<>'') and not FileAdded then
    if (UpperCase(Copy(S,1,9))='PERFORMER') then begin
      l:=Pos(' "',S);
      Prfmr:=Copy(S,l+2,Length(S)-l-2);
    end;
    if Pos('FILE "',SL[i])<>0 then begin
      FileAdded:=False;
      Trackname:=Copy(SL[i],7,Pos('" ',SL[i])-7);
      Z:=0;
      repeat
        Inc(Z);
        Ext := '.' + EL.Strings[Z-1];
        AddedFileName:=ChangeFileExt(FilePath+TrackName,Ext);
        if FileExists(AddedFileName) then begin
          AddEntry(AddedFileName);
          FileAdded:=True;
        end;
      until FileAdded or (Z = EL.Count);
    end
    else if FileExists(AddedFileName) then begin
      if Separated > 1 then Continue;
      if Pos('TRACK',SL[i])<>0 then begin
        for j:=i to (i+4) do begin
          S:=SL.Strings[j];
          if Pos('TITLE',S)<>0 then
            Title:=Copy(S,12,Length(S)-12);
          if Pos('PERFORMER',S)<>0 then begin
            Title:=Copy(S,16,Length(S)-16)+Separator+Title;
            LPFound:=TRUE;
          end;
          if Pos('INDEX',S)<>0 then
          Position:=StrToPos('00:'+Copy(SL.Strings[j],14,5)+'.000');
          if (Position>-1) and (Title<>'') then Break;
        end;
        if (not LPFound) and (Prfmr<>'') then
          Title:=Prfmr+Separator+Title;
        Entries.Last.AddTitledBookMark(Position,Title);
        Position:=-1;
        Title:='';
      end;
    end;
  end;
  UpdateEnd;

  SL.Free;
  EL.Free;
  Log('-TPlayList.AddFromCUE');
end;

procedure TPlayList.DeleteEntry;
begin
  if (Index<0) then Exit;
  if (Index>=Entries.Count) then Exit;

  Entries.Delete(Index);
  if (PlayPos=Index) then
    PlayPos:=-1;

  Changed;
end;

procedure TPlayList.DeleteBookMark;
begin
  if (EIndex<0) then Exit;
  if (EIndex>=Entries.Count) then Exit;
  Entries[EIndex].DeleteBookMark(BIndex);
  Changed;
end;

procedure TPlayEntry.DeleteBookMark;
var
  l:LongInt;
begin
  if (Index<0) then Exit;
  if (Index>=Length(BookMarks)) then Exit;

  for l:=Index to Length(BookMarks)-2 do
    BookMarks[l]:=BookMarks[l+1];
  SetLength(BookMarks,Length(BookMarks)-1);
end;

procedure TPlayList.SwapEntries;
begin
  if (EI1<0) or (EI1>=Entries.Count) then Exit;
  if (EI2<0) or (EI2>=Entries.Count) then Exit;
  if (EI1=EI2) then Exit;

  Entries.OwnsObjects:=FALSE;
  Entries.Move(EI1, EI2);

  Entries.OwnsObjects:=TRUE;
  Changed;
end;

procedure TPlayList.Shuffle;
begin
  if (isShuffleActivated) then
    laShuffle := sfShuffle.Create(Entries.Count)
  else
    FreeAndNil(laShuffle);
end;

procedure TPlayList.VisualShuffle;
var i: Integer;
begin
  Randomize;
  UpdateBegin;
  for i:=0 to (Entries.Count-1) do
    SwapEntries(i,Random(Entries.Count));
  UpdateEnd;
end;

procedure TPlayList.SetCurrentBookmark;
var
  Pos:Int64;
begin
  if (PlayPos<0) then Exit;
  if (PlayPos>=Entries.Count) then Exit;
  if (Player=NIL) then Exit;

  Pos:=Player.Pos;
  Entries[PlayPos].AddTitledBookMark(Pos,'[ '+Copy(PosToStr(Pos),1,8)+' ]');
  Changed;
end;

procedure TPlayEntry.SortBookMarks;
var
  i,j:LongInt;
  B:TBookMark;
begin
  for i:=0 to Length(BookMarks)-2 do
    for j:=(i+1) to Length(BookMarks)-1 do
      if (BookMarks[i].Pos>BookMarks[j].Pos) then begin
        B:=BookMarks[i];
        BookMarks[i]:=BookMarks[j];
        BookMarks[j]:=B;
      end;
end;

function TPlayList.IsRepeat: Boolean;
begin
  Result:=Core.Prefs.ReadBool('PlayList.Repeat');
end;

function TPlayList.IsRepeatOneFile: Boolean;
begin
  Result:=Core.Prefs.ReadBool('Playlist.RepeatOneFile');
end;  

function CompareTitle(Item1,Item2:Pointer):LongInt;
var
  E1,E2:TPlayEntry;
begin
  E1:=TPlayEntry(Item1);
  E2:=TPlayEntry(Item2);
  Result:=COMPARE_1_EQ_2;
  if (E1.Title<E2.Title) then Result:=COMPARE_1_LT_2;
  if (E1.Title>E2.Title) then Result:=COMPARE_1_GT_2;
end;

procedure TPlayList.SortByTitle;
begin
  Entries.Sort(CompareTitle);
  Changed;
end;

function CompareFileName(Item1,Item2:Pointer):LongInt;
var
  E1,E2:TPlayEntry;
  S1,S2:String;
begin
  E1:=TPlayEntry(Item1);
  E2:=TPlayEntry(Item2);
  Result:=COMPARE_1_EQ_2;
  S1:=ExtractFileName(E1.FileName);
  S2:=ExtractFileName(E2.FileName);
  if (S1<S2) then Result:=COMPARE_1_LT_2;
  if (S1>S2) then Result:=COMPARE_1_GT_2;
end;

procedure TPlayList.SortByFileName;
begin
  Entries.Sort(CompareFileName);
  Changed;
end;

procedure TPlayList.Reverse;
var
  l:LongInt;
begin
  for l:=0 to Entries.Count-1 do
    Entries.Move(Entries.Count-1,l);
  Changed;  
end;

function TPlayList.RelativeName;
var
  l:LongInt;
begin
  Result:=FileName;

  l:=Length(Path);
  if SameText(Copy(FileName,1,l),Path) then begin
    Result:=Copy(FileName,l+1,Length(FileName)-l);
  end;
end;

function TPlayList.GetTotalDuration;
var
  Part:Boolean;
  l:LongInt;
  D:Int64;
begin
  Part:=FALSE;
  Result:=1;

  for l:=0 to (Entries.Count-1) do begin
    D:=Entries[l].Duration;
    if (D<0) then begin
      Part:=TRUE;
    end else begin
      Result:=Result+D;
    end;
  end;

  if Part then Result:=-Result;
end;

procedure TPlayList.UpdateDuration;
var
  X:TXMLNode;
  FN:String;
  l:LongInt;
begin
  FN:=ExpandFileName(FileName);

  X:=Core.MediaCache.GetOrCreateInfo(FN);
  X.SetAttr('dur',IntToStr(NewDur));

  for l:=0 to Entries.Count-1 do
    if SameText(FN,Entries[l].FileName) then
      Entries[l].Duration:=NewDur;

  Changed;
end;

procedure TPlayList.SaveToM3U;
var
  i: Integer;
  S: string;
begin
  with TStringList.Create do
    try
      Add('#EXTM3U');
      for i := 0 to Entries.Count - 1 do
      begin
        Entries[i].Duration := GetMemberDur(Entries[i].FileName);
        S:=IntToStr(StrToInt(Core.SysHlp.FormatHNS('{H}',Entries[i].Duration))*3600+(StrToInt(Core.SysHlp.FormatHNS('{M}',Entries[i].Duration))*60)+(StrToInt(Core.SysHlp.FormatHNS('{S}',Entries[i].Duration))));
        Add('#EXTINF:' + S + ',' + Entries[i].Title);
        Add(Entries[i].FileName);
      end;
      SaveToFile(FileName);
    finally
      Free;
    end;
end;

procedure TPlayList.SaveToPLS;
var
  i: Integer;
  S: string;
begin
  with TStringList.Create do
    try
      Add('[playlist]');
      for i := 0 to Entries.Count-1 do
      begin
        Entries[i].Duration := GetMemberDur(Entries[i].FileName);
        S:=IntToStr(StrToInt(Core.SysHlp.FormatHNS('{H}',Entries[i].Duration))*3600+(StrToInt(Core.SysHlp.FormatHNS('{M}',Entries[i].Duration))*60)+(StrToInt(Core.SysHlp.FormatHNS('{S}',Entries[i].Duration))));
        Add('File' + IntToStr(i) + '=' + Entries[i].FileName);
        Add('Title' + IntToStr(i) + '=' + ChangeFileExt(ExtractFileName(Entries[i].Title),''));
        Add('Length' + IntToStr(i) + '=' + S);
      end;
      Add('NumberOfEntries=' + IntToStr(Entries.Count));
      Add('Version=2');
      SaveToFile(FileName);
    finally
      Free;
    end;
end;

function TPlayList.GetBookMarkTitle(BmkPos: Byte):string;
var
  Member: TPlayEntry;
begin
  Member:= TPlayEntry(Entries[PlayPos]);
  Result := TBookmark(Member.BookMarks[BmkPos]).Title;
end;

function TPlayEntry.GetCurrentBookMark:Byte;
var i, j:Byte;
begin
  Result:=0;
  i:=Length(BookMarks);
  ParamStr(0);
  if i=0 then Exit;
  for j:= 0 to i-1 do begin
    if (Core.Player.Pos > BookMarks[j].Pos) and (Core.Player.Pos < BookMarks[j+1].Pos) then
      Result := j;
  end;
end;

function TPlayEntry.GetBookmarkCount:Byte;
begin
  Result:=Length(BookMarks);
end;

end.

