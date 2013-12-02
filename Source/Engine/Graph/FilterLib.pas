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
unit FilterLib;

interface

uses
  // RTL / VCL
  Windows, Classes, SysUtils, ActiveX, Dialogs,
  // Engine
  DirectShow9, FilterBase, SpecialIntf, Multilog;

type
  TFiltersInf = class(TObject)
  private
    Cnt: Integer;
    FiltersInf: array of TFilterInf;
  public
    constructor Create;
    destructor Destriy;

    procedure Add(FInfo:TFilterInf);
    procedure Clear;

    function GetCLSID(Obj: IUnknown): TGUID;

    function GetFInfo(Filter:IBaseFilter;out FInfo:TFilterInf):Boolean;overload;
    function GetFInfo(CLSID:TGUID;out FInfo:TFilterInf):Boolean;overload;
  end;

  TFilterLibrary = class(TObject)
  private
    Filters:TStringList;
  public
    FPath: String;
    FLibPath: String;
    ActiveLocalFilters: TFiltersInf;

    constructor Create(Path:String);
    destructor Destroy; override;

    function FCC2Hex(FCC:String):String;
    function FCC2Str(FCC:DWORD):String;

    function SetFiles: Boolean;
    function FillFilters(Path:String):Boolean;
    function GetFilterFile(ShortFileName:String):String;
    function GetFilterInfo(Request:String):TFilterInf;

    function CreateFilter(Request:String; out FInfo:TFilterInf):IBaseFilter;
    function SwapSourceToSplitter(var FInfo:TFilterInf): Boolean;

    function CreateStaticBaseFilter(FType, FCC:String; out FInfo:TFilterInf):IBaseFilter;
    function CreateDynamicBaseFilter(FType, FCC:String; NeedReload:Boolean; out FInfo:TFilterInf):IBaseFilter;
    function CreateFilterByInfo(var FInfo:TFilterInf):IBaseFilter;

    function IsRegisteredFilter(Filter:IBaseFilter):Boolean;

    procedure RegisterFilter(FInfo:TFilterInf);
    procedure UnRegisterFilter(FInfo:TFilterInf);
  end;

implementation

uses
  Registry, LACore, HttpDownload, CachedStream, XML, OtherGlobalVars;

function TFilterLibrary.CreateFilterByInfo(var FInfo:TFilterInf):IBaseFilter;
var
  hR:HRESULT;

  procedure CreateSystemFilter;
  begin
    try
      hR:=CoCreateInstance(FInfo.ClsID, NIL, CLSCTX_INPROC, IID_IBaseFilter, Result);
    finally
      LogHR('!TFilterLibrary: System:('+FInfo.NAME+')=',hR);
    end;
  end;

  procedure CreateLocalFilter;
  var
    AX:HMODULE;
    ClassFactory:IClassFactory;
    GetCO:function(const CLSID:TCLSID;const IID:TIID;out IFace):HRESULT; stdcall;
  begin
    if not FileExists(GetFilterFile(FInfo.FileName)) then Exit;
    try
      AX:=LoadLibraryEx(PChar(GetFilterFile(FInfo.FileName)), 0, LOAD_WITH_ALTERED_SEARCH_PATH);
      if (AX<>0) then begin
        GetCO:=GetProcAddress(AX,'DllGetClassObject');
        if not(Assigned(GetCO)) then Exit;
        hR:=GetCO(FInfo.ClsID,IID_IClassFactory,ClassFactory);
        LogHR('!TFilterLibrary: Local:('+FInfo.FILENAME+')=',hR);
        hR:=ClassFactory.CreateInstance(NIL,IID_IBaseFilter,Result);
        if FAILED(hR) then Result:=NIL;
        ClassFactory:=NIL;
      end;
    except
      Log('!LoadLibraryEx Error: '+GetFilterFile(FInfo.FileName));
    end;
  end;
