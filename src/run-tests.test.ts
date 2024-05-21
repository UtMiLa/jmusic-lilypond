import { FileItemLy, ScoreDefLy } from './intermediate-ly';
import { expect } from 'chai';
import { load } from './import-lilypond';
import { opendir, readFile, readFileSync } from 'fs';
import * as R from 'ramda';

describe('Run all tests from files', () => {

    function expectParse(input: string, startRule: string, expectedObj: object, ident?: string) {
        if (!ident) ident = input;
        const res = load(input, { startRule });
        expect(res, ident).to.deep.eq(expectedObj);
    }

    function newSpan(x: number, y: number) {
        return { numerator: x, denominator: y, type: 'span' };
    }

    function runItem(content: string[]) {
        const name = R.head(content);
        const values = R.splitWhenever(item => /\*{10}/.test(item), R.tail(content)); 
        console.log(name, values.length);
        if (values.length === 2)
        expectParse(values[0].join('\n'), 'File', JSON.parse(values[1].join('\n')), name);
    }

    function runfile(content: string) {
        const items = R.splitWhenever(item => /#{10}/.test(item), content.split(/[\r\n]+/));
        items.forEach(runItem);
    }

    it('should parse a pitch', (done) => {
        opendir('./tests', async (err, dir) => {
            if (err) throw(err);

            try{
                for await (const dirent of dir) {
                    const content = readFileSync('./tests/' + dirent.name, 'utf8');
                    //, (err, ) => {
                        //if (err) throw(err);
                        runfile(content);
                    //});
                    
                }
            } catch (e) {
                done(e);
            }

            done();
        });
    });
});