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
unit CmdC;

interface

uses
  Windows, Classes, SysUtils, MMKeys;

const
  LAC_CAT_NUMBER = 10;
  LAC_CAT_SIZE : array [0..LAC_CAT_NUMBER-1] of LongInt = (
    4,    // File
    6,    // Playback (must be -1 of real count to hide "Playback disk" command from Keyboard prefs)
    11,   // Seek
    8,    // Window
    21,   // Playlist
    22,   // Video
    8,    // Subtitles
    6,    // Sound
    9,    // App (must be -1 of real count to hide "anti-boss" command from Keyboard prefs)
    3);   // DVD

 // Note: playback section must ends on 'playback disk' command,
 // to hide it from keyboard preferences

 // Note: application section must ends on 'anti-boss' command,
 // to hide it from keyboard preferences

{$I LACmd.pas}

type
  TCommand = packed record
    LAC:LongInt;
    Key:String;
    WMsg:String;
    Enabled:Boolean;
  end;

  TWIRCCallBack = function(Msg:String):Boolean of object;

  TCommandCenter = class(TObject)
  public
    Commands:array of TCommand;
    Captured:boolean;
    FWIRCCB:TWIRCCallBack;

    constructor Create;
    destructor Destroy; override;

    procedure SetDefaultKeys;
    procedure SetBSPlayerKeys;
    procedure SetSasamiKeys;
    procedure SetZoomKeys;
    procedure SetWMPKeys;
    procedure SetKey(aLAC:longint;aKey,aWMsg:string);
    procedure Load;
    procedure Save;
    procedure Clear;

    function VirtualKeyName(Key:Word;Shift:TShiftState):string;

    procedure ProcessCommand(LAC:longint);
    procedure ProcessKey(Key:string);
    procedure ProcessWIRCMessage(Msg:string);

    function GetCommandKey(aLAC:longint):string;
    function GetCommandWMsg(aLAC:longint):string;
    function GetCommandName(aLAC:longint):string;
    function GetCategoryName(CmdCat:longint):string;

    function GetCommandID(aKey,aWMsg:string):longint;
    function ExtractCmdNum(Cmd:string):longint;
  end;

var
  Center:TCommandCenter;

implementation

uses
  MainUnit, LACore;

constructor TCommandCenter.Create;
begin
  inherited;
  SetLength(Commands,0);
  Load;
end;

