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
unit uWinAMP;

interface

uses
  Classes, Windows, SysUtils, Forms, Messages;

type
  PWinAMPGeneralPurposePlugin = ^TWinAMPGeneralPurposePlugin;
  TWinAMPGeneralPurposePlugin = packed record
    Version:integer;
    Description:PChar;
    Init:function:integer;
    Config:procedure;
    Quit:procedure;
    hwndParent:HWND;
    hDllInstance:THandle;
  end;

  TWinAMP = class
    Instance:THandle;
    BridgeHandle:HWND;
    WAPlugs:array of PWinAMPGeneralPurposePlugin;
    SavedWndProc:DWORD;

    constructor Create;
    destructor Destroy; override;

    procedure LoadGeneralPlugins;
    procedure FreeGeneralPlugins;

    procedure FillGeneralPluginList(List:TStrings);
    procedure GeneralConfig(Index:longint);
    procedure CreateBridge;
  end;

var
  WinAMP:TWinAMP;

implementation

uses
  LACore, MainUnit, CmdC;

function WindowProc(hWnd,Msg,wParam,lParam:Longint):longint;stdcall;
begin
  Result:=DefWindowProc(hWnd,Msg,wParam,lParam);

  case Msg of
    WM_USER:begin
      case lParam of
          0:Result:=$2000; // IPC_GETVERSION
        102:Center.ProcessCommand(LAC_PLAYBACK_PLAY); // IPC_STARTPLAY
        104: // IPC_ISPLAYING
            case frMain.State of
               stPlay:Result:=1;
              stPause:Result:=3;
            else
              Result:=0
            end;
        105: // IPC_GETOUTPUTTIME // position/duration
            if (Core.DSH<>nil) then
              if wParam = 0 then
                Result:=longint(Core.DSH.Position)
              else
                Result:=longint(Core.DSH.Duration);
        122:Core.SetVolume(wParam div 255 * 100); // IPC_SETVOLUME
        125:Result:=Core.PlayList.PlayPos;  // IPC_GETLISTPOS
        126: // IPC_GETINFO
            begin
              if (Core.DSH=nil) or (Core.Player=nil) then Exit;
              if not(Core.DSH.HasAudio) then Exit;

              case wParam of
                0: Result:=Longint(Core.Player.MI.FInfo.AStreams[0].Frequency);
                1: Result:=Longint(Core.Player.MI.FInfo.AStreams[0].BitRate);
                2: Result:=Longint(Core.Player.MI.FInfo.AStreams[0].Channels);
              end;
            end;
        211: // IPC_GETPLAYLISTFILE
            if frMain.State=stPlay then
            Result:=longint(pointer(Core.PlayList.Entries.Items[Core.PlayList.PlayPos].FileName));
        212: // IPC_GETPLAYLISTTITLE
            if frMain.State=stPlay then
            Result:=longint(pointer(Core.PlayList.Entries.Items[Core.PlayList.PlayPos].Title));
      end;
    end;
    WM_COMMAND:begin
      case wParam of
        40001:Center.ProcessCommand(LAC_APPLICATION_EXIT);        // WINAMP_FILE_QUIT
        40012:Center.ProcessCommand(LAC_APPLICATION_PREFERENCES); // WINAMP_OPTIONS_PREFS
        40019:Center.ProcessCommand(LAC_WINDOW_STAY_ON_TOP);      // WINAMP_OPTIONS_AOT
        40022:Center.ProcessCommand(LAC_PLAYLIST_REPEAT);         // WINAMP_FILE_REPEAT
        40023:Center.ProcessCommand(LAC_PLAYLIST_SHUFFLE);        // WINAMP_FILE_SHUFFLE
        40029:Center.ProcessCommand(LAC_FILE_OPEN);               // WINAMP_FILE_PLAY
        40040:Center.ProcessCommand(LAC_WINDOW_PLAYLIST);         // WINAMP_OPTIONS_PLEDIT
        40041:Center.ProcessCommand(LAC_APPLICATION_ABOUT);       // WINAMP_HELP_ABOUT
        40044:Center.ProcessCommand(LAC_PLAYLIST_PREV);           // WINAMP_BUTTON1
        40045:Center.ProcessCommand(LAC_PLAYBACK_PLAY);           // WINAMP_BUTTON2
        40046:Center.ProcessCommand(LAC_PLAYBACK_STOP);           // WINAMP_BUTTON3
        40047:  // WINAMP_BUTTON4
          begin
          Center.ProcessCommand(LAC_PLAYBACK_STOP);
          Center.ProcessCommand(LAC_SEEK_REWIND);
          end;
        40048:Center.ProcessCommand(LAC_PLAYLIST_NEXT);           // WINAMP_BUTTON5
        40058:Center.ProcessCommand(LAC_SOUND_VOLUME_INC);        // WINAMP_VOLUMEUP
        40059:Center.ProcessCommand(LAC_SOUND_VOLUME_DEC);        // WINAMP_VOLUMEDOWN
        40060:Center.ProcessCommand(LAC_SEEK_FORWARD);            // WINAMP_FFWD5S
        40061:Center.ProcessCommand(LAC_SEEK_BACKWARD);           // WINAMP_REW5S

        40144:Center.ProcessCommand(LAC_SEEK_BACKWARD);           // WINAMP_FREWIND
        40148:Center.ProcessCommand(LAC_SEEK_FORWARD);            // WINAMP_FFORWARD

        40184:Center.ProcessCommand(LAC_PLAYLIST_PLAY);           // IDC_PLAYLIST_PLAY
        40188:Center.ProcessCommand(LAC_FILE_OSD_INFO);
        40195:Center.ProcessCommand(LAC_SEEK_JUMP_FORWARD);       // WINAMP_JUMP10FWD
        40197:Center.ProcessCommand(LAC_SEEK_JUMP_BACKWARD);      // WINAMP_JUMP10BACK
        40258:Center.ProcessCommand(LAC_WINDOW_MINIMIZE);
      end;
    end;
  end; // case Msg
