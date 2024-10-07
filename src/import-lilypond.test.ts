import { FileItemLy, ScoreDefLy } from './intermediate-ly';
import { expect } from 'chai';
import { lilypondToJMusic, load } from './import-lilypond';
import {Clef, ClefType, createNote, Key, MeterFactory, Note, Pitch, cloneNote, SimpleSequence, Time} from 'jmusic-model/dist/model';

describe('Lilypond import to JMusic', () => {

    /*beforeEach(() => { 
    });*/
    function toNote(def: any) {
        let note = createNote(def.data.pitches.map((p: any) => new Pitch(p[0], p[1], p[2])), def.data.dur);
        if (def.data.tie) note = cloneNote(note, { tie: true });
        return note;
    }

    


    it('should parse a sequence', () => {
        const res = load("{c4 d e f }") as any;

        expect(res.type).to.eq('SimpleSequence');

        expect(res.data.map((elm: any) => toNote(elm))).to.deep.eq(
            new SimpleSequence('c4 d4 e4 f4').elements
        );

    });



    it('should parse a score with staves and voices', () => {

        const score1 = `\\score { % Start score
            <<
              \\new PianoStaff <<  % Start pianostaff
                \\new Staff <<  % Start Staff = RH
                  \\global
                  \\clef "treble"
        
      \\new Voice = "MusicA" << \\Timeline \\voiceOne \\MusicA >> % End Voice = "MusicA"
      \\new Voice = "MusicB" << \\Timeline \\voiceTwo \\MusicB >> % End Voice = "MusicB"
          >>  % End Staff = RH
          \\new Staff <<  % Start Staff = LH
            \\global
            \\clef "bass"
        
      \\new Voice = "MusicC" << \\Timeline \\voiceOne \\MusicC >> % End Voice = "MusicC"
      \\new Voice = "MusicD" << \\Timeline \\voiceTwo \\MusicD >> % End Voice = "MusicD"
                >>  % End Staff = LH
              >>  % End pianostaff
            >>
          }`;



        const res = load(score1, {startRule: 'File'}) as any[];

        expect(res).to.have.length(1);

        const sc = res[0];
        expect(sc.type).to.eq('Score');

        /*const sts = sc.data.staves;
        expect(sts).to.have.length(2);
        
        const st = sts[0];
        expect(st.type).to.eq('Staff');
        expect(st.data).to.have.length(4);

        /*expect(st.data[1]).to.deep.eq({
            "type": "Note",
            "data": {
               "dur": {
                  "numerator": 1,
                  "denominator": 4,
                  "type": "span"
               },
               "pitches": [
                  [
                     0,
                     3,
                     0
                  ]
               ]
            }
         });
        
         */


    });       

    it('should import a function', () => {
      const relFunc = load('var = \\relative d, { c4 }', {startRule: 'File'});
      
      expect (relFunc).to.deep.eq([{
        type: 'VarDef',
        data: {
          identifier: 'var',
          value: {
            type: 'Function',
            data: [
              'relative',
              {
                type: 'Pitch',
                data: [1, 2, 0]
              },
              {
                type: 'SimpleSequence',
                data: [
                  {
                                    "data": {
                                      "dur": {
                                        "denominator": 4,
                                        "numerator": 1,
                                        "type": "span"
                                      },
                                      "pitches": [
                                        [
                                          0,
                                          3,
                                          0
                                        ]
                                      ]
                                    },
                                    "type": "Note"
                                  }
                ]
              }
            ]
          }
        }
      }]);

      const resolved = lilypondToJMusic('var = \\relative d, { c4 }\n\\var');

      console.log(resolved);

    });

});
