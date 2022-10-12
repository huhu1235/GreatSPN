
// To regenerate the parser classes, run:
//     make JavaGUI-antlr
// or manually:
//    antlr4 -visitor -no-listener -package editor.domain.grammar ExprLang.g4
// CLASSPATH=.:/usr/local/lib/antlr-4.2.1-complete.jar:../dist/Editor.jar 
//        grun editor.domain.grammar.ExprLang mainBoolExpr -gui

// To copy as HTML:
// Use Sublime (with SublimeHighlighter installed)
//  select all -> ctrl+shift+P -> copy as HTML

// Define a grammar called ExprLang
grammar ExprLang;

// Tokens that are not generated directly, but are context-sensitive
tokens {
    // special operators, not generated by the lexer.
    INT_TO_REAL, UNION, SETMINUS, SAFE_DIV, LESS_ZEROINF,
    MULTISET_MIN, MULTISET_MAX, MULTISET_FILTER_NEGATIVES,

    INT_PLACE_ID, REAL_PLACE_ID, INT_MSET_PLACE_ID, REAL_MSET_PLACE_ID,
    TRANSITION_ID, 
    INT_CONST_ID, REAL_CONST_ID, INT_MSET_CONST_ID, REAL_MSET_CONST_ID,
    INT_TEMPLATE_ID, REAL_TEMPLATE_ID,
    ACTION_ID, STATEPROP_ID, CLOCK_ID,
    SIMPLECOLORCLASS_ID, COLORDOMAIN_ID, COLORVAR_ID,
    COLORSUBCLASS_ID, COLOR_ID,
    GREATSPN_ALL, GREATSPN_SUBCLASS,

    EXISTS, FORALL, NEXT, FUTURE, GLOBALLY, UNTIL,
    EXISTS_NEXT, EXISTS_FUTURE, EXISTS_GLOBALLY,
    FORALL_NEXT, FORALL_FUTURE, FORALL_GLOBALLY,
    POSSIBLY, IMPOSSIBLY, INVARIANTLY, ENABLED, BOUNDS, DEADLOCK, NO_DEADLOCK, INITIAL_STATE,

    CTLSTAR_NEXT, CTLSTAR_FUTURE, CTLSTAR_GLOBALLY, CTLSTAR_UNTIL,
    CTLSTAR_EXISTS, CTLSTAR_FORALL,
    CTLSTAR_EXISTS_NEXT, CTLSTAR_EXISTS_FUTURE, CTLSTAR_EXISTS_GLOBALLY, 
    CTLSTAR_FORALL_NEXT, CTLSTAR_FORALL_FUTURE, CTLSTAR_FORALL_GLOBALLY, 

    PDF_X_VAR, RECT_FN, UNIFORM_FN, TRIANGULAR_FN, ERLANG_FN, 
    TRUNCATED_EXP_FN, PARETO_FN, DIRAC_DELTA_FN
}
@members {
public ParserContext context = null;
public int parseFlags;
public boolean clockVarInExpr = true;
}
@header{
import editor.domain.*;
import editor.domain.elements.*;
}



//--------------------------------------------------------------------------
//       Entry points
//--------------------------------------------------------------------------

mainIntExpr              : intExpr EOF;
mainRealExpr             : realExpr EOF;
mainBoolExpr             : boolExpr EOF;
mainIntOrInfiniteExpr    : (intExpr|INFINITY) EOF; // Multiple/Infinite servers

mainIntExprList          : intExpr (',' intExpr)* EOF;
mainRealExprList         : realExpr (',' realExpr)* EOF;

mainClockConstr          : clockConstr (';' varUpdateList)? EOF;
mainActSet               : actSet EOF;
mainStatePropExpr        : boolExpr EOF;
mainActBinding           : actBinding EOF;
mainVarFlow              : varFlowList EOF;

mainClockDef             : CLOCK EOF;

mainMeasure              : measure EOF;
mainCsltaExpr            : csltaExpr EOF;

mainColorClassDef        : colorClassDef EOF;
mainColorVarDef          : colorVarDef EOF;
mainPlaceColorDomainDef  : placeColorDomainDef EOF;
mainRealMSetExpr         : realMSetExpr EOF;
mainIntMSetExpr          : intMSetExpr EOF;

mainTagRewriteList       : tagRewriteList EOF;

// <span style="color:#888888">Verbatim general transition functions are written as: </span>
//  FN: <span style="color:#c5060b;font-style:italic">text</span>

