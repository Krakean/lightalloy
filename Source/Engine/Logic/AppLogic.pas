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
unit AppLogic;

interface

uses
  Windows, Classes, NICE, Dialogs, SysUtils, ShellAPI, ShutDownForm, Forms,
  About, Config, StrUtils;

type
  TAppLogic = class(TObject)
  private
    MdlMgr:TModelManager;
    Lazy:TLazyModeller;

    MdlSuperPlay:TIntModel;
    MdlMute:TIntModel;
    MdlPList:TIntModel;
    MdlOnTop:TIntModel;
    MdlRepeat:TIntModel;
    MdlShuffle:TIntModel;
    MdlBookmarks:TIntModel;
  public
    constructor Create(AMdlMgr:TModelManager);

    procedure ModelsLink;
    procedure ModelsUnLink;

    procedure OnFileOSDInfo;
    procedure OnPrefs;
    procedure OnOpenPlayPause;
    procedure OnOpen;
    procedure OnPlay;
    procedure OnPlayPause;
    procedure OnPlayStop;
    procedure OnPlayRealStop;
    procedure OnNext;
    procedure OnPrev;
    procedure OnHelp;
    procedure OnShutDown;
    procedure OnMinimize;
    procedure OnStayOnTop;
    procedure OnSuperPlay;
    procedure OnAudioMute;
    procedure OnWindowPlayList;
    procedure OnScreenShotCB;
    procedure OnSetOE;
    
    procedure About;
    procedure AboutDevLink;
    procedure AboutDesLink;

    procedure OnFullScreen;
    procedure OnVideoHome;
    procedure OnPlayList;
    procedure FrameStep;
    procedure SpeedPlay;
    procedure OnFileInfo;
    procedure OnFilters;
    procedure OnScreenShot;
    procedure OnPlayListEnd;
    procedure OnSoundSwitchStream;
    procedure OnSubsSwitchStream;    
    procedure OnVisualShuffle;

    procedure OnAudioProps;
    procedure OnVideoProps;
    procedure OnSubProps;

    procedure PlayDVDDisc;
    procedure PlayDVDfromHDD;

    procedure PlayListOpenFiles;
    procedure PlayListAddFiles;
    procedure PlayListAddFolder;
    procedure PlayListRemove;
    procedure PlayListClear;
    procedure PlayListSaveAs;
    procedure PlayListMoveFile;
    procedure PlayListJump;
    procedure PlayListSearch;
    procedure PlayFile(FileName:String);
    procedure ReloadMedia;
    procedure PlayListRepeat;
    procedure PlayListShuffleOn;
    procedure PlayListShowMarks;

    procedure StopActivity;
  end;

implementation

uses
  LACore, MainUnit, CmdC, SysHlp, PlayList, PlayGrid, OtherGlobalVars;

{ TAppLogic }

procedure TAppLogic.OnFileOSDInfo;
begin
  PostMessage(frMain.Handle,WM_LACMD,LAC_FILE_OSD_INFO,0);
end;

procedure TAppLogic.OnPrefs;
begin
  isMediaReloadNeeded := False;
  ItWasPausedBeforeNMR := False;
  
  if Assigned(frConfig) then begin
    frConfig.BringToFront;
  end else begin
    frConfig:=TfrConfig.Create(Application);
    frConfig.ShowModal;
    if Assigned(Core.PlayList.Player) and frConfig.NeedMediaReload then
    begin
      isMediaReloadNeeded := True;
      if frMain.State = stPause then
        ItWasPausedBeforeNMR := True;
      ReloadMedia;
    end;
    FreeAndNIL(frConfig);
  end;
end;

procedure TAppLogic.OnNext;
begin
  PostMessage(frMain.Handle,WM_LACMD,LAC_PLAYLIST_NEXT,0);
end;

procedure TAppLogic.OnOpen;
begin
  PostMessage(frMain.Handle,WM_LACMD,LAC_FILE_OPEN,0);
end;

procedure TAppLogic.OnPlay;
begin
  PostMessage(frMain.Handle,WM_LACMD,LAC_PLAYBACK_PLAY,0);
end;

