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
unit PlayGrid;

interface

uses
  Forms, Windows, Classes, SysUtils, StdCtrls, Grids, Graphics, Dialogs,
  Controls, Math, CachedFile, XML, PlayList, Messages, CmdC;

type
  TPlayGrid = class(TDrawGrid)
  private
    FShowBookmarks:Boolean;

    ShowNumbers:Boolean;
    ShowDuration:Boolean;
    FindKey:String;

    bDragging: Boolean;
    bMultiSelect: Boolean;
    bNeedResetSelection: Boolean;
    MinIndex, MaxIndex: Integer;
    PrevCellIndex: Integer;

    procedure ResetSelection;

    procedure SwapMembers(ItemA, ItemB: LongInt);
    function EntryToPos(FilePos, BkMkPos: LongInt): LongInt;
    procedure PosToEntry(index: LongInt; var FilePos: LongInt; var BkMkPos: LongInt);
    procedure SetShowBookmarks(Value:Boolean);

    procedure OnPlayListChanging;
    function IsMouseOver:Boolean;
  protected
    procedure Resize; override;
    procedure DrawCell(ACol,ARow:LongInt;ARect:TRect;AState:TGridDrawState); override;
    procedure OnMouseWheel(var Message:TMessage); message WM_MOUSEWHEEL;
    procedure OnVScroll(var Message:TMessage); message WM_VSCROLL;

    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure WMDblClick(var Msg: TMessage); message WM_LBUTTONDBLCLK;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    SelIndex, BmkSelIndex: LongInt;

    // Background
    PlayListColor,
    // Font Color
    TextColor,
    // Selected text color
    TextSelColor,
    // Selection
    SelBGColor: TColor;

    constructor Create(AOwner:TComponent); override;
    destructor Destroy; override;

    procedure SaveReport(FileName,Template:string);

    procedure Clear;
    procedure Delete;
    procedure PlaySelection;
    procedure MoveUp;
    procedure MoveDown;
    procedure SelectUp;
    procedure SelectDown;
    procedure NewFont;
    procedure NewColors;
    procedure Invalidate; override;

    procedure FindFirst(Key:String);
    procedure FindNext;
    procedure Scrolling(Position: Integer = -1);
    property  ShowBookmarks:Boolean read FShowBookmarks write SetShowBookmarks;
  end;

implementation

uses
  MainUnit, DShowHlp, uMediaInfo, LACore, SysHlp,
  MediaCache, DirectShow9, OtherGlobalVars;

var
  repTemplate:string = '<HTML><HEAD><TITLE>LA report</TITLE>'+#13#10+
    '<STYLE TYPE="text/css">'+#13#10+'<!--'+#13#10+
    'BODY {background-color: white; font-family: Tahoma, Verdana, Arial, Helvetica; color: black}'+#13#10+
    'TD {font-size: 8pt}'+#13#10+'TH {font-size: 9pt}'+#13#10+
    '-->'+#13#10+'</STYLE></HEAD><BODY>'+#13#10+
    '<TABLE cellspacing="1" cellpadding="3" bgcolor="gray" align="center" width="95%">'+#13#10+
    '<TR bgcolor="#CCCCCC">'+
    '<TH>No</TH>'+
    '<TH>File Name</TH>'+
    '<TH>Duration</TH>'+
    '<TH>Artist/Title</TH>'+
    '<TH>Video</TH>'+
    '<TH>Audio</TH>'+
    '<TH>File Size</TH>'+
    '</TR>'+
      '%EntryStart%'+
    '<TR bgcolor="%CellColor%">'+
    '<TD bgcolor="#CCCCCC">%No%</TD>'+
    '<TD>%FileName% (%FileFormat%) MT:(%MediaType%)</TD>'+
    '<TD>%VideoDurationText% (%VideoDuration%)</TD>'+
    '<TD>%Artist% / %Title%</TD>'+
    '<TD>%VideoCodec%, %VideoWidth%x%VideoHeight% (%VideoAspectRatio%) %VideoFPS% VBR:(%VideoBitRate%)</TD>'+
    '<TD>%AudioCodec%, %AudioFormat%, %AudioBitRate% ASC:(%AudioStreamsCount%), AD:(%AudioDuration%), ADT:(%AudioDurationText%)</TD>'+
    '<TD>%Size%</TD>'+
    '</TR>'+#13#10 +
      '%EntryEnd%'+
    '</TABLE></BODY></HTML>';
  memDur    : Int64 = -1;