begin
  Result:=NIL;
  FInfo.LOCALPATH:='';
  if (not Core.Prefs.ReadBool('Modules.DirectShow.LocalFiltersPriority'))
    or (not Core.Prefs.ReadBool('Modules.DirectShow.FastRender'))
  then
  begin
    CreateSystemFilter;
    if (Result<>NIL) then Exit;
    CreateLocalFilter;
    if (Result<>NIL) then FInfo.LOCALPATH:=GetFilterFile(FInfo.FILENAME);
  end
  else begin
    CreateLocalFilter;
    if (Result<>NIL) then begin
      FInfo.LOCALPATH:=GetFilterFile(FInfo.FILENAME);
      Exit;
    end;
    CreateSystemFilter;
  end;
end;

function TFilterLibrary.CreateFilter;
var
  FTYPE, FCC: String;
begin
  Result:=NIL;
  if IsStopping then Exit;
  Log('+TFilterLibrary.CreateFilter');

  FInfo.LOCALPATH:='';

  FTYPE:=Copy(Request,1,Pos('=',Request));
  Delete(Request,1,Pos('=',Request));
  FCC:=UpperCase('/'+Request+'/');

  if Core.Prefs.ReadBool('Core.AllowDownloadFilters') then
    Result:=CreateDynamicBaseFilter(FTYPE,FCC,False,FInfo);

  if Result=NIL then
    Result:=CreateStaticBaseFilter(FTYPE,FCC,FInfo);

  if (Result=NIL) and Core.Prefs.ReadBool('Core.FirstRequest')
    and (not Core.Prefs.ReadBool('Core.AllowDownloadFilters'))
  then begin
    if MessageBox(0,PChar(MS('Core.Title.Message')),'Light Alloy',MB_YESNO)= IDYES then
      Core.Prefs.WriteBool('Core.AllowDownloadFilters',True);
    Core.Prefs.WriteBool('Core.FirstRequest',False);
  end;

  if (Result=NIL) and Core.Prefs.ReadBool('Core.AllowDownloadFilters')
    and (not Core.Prefs.ReadBool('Core.SaveFilterPriorities'))
  then
    Result:=CreateDynamicBaseFilter(FTYPE,FCC,True,FInfo);

  Log('-TFilterLibrary.CreateFilter');
end;

function TFilterLibrary.SwapSourceToSplitter;
var
  i: Integer;
begin
  Result:=False;
  for i:=0 to SplittersCount do begin
    if (ExtractFileName(FInfo.FILENAME)=Splitters[i].FILENAME)
      and (FInfo.NAME[1]=Splitters[i].NAME[1])
    then begin
      FInfo.NAME:=Splitters[i].NAME;
      FInfo.CLSID:=Splitters[i].CLSID;
      Result:=True;
      Break;
    end;
  end;
end;

function TFilterLibrary.CreateStaticBaseFilter;
var
  i, Cnt: Integer;
  QueryFilters:array of TFilterInf;
