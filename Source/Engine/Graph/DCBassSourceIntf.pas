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
// xx.xx.12  1.0   VtX  Created                                              //
///////////////////////////////////////////////////////////////////////////////
unit DCBassSourceIntf;

interface

const
  CLSID_DCBassSource: TGuid = '{ABE7B1D9-4B3E-4ACD-A0D1-92611D3A4492}';
  IID_IDCBassSource:  TGuid = '{050F0E7F-E129-4851-91CC-30093675099A}';

type
  IDCBassSource = interface(IUnknown)
  ['{050F0E7F-E129-4851-91CC-30093675099A}']
    // Returns the current Tag. User must Free the string using CoTaskMemFree
    function GetCurrentTag(out ATag: PWideChar): HRESULT; stdcall;
    function GetIsShoutcast(out AShoutcast: LongBool): HRESULT; stdcall;

    function GetIsWriting(out AWriting: LongBool): HRESULT; stdcall;
    // Returns the current Filename for writing. User must Free the string using CoTaskMemFree
    function GetWritingFileName(out AFileName: PWideChar): HRESULT; stdcall;
    function StartWriting(APath: PWideChar): HRESULT; stdcall;
    function StopWriting: HRESULT; stdcall;
    function GetSplitStreamOnNewTag(out ASplit: LongBool): HRESULT; stdcall;
    function SetSplitStreamOnNewTag(ASplit: LongBool): HRESULT; stdcall;
    // Setup Prebuffering for Shoutcast
    function GetBuffersizeMs(out ABufferMs: Integer): HRESULT; stdcall;
    function SetBuffersizeMs(ABufferMs: Integer): HRESULT; stdcall;
    function GetPrebufferMs(out ABufferMs: Integer): HRESULT; stdcall;
    function SetPrebufferMs(ABufferMs: Integer): HRESULT; stdcall;
  end;

var
  DCBassSourceControl:IDCBassSource;

implementation

end.