unit CfgPgAviSynth;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ConfigPage, StdCtrls;

type
  TCPAviSynth = class(TConfigPageForm)
    cbUseAviSynth: TCheckBox;
    mmScript: TMemo;
    lbScript: TListBox;
    procedure lbScriptClick(Sender: TObject);
  private
    procedure FillScripts;
  public
    procedure ReadPrefs; override;
    procedure UpdateLang; override;
    procedure ApplyChanges; override;
  end;

implementation

{$R *.dfm}

uses
  LACore;

procedure TCPAviSynth.ApplyChanges;
begin
  Core.Prefs.WriteBool('Modules.AviSynth.Enabled',cbUseAviSynth.Checked);
  if (lbScript.ItemIndex>=0) then
    Core.Prefs.WriteString('Modules.AviSynth.Script',lbScript.Items[lbScript.ItemIndex]);
end;

procedure TCPAviSynth.ReadPrefs;
begin
  cbUseAviSynth.Checked:=Core.Prefs.ReadBool('Modules.AviSynth.Enabled');
  FillScripts;
end;

procedure TCPAviSynth.UpdateLang;
begin
  cbUseAviSynth.Caption:=MS('Config.AviSynth.UseScript');
end;

procedure TCPAviSynth.lbScriptClick(Sender: TObject);
var
  FN:String;
begin
  if (lbScript.ItemIndex>=0) then begin
    FN:=lbScript.Items[lbScript.ItemIndex];
    FN:=ExtractFilePath(Application.ExeName)+'Plugins\AviSynth\'+FN;

    mmScript.Clear;
    mmScript.Lines.LoadFromFile(FN);
  end;
end;

procedure TCPAviSynth.FillScripts;
var
  SR:TSearchRec;
  l,Found:LongInt;
  Ext:String;
begin
  lbScript.Items.Clear;
  Found:=FindFirst(ExtractFilePath(Application.ExeName)+'Plugins\AviSynth\*.AVS',faAnyFile,SR);
  while (Found=0) do begin
    Ext:=ExtractFileExt(SR.Name);
    if SameText(Ext,'.AVS') then
      lbScript.Items.Add(SR.Name);
    Found:=FindNext(SR);
  end;
  FindClose(SR);

  lbScript.ItemIndex:=0;
  for l:=0 to (lbScript.Items.Count-1) do
    if (lbScript.Items[l]=Core.Prefs.ReadString('Modules.AviSynth.Script')) then
      lbScript.ItemIndex:=l;
  lbScriptClick(Self);    
end;

end.
