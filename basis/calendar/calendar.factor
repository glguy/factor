! Copyright (C) 2007 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: arrays kernel math math.functions namespaces sequences
strings system vocabs.loader threads accessors combinators
locals classes.tuple math.order summary combinators.short-circuit ;
IN: calendar

HOOK: gmt-offset os ( -- hours minutes seconds )

TUPLE: duration
    { year real }
    { month real }
    { day real }
    { hour real }
    { minute real }
    { second real } ;

C: <duration> duration

TUPLE: timestamp
    { year integer }
    { month integer }
    { day integer }
    { hour integer }
    { minute integer }
    { second real }
    { gmt-offset duration } ;

C: <timestamp> timestamp

: gmt-offset-duration ( -- duration )
    0 0 0 gmt-offset <duration> ;

: <date> ( year month day -- timestamp )
    0 0 0 gmt-offset-duration <timestamp> ;

ERROR: not-a-month n ;
M: not-a-month summary
    drop "Months are indexed starting at 1" ;

<PRIVATE
: check-month ( n -- n )
    dup zero? [ not-a-month ] when ;
PRIVATE>

: month-names ( -- array )
    {
        "January" "February" "March" "April" "May" "June"
        "July" "August" "September" "October" "November" "December"
    } ;

: month-name ( n -- string )
    check-month 1- month-names nth ;

: month-abbreviations ( -- array )
    {
        "Jan" "Feb" "Mar" "Apr" "May" "Jun"
        "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"
    } ;

: month-abbreviation ( n -- string )
    check-month 1- month-abbreviations nth ;

: day-counts { 0 31 28 31 30 31 30 31 31 30 31 30 31 } ; inline

: day-names ( -- array )
    {
        "Sunday" "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday"
    } ;

: day-name ( n -- string ) day-names nth ;

: day-abbreviations2 ( -- array )
    { "Su" "Mo" "Tu" "We" "Th" "Fr" "Sa" } ;

: day-abbreviation2 ( n -- string )
    day-abbreviations2 nth ;

: day-abbreviations3 ( -- array )
    { "Sun" "Mon" "Tue" "Wed" "Thu" "Fri" "Sat" } ;

: day-abbreviation3 ( n -- string )
    day-abbreviations3 nth ;

: average-month ( -- ratio ) 30+5/12 ; inline
: months-per-year ( -- integer ) 12 ; inline
: days-per-year ( -- ratio ) 3652425/10000 ; inline
: hours-per-year ( -- ratio ) 876582/100 ; inline
: minutes-per-year ( -- ratio ) 5259492/10 ; inline
: seconds-per-year ( -- integer ) 31556952 ; inline

:: julian-day-number ( year month day -- n )
    #! Returns a composite date number
    #! Not valid before year -4800
    [let* | a [ 14 month - 12 /i ]
            y [ year 4800 + a - ]
            m [ month 12 a * + 3 - ] |
        day 153 m * 2 + 5 /i + 365 y * +
        y 4 /i + y 100 /i - y 400 /i + 32045 -
    ] ;

:: julian-day-number>date ( n -- year month day )
    #! Inverse of julian-day-number
    [let* | a [ n 32044 + ]
            b [ 4 a * 3 + 146097 /i ]
            c [ a 146097 b * 4 /i - ]
            d [ 4 c * 3 + 1461 /i ]
            e [ c 1461 d * 4 /i - ]
            m [ 5 e * 2 + 153 /i ] |
        100 b * d + 4800 -
        m 10 /i + m 3 +
        12 m 10 /i * -
        e 153 m * 2 + 5 /i - 1+
    ] ;

: >date< ( timestamp -- year month day )
    [ year>> ] [ month>> ] [ day>> ] tri ;

: >time< ( timestamp -- hour minute second )
    [ hour>> ] [ minute>> ] [ second>> ] tri ;

: instant ( -- duration ) 0 0 0 0 0 0 <duration> ;
: years ( x -- duration ) instant clone swap >>year ;
: months ( x -- duration ) instant clone swap >>month ;
: days ( x -- duration ) instant clone swap >>day ;
: weeks ( x -- duration ) 7 * days ;
: hours ( x -- duration ) instant clone swap >>hour ;
: minutes ( x -- duration ) instant clone swap >>minute ;
: seconds ( x -- duration ) instant clone swap >>second ;
: milliseconds ( x -- duration ) 1000 / seconds ;
: microseconds ( x -- duration ) 1000000 / seconds ;
: nanoseconds ( x -- duration ) 1000000000 / seconds ;

GENERIC: leap-year? ( obj -- ? )

M: integer leap-year? ( year -- ? )
    dup 100 mod zero? 400 4 ? mod zero? ;

M: timestamp leap-year? ( timestamp -- ? )
    year>> leap-year? ;

<PRIVATE

