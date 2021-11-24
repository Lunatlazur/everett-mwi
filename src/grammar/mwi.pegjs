{{
  function flatten (commands) {
    const stack = [...commands.map((command) => [command, -1])]
    const result = []
    while(stack.length) {
      const [next, depth] = stack.pop()
      if (Array.isArray(next)) {
        stack.push(...next.map((command) => [command, depth + 1]))
      } else if (next != null) {
        result.push({ ...next, indent: depth })
      }
    }
    return result.reverse()
  }
}}

Program
  = statements:(@__Statement__ NL)*
    statement:__Statement__ EOF {
      return flatten([
        ...statements,
        statement,
        [{ code: 0, parameters: [] }],
      ])
    }

__Statement__
  = __* @Statement? __*

Statement
  = IfStatement
  / ChoicesStatement
  / LoopStatement
  / ProcessBattleStatement
  / CommandStatement

IfStatement
  = ifBlock:ConditionIfBlock
    elseBlock:ConditionElseBlock?
    __End__ {
      return [
        ...ifBlock,
        ...(elseBlock == null ? [] : elseBlock),
        {
          code: 412,
          parameters: [],
        },
      ]
    }

ConditionIfBlock
  = parameters:__If__ NL
    statements:(@__Statement__ NL)* {
      return [
        {
          code: 111,
          parameters,
        },
        ...statements,
        [{
          code: 0,
          parameters: [],
        }],
      ]
    }

ConditionElseBlock
  = __Else__ NL
    statements:(@__Statement__ NL)* {
      return [
        {
          code: 411,
          parameters: [],
        },
        ...statements,
        [{
          code: 0,
          parameters: [],
        }],
      ]
    }

__If__
  = __* If __+ @IfCondition __*

If
  = CommandPrefix "if"

IfCondition
  = SwitchCondition
  / VariableCondition
  / SelfSwitchCondition
  / TimerCondition
  / ActorCondition
  / EnemyCondition
  / CharacterDirectionCondition
  / MoneyCondition
  / OwnedItemCondition
  / OwnedEquipmentCondition
  / ButtonCondition
  / ScriptCondition
  / VehicleCondition

SwitchConditionParameter
  = "on" { return 0 }
  / "off" { return 1 }

SwitchCondition
  = "switch" __+
    left:Id __+
    right:SwitchConditionParameter __* {
      return [0, left, right]
    }

VariableConditionOperatorParameter
  = EQ { return 0 }
  / GE { return 1 }
  / LE { return 2 }
  / GT { return 3 }
  / LT { return 4 }
  / NE { return 5 }

VariableConditionOperandParameter
  = value:Int { return [0, value] }
  / value:Id { return [1, value] }

VariableCondition
  = "variable" __+
    left:Id __*
    operator:VariableConditionOperatorParameter __*
    right:VariableConditionOperandParameter __* {
      return [1, left, ...right, operator]
    }

SelfSwitchCondition
  = left:SelfSwitch __+
    right:SwitchConditionParameter __* {
      return [2, left, right]
    }

TimerConditionOperatorParameter
  = GE { return 0 }
  / LE { return 1 }

TimerCondition
  = "timer" __*
    operator:TimerConditionOperatorParameter __*
    right:Int __* {
      return [3, right, operator]
    }

ActorConditionTypeParameter
  = "job" { return 2 }
  / "skill" { return 3 }
  / "weapon" { return 4 }
  / "armor" { return 5 }
  / "state" { return 6 }

ActorConditionParameter
  = type:ActorConditionTypeParameter __+
    value:Id {
      return [type, value]
    }

ActorCondition
  = "actor" __+
    left:Id __+
    "inParty" __* {
      return [4, left, 0]
    }
  / "actor" __+
    left:Id __+
    right:ActorConditionParameter __* {
      return [4, left, ...right]
    }
  / "actor" __+
    left:Id __+
    "name" __+
    right:Word __* {
      return [4, left, 1, right]
    }

EnemyCondition
  = "enemy" __+
    left:Id __+
    "appeared" __* {
      return [5, left, 0]
    }
  / "enemy" __+
    left:Id __+
    "state" __+
    right:Id __* {
      return [5, left, 1, right]
    }

CharacterDirectionConditionCharacterParameter
  = "player" { return -1 }
  / "this" { return 0 }
  / "event" __+ value:Id { return value }

CharacterDirectionConditionDirectionParameter
  = "down" { return 2 }
  / "left" { return 4 }
  / "right" { return 6 }
  / "up" { return 8 }

