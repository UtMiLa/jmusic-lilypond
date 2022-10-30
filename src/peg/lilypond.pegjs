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
	var ClefType = {
		G: 4,
		C: 0,
		F: -4,
		G8: -3
	};

	function parseLilyMeter(ly) {
		const tokens = ly.split(' ');
		if (tokens.length !== 2 || !/^\d+\/\d+$/.test(tokens[1])) throw 'Illegal meter change: ' + ly;

		const [count, value] = tokens[1].split('/');

		return { count: +count, value: +value };
	}

	function parseLilyClef(ly) {
		ly = ly.replace('\\clef ', '');
		switch(ly) {
			case 'G': case 'G2': case 'violin': case 'treble': return { clefType: ClefType.G, line: -2 };
			case 'tenorG': return { clefType: ClefType.G8, line: -2 };
			case 'tenor': return { clefType: ClefType.C, line: 2 };
			case 'F': case 'bass': return { clefType: ClefType.F, line: 2 };
			case 'C': case 'alto': return { clefType: ClefType.C, line: 0 };
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



File
	= ex:Expression * { return ex; }
    
Expression
  = version:Version /
  include:Include /
  relative: Relative /
  score:Score /
  things: ScoreThings /
  music:Music { return {mus: music}; } /
  notes:MusicElement+ { return {n: notes}; } /
  comment:Comment { return {t:"Comment", def: comment}; }  /
  variableDef:VariableDef
  s:[ \t\n\r]+ { return undefined; } 
Identifier
	= String /
    id:[a-zA-Z]+ { return id.join(''); }
VariableDef
  = v:Identifier _ '=' _ SequenceDelimited { return v }
TransposeFunction
    = "\\transpose" _ Pitch _ Pitch _ Music _ /
    "\\modalTranspose" _ Pitch _ Pitch _ Music Music _
RepeatFunction
	= "\\repeat" _ "unfold" _ no:[0-9]+ _ Music {return {"t": "repeat"}; }
Score
	= "\\score" _ m:ScoreMusic { 
		var res = {
			t: "Score",
			def: {
				title: "t",
				composer: "c",
				author: "a",
				subTitle: "s",
				metadata: {}
			},
			children: m
		};
		return res;
	}
ScoreMusic
	= "{" __ t:ScoreThings* "}" __ { return t; }
ScoreThings
	= StaffExpression /
    PianoStaffExpression
StaffExpression
	= "\\new" _ "Staff" __ m:Music __ { return m }
    / "\\new" _ "Staff" __ "<<" _ m:StaffThings* __ ">>" __ { return m }
StaffThings
	= "\\new" _ "Voice" __ "=" __ Identifier __ "<<" __ m:Sequence __ ">>" _ { return m }
    / m:MusicElement { return m }
PianoStaffExpression
    = "\\new" _ "PianoStaff" __ "<<" _ StaffExpression+ __ ">>" _
Music
	= SequenceDelimited /
    "{" __ "<<" __ StaffExpression* ">>" __ "}" /
    "{" __ "<<" __ PianoStaffExpression* ">>" __ "}"
Sequence
	= __ notes:MusicElement* __ { 
		return { type: 'SimpleSequence', data: notes };
	} 
SequenceDelimited
	= "{" __ seq:Sequence __ "}" { 
		return seq;
	} 
MusicElement
	= Note /
    Rest /
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
VariableRef
	= "\\" name:[a-zA-Z]+ __ { return { t: "Variable", def: {name: name.join('')}}; }
Command "notecommand"
	= "\\numericTimeSignature" _ /
    "[" __ /
    "]" __ /
    "\\(" __ /
    "\\)" __ /
    "(" __ /
    ")" __ /
    "|" __ /
    "\\arpeggio" __
Comment =
	"%" c:([^\n]*) "\n" { return { "Comment": c.join('') }; }
ClefDef "command_element_clef"
	= "\\clef" _ s:Identifier _ { return { type: 'Clef', data: parseLilyClef('\\clef ' + s) }; } 
    
KeyDef "command_event_key"
	= "\\key" _ s:Pitch _ m:Mode _ { return { type: 'Key', data: { pitch: s.data, mode: m } }; }
    
Mode
	= "\\major" / "\\minor"
    
TimeDef "command_element_time"
	= "\\time" _ s:Integer "/" d:Integer _ { 
	//return {"t":"Meter","def":{"abs":{"num":0,"den":1},"def":{"t":"Regular","num":s,"den":d}}};
	return { type: 'RegularMeter', data: parseLilyMeter('\\time ' + s + '/' + d) };
	}
    
Rest
	= [rs] o:Octave d:Duration? __ { 
		var lastDur = theTime(d);
        var mul;
		return {
                    t: "NoteRest",
					def: {
						time: lastDur,
						noteId: "n" + lastDur.num + "_" + lastDur.den,
                        dots: d && d.dots ? d.dots.length : undefined,
                        rest: true,
                        tuplet: d ? d.mul : undefined
					},
					children: []
				}
		}
Note 
	= p:Pitch d:Duration? tie:"~"? __ { 
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
Chord
	= "<" n:(Pitch MultiPitch*) ">" d:Duration? tie:"~"? __ { 
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
MultiPitch
	= _ p:Pitch { return p; }
Duration
	= d:([0-9]+ / "\\brevis") dot:Dots? mul:Multiplier? { return /*{ dur: d, dots: dot, mul: mul }*/ d + (dot ? dot.join('') : ''); }    
Dots 
	= "."+
Multiplier
	= "*" num:Integer "/" den:Integer { return {num:num, den:den}; }
	/ "*" num:Integer { return {num:num, den:1}; }
Pitch "pitch"
	= pit:[a-h] i:Inflection? o:Octave tie:"~"? { 
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
						data: [['c', 'd', 'e', 'f', 'g', 'a', 'b'].indexOf(pit), octave, alteration]
					};
				}
Inflection
	= "s" / "f" / "isis" / "eses" / "is" / "es"
    
Octave "sup_quotes_sub_quotes"
	= s:[\',]* { return s.join(""); }
    
Relative "relative_music"
	= rel:"\\relative" _ s:Note __ m: Music {
  	return { rel: s, mus: m }
    }
Version
	= version:"\\version" _ s:String {
  	return { version: s }
    }
Include
	= version:"\\include" _ s:String {
  	return { include: s }
    }    
String
	= "\"" s:StringChar* "\"" { return s.join(""); }
Integer
	= n:[0-9]+ { return +n.join(''); }
StringChar
	= StringEscape c:. { return c; }
    /
    c:[^"] { return c }

StringEscape
	= "\\"

_ "whitespace"
  = s:(WhitespaceItem+) { return " " }
  
__ "optional_whitespace"
	= s:(WhitespaceItem*) { return {"WS": s}; }

WhitespaceItem
	= [ \t\n\r]+
    / Comment
    