procedure TAppLogic.OnPlayStop;
begin
  PostMessage(frMain.Handle,WM_LACMD,LAC_PLAYBACK_STOP,0);
end;

procedure TAppLogic.OnOpenPlayPause;
begin
  PostMessage(frMain.Handle,WM_LACMD,LAC_PLAYBACK_STOP_PLAY,0);
end;

procedure TAppLogic.OnPlayPause;
begin
  PostMessage(frMain.Handle,WM_LACMD,LAC_PLAYBACK_STOP_PLAY,0);
end;

procedure TAppLogic.OnPlayRealStop;
begin
  PostMessage(frMain.Handle,WM_LACMD,LAC_PLAYBACK_REAL_STOP,0);
end;

procedure TAppLogic.OnPrev;
begin
  PostMessage(frMain.Handle,WM_LACMD,LAC_PLAYLIST_PREV,0);
end;

procedure TAppLogic.ModelsLink;
begin
  Lazy:=TLazyModeller.Create(MdlMgr);
  Lazy['GUI.StayOnTop'].Int:=1;
  Lazy['GUI.StayOnTop'].OnChange:=NIL;

  Lazy['About.DevLink'].OnCommand:=AboutDevLink;
  Lazy['About.DesLink'].OnCommand:=AboutDesLink;

  Lazy['Application.Exit'].OnCommand:=Core.OnAppExit;
  Lazy['Application.Hibernate'].OnCommand:=Core.SysHlp.Hibernate;
  Lazy['Application.MonitorOff'].OnCommand:=Core.SysHlp.ToggleMonitorPower;
  Lazy['Application.PowerOff'].OnCommand:=Core.AppLogic.OnShutdown;

  Lazy['File.PlayDVD'].OnCommand:=Core.AppLogic.PlayDVDDisc;
  Lazy['File.OpenDVD'].OnCommand:=Core.AppLogic.PlayDVDfromHDD;
  Lazy['File.OSDInfo'].OnCommand:=OnFileOSDInfo;

  Lazy['App.Prefs'].OnCommand:=OnPrefs;
  Lazy['GUI.ShowWindow(Preferences)'].OnCommand:=OnPrefs;
  Lazy['Application.SelectSkin'].OnCommand:=OnPrefs;

  Lazy['Video.FullScreen'].OnCommand:=NIL;
  Lazy['Video.ScreenshotCB'].OnCommand:=OnScreenShotCB;

  Lazy['Seek.SetBookmark'].OnCommand:=Core.PlayList.SetCurrentBookmark;
  Lazy['Seek.SetOE'].OnCommand:=OnSetOE;

  Lazy['GUI.Minimize'].OnCommand:=NIL;
  Lazy['Application.OpenPlayPause'].OnCommand:=OnPlayPause;
  Lazy['Playback.Play'].OnCommand:=OnPlay;
  Lazy['Playback.Stop'].OnCommand:=OnPlayStop;
  Lazy['Playback.RealStop'].OnCommand:=OnPlayRealStop;