CharacterDirectionCondition
  = "direction" __+
    left:CharacterDirectionConditionCharacterParameter __+
    right:CharacterDirectionConditionDirectionParameter __* {
      return [6, left, right]
    }

MoneyConditionOperetorParameter
  = GE { return 0 }
  / LE { return 1 }
  / LT { return 2 }

MoneyCondition
  = "money" __*
    operator:MoneyConditionOperetorParameter __*
    right:Int __* {
      return [7, right, operator]
    }

OwnedItemCondition
  = "item" __+
    left:Id __+
    "inInventory" __* {
      return [8, left]
    }

OwnedEquipmentConditionEquipmentTypeParameter
  = "weapon" { return 9 }
  / "armor" { return 10 }

OwnedEquipmentConditionEquipmentParameter
  = type:OwnedEquipmentConditionEquipmentTypeParameter __+
    value:Id { return [type, value] }

OwnedEquipmentConditionOptionParameter
  = includingEquip:(__+ "includingEquip")? {
      return includingEquip != null
    }

OwnedEquipmentCondition
  = left:OwnedEquipmentConditionEquipmentParameter __+
    "inInventory"
    option:OwnedEquipmentConditionOptionParameter __* {
      return [...left, option]
    }

ButtonConditionParameter
  = "pressed" { return 0 }
  / "triggered" { return 1 }
  / "repeated" { return 2 }

ButtonCondition
  = "button" __+
    left:ButtonKey __+
    right:ButtonConditionParameter __* {
      return [11, left, right]
    }

ScriptCondition
  = left:Script {
      return [12, left]
    }

VehicleConditionParameter
  = "boat" { return 0 }
  / "ship" { return 1 }
  / "airship" { return 2 }

VehicleCondition
  = "vehicle" __+
    right:VehicleConditionParameter __* {
      return [13, right]
    }

ChoicesStatement
  = showChoices:__ShowChoicesWithCancel__ NL
    (__* NL)*
    whenBlocks:ChoicesWhenBlocks
    __End__ {
      return [
        {
      	  code: 102,
          parameters: [
            whenBlocks.choices,
            ...showChoices,
          ],
        },
        ...whenBlocks.statements,
        {
          code: 404,
          parameters: [],
        },
      ]
    }
  / showChoices:__ShowChoices__ NL
    (__* NL)*
    whenBlocks:ChoicesWhenBlocks
    elseBlock:ChoicesElseBlock?
    __End__ {
      return [
        {
          code: 102,
          parameters: [
            whenBlocks.choices,
            elseBlock == null ? -1 : -2,
            ...showChoices,
          ],
        },
        ...whenBlocks.statements,
        ...(elseBlock == null ? [] : elseBlock),
        {
          code: 404,
          parameters: [],
        },
      ]
    }

__ShowChoicesWithCancel__
  = __* ShowChoices
    __+ ifCancelled:ShowChoicesWhenCancelledParameter
    byDefault:__ShowChoicesByDefaultIndexParameter?
    __+ choicesWindowParameter:ChoicesWindowParameter
    __* {
      return [ifCancelled, (byDefault == null ? -1 : byDefault), ...choicesWindowParameter]
    }

__ShowChoices__
  = __* ShowChoices
    byDefault:__ShowChoicesByDefaultIndexParameter?
    __+ choicesWindowParameter:ChoicesWindowParameter
    __* {
      return [(byDefault == null ? -1 : byDefault), ...choicesWindowParameter]
    }

ShowChoicesWhenCancelledParameter
  = "cancel:" __* value:UnsignedInt { return value }

__ShowChoicesByDefaultIndexParameter
  = __+ "default:" __* value:UnsignedInt { return value }

ShowChoices
  = CommandPrefix "showChoices"

ChoicesWhenBlocks
  = whenBlocks:ChoicesWhenBlock+ {
      return {
        choices: whenBlocks.map(([text]) => text),
        statements: whenBlocks.flatMap(([text, ...statements], i) => {
          return [
            {
              code: 402,
              parameters: [i, text]
            },
            ...statements,
            [{
              code: 0,
              parameters: [],
            }],
          ]
        })
      }
    }

ChoicesWhenBlock
  = choice:__ChoicesWhen__ NL
    statements:(@__Statement__ NL)* {
      return [
        choice,
        ...statements.filter((_) => _ != null),
      ]
    }

__ChoicesWhen__
  = __* choice:ChoicesWhen __* { return choice }

ChoicesWhen
  = command:When __+ text:(Word / String) {
      return text
    }