//--------------------------------------------------------------------------
//       Basic integer, real and boolean expressions for GSPN:
//--------------------------------------------------------------------------

intConst : INT                # IntConstLiteral
         | INT_CONST_ID       # IntConstId
         | INT_TEMPLATE_ID    # IntTemplateId
         ;

realConst : intConst          # RealFromIntConst
          | REAL              # RealConstLiteral
          | REAL_CONST_ID     # RealConstId
          | REAL_TEMPLATE_ID  # RealTemplateId
          ;

boolConst : TRUE | FALSE ;

intExpr : intExpr op=('*'|'/') intExpr                        # IntExprMulDiv
        | intExpr op=('+'|'-') intExpr                        # IntExprAddSub
        | '-' intExpr                                         # IntExprNegate
        | intConst                                            # IntExprConst
        | '#' INT_PLACE_ID                                    # IntExprPlaceMarking
        | '(' intExpr ')'                                     # IntExprParen
        | unaryIntFn '[' intExpr ']'                          # IntExprUnaryFn
        | unaryIntRealFn '[' realExpr ']'                     # IntExprUnaryRealFn
        | binaryIntFn '[' intExpr ',' intExpr ']'             # IntExprBinaryFn
        | 'If' '[' boolExpr ',' intExpr ',' intExpr ']'       # IntExprCond
        | 'when' boolExpr ':' intExpr ';' 'ever' intExpr ';'  # IntExprCond2
        | 'Card' '[' intMSetExpr ']'                          # IntExprCardMSet
        | 'CN' '[' colorTerm ']'                              # IntExprColorNum
        | BOUNDS '(' INT_PLACE_ID (',' INT_PLACE_ID)* ')'     # IntExprCTLBound /* only CTL */
        | ID /* Generate a parse error */                     # IntExprUnknownId
        | '#' ID /* Generate a parse error */                 # IntExprUnknownPlaceId
        ;

realExpr : realExpr op=('*'|'/') realExpr                            # RealExprMulDiv
         | realExpr op=('+'|'-') realExpr                            # RealExprAddSub
         | '-' realExpr                                              # RealExprNegate
         | realConst                                                 # RealExprConst
         | '#' REAL_PLACE_ID                                         # RealExprPlaceMarking
         | intExpr                                                   # RealExprInt
         | '(' realExpr ')'                                          # RealExprParen
         | (unaryRealFn|unaryIntFn) '[' realExpr ']'                 # RealExprUnaryFn
         | (binaryIntFn|binaryRealFn) '[' realExpr ',' realExpr ']'  # RealExprBinaryFn
         | 'If' '[' boolExpr ',' realExpr ',' realExpr ']'           # RealExprCond
         | 'when' boolExpr ':' realExpr ';' 'ever' realExpr ';'      # RealExprCond2
         | PDF_X_VAR /* x variable for PDF equations */              # RealExprPdfXVar /* only PDF */
         | {clockVarInExpr}? clockVar                                # RealExprClockVar
         | ID /* Generate a parse error */                           # RealExprUnknownId
         | 'FromList' '[' fname=STRING_LITERAL ',' intExpr ']'       # RealExprFromList
         | 'FromTable' '[' fname=STRING_LITERAL ',' intExpr ',' intExpr ']' # RealExprFromTable
         | 'FromTimeTable' '[' fname=STRING_LITERAL ',' intExpr ',' intExpr ']' # RealExprFromTimeTable
         | 'Call' '[' name=STRING_LITERAL intOrRealList ']'          # RealExprCall
         ;

