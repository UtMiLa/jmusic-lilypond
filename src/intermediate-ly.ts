import { ClefDef, RegularMeterDef, TimeSpan } from "jmusic-model/model";

export interface ScoreDefLy {
    type: 'Score',
    data: {
        staves: (StaffDefLy | StaffGroupDefLy)[]
    }
}
export interface StaffDefLy {
    type: 'Staff',
    data: StaffThingLy[]
}

export interface StaffGroupDefLy {
    type: 'StaffGroup';
    data: StaffDefLy[];
}

export type FileItemLy = ScoreDefLy | VarDefLy;

export type StaffThingLy = MusicElementDefLy | VoiceDefLy;

export interface VoiceDefLy {
    type: 'Voice';
    data: { content: SequenceDefLy };
}

export interface VarDefLy {
    type: 'VarDef',
    data: { 
        identifier: string;
        value: SequenceDefLy;
    }
}

export interface VariableDefLy {
    type: 'Variable',
    data: { 
        name: string;
    }
}

export interface MetadataLy {
    type: 'Metadata',
    version?: string;
}

export interface SimpleSequenceDefLy {
    type: 'SimpleSequence';
    data: MusicElementDefLy[];
}

export interface CommandDefLy {
    type: 'Command';
    subType: string;
}

export type SequenceDefLy = SimpleSequenceDefLy;

export type MusicElementDefLy = NoteDefLy | ClefDefLy | KeyDefLy | MeterDefLy | VariableDefLy | SimpleSequenceDefLy | CommandDefLy | MetadataLy | FunctionDefLy;

export interface NoteDefLy {
    type: 'Note';
    data: {
        dur: TimeSpan;
        pitches: ShortPitchDefLy[];
    }
}

export interface ClefDefLyData {
    clefType: 'g' | 'f' | 'c' | 'perc';
    line: number;
    transpose?: number;
}
export interface ClefDefLy {
    type: 'Clef';
    data: ClefDefLyData;
}
export interface KeyDefLy {
    type: 'Key';
    data: {
        pitch: ShortPitchDefLy;
        mode: '\\major' | '\\minor';
    };
}

export interface FunctionDefLy {
    type: 'Function';
    data: any[];
}
export interface MeterDefLy {
    type: 'RegularMeter';
    data: RegularMeterDef;
}
export type ShortPitchDefLy = [number, number, number];

export interface PitchDefLy {
    type: 'Pitch';
    data: ShortPitchDefLy;
}
export interface CommentDefLy {
    type: 'Comment';
    data: string;
}