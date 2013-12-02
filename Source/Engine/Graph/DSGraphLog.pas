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
unit DSGraphLog;

interface

uses
  Windows, Classes, Registry, SysUtils, DirectShow9;

type
  TDSGraphLogger = class(TObject)
  private
    function PinAsText(Pin: IPin): String;
  public
    function GraphAsText(Graph: IGraphBuilder): String;
  end;

implementation

uses
  DShowHlp, FilterCommander;

{ TDSGraphLogger }

function TDSGraphLogger.GraphAsText(Graph: IGraphBuilder): String;
var
  FEnum:IEnumFilters;
  Filter:IBaseFilter;
  Fetched:longint;
  FltCmd:TFilterCommander;
  Pins:IEnumPins;
  Pin:IPin;
begin
  Result:=#13#10;
  FltCmd:=TFilterCommander.Create;

  Graph.EnumFilters(FEnum);
  while (FEnum.Next(1,Filter,@Fetched)=S_OK) do begin
    Result:=Result+'[FLT:] '+DSH.GetFilterName(Filter) +#13#10;
    Result:=Result+'CLSID:'+GUIDToString(DSH.GetCLSID(Filter)) +#13#10;
    FltCmd.ExamineFilter(DSH.GetCLSID(Filter));
    if FltCmd.ModuleName <> '' then
      Result:=Result+ 'FN:' + FltCmd.ModuleName +#13#10
    else
      Result:=Result+ 'FN:' + '?' +#13#10;

    Filter.EnumPins(Pins);
    Pins.Reset;
    while Pins.Next(1,Pin,@Fetched)=S_OK do
      Result:=Result+PinAsText(Pin);
    Pins:=NIL;

    Filter:=NIL;
    Result:=Result+#13#10;
  end;

end;

function TDSGraphLogger.PinAsText(Pin: IPin): String;
var
  PDir:TPINDIRECTION;
  PinInfo:TPinInfo;
  DPinInfo:TPinInfo;
  DPin:IPin;
  TMT: TAMMEDIATYPE;
  PMT: PAMMediaType;
  MediaTypes:IEnumMediaTypes;
  Fetched:Cardinal;
begin
  Result:='';
  Pin.QueryDirection(PDir);
  Pin.QueryPinInfo(PinInfo);

  if  DSH.IsPinConnected(Pin) then begin
    Pin.ConnectedTo(DPin);
    DPin.QueryPinInfo(DPinInfo);
    if PDir = PINDIR_INPUT then
      Result:=Result+'[in]'+PinInfo.achName+' <-c-> '+DPinInfo.achName +#13#10
    else
      Result:=Result+'[out]'+PinInfo.achName+' <-c-> '+DPinInfo.achName +#13#10;
    Pin.ConnectionMediaType(TMT);
    Result:=Result+GUIDToString(TMT.majortype)+':'+GUIDToString(TMT.subtype)
      +#13#10 +#13#10;
  end
  else begin
    if PDir = PINDIR_INPUT then
      Result:=Result+'[in]'+PinInfo.achName +#13#10
    else
      Result:=Result+'[out]'+PinInfo.achName +#13#10;
    Pin.EnumMediaTypes(MediaTypes);
    MediaTypes.Reset;
    while (MediaTypes.Next(1,PMT,@Fetched)=S_OK) do begin
      Result:=Result+GUIDToString(PMT.majortype)+':'+GUIDToString(PMT.subtype)
        +#13#10;
      DSH.DeleteMediaType(PMT);
    end;
    Result:=Result +#13#10;
  end;
end;

initialization

finalization

end.
