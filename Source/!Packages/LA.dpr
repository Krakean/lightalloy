program LA;

uses
  // FastMemoryManager / FastStrings
  FastMM4 in '..\Common\FastLibs\FastMM4.pas',
  FastMove in '..\Common\FastLibs\FastMove.pas',
  FastCode in '..\Common\FastLibs\FastCode.pas', // NOT mandatory, just remove it if you haven't EurekaLog
  FastMM4Messages in '..\Common\FastLibs\FastMM4Messages.pas',
  FastStrings in '..\Common\FastLibs\FastStrings.pas',
  FastStringFuncs in '..\Common\FastLibs\FastStringFuncs.pas',

  // RTL / VCL
  Forms,
  Windows,
  SysUtils,

  // Forms
  About in '..\UI\about.pas' {frAbout},
  Codecs in '..\UI\Codecs.pas' {frCodecs},
  Config in '..\UI\Preferences\config.pas' {frConfig},
  Error in '..\UI\Error.pas' {frError},
  Filter in '..\UI\Filter.pas' {frFilter},
  Filters in '..\UI\filters.pas' {frFilters},
  Info in '..\UI\info.pas' {frInfo},
  MainUnit in '..\UI\MainUnit.pas' {frMain},
  Subtitles in '..\UI\Subtitles.pas' {frSubtitles},
  AdvPList in '..\UI\AdvPList.pas' {frAdvPList},
  Alert in '..\UI\Alert.pas' {frAlert},
  JumpToFile in '..\UI\JumpToFile.pas' {frJumpToFile},
  ShutDownForm in '..\UI\ShutDownForm.pas' {frShutdown},
  OpenURLDialog in '..\UI\OpenURLDialog.pas' {frOpenURL},
  VideoProps in '..\UI\VideoProps.pas' {frVideoProps},
  AudioProps in '..\UI\AudioProps.pas' {frAudioProps},

  // Components
  BrandBrd in '..\Components\BrandBrd.pas',
  BrandCtl in '..\Components\BrandCtl.pas',
  HoverBt in '..\Components\HoverBt.pas',
  VideoPanel in '..\Components\VideoPanel.pas',
  OSDPanel in '..\Components\OSDPanel.pas',

  // Engine
  AMixerFull in '..\Engine\Graph\Sound\AMixerFull.pas',
  CPUUsage in '..\Engine\Logic\Modules\CPUUsage.pas',
  DShowHlp in '..\Engine\DShowHlp.pas',
  PlayGrid in '..\Engine\Logic\Playlist\PlayGrid.pas',
  AdvGraphBuilder in '..\Engine\Graph\AdvGraphBuilder.pas',
  EventCodeNames in '..\Engine\Graph\EventCodeNames.pas',
  AppLogic in '..\Engine\Logic\AppLogic.pas',
  CmdC in '..\Engine\Logic\CmdC.pas',
  DSGraphLog in '..\Engine\Graph\DSGraphLog.pas',
  FilterCommander in '..\Engine\Graph\FilterCommander.pas',
  FilterBase in '..\Engine\Graph\FilterBase.pas',
  GlobalKeys in '..\Engine\Logic\GlobalKeys.pas',
  LACore in '..\Engine\LACore.pas',
  ModMgr in '..\Engine\Logic\ModMgr.pas',
  Module in '..\Engine\Logic\Modules\Module.pas',
  MultiLog in '..\Engine\MultiLog.pas',
  ExplInt in '..\Engine\Logic\ExplInt.pas',
  FullPopupMenu in '..\Engine\Logic\FullPopupMenu.pas',
  VideoProcessor in '..\Engine\VideoProcessor.pas',
  CmdExec in '..\Engine\Logic\CmdExec.pas',
  FourCC in '..\Engine\MediaInfo\FourCC.pas',
  FilterLib in '..\Engine\Graph\FilterLib.pas',
  FilterBox in '..\Engine\Graph\FilterBox.pas',
  FilterControl in '..\Engine\Graph\FilterControl.pas',
  EQMdl in '..\Engine\EQMdl.pas',
  DAMdl in '..\Engine\DAMdl.pas',
  DivXIntf in '..\Engine\Graph\DivXIntf.pas',
  SpecialIntf in '..\Engine\Graph\SpecialIntf.pas',
  SoundOut in '..\Engine\Graph\Sound\SoundOut.pas',
  SubVoicePlayer in '..\Engine\Logic\SubVoicePlayer.pas',
  MediaCache in '..\Engine\Logic\MediaCache.pas',
  MediaSettings in '..\Engine\Logic\MediaSettings.pas',
  OSDManager in '..\Engine\Logic\OSDManager.pas',
  OSDPainter in '..\Engine\Logic\OSDPainter.pas',
  PLView in '..\Engine\Logic\Playlist\PLView.pas',
  DurSniffer in '..\Engine\Logic\DurSniffer.pas',
  uMediaInfo in '..\Engine\MediaInfo\uMediaInfo.pas',
  uWinAMP in '..\Engine\Logic\Modules\uWinAMP.pas',
  AudioPropsModel in '..\Engine\Logic\Models\AudioPropsModel.pas',
  VideoPropsModel in '..\Engine\Logic\Models\VideoPropsModel.pas',
  SoundGlobal in '..\Engine\Graph\Sound\SoundGlobal.pas',
  SubsModel in '..\Engine\Logic\Models\SubsModel.pas',
  Shuffle in '..\Engine\Logic\Playlist\Shuffle.pas',
  SysHlp in '..\Engine\SysHlp.pas',
  PlayList in '..\Engine\Logic\Playlist\PlayList.pas',
  Player in '..\Engine\Logic\Player.pas',
  WinLIRC in '..\Engine\Logic\Modules\WinLIRC.pas',

  // Common
  AudioProcessor in '..\Common\AudioProcessor\AudioProcessor.pas',
  FocusLA in '..\Common\FocusLA.pas',
  FontHelper in '..\Common\FontHelper.pas',
  HttpDownload in '..\Common\HttpDownload.pas',
  MMkeys in '..\Common\MMkeys.pas',
  OtherGlobalVars in '..\Common\OtherGlobalVars.pas',

  GdipApi in '..\Common\GdipApi.pas',
  GdipObj in '..\Common\GdipObj.pas',
  GdipUtils in '..\Common\GdipUtils.pas',

  // Preferences
  ConfigPage in '..\UI\Preferences\ConfigPage.pas' {ConfigPageForm},
  CfgPgFileTypes in '..\UI\Preferences\CfgPgFileTypes.pas' {CPFileTypes},
  CfgPgPlayList in '..\UI\Preferences\CfgPgPlayList.pas' {CPPlayList},
  CfgPgGlobalKeys in '..\UI\Preferences\CfgPgGlobalKeys.pas' {CPGlobalKeys},
  CfgPgDirectShow in '..\UI\Preferences\CfgPgDirectShow.pas' {CPDirectShow},
  CfgPgWinAMP in '..\UI\Preferences\CfgPgWinAMP.pas' {CPWinAMP},
  CfgPgAviSynth in '..\UI\Preferences\CfgPgAviSynth.pas' {CPAviSynth},
  CfgPgWinLIRC in '..\UI\Preferences\CfgPgWinLIRC.pas' {CPWinLIRC},
  CfgPgInterface in '..\UI\Preferences\CfgPgInterface.pas' {CPInterface},
  CfgPgMouse in '..\UI\Preferences\CfgPgMouse.pas' {CPMouse},
  CfgPgEvents in '..\UI\Preferences\CfgPgEvents.pas' {CPEvents},
  CfgPgVideo in '..\UI\Preferences\CfgPgVideo.pas' {CPVideo},
  CfgPgSound in '..\UI\Preferences\CfgPgSound.pas' {CPSound},
  CfgPgSystem in '..\UI\Preferences\CfgPgSystem.pas' {CPSystem},
  CfgPgOSD in '..\UI\Preferences\CfgPgOSD.pas' {CPOSD},
  CfgPgKeyboard in '..\UI\Preferences\CfgPgKeyboard.pas' {CPKeyboard},

  // Without sources
  AMixer in 'AMixer.pas',
  DVDProps in 'DVDProps.pas' {frDVDProps},
  SubStream in 'SubStream.pas',
  YVImage in 'YVImage.pas',
  YVOSD in 'YVOSD.pas',

  // Skin engine
  OptiPanel in 'OptiPanel.pas',
  OptiBuilder in 'OptiBuilder.pas',
  OptiRes in 'OptiRes.pas',
  OptiImage in 'OptiImage.pas',
  OptiBtn in '..\Components\OptiBtn.pas',
  OptiUtils in 'OptiUtils.pas',
  OptiWrapper in 'OptiWrapper.pas',
  OptiSeeker in '..\Components\OptiSeeker.pas',
  OptiText in '..\Components\OptiText.pas',
  OptiFont in 'OptiFont.pas',
  OptiSlider in '..\Components\OptiSlider.pas',

  stFile in '..\Common\stFile.pas',
  stAVITag in '..\Engine\MediaInfo\Video\stAVITag.pas',

  // Audio Tools Library
  atlAACfile in '..\Engine\MediaInfo\Audio\atlAACfile.pas',
  atlAC3 in '..\Engine\MediaInfo\Audio\atlAC3.pas',
  atlAPEtag in '..\Engine\MediaInfo\Audio\atlAPEtag.pas',
  atlCDAtrack in '..\Engine\MediaInfo\Audio\atlCDAtrack.pas',
  atlDTS in '..\Engine\MediaInfo\Audio\atlDTS.pas',
  atlFLACfile in '..\Engine\MediaInfo\Audio\atlFLACfile.pas',
  atlFPLfile in '..\Engine\MediaInfo\Audio\atlFPLfile.pas',
  atlID3v1 in '..\Engine\MediaInfo\Audio\atlID3v1.pas',
  atlID3v2 in '..\Engine\MediaInfo\Audio\atlID3v2.pas',
  atlMonkey in '..\Engine\MediaInfo\Audio\atlMonkey.pas',
  atlMPEGaudio in '..\Engine\MediaInfo\Audio\atlMPEGaudio.pas',
  atlMPEGplus in '..\Engine\MediaInfo\Audio\atlMPEGplus.pas',
  atlMusepack in '..\Engine\MediaInfo\Audio\atlMusepack.pas',
  atlOggVorbis in '..\Engine\MediaInfo\Audio\atlOggVorbis.pas',
  atlOptimFROG in '..\Engine\MediaInfo\Audio\atlOptimFROG.pas',
  atlSpeex in '..\Engine\MediaInfo\Audio\atlSpeex.pas',
  atlTTA in '..\Engine\MediaInfo\Audio\atlTTA.pas',
  atlTwinVQ in '..\Engine\MediaInfo\Audio\atlTwinVQ.pas',
  atlVorbisComment in '..\Engine\MediaInfo\Audio\atlVorbisComment.pas',  
  atlWAVfile in '..\Engine\MediaInfo\Audio\atlWAVfile.pas',
  atlWAVPackfile in '..\Engine\MediaInfo\Audio\atlWAVPackfile.pas',
  atlWMAfile in '..\Engine\MediaInfo\Audio\atlWMAfile.pas';

{$R *.RES}
{$R ..\!Res\LAPACK.RES}

begin
  Core:=TCore.Create;

  Application.Initialize;
  Application.CreateForm(TfrMain, frMain);
  Application.ShowMainForm:=FALSE;

  Core.CheckInfoParam;
  Core.ShowGUI;
  Log('=== Application has been shown');
  Core.LoadModules;

  Core.ProcessCmdLine(System.CmdLine);
  Log('=== Application is responsible');
  Application.Run;
  Core.StopAppProxy;
  Core.HideGUI;
  Log('=== Application has been hidden');

  Core.FreeModules;
  Core.Free;
end.
