"""Author through Content Tool API; source tables remain reviewable, export is canonical."""
from pathlib import Path
import sys,re,json,collections
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools/content_tool'))
import content_tool as ct
from godot_bridge import export_catalog
W=ROOT/'tools/content_tool/writing'
def put(kind,**row):
    if 'approval_state' in row: row.setdefault('implementation','playable' if row['approval_state']=='approved' else 'proposal')
    ok,errors=ct.upsert_item(kind,row)
    if not ok: raise ValueError((kind,row.get('id'),errors))
def base(id,live=False):
    return dict(id=id,text_ready=True,text_only=True,approval_state='approved' if live else 'draft',art_source='MANUAL')
def lines(name): return [x.split('|') for x in (W/name).read_text(encoding='utf-8-sig').splitlines() if x.strip()]
def runtime_choice(name,description,code,reply):
    c=dict(name=name,description=description,reply=reply)
    p=code.split(':'); op=p[0]
    if op=='gold':c['gold_gain']=int(p[1])
    elif op=='heal':c['heal']=int(p[1])
    elif op=='pay':c['gold_cost']=int(p[1])
    elif op=='flag':c['flag']=p[1]
    elif op=='buy':c.update(relic=p[1],gold_cost=int(p[2]))
    elif op=='trade':c.update(relic=p[1],hp_cost=int(p[2]))
    elif op=='hurtflag':c.update(flag=p[1],hp_cost=int(p[2]))
    elif op=='payflag':c.update(flag=p[1],gold_cost=int(p[2]))
    elif op=='payheal':c.update(gold_cost=int(p[1]),heal=int(p[2]))
    elif op=='hurtgold':c.update(hp_cost=int(p[1]),gold_gain=int(p[2]))
    else:raise ValueError(code)
    return c
