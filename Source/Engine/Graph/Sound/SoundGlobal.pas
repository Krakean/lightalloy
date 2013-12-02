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

unit SoundGlobal;

interface

uses
  Windows, Classes, SysUtils, MMSystem,

  DirectSound8,

  AMixer, AMixerFull;

type
  TSoundGlobal = class(TObject)
  private
    AMixerFull: TAMixerFull;
    Click:String;
    DSound:IDirectSound;

    procedure CreateDSound;
    procedure LoadClick;
  public
    HasSoundCard:Boolean;
    Muted:Boolean;

    constructor Create;
    destructor Destroy; override;

    procedure SetVolume(Value:LongInt);

    procedure Ding;
  end;

implementation

uses
  LACore;

constructor TSoundGlobal.Create;
begin
  inherited Create;
  if (Core.Prefs.ReadBool('Sound.Force44')) then
    CreateDSound;
  AMixerFull:=TAMixerFull.Create;
end;

procedure TSoundGlobal.CreateDSound;
var
  DSBD:TDSBufferDesc;
  WFX:TWaveFormatEx;
  DSBPri:IDirectSoundBuffer;
begin
  HasSoundCard:=SUCCEEDED(DirectSoundCreate(NIL,DSound,NIL)); // if SoundCard exists
  if not(HasSoundCard) then begin
    DSound:=NIL;
    Exit;
  end;

  if (Core.Prefs.ReadBool('Sound.Force44')) then begin
    E(DSound.SetCooperativeLevel(Core.AppHandle,DSSCL_PRIORITY),'DSound.SetCooperativeLevel(DSSCL_PRIORITY)');
    ZeroMemory(@DSBD,SizeOf(DSBD));
    DSBD.dwSize:=SizeOf(DSBD);
    DSBD.dwFlags:=DSBCAPS_PRIMARYBUFFER;
    E(DSound.CreateSoundBuffer(DSBD,DSBPri,NIL),'DSound.CreateSoundBuffer');

    ZeroMemory(@WFX,SizeOf(WFX));
    with WFX do begin
      cbSize:=SizeOf(WFX);
      wFormatTag:=WAVE_FORMAT_PCM;
      nSamplesPerSec:=44100;
      nChannels:=2;
      wBitsPerSample:=16;
      nBlockAlign:=(wBitsPerSample shr 3)*nChannels;
      nAvgBytesPerSec:=nSamplesPerSec*nBlockAlign;
    end;

    E(DSBPri.SetFormat(@WFX),'DSBPri.SetFormat');
    E(DSBPri.Play(0,0,DSBPLAY_LOOPING),'DSBPri.Play');
  end else begin
    E(DSound.SetCooperativeLevel(Core.AppHandle,DSSCL_NORMAL),'DSound.SetCooperativeLevel');
  end;
end;

destructor TSoundGlobal.Destroy;
begin
  DSound:=NIL;
  MixerRestoreState;

  AMixerFull.Destroy;
  inherited Destroy;
end;

procedure TSoundGlobal.Ding;
var
  DSBD:TDSBufferDesc;
  WFX:TWaveFormatEx;
  DSB:IDirectSoundBuffer;
  Data1,Data2:Pointer;
  Len1,Len2:DWORD;
  l,V,Vol,Cnt:LongInt;
  PWA:PWordArray;
  PW:PWord;
begin
  if not(Assigned(DSound)) then
    CreateDSound;

  if not(Assigned(DSound)) then Exit;
  if (Length(Click)=0) then LoadClick;

  ZeroMemory(@WFX,SizeOf(WFX));
  with WFX do begin
    cbSize:=SizeOf(WFX);
    wFormatTag:=WAVE_FORMAT_PCM;
    nSamplesPerSec:=44100;
    nChannels:=1;
    wBitsPerSample:=16;
    nBlockAlign:=(wBitsPerSample shr 3)*nChannels;
    nAvgBytesPerSec:=nSamplesPerSec*nBlockAlign;
  end;

//  Dur:=10+(Length(Click) div 44100);

  ZeroMemory(@DSBD,SizeOf(DSBD));
  DSBD.dwSize:=SizeOf(DSBD);
  DSBD.dwFlags:=DSBCAPS_GLOBALFOCUS;
  DSBD.dwBufferBytes:=Length(Click);
  DSBD.lpwfxFormat:=@WFX;

  Vol:=INI.Int['Modules.WinLIRC.Sound.Volume'];
  if SUCCEEDED(DSound.CreateSoundBuffer(DSBD,DSB,NIL)) then begin
    if SUCCEEDED(DSB.Lock(0,0,Data1,Len1,Data2,Len2,DSBLOCK_ENTIREBUFFER)) then begin
      PW:=Data1;
      Cnt:=Length(Click) div 2;
      PWA:=@Click[1];
      for l:=0 to Cnt-1 do begin
        V:=PWA^[l];
        if ((V and $8000)>0) then V:=LongInt(DWORD(V) or $FFFF0000);
        V:=(V*Vol) div 100;
        PW^:=V and $FFFF;
        Inc(PW);
      end;

//      Move(Click[1],Data1^,Len1);
      DSB.UnLock(Data1,Len1,Data2,Len2);

      DSB.Play(0,0,0);
      Sleep(50);
      DSB.Stop;
    end;
    DSB:=NIL;
  end;
end;

procedure TSoundGlobal.LoadClick;
var
  RS:TResourceStream;
begin
  RS:=TResourceStream.Create(0,'Click',RT_RCDATA);
  RS.Position:=$30;
  SetLength(Click,RS.Size-$30);
  RS.Read(Click[1],RS.Size-$30);
  RS.Free;
end;

procedure TSoundGlobal.SetVolume;
var
  InfoStr:String;
  Volume:LongInt;
begin
  Volume:=Value;
  if (Volume<0) then Volume:=0;
  if (Volume>100) then Volume:=100;

  Core.Prefs.WriteInteger('Sound.Volume',Volume);

  InfoStr:=Format(MS('OSD.Volume')+': %d%%',[Volume]);
  if Muted then InfoStr:=InfoStr+' (X)';
  Core.Info(InfoStr);

  if Core.SysHlp.IsExpirienceFamily then begin
    if Core.Prefs.ReadBool('Sound.VolumeMaster') then
      MixerMasterVolume(Volume);
    if Core.Prefs.ReadBool('Sound.VolumeWave') then
      MixerWaveVolume(Volume);
  end else
  if Core.SysHlp.IsVistaFamily then begin
    if Core.Prefs.ReadBool('Sound.VolumeMaster') then
      AMixerFull.FullMixerMasterVolume(Volume);
  end;
end;

end.