//  Lazy['App.SuperPlay'].OnCommand:=OnPlayPause;
  Lazy['PlayList.OpenFiles'].OnCommand:=OnOpen;
  Lazy['PlayList.Prev'].OnCommand:=OnPrev;
  Lazy['PlayList.Next'].OnCommand:=OnNext;

  Lazy['App.Maximize'].OnCommand:=OnFullScreen;
  Lazy['Window.FullScreen'].OnCommand:=OnFullScreen;
  Lazy['Window.Original'].OnCommand:=OnVideoHome;
  Lazy['Player.FrameStep'].OnCommand:=FrameStep;
  Lazy['Player.SpeedPlay'].OnCommand:=SpeedPlay;
  Lazy['Player.ScreenShot'].OnCommand:=OnScreenShot;

  Lazy['Application.Scheduler'].OnCommand:=OnPlayListEnd;

  Lazy['Sound.Switch'].OnCommand:=OnSoundSwitchStream;
  Lazy['Subtitles.Switch'].OnCommand:=OnSubsSwitchStream;

  Lazy['Window.FileInfo'].OnCommand:=OnFileInfo;
  Lazy['Window.Filters'].OnCommand:=OnFilters;

  Lazy['Window.AudioProps'].OnCommand:=OnAudioProps;
  Lazy['Window.VideoProps'].OnCommand:=OnVideoProps;
  Lazy['Window.SubProps'].OnCommand:=OnSubProps;

  Lazy['Application.Help'].OnCommand:=OnHelp;
  Lazy['Application.About'].OnCommand:=About;
  Lazy['Application.PowerOff'].OnCommand:=OnShutdown;

  Lazy['App.About'].OnCommand:=About;
  Lazy['App.Minimize'].OnCommand:=OnMinimize;

  Lazy['PList.AddFiles'].OnCommand:=PlayListAddFiles;
  Lazy['PList.AddDir'].OnCommand:=PlayListAddFolder;
  Lazy['PList.Remove'].OnCommand:=PlayListRemove;
  Lazy['PList.Clear'].OnCommand:=Core.PlayList.Clear;
  Lazy['PList.MoveUp'].OnCommand:=frMain.PlayGrid.MoveUp;
  Lazy['PList.MoveDown'].OnCommand:=frMain.PlayGrid.MoveDown;
  Lazy['PList.Play'].OnCommand:=Core.PlayList.Play;
  Lazy['PList.Save'].OnCommand:=PlayListSaveAs;
  Lazy['PList.Jump'].OnCommand := PlayListJump;
  Lazy['PList.Sort'].OnCommand := Core.PlayList.SortByTitle;
  Lazy['PList.Search'].OnCommand := PlayListSearch;
  Lazy['PList.Report'].OnCommand:=frMain.Report;
  Lazy['PList.VisShuffle'].OnCommand:=OnVisualShuffle;

  // DoubleStates buttons
  MdlSuperPlay:=TIntModel.Create(0,OnSuperPlay);
  MdlMgr.SetModel('App.SuperPlay',MdlSuperPlay);

  MdlOnTop:=TIntModel.Create(Core.Prefs.Int['FrontEnd.StayOnTop'],OnStayOnTop);
  MdlMgr.SetModel('App.StayOnTop',MdlOnTop);

  MdlMute:=TIntModel.Create(Core.Prefs.Int['FrontEnd.Mute'],OnAudioMute);
  MdlMgr.SetModel('Audio.Mute',MdlMute);

  MdlPList:=TIntModel.Create(0,OnWindowPlayList);
  MdlMgr.SetModel('Window.PlayList',MdlPList);

  MdlRepeat:=TIntModel.Create(Core.Prefs.Int['Playlist.Repeat'],PlayListRepeat);
  MdlMgr.SetModel('PList.Repeat',MdlRepeat);

  MdlShuffle:=TIntModel.Create(Core.Prefs.Int['Playlist.ShuffleOn'],PlayListShuffleOn);
  MdlMgr.SetModel('PList.Shuffle',MdlShuffle);

  MdlBookmarks:=TIntModel.Create(Core.Prefs.Int['Playlist.ShowBookmarks'],PlayListShowMarks);
  MdlMgr.SetModel('PList.ShowMarks',MdlBookmarks);
end;

procedure TAppLogic.ModelsUnLink;
begin
  MdlMgr.DestroyModel('App.SuperPlay');
  MdlMgr.DestroyModel('App.StayOnTop');
  MdlMgr.DestroyModel('Audio.Mute');
  MdlMgr.DestroyModel('Window.PlayList');
  MdlMgr.DestroyModel('PList.Repeat');
  MdlMgr.DestroyModel('PList.Shuffle');
  MdlMgr.DestroyModel('PList.ShowMarks');
  Lazy.Free;
end;

constructor TAppLogic.Create;
begin
  MdlMgr:=AMdlMgr;
end;

procedure TAppLogic.PlaylistOpenFiles;
var
  OD:TOpenDialog;
  SL:TStringList;
  FirstFile:String;
  Idx:Integer;
