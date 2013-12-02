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
unit AdvPList;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, Menus, ActnList,
  ComCtrls, ToolWin, ImgList, PLView, DurSniffer, OtherGlobalVars;

(*
  Add file, Add folder, Add URL
  Load list?, Save list, Save as...
  Shuffle, Sort by title(by label), Sort by filename,
  Sort by path, Reverse
  Sort by: Name,Type,Date,Size,Dir,Duration,Artist
  Remove selected, Clear list(remove all), Crop fles
  Move up, Move down
  Renumber, rename, edit id3
  Play item, Repeat(loop) on/off, Random play order
  File info, bookmarks, play control
  Remova all dead files, Physycally remove
  move to folder
  Media Library, groups, list of playlists (WinAMP3), HotKeys(LIRC) to playlists
  Select All, Select None, Select Inverse
  Generate report (HTML playlist)
  Read extended info, get media duration
  Search/Filter
*)

type
  TfrAdvPList = class(TForm)
    MainMenu: TMainMenu;
    N121: TMenuItem;
    Load1: TMenuItem;
    Save1: TMenuItem;
    Sort1: TMenuItem;
    dit1: TMenuItem;
    Select1: TMenuItem;
    New1: TMenuItem;
    N3: TMenuItem;
    SelectAll1: TMenuItem;
    SelectNone1: TMenuItem;
    Inverseselection1: TMenuItem;
    Addfiles1: TMenuItem;
    Addfolder1: TMenuItem;
    AddURL1: TMenuItem;
    N4: TMenuItem;
    Removeselected1: TMenuItem;
    Removeall1: TMenuItem;
    Cropselected1: TMenuItem;
    Shuffle1: TMenuItem;
    Playback1: TMenuItem;
    Addplaylist1: TMenuItem;
    Reverse1: TMenuItem;
    N17: TMenuItem;
    Moveup1: TMenuItem;
    Movedown1: TMenuItem;
    N18: TMenuItem;
    alPL: TActionList;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    ToolButton11: TToolButton;
    ToolButton12: TToolButton;
    ToolButton13: TToolButton;
    ToolButton15: TToolButton;
    ilActs: TImageList;
    ToolButton18: TToolButton;
    Panel1: TPanel;
    aAddFiles: TAction;
    aAddFolder: TAction;
    aExport: TAction;
    aSortByTitle: TAction;
    aSortByFileName: TAction;
    aSortByFullPath: TAction;
    aShuffle: TAction;
    aReverse: TAction;
    aClear: TAction;
    pnList: TPanel;
    edSearch: TEdit;
    sbFind: TSpeedButton;
    lbTotalDur: TLabel;
    aImport: TAction;
    N22: TMenuItem;
    aSortByFileName1: TMenuItem;
    aSortByFullPath1: TMenuItem;
    aSortByTitle1: TMenuItem;
    ToolButton8: TToolButton;
    aSelectAll: TAction;
    aSelectNone: TAction;
    aSelectInvert: TAction;
    aMoveUp: TAction;
    aMoveDown: TAction;
    aRemove: TAction;
    aCrop: TAction;
    ToolBar2: TToolBar;
    ToolButton9: TToolButton;
    aPlay: TAction;
    aStop: TAction;
    aPause: TAction;
    aNext: TAction;
    aPrevious: TAction;
    Play: TMenuItem;
    Stop1: TMenuItem;
    Pause1: TMenuItem;
    Next1: TMenuItem;
    Previous1: TMenuItem;
    ToolButton10: TToolButton;
    ToolButton14: TToolButton;
    ToolButton16: TToolButton;
    ToolButton17: TToolButton;
    ToolButton19: TToolButton;
    tbVol: TTrackBar;
    ToolButton20: TToolButton;
    ToolButton21: TToolButton;
    aMute: TAction;
    
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);

    procedure edSearchKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure sbFindClick(Sender: TObject);
    procedure edSearchChange(Sender: TObject);
    procedure aAddFilesExecute(Sender: TObject);
    procedure aAddFolderExecute(Sender: TObject);
    procedure aExportExecute(Sender: TObject);
    procedure aSortByTitleExecute(Sender: TObject);
    procedure aSortByFileNameExecute(Sender: TObject);
    procedure aSortByFullPathExecute(Sender: TObject);
    procedure aShuffleExecute(Sender: TObject);
    procedure aReverseExecute(Sender: TObject);
    procedure aClearExecute(Sender: TObject);
    procedure aImportExecute(Sender: TObject);
    procedure aSelectAllExecute(Sender: TObject);
    procedure aSelectNoneExecute(Sender: TObject);
    procedure aSelectInvertExecute(Sender: TObject);
    procedure aMoveUpExecute(Sender: TObject);
    procedure aMoveDownExecute(Sender: TObject);
    procedure aRemoveExecute(Sender: TObject);
    procedure aCropExecute(Sender: TObject);
    procedure aPlayExecute(Sender: TObject);
    procedure aPauseExecute(Sender: TObject);
    procedure aStopExecute(Sender: TObject);
    procedure aNextExecute(Sender: TObject);
    procedure aPreviousExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure tbVolChange(Sender: TObject);
    procedure aMuteExecute(Sender: TObject);
    procedure edSearchKeyPress(Sender: TObject; var Key: Char);
  private
    PlayView:TPlayListView;
    DurSnif:TDurationSniffer;

    procedure OnPlayListChange;
    procedure OnTimer;
    function GetUnknownDur:String;
  public
  end;

