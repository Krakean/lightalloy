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

unit DShowHlp;

interface

uses
  // Windows
  Windows, ActiveX, Registry, Messages,
  // VCL
  Classes, Forms, SysUtils, ComObj,
  // Core
  MultiLog,
  // DirectShow
  DirectShow9, FilterBase, FilterLib, EventCodeNames,
  // Interfaces
  DivXIntf, SpecialIntf, DCBassSourceIntf, EVR9,
  // Filters
  VideoProcessor, AudioProcessor, dspConst;

const
  WM_MEDIAEVENT = WM_USER;

  MEDIATYPE_Subtitle: TGUID = '{E487EB08-6B26-4BE9-9DD3-993434D313FD}';

  MEDIASUBTYPE_Ogg: TGUID = '{D2855FA9-61A7-4db0-B979-71F297C17A04}';
  MEDIASUBTYPE_Vorbis: TGUID = '{cddca2d5-6d75-4f98-840e-737bedd5c63b}';
  MEDIASUBTYPE_Vorbis2: TGUID = '{8D2FD10B-5841-4A6B-8905-588FEC1ADED9}';

  MEDIASUBTYPE_NV11: TGUID = '{3131564e-0000-0010-8000-00aa00389b71}';
  MEDIASUBTYPE_NV24: TGUID = '{3432564E-0000-0010-8000-00AA00389B71}';
  MEDIASUBTYPE_I420: TGUID = '{30323449-0000-0010-8000-00AA00389B71}';

  MEDIASUBTYPE_P010: TGUID = '{30313050-0000-0010-8000-00AA00389B71}';
  MEDIASUBTYPE_P016: TGUID = '{36313050-0000-0010-8000-00AA00389B71}';
  MEDIASUBTYPE_P210: TGUID = '{30313250-0000-0010-8000-00AA00389B71}';
  MEDIASUBTYPE_P216: TGUID = '{36313250-0000-0010-8000-00AA00389B71}';
  MEDIASUBTYPE_Y416: TGUID = '{36313459-0000-0010-8000-00AA00389B71}';

  DXVA_ModeMPEG2_A: TGUID = '{1B81BE0A-A0C7-11D3-B984-00C04F2E73C5}';
  DXVA_ModeMPEG2_C: TGUID = '{1B81BE0C-A0C7-11D3-B984-00C04F2E73C5}';
  DXVA_ModeH264_E: TGUID = '{1B81BE68-A0C7-11D3-B984-00C04F2E73C5}';
  DXVA_ModeH264_F: TGUID = '{1B81BE69-A0C7-11D3-B984-00C04F2E73C5}';

  PT_ALL = 0;
  PT_AUDIO = 1;
  PT_VIDEO = 2;

type
  TRealIndex = array [0..1023] of Cardinal;

  TMetaTags = packed record
    Title: string;
    URL: string;
    SName: string;
    Genre: string;
    Bitrate: string;
    SURL: string;
  end;

  TDirectShowHelper = class(TObject)
  private
    Brightness: Integer;
    Contrast: Integer;
    Saturation: Integer;
  public
    Graph:IGraphBuilder;
    MediaControl:IMediaControl;
    VideoWindow:IVideoWindow;
    BasicVideo:IBasicVideo;

    DVDControl:IDVDControl2;
    DVDInfo:IDVDInfo2;

    VMRMixerControl9:IVMRMixerControl9;
    MFVideoDisplayControl:IMFVideoDisplayControl;
    MFVideoProcessor:IMFVideoProcessor;

    MediaSeeking:IMediaSeeking;
    MediaEventEx:IMediaEventEx;
    ROTEntry:LongInt;
    OnComplete:TNotifyEvent;

    UseROT:Boolean;

    EventWND:HWND;
    VideoWidth,VideoHeight:LongInt;
    HasVideo,HasAudio:Boolean;
    VideoFPS:Int64;

    IsDVD:Boolean;

    MetaTags: TMetaTags;
    DivXModule:HMODULE;
    DVDPos,DVDDur:TDVDHMSFTIMECODE;
    MediaDur:Int64;
    DVDLangNames:array of String;
    ARenderers:array of IBaseFilter;
    AudioStreamCount:Cardinal;
    SubsStreamCount:Cardinal;
    DSError:String;

    FLibrary:TFilterLibrary;

    constructor Create;
    destructor Destroy; override;
    {General}
    procedure E(hR:HRESULT;Scope:string);
    function GetErrorText(hR:HRESULT):string;
    procedure CreateBuilder;
    procedure DestroyBuilder;
    function RenderFile(FileName:string):HRESULT;
    procedure SetVideoRenderer;
    procedure SetAudioRenderers(SavePrevious: Boolean = False);
    procedure SetProcessors;
    procedure SetForcedFilters;
    procedure RemoveFreeVideoRenderer;
    procedure RemoveFreeAudioRenderer;
    procedure ClearGraph;
    procedure Stop;
    procedure Pause;
    procedure Run;
    procedure Repaint;
    procedure SeekTo(NewPos:Int64);
    procedure OnMediaEvent(var Message:TMessage);
    procedure ProcessMediaEvent(EvCode,P1,P2:Longint);
    function Position:Int64;
    function Duration:Int64;
    procedure SetRate(Rate:Double);
    procedure FrameStep(Steps:DWORD);
    procedure CheckForAV;
    procedure SetOwner(Wnd:HWND);
    procedure SizeVideoWnd(VRect: TRect);
    function ScreenShot(FileName:string;NanoPos:int64;SSFName:string):Boolean;
    procedure MouseMove(P:TPoint);
    procedure MouseClick(P:TPoint);
    {DVD}
    procedure DVDMenu;
    function BuildDVDGraph(out DVDNav:IBaseFilter):Boolean;
    function GetDVDTitlesCount:LongInt;
    function GetAudioLangCount:LongInt;
    procedure SwitchCCOff;
    function IsDVDMenu:Boolean;
    procedure PlayTitle(Index:LongInt);
    procedure SetDVDAudio(Index:LongInt);
    {Filters}
    procedure DisconnectFilter(Filter:IBaseFilter);
    function GetFilter(CLSID:TGUID):IBaseFilter;
    function GetNthFilter(CLSID:TGUID;N:LongInt):IBaseFilter;
    function CreateFilter(CLSID:TGUID):IBaseFilter; overload;
    function CreateFilter(CLSID:TGUID;out HR:HRESULT):IBaseFilter; overload;
    function ConnectFilters(FSrc,FDest:IBaseFilter; PAM:PAMMEDIATYPE = NIL):HRESULT;
    function ConnectPinToFilter(PinO:IPin;Flt:IBaseFilter; PAM:PAMMEDIATYPE = NIL):HRESULT;
    function IsFilterConnected(Filter:IBaseFilter;PinDir:TPINDIRECTION):Boolean;
    function IsFilterConnectedByCLSID(ID: TGUID):Boolean;
    procedure FilterProperties(hWnd:THandle;Filter:IUnknown);
    function HasProperties(Filter:IUnknown):boolean;
    function GetCLSID(Obj:IUnknown):TGUID;
    function NextFilter(Filter:IBaseFilter):IBaseFilter;
    function PrevFilter(Filter:IBaseFilter):IBaseFilter;
    function GetFilterName(Filter:IBaseFilter):string;
    function GetFilterFileName(CLSID:TGUID):string;
    function GetFilterVersion(FileName:string): string;
    function GetFilterFriendlyName(CLSID:TGUID):string;

    function GetVideoDecoder:IBaseFilter;
    function GetVideoProcessor:IBaseFilter;
    function GetVideoProcProps(Filter:IBaseFilter = NIL):PVideoProcProps;
    function GetVideoRenderer:IBaseFilter;

    function GetAudioDecoder(Index:LongInt):IBaseFilter;
    function GetAudioProcessor:IBaseFilter;
    function GetAudioRendererCount:LongInt;
    function GetAudioRenderer(Index:LongInt = 0):IBaseFilter;

    function GetBalance(Index:LongInt):LongInt;
    function GetVolume(Index:LongInt):LongInt;
    function GetEQBand(Index: Byte): Single;
    function GetEQPreAmp: Single;
    function GetDAEnabled: Bool;
    function GetDAMaxAmplify: Cardinal;
    procedure SetBalance(Index,Balance:LongInt);
    procedure SetVolume(Index,Volume:LongInt);
    procedure SetEQBand(Index: Byte; const Value: Single);
    procedure SetEQPreAmp(Value: Single);
    procedure SetDAEnabled(Value: Bool);
    procedure SetDAMaxAmplify(Value: Cardinal);
    {Streams}
    procedure TearDownStream(Head:IBaseFilter);
    {Pins}
    function FindPin(Pins:IEnumPins;PinDir:TPINDIRECTION;PinType:Byte=0):IPin;
    function GetPin(Filter:IBaseFilter;PinDir:TPINDIRECTION;PinType:Byte=0):IPin;
    function GetUnconnectedPin(Filter:IBaseFilter;PinDir:TPINDIRECTION;PinType:Byte=0):IPin;
    function IsPinConnected(Pin:IPin):Boolean;
    function FindUnconnectedPin:IPin;
    function GetParentFilter(Pin:IPin):IBaseFilter;
    {BCS}
    function VideoControlName:String;

    procedure GetBCS(var B:LongInt;var C:LongInt;var S:LongInt; HideWarnings:Boolean = False);
    procedure SetBCS(NewB,NewC,NewS:LongInt);
    procedure AdjustBCS(DeltaB,DeltaC,DeltaS:LongInt);

    procedure GetBCS_VideoProc(var B:LongInt;var C:LongInt;var S:LongInt);
    procedure GetBCS_DivX4(var B:LongInt;var C:LongInt;var S:LongInt);
    procedure GetBCS_DivX5(var B:LongInt;var C:LongInt;var S:LongInt);
    procedure GetBCS_VMRMixerControl9(var B:LongInt;var C:LongInt;var S:LongInt);
    procedure GetBCS_MFVideoProc(var B:LongInt;var C:LongInt;var S:LongInt);

    procedure SetBCS_VideoProc(NewB,NewC,NewS:LongInt);
    procedure SetBCS_DivX4(NewB,NewC,NewS:LongInt);
    procedure SetBCS_DivX5(NewB,NewC,NewS:LongInt);
    procedure SetBCS_VMRMixerControl9(B:LongInt;C:LongInt;S:LongInt);
    procedure SetBCS_MFVideoProc(B:LongInt;C:LongInt;S:LongInt);

    {Special}
    function IsMediaDetAvail:Boolean;
    procedure DeleteMediaType(pMT:PAMMEDIATYPE);
    procedure FreeMediaType(AM:TAMMEDIATYPE);
    procedure DetectVideoFPS;

    {StreamSelect Alternative Model}
    procedure EnableStream(FilterGraph: IFilterGraph; StreamSelect: IAMStreamSelect; Index: Integer);
    function GetStreamSelector(out StreamSelector: IBaseFilter): Boolean;

    function AStreamSelectAvaible: Boolean;
    function GetAudioStream:Cardinal;
    procedure SetAudioStream(Index:Cardinal);
    property AStreamCount:Cardinal read AudioStreamCount;

    function SStreamSelectAvaible: Boolean;
    function GetSubsStream:Cardinal;
    procedure SetSubsStream(Index:Cardinal);
    property SStreamCount:Cardinal read SubsStreamCount;
  end;

var
  scEVR: Byte;
  scVMR9: Byte;
  scMADVR: Byte;
  DSH: TDirectShowHelper;
  IsShoutCast: Boolean = FALSE;

// -----------------------------------------------------------------------------

implementation

uses
  MainUnit, LACore, OtherGlobalVars;

var
  ARealIndex: TRealIndex;
  SRealIndex: TRealIndex;

function TDirectShowHelper.ScreenShot;
var
  MediaDet:IMediaDet;
  Streams,i:longint;
  guid:TGUID;
  Found:boolean;
  W,H:longint;
  AM:TAMMEDIATYPE;

  GraphState:TFilterState;
  FilterState:TFilterState;
  ImageBuf:Pointer;
  Size:Integer;

  BH:BITMAPINFOHEADER;
  SizeEx:Cardinal;
  TS:Int64;

  FileHandle:THandle;
  BytesWritten:DWORD;
  FH:BITMAPFILEHEADER;
