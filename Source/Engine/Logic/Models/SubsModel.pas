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
unit SubsModel;

interface

uses
  SysUtils, Dialogs, DShowHlp, SubStream, NiceModels, Models, SubVoicePlayer;

type
  TSubStreamModel = class(TObject)
  private
    SubStrm:TSubtitleStream;
    FIndex:LongInt;
    FTitle:String;
    Enabled,VPos,Shift:TSInt32Model;
    VideoFPS:Double;
    FVPos:LongInt;
    VoiceDir:String;
    SubVP:TSubVoicePlayer;

    procedure CreateModels;
    procedure DestroyModels;

    procedure OnVPos;
    function GetFixedPos(Pos:Int64):Int64;
  public
    constructor Create(VPos,Index:LongInt);
    destructor Destroy; override;

    function IsEnabled:Boolean;
    function IsLoaded:Boolean;
    procedure Load(FN:String);
    procedure Clear;

    function IsMicroDVD:Boolean;
    function GetSubText(Pos:Int64):String;

    property YPos:LongInt read FVPos write FVPos;
  end;

  TSubtitlesModel = class(TObject)
  private
    function SelectSubFile:String;
    function FileMasks:String;

    procedure CreateModels;
    procedure DestroyModels;

    procedure LoadSubsFromFN(FileName:String);
    procedure SearchDir(FileName:String);

    function CanLoadSub:Boolean;
    function LoadAnotherSub(FileName:string):Boolean;
  public
    Sub1,Sub2:TSubStreamModel;

    constructor Create;
    destructor Destroy; override;

    procedure SetVideoFPS(FPS:Double);

    procedure Clear;
    procedure Disable;
    procedure Enable;

    function IsEmpty:Boolean;
    procedure SearchSubtitles(FileName:string);
    procedure LoadSubtitles1;
    procedure LoadSubtitles2;

    procedure SwitchStream;
  end;

implementation

uses
  LACore;

procedure TSubtitlesModel.Clear;
begin
  Sub1.Clear;
  Sub2.Clear;
end;

constructor TSubtitlesModel.Create;
begin
  inherited Create;
  Sub1:=TSubStreamModel.Create(Core.Prefs.ReadInteger('Subtitles.Pos1'),0);
  Sub2:=TSubStreamModel.Create(Core.Prefs.ReadInteger('Subtitles.Pos2'),1);
  SetVideoFPS(25);
  CreateModels;
end;

destructor TSubtitlesModel.Destroy;
begin
  Core.Prefs.WriteInteger('Subtitles.Pos1',Sub1.YPos);
  Core.Prefs.WriteInteger('Subtitles.Pos2',Sub2.YPos);
  DestroyModels;

  Sub2.Free;
  Sub1.Free;
  inherited Destroy;
end;

function TSubtitlesModel.IsEmpty: Boolean;
begin
  Result:=not(Sub1.IsLoaded) and not(Sub2.IsLoaded);
end;

function TSubtitlesModel.FileMasks: String;
begin
  Result:='*.txt;*.ass;*.sub;*.srt;*.ssa';
end;

procedure TSubtitlesModel.LoadSubtitles1;
var
  FN:String;
begin
  FN:=SelectSubFile;
  if (FN<>'') then
    Sub1.Load(FN);
end;

procedure TSubtitlesModel.LoadSubtitles2;
var
  FN:String;
begin
  FN:=SelectSubFile;
  if (FN<>'') then
    Sub2.Load(FN);
end;

procedure TSubtitlesModel.SearchSubtitles(FileName: string);
var
  Path:String;
begin
  if Core.Prefs.Bool['Subtitles.UseFolder'] then begin
    Path:=Core.Prefs.Str['Subtitles.Folder'];
    if (Path<>'') then begin
      Path:=IncludeTrailingPathDelimiter(Path);
      SearchDir(Path+ExtractFileName(FileName));
    end;
  end;
  if not(CanLoadSub) then Exit;

  LoadSubsFromFN(FileName);
end;

function TSubtitlesModel.SelectSubFile: String;
var
  OD:TOpenDialog;
  Path:String;
begin
  Result:='';
  OD:=TOpenDialog.Create(NIL);
  if Core.Prefs.Bool['Subtitles.UseFolder'] then begin
    Path:=Core.Prefs.Str['Subtitles.Folder'];
    if (Path<>'') then begin
      OD.InitialDir:=Path;
    end else begin
      OD.InitialDir:=Core.Prefs.Str['OSD.Subs.Folder'];
    end;
  end else begin
    OD.InitialDir:=Core.Prefs.Str['FrontEnd.MediaDir'];
  end;
  OD.Filter:='Subtitles ('+FileMasks+')|'+FileMasks+'|Any File (*.*)|*.*';
  OD.Title:=MS('Command.350')+'...';
  if OD.Execute then begin
    Result:=OD.FileName;
    Core.Prefs.Str['OSD.Subs.Folder']:=ExtractFilePath(OD.FileName);
  end;
  OD.Free;
