import json,sys,copy
U='local_user'
def w(id,name,open_,created,cc=None,order=0,color='0xFF2196F3'):
    return dict(id=id,userId=U,name=name,balance=open_,debt=0,credit=0,investment=0,colorHex=color,
        iconName='account_balance_wallet',createdAt=created,isActive=True,sortOrder=order,
        openingBalance=open_,currency='TRY',categoryIds=None,creditCard=cc)
def card(closing=25,due=5,off=10,stmt=None,limit=50000.0,pw='A'):
    return dict(bankName='QNB',last4='1234',limit=limit,closingDay=closing,dueDay=due,paymentWalletId=pw,
        lastStatement=stmt,dueOffsetDays=off,monthlyInterestRate=None,lateInterestRate=None)
def stmt(close,due,bal=1500.0):
    return dict(closingDate=close+'T00:00:00.000',dueDate=due+'T00:00:00.000',statementBalance=bal,minimumPayment=None,source='manual',recordedAt='2026-10-01T10:00:00.000')
def cat(id,name,exp,parent=None,order=0,icon='category'):
    return dict(id=id,name=name,iconName=icon,isExpense=exp,parentId=parent,sortOrder=order)
CATS=[cat('c-market','Market',True,order=0,icon='shopping_cart'),cat('c-fatura','Fatura',True,order=1,icon='receipt_long'),
 cat('c-elektrik','Elektrik',True,'c-fatura',0,'lightbulb'),cat('c-su','Su',True,'c-fatura',1,'water_drop'),
 cat('c-yemek','Yemek',True,order=2,icon='restaurant'),cat('c-ulasim','Ulaşım',True,order=3,icon='directions_bus'),
 cat('c-elektronik','Elektronik',True,order=4,icon='devices'),cat('c-maas','Maaş',False,order=0,icon='payments')]