var
  frAdvPList: TfrAdvPList;

implementation

{$R *.dfm}

uses
  LACore, SysHlp, PlayList, MainUnit;

procedure TfrAdvPList.FormCreate(Sender: TObject);
var
  S:String;
  XY,WH:TPoint;
begin
  S:=INI.Str['PlayList.Pos'];
  if (S<>'') then
  begin
    Position:=poDesigned;
    XY:=Core.SysHlp.StrToPoint(S);
    WH:=Core.SysHlp.StrToPoint(INI.Str['PlayList.Size']);
    SetBounds(XY.X,XY.Y,WH.X,WH.Y);
  end;

  PlayView:=TPlayListView.Create(Self);
  with PlayView do
  begin
    Parent:=pnList;
    Align:=alClient;
    Invalidate;
  end;
  try
    ActiveControl:=PlayView;
  except
  end;

  if isShuffleActivated then
  aShuffle.Checked := true;

  Core.MdlMgr.AttachWithState('PlayList',OnPlayListChange);
  OnPlayListChange;

  DurSnif:=NIL;
  Core.TimerNotifier.Attach(OnTimer);
end;

procedure TfrAdvPList.OnPlayListChange;
var
  Dur:Int64;
  S:String;
begin
  if Core.PlayList.Entries.Count>0 then
    begin
    Dur:=Core.PlayList.GetTotalDuration;

    S:='';
    if (Dur<0) then begin
      Dur:=-Dur;
      S:='+';
    end;

    S:=Core.SysHlp.FormatHNS('{H}:{M}:{S}',Dur)+S;
    lbTotalDur.Caption:=S;
  end
  else
    lbTotalDur.Caption := '00:00:00+';
end;

procedure TfrAdvPList.FormDestroy(Sender: TObject);
begin
  Core.TimerNotifier.Detach(OnTimer);
  if Assigned(DurSnif) then FreeAndNIL(DurSnif);

  PlayView.Free;
  Core.MdlMgr.DetachWithState('PlayList',OnPlayListChange);
  INI.Str['PlayList.Pos']:=Core.SysHlp.PointToStr(Point(Left,Top));
  INI.Str['PlayList.Size']:=Core.SysHlp.PointToStr(Point(Width,Height));
end;

procedure TfrAdvPList.edSearchKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key=VK_RETURN) then sbFindClick(Self);
end;

procedure TfrAdvPList.sbFindClick(Sender: TObject);
var n: integer;
begin
  n:=PlayView.GetNextSelected;
  if n=-1 then exit;
  Core.PlayList.PlayPos:=n;
  aPlay.Execute;
  sbFind.Down := false;
end;

procedure TfrAdvPList.edSearchChange(Sender: TObject);
begin
  PlayView.FindFirst(edSearch.Text);
end;

procedure TfrAdvPList.aAddFilesExecute(Sender: TObject);
begin
  Core.AppLogic.PlayListAddFiles;
end;

procedure TfrAdvPList.aAddFolderExecute(Sender: TObject);
begin
  Core.AppLogic.PlayListAddFolder;
end;

procedure TfrAdvPList.aExportExecute(Sender: TObject);
begin
  Core.AppLogic.PlayListSaveAs;
end;

procedure TfrAdvPList.aSortByTitleExecute(Sender: TObject);
begin
  Core.PlayList.SortByTitle;
end;

procedure TfrAdvPList.aSortByFileNameExecute(Sender: TObject);
begin
  Core.PlayList.SortByFileName;
end;

procedure TfrAdvPList.aSortByFullPathExecute(Sender: TObject);
begin
  Core.PlayList.SortByFullPath;
end;

procedure TfrAdvPList.aShuffleExecute(Sender: TObject);
begin
  Core.PlayList.Shuffle;
  with aShuffle do Checked := not Checked;
end;

procedure TfrAdvPList.aReverseExecute(Sender: TObject);
begin
  Core.PlayList.Reverse;
