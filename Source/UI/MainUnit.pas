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
unit MainUnit;

interface

uses
  Windows, Classes, Messages, SysUtils,
  Forms, Dialogs, Controls, Graphics, XPMan,

  ComCtrls, ExtCtrls, Buttons,
  Registry, Menus, Jpeg, GdipGraphic,

  ActiveX, ShellAPI, MMSystem,

  HoverBT, BrandCtl, BrandBrd, OSDPanel, FullPopupMenu,
  AudioPropsModel, VideoPropsModel, VideoProps, AudioProps,
  OptiBuilder, OptiPanel, OptiImgUtils, EQMdl, DAMdl,

  DVDProps, ColorSpace,
  CachedFile, PlayGrid, MMKeys, VideoPanel, IdComponent,

  PlayList, OtherGlobalVars, AppEvnts, ClipBrd;

const
  MinWidth     = 380;
  MinHeight    = 260;
  InitWidth    = 380;
  InitHeight   = 320;

  HookHandle: hHook = 0;
  LLKHF_ALTDOWN  = KF_ALTDOWN shr 8;
  WH_KEYBOARD_LL = 13;

  WM_LATRAY = WM_APP + 0;
  WM_LACMD  = WM_APP + 2504;
  ALERT_MESSAGE = WM_USER + 100;

  // 3.1.5383 = 2248 lines

type
  KBDLLHOOKSTRUCT = record
    vkCode: DWORD;
    scanCode: DWORD;
    flags: DWORD;
    time: DWORD;
    dwExtraInfo:Pointer;
  end;
  PKBDLLHOOKSTRUCT = ^KBDLLHOOKSTRUCT;
  TPMsg = ^TMsg;

  THButtonId =
    (hiEject,hiStop,hiFrameStep,hiPlay,hiSpeedPlay,
     hiFullScreen,hiOriginal,
     hiPrev,hiPlayList,hiNext,
     hiMute,hiAudioDec,
     hiVideoDec,hiScreenShot,hiSubtitles,
     hiFilters,hiConfig,hiInfo,
     hiPLPlay,hiRepeat, hiAddFiles,hiAddFolder,
     hiDel,hiClear,
     hiPLUp,hiPLDown,
     hiRandom,hiPLReport,
     hiTree,hiPLSave,
     hiCapAbout,
     hiCapStayOnTop,hiCapMinimize,hiCapMaximize,hiCapExit);
  TState = (stOff,stPlay,stPause,stSpeedPlay);
  TMouseAction = (maNone,maMoveWindow,maMoveMovie,maZoomMovie);

  TfrMain = class(TForm)
    pnControl:TPanel;
    pnStandard:TPanel;
    pnAdvanced:TPanel;
    spPlayList:TSplitter;
    pnPlayList:TPanel;
    pnPlayListBottom:TPanel;
    Timer:TTimer;
    OpenDialog:TOpenDialog;
    sdPLSave: TSaveDialog;

    procedure FormCreate(Sender:TObject);
    procedure FormDestroy(Sender:TObject);

    procedure FormCanResize(Sender:TObject;var NewWidth,NewHeight:Integer;var Resize:Boolean);
    procedure FormKeyDown(Sender:TObject;var Key:Word;Shift:TShiftState);

    procedure pnControlMouseDown(Sender:TObject;Button:TMouseButton;Shift:TShiftState;X,Y:Integer);
    procedure pnControlMouseUp(Sender:TObject;Button:TMouseButton;Shift:TShiftState;X,Y:Integer);

    procedure pnMovieMouseDown(Sender:TObject;Button:TMouseButton;Shift:TShiftState;X,Y:Integer);
    procedure pnMovieMouseMove(Sender:TObject;Shift:TShiftState;X,Y:Integer);
    procedure pnMovieMouseUp(Sender:TObject;Button:TMouseButton;Shift:TShiftState;X,Y:Integer);
    procedure pnMovieDblClick(Sender:TObject);
    procedure pnMovieResize(Sender:TObject);
    procedure TimerTimer(Sender:TObject);
    procedure FormResize(Sender: TObject);
  protected
    procedure CreateParams(var Params:TCreateParams); override;
    procedure OnWMHitTest(var Msg:TMessage); message WM_NCHITTEST;
    procedure CheckMousePos;
  private
    Minimized: Boolean;
    Restored: Boolean;
    BrandBorder:TBrandBorder;
    MovieDblClick:Boolean;

    procedure OnSubsPos;
    procedure OnEraseBG(var Msg:TMessage); message WM_ERASEBKGND;
    procedure ApplyCmdParams;
    procedure ScreenSaverSwitchOff;
    procedure OnSysCommand(var Msg: TMessage); message WM_SYSCOMMAND;
    procedure OnAppMessage(var Msg: TMsg; var Handled: Boolean);
    procedure OnAppMinimize(Sender: TObject);
    procedure OnAppRestore(Sender: Tobject);
  public
    bActive: Boolean;
    PostponedPlay:Boolean;
    State:TState;

    LACaption:TLACaption;
    pnVideo:TVideoPanel;
    PlayGrid:TPlayGrid;
    tbPos:TTimeTrackBar;
    tbVolume:TVolumeTrackBar;
    TimeBar:TTimeBar;
    PosBar:TPosBar;
    LoadBar:TCPULoad;
    pmFull:TFullPopupMenu;

    MouseAction:TMouseAction;
    MouseDownPos,MousePrevPos,MouseDownFormPos:TPoint;
    MouseTimeOut:LongInt;
    MouseTimeIn:LongInt;

    HoverButtons:array [THButtonID] of THoverButton;
    InfoMessage:string;
    InfoDelay:LongInt;
    IconData:TNotifyIconData;
    TrayUsed:Boolean;

    BackScrWidth,BackScrHeight,BackScrDepth,BackScrRate:DWORD;

    imSkin:TImage;
    IsSoundCard:Boolean;
    pnSubs1,pnSubs2,pnInfo:TOSDPanel;

    SSSupress:Boolean;
    SSState:BOOL;

    AudioModel:TAudioPropsModel;
    VideoModel:TVideoPropsModel;

    VideoRect:TRect;
    MappedRect:TRect;
    OrgColor:TColor;
    EQModel:TEQModel;
    DAModel:TDAModel;

    ShowCPanel:Boolean;

    CapOW,CPOW,BrdOW,PlOW:TOptiWrapper;

    procedure tbPosChange(Sender: TObject);
    procedure tbVolumeChange(Sender: TObject);
    procedure PosBarDblClick(Sender: TObject);

    procedure Initialize;
    procedure Finalize;
    procedure LoadSkin(Id:string);
    procedure LoadLAS(FileName:string);
    procedure RemoveLAS;
    procedure SetButtons;
    procedure AddControls;
    procedure FullRepaint;
    procedure RepaintVideo;
    procedure ApplyHue(DeltaHue:LongInt);

    procedure SetCaption(S:String);
    procedure LoadCover(FileName:String);
    procedure HideLogo;
    procedure FileOSDInfo(FileName:String);
    function LoadedFileName:String;

    procedure AddTrayIcon;
    procedure DeleteTrayIcon;

    procedure OnLACommand(var Message:TMessage); message WM_LACMD;
    procedure OnAppCommand(var Msg:TMessage); message WM_APPCOMMAND;
    procedure OnDropFiles(var Message:TMessage); message WM_DROPFILES;
    procedure OnSizing(var Message:TMessage); message WM_SIZING;
    procedure OnNCActivate(var Message:TMessage); message WM_NCACTIVATE;
    procedure OnMouseWheel(var Message:TMessage); message WM_MOUSEWHEEL;
    procedure WMQES(var Message:TMessage); message WM_QUERYENDSESSION;
    procedure OnTrayClick(var Message:TMessage); message WM_LATRAY;
    procedure OnShowHint(var HintStr:string; var CanShow:Boolean; var HintInfo:THintInfo);
    procedure OnWinDMsg(var Msg: TWMShowWindow); message WM_SHOWWINDOW;
    procedure OnFullPopup(Sender:TObject);
    procedure OnMove(var Message:TMessage); message WM_MOVE;
    procedure auUpdateMessage(var Msg:Tmessage); message ALERT_MESSAGE;

    function IsCMDEnabled(Cmd:LongInt):Boolean;
    function IsCMDActive(Cmd:LongInt):Boolean;

    procedure CenterForm;
    procedure ResizeCenter;
    procedure ResizeUser;
    procedure ResizeScaled(Scale:longint);
    procedure ResizeFullScreen;
    procedure MapVideoWindow;
    procedure MapOSD;
    procedure OnGeometryChanged;
    procedure SetCustomRatio;
    procedure SetAspectRatio(X,Y:LongInt);
    procedure DeltaZoom(DeltaX,DeltaY:LongInt);

    function IsMinimized:Boolean;
    procedure ToggleMinimize;
    procedure Maximize;
    procedure Minimize;
    procedure Restore;
    function GetNearestMonitor:TRect;
    procedure ChangeResolution(ToFullScreen:boolean);
    procedure SetStayOnTop(OnTop:boolean);
    procedure ToggleCPanel;
    procedure TogglePanels(IsFromFullScr: Boolean =FALSE);
    procedure HoverCPanelShow(Enabled: boolean);
    procedure CaptionVisibility;
    procedure UpdateSubFont;
    procedure InitSubs;
    procedure SetBorder(Flag:Boolean);
    function GetVideoRect:TRect;
    procedure SetVideoRect(WndRect:TRect);
    procedure ShowPlayList(Visibility:Boolean);
    procedure SkinShot;
    function AllMediaTypes:string;

    procedure Play;
    procedure Pause;
    procedure Stop;

    procedure FrameStep;
    procedure FrameBack;
    procedure SpeedPlay;
    procedure Seek(Delta:string);
    procedure RestoreState;
    procedure EnableControls(Enable:Boolean);
    procedure ScreenShot;
    procedure CClipboard;
    procedure FileInfo(FileName:String);
    procedure FileInformation;
    procedure AddSound;
    procedure Report;

    procedure VideoProps;
    procedure AudioProps;
    procedure AdvancedPlaylist;

    procedure MouseVisibility(Visible:Boolean);
    procedure ResetMouseTimeOut;
    procedure SetVolume;
    procedure DrawSkinRect(DCanvas:TCanvas;SR:TRect;X,Y:longint);
    function IsAltPressed:Boolean;
    procedure SetResolution(aWidth,aHeight,aDepth,aRate:DWORD);
    function GetTrayWindow:HWND;
    procedure SupressScreenSaver(Flag:Boolean);
    procedure PopupForm(Form:TForm; DoModal: Boolean = False);
    procedure SecondWindowHide;
    procedure SecondWindowShow;
    function IsThemeActive: Boolean;

    procedure OnReloadAppPrefs;
  end;

var
  frMain:TfrMain;
  ModernSkinEngine: Boolean;
  LaCap: Boolean;
  LaCP: Boolean;
  firstfsm: Boolean;
  fsmCPVis: Boolean;
  firstrandom: Boolean;
  isToggleActive: Boolean;
  OnOpenFsm: Boolean;
  OldShow: Boolean;
  lastDur: int64;
  emptyfVar: TObject;
  osdHP: Boolean;
  Cover: Boolean;
  NextByHotkey: Boolean;
  Counter: Byte = 0;
  Fcsd: Boolean = False;

implementation

uses
  LACore, Info, DShowHlp, FilterBase, CmdC,
  uMediaInfo, AdvPList, CmdParams, XML, FocusLA, MultiLog,
  JumpToFile, OpenURLDialog, Subtitles, Config, Filters, Filter, Error,
  Codecs, About;

var
  LastPlayListState: boolean;
  workH: integer;

{$R *.DFM}

function KeyboardProc(nCode: integer; wParam: longint; lParam: longint): integer; stdcall;
var
  Active:Boolean;
  KeyStroke: boolean;
  p: PKBDLLHOOKSTRUCT;
  Shift: TShiftState;
begin
  KeyStroke := false;

  if frConfig<>nil then begin
    if (frConfig.CfgPageIndex=9) then begin
      p := PKBDLLHOOKSTRUCT(lParam);
      if  (p^.vkCode = VK_ESCAPE) then begin
        frConfig.CfgPages[9].ESCMessage;
        Result:=1;
        Exit;
      end;
      if (p^.vkCode = VK_TAB) then begin
        frConfig.CfgPages[9].TABMessage;
        Result:=1;
        Exit;
      end;
    end;

    if Core.Prefs.ReadBool('Modules.GlobalKeys.AltMode') then begin
      if (frConfig.CfgPageIndex=13) and frConfig.Active then begin
        p := PKBDLLHOOKSTRUCT(lParam);
        Shift:= [];
        if (GetKeyState(VK_CONTROL) and $8000) <> 0 then Shift:=Shift+ [ssCtrl];
        if (GetKeyState(VK_SHIFT) and $8000) <> 0 then Shift:=Shift+ [ssShift];
        if (GetKeyState(VK_MENU) and $8000) <> 0 then Shift:=Shift+ [ssAlt];
        if (p^.vkCode <> VK_LCONTROL) and (p^.vkCode <> VK_RCONTROL)
          and(p^.vkCode <> VK_LSHIFT) and (p^.vkCode <> VK_RSHIFT)
          and(p^.vkCode <> VK_LMENU) and (p^.vkCode <> VK_RMENU)
        then
          frConfig.CfgPages[13].WriteKeyData(p^.vkCode,Shift);
      end;
    end;
  end;

  Active:=Assigned(Application);
  if (nCode = HC_ACTION) and Active and (frMain.HoverButtons[hiFullScreen].Down)
    and ((Core.Prefs.ReadBool('Video.StayOnTopInFullScreenMode')) or frMain.HoverButtons[hiCapStayOnTop].Down) then
  begin
    case wParam of
      WM_KEYDOWN, WM_SYSKEYDOWN,
      WM_KEYUP,    WM_SYSKEYUP:
      begin
        p := PKBDLLHOOKSTRUCT(lParam);
        KeyStroke :=((p^.vkCode = VK_TAB) and ((p^.flags and LLKHF_ALTDOWN) <> 0))
      end;
    end;
  end;

  if IsDownloading then begin
    p := PKBDLLHOOKSTRUCT(lParam);
    TerminateDownloading:=(p^.vkCode = VK_ESCAPE);
  end;

  if KeyStroke then
  begin
    DisableConfigPageTimer := True;
    Result := 1
  end
  else
  begin
    DisableConfigPageTimer := False;
    result := CallNextHookEx(0, nCode, wParam, lParam);
  end;
end;

procedure Hook(lRun:Boolean);
begin
  if lRun then
    SetWindowsHookEx(WH_KEYBOARD_LL, @KeyboardProc, HInstance, 0)
  else
  begin
    UnhookWindowsHookEx(HookHandle);
  end;
end;

procedure TfrMain.OnWinDMsg(var Msg: TWMShowWindow);
begin
  if (Msg.Status = SW_PARENTCLOSING) and (originMinimizeActivate <> true) then
    PostMessage(frMain.Handle, WM_LACMD, LAC_WINDOW_MINIMIZE, 0)
  else
  begin
    inherited;
    // Отлавливаем минимизацию (Win+D, Win+M и др.)
    if (Msg.Msg = WM_ShowWindow) and (Msg.Status = 1) then
      // Сюда нужно добавить код минимизации
  end;
end;

procedure TfrMain.FormCreate;
var
  L,T,W,H:LongInt;
begin
  NextByHotkey := False;
  ThemeActive := isThemeActive;
  bTrayIconVisible := False;
  BackScrWidth:=0;
  State:=stOff;
  imSkin:=TImage.Create(Application);
  MouseAction:=maNone;
  SSSupress:=FALSE;
  Caption:='Light Alloy';
  DivxSMExeFound := False;
  firstrandom := True;
  originMinimizeActivate:=True;
  PlayGrid:=TPlayGrid.Create(Self.pnPlayList);
  PlayGrid.Parent:=pnPlayList;
  PlayGrid.Align:=alClient;

  Application.OnShowHint := OnShowHint;
  Application.OnMessage  := OnAppMessage;
  Application.OnMinimize := OnAppMinimize;
  Application.OnRestore  := OnAppRestore;

  AddControls;
  SetButtons;
  Hook(TRUE);
  // координты эти не всего окна, а VideoRect
  L:=Core.Prefs.ReadInteger('FrontEnd.Pos.Left');    // это очень важно записывать в конфиг при любых
  T:=Core.Prefs.ReadInteger('FrontEnd.Pos.Top');     // настройках! это надо чтоб определить монитор на котором в последний раз запускали плеер
  W:=Core.Prefs.ReadInteger('FrontEnd.Pos.Right')-L;
  H:=Core.Prefs.ReadInteger('FrontEnd.Pos.Bottom')-T;

  // это если при прошлом запуске конфигурация мониторов була другая
  // и вообще чтоб окно появлялось всегда на экране а не хрен знает где за его пределами
  try  // два if тут специально, что именно в таком порядке проверял
    if not Screen.MonitorFromPoint(Point(l,t), mdNull).Primary then// вот тут и может вылезти эксешн, его и ловим
      if Core.Prefs.ReadBool('OnStart.AlwaysPrMonitor') then
      begin
        L:= (Screen.Width-W)div 2;   // в центр его!
        T:=((Screen.Height-H)div 2)-LACaption.Height -9;
      end;
  except
    L:= (Screen.Width-W)div 2;   // то в центр его!
    T:=((Screen.Height-H)div 2)-LACaption.Height -9;
  end;

  if not Core.Prefs.ReadBool('FrontEnd.PanelsState') then
  begin
    if not Core.Prefs.ReadBool('FrontEnd.AlwaysWindowCaption') then
      LACaption.Visible:= false;
    pnControl.Visible:= false;
  end;

  // сбрасываем размеры, перемещаем в центр и включаем панели
  if Core.Prefs.ReadBool('OnStart.Resize')
     or (W <= 0) or (H <= 0) then // если ширина и высота бредовые то тоже надо
  begin
    LACaption.Visible:= true;
    pnControl.Visible:= true;

    H:=InitHeight-LACaption.Height-pnControl.Height;
    W:=InitWidth;

    L:= Screen.MonitorFromPoint(Point(l,t)).Left
        + (abs(Screen.MonitorFromPoint(Point(l,t)).WorkareaRect.right
        - Screen.MonitorFromPoint(Point(l,t)).WorkareaRect.left)
        -  frMain.Width ) div 2 -11;

    T:= Screen.MonitorFromPoint(Point(l,t)).top
        + (abs(Screen.MonitorFromPoint(Point(l,t)).WorkareaRect.top
        - Screen.MonitorFromPoint(Point(l,t)).WorkareaRect.Bottom)
        - frMain.Height ) div 2 +9;
  end;

  SetVideoRect(Rect(L, T, L + W, T + H));

  Core.MdlMgr.Attach('App.VideoProps.Geometry',OnGeometryChanged);
  Core.MdlMgr.AttachWithState('App.Subs.Pos',OnSubsPos);

  ShowHint:=Core.Prefs.ReadBool('FrontEnd.ShowHints');

  BrandBorder:=TBrandBorder.Create(Self);

  if (OtherGlobalVars.LogEnabled) then
    SetCaption(Core.VerInfo.FormatInfo('{P} {MAJ}.{MIN}{RI} (Logging Enabled)'))
  else
    SetCaption(Core.VerInfo.FormatInfo('{P} {MAJ}.{MIN}{RI}'));

  LACaption.DoubleBuffered := True;
  frMain.DoubleBuffered := True;
