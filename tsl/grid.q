.module.tsgrid:2017.04.26;
txload "tsl/tslib";

//网格交易
//======策略参数[交易计划表TP(sym交易标的,logpx是否使用对数价格,pxbase基准价格,pxstep网格步长,posinf持仓下限,possup持仓上限,stepmap按仓位网格步长,pxscale价格乘数,spreadmax)TRDTIME:,ANCHORSYM:,LONGSYM:,SHORTSYM:,GRIDSIZE,POSINF,POSSUP,RATIO,SHORTOFFSET,LONGOFFSET,PRICESCALE,SPREADMAX,SHORTSTOPRANGE,LONGSTOPRANGE],状态变量[ANCHORPX,ANCHORUP,ANCHORDON,OIDUP,OIDDN]
//======基本逻辑.对TP表里的每个标的:首先检查是否触发止损;根据初始价格pxbase和当前持仓计算锚点价格p0,在上下分别间隔astep/bstep得到卖价pa和买价pb,检查当前挂单价格是否相符,如有必要先撤单,否则挂单

onq_grid:{[x;y];}; /[tid;symlist]

ono_grid:{[x;y]opeg_libpeg[x;y];r:.db.O[y];st:r`status;s:r`sym;if[not (r`end)&s in exec sym from .db.Ts[x;`TP];:()];sd:$[r[`side]=.enum`SELL;`oidup;`oiddn];.db.Ts[x;`TP;s;sd]:.db.Ts[x;`TP;s;sd] except y;if[st=.enum.FILLED;.db.Ts[x;`TP;s;$[sd=`oidup;`nup;`ndn]]+:1];if[not .db.Ts[x;`TP;s;`stop];grid_check[x;s]];}; /[tid;oid]

onr_grid:{[x;y].db.Ts[x;`TP]:update oidup:{`symbol$()} each oidup,oiddn:{`symbol$()} each oiddn,pxask:0n,qtyask:0n,pxbid:0n,qtybid:0n from .db.Ts[x;`TP];};

ont_grid:{[x;y]t:`time$y;grid_check[x] each exec sym from .db.Ts[x;`TP] where istrading[t] each sym,not stop;}; /[tid;.z.P] oexpire_libpeg[x;y];

