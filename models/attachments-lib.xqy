xquery version "1.0-ml";

module namespace alib = "http://marklogic.com/roxy/models/attachments-lib";

import module namespace m = "http://marklogic.com/roxy/models/search-attachments-lib" at "/shared/attachments-xqy/models/search-attachments-lib.xqy";
import module namespace req = "http://marklogic.com/roxy/request" at "/roxy/lib/request.xqy";
import module namespace ufp = "http://www.gov.uk/dclg/common/uploaded-file-permission" at "/app/common/uploaded-file-permission.xqy";
import module namespace aa = "http://www.gov.uk/dclg/common/audit-adapter" at "/app/common/audit-helper-adapter.xqy";

declare namespace j = "http://marklogic.com/xdmp/json/basic";

declare option xdmp:mapping "false";

declare function alib:search-results(
        $body as item()*
) as element() {
    let $start :=
        if(xdmp:castable-as("http://www.w3.org/2001/XMLSchema", "integer", ($body/j:start,"")[1]))
        then fn:max((xs:int($body/j:start), 1))
        else  1
    let $page-size :=
        if(xdmp:castable-as("http://www.w3.org/2001/XMLSchema", "integer", ($body/j:length,"")[1]))
        then xs:int($body/j:length)
        else 10
    let $search-term := ($body/j:search, "")[1]
    let $search-collection := $body/j:collection
    let $sort-column := $body/j:sort/j:json/j:column
    let $sort-direction := $body/j:sort/j:json/j:direction

    return m:search-attachments(req:get("type", "", "type=xs:string"), req:get("uid", "", "type=xs:string"),
            $search-term, $search-collection, $start, $page-size, $sort-column, $sort-direction)

};

declare function alib:do-upload(
        $request-field-names as xs:string*,
        $uri as xs:string,
        $request-body as item()*,
        $collections as xs:string*,
        $type as xs:string,
        $id as xs:string
) {
    let $properties-decode :=
        for $param in $request-field-names
        return if(fn:starts-with($param, "prop:")) then element {fn:QName("", fn:replace($param, "prop:", ""))} {xdmp:url-decode(xdmp:get-request-field($param))} else ()

    let $properties-encode :=
        for $param in $request-field-names
        return if(fn:starts-with($param, "prop:")) then element {fn:QName("", fn:replace($param, "prop:", ""))} {xdmp:get-request-field($param)} else ()

    let $permissions := ufp:get-document-permissions($type, $id)
    let $_ := xdmp:document-insert($uri, $request-body, $permissions, $collections)
    let $_ := xdmp:document-add-properties($uri, $properties-decode)

    return aa:sniff-auditing($type, $id, map:new(( map:entry("properties", $properties-encode) )) )
};

declare namespace j = "http://marklogic.com/xdmp/json/basic";

declare option xdmp:mapping "false";

declare function alib:search-results(
        $body as item()*
) as element() {
    let $start :=
        if(xdmp:castable-as("http://www.w3.org/2001/XMLSchema", "integer", ($body/j:start,"")[1]))
        then fn:max((xs:int($body/j:start), 1))
        else  1
    let $page-size :=
        if(xdmp:castable-as("http://www.w3.org/2001/XMLSchema", "integer", ($body/j:length,"")[1]))
        then xs:int($body/j:length)
        else 10
    let $search-term := ($body/j:search, "")[1]
    let $search-collection := $body/j:collection
    let $sort-column := $body/j:sort/j:json/j:column
    let $sort-direction := $body/j:sort/j:json/j:direction

    return m:search-attachments(req:get("type", "", "type=xs:string"), req:get("uid", "", "type=xs:string"),
            $search-term, $search-collection, $start, $page-size, $sort-column, $sort-direction)

};

declare function alib:do-upload(
        $request-field-names as xs:string*,
        $uri as xs:string,
        $request-body as item()*,
        $collections as xs:string*,
        $type as xs:string,
        $id as xs:string
) {
    let $properties-decode :=
        for $param in $request-field-names
        return if(fn:starts-with($param, "prop:")) then element {fn:QName("", fn:replace($param, "prop:", ""))} {xdmp:url-decode(xdmp:get-request-field($param))} else ()

    let $properties-encode :=
        for $param in $request-field-names
        return if(fn:starts-with($param, "prop:")) then element {fn:QName("", fn:replace($param, "prop:", ""))} {xdmp:get-request-field($param)} else ()

    let $parent-permissions := xdmp:document-get-permissions(ta:get-document-uri($type, $id))
    let $_ := xdmp:document-insert($uri, $request-body, $parent-permissions, $collections)
    let $_ := xdmp:document-add-properties($uri, $properties-decode)

    return aa:sniff-auditing($type, $id, map:new(( map:entry("properties", $properties-encode) )) )
};