end;

///////////////////////////////////////
// изменить масштаб видео и          //
// подогнать размеры окна            //
///////////////////////////////////////
procedure TfrMain.ResizeScaled;
var
  dw,dh,workH: Word;
  R: TRECT;
  Aspect: Real;
  CW: DWORD;
begin
  CW := Get8087CW;
  Set8087CW($133f);
  if not DSH.HasVideo then Exit;

  // если были в полноэкранном режиме то
  // вырубаем полный экран
  if (HoverButtons[hiFullScreen].Down) then
    ResizeUser;

  dw:=Width-pnVideo.Width;    // ширина рамочки и плейлиста если открыт
  dh:=Height-pnVideo.Height;  // высота рамочки и панелей всех

  // изначальные размеры + вписать в экран если не влазит
  if (Scale = -1)  then begin

    // определяем соотношение сторон видио
    try
      Aspect:= DSH.VideoWidth/DSH.VideoHeight;
    except
      Aspect:= 1.33;    
    end;
    R.Right:=DSH.VideoWidth+dw;
    R.Bottom:=DSH.VideoHeight+dh;

    // Do not allow the main form move across window work area borders.
    if R.Right > Screen.MonitorFromWindow(frMain.Handle).Width then
    begin
      R.Right := Screen.MonitorFromWindow(frMain.Handle).Width;
      R.Bottom := round((Screen.MonitorFromWindow(frMain.Handle).Width-dw)/Aspect ) + dh;
    end;

    workH:=abs(Screen.MonitorFromWindow(frMain.Handle).WorkareaRect.top
                  - Screen.MonitorFromWindow(frMain.Handle).WorkareaRect.Bottom);

    if R.Bottom > workH then
    begin
      R.Right := round((workH-dh)*Aspect) + dw;//  Screen.Height-ShellTrayHeight
      R.Bottom := workH;
    end;

  end else
  begin
    // тут собственно и меняем шасштаб видио если именно этого от нас и хотели
    R.Right:=((Scale*DSH.VideoWidth) div 100)+dw;
    R.Bottom:=((Scale*DSH.VideoHeight) div 100)+dh;
  end;

  SetBounds(Left,Top,R.Right,R.Bottom);
  Set8087CW(CW);
end;

procedure TfrMain.ResizeUser;  // переключает на оконный режим
begin
  if not HoverButtons[hiFullScreen].Down then exit ;

  HoverButtons[hiFullScreen].Down:=FALSE;
  FullScreenMode:=FALSE;
  HoverCPanel:=FALSE;

  pnVideo.Align:=alClient;
  ChangeResolution(FALSE);
  SetBorder(TRUE);
  CaptionVisibility;
  SetVideoRect(VideoRect);
  SetStayOnTop(HoverButtons[hiCapStayOnTop].Down);
  spPlayList.Left:=0;
end;

procedure TfrMain.ResizeFullScreen;    // переключает на полно экранный режим
var
  R:TRect;
begin
  if HoverButtons[hiFullScreen].Down then exit;
  HoverButtons[hiFullScreen].Down:=TRUE;
  FullScreenMode:=TRUE;

  VideoRect:=GetVideoRect;
  SetBorder(FALSE);
  ChangeResolution(TRUE);
  R := GetNearestMonitor;
  CaptionVisibility;
  SetBounds(R.Left,R.Top,R.Right,R.Bottom);
  SetStayOnTop(Core.Prefs.ReadBool('Video.StayOnTopInFullScreenMode'));
end;

///////////////////////////////////////
// изменяет размеры окна без видео   //
///////////////////////////////////////
procedure TfrMain.ResizeCenter;
var
  newHeight, newWidth, DeltaY: integer;
begin
  if DSH.HasVideo then exit;
  frMain.pnVideo.Align := alClient;

  DeltaY:=0;
  if not(pnControl.Visible) then Inc(DeltaY,pnControl.Height);
  if not(LACaption.Visible) then Inc(DeltaY,LACaption.Height);

  if DSH.HasAudio and Core.Prefs.ReadBool('FrontEnd.Home_btnOnly') then
  begin
    if not(pnControl.Visible) then TogglePanels;
    if ModernSkinEngine then
      newHeight:=pnControl.Height + LACaption.Height+8
    else
      newHeight:=pnControl.Height + LACaption.Height+10;
  end
  else
    newHeight:=InitHeight-DeltaY;
  newWidth:=InitWidth;
  //Центровка окна
  setBounds(Left,Top,newWidth,newHeight);

  SetStayOnTop(HoverButtons[hiCapStayOnTop].Down);
  VideoRect:=GetVideoRect;
end;

procedure TfrMain.MapVideoWindow;
var
  R:TRect;
begin
  if Assigned(DSH) then begin
    if (DSH.HasVideo and Assigned(DSH.VideoWindow) and Assigned(VideoModel)) then begin
      R:=VideoModel.GetMappedRect(pnVideo.Width,pnVideo.Height);
      if ((R.Right<>0) and (R.Bottom<>0)) then begin
        DSH.VideoWindow.SetWindowPosition(R.Left,R.Top,R.Right-R.Left,R.Bottom-R.Top);
        if DSH.IsFilterConnectedByCLSID(VideoRenderers[scEVR].CLSID) then begin
          pnVideo.InternalPanel.Left:=R.Left;
          pnVideo.InternalPanel.Top:=R.Top;
          pnVideo.InternalPanel.Width:=R.Right-R.Left;
          pnVideo.InternalPanel.Height:=R.Bottom-R.Top;
          DSH.SizeVideoWnd(pnVideo.InternalPanel.ClientRect);
          pnVideo.InternalPanel.Visible:=True;
        end
        else begin
          pnVideo.InternalPanel.Visible:=False;
          pnVideo.InternalPanel.Left:=0;
          pnVideo.InternalPanel.Top:=0;
          pnVideo.InternalPanel.Width:=0;
          pnVideo.InternalPanel.Height:=0;
        end;
        if DSH.IsFilterConnectedByCLSID(VideoRenderers[scMADVR].CLSID) then
          DSH.SizeVideoWnd(R);        
        MappedRect:=R;
      end;
    end
    else
      pnVideo.InternalPanel.Visible:=False;
  end;
  MapOSD;
  if Core.Prefs.ReadBool('OSD.ShowSize') then
    if (DSH<>nil) and (DSH.HasVideo) then
      Core.Info(inttostr(pnVideo.Width)+'x'+inttostr(pnVideo.Height));
end;

procedure TfrMain.TimerTimer(Sender: TObject);
var
  Hour,Min,Sec,MSec:WORD;
  Splitter:Char;
  Pos,Dur:Int64;
  Str:string;
begin
  Pos:=0;
  Dur:=0;
  if (LoadedFileName<>'') then begin
    try
      Pos:=DSH.Position;
      Dur:=DSH.Duration;

      if (DSH.Duration=36000000000) then Dur:=0;

      if (tbPos.Max<>Dur) then
        tbPos.Max:=Dur;

      // автоперемтока
      // отодвинем на 1 секунду чтоб народ мог OSD прочесть
      if (((Dur - Pos) div 10000000)  = ((EndingSeekPos div 10000000)-1))  // это с точностью до секунд сравниваем
        // тут мы проверям из того же сериала серия, точнее просто сравниваем их продолжительность
        // с точностью до  3х минут
        and (((Dur div 1800000000) = (lastDur div 1800000000)) or  (lastDur = 0)) and Core.Prefs.ReadBool('OnOpen.AutoSeek')
        and (EndingSeekPos > 0)
      then
        Core.PlayList.Next;

    except
    end;
  end;

  if (MouseTimeOut>0) then Dec(MouseTimeOut);
  if not DisableMouseHide then
    MouseVisibility(not(Active) or pnControl.Visible or pnPlayList.Visible
      or not(HoverButtons[hiFullScreen].Down) or (MouseTimeOut>0))
  else
    MouseVisibility(True);

  DecodeTime(Time,Hour,Min,Sec,MSec);
  if (Sec and 1)=0 then
    Splitter:=':'
  else
    Splitter:=' ';
  TimeBar.Time:=Format('%.2d%s%.2d',[Hour,Splitter,Min]);

  if (State<>stOff) then begin
    if (Dur<>0) and (Mouse.Capture<>tbPos.Handle) then
      tbPos.Position:=Pos;
    Str:='/';
    if Core.Prefs.ReadBool('FrontEnd.ReversePlayTime') then begin
      Str:='\';
      Pos:=Dur-Pos;
    end;
    PosBar.Pos:=Core.SysHlp.FormatHNS('{H}:{M}:{S}',Pos)+Str+
      Core.SysHlp.FormatHNS('{H}:{M}:{S}',Dur);
  end;

  if PostponedPlay then begin
    PostponedPlay:=FALSE;
    Str:=INI.Str['Last.FileName'];
    Core.PlayList.Play;
    Play;
    ApplyCmdParams;
  end;

  if Assigned(LoadBar) then
    if Assigned(Core.CPU) then
      LoadBar.Load:=LoadBar.Load+((Core.CPU.Usage-LoadBar.Load) div 3);

  CheckMousePos;
  if (MouseTimeIn>0) then Dec(MouseTimeIn);

  // LAC_SEEK_A_B & LAC_SEEK_A_B_STOP
  if (DSH.Position >= Seek_B) and (Seek_A_B = 2) then
    DSH.SeekTo(Seek_A);

  case State of
    stPlay:
    if not(FullScreenMode) and DSH.HasVideo then begin
      if (Core.Prefs.ReadBool('Video.OnTopWhilePlay') = True) and not(HoverButtons[hiCapStayOnTop].Down)
      then
        Center.ProcessCommand(LAC_WINDOW_STAY_ON_TOP);
    end;
    stPause:
    if not(FullScreenMode) and DSH.HasVideo then begin
      if (Core.Prefs.ReadBool('Video.OnTopWhilePlay') = True) and (HoverButtons[hiCapStayOnTop].Down)
      then
        Center.ProcessCommand(LAC_WINDOW_STAY_ON_TOP);
    end;
  end;

  if not hoverCPanel then
    pnVideo.Align := alClient;

  // Refresh header for bookmarks
  if Core.PlayList.HasBookMarks then begin
    if (Core.PlayList.Entries.Count <> 0) then
      if (DSH <> nil) then
        if (DSH.HasAudio) and ((Core.PlayList.Entries[Core.PlayList.PlayPos].GetbookmarkCount)<>0)
        then begin
          NewBmk := Core.PlayList.Entries[Core.PlayList.PlayPos].GetCurrentBookMark;
          if (CurBmk <> NewBmk) then begin
            Str:=Core.PlayList.GetBookMarkTitle(NewBmk);
            if not ((Str[1]='[') and (Str[2]=' ')) then begin
              SetCaption(Str);
              CurBmk := NewBmk;
            end;
          end;
        end;
  end;

  // Prevent high CPU loading
  if Counter < 12 then
  begin
    Inc(Counter);
    Exit;
  end
  else
    Counter:=0;

  // Reset inactivity timer
  if SSSupress then ScreenSaverSwitchOff;

  // Look for 'divxsm.exe'.
  if not Fcsd then
    if (DSH <> nil) and DSH.HasVideo then
      if IsDIVX then
        if not DivxSMExeFound then begin
          GetProcessList;
          // He is found!
          if DivxSMExeFound then
            if not AppInTrayNow then
              if Self.bActive then begin
                FocusApp;
                Fcsd:=True;
              end;
        end;
end;

procedure TfrMain.tbPosChange(Sender: TObject);
begin
  if (Mouse.Capture=tbPos.Handle) then
    DSH.SeekTo(tbPos.Position);
end;

procedure TfrMain.FormKeyDown;
var
  NoShifts:Boolean;
begin
  // Перемотка на предыдущию позицию.
  if (ssCtrl in Shift) and (ssShift in Shift) then
  begin
    if (Key = Ord('Z')) then
      if (i64PreviousPos <> 0) and (DSH.Duration <> 0) and (DSH.Position > 0) then
      begin
        DSH.SeekTo(i64PreviousPos);
        i64PreviousPos := 0;
      end
  end
  else
  begin
    NoShifts:=not((ssShift in Shift) or (ssCtrl in Shift) or (ssAlt in Shift));
    if (ActiveControl=PlayGrid) then
      if ((Key=VK_UP) or (Key=VK_DOWN)) and NoShifts then
      begin
        if Key = VK_UP then
          PlayGrid.SelectUp;
        if Key = VK_DOWN then
          PlayGrid.SelectDown;
        Exit;
      end;

    Center.ProcessKey(Center.VirtualKeyName(Key,Shift));

    if (Core.PlayList.Entries.Count < 1)
      or (Core.PlayList.PlayPos < 0)
    then
      Exit;
      
    //Закладки с № 1 по 9
    if (Core.PlayList.Entries[Core.PlayList.PlayPos].GetBookmarkCount <> 0) then begin
      if (Key>=$31) and (Key<=$39) and (tbPos.Enabled) and NoShifts then
        DSH.SeekTo(tbPos.GetBookmark(Key-$31));
    //Закладка № 10
      if (Key=$30) and (tbPos.Enabled) and NoShifts then
        DSH.SeekTo(tbPos.GetBookmark(10+Key-$31));
    //Закладки с № 11 по 19
      if (ssctrl in Shift) and (ssAlt in Shift) then
        if (Key>=$31) and (Key<=$39) and (tbPos.Enabled) then
          DSH.SeekTo(tbPos.GetBookmark(10+Key-$31));
    end;
  end;
end;

procedure TfrMain.OnSysCommand;
var
  Skip:Boolean;
  SysCmd:DWORD;
begin
  SysCmd:=Msg.wParam and $FFF0;
  Skip:=(SysCmd=SC_SCREENSAVE) or (SysCmd=SC_MONITORPOWER);
  if not(SSSupress) then Skip:=FALSE;
  if Skip then
    Msg.Result:=0
  else
    inherited;
end;

procedure TfrMain.pnMovieMouseDown;
var
  l:LongInt;
begin
  ResetMouseTimeOut;
  GetCursorPos(MouseDownPos);
  MousePrevPos:=MouseDownPos;
  MouseDownFormPos:=Point(Left,Top);

  if (Button=mbLeft) then
  begin
    if DisableMouseHide then
      DisableMouseHide := False;
    if DSH.IsDVDMenu then
      DSH.MouseClick(Point(X,Y))
    else if (ssShift in Shift) then
      MouseAction:=maMoveWindow
    else if (ssCtrl in Shift) then
      MouseAction:=maMoveMovie
    else if (ssAlt in Shift) then
      MouseAction:=maZoomMovie
    else begin
      case Core.Prefs.ReadInteger('Mouse.Left') of
        0:Center.ProcessCommand(LAC_PLAYBACK_STOP_PLAY);
        1:MouseAction:=maMoveWindow;
        2:Center.ProcessCommand(LAC_SOUND_MUTE);
	      3:if HoverButtons[hiFullScreen].Down then
            Center.ProcessCommand(LAC_PLAYBACK_STOP_PLAY)
          else
            MouseAction:=maMoveWindow;
        4:if HoverButtons[hiFullScreen].Down then
            Center.ProcessCommand(LAC_PLAYBACK_STOP_PLAY)
          else
          if pncontrol.Visible then
            Center.ProcessCommand(LAC_PLAYBACK_STOP_PLAY)
          else
            MouseAction:=maMoveWindow;
      end;
    end;
  end;

  if (Button=mbRight) then
    case Core.Prefs.ReadInteger('Mouse.Right') of
      0:Center.ProcessCommand(LAC_WINDOW_CONTROL_PANEL);
      2:Center.ProcessCommand(LAC_WINDOW_PLAYLIST);
    end;

  if (Button=mbMiddle) then
    case Core.Prefs.ReadInteger('Mouse.Middle') of
      0:Center.ProcessCommand(LAC_WINDOW_FULLSCREEN);
      1:Center.ProcessCommand(LAC_WINDOW_MINIMIZE);
      2:Center.ProcessCommand(LAC_PLAYBACK_STOP_PLAY);
      3:begin
        l:=Core.Prefs.Int['Mouse.Wheel'];
        Inc(l);
        if (l=7) then l:=0;
        Core.Prefs.Int['Mouse.Wheel']:=l;
        Core.Info(MS('Config.Mouse.Wheel')+': '+MS('Config.Mouse.Wheel.'+IntToStr(l)));
      end;
    end;
end;

procedure TfrMain.pnMovieResize;
begin
  MapVideoWindow;
end;