//******************************************************************************

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

procedure TPlayGrid.KeyDown;
var
  i: Integer;
  Member: TPlayEntry;
  KeyID: LongInt;
  KeyboardCommand : String;
begin
  KeyID := Center.GetCommandID(Center.VirtualKeyName(Key,Shift),'');
  KeyboardCommand := Center.GetCommandKey(KeyID);

  if frMain.pnPlayList.Visible and (frMain.PlayGrid.Focused) then
  begin
    if (Key = VK_NEXT) and (KeyboardCommand<>'PageDown') or
       (Key = VK_PRIOR) and (KeyboardCommand<>'PageUp') then
     inherited KeyDown(Key, Shift);
  end;

  if (Key<>38) and (Key<>40) then Exit;
  for i:= 0 to Core.PlayList.Entries.Count-1 do
  begin
    Member:= TPlayEntry(Core.PlayList.Entries[i]);
    if Member.Selected then
    begin
      Scrolling(i);
      Break;
    end;
  end;
end;

//******************************************************************************
procedure TPlayGrid.SelectUp;
begin
  if (Core.PlayList.Entries.Count > 0) and (SelIndex > 0) and (SelIndex < Core.PlayList.Entries.Count) then
  begin
    ResetSelection;
    Dec(SelIndex);
    TPlayEntry(Core.PlayList.Entries[SelIndex]).Selected:= True;
  end;
end;

//******************************************************************************
procedure TPlayGrid.SelectDown;
begin
  if (Core.PlayList.Entries.Count > 0) and (SelIndex >= 0) and (SelIndex < Core.PlayList.Entries.Count-1) then
  begin
    ResetSelection;
    Inc(SelIndex);
    TPlayEntry(Core.PlayList.Entries[SelIndex]).Selected:= True;
  end;
end;

//******************************************************************************

procedure TPlayGrid.ResetSelection;
var
  i, j: integer;
  Member: TPlayEntry;
begin
  for i:= 0 to Core.PlayList.Entries.Count-1 do
  begin
    Member:= TPlayEntry(Core.PlayList.Entries[i]);
    Member.Selected:= False;
    for j:= 0 to Length(Member.BookMarks)-1 do
    begin
      Member.BookMarks[j].Selected:= False;
    end;
  end;
  Member:= nil;
  bMultiSelect:= False;
  Self.Invalidate;
end;

//******************************************************************************

procedure TPlayGrid.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  CellIndex, TmpIndex, i, Col: Integer;
  BmkPos, TmpInd, TmpBmk : Longint;
  Member: TPlayEntry;
begin
  inherited;

  bNeedResetSelection:= False;
  Self.MouseToCell(X, Y, Col, CellIndex);
  if (CellIndex < 0) then Exit;

  PosToEntry(CellIndex, TmpIndex, BmkPos);

  if (TmpIndex < 0) or (TmpIndex > Core.PlayList.Entries.Count-1) then Exit;

  Member:= TPlayEntry(Core.PlayList.Entries[TmpIndex]);

  bDragging:= True;
  if (ssCtrl in Shift) and (ssLeft in Shift) then
  begin
    if BmkPos < 0 then
    begin
      Member.Selected:= not Member.Selected;
    end else
    begin
      Member.BookMarks[BmkPos].Selected:= not Member.BookMarks[BmkPos].Selected;
    end;
    bMultiSelect:= True;
    bDragging:= False;
  end else
  if (Shift = [ssLeft]) or (Shift = [ssRight]) then
  begin
    if not bMultiSelect then
    begin
      ResetSelection;
      bNeedResetSelection:= False;
      if BmkPos < 0 then
      begin
        Member.Selected:= True;
      end else
      begin
        Member.BookMarks[BmkPos].Selected:= True;
      end;
    end else
      bNeedResetSelection:= True;
  end else
  if (ssShift in Shift) and (ssLeft in Shift) then
  begin
    if (CellIndex < PrevCellIndex) then
    begin
      for i:= CellIndex to PrevCellIndex do
      begin
        PosToEntry(i, TmpInd, TmpBmk);
        if (TmpBmk < 0) then
        begin
          TPlayEntry(Core.PlayList.Entries[TmpInd]).Selected:= True;
        end else
        begin
          TPlayEntry(Core.PlayList.Entries[TmpInd]).BookMarks[TmpBmk].Selected:= True;
        end;
      end;
    end else
    begin
      for i:= PrevCellIndex to CellIndex do
      begin
        PosToEntry(i, TmpInd, TmpBmk);
        if (TmpBmk < 0) then
        begin
          TPlayEntry(Core.PlayList.Entries[TmpInd]).Selected:= True;
        end else
        begin
          TPlayEntry(Core.PlayList.Entries[TmpInd]).BookMarks[TmpBmk].Selected:= True;
        end;
      end;
    end;
    bMultiSelect:= True;
    bDragging:= False;
  end;
  SelIndex:= TmpIndex;
  PrevCellIndex:= CellIndex;
  BmkSelIndex:= BmkPos;
