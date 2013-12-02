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
unit AdvGraphBuilder;

interface

uses
  Windows, Classes, SysUtils, ShellAPI, Activex, MMSystem,
  
  CachedFile, DirectShow9, DShowHlp, MultiLog, FilterLib,
  DCBassSourceIntf, FilterBase, AudioProcessor, VideoProcessor;

type
  TPinArray = array of IPin;

  TAdvancedGraphBuilder = class(TObject)
  private
    DSH:TDirectShowHelper;
    FLib:TFilterLibrary;
    FastRender:Boolean;
    FirstTrack:Boolean;

    function GetFormat(FileName:String):String;
    function BuildSource(FileName:String):Boolean;

    procedure RenderFreePins(ForceRender:Boolean = False);
    procedure FindUnconnectedPins(var ResPins, SubsPins:TPinArray);
    function IsPinOutput(Pin:IPin):Boolean;

    function RenderPin(Pin:IPin):Boolean;
    function RenderPinByFilterStd(Pin:IPin;Filter:IBaseFilter;Name:String):Boolean;
    function RenderVideoPinByFilter(Pin:IPin;Filter:IBaseFilter;Name:String;MT:PAMMEDIATYPE):Boolean;
    function RenderAudioPinByFilter(Pin:IPin;Filter:IBaseFilter;Name:String;MT:PAMMEDIATYPE):Boolean;
    function RenderVideoPinByFilterFast(Pin:IPin;Filter:IBaseFilter;Name:String;MT:PAMMEDIATYPE):Boolean;
    function RenderAudioPinByFilterFast(Pin:IPin;Filter:IBaseFilter;Name:String;MT:PAMMEDIATYPE):Boolean;
    function RenderSubsPinByFilter(Pin:IPin;Filter:IBaseFilter;Name:String;MT:PAMMEDIATYPE):Boolean;

    function ConnectVideoRenderer(Decoder:IBaseFilter; Renderer:IBaseFilter=NIL):Boolean;
    function ConnectAudioRenderer(Decoder:IBaseFilter; Renderer:IBaseFilter=NIL):Boolean;

    procedure SetMissRequest(Request:String);
    function FCC2Str(FCC:DWORD):String;
  protected
    function RenderPinByCLSID(Pin:IPin;CLSID:TGUID;Name:String):Boolean;
  public
    FMT:String;
    MissReq:String;
    PartialRender,CompleteRender:Boolean;

    constructor Create(ADSH:TDirectShowHelper);
    destructor Destroy; override;

    procedure Init;
    procedure DisableSubs;
    procedure RefreshShoutCastTags;
    function Render(FileName:String):Boolean;
  end;

implementation

uses
  Forms, MainUnit, LACore, SysHlp;

var
  TimerCounter: Byte = 10;
  TagsReadFreq: Byte = 10;

function TAdvancedGraphBuilder.BuildSource(FileName: String): Boolean;
const
  FSName = 'File Source';
var
  hR:HRESULT;
  FRdr,FSrc,Filter:IBaseFilter;
  FSI:IFileSourceFilter;
  FInfo:TFilterInf;
  Name:array [0..MAX_PATH-1] of WChar;
  IsSC:LongBool;
  CW:Word;