begin
  Log('+TDirectShowHelper.ScreenShot(FileName: ' + FileName + ', NanoPos: ' + IntToStr(NanoPos) + ', SSFileName: ' + SSFName + ')');
  Result:=False;
  if Core.Prefs.ReadBool('FrontEnd.FastScreenShots')  then begin
    Log('Used MediaDet');
    E(CoCreateInstance(CLSID_MediaDet,NIL,CLSCTX_INPROC,IID_IMediaDet,MediaDet),'CoCreateInstance');
    if (MediaDet.put_FileName(FileName)<>S_OK) then begin
      Log('-TDirectShowHelper.ScreenShot: MediaDet file render error!');
      Exit;
    end;
    E(MediaDet.get_OutputStreams(Streams),'MediaDet.get_OutputStreams');
    Found:=FALSE;
    W:=100;
    H:=100;
    for i:=0 to Streams-1 do
    begin
      E(MediaDet.put_CurrentStream(i),'MediaDet.put_CurrentStream');
      E(MediaDet.get_StreamType(guid),'MediaDet.get_StreamType');
      if IsEqualGUID(guid,KSDATAFORMAT_TYPE_VIDEO) then begin
        E(MediaDet.get_StreamMediaType(AM),'MediaDet.get_StreamMediaType');
        if IsEqualGUID(AM.FormatType,FORMAT_VideoInfo) then begin
          W:=TVIDEOINFOHEADER(AM.pbFormat^).bmiHeader.biWidth;
          H:=TVIDEOINFOHEADER(AM.pbFormat^).bmiHeader.biHeight;
        end;
        FreeMediaType(AM);
        Found:=TRUE;
      end;
      if Found then Break;
    end;
    if Found then
      if Succeeded(MediaDet.WriteBitmapBits(NanoPos/10000000,W,H,SSFName)) then
        Result:=True;
  end
  else begin
    ImageBuf:=NIL;
    Size:=0;
    SizeEx:=0;

    // --- if Enhanced Video Renderer ------
    if MFVideoDisplayControl<>NIL then begin
      Log('Used VideoDisplayControl');

      MediaControl.GetState(1000, GraphState);
      MediaControl.Pause;
      repeat
        MediaControl.GetState(1000, FilterState);
      until (FilterState = State_Paused)or(FilterState = State_Stopped);

      BH.biSize := SizeOf(BITMAPINFOHEADER);
      MFVideoDisplayControl.GetCurrentImage(@BH,ImageBuf,SizeEx,@TS);
      SizeEx:=(BH.biWidth * BH.biHeight) * 32;
      try
        GetMem(ImageBuf, SizeEx);
      except
        ImageBuf:=NIL;
      end;
      MFVideoDisplayControl.GetCurrentImage(@BH,ImageBuf,SizeEx,@TS);
      if GraphState=State_Running then MediaControl.Run;

      if( SSFName='') or (ImageBuf=nil) then begin
        Log('-TDirectShowHelper.ScreenShot: Wrong ImageBuf!');
        Exit;
      end;
      FileHandle:=CreateFile(PChar(SSFName), GENERIC_WRITE, FILE_SHARE_READ, nil, CREATE_ALWAYS, 0, 0 );
      if FileHandle = INVALID_HANDLE_VALUE then begin
        CloseHandle(FileHandle);
        Log('-TDirectShowHelper.ScreenShot: Wrong file handle!');
        Exit;
      end;

      FH.bfType := $4D42; // 'B' 'M'
      FH.bfSize := SizeOf(BITMAPINFOHEADER)+SizeEx;
      FH.bfReserved1 := 0;
      FH.bfReserved2 := 0;
      FH.bfOffBits := SizeOf(BITMAPFILEHEADER)+SizeOf(BITMAPINFOHEADER);

      WriteFile(FileHandle, FH, SizeOf(BITMAPFILEHEADER), BytesWritten, nil);
      WriteFile(FileHandle, BH, SizeOf(BITMAPINFOHEADER), BytesWritten, nil);
      WriteFile(FileHandle, ImageBuf^, SizeEx, BytesWritten, nil);
      Result:= (BytesWritten > 0);

      CloseHandle(FileHandle);

      Log('-TDirectShowHelper.ScreenShot: '+BoolToStr(Result));
      Exit;
    end;

    // --- With other Video Renderers ------
    Log('Used BasicVideo');
    if BasicVideo=NIL then begin
      Log('-TDirectShowHelper.ScreenShot: Have no BasicVideo interface!');
      Exit;
    end;

    MediaControl.GetState(1000, GraphState);
    MediaControl.Pause;
    repeat
      MediaControl.GetState(1000, FilterState);
    until (FilterState = State_Paused)or(FilterState = State_Stopped);

    BasicVideo.GetCurrentImage(Size,ImageBuf^);
    try
      GetMem(ImageBuf, Size);
    except
      ImageBuf:=NIL;
    end;
    BasicVideo.GetCurrentImage(Size,ImageBuf^);
    if GraphState=State_Running then
      MediaControl.Run;

    if( SSFName='') or (ImageBuf=nil) then begin
      Log('-TDirectShowHelper.ScreenShot: Wrong ImageBuf!');
      Exit;
    end;
    FileHandle:=CreateFile(PChar(SSFName), GENERIC_WRITE, FILE_SHARE_READ, nil, CREATE_ALWAYS, 0, 0 );
    if FileHandle = INVALID_HANDLE_VALUE then begin
      CloseHandle(FileHandle);
      Log('-TDirectShowHelper.ScreenShot: Wrong file handle!');
      Exit;
    end;

    FH.bfType := $4D42; // 'B' 'M'
    FH.bfSize := SizeOf(BITMAPINFOHEADER)+Size;
    FH.bfReserved1 := 0;
    FH.bfReserved2 := 0;
    FH.bfOffBits := SizeOf(BITMAPFILEHEADER)+SizeOf(BITMAPINFOHEADER);

    WriteFile(FileHandle, FH, SizeOf(BITMAPFILEHEADER), BytesWritten, nil);
    WriteFile(FileHandle, ImageBuf^, Size, BytesWritten, nil);
    Result:= (BytesWritten > 0);

    CloseHandle(FileHandle);
  end;
  Log('-TDirectShowHelper.ScreenShot: '+BoolToStr(Result));
  MediaDet:=nil;
end;

procedure TDirectShowHelper.DeleteMediaType;
begin
  FreeMediaType(pmt^);
  CoTaskMemFree(pmt);
end;

procedure TDirectShowHelper.RemoveFreeVideoRenderer;
var
  Filter:IBaseFilter;
begin
  Filter:=GetVideoRenderer;
  if Filter=NIL then Exit;
  if not IsFilterConnected(Filter,PINDIR_INPUT) then
    Graph.RemoveFilter(Filter);
  Filter:=NIL;
end;

procedure TDirectShowHelper.RemoveFreeAudioRenderer;
var
  Filter:IBaseFilter;
  i,num: Integer;
begin
  Num:=GetAudioRendererCount-1;
  for i:=0 to Num do begin
    Filter:=GetAudioRenderer(i);
    if Filter=NIL then Exit;
    if not IsFilterConnected(Filter,PINDIR_INPUT) then
      Graph.RemoveFilter(Filter);
    Filter:=NIL;
  end;
end;

procedure TDirectShowHelper.ClearGraph;
var
  FEnum:IEnumFilters;
  Filter:IBaseFilter;
  Fetched:Cardinal;

  procedure EnumPins;
  var
    PEnum:IEnumPins;
    cPin,Pin:IPin;
    hR:HRESULT;
  begin
    E(Filter.EnumPins(PEnum),'Filter.EnumPins');
    PEnum.Reset;
    while (PEnum.Next(1,Pin,NIL)=S_OK) do begin
      hR:=Pin.ConnectedTo(cPin);
      if (hR<>VFW_E_NOT_CONNECTED) then begin
        E(hR,'Pin.ConnectedTo');
        E(Graph.Disconnect(cPin),'Graph.Disconnect(cPin)');
        cPin:=NIL;
        E(Graph.Disconnect(Pin),'Graph.Disconnect(Pin)');
      end;
      Pin:=NIL;
    end;
    PEnum:=NIL;
  end;
begin
  E(Graph.EnumFilters(FEnum),'Graph.EnumFilters');
  FEnum.Reset;

  VMRMixerControl9:=NIL;
  MFVideoDisplayControl:=NIL;
  MFVideoProcessor:=NIL;
  while (FEnum.Next(1,Filter,@Fetched)=S_OK) do begin
    EnumPins;

    E(Graph.RemoveFilter(Filter),'Graph.RemoveFilter');
    Filter:=NIL;
    E(FEnum.Reset,'FEnum.Reset');
  end;
  Brightness:=50;
  Contrast:=50;
  Saturation:=50;  
  AudioStreamCount:=0;
  SubsStreamCount:=0;
  FLibrary.ActiveLocalFilters.Clear;
  FEnum:=NIL;
  MediaDur:=0;
end;

constructor TDirectShowHelper.Create;
begin
  CoInitialize(NIL);

  inherited Create;
  FLibrary:=TFilterLibrary.Create(Core.ExePath);

  Graph:=NIL;
  MediaControl:=NIL;
  VideoWindow:=NIL;
  MediaSeeking:=NIL;
  OnComplete:=NIL;

  VideoWidth:=0;
  VideoHeight:=0;

  UseROT:=FALSE;
  IsDVD:=FALSE;

  scEVR:=vrEVR;
  scVMR9:=vrVMR9;
  scMADVR:=vrMadVR;
end;

procedure TDirectShowHelper.SetVideoRenderer;
var
  CLSID:TGUID;
  HR:HRESULT;
  MonName:string;
  Filter:IBaseFilter;
  Name:array[0..MAX_PATH-1] of WChar;
  Index:Integer;
begin
  if (Core.Player<>NIL) and (not IsDVD) then begin
    if (Core.Player.MI<>NIL) and not IsURL then
      if (Length(Core.Player.MI.FInfo.VStreams)<=0) then
        Exit;
  end;
  Filter:=GetVideoRenderer;
  if Filter<>NIL then Exit;

  Index:=Core.Prefs.ReadInteger('Video.VideoRenderer');
  // If Windows vers. > XP, then set to EVR
  if ((not Core.SysHlp.IsExpirienceFamily) and (Index=0)) then Index:=scEVR;

  // To prevent unsupported renderer for DVD
  if IsDVD and (Index<2) then Index:=2;

  // Create specified renderer
  if (Index>1) then begin
    CLSID:=VideoRenderers[Index].CLSID;
    MonName:=VideoRenderers[Index].Name;
    Filter:=CreateFilter(CLSID,HR);
    LogHR('SetVideoRenderer: '+VideoRenderers[Index].Name,HR);
  end;

  // Otherwise create default renderer
  if Filter=NIL then begin
    CLSID:=CLSID_VideoRendererDefault;
    Filter:=CreateFilter(CLSID);
    MonName:=VideoRenderers[1].Name;
  end;

  MultiByteToWideChar(CP_ACP,0,PChar(MonName),-1,@Name,MAX_PATH);
  if Filter<>NIL then
    Graph.AddFilter(Filter,Name);

  // Get VMR9 specific interfaces
  if IsEqualGUID(CLSID,VideoRenderers[scVMR9].CLSID) then begin
    if (Filter <> NIL) and Core.Prefs.ReadBool('Video.HardwareProcessing') then begin
      // VMRMixerControl9 works only with mixing mode
      (Filter as IVMRFilterConfig9).SetNumberOfStreams(1);
      Filter.QueryInterface(IID_IVMRMixerControl9,VMRMixerControl9);
    end;
  end;

  // Get EVR specific interfaces
  if IsEqualGUID(CLSID,VideoRenderers[scEVR].CLSID) then
  try
    if Filter <> NIL then begin
      (Filter as IMFGetService).GetService(MR_VIDEO_RENDER_SERVICE, IID_IMFVideoDisplayControl, MFVideoDisplayControl);
      (Filter as IMFGetService).GetService(MR_VIDEO_MIXER_SERVICE, IID_IMFVideoProcessor, MFVideoProcessor);
    end;
  except
  end;
  Filter:=NIL;
end;

procedure TDirectShowHelper.SetAudioRenderers;
var
  FEnum:IEnumFilters;
  Filter:IBaseFilter;
  Fetched:LongInt;
  Cnt:LongInt;
  A:array of IBaseFilter;
  i,j:LongInt;
  Skip:Boolean;
begin
  Cnt:=0;
  if not(Assigned(Graph)) then Exit;
  if not SUCCEEDED(Graph.EnumFilters(FEnum)) then Exit;
  FEnum.Reset;

  if SavePrevious then Cnt:=DSH.GetAudioRendererCount;

  while (FEnum.Next(1,Filter,@Fetched)=S_OK) do begin
    if IsEqualGUID(GetCLSID(Filter),CLSID_DSoundRender)
      or IsEqualGUID(GetCLSID(Filter),CLSID_AudioRender)
      or IsEqualGUID(GetCLSID(Filter),AudioRenderers[0].CLSID)
      or IsEqualGUID(GetCLSID(Filter),AudioRenderers[1].CLSID)
    then begin
      if IsFilterConnected(Filter,PINDIR_INPUT) then begin
        if not SavePrevious then begin
          Inc(Cnt,1);
          SetLength(A,Cnt);
          A[Cnt-1]:=Filter;
        end
        else begin
          Skip:=False;
          for i:=0 to Cnt-1 do
            if GetFilterName(Filter)=GetFilterName(ARenderers[i]) then Skip:=True;
          if not Skip then begin
            Inc(Cnt,1);
            SetLength(ARenderers,Cnt);
            ARenderers[Cnt-1]:=Filter;
          end;
        end;
      end;
    end;
  end;

  if SavePrevious then Exit;

  // Need inverted renderers array
  j:=0;
  SetLength(ARenderers,Cnt);
  for i:=Cnt-1 downto 0 do begin
    Inc(J,1);
    ARenderers[j-1]:=A[i];
  end;
end;

procedure TDirectShowHelper.SetProcessors;
var
  Filter:IBaseFilter;
  VideoProc:TVideoProcessor;
  AudioProc:TAudioProcessor;
  Props:PVideoProcProps;
begin
  if IsDVD then Exit;

  // Set VideoProcessor
  Filter:=GetVideoProcessor;
  if (Filter=NIL) and Core.Prefs.ReadBool('Video.VideoProcessor') then
  begin
    VideoProc:=TVideoProcessor.Create('Video Processor',NIL,CLSID_VideoProcessor);
    E(Graph.AddFilter((VideoProc as IBaseFilter),'Video Processor'),'Graph.AddFilter(VideoProcessor)');
    (VideoProc as IVideoProcessor).GetProps(Props);
    if Core.Prefs.ReadBool('OSD.WithVideo') or (MFVideoDisplayControl<>NIL)
    then
      Props.RestrictYV12:=True;
  end;

  // Set AudioProcessor
  Filter:=GetAudioProcessor;
  if (Filter=NIL) and Core.Prefs.Bool['Sound.Equalizer.Enabled'] then begin
    AudioProc := TAudioProcessor.Create('Audio Processor', NIL, CLSID_AudioProcessor);
    Graph.AddFilter((AudioProc as IBaseFilter), 'Audio Processor');
    Filter:=GetAudioProcessor;
    if Filter <> NIL then
      (Filter as IAudioProcessor).set_EQEnabled(True);
  end;
  Filter:=NIL;
end;

procedure TDirectShowHelper.SetForcedFilters;
var
  Filter:IBaseFilter;
  Name:array[0..MAX_PATH-1] of WChar;
  FList:TStringList;
  MonName:string;

  l:LongInt;
  G:TGUID;
