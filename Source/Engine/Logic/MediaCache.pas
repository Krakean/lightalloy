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
unit MediaCache;

interface

uses
  Windows, Classes, CachedStream, MD5, XML, SysUtils, MultiLog, OtherGlobalVars;

type
  TMediaCache= class(TObject)
  private
    XT:TXMLTree;

    function GetCacheFileName:String;
    procedure SetUsed(X:TXMLNode);
    procedure CropOldest(Count:LongInt);
  public
    constructor Create;
    destructor Destroy; override;

    procedure Load;
    procedure Save;

    function GetFile64KHash(FN:String):String;

    function GetOrCreateInfo(FN:String):TXMLNode;
    function GetInfo(FN:String):TXMLNode;

    procedure UpdateMediaCache(Dur: Int64; FileName: String);
  end;

implementation

uses
  LACore, SysHlp;

constructor TMediaCache.Create;
begin
  inherited Create;
  XT:=TXMLTree.Create;
end;

procedure TMediaCache.CropOldest;
begin
  while (Length(XT.Root.Nodes)>Count) do begin
    XT.Root.DestroyNode(XT.Root.Nodes[0]);
  end;
end;

destructor TMediaCache.Destroy;
begin
  XT.Free;
  inherited Destroy;
end;

function TMediaCache.GetCacheFileName: String;
begin
  Result:=Core.ExePath+'mc.xml';
  if not(Core.SysHlp.IsNT) then Exit;
  if not(INI.Bool['App.IsMultiUser']) then Exit;

  Result:=Core.SysHlp.GetCommonAppDataFolder+'LightAlloy\mc.xml';
  if (INI.Int['App.UserPrefs']=0) then Exit;
  Result:=Core.SysHlp.GetPersonalAppDataFolder+'LightAlloy\mc.xml';
end;

function TMediaCache.GetFile64KHash;
const
  MinSz = 32767;
var
  S: array[0..MinSz] of char;
  FastIndex: Boolean;
  FS:TFileStream;
  MD5:TMD5;
  Sz:Int64;
begin
  Log('+TMediaCache.GetFileHash');
  Result:='';
  FastIndex:=Core.Prefs.ReadBool('Playlist.FastIndex');
  if not FileExists(FN) then begin
    Log('-TMediaCache.GetFileHash: File not found!');
    Exit;
  end;
  try
    FS:=TFileStream.Create(FN,fmOpenRead or fmShareDenyNone);
    Sz:=FS.Size;

    MD5:=TMD5.Create;
    if FastIndex or (Sz<MinSz) then begin
      MD5.UpdateWithString(FN+IntToStr(Sz));
      Result:=MD5.DigestToString(MD5.Final);
    end
    else begin
      FS.Seek(0,soFromBeginning);
      FS.Read(S,MinSz);
      Result:=MD5.DigestToString(MD5.MemoryDigest(@S,MinSz));
    end;
    MD5.Free;
    FS.Free;
  except
  end;
  Log('-TMediaCache.GetFileHash('+Result+')');
end;

function TMediaCache.GetInfo(FN: String): TXMLNode;
begin
  Result:=XT.Root.NodeById('FILE',FN);
  if Assigned(Result) then SetUsed(Result);
end;

function TMediaCache.GetOrCreateInfo(FN: String): TXMLNode;
begin
  Result:=XT.Root.NodeById('FILE',FN);
  if Assigned(Result) then begin
    SetUsed(Result);
    Exit;
  end;

  Result:=TXMLNode.Create;
  Result.Tag:='FILE';
  Result.SetAttr('id',FN);
  XT.Root.AddNode(Result);
  SetUsed(Result);
end;

procedure TMediaCache.Load;
var
  FS:TFileStream;
  CS:TCachedStream;
begin
  Log('+TMediaCache.Load');
  try
    FS:=TFileStream.Create(GetCacheFileName,fmOpenRead or fmShareDenyWrite);
    CS:=TCachedStream.Create(FS,2,4096);
    XT.LoadFromStream(CS);
    CS.Free;
    FS.Free;
  except
    XT.Root:=TXMLNode.Create;
    XT.Root.Tag:='MEDIACACHE';
    XT.Root.SetAttr('app','LightAlloy');
  end;
  Log('-TMediaCache.Load');
end;

procedure TMediaCache.Save;
begin
  Log('+TMediaCache.Save');
  try
    CropOldest(Core.Prefs.ReadInteger('Media.Cache'));
    XT.SaveToFile(GetCacheFileName);
  except
  end;
  Log('-TMediaCache.Save');
end;

procedure TMediaCache.SetUsed;
var
  Stamp:Int64;
begin
  Stamp:=Round((Now-EncodeDate(2000,1,1))*24*60*60);
  X.SetAttr('used',IntToStr(Stamp));

  XT.Root.RemoveNode(X);
  XT.Root.AddNode(X);
end;

procedure TMediaCache.UpdateMediaCache(Dur: Int64; FileName: String);
var
  IsUrl: boolean;
  X:TXMLNode;
begin
  IsUrl:=(System.Pos(':/',FileName) <> 0);
  if not IsURL then
   begin
     X:= Core.MediaCache.GetOrCreateInfo(FileName);
     X.SetAttr('dur',IntToStr(Dur));
     X.SetAttr('hash64k',File2Hash64K);
   end;
end;

end.
