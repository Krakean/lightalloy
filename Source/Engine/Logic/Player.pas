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
unit Player;

interface

uses
  // RTL / VCL
  Windows, Classes, SysUtils, ShellAPI, Forms,

  // Engine
  NICE, CachedFile, MultiLog, XML, CmdC, CachedStream, uMediaInfo,
  AdvGraphBuilder, DShowHlp, FilterBase, Codecs, DSGraphLog,
  VideoPropsModel, AudioPropsModel, SoundOut, EQMdl, DAMdl;

type
  TPlayer = class(TObject)
  private
    DSH:TDirectShowHelper;
    AGBld:TAdvancedGraphBuilder;
    FileHash64K:String;

    procedure OnDSHComplete(Sender:TObject);
    procedure CleanUp;
    procedure SetSubtitles;

    procedure UpdateMediaCache(FileName:String);
    procedure SaveMediaSettings;
    procedure ApplyMediaSettings;

    procedure LogGraph;
  public
    OnComplete:TBlindHandler;
    LoadedFileName:String;
    MI:TMediaInfo;

    constructor Create;
    destructor Destroy; override;

    procedure Rewind;
    function Pos:Int64;
    function MaxPos:Int64;
    procedure SetSoundOut;
    procedure SeekTo(NewPos:Int64);
    procedure PlayFile(FileName:String);

    procedure Progress(S:String);
  end;

var
  DivxSMExeFound: Boolean;

implementation

uses
  LACore, MainUnit, XMLPrefs, SysHlp, FocusLA, OtherGlobalVars;

{ TPlayer }

constructor TPlayer.Create;
begin
  inherited Create;
  DSH:=Core.DSH;
  DSH.OnComplete:=OnDSHComplete;
end;

destructor TPlayer.Destroy;
begin
  SaveMediaSettings;
  DSH.Stop;
  DSH.OnComplete:=NIL;
  CleanUp;
  if Assigned(MI) then MI.Free;
  inherited Destroy;
end;

procedure TPlayer.OnDSHComplete(Sender: TObject);
begin
  DSH.Pause;
  if INI.Bool['OnDone.Rewind'] then DSH.SeekTo(0);
  if Assigned(OnComplete) then OnComplete;
end;

procedure TPlayer.PlayFile;
var
  hR:HRESULT;
  S,SoundFileName:string;
  CFile:TCachedFile;
  FStrm:TFileStream;
  ChStrm:TCachedStream;
  Ok:Boolean;

  Pos:Int64;
