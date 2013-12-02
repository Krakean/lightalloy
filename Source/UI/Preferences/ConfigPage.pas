unit ConfigPage;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs;

type
  TConfigPageForm = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
  public
    NeedReloadMedia: Boolean;
    NeedReloadApp: Boolean;

    procedure ReadPrefs; virtual;
    procedure UpdateLang; virtual;
    procedure ApplyChanges; virtual;
    procedure WriteKeyData(Key:Word;Shift:TShiftState); virtual;
    procedure ESCMessage; virtual;
    procedure TABMessage; virtual;
  end;

implementation



{$R *.dfm}

{ TConfigPageForm }

procedure TConfigPageForm.ApplyChanges;
begin

end;

procedure TConfigPageForm.ReadPrefs;
begin

end;

procedure TConfigPageForm.FormCreate;
begin
  UpdateLang;
  ReadPrefs;
end;

procedure TConfigPageForm.UpdateLang;
begin

end;

procedure TConfigPageForm.FormDestroy(Sender: TObject);
begin
  // Something
end;

procedure TConfigPageForm.EscMessage;
begin
  // Something
end;

procedure TConfigPageForm.TABMessage;
begin
  // Something
end;

procedure TConfigPageForm.WriteKeyData(Key:Word;Shift:TShiftState);
begin
  // Something
end;

end.