grid_cxl:{[x]if[not .db.O[x;`cstatus]=.enum`PENDING_CANCEL;cxlord x];};

grid_check:{[x;s]r:.db.Ts[x;`TP;s];h:.db.QX[s];if[any null h`bid`ask;:()];p:(0.5*sum h`bid`ask)^h`price;sp:h[`ask]-h[`bid];q0:netpos[x;s];d:signum[q0];oul:r`oidup;odl:r`oiddn;ct:0b;if[(((d>0)&p within r`closelongrange)|((d<0)&p within r`closeshortrange))&(sp<=r`spreadmax);if[count oul;grid_cxl each oul;ct:1b];if[count odl;grid_cxl each odl;ct:1b];if[ct;:()];pegord_libpeg each ($[d>0;limit_sell;limit_buy])[x;s;abs[q0];$[d>0;h`bid;h`ask];`stop];.db.Ts[x;`TP;s;`stop]:1b;:()];sup:r`stepup;sdn:r`stepdn;nu:r`nup;nd:r`ndn;.db.Ts[x;`TP;s;`pxref]:pr:r[`pxbase]+(sup*nu)-(sdn*nd);qus:r`qtyups;qdl:r`qtydnl;.db.Ts[x;`TP;s;`qtyref]:qr:r[`qtybase]+(qdl*nd)-(qus*nu);.db.Ts[x;`TP;s;`pxbid]:pb:pr-sdn;.db.Ts[x;`TP;s;`pxask]:pa:pr+sup;xb:$[0=count odl;0n;.db.O[odl[0];`price]];xa:$[0=count oul;0n;.db.O[oul[0];`price]];if[(not null xb)&(pb<>xb);grid_cxl each odl;ct:1b];if[(not null xa)&(pa<>xa);grid_cxl each oul;ct:1b];if[ct;:()];.db.Ts[x;`TP;s;`qtybid]:qb:(r[`possup]&qr+qdl)-q0;if[(0=count odl)&(0<qb)&(pb>=h`inf);.db.Ts[x;`TP;s;`oiddn]:raze limit_buy[x;s;qb;pb;`dn]];.db.Ts[x;`TP;s;`qtyask]:qa:q0-(r[`posinf]|qr-qus);if[(0=count oul)&(0<qa)&(pa<=h`sup);.db.Ts[x;`TP;s;`oidup]:raze limit_sell[x;s;qa;pa;`up]];}; /[tid;sym]ct:有撤单标志

\

.db.Ts.qtx:.enum.nulldict;
.db.Ts.qtx[`active`acc`accx`stop`event]:(0b;`ctp;`symbol$();0b;.enum.nulldict);
.db.Ts.qtx.event[`timer`quote`exerpt`dayroll`sysinit`sysexit]:`ont_grid`onq_grid`ono_grid`onr_grid``;
.db.Ts.qtx[`Cp]:`tmout`tmout1`tmout2`urge!(00:00:05;00:00:10;00:00:15;2);
.db.Ts.qtx[`syms`TP]:(`symbol$();([sym:`symbol$()];stop:`boolean$();logpx:`boolean$();pxbase:`float$();qtybase:`float$();nup:`long$();ndn:`long$();nos:`long$();pxref:`float$();qtyref:`float$();pxask:`float$();qtyask:`float$();pxbid:`float$();qtybid:`float$();stepup:`float$();stepdn:`float$();qtyups:`float$();qtydnl:`float$();posinf:`float$();possup:`float$();stepupmap:();stepdnmap:();qtyupsmap:();qtydnlmap:();spreadmax:`float$();closelongrange:();closeshortrange:();oidup:();oiddn:())); /[标的;止损标志;对数价格标志;基准价格;基准持仓;上涨跳数;下跌跳数;基准移动跳数;当前中枢价格;当前理论持仓;卖单价格;卖单数量;买单价格;买单数量;上涨网格宽度;下跌网格宽度;上涨卖出数量;下跌买入数量;净持仓下限;净持仓上限;非对称上涨价格映射;非对称下跌价格映射;非对称上涨数量映射;非对称下跌数量映射;自动止损盘口价差限制;多头止损区间;空头止损区间;当前卖单列表;当前买单列表]

.db.Ts.qtx.TP,:((`$"SP i1907&i1909.XDCE";0b;0b;60f;2f;1f;0f;0f;()!();1.5;-2 -1f;85 90f;();());(`$"SP i1909&i1911.XDCE";0b;0b;-10f;2f;1f;0f;0f;()!();1.5;-2 -1f;110 120f;();());(`$"SP i1911&i2001.XDCE";0b;0b;12f;2f;1f;0f;0f;()!();1.5;-2 -1f;110 120f;();());(`$"SP i1909&i2001.XDCE";0b;0b;40f;2f;1f;0f;0f;()!();1.5;-2 -1f;110 120f;();()));

.db.Ts.qtx.TP,:(`c2001.XDCE;0b;0b;1843f;0f;0;0;0n;0n;0n;0n;0n;0n;3f;6f;1f;2f;-10f;10f;()!();()!();()!();()!();2f;1570 1600f;2000 2030f;();());
.db.Ts.qtx.TP,:(`TA001.XZCE;0b;0b;4758f;0f;0;0;0n;0n;0n;0n;0n;0n;10f;20f;1f;2f;-10f;10f;()!();()!();()!();()!();5f;4570 4600f;5000 5030f;();());


\
noeexec[`20170201001;`ft`qtx;`XAUUSD.METAL;.enum`SELL;.enum`OPEN;66f;1232.436;"init"];
noeexec[`20170313002;`ft`qtx;`ZC701.XZCE;.enum`SELL;.enum`OPEN;1f;582.2;"init"];


