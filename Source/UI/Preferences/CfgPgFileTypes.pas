unit CfgPgFileTypes;

interface

uses
  Windows, SysUtils, Classes, Graphics, Controls, Forms,
  ConfigPage, StdCtrls, CheckLst, Buttons, ShellAPI, XML;

type
  TCPFileTypes = class(TConfigPageForm)
    clbFileTypes: TCheckListBox;
    sbNone: TSpeedButton;
    sbVideo: TSpeedButton;
    sbAudio: TSpeedButton;
    sbAll: TSpeedButton;
    cbDVD: TCheckBox;
    gbIconset: TGroupBox;
    lbIcons: TListBox;
    mmAuthor: TMemo;
    procedure clbFileTypesDrawItem(Control: TWinControl; Index: Integer;
                                   Rect: TRect; State: TOwnerDrawState);
    procedure sbNoneClick(Sender: TObject);
    procedure sbVideoClick(Sender: TObject);
    procedure sbAudioClick(Sender: TObject);
    procedure sbAllClick(Sender: TObject);
    procedure lbIconsClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure clbFileTypesClick(Sender: TObject);
  private
    bmIcons:TBitmap;

    function AverageColor(C1,C2,C3,C4:TColor):TColor;
    procedure DownScale(BMP:TBitmap);
    procedure DrawFileIcon(FileName:String;IcoNum:LongInt;BMP:TBitmap);
  public
    procedure ReadPrefs; override;
    procedure UpdateLang; override;
    procedure ApplyChanges; override;

    procedure ReloadIconsCache;
    procedure UpdateAuthorship;

    function GetExt(Index:LongInt):string;
    procedure SetExt(Ext:string);
  end;

implementation

uses
  LACore, ExplInt;

var
  NoIcons: Boolean = False;

{$R *.dfm}

procedure TCPFileTypes.clbFileTypesDrawItem;
var
  R:TRect;
  Ext,Text:String;
  l:LongInt;
begin
  with clbFileTypes do begin
    with Canvas do begin
      Text:=Items[Index];
      l:=Pos(' ',Text);
      Ext:=Copy(Text,1,l-1);

      if (Copy(Text,1,3)='---') then begin
        Brush.Color:=clSilver;
        FillRect(R);
        Font.Style:=[fsBold];
        Font.Color:=clBlack;
        TextRect(Rect,Rect.Left+2,Rect.Top+2,Text);
      end else begin
        TextRect(Rect,Rect.Left+20,Rect.Top+2,Text);

        R:=Rect;
        Inc(R.Left,1);
        Inc(R.Top,1);
        R.Right:=R.Left+16;
        R.Bottom:=R.Top+16;

        CopyRect(R,bmIcons.Canvas,Classes.Rect(Index*16,0,Index*16+16,16));
      end;
    end;
  end;
end;

procedure TCPFileTypes.sbNoneClick(Sender: TObject);
var
  l:LongInt;
begin
  for l:=0 to clbFileTypes.Items.Count-1 do
    clbFileTypes.Checked[l]:=FALSE;
end;

procedure TCPFileTypes.UpdateLang;
begin
  sbNone.Caption:=MS('Config.None');
  sbVideo.Caption:=MS('Config.Video');
  sbAudio.Caption:=MS('Config.Sound');
  sbAll.Caption:=MS('Config.All');
  gbIconset.Caption:=' '+MS('Config.Icons')+' ';
end;

procedure TCPFileTypes.sbVideoClick(Sender: TObject);
begin
  //PlayList
  SetExt('LAP');
  SetExt('ASX');
  //Video
  SetExt('3GP');
  SetExt('ASF');
  SetExt('AVI');
  SetExt('DIVX');
  SetExt('FLV');
  SetExt('M1V');
  SetExt('M2V');
  SetExt('MKV');
  SetExt('MOV');
  SetExt('MP4');
  SetExt('MPE');
  SetExt('MPG');
  SetExt('MPEG');
  SetExt('MPV');
  SetExt('OGM');
  SetExt('QT');
  SetExt('RM');
  SetExt('RMVB');
  SetExt('RV');
  SetExt('WEBM');
  SetExt('TS');
  SetExt('MTS');
  SetExt('M2TS');
  SetExt('WM');
  SetExt('WMV');