boolExpr : '!' boolExpr                                          # BoolExprNot
         | boolExpr '&&' boolExpr                                # BoolExprAnd
         | boolExpr '||' boolExpr                                # BoolExprOr
         | boolExpr '->' boolExpr                                # BoolExprImply
         | boolExpr '<->' boolExpr                               # BoolExprBiimply
         | boolConst                                             # BoolExprConst
         | intExpr op=('>='|'<='|'>'|'<'|'=='|'!=') intExpr      # BoolExprIntComp
         | realExpr op=('>='|'<='|'>'|'<'|'=='|'!=') realExpr    # BoolExprRealComp
         | '(' boolExpr ')'                                      # BoolExprParen
         | ID /* Generate a parse error */                       # BoolExprUnknownId
         | STATEPROP_ID /* CSLTA proposition */                  # BoolExprStatePropId
         | colorTerm op=('>='|'<='|'>'|'<'|'=='|'!=') colorTerm  # BoolExprColorTermComp
         | colorTerm (CONTAINS | DONT_CONTAINS) colorSet         # BoolExprColorTermIn
         /* Only available for CTL expressions */
         | temporal_op boolExpr                                  # BoolExprCTL
         | (EXISTS | FORALL) '(' boolExpr UNTIL boolExpr ')'     # BoolExprCTLUntil
         | (EXISTS | FORALL) '[' boolExpr UNTIL boolExpr ']'     # BoolExprCTLUntil2
         | pin=(POSSIBLY|IMPOSSIBLY|INVARIANTLY) boolExpr        # BoolExprCTLpin
         | ENABLED '(' TRANSITION_ID ')'                         # BoolExprCTLenabled
         | (DEADLOCK|NO_DEADLOCK)                                # BoolExprCTLdeadlocks
         | INITIAL_STATE                                         # BoolExprCTLinitState
         /* LTL/CTL* language */
         | op=(CTLSTAR_NEXT | CTLSTAR_FUTURE | CTLSTAR_GLOBALLY) boolExpr  # BoolExprCTLStar
         | '(' boolExpr CTLSTAR_UNTIL boolExpr ')'               # BoolExprCTLStarUntil
         | '[' boolExpr CTLSTAR_UNTIL boolExpr ']'               # BoolExprCTLStarUntil2
         | q=(CTLSTAR_EXISTS | CTLSTAR_FORALL) boolExpr          # BoolExprCTLStarQuantif
         | composite_temporal_op_ctlstar boolExpr                # BoolExprCTLStar2
         ;

unaryIntFn : fn=(ABS_FN | FACTORIAL_FN);

unaryIntRealFn : fn=(CEIL_FN | FLOOR_FN | ROUND_FN);

binaryIntFn : fn=(MIN_FN | MAX_FN | MOD_FN | BINOMIAL_FN | POW_FN | FRACT_FN);

                // Functions for general events PDF
binaryRealFn : fn=(RECT_FN| UNIFORM_FN| TRIANGULAR_FN| ERLANG_FN| TRUNCATED_EXP_FN| PARETO_FN);

unaryRealFn : fn=(SIN_FN | COS_FN | TAN_FN | EXP_FN | SQRT_FN | ARCSIN_FN | ARCCOS_FN | ARCTAN_FN
                // Functions for general events PDF
                | DIRAC_DELTA_FN);

intOrRealList:                             # IntOrRealListEmptyList
             | ',' intExpr intOrRealList   # IntOrRealListInt
             | ',' realExpr intOrRealList  # IntOrRealListReal
             ;

//--------------------------------------------------------------------------
// Multiset expressions:
//--------------------------------------------------------------------------

// WN(S)RG also supports element product with a guard, like:  [d(x)=S1]<x>
// When a guarded arc evaluates to zero (all guard false), it is like if the arc
// is not present.

mSetPredicate : '[' boolExpr ']'                                 # MSetBoolPredicate
              ;

mSetElemPredicate : '[' boolExpr ']'                             # MSetElemBoolPredicate
                  ;

realMSetExpr : '(' realMSetExpr ')'                                # RealMSetExprParen 
             | realMSetExpr op=('+'|'-') realMSetExpr              # RealMSetExprAddSub
             | realExpr? mSetPredicate? '<' multiSetElem (',' multiSetElem)* '>' mSetElemPredicate?  # RealMSetExprElemProduct
             | '#' REAL_MSET_PLACE_ID                              # RealMsetExprPlaceMarking
             | REAL_MSET_CONST_ID                                  # RealMsetExprConst
             ;

intMSetExpr :  '(' intMSetExpr ')'                               # IntMSetExprParen
            | intMSetExpr op=('+'|'-') intMSetExpr               # IntMSetExprAddSub
            | intExpr? mSetPredicate? '<' multiSetElem (',' multiSetElem)* '>' mSetElemPredicate?  # IntMSetExprElemProduct
            | '#' INT_MSET_PLACE_ID                              # IntMsetExprPlaceMarking
            | INT_MSET_CONST_ID                                  # IntMSetExprConst
            ;

multiSetElem : multiSetElem op=('+'|'-') multiSetElem            # MSetElemAddSub
             | colorSet                                          # MSetElemColorTerm
             ;