begin
  Log('+TFilterLibrary.CreateStaticBaseFilter ['+FType+FCC+']');
  Result:=NIL;
  Cnt:=0;

  FInfo.FCC:='';
  FInfo.NAME:='';
  FInfo.FILENAME:='';
  FInfo.CLSID:=GUID_NULL;
  FInfo.LOCALPATH:='';

  if (FTYPE='format=') then begin
    for i:=0 to AudioSourceCount do begin
      if (Pos(FCC,AudioSource[i].FCC)<>0) then begin
        SetLength(QueryFilters,Cnt+1);
        QueryFilters[Cnt].FCC :=AudioSource[i].FCC;
        QueryFilters[Cnt].NAME :=AudioSource[i].NAME;
        QueryFilters[Cnt].FILENAME :=AudioSource[i].FILENAME;
        QueryFilters[Cnt].CLSID :=AudioSource[i].CLSID;
        QueryFilters[Cnt].LOCALPATH :='';
        Inc(Cnt);
      end;
    end;

    for i:=0 to VideoSourceCount do begin
      if (Pos(FCC,VideoSource[i].FCC)<>0) then begin
        SetLength(QueryFilters,Cnt+1);
        QueryFilters[Cnt].FCC :=VideoSource[i].FCC;
        QueryFilters[Cnt].NAME :=VideoSource[i].NAME;
        QueryFilters[Cnt].FILENAME :=VideoSource[i].FILENAME;
        QueryFilters[Cnt].CLSID :=VideoSource[i].CLSID;
        QueryFilters[Cnt].LOCALPATH :='';
        Inc(Cnt);
      end;
    end;
  end;

  if (FTYPE='vidc=') then begin
    for i:=0 to VideoDecodersCount do begin
      if (Pos(FCC,VideoDecoders[i].FCC)<>0) then begin
        SetLength(QueryFilters,Cnt+1);
        QueryFilters[Cnt].FCC :=VideoDecoders[i].FCC;
        QueryFilters[Cnt].NAME :=VideoDecoders[i].NAME;
        QueryFilters[Cnt].FILENAME :=VideoDecoders[i].FILENAME;
        QueryFilters[Cnt].CLSID :=VideoDecoders[i].CLSID;
        QueryFilters[Cnt].LOCALPATH :='';
        Inc(Cnt);
      end;
    end;
  end;

  if (FTYPE='audc=') then begin
    for i:=0 to AudioDecodersCount do begin
      if (Pos(FCC,AudioDecoders[i].FCC)<>0)
        or (Pos('/ANY/',AudioDecoders[i].FCC)<>0)
      then begin
        SetLength(QueryFilters,Cnt+1);
        QueryFilters[Cnt].FCC :=AudioDecoders[i].FCC;
        QueryFilters[Cnt].NAME :=AudioDecoders[i].NAME;
        QueryFilters[Cnt].FILENAME :=AudioDecoders[i].FILENAME;
        QueryFilters[Cnt].CLSID :=AudioDecoders[i].CLSID;
        QueryFilters[Cnt].LOCALPATH :='';
        Inc(Cnt);
      end;
    end;
  end;

  if (FTYPE='advf=') then begin
    for i:=0 to AdvancedFiltersCount do begin
      if (Pos(FCC,AdvancedFilters[i].FCC)<>0) then begin
        SetLength(QueryFilters,Cnt+1);
        QueryFilters[Cnt].FCC :=AdvancedFilters[i].FCC;
        QueryFilters[Cnt].NAME :=AdvancedFilters[i].NAME;
        QueryFilters[Cnt].FILENAME :=AdvancedFilters[i].FILENAME;
        QueryFilters[Cnt].CLSID :=AdvancedFilters[i].CLSID;
        QueryFilters[Cnt].LOCALPATH :='';
        Inc(Cnt);
      end;
    end;
  end;

  if Length(QueryFilters)<1 then begin
    Log('-TFilterLibrary.CreateStaticBaseFilter: filters cannot be found!');
    Exit;
  end;

  for i:=0 to Cnt-1 do begin
    Result:=CreateFilterByInfo(QueryFilters[i]);
    if Result<>NIL then begin
      FInfo:=QueryFilters[i];
      Break;
    end;
  end;

  Log('-TFilterLibrary.CreateStaticBaseFilter: '+BoolToStr(Assigned(Result)));
end;

function TFilterLibrary.CreateDynamicBaseFilter;
var
  i, j, Cnt, Max: Integer;

  QueryFilters:array of TFilterInf;

  Buf: WORD;
  ManyFiles: Boolean;

  s,f: String;
  LocalBase: String;
  RemoteBase: String;

  FilterBaseTree: TXMLTree;

  BaseFile: TFileStream;
  FilterFile: TFileStream;

  CBaseFile: TCachedStream;

  BaseMem: TMemoryStream;
  FilterMem: TMemoryStream;