end;

procedure TCPFileTypes.sbAudioClick(Sender: TObject);
begin
  //PlayList
  SetExt('LAP');
  SetExt('M3U');
  SetExt('PLS');
  //Audio
  SetExt('AIF');
  SetExt('AIFC');
  SetExt('AIFF');
  SetExt('AAC');
  SetExt('APE');
  SetExt('AT3');
  SetExt('AC3');
  SetExt('AU');
  SetExt('CDA');
  SetExt('FLAC');
  SetExt('IT');
  SetExt('OGG');
  SetExt('OMA');
  SetExt('KAR');
  SetExt('M4A');
  SetExt('MID');
  SetExt('MIDI');
  SetExt('MKA');
  SetExt('MOD');
  SetExt('MP1');
  SetExt('MP2');
  SetExt('MP3');
  SetExt('MPA');
  SetExt('MPC');
  SetExt('RA');
  SetExt('RAM');
  SetExt('RMI');
  SetExt('SND');
  SetExt('STM');
  SetExt('S3M');
  SetExt('WAV');
  SetExt('WMA');
  SetExt('XM');
end;

procedure TCPFileTypes.sbAllClick(Sender: TObject);
var
  l:LongInt;
begin
  for l:=0 to clbFileTypes.Items.Count-1 do
    if clbFileTypes.ItemEnabled[l] then
      clbFileTypes.Checked[l]:=TRUE;
end;

function TCPFileTypes.GetExt;
var
  l:LongInt;
begin
  Result:=clbFileTypes.Items[Index];
  for l:=1 to Length(Result) do
    if (Result[l]=' ') then begin
      Result:=Copy(Result,1,l-1);
      Break;
    end;
end;

procedure TCPFileTypes.SetExt(Ext: string);
var
  l:longint;
begin
  for l:=0 to clbFileTypes.Items.Count-1 do
    if (GetExt(l)=Ext) then
      clbFileTypes.Checked[l]:=TRUE;
end;

procedure TCPFileTypes.ApplyChanges;
var
  l:LongInt;
  NewIcons:String;
begin
  NewIcons:=lbIcons.Items[lbIcons.ItemIndex];
  if (Core.Prefs.ReadString('FileTypes.Icons')<>NewIcons) and not NoIcons then
    Core.Prefs.WriteString('FileTypes.Icons',NewIcons);

  for l:=0 to clbFileTypes.Items.Count-1 do
    if (clbFileTypes.ItemEnabled[l]) then
      Core.ExplInt.Associate(GetExt(l),clbFileTypes.Checked[l]);

  Core.ExplInt.IsDVDAutoRun:=cbDVD.Checked;
  Core.ExplInt.UpdateIcons;
end;

procedure TCPFileTypes.ReadPrefs;
var
  SL:TStringList;

  procedure AddList;
  var
    Ext:string;
    l:LongInt;
  begin
    SL.Sort;
    for l:=0 to SL.Count-1 do begin
      Ext:=SL[l];
      clbFileTypes.AddItem(Ext+' - '+Core.ExplInt.GetDescription(Ext),NIL);
      clbFileTypes.Checked[clbFileTypes.Items.Count-1]:=Core.ExplInt.IsAssociated(Ext);
    end;
  end;

var
  SR:TSearchRec;
  l,Found:LongInt;
  Ext:String;
  RO:Boolean;
