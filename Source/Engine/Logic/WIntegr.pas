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
unit WIntegr;

interface

uses
  Windows, ShlObj, Registry, Forms, SysUtils;

type
  TMediaType = (mtMulti,mtPlayList,mtVideo,mtAudio);

  TWIntegrator = class
  private
    NeedRefresh:boolean;
  public
    constructor Create;
    destructor Destroy; override;

    procedure SetDefaultExts;
    procedure Associate(Ext:string;Link:boolean);
    function IsAssociated(Ext:string):boolean;
    procedure RefreshIcons;
    function GetDescription(Ext:string):string;

    function GetFileMasks(MediaType:TMediaType):string;
    function GetExtIcon(Ext:string):longint;
    function CutExt(var List:string):string;

    function IsDVDAutoRun:boolean;
    procedure SetDVDAutoRun(Flag:boolean);
  end;


implementation

uses
  LACore;

procedure TWIntegrator.Associate;
var
  R:TRegistry;
  s:string;
begin
  if (Link=IsAssociated(Ext)) then Exit;
  NeedRefresh:=TRUE;

  R:=TRegistry.Create;
  R.RootKey:=HKEY_CLASSES_ROOT;

  R.OpenKey('\.'+Ext,TRUE);
  R.WriteString('',Ext+'file');
  s:=R.ReadString('');
  s:='\'+s;
  R.OpenKey(s,TRUE);
  if Link then begin
    R.WriteString('',GetDescription(Ext));
    R.OpenKey(s+'\DefaultIcon',TRUE);
    R.WriteString('LA.Backup',R.ReadString(''));
    R.WriteString('',Application.ExeName+','+IntToStr(GetExtIcon(Ext)));

    R.OpenKey(s+'\Shell',TRUE);
    R.WriteString('LA.Backup',R.ReadString(''));
    R.WriteString('','Open');

    R.OpenKey(s+'\Shell\Open',TRUE);
    R.DeleteValue('LegacyDisable');
    R.DeleteKey('DropTarget');
    R.OpenKey(s+'\Shell\Open\Command',TRUE);
    R.WriteString('LA.Backup',R.ReadString(''));
    R.WriteString('','"'+Application.ExeName+'" "%L"');

    R.OpenKey(s+'\Shell\Play',TRUE);
    R.DeleteValue('LegacyDisable');
    R.OpenKey(s+'\Shell\Play\Command',TRUE);
    R.WriteString('LA.Backup',R.ReadString(''));
    R.WriteString('','"'+Application.ExeName+'" "%L"');

    R.OpenKey(s+'\Shell\Enqueue',TRUE);
    R.WriteString('','En&queue in Light Alloy');
    R.OpenKey(s+'\Shell\Enqueue\Command',TRUE);
    R.WriteString('','"'+Application.ExeName+'" /ADD "%L"');
  end else begin
    R.OpenKey(s+'\Shell',TRUE);
    R.WriteString('',R.ReadString('LA.Backup'));
    R.OpenKey(s+'\DefaultIcon',TRUE);
    R.WriteString('',R.ReadString('LA.Backup'));

    R.OpenKey(s+'\Shell\Open\Command',TRUE);
    R.WriteString('',R.ReadString('LA.Backup'));

    R.OpenKey(s+'\Shell\Play\Command',TRUE);
    R.WriteString('',R.ReadString('LA.Backup'));

    R.DeleteKey(s+'\Shell\Enqueue');
  end;
  R.Free;
end;

constructor TWIntegrator.Create;
begin
  inherited Create;
  NeedRefresh:=FALSE;
end;

function TWIntegrator.CutExt;
begin
  Result:='';
  while (Length(List)>0) and (List[1]=',') do
    Delete(List,1,1);
  while (Length(List)>0) and (List[1]<>',') do begin
    Result:=Result+List[1];
    Delete(List,1,1);
  end;
end;

destructor TWIntegrator.Destroy;
begin
  inherited Destroy;
end;