procedure TfrMain.Pause;
begin
  DSH.Pause;
  HoverButtons[hiPlay].Down:=FALSE;
  HoverButtons[hiStop].Down:=TRUE;
  HoverButtons[hiSpeedPlay].Down:=FALSE;
  State:=stPause;

  SupressScreenSaver(FALSE);
  Core.MdlMgr.SetSInt32('App.SuperPlay',0);

  if Core.Prefs.ReadBool('OSD.ShowPositionOnPause') then
    Core.Info(Core.SysHlp.FormatHNS('{H}:{M}:{S}', DSH.Position));
end;

procedure TfrMain.Stop;
begin
  Core.Prefs.WriteInteger('Last.PlayListIdx', Core.PlayList.PlayPos);
  Core.PlayList.StopPlayer;
  frMain.HoverButtons[hiPlay].Down:=FALSE;
  frMain.HoverButtons[hiStop].Down:=TRUE;
  frMain.HoverButtons[hiSpeedPlay].Down:=FALSE;
  frMain.PosBar.Pos:='0:00:00>0:00:00';
  frMain.State := stOff;
  if Core.Prefs.ReadBool('FrontEnd.HideLogo') then begin
    pnVideo.ShowLogo:=TRUE;
    LoadCover('empty')
  end
  else begin
    pnVideo.ShowLogo:=FALSE;
    pnVideo.Invalidate;
  end;
  pnVideo.InternalPanel.Width:=0;
  pnVideo.InternalPanel.Height:=0;

  frMain.SetCaption(Core.VerInfo.FormatInfo('{P} {MAJ}.{MIN}{RI}'));
  Application.Title:=Core.VerInfo.FormatInfo('{P} {MAJ}.{MIN}');
  if TrayUsed then begin
    StrPCopy(IconData.szTip,'Light Alloy '+Core.AppVersion);
    Shell_NotifyIcon(NIM_MODIFY,@frMain.IconData);
  end;
  Fcsd:=False;
end;

procedure TfrMain.Play;
begin
  if (LoadedFileName='') then
  begin
    if (Core.PlayList.Entries.Count>0) then
    begin
      if INI.Bool['OnOpen.SeekLastPos'] then
        Core.PlayList.PlayPos:=INI.Int['Last.PlayListIdx'];
      Core.PlayList.Play;
    end else
    begin
      Core.AppLogic.PlaylistOpenFiles;
    end;
  end;

  if (LoadedFileName<>'') then
  begin
    DSH.SetRate(1.0);
    DSH.Run;
    HoverButtons[hiPlay].Down:=TRUE;
    HoverButtons[hiStop].Down:=FALSE;
    HoverButtons[hiSpeedPlay].Down:=FALSE;
    State:=stPlay;

    if DSH.HasVideo then begin
      SupressScreenSaver(TRUE);
      ScreenSaverSwitchOff;
    end;
    pnVideo.Invalidate;

    Core.MdlMgr.SetSInt32('App.SuperPlay',1);
  end;
end;

procedure TfrMain.SpeedPlay;
begin
  if State <> stSpeedPlay then begin
    DSH.SetRate(Core.Prefs.ReadInteger('Video.SpeedPlayRate')/10);
    DSH.Run;
    HoverButtons[hiPlay].Down:=FALSE;
    HoverButtons[hiStop].Down:=FALSE;
    HoverButtons[hiSpeedPlay].Down:=TRUE;
    State:=stSpeedPlay;
  end
  else begin
    DSH.SetRate(1.0);
    DSH.Run;
    HoverButtons[hiPlay].Down:=TRUE;
    HoverButtons[hiStop].Down:=FALSE;
    HoverButtons[hiSpeedPlay].Down:=FALSE;
    State:=stPlay;
  end;
end;

procedure TfrMain.tbVolumeChange(Sender: TObject);
begin
  SetVolume;
end;

procedure TfrMain.TogglePanels;
var
  Flag:Boolean;
  R:TRect;
  FSize:TRect;
  procedure Visibility;
  begin
    pnControl.Visible:=Flag;
    if (not Flag) then
      if pnPlaylist.Visible then LastPlayListState:=true else LastPlayListState:=false;
    ShowPlayList(Flag and LastPlayListState);
    CaptionVisibility;
  end;
begin
  if isToggleActive = False then
    isToggleActive := True
  else
    isToggleActive := False;

  FSize.Top:=frMain.Top;
  FSize.Left:=frMain.Left;
  FSize.Bottom:=frMain.Height;
  FSize.Right:=frMain.Width;

  pnVideo.Align:=alNone;
  Flag:=not(pnControl.Visible);
  if not(HoverButtons[hiFullScreen].Down) then
  begin
    R:=GetVideoRect;
    Visibility;

    if pnControl.Visible then  // только при включении панели
    begin
      workH:=abs(Screen.MonitorFromWindow(frMain.Handle).Top
               - Screen.MonitorFromWindow(frMain.Handle).WorkareaRect.Bottom);

      if (R.Bottom+pnControl.Height > workH) and (R.Bottom < workH) then
        R.Bottom := workH - pnControl.Height;

      if not Core.Prefs.ReadBool('FrontEnd.AlwaysWindowCaption')
        and (R.Top - LACaption.Height < 0)
        // а это чтоб работать только когда не влазит частично а не когда весь заголовок за эраном
        and (R.Top >= 0)
      then
        R.Top := LACaption.Height;
    end;
    SetVideoRect(rect(R.Left,R.Top,R.Right,R.Bottom));
    if Core.Prefs.ReadBool('FrontEnd.SaveWindowSize') and not IsFromFullScr then
      SetBounds(FSize.Left,FSize.Top,FSize.Right,Fsize.Bottom);    
  end
  else
    Visibility;

  pnVideo.Align:=alClient;
  MapOSD;
end;

///////////////////////////////////////
// показать ВНУТРЕННИЙ плейлист      //
///////////////////////////////////////
procedure TfrMain.ShowPlayList(Visibility:Boolean);
var
  L: LongInt;
  colorString: String;
begin
  // Грузим фон списка.
  if not Core.Prefs.ReadBool('PlayList.UseSkinColor') then begin
    try
      colorString := Core.Prefs.ReadString('PlayList.BackgroundColor');
      if (colorString[1] = 'c') and (colorString[2] = 'l') then
        frMain.pnPlaylist.Color := StringToColor(colorString)
      else
        frMain.pnPlaylist.Color := StringToColor(Core.Prefs.ReadString('PlayList.BackgroundColor'));
    except
      frMain.pnPlaylist.Color := StringToColor(Core.Prefs.ReadString('PlayList.BackgroundColor'));
    end
  end
  else
  if ModernSkinEngine then
    try
      frMain.pnPlaylist.Color:=Core.OptiBld.GetImage('Color.PL').Canvas.Pixels[0,0];
    except
      frMain.pnPlaylist.Color:=$4F4F4F
    end
  else
    frMain.pnPlaylist.Color:=frMain.imSkin.Canvas.Pixels[773,109];

  L := INI.Int['Playlist.External'];

  if (Visibility) then
  begin
    // Internal playlist. Show it.
    if L = 0 then
    begin
      if pnvideo.Width < (pnPlayList.Width+160+7) then   // 160 - spPlayList.MinSize (заодно = pnPlayListBottom.Width чтоб кнопки не уходили за экран)
         pnPlayList.Width := pnvideo.Width-160-7;        // 7 - spPlayList.Width
      if pnvideo.Height < (pnPlayListBottom.Height+15) then
         Height:= Height - pnvideo.Height + pnPlayListBottom.Height+15;
      // Избавляемся от жёлтых багов.
      if FullScreenMode then
        pnVideo.Align:=alClient;
      pnPlayList.Visible:=TRUE;
      spPlayList.Visible:=TRUE;
    end;

    if L = 0 then
      if PlayGrid.Visible then
        PlayGrid.SetFocus;

    HoverButtons[hiPlaylist].Down := true;
  end else
  begin
    spPlayList.Visible:=FALSE;
    pnPlayList.Visible:=FALSE;
    HoverButtons[hiPlaylist].Down := False;
  end;

  Core.MdlMgr.SetSInt32('Window.PlayList',Ord(frMain.HoverButtons[hiPlayList].Down));

  //Обрабатываем кнопку при смене типа Плейлиста
  if (L=1) then
  if Assigned(frAdvPList) then
    if not frAdvPList.Visible then
      begin
        HoverButtons[hiPlaylist].Down := False;
        Core.MdlMgr.SetSInt32('Window.PlayList',Ord(frMain.HoverButtons[hiPlayList].Down));
      end
    else
  else
  begin
    HoverButtons[hiPlaylist].Down := False;
    Core.MdlMgr.SetSInt32('Window.PlayList',Ord(frMain.HoverButtons[hiPlayList].Down));
  end;
end;

procedure TfrMain.Initialize;
begin
  HoverButtons[hiRepeat].Down:=Core.Prefs.ReadBool('Playlist.Repeat');
  HoverButtons[hiTree].Down:=Core.Prefs.ReadBool('Playlist.ShowBookmarks');
  HoverButtons[hiMute].Down:=Core.Prefs.ReadBool('FrontEnd.Mute');
  HoverButtons[hiCapStayOnTop].Down:=Core.Prefs.ReadBool('FrontEnd.StayOnTop');
  SetStayOnTop(Core.Prefs.ReadBool('FrontEnd.StayOnTop'));

  PlayGrid.ShowBookmarks:=HoverButtons[hiTree].Down;
  SetStayOnTop(HoverButtons[hiCapStayOnTop].Down);

  tbVolume.Position:=Core.Prefs.ReadInteger('Sound.Volume');

  DragAcceptFiles(Handle,TRUE);
  Timer.Enabled:=TRUE;

  TrayUsed := Core.Prefs.ReadBool('FrontEnd.MinimizeToTray');
  AlreadyTrayUsed := TrayUsed;

  EnableControls(FALSE);

 if Core.Prefs.Int['FrontEnd.RememberPanelsState'] = 1 then
  fsmCPVis := True;

  isToggleActive := False;
  OnOpenFsm:=True;
  OldShow:=False;
  firstfsm := True; //// Для того чтобы опция  "Включить полный экран" при загрузке работала нормально
  ///см.также CmdExec.pas
end;

procedure TfrMain.EnableControls;
begin
  HoverButtons[hiPlay].Enabled:=TRUE;
  HoverButtons[hiStop].Enabled:=Enable;
  HoverButtons[hiSpeedPlay].Enabled:=Enable;
  tbPos.Enabled:=Enable;

  HoverButtons[hiAudioDec].Enabled:=DSH.HasAudio;
  HoverButtons[hiVideoDec].Enabled:=DSH.HasVideo;
  HoverButtons[hiFilters].Enabled:=Enable;
  if Core.PlayList.Entries.Count > 0 then
    HoverButtons[hiInfo].Enabled:=True//Enable;
  else
    HoverButtons[hiInfo].Enabled := False;

  HoverButtons[hiFrameStep].Enabled:=DSH.HasVideo;
  if (Enable and DSH.HasVideo) then
    HoverButtons[hiScreenShot].Enabled:=TRUE
  else
    HoverButtons[hiScreenShot].Enabled:=FALSE;
end;

procedure TfrMain.OnDropFiles;
var
  DropHandle:HDROP;
  FName:array [0..MAX_PATH-1] of Char;
  Count,i,x:LongInt;
  List:TStringList;
  R:TRect;
  P:TPoint;
begin
  List:=TStringList.Create;
  DropHandle:=Message.WParam;

  Count:=DragQueryFile(DropHandle,$FFFFFFFF,NIL,0);

  for i:=0 to Count-1 do begin
    DragQueryFile(DropHandle,i,FName,MAX_PATH);
    List.Add(FName);
  end;

  GetWindowRect(pnPlayList.Handle,R);
  GetCursorPos(P);
  if (HoverButtons[hiPlayList].Down) and (PtInRect(R,P)) then
  begin
    if (ExtractFileExt(LowerCase(FName))='.srt') or
       (ExtractFileExt(LowerCase(FName))='.sub') or
       (ExtractFileExt(LowerCase(FName))='.txt') or
       (ExtractFileExt(LowerCase(FName))='.ass')
    then begin
      if not(Assigned(frSubtitles)) then
        frSubtitles:=TfrSubtitles.Create(Application);
      Core.Subs.Sub1.Load(FName);
    end
    else
      Core.PlayList.AddList(List);
  end
  else begin
    if (ExtractFileExt(LowerCase(FName))='.srt') or
       (ExtractFileExt(LowerCase(FName))='.sub') or
       (ExtractFileExt(LowerCase(FName))='.txt') or
       (ExtractFileExt(LowerCase(FName))='.ass')
    then begin
      if not(Assigned(frSubtitles)) then
        frSubtitles:=TfrSubtitles.Create(Application);
      Core.Subs.Sub1.Load(FName);
    end
    else begin
      if not(INI.Bool['PlayList.AddInsteadReplacing']) then begin
        Core.PlayList.Clear;
        Core.PlayList.AddList(List);
        Core.PlayList.Play;
      end
      else begin
        i:=Core.PlayList.Entries.Count+1;
        Core.PlayList.AddList(List);
        x:=Core.PlayList.GetEntryIndex(List.Strings[0]);
        if (x>-1) then i:=x;
        Core.PlayList.PlayEntry(i,0);
      end;
    end;
  end;

  DragFinish(DropHandle);
  List.Free;
  inherited;
end;

procedure TfrMain.MouseVisibility;
begin
  if Visible then begin
    while ShowCursor(TRUE)<0 do;
  end else begin
    while ShowCursor(FALSE)>=0 do;
  end
end;

procedure TfrMain.RestoreState;
begin
  case State of
    stPlay:Play;
    stPause:Pause;
    stSpeedPlay:SpeedPlay;
  end;
end;

procedure TfrMain.SetVolume;
var
  Volume:LongInt;
begin
  Volume:=tbVolume.Position;
  if (Volume<0) then Volume:=0;
  if (Volume>100) then Volume:=100;

  Core.SndG.Muted:=HoverButtons[hiMute].Down;
  Core.SndG.SetVolume(Volume);

  if Assigned(AudioModel) then
    AudioModel.UpdateVolume;
end;

procedure TfrMain.UpdateSubFont;
begin
  with pnSubs1.Font do begin
    Name:=Core.Prefs.ReadString('Subtitles.Font');
    Size:=(Core.Prefs.ReadInteger('Subtitles.Size'));
    Charset:=Core.Prefs.ReadInteger('Subtitles.Charset');
    Color:=Core.Prefs.ReadInteger('Subtitles.Color');
    Style:=[];
    if (Core.Prefs.ReadBool('Subtitles.Bold')) then
      Style:=[fsBold];
  end;
  pnSubs2.Font:=pnSubs1.Font;
  pnSubs1.Invalidate;
  pnSubs2.Invalidate;

  with pnInfo.Font do begin
    Name:=Core.Prefs.ReadString('OSD.Info.Font.Family');
    Size:=Core.Prefs.ReadInteger('OSD.Info.Font.Size');
    Charset:=Core.Prefs.ReadInteger('OSD.Info.Font.Charset');
    Color:=Core.Prefs.ReadInteger('OSD.Info.Font.Color');
    Style:=[];
    if (Core.Prefs.ReadBool('OSD.Info.Font.Bold')) then
      Style:=[fsBold];
  end;

  pnInfo.VAlign:=vaTopLeft;
  case Core.Prefs.Int['OSD.Info.Pos'] of
    1: pnInfo.VAlign:=vaTop;
    2: pnInfo.VAlign:=vaTopRight ;
    3: pnInfo.VAlign:=vaBottomLeft;
    4: pnInfo.VAlign:=vaBottom;
    5: pnInfo.VAlign:=vaBottomRight;
  end;

  pnInfo.Invalidate;
  MapOSD;
end;

procedure TfrMain.pnMovieMouseMove;
var
  NewPos:TPoint;
  L,T:LongInt;
  R:TRect;
  StickySize:LongInt;
begin
  GetCursorPos(NewPos);
  DisableMouseHide := False;
  if (MousePrevPos.X<>NewPos.X) or (MousePrevPos.Y<>NewPos.Y) then begin
    if (MouseTimeIn>30) then begin
       ResetMouseTimeOut;
    end else begin
      Inc(MouseTimeIn);
    end;
  end;
  DSH.MouseMove(Point(X,Y));

  case (MouseAction) of
    maMoveWindow:
    begin
      if not(HoverButtons[hiFullScreen].Down) then
      begin
        L:=MouseDownFormPos.X; T:=MouseDownFormPos.Y;
        Inc(L,NewPos.X-MouseDownPos.X);
        Inc(T,NewPos.Y-MouseDownPos.Y);
        if (Core.Prefs.ReadBool('FrontEnd.Sticky')) or (Core.Prefs.ReadBool('FrontEnd.DoNotAcrossWorkArea'))
        then
        begin
          //SystemParametersInfo(SPI_GETWORKAREA,0,@R,0);
          R:= screen.MonitorFromWindow(frMain.Handle).WorkareaRect;
          if Screen.MonitorFromWindow(frMain.Handle) <> Screen.Monitors[0] then
            inc(R.Right,Screen.Monitors[0].Width+1);
          StickySize:=Screen.Width div 85;// TODO! Add support for multimonitor systems.

          if not Core.Prefs.ReadBool('FrontEnd.DoNotAcrossWorkArea') then
          begin
            if (Abs(L-R.Left)<StickySize) then L:=R.Left;
            if (Abs(T-R.Top)<StickySize) then T:=R.Top;
            if (Abs((L+Width)-R.Right)<StickySize) then L:=R.Right-Width;
            if (Abs((T+Height)-R.Bottom)<StickySize) then T:=R.Bottom-Height;
          end
          else
          begin
            if (Abs(L-R.Left)<StickySize)or(L<R.Left) then L:=R.Left;
            if (Abs(T-R.Top)<StickySize)or(T<R.Top) then T:=R.Top;
            if (Abs((L+Width)-R.Right)<StickySize)or(L>R.Right-Width) then L:=R.Right-Width;
            if (Abs((T+Height)-R.Bottom)<StickySize)or(T>R.Bottom-Height) then T:=R.Bottom-Height;
          end;
        end;
        SetBounds(L,T,Width,Height);
      end;
    end;
    maMoveMovie:begin
      if Assigned(VideoModel) then begin
        Inc(VideoModel.Ofs.X,NewPos.X-MousePrevPos.X);
        Inc(VideoModel.Ofs.Y,NewPos.Y-MousePrevPos.Y);
        VideoModel.GeometryChanged;
      end;
    end;
    maZoomMovie:begin
      if Assigned(VideoModel) then
        VideoModel.DeltaZoom(NewPos.X-MousePrevPos.X,-(NewPos.Y-MousePrevPos.Y));
    end;
  end;
  MousePrevPos:=NewPos;