regions=[
('ash_cathedral','잿빛 성당','기록',
'종소리가 멎은 성당에서도 완치 판정은 계속된다. 병실은 비었는데 퇴원 장부에는 이름이 없다. 문지기 에델은 성화가 꺼지기 전에 길을 돌아보라고 권하지만, 무엇을 태워 불을 유지하는지는 말하지 않는다.\n\n미라는 진료표에서 자신이 쓰던 약어를 발견한다. 그러나 수령인 칸의 필적은 가면 안쪽과 다르다. 지금 알아낸 것은 치료의 성공과 환자의 귀환이 같은 뜻이 아니라는 사실뿐이다.\n\n재의 파수꾼은 침입자를 막는 것처럼 보이지만 병동에서 바깥으로 향하는 발걸음도 가로막는다. 그 뒤의 장부는 고통이 지하 화물 승강기를 통해 운하로 인계되었음을 보여 준다.',
'빈 병동 → 완치·퇴원 기록 대조 → 파수꾼 → 필수 이송 장부 → 검은 운하','ward_ledger'),
('black_canal','검은 운하','운송',
'검은 운하의 배는 사람을 승객으로 세지 않는다. 성당에서 실린 수령인은 약재와 같은 봉인 아래 온실로 향한다. 수로지기 마렌은 이름이 자꾸 바뀌는 배에서 흠집과 정박 시간만 믿는다.\n\n이송선을 멈추면 강제 수송을 끊을 수 있다. 하지만 같은 배가 하류의 등불 연료도 운반한다. 원정대는 주민의 우회 수문과 구호선 재고를 확인하며, 구출을 새로운 굶주림으로 바꾸지 않을 길을 찾는다.\n\n돌아오지 않는 선장은 이미 끝난 귀항을 반복한다. 그를 멈춘 뒤 얻는 수령 도장은 목적지가 유리온실임을 가리킨다. 배를 파괴할지 확보할지는 구조 속도와 물자에 영향을 주지만 다음 지역의 길을 닫지는 않는다.',
'화물의 생존 확인 → 우회 수문 → 선장 → 수령 도장 → 유리온실','canal_complete'),
('glass_garden','유리온실','증류',
'로엔은 누구를 기다리는지 모르면서 차를 두 잔 끓인다. 온실은 고통을 걸러 약으로 만들고, 약은 치료의 대가를 기억하지 못하게 한다. 연구자들이 부작용이라 부르던 망각이 어느 순간 성공 기준이 되었다.\n\n미라는 초기 안정화 처방의 공동 서명자였다. 위험을 혼자 만든 사람도, 아무것도 몰랐던 사람도 아니다. 동료가 남긴 경고를 연구가 끝난 뒤 해결할 일로 미뤘다는 사실을 인정해야 한다.\n\n접목된 원장을 쓰러뜨리면 공정을 멈출 수 있다. 원본 처방을 봉인하고 검증 가능한 개정 약제를 공개하는 길, 공정을 폐기하며 대체 진료를 늘리는 길 모두 시간이 든다. 기억 잔사의 배송지는 이름없는 서고다.',
'약효·망각 구분 → 공동 처방 확인 → 접목된 원장 → 공정의 처리 → 이름없는 서고','garden_complete'),
('nameless_archive','이름없는 서고','삭제',
'이곳은 사람의 이름을 지운 뒤에도 관리 번호를 보존했다. 사서 오르트는 이름을 돌려주면 그 이름에 묶인 고통도 돌아올 수 있다고 경고한다. 복원은 선한 버튼 하나로 끝나지 않는다.\n\n미라는 편지의 필체를 가면 안쪽과 대조한다. 이름을 남긴 사람은 동료 이안이었다. 그는 미라의 초승달이 부담을 넘기는 통로가 되는 것을 막기 위해 수령인으로 서명했지만, 영원히 대신 아프겠다고 동의한 것은 아니다. 편지는 자신을 죽었다고 단정하지 말라고 부탁한다.\n\n삭제관을 지나 얻는 최종 배분표는 성화에 상한이 없음을 드러낸다. 한꺼번에 복원할 것인지 단계적으로 연결할 것인지 결정할 때는 지금 살아 있는 사람의 의사를 먼저 확인해야 한다.',
'삭제 기록 → 가면 필체 대조 → 삭제관 → 유한 배분안 → 새벽없는 성소','archive_complete'),
('dawnless_sanctum','새벽없는 성소','배분',
'성화의 안쪽에는 신의 얼굴 대신 서로 연결된 수령인들이 있다. 고통을 나눠 받는 장치가 성가를 통해 하나의 의지처럼 말한다. 그것이 수령 성가대다. 이해할 수 없는 백색막은 인간의 선악을 판정하지 않는다. 전송에는 보내는 이, 받는 이, 매개가 필요할 뿐이다.\n\n에델은 직함 뒤에 자기 이름을 숨겨 수령 명단을 빠져나온 일을 고백한다. 그가 열어 준 길과 숨긴 길을 모두 기록해야 한다. 미라는 자신의 발명만 되찾으러 온 것이 아니라 이후 치료의 책임까지 지기로 한다.\n\n전투는 기계를 부수면 모두 구원된다는 결말이 아니다. 배분을 잠시 멈추고 선택할 시간을 번다. 제한된 중앙 유지, 대피와 단계적 소등, 유한한 작은 매개로의 분산. 어느 선택이든 중단권과 이후의 돌봄이 필요하다.',
'부담 확인 → 에델의 고백 → 수령 성가대 → 세 가지 전환 → 사후 돌봄','sanctum_complete')]
for act,(id,name,function,story,route,flag) in enumerate(regions,1):
    put('regions',**base(id,True),name=name,act=act,description=story,runtime=dict(effect=story,requires_flag='' if act==1 else regions[act-2][5],sources=['원정 기록'],notes='진행 설계: '+route+'\n현재 전투 진행은 ACT I까지. 후속 ACT는 검수 원고입니다.',related=[]),implementation='playable' if act==1 else 'manuscript',spoiler=act>1)