function TWIntegrator.GetDescription;
begin
  Result:=Ext+' file';
  // Playlist.
  if Ext='ASX'  then Result:='Advanced Streaming Index';
  if Ext='IFO'  then Result:='DVD Index File';
  if Ext='LAP'  then Result:='Light Alloy Playlist';
  if Ext='LST'  then Result:='Files List';
  if Ext='M3U'  then Result:='WinAMP Playlist';
  if Ext='PLS'  then Result:='WinAMP Playlist';

  // Video.
  if Ext='ASF'  then Result:='Advanced Streaming Format';
  if Ext='AVI'  then Result:='Audio-Video Interleaved';
  if Ext='DAT'  then Result:='MPEG movie on VCD or SVCD';
  if Ext='DIVX' then Result:='AVI file compressed with DIVX coder';
  if Ext='OGM'  then Result:='OGG Media';
  if Ext='M1V'  then Result:='MPEG1 only video';
  if Ext='M2V'  then Result:='MPEG2 only video';
  if Ext='MKV'  then Result:='Matroska video';
  if Ext='MOV'  then Result:='Quick Time Movie (ver. 2 and lower)';
  if Ext='MP4'  then Result:='MPEG-4';
  if Ext='MPE'  then Result:='Motion Picture Experts Group';
  if Ext='MPEG' then Result:='Motion Picture Experts Group';
  if Ext='MPG'  then Result:='Motion Picture Experts Group';
  if Ext='MPV'  then Result:='Motion Picture Experts Group';
  if Ext='FLV'  then Result:='Flash Video';
  if Ext='QT'   then Result:='Quick Time Movie (ver. 2 and lower)';
  if Ext='RM'   then Result:='RealMedia';
  if Ext='RV'   then Result:='RealVideo';
  if Ext='RMVB' then Result:='RealMedia and Video';
  if Ext='VOB'  then Result:='Video Object';
  if Ext='WM'   then Result:='Windows Media';
  if Ext='WMV'  then Result:='Windows Media Video';
  if Ext='3GP'  then Result:='Third Generation Platform';

  // Audio.
  if Ext='AIF'  then Result:='Apple Audio';
  if Ext='AIFC' then Result:='Apple Audio';
  if Ext='AIFF' then Result:='Apple Audio';
  if Ext='AAC'  then Result:='Advanced Audio Coding';
  if Ext='APE'  then Result:='Monkey Audio';
  if Ext='AC3'  then Result:='Dolby AC3 Sound';
  if Ext='AU'   then Result:='Sun Audio';
  if Ext='FLAC' then Reuslt:='Free Lossless Audio Codec';
  if Ext='IT'  then Result:='Impulse Tracker Module';
  if Ext='OGG'  then Result:='OGG Audio';
  if Ext='KAR'  then Result:='Karaoke (MIDI)';
  if Ext='MID'  then Result:='Musical Interface Digital Instruments';
  if Ext='MIDI' then Result:='Musical Interface Digital Instruments';
  if Ext='MKA'  then Result:='Matroska Audio';
  if Ext='MOD'  then Result:='Tracker Module';
  if Ext='MP1'  then Result:='Audio MPEG1 Layer-1';
  if Ext='MP2'  then Result:='Audio MPEG1 Layer-2';
  if Ext='MP3'  then Result:='Audio MPEG1 Layer-3';
  if Ext='MPA'  then Result:='Audio MPEG';
  if Ext='MPC'  then Result:='MusePack';
  if Ext='RA'   then Result:='RealAudio';
  if Ext='RAM'  then Result:='RealAudio';
  if Ext='RMI'  then Result:='MIDI';
  if Ext='SND'  then Result:='Sun Audio';
  if Ext='STM'  then Result:='Scream Tracker Module';
  if Ext='S3M'  then Result:='Scream Tracker 3 Module';
  if Ext='WAV'  then Result:='Windows Wave PCM Audio';
  if Ext='WMA'  then Result:='Windows Media Audio';
  if Ext='XM'  then Result:='Fast Tracker Module';
end;

function TWIntegrator.GetFileMasks;
var
  List:string;
begin
  case MediaType of
    mtPlayList:begin
      Result:='';
      List:=Core.Prefs.ReadString('WIntegrator.PlayListFiles');
      while (Length(List)>0) do
        Result:=Result+'*.'+CutExt(List)+';';
    end;
    mtVideo:begin
      Result:='';
      List:=Core.Prefs.ReadString('WIntegrator.VideoFiles');
      while (Length(List)>0) do
        Result:=Result+'*.'+CutExt(List)+';';
    end;
    mtAudio:begin
      Result:='';
      List:=Core.Prefs.ReadString('WIntegrator.AudioFiles');
      while (Length(List)>0) do
        Result:=Result+'*.'+CutExt(List)+';';
    end;
    mtMulti:begin
      Result:=GetFileMasks(mtPlayList)+
              GetFileMasks(mtVideo)+
              GetFileMasks(mtAudio);
    end;
  end;
  Result:=LowerCase(Result);