end;

procedure TfrMain.pnMovieMouseUp;
var
  P:TPoint;
begin
  if MovieDblClick then
  begin
    ResetMouseTimeOut;
    MovieDblClick:=FALSE;
    case Core.Prefs.ReadInteger('Mouse.LeftDbl') of
      0:Center.ProcessCommand(LAC_PLAYBACK_STOP_PLAY);
      1:Center.ProcessCommand(LAC_WINDOW_FULLSCREEN);
    end;
  end else
  begin
    if (Button=mbRight) and (Core.Prefs.ReadInteger('Mouse.Right')=1) then
    begin
      DisableMouseHide := False;
      GetCursorPos(P);
      pmFull.Popup(P.X,P.Y);
    end;
  end;
  MouseAction:=maNone;
end;

procedure TfrMain.pnControlMouseUp;
begin
  MouseAction:=maNone;
end;

procedure TfrMain.PosBarDblClick(Sender: TObject);
begin
  Core.Prefs.WriteBool('FrontEnd.ReversePlayTime',not(Core.Prefs.ReadBool('FrontEnd.ReversePlayTime')));
end;

procedure TfrMain.SetStayOnTop;
var
  Flag:HWND;
begin
  if (OnTop) or ((HoverButtons[hiFullScreen].Down) and Core.Prefs.ReadBool('Video.StayOnTopInFullScreenMode')) then
  begin
    Flag:=HWND_TOPMOST;
    TopPosition(frMain.Handle, True);
  end
  else
  begin
    Flag:=HWND_NOTOPMOST;
    TopPosition(frMain.Handle, False);
  end;
  SetWindowPos(Handle,Flag,0,0,0,0,SWP_NOMOVE or SWP_NOSIZE);
end;

const
  ComboStyle = {WS_SYSMENU or WS_CAPTION or} WS_THICKFRAME {or WS_GROUP or WS_TABSTOP};

procedure TfrMain.SetBorder;
begin
  BrandBorder.SetBorder(Flag);
end;

///////////////////////////////////////
// возвращает положение видеопанели  //
///////////////////////////////////////
function TfrMain.GetVideoRect;
begin
  GetWindowRect(Handle,Result);
  if (pnControl.Visible) then
    Result.Bottom:=Result.Bottom-pnControl.Height;
  if (LACaption.Visible) then
    Result.Top:=Result.Top+LACaption.Height;
end;

///////////////////////////////////////
// задает размеры окна в зависомости //
// от размеров видеопанели           //
///////////////////////////////////////
procedure TfrMain.SetVideoRect;
var
  R:TRect;
begin
  R:=WndRect;
  videorect := WndRect;
  if (pnControl.Visible) then
    R.Bottom:=R.Bottom+pnControl.Height;
  if (LACaption.Visible) then
    R.Top:=R.Top-LACaption.Height;
  Dec(R.Right,R.Left);
  Dec(R.Bottom,R.Top);
  SetWindowPos(Handle,0,R.Left,R.Top,R.Right,R.Bottom,SWP_NOZORDER);
end;

procedure TfrMain.ChangeResolution;
var
  DC:THandle;
begin
  if not(Core.Prefs.ReadBool('Video.ChangeResolution')) then Exit;

  if (ToFullScreen) then begin
    if (BackScrWidth=0) then begin
      DC:=GetDC(Application.Handle);
      BackScrWidth:=GetDeviceCaps(DC,HORZRES);
      BackScrHeight:=GetDeviceCaps(DC,VERTRES);
      BackScrDepth:=GetDeviceCaps(DC,BITSPIXEL);
      BackScrRate:=GetDeviceCaps(DC,VREFRESH);
      ReleaseDC(Application.Handle,DC);

      SetResolution(
        Core.Prefs.ReadInteger('Video.ChangeResolution.Width'),
        Core.Prefs.ReadInteger('Video.ChangeResolution.Height'),
        Core.Prefs.ReadInteger('Video.ChangeResolution.Depth'),
        BackScrRate);
    end;
  end else begin
    if (BackScrWidth<>0) then begin
      SetResolution(BackScrWidth,BackScrHeight,BackScrDepth,BackScrRate);
      BackScrWidth:=0;
    end;
  end;
end;

procedure TfrMain.OnLACommand;
begin
  Core.Cmd(Message.wParam);
  inherited;
end;

procedure TfrMain.FrameStep;
begin
  if HoverButtons[hiFrameStep].Enabled then begin
    Pause;
    DSH.FrameStep(1);
  end;
end;

procedure TfrMain.Seek;
var
  DeltaPos,CurPos,SeekPos:Int64;
  Accept:Boolean;
  Tries:LongInt;
begin
  if (DSH.Position <> 0) then
  begin
    DeltaPos:=0;
    try
      DeltaPos:=StrToInt(Delta);
    except
    end;
    DeltaPos:=DeltaPos*10000000;

    CurPos:=DSH.Position;
    i64PreviousPos := CurPos;
    Tries:=10;
    Accept:=FALSE;
    repeat
      SeekPos:=(CurPos+DeltaPos);

      if (Delta[1]='-') then begin
        if ((SeekPos-CurPos)<-HNS) then
          Accept:=TRUE;
        Dec(DeltaPos,HNS div 2);
      end else
      begin
        if ((SeekPos-CurPos)>HNS) then
          Accept:=TRUE;
        Inc(DeltaPos,HNS div 2);
      end;

      Dec(Tries);
      if (Tries=0) then begin
        SeekPos:=CurPos+DeltaPos;
        Accept:=TRUE;
      end;
    until Accept;

    if not (SeekPos>DSH.Duration) then
      DSH.SeekTo(SeekPos)
    else
      DSH.SeekTo(DSH.Duration);
  end;
end;

procedure TfrMain.SetButtons;
var
  AParent:TWinControl;
  BTSZ,BtOfs:LongInt;

  procedure AddButton(hIndex:THButtonId;Ax,Ay:longint;Cmd:longint);
  var
    HBt:THoverButton;
  begin
    HBt:=THoverButton.Create(AParent);
    HBt.Parent:=AParent;
    HBt.OrgX:=BtOfs;
    HBt.OrgImg:=imSkin;
    if (Ax<0) then begin
      Ax:=AParent.Width+Ax;
      HBt.Anchors:=[akTop,akRight];
    end;
    HBt.SetBounds(Ax,Ay,BTSZ,BTSZ);
    HBt.Command:=Cmd;
    HoverButtons[hIndex]:=HBt;
    Inc(BtOfs,BTSZ);
  end;

begin
  BtOfs:=0;
  BTSZ:=21;
  AParent:=pnStandard;
  AddButton(hiEject,4,4,LAC_FILE_OPEN);
  AddButton(hiStop,32,4,LAC_PLAYBACK_STOP);
  AddButton(hiFrameStep,56,4,LAC_SEEK_FRAME_STEP);
  AddButton(hiPlay,80,4,LAC_PLAYBACK_PLAY);
  AddButton(hiSpeedPlay,104,4,LAC_PLAYBACK_SPEED_PLAY);

  AddButton(hiFullScreen,244,4,LAC_WINDOW_FULLSCREEN);
  AddButton(hiOriginal,268,4,LAC_WINDOW_ORIGINAL);

  AParent:=pnStandard;
  AddButton(hiPrev,-73,4,LAC_PLAYLIST_PREV);
  AddButton(hiPlayList,-49,4,LAC_WINDOW_PLAYLIST);
  AddButton(hiNext,-25,4,LAC_PLAYLIST_NEXT);

  AParent:=pnAdvanced;
  AddButton(hiMute,4,4,LAC_SOUND_MUTE);
  AddButton(hiAudioDec,96,4,LAC_SOUND_PROPERTIES);

  AddButton(hiVideoDec,122,4,LAC_VIDEO_PROPERTIES);
  AddButton(hiScreenShot,146,4,LAC_VIDEO_SCREENSHOT);
  Inc(BtOfs,BTSZ);// AddButton(hiProportion,170,4,998);
  AddButton(hiSubtitles,170,4,LAC_SUBTITLES_PROPERTIES);

  AParent:=pnAdvanced;
  AddButton(hiFilters,-129,4,LAC_PLAYBACK_FILTERS);
  AddButton(hiInfo,-105,4,LAC_FILE_INFO);
  AddButton(hiConfig,-25,4,LAC_APPLICATION_PREFERENCES);

  AParent:=pnPlayListBottom;
  AddButton(hiPLPlay,4,4,LAC_PLAYLIST_PLAY);
  AddButton(hiRepeat,4,28,LAC_PLAYLIST_REPEAT);
  AddButton(hiAddFiles,32,4,LAC_PLAYLIST_ADD_FILES);
  AddButton(hiAddFolder,32,28,LAC_PLAYLIST_ADD_FOLDER);
  AddButton(hiDel,56,4,LAC_PLAYLIST_DELETE);
  AddButton(hiClear,56,28,LAC_PLAYLIST_CLEAR);
  AddButton(hiPLUp,80,4,LAC_PLAYLIST_MOVE_UP);
  AddButton(hiPLDown,80,28,LAC_PLAYLIST_MOVE_DOWN);
  AddButton(hiRandom,104,4,LAC_PLAYLIST_SHUFFLE);
  AddButton(hiPLReport,104,28,LAC_PLAYLIST_REPORT);
  AddButton(hiTree,132,4,LAC_PLAYLIST_BOOKMARKS);
  AddButton(hiPLSave,132,28,LAC_PLAYLIST_SAVE);

  BTSZ:=15;
  AParent:=LACaption;
  AddButton(hiCapAbout,2,2,LAC_APPLICATION_ABOUT);
  AddButton(hiCapStayOnTop,19,2,LAC_WINDOW_STAY_ON_TOP);
  AddButton(hiCapMinimize,-51,2,LAC_WINDOW_MINIMIZE);
  AddButton(hiCapMaximize,-34,2,LAC_WINDOW_MAXIMIZE);
  AddButton(hiCapExit,-17,2,LAC_APPLICATION_EXIT);
end;

procedure TfrMain.ScreenShot;
var
  Pos:Int64;
  SSFN,Path,FN,Stamp:String;
  Img:TImage;
  Jpeg:TJpegImage;
  FNandRelatedDir: String;
  Succeed:Boolean;
begin
  if (DSH=NIL) then Exit;

  Pos:=DSH.Position;
  Stamp:=Core.SysHlp.FormatHNS('{H}-{M}-{S}.{MS}',Pos);

  FN:=ExtractFileName(LoadedFileName);
  FN:=ChangeFileExt(FN,'');
  FNandRelatedDir := FN;
  FN:=FN+'.'+Stamp+'.bmp';
  Path:=Core.Prefs.ReadString('App.ScreenShotDir');

  // If no path entered, or directory is not exist, just use My Documents.
  if ((Trim(Path)='') or not(DirectoryExists(Path))) then
    Path:=Core.SysHlp.GetMyDocsFolder;

  // Create related to movie directory name.
  if Core.Prefs.ReadBool('Video.CreateRelatedDirectoryName') then
  begin
    Path:=Core.Prefs.ReadString('App.ScreenShotDir');
    if (Trim(Path)='') then
      Path:=Core.SysHlp.GetMyDocsFolder + '\' + FNandRelatedDir //CreateDir(FNandRelatedDir);
    else
      Path:=Core.Prefs.ReadString('App.ScreenShotDir') + '\' + FNandRelatedDir;
    if not (DirectoryExists(FNandRelatedDir)) then
      CreateDir(Path);
  end;

  SSFN:=IncludeTrailingPathDelimiter(Path)+FN;

  Succeed:=DSH.ScreenShot(LoadedFileName,Pos,SSFN);

  if INI.Bool['App.ScreenShotJPEG'] then begin
    if FileExists(SSFN) then begin
      try
        Img:=TImage.Create(Self);
        Img.Picture.LoadFromFile(SSFN);

        Jpeg:=TJpegImage.Create;
        Jpeg.Assign(Img.Picture.Bitmap);

        FN:=ChangeFileExt(SSFN,'.jpg');
        Jpeg.SaveToFile(FN);
        Jpeg.Free;
        Img.Free;
        DeleteFile(SSFN);
        FN:=ExtractFileName(FN);
      except
      end;
    end;
  end;
  if Succeed then
    Core.Info(MS('OSD.ScreenShot')+' '+FN)
  else
    Core.Info(MS('OSD.ScreenShotError'));
end;

procedure TfrMain.CClipboard;
var
  Pos:Int64;
  SSFN,Path,FN,Stamp:String;
  Img:TImage;
begin
  if (DSH=NIL) then Exit;
  if not DSH.HasVideo then Exit;

  Pos:=DSH.Position;

  FN:=ExtractFileName(LoadedFileName);
  FN:=ChangeFileExt(FN,'');
  FN:=FN+'.'+Stamp+'.bmp';

  Path:=Core.SysHlp.GetMyDocsFolder;
  SSFN:=IncludeTrailingPathDelimiter(Path)+FN;

  DSH.ScreenShot(LoadedFileName,Pos,SSFN);
  
  Img:=TImage.Create(Self);
  Img.Picture.LoadFromFile(SSFN);
  Clipboard.Assign(Img.Picture.Bitmap);
  Img.Free;
  DeleteFile(SSFN);

  Core.Info(MS('OSD.ClipBoard'));
end;

function TfrMain.GetNearestMonitor;
var
  mi:longint;
  R:TRect;
  LACenter,MonCenter:TPoint;
  MinDist,Dist:double;
begin
  LACenter:=Point(Left+(Width div 2),Top+(Height div 2));
  Result:=Rect(0,0,Screen.Width,Screen.Height);
  MinDist:=0;
  for mi:=0 to Screen.MonitorCount-1 do begin
    with Screen.Monitors[mi] do begin
      R:=Rect(Left,Top,Width,Height);
      MonCenter:=Point(Left+(Width div 2),Top+(Height div 2));
    end;
    Dist:=sqrt(sqr((LACenter.X-MonCenter.X)/R.Right)+
               sqr((LACenter.Y-MonCenter.Y)/R.Bottom));
    if (mi=0) or (Dist<MinDist) then begin
      Result:=R;
      MinDist:=Dist;
    end;
  end;
end;

procedure TfrMain.AddControls;
begin
  pnControl.DoubleBuffered:=TRUE;
  pnStandard.DoubleBuffered:=TRUE;
  pnAdvanced.DoubleBuffered:=TRUE;

  pnPlayListBottom.DoubleBuffered:=TRUE;

//================ Large Fonts =====================
  pnControl.Height:=79;
  pnStandard.Height:=29;
  pnAdvanced.Height:=29;

  pnPlayListBottom.Height:=54;

  pmFull:=TFullPopupMenu.Create(Self);
  pmFull.imSkin:=imSkin;
  pmFull.OnPopup:=OnFullPopup;
  pnControl.PopupMenu:=pmFull;
  pnPlayList.PopupMenu:=pmFull;

  LACaption:=TLACaption.Create(Self);
  with LACaption do begin
    Parent:=frMain;
    Align:=alTop;
    Height:=20;
    PopupMenu:=pmFull;
    OnMouseDown:=pnControlMouseDown;
    OnMouseMove:=pnMovieMouseMove;
    OnMouseUp:=pnControlMouseUp;
  end;

  pnVideo:=TVideoPanel.Create(Self);
  with pnVideo do begin
    Parent:=Self;
    Align:=alClient;
    Cursor:=crHandPoint;
    OnDblClick:=pnMovieDblClick;
    OnMouseDown:=pnMovieMouseDown;
    OnMouseMove:=pnMovieMouseMove;
    OnMouseUp:=pnMovieMouseUp;
    OnResize:=pnMovieResize;
    InternalPanel.OnDblClick:=pnMovieDblClick;
    InternalPanel.OnMouseDown:=pnMovieMouseDown;
    InternalPanel.OnMouseMove:=pnMovieMouseMove;
    InternalPanel.OnMouseUp:=pnMovieMouseUp;
    InternalPanel.OnResize:=pnMovieResize;
  end;

  tbPos:=TTimeTrackBar.Create(Self);
  with tbPos do begin
    Parent:=pnControl;
    OnChange:=tbPosChange;
    Align:=alClient;
    Enabled:=FALSE;
  end;

  tbVolume:=TVolumeTrackBar.Create(Self);
  with tbVolume do begin
    Parent:=pnAdvanced;
    SetBounds(28,8-2,65,13+4);
    Position:=Core.Prefs.ReadInteger('Sound.Volume');
    OnChange:=tbVolumeChange;
  end;

  PosBar:=TPosBar.Create(Self);
  with PosBar do begin
    Parent:=pnStandard;
    SetBounds(132,4,106,21);
    Ofs:=Point(726,0);
    PosBar.OnDblClick:=PosBarDblClick;
    OnMouseDown:=pnControlMouseDown;
    OnMouseMove:=pnMovieMouseMove;
    OnMouseUp:=pnControlMouseUp;
  end;

  TimeBar:=TTimeBar.Create(Self);
  with TimeBar do begin
    Parent:=pnAdvanced;
    SetBounds(PArent.Width-25-53-3,4,53,21);
    Anchors:=[akTop,akRight];
    Ofs:=Point(726,18);
    OnMouseDown:=pnControlMouseDown;
    OnMouseMove:=pnMovieMouseMove;
    OnMouseUp:=pnControlMouseUp;
  end;

  if Core.Prefs.ReadBool('Plugins.CPUUsage.Enabled') then begin
    LoadBar:=TCPULoad.Create(Self);
    with LoadBar do begin
      Parent:=pnAdvanced;
      SetBounds(194,4,9,21);
      Ofs:=Point(727,77);
      OnMouseDown:=pnControlMouseDown;
      OnMouseMove:=pnMovieMouseMove;
      OnMouseUp:=pnControlMouseUp;
    end;
  end;

  pnSubs1:=TOSDPanel.Create(Self);
  with pnSubs1 do begin
    SetBounds(0,0,10,10);
    Parent:=Self;
    VAlign:=vaBottom;
    Text:='';
    PanelType:=ptSubtitles;
    OnMouseDown:=pnMovieMouseDown;
    OnMouseMove:=pnMovieMouseMove;
    OnMouseUp:=pnControlMouseUp;
    OnDblClick:=pnMovieDblClick;
    Cursor:=crHandPoint;
    Visible:=FALSE;
  end;
  pnSubs2:=TOSDPanel.Create(Self);
  with pnSubs2 do begin
    SetBounds(0,0,10,10);
    Parent:=Self;
    VAlign:=vaTop;
    Text:='';
    PanelType:=ptSubtitles;
    OnMouseDown:=pnMovieMouseDown;
    OnMouseMove:=pnMovieMouseMove;
    OnMouseUp:=pnControlMouseUp;
    OnDblClick:=pnMovieDblClick;
    Cursor:=crHandPoint;
    Visible:=FALSE;
  end;

  pnInfo:=TOSDPanel.Create(Self);
  with pnInfo do begin
    Parent:=Self;
    SetBounds(0,0,10,10);
    VAlign:=vaTop;
    Text:='Info';
    PanelType:=ptInfo;
    Font.Color:=clAqua;
    Font.Size:=16;
    Font.Name:='Tahoma';
    OnMouseDown:=pnMovieMouseDown;
    OnMouseMove:=pnMovieMouseMove;
    OnMouseUp:=pnControlMouseUp;
    OnDblClick:=pnMovieDblClick;
    Cursor:=crHandPoint;
    Visible:=FALSE;
  end;

  UpdateSubFont;