begin
  clbFileTypes.Clear;

  clbFileTypes.AddItem('------- PlayLists -------',NIL);
  clbFileTypes.ItemEnabled[clbFileTypes.Items.Count-1]:=FALSE;
  SL:=Core.ExplInt.GetMaskList('P');
  AddList;
  SL.Free;

  clbFileTypes.AddItem('------- Video -------',NIL);
  clbFileTypes.ItemEnabled[clbFileTypes.Items.Count-1]:=FALSE;
  SL:=Core.ExplInt.GetMaskList('V');
  AddList;
  SL.Free;

  clbFileTypes.AddItem('------- Sound -------',NIL);
  clbFileTypes.ItemEnabled[clbFileTypes.Items.Count-1]:=FALSE;
  SL:=Core.ExplInt.GetMaskList('A');
  AddList;
  SL.Free;

  lbIcons.Items.Clear;
  Found:=FindFirst(ExtractFilePath(Application.ExeName)+'Icons\*.xml',faAnyFile,SR);
  if Found <> 0 then begin
    NoIcons:=True;
    lbIcons.Items.Add('<Default>');
  end;
  while (Found=0) do begin
    Ext:=ExtractFileExt(SR.Name);
    lbIcons.Items.Add(ChangeFileExt(SR.Name,''));
    Found:=FindNext(SR);
  end;
  FindClose(SR);

  lbIcons.ItemIndex:=0;
  for l:=0 to (lbIcons.Items.Count-1) do
    if (lbIcons.Items[l]=Core.Prefs.ReadString('FileTypes.Icons')) then
      lbIcons.ItemIndex:=l;

  ReloadIconsCache;

  with Core.Prefs do begin
    cbDVD.Checked:=Core.ExplInt.IsDVDAutoRun;
  end;

  RO:=Core.ExplInt.IsReadOnly;
  clbFileTypes.Enabled:=not(RO);
  sbNone.Enabled:=not(RO);
  sbVideo.Enabled:=not(RO);
  sbAudio.Enabled:=not(RO);
  sbAll.Enabled:=not(RO);
  lbIcons.Enabled:=not(RO);
  cbDVD.Enabled:=not(RO);
end;

procedure TCPFileTypes.lbIconsClick(Sender: TObject);
begin
  ReloadIconsCache;
end;

procedure TCPFileTypes.ReloadIconsCache;
var
  OfsX,l,Index:LongInt;
  S,SaveIcons,Text,Ext:String;
  BMP:TBitmap;
begin
  BMP:=TBitmap.Create;
  BMP.PixelFormat:=pf32bit;
  bmIcons.Width:=16*clbFileTypes.Items.Count;
  bmIcons.Height:=16;

  SaveIcons:=Core.Prefs.ReadString('FileTypes.Icons');
  if not NoIcons then
    Core.Prefs.WriteString('FileTypes.Icons',lbIcons.Items[lbIcons.ItemIndex]);

  for Index:=0 to clbFileTypes.Items.Count-1 do begin
    OfsX:=Index*16;
    Text:=clbFileTypes.Items[Index];
    l:=Pos(' ',Text);
    Ext:=Copy(Text,1,l-1);

    if (Copy(Text,1,3)<>'---') then begin
      if not NoIcons then begin
        S:=Core.ExplInt.ExtIcon(Ext);
        l:=Pos(',',S);
        S:=Copy(S,l+1,10);
        l:=StrToInt(S);
        S:=lbIcons.Items[lbIcons.ItemIndex]+'.icl';
        S:=ExtractFilePath(ParamStr(0))+'Icons\'+S;
        BMP.Width:=32;
        BMP.Height:=32;
        with BMP.Canvas do begin
          Brush.Color:=clbFileTypes.Color;
          Pen.Color:=Brush.Color;
          Rectangle(0,0,32,32);
        end;
        DrawFileIcon(S,l,BMP);
        bmIcons.Canvas.Draw(OfsX,0,BMP);
      end
      else begin
        BMP.Width:=32;
        BMP.Height:=32;
        with BMP.Canvas do begin
          Brush.Color:=clbFileTypes.Color;
          Pen.Color:=Brush.Color;
          Rectangle(0,0,32,32);
        end;
        DrawFileIcon(Core.ExeName,1,BMP);
        bmIcons.Canvas.Draw(OfsX,0,BMP);        
      end;
    end;
  end;
  Core.Prefs.WriteString('FileTypes.Icons',SaveIcons);
  if not NoIcons then UpdateAuthorship;

  clbFileTypes.Invalidate;
end;

procedure TCPFileTypes.FormCreate(Sender: TObject);
begin
  bmIcons:=TBitmap.Create;
  bmIcons.PixelFormat:=pf32bit;
  inherited FormCreate(Sender);
end;

procedure TCPFileTypes.FormDestroy(Sender: TObject);
begin
  inherited FormDestroy(Sender);
  bmIcons.Free;
end;

procedure TCPFileTypes.DownScale(BMP: TBitmap);
var
  x,y:LongInt;