# Relics: preserve the three implemented legacy IDs and archive the duplicate draft.
old=ct.load_data()
for r in old['relics']:
    if r['id']=='explorers_map':put('relics',id=r['id'],archived=True,text_ready=False)
    elif r['id'] in ('mira_crescent','blood_contract','explorer_map'):
        flavors={'mira_crescent':'안쪽의 미세한 홈은 균열이 아니다. 누군가 고통이 흐르는 방향을 한 번 바꿨다. 미라는 아직 그 사람의 이름을 읽지 못한다.','blood_contract':'계약서에는 대가가 쓰여 있다. 문제는 서명한 사람이 그 대가를 철회할 방법이 없다는 것이다.','explorer_map':'성당 밖의 길까지 그리려던 지도다. 지워진 선창을 복원하려면 종이보다 사람의 증언이 더 필요하다.'}
        put('relics',id=r['id'],text_ready=True,implementation='playable',flavor_text=flavors[r['id']])
rarities={'common':'일반','uncommon':'고급','rare':'희귀','epic':'영웅','legend':'전설','ancient':'고대'}
hooks=['battle_start_block','victory_heal','reward_gold_bonus','battle_start_poison','battle_start_energy','rest_heal_bonus'];amounts=[2,2,5,1,1,3]
for rank,rarity in rarities.items():
    for i,parts in enumerate(lines('relics_'+rank+'.txt'),1):
        ancient=rank=='ancient'
        if ancient: owner,name,effect,flavor=parts;act=5
        else:name,effect,flavor,act=parts;act=int(act);owner=''
        live=rank=='common' and i<=6
        rt=dict(sources=['개인 연속 이벤트 최종 선택'] if ancient else ['지역 이야기·보물·상점 설계'],shop=live,related=['지역:'+regions[act-1][0]])
        if live:rt[hooks[i-1]]=amounts[i-1]
        extra=dict(character_restriction=owner,origin_event='chain_'+owner+'_final') if ancient else {}
        put('relics',**base(f'relic_{rank}_{i:03}',live),name=name,rarity=rarity,effect=effect,flavor_text=flavor,act=act,scope='PERSONAL',runtime=rt,**extra)
# 100 common events, ACT I is playable now; later acts are manuscript only.
for act in range(1,6):
    for i,p in enumerate(lines(f'events_act{act}.txt'),1):
        assert len(p)==10,(act,i,len(p))
        name,story,n1,d1,c1,r1,n2,d2,c2,r2=p
        choices=[runtime_choice(n1,d1,c1,r1),runtime_choice(n2,d2,c2,r2),dict(name='길을 계속 간다',description='아무 대가 없이 떠납니다.',reply='지금 결정하지 않은 일은 기록에 남겨 두었다.')]
        id=f'common_act{act}_{i:02}'
        put('events',**base(id,act==1),title=name,category='COMMON',act=act,story=story,choices=choices,runtime=dict(pool='common',chapter=f'ACT {act} · '+regions[act-1][1],speaker='원정 기록',related=['지역:'+regions[act-1][0]],sources=['ACT '+str(act)+' 공통 이벤트']),spoiler=act>1)
        # Discoverable notes reflect the chosen branch only, never present unchosen outcomes as fact.
        for c in choices:
            if c.get('flag'):
                put('lore',**base('evidence_'+c['flag'],True),name=name+' · 조사 기록',act=act,description=c['reply'],runtime=dict(effect=c['reply'],requires_flag=c['flag'],related=['이벤트:'+id],sources=['해당 선택으로 획득']),implementation='playable' if act==1 else 'manuscript',spoiler=act>1)
# Potions, supported healing only enters shop. Existing healing_draught remains.
for i,(name,effect,flavor,code,act) in enumerate(lines('potions.txt'),1):
    live=code.startswith('heal:');rt=dict(sources=['상점 즉시 복용'] if live else ['전투용 포션 설계'],related=['지역:'+regions[int(act)-1][0]])
    if live:_,heal,price=code.split(':');rt.update(heal=int(heal),price=int(price))
    put('potions',**base(f'potion_text_{i:02}',live),name=name,rarity='일반' if live else '고급',effect=effect,flavor_text=flavor,act=int(act),runtime=rt)
