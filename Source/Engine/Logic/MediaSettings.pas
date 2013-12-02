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
unit MediaSettings;

interface

uses
  Windows, Classes, CachedStream, XML, SysUtils, MultiLog, OtherGlobalVars;

type
  TMediaSettings = class(TObject)
  private
    XT:TXMLTree;

    function GetStoreFileName:String;
    procedure SetUsed(X:TXMLNode);
    procedure CropOldest(Count:LongInt);
  public
    constructor Create;
    destructor Destroy; override;

    procedure Load;
    procedure Save;

    function GetOrCreateInfo(Hash64K:String):TXMLNode;
    function GetInfo(Hash64K:String):TXMLNode;

    procedure SaveTags(Artist: String; Title: String);
  end;

implementation

uses
  LACore;

constructor TMediaSettings.Create;
begin
  inherited Create;
  XT:=TXMLTree.Create;
end;

destructor TMediaSettings.Destroy;
begin
  XT.Free;
  inherited Destroy;
end;

function TMediaSettings.GetStoreFileName;
begin
  Result:=Core.ExePath+'ms.xml';
  if not(Core.SysHlp.IsNT) then Exit;
  if not(INI.Bool['App.IsMultiUser']) then Exit;

  Result:=Core.SysHlp.GetCommonAppDataFolder+'LightAlloy\ms.xml';
  if (INI.Int['App.UserPrefs']=0) then Exit;
  Result:=Core.SysHlp.GetPersonalAppDataFolder+'LightAlloy\ms.xml';
end;

function TMediaSettings.GetInfo;
begin
  Result:=XT.Root.NodeById('MEDIA',Hash64K);
  if Assigned(Result) then SetUsed(Result);
end;

function TMediaSettings.GetOrCreateInfo(Hash64K: String): TXMLNode;
begin
  Result:=XT.Root.NodeById('MEDIA',Hash64K);
  if Assigned(Result) then begin
    SetUsed(Result);
    Exit;
  end;

  Result:=TXMLNode.Create;
  Result.Tag:='MEDIA';
  Result.SetAttr('id',Hash64K);
  XT.Root.AddNode(Result);
  SetUsed(Result);
end;

procedure TMediaSettings.Load;
var
  FS:TFileStream;
  CS:TCachedStream;
begin
  Log('+TMediaSettings.Load');
  try
    FS:=TFileStream.Create(GetStoreFileName,fmOpenRead or fmShareDenyWrite);
    CS:=TCachedStream.Create(FS,2,4096);
    XT.LoadFromStream(CS);
    CS.Free;
    FS.Free;
  except
    XT.Root:=TXMLNode.Create;
    XT.Root.Tag:='MEDIASETTINGS';
    XT.Root.SetAttr('app','LightAlloy');
  end;
  Log('-TMediaSettings.Load');
end;

procedure TMediaSettings.Save;
begin
  Log('+TMediaSettings.Save');
  try
    CropOldest(Core.Prefs.ReadInteger('Media.Settings'));
    XT.SaveToFile(GetStoreFileName);
  except
  end;
  Log('-TMediaSettings.Save');
end;

procedure TMediaSettings.SetUsed;
var
  Stamp:Int64;
begin
  Stamp:=Round((Now-EncodeDate(2000,1,1))*24*60*60);
  X.SetAttr('used',IntToStr(Stamp));

  XT.Root.RemoveNode(X);
  XT.Root.AddNode(X);
end;

procedure TMediaSettings.CropOldest;
begin
  while (Length(XT.Root.Nodes)>Count) do begin
    XT.Root.DestroyNode(XT.Root.Nodes[0]);
  end;
end;

procedure TMediaSettings.SaveTags(Artist: string; Title: string);
begin
  X2.SetAttr('Artist', Artist);
  X2.SetAttr('Title', Title);
end;

end.