colorVar : COLORVAR_ID  # ColorVarIdentifier ;

colorSubclass : COLORSUBCLASS_ID  # ColorSubclassIdentifier ;

colorTerm : colorTerm op=('++'|'--')               # ColorTermNextPrev
          //| op=('!'|'^') colorTerm                 # ColorTermNextPrev2
          | colorVar                               # ColorTermVar
          | COLOR_ID                               # ColorTermColor
          | '@' SIMPLECOLORCLASS_ID? ('[' INT ']')?  # ColorTermFilterThis
          ;

colorSet : colorTerm                               # ColorSetTerm
         | 'All'                                   # ColorSetAll
         | SIMPLECOLORCLASS_ID                     # ColorSetClass
         | GREATSPN_ALL SIMPLECOLORCLASS_ID        # ColorSetClass2
         | colorSubclass                           # ColorSetSubClass
         | GREATSPN_ALL colorSubclass              # ColorSetSubClass2
         | 'Subclass' '[' colorTerm ']'            # ColorSetSubclassOf
         | GREATSPN_SUBCLASS '(' colorTerm ')'     # ColorSetSubclassOf2
         ;
// NOTE: GREATSPN_ALL and GREATSPN_SUBCLASS (which are 'S' and 'd', respectively)
// are currently not generated by the lexer, so these rules are not used.

//--------------------------------------------------------------------------
// Color class declaration:
//--------------------------------------------------------------------------

colorClassDef : colorClassOrd* colorList ('+' colorList)*         # ColorClassDefNamedSet
              | SIMPLECOLORCLASS_ID ('*' SIMPLECOLORCLASS_ID)+    # ColorClassDefProduct
              //| 'subset' SIMPLECOLORCLASS_ID 'with' colorList     # ColorClassDefSubset
              ;

colorClassOrd : 'ordered' | 'unordered' | 'circular' | 'enum' | 'agent';

colorList : '{' ID (',' ID)* '}' colorSubclassName?                   # ColorListIDs
          | anyID? '{' intConst '..' intConst '}' colorSubclassName?  # ColorListInterval
          ;

colorSubclassName : 'is' ID                           # ColorSubclassNameDef
                  ;

colorVarDef : SIMPLECOLORCLASS_ID ;

placeColorDomainDef : SIMPLECOLORCLASS_ID             # PlaceDomainColorClass
                    | COLORDOMAIN_ID                  # PlaceDomainColorDomain
                    ;

//--------------------------------------------------------------------------
//       Rules for DTA action lists and clock constraints.
//--------------------------------------------------------------------------

actList : '{' '}'                                   # ActListEmpty
        | '{' ACTION_ID (',' ACTION_ID)* '}'        # ActListList
        ;

actSet : ACT                                        # ActSetAll
       | ACT '\\' actList                           # ActSetAllExceptList
       | actList                                    # ActSetList
       //| SHARP                                      # ActSetBoundary
       ;

actBinding : TRANSITION_ID                          # ActBindingTransition
           ;

clockVar : CLOCK_ID                                 # ClockVarId
         ;

clockConstr : realExpr '<' clockVar '<' realExpr    # ClockConstrBetween
            | clockVar op=('<'|'>') realExpr        # ClockConstrIdCmpReal
            | realExpr op=('<'|'>') clockVar        # ClockConstrRealCmpId
            | clockVar '=' realExpr                 # ClockConstrEquals
            | clockConstr '&&' clockConstr          # ClockConstrAnd
            ;

varUpdate : clockVar '=' realExpr                   # VarUpdateValue
          ;

varUpdateList :                                     # VarUpdateListEmpty
              | varUpdate (',' varUpdate)*          # VarUpdateListList
              ;

varFlowList :                                       # VarFlowListEmpty
            | varFlow (',' varFlow)*                # VarFlowListList
            ;

varFlow : clockVar '=' realExpr                     # VarFlowDefinition
        ;

//--------------------------------------------------------------------------
//       Classic performance measures
//--------------------------------------------------------------------------

measure : measure op=('+'|'-') measure                       # MeasureAddSub
        | realConst? 'P{' boolExpr '}'                       # MeasureP
        | realConst? 'E{' intExpr (DIV boolExpr)? '}'        # MeasureE
        | realConst? 'X{' TRANSITION_ID (DIV boolExpr)? '}'  # MeasureX
        ;

