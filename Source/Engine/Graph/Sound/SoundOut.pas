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
unit SoundOut;

interface

uses
  Windows, Classes, ActiveX, SysUtils,

  DirectShow9, DShowHlp, MultiLog;

const
  IID_IPropertyBag :TGUID = '{55272A00-42CB-11CE-8135-00AA004BB851}';
  IID_IPersist     :TGUID = '{0000010C-0000-0000-C000-000000000046}';

type
  TSoundOut = class(TObject)
  private
    SelG:TGUID;

    function GetDeviceGUID:TGUID;
    function CreateRenderer:IBaseFilter;
  public
    procedure ReplaceAudioRenderer;
    procedure EnumSoundDevices(SL:TStrings);
  end;

implementation

uses
  LACore, XMLPrefs, ComObj;

{ TSoundOut }

function TSoundOut.CreateRenderer: IBaseFilter;
var
  CDEnum:ICreateDevEnum;
  EnumMon:IEnumMoniker;
  Moniker:IMoniker;
  Fetched:LongInt;
  PropBag:IPropertyBag;
  varName:OleVariant;
  s:string;
  hR:HRESULT;
  DevName:String;
begin
  Result:=NIL;
  DevName:=Core.Prefs.ReadString('Sound.OutDevice');

  hR:=CoCreateInstance(CLSID_SystemDeviceEnum,NIL,CLSCTX_INPROC_SERVER,IID_ICreateDevEnum,CDENum);
  if FAILED(hR) then Exit;

  hR:=CDENum.CreateClassEnumerator(CLSID_AudioRendererCategory,EnumMon,0);
  if FAILED(hR) then Exit;

  if (EnumMon=NIL) then Exit;

  while (EnumMon.Next(1,Moniker,@Fetched)=S_OK) do begin
    if SUCCEEDED(Moniker.BindToStorage(NIL,NIL,IID_IPropertyBag,PropBag)) then begin
      s:='Noname';
      if SUCCEEDED(PropBag.Read('FriendlyName',varName,NIL)) then s:=varName;

      if SameText(s,DevName) then begin
        Moniker.BindToObject(NIL,NIL,IID_IBaseFilter,Result);
        Exit;
      end;

      PropBag:=NIL;
      Moniker:=NIL;
    end;
  end;
  
  EnumMon:=NIL;
  CDEnum:=NIL;
end;

procedure TSoundOut.EnumSoundDevices;
var
  CDEnum:ICreateDevEnum;
  EnumMon:IEnumMoniker;
  Moniker:IMoniker;
  Fetched:LongInt;
  PropBag:IPropertyBag;
  varName:OleVariant;
  s:string;
  hR:HRESULT;
  DevName:String;
begin
  SL.Clear;
  SelG:=GUID_NULL;
  DevName:=Core.Prefs.ReadString('Sound.OutDevice');

  hR:=CoCreateInstance(CLSID_SystemDeviceEnum,NIL,CLSCTX_INPROC_SERVER,IID_ICreateDevEnum,CDENum);
  if FAILED(hR) then Exit;

  hR:=CDENum.CreateClassEnumerator(CLSID_AudioRendererCategory,EnumMon,0);
  if FAILED(hR) then Exit;

  if Assigned(EnumMon) then begin
    while (EnumMon.Next(1,Moniker,@Fetched)=S_OK) do begin
      s:='CLSID';
      if SUCCEEDED(Moniker.BindToStorage(NIL,NIL,IID_IPropertyBag,PropBag)) then begin
        s:='Noname';
        if SUCCEEDED(PropBag.Read('FriendlyName',varName,NIL)) then s:=varName;
        SL.Add(s);

        if SameText(s,DevName) then begin
          if SUCCEEDED(PropBag.Read('CLSID',varName,NIL)) then begin
            s:=varName;
            SelG:=StringToGUID(s);
          end;
        end;

        PropBag:=NIL;
        Moniker:=NIL;
      end;
    end;
  end;
  EnumMon:=NIL;
  CDEnum:=NIL;
end;

function TSoundOut.GetDeviceGUID: TGUID;
var
  SL:TStringList;
begin
  SelG:=GUID_NULL;

  SL:=TStringList.Create;
  EnumSoundDevices(SL);
  SL.Free;

  Result:=SelG;
end;

procedure TSoundOut.ReplaceAudioRenderer;
var
  l:LongInt;
  Dec,R:IBaseFilter;
  G:TGUID;
  DevName:String;
begin
  DevName:=Core.Prefs.ReadString('Sound.OutDevice');

  G:=GetDeviceGUID;
  if IsEqualGUID(G,GUID_NULL) then Exit;

  Log('SoundOut:DestFilter='+GUIDToString(G));

  for l:=0 to DSH.GetAudioRendererCount-1 do begin
    R:=DSH.ARenderers[l];
    DSH.ARenderers[l]:=NIL;

    Dec:=DSH.PrevFilter(R);
    DSH.DisconnectFilter(R);
    DSH.Graph.RemoveFilter(R);
    R:=NIL;

    R:=CreateRenderer;
    DSH.Graph.AddFilter(R,PWideChar(WideString('Forced: ['+DevName+']')));
    if Succeeded(DSH.ConnectFilters(Dec,R)) then
      DSH.ARenderers[l]:=R;
    Dec:=NIL;
    R:=NIL;
  end;
end;

end.