begin
  Log('+TAdvGraphBuilder.BuildSource');
  CW := Get8087CW;
  Set8087CW($133f);
  Result:=FALSE;
  FSI:=NIL;

  if (FMT<>'Unknown') then begin
    Filter:=FLib.CreateFilter('format='+FMT,FInfo);
    if (Filter<>NIL) then begin
      MultiByteToWideChar(CP_ACP,0,PChar(FInfo.Name),-1,Name,MAX_PATH);
      hR:=DSH.Graph.AddFilter(Filter as IBaseFilter, Name);
      LogHR('TAdvGraphBuilder.BuildSource: AddFilter('+FInfo.Name+')=',hR);
      Filter.QueryInterface(IID_IFileSourceFilter,FSI);
      if FSI<>NIL then
        hR:=FSI.Load(PWideChar(WideString(FileName)),NIL);
      if not SUCCEEDED(hR) or (FSI=NIL) then begin
        if FLib.SwapSourceToSplitter(FInfo) then begin
          DSH.Graph.RemoveFilter(Filter);
          Filter:=FLib.CreateFilterByInfo(FInfo);
          MultiByteToWideChar(CP_ACP,0,PChar(FInfo.Name),-1,Name,MAX_PATH);
          DSH.Graph.AddFilter(Filter as IBaseFilter, Name);
        end;
        if System.Pos(':/',FileName)=0 then
          FRdr:=DSH.CreateFilter(CLSID_AsyncReader)
        else
          FRdr:=DSH.CreateFilter(CLSID_URLReader);
        DSH.Graph.AddFilter(FRdr,FSName);
        (FRdr as IFileSourceFilter).Load(PWideChar(WideString(FileName)),NIL);
        hR:=DSH.ConnectFilters(FRdr,Filter);
        if not SUCCEEDED(hR) then begin
          DSH.Graph.RemoveFilter(FRdr);
          DSH.Graph.RemoveFilter(Filter);
        end;
      end;
      Result:=SUCCEEDED(hR);
      if Result then FLib.ActiveLocalFilters.Add(FInfo);

      if Result and (FMT='SHOUTCAST') then
        Filter.QueryInterface(IID_IDCBassSource, DCBassSourceControl);
    end;

    if not Result then begin
      hR:=DSH.Graph.AddSourceFilter(PWideChar(WideString(FileName)),FSName,FSrc);
      Result:=SUCCEEDED(hR) and not(IsEqualGUID(DSH.GetCLSID(FSrc),CLSID_AsyncReader));
    end;
  end
  else begin
    hR:=DSH.Graph.AddSourceFilter(PWideChar(WideString(FileName)),FSName,Filter);
    Result:=SUCCEEDED(hR) and not(IsEqualGUID(DSH.GetCLSID(Filter),CLSID_AsyncReader));
  end;

  if (FMT='SHOUTCAST') then begin
    if DCBassSourceControl<>NIL then begin
      DCBassSourceControl.GetIsShoutcast(IsSC);
      IsShoutCast:=IsSC;
    end;
  end;
  Filter:=NIL;
  FSrc:=NIL;
  FRdr:=NIL;
  FSI:=NIL;
  Set8087CW(CW);
  Log('-TAdvGraphBuilder.BuildSource: '+BoolToStr(Result));  
end;

procedure TAdvancedGraphBuilder.RefreshShoutCastTags;
var
  TagsAvaible: LongBool;
  ATag: PWideChar;
begin
  if not IsShoutCast then Exit;
  if TimerCounter < TagsReadFreq then begin
    Inc(TimerCounter);
    Exit;
  end;
  TimerCounter:=0;

  if DCBassSourceControl<>NIL then begin
    DCBassSourceControl.GetIsShoutcast(TagsAvaible);
    if TagsAvaible then begin
      DCBassSourceControl.GetCurrentTag(ATag);
      if (DSH.MetaTags.Title<>ATag) and (ATag<>'') then begin
        DSH.MetaTags.Title:=ATag;
        if (DSH.MetaTags.Title<>'') then begin
          frMain.SetCaption(ATag);
          Application.Title:=DSH.MetaTags.Title;
          Core.Info(ATag);
          if frMain.TrayUsed then begin
            StrPCopy(frMain.IconData.szTip,Copy(DSH.MetaTags.Title,1,63));
            Shell_NotifyIcon(NIM_MODIFY,@frMain.IconData);
          end;
        end;
      end;
      CoTaskMemFree(ATag);
    end;
  end;
end;

constructor TAdvancedGraphBuilder.Create;
begin
  inherited Create;
  DSH:=ADSH;
  FLib:=DSH.FLibrary;
  Core.TimerNotifier.Attach(RefreshShoutCastTags);
end;

destructor TAdvancedGraphBuilder.Destroy;
begin
  Core.TimerNotifier.Detach(RefreshShoutCastTags);
  FLib:=NIL;
  inherited Destroy;
end;

function TAdvancedGraphBuilder.FCC2Str(FCC: DWORD): String;
var
  l:LongInt;