ChoicesElseBlock
  = __Else__ NL
    statements:(@__Statement__ NL)* {
      return [
        {
          code: 403,
          parameters: [],
        },
        ...statements,
        [{
          code: 0,
          parameters: [],
        }],
      ]
    }

LoopStatement
  = __Loop__ NL
    statements:(@__Statement__ NL)*
    __End__ {
      return [
        ...statements,
        [{
          code: 0,
          parameters: [],
        }],
        {
          code: 413,
          parameters: [],
        },
      ]
    }

__Loop__
  = __* Loop __*

Loop
  = CommandPrefix "loop"

__Else__
  = __* Else __*

Else
  = CommandPrefix "else"

ProcessBattleStatement
  = parameters:__ProcessBattle__ NL
    whenWon:ProcessBattleWhenWonBlock
    whenEscaped:ProcessBattleWhenEscapedBlock
    whenLost:ProcessBattleWhenLostBlock
    __End__ {
      return [
        {
          code: 301,
          parameters: [...parameters, true, true]

        },
        ...whenWon,
        ...whenEscaped,
        ...whenLost,
      ]
    }
  / parameters:__ProcessBattle__ NL
    whenWon:ProcessBattleWhenWonBlock
    whenEscaped:ProcessBattleWhenEscapedBlock
    __End__ {
      return [
        {
          code: 301,
          parameters: [...parameters, true, false]

        },
        ...whenWon,
        ...whenEscaped,
      ]
    }
  / parameters:__ProcessBattle__ NL
    whenWon:ProcessBattleWhenWonBlock
    whenLost:ProcessBattleWhenLostBlock
    __End__ {
      return [
        {
          code: 301,
          parameters: [...parameters, false, true]

        },
        ...whenWon,
        ...whenLost,
      ]
    }
  / parameters:__ProcessBattle__ {
      return [
        {
          code: 301,
          parameters: [...parameters, false, false]

        },
      ]
    }

__ProcessBattle__
  = __* ProcessBattle __+ @ProcessBattleParameter __*

ProcessBattleParameter
  = value:Int { return [0, value] }
  / value:Variable { return [1, value] }
  / "random" { return [2, 0] }

ProcessBattleWhenWonBlock
  = when:__ProcessBattleWhenWon__ NL
    statements:(@__Statement__ NL)* {
      return [
        {
          code: 601,
          parameters: []
        },
        ...statements.filter((_) => _ != null),
        [{
          code: 0,
          parameters: [],
        }],
      ]
    }

__ProcessBattleWhenWon__
  = __* ProcessBattleWhenWon __*

ProcessBattleWhenEscapedBlock
  = when:__ProcessBattleWhenEscaped__ NL
    statements:(@__Statement__ NL)* {
      return [
        {
          code: 602,
          parameters: []
        },
        ...statements.filter((_) => _ != null),
        [{
          code: 0,
          parameters: [],
        }],
      ]
    }

__ProcessBattleWhenEscaped__
  = __* ProcessBattleWhenEscaped __*

ProcessBattleWhenLostBlock
  = when:__ProcessBattleWhenLost__ NL
    statements:(@__Statement__ NL)* {
      return [
        {
          code: 603,
          parameters: []
        },
        ...statements.filter((_) => _ != null),
        [{
          code: 0,
          parameters: [],
        }],
      ]
    }

__ProcessBattleWhenLost__
  = __* ProcessBattleWhenLost __*

ProcessBattleWhenWon
  = When __+ "won"

ProcessBattleWhenEscaped
  = When __+ "escaped"

ProcessBattleWhenLost
  = When __+ "lost"

ProcessBattle
  = CommandPrefix "processBattle"

When
  = CommandPrefix "when"

__End__
  = __* End __*

End
  = CommandPrefix "end"

Break
  = CommandPrefix "break"

EraseEvent
  = CommandPrefix "eraseEvent"

GetOnOffVehicle
  = CommandPrefix "getOnOffVehicle"

GatherFollowers
  = CommandPrefix "gatherFollowers"

FadeoutScreen
  = CommandPrefix "fadeoutScreen"

FadeinScreen
  = CommandPrefix "fadeinScreen"


CommandStatement
  = __* !(If / ShowChoices / ProcessBattle / When / Else / Loop / End)
    command:$Command
    __* {
      return [{ command }]
    }

Command
  = CommandPrefix @Char+

CommandPrefix
  = At {}

MessageCharacterPrefix
  = GreaterThan __* {}

