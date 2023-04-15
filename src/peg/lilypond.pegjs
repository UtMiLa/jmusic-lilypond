/*
node ..\node_modules\pegjs\bin\pegjs -o .\peg\lilypond.js .\peg\lilypond.pegjs
copy .\peg\lilypond.js .\dist\jMusic\peg\lilypond.js 

Todo:

parse [ ] efter node
s1*7/8
variable
\modalTranspose og \transpose
\time

*/
{

	function parseLilyMeter(ly, pm) {
		const tokens = ly.split(' ');
		if (tokens.length !== 2 || !/^\d+\/\d+$/.test(tokens[1])) throw 'Illegal meter change: ' + ly;

		const [count, value] = tokens[1].split('/');
        
        if (pm) {
        	return { count: +count, value: +value, upbeat: timeFromLilypond(pm) };
        }

		return { count: +count, value: +value };
	}

	function parseLilyClef(ly) {
		ly = ly.replace('\\clef ', '');
		switch(ly) {
			case 'G': case 'G2': case 'violin': case 'treble': case 'soprano': return { clefType: 'g', line: -2 };
			case 'treble_8': case 'tenorG': return { clefType: 'g', line: -2, transpose: -7 };
			case 'tenor': return { clefType: 'c', line: 2 };
			case 'F': case 'bass': return { clefType: 'f', line: 2 };
			case 'C': case 'alto': return { clefType: 'c', line: 0 };
		}
		throw 'Illegal clef: ' + ly;
	}


	var lastTime =  { numerator: 1, denominator: 4, type: 'span' };


    function timeFromLilypond(input) {
        const matcher = /(\d+)(\.*)/;
        const parsed = matcher.exec(input);
        if (!parsed) throw 'Illegal duration: ' + input;
        let numerator = 1;
        let denominator = +parsed[1];

        parsed[2].split('').forEach(char => {
            if (char === '.') {
                numerator = numerator * 2 + 1;
                denominator *= 2;
            }
        });

        //console.log(parsed, numerator, denominator);
        return { numerator: numerator, denominator: denominator, type: 'span' };		
    }


  function theTime(d){
   	if (d) { 
        /*if (d.dur == "\\brevis") {
        	lastTime = { numerator: 2, denominator: 1, type: 'span' };
        } else {
	        let dur = d.dur.join("");
        	lastTime = { numerator: 1, denominator: +dur, type: 'span' };
        }*/
		lastTime = timeFromLilypond(d);
      }
    return lastTime; //{ numerator: lastTime.num, denominator: lastTime.den, type: 'span' };
	
  } 	

}

/* top level expressions */

File
	= ex:Expression * { return ex.filter(x => x); }
    
Expression
  = version:Version /
  include:Include /
  header: Header /
  relative: Relative /
  score:Score /
  things: ScoreThings /
  music: Music { return {mus: music}; } /
  notes: MusicElement+ { return {n: notes}; } /
  comment:Comment { return { type:"Comment", data: comment}; }  /
  variableDef:VariableDef { return variableDef; } /
  sch: SchemeStuff /
  s:[ \t\n\r]+ { return undefined; }

/* rest is sorted alphabetically */

_ "whitespace"
  = s:(WhitespaceItem+) { return undefined; }
  
__ "optional_whitespace"
	= s:(WhitespaceItem*) { return undefined; }
Chord
	= "<" __ n:(Pitch MultiPitch*) __ ">" d:Duration? tie:"~"? __ Markup? { 
		var lastDur = theTime(d);
		var pitches = [n[0]].concat(n[1]);
		
		/*if (tie) {
			n[0].tie  = true;
		}
		var childItems = [n[0]];
		for (var i = 0; i < n[1].length; i++) {
			if (tie) {
				n[1][i].tie  = true;
			}
			childItems.push(n[1][i]); 
		}*/

		var res = { type: 'Note', data: { dur: lastDur, pitches: pitches.map(p =>p.data) } };
		if (tie) res.data.tie = true;
		return res;		
		
	}
Command "notecommand"
	= "\\numericTimeSignature" _ { return { type: 'Command', subType: 'NumericTimeSignature' }; }/
    "[" __ { return { type: 'Command', subType: 'BeginBeam' }; }/
    "]" __ { return { type: 'Command', subType: 'EndBeam' }; }/
    "\\(" __ { return { type: 'Command', subType: 'BeginPhrase' }; }/
    "\\)" __ { return { type: 'Command', subType: 'EndPhrase' }; }/
    "(" __ { return { type: 'Command', subType: 'BeginSlur' }; }/
    ")" __ { return { type: 'Command', subType: 'EndSlur' }; }/
    "|" __ { return { type: 'Command', subType: 'ForceBar' }; }/
    "\\arpeggio" __ { return { type: 'Command', subType: 'Arpeggio' }; }
    / "\\tempo" _ String _ [0-9]+ __ "=" __ [0-9]+ __ { return { type: 'Command', subType: 'Tempo' }; }
