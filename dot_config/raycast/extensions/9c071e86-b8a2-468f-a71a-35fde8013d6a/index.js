var le=Object.create;var M=Object.defineProperty;var fe=Object.getOwnPropertyDescriptor;var me=Object.getOwnPropertyNames;var de=Object.getPrototypeOf,ge=Object.prototype.hasOwnProperty;var H=t=>M(t,"__esModule",{value:!0});var j=(t,e)=>()=>(e||t((e={exports:{}}).exports,e),e.exports),pe=(t,e)=>{for(var r in e)M(t,r,{get:e[r],enumerable:!0})},U=(t,e,r,n)=>{if(e&&typeof e=="object"||typeof e=="function")for(let o of me(e))!ge.call(t,o)&&(r||o!=="default")&&M(t,o,{get:()=>e[o],enumerable:!(n=fe(e,o))||n.enumerable});return t},J=(t,e)=>U(H(M(t!=null?le(de(t)):{},"default",!e&&t&&t.__esModule?{get:()=>t.default,enumerable:!0}:{value:t,enumerable:!0})),t),ve=(t=>(e,r)=>t&&t.get(e)||(r=U(H({}),e,1),t&&t.set(e,r),r))(typeof WeakMap!="undefined"?new WeakMap:0);var Z=j(T=>{"use strict";var p=require("react");function L(){return(L=Object.assign||function(t){for(var e=1;e<arguments.length;e++){var r=arguments[e];for(var n in r)Object.prototype.hasOwnProperty.call(r,n)&&(t[n]=r[n])}return t}).apply(this,arguments)}typeof Symbol<"u"&&(Symbol.iterator||(Symbol.iterator=Symbol("Symbol.iterator"))),typeof Symbol<"u"&&(Symbol.asyncIterator||(Symbol.asyncIterator=Symbol("Symbol.asyncIterator")));var ye=typeof window<"u"&&window.document!==void 0&&window.document.createElement!==void 0?p.useLayoutEffect:p.useEffect,Se={status:"not-requested",loading:!1,result:void 0,error:void 0},B={status:"loading",loading:!0,result:void 0,error:void 0},Q=function(){},be={initialState:function(t){return t&&t.executeOnMount?B:Se},executeOnMount:!0,executeOnUpdate:!0,setLoading:function(t){return B},setResult:function(t,e){return{status:"success",loading:!1,result:t,error:void 0}},setError:function(t,e){return{status:"error",loading:!1,result:void 0,error:t}},onSuccess:Q,onError:Q},$=function(t,e,r){!e&&(e=[]);var n,o=function(s){return L({},be,{},s)}(r),l=p.useState(null),f=l[0],d=l[1],u=function(s){var g=p.useState(function(){return s.initialState(s)}),m=g[0],c=g[1],S=p.useCallback(function(){return c(s.initialState(s))},[c,s]),w=p.useCallback(function(){return c(s.setLoading(m))},[m,c]),C=p.useCallback(function(R){return c(s.setResult(R,m))},[m,c]),N=p.useCallback(function(R){return c(s.setError(R,m))},[m,c]),ce=p.useCallback(function(R){return c(L({},m,{},R))},[m,c]);return{value:m,set:c,merge:ce,reset:S,setLoading:w,setResult:C,setError:N}}(o),i=(n=p.useRef(!1),p.useEffect(function(){return n.current=!0,function(){n.current=!1}},[]),function(){return n.current}),a=function(){var s=p.useRef(null);return{set:function(g){return s.current=g},get:function(){return s.current},is:function(g){return s.current===g}}}(),b=function(s){return i()&&a.is(s)},x=function(s){var g=p.useRef(s);return ye(function(){g.current=s}),p.useCallback(function(){return g.current},[g])}(function(){for(var s=arguments.length,g=new Array(s),m=0;m<s;m++)g[m]=arguments[m];var c=function(){try{return Promise.resolve(t.apply(void 0,g))}catch(S){return Promise.reject(S)}}();return d(g),a.set(c),u.setLoading(),c.then(function(S){b(c)&&u.setResult(S),o.onSuccess(S,{isCurrent:function(){return a.is(c)}})},function(S){b(c)&&u.setError(S),o.onError(S,{isCurrent:function(){return a.is(c)}})}),c}),E=p.useCallback(function(){return x().apply(void 0,arguments)},[x]),F=!i();return p.useEffect(function(){var s=function(){return x().apply(void 0,e)};F&&o.executeOnMount&&s(),!F&&o.executeOnUpdate&&s()},e),L({},u.value,{set:u.set,merge:u.merge,reset:u.reset,execute:E,currentPromise:a.get(),currentParams:f})};function W(t,e,r){return $(t,e,r)}T.useAsync=W,T.useAsyncAbortable=function(t,e,r){var n=p.useRef();return W(function(){for(var o=arguments.length,l=new Array(o),f=0;f<o;f++)l[f]=arguments[f];try{n.current&&n.current.abort();var d=new AbortController;return n.current=d,Promise.resolve(function(u,i){try{var a=Promise.resolve(t.apply(void 0,[d.signal].concat(l)))}catch(b){return i(!0,b)}return a&&a.then?a.then(i.bind(null,!1),i.bind(null,!0)):i(!1,value)}(0,function(u,i){if(n.current===d&&(n.current=void 0),u)throw i;return i}))}catch(u){return Promise.reject(u)}},e,r)},T.useAsyncCallback=function(t,e){return $(t,[],L({},e,{executeOnMount:!1,executeOnUpdate:!1}))}});var Y=j(q=>{"use strict";var v=require("react");function I(){return I=Object.assign||function(t){for(var e=1;e<arguments.length;e++){var r=arguments[e];for(var n in r)Object.prototype.hasOwnProperty.call(r,n)&&(t[n]=r[n])}return t},I.apply(this,arguments)}var Ue=typeof Symbol<"u"?Symbol.iterator||(Symbol.iterator=Symbol("Symbol.iterator")):"@@iterator",Je=typeof Symbol<"u"?Symbol.asyncIterator||(Symbol.asyncIterator=Symbol("Symbol.asyncIterator")):"@@asyncIterator";function he(t,e){try{var r=t()}catch(n){return e(!0,n)}return r&&r.then?r.then(e.bind(null,!1),e.bind(null,!0)):e(!1,value)}var we=typeof window<"u"&&typeof window.document<"u"&&typeof window.document.createElement<"u"?v.useLayoutEffect:v.useEffect,Ce=function(e){var r=v.useRef(e);return we(function(){r.current=e}),v.useCallback(function(){return r.current},[r])},xe={status:"not-requested",loading:!1,result:void 0,error:void 0},z={status:"loading",loading:!0,result:void 0,error:void 0},Ae=function(e){return z},Oe=function(e,r){return{status:"success",loading:!1,result:e,error:void 0}},Ie=function(e,r){return{status:"error",loading:!1,result:void 0,error:e}},_=function(){},Pe={initialState:function(e){return e&&e.executeOnMount?z:xe},executeOnMount:!0,executeOnUpdate:!0,setLoading:Ae,setResult:Oe,setError:Ie,onSuccess:_,onError:_},Ee=function(e){return I({},Pe,{},e)},Re=function(e){var r=v.useState(function(){return e.initialState(e)}),n=r[0],o=r[1],l=v.useCallback(function(){return o(e.initialState(e))},[o,e]),f=v.useCallback(function(){return o(e.setLoading(n))},[n,o]),d=v.useCallback(function(a){return o(e.setResult(a,n))},[n,o]),u=v.useCallback(function(a){return o(e.setError(a,n))},[n,o]),i=v.useCallback(function(a){return o(I({},n,{},a))},[n,o]);return{value:n,set:o,merge:i,reset:l,setLoading:f,setResult:d,setError:u}},Le=function(){var e=v.useRef(!1);return v.useEffect(function(){return e.current=!0,function(){e.current=!1}},[]),function(){return e.current}},De=function(){var e=v.useRef(null);return{set:function(n){return e.current=n},get:function(){return e.current},is:function(n){return e.current===n}}},K=function(e,r,n){!r&&(r=[]);var o=Ee(n),l=v.useState(null),f=l[0],d=l[1],u=Re(o),i=Le(),a=De(),b=function(m){return i()&&a.is(m)},x=function(){for(var m=arguments.length,c=new Array(m),S=0;S<m;S++)c[S]=arguments[S];var w=function(){try{return Promise.resolve(e.apply(void 0,c))}catch(C){return Promise.reject(C)}}();return d(c),a.set(w),u.setLoading(),w.then(function(C){b(w)&&u.setResult(C),o.onSuccess(C,{isCurrent:function(){return a.is(w)}})},function(C){b(w)&&u.setError(C),o.onError(C,{isCurrent:function(){return a.is(w)}})}),w},E=Ce(x),F=v.useCallback(function(){return E().apply(void 0,arguments)},[E]),s=!i();return v.useEffect(function(){var g=function(){return E().apply(void 0,r)};s&&o.executeOnMount&&g(),!s&&o.executeOnUpdate&&g()},r),I({},u.value,{set:u.set,merge:u.merge,reset:u.reset,execute:F,currentPromise:a.get(),currentParams:f})};function X(t,e,r){return K(t,e,r)}var ke=function(e,r,n){var o=v.useRef(),l=function(){for(var d=arguments.length,u=new Array(d),i=0;i<d;i++)u[i]=arguments[i];try{o.current&&o.current.abort();var a=new AbortController;return o.current=a,Promise.resolve(he(function(){return Promise.resolve(e.apply(void 0,[a.signal].concat(u)))},function(b,x){if(o.current===a&&(o.current=void 0),b)throw x;return x}))}catch(b){return Promise.reject(b)}};return X(l,r,n)},Fe=function(e,r){return K(e,[],I({},r,{executeOnMount:!1,executeOnUpdate:!1}))};q.useAsync=X;q.useAsyncAbortable=ke;q.useAsyncCallback=Fe});var G=j((Qe,V)=>{"use strict";process.env.NODE_ENV==="production"?V.exports=Z():V.exports=Y()});var Ve={};pe(Ve,{default:()=>ie});var k=require("react"),P=require("@raycast/api");var A=require("react"),y=require("@raycast/api"),te=J(G()),Me=({onSubmit:t})=>{let[e,r]=(0,A.useState)(""),[n,o]=(0,A.useState)(),[l,f]=(0,A.useState)("new");(0,te.useAsync)(async()=>{let u=await y.LocalStorage.getItem("test-string-history");!u||o(JSON.parse(u))},[]),(0,A.useEffect)(()=>{ee[l]?r(ee[l]):r(n?.find(u=>u.id===l)?.value||"")},[l]);let d=(0,A.useCallback)(()=>{y.LocalStorage.removeItem("test-string-history"),o(void 0)},[]);return _jsx(y.Form,{actions:_jsx(y.ActionPanel,null,_jsx(y.Action.SubmitForm,{title:"Test Regex",onSubmit:t}),_jsx(y.Action,{title:"Clear Previous Test Strings",onAction:d,shortcut:{modifiers:["cmd"],key:"backspace"}}))},_jsx(y.Form.Dropdown,{id:"source",title:"",defaultValue:"new",onChange:f},_jsx(y.Form.Dropdown.Item,{value:"new",title:"New Test String"}),_jsx(y.Form.Dropdown.Item,{value:"lorem",title:"Lorem Ipsum"}),n&&_jsx(y.Form.Dropdown.Section,{title:"Previous Test Strings"},n.map(u=>_jsx(y.Form.Dropdown.Item,{key:u.id,value:u.id,title:u.value})))),_jsx(y.Form.TextArea,{id:"text",title:"",placeholder:"Enter your test string",value:e,onChange:r}))},ee={lorem:"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla malesuada viverra elit, at placerat metus dictum at. Aliquam pretium, massa nec interdum hendrerit, libero ipsum rutrum nibh, iaculis fringilla magna ante sit amet quam. Donec imperdiet leo risus, et accumsan sem malesuada eu. Nunc suscipit urna magna, sit amet tempus lectus laoreet vitae. Fusce in dolor vitae lacus luctus ullamcorper. Maecenas faucibus fringilla feugiat. Phasellus purus mauris, molestie vel dolor eget, posuere iaculis mauris. Nunc blandit neque ut semper ultrices. Cras tempus mollis pharetra. Quisque euismod orci eget augue lobortis feugiat. Suspendisse at consequat eros."},re=Me;var ae=J(G());var D=require("@raycast/api"),O=require("react");var ne=require("@raycast/api"),Te=()=>_jsx(ne.List.Item.Detail,{markdown:qe}),qe=`
# Regular Expression Cheat Sheet

## Character Classes

\`.\`

any character except newline

\`\\w\\d\\s\`

word, digit, whitespace

\`\\W\\D\\S\`

not word, digit, whitespace

\`[abc]\`

any of a, b, or c

\`[^abc]\`

not a, b, or c

\`[a-g]\`

character between a & g

## Anchors

\`^abc$\`

start / end of the string

\`\\b\\B\`

word, not-word boundary

## Escaped characters

\`\\.\\*\\\\\`

escaped special characters

\`\\t\\n\\r\`

tab, linefeed, carriage return

## Groups & Lookaround

\`(abc)\`

capture group

\`\\1\`

backreference to group #1

\`(?:abc)\`

non-capturing group

\`(?=abc)\`

positive lookahead

\`(?!abc)\`

negative lookahead

## Quantifiers & Alternation

\`a*a+a?\`

0 or more, 1 or more, 0 or 1

\`a{5}a{2,}\`

exactly five, two or more

\`a{1,3}\`

between one & three

\`a+?a{2,}?\`

match as few as possible

\`ab|cd\`

match ab or cd

`,oe=Te;var h=require("@raycast/api"),Ne=({onOptionsChange:t})=>_jsx(h.List.Dropdown,{tooltip:"Regex Options",defaultValue:"gm",onChange:t},_jsx(h.List.Dropdown.Item,{title:"No Modifiers",value:""}),_jsx(h.List.Dropdown.Item,{title:"Global (/g)",value:"g"}),_jsx(h.List.Dropdown.Item,{title:"Case-Insensitive (/i)",value:"i"}),_jsx(h.List.Dropdown.Item,{title:"Multiline (/m)",value:"m"}),_jsx(h.List.Dropdown.Item,{title:"Global, Case-Insensitive (/gi)",value:"gi"}),_jsx(h.List.Dropdown.Item,{title:"Global, Multiline (/gm)",value:"gm"}),_jsx(h.List.Dropdown.Item,{title:"Case-Insensitive, Multiline (/im)",value:"im"}),_jsx(h.List.Dropdown.Item,{title:"All Modifiers (/gim)",value:"gim"})),ue=Ne;var je=({testString:t})=>{let[e,r]=(0,O.useState)(""),[n,o]=(0,O.useState)(""),[l,f]=(0,O.useState)("gm"),d=(0,O.useCallback)(u=>{f(u)},[]);return(0,O.useEffect)(()=>{if(e===""){o(t);return}try{let u=t.replace(new RegExp(e,l),i=>`|${i}|`);o(u)}catch(u){console.log("regex error",u)}},[t,e,l]),_jsx(D.List,{isShowingDetail:!0,enableFiltering:!1,searchBarPlaceholder:"([A-Z])\\w+",searchText:e,onSearchTextChange:r,searchBarAccessory:_jsx(ue,{onOptionsChange:d})},_jsx(D.List.Item,{title:"Preview",subtitle:"",detail:_jsx(D.List.Item.Detail,{markdown:n})}),_jsx(D.List.Item,{title:"Cheat Sheet",subtitle:"",detail:_jsx(oe,null)}))},se=je;function ie(){let[t,e]=(0,k.useState)(""),[r,n]=(0,k.useState)(),{push:o}=(0,P.useNavigation)();(0,ae.useAsync)(async()=>{if(r==="new"){let f={id:Date.now().toString(),value:t},d=await P.LocalStorage.getItem("test-string-history");if(d){let u=JSON.parse(d),i=[f,...u].slice(0,5);await P.LocalStorage.setItem("test-string-history",JSON.stringify(i))}else await P.LocalStorage.setItem("test-string-history",JSON.stringify([f]))}},[r]);let l=(0,k.useCallback)(f=>{e(f.text),n(f.source),o(_jsx(se,{testString:f.text}))},[]);return _jsx(re,{onSubmit:l})}module.exports=ve(Ve);0&&(module.exports={});