def mk(V):
    txs=[]
    def t(id,wal,date,tag,amt,inc,title=None,system=False,link=None,**kw):
        d=dict(id=id,userId=U,walletId=wal,title=title or id,tag=tag,amount=amt,
          date=(date if 'T' in date else f'{date}T10:00:00.000') if date.startswith('20') else f'2026-{date}T10:00:00.000',
          type='income' if inc else 'expense',isSystem=system,receiptFileName=None,reference=None,
          linkedRecordId=link,adoptedFromTag=None,origin=None,importBatchId=None,
          installmentGroupId=None,installmentNo=None,installmentCount=None)
        d.update(kw); txs.append(d)
    T='Transfer'
    cats=copy.deepcopy(CATS); bud=[dict(categoryId='c-market',limitAmount=2000.0,walletId='A')]; rec=[]
    ccA=card()
    if V=='cstmt1': ccA=card(stmt=stmt('2026-09-25','2026-10-06'))
    if V=='cstmt2': ccA=card(off=None)
    if V=='cstmt3': ccA=card(off=None,stmt=stmt('2026-09-25','2026-10-05'))
    if V=='c33': ccA=card(stmt=stmt('2026-09-25','2026-10-05'))
    if V=='c40': ccA=card(stmt=stmt('2026-09-25','2026-10-05',bal=1550.0))
    if V=='c41': ccA=card(stmt=stmt('2026-09-25','2026-10-05',bal=1450.0))
    if V=='cstmt4': ccA=card(off=None,stmt=stmt('2026-09-25','2026-10-07'))
    wallets=[w('A','Banka',10000.0,'2026-08-01T09:00:00.000',order=0),
             w('B','Nakit',2000.0,'2026-08-01T09:00:00.000',order=1,color='0xFF4CAF50'),
             w('K','Kart',0.0,'2026-09-01T09:00:00.000',cc=ccA,order=2,color='0xFFF44336')]
    if V=='c43':
        wallets[2]=w('K','Kart',-3000.0,'2026-10-10T09:00:00.000',cc=ccA,order=2,color='0xFFF44336')
    if V=='badcolor':
        # Elle düzenlenmiş yedek: renk bizim 0xAARRGGBB biçiminde değil.
        wallets[0]['colorHex']='FF2196F3'; wallets[1]['colorHex']='#4CAF50'; wallets[2]['colorHex']='kırmızı'
    t('A1','A','09-01','c-maas',30000,True,'Maaş'); t('A2','A','09-04','c-market',1000,False,'Market')
    t('A3','A','09-08','c-elektrik',700,False,'Elektrik'); t('A4','A','09-12','c-yemek',300,False,'Yemek')
    t('A5','A','09-20','c-market',900,False,'Market'); t('A6','A','10-01','c-maas',30000,True,'Maaş')
    t('A7','A','10-02','c-market',450 if V=='i26' else 1200,False,'Market')
    if V!='c43': t('A8','A','10-02',T,300 if V=='c33' else 1500,False,'Kart ödemesi',True,'tr-A8')
    t('A9','A','10-03','c-elektrik',500 if V=='i26' else 800,False,'Elektrik'); t('A10','A','10-03','c-su',200,False,'Su')
    t('A11','A','10-06','c-yemek',370 if V=='i26' else 450,False,'Yemek'); t('A12','A','10-10','c-market',650,False,'Market')
    t('A13','A','10-12',T,2000,False,'Transfer',True,'tr-A13'); t('A14','A','10-14','c-ulasim',300,False,'Ulaşım')
    t('B1','B','10-12',T,2000,True,'Transfer',True,'tr-A13'); t('B2','B','10-13','c-market',150,False,'Market')
    if V!='c43':
        t('K1','K','09-10','c-market',1000,False,'Market'); t('K2','K','09-20','c-yemek',500,False,'Yemek')
        for n,(m,d_) in enumerate([('09','26'),('10','26'),('11','26')],1):
            t(f'K{n+2}','K',f'{m}-{d_}','c-elektronik',1000,False,f'Telefon ({n}/3)',
              installmentGroupId='grp-tel',installmentNo=n,installmentCount=3)
        t('K6','K','10-02',T,300 if V=='c33' else 1500,True,'Kart ödemesi',True,'tr-A8'); t('K7','K','10-10','c-market',400,False,'Market')
    if V=='x53': t('N1','A','10-20','c-market',500,False,'Market (ileri)')
    if V=='r06': t('N1','A','10-20','c-elektronik',30000,False,'Büyük gider')
    if V in('r13','r14'):
        cats.append(cat('c-kirt','Kırtasiye',True,order=5,icon='edit')); t('N1','A','10-15','c-kirt',50,False,'Kırtasiye')
        if V=='r13':
            cats.append(cat('c-kahve','Kahve',True,order=6,icon='local_cafe')); t('N2','A','10-15','c-kahve',40,False,'Kahve')
    if V in('i21','i22'):
        rec.append(dict(id='rec1',userId=U,walletId='A',title='Kira',tag='c-fatura',amount=10000.0 if V=='i21' else 30000.0,
            type='expense',frequency='monthly',nextExecutionDate='2026-10-25T00:00:00.000',anchorDay=25,isActive=True))
    if V=='edge':
        t('E1','A','2026-10-31T23:59:59.000','c-ulasim',10,False,'Saat sınırı')
        t('E2','A','2026-11-01T00:00:00.000','c-ulasim',20,False,'Kasım ilk an')
        t('E3','B','2026-11-14T10:00:00.000','c-yemek',0.10,False,'Kuruş 1')
        t('E4','B','2026-11-14T11:00:00.000','c-yemek',0.20,False,'Kuruş 2')
        t('E5','A','2027-01-31T10:00:00.000','c-yemek',100,False,'Ay sonu')
        bud.append(dict(categoryId='c-elektrik',limitAmount=500.0,walletId='A'))
    if V=='t43':
        t('E5','A','2027-01-31T10:00:00.000','c-yemek',100,False,'Ay sonu')
        t('E6','A','2027-02-28T10:00:00.000','c-yemek',100,False,'Şubat sonu')
        t('E7','A','2027-03-31T10:00:00.000','c-yemek',100,False,'Mart sonu')
    if V=='cedge':
        t('C1','K','2026-10-25T23:00:00.000','c-market',100,False,'Kesim günü 23:00')
        t('C2','K','2026-10-26T00:05:00.000','c-market',100,False,'Kesim ertesi 00:05')
        wallets.append(w('K31','Kart31',0.0,'2026-09-01T09:00:00.000',cc=card(closing=31,due=10,off=None,pw='A'),order=3,color='0xFF9C27B0'))
        t('C3','K31','2026-10-15T10:00:00.000','c-market',250,False,'Kart31 harcama')
    if V=='newuser':
        wallets=[w('A','Banka',0.0,'2026-10-12T09:00:00.000')]
        txs.clear()
        t('F1','A','2026-10-12T10:00:00.000','c-market',1320,False,'Market')
        t('F2','A','2026-10-15T10:00:00.000','c-market',4590,False,'Market')
        bud=[]
    return dict(version=16,timestamp='2026-10-15T03:00:00.000',wallets=wallets,transactions=txs,investments=[],
      debts=[],receivables=[],budgets=bud,recurringTransactions=rec,users={},categories=cats,goals=[])
for V in ['base','x53','r06','r13','r14','i21','i22','edge','cedge','newuser','cstmt1','cstmt2','cstmt3','cstmt4','c43','c33','i26','t43','badcolor','c40','c41']:
    json.dump(mk(V),open(f'golden_{V}.json','w'),ensure_ascii=False)
print('ok')