procedure TCommandCenter.SetDefaultKeys;
begin
  Clear;
  SetKey(LAC_FILE_OPEN,           'F3','');
  SetKey(LAC_FILE_INFO,           'Ctrl+I','');
  SetKey(LAC_FILE_OSD_INFO,       'I','i');
  SetKey(LAC_FILE_OPENURL,        'U','');

  SetKey(LAC_PLAYBACK_REAL_STOP,  'Alt+Q','Stop'); //LAC_PLAYBACK_STOP
  SetKey(LAC_PLAYBACK_PLAY,       'X','Play');
  SetKey(LAC_PLAYBACK_STOP_PLAY,  'Space','Call');
  SetKey(LAC_PLAYBACK_SPEED_PLAY, 'Ctrl+X','');
  SetKey(LAC_PLAYBACK_FILTERS,    'F9','');
  SetKey(LAC_PLAYBACK_STOP,       'V','');
  SetKey(LAC_PLAYBACK_DISK,        '','');

  SetKey(LAC_SEEK_FRAME_STEP,     'Ctrl+Right','');
  SetKey(LAC_SEEK_FRAME_BACK,     'Ctrl+Left','');
  SetKey(LAC_SEEK_FORWARD,        'Right','>');
  SetKey(LAC_SEEK_BACKWARD,       'Left','<');
  SetKey(LAC_SEEK_JUMP_FORWARD,   'Shift+Right','>>');
  SetKey(LAC_SEEK_JUMP_BACKWARD,  'Shift+Left','<<');
  SetKey(LAC_SEEK_REWIND,         'BkSp','<-');
  SetKey(LAC_SEEK_SET_BOOKMARK,   'B','');
  SetKey(LAC_SEEK_SET_OE_OFFSET,  'O','');
  SetKey(LAC_SEEK_LAST_POS,       'L','');
  SetKey(LAC_SEEK_A_B,            'Alt+R','');

  SetKey(LAC_WINDOW_CONTROL_PANEL,'`','Menu');
  SetKey(LAC_WINDOW_PLAYLIST,     'P','-/-');
  SetKey(LAC_WINDOW_FULLSCREEN,   'Enter','Screen');
  SetKey(LAC_WINDOW_ORIGINAL,     'Home','->0<-');
  SetKey(LAC_WINDOW_STAY_ON_TOP,  'A','');
  SetKey(LAC_WINDOW_MINIMIZE,     'End','');
  SetKey(LAC_WINDOW_MAXIMIZE,     '','');
  SetKey(LAC_WINDOW_EX_PLAYLIST,  'Alt+P','');

  SetKey(LAC_PLAYLIST_NEXT,       'PageDown','Down');
  SetKey(LAC_PLAYLIST_PREV,       'PageUp','Up');
  SetKey(LAC_PLAYLIST_PLAY,       '','');
  SetKey(LAC_PLAYLIST_ADD_FILES,  'Insert','');
  SetKey(LAC_PLAYLIST_ADD_FOLDER, 'Shift+Insert','');
  SetKey(LAC_PLAYLIST_DELETE,     'Delete','');
  SetKey(LAC_PLAYLIST_CLEAR,      'Shift+Delete','');
  SetKey(LAC_PLAYLIST_SAVE,       'F2','');
  SetKey(LAC_PLAYLIST_MOVE_UP,    'Ctrl+Up','');
  SetKey(LAC_PLAYLIST_MOVE_DOWN,  'Ctrl+Down','');
  SetKey(LAC_PLAYLIST_SHUFFLE,    'Ctrl+S','');
  SetKey(LAC_PLAYLIST_SORT,       'Ctrl+Home','');
  SetKey(LAC_PLAYLIST_REPORT,     'Ctrl+R','');
  SetKey(LAC_PLAYLIST_REPEAT,     'R','');
  SetKey(LAC_PLAYLIST_REPEAT_FILE,'Shift+R','');
  SetKey(LAC_PLAYLIST_BOOKMARKS,  '\','');
  SetKey(LAC_PLAYLIST_JUMP,       'Ctrl+J','');
  SetKey(LAC_PLAYLIST_SEARCH_FILE, 'Ctrl+F', '');
  SetKey(LAC_PLAYLIST_DELETE_FILE, 'F8', ''); //Ctrl+Delete
  SetKey(LAC_PLAYLIST_VISUALSHUFFLE, 'Shift+V','');

  SetKey(LAC_VIDEO_PROPERTIES,     'Ctrl+V','');
  SetKey(LAC_VIDEO_SCREENSHOT,     'F12','');
  SetKey(LAC_VIDEO_CCLIPBOARD,     'Ctrl+F12','');
  SetKey(LAC_VIDEO_SCALE_50,       'Alt+1','');
  SetKey(LAC_VIDEO_SCALE_100,      'Alt+2','');
  SetKey(LAC_VIDEO_SCALE_200,      'Alt+3','');
  SetKey(LAC_VIDEO_RATIO_ASIS,     'Shift+1','');
  SetKey(LAC_VIDEO_RATIO_16_9,     'Shift+2','');
  SetKey(LAC_VIDEO_RATIO_4_3,      'Shift+3','');
  SetKey(LAC_VIDEO_RATIO_WIDTH,    'Shift+4','');
  SetKey(LAC_VIDEO_RATIO_HEIGHT,   'Shift+5','');
  SetKey(LAC_VIDEO_RATIO_CUSTOM,   'Shift+6','');
  SetKey(LAC_VIDEO_RATIO_FREE,     'Shift+7','');
  SetKey(LAC_VIDEO_ZOOM_IN,        '=','Z+');
  SetKey(LAC_VIDEO_ZOOM_OUT,       '-','Z-');
  SetKey(LAC_VIDEO_BRIGHTNESS_INC, 'NP+','BR+');
  SetKey(LAC_VIDEO_BRIGHTNESS_DEC, 'NP-','BR-');
  SetKey(LAC_VIDEO_CONTRAST_INC,   'Ctrl+NP+','CO+');
  SetKey(LAC_VIDEO_CONTRAST_DEC,   'Ctrl+NP-','CO-');
  SetKey(LAC_VIDEO_SATURATION_INC, 'Alt+NP+','SA+');
  SetKey(LAC_VIDEO_SATURATION_DEC, 'Alt+NP-','SA-');

  SetKey(LAC_SUBTITLES_LOAD,       'Alt+S','');
  SetKey(LAC_SUBTITLES_SHOW,       'S','');
  SetKey(LAC_SUBTITLES_PROPERTIES, 'Shift+S','');
  SetKey(LAC_SUBTITLES_SWITCH_STREAM,'Shift+/', '');  
  // Vpos.
  SetKey(LAC_SUBTITLES_VPOS_INC,   'Shift+Up', '');
  SetKey(LAC_SUBTITLES_VPOS_DEC,   'Shift+Down', '');
  // TS - TimeShift.
  SetKey(LAC_SUBTITLES_TS_INC,     'Ctrl+,', '');
  SetKey(LAC_SUBTITLES_TS_DEC,     'Ctrl+.', '');

  SetKey(LAC_SOUND_PROPERTIES,     'Ctrl+A','');
  SetKey(LAC_SOUND_VOLUME_INC,     'Up','V+');
  SetKey(LAC_SOUND_VOLUME_DEC,     'Down','V-');
  SetKey(LAC_SOUND_MUTE,           'Ctrl+M','');
  SetKey(LAC_SOUND_ADD,            'Alt+A','');
  SetKey(LAC_SOUND_SWITCH_STREAM,  '/','*');

  SetKey(LAC_APPLICATION_PREFERENCES, 'F10','');
  SetKey(LAC_APPLICATION_HELP,        'F1','');
  SetKey(LAC_APPLICATION_ABOUT,       'Ctrl+F1','');
  SetKey(LAC_APPLICATION_EXIT,        'Esc','Power');
  SetKey(LAC_APPLICATION_POWER_OFF,   '','');
  SetKey(LAC_APPLICATION_HIB_ONPLDONE,'H','');
  SetKey(LAC_APPLICATION_POW_ONPLDONE,'Ctrl+P','');

  SetKey(LAC_DVD_PLAY_DISC,        'F7','');
  SetKey(LAC_DVD_MAIN_MENU,        'M','');
  SetKey(LAC_DVD_OPEN_FOLDER,      'Alt+F3','')
end;

destructor TCommandCenter.Destroy;
begin
  inherited;
end;

procedure TCommandCenter.ProcessCommand;
begin
  PostMessage(frMain.Handle,WM_LACMD,LAC,0);
end;

procedure TCommandCenter.ProcessKey;
begin
  if Key <> '' then
    ProcessCommand(GetCommandID(Key,''));
end;

procedure TCommandCenter.ProcessWIRCMessage;
var
  Done:Boolean;
  LAC:LongInt;
begin
  Done:=FALSE;
  if (Assigned(FWIRCCB)) then Done:=FWIRCCB(Msg);
  if not(Done) then
  begin
    LAC:=GetCommandID('',Msg);
    if (LAC>=0) then
    begin
      ProcessCommand(LAC);
    end else begin
      if Core.Prefs.Bool['Modules.WinLIRC.ShowUnhandled'] then
        Core.Info('WinLIRC command: [ '+Msg+' ]');
    end;
  end;
end;

procedure TCommandCenter.SetKey;
var
  l,i:longint;
begin
  i:=-1;
  for l:=0 to Length(Commands)-1 do
    if (Commands[l].LAC=aLAC) then
      i:=l;
  if (i<0) then begin
    i:=Length(Commands);
    SetLength(Commands,i+1);
  end;
  with Commands[i] do begin
    LAC:=aLAC;
    Key:=aKey;
    WMsg:=aWMsg;
  end;
end;

function TCommandCenter.VirtualKeyName;
begin
  Result:='<'+IntToStr(Key)+'>';
  case Key of
                      0:Result:='';
                VK_BACK:Result:='BkSp';
                 VK_TAB:Result:='Tab';
               VK_CLEAR:Result:='Clear';
              VK_RETURN:Result:='Enter';
               VK_SHIFT:Result:='';
             VK_CONTROL:Result:='';
                VK_MENU:Result:=''; // Alt
               VK_PAUSE:Result:='Pause';
             VK_CAPITAL:Result:='CapsLock';
              VK_ESCAPE:Result:='Esc';
               VK_SPACE:Result:='Space';
               VK_PRIOR:Result:='PageUp';
                VK_NEXT:Result:='PageDown';
                 VK_END:Result:='End';
                VK_HOME:Result:='Home';
                VK_LEFT:Result:='Left';
                  VK_UP:Result:='Up';
               VK_RIGHT:Result:='Right';
                VK_DOWN:Result:='Down';
              VK_SELECT:Result:='Select';
               VK_PRINT:Result:='Print';
             VK_EXECUTE:Result:='Exec';
            VK_SNAPSHOT:Result:='PrintScreen';
              VK_INSERT:Result:='Insert';
              VK_DELETE:Result:='Delete';
                VK_HELP:Result:='Help';
               $30..$39:Result:=chr(Key);
               $41..$5A:Result:=chr(Key);
                VK_LWIN:Result:='LWin';
                VK_RWIN:Result:='RWin';
                VK_APPS:Result:='Apps'; // Second windows key
             VK_NUMPAD0:Result:='NP0';
             VK_NUMPAD1:Result:='NP1';
             VK_NUMPAD2:Result:='NP2';
             VK_NUMPAD3:Result:='NP3';
             VK_NUMPAD4:Result:='NP4';
             VK_NUMPAD5:Result:='NP5';
             VK_NUMPAD6:Result:='NP6';
             VK_NUMPAD7:Result:='NP7';
             VK_NUMPAD8:Result:='NP8';
             VK_NUMPAD9:Result:='NP9';
            VK_MULTIPLY:Result:='NP*';
                 VK_ADD:Result:='NP+';
           VK_SEPARATOR:Result:='NP sep';
            VK_SUBTRACT:Result:='NP-';
             VK_DECIMAL:Result:='NP.';
              VK_DIVIDE:Result:='NP/';
          VK_F1..VK_F12:Result:='F'+IntToStr(Key-VK_F1+1);
             VK_NUMLOCK:Result:='NumLock';
              VK_SCROLL:Result:='ScrollLock';

               VK_SLEEP:Result:='Sleep';

        VK_BROWSER_BACK:Result:='Back';
     VK_BROWSER_FORWARD:Result:='Forward';
     VK_BROWSER_REFRESH:Result:='Refresh';
        VK_BROWSER_STOP:Result:='Stop';
      VK_BROWSER_SEARCH:Result:='Search';
   VK_BROWSER_FAVORITES:Result:='Favorites';
        VK_BROWSER_HOME:Result:='Web/Home';

         VK_VOLUME_MUTE:Result:='Mute';
         VK_VOLUME_DOWN:Result:='Vol-';
           VK_VOLUME_UP:Result:='Vol+';

    VK_MEDIA_NEXT_TRACK:Result:='Next';
    VK_MEDIA_PREV_TRACK:Result:='Prev';
          VK_MEDIA_STOP:Result:='Stop';
    VK_MEDIA_PLAY_PAUSE:Result:='Play/Pause';

         VK_LAUNCH_MAIL:Result:='Mail';
 VK_LAUNCH_MEDIA_SELECT:Result:='Media';
         VK_LAUNCH_APP1:Result:='APP1';
         VK_LAUNCH_APP2:Result:='APP2';

               VK_OEM_1:Result:=';';
            VK_OEM_PLUS:Result:='=';
           VK_OEM_COMMA:Result:=',';
           VK_OEM_MINUS:Result:='-';
          VK_OEM_PERIOD:Result:='.';
               VK_OEM_2:Result:='/';
               VK_OEM_3:Result:='`';

                    219:Result:='[';
                    220:Result:='\';
                    221:Result:=']';
                    222:Result:='''';
                    226:Result:='Macro';
  end;
  if (ssShift in Shift) then Result:='Shift+'+Result;
  if (ssAlt in Shift) then Result:='Alt+'+Result;
  if (ssCtrl in Shift) then Result:='Ctrl+'+Result;
end;

function TCommandCenter.GetCommandName;
begin
  Result:=MS(Format('Command.%.3d',[aLAC]));
end;

function TCommandCenter.GetCommandWMsg;
var
  l:longint;
begin
  Result:='';
  for l:=0 to Length(Commands)-1 do
    if (Commands[l].LAC=aLAC) then
      Result:=Commands[l].WMsg;
end;

function TCommandCenter.GetCommandKey;
var
  l:longint;
begin
  Result:='';
  for l:=0 to Length(Commands)-1 do
    if (Commands[l].LAC=aLAC) then
      Result:=Commands[l].Key;
end;

function TCommandCenter.GetCommandID;
var
  l:longint;
begin
  Result:=-1;

  if (Commands <> nil) then
    for l:=0 to Length(Commands)-1 do
      begin
      if (aKey<>'') then
        if (AnsiUpperCase(Commands[l].Key)=AnsiUpperCase(aKey)) then
          Result:=Commands[l].LAC;
      if (aWMsg<>'') then
        if (AnsiUpperCase(Commands[l].WMsg)=AnsiUpperCase(aWMsg)) then
          Result:=Commands[l].LAC;
    end;
end;

procedure TCommandCenter.Save;
var
  l:longint;
begin
  for l:=0 to Length(Commands)-1 do
    with Commands[l] do
      Core.Prefs.WriteString(Format('Command.c%.3d',[LAC]),Key+'|'+WMsg);
end;

function TCommandCenter.GetCategoryName;
begin
  Result:=MS(Format('Command.Category.%d',[CmdCat]));
end;

procedure TCommandCenter.SetBSPlayerKeys;
begin
  Clear;
  SetKey(LAC_FILE_OPEN,           'L','');
  SetKey(LAC_FILE_INFO,           '','');

  SetKey(LAC_PLAYBACK_STOP,       'V','');
  SetKey(LAC_PLAYBACK_PLAY,       'X','');
  SetKey(LAC_PLAYBACK_STOP_PLAY,  'C','');
  SetKey(LAC_PLAYBACK_SPEED_PLAY, '','');
  SetKey(LAC_PLAYBACK_FILTERS,    '','');

  SetKey(LAC_SEEK_FRAME_STEP,     '','');
  SetKey(LAC_SEEK_FRAME_BACK,     '','');
  SetKey(LAC_SEEK_FORWARD,        'Right','');
  SetKey(LAC_SEEK_BACKWARD,       'Left','');
  SetKey(LAC_SEEK_JUMP_FORWARD,   '','');
  SetKey(LAC_SEEK_JUMP_BACKWARD,  '','');
  SetKey(LAC_SEEK_REWIND,         '','');
  SetKey(LAC_SEEK_SET_BOOKMARK,   'Alt+I','');

  SetKey(LAC_WINDOW_CONTROL_PANEL,'H','');
  SetKey(LAC_WINDOW_PLAYLIST,     'Alt+E','');
  SetKey(LAC_WINDOW_FULLSCREEN,   'F','');
  SetKey(LAC_WINDOW_ORIGINAL,     '5','');
  SetKey(LAC_WINDOW_STAY_ON_TOP,  'Ctrl+A','');
  SetKey(LAC_WINDOW_MINIMIZE,     '','');
  SetKey(LAC_WINDOW_MAXIMIZE,     '','');

  SetKey(LAC_PLAYLIST_NEXT,       'B','');
  SetKey(LAC_PLAYLIST_PREV,       'Z','');
  SetKey(LAC_PLAYLIST_PLAY,       '','');
  SetKey(LAC_PLAYLIST_ADD_FILES,  '','');
  SetKey(LAC_PLAYLIST_ADD_FOLDER, '','');
  SetKey(LAC_PLAYLIST_DELETE,     '','');
  SetKey(LAC_PLAYLIST_CLEAR,      '','');
  SetKey(LAC_PLAYLIST_SAVE,       '','');
  SetKey(LAC_PLAYLIST_MOVE_UP,    '','');
  SetKey(LAC_PLAYLIST_MOVE_DOWN,  '','');
  SetKey(LAC_PLAYLIST_SHUFFLE,    '','');
  SetKey(LAC_PLAYLIST_SORT,       '','');
  SetKey(LAC_PLAYLIST_REPORT,     '','');
  SetKey(LAC_PLAYLIST_REPEAT,     '','');
  SetKey(LAC_PLAYLIST_BOOKMARKS,  '','');

  SetKey(LAC_VIDEO_PROPERTIES,     '','');
  SetKey(LAC_VIDEO_SCREENSHOT,     'P','');
  SetKey(LAC_VIDEO_SCALE_50,       '1','');
  SetKey(LAC_VIDEO_SCALE_100,      '2','');
  SetKey(LAC_VIDEO_SCALE_200,      '3','');
  SetKey(LAC_VIDEO_RATIO_ASIS,     'Shift+1','');
  SetKey(LAC_VIDEO_RATIO_16_9,     'Shift+2','');
  SetKey(LAC_VIDEO_RATIO_4_3,      'Shift+3','');
  SetKey(LAC_VIDEO_RATIO_WIDTH,    '','');
  SetKey(LAC_VIDEO_RATIO_HEIGHT,   '','');
  SetKey(LAC_VIDEO_RATIO_CUSTOM,   '','');
  SetKey(LAC_VIDEO_RATIO_FREE,     '','');
  SetKey(LAC_VIDEO_ZOOM_IN,        '=','');
  SetKey(LAC_VIDEO_ZOOM_OUT,       '-','');
  SetKey(LAC_VIDEO_BRIGHTNESS_INC, '','');
  SetKey(LAC_VIDEO_BRIGHTNESS_DEC, '','');
  SetKey(LAC_VIDEO_CONTRAST_INC,   '','');
  SetKey(LAC_VIDEO_CONTRAST_DEC,   '','');
  SetKey(LAC_VIDEO_SATURATION_INC, '','');
  SetKey(LAC_VIDEO_SATURATION_DEC, '','');

  SetKey(LAC_SUBTITLES_LOAD,       'Ctrl+L','');
  SetKey(LAC_SUBTITLES_SHOW,       'S','');

  SetKey(LAC_SOUND_PROPERTIES,     '','');
  SetKey(LAC_SOUND_VOLUME_INC,     'Up','');
  SetKey(LAC_SOUND_VOLUME_DEC,     'Down','');
  SetKey(LAC_SOUND_MUTE,           'Ctrl+M','');

  SetKey(LAC_APPLICATION_PREFERENCES, 'Ctrl+P','');
  SetKey(LAC_APPLICATION_HELP,        '','');
  SetKey(LAC_APPLICATION_ABOUT,       '','');
  SetKey(LAC_APPLICATION_EXIT,        'Alt+F4','');
  SetKey(LAC_APPLICATION_POWER_OFF,   '','');
end;

procedure TCommandCenter.SetSasamiKeys;
begin
  Clear;
  SetKey(LAC_FILE_OPEN,           'Ctrl+O','');
  SetKey(LAC_FILE_INFO,           '','');

  SetKey(LAC_PLAYBACK_STOP,       '','');
  SetKey(LAC_PLAYBACK_PLAY,       'Ctrl+2','');
  SetKey(LAC_PLAYBACK_STOP_PLAY,  'Space','');
  SetKey(LAC_PLAYBACK_SPEED_PLAY, 'Ctrl+3','');
  SetKey(LAC_PLAYBACK_FILTERS,    '','');

  SetKey(LAC_SEEK_FRAME_STEP,     '','');
  SetKey(LAC_SEEK_FRAME_BACK,     '','');
  SetKey(LAC_SEEK_FORWARD,        'Right','');
  SetKey(LAC_SEEK_BACKWARD,       'Left','');
  SetKey(LAC_SEEK_JUMP_FORWARD,   '','');
  SetKey(LAC_SEEK_JUMP_BACKWARD,  '','');
  SetKey(LAC_SEEK_REWIND,         'Ctrl+Home','');
  SetKey(LAC_SEEK_SET_BOOKMARK,   '','');

  SetKey(LAC_WINDOW_CONTROL_PANEL,'','');
  SetKey(LAC_WINDOW_PLAYLIST,     '','');
  SetKey(LAC_WINDOW_FULLSCREEN,   'Alt+Enter','');
  SetKey(LAC_WINDOW_ORIGINAL,     '','');
  SetKey(LAC_WINDOW_STAY_ON_TOP,  'Ctrl+T','');
  SetKey(LAC_WINDOW_MINIMIZE,     '','');
  SetKey(LAC_WINDOW_MAXIMIZE,     '','');

  SetKey(LAC_PLAYLIST_NEXT,       'PageDown','');
  SetKey(LAC_PLAYLIST_PREV,       'PageUp','');
  SetKey(LAC_PLAYLIST_PLAY,       '','');
  SetKey(LAC_PLAYLIST_ADD_FILES,  'Insert','');
  SetKey(LAC_PLAYLIST_ADD_FOLDER, '','');
  SetKey(LAC_PLAYLIST_DELETE,     '','');
  SetKey(LAC_PLAYLIST_CLEAR,      '','');
  SetKey(LAC_PLAYLIST_SAVE,       '','');
  SetKey(LAC_PLAYLIST_MOVE_UP,    '','');
  SetKey(LAC_PLAYLIST_MOVE_DOWN,  '','');
  SetKey(LAC_PLAYLIST_SHUFFLE,    '','');
  SetKey(LAC_PLAYLIST_SORT,       '','');
  SetKey(LAC_PLAYLIST_REPORT,     '','');
  SetKey(LAC_PLAYLIST_REPEAT,     'R','');
  SetKey(LAC_PLAYLIST_BOOKMARKS,  '','');

  SetKey(LAC_VIDEO_PROPERTIES,     '','');
  SetKey(LAC_VIDEO_SCREENSHOT,     '','');
  SetKey(LAC_VIDEO_SCALE_50,       'Alt+1','');
  SetKey(LAC_VIDEO_SCALE_100,      'Alt+2','');
  SetKey(LAC_VIDEO_SCALE_200,      'Alt+3','');
  SetKey(LAC_VIDEO_RATIO_ASIS,     '','');
  SetKey(LAC_VIDEO_RATIO_16_9,     '','');
  SetKey(LAC_VIDEO_RATIO_4_3,      '','');
  SetKey(LAC_VIDEO_RATIO_WIDTH,    '','');
  SetKey(LAC_VIDEO_RATIO_HEIGHT,   '','');
  SetKey(LAC_VIDEO_RATIO_CUSTOM,   '','');
  SetKey(LAC_VIDEO_RATIO_FREE,     '','');
  SetKey(LAC_VIDEO_ZOOM_IN,        '','');
  SetKey(LAC_VIDEO_ZOOM_OUT,       '','');
  SetKey(LAC_VIDEO_BRIGHTNESS_INC, '','');
  SetKey(LAC_VIDEO_BRIGHTNESS_DEC, '','');
  SetKey(LAC_VIDEO_CONTRAST_INC,   '','');
  SetKey(LAC_VIDEO_CONTRAST_DEC,   '','');
  SetKey(LAC_VIDEO_SATURATION_INC, '','');
  SetKey(LAC_VIDEO_SATURATION_DEC, '','');

  SetKey(LAC_SUBTITLES_LOAD,       'Alt+O','');
  SetKey(LAC_SUBTITLES_SHOW,       '','');

  SetKey(LAC_SOUND_PROPERTIES,     '','');
  SetKey(LAC_SOUND_VOLUME_INC,     '','');
  SetKey(LAC_SOUND_VOLUME_DEC,     '','');
  SetKey(LAC_SOUND_MUTE,           'Ctrl+End','');

  SetKey(LAC_APPLICATION_PREFERENCES, 'Ctrl+P','');
  SetKey(LAC_APPLICATION_HELP,        '','');
  SetKey(LAC_APPLICATION_ABOUT,       '','');
  SetKey(LAC_APPLICATION_EXIT,        'Alt+F4','');
  SetKey(LAC_APPLICATION_POWER_OFF,   '','');
end;

procedure TCommandCenter.SetWMPKeys;
begin
  Clear;
  SetKey(LAC_FILE_OPEN,           'Ctrl+O','');
  SetKey(LAC_FILE_INFO,           '','');

  SetKey(LAC_PLAYBACK_STOP,       '.','');
  SetKey(LAC_PLAYBACK_PLAY,       '','');
  SetKey(LAC_PLAYBACK_STOP_PLAY,  'Space','');
  SetKey(LAC_PLAYBACK_SPEED_PLAY, 'Ctrl+Right','');
  SetKey(LAC_PLAYBACK_FILTERS,    '','');

  SetKey(LAC_SEEK_FRAME_STEP,     '','');
  SetKey(LAC_SEEK_FRAME_BACK,     '','');
  SetKey(LAC_SEEK_FORWARD,        'PageDown','');
  SetKey(LAC_SEEK_BACKWARD,       'PageUp','');
  SetKey(LAC_SEEK_JUMP_FORWARD,   '','');
  SetKey(LAC_SEEK_JUMP_BACKWARD,  '','');
  SetKey(LAC_SEEK_REWIND,         'Ctrl+Left','');
  SetKey(LAC_SEEK_SET_BOOKMARK,   '','');

  SetKey(LAC_WINDOW_CONTROL_PANEL,'','');
  SetKey(LAC_WINDOW_PLAYLIST,     '','');
  SetKey(LAC_WINDOW_FULLSCREEN,   'Alt+Enter','');
  SetKey(LAC_WINDOW_ORIGINAL,     '','');
  SetKey(LAC_WINDOW_STAY_ON_TOP,  'Ctrl+T','');
  SetKey(LAC_WINDOW_MINIMIZE,     '','');
  SetKey(LAC_WINDOW_MAXIMIZE,     '','');

  SetKey(LAC_PLAYLIST_NEXT,       'Alt+Right','');
  SetKey(LAC_PLAYLIST_PREV,       'Alt+Left','');
  SetKey(LAC_PLAYLIST_PLAY,       '','');
  SetKey(LAC_PLAYLIST_ADD_FILES,  '','');
  SetKey(LAC_PLAYLIST_ADD_FOLDER, '','');
  SetKey(LAC_PLAYLIST_DELETE,     '','');
  SetKey(LAC_PLAYLIST_CLEAR,      '','');
  SetKey(LAC_PLAYLIST_SAVE,       '','');
  SetKey(LAC_PLAYLIST_MOVE_UP,    '','');
  SetKey(LAC_PLAYLIST_MOVE_DOWN,  '','');
  SetKey(LAC_PLAYLIST_SHUFFLE,    '','');
  SetKey(LAC_PLAYLIST_SORT,       '','');
  SetKey(LAC_PLAYLIST_REPORT,     '','');
  SetKey(LAC_PLAYLIST_REPEAT,     '','');
  SetKey(LAC_PLAYLIST_BOOKMARKS,  '','');

  SetKey(LAC_VIDEO_PROPERTIES,     '','');
  SetKey(LAC_VIDEO_SCREENSHOT,     '','');
  SetKey(LAC_VIDEO_SCALE_50,       'Alt+1','');
  SetKey(LAC_VIDEO_SCALE_100,      'Alt+2','');
  SetKey(LAC_VIDEO_SCALE_200,      'Alt+3','');
  SetKey(LAC_VIDEO_RATIO_ASIS,     '','');
  SetKey(LAC_VIDEO_RATIO_16_9,     '','');
  SetKey(LAC_VIDEO_RATIO_4_3,      '','');
  SetKey(LAC_VIDEO_RATIO_WIDTH,    '','');
  SetKey(LAC_VIDEO_RATIO_HEIGHT,   '','');
  SetKey(LAC_VIDEO_RATIO_CUSTOM,   '','');
  SetKey(LAC_VIDEO_RATIO_FREE,     '','');
  SetKey(LAC_VIDEO_ZOOM_IN,        '','');
  SetKey(LAC_VIDEO_ZOOM_OUT,       '','');
  SetKey(LAC_VIDEO_BRIGHTNESS_INC, '','');
  SetKey(LAC_VIDEO_BRIGHTNESS_DEC, '','');
  SetKey(LAC_VIDEO_CONTRAST_INC,   '','');
  SetKey(LAC_VIDEO_CONTRAST_DEC,   '','');
  SetKey(LAC_VIDEO_SATURATION_INC, '','');
  SetKey(LAC_VIDEO_SATURATION_DEC, '','');

  SetKey(LAC_SUBTITLES_LOAD,       '','');
  SetKey(LAC_SUBTITLES_SHOW,       '','');

  SetKey(LAC_SOUND_PROPERTIES,     '','');
  SetKey(LAC_SOUND_VOLUME_INC,     'Up','');
  SetKey(LAC_SOUND_VOLUME_DEC,     'Down','');
  SetKey(LAC_SOUND_MUTE,           'Ctrl+M','');

  SetKey(LAC_APPLICATION_PREFERENCES, '','');
  SetKey(LAC_APPLICATION_HELP,        '','');
  SetKey(LAC_APPLICATION_ABOUT,       '','');
  SetKey(LAC_APPLICATION_EXIT,        'Alt+F4','');
  SetKey(LAC_APPLICATION_POWER_OFF,   '','');
end;

procedure TCommandCenter.SetZoomKeys;
begin
  Clear;
  SetKey(LAC_FILE_OPEN,           'O','');
  SetKey(LAC_FILE_INFO,           'I','');

  SetKey(LAC_PLAYBACK_STOP,       'A','');
  SetKey(LAC_PLAYBACK_PLAY,       '','');
  SetKey(LAC_PLAYBACK_STOP_PLAY,  'P','');
  SetKey(LAC_PLAYBACK_SPEED_PLAY, 'F','');
  SetKey(LAC_PLAYBACK_FILTERS,    '','');

  SetKey(LAC_SEEK_FRAME_STEP,     'Shift+.','');
  SetKey(LAC_SEEK_FRAME_BACK,     'Shift+,','');
  SetKey(LAC_SEEK_FORWARD,        '.','');
  SetKey(LAC_SEEK_BACKWARD,       ',','');
  SetKey(LAC_SEEK_JUMP_FORWARD,   'Alt+.','');
  SetKey(LAC_SEEK_JUMP_BACKWARD,  'Alt+,','');
  SetKey(LAC_SEEK_REWIND,         'W','');
  SetKey(LAC_SEEK_SET_BOOKMARK,   '','');

  SetKey(LAC_WINDOW_CONTROL_PANEL,'Alt+Space','');
  SetKey(LAC_WINDOW_PLAYLIST,     'Alt+L','');
  SetKey(LAC_WINDOW_FULLSCREEN,   '','');
  SetKey(LAC_WINDOW_ORIGINAL,     '`','');
  SetKey(LAC_WINDOW_STAY_ON_TOP,  'Alt+T','');
  SetKey(LAC_WINDOW_MINIMIZE,     '','');
  SetKey(LAC_WINDOW_MAXIMIZE,     '','');

  SetKey(LAC_PLAYLIST_NEXT,       ']','');
  SetKey(LAC_PLAYLIST_PREV,       '[','');
  SetKey(LAC_PLAYLIST_PLAY,       '','');
  SetKey(LAC_PLAYLIST_ADD_FILES,  '','');
  SetKey(LAC_PLAYLIST_ADD_FOLDER, 'Alt+D','');
  SetKey(LAC_PLAYLIST_DELETE,     '','');
  SetKey(LAC_PLAYLIST_CLEAR,      '','');
  SetKey(LAC_PLAYLIST_SAVE,       'Alt+C','');
  SetKey(LAC_PLAYLIST_MOVE_UP,    '','');
  SetKey(LAC_PLAYLIST_MOVE_DOWN,  '','');
  SetKey(LAC_PLAYLIST_SHUFFLE,    'Ctrl+R','');
  SetKey(LAC_PLAYLIST_SORT,       '','');
  SetKey(LAC_PLAYLIST_REPORT,     '','');
  SetKey(LAC_PLAYLIST_REPEAT,     'Alt+P','');
  SetKey(LAC_PLAYLIST_BOOKMARKS,  'B','');

  SetKey(LAC_VIDEO_PROPERTIES,     'D','');
  SetKey(LAC_VIDEO_SCREENSHOT,     'Alt+F','');
  SetKey(LAC_VIDEO_SCALE_50,       '','');
  SetKey(LAC_VIDEO_SCALE_100,      'Alt+2','');
  SetKey(LAC_VIDEO_SCALE_200,      'Alt+3','');
  SetKey(LAC_VIDEO_RATIO_ASIS,     '','');
  SetKey(LAC_VIDEO_RATIO_16_9,     '','');
  SetKey(LAC_VIDEO_RATIO_4_3,      '','');
  SetKey(LAC_VIDEO_RATIO_WIDTH,    '','');
  SetKey(LAC_VIDEO_RATIO_HEIGHT,   '','');
  SetKey(LAC_VIDEO_RATIO_CUSTOM,   '','');
  SetKey(LAC_VIDEO_RATIO_FREE,     '','');
  SetKey(LAC_VIDEO_ZOOM_IN,        '+','');
  SetKey(LAC_VIDEO_ZOOM_OUT,       '-','');
  SetKey(LAC_VIDEO_BRIGHTNESS_INC, 'Alt+F5','');
  SetKey(LAC_VIDEO_BRIGHTNESS_DEC, 'Ctrl+F5','');
  SetKey(LAC_VIDEO_CONTRAST_INC,   'Alt+F6','');
  SetKey(LAC_VIDEO_CONTRAST_DEC,   'Ctrl+F6','');
  SetKey(LAC_VIDEO_SATURATION_INC, '','');
  SetKey(LAC_VIDEO_SATURATION_DEC, '','');

  SetKey(LAC_SUBTITLES_LOAD,       '','');
  SetKey(LAC_SUBTITLES_SHOW,       'Shift+B','');

  SetKey(LAC_SOUND_PROPERTIES,     'Shift+A','');
  SetKey(LAC_SOUND_VOLUME_INC,     'Shift+Home','');
  SetKey(LAC_SOUND_VOLUME_DEC,     'Shift+End','');
  SetKey(LAC_SOUND_MUTE,           'Ctrl+M','');

  SetKey(LAC_APPLICATION_PREFERENCES, 'Ctrl+O','');
  SetKey(LAC_APPLICATION_HELP,        '','');
  SetKey(LAC_APPLICATION_ABOUT,       '','');
  SetKey(LAC_APPLICATION_EXIT,        'Alt+X','');
  SetKey(LAC_APPLICATION_POWER_OFF,   '','');
end;

procedure TCommandCenter.Load;
var
  CmdCat,LAC,Org,l:longint;
  PrefStr,Key,WMsg:string;
begin
  for CmdCat:=0 to LAC_CAT_NUMBER-1 do begin
    Org:=(CmdCat+1)*50;
    for LAC:=Org to (Org+LAC_CAT_SIZE[CmdCat]-1) do begin
      PrefStr:=Core.Prefs.ReadString(Format('Command.c%.3d',[LAC]));
      l:=Pos('|',PrefStr);
      if (l=0) then begin
        Key:=PrefStr;
        WMsg:='';
      end else begin
        Key:=Copy(PrefStr,1,l-1);
        WMsg:=Copy(PrefStr,l+1,Length(PrefStr));
      end;
      SetKey(LAC,Key,WMsg);
    end;
  end;
end;

procedure TCommandCenter.Clear;
var
  CmdCat,LAC,org:longint;
begin
  for CmdCat:=0 to LAC_CAT_NUMBER-1 do
    begin
    org:=(CmdCat+1)*50;
    for LAC:=org to (org+LAC_CAT_SIZE[CmdCat]-1) do
      SetKey(LAC,'','');
    end;
end;

function TCommandCenter.ExtractCmdNum;
begin
  Result:=StrToInt(Copy(Cmd,2,Length(Cmd)-1));
end;

end.