ont_grid:{[x;y]t:`time$y;wd:weekday[y];r:.db.Ts[x];acc:r`acc;z:r`xsym;pa:.db.QX[z;`ask];pb:.db.QX[z;`bid];if[(not any t within/: r`TRDTIME)|(wd=6)|((wd=5)&t>06:00)|((wd=0)&t<06:00)|(0>=pa&pb);:()];pm:-0w^first r`LONGSTOPRANGE;pM:0w^first r`SHORTSTOPRANGE;sm:r`SPREADMAX;$[((pb>pM)|(pa<pm))&(sm>=pa-pb);$[0<count il:exec id from .db.O where ts=x,not end,(ref in `up`dn)|00:00:05<.z.P-ntime;cxlord each il;[if[(pa within r`SHORTSTOPRANGE)&(sm>=pa-pb)&(0<q:neg .db.P[(x;acc;z);`sqty]);limit_buy[x;z;q;pa+sm;`stopcloseshort];.db.Ts[x;`mode]:`MANUAL];if[(pb within r`LONGSTOPRANGE)&(sm>=pa-pb)&(0<q:.db.P[(x;acc;z);`lqty]);limit_sell[x;z;q;pb-sm;`stopcloselong];.db.Ts[x;`mode]:`MANUAL];]];[pq:sum 0f^.db.P[(x;acc;z);`lqty`sqty];qu:r`GRIDSIZE;ps:1f^ffill r`PRICESCALE;pu:r[`ANCHORUP]+r[`SHORTOFFSET];if[(null r`OIDUP)&(pq>r`POSINF)&(pu<=0w^.db.QX[z;`sup]);.db.Ts[x;`OIDUP]:first limit_sell[x;z;qu;ps*pu;`up]];pd:r[`ANCHORDN]+r[`LONGOFFSET];if[(null r`OIDDN)&(pq<r`POSSUP)&(pd>=0f^.db.QX[z;`inf]);.db.Ts[x;`OIDDN]:first limit_buy[x;z;qu;ps*pd;`dn]]]];}; /[tid;.z.P]

grid_check:{[x;s]r:.db.Ts[x;`TP;s];h:.db.QX[s];if[any null h`bid`ask;:()];p:(0.5*sum h`bid`ask)^h`price;sp:h[`ask]-h[`bid];q0:netpos[x;s];d:signum[q0];oul:r`oidup;odl:r`oiddn;if[(((d>0)&p within r`closelongrange)|((d<0)&p within r`closeshortrange))&(sp<=r`spreadmax);ct:0b;if[count oul;grid_cxl each oul;ct:1b];if[count odl;grid_cxl each odl;ct:1b];if[ct;:()];pegord_libpeg each ($[d>0;limit_sell;limit_buy])[x;s;abs[q0];$[d>0;h`bid;h`ask];`stop];.db.Ts[x;`TP;s;`stop]:1b;:()];sz:r`size;ps:r`pxstep;q:d*sz*n:floor abs[q0]%sz;qr:q-q0;p0:r[`pxbase]-d*n*ps;pb:h[`bid]&p0-ps;pa:h[`ask]|p0+ps;xb:$[0=count odl;0n;.db.O[odl[0];`price]];xa:$[0=count oul;0n;.db.O[oul[0];`price]];if[(not null xb)&(pb<>xb);grid_cxl each odl];if[(not null xa)&(pa<>xa);grid_cxl each oul];q:(sz+0&qr)&r[`possup]-q0;if[(0=count odl)&(0<q)&(pb>=h`inf);.db.Ts[x;`TP;s;`oiddn]:raze limit_buy[x;s;q;pb;`dn]];q:(sz+0&qr)&q0-r`posinf;if[(0=count oul)&(0<q)&(pa>=h`sup);.db.Ts[x;`TP;s;`oidup]:raze limit_sell[x;s;q;pa;`up]];}; /[tid;sym]

