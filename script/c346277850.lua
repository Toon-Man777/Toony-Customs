local s,id=GetID()
function s.initial_effect(c)
	-- Must be Synchro Summoned
	c:EnableReviveLimit()
	-- Custom Synchro Procedure: 1 "Meklord Emperor Granel" (treated as Tuner) + 1+ non-Tuner Machine monsters
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_IGNORE_IMMUNE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.syncon)
	e1:SetTarget(s.syntg)
	e1:SetOperation(s.synop)
	e1:SetValue(SUMMON_TYPE_SYNCHRO)
	c:RegisterEffect(e1)

	-- Gains ATK/DEF equal to half your LP
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetValue(s.lpval)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e3)

	-- Once per turn: Equip 1 opponent's Extra Deck Special Summoned monster
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetCategory(CATEGORY_EQUIP)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1)
	e4:SetTarget(s.eqtg)
	e4:SetOperation(s.eqop)
	c:RegisterEffect(e4)
	aux.AddEREquipLimit(c,nil,s.eqval,s.equipop,e4)

	-- Piercing battle damage
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetCode(EFFECT_PIERCE)
	c:RegisterEffect(e5)

	-- Special Summon 1 monster equipped to this card
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,1))
	e6:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e6:SetType(EFFECT_TYPE_IGNITION)
	e6:SetRange(LOCATION_MZONE)
	e6:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e6:SetTarget(s.sptg)
	e6:SetOperation(s.spop)
	c:RegisterEffect(e6)
end

s.listed_names={9265} -- Meklord Emperor Granel

-- Dynamic Synchro Calculations
function s.tunerfilter(c)
	return c:IsCode(9265) or c:IsType(TYPE_TUNER)
end
function s.nontunerfilter(c,scard,sumtype,tp)
	return c:IsRace(RACE_MACHINE,scard,sumtype,tp)
end
function s.syncon(e,c,smat,mg,minc,maxc)
	if c==nil then return true end
	local tp=c:GetControler()
	local g=Duel.GetMatchingGroup(Card.IsCanBeSynchroMaterial,tp,LOCATION_MZONE,0,nil,c)
	return g:IsExists(s.tunerfilter,1,nil) and g:IsExists(s.nontunerfilter,1,nil,c,SUMMON_TYPE_SYNCHRO,tp)
end
function s.syntg(e,tp,eg,ep,ev,re,r,rp,chk,c,smat,mg,minc,maxc)
	local g=Duel.GetMatchingGroup(Card.IsCanBeSynchroMaterial,tp,LOCATION_MZONE,0,nil,c)
	local tuners=g:Filter(s.tunerfilter,nil)
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SMATERIAL)
	local tuner=tuners:Select(tp,1,1,nil):GetFirst()
	if not tuner then return false end
	
	local nontuners=g:Filter(s.nontunerfilter,tuner,c,SUMMON_TYPE_SYNCHRO,tp)
	local lv=c:GetLevel() - tuner:GetLevel()
	if lv<=0 then return false end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SMATERIAL)
	local nontun=nontuners:SelectWithSumEqual(tp,Card.GetSynchroLevel,lv,1,99,c)
	if #nontun==0 then return false end
	
	local sg=Group.CreateGroup()
	sg:AddCard(tuner)
	sg:Merge(nontun)
	sg:KeepAlive()
	e:SetLabelObject(sg)
	return true
end
function s.synop(e,tp,eg,ep,ev,re,r,rp,c,smat,mg,minc,maxc)
	local g=e:GetLabelObject()
	c:SetMaterial(g)
	Duel.SendtoGrave(g,REASON_MATERIAL+REASON_SYNCHRO)
	g:DeleteGroup()
end

-- LP Processing Function
function s.lpval(e,c)
	return math.floor(Duel.GetLP(e:GetHandlerPlayer())/2)
end

-- Absorber Operations
function s.eqfilter(c)
	return c:IsFaceup() and c:IsSummonLocation(LOCATION_EXTRA)
end
function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and s.eqfilter(chkc) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		and Duel.IsExistingTarget(s.eqfilter,tp,0,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	local g=Duel.SelectTarget(tp,s.eqfilter,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,g,1,0,0)
end
function s.eqval(ec,c,tp)
	return ec:IsControler(1-tp)
end
function s.equipop(c,e,tp,tc)
	if not c:EquipByEffectAndLimitRegister(e,tp,tc,nil,true) then return end
	local atk=tc:GetTextAtk()
	if atk<0 then atk=0 end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetValue(atk)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
	c:RegisterEffect(e1)
end

-- Spit Out / De-attach Summon Logic
function s.spfilter(c,e,tp)
	return c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_SZONE) and chkc:IsControler(tp) and s.spfilter(chkc,e,tp) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and e:GetHandler():GetEquipGroup():IsExists(s.spfilter,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=e:GetHandler():GetEquipGroup():FilterSelect(tp,s.spfilter,1,1,nil,e,tp)
	Duel.SetTargetCard(g)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	end
end