begin
  Result:='';
  for l:=0 to 3 do begin
    Result:=Result+Chr(FCC and $FF);
    FCC:=FCC shr 8;
  end;
end;

procedure TAdvancedGraphBuilder.FindUnconnectedPins;
var
  FEnum:IEnumFilters;
  Filter:IBaseFilter;
  Fetched,MTFetched,l,sl:Longint;
  Pins:IEnumPins;
  Pin:IPin;
  ID: TGUID;
  Skip:Boolean;
  MT:PAMMEDIATYPE;
  EMT:IEnumMediaTypes;
begin
  if not(Assigned(DSH.Graph)) then Exit;
  l:=0;
  sl:=0;

  if FAILED(DSH.Graph.EnumFilters(FEnum)) then Exit;
  while (FEnum.Next(1,Filter,@Fetched)=S_OK) do begin
    Filter.GetClassID(ID);
    if SUCCEEDED(Filter.EnumPins(Pins)) then begin
      Pins.Reset;
      while (Pins.Next(1,Pin,@Fetched)=S_OK) do begin
        if not IsPinOutput(Pin) then Continue;
        Skip:=IsEqualGUID(ID,CLSID_VideoProcessor);
        Skip:=Skip or IsEqualGUID(ID,CLSID_AudioProcessor);
        if not(DSH.IsPinConnected(Pin)) then begin
          Pin.EnumMediaTypes(EMT);
          EMT.Reset;
          while (EMT.Next(1,MT,@MTFetched)=S_OK) do begin
            if IsEqualGUID(MT.MajorType,MEDIATYPE_Subtitle)
              or IsEqualGUID(MT.MajorType,MEDIATYPE_Text)
            then begin
              Skip:=True;
              Inc(sl);
              SetLength(SubsPins,sl);
              SubsPins[sl-1]:=Pin;
              Break;
            end;
            DSH.FreeMediaType(MT^);
          end;

          if not Skip then begin
            Inc(l);
            SetLength(ResPins,l);
            ResPins[l-1]:=Pin;
          end;
          EMT:=NIL;
        end;
        Pin:=NIL;
      end;
      Pins:=NIL;
    end;
    Filter:=NIL;
  end;
end;

function TAdvancedGraphBuilder.IsPinOutput(Pin: IPin): Boolean;
var
  PDir:TPINDIRECTION;
begin
  Result:=FALSE;
  if not(Assigned(Pin)) then Exit;

  Pin.QueryDirection(PDir);
  Result:=(PDir=PINDIR_OUTPUT);
end;

function TAdvancedGraphBuilder.Render;
var
  AVS,AVSTmp,S,PlugDir:String;
  hR:HRESULT;
  f:file;