//--------------------------------------------------------------------------
//       CSL-TA state formula language.
//--------------------------------------------------------------------------

csltaExpr : boolExpr                          # CsltaExprBool
          | INT_PLACE_ID                      # CsltaExprPlace
          | '(' csltaExpr ')'                 # CsltaExprParen
          | NOT csltaExpr                     # CsltaExprNot
          | csltaExpr AND csltaExpr           # CsltaExprAnd
          | csltaExpr OR csltaExpr            # CsltaExprOr
          | PROB_TA op=('>='|'<='|'>'|'<'|'=='|'!=') q=realConst dtaName=ID 
            '(' (real_assign (',' real_assign)*)? '|' 
                (act_assign (',' act_assign)*)? '|' 
                (sp_assign (',' sp_assign)*)? ')' # CsltaExprProbTA
          ;

real_assign : label=(ID|REAL_TEMPLATE_ID|REAL_CONST_ID) '=' realConst;
act_assign  : label=(ID|ACTION_ID|TRANSITION_ID) '=' trn=TRANSITION_ID;
sp_assign   : label=(ID|STATEPROP_ID) '=' csltaExpr;

//--------------------------------------------------------------------------
//       CTL language of RGMEDD.
//--------------------------------------------------------------------------

// Temporal operators of CTL
temporal_op : (EXISTS | FORALL) (NEXT | FUTURE | GLOBALLY)   # TemporalOp2T
            | (EXISTS_NEXT|EXISTS_FUTURE|EXISTS_GLOBALLY)    # TemporalOpExistX
            | (FORALL_NEXT|FORALL_FUTURE|FORALL_GLOBALLY)    # TemporalOpForallX
            ;

composite_temporal_op_ctlstar : CTLSTAR_EXISTS_NEXT          # ComposTempOpEX 
                              | CTLSTAR_EXISTS_FUTURE        # ComposTempOpEF
                              | CTLSTAR_EXISTS_GLOBALLY      # ComposTempOpEG
                              | CTLSTAR_FORALL_NEXT          # ComposTempOpAX
                              | CTLSTAR_FORALL_FUTURE        # ComposTempOpF
                              | CTLSTAR_FORALL_GLOBALLY      # ComposTempOpAG
                              ;

//--------------------------------------------------------------------------
//       Tag rewriting rules
//--------------------------------------------------------------------------

tag : ID                                               # TagDefinition
    | ID '?'                                           # TagComplDefinition
    ;
tagRewrite : tag '->' tag                              # TagRewriteRule
           ;
tagRewriteList :                                       # TagRewriteListEmpty
               | tagRewrite (',' tagRewrite)*          # TagRewriteListList
               ; 

//--------------------------------------------------------------------------
//       Lexer rules:
//--------------------------------------------------------------------------

// Assign names to tokens used in the grammar
MUL        : '*' ;
DIV        : '/' ;
ADD        : '+' ;
SUB        : '-' ;
AND        : '&&' ;
OR         : '||' ;
POSTINCR   : '++' ;
POSTDECR   : '--' ;
HAT        : '^' ;
NOT        : '!' ;
IMPLY      : '->' ;
BIIMPLY    : '<->' ;
COMMA      : ',' ;
COLON      : ':' ;
SEMICOLON  : ';' ;
OP_PAREN   : '(' ;
CL_PAREN   : ')' ;
OP_SQPAR   : '[' ;
CL_SQPAR   : ']' ;
OP_BRACK   : '{' ;
CL_BRACK   : '}' ;
TWODOTS    : '..' ;
EQUAL      : '==' ;
NOT_EQUAL  : '!=' ;
LESS       : '<' ;
GREATER    : '>' ;
LESS_EQ    : '<=' ;
GREATER_EQ : '>=' ;
SHARP      : '#' ;
TRUE       : 'True' ;
FALSE      : 'False' ;
INFINITY   : 'Infinite' ;
CLOCK      : 'clock' ;
ACT        : 'Act' ;
PROB_TA    : 'PROB_TA' ;
CONTAINS   : 'in' ;
DONT_CONTAINS   : '!in' ;
COLOR_ORDINAL : 'CN' ;
MULTISET_CARD : 'Card' ;
MULTISET_SUBCLASS : 'Subclass' ;