//  bDragging:= True;
  Member:= nil;
  Self.Invalidate;
end;

//******************************************************************************

procedure TPlayGrid.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  NewIndex, MinInd, MaxInd, Delta, i, Col: Integer;
  ItemIndex, BmkPos: Longint;
begin
  inherited;

  if BmkSelIndex >= 0 then Exit;

  MinInd:= -1;
  MaxInd:= -1;
  if bDragging then
  begin
    for i:= 0 to Core.PlayList.Entries.Count-1 do
    begin
      if TPlayEntry(Core.PlayList.Entries[i]).Selected and (MinInd < 0) then
        MinInd:= i;
      if TPlayEntry(Core.PlayList.Entries[i]).Selected and (MaxInd < i) then
        MaxInd:= i;
    end;

    Self.MouseToCell(X, Y, Col, NewIndex);
    PosToEntry(NewIndex, ItemIndex, BmkPos);

    if (ShowBookmarks) then
    begin
      Delta:= ItemIndex-MinInd;
    end else
    begin
      Delta:= ItemIndex-SelIndex;
    end;
////
    if Delta = 0 then Exit;
    if BmkPos >= 0 then Exit;

    MinIndex:= MinInd;
    MaxIndex:= MaxInd;
    if (MaxInd+Delta < Core.PlayList.Entries.Count) and (MinInd+Delta >= 0) then
    begin
      if Delta > 0 then
      begin
        for i:= MaxInd downto MinInd do
        begin
          if TPlayEntry(Core.PlayList.Entries[i]).Selected then
          begin
            SwapMembers(i, i+Delta);
          end;
        end;
      end else
      begin
        for i:= MinInd to MaxInd do
        begin
          if TPlayEntry(Core.PlayList.Entries[i]).Selected then
          begin
            SwapMembers(i, i+Delta);
          end;
        end;
      end;
      SelIndex:= ItemIndex;
    end;
    self.Invalidate;
  end;
end;

//******************************************************************************

procedure TPlayGrid.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Col: integer;
begin
  inherited;

  if bDragging then
    Self.MouseToCell(X, Y, Col, PrevCellIndex);

  if bNeedResetSelection then
  begin
    ResetSelection;
    if (BmkSelIndex < 0) then
    begin
      TPlayEntry(Core.PlayList.Entries[SelIndex]).Selected:= True;
    end else
      TPlayEntry(Core.PlayList.Entries[SelIndex]).BookMarks[BmkSelIndex].Selected:= True;
    begin
    end;
  end;
  bDragging:= False;
  Self.Invalidate;
end;

//******************************************************************************

procedure TPlayGrid.WMDblClick(var Msg: TMEssage);
begin
  PlaySelection;

  if (SelIndex < Core.PlayList.Entries.Count) and (SelIndex >=0) then
    if BmkSelIndex < 0 then
    begin
      TPlayEntry(Core.PlayList.Entries[SelIndex]).Selected:= True;
    end else
    begin
      TPlayEntry(Core.PlayList.Entries[SelIndex]).BookMarks[BmkSelIndex].Selected:= True;
    end;
  bDragging:= False;
end;

procedure TPlayGrid.Clear;
begin
  PrevCellIndex:= 0;
  BmkSelIndex:= -1;
  Invalidate;
end;