end;

procedure TfrMain.OnSizing(var Message: TMessage);
var
  PR:PRect;
  DeltaY:LongInt;
begin
  DeltaY:=0;
  if (pnControl.Visible) then Inc(DeltaY,pnControl.Height);
  if (LACaption.Visible) then Inc(DeltaY,LACaption.Height);
  PR:=PRect(Message.lParam);

  if pnPlayList.Visible then
  begin
    if (PR^.Right-PR^.Left) < (pnPlayList.Width{+20}+160+15) then
      if (Message.wParam in [WMSZ_TOPLEFT,WMSZ_LEFT,WMSZ_BOTTOMLEFT]) then
        PR^.Left:=PR^.Right-(pnPlayList.Width{+20}+160+15)
      else
        PR^.Right:=PR^.Left+(pnPlayList.Width{+20}+160+15);

    if (PR^.Bottom-PR^.Top) < (pnPlayListBottom.Height+DeltaY+8) then
      if (Message.wParam in [WMSZ_TOPLEFT,WMSZ_TOP,WMSZ_TOPRIGHT]) then
        PR^.Top:=PR^.Bottom-(pnPlayListBottom.Height+DeltaY+8)
      else
        PR^.Bottom:=PR^.Top+(pnPlayListBottom.Height+DeltaY+8);
  end;

  if LACaption.Visible then
  begin
    if ((PR^.Bottom-PR^.Top) < (LACaption.Height +8)) then
      if (Message.wParam in [WMSZ_TOPLEFT,WMSZ_TOP,WMSZ_TOPRIGHT]) then
        PR^.Top:=PR^.Bottom-(LACaption.Height +8)
      else
        PR^.Bottom:=PR^.Top+(LACaption.Height +8);

    if (PR^.Right-PR^.Left) < (150) then
      if (Message.wParam in [WMSZ_TOPLEFT,WMSZ_LEFT,WMSZ_BOTTOMLEFT]) then
        PR^.Left:=PR^.Right-(150)
      else
        PR^.Right:=PR^.Left+(150);
  end;

  if pnControl.Visible then
  begin
    if (PR^.Right-PR^.Left) < MinWidth then
      if (Message.wParam in [WMSZ_TOPLEFT,WMSZ_LEFT,WMSZ_BOTTOMLEFT]) then
        PR^.Left:=PR^.Right-MinWidth
      else
        PR^.Right:=PR^.Left+MinWidth;

    if (PR^.Bottom-PR^.Top) <(pnControl.Height+LACaption.Height+8) then
      if (Message.wParam in [WMSZ_TOPLEFT,WMSZ_TOP,WMSZ_TOPRIGHT]) then
        PR^.Top:=PR^.Bottom-(pnControl.Height+LACaption.Height+8)
      else
        PR^.Bottom:=PR^.Top+(pnControl.Height+LACaption.Height+8);
  end;

  if (PR^.Right-PR^.Left) < 50 then
    if (Message.wParam in [WMSZ_TOPLEFT,WMSZ_LEFT,WMSZ_BOTTOMLEFT]) then
      PR^.Left:=PR^.Right-50
    else
      PR^.Right:=PR^.Left+50;

  if (PR^.Bottom-PR^.Top) <(50) then
    if (Message.wParam in [WMSZ_TOPLEFT,WMSZ_TOP,WMSZ_TOPRIGHT]) then
      PR^.Top:=PR^.Bottom-(50)
    else
      PR^.Bottom:=PR^.Top+(50);

  inherited;
  Invalidate;
end;

procedure TfrMain.CreateParams;
begin
  inherited CreateParams(Params);
  with Params do
    WinClassName:='LightAlloyFront';
end;

procedure TfrMain.pnMovieDblClick;
begin
  MovieDblClick:=TRUE;
end;

procedure TfrMain.OnNCActivate;
begin
  inherited;
  LACaption.Active:=(Message.wParam=1);
  if (Message.wParam=1) then
    SetStayOnTop(HoverButtons[hiCapStayOnTop].Down);
  if Assigned(BrandBorder) then begin
    BrandBorder.Active:=(Message.wParam=1);
    Invalidate;
  end;
end;

procedure TfrMain.OnMouseWheel(var Message: TMessage);
var
  WDir,D,HW,SpeedRate:LongInt;
begin
  WDir:=Message.wParam;
  if Core.Prefs.ReadBool('Mouse.WheelInvert') then WDir:=-WDir;
  case Core.Prefs.ReadInteger('Mouse.Wheel') of
    0:begin
      if (WDir>0) then begin
        Center.ProcessCommand(LAC_SOUND_VOLUME_INC);
      end else begin
        Center.ProcessCommand(LAC_SOUND_VOLUME_DEC);
      end;
    end;
    1:begin
      if (WDir>0) then begin
        Center.ProcessCommand(LAC_SEEK_FORWARD);
      end else begin
        Center.ProcessCommand(LAC_SEEK_BACKWARD);
      end;
    end;
    2:begin
      if (WDir>0) then begin
        Center.ProcessCommand(LAC_VIDEO_BRIGHTNESS_INC);
      end else begin
        Center.ProcessCommand(LAC_VIDEO_BRIGHTNESS_DEC);
      end;
    end;
    3:begin
      if (WDir>0) then begin
        Center.ProcessCommand(LAC_VIDEO_CONTRAST_INC);
      end else begin
        Center.ProcessCommand(LAC_VIDEO_CONTRAST_DEC);
      end;
    end;
    4:begin
      if (WDir>0) then begin
        Center.ProcessCommand(LAC_VIDEO_SATURATION_INC);
      end else begin
        Center.ProcessCommand(LAC_VIDEO_SATURATION_DEC);
      end;
    end;
    5:begin
      if not(HoverButtons[hiFullScreen].Down)
      then begin
        if not DSH.HasVideo then Exit;
        HW:=((pnVideo.Width*100) div DSH.VideoWidth); // Video size (NewWidth-8)
        if (WDir>0) then begin
          D:=HW+3;
          ResizeScaled(D);
          CenterForm;
        end
        else begin
          if HW < 15 then
            Exit
          else
            D:=HW-3;
          ResizeScaled(D);
          CenterForm;
        end;
      end;
    end;
    6:begin
      if (WDir>0) then begin
        if (Core.Prefs.ReadInteger('Video.SpeedPlayRate') > 19) then
          Core.Prefs.WriteInteger('Video.SpeedPlayRate',9);

        SpeedRate:=(Core.Prefs.ReadInteger('Video.SpeedPlayRate') + 1);
        Core.Prefs.WriteInteger('Video.SpeedPlayRate',SpeedRate);
        Core.Info(MS('Config.Mouse.Wheel.6')+'- '+IntToStr(SpeedRate));
        SpeedPlay;
      end
      else begin
        if (Core.Prefs.ReadInteger('Video.SpeedPlayRate') < 5) then
          Core.Prefs.WriteInteger('Video.SpeedPlayRate',11);

        SpeedRate:=(Core.Prefs.ReadInteger('Video.SpeedPlayRate') - 1);
         Core.Prefs.WriteInteger('Video.SpeedPlayRate',SpeedRate);
         Core.Info(MS('Config.Mouse.Wheel.6')+'- '+IntToStr(SpeedRate));
         SpeedPlay;
      end;
    end;
  end;
//  inherited;
end;

procedure TfrMain.CaptionVisibility;
var
  CapVis:boolean;
begin
  CapVis:=pnControl.Visible;
  if not(HoverButtons[hiFullScreen].Down) and
     (Core.Prefs.ReadBool('FrontEnd.AlwaysWindowCaption')) then
    CapVis:=TRUE;
  if (HoverButtons[hiFullScreen].Down) and
     (Core.Prefs.ReadBool('FrontEnd.NeverFullScrCaption')) then
    CapVis:=FALSE;

  LACaption.Visible:=CapVis;
end;

procedure TfrMain.OnFullPopup(Sender: TObject);
var
  myP: TPoint;
  pnCon: THandle;
begin
  DisableMouseHide := True;
  GetCursorPos(myP);
  pnCon := WindowFromPoint(myP);

  if pnCon = Playgrid.Handle then
     pmFull.SetPlayListMenu
  else
     pmFull.SetFullMenu;

  TrayClicked := false;
end;

procedure TfrMain.FrameBack;
var
  Step:Int64;
  Rate:Double;
begin
  if HoverButtons[hiFrameStep].Enabled then begin
    Pause;
    Rate:=10000000/DSH.VideoFPS;
    if (Rate<0.0001) then Rate:=20;
    Step:=Round(1.25*(10000000/Rate));
    DSH.SeekTo(DSH.Position-Step);
  end;
end;

procedure TfrMain.FileInformation;
begin
  if not(HoverButtons[hiInfo].Enabled) then Exit;
  if (LoadedFileName='') then Exit;

  if Assigned(frInfo) then begin
    frInfo.Close;
    Exit;
  end;

  FileInfo(LoadedFileName);
end;

procedure TfrMain.DrawSkinRect;
var
  DR:TRect;
  BMP:TBitmap;
begin
  BMP:=TBitmap.Create;
  BMP.Width:=SR.Right;
  BMP.Height:=SR.Bottom;

  DR:=Rect(0,0,SR.Right,SR.Bottom);
  Inc(SR.Right,SR.Left);
  Inc(SR.Bottom,SR.Top);

  BMP.Canvas.CopyRect(DR,imSkin.Canvas,SR);

  BMP.Transparent:=TRUE;
  BMP.TransparentColor:=imSkin.Canvas.Pixels[771,121];

  DCanvas.Draw(X,Y,BMP);
  BMP.Free;
end;

function TfrMain.IsAltPressed;
begin
  Result:=(HiWord(GetKeyState(VK_MENU))<>0);
end;

procedure TfrMain.Finalize;
var
  IncHeight: Boolean;
begin
  IncHeight:=False;
  if ModernSkinEngine then
    IncHeight:=True;
  RemoveLAS;

  if HoverButtons[hiFullScreen].Down then begin
    //при закрытии приложения из фулскрина, "скрытость" панелей не сохраняется
    Core.Prefs.WriteBool('FrontEnd.PanelsState',true);
    ResizeUser;
  end else
  begin
    Core.Prefs.WriteBool('FrontEnd.PanelsState',pnControl.Visible);
    IncHeight:=False;
  end;


  VideoRect:=GetVideoRect;
  if IncHeight then begin
    VideoRect.Top := (VideoRect.Top - 1);
    VideoRect.Bottom := (VideoRect.Bottom + 20);
  end;
  Core.Prefs.WriteInteger('FrontEnd.Pos.Left',VideoRect.Left);
  Core.Prefs.WriteInteger('FrontEnd.Pos.Top',VideoRect.Top);
  Core.Prefs.WriteInteger('FrontEnd.Pos.Right',VideoRect.Right);
  Core.Prefs.WriteInteger('FrontEnd.Pos.Bottom',VideoRect.Bottom);

  if TrayUsed then DeleteTrayIcon;

  SupressScreenSaver(FALSE);
end;

procedure TfrMain.SetResolution;
var
  l,res:longint;
  DevMode:TDeviceMode;
begin
  l:=0;
  while EnumDisplaySettings(NIL,l,DevMode) do begin
    if (DevMode.dmPelsWidth=aWidth) and
       (DevMode.dmPelsHeight=aHeight) and
       (DevMode.dmBitsPerPel=aDepth) and
       (DevMode.dmDisplayFrequency=aRate) then begin
      res:=ChangeDisplaySettings(DevMode,0);
      if (res=DISP_CHANGE_SUCCESSFUL) then
        Break;
    end;
    Inc(l);
  end;
end;

procedure TfrMain.Maximize;
var
  R:TRect;
begin
  SystemParametersInfo(SPI_GETWORKAREA,0,@R,0);
  Center.ProcessCommand(LAC_WINDOW_FULLSCREEN);
end;

procedure TfrMain.FormCanResize;
var
  DeltaY: integer;
begin
  Resize:=TRUE;
  DeltaY:=0;
  if (pnControl.Visible) then Inc(DeltaY,pnControl.Height);
  if (LACaption.Visible) then Inc(DeltaY,LACaption.Height);
  if pnPlayList.Visible then begin
    if NewWidth < (pnPlayList.Width+25) then
      NewWidth:= pnPlayList.Width+25;
    if NewHeight < (pnPlayListBottom.Height+DeltaY+8) then
      NewHeight:= pnPlayListBottom.Height+DeltaY+8;
  end;
  if LACaption.Visible then begin
    if (NewHeight < (LACaption.Height +8)) then
      NewHeight:= LACaption.Height +8;
    if NewWidth < (150) then
      NewWidth:= 150;
  end;
  if pnControl.Visible then begin
    if NewWidth < MinWidth then
      NewWidth:=MinWidth;
    if NewHeight <(pnControl.Height+LACaption.Height) then
      NewHeight:=pnControl.Height+LACaption.Height;
  end;
  if (NewHeight < 50) then
    NewHeight:= 50;
  if NewWidth < (50) then
    NewWidth:= 50;
end;

procedure TfrMain.AddTrayIcon;
begin
  IconData.cbSize:=SizeOf(IconData);
  IconData.Wnd:=Handle;
  IconData.uID:=0;
  IconData.hIcon:=LoadIcon(hInstance,'TRAY');
  IconData.uCallbackMessage:=WM_LATRAY;
  IconData.uFlags:=NIF_MESSAGE or NIF_ICON or NIF_TIP;
  StrPCopy(IconData.szTip,'Light Alloy '+Core.AppVersion);
  Shell_NotifyIcon(NIM_ADD,@IconData);

  bTrayIconVisible := True;
end;

procedure TfrMain.DeleteTrayIcon;
begin
  Shell_NotifyIcon(NIM_DELETE,@IconData);
  bTrayIconVisible := False;
end;

procedure TfrMain.OnTrayClick;
var
  P:TPoint;
begin
  if (Message.lParam=WM_LBUTTONUP) then begin
    ToggleMinimize;
  end;
  if (Message.LParam=WM_RBUTTONUP) then begin
    GetCursorPos(P);
    SetForegroundWindow(frMain.Handle);
    TrayClicked := True;
    pmFull.Popup(P.X,P.Y);
  end;
  inherited;
end;

procedure TfrMain.OnShowHint;
var
  l,LAC:LongInt;
begin
  for l:=0 to Ord(High(THButtonID)) do
    if HintInfo.HintControl=HoverButtons[THButtonID(l)] then begin
      LAC:=HoverButtons[THButtonID(l)].Command;
      HintStr:=Center.GetCommandName(LAC);
      if (Center.GetCommandKey(LAC)<>'') then
        HintStr:=HintStr+' ('+Center.GetCommandKey(LAC)+')';
    end;
  if (HintInfo.HintControl=LoadBar) then
    HintStr:=MS('FrontEnd.CPULoad.Hint');
  if (HintInfo.HintControl=TimeBar) then
    HintStr:=MS('FrontEnd.Time.Hint');
  if (HintInfo.HintControl=PosBar) then
    HintStr:=MS('FrontEnd.Position.Hint');
  if (HintInfo.HintControl=tbVolume) then
    HintStr:=MS('FrontEnd.Volume.Hint');
end;

function TfrMain.GetTrayWindow;
var
  Tray,Child:HWND;
  C:array [0..127] of Char;
  S:string;
begin
  Result:=0;
  Tray:=FindWindow('Shell_TrayWnd',NIL);
  Child:=GetWindow(Tray,GW_CHILD);
  while (Child<>0) do begin
    if GetClassName(Child,C,SizeOf(C))>0 then begin
      S:=StrPAS(C);
      if (UpperCase(S)='TRAYNOTIFYWND') then
        Result:=Child;
    end;
    Child:=GetWindow(Child,GW_HWNDNEXT);
  end;
end;

procedure TfrMain.ResetMouseTimeOut;
begin
  MouseTimeOut:=Core.Prefs.ReadInteger('Mouse.TimeOut')*5;
end;

procedure TfrMain.SkinShot;
var
  BMP:TBitmap;
  x,y:longint;
  function AverageColor(C1,C2,C3,C4:TColor):TColor;
  begin
    Result:=((C1 and $FCFCFC) shr 2) + ((C2 and $FCFCFC) shr 2) +
            ((C3 and $FCFCFC) shr 2) + ((C4 and $FCFCFC) shr 2);
  end;