begin
  Log('+TAdvGraphBuilder.Render');
  Init;

  if INI.Bool['Modules.AviSynth.Enabled'] then begin
    AVS:=Core.Prefs.ReadString('Modules.AviSynth.Script');
    AVS:=ExtractFilePath(Core.ExeName)+'Plugins\AviSynth\'+AVS;
    AVSTmp:=Core.SysHlp.GetTempFolder+'Temp.avs';

    AssignFile(f,AVS);
    Reset(f,1);
    SetLength(S,FileSize(f));
    BlockRead(f,S[1],Length(S));
    CloseFile(f);

    S:=StringReplace(S,'{SOURCE}','"'+FileName+'"',[rfReplaceAll,rfIgnoreCase]);
    PlugDir:=ExtractFilePath(Core.ExeName)+'Plugins\AviSynth';
    S:=StringReplace(S,'{PLUGS}',PlugDir,[rfReplaceAll,rfIgnoreCase]);

    AssignFile(f,AVSTmp);
    Rewrite(f,1);
    BlockWrite(f,S[1],Length(S));
    CloseFile(f);

    FileName:=AVSTmp;
  end;

  FMT:=GetFormat(FileName);
  Log('File format: '+FMT);
  if FMT='Unknown' then SetMissRequest('ext='+ExtractFileExt(FileName));

  if FastRender and (FMT<>'IFO') then begin
    Log('=Fast.Render');
    hR:=E_FAIL;
  end else begin
    if not (FMT='SHOUTCAST') then
      hR:=DSH.RenderFile(FileName)
    else
      hR:=E_FAIL;
    LogHR('TAdvGraphBuilder.Render: DSH.RenderFile:',hR);
    DSH.SetAudioRenderers;
  end;

  PartialRender:=SUCCEEDED(hR);
  CompleteRender:=(hR=S_OK);

  if PartialRender then
    if not(CompleteRender) then
      RenderFreePins;

  if not FastRender then begin
    DSH.CheckForAV;
    if ((Length(Core.Player.MI.FInfo.VStreams)>0) and (not DSH.HasVideo)) or
       ((Length(Core.Player.MI.FInfo.AStreams)>0) and (not DSH.HasAudio))
    then
      CompleteRender:=False;
  end;

  if not(CompleteRender) then begin
    if not FastRender then begin
      DSH.ClearGraph;
      DSH.SetVideoRenderer;
      DSH.SetProcessors;
    end;
    if BuildSource(FileName) then
      RenderFreePins(True);
    DSH.SetAudioRenderers;
  end;

  if FastRender and (not PartialRender) then begin
    Log('TAdvGraphBuilder: Standard rendering');
    DSH.ClearGraph;
    DSH.SetVideoRenderer;
    DSH.SetProcessors;
    hR:=DSH.RenderFile(FileName);
    if hR=S_OK then
      CompleteRender:=TRUE;
    DSH.SetAudioRenderers;
  end;
  DSH.RemoveFreeVideoRenderer;
  DSH.RemoveFreeAudioRenderer;

  if hR = VFW_S_PARTIAL_RENDER then PartialRender:=True;
  Result:=(PartialRender or CompleteRender);
  Log('-TAdvGraphBuilder.Render: '+BoolToStr(Result));
end;

procedure TAdvancedGraphBuilder.RenderFreePins;
var
  Pins,SubsPins:TPinArray;
  l:LongInt;
begin
  Log('+TAdvGraphBuilder.RenderFreePins');
  CompleteRender:=TRUE;
  if not FastRender then
    if ForceRender then begin
      FastRender:=ForceRender;
      Log('=Forced.Render');
    end;

  SetLength(Pins,0);
  SetLength(SubsPins,0);
  FindUnconnectedPins(Pins,SubsPins);
  for l:=0 to Length(Pins)-1 do begin
    Log('TAdvGraphBuilder.RenderFreePins: Pin # '+IntToStr(l));
    if RenderPin(Pins[l]) then
      PartialRender:=TRUE
    else
      CompleteRender:=FALSE;
    Pins[l]:=NIL;
  end;

  if not Core.Prefs.ReadBool('Modules.DirectShow.DisableSubs') then
    for l:=0 to Length(SubsPins)-1 do begin
      Log('TAdvGraphBuilder.SubsPin: Pin # '+IntToStr(l));
      RenderPin(SubsPins[l]);
    end;

  SetLength(Pins,0);
  SetLength(SubsPins,0);
  Log('-TAdvGraphBuilder.RenderFreePins');
end;

function TAdvancedGraphBuilder.RenderPin(Pin: IPin): Boolean;
var
  PAM:PAMMEDIATYPE;
  MediaTypes:IEnumMediaTypes;
  Fetched:LongInt;
  FCC:String;
  FInfo:TFilterInf;
  hR:HRESULT;
  Request:String;
  Filter:IBaseFilter;
  PI:TPinInfo;