Comment =
	"%" c:([^\n]*) "\n" { return { "Comment": c.join('') }; }
ClefDef "command_element_clef"
	= "\\clef" _ s:Identifier _ { return { type: 'Clef', data: parseLilyClef('\\clef ' + s) }; } 
Dots 
	= "."+
Duration
	= d:(DurationNumber / "\\brevis") dot:Dots? mul:Multiplier? { return d + (dot ? dot.join('') : ''); }   
DurationNumber
	= d:[0-9]+ ![0-9] { return d.join('') }    

Header
    = "\\header" __ "{" _ hd:HeaderDeclaration* "}"
    / "\\paper" _ "{" __ ([a-z-]+ __ "=" __ [0-9]+ __)* "}"
HeaderDeclaration
	= v:Identifier __ "=" __ s: String _
    / v:Identifier __ "=" __ s: MarkupDeclaration
Identifier
	= String /
    id:[a-zA-Z]+ { return id.join(''); }
Include
	= version:"\\include" _ s:String {
  	return { include: s }
    }    
Inflection
	= "s" / "f" / "isis" / "eses" / "is" / "es"
Integer
	= n:[0-9]+ { return +n.join(''); }
KeyDef "command_event_key"
	= "\\key" _ s:Pitch _ m:Mode _ { return { type: 'Key', data: { pitch: s.data, mode: m } }; }
    
LayoutDef
	= "\\layout" __ MarkupDefinition
LyricMode
	= "\\lyricmode" __ "{" __ LyricSyllable* "}"