begin
  BMP:=TBitmap.Create;
  BMP.PixelFormat:=pf24bit;
  BMP.Width:=Width;
  BMP.Height:=Height;
  BMP.Canvas.CopyRect(Rect(0,0,Width,Height),Canvas,Rect(-3,-3,Width-3,Height-3));
  for y:=0 to (BMP.Height div 2)-1 do
    for x:=0 to (BMP.Width div 2)-1 do
      with BMP.Canvas do
        Pixels[x,y]:=AverageColor(Pixels[x*2+0,y*2+0],Pixels[x*2+0,y*2+1],
                                  Pixels[x*2+1,y*2+0],Pixels[x*2+1,y*2+1]);

  BMP.Width:=BMP.Width div 2;
  BMP.Height:=BMP.Height div 2;
    Bmp.SaveToFile('d:\sc.bmp');
  BMP.Free;
end;

procedure TfrMain.LoadSkin;
var
  OP:TOptiPanel;
  BMP:TBitmap;
  FileName:String;

  SearchRec: TSearchRec;
  l: TStringList;
  sPath: WideString;
begin
  // TODO: Разбить это безобразие на несколько процедур:
  // 1) Поиск и проерка файла шкурки
  // 2) Отдельно загрузка конкретного BMP-скина
  // 3) Отдельно загрузка конкретного LAS-скинов
  // 4) Настройка Border/Caption

  FileName:=Id;

  RemoveLAS;

  if SameText(ExtractFileExt(FileName),'.LAS') then begin
    FileName:=Core.ExePath+'Skins\'+FileName;
    LoadLAS(FileName);
  end;

  if SameText(ExtractFileExt(FileName),'.LSZ') then begin
    FileName:=Core.ExePath+'Skins\'+FileName;
    LoadLAS(FileName);
  end;

  if ((Id<>'') and DirectoryExists(Core.ExePath+'Skins\'+Id)) then begin
    FileName:=Core.ExePath+'Skins\'+FileName;
    LoadLAS(FileName);
  end;

  if (Core.Prefs.ReadBool('FrontEnd.Skin.Random')) and (firstrandom = true) then
  begin
    sPath := ExtractFileDir(Core.ExePath) + '\Skins';
    if (DirectoryExists(sPath)) then begin
      l := TStringList.Create;
      if FindFirst(sPath + '\*.*', faAnyFile, SearchRec) = 0 then
        repeat
          if (ExtractFileExt(SearchRec.Name) = '.bmp') or
             (ExtractFileExt(SearchRec.Name) = '.las')
          then
            l.Add(SearchRec.Name);
        until FindNext(SearchRec) <> 0;
      FindClose(SearchRec);
      Randomize;
      if (l.Count > 0) then begin
        Filename := sPath + '\' + l.Strings[Random(l.Count)];
        if (ExtractFileExt(SearchRec.Name) = '.bmp') then
          imSkin.Picture.Bitmap.LoadFromFile(FileName);
        if (ExtractFileExt(SearchRec.Name) = '.las') then begin
          LoadLAS(FileName);
        end;
        firstrandom := False;
      end
      else begin
        if FileExists(FileName) then begin
          imSkin.Picture.Bitmap.LoadFromFile(FileName);
        end
        else begin
          imSkin.Picture.Bitmap.Handle:=LoadBitmap(hInstance,'DefaultSkin');
        end;
      end;
    end;
  end
  else
    FileName:=Core.ExePath+'Skins\'+FileName+'.bmp';

  if FileExists(FileName) and not ModernSkinEngine then
    imSkin.Picture.Bitmap.LoadFromFile(FileName)
  else begin
    imSkin.Picture.Bitmap.Handle:=LoadBitmap(hInstance,'DefaultSkin');
    if not(ModernSkinEngine) then
      if (Id <> ' <XP.Blue> ') then LoadLAS('-')
  end;

  imSkin.Picture.Bitmap.PixelFormat:=pf32bit;

  OrgColor:=imSkin.Canvas.Pixels[761,114];

  if (INI.Int['FrontEnd.Skin.Hue']<>0) then begin
    ApplyHue(INI.Int['FrontEnd.Skin.Hue']);
  end;

  pnVideo.Color:=imSkin.Canvas.Pixels[761,107];
  pnVideo.UpdateColors;
  pnControl.Color:=imSkin.Canvas.Pixels[761,114];

  PlayGrid.Color:=imSkin.Canvas.Pixels[773,109];
  PlayGrid.TextColor:=imSkin.Canvas.Pixels[771,104];
  PlayGrid.TextSelColor:=imSkin.Canvas.Pixels[762,104];
  PlayGrid.NewColors;

  pnStandard.Color := pnControl.Color;
  pnAdvanced.Color := pnControl.Color;
  if not ModernSkinEngine then
    spPlayList.Color := pnControl.Color;

  pnPlayListBottom.Color:=pnControl.Color;
  if Assigned(BrandBorder) then begin
    if Assigned(BrdOW) then begin
      OP:=BrdOW.Ctl as TOptiPanel;
      BMP:=TBitmap.Create;
      BMP.Width:=OP.arBG.SR.Right-OP.arBG.SR.Left;
      BMP.Height:=OP.arBG.SR.Bottom-OP.arBG.SR.Top;
      BMP.PixelFormat:=pf32bit;

      OptiImgDraw(OP.arBG,BMP.Canvas,Point(0,0));
      BrandBorder.SetImage(BMP,Rect(4,3,4,5),20);

      BMP.Free;
    end else begin
      BrandBorder.SetDefaultImage;
      BrandBorder.SetColors(imSkin.Canvas.Pixels[761,103],imSkin.Canvas.Pixels[770,103]);
    end;
    BrandBorder.DrawBorderImages(LACaption.bmpA,LACaption.bmpI);
    LACaption.UseBG:=TRUE;
    LACaption.SetChildsBG;
    LACaption.Invalidate;
  end;

  Invalidate;
  PlayGrid.Invalidate;
  if not FullScreenMode then
    SetBorder(True)
  else
    SetBorder(False);
end;

procedure TfrMain.WMQES;
var
  X:TXMLNode;
  FN:String;
  FileHash64K: String;
begin
  // Save current playing pos.
  FN:=ExpandFileName(LoadedFileName);
  X:=Core.MediaCache.GetOrCreateInfo(FN);
  X.SetAttr('dur',IntToStr(DSH.Duration));
  FileHash64K := Core.MediaCache.GetFile64KHash(FN);
  X.SetAttr('hash64k',FileHash64K);

  Core.AppLogic.StopActivity;
  Application.ProcessMessages;
  inherited;
  Message.Result:=1;
end;

procedure TfrMain.AddSound;
var
  Masks:string;
  CP:Int64;
  HR:HRESULT;
begin
  if (HoverButtons[hiStop].Enabled) then begin
    Masks:=Core.ExplInt.GetFileMasks('A');
    OpenDialog.Title:=MS('Core.Title.SoundDialog');
    OpenDialog.Filter:=MS('Core.FileType.Audio')+' ('+Masks+')|'+Masks+'|Any file (*.*)|*.*';
    OpenDialog.InitialDir:=Core.Prefs.ReadString('FrontEnd.SoundDir');
    if OpenDialog.Execute then begin
      Core.Prefs.WriteString('FrontEnd.SoundDir',ExtractFilePath(OpenDialog.FileName));
      CP:=DSH.Position;
      DSH.Stop;
      Log('+AddSound: '+OpenDialog.FileName);
      HR:=DSH.RenderFile(OpenDialog.FileName);
      if FAILED(HR) then begin
        if not Core.Prefs.ReadBool('OSD.Info.AlertMsg') then
          Core.Alert(MS('Core.Alert.OpenError')+' '+OpenDialog.FileName)
        else
          Core.Info(MS('Error.RenderError')+' '+OpenDialog.FileName);
      end
      else begin
        OpenDialog.FileName;
        DSH.SetAudioRenderers(True);
        Core.Player.SetSoundOut;
        DSH.SeekTo(0);
        FreeAndNIL(AudioModel);
        AudioModel:=TAudioPropsModel.Create(DSH);
        DSH.SeekTo(CP);
      end;
      DSH.Run;
      LogHR('-AddSound: ',HR);
    end;
  end;
end;

function TfrMain.AllMediaTypes: string;
var
  Masks:string;
begin
  Masks:=Core.ExplInt.GetFileMasks('*');
  Result:=MS('Core.FileType.Media')+'('+Masks+')|'+Masks;

  Masks:=Core.ExplInt.GetFileMasks('P');
  Result:=Result + '|' + MS('Core.FileType.PlayList') + '('+Masks+')|' +Masks;

  Masks:=Core.ExplInt.GetFileMasks('V');
  Result:=Result + '|'+ MS('Core.FileType.Video') + '('+Masks+')|' +Masks;

  Masks:=Core.ExplInt.GetFileMasks('A');
  Result:=Result+ '|' + MS('Core.FileType.Audio') + '('+Masks+')|' +Masks;

  Result:=Result+ '|' + MS('Core.FileType.All') + '(*.*)|*.*';
end;

procedure TfrMain.Report;
var
  SR:TSearchRec;
  Found,l:longint;
  ft:textfile;
  Path,s:string;

  Hour, Min, Sec, MSec: WORD;
  Year, Month, Day:  Word;
  currentDate: TDateTime;
begin
  TotalDuration := 0;
  TotalSize := 0;
  DecodeTime(Time,Hour,Min,Sec, MSec);
  currentDate := Date;
  DecodeDate(currentDate, Year, Month, Day);
  LastUpdate := Format('%d/%d/%d', [Day, Month, Year]) + ' (' + Format('%.2d:%.2d',[Hour,Min]) + ')';
  
  sdPLSave.Filter:='Brief HTML (*.htm;*.html)|*.htm;*.html';
  sdPLSave.FilterIndex := 3; // extended наш выбор.
  Path:=ExtractFilePath(Application.ExeName)+'Report\';
  Found:=FindFirst(Path+'*.txt',faAnyFile,SR);
  while (Found=0) do begin
    try
      AssignFile(ft,Path+SR.Name);
      Reset(ft);
      ReadLn(ft,s);
      CloseFile(ft);
    except
      s:='';
    end;
    sdPLSave.Filter:=sdPLSave.Filter+'|'+Copy(SR.Name,1,Length(SR.Name)-4)+' ('+s+')|'+s;
    Found:=FindNext(SR);
  end;
  FindClose(SR);

  sdPLSave.Title:=MS('Core.Title.Dialog.Report');
  sdPLSave.FileName:='Report';
  sdPLSave.InitialDir:=Core.Prefs.ReadString('Playlist.ReportDir');
  if sdPLSave.Execute then begin
    Core.Prefs.WriteString('Playlist.ReportDir',ExtractFilePath(sdPLSave.FileName));

    s:='';
    FindFirst(Path+'*.txt',faAnyFile,SR);
    for l:=2 to sdPLSave.FilterIndex do begin
      s:=SR.Name;
      FindNext(SR);
    end;
    FindClose(SR);

    Repaint;
    PlayGrid.SaveReport(sdPLSave.FileName,Path+s);
    ShellExecute(0,NIL,PChar(sdPLSave.FileName),NIL,NIL,SW_MAXIMIZE);
  end;
end;

procedure TfrMain.LoadCover(FileName:String);
var
  CoverFileName:String;
  imLogo:TImage;
  dw,dh:Longint;
  R:TRECT;
  tmpStr: String;

  CStrm, OutStrm :TMemoryStream;
  fmt: String;

  Bmp: TBitmap;
  JPic: TJPEGImage;

  SearchRec: TSearchRec;
  l: TStringList;
  sPath: WideString;
begin
  try
    imLogo:=TImage.Create(Self);
    tmpStr := '';
    Cover := False;
    CoverFileName := '';
    fmt:='';
    sPath := ExtractFileDir(Application.ExeName) + '\Logo';

    // Грузим обложку в четыре пресета. Первый - подставной логотип.
    if (DirectoryExists(sPath)) then
    begin
      l := TStringList.Create;
      if FindFirst(sPath + '\*.*', faAnyFile, SearchRec) = 0 then
        repeat
          if (ExtractFileExt(LowerCase(SearchRec.Name)) = '.jpg')
            or (ExtractFileExt(LowerCase(SearchRec.Name)) = '.bmp')
          then
            l.Add(SearchRec.Name);
        until FindNext(SearchRec) <> 0;
      FindClose(SearchRec);
      Randomize;

      if (l.Count > 0) then
        CoverFileName := sPath + '\' + l.Strings[Random(l.Count)];
    end;

    if not Core.Prefs.ReadBool('FrontEnd.HideLogo') then
      CoverFileName := '';

    // Второй - обложка альбома.
    if not (FileName = 'empty') and Core.Prefs.ReadBool('FrontEnd.AllowCovers') then
      tmpStr := ExtractFilePath(FileName) + 'Cover.jpg';
    if not (FileExists(tmpStr)) then
      tmpStr := ExtractFilePath(FileName) + 'Folder.jpg';
    if not (FileExists(tmpStr)) then
      tmpStr := ExtractFilePath(FileName) + 'Cover.bmp';

    // Грузим, что есть.
    if (FileExists(CoverFileName)) and (FileExists(tmpStr)) then
      CoverFileName := tmpStr; // обложка имеет высший приоритет.
    if not(FileExists(CoverFileName)) and (FileExists(tmpStr)) then
      CoverFileName := tmpStr;
    if (ExtractFileName(CoverFileName)='Cover.jpg')
      or (ExtractFileName(CoverFileName)='Folder.jpg')
      or (ExtractFileName(CoverFileName)='Cover.bmp')
    then
      Cover := True;

    // Третий. Если файла обложки альбома нету, пробуем взять его из ID3
    if (not Cover) and Core.Prefs.ReadBool('FrontEnd.AllowCovers') then begin
      if (Core.PlayList.Player <> NIL) then begin
        Bmp:=TBitmap.Create;
        JPic:=TJPEGImage.Create;
        fmt := Core.PlayList.Player.MI.FInfo.FileFormat;
        if (fmt = 'MP3') or (fmt = 'AAC') or (fmt = 'APE')
          or (fmt =  'MPC') or (fmt = 'OGG')
        then begin
          CStrm := TMemoryStream.Create;
          OutStrm := TMemoryStream.Create;
          fmt:=Core.PlayList.Player.MI.ExtractCover(CStrm);
          if fmt = 'JPG' then begin
            JPic.LoadFromStream(CStrm);
            Bmp.Assign(JPic);
            imLogo.Picture.Assign(Bmp);
            pnVideo.SetLogoImage(imLogo);
            pnVideo.ShowLogo:=TRUE;
            Cover:=True;
          end;
          if fmt = 'BMP' then begin
            Bmp.LoadFromStream(CStrm);
            imLogo.Picture.Assign(Bmp);
            pnVideo.SetLogoImage(imLogo);
            pnVideo.ShowLogo:=TRUE;
            Cover:=True;
          end;
          if fmt = 'PNG' then begin
            StreamToBitmapStream(CStrm,OutStrm);
            OutStrm.Seek(0,soFromBeginning);
            Bmp.LoadFromStream(OutStrm);
            imLogo.Picture.Assign(Bmp);
            pnVideo.SetLogoImage(imLogo);
            pnVideo.ShowLogo:=TRUE;
            Cover:=True;
          end;
        end
        else
          fmt:='';
        JPic.Free;
        Bmp.Free;
        CStrm.Free;
        OutStrm.Free;
      end;
    end;

    if (fmt='') and (FileExists(CoverFileName)) then begin
      imLogo.Picture.LoadFromFile(CoverFileName);
      pnVideo.SetLogoImage(imLogo);
      pnVideo.ShowLogo:=TRUE;
    end;

    //Устанавливаем размер окна = размеру обложки
    if Core.Prefs.ReadBool('OnOpen.CoverResize') then
    begin
      dw := width-pnVideo.Width;
      dh := height-pnVideo.Height;
      r.Right := imlogo.Picture.Width+dw;
      r.Bottom := imlogo.Picture.Height+dh;
      if (imlogo.Picture.Width+dw) > (Screen.MonitorFromWindow(frMain.Handle).Width) then
         r.Right:=Screen.MonitorFromWindow(frMain.Handle).Width;
      if (imlogo.Picture.Height+dh) > (Screen.MonitorFromWindow(frMain.Handle).Height) then
         r.Bottom:=Screen.MonitorFromWindow(frMain.Handle).Height;

      if Core.Prefs.ReadBool('FrontEnd.DoNotAcrossWorkArea') then
        begin
          if (Left+R.Right>Screen.WorkAreaWidth) then
            Left:=Left-(Left+R.Right-Screen.WorkAreaWidth);
          if (Top+R.Bottom>Screen.WorkAreaHeight) then
            Top:=Top-(Top+R.Bottom-Screen.WorkAreaHeight);
          if Top<Screen.WorkAreaTop then Top:=Screen.WorkAreaTop;
          if R.Bottom>Screen.WorkAreaHeight then R.Bottom:=Screen.WorkAreaHeight;
        end;
      setbounds(Left, Top, r.Right, r.Bottom);
    end;

    // Установили размер окна = рзмеру обложки
    if Core.Prefs.ReadBool('OnOpen.CoverCenter') then
      CenterForm;

    if not(FileExists(CoverFileName)) and (fmt='') then
      if Core.Prefs.ReadBool('FrontEnd.HideLogo') then
        pnVideo.LoadDefaultLogo
      else
        pnVideo.ShowLogo:=False;

    imLogo.Free;
  // Иначе, четвертый пресет - грузим дефолтное лого.
  except
    if Core.Prefs.ReadBool('FrontEnd.HideLogo') then
      pnVideo.LoadDefaultLogo;
  end;
  if Core.Prefs.ReadBool('FrontEnd.HideLogo') then
    pnVideo.ShowLogo:=TRUE;
  pnVideo.Invalidate;
end;

procedure TfrMain.pnControlMouseDown;
begin
  ResetMouseTimeOut;
  GetCursorPos(MouseDownPos);
  MousePrevPos:=MouseDownPos;
  MouseDownFormPos:=Point(Left,Top);

  if (Button=mbLeft) then
    MouseAction:=maMoveWindow;
end;

procedure TfrMain.SetCustomRatio;
var
  AR:String;
  l,X,Y:Longint;
begin
  try
    AR:=Core.Prefs.ReadString('Video.AspectRatioCustom');
    l:=Pos(':',AR);
    X:=StrToInt(Trim(Copy(AR,1,l-1)));
    Y:=StrToInt(Trim(Copy(AR,l+1,Length(AR)-1)));
    SetAspectRatio(X,Y);
  except
  end;
end;

function TfrMain.IsCMDActive;
var
  l:LongInt;
begin
  Result:=FALSE;
  for l:=0 to Ord(High(THButtonID)) do begin
    if (HoverButtons[THButtonID(l)].Command=Cmd) then begin
      if HoverButtons[THButtonID(l)].Down then
        Result:=TRUE;
    end;
  end;
  case Cmd of
    LAC_SUBTITLES_SHOW:           Result:=pnSubs1.Visible;
    LAC_APPLICATION_HIB_ONPLDONE: Result:=SHibernateOnPlayListDone;
    LAC_APPLICATION_POW_ONPLDONE: Result:=SPlowerOffOnPlayListDone;
    LAC_PLAYLIST_REPEAT_FILE:     Result:=Core.Prefs.ReadBool('Playlist.RepeatOneFile');
  end;

  if not(Assigned(VideoModel)) then Exit;

  case Cmd of
    LAC_VIDEO_RATIO_ASIS:   Result:=(VideoModel.Ratio.X=0) and (VideoModel.Ratio.Y=0);
    LAC_VIDEO_RATIO_16_9:   Result:=(VideoModel.Ratio.X=16) and (VideoModel.Ratio.Y=9);
    LAC_VIDEO_RATIO_4_3:    Result:=(VideoModel.Ratio.X=4) and (VideoModel.Ratio.Y=3);
    LAC_VIDEO_RATIO_WIDTH:  Result:=(VideoModel.Ratio.X=1) and (VideoModel.Ratio.Y=0);
    LAC_VIDEO_RATIO_HEIGHT: Result:=(VideoModel.Ratio.X=0) and (VideoModel.Ratio.Y=1);
    LAC_VIDEO_RATIO_FREE:   Result:=(VideoModel.Ratio.X<0) and (VideoModel.Ratio.Y<0);
    LAC_VIDEO_RATIO_CUSTOM: Result:=(VideoModel.Ratio.X>0) and (VideoModel.Ratio.Y>0)
                            and not((VideoModel.Ratio.X=16) and (VideoModel.Ratio.Y=9))
                            and not((VideoModel.Ratio.X=4) and (VideoModel.Ratio.Y=3));
  end;
end;

function TfrMain.IsCMDEnabled;
var
  l:LongInt;
begin
  Result:=TRUE;
  for l:=0 to Ord(High(THButtonID)) do
    if (HoverButtons[THButtonID(l)].Command=Cmd) then
      if not(HoverButtons[THButtonID(l)].Enabled) then
        Result:=FALSE;
end;

procedure TfrMain.MapOSD;
var
  y:LongInt;
begin
  if FullScreenMode and not(HoverCPanel) then
    pnInfo.AlignSelf(pnVideo,-1);

  if not(FullScreenMode) then
    pnInfo.AlignSelf(pnVideo,-1);

  if osdHP<>pnControl.Visible then
    pnInfo.AlignSelf(pnVideo,-1);

  y:=100-25;
  if Assigned(Core.Subs) then
    y:=100-Core.Subs.Sub2.YPos;
  if (y<50) then begin
    y:=pnVideo.Top+(pnVideo.Height*y) div 100;
    pnSubs2.VAlign:=vaTop;
  end else
  begin
    y:=(pnVideo.Top+(pnVideo.Height*y) div 100)-pnSubs1.Height;
    pnSubs2.VAlign:=vaBottom;
  end;
  pnSubs2.SetBounds(pnVideo.Left,y,pnVideo.Width,pnSubs2.Height);

  y:=100-95;
  if Assigned(Core.Subs) then
    y:=100-Core.Subs.Sub1.YPos;
  if (y<50) then begin
    y:=pnVideo.Top+(pnVideo.Height*y) div 100;
    pnSubs1.VAlign:=vaTop;
  end else begin
    y:=(pnVideo.Top+(pnVideo.Height*y) div 100)-pnSubs1.Height;
    pnSubs1.VAlign:=vaBottom;
  end;
  // Высчитывание положения сабтитров по высоте.
  pnSubs1.SetBounds(pnVideo.Left,y,pnVideo.Width,pnSubs1.Height);

  // OSD info
  if (pnInfo.VAlign = vaBottomLeft) or
     (pnInfo.VAlign = vaBottom) or
     (pnInfo.VAlign = vaBottomRight) then
  begin
    if hoverCPanel then
      if FullScreenMode then
      begin
      if pnControl.Visible then
        pnInfo.Top := pnControl.Top-pnInfo.Height
      else
        pnInfo.Top := frMain.Height-pnInfo.Height;
      end else
    else
      pnInfo.Top := pnVideo.Height-pnInfo.Height;
  end
  else //if vaTop
    if hoverCPanel and LACaption.Visible then pnInfo.Top := LACaption.Height;


  // Subtitles
  if HoverCPanel and (pnSubs1<>nil) then  begin
    if not(pnSubs1.Top < pnControl.Top-pnSubs1.Height) then
      pnSubs1.Top := pnControl.Top-pnSubs1.Height;

    if not(pnSubs1.Top > LaCaption.Top+LaCaption.Height)
       and LACaption.Visible then
       pnSubs1.Top := LaCaption.Top+LaCaption.Height;

    if not(pnSubs2.Top < pnControl.Top-pnSubs2.Height) then
       pnSubs2.Top := pnControl.Top-pnSubs2.Height;

    if not(pnSubs2.Top > LaCaption.Top+LaCaption.Height) then
       pnSubs2.Top := LaCaption.Top+LaCaption.Height;
  end;

  osdHP := pnControl.Visible;

  Invalidate;
end;

procedure TfrMain.FormDestroy;
begin
  Core.MdlMgr.DetachWithState('App.Subs.Pos',OnSubsPos);
  Core.MdlMgr.Detach('App.VideoProps.Geometry',OnGeometryChanged);
  FreeAndNIL(PlayGrid);
  BrandBorder.Free;
  if Assigned(Core.OptiBld) then begin
    Core.OptiBld.Clear;
    FreeAndNIL(Core.OptiBld);
  end;
end;

procedure TfrMain.SupressScreenSaver;
begin
  if (SSSupress<>Flag) then begin
    if Flag then begin
      SystemParametersInfo(SPI_SETSCREENSAVEACTIVE,0,nil,SPIF_SENDWININICHANGE);
      SystemParametersInfo($1027,0,nil,SPIF_SENDWININICHANGE);
    end else begin
      SystemParametersInfo(SPI_SETSCREENSAVEACTIVE,1,nil,SPIF_SENDWININICHANGE);
      SystemParametersInfo($1027,1,nil,SPIF_SENDWININICHANGE);
    end;
    SSSupress:=Flag;
  end;
end;

procedure TfrMain.VideoProps;
begin
  if not(HoverButtons[hiVideoDec].Enabled) then Exit;

  if not(Assigned(frVideoProps)) then
    frVideoProps:=TfrVideoProps.Create(Application);
  PopupForm(frVideoProps);
end;

procedure TfrMain.SecondWindowHide;
begin
  if (frAudioProps <> nil) and (frAudioProps.Visible) then begin
    frAudioProps.Hide;
    vis_frAudioProps := True;
  end;
  if (frVideoProps <> nil) and (frVideoProps.Visible) then begin
    frVideoProps.Hide;
    vis_frVideoProps := True;
  end;
  if (frSubtitles <> nil) and (frSubtitles.Visible) then begin
    frSubtitles.Hide;
    vis_frSubtitles := True;
  end;
  if (frconfig <> nil) and (frconfig.Visible) then begin
    frconfig.Hide;
    vis_frconfig := True;
  end;
  if (frFilters <> nil) and (frFilters.Visible) then begin
    frFilters.Hide;
    vis_frfilters := True;
  end;
  if (frAdvPList <> nil) and (frAdvPList.Visible) then begin
    frAdvPList.Hide;
    vis_frAdvPList := True;
  end;
  if (frJumpToFile <> nil) and (frJumpToFile.Visible) then begin
    frJumpToFile.Hide;
    vis_frJumpToFile := True;
  end;
  if (frOpenURL <> nil) and (frOpenURL.Visible) then begin
    frOpenURL.Hide;
    vis_frOpenURL := True;
  end;
  if (frInfo<>NIL) and (frInfo.Visible) then begin
    frInfo.Hide;
    vis_frInfo := True;
  end;
  if (frFilter<>NIL) and (frFilter.Visible) then begin
    frFilter.Hide;
    vis_frFilter := True;
  end;
  if (frError<>NIL) and (frError.Visible) then begin
    frError.Hide;
    vis_frError := True;
  end;
  if (frDVDProps<>NIL) and (frDVDProps.Visible) then begin
    frDVDProps.Hide;
    vis_frDVDProps := True;
  end;
  if (frCodecs<>NIL) and (frCodecs.Visible) then begin
    frCodecs.Hide;
    vis_frCodecs := True;
  end;
  if Assigned(frsAbout) then
    if frsAbout.Visible then begin
      frsAbout.Hide;
      vis_frAbout := True;
    end;
end;

procedure TfrMain.SecondWindowShow;
begin
  if vis_frAudioProps = True then begin
     frAudioProps.Show;
     SetForeGroundWindow(frAudioProps.Handle);
     vis_frAudioProps := False;
  end;
  if vis_frVideoProps = True then begin
    frVideoProps.Show;
    SetForeGroundWindow(frVideoProps.Handle);
    vis_frVideoProps := False;
  end;
  if vis_frSubtitles = True then begin
    frSubtitles.Show;
    SetForeGroundWindow(frSubtitles.Handle);
    vis_frSubtitles := False;
  end;
  if vis_frconfig = True then begin
    frconfig.Show;
    SetForeGroundWindow(frconfig.Handle);
    vis_frconfig := False;
  end;
  if vis_frfilters = True then begin
    frFilters.Show;
    SetForeGroundWindow(frFilters.Handle);
    vis_frfilters := False;
  end;
  if vis_frAdvPList = True then begin
    frAdvPList.Show;
    SetForeGroundWindow(frAdvPList.Handle);
    vis_frAdvPList := False;
  end;
  if vis_frJumpToFile = True then begin
    frJumpToFile.Show;
    SetForeGroundWindow(frJumpToFile.Handle);
    vis_frJumpToFile := False;
  end;
  if vis_frInfo = True then begin
    frInfo.Show;
    SetForeGroundWindow(frInfo.Handle);
    vis_frInfo := False;
  end;
  if vis_frFilter = True then begin
    frFilter.Show;
    SetForeGroundWindow(frFilter.Handle);
    vis_frFilter := False;
  end;
  if vis_frError = True then begin
    frError.Show;
    SetForeGroundWindow(frError.Handle);
    vis_frError := False;
  end;
  if vis_frDVDProps = True then begin
    frDVDProps.Show;
    SetForeGroundWindow(frDVDProps.Handle);
    vis_frDVDProps := False;
  end;
  if vis_frCodecs = True then begin
    frCodecs.Show;
    SetForeGroundWindow(frCodecs.Handle);
    vis_frCodecs := False;
  end;
  if vis_frAbout then begin
    frsAbout.Show;
    TopPosition(frsAbout.Handle, True);
    vis_frAbout := False;
  end;
end;

procedure TfrMain.Minimize;
var
  SR,DR:TRect;
  Reg: TRegistry;
  AnimeWindow: String;
begin
  Minimized:=True; Restored:=False;
  if (frMain.State = stPlay) or (frMain.State = stSpeedPlay) then
    playStateToMinimize := true
  else
    playStateToMinimize := false;

  if Core.Prefs.ReadBool('OnMinimize.Pause')
    and (HoverButtons[hiStop].Enabled)
    and DSH.HasVideo
  then
    Pause
  else
    if HideFromBoss = 1 then Pause;

  if TrayUsed then
  begin
    Application.Minimize;
    AppInTrayNow := True;
    Hide;
    ShowWindow(Application.Handle,SW_HIDE);
    SR:=Rect(Left,Top,Left+Width,Top+Height);
    GetWindowRect(GetTrayWindow,DR);
    // Считываем реестр дабы убрать лишнее 2е сворачивание
    Reg:=TRegistry.Create;
    REG.RootKey:=HKEY_CURRENT_USER;
    REG.OpenKeyReadOnly('Control Panel\Desktop\WindowMetrics');
    AnimeWindow:= REG.ReadString('MinAnimate');
    if not(StrToInt(AnimeWindow) = 1) then
      DrawAnimatedRects(Handle,3,SR,DR);

    if HideFromBoss = 1 then
      DeleteTrayIcon;

    REG.CloseKey;
    REG.Destroy;
  end
  else
    if HideFromBoss = 1 then
    begin
      //Процедура скрытия вторичных окон LA
      SecondWindowHide;
      Hide;
      ShowWindow(Application.Handle, SW_HIDE);
    end
    else
      Application.Minimize;
end;

procedure TfrMain.Restore;
var
  SR,DR:TRect;
begin
  Minimized:=False; Restored:=True;
  if (TrayUsed and not(Visible)) then
  begin
    GetWindowRect(GetTrayWindow,SR);
    DR:=Rect(Left,Top,Left+Width,Top+Height);
    DrawAnimatedRects(Handle,3,SR,DR);
    if (HideFromBoss > 0) and (TrayUsed) then
      AddTrayIcon;
  end;
    ShowWindow(Application.Handle,SW_SHOW);
  if IsIconic(Application.Handle) then
    Application.Restore;
  Show;
  SetForeGroundWindow(frMain.Handle);
  //Процедура показа вторичных окон LA
  SecondWindowShow;
  HideFromBoss := 2;

  if Core.Prefs.ReadBool('OnMinimize.RestorePlayback') and
    DSH.HasVideo and playStateToMinimize
  then
    Play
end;

procedure TfrMain.ToggleMinimize;
begin
  if not(Visible) or IsIconic(Application.Handle) then
  begin
    Restore;
    AppInTrayNow := False;
  end
  else
    Minimize;
end;

procedure TfrMain.AudioProps;
begin
  if not(HoverButtons[hiAudioDec].Enabled) then Exit;

  if not(Assigned(frAudioProps)) then
    frAudioProps:=TfrAudioProps.Create(Application);
  PopupForm(frAudioProps);
end;

procedure TfrMain.PopupForm;
begin
  Form.Hide;
  Form.FormStyle:=fsNormal;
  if (HoverButtons[hiFullScreen].Down or HoverButtons[hiCapStayOnTop].Down) then
    Form.FormStyle:=fsStayOnTop;
  if not DoModal then
  begin
    Form.Show;
    Form.BringToFront;
  end
  else
    Form.ShowModal;
  SetForegroundWindow(Form.Handle);
end;

procedure TfrMain.OnGeometryChanged;
begin
  MapVideoWindow;
end;

procedure TfrMain.SetAspectRatio;
var
  S:String;
begin
  if not(Assigned(VideoModel)) then Exit;

  VideoModel.Ratio:=Point(X,Y);
  VideoModel.GeometryChanged;
  S:='';
  if ((X=0) and (Y=0)) then
    S:=MS('OSD.AspectRatioAsIs');
  if ((X>0) and (Y>0)) then
    S:=MS('OSD.AspectRatio')+Format(' %d:%d',[X,Y]);
  if ((X=1) and (Y=0)) then
    S:=MS('OSD.AspectRatioByWidth');
  if ((X=0) and (Y=1)) then
    S:=MS('OSD.AspectRatioByHeight');
  if ((X=-1) and (Y=-1)) then
    S:=MS('OSD.AspectRatioFree');

  Core.Info(S);
end;

procedure TfrMain.CenterForm;
var
  L,T:LongInt;
begin
  L:= Screen.MonitorFromWindow(frMain.Handle).Left
   + (abs(Screen.MonitorFromWindow(frMain.Handle).WorkareaRect.right
    - Screen.MonitorFromWindow(frMain.Handle).WorkareaRect.left)
     -  frMain.Width ) div 2;

  T:= Screen.MonitorFromWindow(frMain.Handle).top
   + (abs(Screen.MonitorFromWindow(frMain.Handle).WorkareaRect.top
   - Screen.MonitorFromWindow(frMain.Handle).WorkareaRect.Bottom)
    - frMain.Height ) div 2;
    
  SetBounds(L,T,Width,Height);
end;

procedure TfrMain.OnSubsPos;
begin
  MapOSD;
end;

procedure TfrMain.FileOSDInfo;
var
  V,Str:String;
  Hour,Min,Sec,Msec:Word;
begin
  if (Core.Player<>NIL) then begin
    Str:=Core.Prefs.Text['OSD.InfoStr'];
    Str:=Core.Player.MI.FormatInfo(Str);

    DecodeTime(Time,Hour,Min,Sec,MSec);
    V:=Format('%.2d:%.2d',[Hour,Min]);
    Str:=StringReplace(Str,'{TIME}',V,[rfReplaceAll,rfIgnoreCase]);

    V:=ExtractFileName(FileName);
    Str:=StringReplace(Str,'{FILENAME}',V,[rfReplaceAll,rfIgnoreCase]);
    try
      V:=Core.SysHlp.FormatHNS('{H}:{M}:{S}',DSH.Position);
      Str:=StringReplace(Str,'{POSITION}',V,[rfReplaceAll,rfIgnoreCase]);

      V:=Core.SysHlp.FormatHNS('{H}:{M}:{S}',DSH.Duration-DSH.Position);
      Str:=StringReplace(Str,'{REMAINS}',V,[rfReplaceAll,rfIgnoreCase]);
    except
    end;
  end
  else
    Str:=ExtractFileName(FileName);

  if IsURL then
    str:=DSH.MetaTags.Title;

  if DSH.DSError<>'' then begin
    Str:=Str+#13#10+'['+Core.DSH.DSError+']';
    Core.DSH.DSError:='';
  end;

  Core.Info(Str);
end;

procedure TfrMain.FileInfo;
var
  MediaInfo:TMediaInfo;
  CFile:TCachedFile;
begin
  if (FileName='') then Exit;

  if (frMain.pnPlayList.Visible = FALSE) and (LoadedFileName <> '')
    and (Core.PlayList.Entries.Count <> 0)
  then
    FileName := LoadedFileName;
  CFile:=TCachedFile.Create(FileName);
  MediaInfo:=TMediaInfo.Create(CFile);
  MediaInfo.RetreiveInfo;

  frInfo:=TfrInfo.Create(Application);
  frInfo.ProcessInfo(MediaInfo.ProduceOverview);
  if not Core.CmdParams.IsParamSet('/INFO') then
    PopUpForm(frInfo, True)
  else
    frInfo.ShowModal;

  FreeAndNIL(frInfo);
  FreeAndNIL(MediaInfo);
  FreeAndNIL(CFile);
end;

function TfrMain.LoadedFileName;
begin
  Result:='';
  if (Core.Player<>NIL) then
    Result:=Core.Player.LoadedFileName;
end;

procedure TfrMain.OnAppCommand;
var
  l: Integer;
  Cmd:LongInt;
  Shift: TShiftState;
  XN, XNP: TXMLNode;
begin
  if not(Core.Prefs.ReadBool('Modules.GlobalKeys.MMKeys')) or
    Core.Prefs.ReadBool('Modules.GlobalKeys.AltMode')
  then begin
    inherited;
    Exit;
  end;

  Cmd:=HIWORD(Msg.lParam) and (FAPPCOMMAND_MASK xor $FFFFFFFF);
  if Cmd in [$01..$34] then begin
    Shift:=[];
    XNP := Core.XTree.Root.Node('GlobalKeys');
    for l:=0 to Length(XNP.Nodes)-1 do
    begin
      XN := XNP.Nodes[l];
      if SameText(XN.Tag, 'Keys') then begin
        if Center.VirtualKeyName(Cmd+$A5,Shift) = XN.Attr('MMKey') then begin
          Core.Cmd(Center.ExtractCmdNum(XN.Attr('Command')));
        end;
      end;
    end;
  end;
end;

procedure TfrMain.HideLogo;
begin
  pnVideo.ShowLogo:=FALSE;
end;

procedure TfrMain.OnWMHitTest(var Msg: TMessage);
begin
  BrandBorder.NCHitTest(Msg);
end;

procedure TfrMain.SetCaption(S: String);
begin
  LACaption.Caption:=S;
  BrandBorder.Caption:=S;
  Invalidate;
end;

procedure TfrMain.AdvancedPlaylist;
  procedure BtnsSync;
  begin
    if HoverButtons[hiRandom].Down then
      frAdvPList.aShuffle.Checked:=True
    else
    frAdvPList.aShuffle.Checked:=False;
    if HoverButtons[hiMute].Down then begin
      frAdvPList.aMute.Checked:=True;
      frAdvPList.aMute.ImageIndex:=22;
    end
    else begin
      frAdvPList.aMute.Checked:=False;
      frAdvPList.aMute.ImageIndex:=21;
    end;
    frAdvPList.tbVol.Position:=tbVolume.Position;
  end;
begin
  if Assigned(frAdvPList) then begin
    if frAdvPList.Visible then begin
      TopPosition(frAdvPList.Handle, False);
      frAdvPList.Hide;
      frMain.HoverButtons[hiPlaylist].Down := False;
      Core.MdlMgr.SetSInt32('Window.PlayList',Ord(frMain.HoverButtons[hiPlayList].Down));
      FreeAndNIL(frAdvPList);
    end
    else begin
      frAdvPList.Show;
      BtnsSync;
      frMain.HoverButtons[hiPlaylist].Down := True;
      Core.MdlMgr.SetSInt32('Window.PlayList',Ord(frMain.HoverButtons[hiPlayList].Down));
      TopPosition(frAdvPList.Handle, True);
    end;
    end
  else begin
    frAdvPList:=TfrAdvPList.Create(Application);
    frAdvPList.Show;
    frMain.HoverButtons[hiPlaylist].Down := True;
    Core.MdlMgr.SetSInt32('Window.PlayList',Ord(frMain.HoverButtons[hiPlayList].Down));
    TopPosition(frAdvPList.Handle, True);
    BtnsSync;
  end;
end;


procedure TfrMain.OnEraseBG(var Msg: TMessage);
begin
  Msg.Result:=1;
end;

procedure TfrMain.FullRepaint;
begin
  pnPlayList.Repaint;
  pnControl.Repaint;
  LACaption.Repaint;
  Repaint;
end;

procedure TfrMain.DeltaZoom;
var
  S:String;
  ZX,ZY:LongInt;
begin
  if Assigned(VideoModel) then
    VideoModel.DeltaZoom(DeltaX,DeltaY);

  ZX:=Core.MdlMgr.GetSInt32('App.VideoProps.ZoomX');
  ZY:=Core.MdlMgr.GetSInt32('App.VideoProps.ZoomY');
  S:=Format('%d%% x %d%%',[ZX,ZY]);
  Core.Info(S);
end;

procedure TfrMain.InitSubs;
begin
  with pnSubs1.Font do begin
    Name:=Core.Prefs.ReadString('Subtitles.Font');
    Size:=(Core.Prefs.ReadInteger('Subtitles.Size') * 2);
    Charset:=Core.Prefs.ReadInteger('Subtitles.Charset');
    Color:=Core.Prefs.ReadInteger('Subtitles.Color');
    Style:=[];
    if (Core.Prefs.ReadBool('Subtitles.Bold')) then
      Style:=[fsBold];
  end;
  pnSubs2.Font:=pnSubs1.Font;
  pnSubs1.Invalidate;
  pnSubs2.Invalidate;
end;

function TfrMain.IsMinimized: Boolean;
begin
  if TrayUsed then begin
    Result:=not(Visible);
  end else begin
    Result:=IsIconic(Application.Handle);
  end;
end;

procedure TfrMain.HoverCPanelShow(Enabled: boolean);
begin
  frMain.pnVideo.Align := alNone;
  frMain.pnControl.Visible := Enabled;
  HoverCPanel := Enabled;
  if not(INI.Bool['FrontEnd.NeverFullScrCaption']) then
    frMain.LACaption.Visible := Enabled;
  frMain.pnVideo.SendToBack;
  frMain.MapOSD;
end;

procedure TfrMain.CheckMousePos;
var
  P:TPoint;
  Show:Boolean;
begin
  Show:=false;
  if not(HoverButtons[hiFullScreen].Down) then Exit;
  if not(INI.Bool['Mouse.HoverCPanel']) then Exit;
  if ShowCPanel then exit;

  GetCursorPos(P);

  if not(INI.Bool['FrontEnd.NeverFullScrCaption']) then
    Show:=(P.Y<LaCaption.Height);

  Show := ((P.X > Screen.MonitorFromWindow(frMain.Handle).Left) and
  (P.X < Screen.MonitorFromWindow(frMain.Handle).Width)) and
  (show);

  Show := ((P.Y>(Screen.MonitorFromWindow(frMain.Handle).Height-pnControl.Height)) and
  (P.X > Screen.MonitorFromWindow(frMain.Handle).Left) and
  (P.X < Screen.MonitorFromWindow(frMain.Handle).Width)) or
  (show);

  if pnPlayList.Visible and (P.X > pnPlayList.Left) then exit;

  if show <> oldShow then begin
    OldShow := Show;
    HoverCPanelShow(Show);
  end;
end;

procedure TfrMain.ApplyCmdParams;
var
  S:String;
  l,x,y:LongInt;
begin
  if Core.CmdParams.IsParamSet('/FULLSCREEN') then
    ResizeFullScreen;

  if Core.CmdParams.IsParamSet('/ZOOM') then begin
    S:=Core.CmdParams.GetParamValue('/ZOOM');
    l:=Pos(':',S);
    if (l>0) then begin
      try
        x:=StrToInt(Copy(S,1,l-1));
        y:=StrToInt(Copy(S,l+1,200));
        DeltaZoom(-1000,-1000);
        DeltaZoom(x-50,y-50);
      except
      end;
    end else begin
      try
        x:=StrToInt(S);
        DeltaZoom(-1000,-1000);
        DeltaZoom(x-50,x-50);
      except
      end;
    end;
  end;

  if Core.CmdParams.IsParamSet('/RATIO') then begin
    S:=Core.CmdParams.GetParamValue('/RATIO');
    l:=Pos(':',S);
    if (l>0) then begin
      try
        x:=StrToInt(Copy(S,1,l-1));
        y:=StrToInt(Copy(S,l+1,200));
        SetAspectRatio(x,y);
      except
      end;
    end;
  end;

  if Core.CmdParams.IsParamSet('/MINIMIZE') then
    Core.Cmd(LAC_WINDOW_MINIMIZE);
end;

procedure TfrMain.ScreenSaverSwitchOff;
var
  Inp: TInput;
begin
  // press
  Inp.Itype := INPUT_KEYBOARD;
  Inp.ki.wVk := VK_SHIFT;
  Inp.ki.dwFlags := 0;
  SendInput(1, Inp, SizeOf(Inp));

  // release
  Inp.Itype := INPUT_KEYBOARD;
  Inp.ki.wVk := VK_SHIFT;
  Inp.ki.dwFlags := KEYEVENTF_KEYUP;
  SendInput(1, Inp, SizeOf(Inp));
end;

type
  PRGB32 = ^TRGB32;
  TRGB32 = packed record
    B,G,R,A:Byte;
  end;

procedure TfrMain.ApplyHue;
var
  P:PRGB32;
  SzX,SzY:LongInt;
  x,y:LongInt;
  CS:TColorSpace;
begin
  SzX:=imSkin.Picture.Bitmap.Width;
  SzY:=imSkin.Picture.Bitmap.Height;

  CS:=TColorSpace.Create;
  for y:=0 to SzY-1 do
  begin
    P:=imSkin.Picture.Bitmap.ScanLine[y];
    for x:=0 to SzX-1 do
    begin
      CS.R:=P^.R;
      CS.G:=P^.G;
      CS.B:=P^.B;
      CS.RGB2HSL;
      CS.H:=Byte(CS.H+DeltaHue*255 div 100);
      CS.HSL2RGB;
      P^.R:=CS.R;
      P^.G:=CS.G;
      P^.B:=CS.B;
      Inc(P);
    end;
  end;

  spPlayList.Color := imSkin.Canvas.Pixels[761,114];  
  CS.Free;
end;

procedure TfrMain.LoadLAS(FileName: string);
var
  RS:TResourceStream;
begin
  RemoveLAS;
  tbPos.Visible:=FALSE;
  pnStandard.Visible:=FALSE;
  pnAdvanced.Visible:=FALSE;

  if (((FileName<>'-'))
    and not(FileExists(FileName))
    and not(DirectoryExists(FileName)))
  then Exit;

  if (Core.OptiBld=NIL) then
    Core.OptiBld:=TOptiBuilder.Create;

  if (FileName='-') then
  begin
    RS:=TResourceStream.Create(0,'DefNewSkin',RT_RCDATA);
    Core.OptiBld.LoadFromStream(RS);
    RS.Free;
  end
  else
    Core.OptiBld.Load(FileName);

  BrdOW:=Core.OptiBld.BuildControl('WndBorder',NIL);
  CapOW:=Core.OptiBld.BuildControl('Caption',LACaption);
  LACaption.Height:=CapOW.Ctl.Height;
  CPOW:=Core.OptiBld.BuildControl('CtlPanel',pnControl);
  if CPOW.Ctl.Height = 200 then
    pnControl.Height:=CPOW.Ctl.Height div 2 -1
  else
    pnControl.Height:=CPOW.Ctl.Height;
  PlOW:=Core.OptiBld.BuildControl('PListPanel',pnPlayListBottom);
  pnPlayListBottom.Height:=PlOW.Ctl.Height;
  with CPOW.Ctl do begin
    Align:=alClient;
    BringToFront;
  end;
  with CapOW.Ctl do begin
    Align:=alClient;
    BringToFront;
  end;
  with PlOW.Ctl do begin
    Align:=alClient;
    BringToFront;
  end;

  pnVideo.bmpSkinLogo:=Core.OptiBld.GetImage('Logo.Splash');
  pnVideo.LoadDefaultLogo;

  pmFull.bmpBG:=Core.OptiBld.GetImage('Menu.BG');
  pmFull.bmpPics:=Core.OptiBld.GetImage('Menu.Pics');

  try
    spPlayList.Color:=Core.OptiBld.GetImage('Color.PL').Canvas.Pixels[0,9];
  except
    spPlayList.Color:=Core.OptiBld.GetImage('CP.bg').Canvas.Pixels[1,2];
  end;
  ModernSkinEngine:=True;
end;

procedure TfrMain.RemoveLAS;
begin
  if Assigned(Core.OptiBld) then begin
    if Assigned(CPOW) then begin
      PlOW.Ctl.Free;
      FreeAndNIL(PlOW);
      CPOW.Ctl.Free;
      FreeAndNIL(CPOW);
      CapOW.Ctl.Free;
      FreeAndNIL(CapOW);
      BrdOW.Ctl.Free;
      FreeAndNIL(BrdOW);
    end;
    Core.OptiBld.Clear;
    FreeAndNIL(Core.OptiBld);
  end;

  if Assigned(pmFull.bmpBG) then
    FreeAndNIL(pmFull.bmpBG);
  if Assigned(pmFull.bmpPics) then
    FreeAndNIL(pmFull.bmpPics);

  if Assigned(pnVideo.bmpSkinLogo) then
    FreeAndNIL(pnVideo.bmpSkinLogo);

  if Core.Prefs.ReadBool('FrontEnd.HideLogo') then
    pnVideo.LoadDefaultLogo;

  LACaption.Height:=20;
  pnControl.Height:=79;
  pnPlayListBottom.Height:=54;
  pnPlayList.Width:=160;
  pnStandard.Visible:=TRUE;
  pnAdvanced.Visible:=TRUE;
  tbPos.Visible:=TRUE;
  ModernSkinEngine:=FALSE;
end;

procedure TfrMain.ToggleCPanel;
begin
  ShowCPanel:=not(ShowCPanel);
  if HoverCPanel then begin
    frMain.pnControl.Visible := false;
    HoverCPanel := false;
  end;
  TogglePanels;
end;

procedure TfrMain.OnAppMessage(var Msg: tMSG; var Handled: Boolean);
begin
  // XBUTTON1 clicked
  if (Msg.wParam = 65568) then
    case Core.Prefs.ReadInteger('Mouse.Additional') of
      0: Center.ProcessCommand(LAC_SOUND_VOLUME_DEC);
      1: Center.ProcessCommand(LAC_PLAYLIST_PREV);
      2: Center.ProcessCommand(LAC_SEEK_BACKWARD);
      3: Center.ProcessCommand(LAC_SEEK_JUMP_BACKWARD);
    end;
  // XBUTTON2 clicked
  if (Msg.wParam = 131136) then
    case Core.Prefs.ReadInteger('Mouse.Additional') of
      0: Center.ProcessCommand(LAC_SOUND_VOLUME_INC);
      1: Center.ProcessCommand(LAC_PLAYLIST_NEXT);
      2: Center.ProcessCommand(LAC_SEEK_FORWARD);
      3: Center.ProcessCommand(LAC_SEEK_JUMP_FORWARD);
    end;
end;

procedure TfrMain.OnAppMinimize;
begin
  if not Minimized then Minimize;
  Exit;
end;

procedure TfrMain.OnAppRestore(Sender: Tobject);
begin
  if not Restored then Restore;
  Exit;
end;

function TfrMain.IsThemeActive: Boolean;
 // Returns True if the user uses XP style
const
   themelib = 'uxtheme.dll';
type
   TIsThemeActive = function: BOOL; stdcall;
var
   IsThemeActive: TIsThemeActive;
   huxtheme: HINST;
begin
   Result := False;
   // Check if XP or later Version
  if (Win32Platform  = VER_PLATFORM_WIN32_NT) and
      (((Win32MajorVersion = 5) and (Win32MinorVersion >= 1)) or
       (Win32MajorVersion > 5)) then
  begin
     huxtheme := LoadLibrary(themelib);
     if huxtheme <> 0 then
     begin
       try
         IsThemeActive := GetProcAddress(huxtheme, 'IsThemeActive');
         Result := IsThemeActive;
       finally
        if huxtheme > 0 then
           FreeLibrary(huxtheme);
       end;
     end;
   end;
end;

procedure TfrMain.FormResize(Sender: TObject);
begin
  if  not Core.Prefs.ReadBool('OnOpen.CoverResize') and Cover then
    pnVideo.SetLogoScale;
end;

procedure TfrMain.auUpdateMessage(var Msg: TMessage);
begin
  if (curver < ver) or (StrToInt(curbld) < build) then
    Core.Alert(MS('Core.Alert.AutoUpdate.NewVer') +#13#10 + #13#10 +
      '        ' + ver +' build ' + IntToStr(build),True);
end;

procedure TfrMain.OnMove(var Message: TMessage);
begin
  RepaintVideo;
end;

procedure TfrMain.RepaintVideo;
begin
  if DSH<>nil then
    DSH.Repaint;
end;

procedure TfrMain.OnReloadAppPrefs;
begin
TrayUsed := Core.Prefs.ReadBool('FrontEnd.MinimizeToTray');
  if (TrayUsed = True) and (AlreadyTrayUsed = False)  and (HideFromBoss <> 1) then begin
    AddTrayIcon;
    AlreadyTrayUsed := True;
  end
  else
  if (TrayUsed = False) and (AlreadyTrayUsed = True) and (HideFromBoss <> 1) then begin
    DeleteTrayIcon;
    AlreadyTrayUsed := False;
  end;

  LoadCover('empty');
end;

end.