constructor TPlayGrid.Create;
begin
  inherited Create(AOwner);
  FShowBookmarks:=TRUE;
  ColCount:=1;
  FixedCols:=0;
  FixedRows:= 0;
  DefaultRowHeight:=15;
  DefaultColWidth:=500;
  ScrollBars:=ssVertical;
  GridLineWidth:=0;
  Options:=Options + [goThumbTracking] - [goRangeSelect];
  BorderStyle:=bsNone;
  DefaultDrawing:=FALSE;
  SelIndex:=Core.Prefs.ReadInteger('Last.PlayListIdx');
  PrevCellIndex:=Core.Prefs.ReadInteger('Last.PlayListIdx');
  NewFont;

  Core.MdlMgr.AttachWithState('PlayList',OnPlayListChanging);

  DoubleBuffered:=TRUE;
  Clear;
end;

destructor TPlayGrid.Destroy;
begin
  Core.MdlMgr.Detach('PlayList',OnPlayListChanging);
  inherited;
end;

procedure TPlayGrid.PosToEntry;
var
  l,k,pos:LongInt;
begin
  pos:=0;
  for l:=0 to Core.PlayList.Entries.Count-1 do
    begin
    BkMkPos:=-1;
    FilePos:=l;
    if (pos=index) then Exit;
    inc (pos);
    if FShowBookmarks then
      for k:=0 to Length(TPlayEntry(Core.PlayList.Entries[l]).BookMarks)-1 do begin
        BkMkPos:=k;
        if (pos=index) then Exit;
        inc (pos);
      end;
    end;
  FilePos:=-1;
  BkMkPos:=-1;
end;

procedure TPlayGrid.Delete;
var
  i, j, lastsel: integer;
begin
  lastsel:=0;
  try
    if Core.PlayList.Entries.Count = 0 then Exit;
  except
    Exit;
  end;

  for i:= Core.PlayList.Entries.Count-1 downto 0 do
  begin
    if TPlayEntry(Core.PlayList.Entries[i]).Selected then
    begin
      Core.PlayList.DeleteEntry(i);
      lastsel:=i;
    end else
    begin
      for j:= Length(TPlayEntry(Core.PlayList.Entries[i]).BookMarks)-1 downto 0 do
        if TPlayEntry(Core.PlayList.Entries[i]).BookMarks[j].Selected then
        begin
          Core.PlayList.DeleteBookMark(i, j);
          lastsel:=i;
        end;
    end;
  end;

  if (lastsel=Core.PlayList.Entries.Count) then
    dec(lastsel);
  if (Core.PlayList.Entries.Count>0) then
      TPlayEntry(Core.PlayList.Entries[lastsel]).Selected:= True;

  Invalidate;
end;

function TPlayGrid.EntryToPos(FilePos, BkMkPos: LongInt): LongInt;
var
  l, k: LongInt;
  Member: TPlayEntry;
begin
  Result:=0;
  for l:=0 to Core.PlayList.Entries.Count-1 do begin
    Member:= TPlayEntry(Core.PlayList.Entries[l]);
    if (FilePos=l) and not(FShowBookmarks) then Exit;
    if (FilePos=l) and (BkMkPos=-1) then Exit;
    inc(Result);
    if FShowBookmarks then
      for k:=0 to Length(Member.BookMarks)-1 do begin
        if (FilePos=l) and (BkMkPos=k) then Exit;
        inc (Result);
      end;
  end;
end;

procedure TPlayGrid.Invalidate;
var
  l, Cnt: LongInt;
  Member: TPlayEntry;
begin
  if (SelIndex<0) then SelIndex:=0;
  Cnt:=0;
  if Core.PlayList = nil then Exit;
  if Core.PlayList.Updating > 0 then Exit;

  for l:=0 to Core.PlayList.Entries.Count-1 do begin
    Inc(Cnt);
    if FShowBookmarks then
      Inc(Cnt, Length(TPlayEntry(Core.PlayList.Entries[l]).BookMarks));
  end;

  RowCount:= Cnt;
  Visible:= (Cnt>0);

  if (Core.PlayList.PlayPos>=0) and (Core.PlayList.Entries.Count>0) then begin
    Member:= TPlayEntry(Core.PlayList.Entries[Core.PlayList.PlayPos]);
    frMain.tbPos.ClearBookMarks;
    for l:=0 to Length(Member.BookMarks)-1 do
      frMain.tbPos.SetBookMark(l,TBookmark(Member.BookMarks[l]).Pos);
  end;

  inherited Invalidate;
end;