begin
  // Set Overlay Mixer
  if not(IsDVD) and Core.Prefs.ReadBool('Video.ForceOverlay') then
  begin
    E(CoCreateInstance(CLSID_OverlayMixer2,NIL,CLSCTX_INPROC,IID_IBaseFilter,Filter),'CoCreateInstance(Overlay)');
    E(Graph.AddFilter(Filter,'OverlayMixer2'),'Graph.AddFilter(Overlay)');
    Filter:=NIL;
  end;

  //Set DirectShow Forced Filters
  FList:=TStringList.Create;
  Core.Prefs.ReadList('Modules.DirectShow.ForceFilters',FList);
  for l:=0 to (FList.Count-1) do begin
    try
      G:=StringToGUID(FList[l]);
      E(CoCreateInstance(G,NIL,CLSCTX_INPROC,IID_IBaseFilter,Filter),'CoCreateInstance(Plugin)');
      MonName:='Plugin: '+GetFilterFriendlyName(G);
      MultiByteToWideChar(CP_ACP,0,PChar(MonName),-1,@Name[0],MAX_PATH);
      E(Graph.AddFilter(Filter,Name),'Graph.AddFilter('+MonName+')');
      Filter:=NIL;
    except
    end;
  end;
  FreeAndNIL(FList);
end;

procedure TDirectShowHelper.CreateBuilder;
var
  Moniker:IMoniker;
  Delimiter,Name:array[0..MAX_PATH-1] of WChar;
  ROT:IRunningObjectTable;
  MonName:string;
  DVDNav:IBaseFilter;
begin
  // Create FilterGraph
  E(CoCreateInstance(CLSID_FilterGraph,NIL,CLSCTX_INPROC,IID_IGraphBuilder,Graph),'CoCreateInstance(FilterGraph)');

  if IsDVD then
  begin
    SetVideoRenderer;
    BuildDVDGraph(DVDNav);
    if DVDNav <> NIL then
    begin
      E(DVDNav.QueryInterface(IID_IDvdInfo2,DVDInfo),'DVDBuilder.GetDVDInterface(IDVDInfo2)');
      E(DVDNav.QueryInterface(IID_IDvdControl2,DVDControl),'DVDBuilder.GetDVDInterface(IDVDControl2)');

      DVDControl.SetOption(DVD_ResetOnStop,FALSE);
      DVDControl.SetOption(DVD_NotifyParentalLevelChange,TRUE);
      DVDControl.SetOption(DVD_HMSF_TimeCodeEvents,TRUE);
    end;
  end;

  // Get main control interfaces
  E(Graph.QueryInterface(IID_IMediaControl,MediaControl),'Graph.QueryInterface(IMediaControl)');
  E(Graph.QueryInterface(IID_IMediaEventEx,MediaEventEx),'Graph.QueryInterface(IMediaEventEx)');
  E(Graph.QueryInterface(IID_IVideoWindow,VideoWindow),'Graph.QueryInterface(IVideoWindow)');
  E(Graph.QueryInterface(IID_IMediaSeeking,MediaSeeking),'Graph.QueryInterface(IMediaSeeking)');

  EventWND:=Classes.AllocateHWND(OnMediaEvent);
  E(MediaEventEx.SetNotifyWindow(EventWND,WM_MEDIAEVENT,0),'MediaEventEx.SetNotifyWindow');

  SetVideoRenderer;
  SetProcessors;
  SetForcedFilters;

  Brightness:=50;
  Contrast:=50;
  Saturation:=50;

  // Expose Filter Graph
  UseROT:=Core.Prefs.Bool['Modules.DirectShow.ExposeGraph'];
  if (UseROT) then begin
    E(GetRunningObjectTable(0,ROT),'GetRunningObjectTable');
    MultiByteToWideChar(CP_ACP,0,'!',-1,@Delimiter,MAX_PATH);
    MonName:=Format('FilterGraph %08x pid %08x',[DWORD(Graph),GetCurrentProcessID]);
    MultiByteToWideChar(CP_ACP,0,PChar(MonName),-1,@Name,MAX_PATH);
    E(CreateItemMoniker(Delimiter,Name,Moniker),'CreateItemMoniker');
    E(ROT.Register(0,Graph,Moniker,ROTEntry),'ROT.Register');
    Moniker:=NIL;
    ROT:=NIL;
  end;
end;

destructor TDirectShowHelper.Destroy;
begin
  FLibrary.Free;
  DestroyBuilder;
  inherited;
  CoUninitialize;
end;

procedure TDirectShowHelper.DestroyBuilder;
var
  ROT:IRunningObjectTable;
  CW:DWORD;
begin
  if not(Assigned(Graph)) then Exit;

  if (UseROT) then begin
    E(GetRunningObjectTable(0,ROT),'GetRunningObjectTable');
    ROT.Revoke(ROTEntry);
    ROT:=NIL;
  end;

  if IsDVD then begin
    if Assigned(DVDControl) then
      DVDControl.Stop;
  end else begin
    if Assigned(MediaControl) then begin
      CW := Get8087CW;
      Set8087CW($133f);
      MediaControl.Stop;
      Set8087CW(CW);
    end;
  end;

  if Assigned(VideoWindow) then begin
    VideoWindow.Put_Visible(FALSE);
    VideoWindow.Put_Owner(0);
  end;

  if Assigned(MediaEventEx) then
    MediaEventEx.SetNotifyWindow(0,WM_MEDIAEVENT,0);
  Classes.DeallocateHWND(EventWND);

  if Assigned(Graph) then
    ClearGraph;
  SetLength(ARenderers,0);
  MediaEventEx:=NIL;
  MediaSeeking:=NIL;
  VideoWindow:=NIL;
  BasicVideo:=NIL;
  MediaControl:=NIL;
  VMRMixerControl9:=NIL;
  MFVideoDisplayControl:=NIL;
  MFVideoProcessor:=NIL;
  IsShoutCast:=False;
  DCBassSourceControl:=NIL;

  DVDControl:=NIL;
  DVDInfo:=NIL;

  Graph:=NIL;
end;

function TDirectShowHelper.Duration;
begin
  if IsDVD then begin
    Result:=DVDDur.bHours;
    Result:=Result*60+DVDDur.bMinutes;
    Result:=Result*60+DVDDur.bSeconds;
    Result:=Result*10000000;
  end else begin
    if (MediaDur=0) then begin
      if Assigned(MediaSeeking) then
        MediaSeeking.GetDuration(MediaDur);
    end;
    Result:=MediaDur;
  end;
end;

procedure TDirectShowHelper.E;
var
  ErrStr:string;
begin
  if FAILED(hR) then begin
    ErrStr:=GetErrorText(hR);
    ErrStr:=ErrStr+#13#10+'Scope:['+Scope+']';
    Log(ErrStr);
  end;
end;

procedure TDirectShowHelper.FilterProperties;
var
  Specify:ISpecifyPropertyPages;
  caGUID:TCAGUID;
  hR:HRESULT;
  FInfo:TFilterInf;
  WasRegistered:Boolean;
begin
  if not(Assigned(Filter)) then Exit;
  hR:=Filter.QueryInterface(IID_ISpecifyPropertyPages,Specify);
  if (hr=E_NOINTERFACE) then begin
    Core.Alert(MS('Error.NoProps'));
    Exit;
  end;

  WasRegistered:=FLibrary.IsRegisteredFilter(Filter as IBaseFilter);
  if not(WasRegistered) and FLibrary.ActiveLocalFilters.GetFInfo(Filter as IBaseFilter,FInfo) then
    FLibrary.RegisterFilter(FInfo);

  E(hR,'Filter.QueryInterface(IID_ISpecifyPropertyPages)');
  E(Specify.GetPages(caGUID),'Specify.GetPages');
  if frMain.HoverButtons[hiCapStayOnTop].Enabled then TopPosition(hwnd, true);
  E(OleCreatePropertyFrame(
    hWnd,                   // Parent window
    0,                      // x (Reserved)
    0,                      // y (Reserved)
    'Light Alloy stream',   // Caption for the dialog box
    1,                      // Number of filters
    @Filter,                // Pointer to the filter
    caGUID.cElems,          // Number of property pages
    caGUID.pElems,          // Pointer to property page CLSIDs
    0,                      // Locale identifier
    0,                      // Reserved
    NIL                     // Reserved
    ),'OleCreatePropertyFrame');
  CoTaskMemFree(caGUID.pElems);

  if not(WasRegistered) and FLibrary.ActiveLocalFilters.GetFInfo(Filter as IBaseFilter,FInfo) then
    FLibrary.UnRegisterFilter(FInfo);

  if frMain.HoverButtons[hiCapStayOnTop].Enabled then TopPosition(hwnd, false);
  Specify:=NIL;
end;

procedure TDirectShowHelper.FrameStep;
var
  VFS:IVideoFrameStep;
  Pos:Int64;
begin
  if SUCCEEDED(Graph.QueryInterface(IID_IVideoFrameStep,VFS)) then begin
    VFS.Step(Steps,NIL);
    VFS:=NIL;
  end else begin
    Pos:=Position+VideoFPS;
    SeekTo(Pos);
  end;
end;

function TDirectShowHelper.GetAudioDecoder;
var
  AudioProc: IBaseFilter;
  FEnum:IEnumFilters;
  Filter:IBaseFilter;
  Fetched,Num:LongInt;
  Pins:IEnumPins;
  Pin:IPin;
  MT:TAMMEDIATYPE;
  hR:HRESULT;
begin
  Result:=NIL;
  if not(Assigned(Graph)) then Exit;
  if not SUCCEEDED(Graph.EnumFilters(FEnum)) then Exit;
  AudioProc:=GetAudioProcessor;

  Num:=GetAudioRendererCount-1;
  if AStreamSelectAvaible then Num:=AudioStreamCount-1;

  while (FEnum.Next(1,Filter,@Fetched)=S_OK) do begin
    E(Filter.EnumPins(Pins),'Filter.EnumPins');
    Pin:=FindPin(Pins,PINDIR_OUTPUT);
    if Assigned(Pin) then begin
      hR:=Pin.ConnectionMediaType(MT);
      if SUCCEEDED(hR)
        and (IsEqualGUID(MT.FormatType,FORMAT_WAVEFORMATEX))
        and (IsEqualGUID(MT.SubType,MEDIASUBTYPE_PCM) or (IsEqualGUID(MT.SubType,MEDIASUBTYPE_IEEE_FLOAT)))
      then begin
        if (Filter=(AudioProc as IBaseFilter)) then Continue;
        Result:=Filter;
        if (Num=Index) then begin Result:=Filter; Exit; end;
        Dec (Num);
      end;
      FreeMediaType(MT);
    end;
    Filter:=NIL;
  end;
  FEnum:=NIL;
end;

function TDirectShowHelper.GetCLSID(Obj: IUnknown): TGUID;
var
  P:IPersist;
  G:TGUID;
begin
  g:=GUID_NULL;
  if (SUCCEEDED(Obj.QueryInterface(IID_IPersist,P))) then
    E(P.GetClassID(G),'P.GetClassID');
  P:=NIL;
  Result:=G;
end;

function TDirectShowHelper.GetFilterName;
var
  i:Integer;
  FInfo:TFILTERINFO;
  Name:array[0..255] of char;
  CLSID: TGUID;
begin
  E(Filter.QueryFilterInfo(FInfo),'Filter.QueryInfo');
  WideCharToMultiByte(CP_ACP,0,FInfo.achName,-1,Name,256,NIL,NIL);
  FInfo.pGraph:=NIL;

  CLSID:=GetCLSID(Filter);
  for i:=0 to Length(VideoRenderers)-1 do begin
    if IsEqualGUID(CLSID,VideoRenderers[i].CLSID) then
      Result:=VideoRenderers[i].NAME;
  end;
  Result:=Name;
end;

function TDirectShowHelper.IsPinConnected(Pin: IPin): Boolean;
var
  CPin:IPin;
  hR:HResult;
begin
  Result:=FALSE;
  if not(Assigned(Pin)) then Exit;
  hR:=Pin.ConnectedTo(CPin);
  if SUCCEEDED(hR) then begin
    Result:=TRUE;
    CPin:=NIL;
  end;
end;

function TDirectShowHelper.FindPin;
var
  RPin,Pin:IPin;
  PDir:TPINDIRECTION;
  MT:PAMMEDIATYPE;
  MediaTypes:IEnumMediaTypes;
  Fetched:Cardinal;
begin
  RPin:=NIL;
  E(Pins.Reset,'Pins.Reset');
  while not(Assigned(RPin)) and (Pins.Next(1,Pin,@Fetched)=S_OK) do begin
    E(Pin.QueryDirection(PDir),'Pin.QueryDirection');
    if (PDir=PinDir) then
      if PinType = PT_ALL then
        RPin:=Pin
      else begin
        Pin.EnumMediaTypes(MediaTypes);
        MediaTypes.Reset;
        while not(Assigned(RPin)) and  (MediaTypes.Next(1,MT,@Fetched)=S_OK) do
        begin
          if IsEqualGUID(MT^.MajorType,MEDIATYPE_Video) and (PinType=PT_VIDEO) then
            RPin:=Pin;
          if IsEqualGUID(MT^.MajorType,MEDIATYPE_Audio) and (PinType=PT_AUDIO) then
            RPin:=Pin;
          DSH.DeleteMediaType(MT);
        end;
      end;
  end;
  Result:=RPin;
end;

function TDirectShowHelper.GetPin;
var
  Pins:IEnumPins;
  RPin,Pin:IPin;
  PDir:TPINDIRECTION;
  MT:PAMMEDIATYPE;
  MediaTypes:IEnumMediaTypes;
  Fetched:Cardinal;