GENERIC: +year ( timestamp x -- timestamp )
GENERIC: +month ( timestamp x -- timestamp )
GENERIC: +day ( timestamp x -- timestamp )
GENERIC: +hour ( timestamp x -- timestamp )
GENERIC: +minute ( timestamp x -- timestamp )
GENERIC: +second ( timestamp x -- timestamp )

: /rem ( f n -- q r )
    #! q is positive or negative, r is positive from 0 <= r < n
    [ / floor >integer ] 2keep rem ;

: float>whole-part ( float -- int float )
    [ floor >integer ] keep over - ;

: adjust-leap-year ( timestamp -- timestamp )
    dup
    { [ day>> 29 = ] [ month>> 2 = ] [ leap-year? not ] } 1&&
    [ 3 >>month 1 >>day ] when ;

: unless-zero ( n quot -- )
    [ dup zero? [ drop ] ] dip if ; inline

M: integer +year ( timestamp n -- timestamp )
    [ [ + ] curry change-year adjust-leap-year ] unless-zero ;

M: real +year ( timestamp n -- timestamp )
    [ float>whole-part swapd days-per-year * +day swap +year ] unless-zero ;

: months/years ( n -- months years )
    12 /rem dup zero? [ drop 1- 12 ] when swap ; inline

M: integer +month ( timestamp n -- timestamp )
    [ over month>> + months/years >r >>month r> +year ] unless-zero ;

M: real +month ( timestamp n -- timestamp )
    [ float>whole-part swapd average-month * +day swap +month ] unless-zero ;

M: integer +day ( timestamp n -- timestamp )
    [
        over >date< julian-day-number + julian-day-number>date
        >r >r >>year r> >>month r> >>day
    ] unless-zero ;

M: real +day ( timestamp n -- timestamp )
    [ float>whole-part swapd 24 * +hour swap +day ] unless-zero ;

: hours/days ( n -- hours days )
    24 /rem swap ;

M: integer +hour ( timestamp n -- timestamp )
    [ over hour>> + hours/days >r >>hour r> +day ] unless-zero ;

M: real +hour ( timestamp n -- timestamp )
    float>whole-part swapd 60 * +minute swap +hour ;

: minutes/hours ( n -- minutes hours )
    60 /rem swap ;

M: integer +minute ( timestamp n -- timestamp )
    [ over minute>> + minutes/hours >r >>minute r> +hour ] unless-zero ;

M: real +minute ( timestamp n -- timestamp )
    [ float>whole-part swapd 60 * +second swap +minute ] unless-zero ;

: seconds/minutes ( n -- seconds minutes )
    60 /rem swap >integer ;

M: number +second ( timestamp n -- timestamp )
    [ over second>> + seconds/minutes >r >>second r> +minute ] unless-zero ;

: (time+)
    [ second>> +second ] keep
    [ minute>> +minute ] keep
    [ hour>>   +hour   ] keep
    [ day>>    +day    ] keep
    [ month>>  +month  ] keep
    [ year>>   +year   ] keep ; inline

: +slots [ bi@ + ] curry 2keep ; inline

PRIVATE>

GENERIC# time+ 1 ( time1 time2 -- time3 )

M: timestamp time+
    >r clone r> (time+) drop ;

M: duration time+
    dup timestamp? [
        swap time+
    ] [
        [ year>> ] +slots
        [ month>> ] +slots
        [ day>> ] +slots
        [ hour>> ] +slots
        [ minute>> ] +slots
        [ second>> ] +slots
        2drop <duration>
    ] if ;

: duration>years ( duration -- x )
    #! Uses average month/year length since duration loses calendar
    #! data
    0 swap
    {
        [ year>> + ]
        [ month>> months-per-year / + ]
        [ day>> days-per-year / + ]
        [ hour>> hours-per-year / + ]
        [ minute>> minutes-per-year / + ]
        [ second>> seconds-per-year / + ]
    } cleave ;

M: duration <=> [ duration>years ] compare ;

: duration>months ( duration -- x ) duration>years months-per-year * ;
: duration>days ( duration -- x ) duration>years days-per-year * ;
: duration>hours ( duration -- x ) duration>years hours-per-year * ;
: duration>minutes ( duration -- x ) duration>years minutes-per-year * ;
: duration>seconds ( duration -- x ) duration>years seconds-per-year * ;
: duration>milliseconds ( duration -- x ) duration>seconds 1000 * ;
: duration>microseconds ( duration -- x ) duration>seconds 1000000 * ;
: duration>nanoseconds ( duration -- x ) duration>seconds 1000000000 * ;

GENERIC: time- ( time1 time2 -- time3 )

: convert-timezone ( timestamp duration -- timestamp )
    over gmt-offset>> over = [ drop ] [
        [ over gmt-offset>> time- time+ ] keep >>gmt-offset
    ] if ;

