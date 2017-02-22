xquery version "1.0-ml";

module namespace m = "http://marklogic.com/roxy/models/search-attachments-lib";

import module namespace c = "http://marklogic.com/roxy/config" at "/app/config/config.xqy";
import module namespace da = "http://www.gov.uk/dclg/display/display-lib-adapter"   at "display-lib-adapter.xqy";

declare namespace prop = "http://marklogic.com/xdmp/property";
declare option xdmp:mapping "false";

declare variable $m:PROPERTIES-MAP := map:map(
 <map:map xmlns:map="http://marklogic.com/xdmp/map">
    <map:entry key="lastUpdated">
       <map:value xsi:type="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema"  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">//prop:last-modified</map:value>
    </map:entry>
    <map:entry key="docDescription">
       <map:value xsi:type="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema"  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">//description</map:value>
    </map:entry>
    <map:entry key="docCategory">
       <map:value xsi:type="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema"  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">//category</map:value>
    </map:entry>
    <map:entry key="addedBy">
       <map:value xsi:type="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema"  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">//added-by</map:value>
    </map:entry>
    <map:entry key="addedByRoles">
       <map:value xsi:type="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema"  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">//added-by-roles</map:value>
    </map:entry>
 </map:map>
);



declare function m:search-attachments($attachments-for as xs:string, $parent-uid as xs:string,  
                                      $search-term as xs:string, $search-collection as xs:string?,
                                      $start as xs:int, $page-size as xs:int, 
                                      $sort-column as xs:string?, $sort-direction as xs:string? ){
                                      
      let $_ := xdmp:log(fn:concat("SEARCH ATTACHMENTS PARENT TYPE: ", $attachments-for), "debug") 
      let $_ := xdmp:log(fn:concat("SEARCH ATTACHMENTS PARENT ID: ", $parent-uid), "debug") 
      let $_ := xdmp:log(fn:concat("SEARCH ATTACHMENTS TERM: ", $search-term), "debug")        
      let $_ := xdmp:log(fn:concat("SEARCH ATTACHMENTS COL: ", $search-collection), "debug")                                
      
      let $search-directory := concat("/files/", $attachments-for , "/", $parent-uid, "/")
      
      let $results := 
         (xdmp:value(
            fn:concat(
               "for $item in cts:search(xdmp:document-properties(),",
               " cts:and-query((",
               "  cts:directory-query('", $search-directory, "', 'infinity')",
               if ($search-collection) then fn:concat(", cts:collection-query('", $search-collection, "')") else (),
               " )))",
               if ($sort-column) then fn:concat(" order by $item", map:get($m:PROPERTIES-MAP, $sort-column), " ", $sort-direction) else "",
               " return $item")
         ))[fn:position() ge ($start) and fn:position() le ($start + $page-size)]
         
      let $users := $results//(added-by|added-by-roles)/xs:string(.)
      let $user-data-map := da:get-display-users($users)
         
      return 
       <results>
         <data>{
            for $item in $results
              let $uri := fn:base-uri($item)
              return
               <item>
                  <lastUpdated>{ fn:format-dateTime(xs:dateTime($item//prop:last-modified), $c:display-date-time-picture) }</lastUpdated>
                  <docDescription>{ $item//description/xs:string(.) }</docDescription>
                  <docCategory>{ $item//category/xs:string(.) }</docCategory>
                  <addedBy>{ if(fn:not(fn:empty($item//added-by))) then (map:get($user-data-map, $item//added-by), $item//added-by/xs:string(.))[1]  else ()}</addedBy>
                  <addedByRoles>{ if(fn:not(fn:empty($item//added-by))) then (map:get($user-data-map, $item//added-by-roles), $item//added-by-roles/xs:string(.))[1] else ()}</addedByRoles>
                  <url>{ concat("/v1/documents?uri=", xdmp:url-encode($uri)) }</url>
               </item>
         }</data>
         <totalNumber>{
               if ( $results ) then cts:remainder($results[1]) + ($start) else 0
         }</totalNumber>
       </results>
};
