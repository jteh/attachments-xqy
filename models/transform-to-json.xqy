xquery version "1.0-ml";
module namespace t = "http://marklogic.com/roxy/model/json-util/transform-to-json";

declare namespace j = "http://marklogic.com/xdmp/json/basic";

declare variable $json-basic-ns := "http://marklogic.com/xdmp/json/basic";

declare variable $t:array-nodes := ('result');

declare function t:to-elements(
        $attributes as attribute()*
)
{
    element {fn:QName($json-basic-ns, "attributes")} {
        attribute {"type"} {"object"},
        for $attribute in $attributes
        return element {fn:QName($json-basic-ns, fn:name($attribute))} {
            attribute {"type"} {"string"},
            $attribute/fn:string()
        }
    }
};

declare function t:all-children-elements-identical(
        $nodes as node()*
)
{
    let $child-namespace-uris := for $n in $nodes return fn:namespace-uri($n)
    let $child-local-names := for $n in $nodes return fn:local-name($n)

    let $are-child-namespaces-identical := if (fn:count(fn:distinct-values($child-namespace-uris)) = 1) then fn:true() else fn:false()
    let $are-child-localnames-identical := if (fn:count(fn:distinct-values($child-local-names)) = 1) then fn:true() else fn:false()

    let $all-elements-identical := $are-child-namespaces-identical and $are-child-localnames-identical

    return
        if ($all-elements-identical)
        then fn:true()
        else fn:false()
};

declare function t:is-empty-text(
        $node as node()
)
{
    $node instance of text() and fn:normalize-space($node) = ""
};

declare function t:all-children-are-elements(
        $nodes as node()*
)
{
    let $is-all-elements :=
        fn:not(
                for $node in $nodes
                return
                    if ($node instance of element())
                    then ()
                    else <not-element/>
        )
    return
        if ($is-all-elements)
        then fn:true()
        else fn:false()
};

declare function t:is-array(
        $nodes as node()*
)
{    
    if(t:all-children-elements-identical($nodes))
    then         
        if(($nodes/fn:local-name())[1] = $t:array-nodes)
        then fn:true()
        else if(fn:count($nodes) > 1) 
        then fn:true()
        else fn:false()
    else fn:false()
};

declare function t:format-as-json-basic-xml(
        $e as node()
)
{
    (
        if (fn:empty($e/ node()))
        then
            element {fn:QName($json-basic-ns, fn:local-name($e))} {(
                if (fn:exists($e/@*))
                then ( attribute {"type"} {"object"}, t:to-elements($e/@*))
                else attribute {"type"} {"null"}
            )}
        else if ( t:all-children-are-elements($e/node()[fn:not(t:is-empty-text(.))]))
        then
            element {fn:QName($json-basic-ns, fn:local-name($e))} {(
                attribute {"type"} {if (t:is-array($e/ node())) then "array" else "object"},
                if (fn:exists($e/@*)) then t:to-elements($e/@*) else (),
                t:format-as-json-basic-xml($e/ node()[fn:not(t:is-empty-text(.))])
            )}
        else if ($e/ node() instance of text())
            then
                element {fn:QName($json-basic-ns, fn:local-name($e))} {(
                    if (fn:exists($e/@*))
                    then ( attribute {"type"} {"object"}, t:to-elements($e/@*))
                    else attribute {"type"} {"string"},
                    if (fn:exists($e/@*))
                    then <j:val type="string">{$e/ node()}</j:val>
                    else $e/ node()
                )}
            else ()
    )
};
