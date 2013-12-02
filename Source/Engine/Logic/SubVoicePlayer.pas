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
unit SubVoicePlayer;

interface

uses
  Windows, Classes, SysUtils, ActiveX, DirectShow9;

type
  TSubVoicePlayer = class(TObject)
  private
    LastPlayed:LongInt;
    Graph:IGraphBuilder;
    MC:IMediaControl;

    procedure DoPlay(Index:LongInt);
    procedure Render(FN:String);
    procedure ClearGraph;
  public
    MediaDir:String;

    constructor Create;
    destructor Destroy; override;

    procedure Play(Index:LongInt);
  end;

implementation

uses
  LACore;

procedure TSubVoicePlayer.ClearGraph;
var
  FEnum:IEnumFilters;
  Filter:IBaseFilter;
  Fetched:cardinal;
  procedure EnumPins;
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
begin
  E(Graph.EnumFilters(FEnum),'Graph.EnumFilters');
  while (FEnum.Next(1,Filter,@Fetched)=S_OK) do begin
    EnumPins;
    E(Graph.RemoveFilter(Filter),'Graph.RemoveFilter');
    Filter:=NIL;
    E(FEnum.Reset,'FEnum.Reset');
  end;
  FEnum:=NIL;
end;

constructor TSubVoicePlayer.Create;
begin
  inherited Create;

  E(CoCreateInstance(CLSID_FilterGraph,NIL,CLSCTX_INPROC,IID_IGraphBuilder,Graph),'CoCreateInstance(FilterGraph)');
  E(Graph.QueryInterface(IID_IMediaControl,MC),'Graph.QueryInterface(IMediaControl)');
end;

destructor TSubVoicePlayer.Destroy;
begin
  MC.Stop;
  MC:=NIL;
  Graph:=NIL;
  inherited Destroy;
end;

procedure TSubVoicePlayer.DoPlay(Index: Integer);
var
  FN:String;
begin
  FN:=MediaDir+Format('%.4d',[Index])+'.mp3';
  if not(FileExists(FN)) then Exit;

  MC.Stop;
  ClearGraph;
  Render(FN);
  MC.Run;
end;

procedure TSubVoicePlayer.Play(Index: Integer);
begin
  if (LastPlayed<>Index) then begin
    DoPlay(Index);
    LastPlayed:=Index;
  end;
end;

procedure TSubVoicePlayer.Render(FN: String);
var
  WStr:array [0..MAX_PATH-1] of WChar;
begin
  StringToWideChar(FN,WStr,MAX_PATH);
  Graph.RenderFile(WStr,NIL);
end;

end.