MessageWindowParameter
  = background:MessageWindowBackground __+
    poisition:MessageWindowPosition {
      return [background, poisition]
    }

ChoicesWindowParameter
  = background:MessageWindowBackground __+
    poisition:ChoicesWindowPosition {
      return [poisition, background]
    }

MessageWindowBackground
  = ("window" / "ウィンドウ") {
      return 0
    }
  / ("darken" / "暗くする") {
      return 1
    }
  / ("transparent" / "透明") {
      return 2
    }

MessageWindowPosition
  = ("top" / "上") {
      return 0
    }
  / ("center" / "中") {
      return 1
    }
  / ("right" / "下") {
      return 2
    }

ChoicesWindowPosition
  = ("left" / "左") {
      return 0
    }
  / ("center" / "中") {
      return 1
    }
  / ("right" / "右") {
      return 2
    }

// word literal
Word
  = @$Char+

Char
  = ![ '"\b\f\t\r\n] @.

// indexed value literal
Variable
  = "v" @ArrayIndex

Switch
  = "s" @ArrayIndex

SelfSwitch
  = "selfSwitch" __+ @SelfSwitchKey

ArrayIndex
  = BracketOpen __* @Digits __* BracketClose

SelfSwitchKey
  = [A-D]

Id
  = NumberSign @Digits

ButtonKey
  = "ok"
  / "cancel"
  / "shift"
  / "down"
  / "left"
  / "right"
  / "up"
  / "pageup"
  / "pagedown"

// string literal
Script
  = QX @$BackQuotedChar* QX

String
  = QQ @$DoubleQuotedChar* QQ
  / Q @$QuotedChar* Q

DoubleQuotedChar
  = !(DoubleQuote / Backslash) @.
  / EscapeSequence

QuotedChar
  = !(Quote / Backslash) @.
  / EscapeSequence

BackQuotedChar
  = !(BackQuote / Backslash) @.
  / EscapeSequence

EscapeSequence
  = Backslash @(
      Quote
    / DoubleQuote
    / BackQuote
    / Backslash
    / "b" { return "\b" }
    / "f" { return "\f" }
    / "n" { return "\n" }
    / "r" { return "\r" }
    / "t" { return "\t" }
    / "v" { return "\x0B" }
    )

// number literal
RawDigit
  = [0-9]

Digit
  = RawDigit {
      return Number(text())
    }

Digits
  = RawDigit+ {
      return Number(text())
    }

RawInt
  = [1-9] RawDigit+  {
      return text()
    }
  / RawDigit
UnsignedInt "unsigned integer"
  = RawInt { return Number(text()) }
Int "integer"
  = Minus? RawInt {
      return Number(text())
    }

RawReal
  = RawInt (Dot RawDigit*)? {
      return text()
    }
UnsignedReal "unsigned real number"
  = RawReal { return Number(text()) }
Real "real number"
  = Minus? RawReal {
      return Number(text())
    }

// boolean literal
Boolean
  = True
  / False
True
  = "true" { return true }
False
  = "false" { return false }

// operators
EQ = value:"==" { return { type: 'operator', value } }
LT = value:LessThan { return { type: 'operator', value } }
GT = value:GreaterThan { return { type: 'operator', value } }
LE = value:"<=" { return { type: 'operator', value } }
GE = value:">=" { return { type: 'operator', value } }
NE = value:"!=" { return { type: 'operator', value } }
Plus = value:PlusSign { return { type: 'operator', value } }
Minus = value:Hyphen { return { type: 'operator', value } }
Multi = value:Asterisk { return { type: 'operator', value } }
Div = value:Slash { return { type: 'operator', value } }
Mod = value:Percent { return { type: 'operator', value } }

// quotes
Q = Quote {}
QQ = DoubleQuote {}
QX = BackQuote {}

// punctuations
At = "@"
Dot = "."
Equal = "="
LessThan = "<"
GreaterThan = ">"
Hyphen = "-"
Underscore = "_"
Asterisk = "*"
DollarSign = "$"
NumberSign = "#"
PlusSign = "+"
Percent = "%"
Slash = "/"
Backslash = "\\"
Quote = "'"
DoubleQuote = "\""
BackQuote = "`"
Ampersand = "&"
VerticalBar = "|"
Exclamation = "!"
Question = "?"
Tilde = "~"
BracketOpen = "["
BracketClose = "]"

// whitespace
__ "whitespace" = [ \t] {}
NL "end of line" = LF / CR / CRLF {}
LF = "\n"
CR = "\r"
CRLF = "\r\n"
EOF = !. {}
