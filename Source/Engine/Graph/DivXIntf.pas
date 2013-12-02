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
unit DivXIntf;

  { Interfaces to control the Divx Decoder filter.}

interface

const
  IID_IDivxFilterInterface  :TGUID = '{D132EE97-3E38-4030-8B17-59163B30A1F5}';

type
  IDivx4FilterInterface = interface(IUnknown)
  ['{D132EE97-3E38-4030-8B17-59163B30A1F5}']
    function get_PPLevel(out PPLevel: integer): HRESULT; stdcall;
    function put_PPLevel(PPLevel: integer): HRESULT; stdcall;
    function put_DefaultPPLevel: HRESULT; stdcall;
    function put_MaxDelayAllowed(maxdelayallowed: integer): HRESULT; stdcall;
    function put_Brightness(brightness: integer): HRESULT; stdcall;
    function put_Contrast(contrast: integer): HRESULT; stdcall;
    function put_Saturation(saturation: integer): HRESULT; stdcall;
    function get_MaxDelayAllowed(out maxdelayallowed: integer): HRESULT; stdcall;
    function get_Brightness(out brightness: integer): HRESULT; stdcall;
    function get_Contrast(out contrast: integer): HRESULT; stdcall;
    function get_Saturation(out saturation: integer): HRESULT; stdcall;
    function put_AspectRatio(x, y: integer): HRESULT; stdcall;
    function get_AspectRatio(out x, y: integer): HRESULT; stdcall;
  end;

  IDivx5FilterInterface = interface(IUnknown)
  ['{D132EE97-3E38-4030-8B17-59163B30A1F5}']
    function GetQualityLevel(out Level:Longint):HResult; stdcall;
    function PutQualityLevel(Level:Longint):HResult; stdcall;
    function SetDefaultQualityLevel:HResult; stdcall;

    function PutBrightness(Value:Longint):HResult; stdcall;
    function PutContrast(Value:Longint):HResult; stdcall;
    function PutSaturation(Value:Longint):HResult; stdcall;

    function Unk1:HResult; stdcall;
    function Unk2:HResult; stdcall;
    function Unk3:HResult; stdcall;

    function GetBrightness(out Value:Longint):HResult; stdcall;
    function GetContrast(out Value:Longint):HResult; stdcall;
    function GetSaturation(out Value:Longint):HResult; stdcall;
  end;

implementation

end.
