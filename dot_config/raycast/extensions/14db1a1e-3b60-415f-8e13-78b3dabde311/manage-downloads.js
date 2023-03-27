"use strict";var c=Object.defineProperty;var A=Object.getOwnPropertyDescriptor;var D=Object.getOwnPropertyNames;var y=Object.prototype.hasOwnProperty;var g=(o,t)=>{for(var n in t)c(o,n,{get:t[n],enumerable:!0})},S=(o,t,n,e)=>{if(t&&typeof t=="object"||typeof t=="function")for(let s of D(t))!y.call(o,s)&&s!==n&&c(o,s,{get:()=>t[s],enumerable:!(e=A(t,s))||e.enumerable});return o};var L=o=>S(c({},"__esModule",{value:!0}),o);var k={};g(k,{default:()=>u});module.exports=L(k);var i=require("@raycast/api"),d=require("react");var l=require("fs"),h=require("os"),f=require("path"),a=(0,f.join)((0,h.homedir)(),"Downloads");function m(){return(0,l.readdirSync)(a).filter(t=>!t.startsWith(".")).map(t=>{let n=(0,f.join)(a,t),e=(0,l.statSync)(n).mtime;return{file:t,path:n,lastModifiedAt:e}}).sort((t,n)=>n.lastModifiedAt.getTime()-t.lastModifiedAt.getTime())}var r=require("react/jsx-runtime");function u(){let[o,t]=(0,d.useState)(m());function n(e){t(s=>s.filter(p=>Array.isArray(e)?!e.includes(p.path):e!==p.path))}return(0,r.jsxs)(i.List,{children:[o.length===0&&(0,r.jsx)(i.List.EmptyView,{icon:{fileIcon:a},title:"No downloads found",description:"Well, first download some files \xAF\\_(\u30C4)_/\xAF"}),o.map(e=>(0,r.jsx)(i.List.Item,{title:e.file,icon:{fileIcon:e.path},accessories:[{date:e.lastModifiedAt,tooltip:`Last modified: ${e.lastModifiedAt.toLocaleString()}`}],actions:(0,r.jsxs)(i.ActionPanel,{children:[(0,r.jsxs)(i.ActionPanel.Section,{children:[(0,r.jsx)(i.Action.Open,{title:"Open File",target:e.path}),(0,r.jsx)(i.Action.ShowInFinder,{path:e.path}),(0,r.jsx)(i.Action.OpenWith,{path:e.path,shortcut:{modifiers:["cmd"],key:"o"}})]}),(0,r.jsxs)(i.ActionPanel.Section,{children:[(0,r.jsx)(i.Action.Trash,{title:"Delete Download",paths:e.path,shortcut:{modifiers:["ctrl"],key:"x"},onTrash:n}),(0,r.jsx)(i.Action.Trash,{title:"Delete All Downloads",paths:o.map(s=>s.path),shortcut:{modifiers:["ctrl","shift"],key:"x"},onTrash:n})]})]})},e.path))]})}0&&(module.exports={});