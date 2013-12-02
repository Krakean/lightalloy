unit CfgPgDirectShow;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ConfigPage, StdCtrls, Buttons, DShowHlp, DirectShow9, ExtCtrls;

type
  TCPDirectShow = class(TConfigPageForm)
    cbFastRender: TCheckBox;
    cbLocalFiltersPriority: TCheckBox;
    cbDisableSubs: TCheckBox;
    gbFilters: TGroupBox;
    lbDSPlug: TListBox;
    btDSPlugAdd: TButton;
    btDSPlugRemove: TButton;
    bbDSPlugProps: TBitBtn;
    procedure lbDSPlugDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure btDSPlugAddClick(Sender: TObject);
    procedure btDSPlugRemoveClick(Sender: TObject);
    procedure bbDSPlugPropsClick(Sender: TObject);
  private
    procedure FilterConfig(GUID:TGUID);
  public
    procedure ReadPrefs; override;
    procedure UpdateLang; override;
    procedure ApplyChanges; override;
  end;

implementation

uses
  LACore, Filter, Config;

{$R *.dfm}

procedure TCPDirectShow.ApplyChanges;
begin
  Core.Prefs.WriteList('Modules.DirectShow.ForceFilters',lbDSPlug.Items);
  Core.Prefs.WriteBool('Modules.DirectShow.FastRender',cbFastRender.Checked);
  Core.Prefs.WriteBool('Modules.DirectShow.LocalFiltersPriority',cbLocalFiltersPriority.Checked);
  Core.Prefs.WriteBool('Modules.DirectShow.DisableSubs',cbDisableSubs.Checked);
end;

procedure TCPDirectShow.lbDSPlugDrawItem;
var
  CLSID:string;
begin
  CLSID:=lbDSPlug.Items[Index];
  with lbDSPlug.Canvas do begin
    try
      CLSID:=Core.DSH.GetFilterFriendlyName(StringToGUID(CLSID));
    except
      CLSID:='Unknown';
    end;
    TextRect(Rect,Rect.Left+1,Rect.Top,CLSID);
  end;
end;

procedure TCPDirectShow.ReadPrefs;
begin
  Core.Prefs.ReadList('Modules.DirectShow.ForceFilters',lbDSPlug.Items);
  cbFastRender.Checked:=Core.Prefs.ReadBool('Modules.DirectShow.FastRender');
  cbLocalFiltersPriority.Checked:=Core.Prefs.ReadBool('Modules.DirectShow.LocalFiltersPriority');
  cbDisableSubs.Checked:=Core.Prefs.ReadBool('Modules.DirectShow.DisableSubs');
end;

procedure TCPDirectShow.UpdateLang;
begin
  gbFilters.Caption:=' '+MS('Config.DirectShow.LoadFilters')+' ';
  btDSPlugAdd.Caption:=MS('Config.DirectShow.Add');
  bbDSplugProps.Caption:=MS('Config.DirectShow.Properties');
  btDSPlugRemove.Caption:=MS('Config.DirectShow.Remove');
  cbFastRender.Caption:=MS('Config.DirectShow.FastRender');
  cbLocalFiltersPriority.Caption:=MS('Config.DirectShow.LocalFiltersPriority');
  cbDisableSubs.Caption:=MS('Config.DirectShow.DisableSubs');
end;

procedure TCPDirectShow.btDSPlugAddClick(Sender: TObject);
begin
  frFilter:=TfrFilter.Create(Application);
  if frConfig.ConfigPageAlwayOnTop.Enabled then frConfig.SwitchCfgTopPos(frFilter.Handle, True);
  frFilter.Init;
  //frMain.PopupForm(frFilter);
  frFilter.ShowModal;
  if (frFilter.ModalResult = mrOk) then
  begin
    lbDSPlug.Items.Add(GUIDToString(frFilter.Selected));
  end;
  if frConfig.ConfigPageAlwayOnTop.Enabled then frConfig.SwitchCfgTopPos(frFilter.Handle, False);
  FreeAndNIL(frFilter);
end;

procedure TCPDirectShow.btDSPlugRemoveClick(Sender: TObject);
begin
  if (lbDSPlug.ItemIndex>=0) then
    lbDSPlug.Items.Delete(lbDSPlug.ItemIndex);
end;

procedure TCPDirectShow.bbDSPlugPropsClick(Sender: TObject);
begin
  if (lbDSPlug.ItemIndex>=0) then
    FilterConfig(StringToGuid(lbDSPlug.Items[lbDSPlug.ItemIndex]));
end;

procedure TCPDirectShow.FilterConfig(GUID: TGUID);
var
  Filter:IBaseFilter;
begin
  Filter:=DSH.CreateFilter(GUID);
  DSH.FilterProperties(Handle,Filter);
  Filter:=NIL;
end;

end.