MIN_FN       : 'Min' ;
MAX_FN       : 'Max' ;
MOD_FN       : 'Mod' ;
POW_FN       : 'Pow' ;
FRACT_FN     : 'Fract' ;
FACTORIAL_FN : 'Factorial' ;
ABS_FN       : 'Abs' ;
SIN_FN       : 'Sin' ;
COS_FN       : 'Cos' ;
TAN_FN       : 'Tan' ;
ARCSIN_FN    : 'Asin' ;
ARCCOS_FN    : 'Acos' ;
ARCTAN_FN    : 'Atan' ;
EXP_FN       : 'Exp' ;
LOG_FN       : 'Log' ;
SQRT_FN      : 'Sqrt' ;
CEIL_FN      : 'Ceil' ;
FLOOR_FN     : 'Floor' ;
ROUND_FN     : 'Round' ;
BINOMIAL_FN  : 'Binomial' ;
IF_FN        : 'If' ;

// Skip spaces, tabs, newlines
WHITESPACES : [ \t\r\n]+ -> skip ;

////--------------------------------------------------------------------------
//// Context-sensitive keywords:
////--------------------------------------------------------------------------

//// AVAILABLE ONLY FOR CSL EXPRESSIONS:

//EXISTS           : "E";
//FORALL           : "A";
//NEXT             : "X";
//FUTURE           : "F";
//GLOBALLY         : "G";
//UNTIL            : "U";
//EXISTS_NEXT      : "EX";
//EXISTS_FUTURE    : "EF";
//EXISTS_GLOBALLY  : "EG";
//FORALL_NEXT      : "AX";
//FORALL_FUTURE    : "AF";
//FORALL_GLOBALLY  : "AG";
//POSSIBLY         : "possibly";
//IMPOSSIBLY       : "impossibly";
//INVARIANTLY      : "invariantly";
//ENABLED          : "en";
//BOUNDS           : "bounds";
//DEADLOCK         : "deadlock";
//NO_DEADLOCK      : "ndeadlock";

//// AVAILABLE ONLY FOR PROBABILITY DISTRIBUTION 
//// FUNCTIONS (PDFs) OF GENERAL TRANSITIONS:

//PDF_X_VAR        : "x";
//DIRAC_DELTA_FN   : "I";
//RECT_FN          : "R";
//UNIFORM_FN       : "Uniform";
//TRIANGULAR_FN    : "Triangular";
//ERLANG_FN        : "Erlang";
//TRUNCATED_EXP_FN : "TruncatedExp";
//PARETO_FN        : "Pareto";

//fragment ID_LETTER : 'a'..'z'|'A'..'Z'|'_' ; 
//fragment DIGIT : '0'..'9' ;
//fragment SignPart : '+' | '-';
//fragment ExponentPart : 'e' SignPart? DIGIT+ | 'E' SignPart? DIGIT+;

//ID : ID_LETTER (ID_LETTER | DIGIT)*

//// Integer numbers
//INT : DIGIT+ ;

//// Real floating point numbers (it avoids the 1. floats, so this rule does not
//// interfere with the color subclass declaration that uses the '..' operator)
//REAL : DIGIT+ '.' DIGIT+ ExponentPart?
//     | '.' DIGIT+ ExponentPart?
//     ;

//--------------------------------------------------------------------------
// NOTE: Decomment the part above to generate the documentation 
//       for the editor/gui/docs/grammar.html.file
//--------------------------------------------------------------------------

anyID : (ID|INT_PLACE_ID|REAL_PLACE_ID|INT_MSET_PLACE_ID|REAL_MSET_PLACE_ID|
         INT_CONST_ID|REAL_CONST_ID|INT_MSET_CONST_ID|REAL_MSET_CONST_ID|TRANSITION_ID|CLOCK_ID|
         COLORDOMAIN_ID|SIMPLECOLORCLASS_ID|COLORVAR_ID|COLORSUBCLASS_ID|COLOR_ID|
         INT_TEMPLATE_ID| REAL_TEMPLATE_ID|ACTION_ID|STATEPROP_ID)  # anyIdentifier ;

//--------------------------------------------------------------------------
// Lexer section
//--------------------------------------------------------------------------

fragment ID_LETTER : 'a'..'z'|'A'..'Z'|'_' ; 
fragment DIGIT : '0'..'9' ;
fragment SignPart : '+' | '-';
fragment ExponentPart : 'e' SignPart? DIGIT+ | 'E' SignPart? DIGIT+;