end;

procedure TfrAdvPList.aClearExecute(Sender: TObject);
begin
  Core.PlayList.Clear;
end;

procedure TfrAdvPList.aImportExecute(Sender: TObject);
begin
  Core.AppLogic.PlayListOpenFiles;
end;

procedure TfrAdvPList.aSelectAllExecute(Sender: TObject);
begin
  PlayView.SelectAll;
end;

procedure TfrAdvPList.aSelectNoneExecute(Sender: TObject);
begin
  PlayView.ClearSelection;
end;

procedure TfrAdvPList.aSelectInvertExecute(Sender: TObject);
begin
  PlayView.InvertSelection;
end;

procedure TfrAdvPList.aMoveUpExecute(Sender: TObject);
begin
  PlayView.SelectionUp;
end;

procedure TfrAdvPList.aMoveDownExecute(Sender: TObject);
begin
  PlayView.SelectionDown;
end;

procedure TfrAdvPList.aRemoveExecute(Sender: TObject);
begin
  PlayView.RemoveSelected;
end;

procedure TfrAdvPList.aCropExecute(Sender: TObject);
begin
  PlayView.InvertSelection;
  PlayView.RemoveSelected;
end;

procedure TfrAdvPList.OnTimer;
var
  S:String;
begin
  if not(Visible) then begin
    if Assigned(DurSnif) then FreeAndNIL(DurSnif);
    Exit;
  end;

// тормозилку офф
{  if (DurTicker>0) then begin
    Dec(DurTicker);
    Exit;
  end;}

  if Assigned(DurSnif) then begin
    if DurSnif.IsCompleted then begin
      Core.PlayList.UpdateDuration(DurSnif.FileName,DurSnif.Duration);
{      DurTicker:=1;}
    end else begin
      Exit;
    end;
  end;

  S:=GetUnknownDur;
  if (S='') then begin
    if Assigned(DurSnif) then FreeAndNIL(DurSnif);
    Exit;
  end;

  if not(Assigned(DurSnif)) then
    DurSnif:=TDurationSniffer.Create;

  DurSnif.Request(S);
end;

function TfrAdvPList.GetUnknownDur: String;
var
  Y1,Y2,l:LongInt;
begin
  Y1:=PlayView.TopItem.Index;
  Y2:=Y1+PlayView.VisibleRowCount;

  Result:='';
  for l:=Y1 to Y2-1 do begin
    if (l<Core.PlayList.Entries.Count) then begin
      if (Core.PlayList.Entries[l].Duration<0) then begin
        Result:=Core.PlayList.Entries[l].FileName;
        Exit;
      end;
    end;
  end;
end;

procedure TfrAdvPList.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  // чтобы кнопка не отжималась когда закрываем внешний плейлист при показанном внутреннем
  if not(frmain.pnPlayList.Visible) then
    begin
      frMain.HoverButtons[hiPlayList].Down := False;
      Core.MdlMgr.SetSInt32('Window.PlayList',Ord(frMain.HoverButtons[hiPlayList].Down));
    end;
end;

procedure TfrAdvPList.aPlayExecute(Sender: TObject);
begin
  Core.PlayList.Play;
end;

procedure TfrAdvPList.aPauseExecute(Sender: TObject);
begin
  if (frMain.State=stPause) or (frMain.State=stOff) then
    frMain.Play
  else
    frMain.Pause;
end;

procedure TfrAdvPList.aStopExecute(Sender: TObject);
begin
  Core.PlayList.StopPlayer;
end;

procedure TfrAdvPList.aNextExecute(Sender: TObject);
begin
  Core.PlayList.Next;
end;

procedure TfrAdvPList.aPreviousExecute(Sender: TObject);
begin
  Core.PlayList.Prev;
end;

procedure TfrAdvPList.tbVolChange(Sender: TObject);
begin
frMain.tbVolume.Position := tbVol.Position;
end;

procedure TfrAdvPList.aMuteExecute(Sender: TObject);
begin
      begin
      frMain.HoverButtons[hiMute].Down:=not(frMain.HoverButtons[hiMute].Down);
      Core.Prefs.WriteBool('FrontEnd.Mute',frMain.HoverButtons[hiMute].Down);
      frMain.SetVolume;
      Core.MdlMgr.SetSInt32('Audio.Mute',Ord(frMain.HoverButtons[hiMute].Down));
      end;

with aMute do
  begin
  Checked := not Checked;
  if Checked then ImageIndex:=22 else ImageIndex:=21;
  end;
end;

procedure TfrAdvPList.edSearchKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #27) then
  begin
    Key:=#0;
  end;
  if (Key = #13) then
  begin
    Key:=#0;
  end;
end;

end.