begin
  RPin:=NIL;
  if (Filter=NIL) then Exit;
  E(Filter.EnumPins(Pins),'Filter.EnumPins');
  E(Pins.Reset,'Pins.Reset');
  while not(Assigned(RPin)) and (Pins.Next(1,Pin,@Fetched)=S_OK) do begin
    E(Pin.QueryDirection(PDir),'Pin.QueryDirection');
    if (PDir=PinDir) then
      if PinType = PT_ALL then
        RPin:=Pin
      else begin
        Pin.EnumMediaTypes(MediaTypes);
        MediaTypes.Reset;
        while not(Assigned(RPin)) and (MediaTypes.Next(1,MT,@Fetched)=S_OK) do
        begin
          if IsEqualGUID(MT^.MajorType,MEDIATYPE_Video) and (PinType=PT_VIDEO) then
            RPin:=Pin;
          if IsEqualGUID(MT^.MajorType,MEDIATYPE_Audio) and (PinType=PT_AUDIO) then
            RPin:=Pin;
          DSH.DeleteMediaType(MT);
        end;
      end;
  end;
  Pins:=NIL;
  Result:=RPin;
end;

function TDirectShowHelper.GetUnconnectedPin;
var
  Pins:IEnumPins;
  RPin,Pin:IPin;
  PDir:TPINDIRECTION;
  MT:PAMMEDIATYPE;
  MediaTypes:IEnumMediaTypes;
  Fetched:Cardinal;
begin
  RPin:=NIL;
  if (Filter=NIL) then Exit;
  E(Filter.EnumPins(Pins),'Filter.EnumPins');
  E(Pins.Reset,'Pins.Reset');
  while not(Assigned(RPin)) and (Pins.Next(1,Pin,@Fetched)=S_OK) do begin
    E(Pin.QueryDirection(PDir),'Pin.QueryDirection');
    if not IsPinConnected(Pin) then
      if (PDir=PinDir) then
        if PinType = PT_ALL then
          RPin:=Pin
        else begin
          Pin.EnumMediaTypes(MediaTypes);
          MediaTypes.Reset;
          while not(Assigned(RPin)) and (MediaTypes.Next(1,MT,@Fetched)=S_OK) do
          begin
            if IsEqualGUID(MT^.MajorType,MEDIATYPE_Video) and (PinType=PT_VIDEO) then
              RPin:=Pin;
            if IsEqualGUID(MT^.MajorType,MEDIATYPE_Audio) and (PinType=PT_AUDIO) then
              RPin:=Pin;
            DSH.DeleteMediaType(MT);
          end;
        end;
  end;
  Pins:=NIL;
  Result:=RPin;
end;

function TDirectShowHelper.GetVideoDecoder: IBaseFilter;
var
  FEnum:IEnumFilters;
  Filter:IBaseFilter;
  Fetched:LongInt;
  VDOut,VDIn:IPin;

  function PinMediaType(Pin:IPin):LongInt;
  var
    MT:TAMMEDIATYPE;
    hR:HRESULT;
  begin
    Result:=0;
    if not(Assigned(Pin)) then Exit;

    hR:=Pin.ConnectionMediaType(MT);
    if FAILED(hR) then Exit;

    if IsEqualGUID(MT.MajorType,MEDIATYPE_Video)
      or IsEqualGUID(MT.MajorType,MEDIATYPE_MPEG2_PACK)
      or IsEqualGUID(MT.MajorType,MEDIATYPE_DVD_ENCRYPTED_PACK)
    then begin
      Result:=1;
      if IsEqualGUID(MT.SubType,MEDIASUBTYPE_NV11) or
        IsEqualGUID(MT.SubType,MEDIASUBTYPE_NV12) or
        IsEqualGUID(MT.SubType,MEDIASUBTYPE_NV24) or
        IsEqualGUID(MT.SubType,MEDIASUBTYPE_IMC1) or
        IsEqualGUID(MT.SubType,MEDIASUBTYPE_IMC2) or
        IsEqualGUID(MT.SubType,MEDIASUBTYPE_IMC3) or
        IsEqualGUID(MT.SubType,MEDIASUBTYPE_IMC4) or
        IsEqualGUID(MT.SubType,MEDIASUBTYPE_S340) or
        IsEqualGUID(MT.SubType,MEDIASUBTYPE_I420) or
        IsEqualGUID(MT.SubType,MEDIASUBTYPE_P010) or
        IsEqualGUID(MT.SubType,MEDIASUBTYPE_P016) or
        IsEqualGUID(MT.SubType,MEDIASUBTYPE_P210) or
        IsEqualGUID(MT.SubType,MEDIASUBTYPE_P216) or
        IsEqualGUID(MT.SubType,MEDIASUBTYPE_Y416) or
        //-----
        IsEqualGUID(MT.SubType,DXVA_ModeMPEG2_A) or
        IsEqualGUID(MT.SubType,DXVA_ModeMPEG2_C) or
        IsEqualGUID(MT.SubType,DXVA_ModeH264_E) or
        IsEqualGUID(MT.SubType,DXVA_ModeH264_F) or
        //-----
        IsEqualGUID(MT.SubType,MEDIASUBTYPE_AYUV) or
        IsEqualGUID(MT.SubType,MEDIASUBTYPE_YVU9) or
        IsEqualGUID(MT.SubType,MEDIASUBTYPE_CLPL) or
        IsEqualGUID(MT.SubType,MEDIASUBTYPE_YUYV) or
        IsEqualGUID(MT.SubType,MEDIASUBTYPE_IYUV) or
        IsEqualGUID(MT.SubType,MEDIASUBTYPE_YV12) or
        IsEqualGUID(MT.SubType,MEDIASUBTYPE_Y411) or
        IsEqualGUID(MT.SubType,MEDIASUBTYPE_Y41P) or
        IsEqualGUID(MT.SubType,MEDIASUBTYPE_YUY2) or
        IsEqualGUID(MT.SubType,MEDIASUBTYPE_YVYU) or
        IsEqualGUID(MT.SubType,MEDIASUBTYPE_UYVY) or
        IsEqualGUID(MT.SubType,MEDIASUBTYPE_Y211) or
        IsEqualGUID(MT.SubType,MEDIASUBTYPE_CLJR) or
        IsEqualGUID(MT.SubType,MEDIASUBTYPE_IF09) or
        IsEqualGUID(MT.SubType,MEDIASUBTYPE_RGB1) or
        IsEqualGUID(MT.SubType,MEDIASUBTYPE_RGB4) or
        IsEqualGUID(MT.SubType,MEDIASUBTYPE_RGB8) or
        IsEqualGUID(MT.SubType,MEDIASUBTYPE_RGB565) or
        IsEqualGUID(MT.SubType,MEDIASUBTYPE_RGB555) or
        IsEqualGUID(MT.SubType,MEDIASUBTYPE_RGB24) or
        IsEqualGUID(MT.SubType,MEDIASUBTYPE_RGB32) or
        IsEqualGUID(MT.SubType,MEDIASUBTYPE_ARGB32) or
        IsEqualGUID(MT.SubType,MEDIASUBTYPE_Overlay)
      then
        Result:=2;
      FreeMediaType(MT);
    end;
  end;
begin
  Result:=NIL;
  if not(Assigned(Graph)) then Exit;
  E(Graph.EnumFilters(FEnum),'Graph.EnumFilters');
  while (FEnum.Next(1,Filter,@Fetched)=S_OK) do begin
    VDIn:=GetPin(Filter,PINDIR_INPUT);
    VDOut:=GetPin(Filter,PINDIR_OUTPUT);
    if (PinMediaType(VDIn)=1) and (PinMediaType(VDOut)=2) then begin
      Result:=NIL;
      Result:=Filter;
    end;
    VDIn:=NIL;
    VDOut:=NIL;
  end;
end;

function TDirectShowHelper.HasProperties(Filter: IUnknown): boolean;
var
  Specify:ISpecifyPropertyPages;
  caGUID:TCAGUID;
begin
  Result:=FALSE;
  if not(Assigned(Filter)) then
    Exit;
  if FAILED(Filter.QueryInterface(IID_ISpecifyPropertyPages,Specify)) then
    Exit;
  if FAILED(Specify.GetPages(caGUID)) then
    Exit;
  Result:=caGUID.cElems>0;
  CoTaskMemFree(caGUID.pElems);
end;

function TDirectShowHelper.IsMediaDetAvail;
var
  MediaDet:IMediaDet;
begin
  Result:=FALSE;
  if SUCCEEDED(CoCreateInstance(CLSID_MediaDet,NIL,CLSCTX_INPROC,IID_IMediaDet,MediaDet)) then begin
    Result:=SUCCEEDED(MediaDet.put_FileName(frMain.LoadedFileName));
    MediaDet:=NIL;
  end;
end;

procedure TDirectShowHelper.OnMediaEvent(var Message: TMessage);
var
  evCode,Param1,Param2:LongInt;
  Complete:Boolean;
begin
  if (Message.Msg=WM_MEDIAEVENT) then begin
    Complete:=FALSE;
    if Assigned(MediaEventEx) then begin
      while SUCCEEDED(MediaEventEx.GetEvent(evCode,Param1,Param2,0)) do begin
        Log(Format('MediaEvent: '+MediaEventCodeName(evCode)+' (%d, %d)' ,[Param1,Param2]));
        ProcessMediaEvent(evCode,Param1,Param2);
        if (evCode=EC_COMPLETE) then Complete:=TRUE;
        E(MediaEventEx.FreeEventParams(evCode,Param1,Param2),'MediaEventEx.FreeEventParams');
      end;
    end;
    if Complete and Assigned(OnComplete) then OnComplete(Self);
    Message.Result:=0;
  end else begin
    DefWindowProc(EventWND,Message.Msg,Message.wParam,Message.lParam);
  end;
end;

procedure TDirectShowHelper.Pause;
begin
  if Assigned(MediaControl) then
    E(MediaControl.Pause,'MediaControl.Pause');
end;

function TDirectShowHelper.Position;
{var
  Loc:TDVD_Playback_Location2;}
begin
  Result:=0;
  if IsDVD then begin
    Result:=DVDPos.bHours;
    Result:=Result*60+DVDPos.bMinutes;
    Result:=Result*60+DVDPos.bSeconds;
    Result:=Result*10000000;
{    if SUCCEEDED(DVDInfo.GetCurrentLocation(Loc)) then begin
      Result:=Loc.TimeCode.bHours;
      Result:=Result*60+Loc.TimeCode.bMinutes;
      Result:=Result*60+Loc.TimeCode.bSeconds;
      Result:=Result*10000000;
    end;}
  end else begin
    if Assigned(MediaSeeking) then
      E(MediaSeeking.GetCurrentPosition(Result),'MediaSeeking.GetCurrentPosition');
  end;
end;

procedure TDirectShowHelper.Run;
var
  DVDCmd:IDVDCmd;
begin
  if Assigned(MediaControl) then
    E(MediaControl.Run,'MediaControl.Run');
  if IsDVD then begin
    DVDControl.PlayForwards(1.0,0,DVDCmd);
    DVDCmd:=NIL;
    SwitchCCOff;
  end;
end;

procedure TDirectShowHelper.Repaint;
begin
  if Assigned(VideoWindow) then
    VideoWindow.put_BorderColor(0);
  if Assigned(MFVideoDisplayControl)then
    MFVideoDisplayControl.RepaintVideo;
end;

procedure TDirectShowHelper.SeekTo;
var
  Flags:DWORD;
  Dur,Pos:Int64;
  DVDPos:TDVDHMSFTIMECODE;
  DVDCmd:IDVDCmd;
  CW: Word;
begin
  Log('+TDirectShowHelper.SeekTo ('+Core.SysHlp.FormatHNS('{H}:{M}:{S}',NewPos) + ')');
  CW := Get8087CW;
  Set8087CW($133f);  // Disable FPU Exceptions
  try
    if (NewPos<0) then NewPos:=0;

    if Core.Prefs.ReadBool('OSD.ShowTotalTimeOnSeek') then
      Core.Info(MS('OSD.Seek')+': '+Core.SysHlp.FormatHNS('{H}:{M}:{S}',NewPos) + ' (' + Core.SysHlp.FormatHNS('{H}:{M}:{S}', DSH.Duration) + ')')
    else
      Core.Info(MS('OSD.Seek')+': '+Core.SysHlp.FormatHNS('{H}:{M}:{S}',NewPos));

    if IsDVD then
    begin
      Log('+TDirectShowHelper.SeekTo.IsDVD');
      if (NewPos=0) then begin
        DVDMenu;
      end
      else begin
        Pos:=NewPos div 10000000;
        DVDPos.bSeconds:=Pos mod 60; Pos:=Pos div 60;
        DVDPos.bMinutes:=Pos mod 60; Pos:=Pos div 60;
        DVDPos.bHours:=Pos;
        DVDPos.bFrames:=1;
        Log(' = DVDPos: bSeconds(' + IntToStr(DVDPos.bSeconds) +
        '), bMinutes(' + IntToStr(DVDPos.bMinutes) + '), bHours(' +
        IntToStr(DVDPos.bHours) + ')');
        DVDControl.PlayAtTime(@DVDPos,4{DVD_CMD_FLAG_Block},DVDCmd);
        DVDCmd:=NIL;
      end;
      Log('-TDirectShowHelper.SeekTo.IsDVD');
    end else if Assigned(MediaControl) then
    begin
      Log('+TDirectShowHelper.SeekTo.MediaControl');
      Pos:=NewPos;
      Dur:=Duration;

      if (Pos>Dur) then Pos:=Dur;
      if (Pos<0) then Pos:=0;

      Log(' = Pos(' + IntToStr(pos) + '), Dur(' + IntToStr(Dur) + ')');

      Flags:=AM_SEEKING_AbsolutePositioning;
      if Core.Prefs.ReadBool('Video.KeyFrameSeek') then begin
        Log(' = Video.KeyFrameSeek');
        Flags:=Flags or AM_SEEKING_SeekToKeyFrame;
      end;
      E(MediaSeeking.SetPositions(Pos,Flags,Pos,AM_SEEKING_NoPositioning),'MediaSeeking.SetPositions');
      Log('-TDirectShowHelper.SeekTo.MediaControl');
    end;
  except
  end;
  Set8087CW(CW); //restore FPU flags
  Log('-TDirectShowHelper.SeekTo');