# Existing 300 status seeds are explicitly proposals, not 300 newly implemented effects.
seed=(ROOT/'docs/power_status_300.txt').read_text(encoding='utf-8-sig')
for match in re.finditer(r'(?m)^(\d{3})\. (.+)\r?\n\s*중첩: (\w+)\r?\n\s*효과: (.+)',seed):
    num,name,stack,effect=match.groups();category='SPECIAL'
    prefix=seed[:match.start()];sections=re.findall(r'(?m)^\[(.+)\]',prefix);section=sections[-1] if sections else '공용'
    if '버프' in section:category='DEBUFF' if '디버프' in section else 'BUFF'
    elif '저주' in section:category='CURSE'
    elif 'Power' in section or '파워' in section:category='POWER'
    put('powers',**base('status_draft_'+num),name=name,category=category,effect=effect+' (수치·발동 조건 검수 전)',tooltip=effect+'\n이 항목은 기존 300종 설계 원고입니다. 수치와 중첩 해석은 검수 전이며 전투에 적용되지 않습니다.',stack_mode=stack,duration=0,max_stack=0,design_group=section,runtime=dict(sources=['power_status_300 원고 '+num],related=[]))
# Mandatory ACT I aftermath, with exact story gating independent of optional event rolls.
ledger='파수꾼 뒤에는 출입문이 아니라 화물 승강기가 있었다. 장부에는 완치한 환자 여섯 명과 퇴원자 영 명이 적혀 있었다. 수령인 항목은 별도 명부로 옮겨져 있다.\n\n미라는 약제란의 둥근 필적을 알아본다. 자신의 글씨다. 그러나 가면 안쪽의 짧게 꺾인 획은 이 장부에 없다.\n\n에델이 등불을 낮춘다. “다음 인계는 검은 운하에서 이루어졌겠군.” 미라는 장부를 덮지 않는다. “치료가 끝났다면, 왜 집에 간 사람은 없지?”'
put('events',**base('act1_ledger',True),title='완치 여섯, 퇴원 없음',category='CHAIN',act=1,story=ledger,choices=[dict(name='이송 장부를 챙긴다',description='진료 기록과 운하의 행선지를 도감에 남깁니다.',flag='ward_ledger',reply='환자를 구하려면 치료가 어디로 이어졌는지 알아야 한다. 미라는 자신의 서명이 있는 쪽도 찢지 않고 챙겼다.')],runtime=dict(chapter='ACT I · 잿빛 성당의 끝',speaker='미라와 에델',related=['지역:ash_cathedral','지역:black_canal']))
put('lore',**base('ward_transfer_ledger',True),name='성당 이송 장부',act=1,description=ledger,runtime=dict(effect=ledger,requires_flag='ward_ledger',related=['지역:ash_cathedral','지역:black_canal','유물:mira_crescent'],sources=['ACT I 파수꾼 이후 필수 기록']))
# Three endings are manuscripts; each has a cost, a right to stop, and aftermath.
endings=[('remaining_flame','남겨진 불','중앙 성화는 낮은 밝기로 남았다. 명부와 사용량은 공개되고, 수령인은 기간과 부담 상한을 스스로 정한다. 철회한 사람이 빠지면 출력도 줄여야 한다.\n\n등불회는 더는 관리와 감시를 함께 맡지 않는다. 미라는 약 처방의 책임자로 이름을 남긴다. 불이 있어도 병은 남고, 자원자가 부족한 밤에는 거리가 어두워진다. 영구한 해결이라고 부르는 사람을 다음 회의에서 다시 설득해야 한다.'),('long_night','긴 밤의 귀환','성화는 한 번에 꺼지지 않았다. 병동과 대피소가 준비되는 순서대로 밝기를 줄였다. 사라졌다고 믿었던 통증이 돌아왔고, 누군가는 오랫동안 다른 사람의 도움이 필요했다.\n\n연료와 대피로를 준비했다면 더 많은 사람이 따뜻한 방에서 첫밤을 맞는다. 준비가 부족하면 원정대도 추위와 부족한 약을 함께 견딘다. 밤이 길어졌지만 다른 몸에 떠넘겨 짧아진 밤은 아니었다.'),('many_lanterns','각자의 등불','성화는 유한한 작은 매개로 나뉘었다. 가까운 이웃끼리 부담과 휴식을 정하고, 깨진 매개는 교체하기 전까지 사용하지 않는다. 한 곳의 고장이 모든 사람에게 번지지는 않는다.\n\n부유한 거리와 가난한 거리의 차이는 새 갈등이 되었다. 미라는 공정을 공개하는 것에 그치지 않고 수리와 교육을 함께 다닌다. 각자의 등불이라는 이름이 각자 알아서 버티라는 뜻이 되지 않도록.')]
for id,name,text in endings:
    put('lore',**base('ending_'+id,True),name=name,act=5,description=text,spoiler=True,implementation='manuscript',runtime=dict(effect=text,requires_flag='ending_'+id,notes='결말 검수 원고. 현재 ACT V 전투·결말 선택은 미구현.',related=['지역:dawnless_sanctum']))