begin
  Pin.QueryPinInfo(PI);
  Log('+TAdvGraphBuilder.RenderPin of ['+DSH.GetFilterName(PI.pFilter)+']');
  Result:=FALSE;
  if not(Assigned(Pin)) then begin
    Log('-TAdvGraphBuilder.RenderPin(NIL Pin)');
    Exit;
  end;
  Request:='';

  if not FastRender then begin
    hR:=DSH.Graph.Render(Pin);
    LogHR('TAdvGraphBuilder.RenderPin: TryNormal DSH.Graph.Render(Pin)',hR);
    if SUCCEEDED(hR) then begin
      Result:=TRUE;
      PartialRender:=TRUE;
      Log('-TAdvGraphBuilder.RenderPin(NormalRender)');
      Exit;
    end;
  end;

  Pin.EnumMediaTypes(MediaTypes);
  while (MediaTypes.Next(1,PAM,@Fetched)=S_OK) and (not Result) do begin
    if IsEqualGUID(PAM^.MajorType,MEDIATYPE_VIDEO)
      or IsEqualGUID(PAM^.FormatType,FORMAT_MPEGVideo) then begin
      FCC:=FLib.FCC2Str(PAM.SubType.D1);
      if IsEqualGUID(PAM^.SubType,MEDIASUBTYPE_MPEG1Payload) then FCC:='MPG1';
      if IsEqualGUID(PAM^.SubType,KSDATAFORMAT_SUBTYPE_MPEG1Video) then FCC:='MPG1';
      if IsEqualGUID(PAM^.SubType,MEDIASUBTYPE_MPEG2_VIDEO) then FCC:='MPG2';
      if IsEqualGUID(PAM^.SubType,KSDATAFORMAT_SUBTYPE_MPEG2_VIDEO) then FCC:='MPG2';
      Filter:=Flib.CreateFilter('vidc='+FCC,FInfo);
      if RenderVideoPinByFilter(Pin,Filter,FInfo.NAME,PAM) then begin
        FLib.ActiveLocalFilters.Add(FInfo);
        Result:=TRUE;
      end
      else
        Request:='vidc='+FCC;
    end;

    if IsEqualGUID(PAM^.MajorType,MEDIATYPE_AUDIO) then begin
      if IsEqualGUID(PAM^.FormatType,FORMAT_WaveFormatEx) then
        FCC:=Format('%.4x',[TWAVEFORMATEX(PAM^.pbFormat^).wFormatTag]);
      if (FCC='0000') or (FCC='') then begin
        if IsEqualGUID(PAM^.SubType,MEDIASUBTYPE_DOLBY_AC3) then FCC:='2000';
        if IsEqualGUID(PAM^.SubType,MEDIASUBTYPE_Ogg) then FCC:='674F';
        if IsEqualGUID(PAM^.SubType,MEDIASUBTYPE_Vorbis) then FCC:='674F';
        if IsEqualGUID(PAM^.SubType,MEDIASUBTYPE_Vorbis2) then FCC:='674F';
      end;
      if not (FCC='0001') then
        Filter:=FLib.CreateFilter('audc='+FCC,FInfo);
      if RenderAudioPinByFilter(Pin,Filter,FInfo.NAME,PAM) then begin
        FLib.ActiveLocalFilters.Add(FInfo);
        Result:=TRUE;
      end
      else
        Request:='audc='+FCC;
    end;

    if IsEqualGUID(PAM^.MajorType,MEDIATYPE_Subtitle) then begin
      if not (Core.Prefs.ReadBool('Modules.DirectShow.DisableSubs')) then begin
        FCC:='SUBS';
        Filter:=Flib.CreateFilter('advf='+FCC,FInfo);
        if RenderSubsPinByFilter(Pin,Filter,FInfo.NAME,PAM) then begin
          FLib.ActiveLocalFilters.Add(FInfo);
          Result:=TRUE;
        end;
      end;
    end;
    DSH.DeleteMediaType(PAM);
  end;
  Filter:=NIL;
  MediaTypes:=NIL;

  if FastRender and (not Result) then begin
    hR:=DSH.Graph.Render(Pin);
    if SUCCEEDED(hR) then begin
      Result:=TRUE;
      PartialRender:=TRUE;
    end
    else if Request<>'' then
      SetMissRequest(Request);
  end;

  Log('-TAdvGraphBuilder.RenderPin: '+BoolToStr(Result));
end;

function TAdvancedGraphBuilder.RenderVideoPinByFilter;
begin
  Result:=False;
  if Filter=NIL then Exit;
  if FastRender then
    Result:=RenderVideoPinByFilterFast(Pin,Filter,Name,MT)
  else
    Result:=RenderPinByFilterStd(Pin,Filter,Name)
end;

