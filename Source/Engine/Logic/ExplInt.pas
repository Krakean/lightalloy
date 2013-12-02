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
unit ExplInt;

interface

uses
  Windows, Classes, Registry, FileTypeAss, SysUtils, XMLPrefs, XML;

type
  TExplorerIntegrator = class(TObject)
  private
    FTA:TFileTypeAssociator;
    DVDA:TDVDAssociator;

    function GetIsDVDAutorun:Boolean;
    procedure SetIsDVDAutorun(const Value:Boolean);
    function FullAppPath:String;
    function IsExtInList(AExt:String;AList:String):Boolean;
    function CutListValue(var List:String):String;
  public
    Prefs:TXMLPrefs;

    constructor Create;
    destructor Destroy; override;

    function GetFileMasks(MaskType:String):String;
    function GetMaskList(MaskType:String):TStringList;
    function IsReadOnly:Boolean;

    function GetDescription(Ext:string):string;
    procedure UpdateIcons;
    function GetExtType(AExt:String):String;
    function ExtIcon(AExt:String):String;

    procedure Associate(AExt:string;Link:Boolean);
    function IsAssociated(AExt:string):Boolean;

    property IsDVDAutoRun:Boolean read GetIsDVDAutorun write SetIsDVDAutorun;
  end;

implementation

uses
  LACore;

procedure TExplorerIntegrator.Associate;
var
  Menu:TFileTypeMenu;
  S:String;
begin
  FTA.Ext:=AExt;
  if Link then begin
    Menu.DefaultAction:='Open';
    SetLength(Menu.Actions,5);
    with Menu.Actions[0] do begin
      Code:='Open';
      Title:='';
      Command:=FullappPath+' "%1"';
    end;
    with Menu.Actions[1] do begin
      Code:='Play';
      Title:='';
      Command:=FullappPath+' "%1"';
    end;
    with Menu.Actions[2] do begin
      Code:='Enqueue';
      Title:='En&queue in Light Alloy';
      Command:=FullappPath+'/ADD "%1"';
    end;
    with Menu.Actions[3] do begin
      Code:='PlayNew';
      Title:='Play in &new window';
      Command:=FullappPath+'/NEW "%1"';
    end;
    with Menu.Actions[4] do begin
      Code:='Info';
      Title:='File &Information';
      Command:=FullappPath+'/INFO "%1"';
    end;
    FTA.SetMenu(Menu);
    S:=GetDescription(AExt);
    if (S<>'') then FTA.SetDescription(S);
    FTA.SetIcon(ExtIcon(AExt));
  end else begin
    FTA.Rollback;
  end;
end;

constructor TExplorerIntegrator.Create;
begin
  inherited Create;
  FTA:=TFileTypeAssociator.Create('LA');
  DVDA:=TDVDAssociator.Create;
  DVDA.AppId:='LA';
end;

destructor TExplorerIntegrator.Destroy;
begin
  DVDA.Free;
  FTA.Free;
  inherited Destroy;
end;

function TExplorerIntegrator.GetDescription;
var
  XN:TXMLNode;
begin
  Result:='';
  XN:=Prefs.RootNode.NodeById('EXT',Ext);
  if Assigned(XN) then
    Result:=XN.Attr('desc');
end;

function TExplorerIntegrator.GetIsDVDAutorun;
begin
  Result:=SameText(DVDA.GetAutoRunApp,FullAppPath+' "%1"');
end;

function TExplorerIntegrator.GetFileMasks;
var
  SL:TStringList;
  l:LongInt;
begin
  Result:='';
  SL:=GetMaskList(MaskType);
  for l:=0 to SL.Count-1 do begin
    if (Length(Result)>0) then
      Result:=Result+';';
    Result:=Result+'*.'+SL[l];
  end;
  SL.Free;
end;

function TExplorerIntegrator.IsAssociated;
begin
  FTA.Ext:=AExt;
  Result:=SameText(FTA.GetDefaultCommand,FullAppPath+' "%1"');
end;

procedure TExplorerIntegrator.SetIsDVDAutorun;
begin
  if (Value=IsDVDAutorun) then Exit;

  if Value then begin
    DVDA.SetAutoRunApp(FullAppPath+',0',FullAppPath+' "%1"');
  end else begin
    DVDA.Rollback;
  end;
