import { Alteration, BaseSequence, Clef, ClefDef, ClefType, CompositeSequence, DiatonicKey, ISequence, Key, Meter, MeterFactory, Note, NoteDirection, Pitch, ScoreDef, SequenceDef, SimpleSequence, StaffDef, Time, VoiceDef, createNote } from 'jmusic-model/dist/model';
import { StateChange } from 'jmusic-model/dist/model/states/state';
import { MusicElementDefLy, PitchDefLy, FileItemLy, ScoreDefLy, VarDefLy, StaffDefLy, VoiceDefLy, SequenceDefLy, VariableDefLy, ShortPitchDefLy, SimpleSequenceDefLy, StaffThingLy, ClefDefLy } from './intermediate-ly';
import {parse} from './peg/lilypond';

export function load(ly: string, settings?: { startRule: string }): FileItemLy[] | MusicElementDefLy | PitchDefLy {
    return parse(ly, settings);
}



/* 
Todo:

\partial 8 (upbeat)
ok: g16 should be 1/16, not 1/1
ok: sequence in sequence {c d e { f g }}
timeline in voice should be separate from following music (why?)
variables in quotes
ok: rests
ok: don't parse variable definitions as note variable (global => g lobal), and don't require space after note
	between note and variable must be whitespace
	whitespace not needed before variable (in beginning of document)
	whitespace not needed after note (before sequence terminator)
use \voiceOne etc to set note direction
ok: accept simultaneous key/clef/meter changes, if they are identical

\time #'(4 3) 7/8
f']~

r1*7/4  r1*7/4
basOstinatTo = \basOstinatEt
QuiTollisOstinatEt = << {<g d'>2 <f d'>
 \< 
 \!
 
 a,4.^\markup{\natural} a,2
 
 
sopranGlorytxt = { \lyricmode {
    Glo -- ry to the Lord,
    glo -- ry to the Lord,
	
	
sopranToGlory = { \repeat unfold 11 \fullRest }	
\relative c'{ 

\new ChoirStaff <<

\new Staff \with { 
	instrumentName = "Sopran solo" 
	shortInstrumentName = \markup {
      \center-column { "S"
        \line { "solo" }
      }
    }
*/

class LilypondConverter {
	constructor(private score: ScoreDef, private variables: VarDefLy[]) {}


	convertPitch(pitch: ShortPitchDefLy): Pitch {
		return new Pitch(pitch[0], pitch[1], pitch[2] as Alteration);
	}

	convertClefType(ly: string): ClefType {
		switch(ly) {
			case 'g': return ClefType.G;
			case 'c': return ClefType.C;
			case 'f': return ClefType.F;
			//case 'perc': return ClefType.;
		}
		throw `Cleftype ${ly} not implemented`;
	}

	convertClefDef(ly: ClefDefLy): ClefDef {
		return { clefType: this.convertClefType(ly.data.clefType), line: ly.data.line };
	}

	convertMusicElement(seqElm: MusicElementDefLy): Note | StateChange {
		switch (seqElm.type) {
			case 'Clef': 
				console.log('Clef: ', seqElm);
				return { isState: true, duration: Time.NoTime, clef: new Clef(this.convertClefDef(seqElm)) } as StateChange;
				
			case 'Key': 
				console.log('Key: ', seqElm);
				return { 
					isState: true, 
					duration: Time.NoTime, 
					key: DiatonicKey.fromMode(this.convertPitch(seqElm.data.pitch).pitchClass, seqElm.data.mode.replace('\\', ''))
				} as StateChange;
				

			case 'RegularMeter':
				console.log('Meter: ', seqElm);
				return { isState: true, duration: Time.NoTime, meter: MeterFactory.createRegularMeter(seqElm.data) } as StateChange;
				
			case 'Note': 
				//console.log('Note: ', seqElm);
				return createNote(seqElm.data.pitches.map(p => this.convertPitch(p)), seqElm.data.dur);
				
			default: 
				console.error('Illegal element: ', seqElm);
				throw 'Illegal element';
		}

	}

	convertSimpleSequence(seqIn: SequenceDefLy): ISequence {
		const res = new SimpleSequence('');
		seqIn.data.forEach(seqElm => {
			switch (seqElm.type) {
				case 'Clef': 
				case 'Key': 
				case 'RegularMeter':
				case 'Note': 
					res.addElement(this.convertMusicElement(seqElm));
					break;
				/*case 'Function': 
					console.log('Resolving function: ', seqElm);				
					break;*/
				case 'Variable': {
					if (/^voice(One|Two|Three|Four)/.test(seqElm.data.name)) {
						break; // todo: stem directions!
					}
					const resolved = this.resolveVariable(seqElm);
					if (resolved.data.value.type === 'SimpleSequence') {
						const varSeq = this.convertSimpleSequence(resolved.data.value);
						varSeq.elements.forEach(elm => res.addElement(elm));
					/*} else if (resolved.data.value.type === 'Function') {

						const funcSeq = this.convertSimpleSequence((resolved.data.value.data as any)[2]);
						funcSeq.elements.forEach(elm => res.addElement(elm));
						console.log('Resolved function: ', resolved.data);*/
					} else {
						console.log('Resolved: ', resolved);
					}
					
				}
					break;


				case 'SimpleSequence': {
					
					const internalSequence = this.convertSimpleSequence(seqElm as SimpleSequenceDefLy); 
					
					internalSequence.elements.forEach(elm => res.addElement(elm));
				}
					break;		
				case 'Command': case 'Metadata': {
					// ignore for now
				}
					break;
				default: 
					console.error('Illegal element: ', seqElm);
					throw 'Illegal element';
			}
		});
		return res;
	}