function TAdvancedGraphBuilder.RenderAudioPinByFilter;
begin
  Result:=False;
  if Filter=NIL then Exit;
  if FastRender then
    Result:=RenderAudioPinByFilterFast(Pin,Filter,Name,MT)
  else
    Result:=RenderPinByFilterStd(Pin,Filter,Name)
end;

procedure TAdvancedGraphBuilder.Init;
begin
  MissReq:='';
  PartialRender:=FALSE;
  CompleteRender:=FALSE;
  FastRender:=Core.Prefs.ReadBool('Modules.DirectShow.FastRender');
  FirstTrack:=True;
end;

procedure TAdvancedGraphBuilder.SetMissRequest(Request: String);
begin
  MissReq:=Request;
end;

function TAdvancedGraphBuilder.RenderPinByFilterStd;
var
  hR:HRESULT;
begin
  Result:=FALSE;
  if not(Assigned(Pin)) then Exit;
  if not(Assigned(Filter)) then Exit;

  hR:=DSH.Graph.AddFilter(Filter,PWideChar(WideString(Name)));
  LogHR('TAdvGraphBuilder.RenderPinByFilter:DSH.Graph.AddFilter('+Name+')=',hR);
  if SUCCEEDED(hR) then begin
    hR:=DSH.Graph.Render(Pin);
    LogHR('TAdvGraphBuilder.RenderPinByFilter:DSH.Graph.Render(Pin)',hR);
    if SUCCEEDED(hR) then Result:=TRUE;
  end;
end;

function TAdvancedGraphBuilder.RenderVideoPinByFilterFast;
var
  Source:IBaseFilter;
  Renderer:IBaseFilter;
  VideoProc:IBaseFilter;
  Props:PVideoProcProps;
  HRF:HRESULT;
  HR:HRESULT;
  VPPin:IPin;
begin
  HR:=S_FALSE;
  Source:=DSH.GetParentFilter(Pin);
  VideoProc:=DSH.GetVideoProcessor;
  Renderer:=DSH.GetVideoRenderer;

  DSH.Graph.AddFilter(Filter, PWideChar(WideString(Name)));
  HRF:=DSH.ConnectFilters(Source, Filter);
  if (VideoProc<>NIL) and SUCCEEDED(HRF) then begin
    Pin:=DSH.GetUnconnectedPin(Filter, PINDIR_OUTPUT);
    VPPin:=DSH.GetUnconnectedPin(VideoProc, PINDIR_INPUT);
    if not Core.Prefs.ReadBool('OSD.WithVideo') then begin
      Props:=DSH.GetVideoProcProps(VideoProc);
      Props.RestrictYV12:=False;
    end;

    hR:=DSH.Graph.Connect(Pin,VPPin);
    if SUCCEEDED(hR) then begin
      HR:=DSH.ConnectFilters(VideoProc, Renderer);
      if FAILED(hR) then begin
        DSH.DisconnectFilter(VideoProc);
        Props:=DSH.GetVideoProcProps(VideoProc);
        Props.RestrictYV12:=True;
        DSH.ConnectFilters(Filter, VideoProc);
        HR:=DSH.ConnectFilters(VideoProc, Renderer);
      end;
      if FAILED(hR) then begin
        if ConnectVideoRenderer(VideoProc, Renderer) then
          HR:=S_OK
        else begin
          DSH.DisconnectFilter(VideoProc);
          VideoProc:=NIL;
        end;
      end;
    end
    else
      VideoProc:=NIL;
  end;

  if (VideoProc=NIL) and SUCCEEDED(HRF) then begin
    hR:=DSH.ConnectFilters(Filter, Renderer);
    if FAILED(hR) then
      if ConnectVideoRenderer(Filter, Renderer) then
        HR:=S_OK
      else begin
        Pin:=DSH.GetUnconnectedPin(Filter, PINDIR_OUTPUT, PT_VIDEO);
        hR:=DSH.Graph.Render(Pin);
      end;
  end;

  if not SUCCEEDED(HRF) then
    DSH.Graph.RemoveFilter(Filter);

  Result:=SUCCEEDED(hR) and SUCCEEDED(HRF);

  Pin:=NIL;
  VPPin:=NIL;
  Source:=NIL;
  VideoProc:=NIL;
  Renderer:=NIL;