end;

constructor TWinAMP.Create;
begin
  inherited;
  SetLength(WAPlugs,0);
  CreateBridge;
end;

procedure TWinAMP.CreateBridge;
var
  wClass:TWndClass;
begin
  Instance:=GetModuleHandle(NIL);

  with wClass do begin
    Style:=CS_PARENTDC;
    lpfnWndProc:=@WindowProc;
    cbClsExtra:=0;
    cbWndExtra:=0;
    hInstance:=Instance;
    hIcon:=LoadIcon(Instance,'MAINICON');
    hCursor:=LoadCursor(0,IDC_ARROW);
    hbrBackground:=COLOR_BTNFACE+1;
    lpszMenuName:=NIL;
    lpszClassName:='WA2LA';
    if Core.Prefs.ReadBool('WinAMP.Emulate') then
      lpszClassName:='Winamp v1.x';
  end;
  RegisterClass(wClass);

  BridgeHandle:=CreateWindow(wClass.lpszClassName,'WA2LA bridge',
    0 {or WS_VISIBLE} {or WS_SIZEBOX} {or WS_SYSMENU},
    -100,-100,10,10,Application.Handle,0,Instance,NIL);
end;

destructor TWinAMP.Destroy;
begin
  SetLength(WAPlugs,0);
  DestroyWindow(BridgeHandle);
  UnRegisterClass('Winamp v1.x',Instance);
  inherited Destroy;
end;

procedure TWinAMP.FillGeneralPluginList;
var
  l:longint;
begin
  List.Clear;
  for l:=0 to Length(WAPlugs)-1 do
    List.Add(WAPlugs[l]^.Description);
end;

procedure TWinAMP.FreeGeneralPlugins;
var
  l:longint;
begin
  for l:=(Length(WAPlugs)-1) downto 0 do begin
    WAPlugs[l]^.Quit();
  end;
  SetWindowLong(BridgeHandle,GWL_WNDPROC,SavedWndProc);

  for l:=(Length(WAPlugs)-1) downto 0 do begin
    FreeLibrary(WAPlugs[l]^.hDllInstance);
  end;
  SetLength(WAPlugs,0);
end;

procedure TWinAMP.GeneralConfig;
begin
  if (Index>=0) and (Index<Length(WAPlugs)) then
    WAPlugs[Index]^.Config();
end;

procedure TWinAMP.LoadGeneralPlugins;
var
  l:longint;
  GetPlugin:function:PWinAMPGeneralPurposePlugin;
  SR:TSearchRec;
  Found:longint;
  Plugin:PWinAMPGeneralPurposePlugin;
  DLL:THandle;
begin
  SavedWndProc:=GetWindowLong(BridgeHandle,GWL_WNDPROC);

  Found:=FindFirst(ExtractFilePath(Application.ExeName)+'WinAMP\*.DLL',faAnyfile,SR);
  while (Found=0) do
    begin
    DLL:=LoadLibrary(PChar(ExtractFilePath(Application.ExeName)+'WinAMP\'+SR.Name));
    if (DLL<>0) then
      begin
      GetPlugin:=GetProcAddress(DLL,'winampGetGeneralPurposePlugin');
      if Assigned(GetPlugin) then begin
          Plugin:=GetPlugin();
          if (Plugin^.Version=$10) then begin
            l:=Length(WAPlugs);
            SetLength(WAPlugs,l+1);
            WAPlugs[l]:=Plugin;
            WAPlugs[l]^.hDllInstance:=DLL;
            WAPlugs[l]^.hwndParent:=BridgeHandle;
            WAPlugs[l]^.Init();
          end
        else begin
          FreeLibrary(DLL);
        end;
      end
      else
        FreeLibrary(DLL);
      end;
      Found:=FindNext(SR);
    end;
  FindClose(SR);
end;

end.