LyricSyllable
	= [a-zA-ZæøåÆØÅüÜßöÖäÄ\.,?;!’': ]+ __
    / "--" _
    / "__" _
    / "_" _
Markup
	= "^" MarkupDeclaration __
    / "^" s:String __
    / "--" __
    / "-." __
    / "-!" __

MarkupSymbol
	= "\\sharp" / "\\natural" / "\\flat"
MarkupDeclaration
	= "\\markup" __ MarkupDefinition __
MarkupDefinition
	= "{" __ MarkupDefinitionItem* __ "}"
MarkupDefinitionItem
	= [^{}]
    / MarkupDefinition __
MidiDef
	= "\\midi" __ MarkupDefinition
Mode
	= "\\major" / "\\minor"
MultiPitch
	= _ p:Pitch { return p; }
    
Music
	= SequenceDelimited /
    "{" __ "<<" __ StaffExpression* ">>" __ "}" /
    "{" __ "<<" __ PianoStaffExpression* ">>" __ "}"

MusicElement
	= Note /
    Rest /
    NotYetSupported /
    transpose: TransposeFunction /
    repeat: RepeatFunction /
    Chord /
    ClefDef /
    KeyDef /
    TimeDef /
    Command /
    SequenceDelimited /
    Music /
    variable: VariableRef
MusicParam
	= Music
    / "{" __ Music __ "}" _
    / VariableRef
Note 
	= p:Pitch d:Duration? tie:(__ "~")? ![a-zA-Z0-9] __ Markup? { 
   		var lastDur = theTime(d);
		var res = { type: 'Note', data: { dur: lastDur, pitches: [p.data] } };
		if (tie) res.data.tie = true;
		return res;
	}
		//				time: lastDur,
		//				noteId: "n" + lastDur.num + "_" + lastDur.den,
        //                dots: d && d.dots ? d.dots.length : undefined,
        //                tuplet: d ? d.mul : undefined
		//			},
		//
NotYetSupported
	= "\\<" __
    / "\\!" __
    / "\\>" __
    / "\\bar" __ String
    / "<<" __ (Music __)+ __ ">>" __
    / "<<" __ Music __ ("\\new Voice" __ Music __)+ __ ">>" __
    / "\\override" _ [a-zA-Z.-]+ __ "=" __ String __
Multiplier
	= "*" num:Integer "/" den:Integer { return {num:num, den:den}; }
	/ "*" num:Integer { return {num:num, den:1}; }
Octave "sup_quotes_sub_quotes"
	= s:[\',]* { return s.join(""); }
Pitch "pitch"
	= pit:[a-h] i:Inflection? o:Octave forceAccidental: "!"? tie:"~"? ![a-zA-Z] { 
				    var alteration = 0;
					switch (i) {
                        case "is": alteration = 1; break;
                        case "isis": alteration = 2; break;
                        case "es": case "s": alteration = -1; break;
                        case "eses": case "ses": alteration = -2; break;
                    }
                    var octave = 3;
                    for (var i = 0; i < o.length; i++) {
                    	switch(o[i]){
                        	case "'": octave ++; break;
                        	case ",": octave --; break;
                        }
                    }
					return {
						type: 'Pitch',
						data: [['c', 'd', 'e', 'f', 'g', 'a', 'b'].indexOf(pit.replace('h', 'b')), octave, alteration]
					};
				}

    
Partial
	= '\\partial' _ pd:Duration _ 
    
PianoStaffExpression
    = "\\new" _ "PianoStaff" __ "<<" __ s:StaffExpression+ __ ">>" _ { return { type: "StaffGroup", data: s } }

Relative "relative_music"
	= rel:"\\relative" _ s:Note __ m: Music {
  	return { rel: s, mus: m }
    }	
RepeatFunction
	= "\\repeat" _ "unfold" _ no:[0-9]+ _ MusicParam __ {return {"t": "repeat"}; }
Rest
	= [rsR] o:Octave d:Duration? ![a-zA-Z] __ Markup? { 
		var lastDur = theTime(d);
        var mul;
		return {
                  type: "Note",
                  data: {
                     dur: lastDur,
                     pitches: []
                  }
               };
		}

SchemeStuff
	= "#(" SchemeInternal ")"
SchemeToken
	= [-a-zA-Z0-9]+ __
    / "(" SchemeInternal ")"
SchemeInternal
	= SchemeToken*
Score
	= "\\score" __ m:ScoreMusic { 
		var res = {
			type: "Score",
			data: {
            	staves: m
			}
		};
		return res;
	}
ScoreMusic
	= "{" __ t:ScoreThings* "}" __ { return t; }
    / "{" __ "<<" __ t:ScoreThings* __ ">>" __ "}" __ { return t; }
ScoreThings
	= s:StaffExpression __ { return s; } /
    p:PianoStaffExpression __ { return p; } /
    sg:StaffGroupExpression __ {return sg; } /
    MidiDef __ /
    LayoutDef __
Sequence
	= __ notes:MusicElement* __ { 
		return { type: 'SimpleSequence', data: notes };
	}
SequenceDelimited
	= "{" __ seq:Sequence __ "}" __ { 
		return seq;
	}
StaffExpression
	= "\\new" _ "Staff" __ m:Music __ { return { type: "Staff", data: m }; }
    / "\\new" _ "Staff" __ "<<" __ m:StaffThings* __ ">>" __ { return { type: "Staff", data: m }; }
StaffGroupExpression
	= "\\context" _ "StaffGroup" __ "<<" __ s:StaffExpression+ __ ">>" _ { return { type: "StaffGroup", data: s } }
StaffThings
	= "\\new" _ "Voice" __ "=" __ Identifier __ "<<" __ m:Sequence __ ">>" _ { return { type: 'Voice', data: { content: m } } }
    / m:MusicElement { return m }
String
	= "\"" s:StringChar* "\"" { return s.join(""); }
StringChar
	= StringEscape c:. { return c; }
    /
    c:[^"] { return c }

StringEscape
	= "\\"

TimeGroupList
	= "#'(" (Integer __)* ")" __
TimeDef "command_element_time"
	= "\\time" _ TimeGroupList? s:Integer "/" d:Integer _ pm:Partial? {
	return { type: 'RegularMeter', data: parseLilyMeter('\\time ' + s + '/' + d, pm) };
	}    
TransposeFunction
    = "\\transpose" _ Pitch _ Pitch _ MusicParam _ /
    "\\modalTranspose" _ Pitch _ Pitch _ Music _ MusicParam _
    
VariableDef
  = v:Identifier __ '=' __ "{" __ LyricMode __ "}"
  / v:Identifier _ '=' _ s:SequenceDelimited { return { type: 'VarDef', data: { identifier: v, value: s } }}
  / v:Identifier _ '=' _ "\\" v2:Identifier { return { type: 'VarDef', data: { identifier: v, variable: v2 } }}
  / v:Identifier _ '=' _ NotYetSupported
VariableRef
	= "\\" name:[a-zA-Z]+ __ { return { type: "Variable", data: {name: name.join('')}}; }
Version
	= version:"\\version" _ s:String {
  		return { type: 'Metadata', version: s }
    }

WhitespaceItem
	= [ \t\n\r]+
    / Comment
    