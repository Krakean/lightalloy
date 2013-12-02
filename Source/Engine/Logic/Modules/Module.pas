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
unit Module;

interface

uses
  Windows, Classes, SysUtils, Forms, XMLPrefs;

type
  TModule = class(TObject)
  protected
    Prefs:TXMLPrefs;
    Id:String;
  public
    constructor Create(AId:String;APrefs:TXMLPrefs); virtual;
    destructor Destroy; override;
  end;

  TModuleClass = class of TModule;

implementation

constructor TModule.Create;
begin
  inherited Create;
  Id:=AId;
  Prefs:=APrefs;
end;

destructor TModule.Destroy;
begin
  Prefs.Free;
  inherited Destroy;
end;

end.
