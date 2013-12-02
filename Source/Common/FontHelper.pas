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

unit FontHelper;

interface

uses
  Windows, Classes, Controls, Graphics;

type
  TFontHelper = class(TObject)
  public
    procedure CopyFont(Src,Dest:TFont);

    procedure ReadFromINI(F:TFont;Key:String);
    procedure WriteToINI(F:TFont;Key:String);
  end;

implementation

{ TFontHelper }

uses
  LACore;

procedure TFontHelper.CopyFont(Src, Dest: TFont);
begin
  Dest.Name:=Src.Name;
  Dest.Size:=Src.Size;
  Dest.Color:=Src.Color;
  Dest.Charset:=Src.Charset;
  Dest.Style:=[];
  if (fsBold in Src.Style) then
    Dest.Style:=[fsBold];
end;

procedure TFontHelper.ReadFromINI;
begin
  F.Name:=INI.Str[Key+'.Name'];
  F.Size:=INI.Int[Key+'.Size'];
  F.Charset:=INI.Int[Key+'.Charset'];
  F.Color:=INI.Int[Key+'.Color'];
  F.Style:=[];
  if INI.Bool[Key+'.Bold'] then
    F.Style:=[fsBold];
end;

procedure TFontHelper.WriteToINI(F: TFont; Key: String);
begin
  INI.Str[Key+'.Name']:=F.Name;
  INI.Int[Key+'.Size']:=F.Size;
  INI.Int[Key+'.Charset']:=F.Charset;
  INI.Int[Key+'.Color']:=F.Color;
  INI.Bool[Key+'.Bold']:=(fsBold in F.Style);
end;

end.
 