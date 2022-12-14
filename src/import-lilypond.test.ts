import { FileItemLy, ScoreDefLy } from './intermediate-ly';
import { expect } from 'chai';
import { load } from './import-lilypond';
import {Clef, ClefType, Key, MeterFactory, Note, Pitch, SimpleSequence, Time} from 'jmusic-model/model';

describe('Lilypond import', () => {

    /*beforeEach(() => { 
    });*/
    function toNote(def: any) {
        const note = new Note(def.data.pitches.map((p: any) => new Pitch(p[0], p[1], p[2])), def.data.dur);
        if (def.data.tie) note.tie = true;
        return note;
    }

    it('should parse a pitch', () => {
        const res1 = load("c", {startRule: 'Pitch'});

        expect(res1).to.deep.eq({ type: 'Pitch', data: [0, 3, 0] });
        expect(res1).to.deep.eq(Pitch.parseLilypond('c').getDef());

        const res2 = load("c''", {startRule: 'Pitch'});

        expect(res2).to.deep.eq({ type: 'Pitch', data: [0, 5, 0] });

        const res3 = load("e,", {startRule: 'Pitch'});

        expect(res3).to.deep.eq({ type: 'Pitch', data: [2, 2, 0] });

        const res4 = load("fis,,", {startRule: 'Pitch'});

        expect(res4).to.deep.eq({ type: 'Pitch', data: [3, 1, 1] });

        const res5 = load("beses'", {startRule: 'Pitch'});

        expect(res5).to.deep.eq({ type: 'Pitch', data: [6, 4, -2] });
    });

    it('should parse a note', () => {

        const res1 = load("c4 ", {startRule: 'MusicElement'});

        expect(res1).to.deep.eq( {type: 'Note', data: { pitches: [[0, 3, 0]], dur: Time.newSpan(1, 4) }});

        const res2 = load("<d, fis, a,>128", {startRule: 'MusicElement'});

        expect(res2).to.deep.eq({type: 'Note', data: { 
            pitches: [
            [1, 2, 0],
            [3, 2, 1],
            [5, 2, 0]
        ], dur: Time.newSpan(1, 128) }});

        const res2a = load("<d,>16 ", {startRule: 'MusicElement'});

        expect(toNote(res2a)).to.deep.eq(new Note([
            new Pitch(1, 2, 0),
        ], Time.newSpan(1, 16)));

        const res3 = load("e2. ", {startRule: 'MusicElement'});
        const note3 = new Note([new Pitch(2, 3, 0)], Time.newSpan(3, 4));
        expect(toNote(res3)).to.deep.eq(note3);

        const res4 = load("fisis1~ ", {startRule: 'MusicElement'});
        const note4 = new Note([new Pitch(3, 3, 2)], Time.newSpan(1, 1));
        note4.tie = true;
        expect(toNote(res4)).to.deep.eq(note4);

    });

    it('should parse a rest', () => {

        const res1 = load("r4", {startRule: 'MusicElement'});

        expect(res1).to.deep.eq( {type: 'Note', data: { pitches: [], dur: Time.newSpan(1, 4) }});

        /*const res2 = load("<d, fis, a,>2 ", {startRule: 'MusicElement'});

        expect(res2).to.deep.eq({type: 'Note', data: { 
            pitches: [
            [1, 2, 0],
            [3, 2, 1],
            [5, 2, 0]
        ], dur: Time.newSpan(1, 2) }});

        const res2a = load("<d,>2 ", {startRule: 'MusicElement'});

        expect(toNote(res2a)).to.deep.eq(new Note([
            new Pitch(1, 2, 0),
        ], Time.newSpan(1, 2)));

        const res3 = load("e2. ", {startRule: 'MusicElement'});
        const note3 = new Note([new Pitch(2, 3, 0)], Time.newSpan(3, 4));
        expect(toNote(res3)).to.deep.eq(note3);

        const res4 = load("fisis1~ ", {startRule: 'MusicElement'});
        const note4 = new Note([new Pitch(3, 3, 2)], Time.newSpan(1, 1));
        note4.tie = true;
        expect(toNote(res4)).to.deep.eq(note4);
*/
    });

    it('should parse a clef', () => {
        const res1 = load("\\clef treble ", {startRule: 'MusicElement'});

        expect(res1).to.deep.eq({ type: 'Clef', data: { clefType: ClefType.G, line: -2 }});

    });

    it('should parse a key', () => {
        const res1 = load("\\key d \\major ", {startRule: 'MusicElement'});

        expect(res1).to.deep.eq({ type: 'Key', data: { pitch: [1, 3, 0], mode: '\\major'}}) ;

    });

    it('should parse a meter change', () => {
        const res1 = load("\\time 3/4 ", {startRule: 'MusicElement'});

        expect(res1).to.deep.eq({ type: 'RegularMeter', data: { count: 3, value: 4 }});

    });


    it('should parse a sequence', () => {
        const res = load("{c4 d e f }") as any;

        expect(res.type).to.eq('SimpleSequence');

        expect(res.data.map((elm: any) => toNote(elm))).to.deep.eq(
            new SimpleSequence('c4 d4 e4 f4').elements
        );

    });

    it('should parse a note, key, clef, meter without trailing space', () => {
        const res = load("{c4 d e f}") as any;

        expect(res.type).to.eq('SimpleSequence');
        expect(res.data[3].type).to.eq('Note');
        expect(res.data[3].data.pitches).to.deep.eq([[3, 3, 0]]);
    });

    it('should parse a variable definition, even beginning with a note name', () => {
        const res = load("candle = {c4 d e}", {startRule: 'File'}) as any;

        expect(res).to.have.length(1);
        expect(res[0].type).to.eq('VarDef');
    });

    it('should parse a score', () => {

        const score = `\\score 
            {
              
                \\new Staff <<
                  
                  \\clef treble
        c4 d e
          >> % End Staff = RH

                  }  `;


        const res = load(score, {startRule: 'File'}) as FileItemLy[];

        expect(res).to.have.length(1);

        const sc = res[0];
        expect(sc.type).to.eq('Score');

        const sts = (sc as ScoreDefLy).data.staves;
        expect(sts).to.have.length(1);
        
        const st = sts[0];
        expect(st.type).to.eq('Staff');
        expect(st.data).to.have.length(4);

        expect(st.data[1]).to.deep.eq({
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
          }  % End score`;



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
         
         
         
         
         
// Simple Arithmetics Grammar
// ==========================
//
// Accepts expressions like "2 * (3 + 4)" and computes their value.

File
  = Statement*
  
Statement
  = Note
  / Assignment

Expression
  = "{" Note* "}"
  
Identifier
  = [a-zA-Z]+

Assignment
  = i:Identifier _ "=" _ e:Expression { return { type: 'assignment', 'var': i, ex: e }; }

Note
  = n:[a-g] ![a-zA-Z] _ { return {type: 'note', value: n}; }

_ "whitespace"
  = [ \t\n\r]*         
         
         */


    });       

});