end;

function TWIntegrator.GetExtIcon;
var
  List:string;
begin
  Result:=0;

  List:=Core.Prefs.ReadString('WIntegrator.PlayListFiles');
  while (Length(List)>0) do
    if (Ext=CutExt(List)) then
      Result:=1;

  List:=Core.Prefs.ReadString('WIntegrator.VideoFiles');
  while (Length(List)>0) do
    if (Ext=CutExt(List)) then
      Result:=3;

  List:=Core.Prefs.ReadString('WIntegrator.AudioFiles');
  while (Length(List)>0) do
    if (Ext=CutExt(List)) then
      Result:=5;
end;

function TWIntegrator.IsAssociated;
var
  s:string;
  R:TRegistry;
begin
  Result:=FALSE;

  R:=TRegistry.Create;
  try
    R.RootKey:=HKEY_CLASSES_ROOT;
    R.OpenKeyReadOnly('\.'+Ext);
    s:=R.ReadString('');
    s:='\'+s+'\Shell';
    R.OpenKeyReadOnly(s);
    s:=s+'\'+R.ReadString('')+'\Command';
    R.OpenKeyReadOnly(s);
    Result:=(R.ReadString('')='"'+Application.ExeName+'" "%L"');
  except
  end;
  R.Free;
end;

function TWIntegrator.IsDVDAutoRun;
var
  s:string;
  R:TRegistry;
begin
  Result:=FALSE;

  R:=TRegistry.Create;
  try
    R.RootKey:=HKEY_CLASSES_ROOT;
    s:='\DVD\Shell';
    R.OpenKeyReadOnly(s);
    s:=s+'\'+R.ReadString('')+'\Command';
    R.OpenKeyReadOnly(s);
    Result:=(R.ReadString('')='"'+Application.ExeName+'" "%1"');
  except
  end;
  R.Free;
end;

procedure TWIntegrator.RefreshIcons;
begin
  if NeedRefresh then
    SHChangeNotify(SHCNE_ASSOCCHANGED,SHCNF_IDLIST,NIL,NIL);
  NeedRefresh:=FALSE;
end;

procedure TWIntegrator.SetDefaultExts;
begin
  Core.Prefs.WriteString('WIntegrator.PlayListFiles',
    'ASX,IFO,LAP,LST,M3U,PLS');
  Core.Prefs.WriteString('WIntegrator.VideoFiles',
    'ASF,AVI,DAT,DIVX,OGM,M1V,M2V,MKV,MOV,MP4,MPE,MPEG,MPG,MPV,FLV,QT,RM,RV,RMVB,VOB,WM,WMV,3GP');
  Core.Prefs.WriteString('WIntegrator.AudioFiles',
    'AIF,AIFC,AIFF,AAC,APE,AC3,AU,FLAC,IT,OGG,KAR,MID,MIDI,MKA,MOD,MP1,MP2,MP3,MPA,MPC,RA,RAM,RMI,SND,STM,S3M,WAV,WMA,XM');
end;

procedure TWIntegrator.SetDVDAutoRun;
var
  R:TRegistry;
begin
  if (Flag=IsDVDAutoRun) then Exit;

  R:=TRegistry.Create;
  R.RootKey:=HKEY_CLASSES_ROOT;

  R.OpenKey('\DVD',TRUE);
  if Flag then
    begin
    R.WriteString('','Digital Video Disc');
    R.OpenKey('\DVD\DefaultIcon',TRUE);
    R.WriteString('LA.Backup',R.ReadString(''));
    R.WriteString('',Application.ExeName+',3');

    R.OpenKey('\DVD\Shell',TRUE);
    R.WriteString('LA.Backup',R.ReadString(''));
    R.WriteString('','LPlay');

    R.OpenKey('\DVD\Shell\LPlay',TRUE);
    R.WriteString('','Play in &Light Alloy');
    R.OpenKey('\DVD\Shell\LPlay\Command',TRUE);
    R.WriteString('','"'+Application.ExeName+'" "%1"');
    end
  else
    begin
    R.OpenKey('\DVD\Shell',TRUE);
    R.WriteString('',R.ReadString('LA.Backup'));
    R.OpenKey('\DVD\DefaultIcon',TRUE);
    R.WriteString('',R.ReadString('LA.Backup'));
    end;
  R.Free;
end;

end.