end;

procedure TDirectShowHelper.SetRate;
begin
  if Assigned(MediaSeeking) then
    E(MediaSeeking.SetRate(Rate),'MediaSeeking.SetRate');
end;

procedure TDirectShowHelper.Stop;
var
  CW:DWORD;
begin
  if Assigned(MediaControl) then begin
    CW := Get8087CW;
    Set8087CW($133f);
    E(MediaControl.Stop,'MediaControl.Stop');
    Set8087CW(CW);
  end;
end;

{
procedure TMainForm.TuneSound;
var
  FEnum:IEnumFilters;
  Filter:IBaseFilter;
  Fetched:cardinal;
  FInfo:TFILTERINFO;
  Name:array[0..255] of char;
  Pins:IEnumPins;
  MP3Out:IPin;
  tmt:TAM_MEDIA_TYPE;

  procedure MMAdjust;
  var
    AMStream:IAMMultiMediaStream;
    MMStream:IMultiMediaStream;
    Stream:IMediaStream;
    AStream:IAudioMediaStream;
    wfx:TWAVEFORMATEX;
  begin
    E(CoCreateInstance(CLSID_AMMultiMediaStream,NIL,CLSCTX_INPROC_SERVER,IID_IAMMultiMediaStream,AMStream),'');
    MMStream:=AMStream;
    E(MMStream.GetMediaStream(MSPID_PrimaryVideo,Stream),'');
    E(Stream.QueryInterface(IID_IAudioMediaStream,AStream),'');
    E(AStream.GetFormat(wfx),'');
    with wfx do
      begin
      ShowMessage(Format('Primary Audio: %d',[nSamplesPerSec]));

      nSamplesPerSec:=22050;

      nBlockAlign:=nChannels*wBitsPerSample div 8;
      nAvgBytesPerSec:=nSamplesPerSec*nBlockAlign;
      end;
    E(AStream.SetFormat(wfx),'');
  end;

begin
  MMAdjust;

  E(Graph.EnumFilters(FEnum),'');
  while (FEnum.Next(1,Filter,@Fetched)=S_OK) do
    begin
    E(Filter.QueryFilterInfo(FInfo),'');
    WideCharToMultiByte(CP_ACP,0,FInfo.achName,-1,Name,256,NIL,NIL);

    E(Filter.EnumPins(Pins),'');
    MP3Out:=FindPin(Pins,PINDIR_OUTPUT);
    if Assigned(MP3Out) then
      begin
      E(MP3Out.ConnectionMediaType(tmt),'');
      if (IsEqualGUID(tmt.FormatType,FORMAT_WAVEFORMATEX)) and
         (IsEqualGUID(tmt.SubType,MEDIASUBTYPE_PCM)) then
        begin
        ShowMessage(Name);
//        Adjust;
        end;
      DeleteMediaType(@tmt);

      E(MP3Out.ConnectionMediaType(tmt),'');
      if (IsEqualGUID(tmt.FormatType,FORMAT_WAVEFORMATEX)) and
         (IsEqualGUID(tmt.SubType,MEDIASUBTYPE_PCM)) then
        begin
        ShowMessage(IntToStr(TWAVEFORMATEX(tmt.pbFormat^).nSamplesPerSec));
        end;
      DeleteMediaType(@tmt);
      end;

    FInfo.pGraph:=NIL;
    Filter:=NIL;
    end;
  FEnum:=NIL;
end; }

function TDirectShowHelper.IsFilterConnected;
var
  PN:IPin;
  CPN:IPin;
begin
  Result:=False;
  if Filter<>NIL then begin
    PN:=GetPin(Filter,PinDir);
    if PN<>NIL then
      if PN.ConnectedTo(CPN)=S_OK then
        if (CPN<>NIL) then
          Result:=True;
  end;
  CPN:=NIL;
  PN:=NIL;
end;

function TDirectShowHelper.IsFilterConnectedByCLSID;
var
  Filter:IBaseFilter;
begin
  Result:=False;
  Filter:=GetFilter(ID);
  if Filter=NIL then Exit;
  Result:=IsFilterConnected(Filter,PINDIR_INPUT);
  Result:=Result or IsFilterConnected(Filter,PINDIR_OUTPUT);
  Filter:=NIL;
end;


procedure TDirectShowHelper.SetOwner;
var
  Style:LongInt;
begin
  if (Wnd=0) then begin
    E(VideoWindow.Put_Visible(FALSE),'VideoWindow.Put_Visible');
    E(VideoWindow.Put_Owner(0),'VideoWindow.Put_Owner');
  end else begin
    if (not IsFilterConnectedByCLSID(VideoRenderers[scEVR].CLSID)) then begin
      E(VideoWindow.get_WindowStyle(Style),'VideoWindow.get_WindowStyle');
      Style:=(Style or WS_CHILD) and not(WS_CAPTION or WS_BORDER or WS_THICKFRAME);
      E(VideoWindow.Put_WindowStyle(Style),'VideoWindow.Put_WindowStyle');
      E(VideoWindow.Put_WindowStyle(WS_CHILD or WS_CLIPCHILDREN),'VideoWindow.Put_WindowStyle');
      E(VideoWindow.Put_Owner(Wnd),'VideoWindow.Put_Owner');
      E(VideoWindow.Put_Visible(TRUE),'VideoWindow.Put_Visible');
      E(VideoWindow.Put_MessageDrain(Wnd),'VideoWindow.Put_MessageDrain');
    end
    else
      if MFVideoDisplayControl<>NIL then
        MFVideoDisplayControl.SetVideoWindow(Wnd);
  end;
end;

procedure TDirectShowHelper.SizeVideoWnd;
begin
  if (MFVideoDisplayControl<>nil) and
    IsFilterConnectedByCLSID(VideoRenderers[scEVR].CLSID)
  then begin
    MFVideoDisplayControl.SetAspectRatioMode(MFVideoARMode_None);
    MFVideoDisplayControl.SetVideoPosition(nil, @VRect);
  end;
  if BasicVideo<>NIL then
    BasicVideo.SetDestinationPosition(0,0,VRect.Right,VRect.Bottom);
end;

function TDirectShowHelper.GetVideoRenderer;
var
  i:Integer;
  CLSID: TGUID;
  FEnum:IEnumFilters;
  Filter:IBaseFilter;
  Fetched:LongInt;
begin
  Result:=NIL;
  if not(Assigned(Graph)) then Exit;

  E(Graph.EnumFilters(FEnum),'Graph.EnumFilters');
  while (not Assigned(Result)) and (FEnum.Next(1,Filter,@Fetched)=S_OK) do
  begin
    CLSID:=GetCLSID(Filter);
    for i:=0 to Length(VideoRenderers)-1 do
    begin
      if IsEqualGUID(CLSID,VideoRenderers[i].CLSID) then
        Result:=Filter;
    end;
  end;
  FEnum:=NIL;
  Filter:=NIL;
end;

function TDirectShowHelper.GetErrorText;
var
  AMError:array[0..255] of Char;
  n:longint;
begin
  case Cardinal(hR) of
    $80040200,$80040201,$80040216,$80040265,
    $80040256,$8004027B:StrPLCopy(AMError,MS(Format('DS.Err%.8x',[hR])),256);
  else
    n:=AMGetErrorText(hR,AMError,255);
    AMError[n]:=#0;
  end;
  Result:=Format(MS('DS.Error')+': 0x%.8x ( %s )',[hR,AMError]);
end;

procedure TDirectShowHelper.CheckForAV;
var
  Filter:IBaseFilter;
  VH,VW:longint;
  Size,AR:TSize;
begin
  VideoWidth:=0;
  VideoHeight:=0;

  if not IsFilterConnectedByCLSID(VideoRenderers[scEVR].CLSID) then begin
    E(Graph.QueryInterface(IID_IBasicVideo,BasicVideo),'Graph.QueryInterface(IBasicVideo)');
    HasVideo:=SUCCEEDED(BasicVideo.GetVideoSize(VW,VH));
  end
  else
  begin
    if MFVideoDisplayControl<>NIL then
      MFVideoDisplayControl.GetNativeVideoSize(Size,AR);
    HasVideo:=(Size.cx<>0) and (Size.cy<>0);
    VW:=Size.cx;
    VH:=Size.cy;
  end;

  if HasVideo then begin
    VideoWidth:=VW;
    VideoHeight:=VH;
  end;

  Filter:=GetAudioRenderer(0);
  HasAudio:=Assigned(Filter);
  Filter:=NIL;
end;

function TDirectShowHelper.GetAudioRenderer;
begin
  Result:=NIL;
  if Index>=Length(ARenderers) then Exit;
  if ARenderers[index]<>NIL then
    Result:=ARenderers[index];
end;

procedure TDirectShowHelper.AdjustBCS;
var
  B,C,S:LongInt;
begin
  GetBCS(B,C,S);
  Inc(B,DeltaB);
  Inc(C,DeltaC);
  Inc(S,DeltaS);
  SetBCS(B,C,S);
end;

procedure TDirectShowHelper.TearDownStream;
var
  Filter:IBaseFilter;
begin
  if not(Assigned(Head)) then Exit;
  Filter:=NextFilter(Head);
  TearDownStream(Filter);
  E(Graph.RemoveFilter(Head),'Graph.RemoveFilter');
end;

function TDirectShowHelper.NextFilter;
var
  CPin,Pin:IPin;
  PInfo:TPININFO;
begin
  Result:=NIL;
  Pin:=DSH.GetPin(Filter,PINDIR_OUTPUT);
  if Assigned(Pin) then begin
    E(Pin.ConnectedTo(CPin),'Pin.ConnectedTo(CPin)');
    E(CPin.QueryPinInfo(PInfo),'PInfo.QueryPinInfo');
    Result:=PInfo.pFilter;
  end;
  PInfo.pFilter:=NIL;
  CPin:=NIL;
  Pin:=NIL;
end;

function TDirectShowHelper.GetAudioRendererCount;
begin
  Result:=Length(ARenderers);
end;

procedure TDirectShowHelper.DetectVideoFPS;
var
  Filter:IBaseFilter;
  InPin:IPin;
  MT:TAMMEDIATYPE;
begin
  VideoFPS:=0;
  Filter:=GetVideoDecoder;
  if Assigned(Filter) then begin
    InPin:=GetPin(Filter,PINDIR_INPUT);
    E(InPin.ConnectionMediaType(MT),'InPin.ConnectionMediaType');
    if IsEqualGUID(MT.FormatType,FORMAT_VideoInfo) or
       IsEqualGUID(MT.FormatType,FORMAT_VideoInfo) then
      VideoFPS:=TVideoInfoHeader(MT.pbFormat^).AvgTimePerFrame;
    FreeMediaType(MT);
    InPin:=NIL;
  end;
  Filter:=NIL;

  if (VideoFPS=0) then
    VideoFPS:=10000000 div 25;
end;

function TDirectShowHelper.FindUnconnectedPin;
var
  FEnum:IEnumFilters;
  Filter:IBaseFilter;
  Fetched:longint;
  Pins:IEnumPins;
  RPin,Pin,CPin:IPin;
  PDir:TPINDIRECTION;
  hR:HResult;
begin
  Result:=NIL;
  RPin:=NIL;
  if not(Assigned(Graph)) then Exit;
  E(Graph.EnumFilters(FEnum),'Graph.EnumFilters');
  while not(Assigned(RPin)) and (FEnum.Next(1,Filter,@Fetched)=S_OK) do begin
    E(Filter.EnumPins(Pins),'Filter.EnumPins');
    E(Pins.Reset,'Pins.Reset');
    while not(Assigned(RPin)) and (Pins.Next(1,Pin,@Fetched)=S_OK) do begin
      E(Pin.QueryDirection(PDir),'Pin.QueryDirection');
      if (PDir=PINDIR_OUTPUT) then begin
        hR:=Pin.ConnectedTo(CPin);
        if FAILED(hR) then RPin:=Pin;
        CPin:=NIL;
      end;
      Pin:=NIL;
    end;
    Pins:=NIL;
    Filter:=NIL;
  end;
  Result:=RPin;
end;

procedure TDirectShowHelper.FreeMediaType;
begin
  if (AM.cbFormat<>0) then
    CoTaskMemFree(AM.pbFormat);
  AM.pUnk:=NIL;
  AM.cbFormat:=0;
  AM.pbFormat:=NIL;
end;

function TDirectShowHelper.GetFilterFileName(CLSID: TGUID): string;
var
  R:TRegistry;