begin
  Log('+TFilterLibrary.CreateDynamicBaseFilter ['+FType+FCC+']');
  if SessionFails then begin
    Log('-TFilterLibrary.CreateDynamicBaseFilter: Session Failed!');
    Exit;
  end;
  Result:=NIL;
  Cnt:=0;

  FInfo.FCC:='';
  FInfo.NAME:='';
  FInfo.FILENAME:='';
  FInfo.CLSID:=GUID_NULL;
  FInfo.PRIORITY:=0;
  FInfo.LOCALPATH:='';

  LocalBase:=IncludeTrailingPathDelimiter(Core.ExePath)+'filterbase.xml';
  RemoteBase:=Core.Prefs.ReadString('Core.RemoteBaseURL');

  if not DirectoryExists(FLibPath) then CreateDir(FLibPath);

  // Prepare XML
  if not Assigned(FBNode) or NeedReload then begin
    if not FileExists(LocalBase) or NeedReload then begin
      BaseMem:=TMemoryStream.Create;
      IsReloaded:=inetDL(RemoteBase+'filterbase.xml',TStream(BaseMem));
      if IsReloaded then begin
        BaseFile:=TFileStream.Create(LocalBase, fmCreate or fmShareDenyNone);
        BaseFile.CopyFrom(BaseMem,0);
        BaseMem.Free;
      end
      else begin
        BaseMem.Free;
        Log('-TFilterLibrary.CreateDynamicBaseFilter: filterbase.xml inaccessible!');
        Exit;
      end;
    end;
    if not IsReloaded then
      BaseFile:=TFileStream.Create(LocalBase, fmOpenRead or fmShareDenyNone);
    CBaseFile:=TCachedStream.Create(BaseFile,1,16384);
    FilterBaseTree := TXMLTree.Create;
    FilterBaseTree.LoadFromStream(CBaseFile);
    FBNode :=FilterBaseTree.Root;
    CBaseFile.Free;
    BaseFile.Free;
  end;

  // Source Filters
  if (FTYPE='format=') then begin
    // AudioSplitters
    with FBNode.Nodes[0] do begin
      for i:=0 to StrToInt(Attr('Count'))-1 do begin
        if (Pos(FCC,Nodes[i].Attr('fcc'))<>0) then begin
          SetLength(QueryFilters,Cnt+1);
          QueryFilters[Cnt].FCC:=Nodes[i].Attr('fcc');
          QueryFilters[Cnt].NAME:=Nodes[i].Attr('name');
          QueryFilters[Cnt].FILENAME:=Nodes[i].Attr('files');
          QueryFilters[Cnt].CLSID:=StringToGUID(Nodes[i].Attr('clsid'));
          QueryFilters[Cnt].PRIORITY:=StrToInt(Nodes[i].Attr('priority'));
          Inc(Cnt);
        end;
      end;
    end;
    // VideoSplitters
    with FBNode.Nodes[1] do begin
      for i:=0 to StrToInt(Attr('Count'))-1 do begin
        if (Pos(FCC,Nodes[i].Attr('fcc'))<>0) then begin
          SetLength(QueryFilters,Cnt+1);
          QueryFilters[Cnt].FCC:=Nodes[i].Attr('fcc');
          QueryFilters[Cnt].NAME:=Nodes[i].Attr('name');
          QueryFilters[Cnt].FILENAME:=Nodes[i].Attr('files');
          QueryFilters[Cnt].CLSID:=StringToGUID(Nodes[i].Attr('clsid'));
          QueryFilters[Cnt].PRIORITY:=StrToInt(Nodes[i].Attr('priority'));
          Inc(Cnt);
        end;
      end;
    end;
  end;

  // AudioDecoders
  if (FTYPE='audc=') then begin
    with FBNode.Nodes[2] do begin
      for i:=0 to StrToInt(Attr('Count'))-1 do begin
        if (Pos(FCC,Nodes[i].Attr('fcc'))<>0)
          or (Pos('/ANY/',Nodes[i].Attr('fcc'))<>0)
        then begin
          SetLength(QueryFilters,Cnt+1);
          QueryFilters[Cnt].FCC:=Nodes[i].Attr('fcc');
          QueryFilters[Cnt].NAME:=Nodes[i].Attr('name');
          QueryFilters[Cnt].FILENAME:=Nodes[i].Attr('files');
          QueryFilters[Cnt].CLSID:=StringToGUID(Nodes[i].Attr('clsid'));
          QueryFilters[Cnt].PRIORITY:=StrToInt(Nodes[i].Attr('priority'));
          Inc(Cnt);
        end;
      end;
    end;
  end;

  // VideoDecoders
  if (FTYPE='vidc=') then begin
    with FBNode.Nodes[3] do begin
      for i:=0 to StrToInt(Attr('Count'))-1 do begin
        if (Pos(FCC,Nodes[i].Attr('fcc'))<>0) then begin
          SetLength(QueryFilters,Cnt+1);
          QueryFilters[Cnt].FCC:=Nodes[i].Attr('fcc');
          QueryFilters[Cnt].NAME:=Nodes[i].Attr('name');
          QueryFilters[Cnt].FILENAME:=Nodes[i].Attr('files');
          QueryFilters[Cnt].CLSID:=StringToGUID(Nodes[i].Attr('clsid'));
          QueryFilters[Cnt].PRIORITY:=StrToInt(Nodes[i].Attr('priority'));
          Inc(Cnt);
        end;
      end;
    end;
  end;

  // AdvancedFilters
  if (FTYPE='advf=') then begin
    with FBNode.Nodes[4] do begin
      for i:=0 to StrToInt(Attr('Count'))-1 do begin
        if (Pos(FCC,Nodes[i].Attr('fcc'))<>0) then begin
          SetLength(QueryFilters,Cnt+1);
          QueryFilters[Cnt].FCC:=Nodes[i].Attr('fcc');
          QueryFilters[Cnt].NAME:=Nodes[i].Attr('name');
          QueryFilters[Cnt].FILENAME:=Nodes[i].Attr('files');
          QueryFilters[Cnt].CLSID:=StringToGUID(Nodes[i].Attr('clsid'));
          QueryFilters[Cnt].PRIORITY:=StrToInt(Nodes[i].Attr('priority'));
          Inc(Cnt);
        end;
      end;
    end;
  end;

  if Length(QueryFilters)<1 then begin
    Log('-TFilterLibrary.CreateDynamicBaseFilter: filters cannot be found!');
    Exit;
  end;

  Max:=0;
  for i:=0 to Cnt-1 do begin
    for j:=i+1 to Cnt-1 do
      if QueryFilters[j].PRIORITY > QueryFilters[max].PRIORITY then begin
        FInfo:=QueryFilters[j];
        max:=j;
      end;
    if Max>0 then begin
      QueryFilters[max]:=QueryFilters[i];
      QueryFilters[i]:=Finfo;
    end;
  end;

  for i:=0 to Cnt-1 do begin
    FInfo:=QueryFilters[i];
    if (FInfo.FILENAME<>'') then begin
      S:=FInfo.FILENAME;
      if S[1]='/' then begin
        Delete(S,1,1);
        FInfo.FILENAME:=Copy(S,1,Pos('/',S)-1);
        ManyFiles:=True;
      end
      else
        ManyFiles:=False;

      repeat
        if not ManyFiles then
          F:=FInfo.FILENAME
        else
          F:=Copy(S,1,Pos('/',S)-1);
        if not FileExists(FLibPath+F) and (FInfo.PRIORITY>-1) then begin
          DownloadFilter:=FInfo.NAME;
          DownloadFileName:=F;
          IsDownloading:=True;
          FilterMem:=TMemoryStream.Create;
          if inetDL(RemoteBase+F,TStream(FilterMem)) then begin
            if FilterMem.Size > 4 then begin
              FilterMem.Seek(0,soFromBeginning);
              FilterMem.Read(Buf,2);
              if Buf=$5A4D then begin
                FilterFile:=TFileStream.Create(FLibPath+F, fmCreate or fmShareDenyNone);
                FilterFile.CopyFrom(FilterMem,0);
                FilterFile.Free;
                SetFiles;
              end;
            end;
            FilterMem.Clear;
          end;
          FilterMem.Free;
        end;
        Delete(S,1,Pos('/',S));
      until
        (Pos('/',S)=0) or TerminateDownloading or SessionFails;
      IsDownloading:=False;
      TerminateDownloading:=False;
      FInfo.FILENAME:=FLibPath+FInfo.FILENAME;
      Result:=CreateFilterByInfo(FInfo);
    end;
    if Result<>NIL then Break;
  end;

  Log('-TFilterLibrary.CreateDynamicBaseFilter: '+BoolToStr(Assigned(Result)));
