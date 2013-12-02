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

unit LACore;

interface

uses
  // Windows
  Windows, ActiveX, Messages, ShellAPI,
  // VCL
  Classes, Forms, Controls, ExtCtrls, SysUtils,
  // Core
  MultiLog, CmdParams, VerInfo, SysHlp, AppProxyWnd, AppLogic, OptiBuilder,
  FontHelper, CachedStream, OtherGlobalVars, NICE, LangMgr, XMLPrefs, XML,
  ExplInt, SoundGlobal, CPUUsage, WinLIRC, uWinAMP, SubsModel, ModMgr, PlayList,
  Player, MediaCache, MediaSettings, OSDManager, CmdExec, CmdC, DShowHlp,
  {conschk,}
  // Forms
  MainUnit, Config, Alert, AdvPList;

const
  WM_LATRAY = WM_APP + 0;
  WM_LACMD  = WM_APP + 2504;
  HNS       = 10000000;

type
  TCore = class
  private
    HC: Cardinal;
    LastWinCmd:TDateTime;

    procedure FixCursor;
    procedure Install;
    procedure UnInstall;

    procedure CheckAppProxy;
  public
//------------------ Core ------------------
    CmdParams:TCmdParams;
    VerInfo:TFileVersionInfo;
    SysHlp:TSystemHelper;
    FntHlp:TFontHelper;
    AppPxWnd:TAppProxywindow;
    AppLogic:TAppLogic;

    MdlMgr:TModelManager;
    LangMgr:TLanguageManager;

    Prefs:TXMLPrefs;
    XTree:TXMLTree;

    {ConsChecker:TConsistencyChecker;}
//------------------ Modules ------------------
    OptiBld:TOptiBuilder;
    SndG:TSoundGlobal;
    Subs:TSubtitlesModel;
    ModMgr:TModuleManager;
    MediaCache:TMediaCache;
    MediaSets:TMediaSettings;
    OSDMgr:TOSDManager;
    CPU:TCPU;

    ExplInt:TExplorerIntegrator;
    PlayList:TPlayList;
    WIRC:TWinIRC;
    Timer:TTimer;
    TimerNotifier:TBlindNotifier;

    constructor Create;
    procedure CheckInfoParam;
    procedure ShowGUI;
    procedure LoadModules;
    procedure ProcessCmdLine(CmdLine:String);

    procedure StopAppProxy;
    procedure HideGUI;
    procedure FreeModules;
    destructor Destroy; override;

    procedure InitPrefs;
    procedure LoadPrefs;
    procedure UpgradePrefs;
    procedure SavePrefs(AndFree:Boolean);
    function GetPrefsDir:String;
    procedure CreateAppProxyWnd;
    procedure DestroyAllVCLForms;

    procedure SavePlayList;
    procedure ReloadLang;
    procedure ReloadSkin;
    function IsRussianLang:Boolean;

    function ExePath:String;
    function ExeName:String;
    function AppHandle:HWND;

    procedure Alert(Msg:String; ShowLink:Boolean = False);
    procedure Info(Msg:String);
    procedure Cmd(LAC:LongInt);
    procedure Exec(CmdName:String);
    procedure E(hR:HRESULT;Scope:String);
    function SysText(Template:String):String;
    function GetVolume:LongInt;
    procedure SetVolume(V:LongInt);

    function AppVersion:String;

    procedure AppException(Sender:TObject;E:Exception);
    procedure OnAppExit;
    procedure ForcedTermination;
    procedure OnTimer(Sender:TObject);

    function DSH:TDirectShowHelper;
    function Player:TPlayer;
  end;

function MS(StrID:string):string;
function INI:TXMLPrefs;
procedure E(hR:HRESULT;Scope:string);

var
  Core   : TCore;
  FBNode : TXMLNode;
  ThI    : Cardinal;
  ver    : String;
  build  : Integer;
  curver,
  curbld : String;
  FPName : string;

//=================================================================
implementation

uses BrandCtl, HttpDownload;
//=================================================================

function MS;
begin
  Result:='{'+StrID+'}';
  if Assigned(Core) then
    if Assigned(Core.LangMgr) then
      Result:=Core.LangMgr.GetMultiString(StrID);
end;

procedure E;
begin
  if Assigned(Core) then
    Core.E(hR,Scope);
end;

function INI;
begin
  Result:=NIL;
  if Assigned(Core) then
    Result:=Core.Prefs;
end;

