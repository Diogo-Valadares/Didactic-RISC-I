JMP ALWAYS @0 :start
ADD @0 @0 @0
:start
.word var #FFFFFFFF
LDRW @1 #FFFFFFFC
PUTPSW @0 @1 0
GETPSW @2 0
JMPR ALWAYS 0
ADD @0 @0 @0