end;

function TFilterLibrary.FCC2Hex(FCC: String): String;
begin
  Result:=Format('%.2x%.2x%.2x%.2x',[Ord(FCC[4]),Ord(FCC[3]),Ord(FCC[2]),Ord(FCC[1])]);
end;

function TFilterLibrary.FCC2Str(FCC: DWORD): String;
var
  l:LongInt;
begin
  Result:='';
  for l:=0 to 3 do begin
    Result:=Result+Chr(FCC and $FF);
    FCC:=FCC shr 8;
  end;
end;

function TFilterLibrary.GetFilterFile;
var
  i:Integer;
//  Path:String;  
begin
{  if (FInfo.IncPath<>'') then begin
    Path:=GetEnvironmentVariable('PATH');
    Path:=Path+';'+FInfo.IncPath;
    SetEnvironmentVariable('PATH',PChar(Path));
  end;}
  Result:=ShortFileName;
  with Filters do
    for i:=0 to Count-1 do
      if Pos(LowerCase(ShortFileName),LowerCase(Strings[i]))>0 then
        Result:=Strings[i];
end;

function TFilterLibrary.GetFilterInfo(Request:String):TFilterInf;
var
  Flt:IBaseFilter;
begin
  Result.Name:=Request;
  Result.FileName:='';
  Result.ClsID:=GUID_NULL;
  Flt:=CreateFilter(Request,Result);
  Flt:=NIL;
