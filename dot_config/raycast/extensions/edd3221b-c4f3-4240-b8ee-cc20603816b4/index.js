"use strict";var hn=Object.create;var M=Object.defineProperty;var Sn=Object.getOwnPropertyDescriptor;var gn=Object.getOwnPropertyNames;var yn=Object.getPrototypeOf,xn=Object.prototype.hasOwnProperty;var c=(e,t)=>()=>(t||e((t={exports:{}}).exports,t),t.exports),bn=(e,t)=>{for(var r in t)M(e,r,{get:t[r],enumerable:!0})},Pe=(e,t,r,n)=>{if(t&&typeof t=="object"||typeof t=="function")for(let s of gn(t))!xn.call(e,s)&&s!==r&&M(e,s,{get:()=>t[s],enumerable:!(n=Sn(t,s))||n.enumerable});return e};var ee=(e,t,r)=>(r=e!=null?hn(yn(e)):{},Pe(t||!e||!e.__esModule?M(r,"default",{value:e,enumerable:!0}):r,e)),wn=e=>Pe(M({},"__esModule",{value:!0}),e);var qe=c((bs,Re)=>{Re.exports=Ae;Ae.sync=En;var Ge=require("fs");function vn(e,t){var r=t.pathExt!==void 0?t.pathExt:process.env.PATHEXT;if(!r||(r=r.split(";"),r.indexOf("")!==-1))return!0;for(var n=0;n<r.length;n++){var s=r[n].toLowerCase();if(s&&e.substr(-s.length).toLowerCase()===s)return!0}return!1}function Ce(e,t,r){return!e.isSymbolicLink()&&!e.isFile()?!1:vn(t,r)}function Ae(e,t,r){Ge.stat(e,function(n,s){r(n,n?!1:Ce(s,e,t))})}function En(e,t){return Ce(Ge.statSync(e),e,t)}});var _e=c((ws,ke)=>{ke.exports=Ne;Ne.sync=In;var Oe=require("fs");function Ne(e,t,r){Oe.stat(e,function(n,s){r(n,n?!1:Le(s,t))})}function In(e,t){return Le(Oe.statSync(e),t)}function Le(e,t){return e.isFile()&&Tn(e,t)}function Tn(e,t){var r=e.mode,n=e.uid,s=e.gid,o=t.uid!==void 0?t.uid:process.getuid&&process.getuid(),i=t.gid!==void 0?t.gid:process.getgid&&process.getgid(),a=parseInt("100",8),u=parseInt("010",8),l=parseInt("001",8),f=a|u,h=r&l||r&u&&s===i||r&a&&n===o||r&f&&o===0;return h}});var Be=c((Es,$e)=>{var vs=require("fs"),j;process.platform==="win32"||global.TESTING_WINDOWS?j=qe():j=_e();$e.exports=te;te.sync=Pn;function te(e,t,r){if(typeof t=="function"&&(r=t,t={}),!r){if(typeof Promise!="function")throw new TypeError("callback not provided");return new Promise(function(n,s){te(e,t||{},function(o,i){o?s(o):n(i)})})}j(e,t||{},function(n,s){n&&(n.code==="EACCES"||t&&t.ignoreErrors)&&(n=null,s=!1),r(n,s)})}function Pn(e,t){try{return j.sync(e,t||{})}catch(r){if(t&&t.ignoreErrors||r.code==="EACCES")return!1;throw r}}});var He=c((Is,Xe)=>{var I=process.platform==="win32"||process.env.OSTYPE==="cygwin"||process.env.OSTYPE==="msys",Me=require("path"),Gn=I?";":":",je=Be(),Fe=e=>Object.assign(new Error(`not found: ${e}`),{code:"ENOENT"}),Ue=(e,t)=>{let r=t.colon||Gn,n=e.match(/\//)||I&&e.match(/\\/)?[""]:[...I?[process.cwd()]:[],...(t.path||process.env.PATH||"").split(r)],s=I?t.pathExt||process.env.PATHEXT||".EXE;.CMD;.BAT;.COM":"",o=I?s.split(r):[""];return I&&e.indexOf(".")!==-1&&o[0]!==""&&o.unshift(""),{pathEnv:n,pathExt:o,pathExtExe:s}},De=(e,t,r)=>{typeof t=="function"&&(r=t,t={}),t||(t={});let{pathEnv:n,pathExt:s,pathExtExe:o}=Ue(e,t),i=[],a=l=>new Promise((f,h)=>{if(l===n.length)return t.all&&i.length?f(i):h(Fe(e));let m=n[l],S=/^".*"$/.test(m)?m.slice(1,-1):m,g=Me.join(S,e),y=!S&&/^\.[\\\/]/.test(e)?e.slice(0,2)+g:g;f(u(y,l,0))}),u=(l,f,h)=>new Promise((m,S)=>{if(h===s.length)return m(a(f+1));let g=s[h];je(l+g,{pathExt:o},(y,E)=>{if(!y&&E)if(t.all)i.push(l+g);else return m(l+g);return m(u(l,f,h+1))})});return r?a(0).then(l=>r(null,l),r):a(0)},Cn=(e,t)=>{t=t||{};let{pathEnv:r,pathExt:n,pathExtExe:s}=Ue(e,t),o=[];for(let i=0;i<r.length;i++){let a=r[i],u=/^".*"$/.test(a)?a.slice(1,-1):a,l=Me.join(u,e),f=!u&&/^\.[\\\/]/.test(e)?e.slice(0,2)+l:l;for(let h=0;h<n.length;h++){let m=f+n[h];try{if(je.sync(m,{pathExt:s}))if(t.all)o.push(m);else return m}catch{}}}if(t.all&&o.length)return o;if(t.nothrow)return null;throw Fe(e)};Xe.exports=De;De.sync=Cn});var re=c((Ts,ne)=>{"use strict";var Ke=(e={})=>{let t=e.env||process.env;return(e.platform||process.platform)!=="win32"?"PATH":Object.keys(t).reverse().find(n=>n.toUpperCase()==="PATH")||"Path"};ne.exports=Ke;ne.exports.default=Ke});var Qe=c((Ps,Ve)=>{"use strict";var We=require("path"),An=He(),Rn=re();function ze(e,t){let r=e.options.env||process.env,n=process.cwd(),s=e.options.cwd!=null,o=s&&process.chdir!==void 0&&!process.chdir.disabled;if(o)try{process.chdir(e.options.cwd)}catch{}let i;try{i=An.sync(e.command,{path:r[Rn({env:r})],pathExt:t?We.delimiter:void 0})}catch{}finally{o&&process.chdir(n)}return i&&(i=We.resolve(s?e.options.cwd:"",i)),i}function qn(e){return ze(e)||ze(e,!0)}Ve.exports=qn});var Ye=c((Gs,oe)=>{"use strict";var se=/([()\][%!^"`<>&|;, *?])/g;function On(e){return e=e.replace(se,"^$1"),e}function Nn(e,t){return e=`${e}`,e=e.replace(/(\\*)"/g,'$1$1\\"'),e=e.replace(/(\\*)$/,"$1$1"),e=`"${e}"`,e=e.replace(se,"^$1"),t&&(e=e.replace(se,"^$1")),e}oe.exports.command=On;oe.exports.argument=Nn});var Je=c((Cs,Ze)=>{"use strict";Ze.exports=/^#!(.*)/});var tt=c((As,et)=>{"use strict";var Ln=Je();et.exports=(e="")=>{let t=e.match(Ln);if(!t)return null;let[r,n]=t[0].replace(/#! ?/,"").split(" "),s=r.split("/").pop();return s==="env"?n:n?`${s} ${n}`:s}});var rt=c((Rs,nt)=>{"use strict";var ie=require("fs"),kn=tt();function _n(e){let r=Buffer.alloc(150),n;try{n=ie.openSync(e,"r"),ie.readSync(n,r,0,150,0),ie.closeSync(n)}catch{}return kn(r.toString())}nt.exports=_n});var at=c((qs,it)=>{"use strict";var $n=require("path"),st=Qe(),ot=Ye(),Bn=rt(),Mn=process.platform==="win32",jn=/\.(?:com|exe)$/i,Fn=/node_modules[\\/].bin[\\/][^\\/]+\.cmd$/i;function Un(e){e.file=st(e);let t=e.file&&Bn(e.file);return t?(e.args.unshift(e.file),e.command=t,st(e)):e.file}function Dn(e){if(!Mn)return e;let t=Un(e),r=!jn.test(t);if(e.options.forceShell||r){let n=Fn.test(t);e.command=$n.normalize(e.command),e.command=ot.command(e.command),e.args=e.args.map(o=>ot.argument(o,n));let s=[e.command].concat(e.args).join(" ");e.args=["/d","/s","/c",`"${s}"`],e.command=process.env.comspec||"cmd.exe",e.options.windowsVerbatimArguments=!0}return e}function Xn(e,t,r){t&&!Array.isArray(t)&&(r=t,t=null),t=t?t.slice(0):[],r=Object.assign({},r);let n={command:e,args:t,options:r,file:void 0,original:{command:e,args:t}};return r.shell?n:Dn(n)}it.exports=Xn});var lt=c((Os,ut)=>{"use strict";var ae=process.platform==="win32";function ce(e,t){return Object.assign(new Error(`${t} ${e.command} ENOENT`),{code:"ENOENT",errno:"ENOENT",syscall:`${t} ${e.command}`,path:e.command,spawnargs:e.args})}function Hn(e,t){if(!ae)return;let r=e.emit;e.emit=function(n,s){if(n==="exit"){let o=ct(s,t,"spawn");if(o)return r.call(e,"error",o)}return r.apply(e,arguments)}}function ct(e,t){return ae&&e===1&&!t.file?ce(t.original,"spawn"):null}function Kn(e,t){return ae&&e===1&&!t.file?ce(t.original,"spawnSync"):null}ut.exports={hookChildProcess:Hn,verifyENOENT:ct,verifyENOENTSync:Kn,notFoundError:ce}});var pt=c((Ns,T)=>{"use strict";var dt=require("child_process"),ue=at(),le=lt();function ft(e,t,r){let n=ue(e,t,r),s=dt.spawn(n.command,n.args,n.options);return le.hookChildProcess(s,n),s}function Wn(e,t,r){let n=ue(e,t,r),s=dt.spawnSync(n.command,n.args,n.options);return s.error=s.error||le.verifyENOENTSync(s.status,n),s}T.exports=ft;T.exports.spawn=ft;T.exports.sync=Wn;T.exports._parse=ue;T.exports._enoent=le});var ht=c((Ls,mt)=>{"use strict";mt.exports=e=>{let t=typeof e=="string"?`
`:`
`.charCodeAt(),r=typeof e=="string"?"\r":"\r".charCodeAt();return e[e.length-1]===t&&(e=e.slice(0,e.length-1)),e[e.length-1]===r&&(e=e.slice(0,e.length-1)),e}});var yt=c((ks,N)=>{"use strict";var O=require("path"),St=re(),gt=e=>{e={cwd:process.cwd(),path:process.env[St()],execPath:process.execPath,...e};let t,r=O.resolve(e.cwd),n=[];for(;t!==r;)n.push(O.join(r,"node_modules/.bin")),t=r,r=O.resolve(r,"..");let s=O.resolve(e.cwd,e.execPath,"..");return n.push(s),n.concat(e.path).join(O.delimiter)};N.exports=gt;N.exports.default=gt;N.exports.env=e=>{e={env:process.env,...e};let t={...e.env},r=St({env:t});return e.path=t[r],t[r]=N.exports(e),t}});var bt=c((_s,de)=>{"use strict";var xt=(e,t)=>{for(let r of Reflect.ownKeys(t))Object.defineProperty(e,r,Object.getOwnPropertyDescriptor(t,r));return e};de.exports=xt;de.exports.default=xt});var vt=c(($s,U)=>{"use strict";var zn=bt(),F=new WeakMap,wt=(e,t={})=>{if(typeof e!="function")throw new TypeError("Expected a function");let r,n=0,s=e.displayName||e.name||"<anonymous>",o=function(...i){if(F.set(o,++n),n===1)r=e.apply(this,i),e=null;else if(t.throw===!0)throw new Error(`Function \`${s}\` can only be called once`);return r};return zn(o,e),F.set(o,n),o};U.exports=wt;U.exports.default=wt;U.exports.callCount=e=>{if(!F.has(e))throw new Error(`The given function \`${e.name}\` is not wrapped by the \`onetime\` package`);return F.get(e)}});var Et=c(D=>{"use strict";Object.defineProperty(D,"__esModule",{value:!0});D.SIGNALS=void 0;var Vn=[{name:"SIGHUP",number:1,action:"terminate",description:"Terminal closed",standard:"posix"},{name:"SIGINT",number:2,action:"terminate",description:"User interruption with CTRL-C",standard:"ansi"},{name:"SIGQUIT",number:3,action:"core",description:"User interruption with CTRL-\\",standard:"posix"},{name:"SIGILL",number:4,action:"core",description:"Invalid machine instruction",standard:"ansi"},{name:"SIGTRAP",number:5,action:"core",description:"Debugger breakpoint",standard:"posix"},{name:"SIGABRT",number:6,action:"core",description:"Aborted",standard:"ansi"},{name:"SIGIOT",number:6,action:"core",description:"Aborted",standard:"bsd"},{name:"SIGBUS",number:7,action:"core",description:"Bus error due to misaligned, non-existing address or paging error",standard:"bsd"},{name:"SIGEMT",number:7,action:"terminate",description:"Command should be emulated but is not implemented",standard:"other"},{name:"SIGFPE",number:8,action:"core",description:"Floating point arithmetic error",standard:"ansi"},{name:"SIGKILL",number:9,action:"terminate",description:"Forced termination",standard:"posix",forced:!0},{name:"SIGUSR1",number:10,action:"terminate",description:"Application-specific signal",standard:"posix"},{name:"SIGSEGV",number:11,action:"core",description:"Segmentation fault",standard:"ansi"},{name:"SIGUSR2",number:12,action:"terminate",description:"Application-specific signal",standard:"posix"},{name:"SIGPIPE",number:13,action:"terminate",description:"Broken pipe or socket",standard:"posix"},{name:"SIGALRM",number:14,action:"terminate",description:"Timeout or timer",standard:"posix"},{name:"SIGTERM",number:15,action:"terminate",description:"Termination",standard:"ansi"},{name:"SIGSTKFLT",number:16,action:"terminate",description:"Stack is empty or overflowed",standard:"other"},{name:"SIGCHLD",number:17,action:"ignore",description:"Child process terminated, paused or unpaused",standard:"posix"},{name:"SIGCLD",number:17,action:"ignore",description:"Child process terminated, paused or unpaused",standard:"other"},{name:"SIGCONT",number:18,action:"unpause",description:"Unpaused",standard:"posix",forced:!0},{name:"SIGSTOP",number:19,action:"pause",description:"Paused",standard:"posix",forced:!0},{name:"SIGTSTP",number:20,action:"pause",description:'Paused using CTRL-Z or "suspend"',standard:"posix"},{name:"SIGTTIN",number:21,action:"pause",description:"Background process cannot read terminal input",standard:"posix"},{name:"SIGBREAK",number:21,action:"terminate",description:"User interruption with CTRL-BREAK",standard:"other"},{name:"SIGTTOU",number:22,action:"pause",description:"Background process cannot write to terminal output",standard:"posix"},{name:"SIGURG",number:23,action:"ignore",description:"Socket received out-of-band data",standard:"bsd"},{name:"SIGXCPU",number:24,action:"core",description:"Process timed out",standard:"bsd"},{name:"SIGXFSZ",number:25,action:"core",description:"File too big",standard:"bsd"},{name:"SIGVTALRM",number:26,action:"terminate",description:"Timeout or timer",standard:"bsd"},{name:"SIGPROF",number:27,action:"terminate",description:"Timeout or timer",standard:"bsd"},{name:"SIGWINCH",number:28,action:"ignore",description:"Terminal window size changed",standard:"bsd"},{name:"SIGIO",number:29,action:"terminate",description:"I/O is available",standard:"other"},{name:"SIGPOLL",number:29,action:"terminate",description:"Watched event",standard:"other"},{name:"SIGINFO",number:29,action:"ignore",description:"Request for process information",standard:"other"},{name:"SIGPWR",number:30,action:"terminate",description:"Device running out of power",standard:"systemv"},{name:"SIGSYS",number:31,action:"core",description:"Invalid system call",standard:"other"},{name:"SIGUNUSED",number:31,action:"terminate",description:"Invalid system call",standard:"other"}];D.SIGNALS=Vn});var fe=c(P=>{"use strict";Object.defineProperty(P,"__esModule",{value:!0});P.SIGRTMAX=P.getRealtimeSignals=void 0;var Qn=function(){let e=Tt-It+1;return Array.from({length:e},Yn)};P.getRealtimeSignals=Qn;var Yn=function(e,t){return{name:`SIGRT${t+1}`,number:It+t,action:"terminate",description:"Application-specific signal (realtime)",standard:"posix"}},It=34,Tt=64;P.SIGRTMAX=Tt});var Pt=c(X=>{"use strict";Object.defineProperty(X,"__esModule",{value:!0});X.getSignals=void 0;var Zn=require("os"),Jn=Et(),er=fe(),tr=function(){let e=(0,er.getRealtimeSignals)();return[...Jn.SIGNALS,...e].map(nr)};X.getSignals=tr;var nr=function({name:e,number:t,description:r,action:n,forced:s=!1,standard:o}){let{signals:{[e]:i}}=Zn.constants,a=i!==void 0;return{name:e,number:a?i:t,description:r,supported:a,action:n,forced:s,standard:o}}});var Ct=c(G=>{"use strict";Object.defineProperty(G,"__esModule",{value:!0});G.signalsByNumber=G.signalsByName=void 0;var rr=require("os"),Gt=Pt(),sr=fe(),or=function(){return(0,Gt.getSignals)().reduce(ir,{})},ir=function(e,{name:t,number:r,description:n,supported:s,action:o,forced:i,standard:a}){return{...e,[t]:{name:t,number:r,description:n,supported:s,action:o,forced:i,standard:a}}},ar=or();G.signalsByName=ar;var cr=function(){let e=(0,Gt.getSignals)(),t=sr.SIGRTMAX+1,r=Array.from({length:t},(n,s)=>ur(s,e));return Object.assign({},...r)},ur=function(e,t){let r=lr(e,t);if(r===void 0)return{};let{name:n,description:s,supported:o,action:i,forced:a,standard:u}=r;return{[e]:{name:n,number:e,description:s,supported:o,action:i,forced:a,standard:u}}},lr=function(e,t){let r=t.find(({name:n})=>rr.constants.signals[n]===e);return r!==void 0?r:t.find(n=>n.number===e)},dr=cr();G.signalsByNumber=dr});var Rt=c((Us,At)=>{"use strict";var{signalsByName:fr}=Ct(),pr=({timedOut:e,timeout:t,errorCode:r,signal:n,signalDescription:s,exitCode:o,isCanceled:i})=>e?`timed out after ${t} milliseconds`:i?"was canceled":r!==void 0?`failed with ${r}`:n!==void 0?`was killed with ${n} (${s})`:o!==void 0?`failed with exit code ${o}`:"failed",mr=({stdout:e,stderr:t,all:r,error:n,signal:s,exitCode:o,command:i,escapedCommand:a,timedOut:u,isCanceled:l,killed:f,parsed:{options:{timeout:h}}})=>{o=o===null?void 0:o,s=s===null?void 0:s;let m=s===void 0?void 0:fr[s].description,S=n&&n.code,y=`Command ${pr({timedOut:u,timeout:h,errorCode:S,signal:s,signalDescription:m,exitCode:o,isCanceled:l})}: ${i}`,E=Object.prototype.toString.call(n)==="[object Error]",$=E?`${y}
${n.message}`:y,B=[$,t,e].filter(Boolean).join(`
`);return E?(n.originalMessage=n.message,n.message=B):n=new Error(B),n.shortMessage=$,n.command=i,n.escapedCommand=a,n.exitCode=o,n.signal=s,n.signalDescription=m,n.stdout=e,n.stderr=t,r!==void 0&&(n.all=r),"bufferedData"in n&&delete n.bufferedData,n.failed=!0,n.timedOut=Boolean(u),n.isCanceled=l,n.killed=f&&!u,n};At.exports=mr});var Ot=c((Ds,pe)=>{"use strict";var H=["stdin","stdout","stderr"],hr=e=>H.some(t=>e[t]!==void 0),qt=e=>{if(!e)return;let{stdio:t}=e;if(t===void 0)return H.map(n=>e[n]);if(hr(e))throw new Error(`It's not possible to provide \`stdio\` in combination with one of ${H.map(n=>`\`${n}\``).join(", ")}`);if(typeof t=="string")return t;if(!Array.isArray(t))throw new TypeError(`Expected \`stdio\` to be of type \`string\` or \`Array\`, got \`${typeof t}\``);let r=Math.max(t.length,H.length);return Array.from({length:r},(n,s)=>t[s])};pe.exports=qt;pe.exports.node=e=>{let t=qt(e);return t==="ipc"?"ipc":t===void 0||typeof t=="string"?[t,t,t,"ipc"]:t.includes("ipc")?t:[...t,"ipc"]}});var Nt=c((Xs,K)=>{K.exports=["SIGABRT","SIGALRM","SIGHUP","SIGINT","SIGTERM"];process.platform!=="win32"&&K.exports.push("SIGVTALRM","SIGXCPU","SIGXFSZ","SIGUSR2","SIGTRAP","SIGSYS","SIGQUIT","SIGIOT");process.platform==="linux"&&K.exports.push("SIGIO","SIGPOLL","SIGPWR","SIGSTKFLT","SIGUNUSED")});var Bt=c((Hs,R)=>{var d=global.process,b=function(e){return e&&typeof e=="object"&&typeof e.removeListener=="function"&&typeof e.emit=="function"&&typeof e.reallyExit=="function"&&typeof e.listeners=="function"&&typeof e.kill=="function"&&typeof e.pid=="number"&&typeof e.on=="function"};b(d)?(Lt=require("assert"),C=Nt(),kt=/^win/i.test(d.platform),L=require("events"),typeof L!="function"&&(L=L.EventEmitter),d.__signal_exit_emitter__?p=d.__signal_exit_emitter__:(p=d.__signal_exit_emitter__=new L,p.count=0,p.emitted={}),p.infinite||(p.setMaxListeners(1/0),p.infinite=!0),R.exports=function(e,t){if(!b(global.process))return function(){};Lt.equal(typeof e,"function","a callback must be provided for exit handler"),A===!1&&me();var r="exit";t&&t.alwaysLast&&(r="afterexit");var n=function(){p.removeListener(r,e),p.listeners("exit").length===0&&p.listeners("afterexit").length===0&&W()};return p.on(r,e),n},W=function(){!A||!b(global.process)||(A=!1,C.forEach(function(t){try{d.removeListener(t,z[t])}catch{}}),d.emit=V,d.reallyExit=he,p.count-=1)},R.exports.unload=W,w=function(t,r,n){p.emitted[t]||(p.emitted[t]=!0,p.emit(t,r,n))},z={},C.forEach(function(e){z[e]=function(){if(!!b(global.process)){var r=d.listeners(e);r.length===p.count&&(W(),w("exit",null,e),w("afterexit",null,e),kt&&e==="SIGHUP"&&(e="SIGINT"),d.kill(d.pid,e))}}}),R.exports.signals=function(){return C},A=!1,me=function(){A||!b(global.process)||(A=!0,p.count+=1,C=C.filter(function(t){try{return d.on(t,z[t]),!0}catch{return!1}}),d.emit=$t,d.reallyExit=_t)},R.exports.load=me,he=d.reallyExit,_t=function(t){!b(global.process)||(d.exitCode=t||0,w("exit",d.exitCode,null),w("afterexit",d.exitCode,null),he.call(d,d.exitCode))},V=d.emit,$t=function(t,r){if(t==="exit"&&b(global.process)){r!==void 0&&(d.exitCode=r);var n=V.apply(this,arguments);return w("exit",d.exitCode,null),w("afterexit",d.exitCode,null),n}else return V.apply(this,arguments)}):R.exports=function(){return function(){}};var Lt,C,kt,L,p,W,w,z,A,me,he,_t,V,$t});var jt=c((Ks,Mt)=>{"use strict";var Sr=require("os"),gr=Bt(),yr=1e3*5,xr=(e,t="SIGTERM",r={})=>{let n=e(t);return br(e,t,r,n),n},br=(e,t,r,n)=>{if(!wr(t,r,n))return;let s=Er(r),o=setTimeout(()=>{e("SIGKILL")},s);o.unref&&o.unref()},wr=(e,{forceKillAfterTimeout:t},r)=>vr(e)&&t!==!1&&r,vr=e=>e===Sr.constants.signals.SIGTERM||typeof e=="string"&&e.toUpperCase()==="SIGTERM",Er=({forceKillAfterTimeout:e=!0})=>{if(e===!0)return yr;if(!Number.isFinite(e)||e<0)throw new TypeError(`Expected the \`forceKillAfterTimeout\` option to be a non-negative integer, got \`${e}\` (${typeof e})`);return e},Ir=(e,t)=>{e.kill()&&(t.isCanceled=!0)},Tr=(e,t,r)=>{e.kill(t),r(Object.assign(new Error("Timed out"),{timedOut:!0,signal:t}))},Pr=(e,{timeout:t,killSignal:r="SIGTERM"},n)=>{if(t===0||t===void 0)return n;let s,o=new Promise((a,u)=>{s=setTimeout(()=>{Tr(e,r,u)},t)}),i=n.finally(()=>{clearTimeout(s)});return Promise.race([o,i])},Gr=({timeout:e})=>{if(e!==void 0&&(!Number.isFinite(e)||e<0))throw new TypeError(`Expected the \`timeout\` option to be a non-negative integer, got \`${e}\` (${typeof e})`)},Cr=async(e,{cleanup:t,detached:r},n)=>{if(!t||r)return n;let s=gr(()=>{e.kill()});return n.finally(()=>{s()})};Mt.exports={spawnedKill:xr,spawnedCancel:Ir,setupTimeout:Pr,validateTimeout:Gr,setExitHandler:Cr}});var Ut=c((Ws,Ft)=>{"use strict";var x=e=>e!==null&&typeof e=="object"&&typeof e.pipe=="function";x.writable=e=>x(e)&&e.writable!==!1&&typeof e._write=="function"&&typeof e._writableState=="object";x.readable=e=>x(e)&&e.readable!==!1&&typeof e._read=="function"&&typeof e._readableState=="object";x.duplex=e=>x.writable(e)&&x.readable(e);x.transform=e=>x.duplex(e)&&typeof e._transform=="function";Ft.exports=x});var Xt=c((zs,Dt)=>{"use strict";var{PassThrough:Ar}=require("stream");Dt.exports=e=>{e={...e};let{array:t}=e,{encoding:r}=e,n=r==="buffer",s=!1;t?s=!(r||n):r=r||"utf8",n&&(r=null);let o=new Ar({objectMode:s});r&&o.setEncoding(r);let i=0,a=[];return o.on("data",u=>{a.push(u),s?i=a.length:i+=u.length}),o.getBufferedValue=()=>t?a:n?Buffer.concat(a,i):a.join(""),o.getBufferedLength=()=>i,o}});var Ht=c((Vs,k)=>{"use strict";var{constants:Rr}=require("buffer"),qr=require("stream"),{promisify:Or}=require("util"),Nr=Xt(),Lr=Or(qr.pipeline),Q=class extends Error{constructor(){super("maxBuffer exceeded"),this.name="MaxBufferError"}};async function Se(e,t){if(!e)throw new Error("Expected a stream");t={maxBuffer:1/0,...t};let{maxBuffer:r}=t,n=Nr(t);return await new Promise((s,o)=>{let i=a=>{a&&n.getBufferedLength()<=Rr.MAX_LENGTH&&(a.bufferedData=n.getBufferedValue()),o(a)};(async()=>{try{await Lr(e,n),s()}catch(a){i(a)}})(),n.on("data",()=>{n.getBufferedLength()>r&&i(new Q)})}),n.getBufferedValue()}k.exports=Se;k.exports.buffer=(e,t)=>Se(e,{...t,encoding:"buffer"});k.exports.array=(e,t)=>Se(e,{...t,array:!0});k.exports.MaxBufferError=Q});var Wt=c((Qs,Kt)=>{"use strict";var{PassThrough:kr}=require("stream");Kt.exports=function(){var e=[],t=new kr({objectMode:!0});return t.setMaxListeners(0),t.add=r,t.isEmpty=n,t.on("unpipe",s),Array.prototype.slice.call(arguments).forEach(r),t;function r(o){return Array.isArray(o)?(o.forEach(r),this):(e.push(o),o.once("end",s.bind(null,o)),o.once("error",t.emit.bind(t,"error")),o.pipe(t,{end:!1}),this)}function n(){return e.length==0}function s(o){e=e.filter(function(i){return i!==o}),!e.length&&t.readable&&t.end()}}});var Yt=c((Ys,Qt)=>{"use strict";var Vt=Ut(),zt=Ht(),_r=Wt(),$r=(e,t)=>{t===void 0||e.stdin===void 0||(Vt(t)?t.pipe(e.stdin):e.stdin.end(t))},Br=(e,{all:t})=>{if(!t||!e.stdout&&!e.stderr)return;let r=_r();return e.stdout&&r.add(e.stdout),e.stderr&&r.add(e.stderr),r},ge=async(e,t)=>{if(!!e){e.destroy();try{return await t}catch(r){return r.bufferedData}}},ye=(e,{encoding:t,buffer:r,maxBuffer:n})=>{if(!(!e||!r))return t?zt(e,{encoding:t,maxBuffer:n}):zt.buffer(e,{maxBuffer:n})},Mr=async({stdout:e,stderr:t,all:r},{encoding:n,buffer:s,maxBuffer:o},i)=>{let a=ye(e,{encoding:n,buffer:s,maxBuffer:o}),u=ye(t,{encoding:n,buffer:s,maxBuffer:o}),l=ye(r,{encoding:n,buffer:s,maxBuffer:o*2});try{return await Promise.all([i,a,u,l])}catch(f){return Promise.all([{error:f,signal:f.signal,timedOut:f.timedOut},ge(e,a),ge(t,u),ge(r,l)])}},jr=({input:e})=>{if(Vt(e))throw new TypeError("The `input` option cannot be a stream in sync mode")};Qt.exports={handleInput:$r,makeAllStream:Br,getSpawnedResult:Mr,validateInputSync:jr}});var Jt=c((Zs,Zt)=>{"use strict";var Fr=(async()=>{})().constructor.prototype,Ur=["then","catch","finally"].map(e=>[e,Reflect.getOwnPropertyDescriptor(Fr,e)]),Dr=(e,t)=>{for(let[r,n]of Ur){let s=typeof t=="function"?(...o)=>Reflect.apply(n.value,t(),o):n.value.bind(t);Reflect.defineProperty(e,r,{...n,value:s})}return e},Xr=e=>new Promise((t,r)=>{e.on("exit",(n,s)=>{t({exitCode:n,signal:s})}),e.on("error",n=>{r(n)}),e.stdin&&e.stdin.on("error",n=>{r(n)})});Zt.exports={mergePromise:Dr,getSpawnedPromise:Xr}});var nn=c((Js,tn)=>{"use strict";var en=(e,t=[])=>Array.isArray(t)?[e,...t]:[e],Hr=/^[\w.-]+$/,Kr=/"/g,Wr=e=>typeof e!="string"||Hr.test(e)?e:`"${e.replace(Kr,'\\"')}"`,zr=(e,t)=>en(e,t).join(" "),Vr=(e,t)=>en(e,t).map(r=>Wr(r)).join(" "),Qr=/ +/g,Yr=e=>{let t=[];for(let r of e.trim().split(Qr)){let n=t[t.length-1];n&&n.endsWith("\\")?t[t.length-1]=`${n.slice(0,-1)} ${r}`:t.push(r)}return t};tn.exports={joinCommand:zr,getEscapedCommand:Vr,parseCommand:Yr}});var ln=c((eo,q)=>{"use strict";var Zr=require("path"),xe=require("child_process"),Jr=pt(),es=ht(),ts=yt(),ns=vt(),Y=Rt(),sn=Ot(),{spawnedKill:rs,spawnedCancel:ss,setupTimeout:os,validateTimeout:is,setExitHandler:as}=jt(),{handleInput:cs,getSpawnedResult:us,makeAllStream:ls,validateInputSync:ds}=Yt(),{mergePromise:rn,getSpawnedPromise:fs}=Jt(),{joinCommand:on,parseCommand:an,getEscapedCommand:cn}=nn(),ps=1e3*1e3*100,ms=({env:e,extendEnv:t,preferLocal:r,localDir:n,execPath:s})=>{let o=t?{...process.env,...e}:e;return r?ts.env({env:o,cwd:n,execPath:s}):o},un=(e,t,r={})=>{let n=Jr._parse(e,t,r);return e=n.command,t=n.args,r=n.options,r={maxBuffer:ps,buffer:!0,stripFinalNewline:!0,extendEnv:!0,preferLocal:!1,localDir:r.cwd||process.cwd(),execPath:process.execPath,encoding:"utf8",reject:!0,cleanup:!0,all:!1,windowsHide:!0,...r},r.env=ms(r),r.stdio=sn(r),process.platform==="win32"&&Zr.basename(e,".exe")==="cmd"&&t.unshift("/q"),{file:e,args:t,options:r,parsed:n}},_=(e,t,r)=>typeof t!="string"&&!Buffer.isBuffer(t)?r===void 0?void 0:"":e.stripFinalNewline?es(t):t,Z=(e,t,r)=>{let n=un(e,t,r),s=on(e,t),o=cn(e,t);is(n.options);let i;try{i=xe.spawn(n.file,n.args,n.options)}catch(S){let g=new xe.ChildProcess,y=Promise.reject(Y({error:S,stdout:"",stderr:"",all:"",command:s,escapedCommand:o,parsed:n,timedOut:!1,isCanceled:!1,killed:!1}));return rn(g,y)}let a=fs(i),u=os(i,n.options,a),l=as(i,n.options,u),f={isCanceled:!1};i.kill=rs.bind(null,i.kill.bind(i)),i.cancel=ss.bind(null,i,f);let m=ns(async()=>{let[{error:S,exitCode:g,signal:y,timedOut:E},$,B,mn]=await us(i,n.options,l),ve=_(n.options,$),Ee=_(n.options,B),Ie=_(n.options,mn);if(S||g!==0||y!==null){let Te=Y({error:S,exitCode:g,signal:y,stdout:ve,stderr:Ee,all:Ie,command:s,escapedCommand:o,parsed:n,timedOut:E,isCanceled:f.isCanceled,killed:i.killed});if(!n.options.reject)return Te;throw Te}return{command:s,escapedCommand:o,exitCode:0,stdout:ve,stderr:Ee,all:Ie,failed:!1,timedOut:!1,isCanceled:!1,killed:!1}});return cs(i,n.options.input),i.all=ls(i,n.options),rn(i,m)};q.exports=Z;q.exports.sync=(e,t,r)=>{let n=un(e,t,r),s=on(e,t),o=cn(e,t);ds(n.options);let i;try{i=xe.spawnSync(n.file,n.args,n.options)}catch(l){throw Y({error:l,stdout:"",stderr:"",all:"",command:s,escapedCommand:o,parsed:n,timedOut:!1,isCanceled:!1,killed:!1})}let a=_(n.options,i.stdout,i.error),u=_(n.options,i.stderr,i.error);if(i.error||i.status!==0||i.signal!==null){let l=Y({stdout:a,stderr:u,error:i.error,signal:i.signal,exitCode:i.status,command:s,escapedCommand:o,parsed:n,timedOut:i.error&&i.error.code==="ETIMEDOUT",isCanceled:!1,killed:i.signal!==null});if(!n.options.reject)return l;throw l}return{command:s,escapedCommand:o,exitCode:0,stdout:a,stderr:u,failed:!1,timedOut:!1,isCanceled:!1,killed:!1}};q.exports.command=(e,t)=>{let[r,...n]=an(e);return Z(r,n,t)};q.exports.commandSync=(e,t)=>{let[r,...n]=an(e);return Z.sync(r,n,t)};q.exports.node=(e,t,r={})=>{t&&!Array.isArray(t)&&typeof t=="object"&&(r=t,t=[]);let n=sn.node(r),s=process.execArgv.filter(a=>!a.startsWith("--inspect")),{nodePath:o=process.execPath,nodeOptions:i=s}=r;return Z(o,[...i,e,...Array.isArray(t)?t:[]],{...r,stdin:void 0,stdout:void 0,stderr:void 0,stdio:n,shell:!1})}});var ys={};bn(ys,{default:()=>gs});module.exports=wn(ys);var v=require("@raycast/api"),pn=ee(require("react"));var dn=ee(require("node:process"),1),fn=ee(ln(),1);async function be(e){if(dn.default.platform!=="darwin")throw new Error("macOS only");let{stdout:t}=await(0,fn.default)("osascript",["-e",e]);return t}var J=require("react/jsx-runtime");async function hs(){return(await be('tell application "System Events" to get the short name of every process whose background only is false')).split(", ").map(t=>t.trim())}function Ss(e){return be(`tell application "${e}" to quit`)}var we=class extends pn.default.Component{constructor(t){super(t),this.state={apps:[],isLoading:!0}}componentDidMount(){hs().then(t=>{this.setState({apps:t,isLoading:!1})})}render(){return(0,J.jsx)(v.List,{isLoading:this.state.isLoading,children:this.state.apps.map(t=>(0,J.jsx)(v.List.Item,{title:t,actions:(0,J.jsx)(v.ActionPanel,{children:(0,J.jsx)(v.Action,{title:"Quit",onAction:()=>{this.setState({apps:this.state.apps.filter(r=>r!==t)}),Ss(t)}})})},t))})}},gs=we;0&&(module.exports={});