begin
  OD:=TOpenDialog.Create(NIL);
  OD.Title:=MS('Core.Title.Dialog.OpenFile');
  OD.Filter:=frMain.AllMediaTypes;
  OD.InitialDir:=Core.Prefs.ReadString('FrontEnd.MediaDir');
  OD.Options:=[ofHideReadOnly,ofAllowMultiSelect,ofEnableSizing];
  TopPosition(OD.Handle, True);
  if OD.Execute then begin

    Core.PlayList.StopPlayer;
    Core.Prefs.WriteString('FrontEnd.MediaDir',ExtractFilePath(OD.FileName));
    if not(INI.Bool['PlayList.AddInsteadReplacing']) then
      Core.PlayList.Clear;

    SL:=TStringList.Create;
    SL.AddStrings(OD.Files);
    SL.Sort;
    Core.PlayList.AddList(SL);
    SL.Free;

    Core.PlayList.SortByFullPath;
    FirstFile:=OD.Files.Strings[0];
    Idx:=Core.PlayList.GetEntryIndex(FirstFile);
    Core.PlayList.PlayEntry(Idx,0);
    FirstFile:=UpperCase(ExtractFileExt(FirstFile));
    if Idx=-1 then
      if (FirstFile='.LAP') or
        (FirstFile='.M3U') or
        (FirstFile='.PLS') or
        (FirstFile='.LST') or
        (FirstFile='.ASX') or
        (FirstFile='.CUE')
      then
        Core.PlayList.PlayEntry(0,0);
  end;
  TopPosition(OD.Handle, False);
  OD.Free;
end;

procedure TAppLogic.PlayListAddFiles;
var
  OD:TOpenDialog;
begin
  OD:=TOpenDialog.Create(NIL);
  OD.Title:=MS('Core.Title.Dialog.AddFile');
  OD.Filter:=frMain.AllMediaTypes;
  OD.InitialDir:=Core.Prefs.ReadString('FrontEnd.MediaDir');
  OD.Options:=[ofHideReadOnly,ofAllowMultiSelect,ofEnableSizing];
  if OD.Execute then begin
    Core.Prefs.WriteString('FrontEnd.MediaDir',ExtractFilePath(OD.FileName));
    Core.PlayList.AddList(OD.Files);
  end;
  OD.Free;
end;

procedure TAppLogic.PlayListAddFolder;
var
  Dir:String;
begin
  Dir:=Core.SysHlp.SelectFolder(Core.Prefs.ReadString('FrontEnd.MediaDir'));
  if (Dir<>'') then begin
    Core.Prefs.WriteString('FrontEnd.MediaDir',Dir);
    Core.PlayList.AddFolder(Dir);
  end;
end;

procedure TAppLogic.OnHelp;
var
  HelpFile:String;
begin
  HelpFile:=Core.Prefs.ReadString('FrontEnd.Language');
  if (HelpFile='') then HelpFile:='Russian';
  HelpFile:=ExtractFilePath(ParamStr(0))+'Help\'+HelpFile+'.chm';
  if FileExists(HelpFile) then
    ShellExecute(0,NIL,PChar(HelpFile),NIL,NIL,SW_MAXIMIZE)
  else begin
    HelpFile:=ExtractFilePath(ParamStr(0))+'Help\english.chm';
    if FileExists(HelpFile) then
      ShellExecute(0,NIL,PChar(HelpFile),NIL,NIL,SW_MAXIMIZE)
    else
      Core.Alert(MS('Core.Alert.Help'));
  end;
end;

procedure TAppLogic.OnShutDown;
var
  SF:TfrShutdown;
begin
  if SDDialogCreated then
  begin
    SDDialogCreated := False;
    SF.PowerOff;
  end
  else
  begin
    SDDialogCreated := True;
    SF:=TfrShutdown.Create(Application);
    SF.ShowModal;
    SF.Free;
  end;
end;

procedure TAppLogic.About;
begin
  frsAbout := TfrAbout.Create(Application);
  frsAbout.ShowModal;
  frsAbout.Free;
end;

procedure TAppLogic.StopActivity;
begin
  Core.PlayList.StopPlayer;
end;

