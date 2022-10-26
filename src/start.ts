import {parse} from './peg/lilypond';

export function add(a:number,b: number): number {
    return a+b + 1;
}

export function load(ly: string, settings?: { startRule: string }): unknown {
    return parse(ly, settings);
}