	private resolveVariable(seqElm: VariableDefLy) {
		const resolved = this.variables.find(vd => vd.data.identifier === seqElm.data.name);
		if (!resolved)
			throw "Variable not found: " + seqElm.data.name;
		return resolved;
	}

	convertVoice(voiceIn: VoiceDefLy, voiceNo: number, initialSequence?: ISequence): VoiceDef {
		if (voiceIn.data.content.type === 'SimpleSequence') {
			if (initialSequence) {
				return {
					contentDef: new CompositeSequence(initialSequence, this.convertSimpleSequence(voiceIn.data.content)).asObject,
					noteDirection: voiceNo % 2 ? NoteDirection.Up : NoteDirection.Down
				};
			}
			return {
				contentDef: this.convertSimpleSequence(voiceIn.data.content).asObject,
				noteDirection: voiceNo % 2 ? NoteDirection.Up : NoteDirection.Down
			};
		}
		return {
			contentDef: new SimpleSequence("c'4 d'4 e'4 f'4").asObject,
			noteDirection: voiceNo % 2 ? NoteDirection.Up : NoteDirection.Down
		};
	}

	convertStaff(staffIn: StaffDefLy): StaffDef {
		console.log(staffIn);
		const initialSequence = new SimpleSequence('');
		const voices = [{
			contentDef: initialSequence.asObject
		}] as VoiceDef[];
		let voiceNo = 0;
		staffIn.data.forEach(staffThing => {
			if (staffThing.type === 'Voice') {
				voiceNo++;
				if (voiceNo > voices.length) {
					voices.push(this.convertVoice(staffThing as VoiceDefLy, voiceNo));
				} else {
					voices[0] = this.convertVoice(staffThing as VoiceDefLy, voiceNo, initialSequence);
				}
			} else if (voiceNo === 0) {
				switch (staffThing.type) {
					case 'Clef': case 'Key': case 'Note': case 'RegularMeter':
					initialSequence.addElement(this.convertMusicElement(staffThing));
					break;
					case 'Variable': {
						const resolved = this.resolveVariable(staffThing);
						if (resolved.data.value.type === 'SimpleSequence') {
							const varSeq = this.convertSimpleSequence(resolved.data.value);
							varSeq.elements.forEach(elm => initialSequence.addElement(elm));
						} else {
							console.log('Resolved: ', resolved);
						}
	
					}
				}
			}
		});
		return {
				initialClef: { clefType: ClefType.G, line: -2 },
				initialKey: { accidental: 0, count: 0 },
				initialMeter: { count: 4, value: 4 },
				voices
			} as StaffDef;
	}
	
}


export function lilypondToJMusic(ly: string): ScoreDef {
	const variables = [] as VarDefLy[];
	let scoreDef: ScoreDef = {
		staves: []	
	};

	const stuff = load(ly + '\n', {startRule: 'File'});
	const fi = stuff as FileItemLy[];
	if (fi.length) {
		fi.forEach(element => {
			if (element.type === 'VarDef') {
				variables.push(element);
			} else {
				console.log(element);
				
				scoreDef = {
					staves: []
				}

				const converter = new LilypondConverter(scoreDef, variables);

                if (!element.data) {
                    element = { data: { staves: [
                        {
                            type: 'Staff', 
                            data: [{
                                type: 'Voice',
                                data: {
                                    content: {
                                        type: 'SimpleSequence',
                                        data: (element as any).n
                                    }
                                }
                            }]
                        }
                    ]}} as FileItemLy;
                }
				//if (element.type !== 'Score') throw "Wrong element type: " + element.type;
				(element.data as any).staves.forEach((staff: StaffDefLy) => {
					if (staff.type === 'Staff') {
						scoreDef.staves.push(converter.convertStaff(staff));
					} else if (staff.type === 'StaffGroup') {
						staff.data.forEach((staff: StaffThingLy) => {
							scoreDef.staves.push(converter.convertStaff(staff as unknown as StaffDefLy));
	
						});
					}
				});
			}
		});
	}
	return scoreDef;
}