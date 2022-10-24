import * as parser from './peg/lilypond';

export function add(a:number,b: number): number {
    return a+b + 1;
}

export function load(ly: string): unknown {
    return parser.parse(ly);
}