begin
  with BMP.Canvas do
    for y:=0 to 15 do
      for x:=0 to 15 do
        Pixels[x,y]:=AverageColor(Pixels[x*2+0,y*2+0],Pixels[x*2+0,y*2+1],
                                  Pixels[x*2+1,y*2+0],Pixels[x*2+1,y*2+1]);
  BMP.Width:=BMP.Width div 2;
  BMP.Height:=BMP.Height div 2;
end;

function TCPFileTypes.AverageColor;
begin
  Result:=((C1 and $FCFCFC) shr 2) + ((C2 and $FCFCFC) shr 2) +
          ((C3 and $FCFCFC) shr 2) + ((C4 and $FCFCFC) shr 2);
end;

procedure TCPFileTypes.DrawFileIcon;
var
  Icon:TIcon;
  HndL, Hnd, TmpHnd: HICON;
begin
  Icon:=TIcon.Create;
  TmpHnd:=Icon.Handle;
  //Icon.Handle:= ExtractIcon(hInstance,PChar(FileName),IcoNum);
  ExtractIconEx(PChar(FileName), IcoNum, HndL, Hnd, 1);
{
  Icon.Handle:=CreateIconFromResourceEx(PByte(lpResource),
SizeofResource(hExe, hResource), TRUE, 0x00030000,
CXICON, CYICON, LR_DEFAULTCOLOR);
}
//  BMP.Width:=Icon.Width;
//  BMP.Height:=Icon.Height;
//  BMP.Canvas.Draw(0,0,Icon);
//  DownScale(BMP);
  if Hnd > 0 then
  begin
    Icon.Handle:= Hnd;
    BMP.Width:= Icon.Width;
    BMP.Height:= Icon.Height;
    BMP.Canvas.Draw(0, 0, Icon);
  end else
  begin
    Icon.Handle:= HndL;
    BMP.Width:= Icon.Width;
    BMP.Height:= Icon.Height;
    BMP.Canvas.Draw(0, 0, Icon);
    DownScale(BMP);
  end;

  Icon.Handle:=TmpHnd;
  Icon.Free;
end;

procedure TCPFileTypes.UpdateAuthorship;
var
  S:String;
  X:TXMLTree;
begin
  mmAuthor.Clear;
  {if (lbIcons.ItemIndex=0) then begin
    mmAuthor.Lines.Add('Default IconSet');
    Exit;
  end;}

  S:=lbIcons.Items[lbIcons.ItemIndex]+'.xml';
  S:=ExtractFilePath(ParamStr(0))+'Icons\'+S;

  X:=TXMLTree.Create;
  X.LoadFromFile(S);
  S:=X.GetXValue('\AUTHOR\name');
  if (S<>'') then mmAuthor.Lines.Add('Автор: '+S);
  S:=X.GetXValue('\AUTHOR\email');
  if (S<>'') then mmAuthor.Lines.Add(S);
  S:=X.GetXValue('\AUTHOR\ICQ');
  if (S<>'') then mmAuthor.Lines.Add('ICQ: ' + S);
  S:=X.GetXValue('\AUTHOR\MSN');
  if (S<>'') then mmAuthor.Lines.Add('MSN: ' + S);
  S:=X.GetXValue('\AUTHOR\SKYPE');
  if (S<>'') then mmAuthor.Lines.Add('SKYPE: ' + S);
  S:=X.GetXValue('\AUTHOR\homepage');
  if (S <> '') and (S <> '?') then mmAuthor.Lines.Add('http://'+S+'/');
  S:=X.GetXValue('\AUTHOR\comments');
  if (S<>'') then mmAuthor.Lines.Add(S);
  X.Free;
end;

procedure TCPFileTypes.clbFileTypesClick(Sender: TObject);
var
  l:LongInt;
  Flag:Boolean;
begin
  if clbFileTypes.ItemEnabled[clbFileTypes.ItemIndex] then Exit;

  Flag:=not(clbFileTypes.Checked[clbFileTypes.ItemIndex+1]);
  for l:=clbFileTypes.ItemIndex+1 to clbFileTypes.Items.Count-1 do begin
    if clbFileTypes.ItemEnabled[l] then begin
      clbFileTypes.Checked[l]:=Flag;
    end else begin
      Break;
    end;
  end;
end;

end.