end;

function TExplorerIntegrator.GetMaskList;
var
  l:LongInt;
  XN:TXMLNode;
begin
  Result:=TStringList.Create;
  for l:=0 to Length(Prefs.RootNode.Nodes)-1 do begin
    XN:=Prefs.RootNode.Nodes[l];
    if SameText(XN.Tag,'EXT') then begin
      if ((MaskType='*') or (XN.Attr('Type')=MaskType)) then
        Result.Add(XN.Attr('id'));
    end;
  end;
end;

function TExplorerIntegrator.FullAppPath;
begin
  Result:='"'+Core.SysHlp.GetLongFileName(ParamStr(0))+'"';
end;

function TExplorerIntegrator.ExtIcon;
var
  XN,XNP:TXMLNode;
  IcoX:TXMLTree;
  IcoName,XMLName:String;
  l:LongInt;
  ExtType:String;
begin
  IcoName:=Prefs.ReadString('Icons');

  ExtType:=GetExtType(AExt);
  if (IcoName='') then begin
    Result:='0';
    if (ExtType='P') then Result:='2';
    if (ExtType='V') then Result:='3';
    if (ExtType='A') then Result:='4';
    Result:=FullAppPath+','+Result;
    Exit;
  end;

  XmlName:=ExtractFilePath(ParamStr(0))+'Icons\'+IcoName+'.xml';
  IcoName:=ExtractFilePath(ParamStr(0))+'Icons\'+IcoName+'.icl';
  IcoName:='"'+Core.SysHlp.GetLongFileName(IcoName)+'"';

  Result:='';

  if FileExists(XmlName) then begin
    IcoX:=TXMLTree.Create;
    IcoX.LoadFromFile(XmlName);
    XNP:=IcoX.Root.Node('ICONS');
    if Assigned(XNP) then begin
      for l:=0 to Length(XNP.Nodes)-1 do begin
        XN:=XNP.Nodes[l];
        if SameText(XN.Tag,'ICON') then begin
          if (Result='') then begin
            if ((ExtType='P') and SameText(XN.Attr('type'),'PlayList')) then
              Result:=XN.Attr('id');
            if ((ExtType='V') and SameText(XN.Attr('type'),'Video')) then
              Result:=XN.Attr('id');
            if ((ExtType='A') and SameText(XN.Attr('type'),'Sound')) then
              Result:=XN.Attr('id');
          end;
          if IsExtInList(AExt,XN.Attr('ext')) then begin
            Result:=XN.Attr('id');
          end;
        end;
      end;
    end;
    IcoX.Free;
  end
  else
    IcoName:=Core.ExeName;

  if (Result='') then Result:='0';
  Result:=IcoName+','+Result;
end;

procedure TExplorerIntegrator.UpdateIcons;
begin
  FTA.UpdateExplorerIconCache;
end;

function TExplorerIntegrator.IsExtInList;
var
  S:String;
begin
  Result:=FALSE;
  while (Length(AList)>0) do begin
    S:=CutListValue(AList);
    if SameText(S,AExt) then Result:=TRUE;
  end;
end;

function TExplorerIntegrator.CutListValue;
begin
  List:=Trim(List);
  Result:='';
  if (Length(List)>0) and (List[1]=',') then
    Delete(List,1,1);
  while (Length(List)>0) and (List[1]<>',') do begin
    Result:=Result+List[1];
    Delete(List,1,1);
  end;
end;

function TExplorerIntegrator.GetExtType;
var
  XN:TXMLNode;
begin
  Result:='';
  XN:=Prefs.RootNode.NodeById('EXT',AExt);
  if Assigned(XN) then
    Result:=XN.Attr('type');
end;

function TExplorerIntegrator.IsReadOnly: Boolean;
var
  R:TRegistry;
begin
  try
    R:=TRegistry.Create;
    R.RootKey:=HKEY_LOCAL_MACHINE;
    Result:=not(R.OpenKey('\Software\Classes\.avi',TRUE));
    R.Free;
  except
    Result:=TRUE;
  end;
end;

end.
