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
unit CmdExec;

interface

uses
  Windows, Classes, CmdC, Filters, Forms, SysUtils, DShowHlp,
  JumpToFile, OpenURLDialog, AdvPList,  Subtitles, OtherGlobalVars, ShellApi;

function ExecuteLACommand(LAC:LongInt):Boolean;

implementation

uses
  LACore, MainUnit;

procedure ScanMediaFiles(Path: String);
var
  SearchRec: TSearchRec;
  bFound,
  HasEntr: Boolean;
begin
  bFound  := False;
  HasEntr := FALSE;

  if FindFirst(Path + '*.*', faAnyFile, SearchRec) = 0 then
    repeat
      if (LowerCase(ExtractFileExt(SearchRec.Name)) = '.asf') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.avi') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.dat') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.divx') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.ogm') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.m1v') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.m2v') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.mkv') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.mov') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.mpe') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.mpeg') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.mpg') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.flv') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.qt') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.rm') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.rv') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.rmvb') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.vob') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.wm') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.wmv') or
        // Audio
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.aif') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.aifc') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.aiff') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.aac') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.ape') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.ac3') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.au') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.flac') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.ogg') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.kar') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.mid') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.mka') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.mp1') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.mp2') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.mp3') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.mpa') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.mpc') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.ra') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.ram') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.snd') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.wav') or
        (LowerCase(ExtractFileExt(SearchRec.Name)) = '.wma')
      then
      begin
        bFound := True;

        if (Core.PlayList.Entries.Count > 1) then
          HasEntr := True;

        Core.PlayList.AddEntry(Path + SearchRec.Name);
      end;
    until FindNext(SearchRec) <> 0;
  FindClose(SearchRec);

  if bFound and not HasEntr then
    Core.PlayList.PlayEntry(0, -1);
end;

function ExecuteLACommand(LAC:LongInt):Boolean;
var
  l:LongInt;
  sSelFile: String;
  FileOp: TSHFileOpStruct;
  FileToDel: String;
  fdLoadedFN: String;
  S:String;
  Pos:Int64;