begin
  Log('+TPlayer.PlayFile('+FileName+')');
  DSH.MetaTags.Title := '';
  frMain.SetCaption('');
  Progress('>');

  IsUrl:=(System.Pos(':/', FileName)<>0);
  if not(Core.SysHlp.IsFileExists(FileName)) and not(IsURL) then
  begin
    If not Core.Prefs.ReadBool('OSD.Info.AlertMsg') then
      Core.Alert((MS('Command.Category.0'))+'"'+FileName+'"'+(MS('Core.Alert.NotFound')))
    else
      Core.Info((MS('Command.Category.0'))+'"'+FileName+'"'+(MS('Core.Alert.NotFound')));
    Log('-TPlayer.PlayFile(not found)');
    Exit;
  end;

  if not(IsURL) then begin
    CFile:=TCachedFile.Create(FileName);
    MI:=TMediaInfo.Create(CFile)
  end
  else
    MI:=TMediaInfo.Create(FileName);
  MI.RetreiveInfo;
  FreeAndNil(CFile);

  FocusLA.DivxSMExeFound := False;

  frMain.LoadCover(FileName);

  if not(IsURL) then begin
    FStrm:=TFileStream.Create(FileName,fmOpenRead or fmShareDenyNone);
    ChStrm:=TCachedStream.Create(FStrm,8,65536);
  end;

  Log('TPlayer.PlayFile: CreateBuilder');
  DSH.IsDVD:=MI.FInfo.FileFormat='IFO';

  DSH.CreateBuilder;
  Progress('-');

  AGBld:=TAdvancedGraphBuilder.Create(DSH);
  Ok:=AGBld.Render(FileName);

  if not(Ok) then
  begin
    if not Core.Prefs.ReadBool('OSD.Info.AlertMsg') then begin
      if (frCodecs=NIL) then frCodecs:=TfrCodecs.Create(NIL);
      if IsURL then frMain.SetCaption(Core.VerInfo.FormatInfo('{P} {MAJ}.{MIN}{RI}'));
      frCodecs.ShowRequest(AGBld.MissReq);
      Core.Alert(MS('Error.RenderError')+#13#10+FileName)
    end else
      Core.Info(MS('Error.RenderError')+#13#10+FileName);
    Log('-TPlayer.PlayFile: MissReq: '+AGBld.MissReq);
    CleanUp;
    Exit;
  end;

  if not(AGBld.CompleteRender) then begin
    if not Core.Prefs.ReadBool('OSD.Info.AlertMsg') then begin
      if (frCodecs=NIL) then
        frCodecs:=TfrCodecs.Create(NIL);
      frCodecs.ShowRequest(AGBld.MissReq);
    end else
      if (AGBld.MissReq<>'') then
        DSH.DSError:=MS('DS.Err00040242')+' '+AGBld.MissReq;
  end;

  LogGraph;

  Log('TPlayer.PlayFile: CheckForAV');
  DSH.CheckForAV;

  Log('TPlayer.PlayFile: CreateVideoModel');
  frMain.VideoModel:=TVideoPropsModel.Create;

  if DSH.HasVideo and Core.Prefs.ReadBool('Sound.AddSound') then begin
    SoundFileName:=ChangeFileExt(FileName, '.wav');
    if not(FileExists(SoundFileName)) then
      SoundFileName:=ChangeFileExt(FileName, '.mp3');
    if not (FileExists(SoundFileName)) then
      SoundFileName := ChangeFileExt(FileName, '.wma');
    if not (FileExists(SoundFileName)) then
      SoundFileName := ChangeFileExt(FileName, '.ogg');
    if not (FileExists(SoundFileName)) then
      SoundFileName := ChangeFileExt(FileName, '.ac3');
    if not (FileExists(SoundFileName)) then
      SoundFileName := ChangeFileExt(FileName, '.aac');
    if not (FileExists(SoundFileName)) then
      SoundFileName := ChangeFileExt(FileName, '.mka');
    if FileExists(SoundFileName) then begin
      Progress('a');
      Log('TPlayer.PlayFile: AddSound('+SoundFileName+')');
      hR:=DSH.RenderFile(SoundFileName);
      if FAILED(hR) then
        LogHR('TPlayer.PlayFile: AddSound FAILED',hR);
    end;
  end;

  Log('TPlayer.PlayFile: SetSoundOut');
  SetSoundOut;
  SetSubtitles;

  LoadedFileName:=FileName;

  Progress('-');
  Log('TPlayer.PlayFile: DetectVideoFPS');
  try
    DSH.DetectVideoFPS;
    Log(Format('FPS=%1.7f (%d hns)',[10000000/DSH.VideoFPS,DSH.VideoFPS]));
  except
  end;

  Core.Subs.Clear;
  Core.Subs.SetVideoFPS(10000000/DSH.VideoFPS);
  frMain.InitSubs;
  if Core.Prefs.Bool['Subtitles.AutoLoad'] then begin
    Progress('s');
    Log('TPlayer.PlayFile: SearchForSubtitles');
    Core.Subs.SearchSubtitles(FileName);
    Log('TPlayer.PlayFile: SearchForSubtitles-done');
  end;

  // It is DIVX, is it?
  if System.Pos('divx', PChar(LowerCase(MI.CodecSummary))) > 0 then
    IsDIVX := True
  else
    IsDIVX := False;

  Progress('-');
  //Core.ConsChecker.Load(3);

  Log('TPlayer.PlayFile: SetOwner');
  if DSH.HasVideo then
    if not DSH.IsFilterConnectedByCLSID(VideoRenderers[scEVR].CLSID) then
      DSH.SetOwner(frMain.pnVideo.Handle)
    else
      DSH.SetOwner(frMain.pnVideo.InternalPanel.Handle);
  frMain.tbPos.Max:=DSH.Duration;

  Log('TPlayer.PlayFile: OnOpen');
  if DSH.HasVideo then
  begin
    Log('TPlayer.PlayFile: OnOpen.HidePanels');
    if (Core.Prefs.ReadBool('OnOpen.HidePanels')) and (frMain.pnControl.Visible) then
      frMain.TogglePanels
    else if (not Core.Prefs.ReadBool('OnOpen.HidePanels'))
                and (Core.Prefs.ReadBool('OnOpen.FullScreen')) then
      Center.ProcessCommand(LAC_WINDOW_CONTROL_PANEL);

    Log('TPlayer.PlayFile: OnOpen.Resize');
    if (Core.Prefs.ReadBool('OnOpen.Resize'))
      and not(frMain.HoverButtons[hiFullScreen].Down)
  //    and not(Core.Prefs.ReadBool('OnOpen.FullScreen'))
    then
      frMain.ResizeScaled(-1);

    Log('TPlayer.PlayFile: OnOpen.Center');
    if (Core.Prefs.ReadBool('OnOpen.Center'))
      and not(frMain.HoverButtons[hiFullScreen].Down)
  //    and not(Core.Prefs.ReadBool('OnOpen.FullScreen'))
    then
      frMain.CenterForm;

    Log('TPlayer.PlayFile: OnOpen.FullScreen');
    if (Core.Prefs.ReadBool('OnOpen.FullScreen')) and not(frMain.HoverButtons[hiFullScreen].Down) then
      Center.ProcessCommand(LAC_WINDOW_FULLSCREEN);

    Log('TPlayer.PlayFile: MapVideoWindow');
    frMain.MapVideoWindow;
  end;

  Log('TPlayer.PlayFile: TAudioPropsModel.Create');
  frMain.AudioModel:=TAudioPropsModel.Create(DSH);
  frMain.EQModel:=TEQModel.Create(DSH);
  frMain.DAModel:=TDAModel.Create(DSH);

  if not(DSH.IsDVD) then
  begin
    frMain.Pause;
  end;
  //Core.ConsChecker.Load(4);

  Log('TPlayer.PlayFile: EnableControls');
  frMain.EnableControls(TRUE);
  Log('TPlayer.PlayFile: EnableTimer');
  frMain.Timer.Enabled:=TRUE;

  if DSH.HasAudio then
  begin
    Log('TPlayer.PlayFile: SetVolume');
    frMain.SetVolume;
    frMain.EQModel.UpdateBands;
  end;
  //Core.ConsChecker.Load(5);

  Log('TPlayer.PlayFile: Set playing title');
  if not(IsURL) or (DSH.MetaTags.Title = '') then begin
    S:=Core.PlayList.GetPlayingTitle;
    Application.Title:=S+' - Light Alloy';
    frMain.Caption:=S+' - Light Alloy';
  end
  else
    S:=DSH.MetaTags.Title;
  frMain.SetCaption(S);

  if frMain.TrayUsed then begin
    StrPCopy(frMain.IconData.szTip,Copy(S,1,63));
    Shell_NotifyIcon(NIM_MODIFY,@frMain.IconData);
  end;

  Center.ProcessCommand(LAC_PLAYBACK_PLAY);

  //Core.ConsChecker.Load(7);

  if DSH.HasVideo then frMain.HideLogo;
  if not(DSH.IsDVD) then DSH.Run;

  //frMain.IsCorrupted:=800-Core.ConsChecker.Idx;
  //if (Core.ConsChecker.Idx<800) then :=7;

  if not(IsURL) then begin
    ChStrm.Free;
    FStrm.Free;
  end;

  UpdateMediaCache(FileName);
  ApplyMediaSettings;


  if Core.Prefs.ReadBool('OnOpen.AutoSeek')
    and (((dsh.Duration div 1800000000) = (lastDur div 1800000000)) or  (lastDur = 0))
    and (OpeningSeekPos > 0) then
  begin
    Log('TPlayer.PlayFile: OnOpen.AutoSeek');
    Pos:=OpeningSeekPos;
    DSH.SeekTo(pos);
  end;

  if not(IsURL) then
    frMain.FileOSDInfo(FileName);

  if (DSH <> NIL) and DSH.HasVideo and (not AppInTrayNow) then
  begin
    if frMain.bActive then
      FocusApp;//Core.SysHlp.PopupWindow(frMain.Handle);
  end;

  Log('TPlayer.PlayFile: OnOpen.Play');

  if (ItWasPausedBeforeNMR) then
    Center.ProcessCommand(LAC_PLAYBACK_STOP);

  frMain.UpdateSubFont;
  firstfsm:=True;
  OnOpenFsm:=True;
  Seek_A_B := 0;

  CurBmk := -1;
  NewBmk := 0;

  Log('-TPlayer.PlayFile');
end;

function TPlayer.Pos;
begin
  Result:=DSH.Position;
end;

procedure TPlayer.Rewind;
begin
  DSH.SeekTo(0);
end;

procedure TPlayer.Progress;
begin
  frMain.SetCaption(S+frMain.LACaption.Caption);
  frMain.Repaint;
end;

procedure TPlayer.CleanUp;
begin
  DSH.Stop;
  FreeAndNIL(AGBld);
  FreeAndNIL(frMain.AudioModel);
  FreeAndNIL(frMain.VideoModel);
  FreeAndNIL(frMain.EQModel);
  FreeAndNIL(frMain.DAModel);
  LoadedFileName:='';
  DSH.DestroyBuilder;
  frMain.EnableControls(FALSE);
  Core.Subs.Clear;
end;

procedure TPlayer.SeekTo;
begin
  DSH.SeekTo(NewPos);
end;

procedure TPlayer.SetSoundOut;
var
  SD:String;
  SO:TSoundOut;
begin
  Log('+TPlayer.SetSoundOut');
  SD:=Core.Prefs.ReadString('Sound.OutDevice');

  if SameText(SD,'Default DirectSound Device') then SD:='';
  if (SD<>'') then begin
    SO:=TSoundOut.Create;
    SO.ReplaceAudioRenderer;
    SO.Free;
  end;
  Log('-TPlayer.SetSoundOut');
end;

procedure TPlayer.UpdateMediaCache;
var
  X:TXMLNode;
  FN:String;
begin
  IsUrl:=(System.Pos(':/',FileName) <> 0);
  if not IsURL then begin
    FN:=ExpandFileName(FileName);

    X:=Core.MediaCache.GetOrCreateInfo(FN);
    X.SetAttr('dur',IntToStr(DSH.Duration));

    FileHash64K:=Core.MediaCache.GetFile64KHash(FN);
    X.SetAttr('hash64k',FileHash64K);

    FN2:=Fn;
    X2:=X;
    File2Hash64k:=FileHash64K;
    x2.SetAttr('hash64k',File2Hash64k);
  end;
end;

procedure TPlayer.SaveMediaSettings;
var
  X:TXMLNode;
  Br,Co,Sa:LongInt;
  Zoom,Ratio:TPoint;
begin
  if (FileHash64K='') then Exit;

  X:=Core.MediaSets.GetOrCreateInfo(FileHash64K);
  X.SetAttr('PlayPos',IntToStr(DSH.Position));

  if (DSH.VideoControlName<>'') then begin
    DSH.GetBCS(Br,Co,Sa);
    if (Br=50) and (Co=50) and (Sa=50) then begin
      X.SetAttr('BCS','')
    end else begin
      X.SetAttr('BCS',Core.SysHlp.IntsToStr(',',[Br,Co,Sa]));
    end;
  end;

  if Assigned(frMain.VideoModel) then begin
    Zoom:=frMain.VideoModel.Zoom;
    if (Zoom.X=100) and (Zoom.Y=100) then begin
      X.SetAttr('Zoom','');
    end else begin
      X.SetAttr('Zoom',Core.SysHlp.PointToStr(Zoom));
    end;

    Ratio:=frMain.VideoModel.Ratio;
    if (Ratio.X=0) and (Ratio.Y=0) then begin
      X.SetAttr('AR','');
    end else begin
      X.SetAttr('AR',Core.SysHlp.IntsToStr(':',[Ratio.X,Ratio.Y]));
    end;
  end;
end;

procedure TPlayer.ApplyMediaSettings;
var
  X:TXMLNode;
  S:String;
  Pos:Int64;
  Br,Co,Sa:LongInt;
  Zoom:TPoint;
  P:TPoint;
  MinDur: Int64;
begin
  if (FileHash64K='') then Exit;

  X:=Core.MediaSets.GetInfo(FileHash64K);
  if (X=NIL) then Exit;

  MinDur:=Core.Prefs.ReadInteger('Media.MinMediaDur');
  if (INI.Bool['OnOpen.SeekLastPos'] or isMediaReloadNeeded) and (DSH.Duration >= MinDur*600000000) then begin
    S:=X.Attr('PlayPos');
    if (S<>'') then begin
      try
        Pos:=StrToInt64(S);
        DSH.SeekTo(Pos);
      except
      end;
    end;
  end;

  if not(INI.Bool['OnOpen.ApplySettings']) then Exit;

  if (DSH.VideoControlName<>'') then begin
    S:=X.Attr('BCS');
    if (S<>'') then begin
      Br:=Core.SysHlp.IntParam(S,0);
      Co:=Core.SysHlp.IntParam(S,1);
      Sa:=Core.SysHlp.IntParam(S,2);
      if (Br<>50) or (Co<>50) or (Sa<>50) then
        DSH.SetBCS(Br,Co,Sa);
    end;
  end;

  if Assigned(frMain.VideoModel) then begin
    S:=X.Attr('Zoom');
    if (S<>'') then begin
      Zoom:=Core.SysHlp.StrToPoint(S);
      frMain.VideoModel.SetZoom(Zoom);
    end;

    S:=X.Attr('AR');
    if (S<>'') then begin
      P.X:=Core.SysHlp.IntParam(S,0);
      P.Y:=Core.SysHlp.IntParam(S,1);
      frMain.SetAspectRatio(P.X,P.Y);
    end;
  end;
end;

procedure TPlayer.LogGraph;
var
  GL:TDSGraphLogger;
begin
  GL:=TDSGraphLogger.Create;
  Log(GL.GraphAsText(DSH.Graph));
  GL.Free;
end;

function TPlayer.MaxPos: Int64;
begin
  Result:=DSH.Duration;
end;

procedure TPlayer.SetSubtitles;
begin
  if Core.Prefs.ReadBool('Modules.DirectShow.DisableSubs')
    and DSH.HasVideo
  then
    AGBld.DisableSubs;
end;

end.