end;

function TAdvancedGraphBuilder.RenderAudioPinByFilterFast;
var
  Source:IBaseFilter;
  Renderer:IBaseFilter;
  AudioProc:IBaseFilter;
  HRF:HRESULT;
  HR:HRESULT;
  RName:String;
  FPin:IPin;
  APPin:IPin;
  Direct:Boolean;
begin
  Result:=False;
  Direct:=False;

  Source:=DSH.GetParentFilter(Pin);
  AudioProc:=DSH.GetAudioProcessor;
  Renderer:=DSH.CreateFilter(CLSID_DSoundRender);

  RName:='Default DirectSound Device';
  DSH.Graph.AddFilter(Renderer, PWideChar(WideString(RName)));
  DSH.Graph.AddFilter(Filter, PWideChar(WideString(Name)));

  HRF:=S_FALSE;
  if (not IsEqualGUID(MT^.subtype, MEDIASUBTYPE_PCM)) and
    (not IsEqualGUID(MT^.subtype, MEDIASUBTYPE_IEEE_FLOAT))
  then
    HRF:=DSH.ConnectFilters(Source, Filter)
  else
    Direct:=True;

  if AudioProc<>NIL then begin
    if not Direct then
      FPin:=DSH.GetUnconnectedPin(Filter, PINDIR_OUTPUT, PT_AUDIO)
    else
      FPin:=Pin;
    APPin:=DSH.GetUnconnectedPin(AudioProc, PINDIR_INPUT);
    hR:=DSH.Graph.Connect(FPin,APPin);
    if FirstTrack then begin
      FirstTrack:=False;
      DSH.ConnectFilters(AudioProc, Renderer);
      Result:=SUCCEEDED(hR);
    end;
  end
  else begin
    if not Direct then
      hR:=DSH.ConnectFilters(Filter, Renderer)
    else
      hR:=DSH.ConnectFilters(Source, Renderer);
    Result:=SUCCEEDED(hR);
  end;

  if FAILED(HRF) or Direct then
    DSH.Graph.RemoveFilter(Filter);

  if not SUCCEEDED(HRF) then
    DSH.Graph.RemoveFilter(Renderer);
  Result:=Result and SUCCEEDED(hR);
  FPin:=NIL;
  APPin:=NIL;
  Source:=NIL;
  AudioProc:=NIL;
  Renderer:=NIL;
end;

function TAdvancedGraphBuilder.RenderSubsPinByFilter;
var
  VD: IBaseFilter;
  VP: IBaseFilter;
  VR: IBaseFilter;
  DecID: TGUID;
  HR: HRESULT;
begin
  Result:=FALSE;
  VD:=DSH.GetVideoDecoder;
  VP:=DSH.GetVideoProcessor;
  VR:=DSH.GetVideoRenderer;
  if VD<>NIL then begin
    DecID:=DSH.GetCLSID(VD);
    // ffdshow
    if IsEqualGUID(DecID,VideoDecoders[22].CLSID) then begin
      HR:=DSH.ConnectPinToFilter(Pin,Filter);
      Result:=SUCCEEDED(HR);
    end;
    if not Result then begin
      HR:=DSH.Graph.AddFilter(Filter,PWideChar(WideString(Name)));
      if not SUCCEEDED(HR) then Exit;
      if VR<>NIL then begin
        DSH.DisconnectFilter(VR);
        if VP<>NIL then
          DSH.DisconnectFilter(VP);
        DSH.ConnectFilters(VD,Filter);
        HR:=DSH.ConnectPinToFilter(Pin,Filter);
        if SUCCEEDED(HR) then
          HR:=DSH.ConnectFilters(Filter,VR);
        if not SUCCEEDED(HR) then
          HR:=DSH.Graph.Render(Pin);
        Result:=SUCCEEDED(HR);
        if not Result then
          DSH.ConnectFilters(VD,VR);
      end;
    end;
  end;
end;