# Character chains preserve ownership and never place ancient relics in normal pools.
chain_stories={
'mira':('당신 몫의 고통','운하의 화물 번호와 서고의 편지는 같은 사람에게 이어진다. 살아 있는 이안을 찾았을 때 미라는 먼저 이름을 불러도 되는지 묻는다. 이안은 대신 죽어 주겠다는 말이 아니라 돌아갈 방법을 찾겠다고 썼던 것이라고 답한다.\n\n초승달의 연결은 끊을 수도, 두 사람이 정한 한도 안에서 다시 맺을 수도 있다. 이안의 생존은 선택의 보상이 아니라 앞서 확인한 사실이다.'),
'kalian':('맹세의 수신인','칼리안의 호위 명령은 성물을 지키라고 했고 피난민은 문밖에 남았다. 생존자는 명령서에 자신의 이름을 쓰고 지켜야 했던 것이 누구였는지 묻는다. 칼리안은 왕의 서명을 지우지 않고 그 아래 증언을 더한다.'),
'sera':('별을 남기는 문법','세라는 별을 지우던 문장을 역으로 읽으면 모두 돌아올 거라 믿었다. 그러나 지워진 시간을 함께 돌리면 지금의 삶도 덮인다. 그녀는 복원이 아니라 덧붙여 남기는 문법을 택할 수 있다.'),
'lucian':('거절할 수 있는 축복','루시안에게 치료를 거절한 환자가 돌아온다. 이번에는 이유를 설명할 시간을 달라고 한다. 루시안은 성유를 먼저 바르는 대신 두 손을 내려놓는다.'),
'leonhardt':('문밖에서','성문을 지킨 공로패와 문밖 사망자 명부가 한 상자에 있다. 레온하르트는 방패를 문에 세워 닫히지 않게 한다. 뒤에 남을 경비와 나갈 주민이 함께 철수 순서를 정한다.'),
'erisha':('추적의 마지막 방향','에리샤가 쫓던 도망자는 강제 수령을 거부한 사람이었다. 추적을 끝낼 수 있다는 표식을, 안전하게 돌아갈 길의 표식으로 바꾸려면 의뢰인의 보수를 돌려줘야 한다.'),
'morgan':('앉힐 사람 없는 의자','모르간의 인형은 죽은 이를 대신할 만큼 정확하게 말한다. 하지만 현재의 질문에는 과거의 대답만 반복한다. 그는 빈 의자를 채우는 대신 살아 있는 사람의 새 대답을 듣기로 한다.'),
'kain':('남은 탄환의 주인','카인의 탄창에는 구출 명령보다 처분 명령에 쓰인 탄환이 많다. 마지막 의뢰인은 증인을 처리하라고 한다. 탄창을 반납하는 것과 증언대에 서는 일을 함께 해야 계약이 끝난다.'),
'bella':('내가 적는 양','벨라는 피를 내줄 수 있다는 이유로 언제나 첫 번째 기증자였다. 이번에는 양과 기간을 먼저 적는다. 동료들은 그녀의 거절 뒤에도 곁에 남아 다른 방법을 찾는다.'),
'isaac':('정지 시험','아이작의 기계는 멈추면 실패로 기록되어 쉼 없이 돌아갔다. 안에 묶인 기억을 풀려면 설계자가 정지를 성공으로 인정해야 한다. 그는 출력 기록보다 정지 시험서를 먼저 서명한다.'),
'sylvia':('녹은 뒤의 다리','실비아는 얼음으로 피난민을 지켰지만 영원히 얼려 둘 수는 없다. 녹는 동안 견딜 다리를 먼저 세우고 잠든 사람에게 계절이 바뀐 사실을 설명한다.'),
'drake':('돌아올 매듭','드레이크의 분노는 모두가 필요할 때만 영웅으로 불렸다. 전투가 끝나면 가둘 목줄을 이번에는 본인이 푼다. 동료들은 그가 돌아올 수 있는 신호를 함께 정한다.')}
for i,p in enumerate(lines('relics_ancient.txt'),1):
    owner,relic,effect,flavor=p;name,story=chain_stories[owner]
    put('events',**base('chain_'+owner+'_final'),title=name,category='CHARACTER',character_restriction=owner,act=5,story=story,choices=[dict(name='한도를 정하고 연결한다',description=relic+' 획득 설계. 개인 연속 조건 및 효과 구현 전.',relic=f'relic_ancient_{i:03}',reply='효과와 철회 조건을 당사자가 확인한 뒤 연결한다.'),dict(name='연결하지 않고 기록을 남긴다',description='고대 유물을 받지 않는 결말.',reply='관계를 증명하기 위해 능력을 주고받을 필요는 없었다.')],runtime=dict(pool='character_chain',requires_flags=['chain_'+owner+'_trace','chain_'+owner+'_witness','chain_'+owner+'_consent'],sources=['해당 캐릭터 개인 연속 이벤트 최종 단계'],related=['유물:'+f'relic_ancient_{i:03}']),spoiler=True)
