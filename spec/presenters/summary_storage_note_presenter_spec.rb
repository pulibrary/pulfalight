# frozen_string_literal: true
require "rails_helper"

RSpec.describe SummaryStorageNotePresenter do
  subject(:ssnote) { described_class.new(document) }
  let(:document) { SolrDocument.new(values) }
  let(:values) { {} }

  describe "#render" do
    context "with a document that has been indexed to use json" do
      let(:values) do
        {
          "summary_storage_note_ssm": [
            '{"Firestone Library (scahsvm)":["Boxes 1-11; 13-19"],"Firestone Library (scamss)":["Boxes 12; 83; 330; B-001491"]}'
          ],
          "location_note_ssm": [
            "Box numbers 5, 15 are not used."
          ]
        }
      end
      it "renders the json as a description list" do
        expect(ssnote.render).to eq(
          ["<span>This is stored in multiple locations.</span>",
           "<dl class=\"storage-notes\">",
           "<dt>Firestone Library (scahsvm)</dt>",
           "<dd>Boxes 1-11; 13-19</dd>",
           "<dt>Firestone Library (scamss)</dt>",
           "<dd>Boxes 12; 83; 330</dd>",
           "<dd>Boxes B-001491</dd>",
           "</dl>",
           "<span class=\"storage-notes-appendix\">",
           "<div class=\"header\">Note</div>",
           "<div>Box numbers 5, 15 are not used.</div>",
           "</span>"].join
        )
      end
    end

    context "with no location but a text note" do
      let(:values) do
        {
          "location_note_ssm": [
            "Box numbers 5, 15 are not used."
          ]
        }
      end
      it "returns the text note" do
        expect(ssnote.render).to eq(
          ["<span class=\"storage-notes-appendix\">",
           "<div class=\"header\">Note</div>",
           "<div>Box numbers 5, 15 are not used.</div>",
           "</span>"].join
        )
      end
    end

    context "with neither location nor text note" do
      let(:values) do
        {}
      end
      it "does not return a list or appendix" do
        expect(ssnote.render).to be_blank
      end
    end

    context "with more than one text note" do
      let(:values) do
        {
          "location_note_ssm": [
            "Box numbers 5, 15 are not used.",
            "Box number 6 is also not used."
          ]
        }
      end
      it "returns all text notes" do
        expect(ssnote.render).to eq(
          ["<span class=\"storage-notes-appendix\">",
           "<div class=\"header\">Note</div>",
           "<div>Box numbers 5, 15 are not used.</div>",
           "<div>Box number 6 is also not used.</div>",
           "</span>"].join
        )
      end
    end

    context "when the storage note has one location, with more than one item type" do
      let(:values) do
        {
          "summary_storage_note_ssm": [
            '{"Firestone Library (scahsvm)":["Boxes 1-11; 13-19", "Volumes 2-4"]}'
          ]
        }
      end
      it "does not say 'multiple locations' and it has two dd tags" do
        expect(ssnote.render).to eq(
          ["<dl class=\"storage-notes\">",
           "<dt>Firestone Library (scahsvm)</dt>",
           "<dd>Boxes 1-11; 13-19</dd>",
           "<dd>Volumes 2-4</dd>",
           "</dl>"].join
        )
      end

      context "when the storage note has a lot of consecutive abid-style box  numbers" do
        let(:values) do
          {
            "summary_storage_note_ssm": [
              '{"Firestone Library (mss)":["Boxes B-001494; B-001495; B-001496; B-001497; B-001498; B-001499; B-001500; B-001501; B-001502; B-001503; B-001504; B-001505; B-001506; B-001507; B-001508; B-001509; B-001510; B-001511; B-001512; B-001515; B-001514; B-001513; B-001516; B-001517; B-001518; B-001519; B-001520; B-001521; B-001522; B-001523; B-001524; B-001525; B-001526; B-001527; B-001528; B-001529; B-001530; B-001531; B-001532; B-001533; B-001534; B-001536; B-001535; B-001537; B-001539; B-001538; B-001540; P-000146; B-001541; B-001542; B-001543; B-001544", "Volumes M-003456; M-003457; M-003458"]}'
            ]
          }
        end
        it "collapses the abid-style box numbers into a range" do
          expect(ssnote.render).to eq(
            ["<dl class=\"storage-notes\">",
             "<dt>Firestone Library (mss)</dt>",
             "<dd>Boxes B-001494 to B-001544; P-000146</dd>",
             "<dd>Volumes M-003456 to M-003458</dd>",
             "</dl>"].join
          )
        end
      end
      context "when the storage note has a lot of consecutive box numbers of the form A00" do
        let(:values) do
          {
            "summary_storage_note_ssm": [
              '{"Firestone Library (scamss)":["Boxes 1-2; H1; H2; H3; L1; L2; L3; L4; L5; L6; L7; L8; L9; L10; L11; L12; L13; L14; L15; L16; L17; L18; L19; L20; L21; L22; L23; L24; L25; L26; L27; L28; L29; L30; L31; L32; L33; L34; L35; L36; L37; M1; M2; M3; M4; M5; M6; M7; M8; M9; M10; M11; M12; M13; M14; M15; M16; M17; M18; M19; M20; M21; M22; M23; M24; M25; M26; M27; M28; M29; M30; M31; M32; M33; M34; M35; M36; M37; M38; M39; M40; M41; M42; M43; M44; M45; M46; M47; M48; M49; M50; M51; M52; M53; M54; M55; M56; M57; M58; M59; M60; M61; M62; M63; M64; M65; M66; M67; M68; M69; M70; M71; M72; M73; M74;"]}'
            ]
          }
        end

        it "collapses box numbers with the form A00" do
          expect(ssnote.render).to eq(
            ["<dl class=\"storage-notes\">",
             "<dt>Firestone Library (scamss)</dt>",
             "<dd>Boxes 1-2</dd>",
             "<dd>Boxes H1 to H3; L1 to L37; M1 to M74</dd>",
             "</dl>"].join
          )
        end
      end
      context "when the storage note has a lot of consecutive box numbers of the form 'oversize folder 216'" do
        let(:values) do
          {
            "summary_storage_note_ssm": [
              '{"Mudd Manuscript Library (scamudd)":["Folders 11; 14; 23-24; 27-29; 32-33; 38-41; 43-44; 46; 48; 53; 56; 61-62; 68; 86-87; 104-106; 186; oversize folder 213; oversize folder 214; oversize folder 215; oversize folder 216; oversize folder 217; oversize folder 218; oversize folder 219; oversize folder 220; oversize folder 221; oversize folder 222; oversize folder 223; oversize folder 224; oversize folder 225; oversize folder 226; oversize folder 227; oversize folder 228; oversize folder 234; oversize folder 235; oversize folder 229; oversize folder 230; oversize folder 231; oversize folder 232; oversize folder 236; oversize folder 237; oversize folder 238; oversize folder 239; oversize folder 240; oversize folder 241; oversize folder 233; Oversize folder 1; Not located; Oversize folder 2; Oversize folder 3; Oversize folder 4; Oversize folder 5; Oversize folder 6; Oversize folder 7; Oversize folder 8; Oversize folder 9; Oversize folder 10; Oversize folder 12; Oversize folder 13; Oversize folder 15; Oversize folder 16; Oversize folder 17; Oversize folder 18; Oversize folder 19; Oversize folder 20; Oversize folder 21; Oversize folder 26; Oversize folder 25; Oversize folder 22; Oversize folder 30; Oversize folder 31; Oversize folder 35; Oversize folder 34; Oversize folder 36; Oversize folder 37; Oversize folder 42; Oversize folder 45; Oversize folder 47; Oversize folder 49; Oversize folder 50; Oversize folder 51; Oversize folder 52; Oversize folder 54; Oversize folder 55; Oversize folder 57; Oversize folder 58; Oversize folder 59; Oversize folder 60; Oversize folder 64; Oversize folder 63; Oversize folder 65; Oversize folder 66; Oversize folder 67; Oversize folder 69; Oversize folder 70; Oversize folder 71; Oversize folder 72; Oversize folder 73; Oversize folder 74; Oversize folder 77; Oversize folder 78; Oversize folder 79; Oversize folder 81; Oversize folder 80; Oversize folder 82; Oversize folder 83; Oversize folder 84; Oversize folder 85; Oversize folder 88; Oversize folder 76; Oversize folder 75; Oversize folder 89; Oversize folder 90; Oversize folder 91; Oversize folder 92; Oversize folder 93; Oversize folder 94; Oversize folder 95; Oversize folder 96; Oversize folder 97; Oversize folder 98; Oversize folder 99; Oversize folder 100; Oversize folder 101; Oversize folder 185; Oversize folder 102; Oversize folder 103; Oversize folder 107; Oversize folder 108; Oversize folder 109; Oversize folder 110; Oversize folder 111; Oversize folder 112; Oversize folder 113; Oversize folder 114; Oversize folder 115; Oversize folder 116; Oversize folder 117; Oversize folder 118; Oversize folder 119; Oversize folder 120; Oversize folder 121; Oversize folder 122; Oversize folder 123; Oversize folder 124; Oversize folder 125; Oversize folder 126; Oversize folder 127; Oversize folder 128; Oversize folder 129; Oversize folder 130; Oversize folder 131; Oversize folder 132; Oversize folder 133; Oversize folder 134; Oversize folder 136; Oversize folder 135; Oversize folder 137; Oversize folder 142; Oversize folder 138; Oversize folder 139; Oversize folder 140; Oversize folder 141; Oversize folder 143; Oversize folder 144; Oversize folder 145; Oversize folder 146; Oversize folder 147; Oversize folder 148; Oversize folder 149; Oversize folder 150; Oversize folder 151; Oversize folder 152; Oversize folder 153; Oversize folder 154; Oversize folder 155; Oversize folder 156; Oversize folder 157; Oversize folder 158; Oversize folder 159; Oversize folder 160; Oversize folder 161; Oversize folder 162; Oversize folder 163; Oversize folder 165; Oversize folder 164; Oversize folder 166; Folder not located; Oversize folder 167; Oversize folder 168; Oversize folder 169; Oversize folder 170; Oversize folder 171; Oversize folder 172; Oversize folder 173; Oversize folder 174; Oversize folder 175; Oversize folder 176; Oversize folder 177; Oversize folder 178; Oversize folder 179; Oversize folder 180; Oversize folder 181; Oversize folder 182; Oversize folder 183; Oversize folder 184; Oversize folder 187; Oversize folder 188; Oversize folder 189; Oversize folder 190; Oversize folder 191; Oversize folder 192; Oversize folder 210"]}'
            ]
          }
        end

        it "collapses box numbers with the form 'oversize folder 216'" do
          expect(ssnote.render).to eq(
            ["<dl class=\"storage-notes\">",
             "<dt>Mudd Manuscript Library (scamudd)</dt>",
             "<dd>Folders 11; 14; 23-24; 27-29; 32-33; 38-41; 43-44; 46; 48; 53; 56; 61-62; 68; 86-87; 104-106; 186</dd>",
             "<dd>Oversize folder 1 to 10; 12 to 13; 15 to 22; 25 to 26; 30 to 31; 34 to 37; 42; 45; 47; 49 to 52; 54 to 55; 57 to 60; 63 to 67; 69 to 85; 88 to 103; 107 to 185; 187 to 192; 210; 213 to 241</dd>",
             "<dd>Folder not located; Not located</dd>",
             "</dl>"].join
          )
        end
      end
    end
  end
end