end;

procedure TSubtitlesModel.CreateModels;
begin
  with Core.MdlMgr do begin
    SetModel('App.Subs.Load0',TCommandModel.Create(LoadSubtitles1));
    SetModel('App.Subs.Load1',TCommandModel.Create(LoadSubtitles2));
    SetModel('App.Subs.Pos',TModel.Create(NIL));
  end;
end;

procedure TSubtitlesModel.DestroyModels;
begin
  with Core.MdlMgr do begin
    DestroyModel('App.Subs.Pos');
    DestroyModel('App.Subs.Load1');
    DestroyModel('App.Subs.Load0');
  end;
end;

{ TSubStreamModel }

procedure TSubStreamModel.Clear;
begin
  if Assigned(Shift) then begin
    Core.MdlMgr.SetModel('App.Subs.Shift'+IntToStr(FIndex),NIL);
    FreeAndNIL(Shift);
  end;
  if Assigned(VPos) then begin
    Core.MdlMgr.SetModel('App.Subs.VPos'+IntToStr(FIndex),NIL);
    FreeAndNIL(VPos);
  end;
  if Assigned(Enabled) then begin
    Enabled.set_SInt32(0);
    Core.MdlMgr.SetModel('App.Subs.Enabled'+IntToStr(FIndex),NIL);
    FreeAndNIL(Enabled);
  end;
  SubStrm.Clear;
  if Assigned(SubVP) then
    FreeAndNIL(SubVP);
  FTitle:='';
end;

constructor TSubStreamModel.Create;
begin
  inherited Create;
  SubStrm:=TSubtitleStream.Create;
  FIndex:=Index;
  FVPos:=VPos;
  CreateModels;
  VoiceDir:='';
  SubVP:=NIL;
end;

procedure TSubStreamModel.CreateModels;
begin
  with Core.MdlMgr do begin
    SetModel('App.Subs.Title'+IntToStr(FIndex),TStringModel.Create('',NIL));
  end;
end;

destructor TSubStreamModel.Destroy;
begin
  Clear;
  DestroyModels;
  SubStrm.Free;
  inherited Destroy;
end;

procedure TSubStreamModel.DestroyModels;
begin
  with Core.MdlMgr do begin
    DestroyModel('App.Subs.Title'+IntToStr(FIndex));
  end;
end;

function TSubStreamModel.GetFixedPos;
var
  fps:Double;
  PosX:Int64;
begin
  PosX:=Pos;
  if (IsMicroDVD) then begin
    if (Core.Prefs.Int['Subtitles.SetMicroDVDFPS']=0) then begin
      fps:=VideoFPS;
    end else begin
      try
        fps:=StrToFloat(Core.Prefs.ReadString('Subtitles.MicroDVDFPS'));
      except
        fps:=25.0;
      end;
    end;
    if (fps<0.0001) then fps:=25;
    PosX:=Round((Pos/25.0)*fps);
  end;

  try
    fps:=StrToFloat(Core.Prefs.Str['Subtitles.Offset']);
    if Assigned(Shift) then
      fps:=Shift.get_SInt32/10;
  except
    fps:=0;
  end;
  PosX:=PosX-Round(HNS*fps);

  Result:=PosX;
end;

function TSubStreamModel.GetSubText;
var
  PosX:Int64;
begin
  Result:='';
  if not(IsLoaded) then Exit;
  if not(IsEnabled) then Exit;

  PosX:=GetFixedPos(Pos);
  Result:=SubStrm.GetSubtitle(PosX);

  if (Assigned(SubVP) and (SubStrm.SubIndex>=0)) then
    SubVP.Play(SubStrm.SubIndex+1);
end;

function TSubStreamModel.IsEnabled: Boolean;
begin
  Result:=Assigned(Enabled);
  if not(Result) then Exit;
  Result:=(Enabled.get_SInt32>0);
end;

function TSubStreamModel.IsLoaded;
begin
  IsLoaded:=(FTitle<>'');
end;

function TSubStreamModel.IsMicroDVD: Boolean;
begin
  Result:=(SubStrm.SubFmt='SubV10(MicroDVD)');
end;

