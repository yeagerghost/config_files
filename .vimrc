set hlsearch
colorscheme koehler

let @a=':%s/^.*Outbox-Versions_//g
:%s/\t.*got /=/g
:%s/ (.*$//g
:%s/\t.*$/=/g
:%s/invlib4/invserve/g
'

function Sqline()
  :%s/^/'/g
  :%s/\n/',/g
  :%s/,$//g
endfunction


" Assumes buffer contains select * from customerorder where orderkey in ('list','of','orderkeys')
" Function then creates a grep to search for those orderkeys from a list of results previously generated
" By function GenInvseats
function SOrders()
  :%s/^select.*in/grep -Ew/g
  :%s/'//g
  :%s/(/'/g
  :%s/)/'/g
  :%s/,/|/g
endfunction

" Assumes the buffer contains orderkeys on separate lines with possible duplicates
" Function then generates select * from customerorder for the orderkeys
function COrders()
  :sort u
  :%g/^0$/d
  :%s/^/'/g
  :%s/\n/',/g
  :%s/,$//g
  :%s/^/select * from customerorder where orderkey in (/g
  :%s/$/)/g
endfunction

" Assumes buffer contains select * from invjournal where prodcode='XXX' and seat in ('seat','list') union <journalkey number>
" All execept journalkey number is actually generated by the function MSales()
" Fucntion then generates the SQL statement to open the seats which will be used by importinv
function GenOpens()
  :%s/select \* /select prodCode, seat, oldRest, 0, 'OPEN' /g
  :%s/union/and journalkey >= /g
  :%s/order by timestamp/and journalkey >= /g
  :1,$-1s/$/ union/
endfunction


" Assumes buffer contains select * from invjournal where prodcode='<prodcode>' and seat in ('seat','list') union 
" Function then generates a bash script to to do an invseats CSV file so that orderkeys can be checked against seats
function GetInvseats()
  :%s/^.*prodcode='//g
  :%s/'.*$//g
  :%s/\n/ /g
  :%s/^/for arg in /g 
  :%s/$/; do invseats.py inv -fcsv $arg > $arg.seats; done
endfunction


" Assumes buffer contains select * from invjournal where prodcode='<prodcode>' and seat in ('seat','list') union 
" Swapping around certain search results =====> :%s/\(prodcode=.*' *and\)\(.*$\)/\2 \1/g <======  Oriely Sed and Awk pg 84
" Function (search inv seats) then generates a bash script to grep for the seats from CSV file generated by GetInvseats
function SInvseats()
  :%s/).*$/)/g
  :%s/\(prodcode=.*' *and\)\(.*$\)/\2 \1/g
  :%s/'//g
  :%s/ *and$//g
  :%s/^.*select.*in/grep -Ew
  :%s/(/'/g
  :%s/)/'/g
  :%s/, /|/g
  :%s/prodcode=//g
  :%s/$/.seats/g
endfunction

" Assumes the buffer contains the output from a freshdesk test events for missing sales
" Function then geneates SQL select * from invjoural for the appropriate seats and events
function MSales()
  :%s/uFAIL/\r&/g
  :g!/^uFAIL/d
  :%s/INVENTORY.*$//g
  :%s/uFAIL.*in /select * from invjournal where prodcode='/g
  :%s/: uMissing sales: DB([0-9]\{1,3})/' and seat in /g
  :%s/\[/('/g
  :%s/\]/')/g
  :%s/, /', '/g
  :1,$-1s/$/union/g
  :$s/$/order by timestamp
endfunction


" Assumes the buffer contains the output from a Nagios test events for missing sales
" Function then geneates SQL select * from invjoural for the appropriate seats and events
function NMSales()
  :%s/u'FAIL/\r&/g
  :g!/^u'FAIL/d
  :%s/INVENTORY.*$//g
  :%s/u'FAIL.*in /select * from invjournal where prodcode='/g
  :%s/: u"Missing sales: DB([0-9]\{1,3})/ and seat in /g
  :%s/\[/(/g
  :%s/\]/)/g
  :1,$-1s/$/union/g
  :$s/$/order by timestamp
endfunction


" Assumes the buffer contains the output from a Test event run manually for missing sales
" Function then geneates SQL select * from invjoural for the appropriate seats and events
function TMSales()
  :%s/^FAIL:.*in /select * from invjournal where prodcode='
  :%s/^select .*/&' /g
  :g!/^select \*.*$\|^AssertionError/d
  :%s/INVENTORY.*/XXXXXXXX /g
  :%s/\n//g
  :%s/ XXXXXXXX/\r/g
  :%g/^.$/d
  :%s/AssertionError: Missing sales: DB([0-9]\{1,3})/ and seat in /g
  :%s/\[/(/g
  :%s/\]/)/g
  :1,$-1s/$/ union/g
  :$s/$/ order by timestamp
endfunction