procedure TAppLogic.PlayListSaveAs;
var
  Ext: string;
  function SetPlayListName: String;
  var ts: string;
  begin
    if Core.PlayList.Entries.Count=0 then begin
      SetPlayListName:='Playlist';
      Exit;
    end;

    if core.Prefs.ReadBool('PlayList.GetNamesFromFileTags') then
      begin
        ts:=Core.PlayList.Entries.Items[frMain.PlayGrid.SelIndex].Title;
        Delete(ts,pos(Separator,ts),Length(ts));
      end
    else begin
      ts:=ExtractFilePath(Core.PlayList.Entries.Items[frMain.PlayGrid.SelIndex].FileName);
      ts:=ReverseString(ts);
      Delete(ts,1,1);
      Delete(ts,pos('\',ts),Length(ts));
      ts:=ReverseString(ts);
      if pos(':',ts)>0 then ts:=Core.PlayList.Entries.Items[frMain.PlayGrid.SelIndex].FileName;
    end;

    if (ts<>'') and (pos(':/',ts)=0) then SetPlayListName:=ts;
  end;

begin
  with TSaveDialog.Create(nil) do
  begin
    Title := MS('Core.Title.Dialog.SavePL');
    Filter := 'Light Alloy Playlist (*.lap)|*.lap|Winamp Playlist (*.m3u)|*.m3u|Winamp Playlist (*.pls)|*.pls';
    DefaultExt := 'lap';
    FileName:=SetPlayListName;
    Options := Options + [ofOverwritePrompt];
    InitialDir := Core.Prefs.ReadString('Playlist.PlaylistDir');
    if Execute then
    begin
      Core.Prefs.WriteString('Playlist.PlaylistDir', ExtractFilePath(FileName));
      Ext := UpperCase(ExtractFileExt(FileName));
      with Core.PlayList do
        if Ext = '.M3U' then
          SaveToM3U(FileName)
        else
          if Ext = '.PLS' then
            SaveToPLS(FileName)
          else
            SaveToLAP(FileName);
    end;
    Free;
  end;
end;

procedure TAppLogic.PlayListMoveFile;
var
  SourceFileName: string;
begin
  with TSaveDialog.Create(nil) do
  begin
    Title := MS('Core.Title.Dialog.MoveFile');
    Filter := '';
    DefaultExt := '';

    if (frmain.pnPlayList.Visible) then
      FileName := Core.PlayList.Entries.Items[frMain.PlayGrid.SelIndex].FileName
    else
      FileName := Core.PlayList.Entries.Items[Core.PlayList.PlayPos].FileName;
    SourceFileName:=FileName;

    Options := Options + [ofOverwritePrompt];
    InitialDir := ExtractFilePath(FileName);
    if Execute then begin
      if (SourceFileName = Core.PlayList.Entries.Items[Core.PlayList.PlayPos].FileName)
        and (frMain.State<>stOff)
      then
        frMain.Stop;

      if (MoveFileEx(PAnsiChar(SourceFileName),PAnsiChar(FileName),MOVEFILE_COPY_ALLOWED)) then
      begin
        if (frmain.pnPlayList.Visible) then
          Core.PlayList.Entries.Items[frMain.PlayGrid.SelIndex].FileName := FileName
        else
          Core.PlayList.Entries.Items[Core.PlayList.PlayPos].FileName := FileName;
        Core.Info(MS('OSD.MoveSuccess'));
      end
      else
        Core.Info(MS('OSD.MoveFailed'));
    end;
    Free;
  end;
end;

procedure TAppLogic.PlayListJump;
begin
  PostMessage(frMain.Handle,WM_LACMD,LAC_PLAYLIST_JUMP,0);
end;

procedure TAppLogic.PlayListSearch;
begin
  PostMessage(frMain.Handle,WM_LACMD,LAC_PLAYLIST_SEARCH_FILE,0);
end;

procedure TAppLogic.PlayDVDDisc;
var
  C:CHAR;
  DT:DWORD;
  FN:String;
  OldMode:DWORD;
begin
  Core.Info(MS('OSD.DVD.Search'));

  OldMode:=SetErrorMode(SEM_FAILCRITICALERRORS);
  for c:='C' to 'Z' do begin
    DT:=GetDriveType(PChar(c+':\'));
    if (DT=DRIVE_CDROM) then begin
      FN:=C+':\VIDEO_TS\VIDEO_TS.IFO';
      if FileExists(FN) then begin
        Break;
      end;
      FN:='';
    end;
  end;
  SetErrorMode(OldMode);

  if (FN='') then begin
    Core.Info(MS('OSD.DVD.NotFound'));
  end else begin
    PlayFile(FN);
  end;
end;

procedure TAppLogic.PlayFile(FileName: String);
begin
  Core.PlayList.StopPlayer;
  Core.Prefs.WriteString('FrontEnd.MediaDir',ExtractFilePath(FileName));
  Core.PlayList.Clear;

  Core.PlayList.AddEntry(FileName);
 // AddFile(FileName, Core.PlayList);
  
  Core.PlayList.Play;
end;

procedure TAppLogic.PlayDVDfromHDD;
var
  S:String;
begin
  S:=INI.Str['FrontEnd.DVDFolder'];
  S:=Core.SysHlp.SelectFolder(S);
  if (S<>'') then begin
    S:=IncludeTrailingPathDelimiter(S);
    INI.Str['FrontEnd.DVDFolder']:=S;
    if FileExists(S+'VIDEO_TS.IFO') then begin
      S:=S+'VIDEO_TS.IFO';
    end else begin
      S:=S+'VIDEO_TS\VIDEO_TS.IFO';
    end;
    PlayFile(S);
  end;
end;

procedure TAppLogic.ReloadMedia;
begin
  Core.PlayList.StopPlayer;
  Core.PlayList.Play;
end;

procedure TAppLogic.OnFullScreen;
begin
  PostMessage(frMain.Handle,WM_LACMD,LAC_WINDOW_FULLSCREEN,0);
end;

procedure TAppLogic.OnVideoHome;
begin
  PostMessage(frMain.Handle,WM_LACMD,LAC_WINDOW_ORIGINAL,0);
end;

procedure TAppLogic.OnPlayList;
begin
  PostMessage(frMain.Handle,WM_LACMD,LAC_WINDOW_PLAYLIST,0);
end;

procedure TAppLogic.FrameStep;
begin
  PostMessage(frMain.Handle,WM_LACMD,LAC_SEEK_FRAME_STEP,0);
end;

procedure TAppLogic.SpeedPlay;
begin
  PostMessage(frMain.Handle,WM_LACMD,LAC_PLAYBACK_SPEED_PLAY,0);
end;

procedure TAppLogic.OnFileInfo;
begin
  PostMessage(frMain.Handle,WM_LACMD,LAC_FILE_INFO,0);
end;

procedure TAppLogic.OnFilters;
begin
  PostMessage(frMain.Handle,WM_LACMD,LAC_PLAYBACK_FILTERS,0);
end;

procedure TAppLogic.OnAudioProps;
begin
  PostMessage(frMain.Handle,WM_LACMD,LAC_SOUND_PROPERTIES,0);
end;

procedure TAppLogic.OnScreenShot;
begin
  PostMessage(frMain.Handle,WM_LACMD,LAC_VIDEO_SCREENSHOT,0);
end;

procedure TAppLogic.OnPlayListEnd;
begin
  PostMessage(frMain.Handle,WM_LACMD,LAC_APPLICATION_POW_ONPLDONE,0);
end;

procedure TAppLogic.OnSoundSwitchStream;
begin
  PostMessage(frMain.Handle,WM_LACMD,LAC_SOUND_SWITCH_STREAM,0);
end;

procedure TAppLogic.OnSubsSwitchStream;
begin
  PostMessage(frMain.Handle,WM_LACMD,LAC_SUBTITLES_SWITCH_STREAM,0);
end;

procedure TAppLogic.OnVisualShuffle;
begin
  PostMessage(frMain.Handle,WM_LACMD,LAC_PLAYLIST_VISUALSHUFFLE,0);
end;

procedure TAppLogic.OnSubProps;
begin
  PostMessage(frMain.Handle,WM_LACMD,LAC_SUBTITLES_PROPERTIES,0);
end;

procedure TAppLogic.OnVideoProps;
begin
  PostMessage(frMain.Handle,WM_LACMD,LAC_VIDEO_PROPERTIES,0);
end;

procedure TAppLogic.OnMinimize;
begin
  PostMessage(frMain.Handle,WM_LACMD,LAC_WINDOW_MINIMIZE,0);
end;

procedure TAppLogic.OnStayOnTop;
begin
  if (MdlOnTop.get_SInt32=0) then begin
    if frMain.HoverButtons[hiCapStayOnTop].Down then
      PostMessage(frMain.Handle,WM_LACMD,LAC_WINDOW_STAY_ON_TOP,0);
  end else begin
    if not(frMain.HoverButtons[hiCapStayOnTop].Down) then
      PostMessage(frMain.Handle,WM_LACMD,LAC_WINDOW_STAY_ON_TOP,0);
  end;
end;

procedure TAppLogic.PlayListClear;
begin

end;

procedure TAppLogic.PlayListRemove;
begin
  frMain.PlayGrid.Delete;
end;

procedure TAppLogic.PlayListRepeat;
begin
  if (MdlRepeat.get_SInt32<>Ord(Core.Prefs.ReadBool('PlayList.Repeat'))) then begin
    PostMessage(frMain.Handle,WM_LACMD,LAC_PLAYLIST_REPEAT,0);
  end;
end;

procedure TAppLogic.PlayListShuffleOn;
begin
  if (MdlShuffle.get_SInt32<>Ord(Core.Prefs.ReadBool('PlayList.ShuffleOn'))) then begin
    PostMessage(frMain.Handle,WM_LACMD,LAC_PLAYLIST_SHUFFLE,0);
  end;
end;

procedure TAppLogic.PlayListShowMarks;
begin
  if (MdlBookmarks.get_SInt32<>Ord(Core.Prefs.ReadBool('Playlist.ShowBookmarks'))) then begin
    PostMessage(frMain.Handle,WM_LACMD,LAC_PLAYLIST_BOOKMARKS,0);
  end;
end;

procedure TAppLogic.OnSuperPlay;
begin
  if (MdlSuperPlay.get_SInt32=0) then begin
    if (frMain.State=stPlay) then
      PostMessage(frMain.Handle,WM_LACMD,LAC_PLAYBACK_STOP_PLAY,0);
  end else begin
    if (frMain.State<>stPlay) then
      PostMessage(frMain.Handle,WM_LACMD,LAC_PLAYBACK_STOP_PLAY,0);
  end;
end;

procedure TAppLogic.OnAudioMute;
begin
  if (MdlMute.get_SInt32=0) then begin
    if frMain.HoverButtons[hiMute].Down then
      PostMessage(frMain.Handle,WM_LACMD,LAC_SOUND_MUTE,0);
  end else begin
    if not(frMain.HoverButtons[hiMute].Down) then
      PostMessage(frMain.Handle,WM_LACMD,LAC_SOUND_MUTE,0);
  end;
end;
// смысла в процедуре не вижу, один хер
//  PostMessage(frMain.Handle,WM_LACMD,LAC_WINDOW_PLAYLIST,0);
// вызывает
procedure TAppLogic.OnWindowPlayList;
begin
  if (MdlPList.get_SInt32=0) then begin
    if frMain.HoverButtons[hiPlayList].Down then
      PostMessage(frMain.Handle,WM_LACMD,LAC_WINDOW_PLAYLIST,0);
  end else begin
    if not(frMain.HoverButtons[hiPlayList].Down) then
      PostMessage(frMain.Handle,WM_LACMD,LAC_WINDOW_PLAYLIST,0);
  end;
end;

procedure TAppLogic.OnScreenShotCB;
begin
  PostMessage(frMain.Handle,WM_LACMD,LAC_VIDEO_CCLIPBOARD,0);
end;

procedure TAppLogic.OnSetOE;
begin
  PostMessage(frMain.Handle,WM_LACMD,LAC_SEEK_SET_OE_OFFSET,0);
end;

procedure TAppLogic.AboutDevLink;
begin
  ShellExecute(0,NIL,'http://www.light-alloy.ru/',NIL,NIL,SW_MAXIMIZE);
end;

procedure TAppLogic.AboutDesLink;
begin
  ShellExecute(0,NIL,'http://www.gmzm.narod.ru/',NIL,NIL,SW_MAXIMIZE);
end;

end.
