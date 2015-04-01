unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, DividerBevel, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls, Spin, ComCtrls, IPConnection, BrickletColor, IniFiles;

const
  HOST = 'localhost';
  PORT = 4223;
  UID = 'oPf'; { Change to your UID }

type

  { TfPhotometer }

  TfPhotometer = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    bSave: TButton;
    Button5: TButton;
    cbValue: TComboBox;
    cbChem: TComboBox;
    cbColor: TComboBox;
    DividerBevel1: TDividerBevel;
    DividerBevel2: TDividerBevel;
    DividerBevel3: TDividerBevel;
    DividerBevel4: TDividerBevel;
    eRange: TEdit;
    eMax: TEdit;
    eMin: TEdit;
    eRMax: TEdit;
    eValue: TEdit;
    eRMin: TEdit;
    Label2: TLabel;
    Label3: TLabel;
    lValue: TLabel;
    mUsage: TMemo;
    mRanges: TMemo;
    seTimer1: TFloatSpinEdit;
    Label1: TLabel;
    lTimer1: TLabel;
    Panel1: TPanel;
    SpinEdit1: TSpinEdit;
    TimerRef: TTimer;
    Timer1: TTimer;
    tbR: TTrackBar;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure bSaveClick(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure cbChemSelect(Sender: TObject);
    procedure cbValueSelect(Sender: TObject);
    procedure eRMaxChange(Sender: TObject);
    procedure eRMinChange(Sender: TObject);
    procedure eValueChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure TimerRefTimer(Sender: TObject);
  private
    { private declarations }
    FTimer1 : Integer;
    FOffsR : word;
    FOffsG : word;
    FOffsB : word;
    FOffsC : word;
  public
    { public declarations }
    ipcon: TIPConnection;
    ColorBricklet: TBrickletColor;
    procedure StartMeasurement;
  end;

var
  fPhotometer: TfPhotometer;

implementation

{$R *.lfm}

{ TfPhotometer }

procedure TfPhotometer.FormCreate(Sender: TObject);
begin
  ipcon := TIPConnection.Create;
  ColorBricklet := TBrickletColor.Create(UID, ipcon);
  ipcon.Connect(HOST, PORT);
  ColorBricklet.LightOn;
  ColorBricklet.SetConfig(60,154);
end;

procedure TfPhotometer.Button1Click(Sender: TObject);
var
  sl: TStringList;
  r: word;
  g: word;
  b: word;
  c: word;
begin
  sl := TStringList.Create;
  if FileExistsUTF8('ranges.txt') then
    sl.LoadFromFile('ranges.txt');
  ColorBricklet.GetColor(r,g,b,c);
  sl.Add(eRange.Text+':'+IntToStr(r)+','+IntToStr(g)+','+IntToStr(b)+','+IntToStr(c));
  sl.SaveToFile('ranges.txt');
  sl.Free;
end;

procedure TfPhotometer.Button2Click(Sender: TObject);
begin
  FTimer1:=round(seTimer1.Value*60);
  lTimer1.Caption:=IntToStr(trunc(FTimer1/60))+':'+Format('%.*d',[2,round(frac(FTimer1/60)*60)]);
  Timer1.Enabled:=True;
end;

procedure TfPhotometer.Button3Click(Sender: TObject);
begin
  try
    ColorBricklet.GetColor(FOffsR,FOffsG,FOffsB,FOffsC);
  except
  end;
  case cbColor.Text of
  'rot':eRMax.Text:=IntToStr(FOffsR);
  'grün':eRMax.Text:=IntToStr(FOffsG);
  'blau':eRMax.Text:=IntToStr(FOffsB);
  'alles':eRMax.Text:=IntToStr(FOffsC);
  end;
end;

procedure TfPhotometer.Button4Click(Sender: TObject);
begin
  try
    ColorBricklet.GetColor(FOffsR,FOffsG,FOffsB,FOffsC);
  except
  end;
  case cbColor.Text of
  'rot':eRMin.Text:=IntToStr(FOffsR);
  'grün':eRMin.Text:=IntToStr(FOffsG);
  'blau':eRMin.Text:=IntToStr(FOffsB);
  'alles':eRMin.Text:=IntToStr(FOffsC);
  end;
end;

procedure TfPhotometer.bSaveClick(Sender: TObject);
var
  ini: TIniFile;
  ss: TStringStream;
begin
  ini := TIniFile.Create(cbValue.Text+'.'+cbChem.Text+'.ini');
  ini.WriteString('Value','Min',eRMin.Text);
  ini.WriteString('Value','Max',eRMax.Text);
  ini.WriteString('Value','Color',cbColor.Text);
  ini.WriteString('Value','RealMin',eMin.Text);
  ini.WriteString('Value','RealMax',eMax.Text);
  ss := TStringStream.Create(mUsage.Text);
  ini.WriteBinaryStream('Usage','Text',ss);
  ss.Free;
  ss := TStringStream.Create(mRanges.Text);
  ini.WriteBinaryStream('Ranges','Text',ss);
  ss.Free;
  ini.WriteFloat('Time','Timer',seTimer1.Value);
  ini.UpdateFile;
  ini.Free;
end;

procedure TfPhotometer.Button5Click(Sender: TObject);
begin
  StartMeasurement;
end;

procedure TfPhotometer.cbChemSelect(Sender: TObject);
var
  ini: TIniFile;
  ss: TStringStream;
begin
  ini := TIniFile.Create(cbValue.Text+'.'+cbChem.Text+'.ini');
  eRMin.Text:=ini.ReadString('Value','Min',eRMin.Text);
  eRMax.Text:=ini.ReadString('Value','Max',eRMax.Text);
  cbColor.Text:=ini.ReadString('Value','Color',cbColor.Text);
  eMin.Text:=ini.ReadString('Value','RealMin',eMin.Text);
  eMax.Text:=ini.ReadString('Value','RealMax',eMax.Text);
  ss := TStringStream.Create('');
  ini.ReadBinaryStream('Usage','Text',ss);
  mUsage.Text:=ss.DataString;
  ss.Free;
  ss := TStringStream.Create('');
  ini.ReadBinaryStream('Ranges','Text',ss);
  mRanges.Text:=ss.DataString;
  ss.Free;
  seTimer1.Value := ini.ReadFloat('Time','Timer',seTimer1.Value);
  ini.Free;
end;

procedure TfPhotometer.cbValueSelect(Sender: TObject);
var
  Info: TSearchRec;
  tmp: String;
begin
  cbChem.Clear;
  If FindFirst ('*.ini',faAnyFile,Info)=0 then
    begin
      repeat
        With Info do
          If (Attr and faDirectory) <> faDirectory then
            begin
              if copy(Name,0,length(cbValue.Text))=cbValue.Text then
                begin
                  tmp := Name;
                  tmp := copy(tmp,length(cbValue.Text)+2,length(tmp));
                  tmp := copy(tmp,0,pos('.',tmp)-1);
                  cbChem.items.Add(tmp);
                end;
            end;
      until FindNext(info)<>0;
    end;
  if cbChem.Items.Count=1 then
    begin
      cbChem.ItemIndex:=0;
      cbChemSelect(cbChem);
    end;
end;

procedure TfPhotometer.eRMaxChange(Sender: TObject);
begin
  tbR.Max:=StrToIntDef(eRMax.Text,65535);
end;

procedure TfPhotometer.eRMinChange(Sender: TObject);
begin
  tbR.Min:=StrToIntDef(eRMin.Text,0);
end;

procedure TfPhotometer.eValueChange(Sender: TObject);
begin
  tbR.Position:=StrToIntDef(eValue.Text,0);
end;

procedure TfPhotometer.FormDestroy(Sender: TObject);
begin
  ColorBricklet.Free;
  ipcon.Free;
end;

procedure TfPhotometer.Timer1Timer(Sender: TObject);
begin
  dec(FTimer1);
  lTimer1.Caption:=IntToStr(trunc(FTimer1/60))+':'+Format('%.*d',[2,round(frac(FTimer1/60)*60)]);
  if FTimer1<0 then
    StartMeasurement;
end;

procedure TfPhotometer.TimerRefTimer(Sender: TObject);
var
  r: word;
  g: word;
  b: word;
  c: word;
begin
  if eValue.text<>'' then exit;
  if not ipcon.IsConnected then exit;
  try
    ColorBricklet.GetColor(r,g,b,c);
  except
  end;
  Panel1.Color:=RGBToColor(round((r/SpinEdit1.Value)),round((g/SpinEdit1.Value)),round((b/SpinEdit1.Value)));
  case cbColor.Text of
  'rot':tbR.Position:=r;
  'grün':tbR.Position:=g;
  'blau':tbR.Position:=b;
  'alles':tbR.Position:=c;
  end;
end;

procedure TfPhotometer.StartMeasurement;
var
  r: word;
  g: word;
  b: word;
  c: word;
  val: Word;
  i: Integer;
  aVal: LongInt;
  aMin : LongInt = 0;
  aMax : LongInt = 65535;
  aValR: Extended;
  aMaxR: Extended;
  aMinR: Extended;
  aRes: Extended;
begin
  try
    ColorBricklet.GetColor(r,g,b,c);
  except
  end;
  case cbColor.Text of
  'rot':val:=r;
  'grün':val:=g;
  'blau':val:=b;
  'alles':val:=c;
  end;
  for i := 0 to mRanges.Lines.Count-1 do
    begin
      aVal := StrToIntDef(copy(mRanges.Lines[i],pos('=',mRanges.Lines[i])+1,length(mRanges.Lines[i])),0);
      aValR := StrToFloatDef(copy(mRanges.Lines[i],0,pos('=',mRanges.Lines[i])-1),0);
      if (val>aVal) and (aVal>aMin) then
        begin
          aMin := aVal;
          aMinR := aValR;
        end;
      if (val<aVal) and (aVal<aMax) then
        begin
          aMax := aVal;
          aMaxR := aValR;
        end;
      if aMax=65535 then
        lValue.Caption:='<'
      else if aMin=0 then
        lValue.Caption:='>'
      else
        begin
          aRes := aMinR+((aMaxR-aMinR)/(aMax-aMin))*(val-aMin);
          lValue.Caption:=FormatFloat('0.00',aRes);
        end;
    end;
  Timer1.Enabled:=False;
end;

end.