# Mira's five lead-ins plus the final chain above = six authored personal events.
mira_leads=[
('coat','반납되지 않은 외투',1,'병동의 외투 안감에 미라의 배합 메모가 있다. 옷의 주인은 미라가 아니었고, 수선을 맡긴 날짜는 마지막 공동 연구 직전이다.','가면의 필체와 비교한다','이름은 없지만 획의 버릇이 다르다. 미라의 글씨가 아닌 것을 자기 기억으로 채우지 않기로 했다.',[],'chain_mira_trace'),
('tea','두 번째 찻잔',3,'로엔은 설탕 없는 차를 남겨 둔다. 미라는 동료가 연구 중에는 단 차를 마시지 않았다는 사실을 떠올리지만, 그 취향만으로 생존을 단정할 수는 없다.','배달된 편지를 대조한다','약병 배달 기록과 찻잔의 수가 같은 날부터 하나 줄었다. 운하에서 온 화물 번호를 찾아볼 이유가 생겼다.',[],'mira_tea_trace'),
('child','독을 팔던 아이',2,'아이는 독과 진통제를 같은 병으로 판다. 미라는 아이를 꾸짖다가 자신도 외부 라벨의 차이를 줄이자는 연구안에 서명했던 것을 기억한다.','병을 나눠 표시한다','아이에게 판별법과 취급법을 가르쳤다. 알고 나서 바꿀 책임은 어른에게도 있었다.',[],'mira_responsibility'),
('signature','접힌 서명',3,'초승달을 진료표 위에 놓자 수령인란이 비어 있는 이유를 설명하는 별지가 나온다. 한 명의 서명으로 여러 번 인계하도록 접어 둔 문서다.','접힌 부분을 펼친다','미라는 자기 연구 서명과 수령인의 서명을 따로 베꼈다. 공동 연구에 동의한 것이 무기한 고통 수령에 동의한 것은 아니었다.',['ward_ledger'],'chain_mira_witness'),
('formula','삭제되지 않은 배합',4,'서고의 편지는 자신을 죽었다고 단정하지 말아 달라고 부탁한다. 미라는 가면 안쪽의 글씨와 편지를 맞춘 뒤에야 이안이라는 이름을 말한다.','살아 있는 당사자를 찾는다','편지는 구출 뒤 무엇을 해야 하는지 명령하지 않았다. 찾아내면 현재의 의사를 묻기로 했다.',['chain_mira_trace','chain_mira_witness'],'chain_mira_consent')]
for key,name,act,story,caption,reply,req,flag in mira_leads:
    put('events',**base('mira_'+key),title=name,category='CHARACTER',character_restriction='mira',act=act,story=story,choices=[dict(name=caption,description='미라의 개인 조사 기록.',flag=flag,reply=reply),dict(name='기록을 보류한다',description='결론을 내리지 않습니다.',reply='확인할 수 없는 부분은 빈칸으로 남겼다.')],runtime=dict(requires_flags=req,requires_relic='mira_crescent' if key=='signature' else '',related=['유물:mira_crescent','이벤트:chain_mira_final']),spoiler=act>1)
