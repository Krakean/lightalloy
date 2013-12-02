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

unit OtherGlobalVars;

interface

uses
  Windows, XML;

var
  PLAddMethod: Byte;
  Home_onlyBtn: boolean = false;
  isMediaReloadNeeded: Boolean = false;
  ItWasPausedBeforeNMR: Boolean = false;
  isShuffleActivated: Boolean = false;
  Separator: ShortString;
  NoLogging: Boolean = false;
  OpeningSeekPos, EndingSeekPos: int64;
  bTrayIconVisible: Boolean = false;
  SDDialogCreated: Boolean = false;
  LogEnabled: Boolean = false;
  IsDIVX: Boolean = false;
  i64PreviousPos: Int64 = 0;
  InfoHided: Boolean = true;
  trayClicked: Boolean = false;
  DisableConfigPageTimer: Boolean = false;
  playStateToMinimize: Boolean = false;
  DisableGlobalKeys: Boolean = false;
  NeedAppReload: Boolean = false;
  hoverCPanel: Boolean = false;
  originMinimizeActivate: Boolean = false;
  DisableMouseHide: Boolean = false;
  ThemeActive: Boolean = false;
  FullScreenMode: Boolean;
  SHibernateOnPlayListDone: Boolean = false;
  SPlowerOffOnPlayListDone: Boolean = false;

  //For non Reload
  AlreadyTrayUsed: Boolean = False;

  // anti-boss
  hideFromBoss: Word = 0;
  vis_frAudioProps, vis_frVideoProps, vis_frSubtitles,
  vis_frconfig, vis_frfilters, vis_frAdvPList, vis_frJumpToFile,
  vis_frInfo, vis_frFilter, vis_frError, vis_frDVDProps, vis_frOpenURL,
  vis_frDVDCodec, vis_frCodecs, vis_frCD, vis_frAlert, vis_frAbout: Boolean;

  // Subs.
  iSubsShift0: Integer = 0;
  iSubsVPos0: Integer = 0;

  // Seek_Lat_Pos
  X2: TXMLNode;
  Fn2, File2Hash64k: String;

  // Seek_A_B
  Seek_A: INT64;
  Seek_B: INT64;
  Seek_C: INT64;
  Seek_A_B : Integer = 0;

  // Online streams
  IsURL: Boolean = FALSE;

  // Biikmarks
  CurBmk: Integer = -1;
  NewBmk: Integer = 0;

  // Filters downloading states
  IsDownloading: Boolean = False;
  DownloadProgress: Byte = 0;
  DownloadFilter: String;
  DownloadFileName: String;
  IsReloaded: Boolean = False;
  TerminateDownloading: Boolean = False;
  SessionFails: Boolean = False;

  // Report
  TotalSize: Int64;
  TotalDuration: Int64;
  LastUpdate: ShortString;

  // Additional state control
  IsStopping: Boolean = False;

  function TopPosition(hWin: HWND; Top: Boolean): BOOL;

implementation

function TopPosition(hWin: HWND; Top: Boolean): BOOL;
begin
  if Top then
    Result := SetWindowPos(hWin, HWND_TOPMOST, 0, 0, 0, 0,SWP_NOACTIVATE or SWP_NOMOVE or SWP_NOSIZE)
  else
    Result := SetWindowPos(hWin, HWND_NOTOPMOST, 0, 0, 0, 0,SWP_NOACTIVATE or SWP_NOMOVE or SWP_NOSIZE);
end;

end.