: >local-time ( timestamp -- timestamp )
    gmt-offset-duration convert-timezone ;

: >gmt ( timestamp -- timestamp )
    instant convert-timezone ;

M: timestamp <=> ( ts1 ts2 -- n )
    [ >gmt tuple-slots ] compare ;

: (time-) ( timestamp timestamp -- n )
    [ >gmt ] bi@
    [ [ >date< julian-day-number ] bi@ - 86400 * ] 2keep
    [ >time< >r >r 3600 * r> 60 * r> + + ] bi@ - + ;

M: timestamp time-
    #! Exact calendar-time difference
    (time-) seconds ;

: time* ( obj1 obj2 -- obj3 )
    dup real? [ swap ] when
    dup real? [ * ] [
        {
            [   year>> * ]
            [  month>> * ]
            [    day>> * ]
            [   hour>> * ]
            [ minute>> * ]
            [ second>> * ]
        } 2cleave <duration>
    ] if ;

: before ( duration -- -duration )
    -1 time* ;

M: duration time-
    before time+ ;

: <zero> ( -- timestamp )
    0 0 0 0 0 0 instant <timestamp> ;

: valid-timestamp? ( timestamp -- ? )
    clone instant >>gmt-offset
    dup <zero> time- <zero> time+ = ;

: unix-1970 ( -- timestamp )
    1970 1 1 0 0 0 instant <timestamp> ;

: millis>timestamp ( x -- timestamp )
    >r unix-1970 r> milliseconds time+ ;

: timestamp>millis ( timestamp -- n )
    unix-1970 (time-) 1000 * >integer ;

: gmt ( -- timestamp )
    #! GMT time, right now
    unix-1970 millis milliseconds time+ ;

: now ( -- timestamp ) gmt >local-time ;
: hence ( duration -- timestamp ) now swap time+ ;
: ago ( duration -- timestamp ) now swap time- ;

: zeller-congruence ( year month day -- n )
    #! Zeller Congruence
    #! http://web.textfiles.com/computers/formulas.txt
    #! good for any date since October 15, 1582
    >r dup 2 <= [ 12 + >r 1- r> ] when
    >r dup [ 4 /i + ] keep [ 100 /i - ] keep 400 /i + r>
        [ 1+ 3 * 5 /i + ] keep 2 * + r>
    1+ + 7 mod ;

GENERIC: days-in-year ( obj -- n )

M: integer days-in-year ( year -- n ) leap-year? 366 365 ? ;
M: timestamp days-in-year ( timestamp -- n ) year>> days-in-year ;

: (days-in-month) ( year month -- n )
    dup 2 = [ drop leap-year? 29 28 ? ] [ nip day-counts nth ] if ;

: days-in-month ( timestamp -- n )
    >date< drop (days-in-month) ;

: day-of-week ( timestamp -- n )
    >date< zeller-congruence ;

:: (day-of-year) ( year month day -- n )
    day-counts month head-slice sum day +
    year leap-year? [
        year month day <date>
        year 3 1 <date>
        after=? [ 1+ ] when
    ] when ;

: day-of-year ( timestamp -- n )
    >date< (day-of-year) ;

<PRIVATE
: day-offset ( timestamp m -- timestamp n )
    over day-of-week - ; inline

: day-this-week ( timestamp n -- timestamp )
    day-offset days time+ ;
PRIVATE>

: sunday ( timestamp -- new-timestamp ) 0 day-this-week ;
: monday ( timestamp -- new-timestamp ) 1 day-this-week ;
: tuesday ( timestamp -- new-timestamp ) 2 day-this-week ;
: wednesday ( timestamp -- new-timestamp ) 3 day-this-week ;
: thursday ( timestamp -- new-timestamp ) 4 day-this-week ;
: friday ( timestamp -- new-timestamp ) 5 day-this-week ;
: saturday ( timestamp -- new-timestamp ) 6 day-this-week ;

: midnight ( timestamp -- new-timestamp )
    clone 0 >>hour 0 >>minute 0 >>second ; inline

: noon ( timestamp -- new-timestamp )
    midnight 12 >>hour ; inline

: beginning-of-month ( timestamp -- new-timestamp )
    midnight 1 >>day ;

: beginning-of-week ( timestamp -- new-timestamp )
    midnight sunday ;

: beginning-of-year ( timestamp -- new-timestamp )
    beginning-of-month 1 >>month ;

: time-since-midnight ( timestamp -- duration )
    dup midnight time- ;

: since-1970 ( duration -- timestamp )
    unix-1970 time+ >local-time ;

M: timestamp sleep-until timestamp>millis sleep-until ;

M: duration sleep hence sleep-until ;

{
    { [ os unix? ] [ "calendar.unix" ] }
    { [ os windows? ] [ "calendar.windows" ] }
} cond require
