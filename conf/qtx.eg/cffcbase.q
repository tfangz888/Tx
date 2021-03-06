\d .conf

feedtype:`fc;
fcpass:`fc123;

qbin:"/q/l64/q";
wd:"/kdb";

useha:`ha in ha.nodelist;
useha1:`ha1 in ha.nodelist;

ha.ha.ctp:`fqctp`fectp;
ha.ha.tws:`symbol$();
ha.ha.tickdb:` sv dbbase,app,`ha,`tickdb;

ha.ha1.ctp:`fqctp1`fectp1;
ha.ha1.tws:`fqtws1`fetws1;
ha.ha1.tickdb:` sv dbbase,app,`ha1,`tickdb;

module_tick:raze {ha[x;`tick]} each ha.nodelist;
module_ft:raze {ha[x;`ft]} each ha.nodelist;
module_fq:raze {ha[x;`fq]} each ha.nodelist;
module_fe:raze {ha[x;`fe]} each ha.nodelist;
module_fu:raze {ha[x;`fu]} each ha.nodelist;
module_feed:module_ft,module_fq,module_fe,module_fu;
modules:module_tick,module_feed; 
modules_ha:raze .conf.ha.ha[`tick`ft`fe`fq`fu`fc];
modules_ha1:raze .conf.ha.ha1[`tick`ft`fe`fq`fu];


module_ctp:raze {ha[x;`ctp]} each ha.nodelist;
module_tws:raze {ha[x;`tws]} each ha.nodelist;
modules1:`;

qcl:" -g 1 -P 15 -c 65 2000";

//Node 0
tp.ip:ha.ha.ip;
tp.cpu:0;
tp.port:ha.portbase.tp+ha.ha.portoffset;
tp.args:"tick.q api ",(1_string ha.ha.tickdb),$[useha1;" :",(string ha.ha1.ip),":",(string tp.port+ha.ha1.portoffset)," '",(ssr[;",";"enlist "] -3!(ha.api.fe{(x;y)}\:ha.ha1.fe),(ha.api.ft{(x;y)}\:ha.ha1.ft),(ha.api.fu{(x;y)}\:ha.ha1.ft,ha.ha1.fu)),"'";""];

rdb.ip:ha.ha.ip;
rdb.cpu:0;
rdb.port:tp.port+1;
rdb.args:"tick/r.q :",string tp.port;

hdb.ip:ha.ha.ip;
hdb.cpu:0;
hdb.port:rdb.port+1;
hdb.args:(1_string ha.ha.tickdb),"/api";

ft.ip:ha.ha.ip;
ft.cpu:0;
ft.port:ha.portbase.ft+ha.ha.portoffset;
ft.qcl:" -t 250";
ft.args:"Tx/core/base.q -conf qtx/cfft -code 'txload each (\"core/ftbase\";\"tsl/grid\");cfload \"qtx/ts/cftsqtx\";'";

fqctp.ip:ha.ha.ip;
fqctp.cpu:0;
fqctp.port:ha.portbase.fq+ha.ha.portoffset;
fqctp.qcl:" -t 250";
fqctp.args:"Tx/core/base.q -conf qtx/cffqctp -code 'txload \"feed/ctp/fqctp\"'";

fectp.ip:ha.ha.ip;
fectp.cpu:0;
fectp.port:ha.portbase.fe+ha.ha.portoffset;
fectp.qcl:" -t 250";
fectp.args:"Tx/core/base.q -conf qtx/cffectp -code 'txload \"feed/ctp/fectp\"'";

fqxtp.ip:ha.ha.ip;
fqxtp.cpu:0;
fqxtp.port:ha.portbase.fq+ha.ha.portoffset;
fqxtp.qcl:" -t 250";
fqxtp.args:"Tx/core/base.q -conf qtx/cffqxtp -code 'txload \"feed/xtp/fqxtp\"'";

fextp.ip:ha.ha.ip;
fextp.cpu:0;
fextp.port:ha.portbase.fe+ha.ha.portoffset;
fextp.qcl:" -t 250";
fextp.args:"Tx/core/base.q -conf qtx/cffextp -code 'txload \"feed/xtp/fextp\"'";

fqjg.ip:ha.ha.ip;
fqjg.cpu:0;
fqjg.port:fqxtp.port+ha.portstep;
fqjg.qcl:" -t 250";
fqjg.args:"Tx/core/base.q -conf qtx/cffqjg -code 'txload \"feed/jg/fqjg\"'";

fejg.ip:ha.ha.ip;
fejg.cpu:0;
fejg.port:fextp.port+ha.portstep;
fejg.qcl:" -t 250";
fejg.args:"Tx/core/base.q -conf qtx/cffejg -code 'txload \"feed/jg/fejg\"'";

ftsim.ip:ha.ha.ip;
ftsim.cpu:0;
ftsim.port:ha.portbase.ftsim+ha.ha.portoffset;
ftsim.qcl:" -t 250";
ftsim.args:"Tx/core/base.q -conf qtx/cfftsim -code 'txload each (\"core/ftbase\";\"tsl/grid\");cfload \"qtx/ts/cftsqtx\";'";

ftbt.ip:ha.ha.ip;
ftbt.cpu:3;
ftbt.port:ftsim.port+ha.portstep;
ftbt.qcl:" -t 250";
ftbt.args:"Tx/core/base.q -conf qtx/cfftbt -code 'txload each (\"feed/backtest/ftbacktest\";\"ui/uibase\";\"tsl/grid\");cfload \"qtx/ts/cftszqsim\";'";

\d .
