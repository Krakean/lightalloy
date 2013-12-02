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
unit AudioPropsModel;

interface

uses
  SysUtils, NiceModels, Models, DShowHlp, DirectShow9;

type
  TDecoderCommand = class(TCommandModel)
  private
    FNo:LongInt;
  public
    constructor Create(No:LongInt);
    procedure OnDecoder;
  end;

  TAudioChannel = packed record
    Enabled:TSInt32Model;
    Volume,Balance:TSInt32Model;
    Decoder:TDecoderCommand;
  end;

  TAltAudioChannel = packed record
    Selected:Boolean;
    Enabled:Boolean;
    Volume,Balance: LongInt;
  end;

  TAudioPropsModel = class(TObject)
  private
    Chans:array of TAudioChannel;
    procedure CreateModels;
    procedure DestroyModels;
  public
    AudioStreamsCount: Integer;

    AlternativeEngine: Boolean;
    AltChans:array [1..5] of TAltAudioChannel;

    constructor Create(DSH:TDirectShowHelper);
    destructor Destroy; override;

    function GetStream:Cardinal;
    procedure SetStream(Index:Cardinal);

    procedure UpdateVolume;
    procedure SwitchStream;

    procedure OnDecoder(Index: LongInt);
  end;

implementation

uses
  LACore, MainUnit;

{ TAudioPropsModel }

constructor TAudioPropsModel.Create;
begin
  inherited Create;
  AudioStreamsCount := -1;
  CreateModels;
  UpdateVolume;
end;

procedure TAudioPropsModel.CreateModels;
var
  i,j:Cardinal;
  l:LongInt;
  incChan: ShortInt;
begin
  AlternativeEngine:=DSH.AStreamSelectAvaible;

  if not AlternativeEngine then begin
    SetLength(Chans,DSH.GetAudioRendererCount);
    with Core.MdlMgr do begin
      for l:=0 to Length(Chans)-1 do
      begin
        Chans[l].Enabled:=TSInt32Model.Create(Ord(l=0),UpdateVolume);
        SetModel('App.AudioProps.Enabled'+IntToStr(l),Chans[l].Enabled);
        Chans[l].Volume:=TSInt32Model.Create(100,UpdateVolume);
        SetModel('App.AudioProps.Volume'+IntToStr(l),Chans[l].Volume);
        Chans[l].Balance:=TSInt32Model.Create(50,UpdateVolume);
        SetModel('App.AudioProps.Balance'+IntToStr(l),Chans[l].Balance);
        Chans[l].Decoder:=TDecoderCommand.Create(l);
        SetModel('App.AudioProps.Decoder'+IntToStr(l),Chans[l].Decoder);
      end;
      AudioStreamsCount:=Length(Chans)-1;
    end;
  end
  else begin
    j:=DSH.GetAudioStream;
    AudioStreamsCount:=DSH.AStreamCount;
    for i:=1 to 5 do begin
      AltChans[i].Selected:=(i=j);
      AltChans[i].Enabled:=(i<=DSH.AStreamCount);
      if AltChans[i].Enabled then
        AltChans[i].Volume:=100;
      AltChans[i].Balance:=50;
    end;
  end;

  if not Core.DSH.IsDVD then begin
    if not AlternativeEngine then begin
      if Length(Chans)-1 > 0 then begin
        incChan := Core.Prefs.ReadInteger('Sound.DefaultStream');
        if incChan >= 0 then
          if Length(Chans)-1 >= incChan then begin
            Chans[0].Enabled.set_SInt32(0);
            Chans[incChan].Enabled.set_SInt32(1);
          end;
      end
    end
    else begin
      if AudioStreamsCount > 1 then begin
        incChan := Core.Prefs.ReadInteger('Sound.DefaultStream')+1;
        if incChan > 1 then
          if AudioStreamsCount >= incChan then begin
            AltChans[1].Selected:=False;
            AltChans[incChan].Selected:=True;
            SetStream(incChan);
          end;
      end;
    end;
  end;
end;

destructor TAudioPropsModel.Destroy;
begin
  DestroyModels;
  inherited Destroy;
end;

procedure TAudioPropsModel.DestroyModels;
var
  l:LongInt;
begin
  with Core.MdlMgr do begin
    for l:=0 to Length(Chans)-1 do begin
      SetModel('App.AudioProps.Decoder'+IntToStr(l),NIL);
      Chans[l].Decoder.Free;
      SetModel('App.AudioProps.Balance'+IntToStr(l),NIL);
      Chans[l].Balance.Free;
      SetModel('App.AudioProps.Volume'+IntToStr(l),NIL);
      Chans[l].Volume.Free;
      SetModel('App.AudioProps.Enabled'+IntToStr(l),NIL);
      Chans[l].Enabled.Free;
    end;
  end;
  Chans:=NIL;
