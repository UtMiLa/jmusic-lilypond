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

	const noteModule = require('../../../jmusic-model/src/model/index.ts');	

	var lastTime = noteModule.Time.newSpan(1, 4);
  function theTime(d){
   	if (d) { 
        /*if (d.dur == "\\brevis") {
        	lastTime = { numerator: 2, denominator: 1, type: 'span' };
        } else {
	        let dur = d.dur.join("");
        	lastTime = { numerator: 1, denominator: +dur, type: 'span' };
        }*/
		lastTime = noteModule.Time.fromLilypond(d);
      }
    return lastTime; //{ numerator: lastTime.num, denominator: lastTime.den, type: 'span' };
	//noteModule.Time.newSpan(1, 4)
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
  s:[ \t\n\r]+ { return undefined; } 
  
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
	= "{" __ t:ScoreThings* "}" { return t; }
ScoreThings
	= "\\new" _ "Staff" _ m:Music __ { return {
		t: "Staff",
		def: {},
		children: [m]
	}; }
Music
	= Sequence /
    "{" __ "<<" __ StaffExpression* ">>" __ "}" /
    variable: VariableRef
Sequence
	= "{" __ notes:MusicElement* __ "}" { 
		const res = new noteModule.SimpleSequence('');
		notes.forEach(note => {
			res.addElement(note);
		});
		return res;
	/*{
			t: "Sequence",
			def: {
				stem: "dir"
			},
			children: notes.reverse() // kommer underligt nok i omvendt rækkefølge
		};*/
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
    Sequence /
    Music
VariableRef
	= "\\" name:[a-zA-Z]+ __ { return { t: "Variable", def: {name: name.join('')}}; }
Command
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
	= "\\clef" _ s:[a-zA-Z]+ _ { return noteModule.parseLilyClef('\\clef ' + s.join('')) } 
    
KeyDef "command_event_key"
	= "\\key" _ s:Pitch _ m:Mode _ { return noteModule.parseLilyKey('\\key ' + s.pitchClass.pitchClassName + ' ' + m) }
    
Mode
	= "\\major" / "\\minor"
    
TimeDef "command_element_time"
	= "\\time" _ s:Integer "/" d:Integer _ { 
	//return {"t":"Meter","def":{"abs":{"num":0,"den":1},"def":{"t":"Regular","num":s,"den":d}}};
	return noteModule.parseLilyMeter('\\time ' + s + '/' + d);
	}
    
StaffExpression
	= "\\new" _ "Staff" __ m:Music __ { return m }     
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
		var note = new noteModule.Note([p], lastDur);
        if (tie) note.tie = true;
		return note;
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
		var note = new noteModule.Note(pitches, noteModule.Time.newSpan(1, 4));
		return note;  /*{
					t: "NoteCh",
					def: {
						time: lastDur,
						noteId: "n" + lastDur.num + "_" + lastDur.den,
                        dots: d && d.dots ? d.dots.length : undefined,
                        tuplet: d ? d.mul : undefined
					},
                    n: n,
					children: childItems
					};*/ }
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
					return new noteModule.Pitch(['c', 'd', 'e', 'f', 'g', 'a', 'b'].indexOf(pit), octave, alteration);
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
    