// Identifiers
ID : ID_LETTER (ID_LETTER | DIGIT)* {
    // Classify context-sensitive identifiers
    if (context != null) {
        if (context.hasNamespacePage()) {
            boolean isMarkDepExpr = 0==(parseFlags & ParserContext.PF_CONST_EXPR);
            boolean haveStaticSubclass = 0==(parseFlags & ParserContext.PF_NO_STATIC_SUBCLASS_ID);

            Node node = context.getNodeByUniqueName(getText());
            if (node != null) { // We have a node with the same name
                if (node instanceof Place && isMarkDepExpr) {
                    Place plc = (Place)node;
                    if (plc.isInNeutralDomain())
                        setType(plc.isDiscrete() ? ExprLangParser.INT_PLACE_ID 
                                                 : ExprLangParser.REAL_PLACE_ID);
                    else // in color domain
                        setType(plc.isDiscrete() ? ExprLangParser.INT_MSET_PLACE_ID 
                                                 : ExprLangParser.REAL_MSET_PLACE_ID);
                }
                else if (node instanceof editor.domain.elements.Transition/* && !isConstExpr*/)
                    setType(ExprLangParser.TRANSITION_ID);
                else if (node instanceof ConstantID) {
                    ConstantID con = (ConstantID)node;
                    if (con.isInNeutralDomain())
                        setType(con.isIntConst() ? ExprLangParser.INT_CONST_ID
                                                 : ExprLangParser.REAL_CONST_ID);
                    else // in color domain
                        setType(con.isIntConst() ? ExprLangParser.INT_MSET_CONST_ID
                                                 : ExprLangParser.REAL_MSET_CONST_ID);
                }
                else if (node instanceof ClockVar) {
                    setType(ExprLangParser.CLOCK_ID);
                }
                else if (node instanceof editor.domain.elements.ColorClass) {
                    editor.domain.elements.ColorClass cc = (editor.domain.elements.ColorClass)node;
                    if (cc.isCrossDomain())
                        setType(ExprLangParser.COLORDOMAIN_ID);
                    else
                        setType(ExprLangParser.SIMPLECOLORCLASS_ID);
                }
                else if (node instanceof editor.domain.elements.ColorVar) {
                    setType(ExprLangParser.COLORVAR_ID);
                }
                else if (node instanceof TemplateVariable) {
                    switch (((TemplateVariable)node).getType()) {
                        case INTEGER:
                            setType(ExprLangParser.INT_TEMPLATE_ID); 
                            break;
                        case REAL:      
                            setType(ExprLangParser.REAL_TEMPLATE_ID); 
                            break;
                        case ACTION:    
                            setType(ExprLangParser.ACTION_ID); 
                            break;
                        case STATEPROP: 
                            if (isMarkDepExpr)
                                setType(ExprLangParser.STATEPROP_ID); 
                            break;
                        default: throw new IllegalStateException("Unknown template var type.");
                    }
                }
                else return; // Unknown ID type
            }
            // Otherwise, try each color class to see if getText() is a sub-id
            if (haveStaticSubclass) {
                java.util.Iterator<ColorClass> ccIt = context.colorClassIterator();
                while (ccIt != null && ccIt.hasNext()) {
                    ColorClass cc = ccIt.next();
                    // Test if it is the name of a color subclass
                    if (cc.isSimpleClass()) {
                        if (cc.testHasStaticSubclassNamed(getText())) {
                            setType(ExprLangParser.COLORSUBCLASS_ID);
                            return;
                        }
                        if (cc.testHasColorNamed(context, getText())) {
                            setType(ExprLangParser.COLOR_ID);
                            return;
                        }
                    }
                }
            }
        }
    }
    // Language-dependent tokens
    boolean isCTL = 0!=(parseFlags & ParserContext.PF_CTL_KEYWORDS);
    boolean isLTL = 0!=(parseFlags & ParserContext.PF_LTL_KEYWORDS);
    boolean isCTLSTAR = 0!=(parseFlags & ParserContext.PF_CTLSTAR_KEYWORDS);
    if (isCTL) {
        switch (getText()) {
            case "E":   setType(ExprLangParser.EXISTS);           return;
            case "A":   setType(ExprLangParser.FORALL);           return;
            case "X":   setType(ExprLangParser.NEXT);             return;
            case "F":   setType(ExprLangParser.FUTURE);           return;
            case "G":   setType(ExprLangParser.GLOBALLY);         return;
            case "U":   setType(ExprLangParser.UNTIL);            return;
            case "EX":  setType(ExprLangParser.EXISTS_NEXT);      return;
            case "EF":  setType(ExprLangParser.EXISTS_FUTURE);    return;
            case "EG":  setType(ExprLangParser.EXISTS_GLOBALLY);  return;
            case "AX":  setType(ExprLangParser.FORALL_NEXT);      return;
            case "AF":  setType(ExprLangParser.FORALL_FUTURE);    return;
            case "AG":  setType(ExprLangParser.FORALL_GLOBALLY);  return;
            // If new context-dependent keywords are added to this list,
            // they must also be added in NetObject.extraKeyWords[].
        }
    }
    if (isLTL || isCTLSTAR) {
        switch (getText()) {
            case "X":   setType(ExprLangParser.CTLSTAR_NEXT);             return;
            case "F":   setType(ExprLangParser.CTLSTAR_FUTURE);           return;
            case "G":   setType(ExprLangParser.CTLSTAR_GLOBALLY);         return;
            case "U":   setType(ExprLangParser.CTLSTAR_UNTIL);            return;
        }
    }
    if (isCTLSTAR) {
        switch (getText()) {
            case "E":   setType(ExprLangParser.CTLSTAR_EXISTS);           return;
            case "A":   setType(ExprLangParser.CTLSTAR_FORALL);           return;
            case "EX":  setType(ExprLangParser.CTLSTAR_EXISTS_NEXT);      return;
            case "EF":  setType(ExprLangParser.CTLSTAR_EXISTS_FUTURE);    return;
            case "EG":  setType(ExprLangParser.CTLSTAR_EXISTS_GLOBALLY);  return;
            case "AX":  setType(ExprLangParser.CTLSTAR_FORALL_NEXT);      return;
            case "AF":  setType(ExprLangParser.CTLSTAR_FORALL_FUTURE);    return;
            case "AG":  setType(ExprLangParser.CTLSTAR_FORALL_GLOBALLY);  return;
        }
    }
    if (isCTL || isLTL || isCTLSTAR) {
        switch (getText()) {
            case "possibly":     setType(ExprLangParser.POSSIBLY);    return;
            case "impossibly":   setType(ExprLangParser.IMPOSSIBLY);  return;
            case "invariantly":  setType(ExprLangParser.INVARIANTLY); return;
            case "en":           setType(ExprLangParser.ENABLED);     return;
            case "bounds":       setType(ExprLangParser.BOUNDS);      return;
            case "deadlock":     setType(ExprLangParser.DEADLOCK);    return;
            case "ndeadlock":    setType(ExprLangParser.NO_DEADLOCK); return;
            case "initial":      setType(ExprLangParser.INITIAL_STATE);    return;
            // If new context-dependent keywords are added to this list,
            // they must also be added in NetObject.extraKeyWords[].
        }
    }

    boolean isGenFn = 0!=(parseFlags & ParserContext.PF_GENERAL_FUNCTION_KEYWORDS);
    if (isGenFn) {
        switch (getText()) {
            case "x":             setType(ExprLangParser.PDF_X_VAR);        return;
            case "I":             setType(ExprLangParser.DIRAC_DELTA_FN);   return;
            case "R":             setType(ExprLangParser.RECT_FN);          return;
            case "Uniform":       setType(ExprLangParser.UNIFORM_FN);       return;
            case "Triangular":    setType(ExprLangParser.TRIANGULAR_FN);    return;
            case "Erlang":        setType(ExprLangParser.ERLANG_FN);        return;
            case "TruncatedExp":  setType(ExprLangParser.TRUNCATED_EXP_FN); return;
            case "Pareto":        setType(ExprLangParser.PARETO_FN);        return;
        }
    }
};

// Integer numbers
INT : DIGIT+ ;

// Real floating point numbers (it avoids the 1. floats, so this rule does not
// interfere with the color subclass declaration that uses the '..' operator)
REAL : DIGIT+ '.' DIGIT+ ExponentPart?
     | '.' DIGIT+ ExponentPart?
     ;

// String
STRING_LITERAL : '"' SCharSequence? '"' ;

fragment
SCharSequence : SChar+ ;

fragment
SChar
    :   ~["\\\r\n]
//    |   EscapeSequence
//    |   '\\\n'   // Added line
//    |   '\\\r\n' // Added line
    ;