function TAdvancedGraphBuilder.ConnectVideoRenderer;
var
  hR:HRESULT;
  Pin:IPin;
  MT:PAMMEDIATYPE;
  MediaTypes:IEnumMediaTypes;
  Fetched:Cardinal;
begin
  Result:=False;
  Pin:=DSH.GetUnconnectedPin(Decoder,PINDIR_OUTPUT);
  if Pin<>nil then
    Pin.EnumMediaTypes(MediaTypes)
  else
    Exit;

  if Renderer=NIL then begin
    DSH.SetVideoRenderer;
    Renderer:=DSH.GetVideoRenderer;
  end;

  MediaTypes.Reset;
  HR:=E_FAIL;
  while (MediaTypes.Next(1,MT,@Fetched)=S_OK) and Failed(HR) do begin
    if IsEqualGUID(MT^.MajorType,MEDIATYPE_Video) then begin
      HR:=DSH.ConnectFilters(Decoder,Renderer,MT);
      if Succeeded(HR) then Result:=True;
    end;
    DSH.DeleteMediaType(MT);
  end;
end;

function TAdvancedGraphBuilder.ConnectAudioRenderer;
var
  hR:HRESULT;
  Pin:IPin;
  MT:PAMMEDIATYPE;
  MediaTypes:IEnumMediaTypes;
  Fetched:Cardinal;
begin
  Result:=False;
  Pin:=DSH.GetUnconnectedPin(Decoder,PINDIR_OUTPUT);
  Renderer:=DSH.GetAudioRenderer;
  if Pin<>nil then
    Pin.EnumMediaTypes(MediaTypes)
  else
    Exit;

  MediaTypes.Reset;
  HR:=E_FAIL;
  while (MediaTypes.Next(1,MT,@Fetched)=S_OK) and Failed(HR) do begin
    if IsEqualGUID(MT^.MajorType,MEDIATYPE_Audio) then begin
      HR:=DSH.ConnectFilters(Decoder,Renderer,MT);
      if Succeeded(HR) then Result:=True;
    end;
    DSH.DeleteMediaType(MT);
  end;
end;

function TAdvancedGraphBuilder.RenderPinByCLSID;
var
  Filter:IBaseFilter;
begin
  Result:=FALSE;
  if not(Assigned(Pin)) then Exit;

  Filter:=DSH.CreateFilter(CLSID);
  if Assigned(Filter) then begin
    Result:=RenderPinByFilterStd(Pin,Filter,Name);
  end;
  Filter:=NIL;
end;

function TAdvancedGraphBuilder.GetFormat;
begin
  Result:=Core.Player.MI.FInfo.FileFormat;
  if (System.Pos(':/',FileName) <> 0) and (Result = 'Unknown') then
    Result:='SHOUTCAST';
end;

procedure TAdvancedGraphBuilder.DisableSubs;
var
  Decoder: IBaseFilter;
  VideoProc: IBaseFilter;
  VobSub: IBaseFilter;
  Renderer: IBaseFilter;
begin
  VobSub:=DSH.GetFilter(AdvancedFilters[0].CLSID);
  if VobSub=NIL then VobSub:=DSH.GetFilter(AdvancedFilters[1].CLSID);
  if VobSub=NIL then Exit;
  Decoder:=DSH.GetVideoDecoder;
  if Decoder=NIL then Exit;
  Renderer:=DSH.GetVideoRenderer;
  if Renderer=NIL then Exit;
  VideoProc:=DSH.GetVideoProcessor;

  DSH.DisconnectFilter(Renderer);
  DSH.DisconnectFilter(VobSub);
  DSH.Graph.RemoveFilter(VobSub);

  if VideoProc <> NIL then begin
    if not DSH.IsFilterConnected(VideoProc,PINDIR_INPUT) then begin
      if SUCCEEDED(DSH.ConnectFilters(Decoder,VideoProc)) then begin
        DSH.ConnectFilters(VideoProc,Renderer);
      end
      else
        DSH.ConnectFilters(Decoder,Renderer);
    end
    else
      DSH.ConnectFilters(VideoProc,Renderer);
  end
  else
    DSH.ConnectFilters(Decoder,Renderer);
end;

end.