procedure TSubStreamModel.Load;
begin
  Clear;

  VoiceDir:=ExtractFilePath(FN)+'SubVoice\';
  if not(DirectoryExists(VoiceDir)) then VoiceDir:='';
  if (VoiceDir<>'') then begin
    SubVP:=TSubVoicePlayer.Create;
    SubVP.MediaDir:=VoiceDir;
  end;

  SubStrm.LoadFromFile(FN);
  FTitle:=ExtractFileName(FN);
  Core.MdlMgr.SetString('App.Subs.Title'+IntToStr(FIndex),FTitle);

  if (Enabled=NIL) then begin
    Enabled:=TSInt32Model.Create(1,NIL);
    Core.MdlMgr.SetModel('App.Subs.Enabled'+IntToStr(FIndex),Enabled);
  end;
  Enabled.set_SInt32(1);
  if (VPos=NIL) then begin
    VPos:=TSInt32Model.Create(FVPos,OnVPos);
    Core.MdlMgr.SetModel('App.Subs.VPos'+IntToStr(FIndex),VPos);
  end;
  VPos.set_SInt32(FVPos);
  if (Shift=NIL) then begin
    Shift:=TSInt32Model.Create(0,NIL);
    Core.MdlMgr.SetModel('App.Subs.Shift'+IntToStr(FIndex),Shift);
  end;
  Shift.set_SInt32(0);
end;

procedure TSubStreamModel.OnVPos;
var
  M:TModel;
begin
  FVPos:=VPos.get_SInt32;
  M:=Core.MdlMgr.GetModel('App.Subs.Pos');
  if Assigned(M) then
    M.StateChanged;
end;

procedure TSubtitlesModel.Disable;
begin
  with Core.MdlMgr do begin
    SetSInt32('App.Subs.Enabled0',0);
    SetSInt32('App.Subs.Enabled1',0);
  end;
end;

procedure TSubtitlesModel.Enable;
begin
  with Core.MdlMgr do begin
    SetSInt32('App.Subs.Enabled0',1);
    SetSInt32('App.Subs.Enabled1',1);
  end;
end;

function TSubtitlesModel.LoadAnotherSub;
begin
  if (not(Sub1.IsLoaded)) then begin
    Sub1.Load(FileName);
    Result:=Sub2.IsLoaded;
    Exit;
  end;

  if (not(Sub2.IsLoaded)) then begin
    Sub2.Load(FileName);
  end;

  Result:=Sub2.IsLoaded;
end;

procedure TSubtitlesModel.SearchDir;
var
  SR:TSearchRec;
  Found:LongInt;
  Path,FN:String;
begin
  Path:=ExtractFilePath(FileName);
  FN:=ExtractFileName(FileName);

  if not(CanLoadSub) then Exit;

  LoadSubsFromFN(FileName);

  Found:=FindFirst(Path+'*.*',faAnyFile,SR);
  while (Found=0) do begin
    if ((SR.Name<>'.') and (SR.Name<>'..')
         and ((SR.Attr and faDirectory)>0)) then
      SearchDir(Path+SR.Name+'\'+FN);
    Found:=FindNext(SR);
  end;
  FindClose(SR);
end;

function TSubtitlesModel.CanLoadSub: Boolean;
begin
  Result:=not(Sub1.IsLoaded) or not(Sub2.IsLoaded);
end;

procedure TSubtitlesModel.LoadSubsFromFN(FileName: String);
var
  SubName:string;
begin
  if not(CanLoadSub) then Exit;

  SubName:=ChangeFileExt(FileName,'.ass');
  if (FileExists(SubName)) then
  begin
    LoadAnotherSub(SubName);
    if not(CanLoadSub) then Exit;
  end;

  SubName:=ChangeFileExt(FileName,'.srt');
  if (FileExists(SubName)) then
  begin
    LoadAnotherSub(SubName);
    if not(CanLoadSub) then Exit;
  end;

  SubName:=ChangeFileExt(FileName,'.sub');
  if (FileExists(SubName)) then begin
    LoadAnotherSub(SubName);
    if not(CanLoadSub) then Exit;
  end;

  SubName:=ChangeFileExt(FileName,'.ssa');
  if (FileExists(SubName)) then begin
    LoadAnotherSub(SubName);
    if not(CanLoadSub) then Exit;
  end;
end;

procedure TSubtitlesModel.SetVideoFPS(FPS: Double);
begin
  Sub1.VideoFPS:=FPS;
  Sub2.VideoFPS:=FPS;
end;

procedure TSubtitlesModel.SwitchStream;
var
  Cur,Cnt:LongInt;
begin
  if DSH=nil then Exit;
  if not DSH.SStreamSelectAvaible then begin
    Core.Info(MS('OSD.SubsStream.Notfound'));
    Exit;
  end;
  Cnt:=DSH.SubsStreamCount;
  if Cnt>0 then begin
    Cur:=DSH.GetSubsStream;
    if Cur+1 <= Cnt then
      DSH.SetSubsStream(Cur+1)
    else
      DSH.SetSubsStream(1);
    Core.Info(MS('OSD.SubsStream')+': '+IntToStr(Cur)+' '+MS('OSD.SubsStream.of')+' '+IntToStr(Cnt));
  end;
end;

end.