begin
  Result:='';
  R:=TRegistry.Create;
  R.RootKey:=HKEY_LOCAL_MACHINE;
  if R.KeyExists('\SOFTWARE\Classes\CLSID\'+GUIDToString(CLSID)) then
  if R.OpenKeyReadOnly('SOFTWARE\Classes\CLSID\'+GUIDToString(CLSID)+'\InprocServer32') then
    Result:=R.ReadString('');
  R.CloseKey;
  R.Free;
end;

function TDirectShowHelper.GetFilterVersion(FileName:string): string;
var
  VerInfoSize: DWORD;
  VerInfo: Pointer;
  VerValueSize: DWORD;
  VerValue: PVSFixedFileInfo;
  Dummy: DWORD;
begin
  VerInfoSize := GetFileVersionInfoSize(PChar(FileName), Dummy);
  GetMem(VerInfo, VerInfoSize);
  GetFileVersionInfo(PChar(FileName), 0, VerInfoSize, VerInfo);
  VerQueryValue(VerInfo, '\', Pointer(VerValue), VerValueSize);
  with VerValue^ do
  begin
    Result := IntToStr(dwFileVersionMS shr 16);
    Result := Result + '.' + IntToStr(dwFileVersionMS and $FFFF);
    Result := Result + '.' + IntToStr(dwFileVersionLS shr 16);
    Result := Result + '.' + IntToStr(dwFileVersionLS and $FFFF);
  end;
  FreeMem(VerInfo, VerInfoSize);
end;

function TDirectShowHelper.GetFilterFriendlyName;
var
  R:TRegistry;
begin
  Result:='';
  R:=TRegistry.Create;
  R.RootKey:=HKEY_CLASSES_ROOT;
  if (R.OpenKeyReadOnly('\CLSID\'+GUIDToString(CLSID_LegacyAmFilterCategory)+'\Instance\'+GUIDToString(CLSID))) then
    Result:=R.ReadString('FriendlyName');
  if (R.OpenKeyReadOnly('\CLSID\'+GUIDToString(CLSID))) then
    Result:=Result+' ('+R.ReadString('')+')';
  R.Free;
end;

function TDirectShowHelper.RenderFile;
var
  WideFileName:array [0..MAX_PATH-1] of WChar;
  CW: DWORD;
begin
  CW := Get8087CW;
  Set8087CW($133f);
  if IsDVD then
  begin
    DVDControl.Stop();
    MultiByteToWideChar(CP_ACP,0,PChar(FileName),-1,WideFileName,MAX_PATH);
    Result:=DVDControl.SetDVDDirectory(WideFileName);
  end else
  begin
    IsUrl := (System.Pos(':/',FileName)<>0);
    MultiByteToWideChar(CP_ACP,0,PChar(FileName),-1,WideFileName,MAX_PATH);
    try
      Result:=Graph.RenderFile(WideFileName,NIL);
    except
      Result:=VFW_S_RESERVED;
    end;
  end;
  Set8087CW(CW);
end;

procedure TDirectShowHelper.MouseMove;
begin
  if IsDVD and Assigned(DVDControl) then
    DVDControl.SelectAtPosition(P);
end;

procedure TDirectShowHelper.MouseClick;
begin
  if IsDVD and Assigned(DVDControl) then
    DVDControl.ActivateAtPosition(P);
end;

function TDirectShowHelper.IsDVDMenu;
var
  Domain:TDVDDomain;
begin
  Result:=FALSE;
  if not(IsDVD) then Exit;
  if Assigned(DVDInfo) then begin
    DVDInfo.GetCurrentDomain(Domain);
    Result:=(Ord(Domain)=2) or (Ord(Domain)=3); // VideoManagerMenu, VideoTitleSetMenu
  end;
end;

function TDirectShowHelper.GetVideoProcessor;
var
  FEnum:IEnumFilters;
  Filter:IBaseFilter;
  Fetched:LongInt;
  hR:HRESULT;
  VideoProc:IVideoProcessor;
begin
  Result:=NIL;
  if not(Assigned(Graph)) then Exit;

  E(Graph.EnumFilters(FEnum),'Graph.EnumFilters');
  while (FEnum.Next(1,Filter,@Fetched)=S_OK) do begin
    hR:=Filter.QueryInterface(IID_VideoProcessor,VideoProc);
    if SUCCEEDED(hR) and Assigned(VideoProc) then begin
      Result:=Filter as IBaseFilter;
      VideoProc:=NIL;
    end;
    Filter:=NIL;
  end;
  FEnum:=NIL;
end;

procedure TDirectShowHelper.SetBCS;
var
  VC:String;
  OldB,OldC,OldS:LongInt;
begin
  GetBCS(OldB,OldC,OldS);

  if (NewB<0) then NewB:=0;
  if (NewB>100) then NewB:=100;
  if (NewC<0) then NewC:=0;
  if (NewC>100) then NewC:=100;
  if (NewS<0) then NewS:=0;
  if (NewS>100) then NewS:=100;

  VC:=VideoControlName;
  if (VC='VideoProc') then
    SetBCS_VideoProc(NewB,NewC,NewS)
  else if (VC='VMRMixerControl9') then
    SetBCS_VMRMixerControl9(NewB,NewC,NewS)
  else if (VC='MFVideoProc') then
    SetBCS_MFVideoProc(NewB,NewC,NewS)
  else if (VC='DivX4') then
    SetBCS_DivX4(NewB,NewC,NewS)
  else if (VC='DivX5') then
    SetBCS_DivX5(NewB,NewC,NewS)
  else begin
    if HasVideo then
      Core.Info(MS('OSD.NoVideoInterface'));
    Exit;
  end;

  GetBCS(NewB,NewC,NewS);
  if (NewB<>OldB) then
    Core.Info(MS('OSD.Brightness')+' '+IntToStr(NewB)+'%'); // ('+VC+')
  if (NewC<>OldC) then
    Core.Info(MS('OSD.Contrast')+' '+IntToStr(NewC)+'%'); // ('+VC+')
  if (NewS<>OldS) then
    Core.Info(MS('OSD.Saturation')+' '+IntToStr(NewS)+'%'); // ('+VC+')
end;

procedure TDirectShowHelper.GetBCS;
var
  VC:String;
begin
  B:=50;
  C:=50;
  S:=50;
  VC:=VideoControlName;
  if (VC='VideoProc') then
    GetBCS_VideoProc(B,C,S)
  else if (VC='VMRMixerControl9') then
    GetBCS_VMRMixerControl9(B,C,S)
  else if (VC='MFVideoProc') then
    GetBCS_MFVideoProc(B,C,S)
  else if (VC='DivX4') then
    GetBCS_DivX4(B,C,S)
  else if (VC='DivX5') then
    GetBCS_DivX5(B,C,S)
  else if (not HideWarnings) and HasVideo then
    Core.Info(MS('OSD.NoVideoInterface'));
end;

function TDirectShowHelper.VideoControlName;
var
  Filter:IBaseFilter;
  DivX:IDivx5FilterInterface;
  FInfo:TFilterInf;
  VP:PVideoProcProps;
  DivxPath:string;
  Ver:string;
begin
  Result:='';
  if not(Assigned(Graph)) then Exit;

  VP:=GetVideoProcProps;
  if Assigned(VP) then begin
    if (VP.IsConnected) then begin
      Result:='VideoProc';
      Exit;
    end;
  end;

  if (VMRMixerControl9<>NIL) and Core.Prefs.ReadBool('Video.HardwareProcessing')
  then begin
    Result:='VMRMixerControl9';
    Exit;
  end;

  if (MFVideoProcessor<>NIL) and Core.Prefs.ReadBool('Video.HardwareProcessing')
  then begin
    Result:='MFVideoProc';
    Exit;
  end;

  Filter:=GetVideoDecoder;
  if not(Assigned(Filter)) then Exit;

  if SUCCEEDED(Filter.QueryInterface(IID_IDivxFilterInterface,DivX)) then begin
    if FLibrary.ActiveLocalFilters.GetFInfo(Filter,FInfo) then begin
      DivxPath:=FInfo.LOCALPATH;
    end
    else
      DivxPath:=GetFilterFileName(StringToGUID('{78766964-0000-0010-8000-00AA00389B71}'));

    if DivxPath<>'' then begin
      Ver:=GetFilterVersion(DivxPath);
      if (StrToInt(Ver[1]) = 4) then Result:='DivX4';
      if (StrToInt(Ver[1]) = 5) then Result:='DivX5';
      if (StrToInt(Ver[1]) = 9) then Result:='DivX5';
      if (StrToInt(Ver[1]) = 6) then Result:='DivX5';
    end;

    DivX:=NIL;
    Filter:=NIL;
    Exit;
  end;

  Filter:=NIL;
end;

procedure TDirectShowHelper.GetBCS_DivX4;
var
  Filter:IBaseFilter;
  DivX4:IDivx4FilterInterface;
  l:LongInt;
begin
  Filter:=GetVideoDecoder;
  try
    if SUCCEEDED(Filter.QueryInterface(IID_IDivxFilterInterface,DivX4)) then begin
      DivX4.Get_Brightness(l); // -128..127
      B:=50+(l div 2);
      DivX4.Get_Contrast(l);
      C:=50+(l div 2);
      DivX4.Get_Saturation(l);
      S:=50+(l div 2); //((l+127)*100) div 255;
    end;
  finally
    DivX4:=NIL;
    Filter:=NIL;
  end;
end;

procedure TDirectShowHelper.GetBCS_DivX5;
var
  Filter:IBaseFilter;
  DivX5:IDivx5FilterInterface;
  l:LongInt;
begin
  Filter:=GetVideoDecoder;
  try
    if SUCCEEDED(Filter.QueryInterface(IID_IDivxFilterInterface,DivX5)) then begin
      DivX5.GetBrightness(l); // -128..127
      B:=50+(l div 2);
      DivX5.GetContrast(l);
      C:=50+(l div 2);
      DivX5.GetSaturation(l);
      S:=50+(l div 2); //((l+127)*100) div 255;
    end;
  finally
    DivX5:=NIL;
    Filter:=NIL;
  end;
end;

procedure TDirectShowHelper.GetBCS_VideoProc;
var
  Filter:IBaseFilter;
  VideoProc:IVideoProcessor;
  VP:PVideoProcProps;
  l:LongInt;
begin
  Filter:=GetVideoProcessor;
  if Assigned(Filter) then begin
    VideoProc:=Filter as IVideoProcessor;
    VideoProc.GetProps(VP);
    l:=VP^.Br;
    B:=(100+l) div 2;
    l:=VP^.Co;
    C:=(100+l) div 2;
    l:=VP^.Sa;
    S:=(100+l) div 2;
    VideoProc:=NIL;
  end;
  Filter:=NIL;
end;

procedure TDirectShowHelper.GetBCS_VMRMixerControl9;
begin
  B:=Brightness;
  C:=Contrast;
  S:=Saturation;
end;

procedure TDirectShowHelper.GetBCS_MFVideoProc;
begin
  B:=Brightness;
  C:=Contrast;
  S:=Saturation;
end;

procedure TDirectShowHelper.SetBCS_DivX4;
var
  Filter:IBaseFilter;
  DivX4:IDivx4FilterInterface;
  l:LongInt;
  OldB,OldC,OldS:LongInt;
begin
  GetBCS_DivX4(OldB,OldC,OldS);

  Filter:=GetVideoDecoder;
  try
    if SUCCEEDED(Filter.QueryInterface(IID_IDivxFilterInterface,DivX4)) then begin
      if (OldB<>NewB) then begin
        l:=(NewB-50)*2;
        DivX4.Put_Brightness(l); // -128..127
      end;
      if (OldC<>NewC) then begin
        l:=(NewC-50)*2;
        DivX4.Put_Contrast(l);
      end;
      if (OldS<>NewS) then begin
        l:=(NewS-50)*2;
        DivX4.Put_Saturation(l);
      end;
    end;
  finally
    DivX4:=NIL;
    Filter:=NIL;
  end;
end;

procedure TDirectShowHelper.SetBCS_DivX5;
var
  Filter:IBaseFilter;
  DivX5:IDivx5FilterInterface;
  l:LongInt;
  OldB,OldC,OldS:LongInt;
begin
  GetBCS_DivX5(OldB,OldC,OldS);
  try
    Filter:=GetVideoDecoder;
    if SUCCEEDED(Filter.QueryInterface(IID_IDivxFilterInterface,DivX5)) then begin
      if (OldB<>NewB) then begin
        l:=(NewB-50)*2;
        DivX5.PutBrightness(l); // -128..127
      end;
      if (OldC<>NewC) then begin
        l:=(NewC-50)*2;
        DivX5.PutContrast(l);
      end;
      if (OldS<>NewS) then begin
        l:=(NewS-50)*2;
        DivX5.PutSaturation(l);
      end;
    end;
  finally
    DivX5:=NIL;
    Filter:=NIL;
  end;
end;

procedure TDirectShowHelper.SetBCS_VideoProc;
var
  Filter:IBaseFilter;
  VideoProc:IVideoProcessor;
  VP:PVideoProcProps;
  l:LongInt;
begin
  Filter:=GetVideoProcessor;
  if Assigned(Filter) then begin
    VideoProc:=Filter as IVideoProcessor;
    VideoProc.GetProps(VP);
    l:=NewB*2-100;
    VP^.Br:=l; // -100..100
    l:=NewC*2-100;
    VP^.Co:=l; // -100..100
    l:=NewS*2-100;
    VP^.Sa:=l; // -100..100
    VP^.Update:=True;
    VideoProc:=NIL;
  end;
  Filter:=NIL;
end;

procedure TDirectShowHelper.SetBCS_VMRMixerControl9(B, C, S: Integer);
var
  CW: DWORD;
  HR: HRESULT;
  ProcAmpControlRange: TVMR9ProcAmpControlRange;
  ProcAmpControl: TVMR9ProcAmpControl;
  Range: Double;
begin
  CW := Get8087CW;
  Set8087CW($133f);
  ZeroMemory(@ProcAmpControlRange, SizeOf(ProcAmpControlRange));
  ProcAmpControlRange.dwSize := SizeOf(ProcAmpControlRange);

  ZeroMemory(@ProcAmpControl, SizeOf(ProcAmpControl));
  ProcAmpControl.dwSize := SizeOf(ProcAmpControl);
  try
    ProcAmpControlRange.dwProperty := ProcAmpControl9_Brightness;
    HR:=VMRMixerControl9.GetProcAmpControlRange(0, @ProcAmpControlRange);
    if Succeeded(HR) and (Brightness<>B) then begin
      Range:=ProcAmpControlRange.MaxValue -ProcAmpControlRange.MinValue;
      VMRMixerControl9.GetProcAmpControl(0,@ProcAmpControl);
      if Range>0 then begin
        ProcAmpControl.Brightness:=((Range / 100) * B)-abs(ProcAmpControlRange.MinValue);
        if ProcAmpControl.Brightness < ProcAmpControlRange.MinValue then
          ProcAmpControl.Brightness:=ProcAmpControlRange.MinValue+ProcAmpControlRange.StepSize;
        if ProcAmpControl.Brightness > ProcAmpControlRange.MaxValue then
          ProcAmpControl.Brightness:=ProcAmpControlRange.MaxValue-ProcAmpControlRange.StepSize;
        if B = 50 then
          ProcAmpControl.Brightness:=ProcAmpControlRange.DefaultValue;
        VMRMixerControl9.SetProcAmpControl(0,@ProcAmpControl);
        Brightness:=B;
      end;
    end;

    ProcAmpControlRange.dwProperty := ProcAmpControl9_Contrast;
    HR:=VMRMixerControl9.GetProcAmpControlRange(0, @ProcAmpControlRange);
    if Succeeded(HR) and (Contrast<>C) then begin
      Range:=ProcAmpControlRange.MaxValue -ProcAmpControlRange.MinValue;
      VMRMixerControl9.GetProcAmpControl(0,@ProcAmpControl);
      if Range>0 then begin
        ProcAmpControl.Contrast:=((Range / 100) * C)-abs(ProcAmpControlRange.MinValue);
        if ProcAmpControl.Contrast < ProcAmpControlRange.MinValue then
          ProcAmpControl.Contrast:=ProcAmpControlRange.MinValue+ProcAmpControlRange.StepSize;
        if ProcAmpControl.Contrast > ProcAmpControlRange.MaxValue then
          ProcAmpControl.Contrast:=ProcAmpControlRange.MaxValue-ProcAmpControlRange.StepSize;
        if C = 50 then
          ProcAmpControl.Contrast:=ProcAmpControlRange.DefaultValue;
        VMRMixerControl9.SetProcAmpControl(0,@ProcAmpControl);
        Contrast:=C;
      end;
    end;

    ProcAmpControlRange.dwProperty := ProcAmpControl9_Saturation;
    HR:=VMRMixerControl9.GetProcAmpControlRange(0, @ProcAmpControlRange);
    if Succeeded(HR) and (Saturation<>S) then begin
      Range:=ProcAmpControlRange.MaxValue -ProcAmpControlRange.MinValue;
      VMRMixerControl9.GetProcAmpControl(0,@ProcAmpControl);
      if Range>0 then begin
        ProcAmpControl.Saturation:=((Range / 100) * S)-abs(ProcAmpControlRange.MinValue);
        if ProcAmpControl.Saturation < ProcAmpControlRange.MinValue then
          ProcAmpControl.Saturation:=ProcAmpControlRange.MinValue+ProcAmpControlRange.StepSize;
        if ProcAmpControl.Saturation > ProcAmpControlRange.MaxValue then
          ProcAmpControl.Saturation:=ProcAmpControlRange.MaxValue-ProcAmpControlRange.StepSize;
        if S = 50 then
          ProcAmpControl.Saturation:=ProcAmpControlRange.DefaultValue;
        VMRMixerControl9.SetProcAmpControl(0,@ProcAmpControl);
        Saturation:=S;
      end;
    end;
  except
  end;
  Set8087CW(CW);
end;

procedure TDirectShowHelper.SetBCS_MFVideoProc;
var
  CW: DWORD;
  Values: TDXVA2_ProcAmpValues;
  VBR: TDXVA2_ValueRange;
  VCR: TDXVA2_ValueRange;
  VSR: TDXVA2_ValueRange;
  Range: Double;
begin
  CW := Get8087CW;
  Set8087CW($133f);
  try
    MFVideoProcessor.GetProcAmpValues(DXVA2_ProcAmp_Brightness,Values);
    MFVideoProcessor.GetProcAmpRange(DXVA2_ProcAmp_Brightness, VBR);
    Range := VBR.MaxValue.ll -VBR.MinValue.ll;
    if Range>0 then begin
      Values.Brightness.ll := (Round(Range / 100) * B)-abs(VBR.MinValue.ll);
      if Values.Brightness.ll < VBR.MinValue.ll then
        Values.Brightness.ll := VBR.MinValue.ll+VBR.StepSize.ll;
      if Values.Brightness.ll > VBR.MaxValue.ll then
        Values.Brightness.ll := VBR.MaxValue.ll-VBR.StepSize.ll;
      if B = 50 then
        Values.Brightness.ll:=VBR.DefaultValue.ll;
      Brightness:=B;
    end;


    MFVideoProcessor.GetProcAmpValues(DXVA2_ProcAmp_Contrast,Values);
    MFVideoProcessor.GetProcAmpRange(DXVA2_ProcAmp_Contrast, VCR);
    Range := VCR.MaxValue.ll -VCR.MinValue.ll;
    if Range>0 then begin
      Values.Contrast.ll := (Round(Range / 100) * C)-abs(VCR.MinValue.ll);
      if Values.Contrast.ll < VCR.MinValue.ll then
        Values.Contrast.ll := VCR.MinValue.ll+VCR.StepSize.ll;
      if Values.Contrast.ll > VCR.MaxValue.ll then
        Values.Contrast.ll := VCR.MaxValue.ll-VCR.StepSize.ll;
      if C = 50 then
        Values.Contrast.ll := VCR.DefaultValue.ll;
      Contrast:=C;
    end;


    MFVideoProcessor.GetProcAmpValues(DXVA2_ProcAmp_Saturation,Values);
    MFVideoProcessor.GetProcAmpRange(DXVA2_ProcAmp_Saturation, VSR);
    Range := VSR.MaxValue.ll -VSR.MinValue.ll;
    if Range>0 then begin
      Values.Saturation.ll := (Round(Range / 100) * S)-abs(VSR.MinValue.ll);
      if Values.Saturation.ll < VSR.MinValue.ll then
        Values.Saturation.ll := VSR.MinValue.ll+VSR.StepSize.ll;
      if Values.Saturation.ll > VSR.MaxValue.ll then
        Values.Saturation.ll := VSR.MaxValue.ll-VSR.StepSize.ll;
      if S = 50 then
        Values.Saturation.ll := VSR.DefaultValue.ll;
      Saturation:=S;
    end;

    MFVideoProcessor.SetProcAmpValues(DXVA2_ProcAmp_Saturation or DXVA2_ProcAmp_Contrast or DXVA2_ProcAmp_Brightness ,Values);
  except
  end;
  Set8087CW(CW);
end;

function TDirectShowHelper.GetBalance;
var
  BasicAudio:IBasicAudio;
  Filter:IBaseFilter;
begin
  Result:=0;
  Filter:=GetAudioRenderer(Index);
  if Assigned(Filter) then begin
    if SUCCEEDED(Filter.QueryInterface(IID_IBasicAudio,BasicAudio)) then
      BasicAudio.get_Balance(Result);
    BasicAudio:=NIL;
  end;
  Filter:=NIL;
end;

function TDirectShowHelper.GetVolume;
var
  BasicAudio:IBasicAudio;
  Filter:IBaseFilter;
begin
  Result:=0;
  Filter:=GetAudioRenderer(Index);
  if Assigned(Filter) then begin
    if SUCCEEDED(Filter.QueryInterface(IID_IBasicAudio,BasicAudio)) then
      BasicAudio.get_Volume(Result);
    BasicAudio:=NIL;
  end;
  Filter:=NIL;
end;

procedure TDirectShowHelper.SetBalance;
var
  BasicAudio:IBasicAudio;
  Filter:IBaseFilter;
begin
  Filter:=GetAudioRenderer(Index);
  if Assigned(Filter) then begin
    if SUCCEEDED(Filter.QueryInterface(IID_IBasicAudio,BasicAudio)) then begin
      BasicAudio.put_Balance(Balance);
    end;
    BasicAudio:=NIL;
  end;
  Filter:=NIL;
end;

procedure TDirectShowHelper.SetVolume;
var
  BasicAudio:IBasicAudio;
  Filter:IBaseFilter;
begin
  Filter:=GetAudioRenderer(Index);
  if Assigned(Filter) then begin
    if SUCCEEDED(Filter.QueryInterface(IID_IBasicAudio,BasicAudio)) then begin
      BasicAudio.put_Volume(Volume);
    end;
    BasicAudio:=NIL;
  end;
  Filter:=NIL;
end;

function TDirectShowHelper.CreateFilter(CLSID:TGUID): IBaseFilter;
var
  hR:HRESULT;
begin
  Result:=NIL;
  hR:=CoCreateInstance(CLSID,NIL,CLSCTX_INPROC,IID_IBaseFilter,Result);
  if FAILED(hR) then
    Result:=NIL;
end;

function TDirectShowHelper.CreateFilter(CLSID:TGUID;out HR:HRESULT):IBaseFilter;
begin
  Result:=NIL;
  hR:=CoCreateInstance(CLSID,NIL,CLSCTX_INPROC,IID_IBaseFilter,Result);
  if FAILED(hR) then
    Result:=NIL;
end;

function TDirectShowHelper.GetParentFilter;
var
  PInfo:TPININFO;
begin
  Result:=NIL;
  if (Pin=NIL) then Exit;

  if FAILED(Pin.QueryPinInfo(PInfo)) then Exit;
  Result:=PInfo.pFilter;
  PInfo.pFilter:=NIL;
  Pin:=NIL;
end;

function TDirectShowHelper.ConnectFilters;
var
  PinO:IPin;
  CW: Word;
begin
  CW := Get8087CW;
  Set8087CW($133f);
  Result:=E_FAIL;
  if (FSrc=NIL) then Exit;
  if (FDest=NIL) then Exit;

  if PAM<>NIL then begin
    if IsEqualGUID(PAM.majortype,MEDIATYPE_Video) then
      PinO:=GetUnconnectedPin(FSrc,PINDIR_OUTPUT,PT_VIDEO);
    if IsEqualGUID(PAM.majortype,MEDIATYPE_Audio) then
      PinO:=GetUnconnectedPin(FSrc,PINDIR_OUTPUT,PT_AUDIO);
  end
  else
    PinO:=GetUnconnectedPin(FSrc,PINDIR_OUTPUT);
  if (PinO=NIL) then Exit;
  Result:=ConnectPinToFilter(PinO,FDest,PAM);

  PinO:=NIL;
  Set8087CW(CW);
end;

function TDirectShowHelper.ConnectPinToFilter;
var
  PinI:IPin;
  CW: Word;
begin
  CW := Get8087CW;
  Set8087CW($133f);
  Result:=E_FAIL;
  if (PinO=NIL) then Exit;
  if (Flt=NIL) then Exit;

  PinI:=GetPin(Flt,PINDIR_INPUT);
  if (PinI=NIL) then Exit;

  if PAM<>NIL then
    Result:=Graph.ConnectDirect(PinO,PinI,PAM)
  else
    Result:=Graph.ConnectDirect(PinO,PinI,NIL);
  PinI:=NIL;
  Set8087CW(CW);
end;

function TDirectShowHelper.PrevFilter(Filter: IBaseFilter): IBaseFilter;
var
  CPin,Pin:IPin;
  PInfo:TPININFO;
begin
  Result:=NIL;
  Pin:=DSH.GetPin(Filter,PINDIR_INPUT);
  if Assigned(Pin) then begin
    E(Pin.ConnectedTo(CPin),'Pin.ConnectedTo(CPin)');
    E(CPin.QueryPinInfo(PInfo),'PInfo.QueryPinInfo');
    Result:=PInfo.pFilter;
  end;
  PInfo.pFilter:=NIL;
  CPin:=NIL;
  Pin:=NIL;
end;

function TDirectShowHelper.GetVideoProcProps;
var
  F:IBaseFilter;
  IVP:IVideoProcessor;
begin
  Result:=NIL;
  if Filter<>NIL then
    F:=Filter
  else
    F:=DSH.GetVideoProcessor;
  if Assigned(F) then begin
    IVP:=F as IVideoProcessor;
    IVP.GetProps(Result);
    F:=NIL;
    IVP:=NIL;
  end;
end;

procedure TDirectShowHelper.SwitchCCOff;
var
  Filter:IBaseFilter;
  Dec21:IAMLine21Decoder;
begin
  Exit;
  if not(IsDVD) then Exit;

  Filter:=GetFilter(CLSID_Line21Decoder);
  if (Filter=NIL) then Exit;

  try
    Dec21:=Filter as IAMLine21Decoder;
    Dec21.SetServiceState(AM_L21_CCSTATE_Off);
  except
  end;
end;

function TDirectShowHelper.GetFilter(CLSID: TGUID): IBaseFilter;
var
  FEnum:IEnumFilters;
  Filter:IBaseFilter;
  Fetched:cardinal;
begin
  Result:=NIL;
  if (Graph=NIL) then Exit;

  E(Graph.EnumFilters(FEnum),'Graph.EnumFilters');
  while (FEnum.Next(1,Filter,@Fetched)=S_OK) do begin
    try
      if IsEqualGUID(CLSID,GetCLSID(Filter)) then begin
        Result:=Filter;
        Break;
      end;
    except
    end;
    Filter:=NIL;
  end;
  FEnum:=NIL;
end;

procedure TDirectShowHelper.ProcessMediaEvent(EvCode, P1, P2: Integer);
var
  Flags:DWORD;
begin
  case EvCode of
    EC_DVD_CURRENT_HMSF_TIME:begin
      DVDPos:=TDVDHMSFTIMECODE(P1);
    end;
    EC_DVD_DOMAIN_CHANGE:begin
      if FAILED(DVDInfo.GetTotalTitleTime(DVDDur,Flags)) then begin
        DVDDur.bSeconds:=1;
      end;
    end;
  end;
end;

procedure TDirectShowHelper.DVDMenu;
var
  DVDCmd:IDVDCmd;
begin
  if Assigned(DVDControl) then
    if SUCCEEDED(DVDControl.ShowMenu(DVD_MENU_Title,1{DVD_CMD_FLAG_Flush},DVDCmd)) then begin
      DVDCmd.WaitForEnd;
      DVDCmd:=NIL;
    end;
end;

function TDirectShowHelper.BuildDVDGraph;
var
  DVDN:IBaseFilter;
  Pin:IPin;
  Decoder:IBaseFilter;
  FInfo:TFilterInf;
begin
  CoCreateInstance(CLSID_DVDNavigator,NIL,CLSCTX_INPROC,IID_IBaseFilter,DVDN);
  Graph.AddFilter(DVDN,'DVD Navigator');

  Pin:=GetUnconnectedPin(DVDN,PINDIR_OUTPUT,PT_VIDEO);
  Decoder:=FLibrary.CreateFilter('vidc='+'MPG2',FInfo);
  if Decoder<>NIL then
    Graph.AddFilter(Decoder,PWideChar(WideString(FInfo.NAME)));
  Result:=Succeeded(ConnectFilters(DVDN,Decoder));
  Pin:=GetUnconnectedPin(Decoder,PINDIR_OUTPUT);
  Result:=Result and Succeeded(Graph.Render(Pin));

  Pin:=GetUnconnectedPin(DVDN,PINDIR_OUTPUT);
  Decoder:=FLibrary.CreateFilter('audc='+'2000',FInfo);
  if Decoder<>NIL then
    Graph.AddFilter(Decoder,PWideChar(WideString(FInfo.NAME)));
  ConnectFilters(DVDN,Decoder);
  Pin:=GetUnconnectedPin(Decoder,PINDIR_OUTPUT);
  Graph.Render(Pin);

  Pin:=GetUnconnectedPin(DVDN,PINDIR_OUTPUT);
  Graph.Render(Pin);
  DVDNav:=DVDN;
end;

function TDirectShowHelper.GetDVDTitlesCount: LongInt;
var
  VolNum,CurVol,TitleNum:UINT;
  DS:TDVDDISCSIDE;
begin
  Result:=0;
  if not(IsDVD) then Exit;

  if SUCCEEDED(DVDInfo.GetDVDVolumeInfo(VolNum,CurVol,DS,TitleNum)) then begin
    Result:=TitleNum;
  end;
end;

function TDirectShowHelper.GetAudioLangCount: LongInt;
var
  MA:TDVDMenuAttributes;
  TA:TDVDTitleAttributes;
  l:LongInt;
  PC:array [0..MAX_PATH] of Char;
begin
  Result:=0;
  if not(IsDVD) then Exit;

  if SUCCEEDED(DVDInfo.GetTitleAttributes($FFFFFFFF,MA,TA)) then begin
    Result:=TA.ulNumberOfAudioStreams;

    SetLength(DVDLangNames,Result);
    for l:=0 to Result-1 do begin
      GetLocaleInfo(TA.AudioAttributes[l].Language,LOCALE_SLANGUAGE,@PC[0],MAX_PATH);
      DVDLangNames[l]:=PChar(@PC[0]);
    end;
  end;
end;

procedure TDirectShowHelper.PlayTitle(Index: Integer);
var
  DC:IDVDCmd;
begin
  DC:=NIL;
  DvdControl.PlayTitle(Index,DVD_CMD_FLAG_Block,DC);
end;

procedure TDirectShowHelper.SetDVDAudio(Index: Integer);
var
  DC:IDVDCmd;
begin
  DC:=NIL;
  DvdControl.SelectAudioStream(Index,DVD_CMD_FLAG_Block,DC);
end;

procedure TDirectShowHelper.DisconnectFilter(Filter: IBaseFilter);
var
  PEnum:IEnumPins;
  cPin,Pin:IPin;
  hR:HRESULT;
begin
  E(Filter.EnumPins(PEnum),'Filter.EnumPins');
  while (PEnum.Next(1,Pin,NIL)=S_OK) do begin
    hR:=Pin.ConnectedTo(cPin);
    if (hR<>VFW_E_NOT_CONNECTED) then begin
      E(hR,'Pin.ConnectedTo');
      E(Graph.Disconnect(cPin),'Graph.Disconnect(cPin)');
      cPin:=NIL;
      E(Graph.Disconnect(Pin),'Graph.Disconnect(Pin)');
    end;
    Pin:=NIL;
  end;
  PEnum:=NIL;
end;

function TDirectShowHelper.GetNthFilter;
var
  FEnum:IEnumFilters;
  Filter:IBaseFilter;
  Fetched:cardinal;
  Cur:LongInt;
begin
  Result:=NIL;
  if (Graph=NIL) then Exit;

  Cur:=0;
  E(Graph.EnumFilters(FEnum),'Graph.EnumFilters');
  while (FEnum.Next(1,Filter,@Fetched)=S_OK) do begin
    try
      if IsEqualGUID(CLSID,GetCLSID(Filter)) then begin
        if (Cur=N) then begin
          Result:=Filter;
          Break;
        end;
        Inc(Cur);
      end;
    except
    end;
    Filter:=NIL;
  end;
  FEnum:=NIL;
end;

procedure TDirectShowHelper.EnableStream;
var
  MediaConrol: IMediaControl;
  GraphState: TFilterState;
  CW:DWORD;
begin
  FilterGraph.QueryInterface(IID_IMediaControl, MediaConrol);
  if Assigned(MediaControl) then begin
    MediaControl.GetState(0, GraphState);
    CW := Get8087CW;
    Set8087CW($133f);
    MediaControl.Stop;
    Set8087CW(CW);
  end;

  StreamSelect.Enable(Index, AMSTREAMSELECTENABLE_ENABLE);
  if Assigned(MediaControl) and (GraphState = State_Running) then
    MediaControl.Run;
  MediaConrol := nil;
end;

function TDirectShowHelper.GetAudioProcessor;
var
  FEnum: IEnumFilters;
  Filter: IBaseFilter;
  APIntf: IAudioProcessor;
begin
  Filter := nil;
  Result := nil;

  if not Assigned(Graph) then Exit;
  if Graph.EnumFilters(FEnum) <> S_OK then Exit;

  while FEnum.Next(1, Filter, nil) = S_OK do
  begin
    if Filter.QueryInterface(IID_AudioProcessor, APIntf) = S_OK then
    begin
      Result := Filter;
      APIntf := nil;
      Break;
    end;
    Filter := nil;
  end;
  FEnum := nil;
end;

function TDirectShowHelper.GetStreamSelector(out StreamSelector: IBaseFilter): Boolean;
var
  FEnum: IEnumFilters;
  Filter: IBaseFilter;
  StrSel: IAMStreamSelect;
  TotalStreamsCount: Cardinal;

  ACount: Cardinal;
  SCount: Cardinal;
  ARIndex: TRealIndex;
  SRIndex: TRealIndex;

  pMediaType: PAMMEDIATYPE;
  Flags, LCID, Group: Cardinal;
  Name: PWideChar;
  Obj1, Obj2: IUnknown;

  Index: Cardinal;
begin
  Result := False;
  TotalStreamsCount := 0;

  if not Assigned(Graph) then Exit;
  if Graph.EnumFilters(FEnum) <> S_OK then Exit;

  while FEnum.Next(1, Filter, nil) = S_OK do
  begin
    try
      if Filter.QueryInterface(IID_IAMStreamSelect, StrSel) = S_OK then
      begin
        StrSel.Count(TotalStreamsCount);

        Index:=0;
        ACount:=0;
        SCount:=0;
        while Index < TotalStreamsCount do begin
          if StrSel.Info(Index, pMediaType, Flags, LCID, Group, Name, Obj1, Obj2) = S_OK then begin
            if IsEqualGUID(pMediaType^.majortype, MEDIATYPE_Audio) or
              IsEqualGUID(pMediaType^.majortype, MEDIATYPE_AnalogAudio)or
              IsEqualGUID(pMediaType^.majortype, KSDATAFORMAT_TYPE_AUDIO)
            then begin
              ARIndex[ACount]:=Index;
              inc(ACount);
            end;
            if IsEqualGUID(pMediaType^.majortype, MEDIATYPE_Subtitle) then begin
              SRIndex[SCount]:=Index;
              inc(SCount);
            end;
          end;
          DeleteMediaType(pMediaType);
          Inc(Index);
        end;

        if (ACount > AudioStreamCount)or
           ((ACount>0) and (ACount=AudioStreamCount))
        then begin
          AudioStreamCount:=ACount;
          ARealIndex:=ARIndex;
          StreamSelector:=Filter;
          Result := True;
        end;

        if (SCount > SubsStreamCount)or
           ((SCount>0) and (SCount=SubsStreamCount))
        then begin
          SubsStreamCount:=SCount;
          SRealIndex:=SRIndex;
          StreamSelector:=Filter;
          Result := True;
        end;
        StrSel := nil;
      end;
      Filter := nil;
    except
    end;
  end;
  FEnum := nil;
end;

function TDirectShowHelper.AStreamSelectAvaible: Boolean;
var
  Selector: IBaseFilter;
begin
  Result:=False;
  if not GetStreamSelector(Selector) then Exit;
  Result:=not(GetAudioRendererCount>1);
  Selector:=nil;
end;

function TDirectShowHelper.SStreamSelectAvaible: Boolean;
var
  Selector: IBaseFilter;
begin
  Result:=GetStreamSelector(Selector);
  Selector:=nil;
end;

function TDirectShowHelper.GetAudioStream: Cardinal;
var
  Selector: IBaseFilter;
  StrSel: IAMStreamSelect;
  Index: Cardinal;

  pMediaType: PAMMEDIATYPE;
  Flags, LCID, Group: Cardinal;
  Name: PWideChar;
  Obj1, Obj2: IUnknown;
begin
  Result:=0;
  if not GetStreamSelector(Selector) then Exit;
  Index:=0;

  Selector.QueryInterface(IID_IAMStreamSelect, StrSel);
  while Index < AudioStreamCount do
  begin
    if StrSel.Info(ARealIndex[Index], pMediaType, Flags, LCID, Group, Name, Obj1, Obj2) = S_OK then begin
      if IsEqualGUID(pMediaType^.majortype, MEDIATYPE_Audio) or
         IsEqualGUID(pMediaType^.majortype, MEDIATYPE_AnalogAudio) or
         IsEqualGUID(pMediaType^.majortype, KSDATAFORMAT_TYPE_AUDIO)
      then begin
        if (Flags and AMSTREAMSELECTINFO_ENABLED > 0) then begin
          Result := Index+1;
          Exit;
        end;
      end;
    end;
    DeleteMediaType(pMediaType);
    Inc(Index);
  end;

  Selector := nil;
  StrSel := nil;
end;

procedure TDirectShowHelper.SetAudioStream(Index: Cardinal);
var
  Selector: IBaseFilter;
  StrSel: IAMStreamSelect;
begin
  if not GetStreamSelector(Selector) then Exit;
  if Selector.QueryInterface(IID_IAMStreamSelect, StrSel) = S_OK then begin
    EnableStream(Graph, StrSel, ARealIndex[Index-1]);
  end;
  Selector := nil;
  StrSel := nil;
end;

procedure TDirectShowHelper.SetEQBand;
var
  Filter:IBaseFilter;
begin
  Filter:=GetAudioProcessor;
  if Filter<>nil then
    (Filter as IAudioProcessor).set_EQGainDB(Index, Value);
end;

function TDirectShowHelper.GetEQBand;
var
  Filter:IBaseFilter;
begin
  Result:=0;
  Filter:=GetAudioProcessor;
  if Filter<>nil then
    (Filter as IAudioProcessor).set_EQGainDB(Index, Result);
end;

procedure TDirectShowHelper.SetEQPreAmp(Value: Single);
var
  Filter:IBaseFilter;
begin
  Filter:=GetAudioProcessor;
  if Filter<>nil then
    (Filter as IAudioProcessor).set_EQPreAmp(Value);
end;

function TDirectShowHelper.GetEQPreAmp: Single;
var
  Filter:IBaseFilter;
begin
  Result:=0;
  Filter:=GetAudioProcessor;
  if Filter<>nil then
    (Filter as IAudioProcessor).get_EQPreAmp(Result);
end;

function TDirectShowHelper.GetDAEnabled: Bool;
var
  Filter:IBaseFilter;
begin
  Result:=False;
  Filter:=GetAudioProcessor;
  if Filter<>nil then
    (Filter as IAudioProcessor).get_DAEnabled(Result);
end;

procedure TDirectShowHelper.SetDAEnabled(Value: Bool);
var
  Filter:IBaseFilter;
begin
  Filter:=GetAudioProcessor;
  if Filter<>nil then
    (Filter as IAudioProcessor).set_DAEnabled(Value);
end;

function TDirectShowHelper.GetDAMaxAmplify: Cardinal;
var
  Filter:IBaseFilter;
begin
  Result:=0;
  Filter:=GetAudioProcessor;
  if Filter<>nil then
    (Filter as IAudioProcessor).get_DAMaxAmp(Result);
end;

procedure TDirectShowHelper.SetDAMaxAmplify(Value: Cardinal);
var
  Filter:IBaseFilter;
begin
  Filter:=GetAudioProcessor;
  if Filter<>nil then
    (Filter as IAudioProcessor).set_DAMaxAmp(Value);
end;

function TDirectShowHelper.GetSubsStream: Cardinal;
var
  Selector: IBaseFilter;
  StrSel: IAMStreamSelect;
  Index: Cardinal;

  pMediaType: PAMMEDIATYPE;
  Flags, LCID, Group: Cardinal;
  Name: PWideChar;
  Obj1, Obj2: IUnknown;
begin
  Result:=0;
  if not GetStreamSelector(Selector) then Exit;
  Index:=0;

  Selector.QueryInterface(IID_IAMStreamSelect, StrSel);
  while Index < SubsStreamCount do
  begin
    if StrSel.Info(SRealIndex[Index], pMediaType, Flags, LCID, Group, Name, Obj1, Obj2) = S_OK then begin
      if IsEqualGUID(pMediaType^.majortype, MEDIATYPE_Subtitle) then begin
        if (Flags and AMSTREAMSELECTINFO_ENABLED > 0) then begin
          Result := Index+1;
          Exit;
        end;
      end;
    end;
    DeleteMediaType(pMediaType);
    Inc(Index);
  end;

  Selector := nil;
  StrSel := nil;
end;

procedure TDirectShowHelper.SetSubsStream(Index: Cardinal);
var
  Selector: IBaseFilter;
  StrSel: IAMStreamSelect;
begin
  if not GetStreamSelector(Selector) then Exit;
  if Selector.QueryInterface(IID_IAMStreamSelect, StrSel) = S_OK then begin
    EnableStream(Graph, StrSel, SRealIndex[Index-1]);
  end;
  Selector := nil;
  StrSel := nil;
end;

end.