procedure TPlayGrid.MoveDown;
begin
  if (Core.PlayList.Entries.Count<2) then Exit;
  if ((SelIndex+1)>(Core.PlayList.Entries.Count-1)) then Exit;
  SwapMembers(SelIndex,SelIndex+1);
  Inc(SelIndex);
  Invalidate;
end;

procedure TPlayGrid.MoveUp;
begin
  if (Core.PlayList.Entries.Count<2) then Exit;
  if ((SelIndex-1)<0) then Exit;
  SwapMembers(SelIndex,SelIndex-1);
  Dec(SelIndex);
  Invalidate;
end;

procedure TPlayGrid.SwapMembers;
begin
  if (ItemA>=Core.PlayList.Entries.Count) or (ItemB>=Core.PlayList.Entries.Count) or (ItemA=ItemB) then exit;

  Core.PlayList.SwapEntries(ItemA,ItemB);
end;

{ TPlayGridItem }

procedure TPlayGrid.PlaySelection;
begin
  if (Core.PlayList<>NIL) and (Core.PlayList.Entries.Count>0) then
    Core.PlayList.PlayEntry(SelIndex, BmkSelIndex);
end;

procedure TPlayGrid.SetShowBookmarks(Value: boolean);
begin
  if (FShowBookmarks<>Value) then begin
    FShowBookmarks:=Value;
    Invalidate;
  end;
end;