end;

procedure TAudioPropsModel.SwitchStream;
var
  Cur,Cnt,l:LongInt;
begin
  if not AlternativeEngine then begin
    Cnt:=Length(Chans);
    if (Cnt=0) then begin
      Core.Info(MS('OSD.NoAudioStream'));
      Exit;
    end;
    Cur:=Cnt-1;
    for l:=0 to Cnt-1 do
      if (Chans[l].Enabled.get_SInt32>0) then Cur:=l;
    Inc(Cur); if (Cur=Cnt) then Cur:=0;
    for l:=0 to Cnt-1 do
      Chans[l].Enabled.set_SInt32(Ord(l=Cur));
    Core.Info(MS('OSD.AudioStream')+ ' ' +IntToStr(Cur+1)+ ' '+ MS('OSD.AudioStream.Of') + ' ' +IntToStr(Cnt));
  end
  else begin
    Cnt:=AudioStreamsCount;
    if (Cnt=0) then begin
      Core.Info(MS('OSD.NoAudioStream'));
      Exit;
    end;
    Cur:=1;
    for l:=1 to Cnt+1 do
      if AltChans[l].Selected then Cur:=l;
    inc(Cur); if (Cur>=Cnt+1) then Cur:=1;
    SetStream(Cur);
    Core.Info(MS('OSD.AudioStream')+ ' ' +IntToStr(Cur)+ ' '+ MS('OSD.AudioStream.Of') + ' ' +IntToStr(Cnt));
  end;
end;

procedure TAudioPropsModel.SetStream;
var
  i:Cardinal;
begin
  if not AlternativeEngine then Exit;
  for i:=1 to AudioStreamsCount+1 do begin
    if i = Index then begin
      AltChans[i].Selected:=True;
      DSH.SetAudioStream(Index);
    end
    else
      AltChans[i].Selected:=False;
  end;
  UpdateVolume;
end;

procedure TAudioPropsModel.UpdateVolume;
var
  l:LongInt;
  Volume,Balance:LongInt;
begin
  if AlternativeEngine then begin
    Volume:=0;
    for l:=1 to AudioStreamsCount do begin
      if AltChans[l].Selected then
        Volume:=AltChans[l].Volume;

      Volume:=(Volume*frMain.tbVolume.Position) div 100;
      if Core.Prefs.ReadBool('FrontEnd.Mute') then Volume:=0;
      Volume:=(Volume-100)*40;
      if (Volume=-4000) then Volume:=-10000;
      if AltChans[l].Selected then
        DSH.SetVolume(0,Volume);

      Balance:=AltChans[l].Balance;
      Balance:=Balance*2-100;
      Balance:=Balance*20;
      if (Balance=2000) then Balance:=10000;
      if (Balance=-2000) then Balance:=-10000;
      if AltChans[l].Selected then
        DSH.SetBalance(0,Balance);
    end;
    Exit;
  end;

  for l:=0 to Length(Chans)-1 do begin
    Volume:=Chans[l].Volume.get_SInt32;
    if (Chans[l].Enabled.get_SInt32=0) then Volume:=0;

    Volume:=(Volume*frMain.tbVolume.Position) div 100;
    if Core.Prefs.ReadBool('FrontEnd.Mute') then Volume:=0;
    Volume:=(Volume-100)*40;
    if (Volume=-4000) then Volume:=-10000;
    DSH.SetVolume(l,Volume);

    Balance:=Chans[l].Balance.get_SInt32;
    Balance:=Balance*2-100;
    Balance:=Balance*20;
    if (Balance=2000) then Balance:=10000;
    if (Balance=-2000) then Balance:=-10000;
    DSH.SetBalance(l,Balance);
  end;
end;

function TAudioPropsModel.GetStream: Cardinal;
begin
  Result:=0;
  if not AlternativeEngine then Exit;
  Result:=DSH.GetAudioStream;
end;

procedure TAudioPropsModel.OnDecoder(Index: Integer);
var
  Filter:IBaseFilter;
begin
  Filter:=DSH.GetAudioDecoder(Index-1);
  if not(Assigned(Filter)) then Exit;

  DSH.Stop;
  DSH.FilterProperties(frMain.Handle,Filter);
  frMain.RestoreState;
  Filter:=NIL;
end;

{ TDecoderCommand }

constructor TDecoderCommand.Create;
begin
  inherited Create(OnDecoder);
  FNo:=No;
end;

procedure TDecoderCommand.OnDecoder;
var
  Filter:IBaseFilter;
begin
  Filter:=DSH.GetAudioDecoder(FNo);
  if not(Assigned(Filter)) then Exit;

  DSH.Stop;
  DSH.FilterProperties(frMain.Handle,Filter);
  frMain.RestoreState;
  Filter:=NIL;
end;

end.