# Five lead-in records for the other eleven characters. Text only; no character expansion in combat.
positions=collections.Counter()
for owner,name,story,caption,reply in lines('character_events.txt'):
    positions[owner]+=1;i=positions[owner];act=[1,2,3,3,4][i-1]
    flags=['chain_'+owner+'_trace',owner+'_ordinary_2',owner+'_ordinary_3','chain_'+owner+'_witness','chain_'+owner+'_consent']
    req=[] if i<4 else (['chain_'+owner+'_trace'] if i==4 else ['chain_'+owner+'_witness'])
    put('events',**base(f'{owner}_personal_{i}'),title=name,category='CHARACTER',character_restriction=owner,act=act,story=story,choices=[dict(name=caption,description='개인 서사 기록을 남깁니다.',flag=flags[i-1],reply=reply),dict(name='지금은 떠난다',description='이 단계의 단서를 얻지 않고 떠납니다.',reply='다음에는 같은 자리에 없을 수도 있다. 하지 않은 선택도 여정의 일부로 남았다.')],runtime=dict(encounter_tier='ordinary' if i<=3 else 'conditional',requires_flags=req,related=['이벤트:chain_'+owner+'_final'],sources=['캐릭터 개인 이벤트 원고']),spoiler=act>1)
# Review and runtime discovery are separate; normal archives must not leak mandatory reveals.
for item in ct.load_data()['events']:
    rt=item.get('runtime',{}).copy()
    if item['id'].startswith('common_act') or item['id']=='act1_ledger':
        rt['discovery_flag']='event_seen_'+item['id'];put('events',id=item['id'],runtime=rt)
    if item['id'].startswith('chain_') and item['id'].endswith('_final'):
        rt['encounter_tier']='rare_chain';put('events',id=item['id'],runtime=rt)
    if item['id'].startswith('mira_'):
        rt['encounter_tier']='conditional' if item['id'] in ('mira_signature','mira_formula') else 'ordinary';put('events',id=item['id'],runtime=rt)