{---------------------------------------------------------}
{#                      CREATE                           #}
{---------------------------------------------------------}

constructor TCore.Create;
begin
  Log('+Core.Create');
  inherited Create;

  CoInitialize(NIL);
  Randomize;
  FixCursor;
  FPName := PChar(System.CmdLine);
  FPName:=Copy(FPName,2,Length(FPName)-3);
  Log('System.CmdLine='+System.CmdLine);
  SysHlp:=TSystemHelper.Create;
  FntHlp:=TFontHelper.Create;
  CmdParams:=TCmdParams.Create;
  CmdParams.ParseCmdLine(System.CmdLine);
  VerInfo:=TFileVersionInfo.Create(ParamStr(0));
  HC:=0;
  Log('=== '+VerInfo.FullName+' ===');

  LoadPrefs;
  UpgradePrefs;
  LastWinCmd:=Now;

  if CmdParams.IsParamSet('/INSTALL') then begin
    Install;
    Halt;
  end;
  if CmdParams.IsParamSet('/UNINSTALL') then begin
    UnInstall;
    Halt;
  end;

  CreateAppProxyWnd;

  MdlMgr:=TModelManager.Create;
  AppLogic:=TAppLogic.Create(MdlMgr);
  LangMgr:=TLanguageManager.Create;
  ReloadLang;

  MdlMgr.SetModel('App.Exit',TCommandModel.Create(OnAppExit));

  Application.OnException := AppException;
  Application.Title:=VerInfo.FormatInfo('{P} {MAJ}.{MIN}');

  TimerNotifier:=TBlindNotifier.Create;

  if CmdParams.IsParamSet('/SKIN') then
    Prefs.WriteString('FrontEnd.Skin',CmdParams.GetParamValue('/SKIN'));

  Log('-Core.Create');
end;

{---------------------------------------------------------}
{#                      DESTROY                          #}
{---------------------------------------------------------}

destructor TCore.Destroy;
begin
  Log('+Core.Destroy');

  TimerNotifier.Free;
  MdlMgr.DestroyModel('App.Exit');

  LangMgr.Free;
  AppLogic.Free;
  MdlMgr.Free;
  SavePrefs(TRUE);

  AppPxWnd.Free;
  VerInfo.Free;
  CmdParams.Free;
  FntHlp.Free;
  SysHlp.Free;

  CoUnInitialize;

  inherited Destroy;
  Log('-Core.Destroy');
  if NeedAppReload then ShellExecute(0,NIL,PChar(FPName),NIL,NIL,SW_RESTORE);

end;

{---------------------------------------------------------}
{#                  LOAD MODULES                         #}
{---------------------------------------------------------}

procedure TCore.LoadModules;
 procedure InitAutoSave;
 var P: integer;
 begin
   // Загружаем сохранённую ширину списка.
   frMain.pnPlayList.Width := Core.Prefs.ReadInteger('Playlist.InternalPlaylistWidth');

   // Как на счёт проверки на открытость списка после закрытия LA?
   if Core.Prefs.ReadBool('PlayList.OpenState.Enabled') then
     // Показываем список.
     if not Core.Prefs.ReadBool('PlayList.OpenState.wasClosed') then
       frMain.ShowPlayList(True);

   // Выделяем последний воспроизводимый файл
   P := Core.Prefs.ReadInteger('PlayList.PlayPos');
   if (P <= Core.PlayList.Entries.Count-1) and (P > -1) then begin
     Core.PlayList.PlayPos := P;
     Core.PlayList.Entries.Items[P].Selected := TRUE;
   end;

   // Скрываем логотип, если стоит соотвествующая опция.
   if not Core.Prefs.ReadBool('FrontEnd.HideLogo') then
     frMain.HideLogo;

   if Core.Prefs.ReadBool('FrontEnd.Home_btnOnly') then
     Home_onlyBtn := True;

   // Активируем кнопку шафла.
   if Core.Prefs.ReadBool('PlayList.ShuffleOn') then
     Center.ProcessCommand(LAC_PLAYLIST_SHUFFLE);
 end;
 procedure CheckUpdates;
 var
   auTree : TXMLTree;
   auXML  : TXMLPrefs;
   FS     : TFileStream;
   CS     : TCachedStream;
   auVerInfo : TFileVersionInfo;
   auName : String;

   auCurver,
   auVer: String;

 begin
   if Core.Prefs.ReadBool('Core.NotifyNewVerAvailable') then
   begin
     ver := ''; build := 0;

     auName := ExtractFilePath(Application.ExeName) + '\autoupdate.xml';
     if not FileExists(auName) then
       FS := TFileStream.Create(auName, fmCreate or fmShareDenyNone)
     else
       FS := TFileStream.Create(auName, fmOpenReadWrite or fmShareDenyNone);
     CS := TCachedStream.Create(FS, 2, 4096);

     if inetDL('http://light-alloy.ru/classic/autoupdate.xml', TStream(FS)) then
     begin
       auTree := TXMLTree.Create;
       auTree.LoadFromStream(CS);

       auXML := TXMLPrefs.Create(auTree.Root);
       auVerInfo := TFileVersionInfo.Create(ParamStr(0));

       ver    := auXML.ReadString('Official.Version');
       build  := auXML.ReadInteger('Official.build');
       curver := auVerInfo.FileVersion;
       curbld := auVerInfo.FormatInfo('{B}');

       auCurver := curver;
       auVer    := ver;

       Delete(auCurver, 2, 1);
       Delete(auVer, 2, 1);

       PostMessage(frMain.Handle,ALERT_MESSAGE, 0, 0);

       auXML.Free;
       auTree.Free;
     end;
     CS.Free;
     FS.Free;
   end;
   EndThread(0);
 end;
begin
  Log('+Core.LoadModules');

  MediaCache:=TMediaCache.Create;
  MediaCache.Load;
  MediaSets:=TMediaSettings.Create;
  MediaSets.Load;
  OSDMgr:=TOSDManager.Create;

  DShowHlp.DSH:=TDirectShowHelper.Create;
  ModMgr:=TModuleManager.Create(Prefs.CreateSubPrefs('Modules'));
  ModMgr.Load;
  SndG:=TSoundGlobal.Create;
  Subs:=TSubtitlesModel.Create;

  if Prefs.Bool['Core.HighPriority'] then
    SetPriorityClass(GetCurrentProcess,HIGH_PRIORITY_CLASS);

  Log('Core.LoadModules: CPU.Create');
  if Prefs.Bool['Plugins.CPUUsage.Enabled'] then
    CPU:=TCPU.Create(frMain.Handle);

  Log('Core.LoadModules: PlayList');
  Separator := Core.Prefs.ReadString('PlayList.Separator');
  PlayList:=TPlayList.Create;
  MdlMgr.SetModel('PlayList',TObjectModel.Create(PlayList));
  PlayList.OnChange:=MdlMgr.GetModel('PlayList').StateChanged;
  PlayList.AddFromLAP(GetPrefsDir+'LA.lap');

  Log('Core.LoadModules: WinIRC');
  WIRC:=TWinIRC.Create;
  if Prefs.Bool['Modules.WinLIRC.Enabled'] then begin
    if Prefs.Bool['Modules.WinLIRC.AutoLoad'] then
      WIRC.StartServer;
    WIRC.Active:=TRUE;
  end;

  Log('Core.LoadModules: Main.Initialize');
  frMain.Initialize;

  Log('Core.LoadModules: TCommandCenter');
  Center:=TCommandCenter.Create;

  Log('Core.LoadModules: TExplorerIntegrator');
  ExplInt:=TExplorerIntegrator.Create;
  ExplInt.Prefs:=Prefs.CreateSubPrefs('FileTypes');

  Log('Core.LoadModules: WinAMP');
  WinAMP:=TWinAMP.Create;
  WinAMP.LoadGeneralPlugins;

  Log('Core.LoadModules: Models Linkage');
  AppLogic.ModelsLink;

  Log('Core.LoadModules: Timer');
  Timer:=TTimer.Create(NIL);
  Timer.Interval:=100;
  Timer.OnTimer:=OnTimer;
  Timer.Enabled:=TRUE;

  Log('Core.LoadModules: InitAutoSave');
  InitAutoSave;

  Log('Core.LoadModules: CheckUpdates');
  BeginThread(nil, 0, @CheckUpdates, nil, 0, ThI);

  Log('Core.LoadModules: AddTrayIcon');  
  if frMain.TrayUsed then
    frMain.AddTrayIcon;

  Log('Core.LoadModules: LoadCover');
  frMain.LoadCover('empty');

  Log('-Core.LoadModules');
end;

{---------------------------------------------------------}
{#                   FREE MODULES                        #}
{---------------------------------------------------------}

procedure TCore.FreeModules;
begin
  Log('+Core.FreeModules');

  // Save some preferences here.
  Core.Prefs.WriteInteger('Playlist.InternalPlaylistWidth', frMain.pnPlayList.Width);
  Core.Prefs.WriteBool('PlayList.OpenState.wasClosed', not frMain.pnPlayList.Visible);
  Core.Prefs.WriteBool('Playlist.Repeat', frMain.HoverButtons[hiRepeat].Down);
  Core.Prefs.WriteBool('Playlist.ShowBookmarks', frMain.HoverButtons[hiTree].Down);
  Core.Prefs.WriteBool('PlayList.ShuffleOn', isShuffleActivated);
  Core.Prefs.WriteInteger('Playlist.PlayPos', Core.PlayList.PlayPos);
  Core.Prefs.WriteInteger('Subtitles.Size', Round(frMain.pnSubs1.Font.Size));

  Timer.Enabled:=FALSE;
  Timer.Free;

  //ConsChecker.Free;

  SetPriorityClass(GetCurrentProcess,NORMAL_PRIORITY_CLASS);

  INI.Int['Last.SeekPos']:=0;
  if (Player<>NIL) then
    INI.Int['Last.SeekPos']:=Player.Pos div 10000;
  PlayList.StopPlayer;
  Log('Core.FreeModules:Main.Finalize');
  frMain.Finalize;
  AppLogic.ModelsUnlink;

  if Assigned(frAdvPList) then begin
    frAdvPList.Hide;
    FreeAndNIL(frAdvPList);
  end;

  Log('Core.FreeModules:PlayList.Save');
  SavePlayList;
  MdlMgr.DestroyModel('PlayList');
  PlayList.Free;

  Log('Core.FreeModules:FreeGeneralPlugins');
  WinAMP.FreeGeneralPlugins;
  FreeAndNIL(WinAMP);

  if Assigned(CPU) then begin
    Log('Core.FreeModules:CPU.Free');
    FreeAndNIL(CPU);
  end;

  if Assigned(WIRC) then begin
    WIRC.Active:=FALSE;

    if Prefs.Bool['Modules.WinLIRC.AutoStop'] then
      WIRC.StopServer;

    Log('Core.FreeModules:WinIRC.Free');
    FreeAndNIL(WIRC);
  end;

  ExplInt.Prefs.Free;
  FreeAndNIL(ExplInt);

  Log('Core.Destroy:Center.FreeNIL');
  FreeAndNIL(Center);

  DestroyAllVCLForms;

  FreeAndNIL(Subs);
  FreeAndNIL(SndG);
  ModMgr.Unload;
  FreeAndNIL(ModMgr);
  FreeAndNIL(DShowHlp.DSH);

  FreeAndNIL(OSDMgr);
  MediaSets.Save;
  FreeAndNIL(MediaSets);
  MediaCache.Save;
  FreeAndNIL(MediaCache);

  Log('-Core.FreeModules');
end;

procedure TCore.Alert;
var
  FA:TfrAlert;
begin
  Log('Core.Alert('+Msg+')');
  MessageBeep(MB_OK);

  FA:=TfrAlert.Create(Application);
  FA.FShowLink:=ShowLink;
  if frMain.HoverButtons[hiCapStayOnTop].Enabled then
  begin
    if Assigned(frConfig) then
      frConfig.SwitchCfgTopPos(FA.Handle, True)
    else
      TopPosition(FA.Handle, True);
  end;
  FA.SetText(Msg);
  FA.ShowModal;
  if frMain.HoverButtons[hiCapStayOnTop].Enabled then 
  begin
    if Assigned(frConfig) then
      frConfig.SwitchCfgTopPos(FA.Handle, False)
    else
      TopPosition(FA.Handle, False);
  end;
  FA.Free;
end;

procedure TCore.CreateAppProxyWnd;
begin
  AppPxWnd:=TAppProxyWindow.Create;
  AppPxWnd.AppId:='LightAlloy';
  AppPxWnd.ParentWnd:=Application.Handle;

  if not(Prefs.Bool['FrontEnd.MultiInstance'])
    and not(CmdParams.IsParamSet('/NEW'))
    and not(CmdParams.IsParamSet('/INFO'))
    and AppPxWnd.CopyExists then
  begin
    AppPxWnd.SendToCopy(IntToStr(Round(Now*MSecsPerDay))+'|'+
      GetCurrentDir+'|'+System.CmdLine);
    Halt;
  end;

  AppPxWnd.Active:=TRUE;
end;

procedure TCore.AppException;
begin
  Log('!Exception: '+E.Message);
end;

function TCore.IsRussianLang;
var
  Lang:String;
begin
  Lang:=Prefs.ReadString('FrontEnd.Language');
  Result:=(ANSIUpperCase(Lang)='RUSSIAN');
end;

procedure TCore.OnAppExit;
begin
  if (Core.Prefs.ReadBool('PlayList.EraseOnExit')) then
    Core.PlayList.Clear;
  PostQuitMessage(0);
  Inc(HC);
  if HC > 40 then ForcedTermination;
end;

function TCore.AppVersion: String;
begin
  Result:=VerInfo.FormatInfo('{MAJ}.{MIN}');
end;

procedure TCore.DestroyAllVCLForms;
var
  l:LongInt;
  Form:TForm;
begin
  repeat
    Form:=NIL;
    for l:=0 to Application.ComponentCount-1 do
      if (Application.Components[l] is TForm) then begin
        Form:=Application.Components[l] as TForm;
        Break;
      end;
    if Assigned(Form) then begin
      Log('Core.DestroyForm('+Form.ClassName+')');
      Form.Free;
    end;
  until (Form=NIL);
end;

procedure TCore.ReloadLang;
var
  Lang:String;
begin
  Lang:=Prefs.ReadString('FrontEnd.Language');

  LangMgr.Clear;
  LangMgr.OverloadFromResource('LangEn');
  if (Lang='Russian') then begin
    LangMgr.OverloadFromResource('LangRu')
  end else if (Lang<>'English') then begin
    LangMgr.OverloadFromFile(ExtractFilePath(ParamStr(0))+'Langs\'+Lang+'.txt');
  end;
end;

procedure TCore.LoadPrefs;
var
  FS:TFileStream;
  FN:String;
  CS:TCachedStream;
begin
  XTree:=TXMLTree.Create;

  FN:=ChangeFileExt(Application.ExeName,'.xml');
  if FileExists(FN) then begin
    FS:=TFileStream.Create(FN,fmOpenRead or fmShareDenyWrite);
    CS:=TCachedStream.Create(FS,2,4096);
    XTree.LoadFromStream(CS);
    CS.Free;
    FS.Free;
  end else begin
    Prefs:=TXMLPrefs.Create(XTree.Root);
    InitPrefs;
    Prefs.Free;
  end;

  Prefs:=TXMLPrefs.Create(XTree.Root);
  if not(SysHlp.IsNT) then Exit;
  if not(Prefs.Bool['App.IsMultiUser']) then Exit;

  FN:=SysHlp.GetPersonalAppDataFolder+'LightAlloy\LA.xml';
  if FileExists(FN) then begin
    Prefs.Free;
    FS:=TFileStream.Create(FN,fmOpenRead or fmShareDenyWrite);
    CS:=TCachedStream.Create(FS,2,4096);
    XTree.LoadFromStream(CS);
    CS.Free;
    FS.Free;
    Prefs:=TXMLPrefs.Create(XTree.Root);

    if (Prefs.ReadInteger('App.UserPrefs')=0) then begin
      FN:=SysHlp.GetCommonAppDataFolder+'LightAlloy\LA.xml';
      if FileExists(FN) then begin
        Prefs.Free;
        FS:=TFileStream.Create(FN,fmOpenRead or fmShareDenyWrite);
        CS:=TCachedStream.Create(FS,2,4096);
        XTree.LoadFromStream(CS);
        CS.Free;
        FS.Free;
        Prefs:=TXMLPrefs.Create(XTree.Root);
      end;
    end;
  end;
end;

procedure TCore.SavePrefs;
var
  FN:String;
begin
  XTree.Root.SetAttr('name',VerInfo.FormatInfo('{P}'));
  XTree.Root.SetAttr('version',VerInfo.FormatInfo('{MAJ}.{MIN}'));
  XTree.Root.SetAttr('build',VerInfo.FormatInfo('{B}'));

  FN:=ChangeFileExt(Application.ExeName,'.xml');
  try
    XTree.SaveToFile(FN);
  except end;

  if (SysHlp.IsNT and Prefs.Bool['App.IsMultiUser']) then begin
    FN:=SysHlp.GetPersonalAppDataFolder+'LightAlloy\';
    CreateDir(FN);
    try
      XTree.SaveToFile(FN+'LA.xml');
    except end;
    if (Prefs.ReadInteger('App.UserPrefs')=0) then begin
      FN:=SysHlp.GetCommonAppDataFolder+'LightAlloy\';
      CreateDir(FN);
      try
        XTree.SaveToFile(FN+'LA.xml');
      except end;
    end;
  end;

  if AndFree then begin
    Prefs.Free;
    XTree.Free;
  end;
end;

procedure TCore.ShowGUI;
var
  Skin:String;
begin
  Log('+TCore.ShowGUI');
  Skin:=Prefs.ReadString('FrontEnd.Skin');
  Log('Skin=<'+Skin+'>');
  frMain.LoadSkin(Skin);
  frMain.Show;
  frMain.Repaint;
  Log('-TCore.ShowGUI');
end;

procedure TCore.HideGUI;
begin
  frMain.Hide;
end;

procedure TCore.ProcessCmdLine;
var
  index: Cardinal;
  List:TStringList;
  FirstAddedEntry: Cardinal;
  Replace:Boolean;
  CP:TCmdParams;
  Ext:String;
begin
  Log('+TCore.ProcessCmdLine');
  CP:=TCmdParams.Create;
  CP.ParseCmdLine(CmdLine);

  Replace:=not(CP.IsParamSet('/ADD'));
  List:=CP.GetFileList;

  if (List.Count=0) then begin
    Log('No params');
    if frMain.IsMinimized then frMain.Restore;
    SysHlp.PopupWindow(Application.Handle);
  end else
  begin
    INI.Str['FrontEnd.MediaDir']:=ExtractFilePath(List[0]);
    if Replace and not(INI.Bool['PlayList.AddInsteadReplacing']) then PlayList.Clear;
    FirstAddedEntry:=Core.PlayList.Entries.Count;
    PlayList.AddList(List);
    if Replace then begin
      Log('Exec Play');
      if INI.Bool['PlayList.AddInsteadReplacing'] then begin
        frMain.PlayGrid.SelIndex:=FirstAddedEntry;
        for index:=0 to Core.PlayList.Entries.Count-1 do begin
          if Core.PlayList.Entries[index].FileName = List[0] then
            frMain.PlayGrid.SelIndex:=Index;
        end;
        frMain.PlayGrid.PlaySelection;
      end
      else
        frMain.PostponedPlay:=TRUE;
    end;

    Ext:=ExtractFileExt(List[0]);
    Ext:=Copy(Ext,2,10);
    if (ExplInt.GetExtType(Ext)='V') then begin
      if frMain.IsMinimized then frMain.Restore;
      SysHlp.PopupWindow(Application.Handle);
    end;
  end;

  List.Free;
  CP.Free;

  Log('-TCore.ProcessCmdLine');
end;

procedure TCore.ReloadSkin;
var
  Skin,FileName:String;
begin
  Skin:=Prefs.ReadString('FrontEnd.Skin');
  if SameText(ExtractFileExt(Skin),'.ZIP') then begin
    HideGUI;
    ShowGUI;
  end else begin
    frMain.LoadSkin(Skin);
    frMain.LoadCover(FileName);
    frMain.FullRepaint;
  end;
end;

procedure TCore.OnTimer;
begin
  CheckAppProxy;
  //ConsChecker.Tick;
  OSDMgr.Tick;
  if HC > 0 then begin
    Inc(HC);
    PostQuitMessage(0);
    if HC > 8 then
      ForcedTermination;
  end;
  TimerNotifier.Notify;
end;

procedure TCore.CheckAppProxy;
var
  Param:String;
  sTime,sPath,sCmdLn:string;
  l:LongInt;
  t:TDateTime;
  Diff:Double;
begin
  while AppPxWnd.IsParams do begin
    Param:=AppPxWnd.PopParam;
    Log('Core.PlayParam('+Param+')');

    l:=Pos('|',Param);
    if (l>0) then begin
      sTime:=Copy(Param,1,l-1);
      Param:=Copy(Param,l+1,Length(Param)-l);
      l:=Pos('|',Param);
      if (l>0) then begin
        sPath:=Copy(Param,1,l-1);
        sCmdLn:=Copy(Param,l+1,Length(Param)-l);

        try
          t:=StrToFloat(sTime)/MSecsPerDay;
        except
          t:=0;
        end;

        Diff:=Abs(LastWinCmd-t)*MSecsPerDay;
        LastWinCmd:=t;
        Log(Format('Diff:%f ms',[Diff]));
        if (Diff<500) then sCmdLn:=sCmdLn+' /ADD';

        Log('SetDir: '+sPath);
        SetCurrentDir(sPath);
        Log('ExecCmd: '+sCmdLn);
        ProcessCmdLine(sCmdLn);
      end;
    end;
  end;
end;

procedure TCore.Info;
begin
  if Assigned(OSDMgr) then
    OSDMgr.Info(Msg);
end;

procedure TCore.StopAppProxy;
begin
  AppPxWnd.Active:=FALSE;
end;

procedure TCore.E;
begin
  if FAILED(hR) then
    Log(Format('!E:%.8x (%s)',[hR,Scope]));
end;

function TCore.AppHandle: HWND;
begin
  Result:=Application.Handle;
end;

function TCore.GetPrefsDir;
begin
  Result:=ExtractFilePath(Application.ExeName);

  if (SysHlp.IsNT and Prefs.ReadBool('App.IsMultiUser')) then begin
    Result:=SysHlp.GetPersonalAppDataFolder+'LightAlloy\';
    if (Prefs.ReadInteger('App.UserPrefs')=0) then begin
      Result:=SysHlp.GetCommonAppDataFolder+'LightAlloy\';
    end;
  end;

  Result:=IncludeTrailingPathDelimiter(Result);
  CreateDir(Result);
end;

procedure TCore.CheckInfoParam;
var
  List:TStringList;
begin
  if not(CmdParams.IsParamSet('/INFO')) then Exit;

  List:=CmdParams.GetFileList;
  if (List.Count>0) then
    frMain.FileInfo(List[0]);
  List.Free;
  Halt;
end;

function TCore.DSH;
begin
  Result:=DShowHlp.DSH;
end;

function TCore.Player;
begin
  Result:=NIL;
  if Assigned(PlayList) then Result:=PlayList.Player;
end;

function TCore.ExeName: String;
begin
  Result:=Application.ExeName;
end;

const
  IDC_HAND = MakeIntResource(32649);

procedure TCore.FixCursor;
begin
  Screen.Cursors[crHandPoint]:=LoadCursor(0,IDC_HAND);
end;

procedure TCore.UnInstall;
var
  SL:TStringList;
  l:LongInt;
  Ext:String;
begin
  ExplInt:=TExplorerIntegrator.Create;
  ExplInt.Prefs:=Prefs.CreateSubPrefs('FileTypes');

  SL:=ExplInt.GetMaskList('*');
  for l:=0 to SL.Count-1 do begin
    Ext:=SL[l];
    ExplInt.Associate(Ext,FALSE);
  end;
  SL.Free;

  ExplInt.UpdateIcons;

  ExplInt.Prefs.Free;
  FreeAndNIL(ExplInt);
end;

procedure TCore.Install;
begin
  Core:=Self;
  ExplInt:=TExplorerIntegrator.Create;
  ExplInt.Prefs:=Prefs.CreateSubPrefs('FileTypes');
  
  ExplInt.Associate('LAP',TRUE);

  ExplInt.Associate('3GP',True);
  ExplInt.Associate('ASF',True);
  ExplInt.Associate('AVI',True);
  ExplInt.Associate('DIVX',True);
  ExplInt.Associate('FLV',True);
  ExplInt.Associate('M1V',True);
  ExplInt.Associate('M2V',True);
  ExplInt.Associate('MKV',True);
  ExplInt.Associate('MOV',True);
  ExplInt.Associate('MP4',True);
  ExplInt.Associate('MPE',True);
  ExplInt.Associate('MPG',True);
  ExplInt.Associate('MPEG',True);
  ExplInt.Associate('MPV',True);
  ExplInt.Associate('OGM',True);
  ExplInt.Associate('QT',True);
  ExplInt.Associate('RM',True);
  ExplInt.Associate('RMVB',True);
  ExplInt.Associate('RV',True);
  ExplInt.Associate('WEBM',True);
  ExplInt.Associate('TS',True);
  ExplInt.Associate('MTS',True);
  ExplInt.Associate('M2TS',True);
  ExplInt.Associate('WM',True);
  ExplInt.Associate('WMV',True);

  ExplInt.UpdateIcons;

  ExplInt.Prefs.Free;
  FreeAndNIL(ExplInt);
end;

procedure TCore.InitPrefs;
var
  id:LCID;
  RS:TResourceStream;
  S:String;
begin
  Log('+TCore.InitPrefs');
  Prefs.Free;

  RS:=TResourceStream.Create(0,'InitPrefs',RT_RCDATA);
  XTree.LoadFromStream(RS);
  RS.Free;

  Prefs:=TXMLPrefs.Create(XTree.Root);
  with Prefs do begin
    Int['OSD.Info.Font.Charset']:=Screen.HintFont.Charset;
    Int['Subtitles.Charset']:=Screen.HintFont.Charset;

    id:=GetUserDefaultLangID;
    id:=id and $3FF;
    S:='Russian';
    case id of
      LANG_RUSSIAN:S:='Russian';
      LANG_FRENCH:S:='French';
      LANG_DUTCH:S:='Dutch';
      LANG_GERMAN:S:='German';
      LANG_SPANISH:S:='Spanish';
      LANG_UKRAINIAN:S:='Ukrainian';
      LANG_BELARUSIAN:S:='Belarusian';
      LANG_LITHUANIAN:S:='Lithuanian';
      LANG_ROMANIAN:S:='Romanian';
      LANG_TURKISH:S:='Turkish';
      LANG_POLISH:S:='Polish';
    end;
    Str['FrontEnd.Language']:=S;
  end;
  Log('-TCore.InitPrefs');
end;

procedure TCore.UpgradePrefs;
var
  PrefsBuild,AppBuild:String;
  RS:TResourceStream;
  XTreeLocal:TXMLTree;
  PrefsLocal:TXMLPrefs;
  ANode,CNode:TXMLNode;
  i: Integer;

  procedure UpgradeNode(Address: String; var Node:TXMLNode);
  var
    i: Integer;
    s: String;
  begin
    if Address<>'' then
     Address:=Address+'.';

    if (Address<>'') and (Address<>'FileTypes.EXT.') and (Address<>'GlobalKeys.Keys.') then
      for i:=0 to High(Node.Attrs) do begin
        S:=Prefs.ReadString(Address+Node.Attrs[i].Name);
        if S<>'' then
          Node.Attrs[i].Value:=S;
        S:='';
      end;

    for i:=0 to High(Node.Nodes) do
      UpgradeNode(Address+Node.Nodes[i].Tag,Node.Nodes[i]);
  end;

begin
  Log('+TCore.UpgradePrefs');
  PrefsBuild:=XTree.Root.Attr('build');
  AppBuild:=VerInfo.FormatInfo('{B}');
  Log('= AppBuild: ' + AppBuild + ', PrefsBuild: ' + PrefsBuild);
  if (AppBuild<>PrefsBuild) then begin
    RS:=TResourceStream.Create(0,'InitPrefs',RT_RCDATA);
    XTreeLocal:=TXMLTree.Create;
    XTreeLocal.LoadFromStream(RS);
    PrefsLocal:=TXMLPrefs.Create(XTreeLocal.Root);

    ANode:=PrefsLocal.RootNode;
    UpgradeNode('',ANode);

    ANode := PrefsLocal.RootNode.Node('GlobalKeys');
    CNode := XTree.Root.Node('GlobalKeys');
    for i:=0 to Length(ANode.Nodes)-1 do
    begin
      if i < Length(CNode.Nodes) then begin
        ANode.Nodes[i].Attrs[1].Value:=CNode.Nodes[i].Attrs[1].Value;
        ANode.Nodes[i].Attrs[2].Value:=CNode.Nodes[i].Attrs[2].Value;
      end;
    end;

    if StrToInt(PrefsBuild) <= 1188 then begin
      if PrefsLocal.ReadInteger('Video.VideoRenderer') = 5 then
        PrefsLocal.WriteInteger('Video.VideoRenderer',4);
    end;

    if PrefsLocal.ReadString('OSD.Info.Font.Family') = 'Arial Narrow' then
      PrefsLocal.WriteString(('OSD.Info.Font.Family'),'Arial');

    Prefs.Free;
    XTree.Free;
    XTree:=TXMLTree.Create;
    XTree.Root:=XTreelocal.Root;
    Prefs:=TXMLPrefs.Create(PrefsLocal.RootNode);
  end;
  Log('-TCore.UpgradePrefs');
end;

function TCore.ExePath: String;
begin
  Result:=ExtractFilePath(ExeName);
end;

procedure TCore.Cmd(LAC: Integer);
begin
  ExecuteLACommand(LAC);
end;

procedure TCore.Exec(CmdName: String);
begin
  if SameText(CmdName,'App.OpenFiles') then
    Cmd(LAC_FILE_OPEN);
  if SameText(CmdName,'Player.Pause') then
    Cmd(LAC_PLAYBACK_STOP);
end;

procedure TCore.SavePlayList;
begin
  PlayList.SaveToLAP(GetPrefsDir+'LA.lap');
  INI.Int['Last.PlayListIdx']:=PlayList.PlayPos;
  INI.Str['Last.FileName']:='';
  if (PlayList.PlayPos>=0) then
    INI.Str['Last.FileName']:=PlayList.Entries[PlayList.PlayPos].FileName;
end;

function TCore.SysText(Template: String): String;
var
  S:String;
  Hour,Min,Sec,MSec:WORD;
begin
  if (Pos('{TIME}',Template)>0) then begin
    DecodeTime(Time,Hour,Min,Sec,MSec);
    if (Sec and 1)=0 then
      S:=':'
    else
      S:=' ';
    S:=Format('%.2d%s%.2d',[Hour,S,Min]);
    Template:=StringReplace(Template,'{TIME}',S,[rfReplaceAll]);
  end;

  if (Pos('{POS}',Template)>0) then begin
    S:='0:00:00';
    if (Player<>NIL) then begin
      S:=Core.SysHlp.FormatHNS('{H}:{M}:{S}',Core.Player.Pos);
    end;
    Template:=StringReplace(Template,'{POS}',S,[rfReplaceAll]);
  end;

  if (Pos('{DUR}',Template)>0) then begin
    S:='0:00:00';
    if (Player<>NIL) then begin
      S:=Core.SysHlp.FormatHNS('{H}:{M}:{S}',Core.Player.MaxPos);
    end;
    Template:=StringReplace(Template,'{DUR}',S,[rfReplaceAll]);
  end;

  if (Pos('{TITLE}',Template)>0) then begin
    S:='Light Alloy';
    if Assigned(frMain) then
      S:=frMain.LACaption.Caption;
    Template:=StringReplace(Template,'{TITLE}',S,[rfReplaceAll]);
  end;

  Result:=Template;
end;

function TCore.GetVolume: LongInt;
begin
  Result:=0;
  if Assigned(frMain) then
    Result:=frMain.tbVolume.Position;
end;

procedure TCore.SetVolume(V: Integer);
begin
  if Assigned(frMain) then
    frMain.tbVolume.Position:=V;
end;

procedure TCore.ForcedTermination;
begin
  if HC = 0 then Exit;
  Log('=== !Forced termination ===');
  Halt;
end;

end.