end;

type
  TRegProc = function:HResult; stdcall;

constructor TFilterLibrary.Create(Path: String);
begin
  FPath:=Path;
  SetFiles;
  ActiveLocalFilters:=TFiltersInf.Create;
end;

destructor TFilterLibrary.Destroy;
begin
  Filters.Free;
  ActiveLocalFilters.Free;
  inherited Destroy;
end;

function TFilterLibrary.FillFilters(Path: String): Boolean;
var
  SR:TSearchRec;
  Found:LongInt;
  function ApplyMask(FileName:String):Boolean;
  var
    Ext:String;
  begin
    Result:=False;
    Ext:=LowerCase(ExtractFileExt(FileName));
    if (Ext='.dll') or (Ext='.ax') then
      Result:=True;
  end;
begin
  Filters.Clear;
  Result:=False;

  Found:=FindFirst(Path+'*.*',faAnyFile,SR);
  while (Found=0) do begin
    if (SR.Attr and faDirectory)>0 then begin
      if ((SR.Name<>'.') and (SR.Name<>'..')) then
        FillFilters(Path+SR.Name+'\');
    end else begin
      if ApplyMask(Path+SR.Name) then
        Filters.Add(Path+SR.Name);
    end;
    Found:=FindNext(SR);
  end;
  FindClose(SR);
end;

function TFilterLibrary.SetFiles: Boolean;
begin
  Result:=False;
  if Filters=nil then
    Filters:=TStringList.Create;
  FPath:=IncludeTrailingPathDelimiter(FPath);
  if DirectoryExists(FPath+'Splitters\') then begin
    FLibPath:=FPath+'Splitters\';
    FillFilters(FLibPath);
  end;
  if DirectoryExists(FPath+'Plugins\DirectShow\') then begin
    FLibPath:=FPath+'Plugins\DirectShow\';
    FillFilters(FLibPath);
  end;
  if DirectoryExists(FPath+'Codecs\') then begin
    FLibPath:=FPath+'Codecs\';
    FillFilters(FLibPath);
  end;
  if DirectoryExists(FPath+'Filters\') then begin
    FLibPath:=FPath+'Filters\';
    FillFilters(FLibPath);
  end
  else
  if FLibPath='' then FLibPath:=FPath+'Filters\';
end;

function TFilterLibrary.IsRegisteredFilter;
var
  R:TRegistry;
begin
  R:=TRegistry.Create;
  R.RootKey:=HKEY_LOCAL_MACHINE;
  Result:=R.KeyExists('\SOFTWARE\Classes\CLSID\{083863F1-70DE-11D0-BD40-00A0C911CE86}\Instance\'+
    GUIDToString(ActiveLocalFilters.GetCLSID(Filter)));
  R.CloseKey;
  R.Free;
end;

procedure TFilterLibrary.RegisterFilter;
var
  AX:HMODULE;
  RegProc:TRegProc;
begin
  AX:=LoadLibrary(PChar(FInfo.FileName));
  if (AX=0) then Exit;
  @RegProc:=GetProcAddress(AX,'DllRegisterServer');
  if Assigned(RegProc) then begin
    RegProc;
  end;
  FreeLibrary(AX);
end;

procedure TFilterLibrary.UnRegisterFilter(FInfo: TFilterInf);
var
  AX:HMODULE;
  RegProc:TRegProc;
begin
  AX:=LoadLibrary(PChar(FInfo.FileName));
  if (AX=0) then Exit;
  @RegProc:=GetProcAddress(AX,'DllUnregisterServer');
  if Assigned(RegProc) then begin
    RegProc;
  end;
  FreeLibrary(AX);
end;


{ TFiltersInf }

procedure TFiltersInf.Add(FInfo: TFilterInf);
begin
  if FInfo.LOCALPATH='' then Exit;
  Inc(Cnt);
  SetLength(FiltersInf,Cnt+1);
  FiltersInf[Cnt]:=FInfo;
end;

procedure TFiltersInf.Clear;
begin
  SetLength(FiltersInf,0);
  Cnt:=0;
end;

constructor TFiltersInf.Create;
begin
  SetLength(FiltersInf,0);
  Cnt:=0;
  inherited;
end;

destructor TFiltersInf.Destriy;
begin
  SetLength(FiltersInf,0);
  inherited;
end;

function TFiltersInf.GetCLSID;
var
  P:IPersist;
  G:TGUID;
begin
  g:=GUID_NULL;
  if (SUCCEEDED(Obj.QueryInterface(IID_IPersist,P))) then
    P.GetClassID(G);
  P:=NIL;
  Result:=G;
end;

function TFiltersInf.GetFInfo(Filter:IBaseFilter;out FInfo:TFilterInf):Boolean;
var
  i:Integer;
  G:TGUID;
begin
  Result:=False;
  if Cnt=0 then Exit;
  G:=GetCLSID(Filter);
  for i:=0 to Cnt do begin
    if IsEqualGUID(FiltersInf[i].CLSID,G) then begin
      FInfo.FCC:=FiltersInf[i].FCC;
      FInfo.NAME:=FiltersInf[i].NAME;
      FInfo.FILENAME:=FiltersInf[i].FILENAME;
      FInfo.CLSID:=FiltersInf[i].CLSID;
      FInfo.PRIORITY:=FiltersInf[i].PRIORITY;
      FInfo.LOCALPATH:=FiltersInf[i].LOCALPATH;
      Result:=True;
    end;
  end;
end;

function TFiltersInf.GetFInfo(CLSID:TGUID;out FInfo: TFilterInf):Boolean;
var
  i:Integer;
begin
  Result:=False;
  if (Cnt=0) or IsEqualGUID(CLSID,GUID_NULL) then Exit;
  for i:=0 to Cnt do begin
    if IsEqualGUID(FiltersInf[i].CLSID,CLSID) then begin
      FInfo.FCC:=FiltersInf[i].FCC;
      FInfo.NAME:=FiltersInf[i].NAME;
      FInfo.FILENAME:=FiltersInf[i].FILENAME;
      FInfo.CLSID:=FiltersInf[i].CLSID;
      FInfo.PRIORITY:=FiltersInf[i].PRIORITY;
      FInfo.LOCALPATH:=FiltersInf[i].LOCALPATH;
      Result:=True;
    end;
  end;
end;

end.