# Relic ownership and acquisition are explicit even for unimplemented effects.
for item in ct.load_data()['relics']:
    if not item.get('text_ready'):continue
    effect=item['effect'];scope='GLOBAL_MAP' if item['id']=='explorer_map' else ('PARTY' if '모든 아군' in effect or '파티' in effect else 'PERSONAL')
    rt=item.get('runtime',{}).copy();rt['scope']=scope;rt['stacking']='UNIQUE_PER_PARTY' if scope!='PERSONAL' else 'UNIQUE_PER_OWNER'
    rt['ordinary_drop']=item['rarity']!='고대';rt['shop']=rt.get('shop',True) and item['rarity']!='고대'
    put('relics',id=item['id'],scope=scope,stacking=rt['stacking'],runtime=rt)

for id,name,act,flag,text in lines('lore.txt'):
    text=text.replace('\\n','\n')
    put('lore',**base(id,True),name=name,act=int(act),description=text,spoiler=int(act)>1,implementation='playable' if int(act)==1 else 'manuscript',runtime=dict(effect=text,requires_flag=flag,related=['지역:'+regions[int(act)-1][0]],sources=['세계관·인물 기록 원고']))

for num,effect,detail,stack in lines('status_rules.txt'):
    put('powers',id='status_draft_'+num,effect=effect,tooltip=effect+'\n'+detail,stack_mode=stack,rule_review='specified',text_review_state='pending_user',runtime=dict(notes='상세 규칙 검수안. 현재 전투에는 자동 적용하지 않습니다.\n'+detail,sources=['300종 원고의 규칙 구체화'],related=[]))
for kind,items in ct.load_data().items():
    for item in items:
        if item.get('text_ready'):put(kind,id=item['id'],text_review_state='pending_user')

final_captions={'mira':'두 사람이 보호의 한도를 정한다','kalian':'보호할 이름을 맹세에 더한다','sera':'남기는 문법을 쓴다','lucian':'철회할 수 있는 축복을 정한다','leonhardt':'문밖까지 방패를 펼친다','erisha':'돌아갈 길에 표식을 남긴다','morgan':'빈자리를 그대로 지킨다','kain':'탄창을 반납하고 증언한다','bella':'기증량을 직접 서명한다','isaac':'정지 시험을 완료한다','sylvia':'다리를 확인하고 해빙한다','drake':'함께 정한 신호로 돌아온다'}
for e in ct.load_data()['events']:
    if e['id'].startswith('chain_') and e['id'].endswith('_final'):
        choices=e['choices'];choices[0]['name']=final_captions[e['character_restriction']]
        choices[0]['reply']='이 선택의 흔적이 전용 유물에 남았다. 힘을 얻은 뒤에도 그 선택의 책임은 사라지지 않는다.'
        put('events',id=e['id'],choices=choices)

links={'간병인의 골무':'common_act1_03','접힌 담요':'common_act1_04','배급 주머니':'common_act1_05','소독 집게':'common_act1_06','잔불 심지':'common_act1_07','나무 수저':'common_act1_08','빈 침대의 명패':'empty_ward','밀랍 수송인':'common_act2_04','가라앉지 않는 추':'common_act2_18','두 잔의 찻잔':'common_act3_01','검은 여과지':'common_act3_02','거꾸로 쓴 처방전':'common_act3_12','이름을 남기는 바늘':'common_act4_13','에델의 등불':'common_act5_02','작은 분배기':'common_act5_05','분산된 불씨':'common_act5_05','성가대의 쉼표':'common_act5_04','공개된 장부':'common_act5_10','이안의 봉투':'mira_formula','공동 서명 처방전':'mira_signature'}
for r in ct.load_data()['relics']:
    if r['name'] not in links:continue
    rt=r.get('runtime',{}).copy();rt['related']=list(dict.fromkeys(rt.get('related',[])+['이벤트:'+links[r['name']]]));put('relics',id=r['id'],runtime=rt)

report=ct.validate_all();assert report.get('invalid',0)==0,report
result=export_catalog(ct.load_data(),ROOT)
counts={k:len([r for r in v if r.get('text_ready') and not r.get('archived')]) for k,v in ct.load_data().items()}
print(json.dumps({'text_ready':counts,'export_counts':result['counts']},ensure_ascii=False))

