import { expect } from 'chai';
import { add, load } from './start';
import {Clef, ClefType, Key, MeterFactory, Note, Pitch, SimpleSequence, Time} from '../../jmusic-model/src/model';

describe('Lilypond import', () => {

    /*beforeEach(() => { 
    });*/

    it('should parse a pitch', () => {
        const res1 = load("c", {startRule: 'Pitch'});

        expect(res1).to.deep.eq(new Pitch(0, 3, 0));
        expect(res1).to.deep.eq(Pitch.parseLilypond('c'));

        const res2 = load("c''", {startRule: 'Pitch'});

        expect(res2).to.deep.eq(new Pitch(0, 5, 0));

        const res3 = load("e,", {startRule: 'Pitch'});

        expect(res3).to.deep.eq(new Pitch(2, 2, 0));

        const res4 = load("fis,,", {startRule: 'Pitch'});

        expect(res4).to.deep.eq(new Pitch(3, 1, 1));

        const res5 = load("beses'", {startRule: 'Pitch'});

        expect(res5).to.deep.eq(new Pitch(6, 4, -2));
    });

    it('should parse a note', () => {
        const res1 = load("c4", {startRule: 'MusicElement'});

        expect(res1).to.deep.eq(new Note([new Pitch(0, 3, 0)], Time.newSpan(1, 4)));

        const res2 = load("<d, fis, a,>2", {startRule: 'MusicElement'});

        expect(res2).to.deep.eq(new Note([
            new Pitch(1, 2, 0),
            new Pitch(3, 2, 1),
            new Pitch(5, 2, 0)
        ], Time.newSpan(1, 4)));

        const res2a = load("<d,>2", {startRule: 'MusicElement'});

        expect(res2a).to.deep.eq(new Note([
            new Pitch(1, 2, 0),
        ], Time.newSpan(1, 4)));

        const res3 = load("e2.", {startRule: 'MusicElement'});
        const note3 = new Note([new Pitch(2, 3, 0)], Time.newSpan(3, 4));
        expect(res3).to.deep.eq(note3);

        const res4 = load("fisis1~", {startRule: 'MusicElement'});
        const note4 = new Note([new Pitch(3, 3, 2)], Time.newSpan(1, 1));
        note4.tie = true;
        expect(res4).to.deep.eq(note4);

    });

    it('should parse a clef', () => {
        const res1 = load("\\clef treble ", {startRule: 'MusicElement'});

        expect(res1).to.deep.eq(new Clef({ clefType: ClefType.G, line: -2 }));

    });

    it('should parse a key', () => {
        const res1 = load("\\key d \\major ", {startRule: 'MusicElement'});

        expect(res1).to.deep.eq(new Key({accidental: 1, count: 2}));

    });

    it('should parse a meter change', () => {
        const res1 = load("\\time 3/4 ", {startRule: 'MusicElement'});

        expect(res1).to.deep.eq(MeterFactory.createRegularMeter({ count: 3, value: 4}));

    });


    it('should parse a sequence', () => {
        const res = load("{c4 d e f}") as SimpleSequence;

        expect(res.elements).to.deep.eq(
            new SimpleSequence('c4 d4 e4 f4').elements
        );

    });
});