procedure TPlayGrid.SaveReport;
var
  f:file;
  l:LongInt;
  Header,Entry,Footer,Data,Color:string;
  MediaInfo:TMediaInfo;
  CFile:TCachedFile;
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
function SplitTimeText(Time:TREFERENCETIME):string;
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
begin
  Data:=repTemplate;
  if FileExists(Template) then begin
    FileMode:=0;
    AssignFile(f,Template);
    Reset(f,1);
    SetLength(Data,FileSize(f));
    BlockRead(f,Data[1],FileSize(f));
    CloseFile(f);
    FileMode:=0;

    l:=Pos(#$A,Data);
    Data:=Copy(Data,l+1,Length(Data)-l);
  end;

  l:=Pos('%EntryStart%',Data);
  Header:=Copy(Data,1,l-1);
  Data:=Copy(Data,l+12,Length(Data)-((l-1)+12));
  l:=Pos('%EntryEnd%',Data);
  Entry:=Copy(Data,1,l-1);
  Footer:=Copy(Data,l+10,Length(Data)-((l-1)+10));

  AssignFile(f,FileName);
  Rewrite(f,1);

  Data:=Header;
  BlockWrite(f,Data[1],Length(Data));

  for l:=0 to (Core.PlayList.Entries.Count-1) do
  begin
    CFile:=TCachedFile.Create(TPlayEntry(Core.PlayList.Entries[l]).FileName);
    MediaInfo:=TMediaInfo.Create(CFile);
    MediaInfo.RetreiveInfo;
    Data:=Entry;
    Data:=StringReplace(Data,'%No%',IntToStr(l+1),[rfReplaceAll,rfIgnoreCase]);
    Color:='#EEFFFF';
    if (l and 1)=1 then Color:='#FFFFEE';
    Data:=StringReplace(Data,'%CellColor%',Color,[rfReplaceAll,rfIgnoreCase]);
    Data:=MediaInfo.ReplaceTAGs(Data);
    BlockWrite(f,Data[1],Length(Data));

    Row:=l;
    Invalidate;
    Repaint;

    FreeAndNIL(MediaInfo);
    FreeAndNIL(CFile);
  end;

  // Сколько всего записей?
  Footer := StringReplace(Footer, '%TotalFilesNumber%', IntToStr(Core.PlayList.Entries.Count), [rfReplaceAll, rfIgnoreCase]);
  // Общая продолжительность коллекции?
  Footer := StringReplace(Footer, '%TotalDuration%', SplitTimeText(TotalDuration), [rfReplaceAll, rfIgnoreCase]);
  // Общий размер коллекции?
  Footer := StringReplace(Footer, '%TotalSize%', BytesToStr(TotalSize), [rfReplaceAll, rfIgnoreCase]);
  // Дата последней модификации?
  Footer := StringReplace(Footer, '%LastUpdate%', LastUpdate, [rfReplaceAll, rfIgnoreCase]); 
  // Текущая версия ЛА.
  Footer := StringReplace(Footer, '%LAVersion%', Core.VerInfo.FileVersion + '.' + Core.VerInfo.FormatInfo('{B}'), [rfReplaceAll, rfIgnoreCase]);

  Data:=Footer;
  BlockWrite(f,Data[1],Length(Data));

  CloseFile(f);
end;

// Рисуем элементы списка.
procedure TPlayGrid.DrawCell;
var
  s:string;
  FilePos, BmkPos, l :LongInt;
  Member: TPlayEntry;
  Z:LongInt;
  X:TXMLNode;
  BMP:TBitmap;
begin
  Dec(ARect.Left);
  Dec(ARect.Top);
  with Canvas do
  begin
    PosToEntry(ARow, FilePos, BmkPos);

    Font := Self.Font;
    Font.Color := TextColor;
    Pen.Color := PlayListColor;
    Brush.Color := PlayListColor;

    if Core.PlayList.PlayPos = FilePos then
    begin
      Font.Color:=clLtGray;
      if frMain.LoadedFileName <> '' then
      begin
        Font.Color := TextSelColor;
        if Core.PlayList.IsRepeatOneFile then
          if (INI.Bool['PlayList.UseSkinColor']) then
            Font.Color := Core.OptiBld.GetImage('Color.PL').Canvas.Pixels[0,4]
          else
            Font.Color := StringToColor(INI.Str['PlayList.RepeatFileColor']);
      end;
    end;

    if (FilePos < 0) then FilePos := 0;
    if Core.PlayList.Entries = nil then Exit;

    Member:= TPlayEntry(Core.PlayList.Entries[FilePos]);

    if Member.Selected and (BmkPos < 0) then
      Brush.Color:=SelBGColor;
    if (BmkPos >= 0) then
      if Member.BookMarks[BmkPos].Selected then begin
        Brush.Color:=SelBGColor;
        Pen.Color:=SelBGColor;
      end;

    FillRect(ARect);

    // Файл.
    if (BmkPos<0) then
    begin
      s:=' '+Member.Title;
      if ShowNumbers then
      begin
        l:=1;
        if (Core.PlayList.Entries.Count>0) then l:=1+Trunc(Log10(Core.PlayList.Entries.Count));
        s:=Format(' %.'+IntToStr(l)+'d. %s',[FilePos+1,Member.Title]);
      end;
      TextOut(ARect.Left,ARect.Top,s);

      if ShowDuration then
      begin
        Font.Style:=[fsBold];
        S:=' --:--';
        X := Core.MediaCache.GetOrCreateInfo(Member.FileName);

        if (Member.Duration = -1) then
          if (X.Attr('Dur')) <> '' then
            Member.Duration :=  StrToInt64(X.Attr('Dur'))
            else
          Member.Duration := GetMemberDur(Member.FileName);

        if (Member.Duration >= 0) then
        begin
          S:=' '+Core.SysHlp.FormatHNS('{H}:{M}:{S}',Member.Duration);
          if (Member.Duration<60*60*HNS) then
            S:=' '+Core.SysHlp.FormatHNS('{M}:{S}',Member.Duration);
          if (Member.Duration<10*60*HNS) then
            S:=' '+Core.SysHlp.FormatHNS('{m}:{S}',Member.Duration);
        end;
        X.SetAttr('Dur', IntToStr(Member.Duration));
        Z:=ARect.Right-(TextWidth(S)+20);
        TextOut(Z,ARect.Top,S+'         ');
      end
      else
      begin
        Font.Style:=[fsBold];
        TextOut(ARect.Right-1,ARect.Top,' ');  // убрал 2 чёрных пикселя
      end
    end
    // Закладки.
    else
    begin
      { TODO -oFLASH : We need to take font color for bookmaks from skin/settings. }
      if ModernSkinEngine then begin
        try
          BMP:=TBitmap.Create;
          BMP:=Core.OptiBld.GetImage('Menu.Bookmark');
          BMP.Transparent:=TRUE;
          BMP.TransparentColor:=BMP.Canvas.Pixels[9,9];
          Draw(ARect.Left+19,ARect.Top+4,BMP);
          BMP.Free;
        except
        end;
      end
      else
        frMain.DrawSkinRect(Canvas,Classes.Rect(652,91,11,11),ARect.Left+19,ARect.Top+4);

      if (BmkPos < 9) then
        TextOut(ARect.Left+7,ARect.Top,IntToStr(BmkPos+1));
      if (BmkPos > 8) and (BmkPos < 99) then
        TextOut(ARect.Left+1,ARect.Top,IntToStr(BmkPos+1));

      TextOut(ARect.Left+32,ARect.Top,TBookmark(Member.BookMarks[BmkPos]).Title);

      Font.Style:=[fsBold];
      TextOut(ARect.Right-1,ARect.Top,' ');  // тут тоже убираем 2 чёрных пикселя
    end;
  end;
end;

procedure TPlayGrid.OnPlayListChanging;
begin
  Self.Invalidate;
end;

procedure TPlayGrid.NewFont;
begin
  Core.FntHlp.ReadFromINI(Font,'PlayList.Font');
  DefaultRowHeight:=5+(Font.Size*Font.PixelsPerInch) div 72;

  ShowNumbers:=INI.Bool['PlayList.ShowNumbers'];
  ShowDuration:=INI.Bool['PlayList.ShowDuration'];
end;

procedure TPlayGrid.NewColors;
var
  colorString: String;
begin
  if (INI.Bool['PlayList.UseSkinColor']) then begin
    Color:=frMain.imSkin.Canvas.Pixels[773,109];
    TextColor:=frMain.imSkin.Canvas.Pixels[771,104];
    TextSelColor:=frMain.imSkin.Canvas.Pixels[762,104];
    SelBGColor:=$4F4F4F;
    if ModernSkinEngine then begin
      try
        Color:=Core.OptiBld.GetImage('Color.PL').Canvas.Pixels[0,0];
        TextColor:=Core.OptiBld.GetImage('Color.PL').Canvas.Pixels[0,1];
        TextSelColor:=Core.OptiBld.GetImage('Color.PL').Canvas.Pixels[0,2];
        SelBGColor:=Core.OptiBld.GetImage('Color.PL').Canvas.Pixels[0,3];
      except
      end;
    end;
    if not ModernSkinEngine then
      SelBGColor:=frMain.imSkin.Canvas.Pixels[773,107];
    PlayListColor:=Color;
  end else
  begin
    try
      colorString := INI.Str['PlayList.SelectionColor'];
      if (colorString[1] = 'c') and (colorString[2] = 'l') then
        SelBGColor := StringToColor(colorString)
      else
        SelBGColor := StringToColor(INI.Str['PlayList.SelectionColor']);

      colorString := INI.Str['PlayList.BackgroundColor'];
      if (colorString[1] = 'c') and (colorString[2] = 'l') then
        Color := StringToColor(colorString)
      else
        Color := StringToColor(INI.Str['PlayList.BackgroundColor']);
    except
      SelBGColor := StringToColor(INI.Str['PlayList.SelectionColor']);
      Color := StringToColor(INI.Str['PlayList.BackgroundColor']);
    end;
    PlayListColor:=Color;
    TextColor:=INI.Int['PlayList.Font.Color'];
    TextSelColor:=clWhite;
  end;
end;

procedure TPlayGrid.Resize;
begin
  inherited Resize;
  ColWidths[0]:=Width;
end;

procedure TPlayGrid.OnMouseWheel(var Message: TMessage);
var
  WDir:LongInt;
  Y,Max:LongInt;
  DI: TGridDrawInfo;
begin
  if not(IsMouseOver) then begin
    Message.Result:=SendMessage(frMain.Handle,WM_MOUSEWHEEL,Message.WParam,Message.LParam);
    Exit;
  end;

  WDir:=Message.wParam;
  if (WDir>0) then begin
    Y:=TopRow-3;
  end else begin
    Y:=TopRow+3;
  end;

  CalcDrawInfo(DI);
  Max:=RowCount-1-(DI.Vert.LastFullVisibleCell-DI.Vert.FirstGridCell);

  if (Y<0) then Y:=0;
  if (Y>Max) then Y:=Max;
  TopRow:=Y;

  Invalidate;
end;

procedure TPlayGrid.OnVScroll(var Message: TMessage);
begin
  inherited;
  Exit;
end;

function TPlayGrid.IsMouseOver: Boolean;
var
  P:TPoint;
  R:TRect;
begin
  Result:=FALSE;
  if not(Visible) then Exit;
  GetCursorPos(P);
  GetWindowRect(Handle,R);
  Result:=PtInRect(R,P);
end;

procedure TPlayGrid.FindFirst(Key: String);
begin
  FindKey:=ANSIUpperCase(Key);
  if (Core.PlayList.Entries.Count<1) then Exit;

  SelIndex:=-1;
  //BkMkSel:=-1;

  FindNext;

  Invalidate;
end;

procedure TPlayGrid.FindNext;
var
  l:LongInt;
  S:String;
  Member: TPlayEntry;
  Found:Boolean;
begin
  if (Core.PlayList.Entries.Count<1) then Exit;

  Found:=FALSE;
  for l:=(SelIndex+1) to Core.PlayList.Entries.Count-1 do begin
    Member:= TPlayEntry(Core.PlayList.Entries[l]);
    S:=ANSIUpperCase(Member.Title);
    if (Pos(FindKey,S)>0) then begin
      SelIndex:=l;
      Found:=TRUE;
      Break;
    end;
  end;

  if not(Found) then
    SelIndex:=-1;

  Invalidate;
end;

procedure TPlayGrid.Scrolling;
var
  DI: TGridDrawInfo;
  TmpPos: Integer;
  Centered: Boolean;
  Limit: Integer;
begin
  CalcDrawInfo(DI);
  Limit:=(DI.Vert.LastFullVisibleCell-DI.Vert.FirstGridCell) div 2;

  if Position=-1 then
    Centered:=not((Core.PlayList.PlayPos < Limit) or (Core.PlayList.PlayPos > (Core.PlayList.Entries.Count-(Limit+1))))
      and Core.Prefs.ReadBool('PlayList.Centered')
  else
    Centered:=not((Position < Limit) or (Position > (Core.PlayList.Entries.Count-(Limit+1))))
      and Core.Prefs.ReadBool('PlayList.Centered');

  if not Centered then begin
    // Обычное поведение списка
    if Position=-1 then begin
      if (DSH.HasVideo or DSH.HasAudio) then
      begin
        CalcDrawInfo(DI);
        if (Core.PlayList.PlayPos > DI.Vert.LastFullVisibleCell) or
          (Core.PlayList.PlayPos < Di.Vert.FirstGridCell)
        then begin
          TmpPos:= EntryToPos(Core.PlayList.PlayPos, -1);
          if (RowCount-TmpPos > DI.Vert.LastFullVisibleCell-DI.Vert.FirstGridCell) then
            TopRow := TmpPos
          else
            TopRow := RowCount-(DI.Vert.LastFullVisibleCell-DI.Vert.FirstGridCell+1);
        end;
      end;
    end
    else begin
      CalcDrawInfo(DI);
      if (Position > DI.Vert.LastFullVisibleCell) then
      begin
        TmpPos:=EntryToPos(Position, -1);
        TopRow:=TmpPos-(DI.Vert.LastFullVisibleCell-DI.Vert.FirstGridCell);
      end
      else if (Position < Di.Vert.FirstGridCell) then
        TopRow:=EntryToPos(Position, -1);
    end;
  end else begin
    // Центростремительный режим
    if Position=-1 then begin
      if (DSH.HasVideo or DSH.HasAudio) then
      begin
        CalcDrawInfo(DI);
        if (Core.PlayList.PlayPos > ((DI.Vert.LastFullVisibleCell-DI.Vert.FirstGridCell) div 2)) then
        begin
          TmpPos:=EntryToPos(Core.PlayList.PlayPos-1, -1);
          TopRow:=TmpPos-(DI.Vert.LastFullVisibleCell-DI.Vert.FirstGridCell) div 2;
        end
        else if (Core.PlayList.PlayPos < ((DI.Vert.LastFullVisibleCell-DI.Vert.FirstGridCell) div 2)) then
          TopRow:=EntryToPos(Core.PlayList.PlayPos-1, -1);
      end;
    end
    else begin
      CalcDrawInfo(DI);
      if (Position > ((DI.Vert.LastFullVisibleCell-DI.Vert.FirstGridCell) div 2)) then
      begin
        TmpPos:=EntryToPos(Position-1, -1);
        TopRow:=TmpPos-(DI.Vert.LastFullVisibleCell-DI.Vert.FirstGridCell) div 2;
      end
      else if (Position < ((DI.Vert.LastFullVisibleCell-DI.Vert.FirstGridCell) div 2)) then
        TopRow:=EntryToPos(Position-1, -1);
    end;
  end;
end;

end.
