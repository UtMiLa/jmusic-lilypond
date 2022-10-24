import { expect } from 'chai';
import { add, load } from './start';

describe('Physical model, meter', () => {

    /*beforeEach(() => { 
    });*/


    it('should add 2 numbers', () => {
        const res = add(4, 5);

        expect(res).to.eq(10);

    });

    it('should parse lilypond', () => {
        const res = load("{c4 d e f}");

        expect(res).to.eq([{
            mus: {
                t: 'Sequence',
                def: {
                    stem: 'dir'
                },
                children: []
            }
        }]);

    });
});