begin
  Result:=TRUE;
  if (LAC<0) then begin
    Result:=FALSE;
    Exit;
  end;
  with frMain do
  case LAC of
    LAC_FILE_OPEN: begin
      if IsDownloading then Exit;
      Core.AppLogic.PlaylistOpenFiles;
    end;
    LAC_FILE_OPENURL: begin
      if IsDownloading then Exit;
      frOpenURL := TfrOpenURL.Create(Application);
      frOpenURL.Show;
      TopPosition(frOpenURL.Handle, True);
    end;
    LAC_FILE_INFO:
    if (Core.Player<>NIL) and not(pnPlayList.Visible) then
      FileInfo(Core.Player.LoadedFileName)
    else
      Center.ProcessCommand(LAC_FILE_INFO_PLAYLIST);
    // Специально для КонтМеню.
    LAC_FILE_INFO_PLAYLIST: begin
      if IsDownloading then Exit;
      if (Core.PlayList.Entries.Count > 0) then
        FileInfo(Core.PlayList.Entries.Items[frMain.PlayGrid.SelIndex].FileName);
    end;

    LAC_CD_PLAYDISC_A: ScanMediaFiles('A:\');
    LAC_CD_PLAYDISC_B: ScanMediaFiles('B:\');
    LAC_CD_PLAYDISC_C: ScanMediaFiles('C:\');
    LAC_CD_PLAYDISC_D: ScanMediaFiles('D:\');
    LAC_CD_PLAYDISC_E: ScanMediaFiles('E:\');
    LAC_CD_PLAYDISC_F: ScanMediaFiles('F:\');
    LAC_CD_PLAYDISC_G: ScanMediaFiles('G:\');
    LAC_CD_PLAYDISC_H: ScanMediaFiles('H:\');
    LAC_CD_PLAYDISC_I: ScanMediaFiles('I:\');
    LAC_CD_PLAYDISC_J: ScanMediaFiles('J:\');
    LAC_CD_PLAYDISC_K: ScanMediaFiles('K:\');
    LAC_CD_PLAYDISC_L: ScanMediaFiles('L:\');
    LAC_CD_PLAYDISC_M: ScanMediaFiles('M:\');
    LAC_CD_PLAYDISC_N: ScanMediaFiles('N:\');
    LAC_CD_PLAYDISC_O: ScanMediaFiles('O:\');
    LAC_CD_PLAYDISC_P: ScanMediaFiles('P:\');
    LAC_CD_PLAYDISC_Q: ScanMediaFiles('Q:\');
    LAC_CD_PLAYDISC_R: ScanMediaFiles('R:\');
    LAC_CD_PLAYDISC_S: ScanMediaFiles('S:\');
    LAC_CD_PLAYDISC_T: ScanMediaFiles('T:\');
    LAC_CD_PLAYDISC_U: ScanMediaFiles('U:\');
    LAC_CD_PLAYDISC_V: ScanMediaFiles('V:\');
    LAC_CD_PLAYDISC_W: ScanMediaFiles('W:\');
    LAC_CD_PLAYDISC_X: ScanMediaFiles('X:\');
    LAC_CD_PLAYDISC_Y: ScanMediaFiles('Y:\');
    LAC_CD_PLAYDISC_Z: ScanMediaFiles('Z:\');

    LAC_FILE_OSD_INFO:
      frMain.FileOSDInfo(Core.Player.LoadedFileName);
{=========================== PLAYBACK ===================================}
    LAC_PLAYBACK_STOP_PLAY:
      if (frMain.State=stPause) or (frMain.State=stOff) then frMain.Play else frMain.Pause;
    LAC_PLAYBACK_STOP:
      frMain.Pause;
    LAC_PLAYBACK_REAL_STOP:
      frMain.Stop;
    LAC_PLAYBACK_PLAY:
      frMain.Play;
    LAC_PLAYBACK_SPEED_PLAY:
      frMain.SpeedPlay;
    LAC_PLAYBACK_FILTERS: begin
      if (frMain.HoverButtons[hiFilters].Enabled) then begin
        frFilters:=TfrFilters.Create(Application);
        frFilters.RefreshList;
        frFilters.ShowModal;
        PopUpForm(frFilters);
        TopPosition(frFilters.Handle, True);
        TopPosition(frFilters.Handle, False);
        FreeAndNIL(frFilters);
      end;
    end;
{=========================== SEEK ===================================}
    LAC_SEEK_FRAME_STEP:
      frMain.FrameStep;
    LAC_SEEK_FRAME_BACK:
      frMain.FrameBack;
    LAC_SEEK_BACKWARD:
      frMain.Seek('-'+Core.Prefs.ReadString('Seek.KeySeek'));
    LAC_SEEK_FORWARD:
      frMain.Seek('+'+Core.Prefs.ReadString('Seek.KeySeek'));
    LAC_SEEK_JUMP_BACKWARD:
      frMain.Seek('-'+Core.Prefs.ReadString('Seek.KeyJump'));
    LAC_SEEK_JUMP_FORWARD:
      frMain.Seek('+'+Core.Prefs.ReadString('Seek.KeyJump'));
    LAC_SEEK_REWIND:
      Core.Player.Rewind;
    LAC_SEEK_SET_BOOKMARK:
      Core.PlayList.SetCurrentBookmark;
    LAC_SEEK_SET_OE_OFFSET:
      if (dsh <> nil) and dsh.HasVideo then begin
        lastDur:= DSH.Duration;
        // узнаем позицию конца опенинга или начала эндинга
        if dsh.position < (dsh.Duration div 2) then begin
          OpeningSeekPos:=dsh.position;
          Core.Info(MS('OSD.Opening'));
        end
        else begin
          EndingSeekPos:=dsh.Duration - dsh.position; //  время до конца запоминаем на случай разной длины серий
          Core.Info(MS('OSD.Ending'));
        end;
      end;
    LAC_SEEK_LAST_POS: begin
      if not(DSH.HasVideo) or not(DSH.HasAudio) then
        PLay;

      if (File2Hash64K='') then Exit;
        X2:=Core.MediaSets.GetInfo(File2Hash64K);
      if (X2=NIL) then Exit;
      S:=X2.Attr('PlayPos');
      if (S<>'') then begin
        try
	        Pos:=StrToInt64(S);
		      DSH.SeekTo(Pos);
        except
        end;
      end;
    end;
    LAC_SEEK_A_B: begin
      if LoadedFileName = '' then
        Exit
      else if Seek_A_B = 2 then begin
        Core.Info(MS('OSD.Seek.Off'));
        Seek_A_B := 0 // Выключено
      end
      else if Seek_A_B = 0 then begin
        Seek_A := DSH.Position;
        Core.Info(MS('OSD.Seek.A'));
        Seek_A_B := 1; //Отмечен Опенинг
      end
      else begin
        Seek_B := DSH.Position;
        if Seek_B < Seek_A then begin
          Seek_C := Seek_B;
          Seek_B := Seek_A;
          Seek_A := Seek_C;
        end;
        Core.Info(MS('OSD.Seek.B'));
        Seek_A_B := 2; //Отмечен Эндинг
      end;
    end;

{=========================== WINDOW ===================================}
    LAC_WINDOW_FULLSCREEN: begin
      if (frMain.HoverButtons[hiFullScreen].Enabled) then begin
        if not frMain.HoverButtons[hiFullScreen].Down then
        begin
          frMain.ResizeFullScreen;
          fsmCPVis := frMain.pnControl.Visible;
          frMain.ShowCPanel := false;
        end else
          frMain.ResizeUser;

        case Core.Prefs.ReadInteger('FrontEnd.RememberPanelsState') of
          0: begin // обычное
            if frMain.HoverButtons[hiFullScreen].Down and frMain.pnControl.Visible then
              frMain.TogglePanels;  // выключаем панели при переходе на фулскрин
            if not frMain.HoverButtons[hiFullScreen].Down and not frMain.pnControl.Visible then
              frMain.TogglePanels(TRUE);  // включаем панели при переходе на окно
          end;
          1: begin // всегда сохраняем состояние панели в оконном режиме в том же состоянии
            if isToggleActive = True and not(firstfsm) then
              ShowCpanel:=not(showCPanel);
            if Core.Prefs.ReadBool('OnOpen.FullScreen') and Core.Prefs.ReadBool('Mouse.HoverCPane') and firstfsm = true then
              ShowCPanel:=True;

            if Core.Prefs.ReadBool('OnOpen.FullScreen') and OnOpenFsm = True then
            begin
              fsmCPVis := not(frMain.pnControl.Visible);
              OnOpenFsm := False;
            end;
            if not frMain.HoverButtons[hiFullScreen].Down and (fsmCPVis <> frMain.pnControl.Visible) then
              frMain.TogglePanels(TRUE);  // востанавливаем состояние панели при переходе на окно
          end;
          2: begin
            // всегда сохраняем состояние панели в оконном режиме в том же состоянии
            // и при переключении на фулскрин выключаем панель
            if Core.Prefs.ReadBool('OnOpen.FullScreen') and OnOpenFsm = True then
            begin
              fsmCPVis := not(frMain.pnControl.Visible);
              OnOpenFsm := False;
            end;
            if frMain.HoverButtons[hiFullScreen].Down and frMain.pnControl.Visible then
              frMain.TogglePanels;   // выключаем панели при переходе на фулскрин
            if not frMain.HoverButtons[hiFullScreen].Down and (fsmCPVis <> frMain.pnControl.Visible) then
              frMain.TogglePanels(TRUE);  // востанавливаем состояние панели при переходе на окно
          end;
        end;
        frMain.MapVideoWindow;
      end;
    end;
    LAC_WINDOW_ORIGINAL: begin
      if Assigned(frMain.VideoModel) and (DSH.HasVideo) then begin
        frMain.VideoModel.Zoom:=Point(100,100); // 100,100
        frMain.VideoModel.Ofs:=Point(0,0);
        frMain.VideoModel.Ratio:=Point(0,0);
        frMain.VideoModel.GeometryChanged;
        frMain.ResizeScaled(-1);
      end
      else
        frMain.ResizeUser;
      frMain.ResizeCenter;
      frMain.CenterForm;
      frMain.MapVideoWindow;
    end;
    LAC_WINDOW_PLAYLIST: begin
      if hoverCPanel then begin
        frMain.ToggleCPanel;
        frMain.ShowPlayList(true);
      end
      else begin
        l:=INI.Int['PlayList.External'];
        if frMain.IsAltPressed then l:=1-l;
        if (l=1) then
          frMain.AdvancedPlayList
        else begin
          //  в ShowPlayList состояние кнопки меняется
          //   frMain.HoverButtons[hiPlayList].Down:=not(frMain.HoverButtons[hiPlayList].Down);
          frMain.ShowPlayList(not frMain.HoverButtons[hiPlayList].Down);
        end;
        Core.MdlMgr.SetSInt32('Window.PlayList',Ord(frMain.HoverButtons[hiPlayList].Down));
      end;
    end;
    LAC_WINDOW_CONTROL_PANEL:
      ToggleCPanel;
    LAC_WINDOW_MINIMIZE: begin
      if (HideFromBoss = 0) or (HideFromBoss = 2) then begin
        originMinimizeActivate := True;
        ToggleMinimize;
      end;
    end;
    LAC_WINDOW_MAXIMIZE: begin
      if (HideFromBoss = 0) or (HideFromBoss = 2) then begin
        originMinimizeActivate := True;
        Maximize;
      end;
    end;
    LAC_WINDOW_HIDE_FROM_BOSS: begin
      if (HideFromBoss = 0) or (HideFromBoss = 2) then
        HideFromBoss := 1  // hide
      else
        HideFromBoss := 2; // show
      ToggleMinimize;
    end;
    LAC_WINDOW_STAY_ON_TOP: begin
      HoverButtons[hiCapStayOnTop].Down:=not(HoverButtons[hiCapStayOnTop].Down);
      Core.Prefs.WriteBool('FrontEnd.StayOnTop',HoverButtons[hiCapStayOnTop].Down);
      SetStayOnTop(HoverButtons[hiCapStayOnTop].Down);
      Core.MdlMgr.SetSInt32('App.StayOnTop',Ord(frMain.HoverButtons[hiCapStayOnTop].Down));
    end;
    LAC_WINDOW_EX_PLAYLIST: begin
      AdvancedPlayList;
      Core.MdlMgr.SetSInt32('Window.PlayList',Ord(frMain.HoverButtons[hiPlayList].Down));
    end;  
{=========================== VIDEO ===================================}
    LAC_VIDEO_SCALE_50:
      ResizeScaled(50);
    LAC_VIDEO_SCALE_100:
      ResizeScaled(100);
    LAC_VIDEO_SCALE_200:
      ResizeScaled(200);
    LAC_VIDEO_RATIO_ASIS:
      SetAspectRatio(0,0);
    LAC_VIDEO_RATIO_16_9:
      SetAspectRatio(16,9);
    LAC_VIDEO_RATIO_4_3:
      SetAspectRatio(4,3);
    LAC_VIDEO_RATIO_WIDTH:
      SetAspectRatio(1,0);
    LAC_VIDEO_RATIO_HEIGHT:
      SetAspectRatio(0,1);
    LAC_VIDEO_RATIO_CUSTOM:
      SetCustomRatio;
    LAC_VIDEO_RATIO_FREE:
      SetAspectRatio(-1,-1);
    LAC_VIDEO_ZOOM_IN:
      DeltaZoom(+5,+5);
    LAC_VIDEO_ZOOM_OUT:
      DeltaZoom(-5,-5);
    LAC_VIDEO_BRIGHTNESS_INC:
      DSH.AdjustBCS(+1,0,0);
    LAC_VIDEO_BRIGHTNESS_DEC:
      DSH.AdjustBCS(-1,0,0);
    LAC_VIDEO_CONTRAST_INC:
      DSH.AdjustBCS(0,+1,0);
    LAC_VIDEO_CONTRAST_DEC:
      DSH.AdjustBCS(0,-1,0);
    LAC_VIDEO_SATURATION_INC:
      DSH.AdjustBCS(0,0,+1);
    LAC_VIDEO_SATURATION_DEC:
      DSH.AdjustBCS(0,0,-1);
    LAC_VIDEO_PROPERTIES:
      VideoProps;
    LAC_VIDEO_SCREENSHOT:
      if (HoverButtons[hiScreenShot].Enabled) then ScreenShot;
    LAC_VIDEO_CCLIPBOARD:
      CClipboard;
    LAC_VIDEO_COLOR_RESET:
      DSH.SetBCS(50,50,50);
{=========================== PLAYLIST ===================================}
    LAC_PLAYLIST_NEXT: begin
      if IsDownloading then begin
        Result:=FALSE;
        Exit;
      end;
      NextByHotkey := True;
      Core.PlayList.Next;
    end;
    LAC_PLAYLIST_PREV: begin
      if IsDownloading then begin
        Result:=FALSE;
        Exit;
      end;
      NextByHotkey := True;
      Core.PlayList.Prev;
    end;
    LAC_PLAYLIST_PLAY:
      PlayGrid.PlaySelection;
    LAC_PLAYLIST_REPEAT: begin
      HoverButtons[hiRepeat].Down:=not(HoverButtons[hiRepeat].Down);
      Core.Prefs.WriteBool('Playlist.Repeat',HoverButtons[hiRepeat].Down);
      Core.MdlMgr.SetSInt32('PList.Repeat',Ord(frMain.HoverButtons[hiRepeat].Down));
    end;
    LAC_PLAYLIST_REPEAT_FILE: begin
      if  Core.Prefs.ReadBool('Playlist.RepeatOneFile') then begin
        Core.Prefs.WriteBool('Playlist.RepeatOneFile',False);
        Core.Info(MS('OSD.RepeatOneFile.Off'));
        frMain.PlayGrid.Invalidate;
      end
      else begin
        Core.Prefs.WriteBool('Playlist.RepeatOneFile',True);
        Core.Info(MS('OSD.RepeatOneFile.On'));
        frMain.PlayGrid.Invalidate;
      end
    end;
    LAC_PLAYLIST_ADD_FILES:
      Core.AppLogic.PlayListAddFiles;
    LAC_PLAYLIST_ADD_FOLDER:
      Core.AppLogic.PlayListAddFolder;
    LAC_PLAYLIST_DELETE:
      PlayGrid.Delete;
    LAC_PLAYLIST_CLEAR:
      Core.PlayList.Clear;
    LAC_PLAYLIST_MOVE_UP:
      PlayGrid.MoveUp;
    LAC_PLAYLIST_MOVE_DOWN:
      PlayGrid.MoveDown;
    LAC_PLAYLIST_SHUFFLE: begin
      HoverButtons[hiRandom].Down:=not(HoverButtons[hiRandom].Down);
      Core.Prefs.WriteBool('Playlist.ShuffleOn',HoverButtons[hiRandom].Down);
      Core.MdlMgr.SetSInt32('PList.Shuffle',Ord(frMain.HoverButtons[hiRandom].Down));
      isShuffleActivated:=Core.Prefs.ReadBool('Playlist.ShuffleOn');
      Core.PlayList.Shuffle;
      if frAdvPList<>nil then
        with Advplist.frAdvPList.aShuffle do
          Checked := not(Checked);
    end;
    LAC_PLAYLIST_VISUALSHUFFLE:
      Core.PlayList.VisualShuffle;
    LAC_PLAYLIST_SORT:
      Core.PlayList.SortByFullPath;
    LAC_PLAYLIST_REPORT:
      Report;
    LAC_PLAYLIST_BOOKMARKS: begin
      HoverButtons[hiTree].Down:=not(HoverButtons[hiTree].Down);
      Core.Prefs.WriteBool('Playlist.ShowBookmarks',HoverButtons[hiTree].Down);
      Core.MdlMgr.SetSInt32('PList.ShowMarks',Ord(frMain.HoverButtons[hiTree].Down));
      PlayGrid.ShowBookmarks:=HoverButtons[hiTree].Down;
      PlayGrid.Invalidate;
    end;
    LAC_PLAYLIST_SAVE:
      Core.AppLogic.PlayListSaveAs;
    LAC_PLAYLIST_JUMP: begin
      frJumpToFile := TfrJumpToFile.Create(Application);
      frJumpToFile.Show;
      TopPosition(frJumpToFile.Handle, True);
    end;
   { LAC_PLAYLIST_SHOW:
    begin
      if (frMain.pnPlayList.Visible) then
        frMain.ShowPlayList(False)
      else
        frMain.ShowPlayList(True);
    end;}
    LAC_PLAYLIST_SEARCH_FILE:
    if (frmain.pnPlayList.Visible) then begin
      sSelFile := PChar(Core.PlayList.Entries.Items[frMain.PlayGrid.SelIndex].FileName);
      ShellExecute(0, '', 'explorer', PChar('/e,/select, ' + sSelFile), '', SW_SHOW);
    end
    else begin
      sSelFile := PChar(Core.PlayList.Entries.Items[Core.PlayList.PlayPos].FileName);
      ShellExecute(0, '', 'explorer', PChar('/e,/select, ' + sSelFile), '', SW_SHOW);
    end;

    LAC_PLAYLIST_DELETE_FILE: begin
      if (frmain.pnPlayList.Visible) then
        FileToDel := Core.PlayList.Entries.Items[frMain.PlayGrid.SelIndex].FileName
      else
        FileToDel := Core.PlayList.Entries.Items[Core.PlayList.PlayPos].FileName;

      with FileOp do begin
        Wnd := Application.Handle;
        wFunc := FO_DELETE;
        pFrom := PChar(FileToDel);
        pTo := nil;
        fFlags := FOF_ALLOWUNDO;
        fAnyOperationsAborted := False;
        hNameMappings := nil;
        lpszProgressTitle := nil;
      end;

      if FileToDel = frMain.LoadedFileName then begin
        fdLoadedFN := frMain.LoadedFileName;
        Center.ProcessCommand(LAC_PLAYBACK_REAL_STOP);
      end;

      if SHFileOperation(FileOp) = 0 then
        if not(FileExists(FileToDel)) then
          frMain.PlayGrid.Delete
      else
        if FileToDel = fdLoadedFN then
          Center.ProcessCommand(LAC_PLAYLIST_PLAY);
    end;

    LAC_PLAYLIST_MOVE_FILE:
      Core.AppLogic.PlayListMoveFile;
{=========================== SOUND ===================================}
    LAC_SOUND_MUTE: begin
      HoverButtons[hiMute].Down:=not(HoverButtons[hiMute].Down);
      Core.Prefs.WriteBool('FrontEnd.Mute',HoverButtons[hiMute].Down);
      SetVolume;
      Core.MdlMgr.SetSInt32('Audio.Mute',Ord(HoverButtons[hiMute].Down));
      if frAdvPList<>nil then
        with Advplist.frAdvPList.aMute do
          begin
            Checked := not(Checked);
            if Checked then ImageIndex:=22 else ImageIndex:=21;
          end;
    end;
    LAC_SOUND_VOLUME_INC: begin
      tbVolume.Position:=tbVolume.Position+5;
      if frAdvPList<>nil then
        frAdvPList.tbVol.Position:=tbVolume.Position;
    end;
    LAC_SOUND_VOLUME_DEC: begin
      tbVolume.Position:=tbVolume.Position-5;
      if frAdvPList<>nil then
        frAdvPList.tbVol.Position:=tbVolume.Position;
    end;
    LAC_SOUND_PROPERTIES:
      AudioProps;
    LAC_SOUND_ADD:
      AddSound;
    LAC_SOUND_SWITCH_STREAM:
      if Assigned(frMain.AudioModel) and not(IsURL) then
        frMain.AudioModel.SwitchStream;

{=========================== SUBTITLES ===================================}
    // Shift left/right.
    LAC_SUBTITLES_TS_INC:
    begin
      if Core.Subs.Sub1.IsEnabled then
      begin
        if iSubsShift0 < -9 then
          begin
            iSubsShift0:=-10;
            Exit;
          end;
        iSubsShift0 := iSubsShift0 - 1;
        Core.MdlMgr.SetSInt32('App.Subs.Shift0', Trunc(StrToFloat(IntToStr(iSubsShift0)) * 10));
        Core.Info(MS('OSD.SubtitleShift')+ ': ' + IntToStr(iSubsShift0));
      end;
    end;

    LAC_SUBTITLES_TS_DEC:
    begin
      if Core.Subs.Sub1.IsEnabled then
      begin
        if iSubsShift0 > 9 then
        begin
          iSubsShift0:=10;
          Exit;
        end;
        iSubsShift0 := iSubsShift0 + 1;
        Core.MdlMgr.SetSInt32('App.Subs.Shift0', Trunc(StrToFloat(IntToStr(iSubsShift0)) * 10));
        Core.Info(MS('OSD.SubtitleShift')+ ': ' + IntToStr(iSubsShift0));
      end;
    end;

    LAC_SUBTITLES_VPOS_INC:
    begin
      if Core.Subs.Sub1.IsEnabled then
      begin
        iSubsVPos0 := Core.MdlMgr.GetSInt32('App.Subs.VPos0');
        if iSubsVPos0 > 99 then
          begin
            iSubsVPos0:=100;
            exit;
          end;
            iSubsVPos0 := iSubsVPos0 + 1;
            Core.MdlMgr.SetSInt32('App.Subs.VPos0', iSubsVPos0);
            Core.Info(MS('OSD.SubtitleUpDown')+ ': ' + IntToStr(iSubsVPos0));
      end;
    end;

    LAC_SUBTITLES_VPOS_DEC:
    begin
      iSubsVPos0 := Core.MdlMgr.GetSInt32('App.Subs.VPos0');
      if Core.Subs.Sub1.IsEnabled then
      begin
        if iSubsVPos0 < 1 then
          begin
            iSubsVPos0:=0;
            Exit;
          end;
          iSubsVPos0 := iSubsVPos0 - 1;
          Core.MdlMgr.SetSInt32('App.Subs.VPos0', iSubsVPos0);
          Core.Info(MS('OSD.SubtitleUpDown')+ ': ' + IntToStr(iSubsVPos0));
      end;
    end;

    // Properties.
    LAC_SUBTITLES_PROPERTIES:
    begin
      if not(Assigned(frSubtitles)) then
        frSubtitles:=TfrSubtitles.Create(Application);
      PopupForm(frSubtitles);
    end;

    // Load.
    LAC_SUBTITLES_LOAD:
    begin
      if Assigned(Core.Subs) then
        Core.Subs.LoadSubtitles1;
    end;

    // Show.
    LAC_SUBTITLES_SHOW:
    begin
      if (pnSubs1.Visible) then
        Core.Subs.Disable
      else begin
        if Core.Subs.IsEmpty then
         begin
          if Assigned(Core.Subs) then
            Core.Subs.LoadSubtitles1;
          if not(Core.Subs.IsEmpty) then Core.Subs.Enable;
        end else
          Core.Subs.Enable;
      end;
    end;

    LAC_SUBTITLES_SWITCH_STREAM:
      if Assigned(Core.Subs) then Core.Subs.SwitchStream;
{=========================== DVD ===================================}
    LAC_DVD_PLAY_DISC:
      Core.AppLogic.PlayDVDDisc;
    LAC_DVD_OPEN_FOLDER:
      Core.AppLogic.PlayDVDfromHDD;
    LAC_DVD_MAIN_MENU:
      DSH.DVDMenu;
{=========================== APPLICATION ===================================}
    LAC_APPLICATION_PREFERENCES:
      Core.AppLogic.OnPrefs;
    LAC_APPLICATION_HELP:
      Core.AppLogic.OnHelp;
    LAC_APPLICATION_ABOUT:
      Core.AppLogic.About;
    LAC_APPLICATION_EXIT:
      Core.OnAppExit;
    LAC_APPLICATION_POWER_OFF:
      Core.AppLogic.OnShutdown;
    LAC_APPLICATION_HIBERNATE:
      Core.SysHlp.Hibernate;
    LAC_APPLICATION_MONITOR_OFF:
      Core.SysHlp.ToggleMonitorPower;
    //опция "hibernate по окончанию списка" для текущей сессии
    LAC_APPLICATION_HIB_ONPLDONE:
     begin
      SHibernateOnPlayListDone:=not(SHibernateOnPlayListDone);
      if SHibernateOnPlayListDone then
        begin
          SPlowerOffOnPlayListDone := false;
          Core.Info(MS('Command.457'))
        end
       else
        Core.Info(MS('Common.Cancel'));
    end;
    //опция "PowerOff по окончанию списка" для текущей сессии
    LAC_APPLICATION_POW_ONPLDONE:
     begin
      SPlowerOffOnPlayListDone:=not(SPlowerOffOnPlayListDone);
      if SPlowerOffOnPlayListDone then
        begin
          SHibernateOnPlayListDone := false;
          Core.Info(MS('Command.458'))
        end
      else
        Core.Info(MS('Common.Cancel'));
    end;
    LAC_APPLICATION_HIDEFROMBOSS: begin
      if (HideFromBoss = 0) or (HideFromBoss = 2) then
        HideFromBoss := 1  // hide
      else
        HideFromBoss := 2; // show
      ToggleMinimize;
    end;

  else
    Result:=FALSE;
  end;
end;

end.
